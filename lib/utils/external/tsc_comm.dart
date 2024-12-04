// Package imports:
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/tsc/tsc_response_model.dart';

class TSCComm {
  static Future<TscResponse> checkIfUserExists({required String targetId, required String ownApiKey}) async {
    late TscResponse tscModel;
    http.Response? response;

    try {
      Map<String, String> headers = {
        "Authorization": "10000000-6000-0000-0009-000000000001",
        "Content-Type": "application/json",
      };

      final data = {
        "userId": targetId,
        "apiKey": ownApiKey,
      };
      final body = json.encode(data);

      response = await http
          .post(
            Uri.parse('https://tsc.diicot.cc/next'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        tscModel = tscResponseFromJson(response.body);
      } else {
        //     export enum ErrorCode {
        //        InvalidRequest = 1,
        //        Maintenance = 2,
        //        InvalidApiKey = 3,
        //        InternalError = 4,
        //        UserDisabled = 5,
        //        CachedOnly = 6,
        //      }
        int errorCode = tscResponseFromJson(response.body).code ?? 0;
        String message;

        switch (errorCode) {
          case 1:
            message = "Invalid request. Please contact a PDA developer.";
            break;

          case 2:
            message = "TSC is undergoing maintenance. Please try again later.";
            break;

          case 3:
            message = "Invalid API key.";
            break;

          case 4:
            message = "An internal error has occurred. Please contact Mavri [2402357].";
            break;

          case 5:
            message = "Your account has been disabled.";
            break;

          case 6:
            message = "TSC is running in cache-only mode. This user couldn't be updated.";
            break;

          default:
            message = "Unknown error occurred. Please try again later.\nStatus Code: ${response.statusCode}";
            break;
        }

        tscModel = TscResponse(
          success: false,
          message: message,
          spy: null,
          code: errorCode,
        );
      }
    } catch (e, trace) {
      String message;
      if (e is TimeoutException) {
        message = "Request timed out.";
      } else {
        message = "Model error";
      }

      tscModel = TscResponse(success: false, message: message, spy: null);

      if (response != null) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.log("TSC Crash: $e, trace: $trace");
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("HTTP Response: ${response.body}", null);
        log("PDA Crash at TSC response: $e, trace: $trace");
        log("HTTP Response: ${response.body}");
      }
    }

    return tscModel;
  }
}
