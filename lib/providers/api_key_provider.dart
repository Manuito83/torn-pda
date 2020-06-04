import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';


// TODO: with this new provider, we can remove the call to SharedPreferences in chains and travel

class ApiKeyProvider extends ChangeNotifier {
  String apiKey;
  bool apiKeyValid;

  /// Pass '' if just trying to remove the api key
  void setApiKey ({@required String newApiKey}) {
    apiKey = newApiKey;
    newApiKey == '' ? apiKeyValid = false : apiKeyValid = true;
    SharedPreferencesModel().setApiKey(newApiKey);
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    apiKey = await SharedPreferencesModel().getApiKey();
    apiKey == '' ? apiKeyValid = false : apiKeyValid = true;
    notifyListeners();
  }

}