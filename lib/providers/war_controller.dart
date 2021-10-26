import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/chaining/war_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:http/http.dart' as http;

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
  bool showChainWidget = true;
  WarSortType currentSort;

  bool updating = false;
  bool _stopUpdate = false;

  bool showCaseAddFaction = false;

  bool addFromUserId = false;

  DateTime _lastIntegrityCheck;

  DateTime _lastSpiesDownload;
  List<YataSpyModel> _spies = <YataSpyModel>[];

  @override
  void onInit() {
    super.onInit();
    initialise();
  }

  Future<String> addFaction(String factionId, List<TargetModel> targets) async {
    stopUpdate();
    // Return custom error code if faction already exists
    for (FactionModel faction in factions) {
      if (faction.id.toString() == factionId) {
        return "error_existing";
      }
    }

    final apiResult = await TornApiCaller.faction(_u.apiKey, factionId).getFaction;
    if (apiResult is ApiError || (apiResult is FactionModel && apiResult.id == null)) {
      return "";
    }

    final faction = apiResult as FactionModel;
    factions.add(faction);

    dynamic allSpiesSuccess = await _getYataSpies(_u.apiKey);

    // Add extra member information
    DateTime addedTime = DateTime.now();
    faction.members.forEach((memberId, member) {
      // Last updated time
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
          break;
        }
      }

      if (allSpiesSuccess != null) {
        for (YataSpyModel spy in allSpiesSuccess) {
          if (spy.targetName == member.name) {
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
            member.statsExactTotalKnown = known;
            break;
          }
        }
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
  Future<bool> updateSingleMember(Member member, {dynamic allAttacks, dynamic spies}) async {
    dynamic allAttacksSuccess = allAttacks;
    if (allAttacksSuccess == null) {
      allAttacksSuccess = await getAllAttacks(_u.apiKey);
    }

    member.isUpdating = true;
    update();

    dynamic allSpiesSuccess = await _getYataSpies(_u.apiKey);

    String memberKey = member.memberId.toString();
    bool error = false;

    // Perform update
    try {
      dynamic updatedTarget = await TornApiCaller.target(_u.apiKey, memberKey).getOtherProfile;
      if (updatedTarget is OtherProfileModel) {
        member.lifeMaximum = updatedTarget.life.current;
        member.lifeCurrent = updatedTarget.life.maximum;
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
        if (allSpiesSuccess != null) {
          for (YataSpyModel spy in allSpiesSuccess) {
            if (spy.targetName == member.name) {
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
              member.statsExactTotalKnown = known;
              break;
            }
          }
        }

        member.statsEstimated = _assignEstimatedStats(updatedTarget);

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

  Future<List<int>> updateAllMembers() async {
    await _integrityCheck(force: true);

    dynamic allAttacksSuccess = await getAllAttacks(_u.apiKey);
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
          bool memberSuccess = await updateSingleMember(
            f.members[card.memberId.toString()],
            allAttacks: allAttacksSuccess,
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

  Future updateSomeMembersAfterAttack(List<String> attackedMembers) async {
    await Future.delayed(Duration(seconds: 15));
    dynamic allAttacksSuccess = await getAllAttacks(_u.apiKey);

    updating = true;
    update();

    // Copy list so that alterations (hiding) do not cause error
    // which might happen even if we stop the update
    List<FactionModel> thisFactions = List.from(factions);

    for (String id in attackedMembers) {
      for (FactionModel f in thisFactions) {
        if (_stopUpdate) {
          _stopUpdate = false;
          updating = false;
          update();
          return;
        }

        if (f.members.containsKey(id)) {
          await updateSingleMember(
            f.members[id],
            allAttacks: allAttacksSuccess,
          );

          if (attackedMembers.length > 60) {
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

  dynamic getAllAttacks(String _userKey) async {
    var result = await TornApiCaller.attacks(_userKey).getAttacks;
    if (result is AttackModel) {
      return result;
    }
    return false;
  }

  void toggleChainWidget() {
    showChainWidget = !showChainWidget;
    savePreferences();
    update();
  }

  Future initialise() async {
    List<String> saved = await Prefs().getWarFactions();
    saved.forEach((element) {
      factions.add(factionModelFromJson(element));
    });

    showChainWidget = await Prefs().getShowChainWidgetInWars();

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
      case 'statsDes':
        currentSort = WarSortType.statsDes;
        break;
      case 'statsAsc':
        currentSort = WarSortType.statsDes;
        break;
      case 'nameDes':
        currentSort = WarSortType.nameDes;
        break;
      case 'nameAsc':
        currentSort = WarSortType.nameAsc;
        break;
    }

    List<String> savedSpies = await Prefs().getWarSpies();
    for (String spyJson in savedSpies) {
      YataSpyModel spyModel = yataSpyModelFromJson(spyJson);
      _spies.add(spyModel);
    }
    _lastSpiesDownload = DateTime.fromMillisecondsSinceEpoch(await Prefs().getWarSpiesTime());

    _lastIntegrityCheck = DateTime.fromMillisecondsSinceEpoch(await Prefs().getWarIntegrityCheckTime());

    _integrityCheck();
  }

  void savePreferences() {
    List<String> factionList = [];
    factions.forEach((element) {
      factionList.add(factionModelToJson(element));
    });
    Prefs().setWarFactions(factionList);

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
      case WarSortType.statsDes:
        sortToSave = 'statsDes';
        break;
      case WarSortType.statsAsc:
        sortToSave = 'statsAsc';
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
    List<String> spiesSave = <String>[];
    for (YataSpyModel spy in _spies) {
      String spyJson = yataSpyModelToJson(spy);
      spiesSave.add(spyJson);
    }
    Prefs().setWarSpies(spiesSave);
    Prefs().setWarSpiesTime(_lastSpiesDownload.millisecondsSinceEpoch);
  }

  void sortTargets(WarSortType sortType) {
    currentSort = sortType;
    savePreferences();
    update();
  }

  String _assignEstimatedStats(OtherProfileModel member) {
    final levelTriggers = [2, 6, 11, 26, 31, 50, 71, 100];
    final crimesTriggers = [100, 5000, 10000, 20000, 30000, 50000];
    final networthTriggers = [5000000, 50000000, 500000000, 5000000000, 50000000000];

    final _ranksTriggers = {
      "Absolute beginner": 1,
      "Beginner": 2,
      "Inexperienced": 3,
      "Rookie": 4,
      "Novice": 5,
      "Below average": 6,
      "Average": 7,
      "Reasonable": 8,
      "Above average": 9,
      "Competent": 10,
      "Highly competent": 11,
      "Veteran": 12,
      "Distinguished": 13,
      "Highly distinguished": 14,
      "Professional": 15,
      "Star": 16,
      "Master": 17,
      "Outstanding": 18,
      "Celebrity": 19,
      "Supreme": 20,
      "Idolized": 21,
      "Champion": 22,
      "Heroic": 23,
      "Legendary": 24,
      "Elite": 25,
      "Invincible": 26,
    };

    final _statsResults = [
      "< 2k",
      "2k - 25k",
      "20k - 250k",
      "200k - 2.5M",
      "2M - 25M",
      "20M - 250M",
      "> 200M",
    ];

    var levelIndex = levelTriggers.lastIndexWhere((x) => x <= member.level) + 1;
    var crimeIndex = crimesTriggers.lastIndexWhere((x) => x <= member.criminalrecord.total) + 1;
    var networthIndex = networthTriggers.lastIndexWhere((x) => x <= member.personalstats.networth) + 1;
    var rankIndex = 0;
    _ranksTriggers.forEach((tornRank, index) {
      if (member.rank.contains(tornRank)) {
        rankIndex = index;
      }
    });

    var finalIndex = rankIndex - levelIndex - crimeIndex - networthIndex - 1;
    if (finalIndex >= 0 && finalIndex <= 6) {
      return _statsResults[finalIndex];
    }
    return "";
  }

  Future<List<YataSpyModel>> _getYataSpies(String apiKey) async {
    // If spies where updated less than an hour ago
    if (_lastSpiesDownload != null && DateTime.now().difference(_lastSpiesDownload).inHours < 1) {
      return _spies;
    }

    List<YataSpyModel> spies = <YataSpyModel>[];
    try {
      String yataURL = 'https://yata.yt/api/v1/spies/?key=${apiKey}';
      var resp = await http.get(Uri.parse(yataURL)).timeout(Duration(seconds: 2));
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
      return _spies = null;
    }
    _lastSpiesDownload = DateTime.now();
    _spies = spies;
    saveSpies();

    return spies;
  }

  void launchShowCaseAddFaction() async {
    showCaseAddFaction = true;
    update();
  }

  void toggleAddFromUserId() {
    addFromUserId = !addFromUserId;
    update();
  }

  Future _integrityCheck({bool force = false}) async {
    if (!force && DateTime.now().difference(_lastIntegrityCheck).inHours < 1) {
      return;
    }

    for (FactionModel f in factions) {
      final apiResult = await TornApiCaller.faction(_u.apiKey, f.id.toString()).getFaction;
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
          updateSingleMember(f.members[key]);
        }
      });
    }

    Prefs().setWarIntegrityCheckTime(DateTime.now().millisecondsSinceEpoch);
    savePreferences();
    update();
  }
}
