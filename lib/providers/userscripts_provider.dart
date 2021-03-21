import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/utils/userscript_examples.dart';

class UserScriptChanges {
  UnmodifiableListView<UserScript> scriptsToAdd;
  List<String> scriptsToRemove;
}

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

  UnmodifiableListView<UserScript> getContinuousSources({
    @required String apiKey,
  }) {
    var scriptList = <UserScript>[];
    if (_userScriptsEnabled) {
      for (var script in _userScriptList) {
        if (script.enabled && script.urls.isEmpty) {
          scriptList.add(
            UserScript(
              groupName: script.name,
              injectionTime: Platform.isAndroid
                  ? UserScriptInjectionTime.AT_DOCUMENT_START
                  : UserScriptInjectionTime.AT_DOCUMENT_END,
              source: script.source.replaceAll("###PDA-APIKEY###", apiKey),
            ),
          );
        }
      }
    }
    return UnmodifiableListView<UserScript>(scriptList);
  }

  UserScriptChanges getCondSources({
    @required String url,
    @required String apiKey,
  }) {
    var scriptListToAdd = <UserScript>[];
    var scriptListToRemove = <String>[];
    if (_userScriptsEnabled) {
      for (var script in _userScriptList) {
        if (script.enabled) {
          if (script.urls.isNotEmpty) {
            var found = false;
            for (var u in script.urls) {
              if (url.contains(u)) {
                found = true;
                scriptListToAdd.add(
                  UserScript(
                    groupName: script.name,
                    injectionTime: Platform.isAndroid
                        ? UserScriptInjectionTime.AT_DOCUMENT_START
                        : UserScriptInjectionTime.AT_DOCUMENT_END,
                    source:
                        script.source.replaceAll("###PDA-APIKEY###", apiKey),
                  ),
                );
                break;
              }
            }
            if (!found) {
              scriptListToRemove.add(script.name);
            }
          }
        }
      }
    }
    var changes = UserScriptChanges()
      ..scriptsToAdd = UnmodifiableListView(scriptListToAdd)
      ..scriptsToRemove = scriptListToRemove;
    return changes;
  }

  void addUserScript(String name, String source) {
    var newScript = UserScriptModel(
      enabled: true,
      urls: getUrls(source),
      name: name,
      source: source,
    );
    userScriptList.add(newScript);
    notifyListeners();
    _saveSettingsSharedPrefs();
  }

  void updateUserScript(
    UserScriptModel editedModel,
    String name,
    String source,
  ) {
    for (var script in userScriptList) {
      if (script == editedModel) {
        script.name = name;
        script.urls = getUrls(source);
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

  List<String> getUrls(String source) {
    var urls = <String>[];
    final regex = RegExp(r'(@match+\s+)(.*)');
    var matches = regex.allMatches(source);
    if (matches.length > 0) {
      for (Match match in matches) {
        try {
          print(match.group(2));
          urls.add(match.group(2));
        } catch (e) {
          print(e);
        }
      }
    }
    return urls;
  }

  Future<void> loadPreferences() async {
    var savedScripts = await SharedPreferencesModel().getUserScriptsList();

    // NULL returned if we installed the app, so we add example scripts
    if (savedScripts == null) {
      _userScriptList =
          List<UserScriptModel>.from(ScriptsExamples.getScriptsExamples());
    } else {
      if (savedScripts.isNotEmpty) {
        var decoded = json.decode(savedScripts);
        for (var dec in decoded) {
          _userScriptList.add(UserScriptModel.fromJson(dec));
        }
      }
    }
    notifyListeners();
  }
}
