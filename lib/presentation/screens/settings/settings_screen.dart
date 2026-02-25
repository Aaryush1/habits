import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/seed_data.dart';
import '../../../data/datasources/local/hive_database.dart';
import '../../providers/completions_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifState = ref.watch(notificationProvider);
    final isGranted = notifState.valueOrNull?.permissionGranted ?? false;

    final eveningNudgeEnabled = ref.watch(eveningNudgeEnabledProvider);
    final eveningNudgeTime = ref.watch(eveningNudgeTimeProvider);
    final positiveNudgeEnabled = ref.watch(positiveNudgeEnabledProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: AppSpacing.space16),
            Text('Settings', style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.space24),

            // Notifications
            _SectionHeader(title: 'Notifications'),
            const SizedBox(height: AppSpacing.space8),
            _ToggleTile(
              icon: Icons.notifications_rounded,
              title: 'Enable Reminders',
              subtitle: isGranted
                  ? 'Send daily habit reminders'
                  : 'Permission required — tap to grant',
              color: AppColors.twoMinuteBlue,
              value: settings.notificationsEnabled,
              onChanged: (value) async {
                if (value && !isGranted) {
                  final granted = await ref
                      .read(notificationProvider.notifier)
                      .requestPermission();
                  if (!granted) return;
                }
                await ref
                    .read(settingsProvider.notifier)
                    .setNotificationsEnabled(value);
                if (!value) {
                  await ref.read(notificationProvider.notifier).cancelAll();
                } else {
                  final habits = ref.read(habitsProvider).valueOrNull ?? [];
                  await ref
                      .read(notificationProvider.notifier)
                      .rescheduleAll(habits);
                }
              },
            ),
            const SizedBox(height: AppSpacing.space8),
            _ActionTile(
              icon: Icons.access_time_rounded,
              title: 'Default Reminder Time',
              subtitle: _formatMinutes(settings.defaultReminderTime),
              color: AppColors.twoMinuteBlue,
              onTap: () => _pickDefaultReminderTime(context, ref, settings),
            ),
            const SizedBox(height: AppSpacing.space8),
            _ToggleTile(
              icon: Icons.nights_stay_rounded,
              title: 'Evening Nudge',
              subtitle: 'Get a daily reflection prompt in the evening',
              color: AppColors.twoMinuteBlue,
              value: eveningNudgeEnabled,
              onChanged: (value) async {
                if (value && !isGranted) {
                  final granted = await ref
                      .read(notificationProvider.notifier)
                      .requestPermission();
                  if (!granted) return;
                }
                await ref.read(eveningNudgeEnabledProvider.notifier).set(value);
                if (!value) {
                  await ref
                      .read(notificationProvider.notifier)
                      .scheduleEveningNudge(eveningNudgeTime, [], []);
                }
              },
            ),
            if (eveningNudgeEnabled) ...[
              const SizedBox(height: AppSpacing.space8),
              _TimeTile(
                icon: Icons.bedtime_rounded,
                title: 'Nudge Time',
                subtitle: _formatMinutes(eveningNudgeTime),
                color: AppColors.twoMinuteBlue,
                onTap: () =>
                    _pickEveningNudgeTime(context, ref, eveningNudgeTime),
              ),
            ],
            const SizedBox(height: AppSpacing.space8),
            _ToggleTile(
              icon: Icons.celebration_rounded,
              title: 'Celebrate Perfect Days',
              subtitle: 'Show a nudge when you complete all habits',
              color: AppColors.accentGold,
              value: positiveNudgeEnabled,
              onChanged: (value) async {
                await ref
                    .read(positiveNudgeEnabledProvider.notifier)
                    .set(value);
              },
            ),
            const SizedBox(height: AppSpacing.space24),

            // App Info
            _SectionHeader(title: 'About'),
            const SizedBox(height: AppSpacing.space8),
            _InfoTile(
              icon: Icons.info_outline_rounded,
              title: 'Atomic Habits Tracker',
              subtitle: 'Version 1.0.0',
            ),
            _InfoTile(
              icon: Icons.code_rounded,
              title: 'Built with Flutter',
              subtitle: 'Hive + Riverpod, Clean Architecture',
            ),
            const SizedBox(height: AppSpacing.space24),

            // Developer Tools
            _SectionHeader(title: 'Developer Tools'),
            const SizedBox(height: AppSpacing.space8),
            _ActionTile(
              icon: Icons.science_rounded,
              title: 'Load Sample Data',
              subtitle: '7 habits with 90 days of realistic completions',
              color: AppColors.accentGold,
              onTap: () => _loadSeedData(context, ref),
            ),
            const SizedBox(height: AppSpacing.space8),
            _ActionTile(
              icon: Icons.delete_sweep_rounded,
              title: 'Clear All Data',
              subtitle: 'Remove all habits and completions',
              color: AppColors.missedCoral,
              onTap: () => _clearAllData(context, ref),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final displayMin = m.toString().padLeft(2, '0');
    return '$displayHour:$displayMin $period';
  }

  Future<void> _pickDefaultReminderTime(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final current = TimeOfDay(
      hour: settings.defaultReminderTime ~/ 60,
      minute: settings.defaultReminderTime % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked == null) return;
    await ref
        .read(settingsProvider.notifier)
        .setDefaultReminderTime(picked.hour * 60 + picked.minute);
  }

  Future<void> _pickEveningNudgeTime(
    BuildContext context,
    WidgetRef ref,
    int currentMinutes,
  ) async {
    final current = TimeOfDay(
      hour: currentMinutes ~/ 60,
      minute: currentMinutes % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked == null) return;
    final newMinutes = picked.hour * 60 + picked.minute;
    await ref.read(eveningNudgeTimeProvider.notifier).set(newMinutes);
    // Reschedule with updated time if enabled
    final habits = ref.read(habitsProvider).valueOrNull ?? [];
    await ref
        .read(notificationProvider.notifier)
        .scheduleEveningNudge(newMinutes, habits, []);
  }

  Future<void> _loadSeedData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Sample Data?'),
        content: const Text(
          'This will add 7 habits with 90 days of completion history. '
          'Existing data will NOT be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Load'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating sample data...')),
    );

    final habitRepo = ref.read(habitRepositoryProvider);
    final completionRepo = ref.read(completionRepositoryProvider);

    await generateSeedData(
      habitRepo: habitRepo,
      completionRepo: completionRepo,
    );

    // Invalidate all providers to pick up new data
    ref.invalidate(habitsProvider);
    ref.read(completionsRevisionProvider.notifier).state++;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Sample data loaded! Check your tabs.')),
      );
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all habits and completions. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.missedCoral,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await HiveDatabase.habitsBox.clear();
    await HiveDatabase.completionsBox.clear();

    // Invalidate all providers
    ref.invalidate(habitsProvider);
    ref.read(completionsRevisionProvider.notifier).state++;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared.')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.headlineMedium.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool value;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space8),
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
