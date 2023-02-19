import 'dart:async';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/profile/basic_profile_model.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

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
  Function(String url) callbackBrowser;

  List<Stakeout> _stakeouts = <Stakeout>[];
  List<Stakeout> get stakeouts => _stakeouts;
  set stakeouts(List<Stakeout> value) {
    _stakeouts = value;
  }

  List<StakeoutCardDetails> _orderedCardsDetails = <StakeoutCardDetails>[];
  List<StakeoutCardDetails> get orderedCardsDetails => _orderedCardsDetails;
  set orderedCardsDetails(List<StakeoutCardDetails> value) {
    _orderedCardsDetails = value;
  }

  bool _stakeoutsEnabled;
  bool get stakeoutsEnabled => _stakeoutsEnabled;
  set stakeoutsEnabled(bool value) {
    // TODO: we need to update everything quickly...?
    _stakeoutsEnabled = value;
    Prefs().setStakeoutsEnabled(value);
    update();
  }

  int _sleepStakeoutsTime;
  int get sleepStakeoutsTime => _sleepStakeoutsTime;
  set sleepStakeoutsTime(int value) {
    _sleepStakeoutsTime = value;
    Prefs().setStakeoutsSleepTime(value);
    update();
  }

  Timer _stakeoutTimer;

  @override
  void onInit() {
    super.onInit();
    initialise();
  }

  Future initialise() async {
    await _loadPreferences();
    _stakeoutTimer?.cancel();
    _stakeoutTimer = new Timer.periodic(Duration(milliseconds: 2500), (Timer t) {
      _fetchStakeoutsPeriodic();
      _resetSleepTimeIfExpired();
    });
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

  Future<AddStakeoutResult> removeStakeout({@required String removeId}) {
    stakeouts.removeWhere((s) => s.id == removeId);
    savePreferences();
    update();
  }

  void setCardExpanded({@required Stakeout stakeout, @required bool cardExpanded}) {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);
    s.cardExpanded = cardExpanded;
  }

  void setOkay({@required Stakeout stakeout, @required bool okayEnabled}) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);
    s.okayEnabled = okayEnabled;

    if (okayEnabled && !isAnyOptionActive(stakeout: stakeout)) {
      _fetchSingle(stakeout: stakeout);
    }

    savePreferences();
    update();
  }

  void setHospital({@required Stakeout stakeout, @required bool hospitalEnabled}) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);
    s.hospitalEnabled = hospitalEnabled;

    if (hospitalEnabled && !isAnyOptionActive(stakeout: stakeout)) {
      _fetchSingle(stakeout: stakeout);
    }

    savePreferences();
    update();
  }

  bool isAnyOptionActive({@required Stakeout stakeout}) {
    // TODO all categories
    if (stakeout.okayEnabled || stakeout.hospitalEnabled) {
      return true;
    }
    return false;
  }

  void savePreferences() {
    List<String> toSave = [];
    for (Stakeout st in stakeouts) {
      toSave.add(stakeoutToJson(st));
    }
    Prefs().setStakeouts(toSave);
  }

  Future<void> _loadPreferences() async {
    List<String> saved = await Prefs().getStakeouts();
    for (String s in saved) {
      stakeouts.add(stakeoutFromJson(s));
    }

    _stakeoutsEnabled = await Prefs().getStakeoutsEnabled();

    _sleepStakeoutsTime = await Prefs().getStakeoutsSleepTime();
  }

  void sleepStakeouts() {
    sleepStakeoutsTime = DateTime.now().millisecondsSinceEpoch + 600000; // 10 minutes

    BotToast.showText(
      text: "Stakeouts silenced for 10 minutes!",
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.blue,
      duration: const Duration(seconds: 2),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  void disableSleepStakeouts() {
    sleepStakeoutsTime = 0; // 10 minutes

    BotToast.showText(
      text: "Stakeouts alerts re-enabled!",
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.blue,
      duration: const Duration(seconds: 2),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  void _resetSleepTimeIfExpired() {
    if (_sleepStakeoutsTime > 0) {
      if (_sleepStakeoutsTime < DateTime.now().millisecondsSinceEpoch) {
        sleepStakeoutsTime = 0;
      }
    }
  }

  // Returns 0 if stakeouts are not slept, and the timestamp if they are
  int timeUntilStakeoutsSlept() {
    int currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (sleepStakeoutsTime > currentMillis) {
      return sleepStakeoutsTime;
    }
    return 0;
  }

  void _fetchStakeoutsPeriodic() async {
    if (!_stakeoutsEnabled) return;
    int currentMills = DateTime.now().millisecondsSinceEpoch;
    Stakeout nextToUpdate = stakeouts.firstWhere((element) => currentMills - element.lastUpdate > 30000); // 30 sec
    nextToUpdate.lastUpdate = currentMills;

    if (!isAnyOptionActive(stakeout: nextToUpdate)) {
      log("Stakeouts: ${nextToUpdate.name} has no active options");
      return;
    }

    log("Stakeouts: updating ${nextToUpdate.name} @${DateTime.now()}");
    var response = await TornApiCaller().getOtherProfileBasic(playerId: nextToUpdate.id);
    if (response is BasicProfileModel) {
      int currentMills = DateTime.now().millisecondsSinceEpoch;
      if (currentMills > _sleepStakeoutsTime) {
        _alertStakeout(alertStakeout: nextToUpdate, tornProfile: response);
      }
      _updateStakeout(alertStakeout: nextToUpdate, tornProfile: response);
    }
  }

  /// Used when we need to quickly update all properties of a stakeout, since it was inactive before
  _fetchSingle({@required Stakeout stakeout}) async {
    var response = await TornApiCaller().getOtherProfileBasic(playerId: stakeout.id);
    if (response is BasicProfileModel) {
      _updateStakeout(alertStakeout: stakeout, tornProfile: response);
    }
  }

  void _updateStakeout({@required Stakeout alertStakeout, @required BasicProfileModel tornProfile}) {
    // Update current values
    alertStakeout.okayLast = tornProfile.status.state == "Okay";
    alertStakeout.hospitalLast = tornProfile.status.state == "Hospital";
  }

  void _alertStakeout({@required Stakeout alertStakeout, @required BasicProfileModel tornProfile}) {
    List<String> alerts = [];
    List<Icon> icons = <Icon>[];
    // Send alerts
    bool okayNow = tornProfile.status.state == "Okay";
    if (!alertStakeout.okayLast && okayNow) {
      alerts.add("${alertStakeout.name} is now OK!");
      icons.add(Icon(Icons.check, color: Colors.green));
    }

    bool hospitalNow = tornProfile.status.state == "Hospital";
    if (!alertStakeout.hospitalLast && hospitalNow) {
      alerts.add("${alertStakeout.name} has been hospitalized!");
      icons.add(Icon(FontAwesome.ambulance, color: Colors.red, size: 18));
    }

    if (alerts.isNotEmpty) {
      _showAlert(
        text: alerts,
        icon: icons,
        stakeout: alertStakeout,
      );
    }
  }

  void _showAlert({
    @required List<String> text,
    @required List<Icon> icon,
    @required Stakeout stakeout,
  }) {
    BotToast.showCustomNotification(
      animationDuration: Duration(milliseconds: 200),
      animationReverseDuration: Duration(milliseconds: 200),
      duration: Duration(seconds: 4),
      backButtonBehavior: BackButtonBehavior.none,
      toastBuilder: (cancel) {
        return CustomWidget(
          alertStrings: text,
          icons: icon,
          stakeoutId: stakeout.id,
          cancelFunc: cancel,
          sleepStakeouts: sleepStakeouts,
        );
      },
      enableSlideOff: true,
      onlyOne: true,
      crossPage: true,
    );
  }
}

class CustomWidget extends StatefulWidget {
  final List<String> alertStrings;
  final List<Icon> icons;
  final String stakeoutId;
  final CancelFunc cancelFunc;
  final Function sleepStakeouts;

  const CustomWidget({
    Key key,
    @required this.alertStrings,
    @required this.stakeoutId,
    @required this.cancelFunc,
    @required this.icons,
    @required this.sleepStakeouts,
  }) : super(key: key);

  @override
  CustomWidgetState createState() => CustomWidgetState();
}

class CustomWidgetState extends State<CustomWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.blue,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _alertLines(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: const Icon(MdiIcons.cctv),
                  onPressed: () async {
                    var s = Get.put(StakeoutsController());
                    s.callbackBrowser('https://www.torn.com/profiles.php?XID=${widget.stakeoutId}');
                    widget.cancelFunc;
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: widget.cancelFunc,
                ),
                IconButton(
                  icon: const Icon(Icons.timer_off_outlined),
                  onPressed: widget.sleepStakeouts,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Column _alertLines() {
    List<Widget> lines = <Widget>[];
    for (var i = 0; i < widget.alertStrings.length; i++) {
      lines.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.icons[i],
            SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.alertStrings[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(children: lines);
  }
}
