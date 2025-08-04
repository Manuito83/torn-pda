import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:torn_pda/firebase_options.dart';
import 'package:torn_pda/models/appwidget/appwidget_api_model.dart';
import 'package:torn_pda/models/chaining/attack_full_model.dart';
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/company/employees_model.dart';
import 'package:torn_pda/models/education_model.dart';
import 'package:torn_pda/models/faction/faction_attacks_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/perks/user_perks_model.dart';
import 'package:torn_pda/models/profile/basic_profile_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/models/property_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_user_model.dart';
import 'package:torn_pda/models/travel/travel_model.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/utils/isolates.dart';

class ApiCallsV1 {
  static Future<dynamic> getTravel() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.travel).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return TravelModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getAppWidgetInfo({required int limit, required String? forcedApiKey}) async {
    dynamic apiResult;
    // NOTE: we don't use the ApiCallerController with Getx here, but instead call directly
    // as the app widget won'e be able to find the controller while in the background!
    final apiCaller = ApiCallerController();
    await apiCaller
        .enqueueApiCall(apiSelection: ApiSelection_v1.appWidget, limit: limit, forcedApiKey: forcedApiKey)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return AppWidgetApiModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        // Need to initialize Firebase in the isolate for Crashlytics (Api Caller) to work in this isolate
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getAppWidgetRankedWars({required String? forcedApiKey}) async {
    dynamic apiResult;
    // NOTE: we don't use the ApiCallerController with Getx here, but instead call directly
    // as the app widget won'e be able to find the controller while in the background!
    final apiCaller = ApiCallerController();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.rankedWars, forcedApiKey: forcedApiKey).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return RankedWarsModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        // Need to initialize Firebase in the isolate for Crashlytics (Api Caller) to work in this isolate
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getOwnProfileBasic({String? forcedApiKey = ""}) async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.ownBasic, forcedApiKey: forcedApiKey).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return OwnProfileBasic.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getOwnProfileExtended({required int limit, String forcedApiKey = ""}) async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller
        .enqueueApiCall(apiSelection: ApiSelection_v1.ownExtended, limit: limit, forcedApiKey: forcedApiKey)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return OwnProfileExtended.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getEvents({required int limit, int? from}) async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.events, limit: limit, from: from).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        List<Event> eventsList = <Event>[];
        if (apiResult['events'].length > 0) {
          for (final Map<String, dynamic> eventData in apiResult['events'].values) {
            eventsList.add(Event.fromJson(eventData));
          }
        }
        return eventsList;
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getOwnPersonalStats() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.ownPersonalStats).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return OwnPersonalStatsModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getOtherProfileBasic({required String? playerId}) async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(prefix: playerId, apiSelection: ApiSelection_v1.basicProfile).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return BasicProfileModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getTarget({required String? playerId}) async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(prefix: playerId, apiSelection: ApiSelection_v1.target).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return TargetModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getAttacks() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.attacks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return AttackModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getAttacksFull() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.attacksFull).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return AttackFullModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getFactionAttacks() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.factionAttacks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return FactionAttacksModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getChainStatus() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.chainStatus).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return ChainModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getBarsAndPlayerStatus() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.barsAndPlayerStatus).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return BarsStatusCooldownsModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getItems() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.items).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return ItemsModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getEducation() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.education).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return TornEducationModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getFaction({required String factionId}) async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(prefix: factionId, apiSelection: ApiSelection_v1.faction).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return FactionModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getFactionCrimes({required String playerId}) async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.factionCrimes).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError && apiResult != null) {
      try {
        //Stopwatch stopwatch = new Stopwatch()..start();
        //var processedModel = await FactionCrimesModel.fromJson(apiResult);
        final isolateArgs = <dynamic>[];
        isolateArgs.add(playerId);
        isolateArgs.add(apiResult);
        final processedModel = await compute(isolateDecodeFactionCrimes, isolateArgs);
        //log('isolateDecodeFactionCrimes executed in ${stopwatch.elapsed}');
        return processedModel;
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getFriends({required String playerId}) async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(prefix: playerId, apiSelection: ApiSelection_v1.friends).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return FriendModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getProperty({required String propertyId}) async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(prefix: propertyId, apiSelection: ApiSelection_v1.property).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return PropertyV1.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getAllStocks() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.tornStocks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return StockMarketModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getUserStocks() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.userStocks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return StockMarketUserModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getUserPerks() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.perks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return UserPerksModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getRankedWars() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.rankedWars).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return RankedWarsModel.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  static Future<dynamic> getCompanyEmployees() async {
    dynamic apiResult;
    final apiCaller = Get.find<ApiCallerController>();
    await apiCaller.enqueueApiCall(apiSelection: ApiSelection_v1.companyEmployees).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return CompanyEmployees.fromJson(apiResult as Map<String, dynamic>);
      } catch (e, trace) {
        if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }
}
