import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/color_utils.dart';
import '../../providers/habit_strength_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class ScoreHistoryScreen extends ConsumerStatefulWidget {
  const ScoreHistoryScreen({super.key});

  @override
  ConsumerState<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends ConsumerState<ScoreHistoryScreen> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final strengthAsync = ref.watch(overallStrengthProvider);
    final historyAsync = ref.watch(scoreHistoryProvider(_selectedDays));

    return Scaffold(
      appBar: AppBar(title: const Text('Score History')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          children: [
            // Overall score hero
            strengthAsync.when(
              loading: () => const LoadingIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (data) => Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: data.overallScore.clamp(0.0, 1.0),
                            strokeWidth: 10,
                            backgroundColor: AppColors.borderSubtle,
                            valueColor: AlwaysStoppedAnimation(
                              _scoreColor(data.overallScore),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(data.overallScore * 100).round()}%',
                                style: AppTypography.displayMedium,
                              ),
                              Text(
                                'Overall',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                  ],
                ),
              ),
            ),

            // Time range selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [30, 90, 365].map((days) {
                final selected = _selectedDays == days;
                final label =
                    days == 365 ? '1Y' : '${days}D';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDays = days),
                    selectedColor: AppColors.accentGold,
                    backgroundColor: AppColors.backgroundTertiary,
                    labelStyle: AppTypography.labelSmall.copyWith(
                      color: selected
                          ? AppColors.textInverse
                          : AppColors.textSecondary,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.space16),

            // Score history chart
            historyAsync.when(
              loading: () => const LoadingIndicator(message: 'Computing history'),
              error: (_, _) => const Text('Failed to load history'),
              data: (points) {
                if (points.isEmpty) {
                  return const Center(child: Text('No data'));
                }
                return SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 1,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 0.25,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.borderSubtle,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 0.25,
                            getTitlesWidget: (value, _) => Text(
                              '${(value * 100).round()}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            interval: (points.length / 4).ceilToDouble(),
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                DateFormat('M/d').format(points[idx].date),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: points
                              .asMap()
                              .entries
                              .map((e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value.score.clamp(0.0, 1.0),
                                  ))
                              .toList(),
                          isCurved: true,
                          color: AppColors.accentGold,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.accentGoldSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.space24),

            // Per-habit breakdown
            Text('Per-Habit Strength', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.space12),
            strengthAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (data) => Column(
                children: data.perHabit
                    .map((entry) => _HabitStrengthRow(entry: entry))
                    .toList(),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _HabitStrengthRow extends StatelessWidget {
  const _HabitStrengthRow({required this.entry});
  final HabitStrengthEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(entry.colorHex) ?? AppColors.accentGold;
    final pct = (entry.score * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.habitName,
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: entry.score.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.backgroundQuaternary,
                    valueColor: AlwaysStoppedAnimation(_scoreColor(entry.score)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$pct%',
            style: AppTypography.labelMedium.copyWith(
              color: _scoreColor(entry.score),
            ),
          ),
        ],
      ),
    );
  }
}

Color _scoreColor(double score) {
  if (score > 0.75) return AppColors.completionGreen;
  if (score > 0.5) return AppColors.accentGold;
  return AppColors.missedCoral;
}
