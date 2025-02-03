import 'dart:async';
import 'package:chopper/chopper.dart' as chopper;
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';

enum ApiSelection_v1 {
  appWidget,
  travel,
  ownBasic,
  ownExtended,
  events,
  ownPersonalStats,
  ownMisc,
  bazaar,
  basicProfile,
  target,
  attacks,
  attacksFull,
  chainStatus,
  barsAndPlayerStatus,
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
  perks,
  rankedWars,
  companyEmployees,
}

enum ApiSelection_v2 {
  marketItem,
  userMarketItems,
  userProfileMisc,
  otherUserProfile,
  tornCalendar,
}

class ApiError {
  int? errorId;
  String errorReason = "";
  String pdaErrorDetails = "";
  String tornErrorDetails = "";

  ApiError({this.errorId = 0, this.pdaErrorDetails = "", this.tornErrorDetails = ""}) {
    switch (errorId) {
      // Torn PDA codes
      case 100:
        errorReason = 'connection timed out';
      // Torn PDA codes
      case 101:
        errorReason = 'issue with PDA data model';
        pdaErrorDetails = pdaErrorDetails;
      // Torn codes
      case 0:
        errorReason = 'no connection';
        pdaErrorDetails = pdaErrorDetails;
      case 1:
        errorReason = 'key is empty';
      case 2:
        errorReason = 'incorrect Key';
      case 3:
        errorReason = 'wrong type';
      case 4:
        errorReason = 'wrong fields';
      case 5:
        errorReason = 'too many requests per user (max 100 per minute)';
      case 6:
        errorReason = 'incorrect ID';
      case 7:
        errorReason = 'incorrect ID-entity relation';
      case 8:
        errorReason = 'current IP is banned for a small period of time because of abuse';
      case 9:
        errorReason = "API disabled (probably under maintenance by Torn's developers)!";
      case 10:
        errorReason = 'key owner is in federal jail';
      case 11:
        errorReason = 'key change error: You can only change your API key once every 60 seconds';
      case 12:
        errorReason = 'key read error: Error reading key from Database';
      case 13:
        errorReason = "key is temporary disabled due to inactivity (owner hasn't been online for more than 7 days)";
      case 14:
        errorReason = 'daily read limit reached';
      case 15:
        errorReason = 'an error code specifically for testing purposes that has no dedicated meaning';
      case 16:
        errorReason = 'access level of this key is not high enough: Torn PDA request at least a Limited key';
      case 17:
        errorReason = 'backend error occurred, please try again';
      case 18:
        errorReason = 'API key has been paused by the owner';
      default:
        if (tornErrorDetails.isNotEmpty) {
          errorReason = tornErrorDetails;
        } else {
          errorReason = 'unkown';
        }
    }
  }
}

/// Represents a queued API call request for both API V1 and API V2
class ApiCallRequest {
  // Completer to resolve or reject the queued API call
  final Completer<dynamic> completer;

  // Timestamp when the request was added to the queue
  final DateTime timestamp;

  // API V1 configuration
  final ApiSelection_v1? apiSelection_v1;
  final String? prefix;
  final int limit;
  final int? from;
  final String? forcedApiKey;

  // API V2 configuration
  final ApiSelection_v2? apiSelection_v2;
  final Map<String, dynamic>? payload_v2;
  final Future<chopper.Response<dynamic>> Function(TornV2 client, String apiKey)? apiCall;

  // Constructor to create a queued API call request
  ApiCallRequest({
    required this.completer,
    required this.timestamp,
    this.apiSelection_v1, // For API V1
    this.prefix,
    this.limit = 100,
    this.from,
    this.forcedApiKey,
    this.apiSelection_v2, // For API V2
    this.payload_v2,
    this.apiCall,
  }) : assert(
          (apiSelection_v1 != null && apiSelection_v2 == null) || (apiSelection_v1 == null && apiSelection_v2 != null),
          "You must provide either an API V1 or API V2 configuration, but not both",
        );
}
