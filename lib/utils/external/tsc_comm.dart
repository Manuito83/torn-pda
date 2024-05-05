// Package imports:
import 'dart:convert';
import 'dart:developer';

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
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        tscModel = tscResponseFromJson(response.body);
      } else {
        String message = "Connection Error ${response.statusCode}";

        int errorCode = tscResponseFromJson(response.body).code ?? 0;
        if (errorCode == 3) {
          message = "Invalid API key";
        }

        tscModel = TscResponse(
          success: false,
          message: message,
          spy: null,
          code: errorCode,
        );
      }
    } catch (e, trace) {
      tscModel = TscResponse(success: false, message: "Model error", spy: null);
      if (response != null) {
        FirebaseCrashlytics.instance.log("TSC Crash: $e, trace: $trace");
        FirebaseCrashlytics.instance.recordError("HTTP Response: ${response.body}", null);
        log("PDA Crash at TSC response: $e, trace: $trace");
        log("HTTP Response: ${response.body}");
      }
    }

    return tscModel;
  }
}
