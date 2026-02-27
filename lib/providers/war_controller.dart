import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:bot_toast/bot_toast.dart';
import 'package:csv/csv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/chaining/tornstats/tornstats_spies_model.dart';
import 'package:torn_pda/models/chaining/war_settings.dart';
import 'package:torn_pda/models/chaining/war_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/profile/other_profile_model/other_profile_pda.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/ffscouter_cache_controller.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/stats_calculator.dart';
import 'package:torn_pda/widgets/chaining/war_card.dart';

class WarCardDetails {
  int? cardPosition;
  int? memberId;
  String? name;
  String? personalNote;
  String? personalNoteColor;
}

class WarController extends GetxController {
  List<FactionModel> factions = <FactionModel>[];
  List<WarCardDetails> orderedCardsDetails = <WarCardDetails>[];
  WarSortType? currentSort;
  WarSettings warSettings = WarSettings();

  // Stores the Min/Max Log10 values for the current list of targets
  // Keys: 'Stats', 'Estimated', 'Str', 'Def', 'Spd', 'Dex'
  // Values: {'min': 4.5, 'max': 9.2}
  Map<String, Map<String, double>> attributeRanges = {};

  // Filters
  List<String> activeFilters = [];
  int onlineFilter = 0;
  int okayRedFilter = 0;
  bool countryFilter = false;
  int abroadFilter = 0;
  bool showChainWidget = true;

  bool updating = false;
  bool _stopUpdate = false;

  bool _integrityChecking = false;

  bool showCaseStart = false;

  bool addFromUserId = false;

  late DateTime _lastIntegrityCheck;

  bool _nukeReviveActive = false;
  bool get nukeReviveActive => _nukeReviveActive;
  set nukeReviveActive(bool value) {
    Prefs().setUseNukeRevive(value);
    _nukeReviveActive = value;
  }

  bool _uhcReviveActive = false;
  bool get uhcReviveActive => _uhcReviveActive;
  set uhcReviveActive(bool value) {
    Prefs().setUseUhcRevive(value);
    _uhcReviveActive = value;
  }

  // Shared limiter to avoid flooding profile calls (Torn: 100/min)
  Future<void> _apiRateLimiter = Future.value();
  DateTime _lastApiCall = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _apiGapMsBase = 400; // Faster path when no limits hit
  static const int _apiGapMsBackoff = 1200; // Backoff when rate limited
  int _apiGapMsCurrent = _apiGapMsBase;
  bool _throttleToastShown = false;
  int _fullUpdateTotal = 0;
  int _fullUpdateSuccess = 0;
  bool _fullUpdateInProgress = false;
  static const int _concurrencyBase = 6;
  static const int _concurrencyBackoff = 1;
  int _concurrencyCurrent = _concurrencyBase;

  /*
  bool _helaReviveActive = false;
  bool get helaReviveActive => _helaReviveActive;
  set helaReviveActive(bool value) {
    Prefs().setUseHelaRevive(value);
    _helaReviveActive = value;
  }
  */

  bool _wtfReviveActive = false;
  bool get wtfReviveActive => _wtfReviveActive;
  set wtfReviveActive(bool value) {
    Prefs().setUseWtfRevive(value);
    _wtfReviveActive = value;
  }

  bool _midnightXReviveActive = false;
  bool get midnightXReviveActive => _midnightXReviveActive;
  set midnightXReviveActive(bool value) {
    Prefs().setUseMidnightXevive(value);
    _midnightXReviveActive = value;
  }

  bool _wolverinesReviveActive = false;
  bool get wolverinesReviveActive => _wolverinesReviveActive;
  set wolverinesReviveActive(bool value) {
    Prefs().setUseWolverinesRevive(value);
    _wolverinesReviveActive = value;
  }

  bool _statsShareIncludeHiddenTargets = true;
  bool get statsShareIncludeHiddenTargets => _statsShareIncludeHiddenTargets;
  set statsShareIncludeHiddenTargets(bool value) {
    _statsShareIncludeHiddenTargets = value;
    Prefs().setStatsShareIncludeHiddenTargets(value);
    update();
  }

  bool _statsShareShowOnlyTotals = false;
  bool get statsShareShowOnlyTotals => _statsShareShowOnlyTotals;
  set statsShareShowOnlyTotals(bool value) {
    _statsShareShowOnlyTotals = value;
    Prefs().setStatsShareShowOnlyTotals(value);
    update();
  }

  bool _statsShareShowEstimatesIfNoSpyAvailable = true;
  bool get statsShareShowEstimatesIfNoSpyAvailable => _statsShareShowEstimatesIfNoSpyAvailable;
  set statsShareShowEstimatesIfNoSpyAvailable(bool value) {
    _statsShareShowEstimatesIfNoSpyAvailable = value;
    Prefs().setStatsShareShowEstimatesIfNoSpyAvailable(value);
    update();
  }

  bool _statsShareIncludeTargetsWithNoStatsAvailable = false;
  bool get statsShareIncludeTargetsWithNoStatsAvailable => _statsShareIncludeTargetsWithNoStatsAvailable;
  set statsShareIncludeTargetsWithNoStatsAvailable(bool value) {
    _statsShareIncludeTargetsWithNoStatsAvailable = value;
    Prefs().setStatsShareIncludeTargetsWithNoStatsAvailable(value);
    update();
  }

  bool toggleAddUserActive = false;

  String playerLocation = "";

  // FFScouter cache integration
  late final FFScouterCacheController _ffScouterCache;
  bool _preferFFScouterOverEstimated = false;
  int _ffsOverrideSpyMonths = 0;

  bool initialised = false;
  bool _initWithIntegrity = true;
  WarController({bool initWithIntegrity = true}) {
    _initWithIntegrity = initWithIntegrity;
  }

  List<PendingNotificationRequest> _pendingNotifications = <PendingNotificationRequest>[];
  List<PendingNotificationRequest> get pendingNotifications => _pendingNotifications;
  set pendingNotifications(List<PendingNotificationRequest> value) {
    _pendingNotifications = value;
    update();
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    initialise(needsIntegrityCheck: _initWithIntegrity);
  }

  Future<String?> addFaction(String factionId, List<TargetModel> targets) async {
    stopUpdate();

    final dynamic allAttacksSuccess = await getAllAttacks();

    // Return custom error code if faction already exists
    for (final FactionModel faction in factions) {
      if (faction.id.toString() == factionId) {
        return "error_existing";
      }
    }

    final apiResult = await ApiCallsV1.getFaction(factionId: factionId);
    if (apiResult is ApiError || (apiResult is FactionModel && apiResult.id == null)) {
      return "";
    }

    final faction = apiResult as FactionModel;
    factions.add(faction);

    // Add extra member information
    final DateTime addedTime = DateTime.now();
    faction.members!.forEach((memberId, member) {
      // Last updated time
      member!.memberId = int.parse(memberId);
      member.lastUpdated = addedTime;
      for (final t in targets) {
        // Try to match information with pre-existing targets
        if (t.playerId.toString() == memberId) {
          if (t.respectGain != -1) {
            member.respectGain = t.respectGain;
            member.fairFight = t.fairFight;
          }
          member.hospitalSort = membersSortHospitalTime(member);
          break;
        }
      }

      _assignSpiedStats(member);

      if (allAttacksSuccess is AttackModel) {
        _getRespectFF(
          allAttacksSuccess,
          member,
          oldRespect: member.respectGain,
          oldFF: member.fairFight,
        );
      }
    });

    update();
    savePreferences();

    // Populate FFScouter cache for new members (fire-and-forget, rebuilds cards when done)
    if (_preferFFScouterOverEstimated && faction.members != null) {
      final newIds = faction.members!.keys.map((k) => int.tryParse(k)).whereType<int>().toList();
      if (newIds.isNotEmpty) {
        _ffScouterCache.ensureFresh(newIds).then((fetched) {
          if (fetched > 0) update();
        });
      }
    }

    return faction.name;
  }

  void removeFaction(int? removeId) {
    stopUpdate();
    // Remove also if it was filtered
    factions.removeWhere((f) => f.id == removeId);
    _integrityCheck(force: true);
    savePreferences();
    update();
  }

  void filterFaction(int? factionId) {
    stopUpdate();
    final FactionModel faction = factions.where((f) => f.id == factionId).first;
    faction.hidden = !faction.hidden!;
    savePreferences();
    update();
  }

