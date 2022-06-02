import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/chaining/war_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/models/chaining/tornstats/tornstats_spies_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/utils/stats_calculator.dart';
import 'package:torn_pda/widgets/other/profile_check.dart';

class WarCardDetails {
  int cardPosition;
  int memberId;
  String name;
  String personalNote;
  String personalNoteColor;
}

class WarController extends GetxController {
  UserController _u = Get.put(UserController());

  List<FactionModel> factions = <FactionModel>[];
  List<WarCardDetails> orderedCardsDetails = <WarCardDetails>[];
  WarSortType currentSort;

  // Filters
  List<String> activeFilters = [];
  int onlineFilter = 0;
  bool okayFilter = false;
  bool countryFilter = false;
  bool showChainWidget = true;

  bool updating = false;
  bool _stopUpdate = false;

  bool showCaseStart = false;

  bool addFromUserId = false;

  DateTime _lastIntegrityCheck;

  SpiesSource _spiesSource = SpiesSource.yata;

  DateTime _lastYataSpiesDownload;
  List<YataSpyModel> _yataSpies = <YataSpyModel>[];

  DateTime _lastTornStatsSpiesDownload;
  TornStatsSpiesModel _tornStatsSpies = TornStatsSpiesModel();

  bool nukeReviveActive = false;
  bool uhcReviveActive = false;

  List<String> lastAttackedTargets = [];

  bool toggleAddUserActive = false;

  String playerLocation = "";

  @override
  void onInit() {
    super.onInit();
    initialise();
  }

