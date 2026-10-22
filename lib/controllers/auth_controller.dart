import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sarthi_pilot/models/driver_user.dart';

/// Controller handling driver Firebase Authentication state and validation logic (MVC).
class AuthController extends ChangeNotifier {
  AuthController({FirebaseAuth? auth}) : _customAuth = auth;

  final FirebaseAuth? _customAuth;

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  DriverUser? _currentUser;
  DriverUser? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Validates email field input.
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password field input.
  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Signs in driver with Firebase email and password.
  Future<DriverUser?> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();

    try {
      final auth = _auth;
      if (auth == null) {
        // Safe development/test fallback when native Firebase app is not attached
        await Future<void>.delayed(const Duration(milliseconds: 400));
        _currentUser = DriverUser(
          uid: 'DRV-TEST-${DateTime.now().millisecondsSinceEpoch}',
          email: cleanEmail,
          name: cleanEmail.split('@').first.replaceAll('.', ' ').toUpperCase(),
        );
        return _currentUser;
      }

      final userCredential = await auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        _currentUser = DriverUser(
          uid: user.uid,
          email: user.email ?? cleanEmail,
          name: user.displayName ??
              cleanEmail.split('@').first.replaceAll('.', ' ').toUpperCase(),
        );
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code, e.message);
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Authentication failed. Please check network connection.';
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentUser;
  }

  /// Registers a new driver with Firebase email and password.
  Future<DriverUser?> register({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();

    try {
      final auth = _auth;
      if (auth == null) {
        // Safe development/test fallback when native Firebase app is not attached
        await Future<void>.delayed(const Duration(milliseconds: 400));
        _currentUser = DriverUser(
          uid: 'DRV-TEST-${DateTime.now().millisecondsSinceEpoch}',
          email: cleanEmail,
          name: cleanEmail.split('@').first.replaceAll('.', ' ').toUpperCase(),
        );
        return _currentUser;
      }

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        _currentUser = DriverUser(
          uid: user.uid,
          email: user.email ?? cleanEmail,
          name: user.displayName ??
              cleanEmail.split('@').first.replaceAll('.', ' ').toUpperCase(),
        );
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code, e.message);
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentUser;
  }

  /// Signs the driver out from Firebase.
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    _currentUser = null;
    notifyListeners();
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _mapFirebaseError(String code, String? defaultMessage) {
    switch (code) {
      case 'user-not-found':
        return 'No driver account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please verify and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'user-disabled':
        return 'This driver account has been disabled by admin.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      default:
        return defaultMessage ?? 'Authentication error occurred ($code).';
    }
  }
}
