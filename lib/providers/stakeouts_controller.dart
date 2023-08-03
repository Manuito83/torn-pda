import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/profile/basic_profile_model.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

// TODO: useful?
class StakeoutCardDetails {
  int? cardPosition;
  int? playerId;
  String? name;
  String? personalNote;
  String? personalNoteColor;
}

class AddStakeoutResult {
  bool success;
  String? name;
  String id;
  String error;

  AddStakeoutResult({
    required this.success,
    this.name = "",
    this.id = "",
    this.error = "",
  });
}

class StakeoutsController extends GetxController {
  //UserController _u = Get.put(UserController());
  late Function(String url) callbackBrowser;

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

  bool? _stakeoutsEnabled;
  bool? get stakeoutsEnabled => _stakeoutsEnabled;
  enableStakeOuts() async {
    // Quickly update active stakeouts that have not been updated in 30 seconds
    int millis = DateTime.now().millisecondsSinceEpoch;
    bool anySuccess = false;
    for (Stakeout s in stakeouts) {
      if (isAnyOptionActive(stakeout: s) && millis - s.lastFetch! > 30000) {
        var success = await _fetchSingle(stakeout: s);
        if (success) {
          anySuccess = true;
        }
      }
    }

    if (!anySuccess) {
      BotToast.showText(
        text: "Stakeouts have been enabled but targets could not be updated (API returned error).\n\n"
            "Be aware that you might get false notifications when API information is regained.",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.orange[800]!,
        duration: const Duration(seconds: 8),
        contentPadding: const EdgeInsets.all(10),
      );
    }

    _stakeoutsEnabled = true;
    Prefs().setStakeoutsEnabled(true);
    update();
  }

  disableStakeouts() {
    _stakeoutsEnabled = false;
    Prefs().setStakeoutsEnabled(false);
    update();
  }

  late int _stakeoutsSleepTime;
  int get stakeoutsSleepTime => _stakeoutsSleepTime;
  set stakeoutsSleepTime(int value) {
    _stakeoutsSleepTime = value;
    Prefs().setStakeoutsSleepTime(value);
    update();
  }

  Timer? _stakeoutTimer;
  void startTimer() {
    _stakeoutTimer?.cancel();
    _stakeoutTimer = new Timer.periodic(Duration(milliseconds: 4000), (Timer t) {
      _fetchStakeoutsPeriodic();
      _resetSleepTimeIfExpired();
    });
  }

  void stopTimer() {
    _stakeoutTimer?.cancel();
  }

  int _fetchMinutesDelayLimit = 60;
  int get fetchMinutesDelayLimit => _fetchMinutesDelayLimit;
  set fetchMinutesDelayLimit(int value) {
    _fetchMinutesDelayLimit = value;
    Prefs().setStakeoutsFetchDelayLimit(value);
  }

  @override
  void onInit() {
    super.onInit();
    initialise();
  }

  Future initialise() async {
    await _loadPreferences();
    startTimer();
    update();
  }

  Future<AddStakeoutResult> addStakeout({required String inputId}) async {
    // Return custom error code if stakeout already exists
    for (Stakeout st in stakeouts) {
      if (st.id.toString() == inputId) {
        return AddStakeoutResult(
          success: false,
          error: "already exists!",
        );
      }
    }

    dynamic basicModel = await Get.find<ApiCallerController>().getOtherProfileBasic(playerId: inputId);

    if (basicModel is BasicProfileModel) {
      int millis = DateTime.now().millisecondsSinceEpoch;
      stakeouts.add(
        Stakeout(
          id: basicModel.playerId.toString(),
          name: basicModel.name,
          lastFetch: millis,
          lastPass: millis,
          status: basicModel.status,
          lastAction: basicModel.lastAction,
          okayLast: basicModel.status!.state == "Okay",
          hospitalLast: basicModel.status!.state == "Hospital",
          revivableLast: basicModel.revivable == 1,
          landedLast: basicModel.status!.state != "Traveling",
          onlineLast: basicModel.lastAction!.status == "Online",
          lifeBelowPercentageLast: basicModel.life!.current! < 50,
          lifeBelowPercentageLimit: 50,
          offlineLongerThanLast: _getOfflineTimeInHours(lastAction: basicModel.lastAction!) < 2,
          offlineLongerThanLimit: 2,
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

  void removeStakeout({required String? removeId}) {
    stakeouts.removeWhere((s) => s.id == removeId);
    savePreferences();
    update();
  }

  void setCardExpanded({required Stakeout? stakeout, required bool cardExpanded}) {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);
    s.cardExpanded = cardExpanded;
  }

  void setOkay({required Stakeout? stakeout, required bool okayEnabled}) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);

    if (okayEnabled && !isAnyOptionActive(stakeout: stakeout!)) {
      _fetchSingle(stakeout: stakeout);
    }

    s.okayEnabled = okayEnabled;
    savePreferences();
    update();
  }

  void setHospital({required Stakeout? stakeout, required bool hospitalEnabled}) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);

