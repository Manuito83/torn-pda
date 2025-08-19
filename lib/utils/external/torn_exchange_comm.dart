// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_in.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_out.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_receipt.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';

class TornExchangeComm {
  static Future<TornExchangeInModel> submitItems(
    List<TradeItem> sellerItems,
    String sellerName,
    int tradeId,
    String buyerName,
  ) async {
    var inModel = TornExchangeInModel();

    List<String> itemNames = [];
    List<int> itemQuantities = [];

    for (var itemName in sellerItems) {
      itemNames.add(itemName.name);
    }

    for (var itemName in sellerItems) {
      itemQuantities.add(itemName.quantity);
    }

    final outModel = TornExchangeOutModel(
      sellerName: sellerName,
      userName: buyerName,
      quantities: itemQuantities,
      items: itemNames,
      tradeId: tradeId,
    );

    try {
      final response = await http
          .post(
            Uri.parse('https://tornexchange.com/new_extension_get_prices'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: tornExchangeOutModelToJson(outModel),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        inModel = tornExchangeInModelFromJson(response.body);
      } else {
        // Errors will return as 400
        inModel.serverError = true;
        inModel.serverErrorReason = response.reasonPhrase ?? response.body;
      }
    } catch (e, t) {
      inModel.serverError = true;
      inModel.serverErrorReason = "$e. $t";
      FirebaseCrashlytics.instance.log("PDA TornExchange comm error");
      FirebaseCrashlytics.instance.recordError("PDA Error: $e", t);
    }

    return inModel;
  }

  static Future<TornExchangeReceiptInModel> getReceipt(
    TornExchangeReceiptOutModel receiptOutModel,
  ) async {
    TornExchangeReceiptInModel receiptInModel = TornExchangeReceiptInModel();

    try {
      final response = await http
          .post(
            Uri.parse('https://tornexchange.com/new_create_receipt'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: tornExchangeReceiptOutModelToJson(receiptOutModel),
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        receiptInModel = tornExchangeReceiptInModelFromJson(response.body);
      } else {
        // Errors will return as 400
        receiptInModel.serverError = true;
      }
    } catch (e) {
      receiptInModel.serverError = true;
    }

    if (receiptInModel.tradeMessage.isNotEmpty) {
      receiptInModel.tradeMessage = receiptInModel.tradeMessage
          .replaceAll('&amp;', '&')
          .replaceAll('&#x27;', '\'')
          .replaceAll('&quot;', '"')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
    }
    return receiptInModel;
  }
}
