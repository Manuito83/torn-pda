import 'dart:math';
import 'dart:developer' as dev;
import 'package:get/get.dart';
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
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/stats_calculator.dart';

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
  bool okayFilter = false;
  bool countryFilter = false;
  bool travelingFilter = false;
  bool showChainWidget = true;

  bool updating = false;
  bool _stopUpdate = false;

  bool showCaseStart = false;

  bool addFromUserId = false;

  late DateTime _lastIntegrityCheck;

  bool nukeReviveActive = false;
  bool uhcReviveActive = false;
  bool helaReviveActive = false;
  bool wtfReviveActive = false;

  bool toggleAddUserActive = false;

  String playerLocation = "";

  bool initialised = false;
  bool _initWithIntegrity = true;
  WarController({bool initWithIntegrity = true}) {
    _initWithIntegrity = initWithIntegrity;
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
          member.lifeSort = _getLifeSort(member);
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
  Future<bool> updateSingleMemberFull(Member member, {dynamic allAttacks, dynamic spies, dynamic ownStats}) async {
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

        member.lastUpdated = DateTime.now();
        if (allAttacksSuccess is AttackModel) {
          _getRespectFF(allAttacksSuccess, member, oldRespect: member.respectGain, oldFF: member.fairFight);
        }
        member.lifeSort = _getLifeSort(member);

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

  Future<int> updateAllMembersEasy() async {
    final dynamic allAttacksSuccess = await getAllAttacks();

    stopUpdate();

    await _integrityCheck(force: true);

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

          _assignSpiedStats(f.members![apiMemberId]);

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
          respect = fairFight! * 0.25 * (log(member.level!) + 1);
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

  void setOkayFilterActive(bool value) {
    okayFilter = value;
    if (!value) {
      activeFilters.removeWhere((element) => element == "okay");
    } else {
      activeFilters.add("okay");
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

  void setTravelingFilterActive(bool value) {
    travelingFilter = value;
    if (!value) {
      activeFilters.removeWhere((element) => element == "hide traveling");
    } else {
      activeFilters.add("hide traveling");
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
    okayFilter = await Prefs().getOkayFilterInWars();
    countryFilter = await Prefs().getCountryFilterInWars();
    travelingFilter = await Prefs().getTravelingFilterInWars();
    showChainWidget = await Prefs().getShowChainWidgetInWars();

    nukeReviveActive = await Prefs().getUseNukeRevive();
    uhcReviveActive = await Prefs().getUseUhcRevive();
    helaReviveActive = await Prefs().getUseHelaRevive();
    wtfReviveActive = await Prefs().getUseWtfRevive();

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
    Prefs().setOkayFilterInWars(okayFilter);
    Prefs().setCountryFilterInWars(countryFilter);
    Prefs().setTravelingFilterInWars(travelingFilter);
    Prefs().setShowChainWidgetInWars(showChainWidget);

    // Save sorting
    late String sortToSave;
    switch (currentSort!) {
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

      // Add new members that were not here before
      apiImport.members!.forEach((key, value) {
        if (!oldFactionMembers.containsKey(key)) {
          faction.members![key] = apiImport.members![key];
          updateSingleMemberFull(faction.members![key]!);
          changes = true;
        }
      });

      if (changes) {
        faction.members = Map.from(oldFactionMembers);
      }
    }

    Prefs().setWarIntegrityCheckTime(DateTime.now().millisecondsSinceEpoch);
    savePreferences();
    update();
  }

  int? _getLifeSort(Member member) {
    if (member.status!.state != "Hospital") {
      return member.lifeCurrent;
    } else {
      return -(member.status!.until! - DateTime.now().millisecondsSinceEpoch / 1000).round();
    }
  }

  void _assignSpiedStats(Member? member) {
    final SpiesController spy = Get.find<SpiesController>();

    if (spy.spiesSource == SpiesSource.yata) {
      for (final YataSpyModel spy in spy.yataSpies) {
        if (spy.targetName == member!.name) {
          member.spiesSource = "yata";
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
          if (spy.strength != 1) known += spy.strength!;
          if (spy.speed != 1) known += spy.speed!;
          if (spy.defense != 1) known += spy.defense!;
          if (spy.dexterity != 1) known += spy.dexterity!;
          member.statsExactTotalKnown = known;
          break;
        }
      }
    } else {
      for (final SpyElement spy in spy.tornStatsSpies.spies) {
        if (spy.playerName == member!.name) {
          member.spiesSource = "tornstats";
          member.statsExactTotal = member.statsSort = spy.total;
          member.statsExactUpdated = spy.timestamp;
          member.statsStr = spy.strength;
          member.statsSpd = spy.speed;
          member.statsDef = spy.defense;
          member.statsDex = spy.dexterity;
          int known = 0;
          if (spy.strength != 1) known += spy.strength!;
          if (spy.speed != 1) known += spy.speed!;
          if (spy.defense != 1) known += spy.defense!;
          if (spy.dexterity != 1) known += spy.dexterity!;
          member.statsExactTotalKnown = known;
          break;
        }
      }
    }
  }
}
