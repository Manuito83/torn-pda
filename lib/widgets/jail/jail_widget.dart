// Flutter imports:
// Package imports:
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
                            "Level: ${_jailModel.levelMin}-${_jailModel.levelMax}",
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
        _bustEnabler(),
        _levelSlider(),
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
        ..bailTicker = false
        ..bustTicked = false;
    }

    widget.fireScriptCallback(_jailModel);
  }

  void _saveModel() {
    // ! TODO
    _jailModel
      ..levelMin = _jailModel.levelMin
      ..levelMax = _jailModel.levelMax
      ..timeMin = 0
      ..timeMax = 100
      ..scoreMax = 250000
      ..bailTicker = false
      ..bustTicked = _jailModel.bustTicked;

    Prefs().setJailModel(jailModelToJson(_jailModel));
  }
}
