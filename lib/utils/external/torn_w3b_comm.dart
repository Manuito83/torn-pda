// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/models/trades/torn_w3b/torn_w3b_marketplace.dart';
import 'package:torn_pda/models/trades/torn_w3b/torn_w3b_receipt.dart';

class TornW3bComm {
  static Future<Map<int, int>> getMarketplacePrices() async {
    try {
      final response = await http.get(
        Uri.parse('https://weav3r.dev/api/marketplace'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final marketplace = tornW3bMarketplaceResponseFromJson(response.body);
        return {
          for (final item in marketplace.items)
            if (item.itemId != 0 && item.marketPrice > 0) item.itemId: item.marketPrice,
        };
      }

      throw Exception(response.body.isNotEmpty ? response.body : (response.reasonPhrase ?? 'Unknown error'));
    } catch (e, t) {
      FirebaseCrashlytics.instance.log('PDA TornW3B marketplace error');
      FirebaseCrashlytics.instance.recordError('PDA Error: $e', t);
      rethrow;
    }
  }

  static Future<TornW3bReceiptResponse> generateReceipt(
    int traderUserId,
    TornW3bReceiptRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://weav3r.dev/api/pricelist/$traderUserId'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: tornW3bReceiptRequestToJson(request),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return tornW3bReceiptResponseFromJson(response.body);
      }

      throw Exception(response.body.isNotEmpty ? response.body : (response.reasonPhrase ?? 'Unknown error'));
    } catch (e, t) {
      FirebaseCrashlytics.instance.log('PDA TornW3B receipt error');
      FirebaseCrashlytics.instance.recordError('PDA Error: $e', t);
      rethrow;
    }
  }

  static Future<TornW3bReceiptUpdateResponse> updateReceipt(
    String receiptId,
    TornW3bReceiptUpdateRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://weav3r.dev/api/updateReceipt/$receiptId'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: tornW3bReceiptUpdateRequestToJson(request),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return tornW3bReceiptUpdateResponseFromJson(response.body);
      }

      throw Exception(response.body.isNotEmpty ? response.body : (response.reasonPhrase ?? 'Unknown error'));
    } catch (e, t) {
      FirebaseCrashlytics.instance.log('PDA TornW3B receipt update error');
      FirebaseCrashlytics.instance.recordError('PDA Error: $e', t);
      rethrow;
    }
  }
}
