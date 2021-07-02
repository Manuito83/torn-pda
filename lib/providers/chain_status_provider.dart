// Flutter imports:
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:timezone/timezone.dart' as tz;

// Project imports:
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock/wakelock.dart';

enum ChainWatcherDefcon {
  cooldown,
  green1,
  green2,
  orange1,
  orange2,
  red1,
  red2,
  off,
}

class ChainStatusProvider extends ChangeNotifier {
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

  ChainWatcherDefcon _chainWatcherDefcon = ChainWatcherDefcon.off;
  ChainWatcherDefcon get chainWatcherDefcon {
    return _chainWatcherDefcon;
  }

  Color _borderColor = Colors.transparent;
  Color get borderColor {
    return _borderColor;
  }

  AudioCache _audioCache = new AudioCache();

  bool _soundActive = true;
  bool _vibrationActive = true;
  bool _notificationActive = true;

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

  activateWatcher() {
    _watcherActive = true;
    _enableWakelock();
    _audioCache.play('../sounds/alerts/tick.wav');
    notifyListeners();
  }

  deactivateWatcher() {
    _watcherActive = false;
    _borderColor = Colors.transparent;
    _chainWatcherDefcon = ChainWatcherDefcon.off;
    _disableWakelock();
    //_audioCache.play('../sounds/alerts/tick.wav');
    notifyListeners();
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
    String timeOutHours = timeOut.inHours.remainder(24).toString();
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

      chainModel.chain
        ..timeout = 90
        ..current = 1816
        ..max = 2500
        ..start = 1230000
        ..modifier = 1.23
        ..cooldown = 0;


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
      if (_chainWatcherDefcon != ChainWatcherDefcon.off) {
        _chainWatcherDefcon = ChainWatcherDefcon.off;
        notifyListeners();
      }
      return;
    }

    // If under cooldown, apply blue color and return
    if (chainModel.chain.cooldown > 0) {
      if (_chainWatcherDefcon != ChainWatcherDefcon.cooldown) {
        _chainWatcherDefcon = ChainWatcherDefcon.cooldown;
        _borderColor = Colors.lightBlue[300];
        notifyListeners();
      }
      return;
    }

    if (chainModel.chain.current >= 10 && currentSecondsCounter > 1) {
      // RED LEVEL 2
      if (currentSecondsCounter < 30) {
        if (_chainWatcherDefcon != ChainWatcherDefcon.red2) {
          _chainWatcherDefcon = ChainWatcherDefcon.red2;
          if (_soundActive) {
            _audioCache.play('../sounds/alerts/warning2.wav');
          }
          if (_vibrationActive) {
            _vibrate(3);
          }
          if (_notificationActive) {
            _scheduleNotification(555, "", "RED CHAIN ALERT!", "Less than 30 seconds!");
          }
        } else {
          _borderColor == Colors.transparent ? _borderColor = Colors.red : _borderColor = Colors.transparent;
        }
      }
      // RED LEVEL 1
      else if (currentSecondsCounter >= 30 && currentSecondsCounter < 60) {
        if (_chainWatcherDefcon != ChainWatcherDefcon.red1) {
          _chainWatcherDefcon = ChainWatcherDefcon.red1;
          if (_soundActive) {
            _audioCache.play('../sounds/alerts/warning1.wav');
          }
          if (_vibrationActive) {
            _vibrate(3);
          }
          if (_notificationActive) {
            _scheduleNotification(555, "", "RED CHAIN ALERT!", "Less than 60 seconds!");
          }
        } else {
          _borderColor = Colors.red;
        }
      }
      // ORANGE 2
      else if (currentSecondsCounter >= 60 && currentSecondsCounter < 90) {
        if (_chainWatcherDefcon != ChainWatcherDefcon.orange2) {
          _chainWatcherDefcon = ChainWatcherDefcon.orange2;
          if (_soundActive) {
            _audioCache.play('../sounds/alerts/alert2.wav');
          }
          if (_vibrationActive) {
            _vibrate(3);
          }
        } else {
          _borderColor == Colors.transparent ? _borderColor = Colors.orange : _borderColor = Colors.transparent;
        }
      }
      // ORANGE 1
      else if (currentSecondsCounter >= 90 && currentSecondsCounter < 120) {
        if (_chainWatcherDefcon != ChainWatcherDefcon.orange1) {
          _chainWatcherDefcon = ChainWatcherDefcon.orange1;
          if (_soundActive) {
            _audioCache.play('../sounds/alerts/alert1.wav');
          }
          if (_vibrationActive) {
            _vibrate(3);
          }
        } else {
          _borderColor = Colors.orange;
        }
      }
      // GREEN 2
      else if (currentSecondsCounter >= 120 && currentSecondsCounter < 150) {
        if (_chainWatcherDefcon != ChainWatcherDefcon.green2) {
          _chainWatcherDefcon = ChainWatcherDefcon.green2;
        } else {
          _borderColor == Colors.transparent ? _borderColor = Colors.green : _borderColor = Colors.transparent;
        }
        // GREEN 1
      } else if (currentSecondsCounter >= 150) {
        if (_chainWatcherDefcon != ChainWatcherDefcon.green1) {
          _chainWatcherDefcon = ChainWatcherDefcon.green1;
          _borderColor = Colors.green;
        }
      }
      // GREEN 1
    } else {
      _chainWatcherDefcon = ChainWatcherDefcon.green1;
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
    _soundActive = await Prefs().getChainWatcherSound();
    _vibrationActive = await Prefs().getChainWatcherVibration();
    _notificationActive = await Prefs().getChainWatcherNotificationsEnabled();
  }

  void _scheduleNotification(
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
      sound: 'slow_spring_board.aiff',
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        notificationTitle,
        notificationSubtitle,
        //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // DEBUG
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1)),
        platformChannelSpecifics,
        payload: notificationPayload,
        androidAllowWhileIdle: true, // Deliver at exact time
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }
}
