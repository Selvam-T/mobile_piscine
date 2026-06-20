import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color.fromARGB(255, 138, 102, 87),
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const double _maxResultMagnitude = 1000000000000;
  static const String _overflowResultText = "Too large";
  static const String _errorResultText = "Error";

  // String variables to keep track of the text field states
  String expression = "0";
  String result = "0";
  bool _lastButtonWasEquals = false;

  // Function to handle button presses and log to the debug console
  void _onButtonPressed(String value) {
    debugPrint("button pressed:$value");

    setState(() {
      if (value == "AC") {
        expression = "0";
        result = "0";
        _lastButtonWasEquals = false;
      } else if (value == "C") {
        if (expression.length > 1) {
          expression = expression.substring(0, expression.length - 1);
        } else {
          expression = "0";
        }
        _lastButtonWasEquals = false;
      } else if (value == "=") {
        result = _calculateResult(expression);
        _lastButtonWasEquals = true;
      } else if (value == ".") {
        _appendDecimalPoint();
        _lastButtonWasEquals = false;
      } else if (_isOperator(value)) {
        _appendOperator(value);
        _lastButtonWasEquals = false;
      } else {
        _appendNumber(value);
        _lastButtonWasEquals = false;
      }
    });
  }

  void _appendNumber(String value) {
    if (_lastButtonWasEquals) {
      expression = value == "00" ? "0" : value;
      return;
    }

    if (expression == "0") {
      expression = value == "00" ? "0" : value;
      return;
    }

    expression += value;
  }

  void _appendDecimalPoint() {
    if (_lastButtonWasEquals) {
      expression = "0.";
      return;
    }

    if (_endsWithUnaryMinus()) {
      expression += "0.";
      return;
    }

    if (_isBinaryOperatorAtEnd()) {
      expression += "0.";
      return;
    }

    final int lastOperatorIndex = _lastBinaryOperatorIndex(expression);
    final String currentNumber = expression.substring(lastOperatorIndex + 1);

    if (currentNumber.contains(".")) {
      return;
    }

    expression += expression == "0" ? "." : ".";
  }

  void _appendOperator(String value) {
    if (_lastButtonWasEquals) {
      expression = _canReuseResult() ? "$result$value" : "0$value";
      return;
    }

    if (value == "-" && _canStartNegativeNumber()) {
      expression = expression == "0" ? "-" : "$expression-";
      return;
    }

    if (_endsWithUnaryMinus()) {
      _replacePendingNegativeSign(value);
      return;
    }

    if (_isBinaryOperatorAtEnd()) {
      expression = expression.substring(0, expression.length - 1) + value;
      return;
    }

    expression += value;
  }

  String _calculateResult(String input) {
    final String cleanedInput = _trimIncompleteExpression(input);

    if (cleanedInput.isEmpty) {
      return "0";
    }

    final List<String>? tokens = _tokenize(cleanedInput);

    if (tokens == null || tokens.isEmpty) {
      return "0";
    }

    final List<String> reducedTokens = <String>[tokens.first];

    for (int index = 1; index < tokens.length; index += 2) {
      if (index + 1 >= tokens.length) {
        break;
      }

      final String operator = tokens[index];
      final String nextValue = tokens[index + 1];

      if (operator == "*" || operator == "/") {
        final double leftValue = double.parse(reducedTokens.removeLast());
        final double rightValue = double.parse(nextValue);

        if (operator == "/" && rightValue == 0) {
          return _errorResultText;
        }

        final double calculatedValue = operator == "*"
            ? leftValue * rightValue
            : leftValue / rightValue;
        if (_isTooLarge(calculatedValue)) {
          return _overflowResultText;
        }

        reducedTokens.add(calculatedValue.toString());
      } else {
        reducedTokens.add(operator);
        reducedTokens.add(nextValue);
      }
    }

    double calculatedResult = double.parse(reducedTokens.first);

    for (int index = 1; index < reducedTokens.length; index += 2) {
      final String operator = reducedTokens[index];
      final double nextValue = double.parse(reducedTokens[index + 1]);

      calculatedResult = operator == "+"
          ? calculatedResult + nextValue
          : calculatedResult - nextValue;

      if (_isTooLarge(calculatedResult)) {
        return _overflowResultText;
      }
    }

    return _formatResult(calculatedResult);
  }

  String _formatResult(double value) {
    if (_isTooLarge(value)) {
      return _overflowResultText;
    }

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(10)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  bool _isTooLarge(double value) {
    return !value.isFinite || value.abs() > _maxResultMagnitude;
  }

  bool _canReuseResult() {
    return result != _errorResultText && result != _overflowResultText;
  }

  bool _isOperator(String value) {
    return value == "+" || value == "-" || value == "*" || value == "/";
  }

  bool _isBinaryOperatorAtEnd() {
    if (expression.isEmpty || expression == "-") {
      return false;
    }

    final String lastCharacter = expression[expression.length - 1];
    return _isOperator(lastCharacter) && !_endsWithUnaryMinus();
  }

  bool _canStartNegativeNumber() {
    if (expression == "0") {
      return true;
    }

    return expression.isNotEmpty &&
        _isOperator(expression[expression.length - 1]) &&
        !_endsWithUnaryMinus();
  }

  bool _endsWithUnaryMinus() {
    if (!expression.endsWith("-")) {
      return false;
    }

    if (expression.length == 1) {
      return true;
    }

    return _isOperator(expression[expression.length - 2]);
  }

  void _replacePendingNegativeSign(String value) {
    final String withoutNegativeSign = expression.substring(
      0,
      expression.length - 1,
    );

    if (withoutNegativeSign.isEmpty) {
      expression = "0$value";
      return;
    }

    if (_isOperator(withoutNegativeSign[withoutNegativeSign.length - 1])) {
      expression =
          withoutNegativeSign.substring(0, withoutNegativeSign.length - 1) +
          value;
      return;
    }

    expression = "$withoutNegativeSign$value";
  }

  int _lastBinaryOperatorIndex(String input) {
    for (int index = input.length - 1; index >= 0; index -= 1) {
      final String character = input[index];

      if (!_isOperator(character)) {
        continue;
      }

      final bool isUnaryMinus =
          character == "-" && (index == 0 || _isOperator(input[index - 1]));

      if (!isUnaryMinus) {
        return index;
      }
    }

    return -1;
  }

  String _trimIncompleteExpression(String input) {
    String cleanedInput = input;

    while (cleanedInput.isNotEmpty) {
      final String lastCharacter = cleanedInput[cleanedInput.length - 1];

      if (!_isOperator(lastCharacter)) {
        return cleanedInput;
      }

      cleanedInput = cleanedInput.substring(0, cleanedInput.length - 1);
    }

    return cleanedInput;
  }

  List<String>? _tokenize(String input) {
    final List<String> tokens = <String>[];
    int index = 0;
    bool expectingNumber = true;

    while (index < input.length) {
      final String character = input[index];
      final bool isNegativeNumber =
          character == "-" &&
          expectingNumber &&
          index + 1 < input.length &&
          (_isDigit(input[index + 1]) || input[index + 1] == ".");

      if (_isDigit(character) || character == "." || isNegativeNumber) {
        final int numberStartIndex = index;
        bool hasDecimalPoint = false;

        if (isNegativeNumber) {
          index += 1;
        }

        while (index < input.length &&
            (_isDigit(input[index]) || input[index] == ".")) {
          if (input[index] == ".") {
            if (hasDecimalPoint) {
              return null;
            }

            hasDecimalPoint = true;
          }

          index += 1;
        }

        tokens.add(input.substring(numberStartIndex, index));
        expectingNumber = false;
        continue;
      }

      if (_isOperator(character) && !expectingNumber) {
        tokens.add(character);
        expectingNumber = true;
        index += 1;
        continue;
      }

      return null;
    }

    return tokens;
  }

  bool _isDigit(String value) {
    return RegExp(r'^\d$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    // List of keys configured exactly for a 5-column, 4-row grid layout
    const int buttonColumnCount = 5;
    const double buttonSpacing = 8.0;
    final List<String> buttons = [
      '7',
      '8',
      '9',
      'C',
      'AC',
      '4',
      '5',
      '6',
      '+',
      '-',
      '1',
      '2',
      '3',
      '*',
      '/',
      '0',
      '.',
      '00',
      '=',
      '',
    ];

    const displayTextStyle = TextStyle(fontSize: 32, color: Color(0xFF5A4D46));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: const Color.fromARGB(255, 138, 102, 87),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: Container(
          width: double.infinity,
          color: const Color(0xFFD2C4BE),
          child: Column(
            children: [
              // Child 1: Container holding the vertically aligned display text fields
              Expanded(
                flex: 4, // Allocation of screen space for the display area
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  alignment: Alignment.bottomRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        expression,
                        key: const Key('expression-display'),
                        style: displayTextStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result,
                        key: const Key('result-display'),
                        style: displayTextStyle,
                      ),
                    ],
                  ),
                ),
              ),

              // Child 2: The Grid container containing 5 columns and 4 rows
              Expanded(
                flex: 5, // Allocation of screen space for the keyboard
                child: Container(
                  padding: const EdgeInsets.all(buttonSpacing),
                  color: const Color.fromARGB(255, 138, 102, 87),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final int buttonRowCount =
                          (buttons.length / buttonColumnCount).ceil();
                      final double buttonWidth =
                          (constraints.maxWidth -
                              (buttonColumnCount - 1) * buttonSpacing) /
                          buttonColumnCount;
                      final double buttonHeight =
                          (constraints.maxHeight -
                              (buttonRowCount - 1) * buttonSpacing) /
                          buttonRowCount;

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: buttonColumnCount,
                          crossAxisSpacing: buttonSpacing,
                          mainAxisSpacing: buttonSpacing,
                          childAspectRatio: buttonWidth / buttonHeight,
                        ),
                        itemCount: buttons.length,
                        itemBuilder: (context, index) {
                          final String buttonText = buttons[index];

                          // Handle empty spacing element at the bottom right corner
                          if (buttonText.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return InkWell(
                            onTap: () => _onButtonPressed(buttonText),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 138, 102, 87),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  buttonText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w500,
                                    // Color logic matching your mockup text elements
                                    color:
                                        (_isOperator(buttonText) ||
                                            buttonText == '=')
                                        ? Colors.black
                                        : (buttonText == 'C' ||
                                              buttonText == 'AC')
                                        ? const Color.fromARGB(
                                            255,
                                            17,
                                            217,
                                            167,
                                          )
                                        : const Color.fromARGB(
                                            255,
                                            231,
                                            216,
                                            211,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
