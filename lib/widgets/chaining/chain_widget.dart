// Dart imports:
import 'dart:async';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
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

  final _chainStatusProvider = Get.find<ChainStatusController>();

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
    initialise();
    _chainStatusProvider.widgetVisible = true;

    Color? titleColor;
    if (widget.alwaysDarkBackground) {
      titleColor = Colors.white;
    } else {
      titleColor = _themeProvider.mainText;
    }

    return GetBuilder(
      builder: (ChainStatusController chainP) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          child: Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: chainP.borderColor,
                  width: _assessChainBorderWidth(),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!chainP.panicModeEnabled) const SizedBox(width: 35), // Centers the widget without P icon
                  SizedBox(
                    width: 30,
                    child: !chainP.modelError || (chainP.modelError && chainP.chainWatcherDefcon == WatchDefcon.apiFail)
                        ? GestureDetector(
                            child: Icon(
                              MdiIcons.eyeOutline,
                              color: chainP.watcherActive
                                  ? widget.alwaysDarkBackground
                                      ? Colors.orange[700]
                                      : Colors.orange[900]
                                  : widget.alwaysDarkBackground
                                      ? Colors.grey
                                      : _themeProvider.mainText,
                            ),
                            onTap: () {
                              setState(() {
                                if (chainP.watcherActive) {
                                  _deactivateChainWatcher();
                                } else {
                                  _activateChainWatcher();
                                }
                              });
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (chainP.panicModeEnabled)
                    SizedBox(
                      width: 35,
                      child: !chainP.modelError
                          ? GestureDetector(
                              child: Icon(
                                MdiIcons.alphaPCircleOutline,
                                color: chainP.panicModeActive
                                    ? widget.alwaysDarkBackground
                                        ? Colors.orange[700]
                                        : Colors.orange[900]
                                    : widget.alwaysDarkBackground
                                        ? Colors.grey
                                        : _themeProvider.mainText,
                              ),
                              onTap: () {
                                if (chainP.panicModeActive) {
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
                            if (!chainP.modelError) {
                              return Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          chainP.chainModel!.chain!.cooldown! > 0 ? 'Cooldown ' : 'Chain ',
                                          style: TextStyle(color: titleColor),
                                        ),
                                        Text(
                                          chainP.currentChainTimeString,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: chainP.currentSecondsCounter > 0 &&
                                                    chainP.currentSecondsCounter < 60 &&
                                                    chainP.chainModel!.chain!.cooldown == 0
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
                                    progressColor:
                                        chainP.chainModel!.chain!.cooldown! > 0 ? Colors.green[200] : Colors.blue[200],
                                    center: Text(
                                      chainP.chainModel!.chain!.cooldown! > 0
                                          ? '${chainP.chainModel!.chain!.current} hits'
                                          : '${chainP.chainModel!.chain!.current}/${chainP.chainModel!.chain!.max}',
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                    percent: chainP.chainModel!.chain!.cooldown! > 0
                                        ? 1.0
                                        : chainP.chainModel!.chain!.current! / chainP.chainModel!.chain!.max!,
                                  ),
                                ],
                              );
                            } else {
                              if (chainP.watcherActive && chainP.chainWatcherDefcon == WatchDefcon.apiFail) {
                                return Column(
                                  children: [
                                    Text(
                                      'API FAILED UNDER WATCH!',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.purple[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Last check @${chainP.currentChainTimeString}',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.purple[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              }
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
                            if (chainP.barsAndStatusModel is BarsStatusCooldownsModel) {
                              final bars = chainP.barsAndStatusModel;
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
                                      _formatEnergyText(bars?.energy?.current, bars?.energy?.maximum),
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                    percent: _calculateEnergyPercentage(bars?.energy?.current, bars?.energy?.maximum),
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
                                    percent: _calculateTickPercentage(bars?.energy?.ticktime, bars?.energy?.interval),
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
      },
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
      case WatchDefcon.apiFail:
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
        _finishedLoadingChain = _finishedGettingBars = _chainStatusProvider.activateChainWidgetStatusRequests();
      } else {
        _finishedLoadingChain = _finishedGettingBars = Future.value(true);
      }
    }
  }

  double _calculateEnergyPercentage(int? current, int? maximum) {
    if (current == null || maximum == null || maximum == 0) {
      return 0.0;
    }
    double percentage = current.toDouble() / maximum.toDouble();

    if (percentage > 1.0) return 1.0;
    if (percentage < 0.0) return 0.0;
    return percentage;
  }

  double _calculateTickPercentage(int? ticktime, int? interval) {
    if (ticktime == null || interval == null || interval == 0) {
      return 0.0;
    }
    double percentage = 1.0 - (ticktime.toDouble() / interval.toDouble());

    if (percentage > 1.0) return 1.0;
    if (percentage < 0.0) return 0.0;
    return percentage;
  }

  String _formatEnergyText(int? current, int? maximum) {
    if (current == null || maximum == null) {
      return '';
    }
    return 'E: $current/$maximum';
  }
}
