import 'package:flutter/material.dart';
import '../presentation/screens/analytics/analytics_dashboard_screen.dart';
import '../presentation/screens/habits/habits_list_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/scorecard/scorecard_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';

/// Named routes used across the app.
abstract class AppRoutes {
  static const String home = '/today';
  static const String scorecard = '/scorecard';
  static const String habits = '/habits';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
}

/// Route generation for top-level screen navigation.
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    case AppRoutes.scorecard:
      return MaterialPageRoute(builder: (_) => const ScorecardScreen());
    case AppRoutes.habits:
      return MaterialPageRoute(builder: (_) => const HabitsListScreen());
    case AppRoutes.analytics:
      return MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen());
    case AppRoutes.settings:
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    default:
      return MaterialPageRoute(builder: (_) => const HomeScreen());
  }
}
