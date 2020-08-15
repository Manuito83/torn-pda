import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
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

    var savedUser = await SharedPreferencesModel().getOwnDetails();
    // Check if we have an user at all (json is not empty)
    if (savedUser != '') {
      myUser = ownProfileModelFromJson(savedUser);
      // Check if we have a valid API Key
      if (myUser.userApiKeyValid) {
        // Call the API again to get the latest details (e.g. in case the
        // user has changed name or faction. Then save is as current user.
        var apiVerify =
            await TornApiCaller.ownProfile(myUser.userApiKey).getOwnProfile;
        if (apiVerify is OwnProfileModel) {
          apiVerify.userApiKey = myUser.userApiKey;
          apiVerify.userApiKeyValid = true;
          myUser = apiVerify;
          SharedPreferencesModel().setOwnDetails(ownProfileModelToJson(myUser));

          // We delete this deprecated ApiKey from version 1.2.0 since we won't
          // need to use it in the future again
          SharedPreferencesModel().setApiKey('');
        }
      }
    } else {
      // In v1.3.0 we deprecate getApiKey and setApiKey, but to avoid a logout
      // when transitioning to a newer version, we check if
      // there is still a key saved. If there is, we call with it
      // and erase it. Otherwise we do nothing else.
      await _tryWithDeprecatedSave();
    }

    notifyListeners();
  }

  Future _tryWithDeprecatedSave() async {
    var oldKeySave = await SharedPreferencesModel().getApiKey();
    if (oldKeySave != '') {
      var apiVerify =
          await TornApiCaller.ownProfile(oldKeySave).getOwnProfile;
      if (apiVerify is OwnProfileModel) {
        apiVerify.userApiKey = oldKeySave;
        apiVerify.userApiKeyValid = true;
        myUser = apiVerify;
        SharedPreferencesModel().setOwnDetails(ownProfileModelToJson(myUser));
        SharedPreferencesModel().setApiKey('');
      }
    }
  }
}
