// Package imports:
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/revive_services/nuke_revive_model.dart';

class NukeRevive {
  int playerId;
  String? playerName;
  int? playerFaction;
  String? playerLocation;

  NukeRevive({
    required this.playerId,
    required this.playerName,
    required this.playerFaction,
    required this.playerLocation,
  });

  Future<bool> callMedic() async {
    final modelOut = NukeReviveModel()
      ..tornPlayerId = playerId
      ..tornPlayerName = "$playerName [$playerId]"
      ..factionId = playerFaction
      ..tornPlayerCountry = playerLocation
      ..appInfo = "Torn PDA v$appVersion";

    final bodyOut = nukeReviveModelToJson(modelOut);

    try {
      final response = await http.post(
        Uri.parse('https://nuke.family/api/revive-request'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyOut,
      );

      if (response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at Nuke Revive Comm");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", null);
    }

    return false;
  }
}
