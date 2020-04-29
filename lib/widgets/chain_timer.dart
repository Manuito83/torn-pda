import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';

class ChainTimer extends StatefulWidget {
  final String userKey;

  ChainTimer({Key key, @required this.userKey}) : super(key: key);

  @override
  _ChainTimerState createState() => _ChainTimerState();
}

class _ChainTimerState extends State<ChainTimer> {
  ThemeProvider _themeProvider;

  Future _finishedLoadingChain;

  Timer _tickerDecreaseCount;
  Timer _tickerCallChainApi;

  String _currentChainTimeString = '';
  int _currentSecondsCounter = 0;
  dynamic _chainModel;

  dynamic _barsModel;
  Future _finishedGettingBars;

  int _lastChainCount = 0;

  int _accumulatedErrors = 0;

  bool _wereWeChaining = false;

  @override
  void initState() {
    super.initState();
    _finishedLoadingChain = _getChainStatus();
    _finishedGettingBars = _getEnergy();
    _tickerDecreaseCount = new Timer.periodic(
        Duration(seconds: 1), (Timer t) => _autoDecreaseChainTimer());
    _tickerCallChainApi =
        new Timer.periodic(Duration(seconds: 10), (Timer t) => _getAllStatus());
  }

  @override
  void dispose() {
    _tickerDecreaseCount.cancel();
    _tickerCallChainApi.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          FutureBuilder(
            future: _finishedLoadingChain,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (_chainModel is ChainModel) {
                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _chainModel.chain.cooldown > 0
                                  ? 'Cooldown '
                                  : 'Chain ',
                            ),
                            Text(
                              '$_currentChainTimeString',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _currentSecondsCounter > 0 &&
                                        _currentSecondsCounter < 60 &&
                                        _chainModel.chain.cooldown == 0
                                    ? Colors.red
                                    : _themeProvider.mainText,
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
                        percent: (_barsModel.energy.current /
                                    _barsModel.energy.maximum) >
                                1.0
                            ? 1.0
                            : _barsModel.energy.current /
                                _barsModel.energy.maximum,
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
                        percent: 1 -
                            _barsModel.energy.ticktime /
                                _barsModel.energy.interval,
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
    );
  }

  Future<void> _getChainStatus() async {
    var chainResponse =
        await TornApiCaller.chain(widget.userKey).getChainStatus;
    if (chainResponse is ChainModel) {
      _accumulatedErrors = 0;
      _chainModel = chainResponse;

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
        if (_chainModel.chain.cooldown < _currentSecondsCounter ||
            _wereWeChaining) {
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
      if (_accumulatedErrors == 2) {
        // In this case, we need to call setstate, in other cases
        // setstate has already been called
        setState(() {
          _chainModel = ApiError();
        });
        _accumulatedErrors = 0;
      } else {
        _accumulatedErrors++;
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
    setState(() {
      _currentChainTimeString = '$timeOutMin:$timeOutSec';
    });
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

  void _autoDecreaseChainTimer() {
    if (_currentSecondsCounter > 0) {
      _currentSecondsCounter--;
    }
    if (_chainModel is ChainModel) {
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
}
