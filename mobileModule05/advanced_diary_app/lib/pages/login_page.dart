import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _pageBackground = Color(0xFF292929);
  static const Color _barBlue = Color(0xFF173865);
  static const Color _diaryTeal = Color(0xFF79CBC8);

  final AuthService _authService = AuthService();
  String? _activeProvider;
  String? _errorMessage;

  bool get _isLoading => _activeProvider != null;

  Future<void> _signInWithGoogle() async {
    await _signIn('google', _authService.signInWithGoogle);
  }

  Future<void> _signInWithGitHub() async {
    await _signIn('github', _authService.signInWithGitHub);
  }

  Future<void> _signIn(
    String provider,
    Future<UserCredential> Function() signIn,
  ) async {
    setState(() {
      _activeProvider = provider;
      _errorMessage = null;
    });

    try {
      final UserCredential credential = await signIn().timeout(
        const Duration(minutes: 2),
      );
      final String label =
          credential.user?.displayName ??
          credential.user?.email ??
          'Signed in successfully';

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(label)));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on TimeoutException {
      _showError(
        'Login timed out. Please try again and complete the sign-in window.',
      );
    } on FirebaseAuthException catch (error) {
      debugPrint('Auth error provider: $provider');
      debugPrint('Auth error code: ${error.code}');
      debugPrint('Auth error email: ${error.email}');
      debugPrint('Auth error message: ${error.message}');
      debugPrint('Auth credential provider: ${error.credential?.providerId}');
      _showError(_authErrorMessage(error));
    } catch (error) {
      debugPrint('Sign-in failed for $provider: $error');
      _showError('Authentication failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _activeProvider = null;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
    });
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return error.code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _barBlue,
        foregroundColor: Colors.white,
        title: const Text('Login'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
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
                  Text(
                    'Welcome.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Choose a login method.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _diaryTeal,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 56),
                  _AuthButton(
                    label: 'Login with Google',
                    iconAsset: 'assets/icons/google.png',
                    color: _diaryTeal,
                    isLoading: _activeProvider == 'google',
                    isDisabled: _isLoading,
                    onPressed: _signInWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  _AuthButton(
                    label: 'Login with GitHub',
                    iconAsset: 'assets/icons/github.png',
                    color: _diaryTeal,
                    isLoading: _activeProvider == 'github',
                    isDisabled: _isLoading,
                    onPressed: _signInWithGitHub,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFFB4AB)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.iconAsset,
    required this.color,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final String iconAsset;
  final Color color;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 52,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            disabledForegroundColor: color,
            side: BorderSide(color: color, width: 2),
            disabledBackgroundColor: const Color(0xFF303030),
            backgroundColor: const Color(0xFF303030),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: isDisabled ? null : onPressed,
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Image.asset(
                  iconAsset,
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
          label: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
