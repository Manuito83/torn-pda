import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/attack_full_model.dart';
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/own_profile_model.dart';
import 'package:torn_pda/models/travel_model.dart';
import 'package:torn_pda/models/profile_model.dart';

enum ApiType {
  user,
  faction,
  torn,
}

enum ApiSelection {
  travel,
  profile,
  ownProfile,
  target,
  attacks,
  attacksFull,
  chainStatus,
  bars,
  items,
}

class ApiError {
  int errorId;
  String errorReason;
  ApiError({int errorId}) {
    switch (errorId) {
      case 0:
        errorReason = 'Unknown error';
        break;
      case 1:
        errorReason = 'Key is empty';
        break;
      case 2:
        errorReason = 'Incorrect Key';
        break;
      case 3:
        errorReason = 'Wrong type';
        break;
      case 4:
        errorReason = 'Wrong fields';
        break;
      case 5:
        errorReason = 'Too many requests';
        break;
      case 6:
        errorReason = 'Incorrect ID';
        break;
      case 7:
        errorReason = 'Incorrect ID-entity relation';
        break;
      case 8:
        errorReason = 'IP block';
        break;
      case 9:
        errorReason = 'API disabled';
        break;
      case 10:
        errorReason = 'Key owner is in federal jail';
        break;
      case 11:
        errorReason = 'Key change error: You can only '
            'change your API key once every 60 seconds';
        break;
      case 12:
        errorReason = 'Key read error: Error reading key from Database';
        break;
    }
  }
}

class TornApiCaller {
  String apiKey;
  String targetID;

  TornApiCaller.travel(this.apiKey);
  TornApiCaller.profile(this.apiKey);
  TornApiCaller.ownProfile(this.apiKey);
  TornApiCaller.target(this.apiKey, this.targetID);
  TornApiCaller.attacks(this.apiKey);
  TornApiCaller.chain(this.apiKey);
  TornApiCaller.bars(this.apiKey);
  TornApiCaller.items(this.apiKey);

  Future<dynamic> get getTravel async {
    dynamic apiResult;
    await _apiCall(ApiType.user, apiSelection: ApiSelection.travel)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is http.Response) {
      return TravelModel.fromJson(json.decode(apiResult.body));
    } else if (apiResult is ApiError) {
      return apiResult;
    }
  }

  Future<dynamic> get getProfile async {
    dynamic apiResult;
    await _apiCall(ApiType.user, apiSelection: ApiSelection.profile)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is http.Response) {
      return ProfileModel.fromJson(json.decode(apiResult.body));
    } else if (apiResult is ApiError) {
      return apiResult;
    }
  }

  Future<dynamic> get getOwnProfile async {
    dynamic apiResult;
    await _apiCall(ApiType.user, apiSelection: ApiSelection.ownProfile)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is http.Response) {
      return OwnProfileModel.fromJson(json.decode(apiResult.body));
    } else if (apiResult is ApiError) {
      return apiResult;
    }
  }

  Future<dynamic> get getTarget async {
    dynamic apiResult;
    await _apiCall(ApiType.user,
            prefix: this.targetID, apiSelection: ApiSelection.target)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is http.Response) {
      return TargetModel.fromJson(json.decode(apiResult.body));
    } else if (apiResult is ApiError) {
      return apiResult;
    }
  }

  Future<dynamic> get getAttacks async {
    dynamic apiResult;
    await _apiCall(ApiType.user, apiSelection: ApiSelection.attacks)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is http.Response) {
      return AttackModel.fromJson(json.decode(apiResult.body));
    } else if (apiResult is ApiError) {
      return apiResult;
    }
  }

  Future<dynamic> get getAttacksFull async {
    dynamic apiResult;
    await _apiCall(ApiType.user, apiSelection: ApiSelection.attacksFull)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is http.Response) {
      return AttackFullModel.fromJson(json.decode(apiResult.body));
    } else if (apiResult is ApiError) {
      return apiResult;
    }
  }

  Future<dynamic> get getChainStatus async {
    dynamic apiResult;
    await _apiCall(ApiType.faction, apiSelection: ApiSelection.chainStatus)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is http.Response) {
      try {
        return ChainModel.fromJson(json.decode(apiResult.body));
      } catch (e) {
        return ApiError();
      }
    } else if (apiResult is ApiError) {
      return apiResult;
    }
  }

  Future<dynamic> get getBars async {
    dynamic apiResult;
    await _apiCall(ApiType.user, apiSelection: ApiSelection.bars).then((value) {
      apiResult = value;
    });
    if (apiResult is http.Response) {
      try {
        return BarsModel.fromJson(json.decode(apiResult.body));
      } catch (e) {
        return ApiError();
      }
    } else if (apiResult is ApiError) {
      return apiResult;
    }
  }

  Future<dynamic> get getItems async {
    dynamic apiResult;
    await _apiCall(ApiType.torn, apiSelection: ApiSelection.items)
        .then((value) {
      apiResult = value;
    });
    if (apiResult is http.Response) {
      try {
        return ItemsModel.fromJson(json.decode(apiResult.body));
      } catch (e) {
        return ApiError();
      }
    } else if (apiResult is ApiError) {
      return apiResult;
    }
  }

  Future<dynamic> _apiCall(ApiType apiType,
      {String prefix, ApiSelection apiSelection}) async {
    String url = 'https://api.torn.com/';
    switch (apiType) {
      case ApiType.user:
        url += 'user/';
        break;
      case ApiType.faction:
        url += 'faction/';
        break;
      case ApiType.torn:
        url += 'torn/';
        break;
    }

    switch (apiSelection) {
      case ApiSelection.travel:
        url += '?selections=travel';
        break;
      case ApiSelection.profile:
        url += '?selections=profile';
        break;
      case ApiSelection.ownProfile:
        url += '?selections=profile,bars,networth,cooldowns';
        break;
      case ApiSelection.target:
        url += '$prefix?selections=';
        break;
      case ApiSelection.attacks:
        url += '$prefix?selections=attacks';
        break;
      case ApiSelection.attacksFull:
        url += '$prefix?selections=attacksfull';
        break;
      case ApiSelection.chainStatus:
        url += '?selections=chain';
        break;
      case ApiSelection.bars:
        url += '?selections=bars';
        break;
      case ApiSelection.items:
        url += '?selections=items';
        break;
    }
    url += '&key=$apiKey';

    //url = 'http://www.google.com:81';  // DEBUG FOR TIMEOUT!
    //await new Future.delayed(const Duration(seconds : 5));  // DEBUG TIMEOUT 2
    try {
      final response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        // Check if json is responding with errors
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['error'] != null) {
          return ApiError(errorId: jsonResponse['error']['code']);
        }
        // Otherwise, return a good json response
        return response;
      } else {
        return ApiError(errorId: 0);
      }
    } on TimeoutException catch (e) {
      return ApiError(errorId: 0);
    } catch (e) {
      return ApiError(errorId: 0);
    }
  }
}
