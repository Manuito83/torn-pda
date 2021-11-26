// Flutter imports:
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/models/chaining/chain_panic_target_model.dart';
import 'package:torn_pda/models/chaining/chain_watcher_settings.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/notification.dart';

// Project imports:
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/webview_attack.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock/wakelock.dart';

enum WatchDefcon {
  cooldown,
  green1,
  green2,
  orange1,
  orange2,
  red1,
  red2,
  panic,
  off,
}

class ChainStatusProvider extends ChangeNotifier {
  List<PanicTargetModel> _panicTargets = <PanicTargetModel>[];
  List<PanicTargetModel> get panicTargets {
    return _panicTargets;
  }

  bool _soundEnabled = true;

  bool get soundEnabled {
    return _soundEnabled;
  }

  set changeSoundEnabled(bool value) {
    _soundEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  bool _vibrationEnabled = true;

  bool get vibrationEnabled {
    return _vibrationEnabled;
  }

  set changeVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  bool _notificationsEnabled = true;

  bool get notificationsEnabled {
    return _notificationsEnabled;
  }

  set changeNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  bool initialised = false;
  String _apiKey = "";

  int _accumulatedErrors = 0;

  ChainModel _chainModel;
  ChainModel get chainModel {
    return _chainModel;
  }

  dynamic _barsModel;
  dynamic get barsModel {
    return _barsModel;
  }

  bool _modelError = true;
  bool get modelError {
    return _modelError;
  }

  String _currentChainTimeString = '';
  String get currentChainTimeString {
    return _currentChainTimeString;
  }

  int _currentSecondsCounter = 0;
  int get currentSecondsCounter {
    return _currentSecondsCounter;
  }

  bool _watcherActive = false;
  bool get watcherActive {
    return _watcherActive;
  }

  bool _statusActive = false;
  bool get statusActive {
    return _statusActive;
  }

  WatchDefcon _chainWatcherDefcon = WatchDefcon.off;
  WatchDefcon get chainWatcherDefcon {
    return _chainWatcherDefcon;
  }

  Color _borderColor = Colors.transparent;
  Color get borderColor {
    return _borderColor;
  }

  bool _panicModeActive = false;
  bool get panicModeActive {
    return _panicModeActive;
  }

  AudioCache _audioCache = new AudioCache();

  int _lastChainCount = 0;
  bool _wereWeChaining = false;

  Timer _tickerDecreaseCount;
  Timer _tickerCallChainApi;

  Future activateStatus() async {
    _statusActive = true;
    await getChainStatus();
    await getEnergy();

    // Activate timers
    _tickerCallChainApi = new Timer.periodic(Duration(seconds: 10), (Timer t) => _getAllStatus());
    _tickerDecreaseCount = new Timer.periodic(
      Duration(seconds: 1),
      (Timer t) {
        _decreaseTimer();
        if (_watcherActive) {
          _chainWatchCheck();
        }
      },
    );
  }

  deactivateStatus() {
    _tickerCallChainApi.cancel();
    _tickerDecreaseCount.cancel();
    _statusActive = false;
    print("deactivating status!");
  }

  void activateWatcher() {
    _watcherActive = true;
    _enableWakelock();
    _audioCache.play('../sounds/alerts/tick.wav');
    notifyListeners();
  }

  deactivateWatcher() {
    _watcherActive = false;
    _borderColor = Colors.transparent;
    _chainWatcherDefcon = WatchDefcon.off;
    _disableWakelock();
    //_audioCache.play('../sounds/alerts/tick.wav');
    notifyListeners();
  }

  void activatePanicMode() {
    _panicModeActive = true;
    notifyListeners();
  }

  void deactivatePanicMode() {
    _panicModeActive = false;
    notifyListeners();
  }

  void addPanicTarget(PanicTargetModel target) {
    panicTargets.add(target);
    notifyListeners();
    _saveSettings();
  }

  void removePanicTarget(PanicTargetModel target) {
    panicTargets.removeWhere((element) => element.id == target.id);
    notifyListeners();
    _saveSettings();
  }

  
  void reorderPanicTarget(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      // removing the item at oldIndex will shorten the list by 1
      newIndex -= 1;
    }
    var oldItem = panicTargets[oldIndex];
    panicTargets.removeAt(oldIndex);
    panicTargets.insert(newIndex, oldItem);
    notifyListeners();
    _saveSettings();
  }

  void _refreshChainClock(int secondsRemaining) {
    Duration timeOut = Duration(seconds: secondsRemaining);
    String timeOutMin = timeOut.inMinutes.remainder(60).toString();
    if (timeOut.inMinutes.remainder(60) < 10) {
      timeOutMin = '0$timeOutMin';
    }
    String timeOutSec = timeOut.inSeconds.remainder(60).toString();
    if (timeOut.inSeconds.remainder(60) < 10) {
      timeOutSec = '0$timeOutSec';
    }
    _currentChainTimeString = '$timeOutMin:$timeOutSec';
    notifyListeners();
  }

  void _refreshCooldownClock(int secondsRemaining) {
    Duration timeOut = Duration(seconds: secondsRemaining);
    String timeOutHours = timeOut.inHours.toString();
    String timeOutMin = timeOut.inMinutes.remainder(60).toString();
    String timeOutSec = timeOut.inSeconds.remainder(60).toString();
    if (timeOut.inHours.remainder(24) < 10) {
      timeOutHours = '0$timeOutHours';
    }
    if (timeOut.inMinutes.remainder(60) < 10) {
      timeOutMin = '0$timeOutMin';
    }
    if (timeOut.inSeconds.remainder(60) < 10) {
      timeOutSec = '0$timeOutSec';
    }
    _currentChainTimeString = '$timeOutHours:$timeOutMin:$timeOutSec';
    notifyListeners();
  }

  void _decreaseTimer() {
    if (currentSecondsCounter > 0) {
      _currentSecondsCounter--;
    }
    if (!_modelError) {
      if (chainModel.chain.cooldown > 0) {
        _refreshCooldownClock(currentSecondsCounter);
      } else {
        _refreshChainClock(currentSecondsCounter);
      }
    }
  }

  Future _getAllStatus() async {
    getChainStatus();
    getEnergy();
  }

  Future<void> getEnergy() async {
    dynamic myBars = await TornApiCaller.bars(_apiKey).getBars;
    _barsModel = myBars;
    notifyListeners();
  }

