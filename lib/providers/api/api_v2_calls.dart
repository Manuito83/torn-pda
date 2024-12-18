import 'dart:developer';

import 'package:get/get.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/models/profile/own_profile_misc.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';

class ApiCallsV2 {
  /// Get item market listings
  /// PAYLOAD
  /// Required "id": Item id
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
          bonus: payload["bonus"],
          offset: payload["offset"],
        );
      },
    );
    return apiResponse;
  }

  static Future<dynamic> getUserMarketItemsApi_v2() async {
    final apiCaller = Get.find<ApiCallerController>();
    final apiResponse = await apiCaller.enqueueApiCall<UserItemMarketResponse>(
      apiSelection_v2: ApiSelection_v2.marketItem,
      payload_v2: {},
      apiCall: (client, apiKey) {
        return client.userItemmarketGet(
          key: apiKey,
        );
      },
    );
    return apiResponse;
  }

  static Future<dynamic> getUserProfileMisc_v2() async {
    final apiCaller = Get.find<ApiCallerController>();
    final apiResponse = await apiCaller.enqueueApiCall<dynamic>(
      apiSelection_v2: ApiSelection_v2.userProfileMisc,
      payload_v2: {},
      apiCall: (client, apiKey) {
        return client.userGet(
          key: apiKey,
          selections: "money,education,workstats,battlestats,jobpoints,properties,skills,bazaar,itemmarket",
        );
      },
    );

    try {
      final ownProfileMisc = OwnProfileMisc.fromJson(apiResponse as Map<String, dynamic>);
      return ownProfileMisc;
    } catch (e, trace) {
      log("Error converting V2 OwnProfileMisc: $e, $trace");
      return null;
    }
  }

  static Future<dynamic> getOtherUserProfile_v2({required Map<String, dynamic> payload}) async {
    final apiCaller = Get.find<ApiCallerController>();
    final apiResponse = await apiCaller.enqueueApiCall<dynamic>(
      apiSelection_v2: ApiSelection_v2.otherUserProfile,
      payload_v2: payload,
      apiCall: (client, apiKey) {
        return client.userGet(
          key: apiKey,
          id: payload["id"],
          selections: "profile,personalstats,bazaar",
          cat: "all",
        );
      },
    );

    try {
      final otherProfile = OtherProfileModel.fromJson(apiResponse as Map<String, dynamic>);
      return otherProfile;
    } catch (e, trace) {
      log("Error converting V2 OtherProfileModel: $e, $trace");
      return null;
    }
  }
}