  /// [allAttacks] is to be provided when updating several members at the same time, so that it does not have
  /// to call the API twice every time
  Future<bool> updateSingleMemberFull(
    Member member, {
    dynamic allAttacks,
    dynamic spies,
    dynamic ownStats,
    bool fromCard = false,
  }) async {
    dynamic allAttacksSuccess = allAttacks;
    allAttacksSuccess ??= await getAllAttacks();

    dynamic ownStatsSuccess = ownStats;
    ownStatsSuccess ??= await getOwnStats();

    member.isUpdating = true;
    update();

    // Ensure FFScouter cache is fresh for this member (no-op if already cached)
    if (_preferFFScouterOverEstimated && !_fullUpdateInProgress) {
      await _ffScouterCache.ensureFresh([member.memberId!]);
    }

    final String memberKey = member.memberId.toString();
    bool error = false;

    bool hitRateLimit = false;

    // Perform update with retry on rate limit
    try {
      dynamic updatedTarget;
      int retries = 0;
      final int maxRetries = (_fullUpdateInProgress && _apiGapMsCurrent == _apiGapMsBackoff) ? 10 : 5;
      bool requestCompleted = false;

      while (!requestCompleted && retries < maxRetries) {
        await _waitForApiSlot();
        updatedTarget = await ApiCallsV2.getOtherUserProfile_v2(
          payload: {
            "id": memberKey,
          },
        );

        if (_isRateLimitError(updatedTarget)) {
          hitRateLimit = true;
          if (_fullUpdateInProgress) {
            _enterThrottleMode();
          }
          retries++;
          await Future.delayed(Duration(seconds: 5 * retries));
          continue;
        }

        requestCompleted = true;
      }

      if (updatedTarget is OtherProfilePDA) {
        member.name = updatedTarget.name;
        member.level = updatedTarget.level;
        member.position = updatedTarget.factionPosition;
        member.overrideEasyLife = true;
        member.lifeMaximum = updatedTarget.lifeMaximum;
        member.lifeCurrent = updatedTarget.lifeCurrent;
        member.lastAction!.relative = updatedTarget.lastActionRelative;
        member.lastAction!.status = updatedTarget.lastActionStatus;
        member.status!.description = updatedTarget.statusDescription;
        member.status!.state = updatedTarget.statusState;
        member.status!.until = updatedTarget.statusUntil;
        member.status!.color = updatedTarget.statusColor;
        member.bounty = updatedTarget.bountyDescription ?? "";

        // Erase previous bounties and calculate new ones
        _calculateMemberBounty(updatedTarget, member);

        member.lastUpdated = DateTime.now();
        if (allAttacksSuccess is AttackModel) {
          _getRespectFF(allAttacksSuccess, member, oldRespect: member.respectGain, oldFF: member.fairFight);
        }
        member.hospitalSort = membersSortHospitalTime(member);

        _assignSpiedStats(member);

        member.statsEstimated = StatsCalculator.calculateStats(
          criminalRecordTotal: updatedTarget.personalstats?.criminalRecordTotal,
          level: updatedTarget.level,
          networth: updatedTarget.personalstats?.networth,
          rank: updatedTarget.rank,
        );

        member.statsComparisonSuccess = false;
        if (ownStatsSuccess is OwnPersonalStatsModel) {
          member.statsComparisonSuccess = true;
          member.memberXanax = updatedTarget.personalstats?.xanax ?? 0;
          member.myXanax = ownStatsSuccess.personalstats!.xantaken;

          member.memberRefill = updatedTarget.personalstats?.energyRefills ?? 0;
          member.myRefill = ownStatsSuccess.personalstats!.refills;

          member.memberEnhancement = updatedTarget.personalstats?.statEnhancers ?? 0;
          member.memberCans = updatedTarget.personalstats?.energyDrinks ?? 0;

          member.myCans = ownStatsSuccess.personalstats!.energydrinkused;
          member.myEnhancement = ownStatsSuccess.personalstats!.statenhancersused;

          member.memberEcstasy = updatedTarget.personalstats?.ecstasy ?? 0;
          member.memberLsd = updatedTarget.personalstats?.lsd ?? 0;
        }

        // Even if we assign both exact (if available) and estimated, we only pass estimated to startSort
        // if exact does not exist (-1)
        if (member.statsExactTotal == -1) {
          // Prefer FFScouter BS estimate for statsSort when available (more precise than range-based estimate)
          final ffsEntry = _preferFFScouterOverEstimated ? _ffScouterCache.get(member.memberId!) : null;
          if (ffsEntry != null && ffsEntry.bsEstimate != null) {
            member.statsSort = ffsEntry.bsEstimate!.round();
          } else {
            switch (member.statsEstimated) {
              case "< 2k":
                member.statsSort = 2000;
              case "2k - 25k":
                member.statsSort = 25000;
              case "20k - 250k":
                member.statsSort = 250000;
              case "200k - 2.5M":
                member.statsSort = 2500000;
              case "2M - 25M":
                member.statsSort = 25000000;
              case "20M - 250M":
                member.statsSort = 200000000;
              case "> 200M":
                member.statsSort = 250000000;
              default:
                member.statsSort = 0;
                break;
            }
          }
        }
      } else {
        // If we got an API error (including rate limits) or null, mark error and show throttling toast once
        if (_fullUpdateInProgress) {
          _enterThrottleMode();
        }
        error = true;
      }
    } catch (e) {
      error = true;
    }

    // If we hit rate limiting, add a small delay to avoid flooding
    if (hitRateLimit) {
      await Future.delayed(const Duration(seconds: 1));
    }

    // End animation and update
    member.isUpdating = false;

    // Clear cached ranges to force recalculation with new data
    attributeRanges.clear();

    update();

    // Avoid hundred of updates when performing a full faction update
    if (fromCard) {
      assessPendingNotifications();
    }

    final bool success = !error;
    if (_fullUpdateInProgress && success) {
      _fullUpdateSuccess++;
    }

    // Return result and save if successful
    if (success) {
      _updateResultAnimation(member: member, success: true);
      savePreferences();
      return true;
    }
    _updateResultAnimation(member: member, success: false);
    return false;
  }

  bool _isRateLimitError(dynamic result) {
    if (result is! ApiError) return false;
    final lowerReason = result.errorReason.toLowerCase();
    return result.errorId == 5 || lowerReason.contains('too many requests');
  }

  Future<void> _waitForApiSlot() async {
    final int elapsedMs = DateTime.now().difference(_lastApiCall).inMilliseconds;
    final int waitMs = elapsedMs >= _apiGapMsCurrent ? 0 : _apiGapMsCurrent - elapsedMs;
    _apiRateLimiter = _apiRateLimiter.then((_) => Future.delayed(Duration(milliseconds: waitMs)));
    await _apiRateLimiter;
    _lastApiCall = DateTime.now();
  }

  void _showThrottleToastIfNeeded() {
    if (_throttleToastShown) return;

    final int remaining = (_fullUpdateTotal - _fullUpdateSuccess).clamp(0, _fullUpdateTotal);
    if (remaining <= 0) return;

    _throttleToastShown = true;
    final int estSeconds = _estimateRemainingSeconds();

    BotToast.showText(
      clickClose: true,
      text:
          "Many targets to update. Throttling to avoid API limits. Remaining: $remaining targets (~${estSeconds}s).\n\n"
          "Failed updates will be retried automatically.",
      duration: const Duration(seconds: 5),
      contentColor: Colors.orange[700] ?? Colors.orange,
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentPadding: const EdgeInsets.all(10),
    );

    log("Throttling updates to avoid API limits. Estimated remaining time: ${estSeconds}s for $remaining targets.");
  }

  int _estimateRemainingSeconds() {
    final int remaining = (_fullUpdateTotal - _fullUpdateSuccess).clamp(0, _fullUpdateTotal);
    final double seconds = remaining * (_apiGapMsCurrent / 1000.0);
    return seconds.ceil();
  }

  void _enterThrottleMode() {
    _apiGapMsCurrent = _apiGapMsBackoff;
    _concurrencyCurrent = _concurrencyBackoff;

    // Show toast after switching to backoff values so the estimate reflects throttle mode
    _showThrottleToastIfNeeded();
  }

  Future<List<int>> updateAllMembersFull() async {
    await _integrityCheck(force: true);

    // Get all attacks and own stats from the API
    final dynamic allAttacksSuccess = await getAllAttacks();
    final dynamic ownStatsSuccess = await getOwnStats();
    int numberUpdated = 0;

    _throttleToastShown = false;
    _fullUpdateSuccess = 0;
    _fullUpdateInProgress = true;
    _apiGapMsCurrent = _apiGapMsBase;
    _concurrencyCurrent = _concurrencyBase;

    updating = true;
    update();

    // Copy lists so that alterations (hiding) do not cause error
    // which might happen even if we stop the update
    List<WarCardDetails> thisCards = List.from(orderedCardsDetails);
    List<FactionModel> thisFactions = List.from(factions);

    _fullUpdateTotal = thisCards.length;

    // Bulk prefetch FFScouter BS estimates for all visible members (stale/missing only)
    _preferFFScouterOverEstimated = await Prefs().getPreferFFScouterOverEstimated();
    _ffsOverrideSpyMonths = await Prefs().getFfsOverrideSpyMonths();
    if (_preferFFScouterOverEstimated) {
      final allMemberIds = thisCards.where((c) => c.memberId != null).map((c) => c.memberId!).toList();
      await _ffScouterCache.ensureFresh(allMemberIds);
    }

    // Process with limited concurrency and shared rate limiter to avoid bursts/rate limits
    int index = 0;
    final List<Future<void>> inFlight = [];
    final List<WarCardDetails> failedCards = [];

    Future<void> startTask(WarCardDetails card) async {
      for (final FactionModel f in thisFactions) {
        if (_stopUpdate) return;
        if (f.members!.containsKey(card.memberId.toString())) {
          final bool result = await updateSingleMemberFull(
            f.members![card.memberId.toString()]!,
            allAttacks: allAttacksSuccess,
            ownStats: ownStatsSuccess,
          );
          if (result) {
            numberUpdated++;
          } else {
            failedCards.add(card);
          }
          return;
        }
      }
    }

    while (index < thisCards.length || inFlight.isNotEmpty) {
      while (!_stopUpdate && index < thisCards.length && inFlight.length < _concurrencyCurrent) {
        final WarCardDetails card = thisCards[index++];
        final future = startTask(card);
        inFlight.add(future);
        future.whenComplete(() {
          inFlight.remove(future);
        });
      }

      if (_stopUpdate) {
        _stopUpdate = false;
        updating = false;
        _fullUpdateInProgress = false;
        update();
        return [thisCards.length, numberUpdated];
      }

      if (inFlight.isNotEmpty) {
        await Future.any(inFlight);
      }
    }

    // Retry failed ones sequentially under throttle
    if (failedCards.isNotEmpty && !_stopUpdate) {
      _enterThrottleMode();
      _concurrencyCurrent = _concurrencyBackoff;
      _apiGapMsCurrent = _apiGapMsBackoff;

      for (final WarCardDetails card in failedCards) {
        if (_stopUpdate) {
          _stopUpdate = false;
          updating = false;
          _fullUpdateInProgress = false;
          update();
          return [thisCards.length, numberUpdated];
        }

        for (final FactionModel f in thisFactions) {
          if (f.members!.containsKey(card.memberId.toString())) {
            bool retrySuccess = false;
            int attempts = 0;
            while (!retrySuccess && attempts < 10 && !_stopUpdate) {
              final bool result = await updateSingleMemberFull(
                f.members![card.memberId.toString()]!,
                allAttacks: allAttacksSuccess,
                ownStats: ownStatsSuccess,
              );
              retrySuccess = result;
              if (result) {
                numberUpdated++;
              } else {
                attempts++;
                if (attempts < 10) {
                  await Future.delayed(const Duration(seconds: 2));
                }
              }
            }
            break;
          }
        }
      }
    }

    _stopUpdate = false;
    updating = false;
    _fullUpdateInProgress = false;
    update();

    return [thisCards.length, numberUpdated];
  }

