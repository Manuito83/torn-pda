// Dart imports:
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Package imports:
import 'package:http/http.dart' as http;
// Project imports:
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/target_backup_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/chaining/target_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/models/chaining/yata/yata_targets_export.dart';
import 'package:torn_pda/models/chaining/yata/yata_targets_import.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class AddTargetResult {
  bool success;
  String? errorReason = "";
  String? targetId = "";
  String? targetName = "";

  AddTargetResult({required this.success, this.errorReason, this.targetId, this.targetName});
}

class UpdateTargetsResult {
  bool success;
  int numberErrors;
  int numberSuccessful;

  UpdateTargetsResult({required this.success, required this.numberErrors, required this.numberSuccessful});
}

class TargetsProvider extends ChangeNotifier {
  List<TargetModel> _targets = [];
  UnmodifiableListView<TargetModel> get allTargets => UnmodifiableListView(_targets);

  List<TargetModel> _oldTargetsList = [];

  final UserController _u = Get.find<UserController>();

  String _currentWordFilter = '';
  String get currentWordFilter => _currentWordFilter;

  List<String> _currentColorFilterOut = [];
  List<String> get currentColorFilterOut => _currentColorFilterOut;

  TargetSortType? currentSort;

  TargetsProvider() {
    restorePreferences();
  }

  @override
  void dispose() {
    _targets.clear();
    _oldTargetsList.clear();
    super.dispose();
  }

  /// If providing [notes] or [notesColor], ensure that they are within 200
  /// chars and of an acceptable color (green, blue, red).
  Future<AddTargetResult> addTarget({
    required String? targetId,
    required dynamic attacks,
    String? notes = '',
    String? notesColor = '',
  }) async {
    try {
      // Validate target doesn't exist
      if (_targets.any((tar) => tar.playerId.toString() == targetId)) {
        return AddTargetResult(
          success: false,
          errorReason: 'Target already exists!',
        );
      }

      final dynamic myNewTargetModel = await ApiCallsV1.getTarget(playerId: targetId);

      if (myNewTargetModel is TargetModel) {
        _getRespectFF(attacks, myNewTargetModel);
        _getTargetFaction(myNewTargetModel);
        myNewTargetModel.personalNote = notes;
        myNewTargetModel.personalNoteColor = notesColor;
        myNewTargetModel.hospitalSort = targetsSortHospitalTime(myNewTargetModel);
        myNewTargetModel.timeAdded = DateTime.now().millisecondsSinceEpoch;

        // Parse bounty ammount if it exists
        if (myNewTargetModel.basicicons?.icon13 != null) {
          myNewTargetModel.bountyAmount = _getBountyAmount(myNewTargetModel);
        }

        _targets.add(myNewTargetModel);
        await await _saveTargetsSharedPrefs();
        sortTargets(currentSort);
        notifyListeners();

        return AddTargetResult(
          success: true,
          targetId: myNewTargetModel.playerId.toString(),
          targetName: myNewTargetModel.name,
        );
      } else {
        // myNewTargetModel is ApiError
        final myError = myNewTargetModel as ApiError;
        notifyListeners();
        return AddTargetResult(
          success: false,
          errorReason: myError.errorReason,
        );
      }
    } catch (e) {
      notifyListeners();
      return AddTargetResult(
        success: false,
        errorReason: e.toString(),
      );
    }
  }

  /// The result of this needs to be passed to several functions, so that we don't need
  /// to call several times if looping. Example: we can loop the addTarget method 100 times, but
  /// the attack variable we provide is the same and we only requested it once.
  dynamic getAttacks() async {
    return await ApiCallsV1.getAttacks();
  }

  void _getTargetFaction(TargetModel myNewTargetModel) {
    if (myNewTargetModel.faction!.factionId != 0) {
      myNewTargetModel.hasFaction = true;
    } else {
      myNewTargetModel.hasFaction = false;
    }
  }

