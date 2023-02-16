import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/profile/basic_profile_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/api_caller.dart';

class StakeoutCardDetails {
  int cardPosition;
  int playerId;
  String name;
  String personalNote;
  String personalNoteColor;
}

class AddStakeoutResult {
  bool success;
  String name;
  String id;
  String error;

  AddStakeoutResult({
    @required this.success,
    this.name = "",
    this.id = "",
    this.error = "",
  });
}

class StakeoutsController extends GetxController {
  //UserController _u = Get.put(UserController());

  List<Stakeout> stakeouts = <Stakeout>[];
  List<StakeoutCardDetails> orderedCardsDetails = <StakeoutCardDetails>[];

  @override
  void onInit() {
    super.onInit();
    initialise();
  }

  Future initialise() async {
    //
    update();
  }

  Future<AddStakeoutResult> addStakeout({@required String inputId}) async {
    // Return custom error code if stakeout already exists
    for (Stakeout st in stakeouts) {
      if (st.id.toString() == inputId) {
        return AddStakeoutResult(
          success: false,
          error: "already exists!",
        );
      }
    }

    dynamic basicModel = await TornApiCaller().getOtherProfileBasic(playerId: inputId);

    if (basicModel is BasicProfileModel) {
      stakeouts.add(
        Stakeout(
          id: basicModel.playerId.toString(),
          name: basicModel.name,
          okayNow: basicModel.status.description == "Okay",
        ),
      );
      savePreferences();
      update();
      return AddStakeoutResult(
        success: true,
        name: basicModel.name,
        id: basicModel.playerId.toString(),
      );
    } else {
      var myError = basicModel as ApiError;
      return AddStakeoutResult(
        success: false,
        error: myError.errorReason,
      );
    }
  }

  Future<AddStakeoutResult> removeStakeout({@required String removeId}) async {
    stakeouts.removeWhere((s) => s.id == removeId);
    savePreferences();
    update();
  }

  void savePreferences() {
    // TODO
  }
}
