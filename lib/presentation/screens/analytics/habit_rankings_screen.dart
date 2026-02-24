import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/color_utils.dart';
import '../../providers/rankings_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../habits/habit_detail_screen.dart';

class HabitRankingsScreen extends ConsumerStatefulWidget {
  const HabitRankingsScreen({super.key});

  @override
  ConsumerState<HabitRankingsScreen> createState() =>
      _HabitRankingsScreenState();
}

class _HabitRankingsScreenState extends ConsumerState<HabitRankingsScreen> {
  RankingSortField _sortField = RankingSortField.completionRate;
  bool _ascending = false;

  @override
  Widget build(BuildContext context) {
    final rankingsAsync = ref.watch(rankingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habit Rankings')),
      body: SafeArea(
        child: rankingsAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading rankings'),
          error: (_, _) => const Center(child: Text('Failed to load')),
          data: (ranked) {
            final sorted = _sortRanked(ranked);

            return Column(
              children: [
                // Sort header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: AppSpacing.space8,
                  ),
                  child: Row(
                    children: [
                      _SortButton(
                        label: 'Rate',
                        field: RankingSortField.completionRate,
                        current: _sortField,
                        ascending: _ascending,
                        onTap: _onSort,
                      ),
                      _SortButton(
                        label: 'Streak',
                        field: RankingSortField.currentStreak,
                        current: _sortField,
                        ascending: _ascending,
                        onTap: _onSort,
                      ),
                      _SortButton(
                        label: 'Total',
                        field: RankingSortField.totalCompletions,
                        current: _sortField,
                        ascending: _ascending,
                        onTap: _onSort,
                      ),
                      _SortButton(
                        label: 'Strength',
                        field: RankingSortField.habitStrength,
                        current: _sortField,
                        ascending: _ascending,
                        onTap: _onSort,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Ranked list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space8,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      return _RankingRow(
                        rank: index + 1,
                        habit: sorted[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HabitDetailScreen(
                              habitId: sorted[index].habitId,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onSort(RankingSortField field) {
    setState(() {
      if (_sortField == field) {
        _ascending = !_ascending;
      } else {
        _sortField = field;
        _ascending = false;
      }
    });
  }

  List<RankedHabit> _sortRanked(List<RankedHabit> ranked) {
    final sorted = List<RankedHabit>.from(ranked);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case RankingSortField.completionRate:
          cmp = a.completionRate.compareTo(b.completionRate);
        case RankingSortField.currentStreak:
          cmp = a.currentStreak.compareTo(b.currentStreak);
        case RankingSortField.totalCompletions:
          cmp = a.totalCompletions.compareTo(b.totalCompletions);
        case RankingSortField.habitStrength:
          cmp = a.habitStrength.compareTo(b.habitStrength);
      }
      return _ascending ? cmp : -cmp;
    });
    return sorted;
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.field,
    required this.current,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final RankingSortField field;
  final RankingSortField current;
  final bool ascending;
  final ValueChanged<RankingSortField> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = current == field;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(field),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isActive ? AppColors.accentGold : AppColors.textTertiary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isActive)
                Icon(
                  ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: AppColors.accentGold,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.habit,
    required this.onTap,
  });

  final int rank;
  final RankedHabit habit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(habit.colorHex) ?? AppColors.accentGold;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space8),
        padding: const EdgeInsets.all(AppSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            // Color indicator
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Habit name + status badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.habitName, style: AppTypography.bodyMedium),
                  const SizedBox(height: 2),
                  _StatusChip(status: habit.status),
                ],
              ),
            ),
            // Stats columns
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Text(
                    '${(habit.completionRate * 100).round()}%',
                    style: AppTypography.labelMedium,
                  ),
                  Text(
                    'rate',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    '${habit.currentStreak}',
                    style: AppTypography.labelMedium,
                  ),
                  Text(
                    'streak',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final HabitStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, fgColor) = switch (status) {
      HabitStatus.onFire => (
          'On Fire',
          AppColors.completionGreenSubtle,
          AppColors.completionGreen,
        ),
      HabitStatus.steady => (
          'Steady',
          AppColors.accentGoldSubtle,
          AppColors.accentGold,
        ),
      HabitStatus.needsAttention => (
          'Needs Work',
          AppColors.accentGoldSubtle,
          AppColors.accentGoldMuted,
        ),
      HabitStatus.stalled => (
          'Stalled',
          AppColors.missedCoralSubtle,
          AppColors.missedCoral,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: fgColor,
          fontSize: 10,
        ),
      ),
    );
  }
}
