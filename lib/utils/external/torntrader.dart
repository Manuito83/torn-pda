import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/trades/torntrader/torntrader_auth.dart';
import 'package:torn_pda/models/trades/torntrader/torntrader_out.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:http/http.dart' as http;

class TornTraderHandler {
  List<TradeItem> sellerItems;
  String tornPdaVersion;
  String sellerName;
  int tradeId;
  int buyerId;

  TornTraderHandler.checkIfAllowed({@required int buyerId}) {
    checkIfUserExists(buyerId).then((value) {
      return value;
    });
  }

  TornTraderHandler.submit({
    @required this.sellerItems,
    @required this.sellerName,
    @required this.tradeId,
    @required this.buyerId,
  }) {

    checkIfUserExists(buyerId).then((authModel) {
      if (authModel.error) {
        // TODO
      } else {
        if (!authModel.allowed) {
          // TODO
        } else if (authModel.allowed) {
          _submitToTornTrader();
        }
      }
    });
  }


  // TODO ******************************
  // TODO: CHANGE USER*/*/*/*/*/*/*/*/*/
  static Future<TornTraderAuthModel> checkIfUserExists(int user) async {
    var authModel = TornTraderAuthModel();
    try {
      var response = await http.post('https://torntrader.com/api/v1/users?user=2225097'); //TODO:$user
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

  _submitToTornTrader() {
    var outModel = TornTraderOutModel();
    outModel
      ..appVersion = appVersion
      ..tradeId = tradeId
      ..seller = sellerName
      ..buyer = buyerId
      ..items = List<Item>();

    for (var product in sellerItems) {
      var item = Item(
        name: product.name,
        quantity: product.quantity,
        id: product.id,
      );
      outModel.items.add(item);
    }

    print('lala');

  }
}
