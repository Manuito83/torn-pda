import 'package:flutter/material.dart';
import 'package:torn_pda/models/awards/awards_model.dart';

class AwardsProvider extends ChangeNotifier {
  var pinnedAwards = List<Award>();
  var pinnedNames = List<String>();

  addPinned (Award newPin) {
    for (var existing in pinnedAwards) {
      if (existing.name == newPin.name) {
        return;
      }
    }

    pinnedAwards.add(newPin);
    pinnedNames.add(newPin.name);
    notifyListeners();
  }

  removePinned (Award removedPin) {
    for (var existing in pinnedAwards) {
      if (existing.name == removedPin.name) {
        pinnedAwards.remove(existing);
        pinnedNames.remove(existing.name);
        break;
      }
    }
    notifyListeners();
  }
}
