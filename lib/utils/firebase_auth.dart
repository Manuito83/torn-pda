// Package imports:
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

final firebaseAuth = AuthService();

class AuthService {
  final _firebaseAuth = FirebaseAuth.instance;

  /// TODO Note: as of OCT 2024, Windows does not have user persistence and new anon users are created
  /// each time we launch the app. Therefore, Auth/Firestore is not supported.
  Future<User?> signInAnon({bool isAppUpdate = false, int maxRetries = 3}) async {
    if (Platform.isWindows) return null;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        log("🔒 FirebaseAuth: Signing in anonymously (attempt $attempt/$maxRetries, app_update: $isAppUpdate)",
            name: "AUTH CHECKS");

        // For app updates, add a small delay before each attempt to ensure Firebase is ready
        if (isAppUpdate && attempt > 1) {
          final delayMs = attempt * 1000;
          log("🔒 FirebaseAuth: App update detected, adding ${delayMs}ms delay before attempt $attempt",
              name: "AUTH CHECKS");
          await Future.delayed(Duration(milliseconds: delayMs));
        }

        final UserCredential credential = await _firebaseAuth.signInAnonymously().timeout(const Duration(seconds: 15));

        User? user = credential.user;

        if (user != null) {
          log("🔒 FirebaseAuth: Anonymous sign-in successful on attempt $attempt. UID: ${user.uid}",
              name: "AUTH CHECKS");
          return user;
        } else {
          log("🔒 FirebaseAuth: Anonymous sign-in returned null user on attempt $attempt", name: "AUTH CHECKS");
          if (attempt == maxRetries) return null;
        }
      } catch (e) {
        log("🔒 FirebaseAuth: Anonymous sign-in failed on attempt $attempt: $e", name: "AUTH CHECKS");

        // Record to Crashlytics if this is the final attempt
        if (attempt == maxRetries) {
          FirebaseCrashlytics.instance.recordError(
            'Anonymous sign-in failed after $maxRetries attempts',
            StackTrace.current,
            reason: 'signInAnon failure',
            information: [
              'Error: $e',
              'App Update: $isAppUpdate',
              'Max Attempts: $maxRetries',
              'Platform: ${Platform.operatingSystem}',
            ],
          );
        }

        // Don't retry on certain critical errors
        if (e.toString().contains('network-request-failed') || e.toString().contains('too-many-requests')) {
          log("🔒 FirebaseAuth: Critical error detected, not retrying: $e", name: "AUTH CHECKS");
          return null;
        }

        // Return null on final attempt failure
        if (attempt == maxRetries) {
          return null;
        }

        // Short delay before retry (exponential)
        final delayMs = (attempt * 500);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    return null;
  }

  Future signOut() async {
    if (Platform.isWindows) return null;
    await FirebaseAuth.instance.signOut();
  }

  Future getUID() async {
    if (Platform.isWindows) return null;
    try {
      if (_firebaseAuth.currentUser != null) {
        final user = _firebaseAuth.currentUser;
        return user;
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.log("PDA Crash at GET UID. Error: $e. Stack: $stack");
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        information: [
          'Firebase Auth User: ${_firebaseAuth.currentUser}',
        ],
      );
    }
    return null;
  }
}
