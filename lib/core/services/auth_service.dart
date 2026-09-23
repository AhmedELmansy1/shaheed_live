import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [FirebaseAuth] singleton instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// StreamProvider that reactively tracks the Firebase Auth state.
///
/// Emits the current [User] on sign-in/sign-out events.
/// UI widgets watching this will rebuild automatically if the auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Convenience provider exposing the current Firebase uid (or null).
final currentUidProvider = Provider<String?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.whenOrNull(data: (user) => user?.uid);
});

/// Service responsible for managing Firebase Anonymous Authentication.
///
/// Design contract:
/// - Auth is strictly additive — the app must NEVER block on auth failures.
/// - If Firebase is unavailable (no internet on first launch, misconfigured),
///   the app continues fully functional using shared_preferences only.
class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  /// Returns the current uid if already signed in.
  String? get currentUid => _auth.currentUser?.uid;

  /// Ensures the user is anonymously authenticated.
  ///
  /// Returns the uid on success, or null on failure (logged, never thrown).
  Future<String?> ensureAuthenticated() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('[AuthService] Already authenticated: uid=${currentUser.uid}');
        return currentUser.uid;
      }

      debugPrint('[AuthService] No existing session — signing in anonymously...');
      final credential = await _auth.signInAnonymously();
      final uid = credential.user?.uid;
      debugPrint('[AuthService] Anonymous sign-in successful: uid=$uid');
      return uid;
    } catch (e) {
      debugPrint(
        '[AuthService] WARNING: Anonymous auth failed: $e. '
        'App will continue offline using shared_preferences only.',
      );
      return null;
    }
  }
}

/// Riverpod provider for [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});
