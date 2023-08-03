// Dart imports:
import 'dart:convert';
import 'dart:developer';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/revive_services/hela_revive_model.dart';

class HelaRevive {
  int? tornId;
  String? username;

  HelaRevive({
    required this.tornId,
    required this.username,
  });

  Future<String> callMedic() async {
    var modelOut = HelaReviveModel()
      ..vendor = "HeLa"
      ..tornId = tornId
      ..source = "Torn PDA v$appVersion"
      ..username = username
      ..type = "revive";

    var bodyOut = helaReviveModelToJson(modelOut);

    try {
      var response = await http.post(
        Uri.parse('https://api.no1irishstig.co.uk/request'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyOut,
      );

      if (response.statusCode == 200) {
        var details = json.decode(response.body);
        if (details["contract"]) {
          return "Contract request has been sent to HeLa. Thank you!";
        } else {
          return "Request has been sent to HeLa. Please pay your reviver a Xanax or 1 million TCD. Thank you!";
        }
      } else if (response.statusCode == 400) {
        return "Error: bad payload sent";
      } else if (response.statusCode == 401) {
        return "Error: request denied, please contact HeLa leadership";
      } else if (response.statusCode == 403) {
        return "Error: blocked by vendor";
      } else if (response.statusCode == 429) {
        return "Error: you have already submitted a request to be revived";
      } else if (response.statusCode == 499) {
        return "Error: outdated model, please contact HeLa leadership";
      } else if (response.statusCode == 500) {
        return "Error: an unknown error has occurred, please report this to HeLa leadership";
      }
    } catch (e) {
      log(e.toString());
    }
    return "Error: an unknown error has occurred, please report this to HeLa leadership";
  }
}
