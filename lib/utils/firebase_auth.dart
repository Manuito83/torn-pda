// Package imports:
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuth = _AuthService();

class _AuthService {
  final _firebaseAuth = FirebaseAuth.instance;

  Future signInAnon() async {
    try {
      UserCredential credential = await _firebaseAuth.signInAnonymously();
      User? user = credential.user;
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future getUID() async {
    try {
      var user = _firebaseAuth.currentUser!;
      return user.uid;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
