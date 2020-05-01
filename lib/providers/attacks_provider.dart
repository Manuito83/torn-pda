import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/attack_sort_popup.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

enum AttackTypeFilter {
  all,
  unknownTargets,
}

class AttacksProvider extends ChangeNotifier {
  List<Attack> _attacks = [];
  UnmodifiableListView<Attack> get allAttacks => UnmodifiableListView(_attacks);

  String _currentWordFilter = '';
  String get currentFilter => _currentWordFilter;

  AttackTypeFilter _currentTypeFilter = AttackTypeFilter.all;
  AttackTypeFilter get currentTypeFilter => _currentTypeFilter;

  AttackSort _currentSort;

  String _userKey = '';
  String _ownId = '';

  void initializeAttacks() async {
    await restoreSharedPreferences();
    dynamic attacksResult = await TornApiCaller.attacks(_userKey).getAttacks;
    if (attacksResult is AttackModel) {
      _attacks.clear();
      attacksResult.attacks.forEach((key, thisAttack) {
        // If someone attacked in stealth, it is of no use to us
        if (thisAttack.attackerName != null) {
          // Determine who's the actual target
          _determineTargetNameId(thisAttack);
          // Determine if attack was won or lost
          _determineAttackWonLost(thisAttack);
          // Approximate target level
          _determineTargetLevel(thisAttack);
          // We are going to loop all the attacks currently available in
          // _attacks and compare it with thisAttack. If the target is the same,
          // we just add the result to the existing one, but do not add a new
          // record. Otherwise, we add the new target.
          _addToAttackSeries(thisAttack);
        }
      });
    }
    sortAttacks(_currentSort);
    notifyListeners();
  }

  void _addToAttackSeries(Attack thisAttack) {
    bool green = false;
    if ((thisAttack.attackInitiated && thisAttack.attackWon) ||
        (!thisAttack.attackInitiated && !thisAttack.attackWon)) {
      green = true;
    }

    if (_attacks.length == 0) {
      // At the beginning the list is empty, so we just add a new target
      thisAttack.attackSeriesGreen.add(green);
      _attacks.add(thisAttack);
    } else {
      bool sameTargetFound = false;
      for (var i = 0; i < _attacks.length; i++) {
        if (_attacks[i].targetId == thisAttack.targetId) {
          // If we have attacked the same person more than one
          // add won/lost to the series list, but then do nothing more
          // (sameTargetFound will avoid that we add a new target)
          sameTargetFound = true;
          _attacks[i].attackSeriesGreen.add(green);
          break;
        }
      }
      if (!sameTargetFound) {
        // Only add a new target if we could find a repetition
        thisAttack.attackSeriesGreen.add(green);
        _attacks.add(thisAttack);
      }
    }
  }

  void _determineAttackWonLost(Attack thisAttack) {
    if (thisAttack.result == 'Lost' || thisAttack.result == 'Stalemate') {
      thisAttack.attackWon = false;
    } else {
      thisAttack.attackWon = true;
    }
  }

  void _determineTargetLevel(Attack thisAttack) {
    // Target level does not come directly from AttacksFull and, in order
    // to avoid getting profiles one by one, we'll have to calculate it.
    // Base respect is level dependent. Very simply, the higher the level
    // of your target, the more respect you will earn.
    // Base respect = Respect gain / modifiers
    if (thisAttack.attackInitiated && thisAttack.attackWon) {
      dynamic respectGain = thisAttack.respectGain;
      if (respectGain is String) {
        respectGain = double.parse(respectGain);
        // Also, standardize respect as double
        thisAttack.respectGain = respectGain;
      }
      double modifiers = thisAttack.modifiers.getTotalModifier;
      if (thisAttack.result == 'Mugged') {
        modifiers *= 0.75;
      }
      double baseRespect = respectGain / modifiers;
      // Base respect = (Ln(level) + 1.0)/4.0
      // From the second formula: Level = e^(Base Respect / 4 - 1)
      double levelD = exp(4 * baseRespect - 1);
      thisAttack.targetLevel = levelD.round();
    } else {
      thisAttack.targetLevel = -1;
    }
  }

  void _determineTargetNameId(Attack thisAttack) {
    if (thisAttack.attackerId.toString() == _ownId) {
      thisAttack.targetName = thisAttack.defenderName;
      thisAttack.targetId = thisAttack.defenderId.toString();
      thisAttack.attackInitiated = true;
    } else {
      thisAttack.targetName = thisAttack.attackerName;
      thisAttack.targetId = thisAttack.attackerId.toString();
      thisAttack.attackInitiated = false;
    }
  }

  void setFilterText(String newWordFilter) {
    _currentWordFilter = newWordFilter;
    notifyListeners();
  }

  void setFilterType(AttackTypeFilter typeFilter) {
    _currentTypeFilter = typeFilter;
    notifyListeners();
  }

  void sortAttacks(AttackSort sortType) {
    _currentSort = sortType;
    switch (sortType) {
      case AttackSort.levelDes:
        _attacks.sort((a, b) => b.targetLevel.compareTo(a.targetLevel));
        break;
      case AttackSort.levelAsc:
        _attacks.sort((a, b) => a.targetLevel.compareTo(b.targetLevel));
        break;
      case AttackSort.respectDes:
        _attacks.sort((a, b) => b.respectGain.compareTo(a.respectGain));
        break;
      case AttackSort.respectAsc:
        _attacks.sort((a, b) => a.respectGain.compareTo(b.respectGain));
        break;
      case AttackSort.dateDes:
        _attacks.sort((a, b) => b.timestampEnded.compareTo(a.timestampEnded));
        break;
      case AttackSort.dateAsc:
        _attacks.sort((a, b) => a.timestampEnded.compareTo(b.timestampEnded));
        break;
    }
    _saveSortSharedPrefs();
    notifyListeners();
  }

  void _saveSortSharedPrefs() {
    String sortToSave;
    switch (_currentSort) {
      case AttackSort.levelDes:
        sortToSave = 'levelDes';
        break;
      case AttackSort.levelAsc:
        sortToSave = 'levelAsc';
        break;
      case AttackSort.respectDes:
        sortToSave = 'respectDes';
        break;
      case AttackSort.respectAsc:
        sortToSave = 'respectDes';
        break;
      case AttackSort.dateAsc:
        sortToSave = 'dateDes';
        break;
      case AttackSort.dateDes:
        sortToSave = 'dateDes';
        break;
    }
    SharedPreferencesModel().setAttackSort(sortToSave);
  }

  Future<void> restoreSharedPreferences() async {
    // User key
    _userKey = await SharedPreferencesModel().getApiKey();
    _ownId = await SharedPreferencesModel().getOwnId();

    // Attack sort
    String attackSort = await SharedPreferencesModel().getAttackSort();
    switch (attackSort) {
      case '':
        _currentSort = AttackSort.levelDes;
        break;
      case 'levelDes':
        _currentSort = AttackSort.levelDes;
        break;
      case 'levelAsc':
        _currentSort = AttackSort.levelAsc;
        break;
      case 'respectDes':
        _currentSort = AttackSort.respectDes;
        break;
      case 'respectAsc':
        _currentSort = AttackSort.respectAsc;
        break;
      case 'nameDes':
        _currentSort = AttackSort.dateDes;
        break;
      case 'nameAsc':
        _currentSort = AttackSort.dateAsc;
        break;
    }
  }
}