  Future<void> getChainStatus() async {
    var chainResponse = await TornApiCaller.chain(_apiKey).getChainStatus;

    if (chainResponse is ChainModel) {
      _accumulatedErrors = 0;
      _chainModel = chainResponse;
      _modelError = false;

      // For timer debugging
      //
      /*
      chainModel.chain
        ..timeout = 50
        ..current = 1984
        ..max = 2500
        ..start = 1230000
        ..modifier = 1.23
        ..cooldown = 0;
      */

      // OPTION 1, NOT CHAINING
      if ((chainModel.chain.current == 0 || chainModel.chain.timeout == 0) && chainModel.chain.cooldown == 0) {
        // If we are not chaining, reset everything
        _lastChainCount = 0;
        _currentSecondsCounter = 0;
        _refreshChainClock(currentSecondsCounter);
      } else if (chainModel.chain.cooldown > 0) {
        // OPTION 2, WE ARE WITH COOLDOWN
        // If current seconds is zero, is because we are entering the app,
        // so, perform an update
        if (currentSecondsCounter == 0) {
          _currentSecondsCounter = chainModel.chain.cooldown;
          _refreshCooldownClock(chainModel.chain.cooldown);
        }
        // Thereafter, only update if what we get from the API is below the
        // current automatic timer, or the last thing we have is chaining
        if (chainModel.chain.cooldown < currentSecondsCounter || _wereWeChaining) {
          _currentSecondsCounter = chainModel.chain.cooldown;
          _refreshCooldownClock(chainModel.chain.cooldown);
          _wereWeChaining = false;
        }
      } else if (chainModel.chain.current < 10) {
        // OPTION 3, CHAIN UNDER 10
        // Update if for some reason the count in the app is delayed
        // and the real timer is less in Torn
        if (chainModel.chain.timeout < currentSecondsCounter) {
          _currentSecondsCounter = chainModel.chain.timeout;
          _refreshChainClock(currentSecondsCounter);
        }
        // Below 10, update count but only update timer if it was at 0
        // at the beginning (otherwise count won't start)
        if (chainModel.chain.current > _lastChainCount) {
          if (currentSecondsCounter == 0) {
            _currentSecondsCounter = chainModel.chain.timeout;
          }
          _lastChainCount = chainModel.chain.current;
          _refreshChainClock(currentSecondsCounter);
        }
      } else {
        // OPTION 4, CHAIN OF 10 OR MORE
        // Check if counts are different
        _wereWeChaining = true;
        if (chainModel.chain.current > _lastChainCount) {
          _currentSecondsCounter = chainModel.chain.timeout;
          _lastChainCount = chainModel.chain.current;
          _refreshChainClock(currentSecondsCounter);
        } else {
          // Else, even if the count has not changed,
          // take a look at the timer, in case it's delayed and update
          if (chainModel.chain.timeout < currentSecondsCounter) {
            _currentSecondsCounter = chainModel.chain.timeout;
            _refreshChainClock(currentSecondsCounter);
          }
        }
      }
    } else if (chainResponse is ApiError) {
      // Allowing for several tries of errors before returning ApiError
      // so we avoid showing a blank widget as much as possible
      if (_accumulatedErrors < 2 && !_modelError) {
        _accumulatedErrors++;
      } else {
        _modelError = true;
      }
    }
    notifyListeners();
  }

  Future<void> _chainWatchCheck() async {
    // Return if there is an error with the model
    if (_modelError) {
      if (_chainWatcherDefcon != WatchDefcon.off) {
        _chainWatcherDefcon = WatchDefcon.off;
        notifyListeners();
      }
      return;
    }

    // If under cooldown, apply blue color and return
    if (chainModel.chain.cooldown > 0) {
      if (_chainWatcherDefcon != WatchDefcon.cooldown) {
        _chainWatcherDefcon = WatchDefcon.cooldown;
        _borderColor = Colors.lightBlue[300];
        notifyListeners();
      }
      return;
    }

    if (chainModel.chain.current >= 10 && currentSecondsCounter > 1) {
      if (panicModeActive) {
        // PANIC MODE LEVEL
        if (currentSecondsCounter <= _panicValue) {
          if (_chainWatcherDefcon != WatchDefcon.panic) {
            _chainWatcherDefcon = WatchDefcon.panic;
            if (_soundEnabled) {
              _audioCache.play('../sounds/alerts/warning2.wav');
            }
            if (_vibrationEnabled) {
              _vibrate(3);
            }
            if (_notificationsEnabled) {
              showNotification(555, "", "CHAIN PANIC ALERT!", "Less than ${_currentChainTimeString} remaining!");
            }
            if (panicTargets.isNotEmpty) {
              List<String> attacksIds = <String>[];
              List<String> attacksNames = <String>[];
              List<String> attackNotesColorList = <String>[];
              List<String> attackNotesList = <String>[];
              for (var tar in panicTargets) {
                attacksIds.add(tar.id.toString());
                attacksNames.add(tar.name);
                attackNotesColorList.add('z');
                attackNotesList.add('');
              }
              Get.to(
                TornWebViewAttack(
                  attackIdList: attacksIds,
                  attackNameList: attacksNames,
                  userKey: _apiKey,
                  attackNotesColorList: attackNotesColorList,
                  attackNotesList: attackNotesList,
                  panic: true, // This will skip first target if red/blue regardless of user preferences
                  showNotes: await Prefs().getShowTargetsNotes(),
                  showBlankNotes: await Prefs().getShowBlankTargetsNotes(),
                  showOnlineFactionWarning: await Prefs().getShowOnlineFactionWarning(),
                ),
              );
            }
          } else {
            _borderColor == Colors.black ? _borderColor = Colors.yellow : _borderColor = Colors.black;
          }
        } else {
          _borderColor = Colors.yellow;
          _chainWatcherDefcon = WatchDefcon.green1;
        }
      } else {
        // RED LEVEL 2
        if (red2Enabled && currentSecondsCounter > _red2Min && currentSecondsCounter <= _red2Max) {
          if (_chainWatcherDefcon != WatchDefcon.red2) {
            _chainWatcherDefcon = WatchDefcon.red2;
            if (_soundEnabled) {
              _audioCache.play('../sounds/alerts/warning2.wav');
            }
            if (_vibrationEnabled) {
              _vibrate(3);
            }
            if (_notificationsEnabled) {
              showNotification(555, "", "RED CHAIN ALERT!", "Less than ${_currentChainTimeString} remaining!");
            }
          } else {
            _borderColor == Colors.transparent ? _borderColor = Colors.red : _borderColor = Colors.transparent;
          }
        }
        // RED LEVEL 1
        else if (red1Enabled && currentSecondsCounter > _red1Min && currentSecondsCounter <= _red1Max) {
          if (_chainWatcherDefcon != WatchDefcon.red1) {
            _chainWatcherDefcon = WatchDefcon.red1;
            if (_soundEnabled) {
              _audioCache.play('../sounds/alerts/warning1.wav');
            }
            if (_vibrationEnabled) {
              _vibrate(3);
            }
            if (_notificationsEnabled) {
              showNotification(555, "", "RED CHAIN CAUTION!", "Less than ${_currentChainTimeString} remaining!");
            }
          } else {
            _borderColor = Colors.red;
          }
        }
        // ORANGE 2
        else if (orange2Enabled && currentSecondsCounter > _orange2Min && currentSecondsCounter <= _orange2Max) {
          if (_chainWatcherDefcon != WatchDefcon.orange2) {
            _chainWatcherDefcon = WatchDefcon.orange2;
            if (_soundEnabled) {
              _audioCache.play('../sounds/alerts/alert2.wav');
            }
            if (_vibrationEnabled) {
              _vibrate(3);
            }
          } else {
            _borderColor == Colors.transparent ? _borderColor = Colors.orange : _borderColor = Colors.transparent;
          }
        }
        // ORANGE 1
        else if (orange1Enabled && currentSecondsCounter > _orange1Min && currentSecondsCounter <= _orange1Max) {
          if (_chainWatcherDefcon != WatchDefcon.orange1) {
            _chainWatcherDefcon = WatchDefcon.orange1;
            if (_soundEnabled) {
              _audioCache.play('../sounds/alerts/alert1.wav');
            }
            if (_vibrationEnabled) {
              _vibrate(3);
            }
          } else {
            _borderColor = Colors.orange;
          }
        }
        // GREEN 2
        else if (green2Enabled && currentSecondsCounter > _green2Min && currentSecondsCounter <= _green2Max) {
          if (_chainWatcherDefcon != WatchDefcon.green2) {
            _chainWatcherDefcon = WatchDefcon.green2;
          } else {
            _borderColor == Colors.transparent ? _borderColor = Colors.green : _borderColor = Colors.transparent;
          }
          // GREEN 1
        } else {
          if (_chainWatcherDefcon != WatchDefcon.green1) {
            _chainWatcherDefcon = WatchDefcon.green1;
            _borderColor = Colors.green;
          }
        }
      }
    } else {
      // GREEN 1
      _chainWatcherDefcon = WatchDefcon.green1;
      _borderColor = Colors.green;
    }
    notifyListeners();
  }

