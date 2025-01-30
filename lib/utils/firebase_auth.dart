// Package imports:
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

final firebaseAuth = AuthService();

class AuthService {
  final _firebaseAuth = FirebaseAuth.instance;

  /// TODO Note: as of OCT 2024, Windows does not have user persistence and new anon users are create
  /// each time we launch the app. Therefore, Auth/Firestore is not supported.
  Future signInAnon() async {
    if (Platform.isWindows) return null;
    try {
      final UserCredential credential = await _firebaseAuth.signInAnonymously();
      User? user = credential.user;
      return user;
    } catch (e) {
      log(e.toString());
      return null;
    }
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
