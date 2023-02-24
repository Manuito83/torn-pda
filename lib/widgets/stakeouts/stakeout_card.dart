// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

// Package imports:
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class StakeoutCard extends StatefulWidget {
  final Stakeout stakeout;

  // Key is needed to update at least the hospital counter individually
  StakeoutCard({
    @required this.stakeout,
    @required Key key,
  }) : super(key: key);

  @override
  _StakeoutCardState createState() => _StakeoutCardState();
}

class _StakeoutCardState extends State<StakeoutCard> {
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  WebViewProvider _webViewProvider;

  Stakeout _stakeout;
  final StakeoutsController _s = Get.put(StakeoutsController());

  var _expandableController = ExpandableController();

  String _currentLifeString = "";
  String _lastUpdatedString;
  int _lastUpdatedMinutes;

  @override
  void initState() {
    super.initState();
    _stakeout = widget.stakeout;
    _webViewProvider = context.read<WebViewProvider>();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _expandableController.expanded = _stakeout.cardExpanded;
    _expandableController.addListener(() {
      _s.setCardExpanded(stakeout: _stakeout, cardExpanded: _expandableController.expanded);
    });
  }

  @override
  void dispose() {
    //_expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Slidable(
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            label: 'Delete',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (context) {
              _s.removeStakeout(removeId: _stakeout.id);
            },
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          elevation: 2,
          child: ClipPath(
            clipper: ShapeBorderClipper(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: ExpandablePanel(
              collapsed: null,
              controller: _expandableController,
              header: _header(),
              expanded: _footer(),
            ),
          ),
        ),
      ),
    );
  }

  Column _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // LINE 1
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12, 5, 10, 0),
          child: Row(
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GestureDetector(
                    child: Row(
                      children: [
                        Icon(MdiIcons.cctv),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        SizedBox(
                          width: 95,
                          child: Text(
                            '${_stakeout.name}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _openBrowser();
                    },
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    // If last fetch was more than 10 minutes ago, we don't should Status details
                    if (DateTime.now().millisecondsSinceEpoch - _stakeout.lastFetch < 600000)
                      Row(
                        children: <Widget>[
                          _travelIcon(),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _returnStatusColor(_stakeout.lastAction.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 13),
                            child: Text(
                              _stakeout.lastAction.relative == "0 minutes ago"
                                  ? 'now'
                                  : _stakeout.lastAction.relative.replaceAll(' ago', ''),
                            ),
                          ),
                        ],
                      )
                    else
                      Text("no recent update", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              )
            ],
          ),
        ),
        // LINE 2
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12, 5, 10, 0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: Row(
                  children: [
                    if (!_s.isAnyOptionActive(stakeout: _stakeout))
                      Flexible(
                        child: Text(
                          "Nothing enabled, expand the card for options!",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.orange[800]),
                        ),
                      ),
                    if (_stakeout.okayEnabled)
                      GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Icon(
                            MdiIcons.checkBold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          _showTooltip("Is okay");
                        },
                      ),
                    if (_stakeout.hospitalEnabled)
                      GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Icon(
                            FontAwesome.ambulance,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                        onTap: () {
                          _showTooltip("Is hospitalized");
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // LINE 3
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(8, 5, 15, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 30,
                      height: 20,
                      child: IconButton(
                        padding: EdgeInsets.all(0),
                        iconSize: 20,
                        icon: Icon(
                          MdiIcons.notebookEditOutline,
                          size: 18,
                        ),
                        onPressed: () {
                          _showNotesDialog();
                        },
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Notes: ',
                      style: TextStyle(fontSize: 12),
                    ),
                    Flexible(
                      child: Text(
                        '${_stakeout.personalNote}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Padding _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Is okay"),
              Switch(
                value: _stakeout.okayEnabled,
                onChanged: (value) {
                  _s.setOkay(stakeout: _stakeout, okayEnabled: value);
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Is hospitalized"),
              Switch(
                value: _stakeout.hospitalEnabled,
                onChanged: (value) {
                  _s.setHospital(stakeout: _stakeout, hospitalEnabled: value);
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNotesDialog() {
    // TODO
    /*
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: PersonalNotesDialog(
              memberModel: _stakeout,
              noteType: PersonalNoteType.factionMember,
            ),
          ),
        );
      },
    );
    */
  }

  void _openBrowser() async {
    var browserType = _settingsProvider.currentBrowser;
    String url = 'https://www.torn.com/profiles.php?XID=${_stakeout.id}';
    switch (browserType) {
      case BrowserSetting.app:
        await _webViewProvider.openBrowserPreference(
          context: context,
          useDialog: _settingsProvider.useQuickBrowser,
          url: url,
        );
        break;
      case BrowserSetting.external:
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        break;
    }
  }

  void _showTooltip(String text) {
    BotToast.showText(
      text: text,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.blue,
      duration: const Duration(seconds: 2),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Widget _travelIcon() {
    var country = countryCheck(state: _stakeout.status.state, description: _stakeout.status.description);

    if (_stakeout.status.color == "blue" || (country != "Torn" && _stakeout.status.color == "red")) {
      var destination = _stakeout.status.color == "blue" ? _stakeout.status.description : country;
      var flag = '';
      if (destination.contains('Japan')) {
        flag = 'images/flags/stock/japan.png';
      } else if (destination.contains('Hawaii')) {
        flag = 'images/flags/stock/hawaii.png';
      } else if (destination.contains('China')) {
        flag = 'images/flags/stock/china.png';
      } else if (destination.contains('Argentina')) {
        flag = 'images/flags/stock/argentina.png';
      } else if (destination.contains('United Kingdom')) {
        flag = 'images/flags/stock/uk.png';
      } else if (destination.contains('Cayman')) {
        flag = 'images/flags/stock/cayman.png';
      } else if (destination.contains('South Africa')) {
        flag = 'images/flags/stock/south-africa.png';
      } else if (destination.contains('Switzerland')) {
        flag = 'images/flags/stock/switzerland.png';
      } else if (destination.contains('Mexico')) {
        flag = 'images/flags/stock/mexico.png';
      } else if (destination.contains('UAE')) {
        flag = 'images/flags/stock/uae.png';
      } else if (destination.contains('Canada')) {
        flag = 'images/flags/stock/canada.png';
      }

      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () {
            BotToast.showText(
              text: _stakeout.status.description,
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue,
              duration: Duration(seconds: 5),
              contentPadding: EdgeInsets.all(10),
            );
          },
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: RotatedBox(
                  quarterTurns: _stakeout.status.description.contains('Traveling to ')
                      ? 1 // If traveling to another country
                      : _stakeout.status.description.contains('Returning ')
                          ? 3 // If returning to Torn
                          : 0, // If staying abroad (blue but not moving)
                  child: Icon(
                    _stakeout.status.description.contains('In ')
                        ? Icons.location_city_outlined
                        : Icons.airplanemode_active,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Image.asset(
                  flag,
                  width: 16,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Color _returnStatusColor(String status) {
    switch (status) {
      case 'Online':
        return Colors.green;
        break;
      case 'Idle':
        return Colors.orange;
        break;
      default:
        return Colors.grey;
    }
  }
}
