import 'dart:async';
import 'package:audioplayers/audio_cache.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock/wakelock.dart';

enum ChainWatcherColor {
  cooldown,
  green1,
  green2,
  orange1,
  orange2,
  red,
  off,
}

enum ChainTimerParent {
  targets,
  webView,
}

class ChainTimer extends StatefulWidget {
  final String userKey;
  final bool alwaysDarkBackground;
  final ChainTimerParent chainTimerParent;

  ChainTimer({
    Key key,
    @required this.userKey,
    @required this.alwaysDarkBackground,
    @required this.chainTimerParent,
  }) : super(key: key);

  @override
  _ChainTimerState createState() => _ChainTimerState();
}

class _ChainTimerState extends State<ChainTimer> with TickerProviderStateMixin {
  ThemeProvider _themeProvider;

  Future _finishedLoadingChain;

  Timer _tickerDecreaseCount;
  Timer _tickerCallChainApi;

  String _currentChainTimeString = '';
  int _currentSecondsCounter = 0;

  ChainModel _chainModel;
  bool _modelError = true;

  dynamic _barsModel;
  Future _finishedGettingBars;

  int _lastChainCount = 0;

  int _accumulatedErrors = 0;

  bool _wereWeChaining = false;

  ChainStatusProvider _chainStatusProvider;
  ChainWatcherColor _chainWatcherColor = ChainWatcherColor.off;
  Color _chainBorderColor = Colors.transparent;
  AnimationController _chainBorderController;
  AudioCache audioCache = new AudioCache();