  _vibrate(int times) async {
    if (await Vibration.hasVibrator()) {
      for (var i = 0; i < times; i++) {
        Vibration.vibrate();
        await Future.delayed(Duration(milliseconds: 1000));
      }
    }
  }

  void _enableWakelock() {
    Wakelock.enabled.then((enabled) {
      if (!enabled) {
        Wakelock.enable();
      }
    });
  }

  void _disableWakelock() {
    Wakelock.enabled.then((enabled) {
      if (enabled) {
        Wakelock.disable();
      }
    });
  }

  loadPreferences({@required apiKey}) async {
    initialised = true;
    _apiKey = apiKey;
    _soundEnabled = await Prefs().getChainWatcherSound();
    _vibrationEnabled = await Prefs().getChainWatcherVibration();
    _notificationsEnabled = await Prefs().getChainWatcherNotificationsEnabled();

    String savedSettings = await Prefs().getChainWatcherSettings();
    if (savedSettings.isNotEmpty) {
      ChainWatcherSettings model = chainWatcherModelFromJson(savedSettings);
      _green2Enabled = model.green2Enabled;
      _green2Max = model.green2Max;
      _green2Min = model.green2Min;
      _orange1Enabled = model.orange1Enabled;
      _orange1Max = model.orange1Max;
      _orange1Min = model.orange1Min;
      _orange2Enabled = model.orange2Enabled;
      _orange2Max = model.orange2Max;
      _orange2Min = model.orange2Min;
      _red1Enabled = model.red1Enabled;
      _red1Max = model.red1Max;
      _red1Min = model.red1Min;
      _red2Enabled = model.red2Enabled;
      _red2Max = model.red2Max;
      _red2Min = model.red2Min;
      _panicModeEnabled = model.panicEnabled;
      _panicValue = model.panicValue;
    }

    List<String> savedPanicTargets = await Prefs().getChainWatcherPanicTargets();
    for (String p in savedPanicTargets) {
      panicTargets.add(panicTargetModelFromJson(p));
    }
  }

  void showNotification(
    int id,
    String payload,
    String title,
    String subtitle,
  ) async {
    String channelTitle = 'Manual chain';
    String channelSubtitle = 'Manual chain';
    String channelDescription = 'Manual notifications for chain';
    String notificationTitle = title;
    String notificationSubtitle = subtitle;
    int notificationId = id;
    String notificationPayload = payload;

    var modifier = await getNotificationChannelsModifiers();
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      "$channelTitle ${modifier.channelIdModifier}",
      "$channelSubtitle ${modifier.channelIdModifier}",
      channelDescription,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: 'notification_chain',
      color: Colors.red,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails(
      presentSound: true,
      sound: 'slow_spring_board.aiff',
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      notificationTitle,
      notificationSubtitle,
      platformChannelSpecifics,
      payload: notificationPayload,
    );
  }

  /// ##########################
  /// PANIC MODE SETTINGS
  /// ##########################

  // This enables the icon, not the actual panic mode (handled by _panicModeActive)
  bool _panicModeEnabled = false;
  bool get panicModeEnabled {
    return _panicModeEnabled;
  }

  double _panicValue = 40;
  double get panicValue {
    return _panicValue;
  }

  void enablePanicMode() {
    _panicModeEnabled = true;
    notifyListeners();
  }

  void disablePanicMode() {
    _panicModeActive = false;
    _panicModeEnabled = false;
    notifyListeners();
  }

  void setPanicValue(double value) {
    _panicValue = value;
    notifyListeners();
  }

  /// ##########################
  /// STARTS OPTIONS SETUP LOGIC
  /// INCLUDING PARAMETERS!
  /// ##########################

  bool _green2Enabled = true;
  bool get green2Enabled {
    return _green2Enabled;
  }

  double _green2Max = 150;
  double get green2Max {
    return _green2Max;
  }

  double _green2Min = 120;
  double get green2Min {
    return _green2Min;
  }

  bool _orange1Enabled = true;
  bool get orange1Enabled {
    return _orange1Enabled;
  }

  double _orange1Max = 120;
  double get orange1Max {
    return _orange1Max;
  }

  double _orange1Min = 90;
  double get orange1Min {
    return _orange1Min;
  }

  bool _orange2Enabled = true;
  bool get orange2Enabled {
    return _orange2Enabled;
  }

  double _orange2Max = 90;
  double get orange2Max {
    return _orange2Max;
  }

  double _orange2Min = 60;
  double get orange2Min {
    return _orange2Min;
  }

  bool _red1Enabled = true;
  bool get red1Enabled {
    return _red1Enabled;
  }

  double _red1Max = 60;
  double get red1Max {
    return _red1Max;
  }

  double _red1Min = 30;
  double get red1Min {
    return _red1Min;
  }

  bool _red2Enabled = true;
  bool get red2Enabled {
    return _red2Enabled;
  }

