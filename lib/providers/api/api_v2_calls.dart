// ignore_for_file: non_constant_identifier_names

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
      apiCall: (client, apiKey) {
        return client.marketIdItemmarketGet(
          id: payload["id"],
          bonus: payload["bonus"],
        );
      },
    );
    return apiResponse;
  }

  static Future<dynamic> getUserMarketItemsApi_v2() async {
    final apiCaller = Get.find<ApiCallerController>();
    final apiResponse = await apiCaller.enqueueApiCall<UserItemMarketResponse>(
      apiSelection_v2: ApiSelection_v2.marketItem,
      apiCall: (client, apiKey) {
        return client.userItemmarketGet();
      },
    );
    return apiResponse;
  }

  static Future<dynamic> getUserProfileMisc_v2() async {
    final apiCaller = Get.find<ApiCallerController>();
    final apiResponse = await apiCaller.enqueueApiCall<dynamic>(
      apiSelection_v2: ApiSelection_v2.userProfileMisc,
      apiCall: (client, apiKey) {
        return client.userGet(
          selections: "money,education,workstats,battlestats,jobpoints,properties,skills,bazaar,itemmarket",
        );
      },
    );

    if (apiResponse is ApiError) return null;
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
      apiCall: (client, apiKey) {
        return client.userGet(
          id: payload["id"],
          selections: "profile,personalstats,bazaar",
          cat: "all",
        );
      },
    );

    if (apiResponse is ApiError) return null;
    try {
      final otherProfile = OtherProfileModel.fromJson(apiResponse as Map<String, dynamic>);
      return otherProfile;
    } catch (e, trace) {
      log("Error converting V2 OtherProfileModel: $e, $trace");
      return null;
    }
  }

  static Future<dynamic> getTornCalendar_v2() async {
    final apiCaller = Get.find<ApiCallerController>();
    final apiResponse = await apiCaller.enqueueApiCall<dynamic>(
      apiSelection_v2: ApiSelection_v2.tornCalendar,
      apiCall: (client, apiKey) {
        return client.tornCalendarGet();
      },
    );

    if (apiResponse is TornCalendarResponse) {
      return apiResponse;
    }

    log("Error converting V2 TornCalendarModel");
    return null;
  }

  static Future<dynamic> getUserOC2Crime_v2() async {
    final apiCaller = Get.find<ApiCallerController>();
    final apiResponse = await apiCaller.enqueueApiCall<dynamic>(
      apiSelection_v2: ApiSelection_v2.oc2UserCrime,
      apiCall: (client, apiKey) {
        return client.userOrganizedcrimeGet();
      },
    );

    if (apiResponse is UserOrganizedCrimeResponse) {
      return apiResponse;
    }

    log("No OC2 crime found");
    return null;
  }
}
