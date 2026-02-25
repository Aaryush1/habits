import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// ---------------------------------------------------------------------------
// Individual setting providers for granular watching
// ---------------------------------------------------------------------------

final eveningNudgeEnabledProvider =
    NotifierProvider<_EveningNudgeEnabledNotifier, bool>(
        _EveningNudgeEnabledNotifier.new);

class _EveningNudgeEnabledNotifier extends Notifier<bool> {
  SettingsService get _service => ref.read(settingsServiceProvider);

  @override
  bool build() => _service.eveningNudgeEnabled;

  Future<void> set(bool value) async {
    await _service.setEveningNudgeEnabled(value);
    state = value;
  }
}

final eveningNudgeTimeProvider =
    NotifierProvider<_EveningNudgeTimeNotifier, int>(
        _EveningNudgeTimeNotifier.new);

class _EveningNudgeTimeNotifier extends Notifier<int> {
  SettingsService get _service => ref.read(settingsServiceProvider);

  @override
  int build() => _service.eveningNudgeTime;

  Future<void> set(int minutesSinceMidnight) async {
    await _service.setEveningNudgeTime(minutesSinceMidnight);
    state = minutesSinceMidnight;
  }
}

final positiveNudgeEnabledProvider =
    NotifierProvider<_PositiveNudgeEnabledNotifier, bool>(
        _PositiveNudgeEnabledNotifier.new);

class _PositiveNudgeEnabledNotifier extends Notifier<bool> {
  SettingsService get _service => ref.read(settingsServiceProvider);

  @override
  bool build() => _service.positiveNudgeEnabled;

  Future<void> set(bool value) async {
    await _service.setPositiveNudgeEnabled(value);
    state = value;
  }
}

/// Notifier for app-wide settings (notifications toggle, default reminder time).
class SettingsNotifier extends Notifier<AppSettings> {
  SettingsService get _service => ref.read(settingsServiceProvider);

  @override
  AppSettings build() {
    return AppSettings(
      notificationsEnabled: _service.notificationsEnabled,
      defaultReminderTime: _service.defaultReminderTime,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _service.setNotificationsEnabled(value);
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> setDefaultReminderTime(int minutesSinceMidnight) async {
    await _service.setDefaultReminderTime(minutesSinceMidnight);
    state = state.copyWith(defaultReminderTime: minutesSinceMidnight);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Immutable value class for app settings state.
class AppSettings {
  const AppSettings({
    required this.notificationsEnabled,
    required this.defaultReminderTime,
  });

  final bool notificationsEnabled;
  /// Minutes since midnight for the default daily reminder.
  final int defaultReminderTime;

  AppSettings copyWith({
    bool? notificationsEnabled,
    int? defaultReminderTime,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultReminderTime: defaultReminderTime ?? this.defaultReminderTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.notificationsEnabled == notificationsEnabled &&
        other.defaultReminderTime == defaultReminderTime;
  }

  @override
  int get hashCode =>
      Object.hash(notificationsEnabled, defaultReminderTime);
}
