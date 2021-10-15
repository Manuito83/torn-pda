// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chaining/chain_widget_options.dart';

class ChainWidget extends StatefulWidget {
  final String userKey;
  final bool alwaysDarkBackground;

  ChainWidget({
    @required Key key,
    @required this.userKey,
    @required this.alwaysDarkBackground,
  }) : super(key: key);

  @override
  _ChainWidgetState createState() => _ChainWidgetState();
}

class _ChainWidgetState extends State<ChainWidget> {
  ThemeProvider _themeProvider;

  Future _finishedLoadingChain;
  Future _finishedGettingBars;

  ChainStatusProvider _chainStatusProvider;

  bool _initialised = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: true);
    initialise();

    Color titleColor;
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
              SizedBox(
                width: 40,
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
                    : SizedBox.shrink(),
              ),
              SizedBox(width: 5),
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
                                padding: EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      _chainStatusProvider.chainModel.chain.cooldown > 0 ? 'Cooldown ' : 'Chain ',
                                      style: TextStyle(color: titleColor),
                                    ),
                                    Text(
                                      _chainStatusProvider.currentChainTimeString,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _chainStatusProvider.currentSecondsCounter > 0 &&
                                                _chainStatusProvider.currentSecondsCounter < 60 &&
                                                _chainStatusProvider.chainModel.chain.cooldown == 0
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
                                progressColor: _chainStatusProvider.chainModel.chain.cooldown > 0
                                    ? Colors.green[200]
                                    : Colors.blue[200],
                                center: Text(
                                  _chainStatusProvider.chainModel.chain.cooldown > 0
                                      ? '${_chainStatusProvider.chainModel.chain.current} hits'
                                      : '${_chainStatusProvider.chainModel.chain.current}/${_chainStatusProvider.chainModel.chain.max}',
                                  style: TextStyle(color: Colors.black),
                                ),
                                percent: _chainStatusProvider.chainModel.chain.cooldown > 0
                                    ? 1.0
                                    : _chainStatusProvider.chainModel.chain.current /
                                        _chainStatusProvider.chainModel.chain.max,
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
                        if (_chainStatusProvider.barsModel is BarsModel) {
                          final bars = _chainStatusProvider.barsModel;
                          return Column(
                            children: <Widget>[
                              LinearPercentIndicator(
                                alignment: MainAxisAlignment.center,
                                width: 150,
                                lineHeight: 16,
                                backgroundColor: Colors.green[100],
                                progressColor: Colors.green,
                                center: Text(
                                  'E: ${bars.energy.current}/${bars.energy.maximum}',
                                  style: TextStyle(color: Colors.black),
                                ),
                                // Take drugs into account
                                percent: (bars.energy.current / bars.energy.maximum) > 1.0
                                    ? 1.0
                                    : bars.energy.current / bars.energy.maximum,
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
                                percent: 1 - bars.energy.ticktime / bars.energy.interval,
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
              SizedBox(
                width: 40,
                child: GestureDetector(
                  child: Icon(
                    Icons.settings,
                  ),
                  onTap: () {
                    Get.to(() => ChainWidgetOptions());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  var lastReported = ChainWatcherDefcon.red1;
  _assessChainBorderWidth() {
    switch (_chainStatusProvider.chainWatcherDefcon) {
      case ChainWatcherDefcon.cooldown:
        return 20.0;
        break;
      case ChainWatcherDefcon.green1:
        return 20.0;
        break;
      case ChainWatcherDefcon.green2:
        return 20.0;
        break;
      case ChainWatcherDefcon.orange1:
        return 20.0;
        break;
      case ChainWatcherDefcon.orange2:
        return 20.0;
        break;
      case ChainWatcherDefcon.red1:
        return 20.0;
        break;
      case ChainWatcherDefcon.red2:
        return 20.0;
        break;
      case ChainWatcherDefcon.off:
        return 0.0;
        break;
    }
  }

  void _activateChainWatcher() {
    _chainStatusProvider.activateWatcher();

    BotToast.showText(
      text: 'Chain watcher activated!'
          '\n\nYour phone screen will remain on, consider plugging it in.',
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.green[700],
      duration: Duration(seconds: 7),
      contentPadding: EdgeInsets.all(10),
    );
  }

  void _deactivateChainWatcher() {
    _chainStatusProvider.deactivateWatcher();

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
