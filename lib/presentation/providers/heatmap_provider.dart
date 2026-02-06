import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/completion.dart';
import 'completions_provider.dart';
import 'repository_providers.dart';

class HeatmapQuery {
  const HeatmapQuery({
    required this.startDate,
    required this.endDate,
    this.habitId,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String? habitId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HeatmapQuery &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.habitId == habitId;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, habitId);
}

class HeatmapPoint {
  const HeatmapPoint({
    required this.date,
    required this.count,
  });

  final DateTime date;
  final int count;
}

final heatmapProvider =
    FutureProvider.family<List<HeatmapPoint>, HeatmapQuery>((ref, query) async {
  final completionRepository = ref.watch(completionRepositoryProvider);
  final revision = ref.watch(completionsRevisionProvider);
  final cacheKey =
      '${query.startDate.toIso8601String()}|${query.endDate.toIso8601String()}|${query.habitId ?? "all"}#$revision';

  final cached = _heatmapCache[cacheKey];
  if (cached != null) {
    return cached;
  }

  final completions = await completionRepository.getCompletionsForDateRange(
    query.startDate,
    query.endDate,
  );

  final dateCount = <DateTime, int>{};
  for (final completion in completions) {
    if (completion.completionType == HabitCompletionType.skipped) {
      continue;
    }
    if (query.habitId != null && completion.habitId != query.habitId) {
      continue;
    }
    final date = DateTime(
      completion.date.year,
      completion.date.month,
      completion.date.day,
    );
    dateCount[date] = (dateCount[date] ?? 0) + 1;
  }

  final result = <HeatmapPoint>[];
  var cursor = DateTime(
    query.startDate.year,
    query.startDate.month,
    query.startDate.day,
  );
  final end = DateTime(query.endDate.year, query.endDate.month, query.endDate.day);
  while (!cursor.isAfter(end)) {
    result.add(HeatmapPoint(date: cursor, count: dateCount[cursor] ?? 0));
    cursor = cursor.add(const Duration(days: 1));
  }

  _heatmapCache[cacheKey] = result;
  return result;
});

final Map<String, List<HeatmapPoint>> _heatmapCache = {};
