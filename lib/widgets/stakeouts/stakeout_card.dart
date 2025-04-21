// Dart imports:
import 'dart:async';
import 'dart:math' as math;

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
// Package imports:
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/widgets/notes_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class StakeoutCard extends StatefulWidget {
  final Stakeout stakeout;

  // Key is needed to update at least the hospital counter individually
  const StakeoutCard({
    required this.stakeout,
    required Key key,
  }) : super(key: key);

  @override
  StakeoutCardState createState() => StakeoutCardState();
}

class StakeoutCardState extends State<StakeoutCard> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;

  Stakeout? _stakeout;
  final StakeoutsController _s = Get.find<StakeoutsController>();

  final _expandableController = ExpandableController();

  final _lifePercentageTextController = TextEditingController();
  final _lifePercentageFormController = GlobalKey<FormState>();

  final _offlineHoursTextController = TextEditingController();
  final _offlineHoursFormController = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _stakeout = widget.stakeout;
    _webViewProvider = context.read<WebViewProvider>();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _expandableController.expanded = _stakeout!.cardExpanded;
    _expandableController.addListener(() {
      _s.setCardExpanded(stakeout: _stakeout, cardExpanded: _expandableController.expanded);
    });

    _lifePercentageTextController.text = _stakeout!.lifeBelowPercentageLimit.toString();
    _offlineHoursTextController.text = _stakeout!.offlineLongerThanLimit.toString();
  }

  @override
  void dispose() {
    //_expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Slidable(
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            label: 'Delete',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (context) {
              _s.removeStakeout(removeId: _stakeout!.id);
            },
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
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
              collapsed: Container(),
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
          padding: const EdgeInsetsDirectional.fromSTEB(12, 5, 10, 0),
          child: Row(
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GestureDetector(
                    child: Row(
                      children: [
                        const Icon(MdiIcons.cctv),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        SizedBox(
                          width: 95,
                          child: Text(
                            '${_stakeout!.name}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _openBrowser(shortTap: true);
                    },
                    onLongPress: () {
                      _openBrowser(shortTap: true);
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    // If last fetch was more than 10 minutes ago, we don't update status details
                    if (DateTime.now().millisecondsSinceEpoch - _stakeout!.lastFetch! < 600000)
                      Row(
                        children: <Widget>[
                          _travelIcon(),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _returnStatusColor(_stakeout!.lastAction!.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 13),
                            child: Text(
                              _stakeout!.lastAction!.relative == "0 minutes ago"
                                  ? 'now'
                                  : _stakeout!.lastAction!.relative!.replaceAll(' ago', ''),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text("no recent update", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              )
            ],
          ),
        ),
        // LINE 2
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 5, 10, 0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: Row(
                  children: [
                    if (!_s.isAnyOptionActive(stakeout: _stakeout!))
                      Flexible(
                        child: Text(
                          "Nothing enabled, expand the card for options!",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.orange[800]),
                        ),
                      ),
                    if (_stakeout!.okayEnabled)
                      GestureDetector(
                        child: const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(
                            MdiIcons.checkBold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          _showTooltip("Is okay");
                        },
                      ),
                    if (_stakeout!.hospitalEnabled)
                      GestureDetector(
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
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
                    if (_stakeout!.revivableEnabled)
                      GestureDetector(
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.monitor_heart_outlined,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          _showTooltip("Is revivable");
                        },
                      ),
                    if (_stakeout!.landedEnabled)
                      GestureDetector(
                        child: const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(
                            MdiIcons.airplaneLanding,
                            color: Colors.blue,
                          ),
                        ),
                        onTap: () {
                          _showTooltip("Has landed");
                        },
                      ),
                    if (_stakeout!.onlineEnabled)
                      GestureDetector(
                        child: const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(
                            MdiIcons.circle,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          _showTooltip("Is online");
                        },
                      ),
                    if (_stakeout!.lifeBelowPercentageEnabled)
                      GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Transform.rotate(
                            angle: 90 * math.pi / 180,
                            child: const Icon(MdiIcons.glassStange, color: Colors.red),
                          ),
                        ),
                        onTap: () {
                          _showTooltip("Life below ${_stakeout!.lifeBelowPercentageLimit}%");
                        },
                      ),
                    if (_stakeout!.offlineLongerThanEnabled)
                      GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Icon(Icons.hourglass_bottom_outlined, color: Colors.orange[800]),
                        ),
                        onTap: () {
                          _showTooltip("Offline time longer than${_stakeout!.offlineLongerThanEnabled} hours");
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
          padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 15, 0),
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
                        padding: const EdgeInsets.all(0),
                        iconSize: 20,
                        icon: const Icon(
                          MdiIcons.notebookEditOutline,
                          size: 18,
                        ),
                        onPressed: () {
                          _showNotesDialog();
                        },
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Notes: ',
                      style: TextStyle(fontSize: 12),
                    ),
                    Flexible(
                      child: Text(
                        _stakeout!.personalNote,
                        style: TextStyle(fontSize: 12, color: _returnTargetNoteColor()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Padding _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Is okay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Row(
                children: [
                  SizedBox(
                    width: 25,
                    child: Icon(
                      MdiIcons.checkBold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text("Is okay"),
                ],
              ),
              Switch(
                value: _stakeout!.okayEnabled,
                onChanged: (value) {
                  _s.setOkay(stakeout: _stakeout, okayEnabled: value);
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
          // Hospitalized
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Row(
                children: [
                  SizedBox(
                    width: 25,
                    child: Icon(
                      FontAwesome.ambulance,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text("Is hospitalized"),
                ],
              ),
              Switch(
                value: _stakeout!.hospitalEnabled,
                onChanged: (value) {
                  _s.setHospital(stakeout: _stakeout, hospitalEnabled: value);
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
          // Revivable
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Row(
                children: [
                  SizedBox(
                    width: 25,
                    child: Icon(
                      Icons.monitor_heart_outlined,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text("Is revivable"),
                ],
              ),
              Switch(
                value: _stakeout!.revivableEnabled,
                onChanged: (value) {
                  _s.setRevivable(stakeout: _stakeout, revivableEnabled: value);
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
          // Has landed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Row(
                children: [
                  SizedBox(
                    width: 25,
                    child: Icon(
                      MdiIcons.airplaneLanding,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text("Has landed"),
                ],
              ),
              Switch(
                value: _stakeout!.landedEnabled,
                onChanged: (value) {
                  _s.setLanded(stakeout: _stakeout, landedEnabled: value);
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
          // Comes online
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Row(
                children: [
                  SizedBox(
                    width: 25,
                    child: Icon(
                      MdiIcons.circle,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text("Comes online"),
                ],
              ),
              Switch(
                value: _stakeout!.onlineEnabled,
                onChanged: (value) {
                  _s.setOnline(stakeout: _stakeout, onlineEnabled: value);
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
          // Life below percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: [
                  SizedBox(
                    width: 25,
                    child: Transform.rotate(
                      angle: 90 * math.pi / 180,
                      child: const Icon(MdiIcons.glassStange, color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("Life below %"),
                ],
              ),
              Switch(
                value: _stakeout!.lifeBelowPercentageEnabled,
                onChanged: (value) {
                  _s.setLifePercentageEnabled(stakeout: _stakeout, lifePercentageEnabled: value);
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
          if (_stakeout!.lifeBelowPercentageEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 33, right: 5, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Percentage"),
                  GestureDetector(
                    child: Container(
                      decoration: BoxDecoration(border: Border.all()),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("${_stakeout!.lifeBelowPercentageLimit}%"),
                      ),
                    ),
                    onTap: () {
                      _showLifePercentageDialog();
                    },
                  ),
                ],
              ),
            ),
          // Offline time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: [
                  SizedBox(
                    width: 25,
                    child: Icon(
                      Icons.hourglass_bottom_outlined,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("Offline time"),
                ],
              ),
              Switch(
                value: _stakeout!.offlineLongerThanEnabled,
                onChanged: (value) {
                  _s.setOfflineLongerThanEnabled(stakeout: _stakeout, offlineLongerThanEnabled: value);
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
          if (_stakeout!.offlineLongerThanEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 33, right: 5, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Hours"),
                  GestureDetector(
                    child: Container(
                      decoration: BoxDecoration(border: Border.all()),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("${_stakeout!.offlineLongerThanLimit}h"),
                      ),
                    ),
                    onTap: () {
                      _showOfflineTimeLimitDialog();
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _showNotesDialog() {
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
              stakeoutModel: _stakeout,
              noteType: PersonalNoteType.stakeout,
            ),
          ),
        );
      },
    );
  }

  Color? _returnTargetNoteColor() {
    switch (_stakeout!.personalNoteColor) {
      case 'red':
        return Colors.red[600];
      case 'orange':
        return Colors.orange[600];
      case 'green':
        return Colors.green[600];
      default:
        return _themeProvider.mainText;
    }
  }

  Future<void> _openBrowser({required bool shortTap}) async {
    final browserType = _settingsProvider.currentBrowser;
    final String url = 'https://www.torn.com/profiles.php?XID=${_stakeout!.id}';
    switch (browserType) {
      case BrowserSetting.app:
        await _webViewProvider.openBrowserPreference(
          context: context,
          browserTapType: shortTap ? BrowserTapType.short : BrowserTapType.long,
          url: url,
        );
      case BrowserSetting.external:
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
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
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Widget _travelIcon() {
    final country = countryCheck(state: _stakeout!.status!.state, description: _stakeout!.status!.description);

    if (_stakeout!.status!.color == "blue" || (country != "Torn" && _stakeout!.status!.color == "red")) {
      final destination = _stakeout!.status!.color == "blue" ? _stakeout!.status!.description! : country;
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
              text: _stakeout!.status!.description!,
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue,
              duration: const Duration(seconds: 5),
              contentPadding: const EdgeInsets.all(10),
            );
          },
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: RotatedBox(
                  quarterTurns: _stakeout!.status!.description!.contains('Traveling to ')
                      ? 1 // If traveling to another country
                      : _stakeout!.status!.description!.contains('Returning ')
                          ? 3 // If returning to Torn
                          : 0, // If staying abroad (blue but not moving)
                  child: Icon(
                    _stakeout!.status!.description!.contains('In ')
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
      return const SizedBox.shrink();
    }
  }

  Color _returnStatusColor(String? status) {
    switch (status) {
      case 'Online':
        return Colors.green;
      case 'Idle':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showLifePercentageDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 30),
                    decoration: BoxDecoration(
                      color: _themeProvider.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Life"),
                            Form(
                              key: _lifePercentageFormController,
                              child: SizedBox(
                                width: 100,
                                child: TextFormField(
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  controller: _lifePercentageTextController,
                                  maxLength: 3,
                                  minLines: 1,
                                  keyboardType: const TextInputType.numberWithOptions(),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    suffixText: "%",
                                    isDense: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'\d+'),
                                    )
                                  ],
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "Empty!";
                                    }
                                    final n = num.tryParse(value);
                                    if (n == null) {
                                      return 'Not a number!';
                                    }
                                    final int number = n as int;
                                    if (number > 100) {
                                      return 'Max 100%!';
                                    } else if (number < 1) {
                                      return 'Min 1%!';
                                    }
                                    _offlineHoursTextController.text = value.trim();
                                    return null;
                                  },
                                  onEditingComplete: () {
                                    if (_lifePercentageFormController.currentState!.validate()) {
                                      _s.setLifePercentageLimit(
                                        stakeout: _stakeout,
                                        percentage: int.tryParse(_lifePercentageTextController.text),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  onTapOutside: (value) {
                                    if (_lifePercentageFormController.currentState!.validate()) {
                                      _s.setLifePercentageLimit(
                                        stakeout: _stakeout,
                                        percentage: int.tryParse(_lifePercentageTextController.text),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          child: const Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.mainText,
                      radius: 22,
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: Transform.rotate(
                          angle: 90 * math.pi / 180,
                          child: const Icon(MdiIcons.glassStange, color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showOfflineTimeLimitDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 30),
                    decoration: BoxDecoration(
                      color: _themeProvider.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Time"),
                            Form(
                              key: _offlineHoursFormController,
                              child: SizedBox(
                                width: 100,
                                child: TextFormField(
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  controller: _offlineHoursTextController,
                                  maxLength: 4,
                                  minLines: 1,
                                  keyboardType: const TextInputType.numberWithOptions(),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    suffixText: "h",
                                    isDense: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'\d+'),
                                    )
                                  ],
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "Empty!";
                                    }
                                    final n = num.tryParse(value);
                                    if (n == null) {
                                      return 'Not a number!';
                                    }
                                    final int number = n as int;
                                    if (number > 1500) {
                                      return 'Max 2 months!';
                                    } else if (number < 1) {
                                      return 'Min 1h!';
                                    }
                                    _lifePercentageTextController.text = value.trim();
                                    return null;
                                  },
                                  onEditingComplete: () {
                                    if (_offlineHoursFormController.currentState!.validate()) {
                                      _s.setOfflineLongerThanLimit(
                                        stakeout: _stakeout,
                                        hours: int.tryParse(_offlineHoursTextController.text),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  onTapOutside: (value) {
                                    if (_offlineHoursFormController.currentState!.validate()) {
                                      _s.setOfflineLongerThanLimit(
                                        stakeout: _stakeout,
                                        hours: int.tryParse(_offlineHoursTextController.text),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          child: const Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.mainText,
                      radius: 22,
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: Icon(
                          Icons.hourglass_bottom_outlined,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
