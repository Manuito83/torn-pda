import 'package:flutter/material.dart';
import 'package:torn_pda/models/awards/awards_model.dart';
import 'package:torn_pda/utils/external/yata_comm.dart';

class AwardsProvider extends ChangeNotifier {
  var pinnedAwards = <Award>[];
  var pinnedNames = <String>[];

  Future<bool> addPinned (String apiKey, Award newPin) async {
    var result = await YataComm.getPin(apiKey, newPin.awardKey);
    if (result is YataError) {
      return false;
    }

    var currentAwards = result as Map<String, dynamic>;
    for (var aw in currentAwards["pinnedAwards"]) {
      if (aw == newPin.awardKey) {
        pinnedAwards.add(newPin);
        pinnedNames.add(newPin.name);
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  Future<bool> removePinned (String apiKey, Award removedPin) async {
    var result = await YataComm.getPin(apiKey, removedPin.awardKey);
    if (result is YataError) {
      return false;
    }

    var currentAwards = result as Map<String, dynamic>;
    for (var aw in currentAwards["pinnedAwards"]) {
      if (aw == removedPin.awardKey) return false;
    }

    for (var existing in pinnedAwards) {
      if (existing.name == removedPin.name) {
        pinnedAwards.remove(existing);
        pinnedNames.remove(existing.name);
        break;
      }
    }
    notifyListeners();
    return true;
  }
}
