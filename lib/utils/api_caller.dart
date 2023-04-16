// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:torn_pda/firebase_options.dart';
import 'package:torn_pda/models/appwidget/appwidget_api_model.dart';

// Project imports:
import 'package:torn_pda/models/chaining/attack_full_model.dart';
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/education_model.dart';
import 'package:torn_pda/models/faction/faction_attacks_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/models/inventory_model.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/market/market_item_model.dart';
import 'package:torn_pda/models/perks/user_perks_model.dart';
import 'package:torn_pda/models/profile/basic_profile_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/own_profile_misc.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/models/property_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_user_model.dart';
import 'package:torn_pda/models/travel/travel_model.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/isolates.dart';

import '../main.dart';

/*
enum ApiType {
  user,
  faction,
  torn,
  property,
  market,
}
*/

enum ApiSelection {
  appWidget,
  travel,
  ownBasic,
  ownExtended,
  ownPersonalStats,
  ownMisc,
  bazaar,
  otherProfile,
  basicProfile,
  target,
  attacks,
  attacksFull,
  chainStatus,
  bars,
  items,
  inventory,
  education,
  faction,
  factionCrimes,
  factionAttacks,
  friends,
  property,
  userStocks,
  tornStocks,
  marketItem,
  perks,
  rankedWars,
}

class ApiError {
  int errorId;
  String errorReason = "";
  String pdaErrorDetails = "";
  ApiError({this.errorId = 0, this.pdaErrorDetails = ""}) {
    switch (errorId) {
      // Torn PDA codes
      case 100:
        errorReason = 'connection timed out';
        break;
      // Torn PDA codes
      case 101:
        errorReason = 'issue with data model';
        pdaErrorDetails = pdaErrorDetails;
        break;
      // Torn codes
      case 0:
        errorReason = 'no connection';
        pdaErrorDetails = pdaErrorDetails;
        break;
      case 1:
        errorReason = 'key is empty';
        break;
      case 2:
        errorReason = 'incorrect Key';
        break;
      case 3:
        errorReason = 'wrong type';
        break;
      case 4:
        errorReason = 'wrong fields';
        break;
      case 5:
        errorReason = 'too many requests per user (max 100 per minute)';
        break;
      case 6:
        errorReason = 'incorrect ID';
        break;
      case 7:
        errorReason = 'incorrect ID-entity relation';
        break;
      case 8:
        errorReason = 'current IP is banned for a small period of time because of abuse';
        break;
      case 9:
        errorReason = 'API disabled (probably under maintenance by Torn\'s developers)!';
        break;
      case 10:
        errorReason = 'key owner is in federal jail';
        break;
      case 11:
        errorReason = 'key change error: You can only change your API key once every 60 seconds';
        break;
      case 12:
        errorReason = 'key read error: Error reading key from Database';
        break;
      case 13:
        errorReason = 'key is temporary disabled due to inactivity (owner hasn\'t been online for more than 7 days).';
        break;
      case 14:
        errorReason = 'daily read limit reached.';
        break;
      case 15:
        errorReason = 'an error code specifically for testing purposes that has no dedicated meaning.';
        break;
      case 16:
        errorReason = 'access level of this key is not high enough: Torn PDA request at least a Limited key.';
        break;
      case 17:
        errorReason = 'backend error occurred, please try again.';
        break;
    }
  }
}