    if (hospitalEnabled && !isAnyOptionActive(stakeout: stakeout!)) {
      _fetchSingle(stakeout: stakeout);
    }

    s.hospitalEnabled = hospitalEnabled;
    savePreferences();
    update();
  }

  void setRevivable({required Stakeout? stakeout, required bool revivableEnabled}) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);

    if (revivableEnabled && !isAnyOptionActive(stakeout: stakeout!)) {
      _fetchSingle(stakeout: stakeout);
    }

    s.revivableEnabled = revivableEnabled;
    savePreferences();
    update();
  }

  void setLanded({required Stakeout? stakeout, required bool landedEnabled}) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);

    if (landedEnabled && !isAnyOptionActive(stakeout: stakeout!)) {
      _fetchSingle(stakeout: stakeout);
    }

    s.landedEnabled = landedEnabled;
    savePreferences();
    update();
  }

  void setOnline({required Stakeout? stakeout, required bool onlineEnabled}) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);

    if (onlineEnabled && !isAnyOptionActive(stakeout: stakeout!)) {
      _fetchSingle(stakeout: stakeout);
    }

    s.onlineEnabled = onlineEnabled;
    savePreferences();
    update();
  }

  void setLifePercentageEnabled({
    required Stakeout? stakeout,
    required bool lifePercentageEnabled,
  }) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);

    if (lifePercentageEnabled && !isAnyOptionActive(stakeout: stakeout!)) {
      _fetchSingle(stakeout: stakeout);
    }

    s.lifeBelowPercentageEnabled = lifePercentageEnabled;
    savePreferences();
    update();
  }

  void setLifePercentageLimit({
    required Stakeout? stakeout,
    required int? percentage,
  }) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);
    s.lifeBelowPercentageLimit = percentage;
    savePreferences();
    update();
  }

  void setOfflineLongerThanEnabled({
    required Stakeout? stakeout,
    required bool offlineLongerThanEnabled,
  }) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);

    if (offlineLongerThanEnabled && !isAnyOptionActive(stakeout: stakeout!)) {
      _fetchSingle(stakeout: stakeout);
    }

    s.offlineLongerThanEnabled = offlineLongerThanEnabled;
    savePreferences();
    update();
  }

  void setOfflineLongerThanLimit({
    required Stakeout? stakeout,
    required int? hours,
  }) async {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);
    s.offlineLongerThanLimit = hours;
    savePreferences();
    update();
  }

  int _getOfflineTimeInHours({required LastAction lastAction}) {
    if (lastAction.status != "Offline") {
      return 0;
    }

    int offlineTimestamp = lastAction.timestamp! * 1000;
    int currentMillis = DateTime.now().millisecondsSinceEpoch;
    int diff = currentMillis - offlineTimestamp;
    Duration millisElapsed = Duration(milliseconds: diff);

    return millisElapsed.inHours;
  }

  bool isAnyOptionActive({required Stakeout stakeout}) {
    if (stakeout.okayEnabled ||
        stakeout.hospitalEnabled ||
        stakeout.landedEnabled ||
        stakeout.onlineEnabled ||
        stakeout.revivableEnabled ||
        stakeout.lifeBelowPercentageEnabled ||
        stakeout.offlineLongerThanEnabled) {
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
    _stakeoutsSleepTime = await Prefs().getStakeoutsSleepTime();
    _fetchMinutesDelayLimit = await Prefs().getStakeoutsFetchDelayLimit();
  }

  void sleepStakeouts() {
    stakeoutsSleepTime = DateTime.now().millisecondsSinceEpoch + 600000; // 10 minutes

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
    stakeoutsSleepTime = 0; // 10 minutes

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
    if (_stakeoutsSleepTime > 0) {
      if (_stakeoutsSleepTime < DateTime.now().millisecondsSinceEpoch) {
        stakeoutsSleepTime = 0;
      }
    }
  }

  // Returns 0 if stakeouts are not slept, and the timestamp if they are
  int timeUntilStakeoutsSlept() {
    int currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (stakeoutsSleepTime > currentMillis) {
      return stakeoutsSleepTime;
    }
    return 0;
  }

  void _fetchStakeoutsPeriodic() async {
    if (!_stakeoutsEnabled!) return;
    int currentMills = DateTime.now().millisecondsSinceEpoch;
    Stakeout? stakeoutPass = stakeouts.firstWhereOrNull((element) => currentMills - element.lastPass > 30000);
    if (stakeoutPass == null) return;
    // [lastPass] always gets updated, even if no option are active;
    stakeoutPass.lastPass = currentMills;

    if (!isAnyOptionActive(stakeout: stakeoutPass)) {
      //log("Stakeouts: ${stakeoutPass.name} has no active options");
      return;
    }

    //log("Stakeouts: updating ${stakeoutPass.name} @${DateTime.now()}");
    var response = await Get.find<ApiCallerController>().getOtherProfileBasic(playerId: stakeoutPass.id);
    if (response is BasicProfileModel) {
      int currentMills = DateTime.now().millisecondsSinceEpoch;
      // Get minutes since last fetch, so that we don't alert if it's above a certain threshold
      double minutesSinceFetch = (currentMills - stakeoutPass.lastFetch!) / 60000;
      // Then update, since we already fetched
      stakeoutPass.lastFetch = currentMills;

      if (currentMills > _stakeoutsSleepTime) {
        if (minutesSinceFetch > _fetchMinutesDelayLimit) {
          log("Stakeouts: skipping ${stakeoutPass.name} alert due > ${_fetchMinutesDelayLimit} minutes delay");
        } else {
          _alertStakeout(alertStakeout: stakeoutPass, tornProfile: response);
        }
      }
      _updateStakeout(updateStakeout: stakeoutPass, tornProfile: response);
    }
  }

  /// Used when we need to quickly update all properties of a stakeout, since it was inactive before
  Future<bool> _fetchSingle({required Stakeout stakeout}) async {
    var response = await Get.find<ApiCallerController>().getOtherProfileBasic(playerId: stakeout.id);
    if (response is BasicProfileModel) {
      _updateStakeout(updateStakeout: stakeout, tornProfile: response);
      return true;
    }
    return false;
  }

  void _updateStakeout({required Stakeout updateStakeout, required BasicProfileModel tornProfile}) {
    // Update current values
    int millis = DateTime.now().millisecondsSinceEpoch;
    updateStakeout.lastAction = tornProfile.lastAction;
    updateStakeout.status = tornProfile.status;
    updateStakeout.lastFetch = millis;
    updateStakeout.lastPass = millis;
    updateStakeout.okayLast = tornProfile.status!.state == "Okay";
    updateStakeout.hospitalLast = tornProfile.status!.state == "Hospital";
    updateStakeout.revivableLast = tornProfile.revivable == 1;
    updateStakeout.landedLast = tornProfile.status!.state != "Traveling";
    updateStakeout.onlineLast = tornProfile.lastAction!.status == "Online";
    updateStakeout.lifeBelowPercentageLast = tornProfile.life!.current! < updateStakeout.lifeBelowPercentageLimit!;
    updateStakeout.offlineLongerThanLast =
        _getOfflineTimeInHours(lastAction: updateStakeout.lastAction!) > updateStakeout.offlineLongerThanLimit!;
    savePreferences();
    update();
  }

  void _alertStakeout({required Stakeout alertStakeout, required BasicProfileModel tornProfile}) {
    List<String> alerts = [];
    List<Widget> icons = <Widget>[];

    // Send alerts
    if (alertStakeout.okayEnabled) {
      bool okayNow = tornProfile.status!.state == "Okay";
      if (!alertStakeout.okayLast && okayNow) {
        alerts.add("${alertStakeout.name} is now OK!");
        icons.add(Icon(Icons.check, color: Colors.green));
      }
    }

    if (alertStakeout.hospitalEnabled) {
      bool hospitalNow = tornProfile.status!.state == "Hospital";
      if (!alertStakeout.hospitalLast && hospitalNow) {
        alerts.add("${alertStakeout.name} has been hospitalized!");
        icons.add(Icon(FontAwesome.ambulance, color: Colors.red, size: 18));
      }
    }

    if (alertStakeout.revivableEnabled) {
      bool revivableNow = tornProfile.revivable == 1;
      if (!alertStakeout.revivableLast && revivableNow) {
        alerts.add("${alertStakeout.name} is now revivable!");
        icons.add(Icon(Icons.monitor_heart_outlined, color: Colors.green));
      }
    }

    if (alertStakeout.landedEnabled) {
      bool landedNow = tornProfile.status!.state != "Traveling";
      if (!alertStakeout.landedLast && landedNow) {
        alerts.add("${alertStakeout.name} has landed!");
        icons.add(Icon(MdiIcons.airplaneLanding, color: Colors.blue));
      }
    }

    if (alertStakeout.onlineEnabled) {
      bool onlineNow = tornProfile.lastAction!.status == "Online";
      if (!alertStakeout.onlineLast && onlineNow) {
        alerts.add("${alertStakeout.name} is online!");
        icons.add(Icon(MdiIcons.circle, color: Colors.green));
      }
    }

    if (alertStakeout.lifeBelowPercentageEnabled) {
      bool lifeBelowPercentageNow = tornProfile.life!.current! < alertStakeout.lifeBelowPercentageLimit!;
      if (!alertStakeout.lifeBelowPercentageLast && lifeBelowPercentageNow) {
        alerts.add("${alertStakeout.name} life is below ${alertStakeout.lifeBelowPercentageLimit}%!");
        icons.add(
          Container(
            child: Transform.rotate(
              angle: 90 * math.pi / 180,
              child: Icon(MdiIcons.glassStange, color: Colors.red),
            ),
          ),
        );
      }
    }

    if (alertStakeout.offlineLongerThanEnabled) {
      bool offlineLongerThanNow =
          _getOfflineTimeInHours(lastAction: tornProfile.lastAction!) > alertStakeout.offlineLongerThanLimit!;
      if (!alertStakeout.offlineLongerThanLast && offlineLongerThanNow) {
        alerts.add("${alertStakeout.name} offline for longer than ${alertStakeout.offlineLongerThanLimit} hours!");
        icons.add(Icon(Icons.hourglass_bottom_outlined, color: Colors.orange[800]));
      }
    }

    if (alerts.isNotEmpty) {
      log(alerts.toString());
      _showAlert(
        text: alerts,
        icon: icons,
        stakeout: alertStakeout,
      );
    }
  }

  void _showAlert({
    required List<String> text,
    required List<Widget> icon,
    required Stakeout stakeout,
  }) {
    BotToast.showCustomNotification(
      animationDuration: Duration(milliseconds: 200),
      animationReverseDuration: Duration(milliseconds: 200),
      duration: Duration(seconds: 6),
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
      onlyOne: false,
      crossPage: true,
    );
  }

  void setStakeoutNote(Stakeout? stakeout, String note, String? noteColor) {
    Stakeout s = stakeouts.firstWhere((element) => stakeout == element);
    s.personalNote = note;
    s.personalNoteColor = noteColor;
    savePreferences();
    update();
  }
}

class CustomWidget extends StatefulWidget {
  final List<String> alertStrings;
  final List<Widget> icons;
  final String? stakeoutId;
  final CancelFunc cancelFunc;
  final Function sleepStakeouts;

  const CustomWidget({
    Key? key,
    required this.alertStrings,
    required this.stakeoutId,
    required this.cancelFunc,
    required this.icons,
    required this.sleepStakeouts,
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
                  onPressed: widget.sleepStakeouts as void Function()?,
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
