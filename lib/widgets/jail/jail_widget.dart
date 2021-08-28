// Flutter imports:
// Package imports:
import 'dart:math';

import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:non_linear_slider/models/interval.dart';
import 'package:non_linear_slider/non_linear_slider.dart';
import 'package:torn_pda/models/jail/jail_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class JailWidget extends StatefulWidget {
  final InAppWebViewController webview;
  final Function fireScriptCallback;

  const JailWidget({
    @required this.webview,
    @required this.fireScriptCallback,
    Key key,
  }) : super(key: key);

  @override
  _JailWidgetState createState() => _JailWidgetState();
}

class _JailWidgetState extends State<JailWidget> {
  // Log scale setup
  // Position will be between 0 and 1000
  final _minp = 0;
  final _maxp = 1000;
  // The result should be between 1 an 10000000
  final _minv = log(1);
  final _maxv = log(250000);

  final _scrollController = ScrollController();
  final _expandableController = ExpandableController();

  Future _getPreferences;

  JailModel _jailModel;
  bool _panelExpanded = false;

  @override
  void initState() {
    super.initState();

    _expandableController.addListener(() {
      if (_expandableController.expanded) {
        setState(() {
          _panelExpanded = true;
        });
      } else {
        setState(() {
          _panelExpanded = false;
        });
      }
    });

    _getPreferences = _getSaved();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getPreferences,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: ExpandablePanel(
              controller: _expandableController,
              theme: const ExpandableThemeData(
                hasIcon: false,
                iconColor: Colors.grey,
                tapBodyToExpand: true,
                tapHeaderToExpand: true,
                tapBodyToCollapse: false,
              ),
              header: Row(
                mainAxisAlignment: _panelExpanded ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                children: [
                  if (!_panelExpanded)
                    SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Quick bail: ${_jailModel.bailTicked ? 'ON' : 'OFF'}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            "Quick bust: ${_jailModel.bustTicked ? 'ON' : 'OFF'}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: 80,
                    child: Column(
                      children: const [
                        Text(
                          'JAIL',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                        Text(
                          '(tab to expand)',
                          style: TextStyle(color: Colors.orange, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  if (!_panelExpanded)
                    SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Time (h): ${_jailModel.timeMin}-${_jailModel.timeMax}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            "Level: ${_jailModel.levelMin}-${_jailModel.levelMax}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            "Score: ${_jailModel.scoreMax}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              collapsed: null,
              expanded: Padding(
                padding: const EdgeInsets.all(10),
                child: _vaultExpanded(),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _vaultExpanded() {
    return Column(
      children: [
        _bailEnabled(),
        _bustEnabler(),
        _timeSlider(),
        _levelSlider(),
        _scoreSlider(),
      ],
    );
  }

  Row _bailEnabled() {
    return Row(
      children: [
        const Text(
          "Quick bail",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 50),
        Switch(
          value: _jailModel.bailTicked,
          activeColor: Colors.green,
          activeTrackColor: Colors.green[200],
          inactiveThumbColor: Colors.red,
          inactiveTrackColor: Colors.red[200],
          onChanged: (active) {
            setState(() {
              _jailModel.bailTicked = active;
            });
            widget.fireScriptCallback(_jailModel);
            _saveModel();
          },
        )
      ],
    );
  }

  Row _bustEnabler() {
    return Row(
      children: [
        const Text(
          "Quick bust",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 50),
        Switch(
          value: _jailModel.bustTicked,
          activeColor: Colors.green,
          activeTrackColor: Colors.green[200],
          inactiveThumbColor: Colors.red,
          inactiveTrackColor: Colors.red[200],
          onChanged: (active) {
            setState(() {
              _jailModel.bustTicked = active;
            });
            widget.fireScriptCallback(_jailModel);
            _saveModel();
          },
        )
      ],
    );
  }

  Row _timeSlider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Time (h)",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        Row(
          children: [
            Text(
              _jailModel.timeMin.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            RangeSlider(
              values: RangeValues(_jailModel.timeMin.toDouble(), _jailModel.timeMax.toDouble()),
              max: 100,
              divisions: 100,
              onChanged: (RangeValues values) {
                setState(() {
                  _jailModel.timeMin = values.start.toInt();
                  _jailModel.timeMax = values.end.toInt();
                });
              },
              onChangeEnd: (RangeValues values) {
                widget.fireScriptCallback(_jailModel);
                _saveModel();
              },
            ),
            Text(
              _jailModel.timeMax.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Row _levelSlider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Level",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        Row(
          children: [
            Text(
              _jailModel.levelMin.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            RangeSlider(
              values: RangeValues(_jailModel.levelMin.toDouble(), _jailModel.levelMax.toDouble()),
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (RangeValues values) {
                setState(() {
                  _jailModel.levelMin = values.start.toInt();
                  _jailModel.levelMax = values.end.toInt();
                });
              },
              onChangeEnd: (RangeValues values) {
                widget.fireScriptCallback(_jailModel);
                _saveModel();
              },
            ),
            Text(
              _jailModel.levelMax.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Row _scoreSlider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Score",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        Row(
          children: [
            Text(
              _jailModel.scoreMax.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            NonLinearSlider(
              value: _jailModel.scoreMax.toDouble(),
              intervals: [
                NLSInterval(0, 175000, 0.80),
                NLSInterval(175000, 250000, 0.20),
              ],
              onChanged: (value) {
                setState(() {
                  _jailModel.scoreMax = value.toInt();
                });
              },
              onChangeEnd: (value) {
                widget.fireScriptCallback(_jailModel);
                _saveModel();
              },
            ),
          ],
        ),
      ],
    );
  }

  double logSlider(double position) {
    // Adjustment factor
    final scale = (_maxv - _minv) / (_maxp - _minp);

    return exp(_minv + scale * (position - _minp));
  }

  double logPosition(double value) {
    // Adjustment factor
    final scale = (_maxv - _minv) / (_maxp - _minp);

    return (log(value) - _minv) / scale + _minp;
  }

  Future _getSaved() async {
    final savedJson = await Prefs().getJailModel();
    if (savedJson.isNotEmpty) {
      _jailModel = jailModelFromJson(savedJson);
    } else {
      _jailModel = JailModel()
        ..levelMin = 1
        ..levelMax = 100
        ..timeMin = 0
        ..timeMax = 100
        ..scoreMax = 250000
        ..bailTicked = false
        ..bustTicked = false;
    }

    widget.fireScriptCallback(_jailModel);
  }

  void _saveModel() {
    _jailModel
      ..levelMin = _jailModel.levelMin
      ..levelMax = _jailModel.levelMax
      ..timeMin = _jailModel.timeMin
      ..timeMax = _jailModel.timeMax
      ..scoreMax = _jailModel.scoreMax
      ..bailTicked = _jailModel.bailTicked
      ..bustTicked = _jailModel.bustTicked;

    Prefs().setJailModel(jailModelToJson(_jailModel));
  }
}
