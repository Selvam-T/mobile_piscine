import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_app/main.dart';

void main() {
  testWidgets('AC and C keep the expression display at zero', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tapButton(tester, '7');
    await tapButton(tester, 'AC');
    expect(displayText(tester, 'expression-display'), '0');

    await tapButton(tester, '8');
    await tapButton(tester, 'C');
    expect(displayText(tester, 'expression-display'), '0');
  });

  testWidgets('equals evaluates a simple expression', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tapButton(tester, '1');
    await tapButton(tester, '+');
    await tapButton(tester, '2');
    await tapButton(tester, '=');

    expect(displayText(tester, 'result-display'), '3');
  });

  testWidgets('decimal input starts with zero and allows one decimal point', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tapButton(tester, '.');
    await tapButton(tester, '5');
    await tapButton(tester, '.');

    expect(displayText(tester, 'expression-display'), '0.5');
  });

  testWidgets('operator after equals continues from the result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tapButton(tester, '6');
    await tapButton(tester, '6');
    await tapButton(tester, '6');
    await tapButton(tester, '+');
    await tapButton(tester, '3');
    await tapButton(tester, '=');
    expect(displayText(tester, 'result-display'), '669');

    await tapButton(tester, '/');
    await tapButton(tester, '1');
    expect(displayText(tester, 'expression-display'), '669/1');
    expect(displayText(tester, 'result-display'), '669');

    await tapButton(tester, '*');
    await tapButton(tester, '5');
    await tapButton(tester, '=');
    expect(displayText(tester, 'expression-display'), '669/1*5');
    expect(displayText(tester, 'result-display'), '3345');
  });

  testWidgets('minus can start a negative number', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tapButton(tester, '-');
    await tapButton(tester, '5');
    await tapButton(tester, '+');
    await tapButton(tester, '2');
    await tapButton(tester, '=');

    expect(displayText(tester, 'expression-display'), '-5+2');
    expect(displayText(tester, 'result-display'), '-3');
  });

  testWidgets('minus after an operator creates a negative operand', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tapButton(tester, '5');
    await tapButton(tester, '*');
    await tapButton(tester, '-');
    await tapButton(tester, '3');
    await tapButton(tester, '=');

    expect(displayText(tester, 'expression-display'), '5*-3');
    expect(displayText(tester, 'result-display'), '-15');
  });

  testWidgets('minus after minus subtracts a negative operand', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tapButton(tester, '5');
    await tapButton(tester, '-');
    await tapButton(tester, '-');
    await tapButton(tester, '3');
    await tapButton(tester, '=');

    expect(displayText(tester, 'expression-display'), '5--3');
    expect(displayText(tester, 'result-display'), '8');
  });

  testWidgets('minus after equals continues from the result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tapButton(tester, '6');
    await tapButton(tester, '+');
    await tapButton(tester, '2');
    await tapButton(tester, '=');
    await tapButton(tester, '-');

    expect(displayText(tester, 'expression-display'), '8-');
    expect(displayText(tester, 'result-display'), '8');
  });

  testWidgets('very large results show a clear overflow message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await enterText(tester, '999999999999');
    await tapButton(tester, '*');
    await tapButton(tester, '9');
    await tapButton(tester, '=');

    expect(displayText(tester, 'result-display'), 'Too large');
  });

  testWidgets('operator after overflow starts from zero', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await enterText(tester, '999999999999');
    await tapButton(tester, '*');
    await tapButton(tester, '9');
    await tapButton(tester, '=');
    await tapButton(tester, '+');

    expect(displayText(tester, 'expression-display'), '0+');
  });
}

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pump();
}

Future<void> enterText(WidgetTester tester, String text) async {
  for (final String character in text.split('')) {
    await tapButton(tester, character);
  }
}

String? displayText(WidgetTester tester, String keyName) {
  return tester.widget<Text>(find.byKey(Key(keyName))).data;
}