  @override
  void initState() {
    super.initState();
    _finishedLoadingChain = _getChainStatus();
    _finishedGettingBars = _getEnergy();
    _tickerDecreaseCount = new Timer.periodic(
      Duration(seconds: 1),
      (Timer t) {
        _decreaseTimer();
        _chainWatchCheck();
      },
    );
    _tickerCallChainApi = new Timer.periodic(Duration(seconds: 10), (Timer t) => _getAllStatus());

    _chainBorderController = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: 1),
    );

    // We assign the parent to this instance of the widget, so that we can prevent it from raising
    // alerts if it's not visible (but active on the background)
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: false);
    _chainStatusProvider.watcherAssignParent(newParent: widget.chainTimerParent);
    if (!_chainStatusProvider.preferencesLoaded) {
      _chainStatusProvider.loadPreferences();
    }
    // If we exit the section and reenter, activate the wakelock if watcher is active
    if (_chainStatusProvider.watcherActive) {
      Wakelock.enable();
      print('enabled!');
    }
  }

  @override
  void dispose() {
    _tickerDecreaseCount.cancel();
    _tickerCallChainApi.cancel();
    _chainBorderController.dispose();
    audioCache.clearCache();
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    Color titleColor;
    if (widget.alwaysDarkBackground) {
      titleColor = Colors.white;
    } else {
      titleColor = _themeProvider.mainText;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: AnimatedBuilder(
        animation: _chainBorderController,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: _chainBorderColor,
                  width: _assessChainBorderWidth(),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    child: !_modelError
                        ? IconButton(
                            icon: Icon(MdiIcons.eyeOutline),
                            color: _chainStatusProvider.watcherActive
                                ? widget.alwaysDarkBackground
                                    ? Colors.orange[700]
                                    : Colors.orange[900]
                                : widget.alwaysDarkBackground
                                    ? Colors.grey
                                    : _themeProvider.mainText,
                            onPressed: () {
                              setState(() {
                                if (_chainStatusProvider.watcherActive) {
                                  _deactivateChainWatcher();
                                } else {
                                  _activateChainWatcher();
                                }
                              });
                            },
                          )
                        : SizedBox.shrink(),
                  ),
                  SizedBox(width: 5),
                  Column(
                    children: <Widget>[
                      FutureBuilder(
                        future: _finishedLoadingChain,
                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            if (!_modelError) {
                              return Column(
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          _chainModel.chain.cooldown > 0 ? 'Cooldown ' : 'Chain ',
                                          style: TextStyle(color: titleColor),
                                        ),
                                        Text(
                                          '$_currentChainTimeString',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _currentSecondsCounter > 0 &&
                                                    _currentSecondsCounter < 60 &&
                                                    _chainModel.chain.cooldown == 0
                                                ? Colors.red
                                                : titleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  LinearPercentIndicator(
                                    alignment: MainAxisAlignment.center,
                                    width: 150,
                                    lineHeight: 16,
                                    backgroundColor: Colors.grey,
                                    progressColor: _chainModel.chain.cooldown > 0
                                        ? Colors.green[200]
                                        : Colors.blue[200],
                                    center: Text(
                                      _chainModel.chain.cooldown > 0
                                          ? '${_chainModel.chain.current} hits'
                                          : '${_chainModel.chain.current}/${_chainModel.chain.max}',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    percent: _chainModel.chain.cooldown > 0
                                        ? 1.0
                                        : _chainModel.chain.current / _chainModel.chain.max,
                                  ),
                                ],
                              );
                            } else {
                              return Text(
                                'Cannot retrieve chain details!',
                                style: TextStyle(
                                    fontStyle: FontStyle.italic, color: Colors.orange[800]),
                              );
                            }
                          } else {
                            return SizedBox(height: 30);
                          }
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      FutureBuilder(
                        future: _finishedGettingBars,
                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            if (_barsModel is BarsModel) {
                              return Column(
                                children: <Widget>[
                                  LinearPercentIndicator(
                                    alignment: MainAxisAlignment.center,
                                    width: 150,
                                    lineHeight: 16,
                                    backgroundColor: Colors.green[100],
                                    progressColor: Colors.green,
                                    center: Text(
                                      'E: ${_barsModel.energy.current}/${_barsModel.energy.maximum}',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    // Take drugs into account
                                    percent:
                                        (_barsModel.energy.current / _barsModel.energy.maximum) >
                                                1.0
                                            ? 1.0
                                            : _barsModel.energy.current / _barsModel.energy.maximum,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                  ),
                                  LinearPercentIndicator(
                                    alignment: MainAxisAlignment.center,
                                    width: 150,
                                    lineHeight: 3,
                                    backgroundColor: Colors.green[100],
                                    progressColor: Colors.green,
                                    percent:
                                        1 - _barsModel.energy.ticktime / _barsModel.energy.interval,
                                  ),
                                ],
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(width: 5),
                  // Placeholder for another icon
                  SizedBox(width: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _getChainStatus() async {
    var chainResponse = await TornApiCaller.chain(widget.userKey).getChainStatus;

    if (chainResponse is ChainModel) {
      _accumulatedErrors = 0;
      _chainModel = chainResponse;
      _modelError = false;

      // For timer debugging
      /*
      _chainModel.chain
        ..timeout = 115
        ..current = 1800
        ..max = 2500
        ..start = 1230000
        ..modifier = 1.23
        ..cooldown = 0;
      */

      // OPTION 1, NOT CHAINING
      if ((_chainModel.chain.current == 0 || _chainModel.chain.timeout == 0) &&
          _chainModel.chain.cooldown == 0) {
        // If we are not chaining, reset everything
        _lastChainCount = 0;
        _currentSecondsCounter = 0;
        _refreshChainClock(_currentSecondsCounter);
      } else if (_chainModel.chain.cooldown > 0) {
        // OPTION 2, WE ARE WITH COOLDOWN
        // If current seconds is zero, is because we are entering the app,
        // so, perform an update
        if (_currentSecondsCounter == 0) {
          _currentSecondsCounter = _chainModel.chain.cooldown;
          _refreshCooldownClock(_chainModel.chain.cooldown);
        }
        // Thereafter, only update if what we get from the API is below the
        // current automatic timer, or the last thing we have is chaining
        if (_chainModel.chain.cooldown < _currentSecondsCounter || _wereWeChaining) {
          _currentSecondsCounter = _chainModel.chain.cooldown;
          _refreshCooldownClock(_chainModel.chain.cooldown);
          _wereWeChaining = false;
        }
      } else if (_chainModel.chain.current < 10) {
        // OPTION 3, CHAIN UNDER 10
        // Update if for some reason the count in the app is delayed
        // and the real timer is less in Torn
        if (_chainModel.chain.timeout < _currentSecondsCounter) {
          _currentSecondsCounter = _chainModel.chain.timeout;
          _refreshChainClock(_currentSecondsCounter);
        }
        // Below 10, update count but only update timer if it was at 0
        // at the beginning (otherwise count won't start)
        if (_chainModel.chain.current > _lastChainCount) {
          if (_currentSecondsCounter == 0) {
            _currentSecondsCounter = _chainModel.chain.timeout;
          }
          _lastChainCount = _chainModel.chain.current;
          _refreshChainClock(_currentSecondsCounter);
        }
      } else {
        // OPTION 4, CHAIN OF 10 OR MORE
        // Check if counts are different
        _wereWeChaining = true;
        if (_chainModel.chain.current > _lastChainCount) {
          _currentSecondsCounter = _chainModel.chain.timeout;
          _lastChainCount = _chainModel.chain.current;
          _refreshChainClock(_currentSecondsCounter);
        } else {
          // Else, even if the count has not changed,
          // take a look at the timer, in case it's delayed and update
          if (_chainModel.chain.timeout < _currentSecondsCounter) {
            _currentSecondsCounter = _chainModel.chain.timeout;
            _refreshChainClock(_currentSecondsCounter);
          }
        }
      }
    } else if (chainResponse is ApiError) {
      // Allowing for several tries of errors before returning ApiError
      // so we avoid showing a blank widget as much as possible
      if (_accumulatedErrors < 2 && !_modelError) {
        _accumulatedErrors++;
      } else {
        setState(() {
          _modelError = true;
        });
      }
    }
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
    if (mounted) {
      setState(() {
        _currentChainTimeString = '$timeOutMin:$timeOutSec';
      });
    }
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
    setState(() {
      _currentChainTimeString = '$timeOutHours:$timeOutMin:$timeOutSec';
    });
  }

  void _decreaseTimer() {
    if (_currentSecondsCounter > 0) {
      _currentSecondsCounter--;
    }
    if (!_modelError) {
      if (_chainModel.chain.cooldown > 0) {
        _refreshCooldownClock(_currentSecondsCounter);
      } else {
        _refreshChainClock(_currentSecondsCounter);
      }
    }
  }

  Future<void> _getEnergy() async {
    dynamic myBars = await TornApiCaller.bars(widget.userKey).getBars;
    setState(() {
      _barsModel = myBars;
    });
  }

  void _getAllStatus() {
    _getChainStatus();
    _getEnergy();
  }

  _assessChainBorderWidth() {
    switch (_chainWatcherColor) {
      case ChainWatcherColor.cooldown:
        return 20.0;
        break;
      case ChainWatcherColor.green1:
        return 20.0;
        break;
      case ChainWatcherColor.green2:
        return 20.0;
        break;
      case ChainWatcherColor.orange1:
        return 20.0;
        break;
      case ChainWatcherColor.orange2:
        return _chainBorderController.value * 20;
        break;
      case ChainWatcherColor.red:
        return _chainBorderController.value * 20;
        break;
      case ChainWatcherColor.off:
        return _chainBorderController.value * 0;
        break;
    }
  }

  void _activateChainWatcher() {
    if (widget.chainTimerParent == ChainTimerParent.targets) {
      _chainStatusProvider.watcherAssignParent(
        newParent: ChainTimerParent.targets,
        activate: true,
      );
    } else if (widget.chainTimerParent == ChainTimerParent.webView) {
      _chainStatusProvider.watcherAssignParent(
        newParent: ChainTimerParent.webView,
        activate: true,
      );
    }

    Wakelock.enable();
    _chainWatchCheck();
    BotToast.showText(
      text: 'Chain watcher activated!\n\nYour phone screen will '
          'remain on, consider plugging it in.',
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.green[700],
      duration: Duration(seconds: 5),
      contentPadding: EdgeInsets.all(10),
    );
  }

  void _deactivateChainWatcher() {
    Wakelock.disable();
    _chainBorderController.stop();
    setState(() {
      _chainStatusProvider.watcherDeactivate();
      _chainWatcherColor = ChainWatcherColor.off;
      _chainBorderColor = Colors.transparent;
    });
    BotToast.showText(
      text: 'Chain watcher deactivated!',
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.orange[700],
      duration: Duration(seconds: 5),
      contentPadding: EdgeInsets.all(10),
    );
  }

  Future<void> _chainWatchCheck() async {
    // Return if this is not the visible chain widget
    if ((!_chainStatusProvider.watcherActiveTargets &&
            widget.chainTimerParent == ChainTimerParent.targets) ||
        (!_chainStatusProvider.watcherActiveWebView &&
            widget.chainTimerParent == ChainTimerParent.webView)) {

      if (_chainWatcherColor != ChainWatcherColor.off) {
        _chainBorderController.stop();
        setState(() {
          _chainWatcherColor = ChainWatcherColor.off;
          _chainBorderColor = Colors.transparent;
        });
      }

      return;
    }

    // Return if there is an error with the model
    if (_modelError) {
      if (_chainWatcherColor != ChainWatcherColor.off) {
        _chainBorderController.stop();
        setState(() {
          _chainWatcherColor = ChainWatcherColor.off;
          _chainBorderColor = Colors.transparent;
        });
      }
      return;
    }

    // If under cooldown, apply blue color and return
    if (_chainModel.chain.cooldown > 0) {
      if (_chainWatcherColor != ChainWatcherColor.cooldown) {
        _chainBorderController.stop();
        setState(() {
          _chainWatcherColor = ChainWatcherColor.cooldown;
          _chainBorderColor = Colors.blue[200];
        });
      }
      return;
    }

    if (_chainModel.chain.current >= 10 && _currentSecondsCounter > 1) {
      if (_currentSecondsCounter < 60) {
        // Checking if it's already assigned to a color, prevents the animation from resetting,
        // which looks like a glitch to the user
        if (_chainWatcherColor != ChainWatcherColor.red) {
          // We stop and restart the animation otherwise. This will continue and repeat until
          // replaced by another animation
          _chainBorderController.stop();
          _chainBorderController =
              new AnimationController(vsync: this, duration: new Duration(milliseconds: 750))
                ..repeat();
          // If another chain widget already raised an alert (which is controlled by the provider),
          // we won't raise it again. Otherwise, sound/vibrate as applicable.
          if (_chainStatusProvider.watcherColorReportedByActive != ChainWatcherColor.red) {
            if (_chainStatusProvider.soundActive){
              audioCache.play('../sounds/alerts/warning.wav');
            }
            if (_chainStatusProvider.vibrationActive) {
              _vibrate(3);
            }
            _chainStatusProvider.watcherColorReportedByActive = ChainWatcherColor.red;
          }
          // Update colors and borders in the animation
          setState(() {
            _chainWatcherColor = ChainWatcherColor.red;
            _chainBorderColor = Colors.red;
          });
        }
      } else if (_currentSecondsCounter >= 60 && _currentSecondsCounter < 120) {
        if (_chainWatcherColor != ChainWatcherColor.orange2) {
          _chainBorderController.stop();
          _chainBorderController = new AnimationController(
            vsync: this,
            duration: new Duration(milliseconds: 1500),
          )..repeat();
          if (_chainStatusProvider.watcherColorReportedByActive != ChainWatcherColor.orange2) {
            if (_chainStatusProvider.soundActive){
              audioCache.play('../sounds/alerts/alert2.wav');
            }
            if (_chainStatusProvider.vibrationActive) {
              _vibrate(2);
            }
            _chainStatusProvider.watcherColorReportedByActive = ChainWatcherColor.orange2;
          }
          setState(() {
            _chainWatcherColor = ChainWatcherColor.orange2;
            _chainBorderColor = Colors.orange;
          });
        }
      } else if (_currentSecondsCounter >= 120 && _currentSecondsCounter < 180) {
        if (_chainWatcherColor != ChainWatcherColor.orange1) {
          _chainBorderController.stop();
          if (_chainStatusProvider.watcherColorReportedByActive != ChainWatcherColor.orange1) {
            if (_chainStatusProvider.soundActive){
              audioCache.play('../sounds/alerts/alert1.wav');
            }
            _chainStatusProvider.watcherColorReportedByActive = ChainWatcherColor.orange1;
          }
          setState(() {
            _chainWatcherColor = ChainWatcherColor.orange1;
            _chainBorderColor = Colors.orange;
          });
        }
      } else {
        if (_chainWatcherColor != ChainWatcherColor.green2) {
          _chainBorderController.stop();
          _chainStatusProvider.watcherColorReportedByActive = ChainWatcherColor.green2;
          setState(() {
            _chainWatcherColor = ChainWatcherColor.green2;
            _chainBorderColor = Colors.green;
          });
        }
      }
    } else {
      if (_chainWatcherColor != ChainWatcherColor.green1) {
        _chainBorderController.stop();
        _chainStatusProvider.watcherColorReportedByActive = ChainWatcherColor.green1;
        setState(() {
          _chainWatcherColor = ChainWatcherColor.green1;
          _chainBorderColor = Colors.green[200];
        });
      }
    }
  }

  _vibrate(int times) async {
    if (await Vibration.hasVibrator()) {
      for (var i = 0; i < times; i++) {
        Vibration.vibrate();
        await Future.delayed(Duration(milliseconds: 1000));
      }
    }
  }
}
