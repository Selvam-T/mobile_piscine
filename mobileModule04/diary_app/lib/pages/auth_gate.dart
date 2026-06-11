import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'profile_page.dart';
import 'welcome_page.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key, AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = snapshot.data;

        if (user == null) {
          return const WelcomePage();
        }

        return ProfilePage(user: user);
      },
    );
  }
}