  double _red2Max = 30;
  double get red2Max {
    return _red2Max;
  }

  double _red2Min = 0;
  double get red2Min {
    return _red2Min;
  }

  void resetAllDefcon() {
    _green2Enabled = true;
    _green2Max = 150;
    _green2Min = 120;
    _orange1Enabled = true;
    _orange1Max = 120;
    _orange1Min = 90;
    _orange2Enabled = true;
    _orange2Max = 90;
    _orange2Min = 60;
    _red1Enabled = true;
    _red1Max = 60;
    _red1Min = 30;
    _red2Enabled = true;
    _red2Max = 30;
    _red2Min = 0;
    _panicValue = 40;
    notifyListeners();
    _saveSettings();
  }

  void setDefconRange(WatchDefcon defcon, RangeValues range, {bool consequence = false}) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        // Depending on which value moves, ensure it leaves a gap with the other
        if (range.start != green2Min && range.start > green2Max - 20) {
          _green2Min = green2Max - 20;
        } else if (range.end != green2Max && range.end < green2Min + 20) {
          _green2Max = green2Min + 20;
        } else {
          _green2Min = range.start;
          _green2Max = range.end;
        }

        // Limit lowest possible value so that a lower bar doesn't narrow too much
        double lowestPossibleValue = _findLowestPossibleValue(WatchDefcon.green2);
        if (_green2Min < lowestPossibleValue) _green2Min = lowestPossibleValue;

        // Only move the other values around if we are really moving this bar
        if (!consequence) {
          // Below
          if (orange1Enabled) {
            setDefconRange(WatchDefcon.orange1, RangeValues(_orange1Min, _green2Min), consequence: true);
          } else if (orange2Enabled) {
            setDefconRange(WatchDefcon.orange2, RangeValues(_orange2Min, _green2Min), consequence: true);
          } else if (red1Enabled) {
            setDefconRange(WatchDefcon.red1, RangeValues(_red1Min, _green2Min), consequence: true);
          } else if (red2Enabled) {
            setDefconRange(WatchDefcon.red2, RangeValues(_red2Min, _green2Min), consequence: true);
          }
        }

        // If there is no other value active, this alert goes to 0:00
        if (!_checkIfAnyActiveBelow(WatchDefcon.green2)) {
          _green2Min = 0;
        }
        break;
      case WatchDefcon.orange1:
        // Depending on which value moves, ensure it leaves a gap with the other
        if (range.start != orange1Min && range.start > orange1Max - 20) {
          _orange1Min = orange1Max - 20;
        } else if (range.end != orange1Max && range.end < orange1Min + 20) {
          _orange1Max = orange1Min + 20;
        } else {
          _orange1Min = range.start;
          _orange1Max = range.end;
        }

        // Only move the other values around if we are really moving this bar
        if (!consequence) {
          // Above
          if (green2Enabled) {
            setDefconRange(WatchDefcon.green2, RangeValues(_orange1Max, _green2Max), consequence: true);
          }
          // Below
          if (orange2Enabled) {
            setDefconRange(WatchDefcon.orange2, RangeValues(_orange2Min, _orange1Min), consequence: true);
          } else if (red1Enabled) {
            setDefconRange(WatchDefcon.red1, RangeValues(_red1Min, _orange1Min), consequence: true);
          } else if (red2Enabled) {
            setDefconRange(WatchDefcon.red2, RangeValues(_red2Min, _orange1Min), consequence: true);
          }
        }

        // Limit lowest possible value so that a lower bar doesn't narrow too much
        double lowestPossibleValue = _findLowestPossibleValue(WatchDefcon.orange1);
        if (_orange1Min < lowestPossibleValue) _orange1Min = lowestPossibleValue;
        // Limit highest
        double highestPossibleValue = _findHighestPossibleValue(WatchDefcon.orange1);
        if (_orange1Max > highestPossibleValue) _orange1Max = highestPossibleValue;

        // If there is no other value active, this alert goes to 0:00
        if (!_checkIfAnyActiveBelow(WatchDefcon.orange1)) {
          _orange1Min = 0;
        }
        break;
      case WatchDefcon.orange2:
        // Depending on which value moves, ensure it leaves a gap with the other
        if (range.start != orange2Min && range.start > orange2Max - 20) {
          _orange2Min = orange2Max - 20;
        } else if (range.end != orange2Max && range.end < orange2Min + 20) {
          _orange2Max = orange2Min + 20;
        } else {
          _orange2Min = range.start;
          _orange2Max = range.end;
        }

        // Only move the other values around if we are really moving this bar
        if (!consequence) {
          // Above
          if (orange1Enabled) {
            setDefconRange(WatchDefcon.orange1, RangeValues(_orange2Max, _orange1Max), consequence: true);
          } else if (green2Enabled) {
            setDefconRange(WatchDefcon.green2, RangeValues(_orange2Max, _green2Max), consequence: true);
          }
          // Below
          if (red1Enabled) {
            setDefconRange(WatchDefcon.red1, RangeValues(_red1Min, _orange2Min), consequence: true);
          } else if (red2Enabled) {
            setDefconRange(WatchDefcon.red2, RangeValues(_red2Min, _orange2Min), consequence: true);
          }
        }

        // Limit lowest possible value so that a lower bar doesn't narrow too much
        double lowestPossibleValue = _findLowestPossibleValue(WatchDefcon.orange2);
        if (_orange2Min < lowestPossibleValue) _orange2Min = lowestPossibleValue;
        // Limit highest
        double highestPossibleValue = _findHighestPossibleValue(WatchDefcon.orange2);
        if (_orange2Max > highestPossibleValue) _orange2Max = highestPossibleValue;

        // If there is no other value active, this alert goes to 0:00
        if (!_checkIfAnyActiveBelow(WatchDefcon.orange2)) {
          _orange2Min = 0;
        }
        break;
      case WatchDefcon.red1:
        // Depending on which value moves, ensure it leaves a gap with the other
        if (range.start != red1Min && range.start > red1Max - 20) {
          _red1Min = red1Max - 20;
        } else if (range.end != red1Max && range.end < red1Min + 20) {
          _red1Max = red1Min + 20;
        } else {
          _red1Min = range.start;
          _red1Max = range.end;
        }

        // Only move the other values around if we are really moving this bar
        if (!consequence) {
          // Above
          if (orange2Enabled) {
            setDefconRange(WatchDefcon.orange2, RangeValues(_red1Max, _orange2Max), consequence: true);
          } else if (orange1Enabled) {
            setDefconRange(WatchDefcon.orange1, RangeValues(_red1Max, _orange1Max), consequence: true);
          } else if (green2Enabled) {
            setDefconRange(WatchDefcon.green2, RangeValues(_red1Max, _green2Max), consequence: true);
          }
          // Below
          if (red2Enabled) {
            setDefconRange(WatchDefcon.red2, RangeValues(_red2Min, _red1Min), consequence: true);
          }
        }