class TornApiCaller {
  Future<dynamic> getAppWidgetInfo({@required int limit, @required String forcedApiKey}) async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.appWidget, limit: limit, forcedApiKey: forcedApiKey).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return AppWidgetApiModel.fromJson(apiResult);
      } catch (e, trace) {
        // Need to initialize Firebase in the isolate for Crashlytics (Api Caller) to work in this isolate
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getTravel() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.travel).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return TravelModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getOwnProfileBasic({String forcedApiKey = ""}) async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.ownBasic, forcedApiKey: forcedApiKey).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return OwnProfileBasic.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getOwnProfileExtended({@required int limit, String forcedApiKey = ""}) async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.ownExtended, limit: limit, forcedApiKey: forcedApiKey).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return OwnProfileExtended.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getOwnPersonalStats() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.ownPersonalStats).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return OwnPersonalStatsModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getOwnProfileMisc() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.ownMisc).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return OwnProfileMisc.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getOtherProfileExtended({@required String playerId}) async {
    dynamic apiResult;
    await _apiCall(prefix: playerId, apiSelection: ApiSelection.otherProfile).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return OtherProfileModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getOtherProfileBasic({@required String playerId}) async {
    dynamic apiResult;
    await _apiCall(prefix: playerId, apiSelection: ApiSelection.basicProfile).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return BasicProfileModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getTarget({@required String playerId}) async {
    dynamic apiResult;
    await _apiCall(prefix: playerId, apiSelection: ApiSelection.target).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return TargetModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getAttacks() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.attacks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return AttackModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getAttacksFull() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.attacksFull).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return AttackFullModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getFactionAttacks() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.factionAttacks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return FactionAttacksModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getChainStatus() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.chainStatus).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return ChainModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getBars() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.bars).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return BarsModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getItems() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.items).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return ItemsModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getInventory() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.inventory).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return InventoryModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getEducation() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.education).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return TornEducationModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getFaction({@required String factionId}) async {
    dynamic apiResult;
    await _apiCall(prefix: factionId, apiSelection: ApiSelection.faction).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return FactionModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getFactionCrimes({@required String playerId}) async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.factionCrimes).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError && apiResult != null) {
      try {
        //Stopwatch stopwatch = new Stopwatch()..start();
        //var processedModel = await FactionCrimesModel.fromJson(apiResult);
        final isolateArgs = <dynamic>[];
        isolateArgs.add(playerId);
        isolateArgs.add(apiResult);
        var processedModel = await compute(isolateDecodeFactionCrimes, isolateArgs);
        //log('isolateDecodeFactionCrimes executed in ${stopwatch.elapsed}');
        return processedModel;
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getFriends({@required String playerId}) async {
    dynamic apiResult;
    await _apiCall(prefix: playerId, apiSelection: ApiSelection.friends).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return FriendModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getProperty({@required String propertyId}) async {
    dynamic apiResult;
    await _apiCall(prefix: propertyId, apiSelection: ApiSelection.property).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return PropertyModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getAllStocks() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.tornStocks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return StockMarketModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getUserStocks() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.userStocks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return StockMarketUserModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getMarketItem({@required String itemId}) async {
    dynamic apiResult;
    await _apiCall(prefix: itemId, apiSelection: ApiSelection.marketItem).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return MarketItemModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getUserPerks() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.perks).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return UserPerksModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> getRankedWars() async {
    dynamic apiResult;
    await _apiCall(apiSelection: ApiSelection.rankedWars).then((value) {
      apiResult = value;
    });
    if (apiResult is! ApiError) {
      try {
        return RankedWarsModel.fromJson(apiResult);
      } catch (e, trace) {
        FirebaseCrashlytics.instance.recordError(e, trace);
        return ApiError(errorId: 101, pdaErrorDetails: "$e\n$trace");
      }
    } else {
      return apiResult;
    }
  }

  Future<dynamic> _apiCall({
    @required ApiSelection apiSelection,
    String prefix = "",
    int limit = 100,
    String forcedApiKey = "",
  }) async {
    String apiKey = "";
    if (forcedApiKey != "") {
      apiKey = forcedApiKey;
    } else {
      UserController user = Get.put(UserController());
      apiKey = user.apiKey;
    }

    String url = 'https://api.torn.com:443/';

    switch (apiSelection) {
      case ApiSelection.appWidget:
        url += 'user/?selections=profile,icons,bars,cooldowns,newevents,newmessages,travel,money';
        break;
      case ApiSelection.travel:
        url += 'user/?selections=money,travel';
        break;
      case ApiSelection.ownBasic:
        url += 'user/?selections=profile,battlestats';
        break;
      case ApiSelection.ownExtended:
        url += 'user/?selections=profile,bars,networth,cooldowns,events,notifications'
            ',travel,icons,money,education,messages';
        break;
      case ApiSelection.ownPersonalStats:
        url += 'user/?selections=personalstats';
        break;
      case ApiSelection.ownMisc:
        url += 'user/?selections=money,education,workstats,battlestats,jobpoints,properties,skills,bazaar';
        break;
      case ApiSelection.bazaar:
        url += 'user/?selections=bazaar';
        break;
      case ApiSelection.otherProfile:
        url += 'user/$prefix?selections=profile,crimes,personalstats,bazaar';
        break;
      case ApiSelection.basicProfile:
        url += 'user/$prefix?selections=profile';
        break;
      case ApiSelection.target:
        url += 'user/$prefix?selections=profile,discord';
        break;
      case ApiSelection.attacks:
        url += 'user/$prefix?selections=attacks';
        break;
      case ApiSelection.attacksFull:
        url += 'user/$prefix?selections=attacksfull';
        break;
      case ApiSelection.chainStatus:
        url += 'faction/?selections=chain';
        break;
      case ApiSelection.bars:
        url += 'user/?selections=bars';
        break;
      case ApiSelection.items:
        url += 'torn/?selections=items';
        break;
      case ApiSelection.inventory:
        url += 'user/?selections=inventory,display';
        break;
      case ApiSelection.education:
        url += 'torn/?selections=education';
        break;
      case ApiSelection.faction:
        url += 'faction/$prefix?selections=';
        break;
      case ApiSelection.factionCrimes:
        url += 'faction/?selections=crimes';
        break;
      case ApiSelection.factionAttacks:
        url += 'faction/?selections=attacks';
        break;
      case ApiSelection.friends:
        url += 'user/$prefix?selections=profile,discord';
        break;
      case ApiSelection.property:
        url += 'property/$prefix?selections=property';
        break;
      case ApiSelection.userStocks:
        url += 'user/?selections=stocks';
        break;
      case ApiSelection.tornStocks:
        url += 'torn/?selections=stocks';
        break;
      case ApiSelection.marketItem:
        url += 'market/$prefix?selections=bazaar,itemmarket';
        break;
      case ApiSelection.perks:
        url += 'user/$prefix?selections=perks';
        break;
      case ApiSelection.rankedWars:
        url += 'torn/?selections=rankedwars';
        break;
    }
    url += '&key=${apiKey.trim()}&comment=PDA-App&limit=$limit';

    try {
      Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          responseType: ResponseType.plain,
        ),
      );

      dio.httpClientAdapter = IOHttpClientAdapter()
        ..onHttpClientCreate = (HttpClient client) {
          client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
          return client;
        };

      final response = await dio.get(url);

      // ERROR HANDLING 1: verify whether API reply has a correct JSON structure
      dynamic jsonResponse;
      try {
        jsonResponse = json.decode(response.data);
      } catch (e) {
        log("API REPLY ERROR [$e]");
        // Analytics limits at 100 chars
        String platform = Platform.isAndroid ? "a" : "i";
        String versionError = "$appVersion$platform $e";
        analytics.logEvent(
          name: 'api_reply_error',
          parameters: {
            'error': versionError.length > 99 ? versionError.substring(0, 99) : versionError,
          },
        );
        // We limit to a bit more here (it will be shown to the user)
        String error = response == null ? "null" : response.data.toString();
        if (error.isEmpty) {
          error = "Torn API is returning an empty string, please try again in a while. You can check "
              "if there are issues with the API directly in Torn, by visiting https://api.torn.com and trying "
              "a request with your API key";
        }
        return ApiError(
            errorId: 0,
            pdaErrorDetails: "API REPLY ERROR\n[Reply: ${error.length > 300 ? error.substring(0, 300) : error}]");
      }

      // ERROR HANDLING 2: JSON is correct, but the API is reporting an error from JSON
      if (jsonResponse.isNotEmpty && response.statusCode == 200) {
        if (jsonResponse['error'] != null) {
          var code = jsonResponse['error']['code'];
          return ApiError(errorId: code);
        }
        // Otherwise, return a good json response
        return jsonResponse;
      } else {
        log("Api code ${response.statusCode}: ${response.data}");
        analytics.logEvent(
          name: 'api_status_error',
          parameters: {
            'status_code': response.statusCode,
            'response_body': jsonResponse.length > 99 ? jsonResponse.substring(0, 99) : jsonResponse,
          },
        );
        return ApiError(errorId: 0, pdaErrorDetails: "API STATUS ERROR\n[${response.statusCode}: ${response.data}]");
      }
    } on TimeoutException catch (_) {
      return ApiError(errorId: 100);
    } catch (e) {
      // ERROR HANDLING 3: exception from http call

      log("API CALL ERROR (URL was $url): [$e]");
      // Analytics limits at 100 chars
      String platform = Platform.isAndroid ? "a" : "i";
      String versionError = "$appVersion$platform (URL was $url): $e";
      analytics.logEvent(
        name: 'api_call_error',
        parameters: {
          'error': versionError.length > 99 ? versionError.substring(0, 99) : versionError,
        },
      );
      // We limit to a bit more here (it will be shown to the user)
      String error = e.toString();
      return ApiError(
          errorId: 0, pdaErrorDetails: "API CALL ERROR\n[${error.length > 300 ? error.substring(0, 300) : e}]");
    }
  }
}
