import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google + Firebase Auth. Prefer real Google identity over anonymous.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleReady = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn =>
      currentUser != null && !(currentUser?.isAnonymous ?? true);

  /// iOS/macOS OAuth client from GoogleService-Info.plist.
  static const macOsClientId =
      '273656560091-35sbjjsjpp5r6vglpsld1002migoegd7.apps.googleusercontent.com';

  /// Web client ID used as [serverClientId] so Firebase gets a valid idToken.
  static const webClientId =
      '273656560091-11s10n56fa0naj0merl0jbuvt5vhu0rp.apps.googleusercontent.com';

  Future<void> initializeGoogleSignIn() async {
    if (kIsWeb || _googleReady) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.macOS ||
                defaultTargetPlatform == TargetPlatform.iOS
            ? macOsClientId
            : null,
        serverClientId: webClientId,
      );
      _googleReady = true;
    } catch (e, s) {
      developer.log(
        'GoogleSignIn.initialize failed',
        name: 'notebook_pro.auth',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    await initializeGoogleSignIn();

    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an idToken.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final current = _auth.currentUser;

    // Prefer linking anonymous → Google so the same UID keeps cloud data.
    if (current != null && current.isAnonymous) {
      try {
        return await current.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use' ||
            e.code == 'provider-already-linked') {
          return _auth.signInWithCredential(credential);
        }
        rethrow;
      }
    }

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      if (_googleReady) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // Ignore Google sign-out failures; still clear Firebase session.
    }
    await _auth.signOut();
  }
}
