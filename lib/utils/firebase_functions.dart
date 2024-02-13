import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

final firebaseFunctions = _FirebaseFunctions();

class _FirebaseFunctions {
  Future<int> sendAttackAssistMessage({
    required String attackId,
    String? attackName = "",
    String attackLevel = "",
    String attackLife = "",
    String attackAge = "",
    String estimatedStats = "",
    String xanax = "unk",
    String refills = "unk",
    String drinks = "unk",
    String exactStats = "",
  }) async {
    //################
    // ASSIST MESSAGES
    final HttpsCallable callable = FirebaseFunctions.instanceFor(
      region: 'us-east4',
    ).httpsCallable(
      'factionAssist-sendAssistMessage',
    );

    final HttpsCallableResult results = await callable.call(<String, dynamic>{
      'attackId': attackId,
      'attackName': attackName,
      'attackLevel': attackLevel,
      'attackLife': attackLife,
      'attackAge': attackAge,
      'estimatedStats': estimatedStats,
      'xanax': xanax,
      'refills': refills,
      'drinks': drinks,
      'exactStats': exactStats,
    });

    // Data comes with number of people notified
    return results.data;
  }

  //###################
  // PREFERENCES BACKUP
  Future<Map<String, dynamic>> saveUserPrefs({
    required String apiKey,
    required int userId,
    required Map<String, dynamic> prefs,
  }) async {
    final HttpsCallable callable = FirebaseFunctions.instanceFor(
      region: 'us-east4',
    ).httpsCallable(
      'prefsBackup-saveUserPrefs',
    );

    Map<String, dynamic> data = {
      'key': apiKey,
      'id': userId,
      'prefs': prefs,
    };

    String jsonData = json.encode(data);

    final HttpsCallableResult results = await callable.call(jsonData);

    return json.decode(results.data);
  }

  Future<Map<String, dynamic>> getUserPrefs({
    required String apiKey,
    required int userId,
  }) async {
    final HttpsCallable callable = FirebaseFunctions.instanceFor(
      region: 'us-east4',
    ).httpsCallable(
      'prefsBackup-getUserPrefs',
    );

    Map<String, dynamic> data = {
      'key': apiKey,
      'id': userId,
    };

    String jsonData = json.encode(data);

    final HttpsCallableResult results = await callable.call(jsonData);

    return json.decode(results.data);
  }

  Future<Map<String, dynamic>> deleteUserPrefs({
    required String apiKey,
    required int userId,
  }) async {
    final HttpsCallable callable = FirebaseFunctions.instanceFor(
      region: 'us-east4',
    ).httpsCallable(
      'prefsBackup-deleteUserPrefs',
    );

    Map<String, dynamic> data = {
      'key': apiKey,
      'id': userId,
    };

    String jsonData = json.encode(data);

    final HttpsCallableResult results = await callable.call(jsonData);

    return json.decode(results.data);
  }

  Future<Map<String, dynamic>> saveOwnBackupShare({
    required String apiKey,
    required int userId,
    required bool ownShareEnabled,
    required String ownSharePassword,
    required List<String> prefs,
  }) async {
    final HttpsCallable callable = FirebaseFunctions.instanceFor(
      region: 'us-east4',
    ).httpsCallable(
      'prefsBackup-setOwnSharePrefs',
    );

    Map<String, dynamic> data = {
      'key': apiKey,
      'id': userId,
      'ownShareEnabled': ownShareEnabled,
      'ownSharePassword': ownSharePassword,
      'ownSharePrefs': prefs,
    };

    String jsonData = json.encode(data);

    final HttpsCallableResult results = await callable.call(jsonData);

    return json.decode(results.data);
  }

  Future<Map<String, dynamic>> getImportShare({
    required int shareId,
    required String sharePassword,
  }) async {
    final HttpsCallable callable = FirebaseFunctions.instanceFor(
      region: 'us-east4',
    ).httpsCallable(
      'prefsBackup-getImportShare',
    );

    Map<String, dynamic> data = {
      'shareId': shareId,
      'sharePassword': sharePassword,
    };

    String jsonData = json.encode(data);

    final HttpsCallableResult results = await callable.call(jsonData);

    return json.decode(results.data);
  }
}
