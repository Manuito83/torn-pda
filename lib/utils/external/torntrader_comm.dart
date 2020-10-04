import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/trades/torntrader/torntrader_auth.dart';
import 'package:torn_pda/models/trades/torntrader/torntrader_in.dart';
import 'package:torn_pda/models/trades/torntrader/torntrader_out.dart';
import 'package:http/http.dart' as http;

class TornTraderComm {

  static Future<TornTraderAuthModel> checkIfUserExists(int user) async {
    var authModel = TornTraderAuthModel();
    try {
      var response = await http.post('https://torntrader.com/api/v1/users?user=$user');
      if (response.statusCode == 200) {
        authModel = tornTraderAuthModelFromJson(response.body);
        authModel.error = false;
      } else {
        authModel.error = true;
      }
    } catch (e) {
      authModel.error = true;
    }
    return authModel;
  }

  static Future<TornTraderInModel> submitItems(sellerItems, sellerName, tradeId, buyerId) async {
    var inModel = TornTraderInModel();

    var authModel = await checkIfUserExists(buyerId);
    if (authModel.error) {
      inModel.serverError = true;
      return inModel;
    }

    if (!authModel.allowed) {
      inModel.authError = true;
      return inModel;
    }

    var outModel = TornTraderOutModel();
    outModel
      ..appVersion = appVersion
      ..tradeId = tradeId
      ..seller = sellerName
      ..buyer = buyerId
      ..items = List<ttOutItem>();

    for (var product in sellerItems) {
      var item = ttOutItem(
        name: product.name,
        quantity: product.quantity,
        id: product.id,
      );
      outModel.items.add(item);
    }

    try {
      var response = await http.post('https://torntrader.com/api/v1/trades',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': authModel.token,
        },
        body: tornTraderOutToJson(outModel),
      );

      if (response.statusCode == 200) {
        inModel = tornTraderInModelFromJson(response.body);
      } else {
        inModel.serverError = true;
      }
    } catch (e) {
      inModel.serverError = true;
    }

    return inModel;
  }

}