        // Limit lowest possible value so that a lower bar doesn't narrow too much
        double lowestPossibleValue = _findLowestPossibleValue(WatchDefcon.red1);
        if (_red1Min < lowestPossibleValue) _red1Min = lowestPossibleValue;
        // Limit highest
        double highestPossibleValue = _findHighestPossibleValue(WatchDefcon.red1);
        if (_red1Max > highestPossibleValue) _red1Max = highestPossibleValue;

        // If there is no other value active, this alert goes to 0:00
        if (!_checkIfAnyActiveBelow(WatchDefcon.red1)) {
          _red1Min = 0;
        }
        break;
      case WatchDefcon.red2:
        // Depending on which value moves, ensure it leaves a gap with the other
        if (range.start != red2Min && range.start > red2Max - 20) {
          _red2Min = red2Max - 20;
        } else if (range.end != red2Max && range.end < red2Min + 20) {
          _red2Max = red2Min + 20;
        } else {
          _red2Min = range.start;
          _red2Max = range.end;
        }

        // Only move the other values around if we are really moving this bar
        if (!consequence) {
          // Above
          if (red1Enabled) {
            setDefconRange(WatchDefcon.red1, RangeValues(_red2Max, _red1Max), consequence: true);
          } else if (orange2Enabled) {
            setDefconRange(WatchDefcon.orange2, RangeValues(_red2Max, _orange2Max), consequence: true);
          } else if (orange1Enabled) {
            setDefconRange(WatchDefcon.orange1, RangeValues(_red2Max, _orange1Max), consequence: true);
          } else if (green2Enabled) {
            setDefconRange(WatchDefcon.green2, RangeValues(_red2Max, _green2Max), consequence: true);
          }
        }

        // Limit lowest possible value so that a lower bar doesn't narrow too much
        double lowestPossibleValue = _findLowestPossibleValue(WatchDefcon.red2);
        if (_red2Min < lowestPossibleValue) _red2Min = lowestPossibleValue;
        // Limit highest
        double highestPossibleValue = _findHighestPossibleValue(WatchDefcon.red2);
        if (_red2Max > highestPossibleValue) _red2Max = highestPossibleValue;

