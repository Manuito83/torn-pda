import 'package:flutter/material.dart';
import 'package:torn_pda/models/own_profile_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class UserDetailsProvider extends ChangeNotifier {
  var myUser = OwnProfileModel();

  void setUserDetails({@required OwnProfileModel userDetails}) {
    myUser = userDetails;
    SharedPreferencesModel().setOwnDetails(ownProfileModelToJson(myUser));
    notifyListeners();
  }

  void removeUser() {
    myUser = OwnProfileModel();
    SharedPreferencesModel().setOwnDetails('');
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    var savedUser = await SharedPreferencesModel().getOwnDetails();
    if (savedUser != '') {
      myUser = ownProfileModelFromJson(savedUser);
      myUser.userApiKey == ''
          ? myUser.userApiKeyValid = false
          : myUser.userApiKeyValid = true;
    }
    notifyListeners();

    // TODO: put here a async call without awaiting

  }
}
