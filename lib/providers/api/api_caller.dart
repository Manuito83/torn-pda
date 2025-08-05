// Dart imports:
// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
// Package imports:
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:chopper/chopper.dart' as chopper;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
// Project imports:
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ApiCallerController extends GetxController {
  int maxCallsAllowed = 95;

  final _callQueue = Queue<ApiCallRequest>();
  final _callCount = 0.obs;
  final List<DateTime> _callTimestamps = [];
  Timer? _timer;

  final _callCountStream = BehaviorSubject<int>.seeded(0);
  Stream<int> get callCountStream => _callCountStream.stream;

  final _queueStatsStream = BehaviorSubject<Map<String, dynamic>>.seeded({'queueLength': 0, 'avgTime': 0});
  Stream<Map<String, dynamic>> get queueStatsStream => _queueStatsStream.stream;

  bool _delayCalls = false;
  bool get delayCalls => _delayCalls;
  set delayCalls(bool value) {
    _delayCalls = value;
    Prefs().setDelayApiCalls(value);
    update();
  }

  var _showApiRateInDrawer = false.obs;
  RxBool get showApiRateInDrawer => _showApiRateInDrawer;
  set showApiRateInDrawer(RxBool value) {
    _showApiRateInDrawer = value;
    Prefs().setShowApiRateInDrawer(value.isTrue ? true : false);
    update();
  }

  int _lastMaxCallWarningTs = 0;
  var _showApiMaxCallWarning = false;
  bool get showApiMaxCallWarning => _showApiMaxCallWarning;
  set showApiMaxCallWarning(bool value) {
    _showApiMaxCallWarning = value;
    Prefs().setShowApiMaxCallWarning(value);
    update();
  }

  /// Records a new error, keeping only the latest 30 entries
  final RxList<ApiErrorEntry> apiErrors = <ApiErrorEntry>[].obs;
  void recordApiError(Object error, String trace, String apiVersion) {
    final entry = ApiErrorEntry(
      timestamp: DateTime.now().toUtc(),
      message: error.toString(),
      trace: trace,
      apiVersion: apiVersion,
    );
    apiErrors.add(entry);
    while (apiErrors.length > 30) {
      apiErrors.removeAt(0);
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    // Set up the timer to check the queue for API call requests every second
    _timer = Timer.periodic(const Duration(seconds: 1), _checkQueue);
    _showApiRateInDrawer = (await Prefs().getShowApiRateInDrawer()) ? RxBool(true) : RxBool(false);
    _showApiMaxCallWarning = await Prefs().getShowApiMaxCallWarning();
    _delayCalls = await Prefs().getDelayApiCalls();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _callCountStream.close();
    _queueStatsStream.close();
    super.onClose();
  }

  /// Handles both API V1 and API V2 requests
  Future<dynamic> enqueueApiCall<T>({
    // API V1
    ApiSelection_v1? apiSelection,
    String? prefix = "", // Optional prefix for API V1
    int limit = 100, // Default limit for API V1
    int? from, // Optional timestamp for API V1
    // API V2
    ApiSelection_v2? apiSelection_v2, // For API V2
    Future<chopper.Response<T>> Function(TornV2 client, String apiKey)? apiCall, // API V2 logic
    // Others
    String? forcedApiKey = "", // (e.g.: Android App Widget)
  }) async {
    if (apiSelection == null && apiSelection_v2 == null) {
      throw ArgumentError("You must provide either an API V1 or API V2 selection.");
    }
    if (apiSelection != null && apiSelection_v2 != null) {
      throw ArgumentError("You cannot provide both API V1 and API V2 selections.");
    }

    // Manage rate limiting and timestamps
    final now = DateTime.now();
    _callTimestamps.removeWhere((timestamp) => now.difference(timestamp).inSeconds >= 60);
    _callTimestamps.add(now);

    // If calls should be delayed, queue the request
    if (delayCalls &&
        _callTimestamps.length >= maxCallsAllowed &&
        now.difference(_callTimestamps.first).inSeconds < 60) {
      return _queueApiCall(
        apiSelection: apiSelection,
        apiSelection_v2: apiSelection_v2,
        apiCall: apiCall,
        prefix: prefix,
        limit: limit,
        from: from,
        forcedApiKey: forcedApiKey,
      );
    }

    // Increment active call count
    _callCount.value++;
    _callCountStream.add(_callTimestamps.length);

    // Execute the appropriate API call
    try {
      if (apiSelection_v2 != null) {
        // API V2
        if (apiCall == null) {
          throw ArgumentError("For API V2, 'apiCall' must be provided.");
        }
        dynamic apiV2Response = await _launchApiCall_v2(
          apiSelection_v2: apiSelection_v2,
          apiCall: apiCall,
        );
        return apiV2Response;
      } else if (apiSelection != null) {
        // API V1
        return await _launchApiCall_v1(
          apiSelection: apiSelection,
          prefix: prefix,
          limit: limit,
          from: from,
          forcedApiKey: forcedApiKey,
        );
      } else {
        throw ArgumentError("Invalid API configuration."); // Safety fallback
      }
    } finally {
      // Decrement active call count after the call completes
      _callCount.value--;
      _logCallCount();
    }
  }

  /// Adds an API call to the queue for delayed execution
  Future<dynamic> _queueApiCall<T>({
    ApiSelection_v1? apiSelection, // For API V1
    ApiSelection_v2? apiSelection_v2, // For API V2
    Map<String, dynamic>? payload_v2, // Payload for API V2
    Future<chopper.Response<T>> Function(TornV2 client, String apiKey)? apiCall, // API V2 logic
    String? prefix,
    int limit = 100,
    int? from,
    String? forcedApiKey = "",
  }) async {
    final completer = Completer<dynamic>();

    final apiCallRequest = ApiCallRequest(
      completer: completer,
      timestamp: DateTime.now(),
      apiSelection_v1: apiSelection,
      apiSelection_v2: apiSelection_v2,
      apiCall: apiCall,
      prefix: prefix,
      limit: limit,
      from: from,
      forcedApiKey: forcedApiKey,
    );

    _callQueue.add(apiCallRequest);
    _logQueueMessage(apiCallRequest);

    return completer.future;
  }

  void _checkQueue(Timer timer) {
    final now = DateTime.now();

    // Remove old timestamps
    _callTimestamps.removeWhere((timestamp) => now.difference(timestamp).inSeconds >= 60);

    // Process queued calls when allowed
    if (_callQueue.isNotEmpty &&
        (_callTimestamps.length < maxCallsAllowed || now.difference(_callTimestamps.first).inSeconds >= 60)) {
      final apiCallRequest = _callQueue.removeFirst();
      _callTimestamps.add(now);

      _callCount.value++;

      Future<dynamic> responseFuture;
      if (apiCallRequest.apiSelection_v1 != null) {
        // Handle API V1 request
        responseFuture = _launchApiCall_v1(
          apiSelection: apiCallRequest.apiSelection_v1!,
          prefix: apiCallRequest.prefix,
          limit: apiCallRequest.limit,
          from: apiCallRequest.from,
          forcedApiKey: apiCallRequest.forcedApiKey,
        );
      } else {
        // Handle API V2 request
        responseFuture = _launchApiCall_v2(
          apiSelection_v2: apiCallRequest.apiSelection_v2!,
          apiCall: apiCallRequest.apiCall!,
        );
      }

      responseFuture.then((response) {
        // Complete the request with the response
        apiCallRequest.completer.complete(response);
        _callCount.value--;
        _logCallCount();
      });
    }

    // If the queue is empty, update the queue stats stream
    if (_callQueue.isEmpty) {
      _queueStatsStream.add({'queueLength': 0, 'avgTime': 0});
    }
  }

  void _logQueueMessage(ApiCallRequest request) {
    final int queuedCalls = _callQueue.length; // Get the number of API calls in the queue
    final int delaySum = _callQueue.fold(0, (sum, req) => sum + DateTime.now().difference(req.timestamp).inSeconds);
    final double averageDelay = queuedCalls > 0 ? delaySum / queuedCalls : 0;

    // Update the queue stats stream
    _queueStatsStream.add({'queueLength': _callQueue.length, 'avgTime': averageDelay});

    debugPrint("$queuedCalls queued calls! Average delay is $averageDelay seconds");
  }

  void _logCallCount() {
    final countInLast60Seconds = _callTimestamps.length;
    //debugPrint('Number of calls in the last 60 seconds: $countInLast60Seconds');
    if (showApiMaxCallWarning && countInLast60Seconds >= 95) {
      final int ts = DateTime.now().millisecondsSinceEpoch;
      // Don't show the message again in 30 seconds
      if (ts - _lastMaxCallWarningTs > 30000) {
        _lastMaxCallWarningTs = ts;
        BotToast.showText(
          clickClose: true,
          text: "API rate ($countInLast60Seconds calls)!",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.orange[700]!,
          contentPadding: const EdgeInsets.all(10),
        );
      }
    }
  }

  Future<dynamic> _launchApiCall_v1({
    required ApiSelection_v1 apiSelection,
    String? prefix = "",
    int limit = 100,
    int? from,
    String? forcedApiKey = "",
  }) async {
    String? apiKey = "";
    if (forcedApiKey != "") {
      apiKey = forcedApiKey;
    } else {
      final UserController user = Get.find<UserController>();
      apiKey = user.apiKey;
    }

    // Make sure we don't allow calls without an API key
    // (e.g. when checking something in Drawer on first launch)
    if (apiKey == null || apiKey.isEmpty) {
      return ApiError(errorId: 999);
    }

    String url = 'https://api.torn.com:443/';

    switch (apiSelection) {
      case ApiSelection_v1.appWidget:
        url += 'user/?selections=profile,icons,bars,cooldowns,newevents,newmessages,travel,money';
        break;
      case ApiSelection_v1.travel:
        url += 'user/?selections=money,travel';
        break;
      case ApiSelection_v1.ownBasic:
        url += 'user/?selections=profile,battlestats,bars';
        break;
      case ApiSelection_v1.ownExtended:
        url += 'user/?selections=profile,bars,networth,cooldowns,notifications,travel,icons,money,education,messages';
        break;
      case ApiSelection_v1.events:
        url += 'user/?selections=events';
        break;
      case ApiSelection_v1.ownPersonalStats:
        final stats = "xantaken,statenhancersused,refills,exttaken,lsdtaken,networth,energydrinkused";
        url += 'user/?selections=personalstats&stat=$stats';
        break;
      case ApiSelection_v1.ownMisc:
        url += 'user/?selections=money,education,workstats,battlestats,jobpoints,properties,skills,bazaar';
        break;
      case ApiSelection_v1.bazaar:
        url += 'user/?selections=bazaar';
        break;
      case ApiSelection_v1.basicProfile:
        url += 'user/$prefix?selections=profile';
        break;
      case ApiSelection_v1.target:
        url += 'user/$prefix?selections=profile,discord';
        break;
      case ApiSelection_v1.attacks:
        url += 'user/$prefix?selections=attacks';
        break;
      case ApiSelection_v1.attacksFull:
        url += 'user/$prefix?selections=attacksfull';
        break;
      case ApiSelection_v1.chainStatus:
        url += 'faction/?selections=chain';
        break;
      case ApiSelection_v1.barsAndPlayerStatus:
        url += 'user/?selections=bars,profile,travel,cooldowns,money';
        break;
      case ApiSelection_v1.items:
        url += 'torn/?selections=items';
        break;
      case ApiSelection_v1.inventory:
        url += 'user/?selections=inventory,display';
        break;
      case ApiSelection_v1.education:
        url += 'torn/?selections=education';
        break;
      case ApiSelection_v1.faction:
        url += 'faction/$prefix?selections=';
        break;
      case ApiSelection_v1.factionCrimes:
        url += 'faction/?selections=crimes';
        break;
      case ApiSelection_v1.factionAttacks:
        url += 'faction/?selections=attacks';
        break;
      case ApiSelection_v1.friends:
        url += 'user/$prefix?selections=profile,discord';
        break;
      case ApiSelection_v1.property:
        url += 'property/$prefix?selections=property';
        break;
      case ApiSelection_v1.userStocks:
        url += 'user/?selections=stocks';
        break;
      case ApiSelection_v1.tornStocks:
        url += 'torn/?selections=stocks';
        break;
      case ApiSelection_v1.perks:
        url += 'user/$prefix?selections=perks';
        break;
      case ApiSelection_v1.rankedWars:
        url += 'torn/?selections=rankedwars';
        break;
      case ApiSelection_v1.companyEmployees:
        url += 'company/?selections=employees';
        break;
    }
    url += '&key=${apiKey.trim()}&comment=PDA-App&limit=$limit${from != null ? "&from=$from" : ""}';

    // DEBUG
    // if (kDebugMode) return ApiError(errorId: 0);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"source-app": "torn-pda"},
      ).timeout(const Duration(seconds: 15));

      // ERROR HANDLING 1: verify whether API reply has a correct JSON structure
      dynamic jsonResponse;
      try {
        jsonResponse = json.decode(response.body);
      } catch (e, trace) {
        log("API REPLY ERROR [$e]");
        // Analytics limits at 100 chars
        final String platform = Platform.isAndroid ? "a" : "i";
        final String versionError = "$appVersion$platform $e";
        analytics?.logEvent(
          name: 'api_reply_error',
          parameters: {
            'error': versionError.length > 99 ? versionError.substring(0, 99) : versionError,
          },
        );
        // We limit to a bit more here (it will be shown to the user)
        String error = response.body;
        if (error.isEmpty) {
          error = "Torn API is returning empty information, please try again in a while. You can check "
              "if there are issues with the API directly in Torn, by visiting https://api.torn.com and trying "
              "a request with your API key";
        }

        recordApiError(e, trace.toString(), "V1");
        return ApiError(
          // We limit to a bit more here (it might get shown to the user)
          pdaErrorDetails: "API REPLY ERROR\n[Reply: ${error.length > 300 ? error.substring(0, 300) : error}]",
        );
      }

      // ERROR HANDLING 2: JSON is correct, but the API is reporting an error from JSON
      if (jsonResponse.isNotEmpty && response.statusCode == 200) {
        if (jsonResponse['error'] != null) {
          final code = jsonResponse['error']['code'];
          final tornReason = jsonResponse['error']['error'];

          recordApiError("Torn Error Code: $code", tornReason, "V1");
          return ApiError(errorId: code, tornErrorDetails: tornReason);
        }
        // Otherwise, return a good json response
        return jsonResponse;
      } else {
        log("Api code ${response.statusCode}: ${response.body}");
        analytics?.logEvent(
          name: 'api_status_error',
          parameters: {
            'status_code': response.statusCode,
            'response_body':
                jsonResponse.length > 99 ? jsonResponse.substring(0, 99).toString() : jsonResponse.toString(),
          },
        );

        final String e = response.body;
        int? errorParsed = 0;
        if (response.body.contains('"code":')) {
          errorParsed = int.tryParse(response.body.split('"code":')[1].split(",")[0]);
        }

        recordApiError("HTTP Error Code: ${response.statusCode}", e.length > 300 ? e.substring(0, 300) : e, "V1");
        return ApiError(
          errorId: errorParsed ?? 0,
          // We limit to a bit more here (it might get shown to the user)
          pdaErrorDetails: "API STATUS ERROR\n[${response.statusCode}: ${e.length > 300 ? e.substring(0, 300) : e}]",
        );
      }
    } on TimeoutException catch (_) {
      recordApiError("Torn Timed Out", "Connection Timed Out", "V1");
      return ApiError(errorId: 100);
    } catch (e) {
      // ERROR HANDLING 3: exception from http call

      log("API CALL ERROR: [$e]");
      // Analytics limits at 100 chars
      final String platform = Platform.isAndroid ? "a" : "i";
      final String versionError = "$appVersion$platform: $e";
      analytics?.logEvent(
        name: 'api_call_error',
        parameters: {
          'error': versionError.length > 99 ? versionError.substring(0, 99) : versionError,
        },
      );

      final String error = e.toString();

      recordApiError("HTTP Connection Crash", error.length > 300 ? error.substring(0, 300) : error, "V1");
      return ApiError(
        // We limit to a bit more here (it might get shown to the user)
        pdaErrorDetails: "API CALL ERROR\n[${error.length > 300 ? error.substring(0, 300) : error}]",
      );
    }
  }

  Future<dynamic> _launchApiCall_v2<T>({
    required ApiSelection_v2 apiSelection_v2,
    required Future<chopper.Response<T>> Function(TornV2 client, String apiKey) apiCall,
  }) async {
    final UserController user = Get.find<UserController>();
    final String apiKey = user.apiKey!;

    // Make sure we don't allow calls without an API key
    // (e.g. when checking something in Drawer on first launch)
    if (apiKey.isEmpty) {
      return ApiError(errorId: 999);
    }

    final TornV2 client = TornV2.create(
      baseUrl: Uri.parse('https://api.torn.com:443/v2'),
      interceptors: [
        chopper.HeadersInterceptor({"Authorization": "ApiKey $apiKey"}),
      ],
    );

    int? statusCode;

    try {
      final response = await apiCall(client, apiKey).timeout(const Duration(seconds: 15));
      statusCode = response.statusCode;

      final rawBody = response.bodyString;
      final decodedBody = jsonDecode(rawBody) as Map<String, dynamic>;

      if (decodedBody.containsKey('error')) {
        final error = decodedBody['error'] as Map<String, dynamic>;
        final errorCode = error['code'];
        final errorMessage = error['error'];

        throw _handleError_v2(
          ApiError(
            errorId: errorCode,
            tornErrorDetails: errorMessage,
          ),
          statusCode,
          null,
        );
      }

      return response.body;
    } catch (e, trace) {
      return _handleError_v2(e, statusCode, trace);
    }
  }

  // TODO: Probably needs to be completed with more use cases as in API V1
  ApiError _handleError_v2(dynamic e, int? statusCode, StackTrace? trace) {
    if (e is TimeoutException) {
      log("TORN API v2 TIMED OUT: $e, trace: $trace");

      recordApiError("Torn Timed Out: $e", trace.toString(), "V2");
      return ApiError(errorId: 100);
    } else if (e is ApiError) {
      log("TORN API v2 ERROR: [${e.tornErrorDetails}], trace: $trace");
      analytics?.logEvent(
        name: 'api_status_error',
        parameters: {
          'status_code': statusCode ?? -1,
          'response_body': e.tornErrorDetails,
        },
      );

      recordApiError("Torn Api Error: ${e.errorId}",
          e.toString().length > 300 ? e.toString().substring(0, 300) : e.toString(), "V2");
      return ApiError(
        errorId: e.errorId,
        pdaErrorDetails: "TORN API ERROR\n[${e.toString().length > 300 ? e.toString().substring(0, 300) : e}]",
      );
    } else {
      log("API v2 PDA CALL ERROR: [$e], trace: $trace");
      // Analytics limits at 100 chars
      final String platform = Platform.isAndroid ? "a" : "i";
      final String versionError = "$appVersion$platform: $e";
      analytics?.logEvent(
        name: 'api_v2_call_error',
        parameters: {
          'error': versionError.length > 99 ? versionError.substring(0, 99) : versionError,
        },
      );

      final String error = e.toString();

      recordApiError(
          "HTTP Connection Crash: ${e.errorId}", error.length > 300 ? error.substring(0, 300) : error.toString(), "V2");
      return ApiError(
        // We limit to a bit more here (it might get shown to the user)
        pdaErrorDetails: "API CALL ERROR\n[${error.length > 300 ? error.substring(0, 300) : error}]",
      );
    }
  }
}
