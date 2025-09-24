// Dart imports:
import 'dart:convert';
import 'dart:developer';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/revive_services/wolverines_revive_model.dart';

class WolverinesRevive {
  int? tornId;
  String? username;
  String? price;

  WolverinesRevive({
    required this.tornId,
    required this.username,
    required this.price,
  });

  Future<String> callMedic() async {
    final modelOut = WolverinesReviveModel()
      ..vendor = "The Wolverines"
      ..tornId = tornId
      ..source = "Torn PDA v$appVersion"
      ..username = username
      ..type = "revive";

    final bodyOut = wolverinesReviveModelToJson(modelOut);

    try {
      final response = await http.post(
        Uri.parse('https://api.no1irishstig.co.uk/request'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyOut,
      );

      if (response.statusCode == 200) {
        final details = json.decode(response.body);
        if (details["contract"]) {
          return "Contract request has been sent to The Wolverines. Thank you!";
        } else {
          return "Request has been sent to The Wolverines. Please pay your reviver $price. Thank you!";
        }
      } else if (response.statusCode == 400) {
        return "Error: bad payload sent";
      } else if (response.statusCode == 401) {
        return "Error: request denied, please contact The Wolverines leadership";
      } else if (response.statusCode == 403) {
        return "Error: blocked by vendor";
      } else if (response.statusCode == 429) {
        return "Error: you have already submitted a request to be revived";
      } else if (response.statusCode == 499) {
        return "Error: outdated model, please contact The Wolverines leadership";
      } else if (response.statusCode == 500) {
        return "Error: an unknown error has occurred, please report this to The Wolverines leadership";
      }
    } catch (e) {
      log(e.toString());
    }
    return "Error: an unknown error has occurred, please report this to The Wolverines leadership";
  }
}
