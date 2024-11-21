import 'package:get/get.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';

class ApiCallsV2 {
  /// Get item market listings
  /// PAYLOAD
  /// Required "id": Item id
  /// Optional "cat": This parameter is being replaced with 'bonus' parameter and will be removed on 1st December 2024.
  /// Optional "bonus": Used to filter weapons with a specific bonus.
  /// Optional "offset"
  static Future<dynamic> getMarketItemApi_v2({required Map<String, dynamic> payload}) async {
    final apiCaller = Get.find<ApiCallerController>();
    final apiResponse = await apiCaller.enqueueApiCall<MarketItemMarketResponse>(
      apiSelection_v2: ApiSelection_v2.marketItem,
      payload_v2: payload,
      apiCall: (client, apiKey) {
        return client.marketIdItemmarketGet(
          key: apiKey,
          id: payload["id"],
          cat: payload["cat"],
          bonus: payload["bonus"],
          offset: payload["offset"],
        );
      },
    );
    return apiResponse;
  }
}
