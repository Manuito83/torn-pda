// Dart imports:
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

// Package imports:
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/utils/js_handlers.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
// import 'package:torn_pda/utils/userscript_examples.dart';

class UserScriptsProvider extends ChangeNotifier {
  final List<UserScriptModel> _userScriptList = <UserScriptModel>[];
  List<UserScriptModel> get userScriptList => _userScriptList;

  List<UserScriptModel> exampleScripts = <UserScriptModel>[];

  bool _scriptsFirstTime = true;
  bool get scriptsFirstTime => _scriptsFirstTime;

  var _userScriptsEnabled = true;
  bool get userScriptsEnabled => _userScriptsEnabled;
  set setUserScriptsEnabled(bool enabled) {
    _userScriptsEnabled = enabled;
    Prefs().setUserScriptsEnabled(enabled);
    _saveUserScriptsListSharedPrefs();
    notifyListeners();
  }

  var _userScriptsNotifyUpdates = true;
  bool get userScriptsNotifyUpdates => _userScriptsNotifyUpdates;
  set setUserScriptsNotifyUpdates(bool enabled) {
    _userScriptsNotifyUpdates = enabled;
    Prefs().setUserScriptsNotifyUpdates(enabled);
    notifyListeners();
  }

  List<String?> get defaultScriptUrls => UserScriptModel.exampleScriptURLs;

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
    required String pdaApiKey,
    required UserScriptTime time,
  }) {
    if (_userScriptsEnabled) {
      try {
        return UnmodifiableListView(
          _userScriptList.where((s) => s.shouldInject(url, time)).map(
            (s) {
              return UserScript(
                groupName: s.name,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                // If the script is a custom API key script, we need to replace the API key
                source: adaptSource(
                  source: s.source,
                  scriptFinalApiKey: s.customApiKey.isNotEmpty ? s.customApiKey : pdaApiKey,
                ),
              );
            },
          ),
        );
      } catch (e, trace) {
        if (!Platform.isWindows) {
          FirebaseCrashlytics.instance.log("PDA error at userscripts getCondSources. Error: $e");
        }
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        logToUser("PDA error at userscripts getCondSources. Error: $e");
      }
    }
    return UnmodifiableListView(const <UserScript>[]);
  }

  List<String> getScriptsToRemove({
    required String url,
  }) {
    if (!_userScriptsEnabled) {
      return const <String>[];
    } else {
      return _userScriptList.where((s) => !s.shouldInject(url)).map((s) => s.name).toList();
    }
  }

  String adaptSource({required String source, required String scriptFinalApiKey}) {
    final String withApiKey = source.replaceAll("###PDA-APIKEY###", scriptFinalApiKey);
    String anonFunction = "(function() {$withApiKey}());";
    anonFunction = anonFunction.replaceAll('“', '"');
    anonFunction = anonFunction.replaceAll('”', '"');
    return anonFunction;
  }

  void addUserScriptByModel(UserScriptModel model) {
    userScriptList.add(model);
    _sort();
    _saveUserScriptsListSharedPrefs();
    notifyListeners();
  }

  Future<void> addUserScript(
    String name,
    UserScriptTime time,
    String source, {
    bool enabled = true,
    String version = "0.0.0",
    bool manuallyEdited = false,
    String? url,
    UserScriptUpdateStatus updateStatus = UserScriptUpdateStatus.noRemote,
    bool isExample = false,
    List<String>? matches,
    String? customApiKey,
    bool? customApiKeyCandidate,
  }) async {
    final newScript = UserScriptModel(
      name: name,
      time: time,
      source: source,
      enabled: enabled,
      version: version,
      manuallyEdited: manuallyEdited,
      matches: matches ?? UserScriptModel.tryGetMatches(source),
      updateStatus: updateStatus,
      url: url,
      isExample: isExample,
      customApiKey: customApiKey ?? "",
      customApiKeyCandidate: customApiKeyCandidate ?? false,
    );

    _userScriptList.add(newScript);

    _sort();
    await _saveUserScriptsListSharedPrefs();
    notifyListeners();
  }

  /// Returns a bool indicating if the header could be parsed
  bool updateUserScript({
    required UserScriptModel editedModel,
    required String name,
    required UserScriptTime time,
    required String source,
    required bool manuallyEdited,
    required bool isFromRemote,
    required String? customApiKey,
    required bool? customApiKeyCandidate,
  }) {
    List<String>? matches;
    bool couldParseHeader = true;
    try {
      matches = UserScriptModel.tryGetMatches(source);
    } catch (e) {
      matches ??= const ["*"];
    }

    userScriptList.firstWhere((script) => script.name == editedModel.name).update(
          name: name,
          time: time,
          source: source,
          manuallyEdited: manuallyEdited,
          customApiKey: customApiKey ?? "",
          customApiKeyCandidate: customApiKeyCandidate ?? false,
          matches: matches,
          updateStatus: () {
            // If the script comes from remote
            if (isFromRemote) return UserScriptUpdateStatus.upToDate;
            // If the previous status was noRemote, keep it
            if (editedModel.updateStatus == UserScriptUpdateStatus.noRemote) return UserScriptUpdateStatus.noRemote;
            // If previous status was upToDate and the script has NOT been edited, keep as upToDate
            // so that it doesn't show as localModified when we just load an API key, for example,
            // or just open/close the script without editing it at all
            if (editedModel.updateStatus == UserScriptUpdateStatus.upToDate && !manuallyEdited) {
              return UserScriptUpdateStatus.upToDate;
            }
            // Otherwise... localModified
            return UserScriptUpdateStatus.localModified;
          }(),
        );
    notifyListeners();
    _saveUserScriptsListSharedPrefs();
    return couldParseHeader;
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

  /// [defaultToDisabled] makes all scripts inactive, if we can trust them 100% because they come from a shared backup
  Future<void> restoreScriptsFromServerSave({
    required bool overwrite, // Renamed for clarity, Dart convention
    required String scriptsList,
    bool defaultToDisabled = false,
  }) async {
    if (overwrite) {
      _userScriptList.clear();
      final List<dynamic> decoded = json.decode(scriptsList);

      for (final dec in decoded) {
        try {
          // Create and add the model
          _userScriptList.add(UserScriptModel.fromJson(dec));
        } catch (e, trace) {
          // Log if a single script in the backup is corrupt, but continue
          if (!Platform.isWindows) {
            FirebaseCrashlytics.instance.log("PDA error parsing server script on overwrite. Error: $e.");
          }
          if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
          logToUser("PDA error at parsing server script. Error: $e");
        }
      }

      if (defaultToDisabled) {
        for (final script in _userScriptList) {
          script.enabled = false;
        }
      }
    } else {
      // We add the scripts that don't already exist
      final decoded = json.decode(scriptsList);

      for (final dec in decoded) {
        try {
          final decodedModel = UserScriptModel.fromJson(dec);

          // Check if the script with the same name already exists in the list
          final bool scriptExists = _userScriptList.any(
            (script) => script.name.toLowerCase() == decodedModel.name.toLowerCase(),
          );

          if (scriptExists) continue;

          _userScriptList.add(UserScriptModel(
              name: decodedModel.name,
              time: decodedModel.time,
              source: decodedModel.source,
              enabled: defaultToDisabled ? false : decodedModel.enabled,
              version: decodedModel.version,
              manuallyEdited: decodedModel.manuallyEdited,
              isExample: decodedModel.isExample,
              updateStatus: decodedModel.updateStatus,
              url: decodedModel.url,
              matches: decodedModel.matches,
              // Custom API key fields are already part of fromJson, but explicitly listing them is fine.
              customApiKey: decodedModel.customApiKey,
              customApiKeyCandidate: decodedModel.customApiKeyCandidate));
        } catch (e, trace) {
          if (!Platform.isWindows) {
            FirebaseCrashlytics.instance.log("PDA error at adding server userscript. Error: $e. Stack: $trace");
          }
          if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
          logToUser("PDA error at adding server userscript. Error: $e. Stack: $trace");
        }
      }
    }

    // Perform final operations once, after the list has been fully manipulated
    _sort();
    await _saveUserScriptsListSharedPrefs();
    notifyListeners();
  }

  Future<void> _saveUserScriptsListSharedPrefs() async {
    _checkForCustomApiKeyCandidates();
    final saveString = json.encode(_userScriptList);
    await Prefs().setUserScriptsList(saveString);
  }

  void _sort() {
    _userScriptList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void changeScriptsFirstTime(bool value) {
    _scriptsFirstTime = value;
    Prefs().setUserScriptsFirstTime(value);
  }

  Future<void> loadPreferences() async {
    // Clear the in-memory list to ensure a clean slate and prevent duplicates.
    _userScriptList.clear();

    try {
      _scriptsFirstTime = await Prefs().getUserScriptsFirstTime();

      // #### RETRY LOGIC START
      // (mainly because of numerous user reports of empty scripts)
      String? savedScripts;
      // Try a total of 3 times (initial + 2 retries)
      const int maxRetries = 2;
      const Duration retryDelay = Duration(seconds: 1);

      for (int i = 0; i <= maxRetries; i++) {
        savedScripts = await Prefs().getUserScriptsList();
        // If the load is successful, break
        if (savedScripts != null) {
          if (i > 0) log("UserScripts load attempt ${i + 1} succeeded");
          break;
        }

        // If it's not the last attempt, log and wait before trying again
        if (i < maxRetries) {
          log("UserScripts load attempt ${i + 1} failed, retrying...");
          await Future.delayed(retryDelay);
        } else {
          log("UserScripts load failed after ${maxRetries + 1} attempts");
        }
      }
      // #### RETRY LOGIC END

      // Failed or first time (SharedPrefs returns null by default)
      if (savedScripts == null || savedScripts.isEmpty) {
        // Only seed with defaults scripts if it's the first app run
        if (_scriptsFirstTime) {
          await addDefaultScripts();
        }

        notifyListeners();
        return;
      }

      // Decode and populate
      final decoded = json.decode(savedScripts);
      if (decoded is List) {
        for (final dec in decoded) {
          try {
            final decodedModel = UserScriptModel.fromJson(dec);

            // Check if the script with the same name already exists in the list
            // (user-reported bug)
            final String name = decodedModel.name.toLowerCase();
            if (_userScriptList.any((script) => script.name.toLowerCase() == name)) continue;

            // Use a direct add to avoid triggering saves
            _userScriptList.add(
              UserScriptModel(
                name: decodedModel.name,
                time: decodedModel.time,
                source: decodedModel.source,
                enabled: decodedModel.enabled,
                version: decodedModel.version,
                manuallyEdited: decodedModel.manuallyEdited,
                url: decodedModel.url,
                updateStatus: decodedModel.updateStatus,
                matches: decodedModel.matches,
                isExample: decodedModel.isExample,
                customApiKey: decodedModel.customApiKey,
                customApiKeyCandidate: decodedModel.customApiKeyCandidate,
              ),
            );
          } catch (e, trace) {
            if (!Platform.isWindows) {
              FirebaseCrashlytics.instance.log("PDA error at adding one userscript. Error: $e. Stack: $trace");
            }
            if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
            logToUser("PDA error at adding one userscript. Error: $e. Stack: $trace");
          }
        }
      }

      _sort();
      _checkForCustomApiKeyCandidates();

      notifyListeners();
    } catch (e, trace) {
      // The main list will be empty, but the user's data is not wiped from disk
      // ... perhaps recoverable after reloading the app...?
      // (see bug explanation for retries above)
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA error at userscripts first load. Error: $e. Stack: $trace");
        FirebaseCrashlytics.instance.recordError(e, trace);
      }
      logToUser("PDA error at userscript first load. Error: $e. Stack: $trace");
    }
  }

  /// Flag scripts that are candidates for custom API keys
  void _checkForCustomApiKeyCandidates() {
    try {
      for (final script in _userScriptList) {
        if (script.source.contains("###PDA-APIKEY###")) {
          script.customApiKeyCandidate = true;
        } else {
          script.customApiKeyCandidate = false;
        }
      }
    } catch (e, trace) {
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA error at checking custom API key candidates. Error: $e. Stack: $trace");
      }
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
      logToUser("PDA error at checking custom API key candidates. Error: $e. Stack: $trace");
    }
  }

  Future<int> checkForUpdates() async {
    int updates = 0;
    await Future.wait<void>(_userScriptList.map((s) {
      // Only check for updates on relevant scripts
      if (s.updateStatus == UserScriptUpdateStatus.localModified || s.updateStatus == UserScriptUpdateStatus.noRemote) {
        return Future.value();
      }
      // Ensure script has a valid URL
      if (s.url == null) return Future.value();

      s.updateStatus = UserScriptUpdateStatus.updating;
      notifyListeners(); // Notify listeners of the change to show updating, but **do not save this to shared prefs**

      return s.checkUpdateStatus().then((updateStatus) {
        if (updateStatus == UserScriptUpdateStatus.updateAvailable) updates++;
        s.updateStatus = updateStatus;
        notifyListeners(); // Notify listeners of the change after every row
      }).catchError((e) {
        print(e);
        s.updateStatus = UserScriptUpdateStatus.error;
        notifyListeners(); // Notify listeners of the change after every row
      });
    }));

    _saveUserScriptsListSharedPrefs(); // Only save once all scripts are updated, so that we don't save the "updating" status
    return updates;
  }

  Future<({int added, int failed, int removed})> addDefaultScripts() async {
    int added = 0;
    int failed = 0;
    // int alreadyAdded = 0;
    int initialScriptCount = userScriptList.length;
    // Remove example scripts;
    userScriptList.removeWhere((s) => s.isExample);
    await Future.wait(defaultScriptUrls.map((url) => url == null
        ? Future.value()
        : addUserScriptFromURL(url, isExample: true).then((r) => r.success ? added++ : failed++)));

    _checkForCustomApiKeyCandidates();

    return (
      added: added,
      failed: failed,
      removed: initialScriptCount - (userScriptList.length - added),
    );
  }

  Future<({bool success, String? message})> addUserScriptFromURL(String url, {bool? isExample}) async {
    final response = await UserScriptModel.fromURL(url, isExample: isExample);
    if (response.success && response.model != null) {
      if (_userScriptList.any((script) => script.name == response.model!.name)) {
        return (success: false, message: "Script with same name already exists");
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
}