        // If there is no other value active, this alert goes to 0:00
        if (!_checkIfAnyActiveBelow(WatchDefcon.red2)) {
          _red2Min = 0;
        }
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }

    notifyListeners();
    _saveSettings();
  }

  void activateDefcon(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        // Try to make room to the left, find that's the first gap
        WatchDefcon gapOwnerBelow;
        if (orange1Enabled && orange1Max - orange1Min >= 40) {
          gapOwnerBelow = WatchDefcon.orange1;
        } else if (orange2Enabled && orange2Max - orange2Min >= 40) {
          gapOwnerBelow = WatchDefcon.orange2;
        } else if (red1Enabled && red1Max - red1Min >= 40) {
          gapOwnerBelow = WatchDefcon.red1;
        } else if (red2Enabled && red2Max - red2Min >= 40) {
          gapOwnerBelow = WatchDefcon.red2;
        }

        // If there is a gap, use it by shrinking
        if (gapOwnerBelow != null) {
          if (gapOwnerBelow == WatchDefcon.red2) {
            _shrinkLeft(WatchDefcon.red2);
            if (red1Enabled) _displaceLeft(WatchDefcon.red1);
            if (orange2Enabled) _displaceLeft(WatchDefcon.orange2);
            if (orange1Enabled) _displaceLeft(WatchDefcon.orange1);
          } else if (gapOwnerBelow == WatchDefcon.red1) {
            _shrinkLeft(WatchDefcon.red1);
            if (orange2Enabled) _displaceLeft(WatchDefcon.orange2);
            if (orange1Enabled) _displaceLeft(WatchDefcon.orange1);
          } else if (gapOwnerBelow == WatchDefcon.orange2) {
            _shrinkLeft(WatchDefcon.orange2);
            if (orange1Enabled) _displaceLeft(WatchDefcon.orange1);
          } else if (gapOwnerBelow == WatchDefcon.orange1) {
            _shrinkLeft(WatchDefcon.orange1);
          }

          double lowerValue = _findLowerDefconMaxValue(defcon);
          _green2Min = lowerValue;
          _green2Max = lowerValue + 20;
        }

        // If we could not make space to the left by shrinking or displacing, use the right
        if (gapOwnerBelow == null) {
          // Determine actual limits up and down
          double lowerValue = _findLowerDefconMaxValue(defcon);
          double upperValue = _findUpperDefconMinValue(defcon);
          // Handle to special cases when there is nothing above the value
          if (lowerValue == 0 && upperValue == 270) {
            // If it's the only value in existence, limit it from 00:00 to the default one
            upperValue = 150;
          } else if (lowerValue > 0 && upperValue == 270) {
            // If there is another value below, but nothing above, adjust lower side to +60 seconds or 04:30 (max)
            lowerValue = _findLowerDefconMaxValue(defcon);
            if (lowerValue + 60 > 270) {
              upperValue = 270;
            } else {
              upperValue = lowerValue + 60;
            }
          }
          // Assign final values
          _green2Min = lowerValue;
          _green2Max = upperValue;
        }

        // Activate
        _green2Enabled = true;
        break;

      case WatchDefcon.orange1:
        // Try to make room to the left, find that's the first gap
        WatchDefcon gapOwnerBelow;
        if (orange2Enabled && orange2Max - orange2Min >= 40) {
          gapOwnerBelow = WatchDefcon.orange2;
        } else if (red1Enabled && red1Max - red1Min >= 40) {
          gapOwnerBelow = WatchDefcon.red1;
        } else if (red2Enabled && red2Max - red2Min >= 40) {
          gapOwnerBelow = WatchDefcon.red2;
        }

        // If there is a gap, use it by shrinking
        if (gapOwnerBelow != null) {
          if (gapOwnerBelow == WatchDefcon.red2) {
            _shrinkLeft(WatchDefcon.red2);
            if (red1Enabled) _displaceLeft(WatchDefcon.red1);
            if (orange2Enabled) _displaceLeft(WatchDefcon.orange2);
          }
          if (gapOwnerBelow == WatchDefcon.red1) {
            _shrinkLeft(WatchDefcon.red1);
            if (orange2Enabled) _displaceLeft(WatchDefcon.orange2);
          }
          if (gapOwnerBelow == WatchDefcon.orange2) {
            _shrinkLeft(WatchDefcon.orange2);
          }

          double lowerValue = _findLowerDefconMaxValue(defcon);
          _orange1Min = lowerValue;
          _orange1Max = lowerValue + 20;
        }

        // If we could not make space to the left by shrinking or displacing, try to the right
        if (gapOwnerBelow == null) {
          WatchDefcon gapOwnerAbove;
          if (green2Enabled && green2Max - green2Min >= 40) {
            gapOwnerAbove = WatchDefcon.green2;
          }

          // Try to move step by step
          if (gapOwnerAbove != null) {
            if (gapOwnerAbove == WatchDefcon.green2) {
              _shrinkRight(WatchDefcon.green2);
            }
          } else {
            // If no gaps, move everything to the right (we can't reach max because we could not move down)
            _displaceRight(WatchDefcon.green2);
          }

          // Determine actual limits up and down
          double lowerValue = _findLowerDefconMaxValue(defcon);
          double upperValue = _findUpperDefconMinValue(defcon);
          // Handle to special cases when there is nothing above the value
          if (lowerValue == 0 && upperValue == 270) {
            // If it's the only value in existence, limit it from 00:00 to the default one
            upperValue = 120;
          } else if (lowerValue > 0 && upperValue == 270) {
            // If there is another value below, but nothing above, adjust lower side to +60 seconds or 04:30 (max)
            lowerValue = _findLowerDefconMaxValue(defcon);
            if (lowerValue + 60 > 270) {
              upperValue = 270;
            } else {
              upperValue = lowerValue + 60;
            }
          }
          // Assign final values
          _orange1Min = lowerValue;
          _orange1Max = upperValue;
        }

        // Activate
        _orange1Enabled = true;
        break;

      case WatchDefcon.orange2:
        // Try to make room to the left, find that's the first gap
        WatchDefcon gapOwnerBelow;
        if (red1Enabled && red1Max - red1Min >= 40) {
          gapOwnerBelow = WatchDefcon.red1;
        } else if (red2Enabled && red2Max - red2Min >= 40) {
          gapOwnerBelow = WatchDefcon.red2;
        }

        // If there is a gap, use it by shrinking
        if (gapOwnerBelow != null) {
          if (gapOwnerBelow == WatchDefcon.red2) {
            _shrinkLeft(WatchDefcon.red2);
            if (red1Enabled) _displaceLeft(WatchDefcon.red1);
          } else if (gapOwnerBelow == WatchDefcon.red1) {
            _shrinkLeft(WatchDefcon.red1);
          }

          double lowerValue = _findLowerDefconMaxValue(defcon);
          _orange2Min = lowerValue;
          _orange2Max = lowerValue + 20;
        }

        // If we could not make space to the left by shrinking or displacing, try to the right
        if (gapOwnerBelow == null) {
          WatchDefcon gapOwnerAbove;
          if (orange1Enabled && orange1Max - orange1Min >= 40) {
            gapOwnerAbove = WatchDefcon.orange1;
          } else if (green2Enabled && green2Max - green2Min >= 40) {
            gapOwnerAbove = WatchDefcon.green2;
          }

          if (gapOwnerAbove != null) {
            // Try to move step by step
            if (gapOwnerAbove == WatchDefcon.green2) {
              _shrinkRight(WatchDefcon.green2);
              if (orange1Enabled) _displaceRight(WatchDefcon.orange1);
            } else if (gapOwnerAbove == WatchDefcon.orange1) {
              _shrinkRight(WatchDefcon.orange1);
            }
          } else {
            // If no gaps, move everything to the right (we can't reach max because we could not move down)
            _displaceRight(WatchDefcon.green2);
            _displaceRight(WatchDefcon.orange1);
          }

          // Determine actual limits up and down
          double lowerValue = _findLowerDefconMaxValue(defcon);
          double upperValue = _findUpperDefconMinValue(defcon);
          // Handle to special cases when there is nothing above the value
          if (lowerValue == 0 && upperValue == 270) {
            // If it's the only value in existence, limit it from 00:00 to the default one
            upperValue = 90;
          } else if (lowerValue > 0 && upperValue == 270) {
            // If there is another value below, but nothing above, adjust lower side to +60 seconds or 04:30 (max)
            lowerValue = _findLowerDefconMaxValue(defcon);
            if (lowerValue + 60 > 270) {
              upperValue = 270;
            } else {
              upperValue = lowerValue + 60;
            }
          }
          // Assign final values
          _orange2Min = lowerValue;
          _orange2Max = upperValue;
        }

        // Activate
        _orange2Enabled = true;
        break;

      case WatchDefcon.red1:
        // Try to make room to the left, find that's the first gap
        WatchDefcon gapOwnerBelow;
        if (red2Enabled && red2Max - red2Min >= 40) {
          gapOwnerBelow = WatchDefcon.red2;
        }

        // If there is a gap, use it by shrinking
        if (gapOwnerBelow != null) {
          _shrinkLeft(WatchDefcon.red2);

          double lowerValue = _findLowerDefconMaxValue(defcon);
          _red1Min = lowerValue;
          _red1Max = lowerValue + 20;
        }

        // If we could not make space to the left by shrinking or displacing, try to the right
        if (gapOwnerBelow == null) {
          WatchDefcon gapOwnerAbove;
          if (orange2Enabled && orange2Max - orange2Min >= 40) {
            gapOwnerAbove = WatchDefcon.orange2;
          } else if (orange1Enabled && orange1Max - orange1Min >= 40) {
            gapOwnerAbove = WatchDefcon.orange1;
          } else if (green2Enabled && green2Max - green2Min >= 40) {
            gapOwnerAbove = WatchDefcon.green2;
          }

          // Try to move step by step
          if (gapOwnerAbove != null) {
            if (gapOwnerAbove == WatchDefcon.green2) {
              _shrinkRight(WatchDefcon.green2);
              if (orange1Enabled) _displaceRight(WatchDefcon.orange1);
              if (orange2Enabled) _displaceRight(WatchDefcon.orange2);
            } else if (gapOwnerAbove == WatchDefcon.orange1) {
              _shrinkRight(WatchDefcon.orange1);
              if (orange2Enabled) _displaceRight(WatchDefcon.orange2);
            } else if (gapOwnerAbove == WatchDefcon.orange2) {
              _shrinkRight(WatchDefcon.orange2);
            }
          } else {
            // If no gaps, move everything to the right (we can't reach max because we could not move down)
            _displaceRight(WatchDefcon.green2);
            _displaceRight(WatchDefcon.orange1);
            _displaceRight(WatchDefcon.orange2);
          }

          // Determine actual limits up and down
          double lowerValue = _findLowerDefconMaxValue(defcon);
          double upperValue = _findUpperDefconMinValue(defcon);
          // Handle to special cases when there is nothing above the value
          if (lowerValue == 0 && upperValue == 270) {
            // If it's the only value in existence, limit it from 00:00 to the default one
            upperValue = 60;
          } else if (lowerValue > 0 && upperValue == 270) {
            // If there is another value below, but nothing above, adjust lower side to +60 seconds or 04:30 (max)
            lowerValue = _findLowerDefconMaxValue(defcon);
            if (lowerValue + 60 > 270) {
              upperValue = 270;
            } else {
              upperValue = lowerValue + 60;
            }
          }
          // Assign final values
          _red1Min = lowerValue;
          _red1Max = upperValue;
        }

        // Activate
        _red1Enabled = true;
        break;

      case WatchDefcon.red2:
        // In Red 2 we can only make room above

        // If there was a gap, use it by shrinking
        WatchDefcon gapOwnerAbove;
        if (red1Enabled && red1Max - red1Min >= 40) {
          gapOwnerAbove = WatchDefcon.red1;
        } else if (orange2Enabled && orange2Max - orange2Min >= 40) {
          gapOwnerAbove = WatchDefcon.orange2;
        } else if (orange1Enabled && orange1Max - orange1Min >= 40) {
          gapOwnerAbove = WatchDefcon.orange1;
        } else if (green2Enabled && green2Max - green2Min >= 40) {
          gapOwnerAbove = WatchDefcon.green2;
        }

        if (gapOwnerAbove != null) {
          // Try to move step by step
          if (gapOwnerAbove == WatchDefcon.green2) {
            _shrinkRight(WatchDefcon.green2);
            if (orange1Enabled) _displaceRight(WatchDefcon.orange1);
            if (orange2Enabled) _displaceRight(WatchDefcon.orange2);
            if (red1Enabled) _displaceRight(WatchDefcon.red1);
          }
          if (gapOwnerAbove == WatchDefcon.orange1) {
            _shrinkRight(WatchDefcon.orange1);
            if (orange2Enabled) _displaceRight(WatchDefcon.orange2);
            if (red1Enabled) _displaceRight(WatchDefcon.red1);
          }
          if (gapOwnerAbove == WatchDefcon.orange2) {
            _shrinkRight(WatchDefcon.orange2);
            if (red1Enabled) _displaceRight(WatchDefcon.red1);
          }
          if (gapOwnerAbove == WatchDefcon.red1) {
            _shrinkRight(WatchDefcon.red1);
          }
        } else {
          // If no gaps, move everything to the right (we can't reach max because we could not move down)
          if (green2Enabled) _displaceRight(WatchDefcon.green2);
          if (orange1Enabled) _displaceRight(WatchDefcon.orange1);
          if (orange2Enabled) _displaceRight(WatchDefcon.orange2);
          if (red1Enabled) _displaceRight(WatchDefcon.red1);
        }

        // Determine actual limits up and down
        double lowerValue = _findLowerDefconMaxValue(defcon);
        double upperValue = _findUpperDefconMinValue(defcon);
        // Handle to special cases when there is nothing above the value
        if (lowerValue == 0 && upperValue == 270) {
          // If it's the only value in existence, limit it from 00:00 to the default one
          upperValue = 30;
        } else if (lowerValue > 0 && upperValue == 270) {
          // If there is another value below, but nothing above, adjust lower side to +60 seconds or 04:30 (max)
          lowerValue = _findLowerDefconMaxValue(defcon);
          if (lowerValue + 60 > 270) {
            upperValue = 270;
          } else {
            upperValue = lowerValue + 60;
          }
        }
        // Assign final values
        _red2Min = lowerValue;
        _red2Max = upperValue;

        // Activate
        _red2Enabled = true;
        break;

      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
    notifyListeners();
    _saveSettings();
  }

  void _shrinkLeft(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        _green2Max -= 20;
        break;
      case WatchDefcon.orange1:
        _orange1Max -= 20;
        break;
      case WatchDefcon.orange2:
        _orange2Max -= 20;
        break;
      case WatchDefcon.red1:
        _red1Max -= 20;
        break;
      case WatchDefcon.red2:
        _red2Max -= 20;
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
  }

  void _shrinkRight(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        _green2Min += 20;
        break;
      case WatchDefcon.orange1:
        _orange1Min += 20;
        break;
      case WatchDefcon.orange2:
        _orange2Min += 20;
        break;
      case WatchDefcon.red1:
        _red1Min += 20;
        break;
      case WatchDefcon.red2:
        _red2Min += 20;
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
  }

  void _displaceLeft(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        _green2Min -= 20;
        _green2Max -= 20;
        break;
      case WatchDefcon.orange1:
        _orange1Min -= 20;
        _orange1Max -= 20;
        break;
      case WatchDefcon.orange2:
        _orange2Min -= 20;
        _orange2Max -= 20;
        break;
      case WatchDefcon.red1:
        _red1Min -= 20;
        _red1Max -= 20;
        break;
      case WatchDefcon.red2:
        _red2Min -= 20;
        _red2Max -= 20;
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
  }

  void _displaceRight(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        _green2Min += 20;
        _green2Max += 20;
        break;
      case WatchDefcon.orange1:
        _orange1Min += 20;
        _orange1Max += 20;
        break;
      case WatchDefcon.orange2:
        _orange2Min += 20;
        _orange2Max += 20;
        break;
      case WatchDefcon.red1:
        _red1Min += 20;
        _red1Max += 20;
        break;
      case WatchDefcon.red2:
        _red2Min += 20;
        _red2Max += 20;
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
  }

  void deactivateDefcon(WatchDefcon defcon) {
    double upper = _findUpperDefconMinValue(defcon);

    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        _green2Enabled = false;
        break;
      case WatchDefcon.orange1:
        _orange1Enabled = false;
        if (upper == 270) break;
        if (orange2Enabled) {
          setDefconRange(WatchDefcon.orange2, RangeValues(orange2Min, upper));
        } else if (red1Enabled) {
          setDefconRange(WatchDefcon.red1, RangeValues(red1Min, upper));
        } else if (red2Enabled) {
          setDefconRange(WatchDefcon.red2, RangeValues(red2Min, upper));
        } else {
          // Ensure that we always reach the bottom
          if (green2Enabled) {
            _green2Min = 0;
          }
        }
        break;
      case WatchDefcon.orange2:
        _orange2Enabled = false;
        if (upper == 270) break;
        if (red1Enabled) {
          setDefconRange(WatchDefcon.red1, RangeValues(red1Min, upper));
        } else if (red2Enabled) {
          setDefconRange(WatchDefcon.red2, RangeValues(red2Min, upper));
        } else {
          // Ensure that we always reach the bottom
          if (orange1Enabled) {
            _orange1Min = 0;
          } else if (green2Enabled) {
            _green2Min = 0;
          }
        }
        break;
      case WatchDefcon.red1:
        _red1Enabled = false;
        if (upper == 270) break;
        if (red2Enabled) {
          setDefconRange(WatchDefcon.red2, RangeValues(red2Min, upper));
        } else {
          // Ensure that we always reach the bottom
          if (orange2Enabled) {
            _orange2Min = 0;
          } else if (orange1Enabled) {
            _orange1Min = 0;
          } else if (green2Enabled) {
            _green2Min = 0;
          }
        }
        break;
      case WatchDefcon.red2:
        _red2Enabled = false;
        // Ensure that we always reach the bottom
        if (red1Enabled) {
          _red1Min = 0;
        } else if (orange2Enabled) {
          _orange2Min = 0;
        } else if (orange1Enabled) {
          _orange1Min = 0;
        } else if (green2Enabled) {
          _green2Min = 0;
        }
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }

    notifyListeners();
    _saveSettings();
  }

  bool _checkIfAnyActiveBelow(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        if (_orange1Enabled || orange2Enabled || red1Enabled || red2Enabled) return true;
        break;
      case WatchDefcon.orange1:
        if (orange2Enabled || red1Enabled || red2Enabled) return true;
        break;
      case WatchDefcon.orange2:
        if (red1Enabled || red2Enabled) return true;
        break;
      case WatchDefcon.red1:
        if (red2Enabled) return true;
        break;
      case WatchDefcon.red2:
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
    return false;
  }

  // 'Possible' means that the next defcon is displaced until it leaves 20 seconds gap
  double _findLowestPossibleValue(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        if (_orange1Enabled) {
          return _orange1Min + 20;
        } else if (_orange2Enabled) {
          return _orange2Min + 20;
        } else if (_red1Enabled) {
          return _red1Min + 20;
        } else if (_red2Enabled) {
          return _red2Min + 20;
        }
        return 0;
        break;
      case WatchDefcon.orange1:
        if (_orange2Enabled) {
          return _orange2Min + 20;
        } else if (_red1Enabled) {
          return _red1Min + 20;
        } else if (_red2Enabled) {
          return _red2Min + 20;
        }
        return 0;
        break;
      case WatchDefcon.orange2:
        if (_red1Enabled) {
          return _red1Min + 20;
        } else if (_red2Enabled) {
          return _red2Min + 20;
        }
        break;
      case WatchDefcon.red1:
        if (_red2Enabled) {
          return _red2Min + 20;
        }
        break;
      case WatchDefcon.red2:
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
    return 0;
  }

