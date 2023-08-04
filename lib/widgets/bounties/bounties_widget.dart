// Flutter imports:
// Package imports:
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/models/bounties/bounties_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class BountiesWidget extends StatefulWidget {
  final InAppWebViewController? webview;
  final Function fireScriptCallback;

  const BountiesWidget({
    required this.webview,
    required this.fireScriptCallback,
    super.key,
  });

  @override
  _BountiesWidgetState createState() => _BountiesWidgetState();
}

class _BountiesWidgetState extends State<BountiesWidget> {
  final _scrollController = ScrollController();
  final _expandableController = ExpandableController();

  Future? _getPreferences;

  late BountiesModel _bountiesModel;
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
                            "Max level: ${_bountiesModel.levelMax}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Text(
                          'BOUNTIES',
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
                            "Unavailable: ${_bountiesModel.removeRed ? "hide" : "show"}",
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
        _levelSlider(),
        _bailEnabled(),
      ],
    );
  }

  Row _levelSlider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Text(
            "Max level",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Row(
          children: [
            Slider(
              value: _bountiesModel.levelMax.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (value) {
                setState(() {
                  _bountiesModel.levelMax = value.toInt();
                });
                widget.fireScriptCallback(_bountiesModel);
                _saveModel();
              },
            ),
            Text(
              _bountiesModel.levelMax.toString(),
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

  Row _bailEnabled() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Unavailable (red) targets",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        Row(
          children: [
            Switch(
              value: _bountiesModel.removeRed,
              activeColor: Colors.green,
              activeTrackColor: Colors.green[200],
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.red[200],
              onChanged: (active) {
                setState(() {
                  _bountiesModel.removeRed = active;
                });
                widget.fireScriptCallback(_bountiesModel);
                _saveModel();
              },
            ),
            Text(
              _bountiesModel.removeRed ? "Hide" : "Show",
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
    final savedJson = await Prefs().getBountiesModel();
    if (savedJson.isNotEmpty) {
      _bountiesModel = bountiesModelFromJson(savedJson);
    } else {
      _bountiesModel = BountiesModel()
        ..levelMax = 100
        ..removeRed = false;
    }

    widget.fireScriptCallback(_bountiesModel);
  }

  void _saveModel() {
    _bountiesModel
      ..levelMax = _bountiesModel.levelMax
      ..removeRed = _bountiesModel.removeRed;

    Prefs().setBountiesModel(bountiesModelToJson(_bountiesModel));
  }
}
