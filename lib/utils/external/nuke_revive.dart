// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/revive_services/nuke_revive_model.dart';

class NukeRevive {
  String playerId;
  String? playerName;
  String? playerFaction;
  String? playerLocation;

  NukeRevive({
    required this.playerId,
    required this.playerName,
    required this.playerFaction,
    required this.playerLocation,
  });

  Future<String> callMedic() async {
    final modelOut = NukeReviveModel()
      ..uid = playerId
      ..player = "$playerName [$playerId]"
      ..faction = playerFaction
      ..country = playerLocation
      ..appInfo = "Torn PDA v$appVersion";

    final bodyOut = nukeReviveModelToJson(modelOut);

    try {
      final response = await http.post(
        Uri.parse('https://www.nukefamily.org/dev/reviveme.php'),
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
