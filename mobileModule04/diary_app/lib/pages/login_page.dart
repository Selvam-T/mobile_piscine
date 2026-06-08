import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _pageBackground = Color(0xFFF2FAFE);
  static const Color _diaryBlue = Color(0xFF079FE3);

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
      final UserCredential credential = await signIn();
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
    } on FirebaseAuthException catch (error) {
      _showError(_authErrorMessage(error));
    } catch (error) {
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
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using another sign-in method.';
      case 'cancelled-popup-request':
      case 'popup-closed-by-user':
        return 'Sign in was cancelled.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';
      case 'popup-blocked':
        return 'The sign-in popup was blocked. Allow popups for this site and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return error.message ?? 'Authentication failed. Code: ${error.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(title: const Text('Login')),
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
                    height: 352,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  _AuthButton(
                    label: 'Login with Google',
                    iconAsset: 'assets/icons/google.png',
                    color: _diaryBlue,
                    isLoading: _activeProvider == 'google',
                    isDisabled: _isLoading,
                    onPressed: _signInWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  _AuthButton(
                    label: 'Login with GitHub',
                    iconAsset: 'assets/icons/github.png',
                    color: _diaryBlue,
                    isLoading: _activeProvider == 'github',
                    isDisabled: _isLoading,
                    onPressed: _signInWithGitHub,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
            side: BorderSide(color: color),
            backgroundColor: Colors.white,
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
