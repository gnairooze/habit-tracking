import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracking/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts with the bottom navigation bar
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that we have the Habits tab
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });
}
