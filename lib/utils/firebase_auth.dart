// Package imports:
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuth = _AuthService();

class _AuthService {
  final _firebaseAuth = FirebaseAuth.instance;

  Future signInAnon() async {
    try {
      UserCredential credential = await _firebaseAuth.signInAnonymously();
      User user = credential.user;
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future signOut() async {
    var user = _firebaseAuth.currentUser;
    user.delete();
  }

  Future getUID() async {
    try {
      var user = _firebaseAuth.currentUser;
      return user.uid;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future currentUser() async {
    var user = _firebaseAuth.currentUser;
    if (user == null) {
      // Some users reported issues with currentUsers not getting initialised
      await Future.delayed(Duration(seconds: 2));
      user = _firebaseAuth.currentUser;
    }
    return user;
  }
}
