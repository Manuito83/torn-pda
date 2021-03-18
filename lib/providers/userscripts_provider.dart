import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/models/userscript_model.dart';

class UserScriptsProvider extends ChangeNotifier {
  List<UserScriptModel> _userScriptList = <UserScriptModel>[];
  List<UserScriptModel> get userScriptList => _userScriptList;

  var _userScriptsEnabled = true;
  bool get userScriptsEnabled => _userScriptsEnabled;
  set setUserScriptsEnabled(bool value) {
    _userScriptsEnabled = value;
    _saveSettingsSharedPrefs();
    notifyListeners();
  }

  UnmodifiableListView<UserScript> getSources() {
    var scriptList = <UserScript>[];
    for (var script in _userScriptList) {
      scriptList.add(
        UserScript(
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          source: script.source,
        ),
      );
    }
    return UnmodifiableListView<UserScript>(scriptList);
  }

  void addUserScript(String name, String source) {
    var newScript = UserScriptModel()
      ..enabled = true
      ..name = name
      ..source = source;
    userScriptList.add(newScript);
    notifyListeners();
    _saveSettingsSharedPrefs();
  }

  void updateUserScript(
      UserScriptModel editedModel, String name, String source) {
    for (var script in userScriptList) {
      if (script == editedModel) {
        script.name = name;
        script.source = source;
        break;
      }
    }
    notifyListeners();
    _saveSettingsSharedPrefs();
  }

  void removeUserScript(UserScriptModel removedModel) {
    _userScriptList.remove(removedModel);
    notifyListeners();
    _saveSettingsSharedPrefs();
  }

  void changeUserScriptEnabled(UserScriptModel changedModel, bool enabled) {
    for (var script in userScriptList) {
      if (script == changedModel) {
        script.enabled = enabled;
        break;
      }
    }
    notifyListeners();
    _saveSettingsSharedPrefs();
  }

  void wipe() {
    _userScriptList.clear();
    notifyListeners();
    _saveSettingsSharedPrefs();
  }

  void _saveSettingsSharedPrefs() {
    var saveString = json.encode(_userScriptList);
    SharedPreferencesModel().setUserScriptsList(saveString);
  }

  Future<void> loadPreferences() async {
    var savedScripts = await SharedPreferencesModel().getUserScriptsList();
    if (savedScripts.isNotEmpty) {
      var decoded = json.decode(savedScripts);
      for (var dec in decoded) {
        _userScriptList.add(UserScriptModel.fromJson(dec));
      }
    }
    notifyListeners();
  }
}
