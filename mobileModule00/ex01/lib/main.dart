// mod 0 ex01
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // multiple functions need to see isToggled, so define at class level
  bool isToggled = true;

  String toggleMsg() {
    final String msg1 = 'A simple text';
    final String msg2 = 'Hello World!';
    return (isToggled ? msg1 : msg2);
  }

  @override
  Widget build(BuildContext context) {
    final String message = 'Click me';

    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  toggleMsg(),
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // call setState by passing anonymous function that toggles
                  setState(() {
                    isToggled = !isToggled;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.deepPurpleAccent[200],
                  ),
                ),
              ),              
            ],
          ),
        ),
      ),
    );
  }

  void printButtonPressed() {
    debugPrint('Button Pressed');
  }

}
