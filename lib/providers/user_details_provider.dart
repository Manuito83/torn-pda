import 'package:flutter/material.dart';
import 'package:torn_pda/models/user_details_model.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class UserDetailsProvider extends ChangeNotifier {
  UserDetailsModel myUser;

  void setUserDetails({@required UserDetailsModel userDetails}) {
    myUser = userDetails;
    SharedPreferencesModel().setOwnDetails(userDetailsModelToJson(myUser));
    notifyListeners();
  }

  void removeUser() {
    myUser = UserDetailsModel();
    SharedPreferencesModel().setOwnDetails('');
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    // Initialize [myUser]. We will configure it in the next few lines.
    myUser = UserDetailsModel();

    var savedUser = await SharedPreferencesModel().getOwnDetails();
    // Check if we have an user at all (json is not empty)
    if (savedUser != '') {
      myUser = userDetailsModelFromJson(savedUser);
      // Check if we have a valid API Key
      if (myUser.userApiKeyValid) {
        // Call the API again to get the latest details (e.g. in case the
        // user has changed name or faction. Then save is as current user.
        var apiVerify =
            await TornApiCaller.userDetails(myUser.userApiKey).getUserDetails;
        if (apiVerify is UserDetailsModel) {
          apiVerify.userApiKey = myUser.userApiKey;
          apiVerify.userApiKeyValid = true;
          myUser = apiVerify;
          SharedPreferencesModel().setOwnDetails(userDetailsModelToJson(myUser));

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
          await TornApiCaller.userDetails(oldKeySave).getUserDetails;
      if (apiVerify is UserDetailsModel) {
        apiVerify.userApiKey = oldKeySave;
        apiVerify.userApiKeyValid = true;
        myUser = apiVerify;
        SharedPreferencesModel().setOwnDetails(userDetailsModelToJson(myUser));
        SharedPreferencesModel().setApiKey('');
      }
    }
  }
}
