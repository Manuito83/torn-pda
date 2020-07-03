import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuth = _AuthService();

class _AuthService {

  final _firebaseAuth = FirebaseAuth.instance;

  Future signInAnon() async {
    try {
      AuthResult result = await _firebaseAuth.signInAnonymously();
      FirebaseUser user = result.user;
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future getUID() async {
    try {
      var user = await _firebaseAuth.currentUser();
      return user.uid;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // TODO: sign out when API Key removed

}