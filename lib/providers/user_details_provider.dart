import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class UserDetailsProvider extends ChangeNotifier {
  OwnProfileBasic basic;

  void setUserDetails({@required OwnProfileBasic userDetails}) {
    basic = userDetails;
    Prefs().setOwnDetails(ownProfileBasicToJson(basic));
    notifyListeners();
  }

  void removeUser() {
    basic = OwnProfileBasic();
    Prefs().setOwnDetails('');
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    // Initialize [myUser]. We will configure it in the next few lines.
    basic = OwnProfileBasic();

    var savedUser = await Prefs().getOwnDetails();
    // Check if we have an user at all (json is not empty)
    if (savedUser != '') {
      basic = ownProfileBasicFromJson(savedUser);
      // Check if we have a valid API Key
      if (basic.userApiKeyValid) {
        // Call the API again to get the latest details (e.g. in case the
        // user has changed name or faction. Then save is as current user.
        // NOTE: calling basic to make things faster
        // Basic includes:
        // + Battle stats for TAC
        var apiVerify = await TornApiCaller.ownBasic(basic.userApiKey).getProfileBasic;

        if (apiVerify is OwnProfileBasic) {
          // Reassign from saved user, as these don't come with the API
          apiVerify.userApiKey = basic.userApiKey;
          apiVerify.userApiKeyValid = true;

          // Then recreate the basic model
          basic = apiVerify;

          Prefs().setOwnDetails(ownProfileBasicToJson(basic));

          // We delete this deprecated ApiKey from version 1.2.0 since we won't
          // need to use it in the future again
          Prefs().setApiKey('');
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
    var oldKeySave = await Prefs().getApiKey();
    if (oldKeySave != '') {
      var apiVerify = await TornApiCaller.ownExtended(oldKeySave).getProfileExtended;
      if (apiVerify is OwnProfileBasic) {
        apiVerify.userApiKey = oldKeySave;
        apiVerify.userApiKeyValid = true;
        basic = apiVerify;
        Prefs().setOwnDetails(ownProfileBasicToJson(basic));
        Prefs().setApiKey('');
      }
    }
  }
}
