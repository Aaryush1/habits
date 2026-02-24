import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/schedule_utils.dart';
import '../../providers/heatmap_provider.dart';
import '../../providers/habits_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class FullHeatmapScreen extends ConsumerStatefulWidget {
  const FullHeatmapScreen({super.key});

  @override
  ConsumerState<FullHeatmapScreen> createState() => _FullHeatmapScreenState();
}

class _FullHeatmapScreenState extends ConsumerState<FullHeatmapScreen> {
  int _rangeDays = 84; // 12 weeks default
  String? _selectedHabitId; // null = all habits

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = dateOnly(now);
    final start = today.subtract(Duration(days: _rangeDays - 1));
    final heatmapAsync = ref.watch(heatmapProvider(
      HeatmapQuery(
        startDate: start,
        endDate: today,
        habitId: _selectedHabitId,
      ),
    ));
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Heatmap')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          children: [
            // Range selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rangeChip('12W', 84),
                _rangeChip('6M', 182),
                _rangeChip('1Y', 365),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),

            // Habit filter
            habitsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (habits) => SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('All Habits', null),
                    ...habits.map(
                      (h) => _filterChip(h.name, h.id),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),

            // Heatmap grid
            heatmapAsync.when(
              loading: () => const LoadingIndicator(message: 'Building heatmap'),
              error: (_, _) => const Center(child: Text('Failed to load')),
              data: (points) {
                if (points.isEmpty) {
                  return const Center(child: Text('No data'));
                }

                final maxCount = points.fold<int>(
                  1,
                  (a, p) => a > p.count ? a : p.count,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month labels + grid
                    _HeatmapGridView(
                      points: points,
                      maxCount: maxCount,
                    ),
                    const SizedBox(height: AppSpacing.space12),

                    // Legend
                    _Legend(maxCount: maxCount),
                    const SizedBox(height: AppSpacing.space20),

                    // Insights
                    _Insights(points: points),
                  ],
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(String label, int days) {
    final selected = _rangeDays == days;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _rangeDays = days),
        selectedColor: AppColors.accentGold,
        backgroundColor: AppColors.backgroundTertiary,
        labelStyle: AppTypography.labelSmall.copyWith(
          color:
              selected ? AppColors.textInverse : AppColors.textSecondary,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? habitId) {
    final selected = _selectedHabitId == habitId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedHabitId = habitId),
        selectedColor: AppColors.accentGold,
        backgroundColor: AppColors.backgroundTertiary,
        labelStyle: AppTypography.labelSmall.copyWith(
          color:
              selected ? AppColors.textInverse : AppColors.textSecondary,
          fontSize: 11,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _HeatmapGridView extends StatelessWidget {
  const _HeatmapGridView({
    required this.points,
    required this.maxCount,
  });

  final List<HeatmapPoint> points;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    // Pad to align with Monday
    final firstDay = points.first.date;
    final startPadding = (firstDay.weekday - 1) % 7;

    final cells = <int>[
      ...List.filled(startPadding, -1),
      ...points.map((p) => p.count),
    ];

    // Build columns (each column = 1 week, 7 rows)
    final numWeeks = (cells.length / 7).ceil();
    const cellSize = 13.0;
    const gap = 2.0;

    // Determine month labels
    final monthLabels = <int, String>{};
    for (var col = 0; col < numWeeks; col++) {
      final idx = col * 7;
      if (idx < startPadding) continue;
      final pointIdx = idx - startPadding;
      if (pointIdx < 0 || pointIdx >= points.length) continue;
      final date = points[pointIdx].date;
      if (date.day <= 7) {
        monthLabels[col] = DateFormat('MMM').format(date);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 28), // space for day labels
              ...List.generate(numWeeks, (col) {
                return SizedBox(
                  width: cellSize + gap,
                  child: monthLabels.containsKey(col)
                      ? Text(
                          monthLabels[col]!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Grid with day labels
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Column(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map((d) => SizedBox(
                          width: 24,
                          height: cellSize + gap,
                          child: Center(
                            child: Text(
                              d,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              // Grid columns
              ...List.generate(numWeeks, (col) {
                return Column(
                  children: List.generate(7, (row) {
                    final idx = col * 7 + row;
                    if (idx >= cells.length || cells[idx] == -1) {
                      return SizedBox(
                        width: cellSize + gap,
                        height: cellSize + gap,
                      );
                    }
                    final count = cells[idx];
                    final level = maxCount == 0
                        ? 0
                        : ((count / maxCount) * 4).ceil().clamp(0, 4);
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.all(gap / 2),
                      decoration: BoxDecoration(
                        color: AppColors.heatmapGradient[level],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.maxCount});
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(5, (i) => Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.heatmapGradient[i],
                borderRadius: BorderRadius.circular(3),
              ),
            )),
        const SizedBox(width: 6),
        Text(
          'More',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _Insights extends StatelessWidget {
  const _Insights({required this.points});
  final List<HeatmapPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    // Best day of week
    final dowTotals = List.filled(7, 0);
    final dowCounts = List.filled(7, 0);
    for (final p in points) {
      final dow = p.date.weekday - 1;
      dowTotals[dow] += p.count;
      dowCounts[dow]++;
    }
    final dowAverages = List.generate(7, (i) {
      return dowCounts[i] == 0 ? 0.0 : dowTotals[i] / dowCounts[i];
    });
    var bestDow = 0;
    for (var i = 1; i < 7; i++) {
      if (dowAverages[i] > dowAverages[bestDow]) bestDow = i;
    }
    const dowNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    // Most active month
    final monthTotals = <int, int>{};
    for (final p in points) {
      monthTotals[p.date.month] = (monthTotals[p.date.month] ?? 0) + p.count;
    }
    var bestMonth = monthTotals.entries.first;
    for (final entry in monthTotals.entries) {
      if (entry.value > bestMonth.value) bestMonth = entry;
    }
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.space8),
          _insightRow(
            Icons.today_rounded,
            'Your best day is ${dowNames[bestDow]}',
          ),
          const SizedBox(height: 6),
          _insightRow(
            Icons.calendar_month_rounded,
            'Most active in ${monthNames[bestMonth.key]}',
          ),
          const SizedBox(height: 6),
          _insightRow(
            Icons.check_circle_rounded,
            '${points.where((p) => p.count > 0).length} active days out of ${points.length}',
          ),
        ],
      ),
    );
  }

  Widget _insightRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accentGold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