  Future<int> updateAllMembersEasy({bool forceIntegrityCheck = true}) async {
    final dynamic allAttacksSuccess = await getAllAttacks();

    stopUpdate();

    await _integrityCheck(force: forceIntegrityCheck);

    int numberUpdated = 0;

    // Get player's current location
    final apiPlayer = await ApiCallsV1.getOwnProfileBasic();
    if (apiPlayer is ApiError) {
      return -1;
    }
    final profile = apiPlayer as OwnProfileBasic;
    playerLocation = countryCheck(
      state: profile.status!.state,
      description: profile.status!.description,
    );

    // Refresh FFScouter cache for all members (fire-and-forget to avoid blocking quick update)
    _preferFFScouterOverEstimated = await Prefs().getPreferFFScouterOverEstimated();
    if (_preferFFScouterOverEstimated) {
      final allMemberIds = <int>[];
      for (final f in factions) {
        if (f.members != null) {
          for (final key in f.members!.keys) {
            final id = int.tryParse(key);
            if (id != null) allMemberIds.add(id);
          }
        }
      }
      if (allMemberIds.isNotEmpty) {
        _ffScouterCache.ensureFresh(allMemberIds).then((fetched) {
          if (fetched > 0) update();
        });
      }
    }

    for (final FactionModel f in factions) {
      final apiResult = await ApiCallsV1.getFaction(factionId: f.id.toString());
      if (apiResult is ApiError || (apiResult is FactionModel && apiResult.id == null)) {
        return -1;
      }
      final apiFaction = apiResult as FactionModel;

      final DateTime updatedTime = DateTime.now();
      apiFaction.members!.forEach((apiMemberId, apiMember) {
        if (f.members!.containsKey(apiMemberId)) {
          f.members![apiMemberId]!.overrideEasyLife = false;

          // Remove active bounties since we are not getting the necessary details from a quick update
          _removeMemberBountyInfo(f.members![apiMemberId]!);

          f.members![apiMemberId]!.justUpdatedWithSuccess = true;
          update();
          Future.delayed(const Duration(seconds: 2)).then((value) {
            f.members![apiMemberId]!.justUpdatedWithSuccess = false;
            update();
          });

          // Update only what's necessary (most info does not come from API)
          f.members![apiMemberId]!.lastUpdated = updatedTime;
          f.members![apiMemberId]!.status = apiMember!.status;
          f.members![apiMemberId]!.lastAction = apiMember.lastAction;
          f.members![apiMemberId]!.level = apiMember.level;
          f.members![apiMemberId]!.position = apiMember.position;
          f.members![apiMemberId]!.name = apiMember.name;

          _assignSpiedStats(f.members![apiMemberId]!);

          f.members![apiMemberId]!.hospitalSort = membersSortHospitalTime(f.members![apiMemberId]!);

          if (allAttacksSuccess is AttackModel) {
            _getRespectFF(
              allAttacksSuccess,
              f.members![apiMemberId],
              oldRespect: f.members![apiMemberId]!.respectGain,
              oldFF: f.members![apiMemberId]!.fairFight,
            );
          }

          numberUpdated++;
        }
      });
    }

    update();

    savePreferences();
    return numberUpdated;
  }

  Future updateSomeMembersAfterAttack({required List<String> lastAttackedMembers}) async {
    // Copies the list locally, as it will be erased by the webview after it has been sent
    // so that other attacks are possible
    List<String> lastAttackedCopy = List<String>.from(lastAttackedMembers);
    await Future.delayed(const Duration(seconds: 15));
    final dynamic allAttacksSuccess = await getAllAttacks();
    final dynamic ownStatsSuccess = await getOwnStats();

    updating = true;
    update();

    // Copy list so that alterations (hiding) do not cause error
    // which might happen even if we stop the update
    List<FactionModel> thisFactions = List.from(factions);

    for (final String id in lastAttackedCopy) {
      for (final FactionModel f in thisFactions) {
        if (_stopUpdate) {
          _stopUpdate = false;
          updating = false;
          update();
          return;
        }

        if (f.members!.containsKey(id)) {
          await updateSingleMemberFull(
            f.members![id]!,
            allAttacks: allAttacksSuccess,
            ownStats: ownStatsSuccess,
          );

          if (lastAttackedCopy.length > 60) {
            await Future.delayed(const Duration(seconds: 1));
          }
          break;
        }
        continue;
      }
    }

    _stopUpdate = false;
    updating = false;
    update();
    assessPendingNotifications();
  }

  void stopUpdate() {
    if (updating) {
      _stopUpdate = true;
    }
  }

  Future<void> _updateResultAnimation({Member? member, required bool success}) async {
    if (success) {
      member!.justUpdatedWithSuccess = true;
      update();
      await Future.delayed(const Duration(seconds: 5), () {});
      member.justUpdatedWithSuccess = false;
      update();
    } else {
      member!.justUpdatedWithError = true;
      update();
      await Future.delayed(const Duration(seconds: 5), () {});
      member.justUpdatedWithError = false;
      update();
    }
  }

  void _getRespectFF(
    AttackModel attackModel,
    Member? member, {
    double? oldRespect = -1,
    double? oldFF = -1,
  }) {
    double respect = -1;
    double? fairFight = -1; // Unknown
    List<bool> userWonOrDefended = <bool>[];
    attackModel.attacks!.forEach((key, value) {
      // We look for the our target in the the attacks list
      if (member!.memberId == value.defenderId || member.memberId == value.attackerId) {
        // Only update if we have still not found a positive value (because
        // we lost or we have no records)
        if (value.respectGain > 0) {
          fairFight = value.modifiers!.fairFight;
          respect = fairFight! * 0.25 * (math.log(member.level ?? 1) + 1);
        } else if (respect == -1) {
          respect = 0;
          fairFight = 1.00;
        }

        if (member.memberId == value.defenderId) {
          if (value.result == Result.LOST || value.result == Result.STALEMATE) {
            // If we attacked and lost
            userWonOrDefended.add(false);
          } else {
            userWonOrDefended.add(true);
          }
        } else if (member.memberId == value.attackerId) {
          if (value.result == Result.LOST || value.result == Result.STALEMATE) {
            // If we were attacked and the attacker lost
            userWonOrDefended.add(true);
          } else {
            userWonOrDefended.add(false);
          }
        }
      }
    });

    // Respect and fair fight should only update if they are not unknown (-1), which means we have a value
    // Otherwise, they default to -1 upon class instantiation
    if (respect != -1) {
      member!.respectGain = respect;
    } else if (respect == -1 && oldRespect != -1) {
      // If it is unknown BUT we have a previously recorded value, we need to provide it for the new target (or
      // otherwise it will default to -1). This can happen when the last attack on this target is not within the
      // last 100 total attacks and therefore it's not returned in the attackModel.
      member!.respectGain = oldRespect;
    }

    // Same as above
    if (fairFight != -1) {
      member!.fairFight = fairFight;
    } else if (fairFight == -1 && oldFF != -1) {
      member!.fairFight = oldFF;
    }

    if (userWonOrDefended.isNotEmpty) {
      member!.userWonOrDefended = userWonOrDefended.first;
    } else {
      member!.userWonOrDefended = true; // Placeholder
    }
  }

  void hideMember(Member? hiddenMember) {
    for (final f in factions) {
      if (f.members!.keys.contains(hiddenMember!.memberId.toString())) {
        f.members![hiddenMember.memberId.toString()]!.hidden = true;
        savePreferences();
        update();
        break;
      }
    }
  }

  void unhideMember(Member? hiddenMember) {
    for (final f in factions) {
      if (f.members!.keys.contains(hiddenMember!.memberId.toString())) {
        f.members![hiddenMember.memberId.toString()]!.hidden = false;
        savePreferences();
        update();
        break;
      }
    }
  }

  void pinMember(Member? pinMember) {
    for (final f in factions) {
      if (f.members!.keys.contains(pinMember!.memberId.toString())) {
        f.members![pinMember.memberId.toString()]!.pinned = true;
        savePreferences();
        update();
        break;
      }
    }
  }

  void unpinMember(Member? pinMember) {
    for (final f in factions) {
      if (f.members!.keys.contains(pinMember!.memberId.toString())) {
        f.members![pinMember.memberId.toString()]!.pinned = false;
        savePreferences();
        update();
        break;
      }
    }
  }

  int getHiddenMembersNumber() {
    int membersHidden = 0;
    for (final FactionModel f in factions) {
      membersHidden += f.members!.values.where((m) => m!.hidden!).length;
    }
    return membersHidden;
  }

  List<Member?> getHiddenMembersDetails() {
    List<Member?> membersHidden = <Member?>[];
    for (final FactionModel f in factions) {
      membersHidden.addAll(f.members!.values.where((m) => m!.hidden!));
    }
    return membersHidden;
  }

  dynamic getAllAttacks() async {
    final result = await ApiCallsV1.getAttacks();
    if (result is AttackModel) {
      return result;
    }
    return false;
  }

  dynamic getOwnStats() async {
    final result = await ApiCallsV1.getOwnPersonalStats();
    if (result is OwnPersonalStatsModel) {
      return result;
    }
    return false;
  }

  void toggleChainWidget() {
    showChainWidget = !showChainWidget;
    savePreferences();
    update();
  }

  void setOnlineFilter(int i) {
    onlineFilter = i;
    if (i == 0) {
      activeFilters.removeWhere((element) => element == "online/idle");
      activeFilters.removeWhere((element) => element == "offline");
    } else if (i == 1) {
      activeFilters.add("online/idle");
      activeFilters.removeWhere((element) => element == "offline");
    } else if (i == 2) {
      activeFilters.add("offline");
      activeFilters.removeWhere((element) => element == "online/idle");
    }
    savePreferences();
    update();
  }

  void setOkayRedFilter(int value) {
    okayRedFilter = value;
    if (value == 0) {
      activeFilters.removeWhere((element) => element == "okay");
      activeFilters.removeWhere((element) => element == "red");
    } else if (value == 1) {
      activeFilters.add("okay");
      activeFilters.removeWhere((element) => element == "red");
    } else if (value == 2) {
      activeFilters.add("red");
      activeFilters.removeWhere((element) => element == "okay");
    }
    savePreferences();
    update();
  }

