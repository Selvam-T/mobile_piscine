import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _isGoogleSignInInitialized = false;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');

    if (kIsWeb) {
      return _firebaseAuth.signInWithPopup(googleProvider);
    }

    await _initializeGoogleSignIn();

    final GoogleSignInAccount googleAccount = await _googleSignIn
        .authenticate();
    final GoogleSignInAuthentication googleAuth = googleAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithGitHub() async {
    final GithubAuthProvider githubProvider = GithubAuthProvider();
    githubProvider.addScope('user:email');

    if (kIsWeb) {
      return _firebaseAuth.signInWithPopup(githubProvider);
    }

    return _firebaseAuth.signInWithProvider(githubProvider);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    if (_isGoogleSignInInitialized) {
      await _googleSignIn.signOut();
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleSignInInitialized) {
      return;
    }

    await _googleSignIn.initialize();
    _isGoogleSignInInitialized = true;
  }
}
