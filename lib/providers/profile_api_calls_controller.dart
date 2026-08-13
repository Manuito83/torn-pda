// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chaining/bars_model.dart' as bars_model;
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/company/employees_model.dart';
import 'package:torn_pda/models/education_model.dart';
import 'package:torn_pda/models/faction/faction_crimes_model.dart';
import 'package:torn_pda/models/profile/external/torn_stats_chart.dart';
import 'package:torn_pda/models/profile/own_profile_misc.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/profile/stats_chart.dart';

class ProfileApiPageHooks {
  final void Function() onStateUpdated;
  final void Function(OwnProfileExtended user) onUserFetched;
  final void Function(OwnProfileMisc misc, bool forced) onMiscFetched;
  final void Function() onFetchCycleEnd;

  ProfileApiPageHooks({
    required this.onStateUpdated,
    required this.onUserFetched,
    required this.onMiscFetched,
    required this.onFetchCycleEnd,
  });
}

/// Active only between [activate] and [deactivate] (page lifecycle)
class ProfileApiCallsController extends GetxController {
  // #### DEBUG LOGS ####
  static const bool debugApiLog = false;
  // ####################

  SettingsProvider? _settings;
  WebViewProvider? _webView;
  ProfileApiPageHooks? _hooks;
  final UserController _u = Get.find<UserController>();
  ChainStatusController get _chain => Get.find<ChainStatusController>();

  int _messagesShowNumber = 25;
  int _eventsShowNumber = 25;

  Timer? _ticker;
  // Bumped when Profile attaches and detaches
  int _visitId = 0;
  bool _sameVisit(int id) => id == _visitId;
  DateTime _lastFetchApiTime = DateTime.now();
  DateTime _lastMiscUpdateTime = DateTime.now();
  bool _fastInFlight = false;
  bool _miscInFlight = false;
  bool _eventsInFlight = false;

  final Stopwatch _logWatch = Stopwatch();
  int _totalCalls = 0;
  int _totalSkips = 0;

  Future? apiFetched;
  bool apiGoodData = false;
  ApiError? apiError = ApiError();
  int _apiRetries = 0;

  OwnProfileExtended? user;
  DateTime serverTime = DateTime.now();
  ChainModel chainModel = ChainModel()..chain = ChainDetails();

  bool miscApiFetchedOnce = false;
  OwnProfileMisc? miscModel;
  TornEducationModel? tornEducationModel;
  UserItemMarketResponse? marketItemsV2;
  UserVirus? virusModel;

  List<Event> events = <Event>[];

  UserOrganizedCrimeResponse? oc2Model;
  DateTime ocTime = DateTime.now();
  bool ocSimpleExists = false;
  String ocSimpleStringFinal = "";
  bool ocSimpleReady = false;
  String ocFinalStringLong = "";
  String ocFinalStringShort = "";
  int ocComplexPeopleNotReady = 0;
  bool ocComplexReady = false;

  RankedWar? factionRankedWar;
  int? companyAddiction;

  StatsChartTornStats? statsChartModel;
  bool statsChartIsCached = false;
  String? statsChartError;
  Future? statsChartDataFetched;

  bool _mergeOcAndVirusInMisc = true;

  static const int _educationTtlHours = 6;
  bool _educationFetchedThisVisit = false;
  bool _educationRefetchTried = false;

  void activate({
    required SettingsProvider settingsProvider,
    required WebViewProvider webViewProvider,
    required ProfileApiPageHooks hooks,
  }) {
    _settings = settingsProvider;
    _webView = webViewProvider;
    _hooks = hooks;
    _visitId++;
    _resetState();
    _logWatch
      ..reset()
      ..start();
    _totalCalls = 0;
    _totalSkips = 0;
    _logLine("ACTIVATE", "");
    resetApiTimer(trigger: "activate");
  }

  void deactivate() {
    _visitId++;
    _chain.statusUpdateSource = "provider";
    _ticker?.cancel();
    _hooks = null;
    _logLine("DEACTIVATE", "", {
      "totalCalls": _totalCalls,
      "totalSkips": _totalSkips,
      "uptime": "${_logWatch.elapsed.inSeconds}s",
    });
    _logWatch.stop();
  }

  void startInitialFetch({required int messagesShowNumber, required int eventsShowNumber}) {
    _messagesShowNumber = messagesShowNumber;
    _eventsShowNumber = eventsShowNumber;
    apiFetched = fetchApi(trigger: "init");
    _notify();
  }

  Future<void> setShowNumbers(int messages, int events) async {
    final bool needsLonger = user != null && events > _eventsShowNumber && events > this.events.length;
    _messagesShowNumber = messages;
    _eventsShowNumber = events;
    if (!needsLonger) return;

    await Prefs().setEventsLastRetrieved(0);
    _lastFetchApiTime = DateTime.now().subtract(const Duration(seconds: 20));
  }

