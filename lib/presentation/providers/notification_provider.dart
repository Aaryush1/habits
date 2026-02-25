import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/notification_service.dart';
import '../../domain/entities/completion.dart';
import '../../domain/entities/habit.dart';
import '../screens/habits/habit_detail_screen.dart';
import 'completions_provider.dart';
import 'settings_provider.dart';

// ---------------------------------------------------------------------------
// Navigator key
//
// Wire this into MaterialApp in app.dart so notifications can push routes:
//   navigatorKey: ref.watch(notificationNavigatorKeyProvider),
// ---------------------------------------------------------------------------

/// Shared [GlobalKey<NavigatorState>] for notification-driven navigation.
final notificationNavigatorKeyProvider =
    Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});

/// State for the notification subsystem.
class NotificationState {
  const NotificationState({
    this.permissionGranted = false,
    this.initialized = false,
  });

  final bool permissionGranted;
  final bool initialized;

  NotificationState copyWith({
    bool? permissionGranted,
    bool? initialized,
  }) {
    return NotificationState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      initialized: initialized ?? this.initialized,
    );
  }
}

class NotificationNotifier extends AsyncNotifier<NotificationState> {
  NotificationService get _service => ref.read(notificationServiceProvider);

  StreamSubscription<NotificationTapEvent>? _tapSubscription;

  @override
  Future<NotificationState> build() async {
    await _service.initialize();
    final granted = await _service.isPermissionGranted();

    // Subscribe to all tap events (foreground interactions + cold-launch).
    _tapSubscription?.cancel();
    _tapSubscription = _service.responseStream.listen(_handleTapEvent);
    ref.onDispose(() => _tapSubscription?.cancel());

    return NotificationState(permissionGranted: granted, initialized: true);
  }

  Future<void> _handleTapEvent(NotificationTapEvent event) async {
    if (event.actionId == NotificationTapEvent.quickComplete) {
      // Toggle the habit complete for today via the family provider.
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      await ref
          .read(completionsProvider(todayDate).notifier)
          .toggleCompletion(habitId: event.habitId);
      return;
    }

    // Plain body tap or explicit OPEN_HABIT action → navigate to detail screen.
    if (event.actionId == NotificationTapEvent.open ||
        event.actionId.isEmpty) {
      _navigateToHabitDetail(event.habitId);
    }
  }

  /// Pushes [HabitDetailScreen] using the shared navigator key.
  /// Silently no-ops if the navigator is not yet attached to the widget tree.
  void _navigateToHabitDetail(String habitId) {
    final navigatorKey = ref.read(notificationNavigatorKeyProvider);
    final navState = navigatorKey.currentState;
    if (navState == null) return;

    navState.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            HabitDetailScreen(habitId: habitId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  /// Requests notification permission and updates state.
  Future<bool> requestPermission() async {
    final granted = await _service.requestPermission();
    state = AsyncData(
      state.valueOrNull?.copyWith(permissionGranted: granted) ??
          NotificationState(permissionGranted: granted, initialized: true),
    );
    return granted;
  }

  /// Schedules or cancels a reminder for a single habit based on its
  /// [notificationsEnabled] flag and [reminderTime].
  Future<void> updateHabitReminder(Habit habit) async {
    if (habit.notificationsEnabled && habit.reminderTime != null) {
      await _service.scheduleHabitReminder(
        habit,
        reminderTime: habit.reminderTime,
      );
    } else {
      await _service.cancelHabitReminder(habit.id);
    }
  }

  /// Schedules the evening nudge notification.
  Future<void> scheduleEveningNudge(
    int eveningTime,
    List<Habit> habits,
    List<Completion> completions,
  ) async {
    await _service.scheduleEveningNudge(eveningTime, habits, completions);
  }

  /// Re-schedules all notifications (habit reminders + evening nudge) using
  /// current settings. Pass [todayCompletions] for a contextual nudge body.
  Future<void> rescheduleAll(
    List<Habit> habits, {
    List<Completion> todayCompletions = const [],
  }) async {
    final settings = ref.read(settingsServiceProvider);
    await _service.rescheduleAll(
      habits,
      settings,
      todayCompletions: todayCompletions,
    );
  }

  /// Cancels all reminders immediately.
  Future<void> cancelAll() async {
    await _service.cancelAllReminders();
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
