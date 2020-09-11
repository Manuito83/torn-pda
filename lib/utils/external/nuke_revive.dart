import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/profile/nuke_revive/nuke_revive_model.dart';

class NukeRevive {
  String playerId;
  String playerName;
  String playerFaction;
  String playerLocation;

  NukeRevive({
    @required this.playerId,
    @required this.playerName,
    @required this.playerFaction,
    @required this.playerLocation,
  });

  Future<String> callMedic() async {
    var modelOut = NukeReviveModel()
      ..uid = playerId
      ..player = playerName
      ..faction = playerFaction
      ..country = playerLocation;

    var bodyOut = nukeReviveModelToJson(modelOut);

    try {
      var response = await http.post('AAAAhttps://www.nukefamily.org/dev/reviveme.php',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyOut,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }
}
