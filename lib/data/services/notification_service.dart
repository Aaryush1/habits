import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/completion.dart';
import '../../domain/entities/habit.dart';
import 'settings_service.dart';

/// Payload object delivered when the user taps a notification or action button.
class NotificationTapEvent {
  const NotificationTapEvent({
    required this.habitId,
    required this.actionId,
  });

  /// The habit UUID carried in the notification payload.
  final String habitId;

  /// The action ID, or empty string for a plain notification tap.
  static const String quickComplete = 'QUICK_COMPLETE';
  static const String open = 'OPEN_HABIT';

  final String actionId;
}

/// Handles scheduling and cancelling local notifications for habit reminders.
class NotificationService {
  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDesc = 'Daily reminders for your habit practice';

  /// Reserved notification ID for the evening nudge.
  static const int _eveningNudgeId = 0;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final _responseController =
      StreamController<NotificationTapEvent>.broadcast();

  /// Stream of tap events from foreground notifications and action buttons.
  Stream<NotificationTapEvent> get responseStream =>
      _responseController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Emit a tap event if the app was cold-launched by tapping a notification.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      _onNotificationResponse(launchDetails.notificationResponse!);
    }

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final habitId = response.payload;
    if (habitId == null || habitId.isEmpty) return;

    _responseController.add(NotificationTapEvent(
      habitId: habitId,
      actionId: response.actionId ?? '',
    ));
  }

  void dispose() {
    _responseController.close();
  }

  /// Requests POST_NOTIFICATIONS permission on Android 13+.
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Returns true if the notification permission is currently granted.
  Future<bool> isPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Schedules a daily reminder for [habit] at the given [reminderTime]
  /// (minutes since midnight). Cancels any existing reminder for the habit first.
  ///
  /// If [reminderTime] is null, only cancels the existing reminder.
  Future<void> scheduleHabitReminder(
    Habit habit, {
    required int? reminderTime,
  }) async {
    await cancelHabitReminder(habit.id);
    if (reminderTime == null) return;

    final notifId = _habitNotificationId(habit.id);
    final scheduledDate = _nextOccurrence(reminderTime);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          NotificationTapEvent.quickComplete,
          'Mark Done',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationTapEvent.open,
          'Open',
          showsUserInterface: true,
        ),
      ],
    );

    await _plugin.zonedSchedule(
      notifId,
      habit.name,
      _buildHabitBody(habit),
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: habit.id,
    );
  }

  /// Schedules a daily evening reflection nudge at [eveningTime] (minutes
  /// since midnight). Builds contextual body text from today's [habits] and
  /// their [completions] to show progress. Uses notification ID 0.
  Future<void> scheduleEveningNudge(
    int eveningTime,
    List<Habit> habits,
    List<Completion> completions,
  ) async {
    await _plugin.cancel(_eveningNudgeId);

    final scheduledDate = _nextOccurrence(eveningTime);
    final completedIds = completions.map((c) => c.habitId).toSet();
    final scheduledToday = habits
        .where((h) => h.notificationsEnabled || h.reminderTime != null)
        .toList();
    final completedCount =
        scheduledToday.where((h) => completedIds.contains(h.id)).length;
    final total = scheduledToday.length;

    final body = total > 0
        ? 'You completed $completedCount of $total habits today. Reflect on your progress!'
        : 'How did your habits go today? Take a moment to reflect.';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.zonedSchedule(
      _eveningNudgeId,
      'Evening Reflection',
      body,
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels the scheduled reminder for the given habit ID.
  Future<void> cancelHabitReminder(String habitId) async {
    await _plugin.cancel(_habitNotificationId(habitId));
  }

  /// Cancels the evening nudge notification.
  Future<void> cancelEveningNudge() async {
    await _plugin.cancel(_eveningNudgeId);
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  /// Re-schedules all notifications from scratch using current [habits] and
  /// [settings]. Cancels everything first, then schedules per-habit reminders
  /// and (if enabled) the evening nudge.
  ///
  /// Pass [todayCompletions] to build a contextual evening nudge body.
  Future<void> rescheduleAll(
    List<Habit> habits,
    SettingsService settings, {
    List<Completion> todayCompletions = const [],
  }) async {
    await _plugin.cancelAll();

    if (!settings.notificationsEnabled) return;

    // Per-habit reminders
    for (final habit in habits) {
      if (habit.notificationsEnabled && habit.reminderTime != null) {
        await scheduleHabitReminder(habit, reminderTime: habit.reminderTime);
      }
    }

    // Evening nudge
    if (settings.eveningNudgeEnabled) {
      await scheduleEveningNudge(
        settings.eveningNudgeTime,
        habits,
        todayCompletions,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns the next TZDateTime at [minutesSinceMidnight] (today or tomorrow).
  tz.TZDateTime _nextOccurrence(int minutesSinceMidnight) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = minutesSinceMidnight ~/ 60;
    final minute = minutesSinceMidnight % 60;

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Builds the notification body for a habit reminder.
  /// Priority: identity statement → implementation intention → 2-minute version → default.
  String _buildHabitBody(Habit habit) {
    if (habit.identityStatement != null) {
      return habit.identityStatement!;
    }
    if (habit.implementationTime != null &&
        habit.implementationLocation != null) {
      return '${habit.implementationTime} at ${habit.implementationLocation}';
    }
    if (habit.implementationTime != null) {
      return habit.implementationTime!;
    }
    if (habit.twoMinuteVersion != null) {
      return 'Start small: ${habit.twoMinuteVersion}';
    }
    return 'Time to build your habit!';
  }

  /// Stable notification ID for a habit derived from its UUID.
  /// IDs start at 1 to avoid collision with the reserved evening nudge ID (0).
  int _habitNotificationId(String habitId) {
    return (habitId.hashCode.abs() % 100000) + 1;
  }
}
