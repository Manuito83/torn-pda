import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

// TODO: with this can remove the call to SharedPreferences in chains and travel

class UserDetails {
  String userApiKey = '';
  bool userApiKeyValid = false;

  String userId = '';
  String userName = '';
  String userFactionId = '';
}

class UserDetailsProvider extends ChangeNotifier {
  var myUser = UserDetails();

  void setUserDetails({@required UserDetails userDetails}) {
    myUser = userDetails;

    // TODO: save whole object
    SharedPreferencesModel().setApiKey(myUser.userApiKey);

    notifyListeners();
  }

  void removeUser() {
    myUser = UserDetails();

    // TODO: save whole object
    SharedPreferencesModel().setApiKey('');

    notifyListeners();
  }

  Future<void> loadPreferences() async {
    myUser.userApiKey = await SharedPreferencesModel().getApiKey();
    myUser.userApiKey == ''
        ? myUser.userApiKeyValid = false
        : myUser.userApiKeyValid = true;
    notifyListeners();
  }
}
