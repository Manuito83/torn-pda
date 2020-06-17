import 'package:flutter/material.dart';
import 'package:torn_pda/models/own_profile_model.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class UserDetailsProvider extends ChangeNotifier {
  OwnProfileModel myUser;

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
    // Initialize [myUser]. We will configure it in the next few lines.
    myUser = OwnProfileModel();

    // Check if we have a saved user in SharedPreferences
    var savedUser = await SharedPreferencesModel().getOwnDetails();
    if (savedUser != '') {
      myUser = ownProfileModelFromJson(savedUser);
      // Saved user must have a valid API Key
      if (myUser.userApiKeyValid) {
        var apiVerify =
            await TornApiCaller.ownProfile(myUser.userApiKey).getOwnProfile;
        if (apiVerify is OwnProfileModel) {
          apiVerify.userApiKey = myUser.userApiKey;
          apiVerify.userApiKeyValid = true;
          myUser = apiVerify;

          SharedPreferencesModel().setApiKey('');
        }
      }
      // If the user is not valid, we just update two values in [myUser] to
      // indicate that no API key has been inserted
      else {
        myUser.userApiKey == ''
            ? myUser.userApiKeyValid = false
            : myUser.userApiKeyValid = true;
      }
    }
    // In v1.3.0 we deprecate getApiKey and setApiKey, but to avoid a logout
    // we check if there is still a save key. If there is, we call with it
    // and erase it. Otherwise we do nothing else.
    else {
      var oldKeySave = await SharedPreferencesModel().getApiKey();
      if (oldKeySave != '') {
        var apiVerify =
            await TornApiCaller.ownProfile(oldKeySave).getOwnProfile;
        if (apiVerify is OwnProfileModel) {
          myUser = apiVerify;
          SharedPreferencesModel().setApiKey('');
        }
      }
    }

    notifyListeners();

    // TODO: put here a async call without awaiting
  }
}
