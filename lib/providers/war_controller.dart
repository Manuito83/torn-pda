import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:developer' as dev;
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
import 'package:torn_pda/models/chaining/war_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/utils/country_check.dart';
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

  // Filters
  List<String> activeFilters = [];
  int onlineFilter = 0;
  int okayRedFilter = 0;
  bool countryFilter = false;
  int abroadFilter = 0;
  bool showChainWidget = true;

  bool updating = false;
  bool _stopUpdate = false;

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

  bool _helaReviveActive = false;
  bool get helaReviveActive => _helaReviveActive;
  set helaReviveActive(bool value) {
    Prefs().setUseHelaRevive(value);
    _helaReviveActive = value;
  }

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

  bool toggleAddUserActive = false;

  String playerLocation = "";

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

    final apiResult = await Get.find<ApiCallerController>().getFaction(factionId: factionId);
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
          member.personalNoteColor = t.personalNoteColor;
          if (t.personalNote!.isNotEmpty) {
            member.personalNote = t.personalNote;
          }
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

    final String memberKey = member.memberId.toString();
    bool error = false;

    // Perform update
    try {
      final dynamic updatedTarget = await Get.find<ApiCallerController>().getOtherProfileExtended(playerId: memberKey);
      if (updatedTarget is OtherProfileModel) {
        member.name = updatedTarget.name;
        member.level = updatedTarget.level;
        member.position = updatedTarget.faction!.position;
        member.overrideEasyLife = true;
        member.lifeMaximum = updatedTarget.life!.maximum;
        member.lifeCurrent = updatedTarget.life!.current;
        member.lastAction!.relative = updatedTarget.lastAction!.relative;
        member.lastAction!.status = updatedTarget.lastAction!.status;
        member.status!.description = updatedTarget.status!.description;
        member.status!.state = updatedTarget.status!.state;
        member.status!.until = updatedTarget.status!.until;
        member.status!.color = updatedTarget.status!.color;
        member.bounty = updatedTarget.basicicons?.icon13 ?? "";

        // Erase previous bounties and calculate new ones
        _calculateMemberBounty(updatedTarget, member);

        member.lastUpdated = DateTime.now();
        if (allAttacksSuccess is AttackModel) {
          _getRespectFF(allAttacksSuccess, member, oldRespect: member.respectGain, oldFF: member.fairFight);
        }
        member.hospitalSort = membersSortHospitalTime(member);

        _assignSpiedStats(member);

        member.statsEstimated = StatsCalculator.calculateStats(
          criminalRecordTotal: updatedTarget.criminalrecord!.total,
          level: updatedTarget.level,
          networth: updatedTarget.personalstats!.networth,
          rank: updatedTarget.rank,
        );

        member.statsComparisonSuccess = false;
        if (ownStatsSuccess is OwnPersonalStatsModel) {
          member.statsComparisonSuccess = true;
          member.memberXanax = updatedTarget.personalstats!.xantaken;
          member.myXanax = ownStatsSuccess.personalstats!.xantaken;
          member.memberRefill = updatedTarget.personalstats!.refills;
          member.myRefill = ownStatsSuccess.personalstats!.refills;
          member.memberEnhancement = updatedTarget.personalstats!.statenhancersused;
          member.memberCans = updatedTarget.personalstats!.energydrinkused;
          member.myCans = ownStatsSuccess.personalstats!.energydrinkused;
          member.myEnhancement = ownStatsSuccess.personalstats!.statenhancersused;
          member.memberEcstasy = updatedTarget.personalstats!.exttaken;
          member.memberLsd = updatedTarget.personalstats!.lsdtaken;
        }

        // Even if we assign both exact (if available) and estimated, we only pass estimated to startSort
        // if exact does not exist (-1)
        if (member.statsExactTotal == -1) {
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
      } else {
        error = true;
      }
    } catch (e) {
      error = true;
    }

    // End animation and update
    member.isUpdating = false;
    update();

    // Avoid hundred of updates when performing a full faction update
    if (fromCard) {
      assessPendingNotifications();
    }

    // Return result and save if successful
    if (!error) {
      _updateResultAnimation(member: member, success: true);
      savePreferences();
      return true;
    }
    _updateResultAnimation(member: member, success: false);
    return false;
  }

  Future<List<int>> updateAllMembersFull() async {
    await _integrityCheck(force: true);

    // Get all attacks and own stats from the API
    final dynamic allAttacksSuccess = await getAllAttacks();
    final dynamic ownStatsSuccess = await getOwnStats();
    int numberUpdated = 0;

    updating = true;
    update();

    // Copy lists so that alterations (hiding) do not cause error
    // which might happen even if we stop the update
    List<WarCardDetails> thisCards = List.from(orderedCardsDetails);
    List<FactionModel> thisFactions = List.from(factions);

    int callsPerBatch = 0;
    int delayBetweenCalls = 0;

    // If there are less than or equal to 75 members, set the batch size and delay accordingly
    if (thisCards.length <= 75) {
      callsPerBatch = thisCards.length;
      // No delay for less than 75 members
      delayBetweenCalls = 0;
    } else {
      // Limit the calls to 75 per minute
      callsPerBatch = 75;
      // Calculate the required delay between calls
      delayBetweenCalls = (60 / callsPerBatch).floor();
    }

    // If there are less than 75 members, make API calls concurrently
    if (thisCards.length <= 75) {
      // Create a list to store the update tasks
      List<Future<bool>> updateTasks = [];

      // Loop through each card in thisCards
      for (final WarCardDetails card in thisCards) {
        // Loop through each faction in thisFactions
        for (final FactionModel f in thisFactions) {
          // If the member is found in the faction, add the update task to the list
          if (f.members!.containsKey(card.memberId.toString())) {
            updateTasks.add(
              updateSingleMemberFull(
                f.members![card.memberId.toString()]!,
                allAttacks: allAttacksSuccess,
                ownStats: ownStatsSuccess,
              ),
            );
            break;
          }
        }
      }

      // Execute all update tasks concurrently and store the results
      List<bool> results = await Future.wait(updateTasks);
      // Count the number of successful updates
      numberUpdated = results.where((result) => result).length;
    } else {
      // If there are more than 60 members, use the rate limiting logic
      for (int i = 0; i < thisCards.length; i++) {
        final WarCardDetails card = thisCards[i];
        for (final FactionModel f in thisFactions) {
          // If the update process is stopped, reset the state and return the results
          if (_stopUpdate) {
            _stopUpdate = false;
            updating = false;
            update();
            return [thisCards.length, numberUpdated];
          }

          // If the member is found in the faction, update the member
          if (f.members!.containsKey(card.memberId.toString())) {
            final bool result = await updateSingleMemberFull(
              f.members![card.memberId.toString()]!,
              allAttacks: allAttacksSuccess,
              ownStats: ownStatsSuccess,
            );
            // If the update is successful, increment the numberUpdated counter
            if (result) {
              numberUpdated++;
            }
            break;
          }
          // If the member is not found in the faction, continue searching
          continue;
        }

        // Add a delay between calls if required
        if (callsPerBatch > 0 && (i + 1) % callsPerBatch == 0) {
          await Future.delayed(Duration(seconds: delayBetweenCalls));
        }
      }
    }

    _stopUpdate = false;
    updating = false;
    update();

    return [thisCards.length, numberUpdated];
  }

  Future<int> updateAllMembersEasy({bool forceIntegrityCheck = true}) async {
    final dynamic allAttacksSuccess = await getAllAttacks();

    stopUpdate();

    await _integrityCheck(force: forceIntegrityCheck);

    int numberUpdated = 0;

    // Get player's current location
    final apiPlayer = await Get.find<ApiCallerController>().getOwnProfileBasic();
    if (apiPlayer is ApiError) {
      return -1;
    }
    final profile = apiPlayer as OwnProfileBasic;
    playerLocation = countryCheck(
      state: profile.status!.state,
      description: profile.status!.description,
    );

    for (final FactionModel f in factions) {
      final apiResult = await Get.find<ApiCallerController>().getFaction(factionId: f.id.toString());
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
          respect = fairFight! * 0.25 * (math.log(member.level!) + 1);
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

  void setMemberNote(Member? changedMember, String note, String? color) {
    // We are not updating the target directly, but instead looping for the correct one because
    // after an attack the targets get updated several times: if the user wants to change the note
    // right after the attack, the good target might have been replaced and the note does not get
    // updated. Therefore, we just loop whenever the user submits the new text.
    for (final f in factions) {
      if (f.members!.keys.contains(changedMember!.memberId.toString())) {
        f.members![changedMember.memberId.toString()]!.personalNote = note;
        f.members![changedMember.memberId.toString()]!.personalNoteColor = color;
        savePreferences();
        update();
        break;
      }
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
    final result = await Get.find<ApiCallerController>().getAttacks();
    if (result is AttackModel) {
      return result;
    }
    return false;
  }

  dynamic getOwnStats() async {
    final result = await Get.find<ApiCallerController>().getOwnPersonalStats();
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
    helaReviveActive = await Prefs().getUseHelaRevive();
    wtfReviveActive = await Prefs().getUseWtfRevive();
    midnightXReviveActive = await Prefs().getUseMidnightXRevive();

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
    }

    _lastIntegrityCheck = DateTime.fromMillisecondsSinceEpoch(await Prefs().getWarIntegrityCheckTime());

    if (needsIntegrityCheck) {
      _integrityCheck();
    }

    initialised = true;
    update();
  }

  void savePreferences() {
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

    // Save sorting
    late String sortToSave;
    switch (currentSort ??= WarSortType.nameAsc) {
      case WarSortType.levelDes:
        sortToSave = 'levelDes';
      case WarSortType.levelAsc:
        sortToSave = 'levelAsc';
      case WarSortType.respectDes:
        sortToSave = 'respectDes';
      case WarSortType.respectAsc:
        sortToSave = 'respectAsc';
      case WarSortType.nameDes:
        sortToSave = 'nameDes';
      case WarSortType.nameAsc:
        sortToSave = 'nameAsc';
      case WarSortType.lifeDes:
        sortToSave = 'lifeDes';
      case WarSortType.lifeAsc:
        sortToSave = 'lifeAsc';
      case WarSortType.hospitalDes:
        sortToSave = 'hospitalDes';
      case WarSortType.hospitalAsc:
        sortToSave = 'hospitalAsc';
      case WarSortType.statsDes:
        sortToSave = 'statsDes';
      case WarSortType.statsAsc:
        sortToSave = 'statsAsc';
      case WarSortType.onlineDes:
        sortToSave = 'onlineDes';
      case WarSortType.onlineAsc:
        sortToSave = 'onlineAsc';
      case WarSortType.colorDes:
        sortToSave = 'colorDes';
      case WarSortType.colorAsc:
        sortToSave = 'colorAsc';
      case WarSortType.notesDes:
        sortToSave = 'notesDes';
      case WarSortType.notesAsc:
        sortToSave = 'notesAsc';
      case WarSortType.bounty:
        sortToSave = 'bounty';
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

  Future _integrityCheck({bool force = false}) async {
    if (!force && DateTime.now().difference(_lastIntegrityCheck).inMinutes < 10) {
      return;
    }

    for (final FactionModel faction in factions) {
      final apiResult = await Get.find<ApiCallerController>().getFaction(factionId: faction.id.toString());
      if (apiResult is ApiError || (apiResult is FactionModel && apiResult.id == null)) {
        return;
      }
      final FactionModel apiImport = apiResult as FactionModel;

      bool changes = false;

      // Get a copy of the in-app faction members so that we can iterate safety and add/delete members
      Map<String, Member> oldFactionMembers = Map.from(faction.members!);

      // Remove members that do not longer belong to the faction
      oldFactionMembers.removeWhere((memberId, memberDetails) {
        if (!apiImport.members!.containsKey(memberId)) {
          dev.log("${memberDetails.name} left faction!");
          changes = true;
          return true;
        }
        return false;
      });

      // If some members have left, update [faction.members] from the changes in [oldFactionMembers]
      if (changes) {
        faction.members = Map.from(oldFactionMembers);
      }

      // Add new members that were not here before. We add them directly in [faction.members] so there is no need
      // to track changes or use [oldFactionMembers] again here
      apiImport.members!.forEach((key, value) {
        if (!oldFactionMembers.containsKey(key)) {
          faction.members![key] = apiImport.members![key];
          updateSingleMemberFull(faction.members![key]!);
        }
      });
    }

    Prefs().setWarIntegrityCheckTime(DateTime.now().millisecondsSinceEpoch);
    savePreferences();
    assessPendingNotifications();
    update();
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

    bool spyFound = false;

    // Delete spy information if we don't allow mixed spies sources
    if ((!spyController.allowMixedSpiesSources &&
            member.spySource != SpiesSource.yata &&
            spyController.spiesSource == SpiesSource.yata) ||
        (!spyController.allowMixedSpiesSources &&
            member.spySource != SpiesSource.tornStats &&
            spyController.spiesSource == SpiesSource.tornStats)) {
      _deleteSpiedStats(member);
    }

    // Find the spy based in the current selected spy source
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

  _deleteSpiedStats(Member member) {
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

  void _calculateMemberBounty(OtherProfileModel updatedTarget, Member member) {
    if (updatedTarget.basicicons?.icon13 != null) {
      // API example text: Bounty - On this person's head for $200,000 : "Optional reason"
      RegExp amountRegex = RegExp(r"\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?");
      Match? match = amountRegex.firstMatch(updatedTarget.basicicons!.icon13!);
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
      FirebaseCrashlytics.instance.log("PDA Crash at Assess Pending Notifications");
      FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
    }
  }

  // Sorting function for MemberModel lists to be used in shareStats
  int compareMembers(Member a, Member b, WarSortType sortType) {
    switch (sortType) {
      case WarSortType.levelDes:
        return b.level!.compareTo(a.level!);
      case WarSortType.levelAsc:
        return a.level!.compareTo(b.level!);
      case WarSortType.respectDes:
        return b.respectGain!.compareTo(a.respectGain!);
      case WarSortType.respectAsc:
        return a.respectGain!.compareTo(b.respectGain!);
      case WarSortType.nameDes:
        return b.name!.toLowerCase().compareTo(a.name!.toLowerCase());
      case WarSortType.nameAsc:
        return a.name!.toLowerCase().compareTo(b.name!.toLowerCase());
      case WarSortType.lifeDes:
        return b.lifeCurrent!.compareTo(a.lifeCurrent!);
      case WarSortType.lifeAsc:
        return a.lifeCurrent!.compareTo(b.lifeCurrent!);
      case WarSortType.hospitalDes:
        return b.hospitalSort!.compareTo(a.hospitalSort!);
      case WarSortType.hospitalAsc:
        if (a.hospitalSort! > 0 && b.hospitalSort! > 0) {
          return a.hospitalSort!.compareTo(b.hospitalSort!);
        } else if (a.hospitalSort! > 0) {
          return -1;
        } else if (b.hospitalSort! > 0) {
          return 1;
        } else {
          return a.name!.toLowerCase().compareTo(b.name!.toLowerCase());
        }
      case WarSortType.statsDes:
        return b.statsSort!.compareTo(a.statsSort!);
      case WarSortType.statsAsc:
        return a.statsSort!.compareTo(b.statsSort!);
      case WarSortType.onlineDes:
        return b.lastAction!.timestamp!.compareTo(a.lastAction!.timestamp!);
      case WarSortType.onlineAsc:
        return a.lastAction!.timestamp!.compareTo(b.lastAction!.timestamp!);
      case WarSortType.colorDes:
        return b.personalNoteColor!.toLowerCase().compareTo(a.personalNoteColor!.toLowerCase());
      case WarSortType.colorAsc:
        return a.personalNoteColor!.toLowerCase().compareTo(b.personalNoteColor!.toLowerCase());
      case WarSortType.notesDes:
        return b.personalNote!.toLowerCase().compareTo(a.personalNote!.toLowerCase());
      case WarSortType.notesAsc:
        if (a.personalNote!.isEmpty && b.personalNote!.isNotEmpty) {
          return 1;
        } else if (a.personalNote!.isNotEmpty && b.personalNote!.isEmpty) {
          return -1;
        } else if (a.personalNote!.isEmpty && b.personalNote!.isEmpty) {
          return 0;
        } else {
          return a.personalNote!.toLowerCase().compareTo(b.personalNote!.toLowerCase());
        }
      case WarSortType.bounty:
        int aBounty = a.bountyAmount ?? 0;
        int bBounty = b.bountyAmount ?? 0;
        return bBounty.compareTo(aBounty);
      default:
        return a.name!.toLowerCase().compareTo(b.name!.toLowerCase());
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
        for (final memberId in faction.members!.keys) {
          final member = faction.members![memberId];
          if (member != null && member.hidden != true) {
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
        statsBuffer.writeln("${member.name} [${member.memberId}] - ${member.factionName}");

        // Check if there are exact stats available
        bool hasExactStats = (member.statsStr != null && member.statsStr != -1) ||
            (member.statsSpd != null && member.statsSpd != -1) ||
            (member.statsDef != null && member.statsDef != -1) ||
            (member.statsDex != null && member.statsDex != -1) ||
            (member.statsExactTotal != null && member.statsExactTotal != -1);

        if (hasExactStats) {
          statsBuffer.writeln("* Spied stats *");

          // Strength
          statsBuffer.writeln(
              "Strength: ${member.statsStr != null && member.statsStr != -1 ? formatBigNumbers(member.statsStr!) : '?'}${member.statsStrUpdated != null && member.statsStrUpdated != -1 ? " (${spyController.statsOld(member.statsStrUpdated!)})" : ""}");

          // Speed
          statsBuffer.writeln(
              "Speed: ${member.statsSpd != null && member.statsSpd != -1 ? formatBigNumbers(member.statsSpd!) : '?'}${member.statsSpdUpdated != null && member.statsSpdUpdated != -1 ? " (${spyController.statsOld(member.statsSpdUpdated!)})" : ""}");

          // Defense
          statsBuffer.writeln(
              "Defense: ${member.statsDef != null && member.statsDef != -1 ? formatBigNumbers(member.statsDef!) : '?'}${member.statsDefUpdated != null && member.statsDefUpdated != -1 ? " (${spyController.statsOld(member.statsDefUpdated!)})" : ""}");

          // Dexterity
          statsBuffer.writeln(
              "Dexterity: ${member.statsDex != null && member.statsDex != -1 ? formatBigNumbers(member.statsDex!) : '?'}${member.statsDexUpdated != null && member.statsDexUpdated != -1 ? " (${spyController.statsOld(member.statsDexUpdated!)})" : ""}");

          // Total
          statsBuffer.writeln(
              "Total: ${member.statsExactTotal != null && member.statsExactTotal != -1 ? formatBigNumbers(member.statsExactTotal!) : '?'}${member.statsExactUpdated != null && member.statsExactUpdated != -1 ? " (${spyController.statsOld(member.statsExactUpdated!)})" : ""}");
        } else if (member.statsEstimated != null && member.statsEstimated!.isNotEmpty) {
          // Show estimated stats if no exact stats are available and estimated stats are not empty
          statsBuffer.writeln("* Estimated stats: ${member.statsEstimated} *");

          // Additional estimated details
          statsBuffer.writeln("Xanax taken: ${member.memberXanax}");
          ("Refills: ${member.memberRefill}");
          ("Enhancers used: ${member.memberEnhancement}");
          ("Energy drinks (Cans): ${member.memberCans}");

          // Calculate SSL probability
          statsBuffer.writeln("SSL probability: ${calculateSSLProbability(member)}");
        } else {
          statsBuffer.writeln("Unknown stats!");
        }

        statsBuffer.writeln("");
      }

      if (statsBuffer.isEmpty) {
        statsBuffer.writeln("No visible war targets with stats available.");
      }

      String stats = statsBuffer.toString();

      await Share.share(
        stats,
        sharePositionOrigin: Rect.fromLTWH(
          0,
          0,
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height / 2,
        ),
      );
    } catch (e, t) {
      FirebaseCrashlytics.instance.log("PDA Crash at War Stats Share");
      FirebaseCrashlytics.instance.recordError("PDA Error: $e", t);
    }
  }

  Future<void> generateCSV(BuildContext context) async {
    final spyController = Get.find<SpiesController>();

    try {
      final List<List<String>> csvData = [];

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

      List<Member> pinnedMembers = [];
      List<Member> nonPinnedMembers = [];

      for (final faction in factions) {
        for (final memberId in faction.members!.keys) {
          final member = faction.members![memberId];
          if (member != null && member.hidden != true) {
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
        final List<String> rowData = [
          member.name ?? '',
          member.memberId?.toString() ?? '',
          member.factionName ?? '',
          '', // Type of Stats
          '', // Strength
          '', // Strength Updated
          '', // Speed
          '', // Speed Updated
          '', // Defense
          '', // Defense Updated
          '', // Dexterity
          '', // Dexterity Updated
          '', // Total
          '', // Total Updated
          '', // Xanax
          '', // Refills
          '', // Enhancers
          '', // Energy Drinks
          '', // SSL Probability
        ];

        bool hasExactStats = (member.statsStr != null && member.statsStr != -1) ||
            (member.statsSpd != null && member.statsSpd != -1) ||
            (member.statsDef != null && member.statsDef != -1) ||
            (member.statsDex != null && member.statsDex != -1) ||
            (member.statsExactTotal != null && member.statsExactTotal != -1);

        if (hasExactStats) {
          rowData[3] = 'Spied';
          rowData[4] = member.statsStr != null && member.statsStr != -1 ? formatBigNumbers(member.statsStr!) : '';
          rowData[5] = member.statsStrUpdated != null && member.statsStrUpdated != -1
              ? spyController.statsOld(member.statsStrUpdated!)
              : '';
          rowData[6] = member.statsSpd != null && member.statsSpd != -1 ? formatBigNumbers(member.statsSpd!) : '';
          rowData[7] = member.statsSpdUpdated != null && member.statsSpdUpdated != -1
              ? spyController.statsOld(member.statsSpdUpdated!)
              : '';
          rowData[8] = member.statsDef != null && member.statsDef != -1 ? formatBigNumbers(member.statsDef!) : '';
          rowData[9] = member.statsDefUpdated != null && member.statsDefUpdated != -1
              ? spyController.statsOld(member.statsDefUpdated!)
              : '';
          rowData[10] = member.statsDex != null && member.statsDex != -1 ? formatBigNumbers(member.statsDex!) : '';
          rowData[11] = member.statsDexUpdated != null && member.statsDexUpdated != -1
              ? spyController.statsOld(member.statsDexUpdated!)
              : '';
          rowData[12] = member.statsExactTotal != null && member.statsExactTotal != -1
              ? formatBigNumbers(member.statsExactTotal!)
              : '';
          rowData[13] =
              member.statsExactUpdated != null && member.statsExactUpdated != -1 && member.statsExactUpdated! > 0
                  ? spyController.statsOld(member.statsExactUpdated!)
                  : '';
        } else if (member.statsEstimated != null && member.statsEstimated!.isNotEmpty) {
          rowData[3] = 'Estimated';
          rowData[4] = member.statsEstimated!;
          rowData[14] = member.memberXanax?.toString() ?? ''; // Xanax
          rowData[15] = member.memberRefill?.toString() ?? ''; // Refills
          rowData[16] = member.memberEnhancement?.toString() ?? ''; // Enhancers
          rowData[17] = member.memberCans?.toString() ?? ''; // Energy Drinks
          rowData[18] = calculateSSLProbability(member);
        } else {
          rowData[3] = 'Unknown';
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

      await Share.shareXFiles([xFile], text: 'War targets stats');

      // Clean the temporary file
      await file.delete();
    } catch (e, t) {
      FirebaseCrashlytics.instance.log("PDA Crash at War Stats CSV Generation");
      FirebaseCrashlytics.instance.recordError("PDA Error: $e", t);
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
}
