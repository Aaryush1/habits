import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CompletionBarChart extends StatelessWidget {
  const CompletionBarChart({
    super.key,
    required this.values,
  });

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          barGroups: values
              .asMap()
              .entries
              .map(
                (entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      width: 14,
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.accentGold,
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
