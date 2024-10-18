// Package imports:
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

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
        return user!.uid;
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }
}
