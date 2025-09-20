// Dart imports:
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
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
  final _initializationCompleter = Completer<void>();
  Future<void> get onInitialized => _initializationCompleter.future;

  final List<UserScriptModel> _userScriptList = <UserScriptModel>[];
  List<UserScriptModel> get userScriptList => _userScriptList;

  List<UserScriptModel> exampleScripts = <UserScriptModel>[];

  bool _scriptsSectionNeverVisited = true;
  bool get scriptsFirstTime => _scriptsSectionNeverVisited;
  set changeScriptsFirstTime(bool value) {
    _scriptsSectionNeverVisited = value;
    Prefs().setUserScriptsSectionNeverVisited(value);
  }

  var _userScriptsEnabled = true;
  bool get userScriptsEnabled => _userScriptsEnabled;
  set setUserScriptsEnabled(bool enabled) {
    _userScriptsEnabled = enabled;
    Prefs().setUserScriptsEnabled(enabled);
    _saveUserScriptsToStorage();
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
    anonFunction = anonFunction.replaceAll(RegExp(r'[“”]'), '"').replaceAll(RegExp(r'[‘’]'), "'");
    return anonFunction;
  }

  void addUserScriptByModel(UserScriptModel model) {
    if (_addScript(_userScriptList, model, "addUserScriptByModel")) {
      _sort();
      _saveUserScriptsToStorage();
      notifyListeners();
    }
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

    if (_addScript(_userScriptList, newScript, "addUserScript")) {
      _sort();
      await _saveUserScriptsToStorage();
      notifyListeners();
    }
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
    _saveUserScriptsToStorage();
    return couldParseHeader;
  }

  void removeUserScript(UserScriptModel removedModel) {
    _userScriptList.remove(removedModel);
    notifyListeners();
    _saveUserScriptsToStorage();
  }

  void changeUserScriptEnabled(UserScriptModel changedModel, bool enabled) {
    for (final script in userScriptList) {
      if (script == changedModel) {
        script.enabled = enabled;
        break;
      }
    }
    notifyListeners();
    _saveUserScriptsToStorage();
  }

  void wipe() {
    _userScriptList.clear();
    notifyListeners();
    _saveUserScriptsToStorage();
  }

  /// [defaultToDisabled] makes all scripts inactive, if we can trust them 100% because they come from a shared backup
  Future<void> restoreScriptsFromServerSave({
    required bool overwrite,
    required String scriptsList,
    bool defaultToDisabled = false,
  }) async {
    if (overwrite) {
      _userScriptList.clear();
      final List<dynamic> decoded = json.decode(scriptsList);

      for (final dec in decoded) {
        try {
          // Create and add the model
          final scriptModel = UserScriptModel.fromJson(dec);
          _addScript(_userScriptList, scriptModel, "restoreScriptsFromServerSave-overwrite");
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

          final newScriptModel = UserScriptModel(
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
              customApiKeyCandidate: decodedModel.customApiKeyCandidate);

          _addScript(_userScriptList, newScriptModel, "restoreScriptsFromServerSave-merge");
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
    await _saveUserScriptsToStorage();
    notifyListeners();
  }

  /// Save userscripts list with proper encoding
  Future<void> _saveUserScriptsToStorage() async {
    if (!_initializationCompleter.isCompleted) {
      log("📜❌ Rejected userscripts save");
      return;
    }

    try {
      _checkForCustomApiKeyCandidates();
      final saveString = json.encode(_userScriptList);
      // Encode to Base64 with prefix to prevent character encoding issues
      final encodedString = "PDA_B64:${base64Encode(utf8.encode(saveString))}";
      await Prefs().setUserScriptsList(encodedString);
    } catch (e, trace) {
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA error saving userscripts. Error: $e");
        FirebaseCrashlytics.instance.recordError(e, trace);
      }
      logToUser("PDA error saving userscripts. Error: $e");
    }
  }

  /// Load userscripts list with automatic format detection
  Future<String?> _loadUserScriptsFromStorage() async {
    String? savedScripts = await Prefs().getUserScriptsList();
    if (savedScripts == null) return null;

    if (savedScripts.startsWith("PDA_B64:")) {
      try {
        // New format: Base64 encoded
        final base64Data = savedScripts.substring(8); // Remove "PDA_B64:" prefix
        final decodedBytes = base64Decode(base64Data);
        final decodedString = utf8.decode(decodedBytes);
        log("📜 UserScripts loaded from new Base64 format");
        return decodedString;
      } catch (e, trace) {
        if (!Platform.isWindows) {
          FirebaseCrashlytics.instance.log("PDA error decoding Base64 userscripts. Error: $e");
        }
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        logToUser("PDA error decoding Base64 userscripts. Error: $e");
        return null;
      }
    } else {
      // Old format: direct JSON string
      log("📜 UserScripts loaded from legacy format");
      return savedScripts;
    }
  }

  /// Get userscripts as JSON string for external use (backups, etc.)
  Future<String?> getUserScriptsAsJsonString() async {
    return await _loadUserScriptsFromStorage();
  }

  void _sort() {
    _userScriptList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  bool _addScript(List<UserScriptModel> targetList, UserScriptModel script, String context) {
    try {
      final String scriptName = script.name.toLowerCase();
      if (targetList.any((existingScript) => existingScript.name.toLowerCase() == scriptName)) {
        log("📜 UserScripts: Script '${script.name}' already exists in list, skipping (context: $context)");
        return false;
      }

      targetList.add(script);
      return true;
    } catch (e, trace) {
      final errorMessage = "Error adding userscript '${script.name}' in context: $context. Error: $e";
      log("📜 UserScripts ERROR: $errorMessage");

      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA error at _addScript. $errorMessage");
        FirebaseCrashlytics.instance.recordError(e, trace, reason: "UserScript add failure in $context");
      }

      BotToast.showText(
        text: "Error adding script: ${script.name}",
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.red[800]!,
        duration: const Duration(seconds: 4),
      );

      return false;
    }
  }

  Future<void> loadPreferencesAndScripts() async {
    _scriptsSectionNeverVisited = await Prefs().getUserScriptsSectionNeverVisited();

    // 1. Always try to load existing scripts first (regardless of app version)
    // 2. Only check if it's "first time" if no scripts exist

    try {
      // If scripts exist, load them regardless of what lastSavedAppCompilation says
      String? savedScripts;
      const int maxRetries = 5;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        savedScripts = await _loadUserScriptsFromStorage();
        if (savedScripts != null) {
          if (attempt > 1) {
            log("📜 UserScripts: Load succeeded on attempt $attempt");
          }
          break;
        }

        if (attempt < maxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          log("📜 UserScripts: Load failed after $maxRetries attempts");
        }
      }

      // If we found saved scripts, decode and load them
      if (savedScripts != null) {
        final List<UserScriptModel> tempList = <UserScriptModel>[];
        final decoded = json.decode(savedScripts);
        if (decoded is List) {
          for (final dec in decoded) {
            final decodedModel = UserScriptModel.fromJson(dec);
            _addScript(tempList, decodedModel, "loadPreferencesAndScripts-existing");
          }
        }

        // Apply loaded scripts
        _userScriptList.clear();
        _userScriptList.addAll(tempList);
        _sort();
        _checkForCustomApiKeyCandidates();
        notifyListeners();

        log("📜 UserScripts: Successfully loaded ${_userScriptList.length} existing scripts");
        return;
      }

      // Check if it's the first run based on app update status
      // Scripts == null and app never updated -> should be first run
      if (!appHasBeenUpdated) {
        log("📜 UserScripts: First app run detected, loading default scripts");
        // NOTE: this will probably get a rejected save (and a log message) as the completer is not completed,
        // but it's fine (and it will keep happening) for several app starts while scripts are untouched)
        // since we have no custom scripts yet and any user action (a save, deletion, etc.)
        // will save them eventually
        await addDefaultScripts();
        notifyListeners();
        return;
      }

      // If we reach here, scripts are null but the app has been updated
      // It does not make sense. If anything, scripts could be empty but not null.
      // This should not happen take place and we should not load defaults
      // just in case the user can recover them by resetting the app
      throw Exception("PDA error in loadPreferencesAndScripts. Scripts are null after app update.");
    } catch (e, trace) {
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA error in loadPreferencesAndScripts. Error: $e");
        FirebaseCrashlytics.instance.recordError(e, trace);
      }
      BotToast.showText(
        text: "⚠️"
            "\n\nThere was a problem retrieving userscripts: $e"
            "\n\nConsider restarting the app to ensure that no data is lost!",
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.orange.shade800,
        duration: const Duration(seconds: 8),
      );
    } finally {
      // We complete the init after 2 seconds:
      // - Any tries to save the scripts before initialisation completes are ignored immediately
      // - Checks for updates can proceed will wait for the completer and then proceed
      Future.delayed(const Duration(seconds: 2)).then((_) {
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.complete();
        }
      });
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
    // Wait until provider is initialized (+ a couple of seconds)
    await onInitialized;

    // If no scripts exist, don't execute
    if (_userScriptList.isEmpty) return 0;

    // Filter scripts that need checking
    final scriptsToCheck = _userScriptList
        .where((s) =>
            s.updateStatus != UserScriptUpdateStatus.localModified &&
            s.updateStatus != UserScriptUpdateStatus.noRemote &&
            s.url != null)
        .toList();

    // If no scripts need checking, return
    if (scriptsToCheck.isEmpty) return 0;

    int updates = 0;
    bool hasChanges = false;

    // Update process
    try {
      await Future.wait<void>(scriptsToCheck.map((s) {
        s.updateStatus = UserScriptUpdateStatus.updating;
        // Notify listeners of the change to show updating, but **do not save this to shared prefs**
        notifyListeners();

        return s.checkUpdateStatus().then((updateStatus) {
          if (updateStatus == UserScriptUpdateStatus.updateAvailable) updates++;

          if (s.updateStatus != updateStatus) {
            s.updateStatus = updateStatus;
            hasChanges = true;
          }
          // Notify listeners of the change after every row
          notifyListeners();
        }).catchError((e) {
          log(e);
          if (s.updateStatus != UserScriptUpdateStatus.error) {
            s.updateStatus = UserScriptUpdateStatus.error;
            hasChanges = true;
          }
          // Notify listeners of the change after every row
          notifyListeners();
        });
      }));

      // Only save if we have actual changes and at the end of all updates
      // so that we don't save the "updating" status
      if (hasChanges) {
        await _saveUserScriptsToStorage();
      }
    } catch (e, trace) {
      // Log the error but don't save corrupted state
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("SCRIPTS PROVIDER: error during checkForUpdates. Error: $e. Stack: $trace");
        FirebaseCrashlytics.instance.recordError(e, trace);
      }
      logToUser("SCRIPTS PROVIDER: error during script updates. Error: $e");
      // Reset any scripts that might be stuck in "updating" state
      for (final script in scriptsToCheck) {
        if (script.updateStatus == UserScriptUpdateStatus.updating) {
          script.updateStatus = UserScriptUpdateStatus.error;
        }
      }
      notifyListeners();
    }

    return updates;
  }

  Future<({int added, int failed, int removed})> addDefaultScripts({bool overwriteExisting = false}) async {
    int added = 0;
    int failed = 0;
    int removed = 0;

    if (overwriteExisting) {
      final originalCount = _userScriptList.length;
      _userScriptList.removeWhere((s) => s.isExample);
      removed = originalCount - _userScriptList.length;
    }

    final existingScriptNames = _userScriptList.map((s) => s.name.toLowerCase()).toSet();

    for (final url in defaultScriptUrls) {
      if (url == null) continue;

      final response = await UserScriptModel.fromURL(url, isExample: true);

      if (response.success && response.model != null) {
        if (!existingScriptNames.contains(response.model!.name.toLowerCase())) {
          if (_addScript(_userScriptList, response.model!, "addDefaultScripts")) {
            added++;
          }
        }
      } else {
        failed++;
      }
    }

    if (added > 0 || removed > 0) {
      _sort();
      await _saveUserScriptsToStorage();
      notifyListeners();
    }

    _checkForCustomApiKeyCandidates();

    return (
      added: added,
      failed: failed,
      removed: removed,
    );
  }

  Future<({bool success, String? message})> addUserScriptFromURL(String url, {bool? isExample}) async {
    final response = await UserScriptModel.fromURL(url, isExample: isExample);
    if (response.success && response.model != null) {
      if (_userScriptList.any((script) => script.name == response.model!.name)) {
        return (success: false, message: "Script with same name already exists");
      }

      if (_addScript(_userScriptList, response.model!, "addUserScriptFromURL")) {
        _sort();
        _saveUserScriptsToStorage();
        notifyListeners();
        return (success: true, message: null);
      } else {
        return (success: false, message: "Failed to add script safely");
      }
    } else {
      return (success: false, message: response.message);
    }
  }
}
