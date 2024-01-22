// Dart imports:
import 'dart:collection';
import 'dart:convert';

// Flutter imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/utils/js_handlers.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
// import 'package:torn_pda/utils/userscript_examples.dart';

const List<String> _defaultScriptUrls = [
  "https://github.com/Manuito83/torn-pda/raw/master/userscripts/Bazaar%20Auto%20Price%20(Torn%20PDA).js",
  "https://github.com/Manuito83/torn-pda/raw/master/userscripts/Company%20Activity%20(Torn%20PDA).js",
  "https://github.com/Manuito83/torn-pda/raw/master/userscripts/Company%20Stock%20Order%20(Torn%20PDA).js",
  "https://github.com/Manuito83/torn-pda/raw/master/userscripts/Custom%20Gym%20Ratios%20(Torn%20PDA).js",
];

class UserScriptsProvider extends ChangeNotifier {
  final List<UserScriptModel> _userScriptList = <UserScriptModel>[];
  List<UserScriptModel> get userScriptList => _userScriptList;

  List<UserScriptModel> exampleScripts = <UserScriptModel>[];

  bool _scriptsFirstTime = true;
  bool get scriptsFirstTime => _scriptsFirstTime;

  bool _v2FirstTime = true;
  bool get v2FirstTime => _v2FirstTime;

  // bool newFeatInjectionTimeShown = true;

  var _userScriptsEnabled = true;
  bool get userScriptsEnabled => _userScriptsEnabled;
  set setUserScriptsEnabled(bool enabled) {
    _userScriptsEnabled = enabled;
    Prefs().setUserScriptsEnabled(enabled);
    _saveUserScriptsListSharedPrefs();
    notifyListeners();
  }

  List<String> get defaultScriptUrls => _defaultScriptUrls;

