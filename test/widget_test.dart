import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whichinternationalday/main.dart';

void main() {
  testWidgets('App navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());
    
    // Wait for localizations
    await tester.pumpAndSettle();

    // Verify that the schedule page is shown first.
    // Note: TableCalendar might take some time or layout, but the AppBar title should be there.
    expect(find.text('Calendrier des Journées'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);

    // Tap on the Quiz icon.
    await tester.tap(find.byIcon(Icons.quiz));
    await tester.pumpAndSettle();

    // Verify that the quiz page selection is shown.
    expect(find.text('Sélectionner le mode de jeu'), findsOneWidget);

    // Tap on the Settings icon.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify that the settings page is shown.
    expect(find.text('Mode Sombre'), findsOneWidget);
    expect(find.text('Rappel Quotidien'), findsOneWidget);
  });
}