  Future<String> addFaction(String factionId, List<TargetModel> targets) async {
    stopUpdate();

    dynamic allAttacksSuccess = await getAllAttacks();

    // Return custom error code if faction already exists
    for (FactionModel faction in factions) {
      if (faction.id.toString() == factionId) {
        return "error_existing";
      }
    }

    final apiResult = await TornApiCaller().getFaction(factionId: factionId);
    if (apiResult is ApiError || (apiResult is FactionModel && apiResult.id == null)) {
      return "";
    }

    final faction = apiResult as FactionModel;
    factions.add(faction);

    dynamic allSpiesSuccess;
    if (_spiesSource == SpiesSource.yata) {
      allSpiesSuccess = await _getYataSpies(_u.apiKey);
    } else {
      allSpiesSuccess = await _getTornStatsSpies(_u.apiKey);
    }

    // Add extra member information
    DateTime addedTime = DateTime.now();
    faction.members.forEach((memberId, member) {
      // Last updated time
      member.memberId = int.parse(memberId);
      member.lastUpdated = addedTime;
      for (var t in targets) {
        // Try to match information with pre-existing targets
        if (t.playerId.toString() == memberId) {
          member.personalNoteColor = t.personalNoteColor;
          if (t.personalNote.isNotEmpty) {
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

      _assignSpiedStats(allSpiesSuccess, member);

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

  void removeFaction(int removeId) {
    stopUpdate();
    // Remove also if it was filtered
    factions.removeWhere((f) => f.id == removeId);
    savePreferences();
    update();
  }

  void filterFaction(int factionId) {
    stopUpdate();
    FactionModel faction = factions.where((f) => f.id == factionId).first;
    faction.hidden = !faction.hidden;
    savePreferences();
    update();
  }

  /// [allAttacks] is to be provided when updating several members at the same time, so that it does not have
  /// to call the API twice every time
  Future<bool> updateSingleMemberFull(Member member, {dynamic allAttacks, dynamic spies, dynamic ownStats}) async {
    dynamic allAttacksSuccess = allAttacks;
    if (allAttacksSuccess == null) {
      allAttacksSuccess = await getAllAttacks();
    }

    dynamic ownStatsSuccess = ownStats;
    if (ownStatsSuccess == null) {
      ownStatsSuccess = await getOwnStats();
    }

    member.isUpdating = true;
    update();

    dynamic allSpiesSuccess;
    if (_spiesSource == SpiesSource.yata) {
      allSpiesSuccess = await _getYataSpies(_u.apiKey);
    } else {
      allSpiesSuccess = await _getTornStatsSpies(_u.apiKey);
    }

    String memberKey = member.memberId.toString();
    bool error = false;

    // Perform update
    try {
      dynamic updatedTarget = await TornApiCaller().getOtherProfile(playerId: memberKey);
      if (updatedTarget is OtherProfileModel) {
        member.overrideEasyLife = true;
        member.lifeMaximum = updatedTarget.life.maximum;
        member.lifeCurrent = updatedTarget.life.current;
        member.lastAction.relative = updatedTarget.lastAction.relative;
        member.lastAction.status = updatedTarget.lastAction.status;
        member.status.description = updatedTarget.status.description;
        member.status.state = updatedTarget.status.state;
        member.status.until = updatedTarget.status.until;
        member.status.color = updatedTarget.status.color;
        member.lastUpdated = DateTime.now();
        if (allAttacksSuccess is AttackModel) {
          _getRespectFF(allAttacksSuccess, member, oldRespect: member.respectGain, oldFF: member.fairFight);
        }
        member.lifeSort = _getLifeSort(member);

        _assignSpiedStats(allSpiesSuccess, member);

        member.statsEstimated = StatsCalculator.calculateStats(
          criminalRecordTotal: updatedTarget.criminalrecord.total,
          level: updatedTarget.level,
          networth: updatedTarget.personalstats.networth,
          rank: updatedTarget.rank,
        );

        member.statsComparisonSuccess = false;
        if (ownStatsSuccess is OwnPersonalStatsModel) {
          member.statsComparisonSuccess = true;
          member.memberXanax = updatedTarget.personalstats.xantaken;
          member.myXanax = ownStatsSuccess.personalstats.xantaken;
          member.memberRefill = updatedTarget.personalstats.refills;
          member.myRefill = ownStatsSuccess.personalstats.refills;
          member.memberEnhancement = updatedTarget.personalstats.statenhancersused;
          member.memberCans = updatedTarget.personalstats.energydrinkused;
          member.myCans = ownStatsSuccess.personalstats.energydrinkused;
          member.myEnhancement = ownStatsSuccess.personalstats.statenhancersused;
          member.memberEcstasy = updatedTarget.personalstats.exttaken;
          member.memberLsd = updatedTarget.personalstats.lsdtaken;
        }

        // Even if we assign both exact (if available) and estimated, we only pass estimated to startSort
        // if exact does not exist (-1)
        if (member.statsExactTotal == -1) {
          switch (member.statsEstimated) {
            case "< 2k":
              member.statsSort = 2000;
              break;
            case "2k - 25k":
              member.statsSort = 25000;
              break;
            case "20k - 250k":
              member.statsSort = 250000;
              break;
            case "200k - 2.5M":
              member.statsSort = 2500000;
              break;
            case "2M - 25M":
              member.statsSort = 25000000;
              break;
            case "20M - 250M":
              member.statsSort = 200000000;
              break;
            case "> 200M":
              member.statsSort = 250000000;
              break;
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

    dynamic allAttacksSuccess = await getAllAttacks();
    dynamic ownStatsSuccess = await getOwnStats();
    int numberUpdated = 0;

    updating = true;
    update();

    // Copy lists so that alterations (hiding) do not cause error
    // which might happen even if we stop the update
    List<WarCardDetails> thisCards = List.from(orderedCardsDetails);
    List<FactionModel> thisFactions = List.from(factions);

    for (WarCardDetails card in thisCards) {
      for (FactionModel f in thisFactions) {
        if (_stopUpdate) {
          _stopUpdate = false;
          updating = false;
          update();
          return [thisCards.length, numberUpdated];
        }

        if (f.members.containsKey(card.memberId.toString())) {
          bool memberSuccess = await updateSingleMemberFull(
            f.members[card.memberId.toString()],
            allAttacks: allAttacksSuccess,
            ownStats: ownStatsSuccess,
          );
          if (memberSuccess) {
            numberUpdated++;
          }
          if (orderedCardsDetails.length > 60) {
            await Future.delayed(Duration(seconds: 1));
          }
          break;
        }
        continue;
      }
    }

    _stopUpdate = false;
    updating = false;
    update();

    return [thisCards.length, numberUpdated];
  }

  Future<int> updateAllMembersEasy() async {
    dynamic allAttacksSuccess = await getAllAttacks();

    stopUpdate();

    await _integrityCheck(force: true);

    dynamic allSpiesSuccess;
    if (_spiesSource == SpiesSource.yata) {
      allSpiesSuccess = await _getYataSpies(_u.apiKey);
    } else {
      allSpiesSuccess = await _getTornStatsSpies(_u.apiKey);
    }

    int numberUpdated = 0;

    // Get player's current location
    final apiPlayer = await TornApiCaller().getProfileBasic();
    if (apiPlayer is ApiError) {
      return -1;
    }
    final profile = apiPlayer as OwnProfileBasic;
    playerLocation = countryCheck(profile.status);

    for (FactionModel f in factions) {
      final apiResult = await TornApiCaller().getFaction(factionId: f.id.toString());
      if (apiResult is ApiError || (apiResult is FactionModel && apiResult.id == null)) {
        return -1;
      }
      final apiFaction = apiResult as FactionModel;

      DateTime updatedTime = DateTime.now();

      apiFaction.members.forEach((apiMemberId, apiMember) {
        if (f.members.containsKey(apiMemberId)) {
          f.members[apiMemberId].overrideEasyLife = false;

          f.members[apiMemberId].justUpdatedWithSuccess = true;
          update();
          Future.delayed(Duration(seconds: 2)).then((value) {
            f.members[apiMemberId].justUpdatedWithSuccess = false;
            update();
          });

          f.members[apiMemberId].lastUpdated = updatedTime;
          f.members[apiMemberId] = apiMember;

          _assignSpiedStats(allSpiesSuccess, f.members[apiMemberId]);

          if (allAttacksSuccess is AttackModel) {
            _getRespectFF(
              allAttacksSuccess,
              f.members[apiMemberId],
              oldRespect: f.members[apiMemberId].respectGain,
              oldFF: f.members[apiMemberId].fairFight,
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

  Future updateSomeMembersAfterAttack() async {
    await Future.delayed(Duration(seconds: 15));
    dynamic allAttacksSuccess = await getAllAttacks();
    dynamic ownStatsSuccess = await getOwnStats();

    updating = true;
    update();

    // Copy list so that alterations (hiding) do not cause error
    // which might happen even if we stop the update
    List<FactionModel> thisFactions = List.from(factions);

    for (String id in lastAttackedTargets) {
      for (FactionModel f in thisFactions) {
        if (_stopUpdate) {
          _stopUpdate = false;
          updating = false;
          update();
          return;
        }

        if (f.members.containsKey(id)) {
          await updateSingleMemberFull(
            f.members[id],
            allAttacks: allAttacksSuccess,
            ownStats: ownStatsSuccess,
          );

          if (lastAttackedTargets.length > 60) {
            await Future.delayed(Duration(seconds: 1));
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

  Future<void> _updateResultAnimation({Member member, bool success}) async {
    if (success) {
      member.justUpdatedWithSuccess = true;
      update();
      await Future.delayed(const Duration(seconds: 5), () {});
      member.justUpdatedWithSuccess = false;
      update();
    } else {
      member.justUpdatedWithError = true;
      update();
      await Future.delayed(const Duration(seconds: 5), () {});
      member.justUpdatedWithError = false;
      update();
    }
  }

  void _getRespectFF(
    AttackModel attackModel,
    Member member, {
    double oldRespect = -1,
    double oldFF = -1,
  }) {
    double respect = -1;
    double fairFight = -1; // Unknown
    List<bool> userWonOrDefended = <bool>[];
    if (attackModel is AttackModel) {
      attackModel.attacks.forEach((key, value) {
        // We look for the our target in the the attacks list
        if (member.memberId == value.defenderId || member.memberId == value.attackerId) {
          // Only update if we have still not found a positive value (because
          // we lost or we have no records)
          if (value.respectGain > 0) {
            fairFight = value.modifiers.fairFight;
            respect = fairFight * 0.25 * (log(member.level) + 1);
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
        member.respectGain = respect;
      } else if (respect == -1 && oldRespect != -1) {
        // If it is unknown BUT we have a previously recorded value, we need to provide it for the new target (or
        // otherwise it will default to -1). This can happen when the last attack on this target is not within the
        // last 100 total attacks and therefore it's not returned in the attackModel.
        member.respectGain = oldRespect;
      }

      // Same as above
      if (fairFight != -1) {
        member.fairFight = fairFight;
      } else if (fairFight == -1 && oldFF != -1) {
        member.fairFight = oldFF;
      }

      if (userWonOrDefended.isNotEmpty) {
        member.userWonOrDefended = userWonOrDefended.first;
      } else {
        member.userWonOrDefended = true; // Placeholder
      }
    }
  }

  void setMemberNote(Member changedMember, String note, String color) {
    // We are not updating the target directly, but instead looping for the correct one because
    // after an attack the targets get updated several times: if the user wants to change the note
    // right after the attack, the good target might have been replaced and the note does not get
    // updated. Therefore, we just loop whenever the user submits the new text.
    for (var f in factions) {
      if (f.members.keys.contains(changedMember.memberId.toString())) {
        f.members[changedMember.memberId.toString()].personalNote = note;
        f.members[changedMember.memberId.toString()].personalNoteColor = color;
        savePreferences();
        update();
        break;
      }
    }
  }

  void hideMember(Member hiddenMember) {
    for (var f in factions) {
      if (f.members.keys.contains(hiddenMember.memberId.toString())) {
        f.members[hiddenMember.memberId.toString()].hidden = true;
        savePreferences();
        update();
        break;
      }
    }
  }

  void unhideMember(Member hiddenMember) {
    for (var f in factions) {
      if (f.members.keys.contains(hiddenMember.memberId.toString())) {
        f.members[hiddenMember.memberId.toString()].hidden = false;
        savePreferences();
        update();
        break;
      }
    }
  }

  int getHiddenMembersNumber() {
    int membersHidden = 0;
    for (FactionModel f in factions) {
      membersHidden += f.members.values.where((m) => m.hidden).length;
    }
    return membersHidden;
  }

  List<Member> getHiddenMembersDetails() {
    List<Member> membersHidden = <Member>[];
    for (FactionModel f in factions) {
      membersHidden.addAll((f.members.values.where((m) => m.hidden)));
    }
    return membersHidden;
  }

  dynamic getAllAttacks() async {
    var result = await TornApiCaller().getAttacks();
    if (result is AttackModel) {
      return result;
    }
    return false;
  }

  dynamic getOwnStats() async {
    var result = await TornApiCaller().getOwnPersonalStats();
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

  Future initialise() async {
    String spiesSource = await Prefs().getSpiesSource();
    spiesSource == "yata" ? _spiesSource = SpiesSource.yata : _spiesSource = SpiesSource.tornStats;

    List<String> saved = await Prefs().getWarFactions();
    saved.forEach((element) {
      factions.add(factionModelFromJson(element));
    });

    activeFilters = await Prefs().getFilterListInWars();
    onlineFilter = await Prefs().getOnlineFilterInWars();
    okayFilter = await Prefs().getOkayFilterInWars();
    countryFilter = await Prefs().getCountryFilterInWars();
    showChainWidget = await Prefs().getShowChainWidgetInWars();

    nukeReviveActive = await Prefs().getUseNukeRevive();
    uhcReviveActive = await Prefs().getUseUhcRevive();

    // Get sorting
    String targetSort = await Prefs().getWarMembersSort();
    switch (targetSort) {
      case '':
        currentSort = WarSortType.levelDes;
        break;
      case 'levelDes':
        currentSort = WarSortType.levelDes;
        break;
      case 'levelAsc':
        currentSort = WarSortType.levelAsc;
        break;
      case 'respectDes':
        currentSort = WarSortType.respectDes;
        break;
      case 'respectAsc':
        currentSort = WarSortType.respectAsc;
        break;
      case 'nameDes':
        currentSort = WarSortType.nameDes;
        break;
      case 'nameAsc':
        currentSort = WarSortType.nameAsc;
        break;
      case 'lifeDes':
        currentSort = WarSortType.lifeDes;
        break;
      case 'lifeAsc':
        currentSort = WarSortType.lifeAsc;
        break;
      case 'statsDes':
        currentSort = WarSortType.statsDes;
        break;
      case 'statsAsc':
        currentSort = WarSortType.statsDes;
        break;
      case 'onlineDes':
        currentSort = WarSortType.onlineDes;
        break;
      case 'onlineAsc':
        currentSort = WarSortType.onlineAsc;
        break;
      case 'colorDes':
        currentSort = WarSortType.colorDes;
        break;
      case 'colorAsc':
        currentSort = WarSortType.colorAsc;
        break;
    }

    if (_spiesSource == SpiesSource.yata) {
      List<String> savedYataSpies = await Prefs().getYataSpies();
      for (String spyJson in savedYataSpies) {
        YataSpyModel spyModel = yataSpyModelFromJson(spyJson);
        _yataSpies.add(spyModel);
      }
      _lastYataSpiesDownload = DateTime.fromMillisecondsSinceEpoch(await Prefs().getYataSpiesTime());
    } else {
      String savedTornStatsSpies = await Prefs().getTornStatsSpies();
      if (savedTornStatsSpies.isNotEmpty) {
        _tornStatsSpies = tornStatsSpiesModelFromJson(savedTornStatsSpies);
        _lastTornStatsSpiesDownload = DateTime.fromMillisecondsSinceEpoch(await Prefs().getTornStatsSpiesTime());
      }
    }

    _lastIntegrityCheck = DateTime.fromMillisecondsSinceEpoch(await Prefs().getWarIntegrityCheckTime());

    _integrityCheck();

    update();
  }

  void savePreferences() {
    List<String> factionList = [];
    factions.forEach((element) {
      factionList.add(factionModelToJson(element));
    });
    Prefs().setWarFactions(factionList);

    Prefs().setFilterListInWars(activeFilters);
    Prefs().setOnlineFilterInWars(onlineFilter);
    Prefs().setOkayFilterInWars(okayFilter);
    Prefs().setCountryFilterInWars(countryFilter);
    Prefs().setShowChainWidgetInWars(showChainWidget);

    // Save sorting
    String sortToSave;
    switch (currentSort) {
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
        sortToSave = 'respectDes';
        break;
      case WarSortType.nameDes:
        sortToSave = 'nameDes';
        break;
      case WarSortType.nameAsc:
        sortToSave = 'nameDes';
        break;
      case WarSortType.lifeDes:
        sortToSave = 'nameDes';
        break;
      case WarSortType.lifeAsc:
        sortToSave = 'nameDes';
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
    }
    Prefs().setWarMembersSort(sortToSave);
  }

  void saveSpies() {
    if (_spiesSource == SpiesSource.yata) {
      List<String> yataSpiesSave = <String>[];
      for (YataSpyModel spy in _yataSpies) {
        String spyJson = yataSpyModelToJson(spy);
        yataSpiesSave.add(spyJson);
      }
      Prefs().setYataSpies(yataSpiesSave);
      Prefs().setYataSpiesTime(_lastYataSpiesDownload.millisecondsSinceEpoch);
    } else {
      Prefs().setTornStatsSpies(tornStatsSpiesModelToJson(_tornStatsSpies));
      Prefs().setTornStatsSpiesTime(_lastTornStatsSpiesDownload.millisecondsSinceEpoch);
    }
  }

  void sortTargets(WarSortType sortType) {
    currentSort = sortType;
    savePreferences();
    update();
  }

  Future<List<YataSpyModel>> _getYataSpies(String apiKey) async {
    // If spies where updated less than an hour ago
    if (_lastYataSpiesDownload != null && DateTime.now().difference(_lastYataSpiesDownload).inHours < 1) {
      return _yataSpies;
    }

    List<YataSpyModel> spies = <YataSpyModel>[];
    try {
      String yataURL = 'https://yata.yt/api/v1/spies/?key=${_u.alternativeYataKey}';
      var resp = await http.get(Uri.parse(yataURL)).timeout(Duration(seconds: 10));
      if (resp.statusCode == 200) {
        dynamic spiesJson = json.decode(resp.body);
        if (spiesJson != null) {
          Map<String, dynamic> mainMap = spiesJson as Map<String, dynamic>;
          Map<String, dynamic> spyList = mainMap.entries.first.value;
          spyList.forEach((key, value) {
            YataSpyModel spyModel = yataSpyModelFromJson(json.encode(value));
            spies.add(spyModel);
          });
        }
      }
    } catch (e) {
      return _yataSpies = null;
    }
    _lastYataSpiesDownload = DateTime.now();
    _yataSpies = spies;
    saveSpies();

    return spies;
  }

  Future<TornStatsSpiesModel> _getTornStatsSpies(String apiKey) async {
    // If spies where updated less than an hour ago
    if (_lastTornStatsSpiesDownload != null && DateTime.now().difference(_lastTornStatsSpiesDownload).inHours < 1) {
      return _tornStatsSpies;
    }

    try {
      String tornStatsURL = 'https://www.tornstats.com/api/v1/${_u.alternativeTornStatsKey}/faction/spies';
      var resp = await http.get(Uri.parse(tornStatsURL)).timeout(Duration(seconds: 10));
      if (resp.statusCode == 200) {
        TornStatsSpiesModel spyJson = tornStatsSpiesModelFromJson(resp.body);
        if (spyJson != null && !spyJson.message.contains("Error")) {
          _lastTornStatsSpiesDownload = DateTime.now();
          _tornStatsSpies = spyJson;
          saveSpies();
          return spyJson;
        }
      }
    } catch (e) {
      // Returns null
      print(e);
    }
    return _tornStatsSpies = null;
  }

  void launchShowCaseAddFaction() async {
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
    if (!force && DateTime.now().difference(_lastIntegrityCheck).inHours < 1) {
      return;
    }

    for (FactionModel f in factions) {
      final apiResult = await TornApiCaller().getFaction(factionId: f.id.toString());
      if (apiResult is ApiError || (apiResult is FactionModel && apiResult.id == null)) {
        return;
      }
      FactionModel imported = apiResult as FactionModel;

      Map<String, Member> thisMembers = Map.from(f.members);

      // Remove members that do not longer belong to the faction
      thisMembers.forEach((memberId, memberDetails) {
        if (!imported.members.containsKey(memberId)) {
          f.members.removeWhere((key, value) => key == memberId);
        }
      });

      // Add new members that were not here before
      imported.members.forEach((key, value) {
        if (!thisMembers.containsKey(key)) {
          f.members[key] = imported.members[key];
          updateSingleMemberFull(f.members[key]);
        }
      });
    }

    Prefs().setWarIntegrityCheckTime(DateTime.now().millisecondsSinceEpoch);
    savePreferences();
    update();
  }

  int _getLifeSort(Member member) {
    if (member.status.state != "Hospital") {
      return member.lifeCurrent;
    } else {
      return -(member.status.until - DateTime.now().millisecondsSinceEpoch / 1000).round();
    }
  }

  void _assignSpiedStats(dynamic spies, Member member) {
    if (spies != null) {
      if (_spiesSource == SpiesSource.yata) {
        for (YataSpyModel spy in spies) {
          if (spy.targetName == member.name) {
            member.spiesSource = "yata";
            member.statsExactTotal = member.statsSort = spy.total;
            member.statsExactUpdated = spy.update;
            member.statsStr = spy.strength;
            member.statsSpd = spy.speed;
            member.statsDef = spy.defense;
            member.statsDex = spy.dexterity;
            int known = 0;
            if (spy.strength != 1) known += spy.strength;
            if (spy.speed != 1) known += spy.speed;
            if (spy.defense != 1) known += spy.defense;
            if (spy.dexterity != 1) known += spy.dexterity;
            member?.statsExactTotalKnown = known;
            break;
          }
        }
      } else {
        for (SpyElement spy in spies.spies) {
          if (spy.playerName == member.name) {
            member.spiesSource = "tornstats";
            member.statsExactTotal = member.statsSort = spy.total;
            member.statsExactUpdated = spy.timestamp;
            member.statsStr = spy.strength;
            member.statsSpd = spy.speed;
            member.statsDef = spy.defense;
            member.statsDex = spy.dexterity;
            int known = 0;
            if (spy.strength != 1) known += spy.strength;
            if (spy.speed != 1) known += spy.speed;
            if (spy.defense != 1) known += spy.defense;
            if (spy.dexterity != 1) known += spy.dexterity;
            member?.statsExactTotalKnown = known;
            break;
          }
        }
      }
    }
  }
}
