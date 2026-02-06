import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/hive_database.dart';

final databaseInitializationProvider = FutureProvider<void>((ref) async {
  await HiveDatabase.initialize();
});
