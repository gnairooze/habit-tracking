import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracking/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts with the home screen
    expect(find.text('My Habits'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify navigation tabs are present
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('Navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Test navigation to Alerts screen
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Alerts'), findsOneWidget);

    // Test navigation to Reports screen
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Reports'), findsOneWidget);

    // Test navigation back to Habits screen
    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    expect(find.text('My Habits'), findsOneWidget);
  });
}
