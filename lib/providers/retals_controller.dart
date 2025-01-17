import 'dart:developer' as dev;
import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/attack_model.dart' as am;
import 'package:torn_pda/models/chaining/retal_model.dart';
import 'package:torn_pda/models/chaining/tornstats/tornstats_spies_model.dart';
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/models/faction/faction_attacks_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart' as other;
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/stats_calculator.dart';

class RetalsCardDetails {
  int? cardPosition;
  int? retalId;
  String? name;
  String? personalNote;
  String? personalNoteColor;
}

class RetalsController extends GetxController {
  List<Retal> retaliationList = <Retal>[];
  List<RetalsCardDetails> orderedCardsDetails = <RetalsCardDetails>[];

  bool sectionVisible = false;
  bool updating = false;
  bool browserIsOpen = false;

  List<String> lastAttackedTargets = [];

  Future<Retal?> getInfoForNewRetal(String retalId, {dynamic allAttacks, dynamic ownStats}) async {
    final retal = Retal(lastAction: LastAction(), status: Status());

    dynamic allAttacksSuccess = allAttacks;
    allAttacksSuccess ??= await getAllAttacks();

    dynamic ownStatsSuccess = ownStats;
    ownStatsSuccess ??= await getOwnStats();

    final String retalKey = retalId;
    bool error = false;

    // Perform update
    try {
      final dynamic updatedTarget = await ApiCallsV2.getOtherUserProfile_v2(
        payload: {
          "id": retalKey,
        },
      );

      if (updatedTarget is other.OtherProfileModel) {
        retal.name = updatedTarget.name;
        retal.level = updatedTarget.level;
        retal.position = updatedTarget.faction!.position;
        retal.factionName = updatedTarget.faction!.factionName;
        retal.retalId = updatedTarget.playerId;
        retal.overrideEasyLife = true;
        retal.lifeMaximum = updatedTarget.life!.maximum;
        retal.lifeCurrent = updatedTarget.life!.current;
        retal.lastAction.relative = updatedTarget.lastAction!.relative;
        retal.lastAction.status = updatedTarget.lastAction!.status;
        retal.status.description = updatedTarget.status!.description;
        retal.status.state = updatedTarget.status!.state;
        retal.status.until = updatedTarget.status!.until;
        retal.status.color = updatedTarget.status!.color;

        retal.lastUpdated = DateTime.now();
        if (allAttacksSuccess is am.AttackModel) {
          _getRespectFF(allAttacksSuccess, retal, oldRespect: retal.respectGain, oldFF: retal.fairFight);
        }

        _assignSpiedStats(retal);

        retal.statsEstimated = StatsCalculator.calculateStats(
          criminalRecordTotal: updatedTarget.personalstats?.crimes?.offenses?.total,
          level: updatedTarget.level,
          networth: updatedTarget.personalstats!.networth!.total,
          rank: updatedTarget.rank,
        );

        retal.statsComparisonSuccess = false;
        if (ownStatsSuccess is OwnPersonalStatsModel) {
          retal.statsComparisonSuccess = true;

          retal.retalXanax = updatedTarget.personalstats!.drugs!.xanax;
          retal.myXanax = ownStatsSuccess.personalstats!.xantaken;

          retal.retalRefill = updatedTarget.personalstats!.other!.refills!.energy;
          retal.myRefill = ownStatsSuccess.personalstats!.refills;

          retal.retalCans = updatedTarget.personalstats!.items!.used!.energy;
          retal.myCans = ownStatsSuccess.personalstats!.energydrinkused;

          retal.retalEnhancement = updatedTarget.personalstats!.items!.used!.statEnhancers;
          retal.myEnhancement = ownStatsSuccess.personalstats!.statenhancersused;

          retal.retalEcstasy = updatedTarget.personalstats!.drugs!.ecstasy;
          retal.retalLsd = updatedTarget.personalstats!.drugs!.lsd;
        }

        // Even if we assign both exact (if available) and estimated, we only pass estimated to startSort
        // if exact does not exist (-1)
        if (retal.statsExactTotal == -1) {
          switch (retal.statsEstimated) {
            case "< 2k":
              retal.statsSort = 2000;
            case "2k - 25k":
              retal.statsSort = 25000;
            case "20k - 250k":
              retal.statsSort = 250000;
            case "200k - 2.5M":
              retal.statsSort = 2500000;
            case "2M - 25M":
              retal.statsSort = 25000000;
            case "20M - 250M":
              retal.statsSort = 200000000;
            case "> 200M":
              retal.statsSort = 250000000;
            default:
              retal.statsSort = 0;
              break;
          }
        }
      } else {
        error = true;
      }
    } catch (e) {
      error = true;
      dev.log("Error adding retal: $e");
    }

    if (!error) {
      return retal;
    }
    return null;
  }

