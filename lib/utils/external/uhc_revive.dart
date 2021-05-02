// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/revive_services/uhc_revive_model.dart';

class UhcRevive {
  int playerId;
  String playerName;
  String playerFaction;
  int playerFactionId;

  UhcRevive({
    @required this.playerId,
    @required this.playerName,
    @required this.playerFaction,
    @required this.playerFactionId,
  });

  Future<String> callMedic() async {
    var modelOut = UhcReviveModel()
      ..userID = playerId
      ..userName = "$playerName"
      ..factionName = playerFaction
      ..factionID = playerFactionId
      ..source = "Torn PDA v$appVersion";

    var bodyOut = uhcReviveModelToJson(modelOut);

    try {
      var response = await http.post(
        Uri.parse('https://elimination.me/api/request'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyOut,
      );

      if (response.statusCode == 200) {
        return "200";
      } else {
        var details = json.decode(response.body);
        return details["reason"];
      }
    } catch (e) {
      return "error";
    }
  }
}