  void resetApiTimer({bool initCall = false, required String trigger}) {
    if (initCall && (!_webView!.browserShowInForeground || _webView!.webViewSplitActive)) {
      _apiRefreshPeriodic(trigger: trigger);
    }

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!_webView!.browserShowInForeground || _webView!.webViewSplitActive) {
        _apiRefreshPeriodic(trigger: "timer");
      }
    });
  }

  void pauseTicker() {
    _ticker?.cancel();
  }

  void disregardSimpleCrime() {
    ocSimpleExists = false;
    ocSimpleStringFinal = "";
    _settings?.changeOCrimeDisregarded = ocTime.millisecondsSinceEpoch;
    _notify();
  }

  void _apiRefreshPeriodic({required String trigger}) {
    final bool fromTimer = trigger == "timer";

    // Fast calls: only if data is older than 20 seconds
    final secondsSinceLastFetch = DateTime.now().difference(_lastFetchApiTime).inSeconds;
    if (secondsSinceLastFetch >= 20) {
      if (_fastInFlight && fromTimer) {
        _logSkip("CYCLE fast", {"reason": "in-flight"});
      } else {
        final String cycleTrigger = fromTimer ? "timer-fast" : trigger;
        // Events are inside the ownExtended response
        fetchApi(trigger: cycleTrigger);
        _lastFetchApiTime = DateTime.now();
      }
    }

    // Misc calls: only if data is older than 60 seconds
    final secondsSinceLastMisc = DateTime.now().difference(_lastMiscUpdateTime).inSeconds;
    if (secondsSinceLastMisc >= 60) {
      if (_miscInFlight && fromTimer) {
        _logSkip("CYCLE misc", {"reason": "in-flight"});
      } else {
        final String cycleTrigger = fromTimer ? "timer-misc" : trigger;
        _getMiscCardInfo(trigger: cycleTrigger);
        getStatsChart(trigger: cycleTrigger);
        _getRankedWars(trigger: cycleTrigger);
        _getCompanyAddiction(trigger: cycleTrigger);
        _lastMiscUpdateTime = DateTime.now();
      }
    }
  }

  Future<void> fetchApi({required String trigger}) async {
    if (_hooks == null) return;
    final int visit = _visitId;
    _fastInFlight = true;
    final cycleWatch = Stopwatch()..start();
    final int c0 = _totalCalls, s0 = _totalSkips;
    _logLine("CYCLE fast start", "", {"trigger": trigger});

    try {
      // Try to get only as many messages as strictly necessary, as per Torn recommendations
      var limit = 3;
      if (_messagesShowNumber > limit) limit = _messagesShowNumber;
      if (_eventsShowNumber > limit) limit = _eventsShowNumber;

      final extendedResult = await _timedCall(
        "v1 user/ownExtended+events",
        () => ApiCallsV1.getOwnProfileExtendedWithEvents(limit: limit),
        kv: {"cycle": "fast", "limit": limit},
      );

      final dynamic apiResponse = extendedResult is ProfileExtendedResult ? extendedResult.profile : extendedResult;
      final List<Event>? prefetchedEvents = extendedResult is ProfileExtendedResult ? extendedResult.events : null;

      // Reuse the controller's chain, but only while it keeps refreshing it: it holds on
      // to its last model after stopping, and that one never updates again
      dynamic chain;
      if (_chain.chainModel is ChainModel && _chain.statusActive) {
        chain = _chain.chainModel;
        _logSkip("v1 faction/chain", {"reason": "chain-controller-reuse"});
      } else {
        chain = await _timedCall("v1 faction/chain", ApiCallsV1.getChainStatus);
      }

      if (!_sameVisit(visit)) {
        _logSkip("apply fast result", {"reason": "left-profile"});
        return;
      }

      if (apiResponse is OwnProfileExtended) {
        _apiRetries = 0;
        user = apiResponse;
        serverTime = DateTime.fromMillisecondsSinceEpoch(user!.serverTime! * 1000);
        apiGoodData = true;

        if (chain is ChainModel) {
          chainModel = chain;
        } else {
          chainModel = ChainModel()..chain = ChainDetails();
        }

        if (apiResponse.status != null && apiResponse.travel != null) {
          // Signal that we are updating from the profile page
          _chain.statusUpdateSource = "profile";

          bars_model.Status chainStatusModel = bars_model.Status()
            ..color = apiResponse.status!.color
            ..description = apiResponse.status!.description
            ..details = apiResponse.status!.details
            ..state = apiResponse.status!.state
            ..until = apiResponse.status!.until;

          bars_model.Travel chainTravelModel = bars_model.Travel()
            ..departed = apiResponse.travel!.departed
            ..destination = apiResponse.travel!.destination
            ..timeLeft = apiResponse.travel!.timeLeft
            ..timestamp = apiResponse.travel!.timestamp;

          // Icons so Racing LA can detect race state (icon17 racing, icon18 finished)
          bars_model.Basicicons? chainBasicicons;
          if (apiResponse.icons != null) {
            chainBasicicons = bars_model.Basicicons(
              icon17: apiResponse.icons!.icon17,
              icon18: apiResponse.icons!.icon18,
            );
          }

          bars_model.BarsStatusCooldownsModel externalStatusModel = bars_model.BarsStatusCooldownsModel()
            ..status = chainStatusModel
            ..travel = chainTravelModel
            ..basicicons = chainBasicicons;

          _chain.getOrSetStatus(externalStatusModel: externalStatusModel);
        }

        if (apiResponse.faction?.factionId != null && apiResponse.faction!.factionId! > 0) {
          _u.factionId = apiResponse.faction!.factionId!;
        }

        if (apiResponse.job?.companyId != null && apiResponse.job!.companyId! > 0) {
          _u.companyId = apiResponse.job!.companyId!;
        }

        _hooks?.onUserFetched(apiResponse);
      } else {
        if (apiGoodData && _apiRetries < 8) {
          _apiRetries++;
        } else {
          apiGoodData = false;
          apiError = apiResponse as ApiError?;
          _apiRetries = 0;
        }
      }
      _notify();

      // Before misc, crimes V1 without AA parses the events
      await _refreshEvents(trigger: trigger, prefetched: prefetchedEvents);

      // First successful cycle brings the rest of the sections
      if (apiGoodData && !miscApiFetchedOnce) {
        await _getMiscCardInfo(trigger: trigger);
        statsChartDataFetched = getStatsChart(trigger: trigger);
        _getRankedWars(trigger: trigger);
        _getCompanyAddiction(trigger: trigger);
      }

      _hooks?.onFetchCycleEnd();
    } finally {
      _fastInFlight = false;
      _logLine("CYCLE fast end", "", {
        "trigger": trigger,
        "calls": _totalCalls - c0,
        "skips": _totalSkips - s0,
        "dur": "${cycleWatch.elapsedMilliseconds}ms",
      });
    }
  }

  Future _getMiscCardInfo({required String trigger, bool forcedUpdate = false}) async {
    if (user == null) {
      _logSkip("CYCLE misc", {"reason": "user-null"});
      return;
    }

    _miscInFlight = true;
    final cycleWatch = Stopwatch()..start();
    final int c0 = _totalCalls, s0 = _totalSkips;
    _logLine("CYCLE misc start", "", {"trigger": trigger});

    try {
      final bool mergeVirus = _mergeOcAndVirusInMisc;
      final bool mergeOc =
          _mergeOcAndVirusInMisc && _settings!.oCrimesEnabled && _settings!.playerInOCv2 && UserHelper.factionId != 0;

      final result = await _timedCall(
        "v2 user/misc+itemmarket${mergeOc ? "+oc" : ""}${mergeVirus ? "+virus" : ""}",
        () => ApiCallsV2.getUserProfileMiscAndMarket_v2(includeOrganizedCrime: mergeOc, includeVirus: mergeVirus),
        kv: {"cycle": "misc"},
      );

      if (result is! ProfileMiscResult) {
        // The MISC card is worth more than the two calls we save by merging
        if (mergeVirus || mergeOc) {
          _mergeOcAndVirusInMisc = false;
          _logLine("FALLBACK", "oc and virus back to their own calls", {"reason": "misc call failed while merging"});
        }
        return;
      }
      final OwnProfileMisc miscApiResponse = result.misc;

      await _getEducationCatalog(miscApiResponse);

      // Market listings come inside the misc response, no dedicated call needed
      if (result.itemmarket != null) {
        marketItemsV2 = result.itemmarket;
        _logSkip("v2 user/itemmarket", {
          "reason": "reused-misc-node",
          "listings": result.itemmarket!.itemmarket.length,
        });
      } else {
        try {
          final market = await _timedCall(
            "v2 user/itemmarket",
            ApiCallsV2.getUserMarketItemsApi_v2,
            kv: {"reason": "fallback-misc-parse-failed"},
          );
          if (market is UserItemMarketResponse) marketItemsV2 = market;
        } catch (e, t) {
          log("Issue getting market items: $e, $t");
        }
      }

      if (result.virusResolved) {
        virusModel = result.virus;
        _logSkip("v2 user/virus", {"reason": "reused-misc-node", "active": result.virus != null});
      } else {
        final virus = await _timedCall("v2 user/virus", ApiCallsV2.getUserVirus_v2);
        if (virus is UserVirus) {
          virusModel = virus;
        } else if (virus == null) {
          virusModel = null;
        }
      }

      if (_settings!.oCrimesEnabled) {
        if (_settings!.playerInOCv2) {
          if (result.organizedCrime != null) {
            oc2Model = result.organizedCrime;
            _logSkip("v2 user/organizedcrime", {"reason": "reused-misc-node"});
          } else {
            getFactionCrimesV2(trigger: trigger);
          }
        } else {
          getFactionCrimesV1(trigger: trigger);
        }
      } else {
        _logSkip("oc crimes", {"reason": "setting-off"});
      }

      // Not awaited, the MISC card must not wait for properties
      _hooks?.onMiscFetched(miscApiResponse, forcedUpdate);

      miscModel = miscApiResponse;
      miscApiFetchedOnce = true;
      _notify();
    } catch (e) {
      // If something fails, we simply don't show the MISC section
    } finally {
      _miscInFlight = false;
      _logLine("CYCLE misc end", "", {
        "trigger": trigger,
        "calls": _totalCalls - c0,
        "skips": _totalSkips - s0,
        "dur": "${cycleWatch.elapsedMilliseconds}ms",
      });
    }
  }

  /// Once per visit, then every 6h
  /// The user's own course comes with misc every cycle anyway
  Future _getEducationCatalog(OwnProfileMisc misc) async {
    if (tornEducationModel == null) {
      final saved = await Prefs().getTornEducationCatalogSave();
      if (saved.isNotEmpty) {
        try {
          tornEducationModel = TornEducationModel.fromJson(json.decode(saved));
        } catch (e) {
          log("Error loading education catalog cache: $e");
        }
      }
    }

    final int ts = await Prefs().getTornEducationCatalogTimestamp();
    final int ageHours = ts == 0 ? -1 : DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)).inHours;
    final bool cacheFresh = tornEducationModel != null && ageHours >= 0 && ageHours < _educationTtlHours;

    final int? activeCourseId = misc.education.current?.id;
    final bool activeCourseKnown =
        activeCourseId == null || (tornEducationModel?.education.containsKey(activeCourseId.toString()) ?? false);

    if (_educationFetchedThisVisit && cacheFresh && (activeCourseKnown || _educationRefetchTried)) {
      _logSkip("v1 torn/education", {"reason": "cache", "age": "${ageHours}h", "ttl": "${_educationTtlHours}h"});
      return;
    }

    final Map<String, dynamic> kv = {};
    if (!_educationFetchedThisVisit) {
      kv["reason"] = "first-visit-refresh";
    } else if (cacheFresh && !activeCourseKnown) {
      // Course not in the catalog, refetch once per visit
      _educationRefetchTried = true;
      kv["reason"] = "unknown-active-course";
    }

    final education = await _timedCall("v1 torn/education", ApiCallsV1.getEducation, kv: kv);
    if (education is TornEducationModel) {
      _educationFetchedThisVisit = true;
      tornEducationModel = education;
      Prefs().setTornEducationCatalogSave(json.encode(education.toJson()));
      Prefs().setTornEducationCatalogTimestamp(DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future getStatsChart({String trigger = "stats-callback"}) async {
    Future<void> loadFromCacheOrError(String errorMsg, {bool forceShow = false}) async {
      final savedChart = await Prefs().getTornStatsChartSave();
      if (savedChart.isNotEmpty) {
        statsChartModel = statsChartTornStatsFromJson(savedChart);
        statsChartIsCached = true;
        statsChartError = null;
      } else {
        String errorStr = errorMsg;
        if (!forceShow && errorStr.length > 20) {
          errorStr = '${errorStr.substring(0, 20)}...';
        }
        statsChartError = "Torn Stats chart error: $errorStr";
      }
      _notify();
    }

    try {
      if (!_settings!.tornStatsChartEnabled) {
        _logSkip("tornstats battlestats/graph", {"reason": "setting-off"});
        return;
      }

      final DateTime lastFetched = DateTime.fromMillisecondsSinceEpoch(_settings!.tornStatsChartDateTime);

      if (DateTime.now().difference(lastFetched).inHours < 26) {
        final savedChart = await Prefs().getTornStatsChartSave();
        if (savedChart.isNotEmpty) {
          statsChartModel = statsChartTornStatsFromJson(savedChart);
          statsChartIsCached = true;
          statsChartError = null;
          _notify();
          _logSkip("tornstats battlestats/graph", {"reason": "cache-26h"});
          return;
        }
      }

      _totalCalls++;
      _logLine("CALL", "tornstats battlestats/graph", {"trigger": trigger});
      final callWatch = Stopwatch()..start();
      final String tornStatsURL = 'https://www.tornstats.com/api/v1/${_u.alternativeTornStatsKey}/battlestats/graph';
      final resp = await http.get(Uri.parse(tornStatsURL)).timeout(const Duration(seconds: 5));
      _logLine("DONE", "tornstats battlestats/graph", {
        "dur": "${callWatch.elapsedMilliseconds}ms",
        "result": "http-${resp.statusCode}",
      });

      if (resp.statusCode == 200) {
        final StatsChartTornStats statsJson = statsChartTornStatsFromJson(resp.body);
        if (statsJson.status == true && statsJson.data != null && statsJson.data!.isNotEmpty) {
          statsChartModel = statsJson;
          statsChartIsCached = false;
          statsChartError = null;
          _notify();

          Prefs().setTornStatsChartSave(resp.body);
          _settings!.setTornStatsChartDateTime = DateTime.now().millisecondsSinceEpoch;
        } else {
          final errorMsg = formatTornStatsErrorMessage(statsJson.message);
          await loadFromCacheOrError(errorMsg, forceShow: errorMsg.toLowerCase().contains('user not found'));
        }
      } else {
        String errorMsg;
        bool forceShow = false;
        if (resp.statusCode == 404 && resp.body.contains("User not found")) {
          errorMsg = formatTornStatsErrorMessage('User not found.');
          forceShow = true;
        } else {
          errorMsg = formatTornStatsHttpError(resp.statusCode);
        }
        await loadFromCacheOrError(errorMsg, forceShow: forceShow);
      }
    } catch (e) {
      if (e is TimeoutException) {
        await loadFromCacheOrError("connection timed out");
      } else {
        await loadFromCacheOrError(e.toString());
      }
    }
  }

  Future _getRankedWars({required String trigger}) async {
    if (user == null) {
      _logSkip("v1 torn/rankedwars", {"reason": "user-null"});
      return;
    }

    try {
      if (user!.faction!.factionId == 0) {
        _logSkip("v1 torn/rankedwars", {"reason": "faction-id-0"});
        return;
      }
      if (!_settings!.rankedWarsInProfile) {
        _logSkip("v1 torn/rankedwars", {"reason": "setting-off"});
        return;
      }

      final dynamic apiResponse = await _timedCall("v1 torn/rankedwars", ApiCallsV1.getRankedWars);
      if (apiResponse is RankedWarsModel) {
        for (final warMap in apiResponse.rankedwars!.entries) {
          if (warMap.value.factions!.keys.contains(user!.faction!.factionId.toString())) {
            final int ts = DateTime.now().millisecondsSinceEpoch;
            final bool warInFuture = warMap.value.war!.start! * 1000 > ts;
            final bool warActive = warMap.value.war!.start! < ts && warMap.value.war!.end == 0;
            if (warInFuture || warActive) {
              factionRankedWar = warMap.value;
              _notify();
            }
            return;
          }
        }
      }
    } catch (e) {
      // Returns null
    }
    factionRankedWar = null;
    return;
  }

  Future _getCompanyAddiction({required String trigger}) async {
    if (user == null) {
      _logSkip("v1 company/employees", {"reason": "user-null"});
      return;
    }

    try {
      if (user!.job!.companyId == 0) {
        _logSkip("v1 company/employees", {"reason": "company-id-0"});
        return;
      }

      final nextFetchTime = await Prefs().getJobAddictionNextCallTime();

      final int currentTimeMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
      final bool shouldCallApi = currentTimeMillis >= nextFetchTime;

      if (shouldCallApi || nextFetchTime == 0) {
        final dynamic apiResponse = await _timedCall("v1 company/employees", ApiCallsV1.getCompanyEmployees);
        if (apiResponse is CompanyEmployees) {
          for (final eMap in apiResponse.companyEmployees!.entries) {
            if (eMap.key != user!.playerId.toString()) continue;

            // Next allowed call at 18:30 UTC
            final DateTime now = DateTime.now().toUtc();
            DateTime nextAllowedTime = DateTime.utc(now.year, now.month, now.day, 18, 30);
            if (now.isAfter(nextAllowedTime)) {
              nextAllowedTime = nextAllowedTime.add(const Duration(days: 1));
            }
            final int nextAllowedTimeMillis = nextAllowedTime.millisecondsSinceEpoch;

            Prefs().setJobAddictionNextCallTime(nextAllowedTimeMillis);
            Prefs().setJobAdditionValue(eMap.value.effectiveness!.addiction ?? 0);
            companyAddiction = eMap.value.effectiveness!.addiction ?? 0;
            _notify();
            return;
          }
        }
      } else {
        _logSkip("v1 company/employees", {
          "reason": "daily-slot",
          "next": DateTime.fromMillisecondsSinceEpoch(nextFetchTime).toUtc().toIso8601String(),
        });
        final int savedAddition = await Prefs().getJobAddictionValue();
        companyAddiction = savedAddition;
        _notify();
      }
    } catch (e) {
      companyAddiction = null;
      return;
    }
  }

  /// ownExtended only carries the newest events, so they are enough only when the
  /// oldest of them reaches what we had saved. If not, some are missing in between
  bool _overlapsSavedEvents(List<Event> incoming, int? newestSavedTs) {
    if (newestSavedTs == null || incoming.isEmpty) return false;
    int oldest = incoming.first.timestamp ?? 0;
    for (final e in incoming) {
      final int t = e.timestamp ?? 0;
      if (t < oldest) oldest = t;
    }
    return oldest <= newestSavedTs;
  }

  /// Full events update only if > 30 minutes from last, incremental otherwise
  /// [prefetched] comes with ownExtended, used when it leaves no gap
  Future _refreshEvents({required String trigger, List<Event>? prefetched}) async {
    if (_eventsInFlight) {
      _logSkip("v1 user/events", {"reason": "in-flight"});
      return;
    }
    _eventsInFlight = true;
    try {
      List<Event> eventsSave = <Event>[];
      List<String> save = await Prefs().getEventsSave();
      for (final s in save) {
        eventsSave.add(eventFromJson(s));
      }

      final DateTime lastEventsTs = DateTime.fromMillisecondsSinceEpoch(await Prefs().getEventsLastRetrieved());
      int minutesDiff = DateTime.now().difference(lastEventsTs).inMinutes;

      // If less than 30 minutes have elapsed, we'll just query for new events and fill the list
      if (minutesDiff < 30 && eventsSave.isNotEmpty) {
        if (eventsSave.isEmpty) return;
        int? lastTs = eventsSave[0].timestamp;

        dynamic newEventsResponse;
        if (prefetched != null && _overlapsSavedEvents(prefetched, lastTs)) {
          newEventsResponse = prefetched;
          _logSkip("v1 user/events", {"reason": "reused-ownextended-node", "got": prefetched.length});
        } else {
          newEventsResponse = await _timedCall(
            "v1 user/events",
            () => ApiCallsV1.getEvents(limit: 100, from: lastTs),
            kv: {"mode": "incremental", "reason": prefetched == null ? "no-node" : "gap"},
          );
        }
        if (newEventsResponse is List<Event>) {
          if (newEventsResponse.isNotEmpty) {
            for (int i = 0; i < newEventsResponse.length; i++) {
              bool repeated = false;
              for (final Event inSave in eventsSave) {
                if (newEventsResponse[i].event == inSave.event && newEventsResponse[i].timestamp == inSave.timestamp) {
                  repeated = true;
                  break;
                }
              }
              // Avoid events repetition (even adding 1 ms to lastTs didn't help)
              if (!repeated) {
                eventsSave.insert(i, newEventsResponse[i]);
              }
            }

            List<String> eventsListToSave = [];
            for (final Event e in eventsSave) {
              eventsListToSave.add(eventToJson(e));
            }
            Prefs().setEventsSave(eventsListToSave);
          }
          Prefs().setEventsLastRetrieved(DateTime.now().millisecondsSinceEpoch);
        }

        events = List<Event>.from(eventsSave);
        _notify();
        return;
      }

      // If more than 30 minutes elapsed, we get the whole pack (one month back)
      final int monthAgo = ((DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch) / 1000).ceil();
      final dynamic allEventsResponse = await _timedCall(
        "v1 user/events",
        () => ApiCallsV1.getEvents(limit: 100, from: monthAgo),
        kv: {"mode": "full-30d"},
      );
      if (allEventsResponse is List<Event>) {
        List<String> eventsListToSave = [];
        for (final Event e in allEventsResponse) {
          eventsListToSave.add(eventToJson(e));
        }
        Prefs().setEventsSave(eventsListToSave);
        Prefs().setEventsLastRetrieved(DateTime.now().millisecondsSinceEpoch);

        events = List<Event>.from(allEventsResponse);
      } else {
        // In case of error, return what's saved
        events = List<Event>.from(eventsSave);
      }
      _notify();
    } catch (e, trace) {
      logToUser("PDA Error at Profile Events: $e, $trace");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at Profile Events");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
    } finally {
      _eventsInFlight = false;
    }
  }

  Future<void> getFactionCrimesV1({required String trigger}) async {
    if (_settings!.playerInOCv2) return;

    try {
      if (user == null) {
        _logSkip("v1 faction/crimes", {"reason": "user-null"});
        return;
      }
      final factionCrimes = await _timedCall(
        "v1 faction/crimes",
        () => ApiCallsV1.getFactionCrimes(playerId: user!.playerId.toString()),
      );

      // OPTION 1 - Check if we have faction AA access
      if (factionCrimes != null && factionCrimes is FactionCrimesModel) {
        String? complexString = "";
        DateTime complexTime = DateTime.now();

        factionCrimes.crimes!.forEach((key, crime) {
          if (crime.initiated == 0 && complexString!.isEmpty) {
            var participantsNotReady = 0;
            for (final participant in crime.participants!) {
              participant.forEach((key, values) {
                if (values?.description != "Okay") {
                  participantsNotReady++;
                }
              });

              if (participant.containsKey(UserHelper.playerId.toString())) {
                complexString = crime.crimeName;
                complexTime = DateTime.fromMillisecondsSinceEpoch(crime.timeReady! * 1000);
              }
            }

            if (complexString!.isNotEmpty) ocComplexPeopleNotReady = participantsNotReady;
          }
        });

        if (complexString!.isNotEmpty) {
          bool complexReady = false;
          String complexTimeString = "";
          if (complexTime.isAfter(DateTime.now())) {
            final formattedTime = TimeFormatter(
              inputTime: complexTime,
              timeFormatSetting: _settings!.currentTimeFormat,
              timeZoneSetting: _settings!.currentTimeZone,
            ).formatHourWithDaysElapsed();
            complexTimeString =
                "OC will be ready @ $formattedTime${_timeFormatted(complexTime, previous: formattedTime)}";
          } else {
            complexReady = true;
            if (ocComplexPeopleNotReady == 0) {
              complexTimeString = "OC and all participants are ready!";
            } else if (ocComplexPeopleNotReady == 1) {
              complexTimeString = "OC is ready, but 1 participant is not!";
            } else {
              complexTimeString = "OC is ready, but $ocComplexPeopleNotReady participants are not!";
            }
          }

          ocFinalStringLong = "$complexString $complexTimeString";
          ocFinalStringShort = complexTimeString;
          ocComplexReady = complexReady;
          ocTime = complexTime;
          _notify();

          return;
        }
      }

      // OPTION 2 - No AA access, we look for OC hints in events
      if (factionCrimes == null || factionCrimes is ApiError || ocFinalStringLong.isEmpty) {
        bool simpleExists = false;
        DateTime simpleTime = DateTime.now();
        String simpleString = "";
        bool simpleReady = false;

        void calculateSimpleReadiness() {
          if (simpleTime.isBefore(DateTime.now())) {
            simpleReady = true;
            simpleString = "A faction organized crime might be ready!";
          } else {
            final formattedTime = TimeFormatter(
              inputTime: simpleTime,
              timeFormatSetting: _settings!.currentTimeFormat,
              timeZoneSetting: _settings!.currentTimeZone,
            ).formatHourWithDaysElapsed();
            simpleString =
                "A faction organized crime will be ready @ "
                "$formattedTime${_timeFormatted(simpleTime, previous: formattedTime)}";
          }
        }

        bool foundExpired = false;
        bool foundProgress = false;
        bool error = false;

        // Review the last 100 events, the first hit is the one that counts
        for (final Event e in events) {
          if (!foundExpired && !foundProgress && !error) {
            if (e.event!.contains("You and your team") ||
                (e.event!.contains("canceled the") && e.event!.contains("that you were selected for"))) {
              foundExpired = true;
            } else if (e.event!.contains("You have been selected")) {
              final RegExp strRaw = RegExp("([0-9]+) hours");
              final matches = strRaw.allMatches(e.event!);
              if (matches.isNotEmpty) {
                for (final match in matches) {
                  final hoursString = match.group(1)!;
                  try {
                    final hours = int.parse(hoursString);
                    simpleTime = DateTime.fromMillisecondsSinceEpoch(e.timestamp! * 1000).add(Duration(hours: hours));
                    foundProgress = true;
                    simpleExists = true;
                    _settings!.changeOCrimeLastKnown = simpleTime.millisecondsSinceEpoch;
                    calculateSimpleReadiness();
                  } catch (e) {
                    foundExpired = false;
                    foundProgress = false;
                    error = true;
                  }
                }
              }
            }
          }
        }

        // No hits in 100 events but still ahead of the last known OC time: show that one
        if (!foundProgress && !foundExpired && !error) {
          final lastKnown = DateTime.fromMillisecondsSinceEpoch(_settings!.oCrimeLastKnown);
          if (DateTime.now().isBefore(lastKnown)) {
            simpleExists = true;
            simpleTime = lastKnown;
            foundProgress = true;
            calculateSimpleReadiness();
          }
        }

        // If this same crime was disregarded, don't show it
        if (foundProgress) {
          if (_settings!.oCrimeDisregarded == simpleTime.millisecondsSinceEpoch) {
            simpleExists = false;
            ocSimpleStringFinal = "";
          }
        }

        ocSimpleExists = simpleExists;
        ocSimpleReady = simpleReady;
        ocSimpleStringFinal = simpleString;
        ocTime = simpleTime;
        _notify();
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> getFactionCrimesV2({required String trigger}) async {
    if (!_settings!.playerInOCv2) return;
    if (UserHelper.factionId == 0) {
      _logSkip("v2 user/organizedcrime", {"reason": "faction-id-0"});
      return;
    }

    final dynamic apiResponse = await _timedCall("v2 user/organizedcrime", ApiCallsV2.getUserOC2Crime_v2);
    if (apiResponse != null && apiResponse is UserOrganizedCrimeResponse) {
      oc2Model = apiResponse;
      _notify();
    }
  }

  String _timeFormatted(DateTime timeEnd, {required String previous}) {
    final timeDifference = timeEnd.difference(serverTime);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
    String diff = '';
    if (timeDifference.inMinutes < 1) {
      diff = ', in a few seconds';
    } else if (timeDifference.inMinutes >= 1 && timeDifference.inHours < 24) {
      diff = ', in ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
    } else {
      final dayWeek = TimeFormatter(
        inputTime: timeEnd,
        timeFormatSetting: _settings!.currentTimeFormat,
        timeZoneSetting: _settings!.currentTimeZone,
      ).formatDayWeek;
      if (previous.contains("tomorrow")) {
        diff =
            ', in '
            '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
      } else {
        diff =
            ' (${dayWeek!.replaceAll("on ", "")}), in '
            '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
      }
    }
    return diff;
  }

  void _notify() {
    update();
    _hooks?.onStateUpdated();
  }

  void _resetState() {
    apiFetched = null;
    apiGoodData = false;
    apiError = ApiError();
    _apiRetries = 0;
    user = null;
    serverTime = DateTime.now();
    chainModel = ChainModel()..chain = ChainDetails();
    miscApiFetchedOnce = false;
    miscModel = null;
    tornEducationModel = null;
    marketItemsV2 = null;
    virusModel = null;
    events = <Event>[];
    oc2Model = null;
    ocTime = DateTime.now();
    ocSimpleExists = false;
    ocSimpleStringFinal = "";
    ocSimpleReady = false;
    ocFinalStringLong = "";
    ocFinalStringShort = "";
    ocComplexPeopleNotReady = 0;
    ocComplexReady = false;
    factionRankedWar = null;
    companyAddiction = null;
    statsChartModel = null;
    statsChartIsCached = false;
    statsChartError = null;
    statsChartDataFetched = null;
    _lastFetchApiTime = DateTime.now();
    _lastMiscUpdateTime = DateTime.now();
    _fastInFlight = false;
    _miscInFlight = false;
    _eventsInFlight = false;
    _educationFetchedThisVisit = false;
    _educationRefetchTried = false;
    _mergeOcAndVirusInMisc = true;
  }

  Future<dynamic> _timedCall(String what, Future<dynamic> Function() call, {Map<String, dynamic>? kv}) async {
    _totalCalls++;
    _logLine("CALL", what, kv ?? const {});
    final callWatch = Stopwatch()..start();
    final result = await call();
    _logLine("DONE", what, {"dur": "${callWatch.elapsedMilliseconds}ms", "result": _resultLabel(result)});
    return result;
  }

  String _resultLabel(dynamic r) {
    if (r == null) return "null";
    if (r is ApiError) return "ApiError(${r.errorId})";
    if (r is List) return "list(${r.length})";
    return r.runtimeType.toString();
  }

  void _logSkip(String what, [Map<String, dynamic> kv = const {}]) {
    _totalSkips++;
    _logLine("SKIP", what, kv);
  }

  void _logLine(String kind, String what, [Map<String, dynamic> kv = const {}]) {
    if (!debugApiLog) return;
    final details = kv.isEmpty ? "" : " | ${kv.entries.map((e) => '${e.key}=${e.value}').join(' ')}";
    final label = what.isEmpty ? kind : "$kind $what";
    debugPrint("[ProfileAPI] +${_logWatch.elapsedMilliseconds}ms $label$details");
  }
}
