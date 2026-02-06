import 'package:hive_flutter/hive_flutter.dart';
import '../../models/category_model.dart';
import '../../models/completion_model.dart';
import '../../models/habit_model.dart';
import '../../models/habit_stack_model.dart';

class HiveDatabase {
  static const String habitsBoxName = 'habits_box';
  static const String completionsBoxName = 'completions_box';
  static const String habitStacksBoxName = 'habit_stacks_box';
  static const String categoriesBoxName = 'categories_box';

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await Hive.initFlutter();
    _registerAdapters();
    try {
      await _openBoxes();
    } catch (e) {
      // If boxes are corrupted, delete and re-open them
      await Hive.deleteFromDisk();
      await Hive.initFlutter();
      _registerAdapters();
      await _openBoxes();
    }
    _isInitialized = true;
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CompletionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HabitStackModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
  }

  static Future<void> _openBoxes() async {
    await Future.wait([
      if (!Hive.isBoxOpen(habitsBoxName))
        Hive.openBox<HabitModel>(habitsBoxName),
      if (!Hive.isBoxOpen(completionsBoxName))
        Hive.openBox<CompletionModel>(completionsBoxName),
      if (!Hive.isBoxOpen(habitStacksBoxName))
        Hive.openBox<HabitStackModel>(habitStacksBoxName),
      if (!Hive.isBoxOpen(categoriesBoxName))
        Hive.openBox<CategoryModel>(categoriesBoxName),
    ]);
  }

  static Box<HabitModel> get habitsBox => Hive.box<HabitModel>(habitsBoxName);
  static Box<CompletionModel> get completionsBox =>
      Hive.box<CompletionModel>(completionsBoxName);
  static Box<HabitStackModel> get habitStacksBox =>
      Hive.box<HabitStackModel>(habitStacksBoxName);
  static Box<CategoryModel> get categoriesBox =>
      Hive.box<CategoryModel>(categoriesBoxName);
}
