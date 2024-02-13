// Package imports:
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/tsc/tsc_response_model.dart';

class TSCComm {
  static Future<TscResponse> checkIfUserExists({required String targetId, required String ownApiKey}) async {
    late TscResponse tscModel;

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

      final response = await http
          .post(
            Uri.parse('https://tsc.diicot.cc/stats/update'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        tscModel = tscResponseFromJson(response.body);
      } else {
        tscModel = TscResponse(success: false, message: "Connection Error ${response.statusCode}", spy: null);
      }
    } catch (e) {
      tscModel = TscResponse(success: false, message: "Model error", spy: null);
    }

    return tscModel;
  }
}
