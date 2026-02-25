import 'package:hive/hive.dart';
import '../datasources/local/hive_database.dart';

/// Key-value settings store backed by a plain Hive box.
class SettingsService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _defaultReminderTimeKey = 'default_reminder_time';
  static const String _eveningNudgeEnabledKey = 'evening_nudge_enabled';
  static const String _eveningNudgeTimeKey = 'evening_nudge_time';
  static const String _positiveNudgeEnabledKey = 'positive_nudge_enabled';

  Box<dynamic> get _box => HiveDatabase.settingsBox;

  /// Whether global habit reminder notifications are enabled (defaults to false).
  bool get notificationsEnabled {
    return _box.get(_notificationsEnabledKey, defaultValue: false) as bool;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _box.put(_notificationsEnabledKey, value);
  }

  /// Default reminder time as minutes since midnight (defaults to 480 = 8:00 AM).
  int get defaultReminderTime {
    return _box.get(_defaultReminderTimeKey, defaultValue: 480) as int;
  }

  Future<void> setDefaultReminderTime(int minutesSinceMidnight) async {
    await _box.put(_defaultReminderTimeKey, minutesSinceMidnight);
  }

  /// Whether the evening reflection nudge is enabled (defaults to false).
  bool get eveningNudgeEnabled {
    return _box.get(_eveningNudgeEnabledKey, defaultValue: false) as bool;
  }

  Future<void> setEveningNudgeEnabled(bool value) async {
    await _box.put(_eveningNudgeEnabledKey, value);
  }

  /// Evening nudge time as minutes since midnight (defaults to 1260 = 9:00 PM).
  int get eveningNudgeTime {
    return _box.get(_eveningNudgeTimeKey, defaultValue: 1260) as int;
  }

  Future<void> setEveningNudgeTime(int minutesSinceMidnight) async {
    await _box.put(_eveningNudgeTimeKey, minutesSinceMidnight);
  }

  /// Whether positive streak/milestone nudges are enabled (defaults to true).
  bool get positiveNudgeEnabled {
    return _box.get(_positiveNudgeEnabledKey, defaultValue: true) as bool;
  }

  Future<void> setPositiveNudgeEnabled(bool value) async {
    await _box.put(_positiveNudgeEnabledKey, value);
  }
}
