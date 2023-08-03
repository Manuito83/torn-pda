// Flutter imports:
// Package imports:
import 'dart:math';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/jail/jail_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/jail/jail_record_dialog.dart';

class JailWidget extends StatefulWidget {
  final InAppWebViewController? webview;
  final Function fireScriptCallback;
  final String playerName;

  const JailWidget({
    required this.webview,
    required this.fireScriptCallback,
    required this.playerName,
    Key? key,
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

  Future? _getPreferences;

  late JailModel _jailModel;
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
                          Text(
                            "Show oneself: ${_jailModel.excludeSelf ? 'YES' : 'NO'}",
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
                          '(tap to expand)',
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
                            "Score: ${_jailModel.scoreMin} - ${_jailModel.scoreMax}",
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
              collapsed: Container(),
              expanded: Padding(
                padding: const EdgeInsets.all(5),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _bailEnabled(),
            _bustEnabler(),
          ],
        ),
        _excludeSelf(),
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
        const SizedBox(width: 10),
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
        const SizedBox(width: 10),
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

  Row _excludeSelf() {
    return Row(
      children: [
        const Text(
          "Always show oneself",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 10),
        Switch(
          value: _jailModel.excludeSelf,
          activeColor: Colors.green,
          activeTrackColor: Colors.green[200],
          inactiveThumbColor: Colors.red,
          inactiveTrackColor: Colors.red[200],
          onChanged: (active) {
            setState(() {
              _jailModel.excludeSelf = active;
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
        Flexible(
          child: const Text(
            "Time (h)",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        SizedBox(width: 5),
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
              inactiveColor: Colors.grey,
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
        Flexible(
          child: const Text(
            "Level",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        SizedBox(width: 5),
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
              inactiveColor: Colors.grey,
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

  /// From 0-40000, travel 50%
  /// From 40000-175000 travel 40%
  /// From 175000 to 250000 travel 10%
  double customScoreMapping(double value) {
    if (value <= 0.5) {
      return 40000 * value / 0.5;
    } else if (value <= 0.9) {
      return 40000 + (175000 - 40000) * (value - 0.5) / 0.4;
    } else {
      return 175000 + (250000 - 175000) * (value - 0.9) / 0.1;
    }
  }

  double customScoreReverseMapping(double value) {
    if (value <= 40000) {
      return 0.5 * value / 40000;
    } else if (value <= 175000) {
      return 0.5 + 0.4 * (value - 40000) / (175000 - 40000);
    } else {
      return 0.9 + 0.1 * (value - 175000) / (250000 - 175000);
    }
  }

  Row _scoreSlider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Score Min ${_jailModel.scoreMin.toString()}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
            Text(
              "Score Max ${_jailModel.scoreMax.toString()}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 164,
                child: FlutterSlider(
                  min: 0,
                  max: 1,
                  step: FlutterSliderStep(step: 0.01),
                  values: [
                    customScoreReverseMapping(_jailModel.scoreMin.toDouble()),
                    customScoreReverseMapping(_jailModel.scoreMax.toDouble()),
                  ],
                  rangeSlider: true,
                  onDragging: (handlerIndex, lower, upper) {
                    double lowerActualValue = customScoreMapping(lower);
                    double upperActualValue = customScoreMapping(upper);
                    setState(() {
                      _jailModel.scoreMin = lowerActualValue.toInt();
                      _jailModel.scoreMax = upperActualValue.toInt();
                    });
                  },
                  onDragCompleted: (handlerIndex, lower, upper) {
                    widget.fireScriptCallback(_jailModel);
                    _saveModel();
                  },
                  handler: FlutterSliderHandler(
                    decoration: BoxDecoration(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).primaryColor,
                      ),
                      height: 22,
                      width: 22,
                    ),
                  ),
                  rightHandler: FlutterSliderHandler(
                    decoration: BoxDecoration(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).primaryColor,
                      ),
                      height: 22,
                      width: 22,
                    ),
                  ),
                  handlerWidth: 20,
                  handlerHeight: 20,
                  trackBar: FlutterSliderTrackBar(
                    activeTrackBarHeight: 5,
                    inactiveTrackBarHeight: 4,
                    inactiveTrackBar: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey,
                    ),
                    activeTrackBar: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  tooltip: FlutterSliderTooltip(
                    disabled: false,
                    custom: (value) {
                      double actualValue = customScoreMapping(value);
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.black,
                        ),
                        child: Text(
                          actualValue.toStringAsFixed(0),
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            GestureDetector(
              child: const Icon(MdiIcons.alarmPanelOutline, color: Colors.white70, size: 21),
              onTap: () {
                showDialog<void>(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    return JailRecordDialog(
                      currentRecord: _jailModel.scoreMax,
                      recordCallback: recordFormCallback,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void recordFormCallback(int newRecord) {
    setState(() {
      _jailModel.scoreMax = newRecord;
    });
    widget.fireScriptCallback(_jailModel);
    _saveModel();
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
        ..scoreMin = 0
        ..scoreMax = 250000
        ..bailTicked = false
        ..bustTicked = false
        ..excludeSelf = false
        ..excludeName = widget.playerName.toUpperCase();
      //widget.playerName;
    }

    widget.fireScriptCallback(_jailModel);
  }

  void _saveModel() {
    _jailModel
      ..levelMin = _jailModel.levelMin
      ..levelMax = _jailModel.levelMax
      ..timeMin = _jailModel.timeMin
      ..timeMax = _jailModel.timeMax
      ..scoreMin = _jailModel.scoreMin
      ..scoreMax = _jailModel.scoreMax
      ..bailTicked = _jailModel.bailTicked
      ..bustTicked = _jailModel.bustTicked
      ..excludeSelf = _jailModel.excludeSelf
      ..excludeName = widget.playerName.toUpperCase();

    Prefs().setJailModel(jailModelToJson(_jailModel));
  }
}