  void setCountryFilterActive(bool value) {
    countryFilter = value;
    if (!value) {
      activeFilters.removeWhere((element) => element == "same country");
    } else {
      activeFilters.add("same country");
    }
    savePreferences();
    update();
  }

  void setTravelingFilterStatus(int value) {
    abroadFilter = value;
    if (value == 0) {
      activeFilters.removeWhere((element) => element == "not abroad");
      activeFilters.removeWhere((element) => element == "abroad");
    } else if (value == 1) {
      activeFilters.removeWhere((element) => element == "not abroad");
      activeFilters.add("abroad");
    } else if (value == 2) {
      activeFilters.removeWhere((element) => element == "abroad");
      activeFilters.add("not abroad");
    }
    savePreferences();
    update();
  }

  /// [needsIntegrityCheck] calls the API. Might not be necessary for simple controller uses
  /// (e.g.: profile widget)
  Future initialise({bool needsIntegrityCheck = true}) async {
    List<String> saved = await Prefs().getWarFactions();
    for (final element in saved) {
      factions.add(factionModelFromJson(element));
    }

    activeFilters = await Prefs().getFilterListInWars();
    onlineFilter = await Prefs().getOnlineFilterInWars();
    okayRedFilter = await Prefs().getOkayRedFilterInWars();
    countryFilter = await Prefs().getCountryFilterInWars();
    abroadFilter = await Prefs().getTravelingFilterInWars();
    showChainWidget = await Prefs().getShowChainWidgetInWars();

    nukeReviveActive = await Prefs().getUseNukeRevive();
    uhcReviveActive = await Prefs().getUseUhcRevive();
    //helaReviveActive = await Prefs().getUseHelaRevive();
    wtfReviveActive = await Prefs().getUseWtfRevive();
    midnightXReviveActive = await Prefs().getUseMidnightXRevive();
    wolverinesReviveActive = await Prefs().getUseWolverinesRevive();

    _statsShareIncludeHiddenTargets = await Prefs().getStatsShareIncludeHiddenTargets();
    _statsShareShowOnlyTotals = await Prefs().getStatsShareShowOnlyTotals();
    _statsShareShowEstimatesIfNoSpyAvailable = await Prefs().getStatsShareShowEstimatesIfNoSpyAvailable();
    _statsShareIncludeTargetsWithNoStatsAvailable = await Prefs().getStatsShareIncludeTargetsWithNoStatsAvailable();

    _preferFFScouterOverEstimated = await Prefs().getPreferFFScouterOverEstimated();
    _ffsOverrideSpyMonths = await Prefs().getFfsOverrideSpyMonths();
    _ffScouterCache = Get.find<FFScouterCacheController>();

    warSettings = await Prefs().getWarSettings();

    // Get sorting
    final String targetSort = await Prefs().getWarMembersSort();
    switch (targetSort) {
      case '':
        currentSort = WarSortType.levelDes;
      case 'levelDes':
        currentSort = WarSortType.levelDes;
      case 'levelAsc':
        currentSort = WarSortType.levelAsc;
      case 'respectDes':
        currentSort = WarSortType.respectDes;
      case 'respectAsc':
        currentSort = WarSortType.respectAsc;
      case 'nameDes':
        currentSort = WarSortType.nameDes;
      case 'nameAsc':
        currentSort = WarSortType.nameAsc;
      case 'lifeDes':
        currentSort = WarSortType.lifeDes;
      case 'lifeAsc':
        currentSort = WarSortType.lifeAsc;
      case 'hospitalDes':
        currentSort = WarSortType.hospitalDes;
      case 'hospitalAsc':
        currentSort = WarSortType.hospitalAsc;
      case 'statsDes':
        currentSort = WarSortType.statsDes;
      case 'statsAsc':
        currentSort = WarSortType.statsDes;
      case 'onlineDes':
        currentSort = WarSortType.onlineDes;
      case 'onlineAsc':
        currentSort = WarSortType.onlineAsc;
      case 'colorDes':
        currentSort = WarSortType.colorDes;
      case 'colorAsc':
        currentSort = WarSortType.colorAsc;
      case 'notesDes':
        currentSort = WarSortType.notesDes;
      case 'notesAsc':
        currentSort = WarSortType.notesAsc;
      case 'bounty':
        currentSort = WarSortType.bounty;
      case 'travelDistanceDes':
        currentSort = WarSortType.travelDistanceDesc;
      case 'travelDistanceAsc':
        currentSort = WarSortType.travelDistanceAsc;
      case 'smartScore':
        currentSort = WarSortType.smartScore;
    }

    _lastIntegrityCheck = DateTime.fromMillisecondsSinceEpoch(await Prefs().getWarIntegrityCheckTime());

    if (needsIntegrityCheck) {
      _integrityCheck();
    }

    initialised = true;
    update();

    // Trigger initial FFScouter cache population for all existing members
    if (_preferFFScouterOverEstimated && factions.isNotEmpty) {
      final allIds = <int>[];
      for (final f in factions) {
        if (f.members != null) {
          for (final key in f.members!.keys) {
            final id = int.tryParse(key);
            if (id != null) allIds.add(id);
          }
        }
      }
      if (allIds.isNotEmpty) {
        _ffScouterCache.ensureFresh(allIds).then((fetched) {
          if (fetched > 0) {
            update(); // Rebuild cards so they pick up cached data
          }
        });
      }
    }
  }

  void savePreferences() {
    // Remove any duplicate members within each faction
    for (final faction in factions) {
      faction.members = Map.fromEntries(faction.members!.entries.toSet());
    }

    List<String> factionList = [];
    for (final element in factions) {
      factionList.add(factionModelToJson(element));
    }
    Prefs().setWarFactions(factionList);

    Prefs().setFilterListInWars(activeFilters);
    Prefs().setOnlineFilterInWars(onlineFilter);
    Prefs().setOkayRedFilterInWars(okayRedFilter);
    Prefs().setCountryFilterInWars(countryFilter);
    Prefs().setTravelingFilterInWars(abroadFilter);
    Prefs().setShowChainWidgetInWars(showChainWidget);
    Prefs().setWarSettings(warSettings);

    // Save sorting
    late String sortToSave;
    switch (currentSort ??= WarSortType.nameAsc) {
      case WarSortType.levelDes:
        sortToSave = 'levelDes';
        break;
      case WarSortType.levelAsc:
        sortToSave = 'levelAsc';
        break;
      case WarSortType.respectDes:
        sortToSave = 'respectDes';
        break;
      case WarSortType.respectAsc:
        sortToSave = 'respectAsc';
        break;
      case WarSortType.nameDes:
        sortToSave = 'nameDes';
        break;
      case WarSortType.nameAsc:
        sortToSave = 'nameAsc';
        break;
      case WarSortType.lifeDes:
        sortToSave = 'lifeDes';
        break;
      case WarSortType.lifeAsc:
        sortToSave = 'lifeAsc';
        break;
      case WarSortType.hospitalDes:
        sortToSave = 'hospitalDes';
        break;
      case WarSortType.hospitalAsc:
        sortToSave = 'hospitalAsc';
        break;
      case WarSortType.statsDes:
        sortToSave = 'statsDes';
        break;
      case WarSortType.statsAsc:
        sortToSave = 'statsAsc';
        break;
      case WarSortType.onlineDes:
        sortToSave = 'onlineDes';
        break;
      case WarSortType.onlineAsc:
        sortToSave = 'onlineAsc';
        break;
      case WarSortType.colorDes:
        sortToSave = 'colorDes';
        break;
      case WarSortType.colorAsc:
        sortToSave = 'colorAsc';
        break;
      case WarSortType.notesDes:
        sortToSave = 'notesDes';
        break;
      case WarSortType.notesAsc:
        sortToSave = 'notesAsc';
        break;
      case WarSortType.bounty:
        sortToSave = 'bounty';
        break;
      case WarSortType.travelDistanceDesc:
        sortToSave = 'travelDistanceDes';
        break;
      case WarSortType.travelDistanceAsc:
        sortToSave = 'travelDistanceAsc';
        break;
      case WarSortType.smartScore:
        sortToSave = 'smartScore';
        break;
    }
    Prefs().setWarMembersSort(sortToSave);
  }

  void sortTargets(WarSortType sortType) {
    currentSort = sortType;
    savePreferences();
    update();
  }

  Future<void> launchShowCaseAddFaction() async {
    showCaseStart = true;
    update();
  }

  void toggleAddFromUserId() {
    addFromUserId = !addFromUserId;
    update();
  }

  void setAddUserActive(bool active) {
    toggleAddUserActive = active;
    update();
  }

  Future<void> _integrityCheck({bool force = false}) async {
    // Prevent concurrent execution
    if (_integrityChecking) return;
    _integrityChecking = true;

    try {
      if (!force && DateTime.now().difference(_lastIntegrityCheck).inMinutes < 10) {
        return;
      }

      // Parallel API calls for efficiency
      final results = await Future.wait(factions.map((f) => ApiCallsV1.getFaction(factionId: f.id.toString())));

      for (int i = 0; i < factions.length; i++) {
        final FactionModel faction = factions[i];
        final dynamic apiResult = results[i];

        if (apiResult is ApiError || (apiResult is FactionModel && apiResult.id == null)) {
          continue;
        }
        final FactionModel apiImport = apiResult as FactionModel;

        // Remove members that no longer belong to the faction
        faction.members = Map.fromEntries(faction.members!.entries.where(
          (entry) => apiImport.members!.containsKey(entry.key),
        ));

        // Add new members without overwriting
        apiImport.members!.forEach((key, value) {
          if (!faction.members!.containsKey(key)) {
            faction.members![key] = value;
            updateSingleMemberFull(faction.members![key]!);
          }
        });

        // Ensure no duplicates exist in the member list
        faction.members = Map.fromEntries(faction.members!.entries.toSet());
      }

      Prefs().setWarIntegrityCheckTime(DateTime.now().millisecondsSinceEpoch);
      savePreferences();
      assessPendingNotifications();

      // Clear cached ranges to force recalculation with new data
      attributeRanges.clear();

      update();
    } finally {
      _integrityChecking = false;
    }
  }

