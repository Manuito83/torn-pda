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

  bool _scriptsFirstTime = true;
  bool get scriptsFirstTime => _scriptsFirstTime;

  var _userScriptsEnabled = true;
  bool get userScriptsEnabled => _userScriptsEnabled;
  set setUserScriptsEnabled(bool value) {
    _userScriptsEnabled = value;
    _saveUserScriptsSharedPrefs();
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
              source: _adaptSource(script, apiKey),
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
                    source: _adaptSource(script, apiKey),
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

  String _adaptSource(UserScriptModel script, String apiKey) {
    String withApiKey = script.source.replaceAll("###PDA-APIKEY###", apiKey);
    String anonFunction = "(function() {\n$withApiKey\n}());";
    return anonFunction;
  }

  void addUserScript(String name, String source) {
    var newScript = UserScriptModel(
      enabled: true,
      urls: getUrls(source),
      name: name,
      source: source,
    );
    userScriptList.add(newScript);

    _sort();
    notifyListeners();
    _saveUserScriptsSharedPrefs();
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
    _saveUserScriptsSharedPrefs();
  }

  void removeUserScript(UserScriptModel removedModel) {
    _userScriptList.remove(removedModel);
    notifyListeners();
    _saveUserScriptsSharedPrefs();
  }

  void changeUserScriptEnabled(UserScriptModel changedModel, bool enabled) {
    for (var script in userScriptList) {
      if (script == changedModel) {
        script.enabled = enabled;
        break;
      }
    }
    notifyListeners();
    _saveUserScriptsSharedPrefs();
  }

  Future restoreExamples(bool onlyRestoreNew) async {
    var newList = <UserScriptModel>[];

    // Add the ones that are not examples
    for (var existing in _userScriptList) {
      if (existing.exampleCode == 0) {
        newList.add(existing);
      }
    }

    // Then add the examples ones
    var exampleScripts =
        List<UserScriptModel>.from(ScriptsExamples.getScriptsExamples());
    if (onlyRestoreNew) {
      for (var i = 0; i < exampleScripts.length; i++) {
        var newExample = true;
        for (var j = 0; j < _userScriptList.length; j++) {
          if (exampleScripts[i].exampleCode == _userScriptList[j].exampleCode) {
            newExample = false;
            break;
          }
        }
        if (newExample) {
          newList.add(exampleScripts[i]);
        } else {
          newList.add(_userScriptList
              .singleWhere((element) => element.exampleCode == i + 1));
        }
      }
    } else {
      newList.addAll(exampleScripts);
    }

    _userScriptList = List<UserScriptModel>.from(newList);

    _sort();
    _saveUserScriptsSharedPrefs();
    notifyListeners();
  }

  void wipe() {
    _userScriptList.clear();
    notifyListeners();
    _saveUserScriptsSharedPrefs();
  }

  void _saveUserScriptsSharedPrefs() {
    var saveString = json.encode(_userScriptList);
    Prefs().setUserScriptsList(saveString);
  }

  List<String> getUrls(String source) {
    var urls = <String>[];
    final regex = RegExp(r'(@match+\s+)(.*)');
    var matches = regex.allMatches(source);
    if (matches.length > 0) {
      for (Match match in matches) {
        try {
          var noWildcard = match.group(2).replaceAll("*", "");
          urls.add(noWildcard);
        } catch (e) {
          //
        }
      }
    }
    return urls;
  }

  _sort() {
    _userScriptList
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void changeScriptsFirstTime(bool value) {
    _scriptsFirstTime = value;
    Prefs().setUserScriptsFirstTime(value);
  }

  Future<void> loadPreferences() async {
    _scriptsFirstTime =
        await Prefs().getUserScriptsFirstTime();

    var savedScripts = await Prefs().getUserScriptsList();

    // NULL returned if we installed the app, so we add example scripts
    if (savedScripts == null) {
      _userScriptList =
          List<UserScriptModel>.from(ScriptsExamples.getScriptsExamples());
      _saveUserScriptsSharedPrefs();
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
