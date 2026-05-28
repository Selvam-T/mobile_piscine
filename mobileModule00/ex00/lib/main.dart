// mod 0 ex00

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// main()
// runApp()
// MyApp widget
// build()
// screen UI

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
                // Child 1. I place text in container to style around text
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent[200],
                  //border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'A simple text',
                  style: TextStyle(fontSize: 24, color: Colors.black),
                ),
              ),
              ElevatedButton(
                // Child 2
                onPressed: printButtonPressed,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: Text(
                  message,
                  style: TextStyle(color: Colors.deepPurpleAccent[200]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void printButtonPressed() {
    debugPrint('Button pressed');
  }
}

// Scaffold --> QMainWindow
//  body     --> QWidget
//   Center  --> QVBoxLayout with setAlignment(Qt.AlignCenter)
//    Column --> QVBoxLayout
//     Text --> QLabel
//     ElevatedButton  --> QPushButton
