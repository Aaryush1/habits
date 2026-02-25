import 'package:flutter/material.dart';
import '../presentation/screens/analytics/analytics_hub_screen.dart';
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

/// Shared fade + slide-up page transition used for pushed routes (detail
/// screens, drill-downs). Duration 350ms, slides up 6% from bottom.
Route<T> fadeSlideRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// Route generation for top-level screen navigation.
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return fadeSlideRoute((_) => const HomeScreen());
    case AppRoutes.scorecard:
      return fadeSlideRoute((_) => const ScorecardScreen());
    case AppRoutes.habits:
      return fadeSlideRoute((_) => const HabitsListScreen());
    case AppRoutes.analytics:
      return fadeSlideRoute((_) => const AnalyticsHubScreen());
    case AppRoutes.settings:
      return fadeSlideRoute((_) => const SettingsScreen());
    default:
      return fadeSlideRoute((_) => const HomeScreen());
  }
}