  int membersSortHospitalTime(Member m) {
    if (m.status!.state == "Hospital") {
      return m.status!.until!;
    }
    return 0;
  }

  void _assignSpiedStats(Member member) {
    final SpiesController spyController = Get.find<SpiesController>();

    void assignTornStatsSpy(Member member, SpyElement spy) {
      member.spySource = SpiesSource.tornStats;
      member.statsExactTotal = member.statsSort = spy.total;
      member.statsExactUpdated = spy.timestamp;
      member.statsStr = spy.strength;
      member.statsSpd = spy.speed;
      member.statsDef = spy.defense;
      member.statsDex = spy.dexterity;

      int known = 0;
      if (spy.strength != -1) known += spy.strength!;
      if (spy.speed != -1) known += spy.speed!;
      if (spy.defense != -1) known += spy.defense!;
      if (spy.dexterity != -1) known += spy.dexterity!;
      member.statsExactTotalKnown = known;
    }

    void assignYataSpy(Member member, YataSpyModel spy) {
      member.spySource = SpiesSource.yata;
      member.statsExactTotal = member.statsSort = spy.total;
      member.statsExactTotalUpdated = spy.totalTimestamp;
      member.statsExactUpdated = spy.update;
      member.statsStr = spy.strength;
      member.statsStrUpdated = spy.strengthTimestamp;
      member.statsSpd = spy.speed;
      member.statsSpdUpdated = spy.speedTimestamp;
      member.statsDef = spy.defense;
      member.statsDefUpdated = spy.defenseTimestamp;
      member.statsDex = spy.dexterity;
      member.statsDexUpdated = spy.dexterityTimestamp;

      int known = 0;
      if (spy.strength != -1) known += spy.strength!;
      if (spy.speed != -1) known += spy.speed!;
      if (spy.defense != -1) known += spy.defense!;
      if (spy.dexterity != -1) known += spy.dexterity!;
      member.statsExactTotalKnown = known;
    }

    // Continue with existing logic to determine spy source
    bool spyFound = false;

    // Clean stats if not allowed to mix spy sources
    if ((!spyController.allowMixedSpiesSources &&
            member.spySource != SpiesSource.yata &&
            spyController.spiesSource == SpiesSource.yata) ||
        (!spyController.allowMixedSpiesSources &&
            member.spySource != SpiesSource.tornStats &&
            spyController.spiesSource == SpiesSource.tornStats)) {
      _deleteSpiedStats(member);
    }

    // Assign spies based on the source
    if (spyController.spiesSource == SpiesSource.yata) {
      final spy = spyController.getYataSpy(userId: member.memberId.toString(), name: member.name);
      if (spy != null) {
        assignYataSpy(member, spy);
        spyFound = true;
      } else if (spyController.allowMixedSpiesSources) {
        // Check alternate source of spies if we allow mixed sources
        final altSpy = spyController.getTornStatsSpy(userId: member.memberId.toString());
        if (altSpy != null) {
          assignTornStatsSpy(member, altSpy);
          spyFound = true;
        }
      }
    } else if (spyController.spiesSource == SpiesSource.tornStats) {
      final spy = spyController.getTornStatsSpy(userId: member.memberId.toString());
      if (spy != null) {
        assignTornStatsSpy(member, spy);
        spyFound = true;
      } else if (spyController.allowMixedSpiesSources) {
        // Check alternate source of spies if we allow mixed sources
        final altSpy = spyController.getYataSpy(userId: member.memberId.toString(), name: member.name);
        if (altSpy != null) {
          assignYataSpy(member, altSpy);
          spyFound = true;
        }
      }
    }

    // If we didn't find a spy at all, delete the spies information (it might be an old spy,
    // or the user might have deleted and recreated the spies list)
    if (!spyFound) {
      _deleteSpiedStats(member);
    }
  }

  void _deleteSpiedStats(Member member) {
    member.spySource = SpiesSource.yata;
    member.statsExactTotal = -1;
    member.statsExactTotalUpdated = -1;
    member.statsExactUpdated = -1;
    member.statsStr = -1;
    member.statsStrUpdated = -1;
    member.statsSpd = -1;
    member.statsSpdUpdated = -1;
    member.statsDef = -1;
    member.statsDefUpdated = -1;
    member.statsDex = -1;
    member.statsDexUpdated = -1;
    member.statsExactTotalKnown = -1;
  }

  void _calculateMemberBounty(OtherProfilePDA updatedTarget, Member member) {
    if (updatedTarget.bountyDescription != null) {
      // API example text: Bounty - On this person's head for $200,000 : "Optional reason"
      RegExp amountRegex = RegExp(r"\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?");
      Match? match = amountRegex.firstMatch(updatedTarget.bountyDescription!);
      if (match != null) {
        String amountStr = match.group(0)!;
        amountStr = amountStr.replaceAll(",", "").replaceAll("\$", "");
        member.bountyAmount = int.tryParse(amountStr);
      }
    } else {
      // Erase bounty information in case there was a previous [bountyAmount] saved
      _removeMemberBountyInfo(member);
    }
  }

  void _removeMemberBountyInfo(Member m) {
    m.bounty = "";
    m.bountyAmount = null;
  }