  void _getRespectFF(
    AttackModel attackModel,
    TargetModel myNewTargetModel, {
    double? oldRespect = -1,
    double? oldFF = -1,
  }) {
    double respect = -1;
    double? fairFight = -1; // Unknown
    List<bool> userWonOrDefended = <bool>[];
    attackModel.attacks!.forEach((key, value) {
      // We look for the our target in the the attacks list
      if (myNewTargetModel.playerId == value.defenderId || myNewTargetModel.playerId == value.attackerId) {
        // Only update if we have still not found a positive value (because
        // we lost or we have no records)
        if (value.respectGain > 0) {
          fairFight = value.modifiers!.fairFight;
          respect = fairFight! * 0.25 * (log(myNewTargetModel.level!) + 1);
        } else if (respect == -1) {
          respect = 0;
          fairFight = 1.00;
        }

        if (myNewTargetModel.playerId == value.defenderId) {
          if (value.result == Result.LOST || value.result == Result.STALEMATE) {
            // If we attacked and lost
            userWonOrDefended.add(false);
          } else {
            userWonOrDefended.add(true);
          }
        } else if (myNewTargetModel.playerId == value.attackerId) {
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
      myNewTargetModel.respectGain = respect;
    } else if (respect == -1 && oldRespect != -1) {
      // If it is unknown BUT we have a previously recorded value, we need to provide it for the new target (or
      // otherwise it will default to -1). This can happen when the last attack on this target is not within the
      // last 100 total attacks and therefore it's not returned in the attackModel.
      myNewTargetModel.respectGain = oldRespect;
    }

    // Same as above
    if (fairFight != -1) {
      myNewTargetModel.fairFight = fairFight;
    } else if (fairFight == -1 && oldFF != -1) {
      myNewTargetModel.fairFight = oldFF;
    }

    if (userWonOrDefended.isNotEmpty) {
      myNewTargetModel.userWonOrDefended = userWonOrDefended.first;
    } else {
      myNewTargetModel.userWonOrDefended = true; // Placeholder
    }
  }

  void setTargetNote(TargetModel? changedTarget, String? note, String? color) async {
    // We are not updating the target directly, but instead looping for the correct one because
    // after an attack the targets get updated several times: if the user wants to change the note
    // right after the attack, the good target might have been replaced and the note does not get
    // updated. Therefore, we just loop whenever the user submits the new text.
    for (final tar in _targets) {
      if (tar.playerId == changedTarget!.playerId) {
        tar.personalNote = note;
        tar.personalNoteColor = color;
        await _saveTargetsSharedPrefs();
        notifyListeners();
        break;
      }
    }
  }

  Future<bool> updateTarget({
    required TargetModel targetToUpdate,
    required dynamic attacks,
  }) async {
    targetToUpdate.isUpdating = true;
    notifyListeners();

    try {
      final dynamic myUpdatedTargetModel = await ApiCallsV1.getTarget(playerId: targetToUpdate.playerId.toString());
      if (myUpdatedTargetModel is TargetModel) {
        _getRespectFF(
          attacks,
          myUpdatedTargetModel,
          oldRespect: targetToUpdate.respectGain,
          oldFF: targetToUpdate.fairFight,
        );
        _getTargetFaction(myUpdatedTargetModel);
        _targets[_targets.indexOf(targetToUpdate)] = myUpdatedTargetModel;
        final newTarget = _targets[_targets.indexOf(myUpdatedTargetModel)];
        _updateResultAnimation(newTarget, true);
        newTarget.personalNote = targetToUpdate.personalNote;
        newTarget.personalNoteColor = targetToUpdate.personalNoteColor;
        newTarget.lastUpdated = DateTime.now();
        newTarget.hospitalSort = targetsSortHospitalTime(targetToUpdate);

        // Parse bounty ammount if it exists
        if (myUpdatedTargetModel.basicicons?.icon13 != null) {
          newTarget.bountyAmount = _getBountyAmount(myUpdatedTargetModel);
        }

        await _saveTargetsSharedPrefs();
        return true;
      } else {
        // myUpdatedTargetModel is ApiError
        targetToUpdate.isUpdating = false;
        _updateResultAnimation(targetToUpdate, false);
        return false;
      }
    } catch (e) {
      targetToUpdate.isUpdating = false;
      _updateResultAnimation(targetToUpdate, false);
      return false;
    }
  }

  Future<UpdateTargetsResult> updateAllTargets() async {
    bool wasSuccessful = true;
    int numberOfErrors = 0;
    int numberSuccessful = 0;
    // Activate every single update icon
    for (final tar in _targets) {
      tar.isUpdating = true;
    }
    notifyListeners();
    // Then start the real update
    final dynamic attacks = await getAttacks();
    for (var i = 0; i < _targets.length; i++) {
      try {
        final dynamic myUpdatedTargetModel = await ApiCallsV1.getTarget(playerId: _targets[i].playerId.toString());
        if (myUpdatedTargetModel is TargetModel) {
          _getRespectFF(
            attacks,
            myUpdatedTargetModel,
            oldRespect: _targets[i].respectGain,
            oldFF: _targets[i].fairFight,
          );
          _getTargetFaction(myUpdatedTargetModel);
          final notes = _targets[i].personalNote;
          final notesColor = _targets[i].personalNoteColor;
          _targets[i] = myUpdatedTargetModel;
          _updateResultAnimation(_targets[i], true);
          _targets[i].personalNote = notes;
          _targets[i].personalNoteColor = notesColor;
          _targets[i].lastUpdated = DateTime.now();
          _targets[i].hospitalSort = targetsSortHospitalTime(_targets[i]);

          // Parse bounty ammount if it exists
          if (myUpdatedTargetModel.basicicons?.icon13 != null) {
            _targets[i].bountyAmount = _getBountyAmount(myUpdatedTargetModel);
          }

          await _saveTargetsSharedPrefs();
          numberSuccessful++;
        } else {
          // myUpdatedTargetModel is ApiError
          _updateResultAnimation(_targets[i], false);
          _targets[i].isUpdating = false;
          numberOfErrors++;
          wasSuccessful = false;
        }
        // Wait for the API limit (100 calls/minute)
        if (_targets.length > 75) {
          await Future.delayed(const Duration(seconds: 1), () {});
        }
      } catch (e) {
        _updateResultAnimation(_targets[i], false);
        _targets[i].isUpdating = false;
        numberOfErrors++;
        wasSuccessful = false;
      }
    }
    return UpdateTargetsResult(
      success: wasSuccessful,
      numberErrors: numberOfErrors,
      numberSuccessful: numberSuccessful,
    );
  }

  Future<void> updateTargetsAfterAttacks({required List<String> lastAttackedTargets}) async {
    // Copies the list locally, as it will be erased by the webview after it has been sent
    // so that other attacks are possible
    List<String> lastAttackedCopy = List<String>.from(lastAttackedTargets);
    await Future.delayed(const Duration(seconds: 15));

    // Get attacks full to use later
    final dynamic attacks = await getAttacks();

    // Local function for the update of several targets after attacking
    // Local function for the update of several targets after attacking
    for (final tar in _targets) {
      for (var i = 0; i < lastAttackedCopy.length; i++) {
        if (tar.playerId.toString() == lastAttackedCopy[i]) {
          tar.isUpdating = true;
          notifyListeners();
          try {
            final dynamic attackedTarget = await ApiCallsV1.getTarget(playerId: tar.playerId.toString());
            if (attackedTarget is TargetModel) {
              final targetIndex = _targets.indexOf(tar);
              _getRespectFF(
                attacks,
                attackedTarget,
                oldRespect: _targets[targetIndex].respectGain,
                oldFF: _targets[targetIndex].fairFight,
              );
              _getTargetFaction(attackedTarget);

              // Update the existing target directly
              _targets[targetIndex] = attackedTarget;
              _targets[targetIndex].personalNote = tar.personalNote;
              _targets[targetIndex].personalNoteColor = tar.personalNoteColor;
              _targets[targetIndex].lastUpdated = DateTime.now();
              _targets[targetIndex].hospitalSort = targetsSortHospitalTime(attackedTarget);

              // Parse bounty ammount if it exists
              if (attackedTarget.basicicons?.icon13 != null) {
                _targets[targetIndex].bountyAmount = _getBountyAmount(attackedTarget);
              }

              _updateResultAnimation(_targets[targetIndex], true);
              await _saveTargetsSharedPrefs();
            } else {
              tar.isUpdating = false;
              _updateResultAnimation(tar, false);
            }
          } catch (e) {
            tar.isUpdating = false;
            _updateResultAnimation(tar, false);
          }
          if (lastAttackedCopy.length > 40) {
            await Future.delayed(const Duration(seconds: 1), () {});
          }
        }
      }
    }
  }

  Future<void> _updateResultAnimation(TargetModel target, bool success) async {
    if (success) {
      target.justUpdatedWithSuccess = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 5), () {});
      target.justUpdatedWithSuccess = false;
      notifyListeners();
    } else {
      target.justUpdatedWithError = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 15), () {});
      target.justUpdatedWithError = false;
      notifyListeners();
    }
  }

  Future deleteTarget(TargetModel target) async {
    _oldTargetsList = List.from(_targets);
    final wasRemoved = _targets.remove(target);

    if (wasRemoved) {
      await await _saveTargetsSharedPrefs();
      notifyListeners();
      return true;
    } else {
      _oldTargetsList.clear();
      return false;
    }
  }

  void deleteTargetById(String? removedId) async {
    _oldTargetsList = List<TargetModel>.from(_targets);
    for (final tar in _targets) {
      if (tar.playerId.toString() == removedId) {
        _targets.remove(tar);
        break;
      }
    }
    notifyListeners();
    await _saveTargetsSharedPrefs();
  }

  void restoredDeleted() {
    _targets = List<TargetModel>.from(_oldTargetsList);
    _oldTargetsList.clear();
    notifyListeners();
  }

  /// CAREFUL!
  void wipeAllTargets() async {
    _targets.clear();
    await _saveTargetsSharedPrefs();
    notifyListeners();
  }

  void setFilterText(String newFilter) {
    _currentWordFilter = newFilter;
    notifyListeners();
  }

  void setFilterColorsOut(List<String> newFilter) {
    _currentColorFilterOut = newFilter;
    Prefs().setTargetsColorFilter(_currentColorFilterOut);
    notifyListeners();
  }

  void sortTargets(TargetSortType? sortType) async {
    currentSort = sortType;
    switch (sortType!) {
      case TargetSortType.levelDes:
        _targets.sort((a, b) => b.level!.compareTo(a.level!));
      case TargetSortType.levelAsc:
        _targets.sort((a, b) => a.level!.compareTo(b.level!));
      case TargetSortType.respectDes:
        _targets.sort((a, b) => b.respectGain!.compareTo(a.respectGain!));
      case TargetSortType.respectAsc:
        _targets.sort((a, b) => a.respectGain!.compareTo(b.respectGain!));
      case TargetSortType.ffDes:
        _targets.sort((a, b) => b.fairFight!.compareTo(a.fairFight!));
      case TargetSortType.ffAsc:
        _targets.sort((a, b) => a.fairFight!.compareTo(b.fairFight!));
      case TargetSortType.nameDes:
        _targets.sort((a, b) => b.name!.toLowerCase().compareTo(a.name!.toLowerCase()));
      case TargetSortType.nameAsc:
        _targets.sort((a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));
      case TargetSortType.lifeDes:
        _targets.sort((a, b) => b.life!.current!.compareTo(a.life!.current!));
      case TargetSortType.lifeAsc:
        _targets.sort((a, b) => a.life!.current!.compareTo(b.life!.current!));
      case TargetSortType.hospitalDes:
        _targets.sort((a, b) {
          return b.hospitalSort!.compareTo(a.hospitalSort!);
        });
      case TargetSortType.hospitalAsc:
        _targets.sort((a, b) {
          // First sort by hospitalSort
          if (a.hospitalSort! > 0 && b.hospitalSort! > 0) {
            return a.hospitalSort!.compareTo(b.hospitalSort!);
          } else if (a.hospitalSort! > 0) {
            return -1;
          } else if (b.hospitalSort! > 0) {
            return 1;
          } else {
            // If both hospitalSort values are 0, sort by name
            return a.name!.toLowerCase().compareTo(b.name!.toLowerCase());
          }
        });
      case TargetSortType.colorDes:
        _targets.sort((a, b) => b.personalNoteColor!.toLowerCase().compareTo(a.personalNoteColor!.toLowerCase()));
      case TargetSortType.colorAsc:
        _targets.sort((a, b) => a.personalNoteColor!.toLowerCase().compareTo(b.personalNoteColor!.toLowerCase()));
      case TargetSortType.onlineDes:
        _targets.sort((a, b) => b.lastAction!.timestamp!.compareTo(a.lastAction!.timestamp!));
      case TargetSortType.onlineAsc:
        _targets.sort((a, b) => a.lastAction!.timestamp!.compareTo(b.lastAction!.timestamp!));
      case TargetSortType.notesDes:
        _targets.sort((a, b) => b.personalNote!.toLowerCase().compareTo(a.personalNote!.toLowerCase()));
      case TargetSortType.notesAsc:
        _targets.sort((a, b) {
          if (a.personalNote!.isEmpty && b.personalNote!.isNotEmpty) {
            return 1;
          } else if (a.personalNote!.isNotEmpty && b.personalNote!.isEmpty) {
            return -1;
          } else if (a.personalNote!.isEmpty && b.personalNote!.isEmpty) {
            return 0;
          } else {
            return a.personalNote!.toLowerCase().compareTo(b.personalNote!.toLowerCase());
          }
        });
      case TargetSortType.bounty:
        for (var t in _targets) {
          t.bountyAmount ??= 0;
        }
        _targets.sort((a, b) {
          return b.bountyAmount!.compareTo(a.bountyAmount!);
        });
      case TargetSortType.timeAddedDes:
        _targets.sort((a, b) {
          return b.timeAdded.compareTo(a.timeAdded);
        });
      case TargetSortType.timeAddedAsc:
        _targets.sort((a, b) {
          return a.timeAdded.compareTo(b.timeAdded);
        });
    }
    _saveSortSharedPrefs();
    await _saveTargetsSharedPrefs();
    notifyListeners();
  }

  int getTargetNumber() {
    return _targets.length;
  }

  String exportTargets() {
    final output = <TargetBackup>[];
    for (final tar in _targets) {
      final export = TargetBackup();
      export.id = tar.playerId;
      export.notes = tar.personalNote;
      export.notesColor = tar.personalNoteColor;
      output.add(export);
    }
    return targetsBackupModelToJson(TargetsBackupModel(targetBackup: output));
  }

  Future _saveTargetsSharedPrefs() async {
    List<String> newPrefs = <String>[];
    for (final tar in _targets) {
      newPrefs.add(targetModelToJson(tar));
    }
    await Prefs().setTargetsList(newPrefs);
  }

  void _saveSortSharedPrefs() {
    late String sortToSave;
    switch (currentSort!) {
      case TargetSortType.levelDes:
        sortToSave = 'levelDes';
      case TargetSortType.levelAsc:
        sortToSave = 'levelAsc';
      case TargetSortType.respectDes:
        sortToSave = 'respectDes';
      case TargetSortType.respectAsc:
        sortToSave = 'respectAsc';
      case TargetSortType.ffDes:
        sortToSave = 'ffDes';
      case TargetSortType.ffAsc:
        sortToSave = 'ffAsc';
      case TargetSortType.nameDes:
        sortToSave = 'nameDes';
      case TargetSortType.nameAsc:
        sortToSave = 'nameAsc';
      case TargetSortType.lifeDes:
        sortToSave = 'lifeDes';
      case TargetSortType.lifeAsc:
        sortToSave = 'lifeAsc';
      case TargetSortType.hospitalDes:
        sortToSave = 'hospitalDes';
      case TargetSortType.hospitalAsc:
        sortToSave = 'hospitalAsc';
      case TargetSortType.colorDes:
        sortToSave = 'colorDes';
      case TargetSortType.colorAsc:
        sortToSave = 'colorAsc';
      case TargetSortType.onlineDes:
        sortToSave = 'onlineDes';
      case TargetSortType.onlineAsc:
        sortToSave = 'onlineAsc';
      case TargetSortType.notesDes:
        sortToSave = 'notesDes';
      case TargetSortType.notesAsc:
        sortToSave = 'notesAsc';
      case TargetSortType.bounty:
        sortToSave = 'bounty';
      case TargetSortType.timeAddedDes:
        sortToSave = 'timeAddedDes';
      case TargetSortType.timeAddedAsc:
        sortToSave = 'timeAddedAsc';
    }
    Prefs().setTargetsSort(sortToSave);
  }

  Future<void> restorePreferences() async {
    // Target list
    bool needToSave = false;
    List<String> jsonTargets = await Prefs().getTargetsList();
    for (final jTar in jsonTargets) {
      final thisTarget = targetModelFromJson(jTar);

      // In v1.8.5 we change from blue to orange and we need to do the conversion
      // here. This can be later removed safely at some point.
      if (thisTarget.personalNoteColor == "blue") {
        thisTarget.personalNoteColor = "orange";
        needToSave = true;
      }

      // In v2.3.0 we adapt colors to be as per YATA, with black/white sorting at the end.
      // This can be later removed safely at some point.
      if (thisTarget.personalNoteColor == "") {
        thisTarget.personalNoteColor = "z";
        needToSave = true;
      }

      _targets.add(thisTarget);
    }

    if (needToSave) {
      await _saveTargetsSharedPrefs();
    }

    // Target sort
    final String targetSort = await Prefs().getTargetsSort();
    switch (targetSort) {
      case '':
        currentSort = TargetSortType.levelDes;
      case 'levelDes':
        currentSort = TargetSortType.levelDes;
      case 'levelAsc':
        currentSort = TargetSortType.levelAsc;
      case 'respectDes':
        currentSort = TargetSortType.respectDes;
      case 'respectAsc':
        currentSort = TargetSortType.respectAsc;
      case 'ffDes':
        currentSort = TargetSortType.ffDes;
      case 'ffAsc':
        currentSort = TargetSortType.ffAsc;
      case 'nameDes':
        currentSort = TargetSortType.nameDes;
      case 'nameAsc':
        currentSort = TargetSortType.nameAsc;
      case 'colorAsc':
        currentSort = TargetSortType.colorAsc;
      case 'colorDes':
        currentSort = TargetSortType.colorDes;
      case 'onlineDes':
        currentSort = TargetSortType.onlineDes;
      case 'onlineAsc':
        currentSort = TargetSortType.onlineAsc;
      case 'bounty':
        currentSort = TargetSortType.bounty;
      case 'timeAddedDes':
        currentSort = TargetSortType.timeAddedDes;
      case 'timeAddedAsc':
        currentSort = TargetSortType.timeAddedAsc;
    }

    // Targets color filter
    _currentColorFilterOut = await Prefs().getTargetsColorFilter();

    // Apply the restored sort if we have targets
    if (_targets.isNotEmpty && currentSort != null) {
      sortTargets(currentSort);
    } else {
      // Notification only if we didn't call sortTargets (which already calls notifyListeners)
      notifyListeners();
    }
  }

  // SERVER BACKUP RESTORE
  Future<void> restoreTargetsFromServerSave({required List<String> backup, required bool overwritte}) async {
    if (overwritte) {
      _targets.clear();
    }

    var filteredBackup = backup.where((bTar) {
      var backupTarget = targetModelFromJson(bTar);
      return !_targets.any((local) => local.playerId == backupTarget.playerId);
    }).toList();

    for (var lala in filteredBackup) {
      _targets.add(targetModelFromJson(lala));
    }

    await _saveTargetsSharedPrefs();

    // Apply current sort to the restored targets
    if (_targets.isNotEmpty && currentSort != null) {
      sortTargets(currentSort);
    } else {
      notifyListeners();
    }
  }

  // Bounty calculation
  int? _getBountyAmount(TargetModel myUpdatedTargetModel) {
    RegExp amountRegex = RegExp(r"\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?");
    Match? match = amountRegex.firstMatch(myUpdatedTargetModel.basicicons!.icon13!);
    if (match != null) {
      String amountStr = match.group(0)!;
      amountStr = amountStr.replaceAll(",", "").replaceAll("\$", "");
      return int.tryParse(amountStr);
    }
    return null;
  }

  // YATA SYNC
  Future<YataTargetsImportModel> getTargetsFromYata() async {
    try {
      final response = await http.get(
        Uri.parse('https://yata.yt/api/v1/targets/export/?key=${_u.alternativeYataKey}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return yataTargetsImportModelFromJson(response.body);
      } else {
        if (response.body.contains("Player not found")) {
          return YataTargetsImportModel()..errorPlayer = true;
        } else {
          return YataTargetsImportModel()
            ..errorConnection = true
            ..errorReason = response.statusCode.toString();
        }
      }
    } catch (e) {
      return YataTargetsImportModel()..errorConnection = true;
    }
  }

  Future<String> postTargetsToYata({
    required List<TargetsOnlyLocal> onlyLocal,
    required List<TargetsBothSides> bothSides,
  }) async {
    final modelOut = YataTargetsExportModel();
    modelOut.key = _u.alternativeYataKey;
    //modelOut.user = "Torn PDA $appVersion";

    final targets = <String?, YataExportTarget>{};
    for (final localTarget in onlyLocal) {
      // Max chars in Yata notes is 128
      if (localTarget.noteLocal!.length > 128) {
        localTarget.noteLocal = localTarget.noteLocal!.substring(0, 127);
      }
      final exportDetails = YataExportTarget()
        ..note = localTarget.noteLocal
        ..color = localTarget.colorLocal;
      targets.addAll({localTarget.id: exportDetails});
    }
    for (final bothSidesTarget in bothSides) {
      // Max chars in Yata notes is 128
      if (bothSidesTarget.noteLocal!.length > 128) {
        bothSidesTarget.noteLocal = bothSidesTarget.noteLocal!.substring(0, 127);
      }
      final exportDetails = YataExportTarget()
        ..note = bothSidesTarget.noteLocal
        ..color = bothSidesTarget.colorLocal;
      targets.addAll({bothSidesTarget.id: exportDetails});
    }
    modelOut.targets = targets;

    final bodyOut = yataTargetsExportModelToJson(modelOut);

    try {
      final response = await http
          .post(
            Uri.parse('https://yata.yt/api/v1/targets/import/'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: bodyOut,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);
        var answer = result.values.first;
        if (answer.contains("No new targets added") || answer.contains("You added")) {
          answer += ". Any existing notes and colors have been exported and overwritten in YATA";
        }

        return answer;
      } else {
        //return "";
        return "Error: $e"; // Returns full error to player (in case YATA is down, etc.)
      }
    } catch (e) {
      //return "";
      return "Error: $e"; // Returns full error to player (in case YATA is down, etc.)
    }
  }

  int targetsSortHospitalTime(TargetModel myNewTargetModel) {
    if (myNewTargetModel.status!.state == "Hospital") {
      return myNewTargetModel.status!.until!;
    }
    return 0;
  }
}
