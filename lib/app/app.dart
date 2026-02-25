import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../presentation/providers/notification_provider.dart';
import 'router.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/analytics/analytics_hub_screen.dart';
import '../presentation/screens/habits/habits_list_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/widgets/navigation/bottom_nav_bar.dart';

/// Main application widget.
class AtomicHabitsApp extends ConsumerWidget {
  const AtomicHabitsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigatorKey = ref.watch(notificationNavigatorKeyProvider);
    return MaterialApp(
      title: 'Atomic Habits',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,
      onGenerateRoute: onGenerateRoute,
      home: const AppShell(),
    );
  }
}

/// App shell with bottom navigation.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    HabitsListScreen(),
    AnalyticsHubScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        // Key must change when the selected tab changes so AnimatedSwitcher
        // actually triggers.
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
