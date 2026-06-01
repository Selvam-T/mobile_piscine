import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medium_weather_app/main.dart';

void main() {
  testWidgets('Weather app shell updates tab content from search', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.near_me), findsOneWidget);
    expect(find.text('Currently'), findsWidgets);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Weekly'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Singapore');
    await tester.pump();

    expect(find.text('Currently\nSingapore'), findsOneWidget);
  });
}
