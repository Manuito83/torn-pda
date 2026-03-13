// Dart imports:
import 'dart:convert';
import 'dart:developer';
// Package imports:
import 'package:http/http.dart' as http;
// Project imports:
import 'package:torn_pda/models/profile/revive_services/combat_ready_revive_model.dart';

class CombatReadyRevive {
  int? tornId;
  String? username;
  String? faction;

  CombatReadyRevive({
    required this.tornId,
    required this.username,
    required this.faction,
  });

  Future<List<String?>> callMedic() async {
    final modelOut = CombatReadyReviveModel()
      ..userId = tornId.toString()
      ..userName = username
      ..faction = faction;

    final bodyOut = combatReadyReviveModelToJson(modelOut);

    try {
      final response = await http.post(
        Uri.parse('https://revive.cmbtready.workers.dev/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyOut,
      );

      final String code = response.statusCode.toString();
      String? message = json.decode(response.body)["message"];

      if (code == "500") {
        message = "Error: an unknown error has occurred, please report this to Combat Ready leadership";
      }

      return [code, message];
    } catch (e) {
      log(e.toString());
    }

    return ["Error", "Error: an unknown error has occurred, please report this to Combat Ready leadership"];
  }
}
