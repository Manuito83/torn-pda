// Dart imports:
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/utils/js_handlers.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/userscript_examples.dart';

class UserScriptsProvider extends ChangeNotifier {
  List<UserScriptModel> _userScriptList = <UserScriptModel>[];
  List<UserScriptModel> get userScriptList => _userScriptList;

  List<UserScriptModel> exampleScripts = <UserScriptModel>[];

  bool _scriptsFirstTime = true;
  bool get scriptsFirstTime => _scriptsFirstTime;

  bool newFeatureInjectionTimeShown = true;

  var _userScriptsEnabled = true;
  bool get userScriptsEnabled => _userScriptsEnabled;
  set setUserScriptsEnabled(bool enabled) {
    _userScriptsEnabled = enabled;
    Prefs().setUserScriptsEnabled(enabled);
    _saveUserScriptsListSharedPrefs();
    notifyListeners();
  }

  UnmodifiableListView<UserScript> getContinuousSources({
    @required String apiKey,
  }) {
    var scriptList = <UserScript>[];
    if (_userScriptsEnabled) {
      // Add the main event to let other handlers that the platform is ready
      scriptList.add(
        UserScript(
          groupName: "__TornPDA_ReadyEvent__",
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          source: handler_flutterPlatformReady(),
        ),
      );

      // Add the userscript API first so that it's available to other scripts
      scriptList.add(
        UserScript(
          groupName: "__TornPDA_API__",
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          source: handler_pdaAPI(),
        ),
      );

      // Add evaluateJavascript handler
      scriptList.add(
        UserScript(
          groupName: "__TornPDA_EvaluateJavascript__",
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          source: handler_evaluateJS(),
        ),
      );

      // Then add the rest of scripts
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

  UnmodifiableListView<UserScript> getCondSources({
    @required String url,
    @required String apiKey,
    @required UserScriptTime time,
  }) {
    var scriptListToAdd = <UserScript>[];
    if (_userScriptsEnabled) {
      for (var script in _userScriptList) {
        if (script.enabled) {
          if (time != script.time) continue;
          if (script.urls.isNotEmpty) {
            for (String u in script.urls) {
              if (url.contains(u.replaceAll("*", ""))) {
                scriptListToAdd.add(
                  UserScript(
                    groupName: script.name,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    source: _adaptSource(script, apiKey),
                  ),
                );
                break;
              }
            }
          }
        }
      }
    }
    return UnmodifiableListView(scriptListToAdd);
  }

  List<String> getScriptsToRemove({
    @required String url,
  }) {
    var scriptListToRemove = <String>[];
    if (_userScriptsEnabled) {
      for (var script in _userScriptList) {
        if (script.enabled) {
          if (script.urls.isNotEmpty) {
            var found = false;
            for (String u in script.urls) {
              if (url.contains(u.replaceAll("*", ""))) {
                found = true;
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
    return scriptListToRemove;
  }

  String _adaptSource(UserScriptModel script, String apiKey) {
    String withApiKey = script.source.replaceAll("###PDA-APIKEY###", apiKey);
    String anonFunction = "(function() {\n$withApiKey\n}());";
    return anonFunction;
  }

  void addUserScript(
    String name,
    UserScriptTime time,
    String source, {
    bool enabled = true,
    int exampleCode = 0,
    int version = 0,
    edited = false,
    allScriptFirstLoad = false,
  }) {
    var newScript = UserScriptModel(
      name: name,
      time: time,
      source: source,
      enabled: enabled,
      exampleCode: exampleCode,
      version: version,
      edited: edited,
      urls: getUrls(source),
    );
    userScriptList.add(newScript);

    // During first load we just sort, save and notify once
    if (!allScriptFirstLoad) {
      _sort();
      notifyListeners();
      _saveUserScriptsListSharedPrefs();
    }
  }

  void updateUserScript(
    UserScriptModel editedModel,
    String name,
    UserScriptTime time,
    String source,
    bool changedSource,
  ) {
    for (var script in userScriptList) {
      if (script == editedModel) {
        script.name = name;
        script.urls = getUrls(source);
        script.time = time;
        script.source = source;
        script.edited = changedSource;
        break;
      }
    }
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
  }

  void removeUserScript(UserScriptModel removedModel) {
    _userScriptList.remove(removedModel);
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
  }

  void changeUserScriptEnabled(UserScriptModel changedModel, bool enabled) {
    for (var script in userScriptList) {
      if (script == changedModel) {
        script.enabled = enabled;
        break;
      }
    }
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
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
    var exampleScripts = List<UserScriptModel>.from(ScriptsExamples.getScriptsExamples());

    // But before, ensure that we don't add an example script with an already taken name
    // in a user-inserted script (with exampleCode == 0)
    for (var s = 0; s < exampleScripts.length; s++) {
      for (var existingScript in _userScriptList) {
        if (existingScript.name.toLowerCase() == exampleScripts[s].name.toLowerCase() &&
            existingScript.exampleCode == 0) {
          exampleScripts[s].name += " (example)";
          break;
        }
      }
    }

    if (onlyRestoreNew) {
      for (var i = 0; i < exampleScripts.length; i++) {
        var newExample = true;
        var currentExampleCode = exampleScripts[i].exampleCode;
        for (var j = 0; j < _userScriptList.length; j++) {
          if (currentExampleCode == _userScriptList[j].exampleCode) {
            newExample = false;
            break;
          }
        }
        if (newExample) {
          newList.add(exampleScripts[i]);
        } else {
          newList.add(_userScriptList.singleWhere((element) => element.exampleCode == currentExampleCode));
        }
      }
    } else {
      newList.addAll(exampleScripts);
    }

    _userScriptList = List<UserScriptModel>.from(newList);

    _sort();
    _saveUserScriptsListSharedPrefs();
    notifyListeners();
  }

  void wipe() {
    _userScriptList.clear();
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
  }

  void _saveUserScriptsListSharedPrefs() {
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
    _userScriptList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void changeScriptsFirstTime(bool value) {
    _scriptsFirstTime = value;
    Prefs().setUserScriptsFirstTime(value);
  }

  void changeFeatInjectionTimeShown(bool value) {
    newFeatureInjectionTimeShown = value;
    Prefs().setUserScriptsFeatInjectionTimeShown(value);
  }

  Future<void> loadPreferences() async {
    try {
      _userScriptsEnabled = await Prefs().getUserScriptsEnabled();

      _scriptsFirstTime = await Prefs().getUserScriptsFirstTime();
      newFeatureInjectionTimeShown = await Prefs().getUserScriptsFeatInjectionTimeShown();

      var savedScripts = await Prefs().getUserScriptsList();
      exampleScripts = await List<UserScriptModel>.from(ScriptsExamples.getScriptsExamples());

      // NULL returned if we installed the app, so we add all the example scripts
      if (savedScripts == null) {
        for (var example in exampleScripts) {
          addUserScript(
            example.name,
            example.time,
            example.source,
            enabled: example.enabled,
            exampleCode: example.exampleCode,
            allScriptFirstLoad: true,
          );
        }
        _saveUserScriptsListSharedPrefs();
      } else {
        if (savedScripts.isNotEmpty) {
          var decoded = json.decode(savedScripts);
          for (var dec in decoded) {
            try {
              var decodedModel = UserScriptModel.fromJson(dec);
              addUserScript(
                decodedModel.name,
                decodedModel.time,
                decodedModel.source,
                enabled: decodedModel.enabled,
                exampleCode: decodedModel.exampleCode,
                version: decodedModel.version,
                edited: decodedModel.edited,
                allScriptFirstLoad: true,
              );
            } catch (e, trace) {
              FirebaseCrashlytics.instance.log("PDA error at adding one userscript. Error: $e. Stack: $trace");
              FirebaseCrashlytics.instance.recordError(e, trace);
            }
          }
        }

        // Update example scripts to latest versions
        for (var script in _userScriptList) {
          // Look for saved scripts than come from examples
          if (script.exampleCode > 0) {
            if (script.edited == null) continue;
            if (!script.edited) {
              // If the script has not been edited, find the example script and see if we need to update the source
              for (var example in exampleScripts) {
                if (script.exampleCode == example.exampleCode &&
                    script.version != null &&
                    script.version < example.version) {
                  script.source = example.source;
                  script.version = example.version;
                }
              }
            }
          }
        }

        _sort();
        notifyListeners();
        _saveUserScriptsListSharedPrefs();
      }
      notifyListeners();
    } catch (e, trace) {
      // Pass (scripts will be empty)
      FirebaseCrashlytics.instance.log("PDA error at userscripts first load. Error: $e. Stack: $trace");
      FirebaseCrashlytics.instance.recordError(e, trace);
    }
  }
}
