import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/completion.dart';
import 'completions_provider.dart';

final todayCompletionsProvider = Provider<AsyncValue<List<Completion>>>((ref) {
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  return ref.watch(completionsProvider(normalizedToday));
});
