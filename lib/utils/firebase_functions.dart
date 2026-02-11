import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';

final firebaseFunctions = _FirebaseFunctions();

class _FirebaseFunctions {
  final String region = 'us-east4';

  Future<String> _getProjectId() async {
    FirebaseApp app = Firebase.app();
    return app.options.projectId;
  }

  /// Helper function to call Cloud Functions via HTTP for Windows
  ///
  /// Faction Assist and Cloud Backups expect [data] in different formats (TODO... correct?)
  /// To maintain compatibility with Android/iOS we can specify whether to wrap the [data] field as a JSON string
  /// or send it as an object
  ///
  /// - [functionName]: The name of the Cloud Function to call
  /// - [data]: The data to send to the Cloud Function
  /// - [wrapDataAsJsonString]: Whether to wrap the 'data' field as a JSON string.
  Future<dynamic> _callHttpFunctionForDesktop(
    String functionName,
    Map<String, dynamic> data, {
    bool wrapDataAsJsonString = true,
  }) async {
    String projectId = await _getProjectId();

    String url = 'https://$region-$projectId.cloudfunctions.net/$functionName';

    // CAUTION! DEBUG: Use local emulator URL if in debug mode
    /*
    if (kDebugMode) {
      url = "http://localhost:5001/$projectId/$region/$functionName";
    }
    */

    // Retrieve the Firebase Auth ID token
    String? idToken = await FirebaseAuth.instance.currentUser!.getIdToken();

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    // Decide whether to wrap [data] as a JSON string or send as an object
    final requestBody = wrapDataAsJsonString ? json.encode({'data': json.encode(data)}) : json.encode({'data': data});

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: requestBody,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData.containsKey('result')) {
        final dynamic result = responseData['result'];
        if (result is String) {
          // Parse the JSON string into a Map
          final Map<String, dynamic> parsedResult = json.decode(result);
          return parsedResult;
        } else if (result is Map<String, dynamic>) {
          return result;
        } else if (result is int || result is bool) {
          // Return the result directly if it's a primitive type
          return result;
        } else {
          throw Exception('Unexpected result type: ${result.runtimeType}');
        }
      } else {
        throw Exception('Invalid response from Cloud Function');
      }
    } else {
      throw Exception('Error calling Cloud Function: ${response.statusCode} ${response.body}');
    }
  }

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
    String ffsStats = "",
    String fairFight = "",
  }) async {
    final String functionName = 'factionAssist-sendAssistMessage';

    Map<String, dynamic> data = {
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
      'ffsStats': ffsStats,
      'fairFight': fairFight,
    };

    if (Platform.isWindows) {
      final result = await _callHttpFunctionForDesktop(functionName, data, wrapDataAsJsonString: false);
      return result as int;
    } else {
      // Android / iOS
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-east4',
      ).httpsCallable(functionName);

      final HttpsCallableResult results = await callable.call(data);
      return results.data;
    }
  }

  Future<bool> sendAlertsTroubleshootingTest() async {
    final String functionName = 'troubleshooting-sendTroubleshootingAutoNotification';

    if (Platform.isWindows) {
      final result = await _callHttpFunctionForDesktop(functionName, {});
      return result as bool;
    } else {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-east4',
      ).httpsCallable(functionName);

      final HttpsCallableResult results = await callable.call();
      return results.data;
    }
  }

  Future<Map<String, dynamic>> saveUserPrefs({
    required String apiKey,
    required int userId,
    required Map<String, dynamic> prefs,
  }) async {
    final String functionName = 'prefsBackup-saveUserPrefs';

    Map<String, dynamic> data = {
      'key': apiKey,
      'id': userId,
      'prefs': prefs,
    };

    if (Platform.isWindows) {
      final result = await _callHttpFunctionForDesktop(functionName, data);
      return result as Map<String, dynamic>;
    } else {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-east4',
      ).httpsCallable(functionName);

      final HttpsCallableResult results = await callable.call(json.encode(data));
      return json.decode(results.data);
    }
  }

  Future<Map<String, dynamic>?> lookupUserByApiKey({
    required String apiKey,
    required String currentUid,
    String? platform,
  }) async {
    const String functionName = 'lookupPlayerByApiKey';

    final Map<String, dynamic> data = {
      'apiKey': apiKey,
      'currentUid': currentUid,
      if (platform != null && platform.isNotEmpty) 'platform': platform,
    };

    try {
      if (Platform.isWindows) {
        final result = await _callHttpFunctionForDesktop(functionName, data, wrapDataAsJsonString: false);
        return result as Map<String, dynamic>?;
      } else {
        final HttpsCallable callable = FirebaseFunctions.instanceFor(region: region).httpsCallable(functionName);
        final HttpsCallableResult results = await callable.call(data);
        if (results.data is Map<String, dynamic>) {
          return results.data as Map<String, dynamic>;
        }
        return null;
      }
    } catch (e, trace) {
      log("Error in lookupUserByApiKey: $e\n$trace");
    }
    return null;
  }

  Future<Map<String, dynamic>> getUserPrefs({
    required String apiKey,
    required int userId,
  }) async {
    final String functionName = 'prefsBackup-getUserPrefs';

    Map<String, dynamic> data = {
      'key': apiKey,
      'id': userId,
    };

    if (Platform.isWindows) {
      final result = await _callHttpFunctionForDesktop(functionName, data);
      return result as Map<String, dynamic>;
    } else {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-east4',
      ).httpsCallable(functionName);

      final HttpsCallableResult results = await callable.call(json.encode(data));
      return json.decode(results.data);
    }
  }

  Future<Map<String, dynamic>> deleteUserPrefs({
    required String apiKey,
    required int userId,
  }) async {
    final String functionName = 'prefsBackup-deleteUserPrefs';

    Map<String, dynamic> data = {
      'key': apiKey,
      'id': userId,
    };

    if (Platform.isWindows) {
      final result = await _callHttpFunctionForDesktop(functionName, data);
      return result as Map<String, dynamic>;
    } else {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-east4',
      ).httpsCallable(functionName);

      final HttpsCallableResult results = await callable.call(json.encode(data));
      return json.decode(results.data);
    }
  }

  Future<Map<String, dynamic>> saveOwnBackupShare({
    required String apiKey,
    required int userId,
    required bool ownShareEnabled,
    required String ownSharePassword,
    required List<String> prefs,
  }) async {
    final String functionName = 'prefsBackup-setOwnSharePrefs';

    Map<String, dynamic> data = {
      'key': apiKey,
      'id': userId,
      'ownShareEnabled': ownShareEnabled,
      'ownSharePassword': ownSharePassword,
      'ownSharePrefs': prefs,
    };

    if (Platform.isWindows) {
      final result = await _callHttpFunctionForDesktop(functionName, data);
      return result as Map<String, dynamic>;
    } else {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-east4',
      ).httpsCallable(functionName);

      final HttpsCallableResult results = await callable.call(json.encode(data));
      return json.decode(results.data);
    }
  }

  Future<Map<String, dynamic>> getImportShare({
    required int shareId,
    required String sharePassword,
  }) async {
    final String functionName = 'prefsBackup-getImportShare';

    Map<String, dynamic> data = {
      'shareId': shareId,
      'sharePassword': sharePassword,
    };

    if (Platform.isWindows) {
      final result = await _callHttpFunctionForDesktop(functionName, data);
      return result as Map<String, dynamic>;
    } else {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-east4',
      ).httpsCallable(functionName);

      final HttpsCallableResult results = await callable.call(json.encode(data));
      return json.decode(results.data);
    }
  }

  Future<void> registerLiveActivityPushToStartToken({
    required String token,
    required String activityType,
  }) async {
    if (!Platform.isIOS) return;

    final String functionName = 'liveActivities-registerPushToStartToken';

    Map<String, dynamic> data = {
      'token': token,
      'activityType': activityType,
    };

    try {
      if (Platform.isWindows) {
        await _callHttpFunctionForDesktop(functionName, data, wrapDataAsJsonString: false);
      } else {
        final HttpsCallable callable = FirebaseFunctions.instanceFor(
          region: 'us-east4',
        ).httpsCallable(functionName);
        await callable.call(data);
      }
      log("Successfully called registerPushToStartToken for type: $activityType");
    } catch (e) {
      log("Error calling registerPushToStartToken: $e");
    }
  }
}
