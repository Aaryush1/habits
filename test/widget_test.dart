import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atomic_habits/app/app.dart';

void main() {
  testWidgets('App launches and shows Today screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AtomicHabitsApp(),
      ),
    );

    // Verify that the Today screen is shown (it's the first tab)
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Scorecard'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
