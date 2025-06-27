import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firebase_service.dart';
import 'settings_provider.dart';
import 'product_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> signInWithGoogle(
    SettingsProvider settingsProvider,
    ProductProvider productProvider,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      // Load user-specific settings and data
      await settingsProvider.loadUserSettings();
      await productProvider.loadUserData();

    } catch (e) {
      _error = 'Error signing in with Google: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut(
    SettingsProvider settingsProvider,
    ProductProvider productProvider,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Clear user data before signing out
      await productProvider.clearUserData();
      await settingsProvider.clearUserSettings();

      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;

    } catch (e) {
      _error = 'Error signing out: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 