  void assessPendingNotifications() async {
    if (Platform.isWindows) return;

    try {
      // Get the current active notifications
      List<PendingNotificationRequest> active = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      List<PendingNotificationRequest> newList = List<PendingNotificationRequest>.from(active);

      // Assess whether the last udpated members are still in the same condition
      for (final notification in active) {
        // Check notificaiton ids 300 only
        if (notification.payload == null) continue;
        if (!notification.payload!.contains("300-")) continue;

        String notificationMemberId = notification.payload!.split("-")[1];
        String notificationTime = notification.payload!.split("-")[2];
        String notificationPlace = notification.payload!.split("#")[1];

        bool memberFound = false;

        // Locate the member
        for (final FactionModel f in factions) {
          f.members!.forEach((apiMemberId, apiMember) async {
            if (apiMember!.memberId!.toString() == notificationMemberId) {
              memberFound = true;
              bool remove = false;

              // Remove notification if no longet in hospital or jail condition
              if (apiMember.status!.state! == "Hospital") {
                if (notificationPlace != "h") {
                  log("Removing member ${apiMember.memberId!} notification as he's no longer in Hospital");
                  remove = true;
                }
              } else if (apiMember.status!.state! == "Jail") {
                if (notificationPlace != "j") {
                  log("Removing member ${apiMember.memberId!} notification as he's no longer in Jail");
                  remove = true;
                }
              } else {
                log("Removing member ${apiMember.memberId!} notification as he's no longer in red state");
                remove = true;
              }

              // Remove notification if time has elapsed
              if (!remove) {
                int? ts = int.tryParse(notificationTime);
                if (ts != null) {
                  DateTime notTime = DateTime.fromMillisecondsSinceEpoch(ts);
                  if (notTime.isBefore(DateTime.now())) {
                    remove = true;
                    log("Removing member ${apiMember.memberId!} notification as it's expired");
                  }
                }
              }

              if (remove) {
                await flutterLocalNotificationsPlugin.cancel(apiMember.memberId!);
                newList.removeWhere((element) => element.payload!.contains("300-${apiMember.memberId!}"));
              }
            }
          });
        }

        // If member is not found, remove its notification
        if (!memberFound) {
          log("Member $notificationMemberId not found, removing its notification");
          await flutterLocalNotificationsPlugin.cancel(int.parse(notificationMemberId));
          newList.removeWhere((element) => element.payload!.contains("300-$notificationMemberId"));
        }
      }

      // Print the list of pending war member notifications
      if (newList.isNotEmpty) {
        log("Found pending war member notifications: ${newList.map((notification) => notification.payload).toList()}");
      }

      pendingNotifications = List<PendingNotificationRequest>.from(newList);

      update();
    } catch (e, trace) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at Assess Pending Notifications");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
    }
  }

  void calculateAttributeRanges() {
    List<double> stats = [];
    List<double> est = [];
    List<double> str = [];
    List<double> def = [];
    List<double> spd = [];
    List<double> dex = [];
    List<double> hospital = [];

    // Collect all valid stats
    for (var faction in factions) {
      if (faction.members != null) {
        for (var m in faction.members!.values) {
          if (m == null) continue;

          // Estimated (prefer FFS if available)
          double e = getMemberEstimatedStats(m);
          if (e <= 0 && _preferFFScouterOverEstimated && m.memberId != null) {
            final ffs = _ffScouterCache.get(m.memberId!);
            if (ffs != null && ffs.bsEstimate != null) e = ffs.bsEstimate!.toDouble();
          }
          if (e > 0) est.add(e);

          // Total Stats (including FFS fallback)
          double s = getMemberTotalStatsWithFFS(m);
          if (s > 0) stats.add(s);

          // Individual
          if (m.statsStr != null && m.statsStr! > 0) str.add(m.statsStr!.toDouble());
          if (m.statsDef != null && m.statsDef! > 0) def.add(m.statsDef!.toDouble());
          if (m.statsSpd != null && m.statsSpd! > 0) spd.add(m.statsSpd!.toDouble());
          if (m.statsDex != null && m.statsDex! > 0) dex.add(m.statsDex!.toDouble());

          // Hospital Time
          if (m.status?.state == 'Hospital') {
            int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            int remaining = (m.status?.until ?? 0) - now;
            if (remaining < 0) remaining = 0;
            hospital.add(remaining.toDouble());
          } else {
            hospital.add(0.0);
          }
        }
      }
    }

    // Calculate Log Range with spread for a given list of stats
    // Normalize scores between 0.0 and 1.0.
    Map<String, double> calcRange(List<double> values) {
      if (values.isEmpty) return {'min': 0, 'max': 10, 'spread': 10, 'count': 0}; // Default fallback

      // We use Log10 to handle the massive difference in stats
      // We add +1 to avoid log(0) errors
      var logs = values.map((v) => math.log(v + 1) / math.ln10).toList();

      // Find the lowest and highest log values in the data
      double minLog = logs.reduce(math.min);
      double maxLog = logs.reduce(math.max);

      // Spread rule (min 2.0 difference)
      // If the difference between the strongest and weakest is too small (e.g. everyone has similar stats)
      // the normalization would be too sensitive (small differences would look huge).
      // We apply a minimum spread of 2.0 (which corresponds to a 100x difference in raw values)
      double spread = maxLog - minLog;
      if (spread < 2.0) {
        maxLog = minLog + 2.0;
        spread = 2.0;
      }

      return {'min': minLog, 'max': maxLog, 'spread': spread, 'count': values.length.toDouble()};
    }

    attributeRanges['Stats'] = calcRange(stats);
    attributeRanges['Estimated'] = calcRange(est);
    attributeRanges['Str'] = calcRange(str);
    attributeRanges['Def'] = calcRange(def);
    attributeRanges['Spd'] = calcRange(spd);
    attributeRanges['Dex'] = calcRange(dex);

    // Hospital - Fixed range 0-100h to match filter and avoid outlier skewing
    if (hospital.isNotEmpty) {
      double maxHosp = 360000; // 100 hours
      double maxLogHosp = math.log(maxHosp + 1) / math.ln10;
      attributeRanges['Hospital'] = {
        'min': 0.0,
        'max': maxLogHosp,
        'spread': maxLogHosp,
        'count': hospital.length.toDouble(),
      };
    } else {
      attributeRanges['Hospital'] = {'min': 0, 'max': 10, 'spread': 10, 'count': 0};
    }
  }

  double calculateSmartScore(Member member) {
    return getSmartScoreDetails(member)['total']!;
  }

  /// Returns true when the member has spied stats BUT the spy is older than
  /// the user-configured threshold ([_ffsOverrideSpyMonths]), and a fresh FFS
  /// cache entry exists. In that case callers should prefer the FFS value.
  bool _shouldFfsOverrideSpy(Member member) {
    if (_ffsOverrideSpyMonths <= 0) return false;
    if (!_preferFFScouterOverEstimated) return false;
    // Must have spied stats to consider overriding
    if (member.statsExactTotal == null || member.statsExactTotal == -1) return false;
    // Need a valid spy timestamp
    final ts = member.statsExactUpdated;
    if (ts == null || ts <= 0) return false;
    // Compute age in months (same logic as SpiesController.statsOld)
    final spyDate = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final ageDays = DateTime.now().difference(spyDate).inDays;
    final ageMonths = ageDays ~/ 30;
    if (ageMonths < _ffsOverrideSpyMonths) return false;
    // Finally check that we actually have FFS data
    if (member.memberId == null) return false;
    final ffs = _ffScouterCache.get(member.memberId!);
    return ffs != null && ffs.bsEstimate != null;
  }

  double getMemberTotalStats(Member member) {
    if (member.statsExactTotal != null && member.statsExactTotal != -1) {
      return member.statsExactTotal!.toDouble();
    }
    return 0.0;
  }

  /// Like [getMemberTotalStats] but falls back to the FFScouter BS estimate.
  /// Also returns FFS when spied stats exist but are too old (spy age threshold).
  /// Used for the "Total Stats (Spied/FFS)" filter and its slider range.
  double getMemberTotalStatsWithFFS(Member member) {
    // If spied stats exist but spy is too old, prefer FFS
    if (_shouldFfsOverrideSpy(member)) {
      final ffs = _ffScouterCache.get(member.memberId!);
      return ffs!.bsEstimate!.toDouble();
    }
    final spied = getMemberTotalStats(member);
    if (spied > 0) return spied;
    if (_preferFFScouterOverEstimated && member.memberId != null) {
      final ffs = _ffScouterCache.get(member.memberId!);
      if (ffs != null && ffs.bsEstimate != null) return ffs.bsEstimate!.toDouble();
    }
    return 0.0;
  }

  double _getPartialExactStats(Member member) {
    // Use precomputed known total if available
    if (member.statsExactTotalKnown != null && member.statsExactTotalKnown! > 0) {
      return member.statsExactTotalKnown!.toDouble();
    }

    double sum = 0.0;
    bool hasAny = false;
    if (member.statsStr != null && member.statsStr! > 0) {
      sum += member.statsStr!;
      hasAny = true;
    }
    if (member.statsSpd != null && member.statsSpd! > 0) {
      sum += member.statsSpd!;
      hasAny = true;
    }
    if (member.statsDef != null && member.statsDef! > 0) {
      sum += member.statsDef!;
      hasAny = true;
    }
    if (member.statsDex != null && member.statsDex! > 0) {
      sum += member.statsDex!;
      hasAny = true;
    }

    return hasAny ? sum : 0.0;
  }

  /// Returns stats for sorting with grouping: 0 exact (total or partial), 1 estimate, 2 unknown
  ({int group, double value}) getMemberStatsForSorting(Member member) {
    // If spied but too old and FFS available, use FFS (group 1 = estimate)
    if (_shouldFfsOverrideSpy(member)) {
      final ffs = _ffScouterCache.get(member.memberId!);
      return (group: 1, value: ffs!.bsEstimate!.toDouble());
    }

    final double exact = getMemberTotalStats(member);
    if (exact > 0) return (group: 0, value: exact);

    final double partialExact = _getPartialExactStats(member);
    if (partialExact > 0) return (group: 0, value: partialExact);

    final double estimated = getMemberEstimatedStats(member);
    if (estimated > 0) return (group: 1, value: estimated);

    // FFScouter BS estimate as fallback for sorting (still an estimate → group 1)
    if (_preferFFScouterOverEstimated && member.memberId != null) {
      final ffsEntry = _ffScouterCache.get(member.memberId!);
      if (ffsEntry != null && ffsEntry.bsEstimate != null) {
        return (group: 1, value: ffsEntry.bsEstimate!.toDouble());
      }
    }

    return (group: 2, value: 0.0);
  }

  static const List<String> estimateCategories = [
    "< 2k",
    "2k - 25k",
    "20k - 250k",
    "200k - 2.5M",
    "2M - 25M",
    "20M - 250M",
    "> 200M"
  ];

  double getMemberEstimatedStats(Member member) {
    return _parseEstimate(member.statsEstimated);
  }

  int getMemberEstimatedStatsIndex(Member member) {
    if (member.statsEstimated == null) return -1;
    return estimateCategories.indexOf(member.statsEstimated!);
  }

  double _parseEstimate(String? estimate) {
    if (estimate == null || estimate.isEmpty) return 0.0;
    switch (estimate) {
      case "< 2k":
        return 2000;
      case "2k - 25k":
        return 25000;
      case "20k - 250k":
        return 250000;
      case "200k - 2.5M":
        return 2500000;
      case "2M - 25M":
        return 25000000;
      case "20M - 250M":
        return 200000000;
      case "> 200M":
        return 250000000;
      default:
        return 0.0;
    }
  }

  Map<String, double> getSmartScoreDetails(Member member) {
    if (attributeRanges.isEmpty) calculateAttributeRanges();
    double score = 0.0;

    double calcContribution(double? normalizedVal, double weight) {
      if (normalizedVal == null) return 0.0; // Unknown is 0 points
      if (weight < 0) {
        return (1.0 - normalizedVal) * weight.abs();
      } else {
        return normalizedVal * weight;
      }
    }

    // Log-MinMax scaling
    double? calcLogScore(double val, String key) {
      if (val <= 0) return null;
      var range = attributeRanges[key];

      // Should not happen if init correctly
      if (range == null) return 0.0;

      double valLog = math.log(val + 1) / math.ln10;
      double minLog = range['min']!;
      double spread = range['spread']!;

      // Clamp to range (just in case)
      if (valLog < minLog) valLog = minLog;
      if (valLog > range['max']!) valLog = range['max']!;

      return (valLog - minLog) / spread;
    }

    // Hospital Time
    double? hospitalScore;
    int seconds = 0;
    bool inHospital = false;
    if (member.status?.state == 'Hospital') {
      inHospital = true;
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      seconds = (member.status?.until ?? 0) - now;
      if (seconds < 0) seconds = 0;
    }

    // Only calculate score if actually in hospital.
    // If not in hospital, score is null (0 contribution), so they don't get points for "0 seconds".
    double hospitalContribution = 0.0;
    if (inHospital) {
      hospitalScore = calcLogScore(seconds.toDouble(), 'Hospital');
      // If calcLogScore returns null (e.g. val <= 0), we treat it as 0.0 normalized (min value)
      hospitalScore ??= 0.0;
      hospitalContribution = calcContribution(hospitalScore, warSettings.weightHospitalTime);
      score += hospitalContribution;
    } else {
      // Not in hospital -> No score contribution (Neutral)
      hospitalScore = null;
    }

    // Life
    double? lifeScore;
    if (member.lifeCurrent != null && member.lifeMaximum != null && member.lifeMaximum! > 0) {
      lifeScore = member.lifeCurrent! / member.lifeMaximum!;
    } else {
      lifeScore = null;
    }
    double lifeContribution = calcContribution(lifeScore, warSettings.weightLife);
    score += lifeContribution;

    // Estimated Stats (with FFS fallback)
    double? estimatedStatsScore;
    double estimatedVal = getMemberEstimatedStats(member);
    if (estimatedVal <= 0 && _preferFFScouterOverEstimated && member.memberId != null) {
      final ffs = _ffScouterCache.get(member.memberId!);
      if (ffs != null && ffs.bsEstimate != null) estimatedVal = ffs.bsEstimate!.toDouble();
    }
    if (estimatedVal > 0) {
      estimatedStatsScore = calcLogScore(estimatedVal, 'Estimated');
    }
    double estimatedStatsContribution = calcContribution(estimatedStatsScore, warSettings.weightEstimatedStats);
    score += estimatedStatsContribution;

    // Spied stats (with FFS fallback)
    double statsContribution = 0.0;
    double strContribution = 0.0;
    double defContribution = 0.0;
    double spdContribution = 0.0;
    double dexContribution = 0.0;

    double? statsScore;
    double totalStatsVal = getMemberTotalStatsWithFFS(member);
    if (totalStatsVal > 0) {
      statsScore = calcLogScore(totalStatsVal, 'Stats');
    }
    statsContribution = calcContribution(statsScore, warSettings.weightStats);
    score += statsContribution;

    strContribution =
        calcContribution(calcLogScore(member.statsStr?.toDouble() ?? 0, 'Str'), warSettings.weightStrength);
    defContribution =
        calcContribution(calcLogScore(member.statsDef?.toDouble() ?? 0, 'Def'), warSettings.weightDefense);
    spdContribution = calcContribution(calcLogScore(member.statsSpd?.toDouble() ?? 0, 'Spd'), warSettings.weightSpeed);
    dexContribution =
        calcContribution(calcLogScore(member.statsDex?.toDouble() ?? 0, 'Dex'), warSettings.weightDexterity);

    score += strContribution + defContribution + spdContribution + dexContribution;

    // Fair Fight
    // Normalize 0.0 (1.0 FF) to 1.0 (3.0 FF)
    double? ffScore;
    if (member.fairFight != null && member.fairFight! >= 1.0) {
      double ff = member.fairFight!;
      if (ff < 1.0) ff = 1.0;
      if (ff > 3.0) ff = 3.0;
      // Map 1.0->0.0, 3.0->1.0
      ffScore = (ff - 1.0) / 2.0;
    }
    double ffContribution = calcContribution(ffScore, warSettings.weightFairFight);
    score += ffContribution;

    // Level
    // Normalize: 0.0 (Lvl 1) to 1.0 (Lvl 100)
    double? levelScore;
    if (member.level != null) {
      double lvl = member.level!.toDouble();
      if (lvl > 100) lvl = 100;
      levelScore = lvl / 100.0;
    }
    double levelContribution = calcContribution(levelScore, warSettings.weightLevel);
    score += levelContribution;

    return {
      'total': score,
      'Hospital': hospitalContribution,
      'Life': lifeContribution,
      'Stats': statsContribution,
      'Estimated Stats': estimatedStatsContribution,
      'Str': strContribution,
      'Def': defContribution,
      'Spd': spdContribution,
      'Dex': dexContribution,
      'Fair Fight': ffContribution,
      'Level': levelContribution,
    };
  }

  // Sorting function for MemberModel lists to be used in shareStats
  int compareMembers(Member a, Member b, WarSortType sortType) {
    // Get the notes controller once for all note/color related operations
    PlayerNotesController? notesProvider;
    if (sortType == WarSortType.colorDes ||
        sortType == WarSortType.colorAsc ||
        sortType == WarSortType.notesDes ||
        sortType == WarSortType.notesAsc) {
      notesProvider = Get.find<PlayerNotesController>();
    }

    switch (sortType) {
      case WarSortType.levelDes:
        return (b.level ?? 0).compareTo(a.level ?? 0);
      case WarSortType.levelAsc:
        return (a.level ?? 0).compareTo(b.level ?? 0);
      case WarSortType.respectDes:
        return b.respectGain!.compareTo(a.respectGain!);
      case WarSortType.respectAsc:
        return a.respectGain!.compareTo(b.respectGain!);
      case WarSortType.nameDes:
        return (b.name ?? '').toLowerCase().compareTo((a.name ?? '').toLowerCase());
      case WarSortType.nameAsc:
        return (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
      case WarSortType.lifeDes:
        return b.lifeCurrent!.compareTo(a.lifeCurrent!);
      case WarSortType.lifeAsc:
        return a.lifeCurrent!.compareTo(b.lifeCurrent!);
      case WarSortType.hospitalDes:
        // Apply "Okay at top" logic if enabled
        if (warSettings.okayTargetsAtTop) {
          bool aIsOkay = (a.status?.state ?? 'Okay') == 'Okay';
          bool bIsOkay = (b.status?.state ?? 'Okay') == 'Okay';
          if (aIsOkay && !bIsOkay) return -1;
          if (!aIsOkay && bIsOkay) return 1;

          if (aIsOkay && bIsOkay) {
            return compareMembers(a, b, warSettings.secondarySortForOkay);
          }
        }
        return b.hospitalSort!.compareTo(a.hospitalSort!);
      case WarSortType.hospitalAsc:
        bool aIsOkay = (a.status?.state ?? 'Okay') == 'Okay';
        bool bIsOkay = (b.status?.state ?? 'Okay') == 'Okay';

        if (warSettings.okayTargetsAtTop) {
          if (aIsOkay && !bIsOkay) return -1;
          if (!aIsOkay && bIsOkay) return 1;
        } else {
          if (aIsOkay && !bIsOkay) return 1;
          if (!aIsOkay && bIsOkay) return -1;
        }

        if (aIsOkay && bIsOkay) {
          return compareMembers(a, b, warSettings.secondarySortForOkay);
        }

        // If both are hospitalized, sort by time
        if (a.hospitalSort! > 0 && b.hospitalSort! > 0) {
          return a.hospitalSort!.compareTo(b.hospitalSort!);
        } else if (a.hospitalSort! > 0) {
          return -1;
        } else if (b.hospitalSort! > 0) {
          return 1;
        } else {
          return (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
        }
      case WarSortType.statsDes:
        final statsA = getMemberStatsForSorting(a);
        final statsB = getMemberStatsForSorting(b);

        // Group order: exact (0) -> estimated (1) -> unknown (2)
        if (statsA.group != statsB.group) {
          return statsA.group.compareTo(statsB.group);
        }

        final int statsComparison = statsB.value.compareTo(statsA.value);
        if (statsComparison != 0) return statsComparison;
        return (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
      case WarSortType.statsAsc:
        final statsA = getMemberStatsForSorting(a);
        final statsB = getMemberStatsForSorting(b);

        // Group order: exact (0) -> estimated (1) -> unknown (2)
        if (statsA.group != statsB.group) {
          return statsA.group.compareTo(statsB.group);
        }

        final int statsComparison = statsA.value.compareTo(statsB.value);
        if (statsComparison != 0) return statsComparison;
        return (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
      case WarSortType.smartScore:
        // Ensure ranges are calculated before sorting
        if (attributeRanges.isEmpty) {
          calculateAttributeRanges();
        }
        // We do NOT apply "Okay at top" logic here anymore, as requested.
        // Smart Score should be pure score sorting.
        int scoreComparison = calculateSmartScore(b).compareTo(calculateSmartScore(a)); // Descending score
        if (scoreComparison == 0) {
          return (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
        }
        return scoreComparison;
      case WarSortType.onlineDes:
        return b.lastAction!.timestamp!.compareTo(a.lastAction!.timestamp!);
      case WarSortType.onlineAsc:
        return a.lastAction!.timestamp!.compareTo(b.lastAction!.timestamp!);
      case WarSortType.colorDes:
        final aNote = notesProvider!.getNoteForPlayer(a.memberId.toString());
        final bNote = notesProvider.getNoteForPlayer(b.memberId.toString());
        final aColor = aNote?.color ?? '';
        final bColor = bNote?.color ?? '';
        return bColor.toLowerCase().compareTo(aColor.toLowerCase());
      case WarSortType.colorAsc:
        final aNote = notesProvider!.getNoteForPlayer(a.memberId.toString());
        final bNote = notesProvider.getNoteForPlayer(b.memberId.toString());
        final aColor = aNote?.color ?? '';
        final bColor = bNote?.color ?? '';
        return aColor.toLowerCase().compareTo(bColor.toLowerCase());
      case WarSortType.notesDes:
        final aNote = notesProvider!.getNoteForPlayer(a.memberId.toString());
        final bNote = notesProvider.getNoteForPlayer(b.memberId.toString());
        final aNoteText = aNote?.note ?? '';
        final bNoteText = bNote?.note ?? '';
        return bNoteText.toLowerCase().compareTo(aNoteText.toLowerCase());
      case WarSortType.notesAsc:
        final aNote = notesProvider!.getNoteForPlayer(a.memberId.toString());
        final bNote = notesProvider.getNoteForPlayer(b.memberId.toString());
        final aNoteText = aNote?.note ?? '';
        final bNoteText = bNote?.note ?? '';
        if (aNoteText.isEmpty && bNoteText.isNotEmpty) {
          return 1;
        } else if (aNoteText.isNotEmpty && bNoteText.isEmpty) {
          return -1;
        } else if (aNoteText.isEmpty && bNoteText.isEmpty) {
          return 0;
        } else {
          return aNoteText.toLowerCase().compareTo(bNoteText.toLowerCase());
        }
      case WarSortType.bounty:
        int aBounty = a.bountyAmount ?? 0;
        int bBounty = b.bountyAmount ?? 0;
        return bBounty.compareTo(aBounty);

      // Trip distance (time)
      case WarSortType.travelDistanceAsc:
        return getTripTime(a).compareTo(getTripTime(b));
      case WarSortType.travelDistanceDesc:
        return getTripTime(b).compareTo(getTripTime(a));
    }
  }

  void sortMembers(List<Member> members) {
    members.sort((a, b) => compareMembers(a, b, currentSort ?? WarSortType.levelDes));
  }

  void sortWarCards(List<WarCard> warCards) {
    warCards.sort((a, b) => compareMembers(a.memberModel, b.memberModel, currentSort ?? WarSortType.levelDes));
  }

  void shareStats(BuildContext context) async {
    try {
      StringBuffer statsBuffer = StringBuffer();
      final spyController = Get.find<SpiesController>();

      List<Member> pinnedMembers = [];
      List<Member> nonPinnedMembers = [];

      for (final faction in factions) {
        if (faction.hidden != null && faction.hidden! && !statsShareIncludeHiddenTargets) {
          // Do not share hidden factions unless explicitly requested
          continue;
        }

        for (final memberId in faction.members!.keys) {
          final member = faction.members![memberId];
          if (member != null) {
            if (member.hidden == true && !statsShareIncludeHiddenTargets) continue;

            if (member.pinned) {
              pinnedMembers.add(member);
            } else {
              nonPinnedMembers.add(member);
            }
          }
        }
      }

      sortMembers(pinnedMembers);
      sortMembers(nonPinnedMembers);
      List<Member> sortedMembers = [...pinnedMembers, ...nonPinnedMembers];

      for (final member in sortedMembers) {
        // Determine if the member has any stats (spied or estimated)
        bool hasExactStats = (member.statsStr != null && member.statsStr != -1) ||
            (member.statsSpd != null && member.statsSpd != -1) ||
            (member.statsDef != null && member.statsDef != -1) ||
            (member.statsDex != null && member.statsDex != -1) ||
            (member.statsExactTotal != null && member.statsExactTotal != -1);

        bool hasEstimatedStats = member.statsEstimated != null && member.statsEstimated!.isNotEmpty;

        // Skip member if no stats are available and we shouldn't show estimates
        if (!hasExactStats && (!statsShareShowEstimatesIfNoSpyAvailable || !hasEstimatedStats)) {
          if (!statsShareIncludeTargetsWithNoStatsAvailable) {
            continue; // Skip member if no stats and we don't include targets without stats
          } else {
            statsBuffer.writeln("${member.name} [${member.memberId}] - ${HtmlParser.fix(member.factionName)}");
            statsBuffer.writeln("Unknown stats!");
            statsBuffer.writeln("");
            continue;
          }
        }

        statsBuffer.writeln("${member.name} [${member.memberId}] - ${HtmlParser.fix(member.factionName)}");

        if (hasExactStats) {
          if (statsShareShowOnlyTotals) {
            statsBuffer.writeln(
                "Total: ${member.statsExactTotal != null && member.statsExactTotal != -1 ? formatBigNumbers(member.statsExactTotal!) : '?'}${member.statsExactUpdated != null && member.statsExactUpdated != -1 ? " (${spyController.statsOld(member.statsExactUpdated!)})" : ""}");
          } else {
            statsBuffer.writeln("* Spied stats *");
            statsBuffer.writeln(
                "Strength: ${member.statsStr != null && member.statsStr != -1 ? formatBigNumbers(member.statsStr!) : '?'}${member.statsStrUpdated != null && member.statsStrUpdated != -1 ? " (${spyController.statsOld(member.statsStrUpdated!)})" : ""}");
            statsBuffer.writeln(
                "Speed: ${member.statsSpd != null && member.statsSpd != -1 ? formatBigNumbers(member.statsSpd!) : '?'}${member.statsSpdUpdated != null && member.statsSpdUpdated != -1 ? " (${spyController.statsOld(member.statsSpdUpdated!)})" : ""}");
            statsBuffer.writeln(
                "Defense: ${member.statsDef != null && member.statsDef != -1 ? formatBigNumbers(member.statsDef!) : '?'}${member.statsDefUpdated != null && member.statsDefUpdated != -1 ? " (${spyController.statsOld(member.statsDefUpdated!)})" : ""}");
            statsBuffer.writeln(
                "Dexterity: ${member.statsDex != null && member.statsDex != -1 ? formatBigNumbers(member.statsDex!) : '?'}${member.statsDexUpdated != null && member.statsDexUpdated != -1 ? " (${spyController.statsOld(member.statsDexUpdated!)})" : ""}");
            statsBuffer.writeln(
                "Total: ${member.statsExactTotal != null && member.statsExactTotal != -1 ? formatBigNumbers(member.statsExactTotal!) : '?'}${member.statsExactUpdated != null && member.statsExactUpdated != -1 ? " (${spyController.statsOld(member.statsExactUpdated!)})" : ""}");
          }
        } else if (statsShareShowEstimatesIfNoSpyAvailable && hasEstimatedStats) {
          if (statsShareShowOnlyTotals) {
            statsBuffer.writeln("Estimated stats: ${member.statsEstimated}");
          } else {
            statsBuffer.writeln("* Estimated stats: ${member.statsEstimated} *");
            statsBuffer.writeln("Xanax taken: ${member.memberXanax ?? ''}");
            statsBuffer.writeln("Refills: ${member.memberRefill ?? ''}");
            statsBuffer.writeln("Enhancers used: ${member.memberEnhancement ?? ''}");
            statsBuffer.writeln("Energy drinks (Cans): ${member.memberCans ?? ''}");
            statsBuffer.writeln("SSL probability: ${calculateSSLProbability(member)}");
          }
        } else {
          statsBuffer.writeln("Unknown stats!");
        }

        statsBuffer.writeln("");
      }

      if (statsBuffer.isEmpty) {
        statsBuffer.writeln("No visible war targets with stats available.");
      }

      String stats = statsBuffer.toString();

      await SharePlus.instance.share(
        ShareParams(
          text: stats,
          sharePositionOrigin: Rect.fromLTWH(
            0,
            0,
            MediaQuery.sizeOf(context).width,
            MediaQuery.sizeOf(context).height / 2,
          ),
        ),
      );
    } catch (e, t) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at War Stats Share");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", t);
    }
  }

  Future<void> generateCSV(BuildContext context) async {
    final spyController = Get.find<SpiesController>();

    try {
      final List<List<String>> csvData = [];

      if (statsShareShowOnlyTotals) {
        csvData.add([
          'Name',
          'ID',
          'Faction Name',
          'Type of Stats',
          'Total',
          'Total Updated',
        ]);
      } else {
        csvData.add([
          'Name',
          'ID',
          'Faction Name',
          'Type of Stats',
          'Strength',
          'Strength Updated',
          'Speed',
          'Speed Updated',
          'Defense',
          'Defense Updated',
          'Dexterity',
          'Dexterity Updated',
          'Total',
          'Total Updated',
          'Xanax',
          'Refills',
          'Enhancers',
          'Energy Drinks',
          'SSL Probability',
        ]);
      }

      List<Member> pinnedMembers = [];
      List<Member> nonPinnedMembers = [];

      for (final faction in factions) {
        if (faction.hidden != null && faction.hidden! && !statsShareIncludeHiddenTargets) {
          // Do not share hidden factions unless explicitly requested
          continue;
        }

        for (final memberId in faction.members!.keys) {
          final member = faction.members![memberId];
          if (member != null) {
            if (member.hidden == true && !statsShareIncludeHiddenTargets) continue;

            if (member.pinned) {
              pinnedMembers.add(member);
            } else {
              nonPinnedMembers.add(member);
            }
          }
        }
      }

      sortMembers(pinnedMembers);
      sortMembers(nonPinnedMembers);
      List<Member> sortedMembers = [...pinnedMembers, ...nonPinnedMembers];

      for (final member in sortedMembers) {
        bool hasExactStats = (member.statsStr != null && member.statsStr != -1) ||
            (member.statsSpd != null && member.statsSpd != -1) ||
            (member.statsDef != null && member.statsDef != -1) ||
            (member.statsDex != null && member.statsDex != -1) ||
            (member.statsExactTotal != null && member.statsExactTotal != -1);

        bool hasEstimatedStats = member.statsEstimated != null && member.statsEstimated!.isNotEmpty;

        if (!hasExactStats && (!statsShareShowEstimatesIfNoSpyAvailable || !hasEstimatedStats)) {
          if (!statsShareIncludeTargetsWithNoStatsAvailable) {
            continue; // Skip member if no stats and we don't include targets without stats
          }
        }

        final List<String> rowData = [
          member.name ?? '',
          member.memberId?.toString() ?? '',
          HtmlParser.fix(member.factionName),
          '', // Type of Stats
          '', // Total
          '', // Total Updated
        ];

        if (hasExactStats) {
          rowData[3] = 'Spied';
          rowData[4] = member.statsExactTotal != null && member.statsExactTotal != -1
              ? formatBigNumbers(member.statsExactTotal!)
              : '?';
          rowData[5] =
              member.statsExactUpdated != null && member.statsExactUpdated != -1 && member.statsExactUpdated! > 0
                  ? spyController.statsOld(member.statsExactUpdated!)
                  : '';
        } else if (statsShareShowEstimatesIfNoSpyAvailable && hasEstimatedStats) {
          rowData[3] = 'Estimated';
          rowData[4] = member.statsEstimated!;
          rowData[5] = ''; // No Total Updated for estimated stats

          if (!statsShareShowOnlyTotals) {
            rowData.addAll([
              member.memberXanax?.toString() ?? '',
              member.memberRefill?.toString() ?? '',
              member.memberEnhancement?.toString() ?? '',
              member.memberCans?.toString() ?? '',
              calculateSSLProbability(member),
            ]);
          }
        } else {
          rowData[3] = 'Unknown';
          rowData[4] = '?';
        }

        csvData.add(rowData);
      }

      final String csvString = const ListToCsvConverter().convert(csvData);

      // Save the CSV content to a temporary file
      final directory = await getTemporaryDirectory();
      final String path = '${directory.path}/stats.csv';
      final File file = File(path);
      await file.writeAsString(csvString);

      // Create an XFile from the file path and share it
      final XFile xFile = XFile(path);

      final shareParams = ShareParams(
        text: 'War targets stats',
        files: [xFile],
      );
      await SharePlus.instance.share(shareParams);

      // Clean the temporary file
      await file.delete();
    } catch (e, t) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at War Stats CSV Generation");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", t);
    }
  }

  String calculateSSLProbability(Member member) {
    int xanaxAndEcstasy = (member.memberXanax ?? 0) + (member.memberEcstasy ?? 0);
    int lsd = member.memberLsd ?? 0;

    if (xanaxAndEcstasy > 150) {
      return "none";
    } else if (xanaxAndEcstasy <= 150 && lsd < 50) {
      return "low";
    } else if (xanaxAndEcstasy <= 150 && lsd >= 50 && lsd < 100) {
      return "medium";
    } else if (xanaxAndEcstasy <= 150 && lsd >= 100) {
      return "high";
    } else {
      return "unknown";
    }
  }

  int getTripTime(Member member) {
    String destination = "Torn";
    destination = countryCheck(state: member.status!.state, description: member.status!.description);

    switch (destination) {
      case 'Torn':
        return 0;
      case 'Japan':
        return 225;
      case 'Hawaii':
        return 134;
      case 'China':
        return 242;
      case 'Argentina':
        return 167;
      case 'UK':
        return 159;
      case 'Cayman':
        return 35;
      case 'South Africa':
        return 297;
      case 'Switzerland':
        return 175;
      case 'Mexico':
        return 26;
      case 'UAE':
        return 271;
      case 'Canada':
        return 41;
      default:
        return 9999;
    }
  }

  /// Check if a player ID is in any faction members list
  bool isPlayerInWarFactions(String playerId) {
    for (final faction in factions) {
      if (faction.members!.containsKey(playerId)) {
        return true;
      }
    }
    return false;
  }
}
