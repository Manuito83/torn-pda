// Package imports:
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/yata/yata_stats_response_model.dart';

class YataStatsComm {
  static Future<YataStatsResponse> getYataStats({required String targetId, required String ownApiKey}) async {
    late YataStatsResponse yataModel;
    http.Response? response;

    try {
      response = await http
          .get(Uri.parse('https://yata.yt/api/v1/bs/$targetId/?key=$ownApiKey'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          yataModel = YataStatsResponse.fromJson(jsonDecode(response.body));
          return yataModel;
        } catch (e, trace) {
          FirebaseCrashlytics.instance.log("Yata Stats Crash at Model: $e, trace: $trace");
          FirebaseCrashlytics.instance.recordError("HTTP Response: ${response.body}", null);
          log("YATA Stats Crash at Model: $e, trace: $trace");
          return YataStatsResponse(
            success: false,
            error: YataStatsError(code: -1, error: "Error decoding YATA Stats response"),
          );
        }
      } else if (response.statusCode == 400) {
        // In case of code 400, the API sends a error string
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorModel = YataStatsError.fromJson(errorData['error']);
          return YataStatsResponse(
            success: false,
            error: YataStatsError(code: response.statusCode, error: errorModel.error),
          );
        } catch (e) {
          return YataStatsResponse(
            success: false,
            error: YataStatsError(
              code: response.statusCode,
              error: "Error: status code ${response.statusCode}",
            ),
          );
        }
      } else {
        return YataStatsResponse(
          success: false,
          error: YataStatsError(
            code: response.statusCode,
            error: "Error: status code ${response.statusCode}",
          ),
        );
      }
    } on TimeoutException catch (e) {
      FirebaseCrashlytics.instance.log("YATA Stats Timeout: $e");
      log("Yata Stats Timeout: $e");
      return YataStatsResponse(
        success: false,
        error: YataStatsError(
          code: -1,
          error: "Error: connection timed out (YATA is not responding on time)",
        ),
      );
    } catch (e, trace) {
      if (response != null) {
        FirebaseCrashlytics.instance.log("Yata Stats (global): $e, trace: $trace");
        FirebaseCrashlytics.instance.recordError("HTTP Response: ${response.body}", null);
        log("PDA Crash at YATA Stats (global): $e, trace: $trace");
        log("HTTP Response: ${response.body}");
      }
      return YataStatsResponse(
        success: false,
        error: YataStatsError(
          code: -1,
          error: "Network Error",
        ),
      );
    }
  }
}
