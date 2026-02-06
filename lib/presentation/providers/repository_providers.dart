import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/completion_repository_impl.dart';
import '../../data/repositories/habit_repository_impl.dart';
import '../../data/repositories/stack_repository_impl.dart';
import '../../domain/repositories/completion_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/repositories/stack_repository.dart';
import 'database_provider.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  ref.watch(databaseInitializationProvider);
  return HabitRepositoryImpl();
});

final completionRepositoryProvider = Provider<CompletionRepository>((ref) {
  ref.watch(databaseInitializationProvider);
  return CompletionRepositoryImpl();
});

final stackRepositoryProvider = Provider<StackRepository>((ref) {
  ref.watch(databaseInitializationProvider);
  return StackRepositoryImpl();
});