  void _getRespectFF(
    am.AttackModel attackModel,
    Retal retal, {
    double? oldRespect = -1,
    double? oldFF = -1,
  }) {
    double respect = -1;
    double? fairFight = -1; // Unknown
    List<bool> userWonOrDefended = <bool>[];
    attackModel.attacks!.forEach((key, value) {
      // We look for the our target in the the attacks list
      if (retal.retalId == value.defenderId || retal.retalId == value.attackerId) {
        // Only update if we have still not found a positive value (because
        // we lost or we have no records)
        if (value.respectGain > 0) {
          fairFight = value.modifiers!.fairFight;
          respect = fairFight! * 0.25 * (log(retal.level!) + 1);
        } else if (respect == -1) {
          respect = 0;
          fairFight = 1.00;
        }

        if (retal.retalId == value.defenderId) {
          if (value.result as Result == Result.LOST || value.result as Result == Result.STALEMATE) {
            // If we attacked and lost
            userWonOrDefended.add(false);
          } else {
            userWonOrDefended.add(true);
          }
        } else if (retal.retalId == value.attackerId) {
          if (value.result as Result == Result.LOST || value.result as Result == Result.STALEMATE) {
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
      retal.respectGain = respect;
    } else if (respect == -1 && oldRespect != -1) {
      // If it is unknown BUT we have a previously recorded value, we need to provide it for the new target (or
      // otherwise it will default to -1). This can happen when the last attack on this target is not within the
      // last 100 total attacks and therefore it's not returned in the attackModel.
      retal.respectGain = oldRespect;
    }

    // Same as above
    if (fairFight != -1) {
      retal.fairFight = fairFight;
    } else if (fairFight == -1 && oldFF != -1) {
      retal.fairFight = oldFF;
    }

    if (userWonOrDefended.isNotEmpty) {
      retal.userWonOrDefended = userWonOrDefended.first;
    } else {
      retal.userWonOrDefended = true; // Placeholder
    }
  }

  dynamic getAllAttacks() async {
    final result = await ApiCallsV1.getAttacks();
    if (result is am.AttackModel) {
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

  Future retrieveRetals(BuildContext context) async {
    if (!sectionVisible) {
      return;
    }

    updating = true;
    update();

    try {
      final String error = await _getApiEvaluateRetals(context);
      int seconds = 6;
      if (error.isNotEmpty) {
        String message = "There was an issue fetching targets, there might be a connection error with the API."
            "\n\nPlease try again in a while";

        if (error.contains("incorrect ID-entity relation")) {
          message = "Permission error!\n\n You do not seem to have Faction API permissions to use this feature."
              "\n\nIf you think there might be an error, please talk to your faction leaders about it.\n\n"
              "If you wish, you can deactivate this section altogether in Targets / Options.";
          seconds = 10;
        }

        BotToast.showText(
          clickClose: true,
          text: message,
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.orange[900]!,
          duration: Duration(seconds: seconds),
          contentPadding: const EdgeInsets.all(10),
        );
        return;
      }
    } catch (e) {
      //
    }

    updating = false;
    update();
  }

  Future<String> _getApiEvaluateRetals(BuildContext context) async {
    List<Retal> newList = <Retal>[];

    final attacksResult = await ApiCallsV1.getFactionAttacks();
    if (attacksResult is FactionAttacksModel) {
      final dynamic allAttacksSuccess = await getAllAttacks();
      final dynamic ownStatsSuccess = await getOwnStats();

      final timeStamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

      final validAttacks = <Attack>[];

      attacksResult.attacks!.forEach((key, value) {
        // Choose only valid retaliations
        bool validAttack = false;
        if (value.attackerName!.isNotEmpty && value.respect! > 0) {
          validAttack = true;
        }

        // DEBUG
        bool validTime = false;
        if ((timeStamp - value.timestampEnded!) < 300) {
          validTime = true;
        }

        bool validFaction = false;
        final userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
        if (value.attackerFaction != userProvider.basic!.faction!.factionId) {
          validFaction = true;
        }

        if (validAttack && validTime && validFaction) {
          validAttacks.add(value);
        }
      });

      // From the existing retaliations, see if the faction already retaliated, and discard!
      for (final Attack incomingAttack in validAttacks) {
        bool alreadyRetaliated = false;
        attacksResult.attacks!.forEach((key, outgoingAttack) {
          if (outgoingAttack.defenderName == incomingAttack.attackerName &&
              outgoingAttack.timestampEnded! > incomingAttack.timestampEnded! &&
              outgoingAttack.respect! > 0) {
            alreadyRetaliated = true;
          }
        });

        if (!alreadyRetaliated) {
          final dynamic infoResult = await getInfoForNewRetal(
            incomingAttack.attackerId.toString(),
            allAttacks: allAttacksSuccess,
            ownStats: ownStatsSuccess,
          );

          if (infoResult is Retal) {
            infoResult.retalExpiry = incomingAttack.timestampEnded! + 300;
            newList.add(infoResult);
          }
        }
      }

      // Remove duplicates (just keep the last attack for each attacker)
      final ids = <dynamic>{};
      newList.retainWhere((x) => ids.add(x.name));

      retaliationList = List<Retal>.from(newList);
      return "";
    } else if (attacksResult is ApiError) {
      return attacksResult.errorReason;
    }
    return "error";
  }

  void _assignSpiedStats(Retal retal) {
    final SpiesController spyController = Get.find<SpiesController>();

    void assignTornStatsSpy(Retal retal, SpyElement spy) {
      retal.spySource = SpiesSource.tornStats;
      retal.statsExactTotal = retal.statsSort = spy.total;
      retal.statsExactUpdated = spy.timestamp;
      retal.statsStr = spy.strength;
      retal.statsSpd = spy.speed;
      retal.statsDef = spy.defense;
      retal.statsDex = spy.dexterity;
      int known = 0;
      if (spy.strength != 1) known += spy.strength!;
      if (spy.speed != 1) known += spy.speed!;
      if (spy.defense != 1) known += spy.defense!;
      if (spy.dexterity != 1) known += spy.dexterity!;
      retal.statsExactTotalKnown = known;
    }

    void assignYataSpy(Retal retal, YataSpyModel spy) {
      retal.spySource = SpiesSource.yata;
      retal.statsExactTotal = retal.statsSort = spy.total;
      retal.statsExactTotalUpdated = spy.totalTimestamp;
      retal.statsExactUpdated = spy.update;
      retal.statsStr = spy.strength;
      retal.statsStrUpdated = spy.strengthTimestamp;
      retal.statsSpd = spy.speed;
      retal.statsSpdUpdated = spy.speedTimestamp;
      retal.statsDef = spy.defense;
      retal.statsDefUpdated = spy.defenseTimestamp;
      retal.statsDex = spy.dexterity;
      retal.statsDexUpdated = spy.dexterityTimestamp;
      int known = 0;
      if (spy.strength != 1) known += spy.strength!;
      if (spy.speed != 1) known += spy.speed!;
      if (spy.defense != 1) known += spy.defense!;
      if (spy.dexterity != 1) known += spy.dexterity!;
      retal.statsExactTotalKnown = known;
    }

    bool spyFound = false;

    // Delete spy information if we don't allow mixed spies sources
    if ((!spyController.allowMixedSpiesSources &&
            retal.spySource != SpiesSource.yata &&
            spyController.spiesSource == SpiesSource.yata) ||
        (!spyController.allowMixedSpiesSources &&
            retal.spySource != SpiesSource.tornStats &&
            spyController.spiesSource == SpiesSource.tornStats)) {
      _deleteSpiedStats(retal);
    }

    // Find the spy based in the current selected spy source
    if (spyController.spiesSource == SpiesSource.yata) {
      final spy = spyController.getYataSpy(userId: retal.retalId.toString(), name: retal.name);
      if (spy != null) {
        assignYataSpy(retal, spy);
        spyFound = true;
      } else if (spyController.allowMixedSpiesSources) {
        // Check alternate source of spies if we allow mixed sources
        final altSpy = spyController.getTornStatsSpy(userId: retal.retalId.toString());
        if (altSpy != null) {
          assignTornStatsSpy(retal, altSpy);
          spyFound = true;
        }
      }
    } else if (spyController.spiesSource == SpiesSource.tornStats) {
      final spy = spyController.getTornStatsSpy(userId: retal.retalId.toString());
      if (spy != null) {
        assignTornStatsSpy(retal, spy);
        spyFound = true;
      } else if (spyController.allowMixedSpiesSources) {
        // Check alternate source of spies if we allow mixed sources
        final altSpy = spyController.getYataSpy(userId: retal.retalId.toString(), name: retal.name);
        if (altSpy != null) {
          assignYataSpy(retal, altSpy);
          spyFound = true;
        }
      }
    }

    // If we didn't find a spy at all, delete the spies information (it might be an old spy,
    // or the user might have deleted and recreated the spies list)
    if (!spyFound) {
      _deleteSpiedStats(retal);
    }
  }

  _deleteSpiedStats(Retal retal) {
    retal.spySource = SpiesSource.yata;
    retal.statsExactTotal = -1;
    retal.statsExactTotalUpdated = -1;
    retal.statsExactUpdated = -1;
    retal.statsStr = -1;
    retal.statsStrUpdated = -1;
    retal.statsSpd = -1;
    retal.statsSpdUpdated = -1;
    retal.statsDef = -1;
    retal.statsDefUpdated = -1;
    retal.statsDex = -1;
    retal.statsDexUpdated = -1;
    retal.statsExactTotalKnown = -1;
  }
}
