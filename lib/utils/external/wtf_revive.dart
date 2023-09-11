// Dart imports:
import 'dart:convert';
import 'dart:developer';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/revive_services/wtf_revive_model.dart';

class WtfRevive {
  int? tornId;
  String? username;
  String? faction;
  String country;

  WtfRevive({
    required this.tornId,
    required this.username,
    required this.faction,
    required this.country,
  });

  Future<List<String?>> callMedic() async {
    final modelOut = WtfReviveModel()
      ..userId = tornId.toString()
      ..userName = username
      ..faction = faction
      ..country = country
      ..requestChannel = "Torn PDA v$appVersion";

    final bodyOut = wtfReviveModelToJson(modelOut);

    try {
      final response = await http.post(
        Uri.parse('https://what-the-f.de/wtfapi/revive'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyOut,
      );

      final String code = response.statusCode.toString();
      String? message = json.decode(response.body)["message"];

      if (code == "500") {
        message = "Error: an unknown error has occurred, please report this to WTF leadership";
      }

      return [code, message];
    } catch (e) {
      log(e.toString());
    }
    return ["Error", "Error: an unknown error has occurred, please report this to WTF leadership"];
  }
}
