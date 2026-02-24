import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../providers/weekly_trends_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class WeeklyTrendsScreen extends ConsumerWidget {
  const WeeklyTrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(weeklyTrendsProvider);
    final detailAsync = ref.watch(weekDayDetailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Trends')),
      body: SafeArea(
        child: trendsAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading trends'),
          error: (_, _) => const Center(child: Text('Failed to load')),
          data: (trends) => ListView(
            padding: const EdgeInsets.all(AppSpacing.space16),
            children: [
              // Week-over-week delta
              _DeltaHeader(trends: trends),
              const SizedBox(height: AppSpacing.space20),

              // Weekly comparison bar chart
              Text('Last 4 Weeks', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.space12),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
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
                            '${(value * 100).round()}%',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= trends.weeks.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              DateFormat('M/d')
                                  .format(trends.weeks[idx].weekStart),
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
                    barGroups: trends.weeks.asMap().entries.map((entry) {
                      final isLatest = entry.key == trends.weeks.length - 1;
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.completionRate,
                            width: 28,
                            borderRadius: BorderRadius.circular(6),
                            color: isLatest
                                ? AppColors.accentGold
                                : AppColors.backgroundQuaternary,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // Day-of-week heatmap
              Text('Day-of-Week Patterns', style: AppTypography.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Average completion rate by weekday across all time',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              _DayOfWeekHeatmap(rates: trends.dayOfWeekRates),
              const SizedBox(height: AppSpacing.space24),

              // This week detail
              Text('This Week', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.space12),
              detailAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, _) => const Text('Failed to load'),
                data: (details) => Column(
                  children: details
                      .map((d) => _DayDetailTile(detail: d))
                      .toList(),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeltaHeader extends StatelessWidget {
  const _DeltaHeader({required this.trends});
  final WeeklyTrends trends;

  @override
  Widget build(BuildContext context) {
    final thisWeek = trends.weeks.isNotEmpty ? trends.weeks.last : null;
    final rate = thisWeek?.completionRate ?? 0;
    final delta = trends.thisWeekDelta;
    final deltaPrefix = delta >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Week',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(rate * 100).round()}%',
                style: AppTypography.displayMedium,
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: delta >= 0
                  ? AppColors.completionGreenSubtle
                  : AppColors.missedCoralSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  delta >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 18,
                  color: delta >= 0
                      ? AppColors.completionGreen
                      : AppColors.missedCoral,
                ),
                const SizedBox(width: 4),
                Text(
                  '$deltaPrefix${(delta * 100).round()}%',
                  style: AppTypography.labelMedium.copyWith(
                    color: delta >= 0
                        ? AppColors.completionGreen
                        : AppColors.missedCoral,
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

class _DayOfWeekHeatmap extends StatelessWidget {
  const _DayOfWeekHeatmap({required this.rates});
  final List<double> rates;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: List.generate(7, (i) {
        final rate = i < rates.length ? rates[i] : 0.0;
        final level = (rate * 4).ceil().clamp(0, 4);

        return Expanded(
          child: Column(
            children: [
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.heatmapGradient[level],
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${(rate * 100).round()}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: level >= 2
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DayDetailTile extends StatelessWidget {
  const _DayDetailTile({required this.detail});
  final WeekDayDetail detail;

  @override
  Widget build(BuildContext context) {
    final done = detail.completedHabits.length;
    final total = detail.totalScheduled;
    final rate = total == 0 ? 0.0 : done / total;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space8),
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(detail.date),
                style: AppTypography.labelMedium,
              ),
              const Spacer(),
              Text(
                '$done/$total',
                style: AppTypography.labelMedium.copyWith(
                  color: rate >= 0.8
                      ? AppColors.completionGreen
                      : rate >= 0.5
                          ? AppColors.accentGold
                          : AppColors.missedCoral,
                ),
              ),
            ],
          ),
          if (detail.missedHabits.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Missed: ${detail.missedHabits.join(", ")}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.missedCoral,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
