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
        // Matching the warm, earthy aesthetic from your mockup image
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFD2C4BE),
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
  // String variables to keep track of the text field states
  String expression = "0";
  String result = "0";

  // Function to handle button presses and log to the debug console
  void _onButtonPressed(String value) {
    debugPrint("button pressed:$value");

    // Future state management logic will update the UI here using setState()
    setState(() {
      expression = "0";
      result = "0";
    });
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
        backgroundColor: const Color(0xFF9E847A),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
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
                    Text(expression, style: displayTextStyle),
                    const SizedBox(height: 8),
                    Text(result, style: displayTextStyle),
                  ],
                ),
              ),
            ),

            // Child 2: The Grid container containing 5 columns and 4 rows
            Expanded(
              flex: 5, // Allocation of screen space for the keyboard
              child: Container(
                padding: const EdgeInsets.all(buttonSpacing),
                color: const Color(0xFFAB958C),
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
                            decoration: BoxDecoration(
                              color: const Color(0xFFAB958C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                buttonText,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  // Color logic matching your mockup text elements
                                  color:
                                      (buttonText == 'C' || buttonText == 'AC')
                                      ? Colors.tealAccent[400]
                                      : const Color(0xFFEFE6E2),
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
    );
  }
}
