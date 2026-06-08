import 'package:flutter/material.dart';

import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const Color _pageBackground = Color(0xFFF2FAFE);
  static const Color _diaryBlue = Color(0xFF079FE3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/diary.png',
                    height: 384,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _diaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
