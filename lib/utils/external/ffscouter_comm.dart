import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_key_models.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_stats_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';

class FFScouterResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int? errorCode;

  FFScouterResult({required this.success, this.data, this.errorMessage, this.errorCode});
}

class FFScouterComm {
  static const String _baseUrl = 'https://ffscouter.com/api/v1';

  /// Fetches battle stats estimates for up to 205 targets at once
  /// Rate limit: 20 requests per minute per IP
  static Future<FFScouterResult<List<FFScouterPlayerStats>>> getStats({
    required String key,
    required List<int> targetIds,
    int timeout = 20,
  }) async {
    try {
      if (targetIds.isEmpty || targetIds.length > 205) {
        return FFScouterResult(
          success: false,
          errorMessage: "Target list must contain between 1 and 205 IDs",
        );
      }

      final targetsParam = targetIds.join(',');
      final uri = Uri.parse('$_baseUrl/get-stats?key=$key&targets=$targetsParam');

      final response = await http.get(uri).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final stats = ffScouterStatsFromJson(response.body);
        return FFScouterResult(success: true, data: stats);
      } else {
        final error = FFScouterErrorResponse.fromJson(json.decode(response.body));
        return FFScouterResult(
          success: false,
          errorMessage: error.error ?? "Unknown error",
          errorCode: error.code,
        );
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      log("FFScouterComm.getStats error: $e");
      FirebaseCrashlytics.instance.recordError("FFScouter getStats error: $e", stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  /// Fetches recommended targets based on filter criteria.
  /// Rate limit: 5 requests per minute per IP.
  static Future<FFScouterResult<FFScouterTargetsResponse>> getTargets({
    required String key,
    String? preset,
    int? minLevel,
    int? maxLevel,
    int? inactiveOnly,
    double? minFf,
    double? maxFf,
    int? limit,
    int? factionless,
    int timeout = 20,
  }) async {
    try {
      final queryParams = <String, String>{'key': key};

      if (preset != null) {
        queryParams['preset'] = preset;
      } else {
        if (minLevel != null) queryParams['minlevel'] = minLevel.toString();
        if (maxLevel != null) queryParams['maxlevel'] = maxLevel.toString();
        if (inactiveOnly != null) queryParams['inactiveonly'] = inactiveOnly.toString();
        if (minFf != null) queryParams['minff'] = minFf.toStringAsFixed(2);
        if (maxFf != null) queryParams['maxff'] = maxFf.toStringAsFixed(2);
        if (factionless != null) queryParams['factionless'] = factionless.toString();
      }

      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$_baseUrl/get-targets').replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = ffScouterTargetsFromJson(response.body);
        return FFScouterResult(success: true, data: data);
      } else {
        final error = FFScouterErrorResponse.fromJson(json.decode(response.body));
        return FFScouterResult(
          success: false,
          errorMessage: error.error ?? "Unknown error",
          errorCode: error.code,
        );
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      log("FFScouterComm.getTargets error: $e");
      FirebaseCrashlytics.instance.recordError("FFScouter getTargets error: $e", stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  /// Checks whether an API key is registered with FFScouter.
  /// Rate limit: 10 requests per minute per IP.
  /// Note: this endpoint does NOT register the key or make external requests.
  static Future<FFScouterResult<FFScouterCheckKeyResponse>> checkKey({
    required String key,
    int timeout = 15,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/check-key?key=$key');
      final response = await http.get(uri).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = ffScouterCheckKeyFromJson(response.body);
        return FFScouterResult(success: true, data: data);
      } else {
        final error = FFScouterErrorResponse.fromJson(json.decode(response.body));
        return FFScouterResult(
          success: false,
          errorMessage: error.error ?? "Unknown error",
          errorCode: error.code,
        );
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      log("FFScouterComm.checkKey error: $e");
      FirebaseCrashlytics.instance.recordError("FFScouter checkKey error: $e", stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  /// Registers an API key with FFScouter.
  /// Rate limit: 3 requests per minute per IP.
  /// IMPORTANT: The user MUST have agreed to FFScouter's data policy and terms
  /// before calling this method (required by Torn rules).
  static Future<FFScouterResult<FFScouterRegisterResponse>> registerKey({
    required String key,
    int timeout = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/register');
      final body = json.encode({
        'key': key,
        'agree_to_data_policy': true,
        'signup_source': 'TornPDA',
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = ffScouterRegisterFromJson(response.body);
        return FFScouterResult(success: true, data: data);
      } else {
        final error = FFScouterErrorResponse.fromJson(json.decode(response.body));
        return FFScouterResult(
          success: false,
          errorMessage: error.error ?? "Unknown error",
          errorCode: error.code,
        );
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      log("FFScouterComm.registerKey error: $e");
      FirebaseCrashlytics.instance.recordError("FFScouter registerKey error: $e", stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }
}