  UnmodifiableListView<UserScript> getHandlerSources({
    required String apiKey,
  }) {
    final scriptList = <UserScript>[];
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

      // Add GM Handlers (by Kwack)
      scriptList.add(
        UserScript(
          groupName: "__TornPDA_GM__",
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          source: handler_GM(),
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
    }
    return UnmodifiableListView<UserScript>(scriptList);
  }

  UnmodifiableListView<UserScript> getCondSources({
    required String url,
    required String apiKey,
    required UserScriptTime time,
  }) {
    if (!_userScriptsEnabled) {
      return UnmodifiableListView(const <UserScript>[]);
    } else {
      return UnmodifiableListView(_userScriptList
          .where((s) => s.shouldInject(url, time))
          .map((s) => UserScript(
                groupName: s.name,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                source: adaptSource(s.source, apiKey),
              )));
    }
  }

  List<String> getScriptsToRemove({
    required String url,
  }) {
    if (!_userScriptsEnabled) {
      return const <String>[];
    } else {
      return _userScriptList
          .where((s) => !s.shouldInject(url))
          .map((s) => s.name)
          .toList();
    }
  }

  String adaptSource(String source, String apiKey) {
    final String withApiKey = source.replaceAll("###PDA-APIKEY###", apiKey);
    String anonFunction = "(function() {$withApiKey}());";
    anonFunction = anonFunction.replaceAll('“', '"');
    anonFunction = anonFunction.replaceAll('”', '"');
    return anonFunction;
  }

  Future<({bool success, String? message})> addUserScriptFromURL(String url,
      {bool? isExample}) async {
    final response = await UserScriptModel.fromURL(url, isExample: isExample);
    if (response.success && response.model != null) {
      if (_userScriptList
          .any((script) => script.name == response.model!.name)) {
        return (
          success: false,
          message: "Script with same name already exists"
        );
      }
      userScriptList.add(response.model!);
      _sort();
      _saveUserScriptsListSharedPrefs();
      notifyListeners();
      return (success: true, message: null);
    } else {
      return (success: false, message: response.message);
    }
  }

  void addUserScript(
    String name,
    UserScriptTime time,
    String source, {
    bool enabled = true,
    String version = "0.0.0",
    edited = false,
    String? url,
    UserScriptUpdateStatus updateStatus = UserScriptUpdateStatus.noRemote,
    allScriptFirstLoad = false,
    bool isExample = false,
  }) {
    final newScript = UserScriptModel(
      name: name,
      time: time,
      source: source,
      enabled: enabled,
      version: version,
      edited: edited,
      matches: getUrls(source),
      updateStatus: updateStatus,
      url: url,
      isExample: isExample,
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
    bool isFromRemote,
  ) {
    userScriptList
        .firstWhere((script) => script.name == editedModel.name)
        .update(
            name: name,
            time: time,
            source: source,
            matches: getUrls(source),
            updateStatus: isFromRemote
                ? UserScriptUpdateStatus.upToDate
                : editedModel.updateStatus == UserScriptUpdateStatus.noRemote
                    ? UserScriptUpdateStatus.noRemote
                    : UserScriptUpdateStatus.localModified);
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
  }

  void removeUserScript(UserScriptModel removedModel) {
    _userScriptList.remove(removedModel);
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
  }

  void changeUserScriptEnabled(UserScriptModel changedModel, bool enabled) {
    for (final script in userScriptList) {
      if (script == changedModel) {
        script.enabled = enabled;
        break;
      }
    }
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
  }

  void wipe() {
    _userScriptList.clear();
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
  }

  void restoreScriptsFromServerSave({
    required bool overwritte,
    required String scriptsList,
  }) async {
    // If we overwritte, just save to prefs and initialise
    if (overwritte) {
      await Prefs().setUserScriptsList(scriptsList);
      _userScriptList.clear();
      await loadPreferences();
      return;
    }

    // If we don't overwritte, try to add the scripts
    final decoded = json.decode(scriptsList);
    for (final dec in decoded) {
      try {
        final decodedModel = UserScriptModel.fromJson(dec);

        // Check if the script with the same name already exists in the list
        final bool scriptExists = _userScriptList.any((script) {
          return script.name.toLowerCase() == decodedModel.name.toLowerCase();
        });

        if (scriptExists) continue;

        addUserScript(
          decodedModel.name,
          decodedModel.time,
          decodedModel.source,
          enabled: decodedModel.enabled,
          version: decodedModel.version,
          edited: decodedModel.edited,
          allScriptFirstLoad: true,
          isExample: decodedModel.isExample,
          updateStatus: decodedModel.updateStatus,
          url: decodedModel.url,
        );
      } catch (e, trace) {
        FirebaseCrashlytics.instance.log("PDA error at adding server userscript. Error: $e. Stack: $trace");
        FirebaseCrashlytics.instance.recordError(e, trace);
      }
    }
    _sort();
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
  }

  void _saveUserScriptsListSharedPrefs() {
    final saveString = json.encode(_userScriptList);
    Prefs().setUserScriptsList(saveString);
  }

  List<String> getUrls(String source) {
    final Map<String, dynamic> metaMap = UserScriptModel.parseHeader(source);
    if (metaMap["matches"] == null) {
      return const ["*"];
    } else {
      return metaMap["matches"];
    }
  }

  void _sort() {
    _userScriptList
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void changeScriptsFirstTime(bool value) {
    _scriptsFirstTime = value;
    Prefs().setUserScriptsFirstTime(value);
  }

  void changeV2FirstTime(bool value) {
    _v2FirstTime = value;
    Prefs().setUserScriptsFeatV2Shown(value);
  }

  Future<void> loadPreferences() async {
    try {
      // _userScriptsEnabled = await Prefs().getUserScriptsEnabled();

      _scriptsFirstTime = await Prefs().getUserScriptsFirstTime();

      _v2FirstTime = await Prefs().getUserScriptsFirstTime();

      final savedScripts = await Prefs().getUserScriptsList();

      _v2FirstTime = await Prefs().getUserScriptsFeatV2Shown();

      // NULL returned if we installed the app, so we add all the example scripts
      if (savedScripts == null) {
        await addDefaultScripts();
        _saveUserScriptsListSharedPrefs();
      } else {
        if (savedScripts.isNotEmpty) {
          final decoded = json.decode(savedScripts);
          for (final dec in decoded) {
            try {
              final decodedModel = UserScriptModel.fromJson(dec);

              // Check if the script with the same name already exists in the list
              // (user-reported bug)
              final String name = decodedModel.name.toLowerCase();
              if (_userScriptList
                  .any((script) => script.name.toLowerCase() == name)) continue;

              addUserScript(
                decodedModel.name,
                decodedModel.time,
                decodedModel.source,
                enabled: decodedModel.enabled,
                version: decodedModel.version,
                edited: decodedModel.edited,
                url: decodedModel.url,
                updateStatus: decodedModel.updateStatus,
                allScriptFirstLoad: true,
                isExample: decodedModel.isExample,
              );
            } catch (e, trace) {
              FirebaseCrashlytics.instance.log(
                  "PDA error at adding one userscript. Error: $e. Stack: $trace");
              FirebaseCrashlytics.instance.recordError(e, trace);
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
      FirebaseCrashlytics.instance
          .log("PDA error at userscripts first load. Error: $e. Stack: $trace");
      FirebaseCrashlytics.instance.recordError(e, trace);
    }
  }

  Future<int> checkForUpdates() async {
    int updates = 0;
    await Future.wait(_userScriptList.map((s) {
      if (s.url == null) return Future.value();
      s.updateStatus = UserScriptUpdateStatus.updating;
      notifyListeners(); // Notify listeners of the change to show updating, but **do not save this to shared prefs**
      return s.canUpdate().then((canUpdate) {
        if (canUpdate) {
          s.updateStatus = UserScriptUpdateStatus.updateAvailable;
          updates++; // Increment number of scripts updated
        } else {
          s.updateStatus = UserScriptUpdateStatus.upToDate;
        }
        notifyListeners(); // Notify listeners of the change after every row
      });
    }));
    _saveUserScriptsListSharedPrefs(); // Only save once all scripts are updated, so that we don't save the "updating" status
    return updates;
  }

  Future<({int added, int failed, int alreadyAdded})>
      addDefaultScripts() async {
    int added = 0;
    int failed = 0;
    int alreadyAdded = 0;
    await Future.wait(defaultScriptUrls.map((url) =>
        addUserScriptFromURL(url, isExample: true).then((r) => r.success
            ? added++
            : r.message == "Script with same name already exists"
                ? alreadyAdded++
                : failed++)));
    return (
      added: added,
      failed: failed,
      alreadyAdded: alreadyAdded,
    );
  }
}
