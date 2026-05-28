import 'package:flutter_test/flutter_test.dart';

import 'package:ex00/main.dart';

void main() {
  testWidgets('shows centered text and button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('A simple text'), findsOneWidget);
    expect(find.text('Click me'), findsOneWidget);

    await tester.tap(find.text('Click me'));
    await tester.pump();

    expect(find.text('A simple text'), findsOneWidget);
    expect(find.text('Click me'), findsOneWidget);
  });
}
