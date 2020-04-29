import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/attack_full_model.dart';
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/travel_model.dart';
import 'package:torn_pda/models/profile_model.dart';

enum ApiType {
  user,
  faction,
}

enum ApiSelection {
  travel,
  profile,
  target,
  attacks,
  attacksFull,
  chainStatus,
  bars,
}

class ApiError {
  int errorId;
  String errorReason;
  ApiError({int errorId}) {
    if (errorId == 0) {
      errorReason = 'Server cannot be contacted (timeout)!';
    } else if (errorId == 1) {
      errorReason = 'Invalid Torn API Key!';
    } else {
      errorReason = 'Unknown error!';
    }
  }
}

class TornApiCaller {
  String apiKey;
  String targetID;

  TornApiCaller.travel(this.apiKey);
  TornApiCaller.profile(this.apiKey);
  TornApiCaller.target(this.apiKey, this.targetID);
  TornApiCaller.attacks(this.apiKey);
  TornApiCaller.chain(this.apiKey);
  TornApiCaller.bars(this.apiKey);

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
    await _apiCall(ApiType.user, apiSelection: ApiSelection.bars)
        .then((value) {
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
    }

    switch (apiSelection) {
      case ApiSelection.travel:
        url += '?selections=travel';
        break;
      case ApiSelection.profile:
        url += '?selections=profile';
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
          if (jsonResponse['error']['code'] == 2) {
            return ApiError(errorId: 1);
          } else {
            return ApiError(errorId: 99);
          }
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
