// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/models/awards/awards_model.dart';
import 'package:torn_pda/utils/external/yata_comm.dart';

class AwardsProvider extends ChangeNotifier {
  var pinnedAwards = <Award>[];
  var pinnedNames = <String?>[];

  Future<bool> addPinned (Award newPin) async {
    var result = await YataComm.getPin(newPin.awardKey);
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

  Future<bool> removePinned (Award removedPin) async {
    var result = await YataComm.getPin(removedPin.awardKey);
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