// 'Possible' means that the next defcon is displaced until it leaves 20 seconds gap
  double _findHighestPossibleValue(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        return 270;
        break;
      case WatchDefcon.orange1:
        if (_green2Enabled) return _green2Max - 20;
        return 270;
        break;
      case WatchDefcon.orange2:
        if (_orange1Enabled) {
          return _orange1Max - 20;
        } else if (_green2Enabled) {
          return _green2Max - 20;
        }
        return 270;
        break;
      case WatchDefcon.red1:
        if (_orange2Enabled) {
          return _orange2Max - 20;
        } else if (_orange1Enabled) {
          return _orange1Max - 20;
        } else if (_green2Enabled) {
          return _green2Max - 20;
        }
        return 270;
        break;
      case WatchDefcon.red2:
        if (_red1Enabled) {
          return _red1Max - 20;
        } else if (_orange2Enabled) {
          return _orange2Max - 20;
        } else if (_orange1Enabled) {
          return _orange1Max - 20;
        } else if (_green2Enabled) {
          return _green2Max - 20;
        }
        return 270;
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
    return 270;
  }

  // Without displacement, where is the upper defcon's minimum value
  double _findUpperDefconMinValue(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        return 270;
        break;
      case WatchDefcon.orange1:
        if (_green2Enabled) return _green2Min;
        return 270;
        break;
      case WatchDefcon.orange2:
        if (_orange1Enabled) {
          return _orange1Min;
        } else if (_green2Enabled) {
          return _green2Min;
        }
        return 270;
        break;
      case WatchDefcon.red1:
        if (_orange2Enabled) {
          return _orange2Min;
        } else if (_orange1Enabled) {
          return _orange1Min;
        } else if (_green2Enabled) {
          return _green2Min;
        }
        return 270;
        break;
      case WatchDefcon.red2:
        if (_red1Enabled) {
          return _red1Min;
        } else if (_orange2Enabled) {
          return _orange2Min;
        } else if (_orange1Enabled) {
          return _orange1Min;
        } else if (_green2Enabled) {
          return _green2Min;
        }
        return 270;
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
    return 270;
  }

  // Without displacement, where is the lower defcon's maximum value
  double _findLowerDefconMaxValue(WatchDefcon defcon) {
    switch (defcon) {
      case WatchDefcon.cooldown:
        break;
      case WatchDefcon.green1:
        break;
      case WatchDefcon.green2:
        if (orange1Enabled) {
          return orange1Max;
        } else if (orange2Enabled) {
          return orange2Max;
        } else if (red1Enabled) {
          return red1Max;
        } else if (red2Enabled) {
          return red2Max;
        }
        return 0;
        break;
      case WatchDefcon.orange1:
        if (orange2Enabled) {
          return orange2Max;
        } else if (red1Enabled) {
          return red1Max;
        } else if (red2Enabled) {
          return red2Max;
        }
        return 0;
        break;
      case WatchDefcon.orange2:
        if (red1Enabled) {
          return red1Max;
        } else if (red2Enabled) {
          return red2Max;
        }
        return 0;
        break;
      case WatchDefcon.red1:
        if (red2Enabled) {
          return red2Max;
        }
        return 0;
        break;
      case WatchDefcon.red2:
        return 0;
        break;
      case WatchDefcon.off:
        break;
      case WatchDefcon.panic:
        break;
    }
    return 0;
  }

  void _saveSettings() {
    Prefs().setChainWatcherSound(_soundEnabled);
    Prefs().setChainWatcherVibration(_vibrationEnabled);
    Prefs().setChainWatcherNotificationsEnabled(_notificationsEnabled);

    ChainWatcherSettings model = ChainWatcherSettings()
      ..green2Enabled = green2Enabled
      ..green2Max = _green2Max
      ..green2Min = _green2Min
      ..orange1Enabled = _orange1Enabled
      ..orange1Max = _orange1Max
      ..orange1Min = _orange1Min
      ..orange2Enabled = _orange2Enabled
      ..orange2Max = _orange2Max
      ..orange2Min = _orange2Min
      ..red1Enabled = _red1Enabled
      ..red1Max = _red1Max
      ..red1Min = _red1Min
      ..red2Enabled = _red2Enabled
      ..red2Max = _red2Max
      ..red2Min = _red2Min
      ..panicEnabled = _panicModeEnabled
      ..panicValue = _panicValue;
    Prefs().setChainWatcherSettings(chainWatcherModelToJson(model));

    List<String> panicTargetsModel = <String>[];
    for (PanicTargetModel p in panicTargets) {
      panicTargetsModel.add(panicTargetModelToJson(p));
    }
    Prefs().setChainWatcherPanicTargets(panicTargetsModel);
  }
}
