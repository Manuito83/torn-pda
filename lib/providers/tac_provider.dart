// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:

// Project imports:
import 'package:torn_pda/models/chaining/tac/tac_target_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';

class UpdateTargetsResult {
  bool success;
  int numberErrors;
  int numberSuccessful;

  UpdateTargetsResult(
      {required this.success, required this.numberErrors, required this.numberSuccessful,});
}

class TacProvider extends ChangeNotifier {
  List<TacTarget> targetsList = <TacTarget>[];

  getSingleStatus(int index, TargetModel model) async {
    final tac = targetsList.elementAt(index);
    tac.currentLife = model.life!.current;
    tac.maxLife = model.life!.maximum;
    if (model.status!.state == "Hospital") {
      tac.hospital = true;
    } else {
      tac.hospital = false;
    }
    if (model.status!.state == "Abroad") {
      tac.abroad = true;
    } else {
      tac.abroad = false;
    }
    notifyListeners();
  }
}
