// Dart imports:
import 'dart:async';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chaining/chain_widget_options.dart';

class ChainWidget extends StatefulWidget {
  final bool alwaysDarkBackground;
  final Function? callBackOptions;

  const ChainWidget({
    required Key key,
    required this.alwaysDarkBackground,
    this.callBackOptions,
  }) : super(key: key);

  @override
  ChainWidgetState createState() => ChainWidgetState();
}

class ChainWidgetState extends State<ChainWidget> {
  late ThemeProvider _themeProvider;

  Future? _finishedLoadingChain;
  Future? _finishedGettingBars;

  late ChainStatusProvider _chainStatusProvider;

  bool _initialised = false;

  @override
  void dispose() {
    if (!_chainStatusProvider.watcherActive) {
      _chainStatusProvider.widgetVisible = false;
      _chainStatusProvider.tryToDeactivateStatus();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context);
    initialise();
    _chainStatusProvider.widgetVisible = true;

    Color? titleColor;
    if (widget.alwaysDarkBackground) {
      titleColor = Colors.white;
    } else {
      titleColor = _themeProvider.mainText;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Container(
        decoration: BoxDecoration(
          border: Border.symmetric(
            vertical: BorderSide(
              color: _chainStatusProvider.borderColor,
              width: _assessChainBorderWidth(),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_chainStatusProvider.panicModeEnabled)
                const SizedBox(width: 35), // Centers the widget without P icon
              SizedBox(
                width: 30,
                child: !_chainStatusProvider.modelError
                    ? GestureDetector(
                        child: Icon(
                          MdiIcons.eyeOutline,
                          color: _chainStatusProvider.watcherActive
                              ? widget.alwaysDarkBackground
                                  ? Colors.orange[700]
                                  : Colors.orange[900]
                              : widget.alwaysDarkBackground
                                  ? Colors.grey
                                  : _themeProvider.mainText,
                        ),
                        onTap: () {
                          setState(() {
                            if (_chainStatusProvider.watcherActive) {
                              _deactivateChainWatcher();
                            } else {
                              _activateChainWatcher();
                            }
                          });
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              if (_chainStatusProvider.panicModeEnabled)
                SizedBox(
                  width: 35,
                  child: !_chainStatusProvider.modelError
                      ? GestureDetector(
                          child: Icon(
                            MdiIcons.alphaPCircleOutline,
                            color: _chainStatusProvider.panicModeActive
                                ? widget.alwaysDarkBackground
                                    ? Colors.orange[700]
                                    : Colors.orange[900]
                                : widget.alwaysDarkBackground
                                    ? Colors.grey
                                    : _themeProvider.mainText,
                          ),
                          onTap: () {
                            if (_chainStatusProvider.panicModeActive) {
                              _deactivatePanicMode();
                            } else {
                              _activatePanicMode();
                            }
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              const SizedBox(width: 10),
              Column(
                children: <Widget>[
                  FutureBuilder(
                    future: _finishedLoadingChain,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (!_chainStatusProvider.modelError) {
                          return Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      _chainStatusProvider.chainModel!.chain!.cooldown > 0 ? 'Cooldown ' : 'Chain ',
                                      style: TextStyle(color: titleColor),
                                    ),
                                    Text(
                                      _chainStatusProvider.currentChainTimeString,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _chainStatusProvider.currentSecondsCounter > 0 &&
                                                _chainStatusProvider.currentSecondsCounter < 60 &&
                                                _chainStatusProvider.chainModel!.chain!.cooldown == 0
                                            ? Colors.red
                                            : titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              LinearPercentIndicator(
                                padding: const EdgeInsets.all(0),
                                barRadius: const Radius.circular(10),
                                alignment: MainAxisAlignment.center,
                                width: 150,
                                lineHeight: 16,
                                backgroundColor: Colors.grey,
                                progressColor: _chainStatusProvider.chainModel!.chain!.cooldown > 0
                                    ? Colors.green[200]
                                    : Colors.blue[200],
                                center: Text(
                                  _chainStatusProvider.chainModel!.chain!.cooldown > 0
                                      ? '${_chainStatusProvider.chainModel!.chain!.current} hits'
                                      : '${_chainStatusProvider.chainModel!.chain!.current}/${_chainStatusProvider.chainModel!.chain!.max}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                percent: _chainStatusProvider.chainModel!.chain!.cooldown > 0
                                    ? 1.0
                                    : _chainStatusProvider.chainModel!.chain!.current /
                                        _chainStatusProvider.chainModel!.chain!.max,
                              ),
                            ],
                          );
                        } else {
                          return Text(
                            'Cannot retrieve chain details!',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange[800]),
                          );
                        }
                      } else {
                        return const SizedBox(height: 30);
                      }
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                  ),
                  FutureBuilder(
                    future: _finishedGettingBars,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (_chainStatusProvider.barsModel is BarsModel) {
                          final bars = _chainStatusProvider.barsModel;
                          return Column(
                            children: <Widget>[
                              LinearPercentIndicator(
                                padding: const EdgeInsets.all(0),
                                barRadius: const Radius.circular(10),
                                alignment: MainAxisAlignment.center,
                                width: 150,
                                lineHeight: 16,
                                backgroundColor: Colors.green[100],
                                progressColor: Colors.green,
                                center: Text(
                                  'E: ${bars.energy.current}/${bars.energy.maximum}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                // Take drugs into account
                                percent: (bars.energy.current / bars.energy.maximum) > 1.0
                                    ? 1.0
                                    : bars.energy.current / bars.energy.maximum,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                              ),
                              LinearPercentIndicator(
                                padding: const EdgeInsets.all(0),
                                barRadius: const Radius.circular(10),
                                alignment: MainAxisAlignment.center,
                                width: 150,
                                lineHeight: 3,
                                backgroundColor: Colors.green[100],
                                progressColor: Colors.green,
                                percent: 1 - bars.energy.ticktime / bars.energy.interval as double,
                              ),
                            ],
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 30,
                child: GestureDetector(
                  child: Icon(
                    Icons.settings_outlined,
                    color: widget.alwaysDarkBackground ? Colors.grey : _themeProvider.mainText,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => ChainWidgetOptions(
                          callBackOptions: _callBackChainOptions,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 35,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _callBackChainOptions() {
    if (widget.callBackOptions != null) {
      setState(() {
        widget.callBackOptions!();
      });
    }
  }

  WatchDefcon lastReported = WatchDefcon.red1;
  double _assessChainBorderWidth() {
    switch (_chainStatusProvider.chainWatcherDefcon) {
      case WatchDefcon.cooldown:
        return 20.0;
      case WatchDefcon.green1:
        return 20.0;
      case WatchDefcon.green2:
        return 20.0;
      case WatchDefcon.orange1:
        return 20.0;
      case WatchDefcon.orange2:
        return 20.0;
      case WatchDefcon.red1:
        return 20.0;
      case WatchDefcon.red2:
        return 20.0;
      case WatchDefcon.off:
        return 0.0;
      case WatchDefcon.panic:
        return 20.0;
    }
  }

  void _activateChainWatcher({bool withPanic = false}) {
    _chainStatusProvider.activateWatcher();

    String message = 'Chain watcher activated!\n\nYour phone screen will remain on, consider plugging it in.';
    if (withPanic) {
      message = 'Panic mode activated!\n\nYour phone screen will remain on, consider plugging it in.';
    }

    BotToast.showText(
      text: message,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.green[700]!,
      duration: const Duration(seconds: 7),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  void _deactivateChainWatcher() {
    _chainStatusProvider.deactivateWatcher();

    if (_chainStatusProvider.panicModeActive) {
      _chainStatusProvider.deactivatePanicMode();
    }

    BotToast.showText(
      text: 'Chain watcher deactivated!',
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.orange[700]!,
      duration: const Duration(seconds: 5),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  void _activatePanicMode() {
    _chainStatusProvider.activatePanicMode();

    String message = 'Panic mode activated!';
    if (!_chainStatusProvider.watcherActive) {
      message = 'Chain watcher and panic mode have been activated!'
          '\n\nYour phone screen will remain on, consider plugging it in.';
      _chainStatusProvider.activateWatcher();
    }

    BotToast.showText(
      text: message,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.green[700]!,
      duration: const Duration(seconds: 7),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  void _deactivatePanicMode() {
    _chainStatusProvider.deactivatePanicMode();

    BotToast.showText(
      text: 'Panic mode deactivated!',
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.orange[700]!,
      duration: const Duration(seconds: 5),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  initialise() {
    if (!_initialised || _chainStatusProvider.chainModel == null) {
      _initialised = true;
      if (!_chainStatusProvider.statusActive) {
        _finishedLoadingChain = _finishedGettingBars = _chainStatusProvider.activateStatus();
      } else {
        _finishedLoadingChain = _finishedGettingBars = Future.value(true);
      }
    }
  }
}
