// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/models/trades/torntrader/torntrader_auth.dart';

class TornStatsCentralComm {
  static Future<bool> checkIfUserExists(int? user) async {
    //var authModel = ...;
    try {
      final response = await http.post(Uri.parse('https://...')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        //authModel = modelFromJson(response.body);
        //authModel.error = false;
      } else {
        //authModel.error = true;
      }
    } catch (e) {
      //authModel.error = true;
    }
    // TODO: Placeholder, change to model
    return true;
  }
}
