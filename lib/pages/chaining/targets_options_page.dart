// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TargetsOptionsReturn {
  bool? yataEnabled;
  bool? retaliationEnabled;
  //bool tacEnabled;
}

class TargetsOptionsPage extends StatefulWidget {
  @override
  TargetsOptionsPageState createState() => TargetsOptionsPageState();
}

class TargetsOptionsPageState extends State<TargetsOptionsPage> {
  // Targets notes while chaining
  bool _showTargetsNotes = true;
  bool _showBlankTargetsNotes = true;
  bool _showOnlineFactionWarning = true;

  // Retaliation
  bool _retaliationEnabled = true;

  // Yata import
  bool _yataTargetsEnabled = true;

  // TAC
  //bool _tacEnabled = true;

  Future? _preferencesLoaded;

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    routeWithDrawer = false;
    routeName = "targets_options";
    _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "targets_options") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        right: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left,
        left: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Builder(
            builder: (BuildContext context) {
              return Container(
                color: _themeProvider.canvas,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                  child: FutureBuilder(
                    future: _preferencesLoaded,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 15),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CHAINING',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Text("Show targets notes"),
                                    Switch(
                                      value: _showTargetsNotes,
                                      onChanged: (value) {
                                        Prefs().setShowTargetsNotes(value);
                                        setState(() {
                                          _showTargetsNotes = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'If enabled, you will be shown the note you have saved for every '
                                  'target and its color as you progress with the chain. Applies only '
                                  'for standard targets.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              if (_showTargetsNotes)
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          const Text("Show blank notes"),
                                          Switch(
                                            value: _showBlankTargetsNotes,
                                            onChanged: (value) {
                                              Prefs().setShowBlankTargetsNotes(value);
                                              setState(() {
                                                _showBlankTargetsNotes = value;
                                              });
                                            },
                                            activeTrackColor: Colors.lightGreenAccent,
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Text(
                                        "If enabled, you will be shown a colored square even if your target's note is empty, "
                                        'so that you are aware of the color even if no details have been entered.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                              if (_showTargetsNotes)
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          const Text("Last online & faction warning"),
                                          Switch(
                                            value: _showOnlineFactionWarning,
                                            onChanged: (value) {
                                              Prefs().setShowOnlineFactionWarning(value);
                                              setState(() {
                                                _showOnlineFactionWarning = value;
                                              });
                                            },
                                            activeTrackColor: Colors.lightGreenAccent,
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Text(
                                        "If enabled, in addition to the target's note (if any) you'll be shown if the "
                                        'target has been online in the last 7 days. If so, a faction check will also be performed. '
                                        'This is to avoid attacking active targets, if desired.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Text("Skip red/blue targets"),
                                    Switch(
                                      value: _settingsProvider.targetSkippingAll,
                                      onChanged: (value) {
                                        setState(() {
                                          _settingsProvider.changeTargetSkippingAll = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'If enabled, targets that are in hospital, jail or in another '
                                  'country will be skipped (max 3 at a time, to avoid delays). '
                                  'This does NOT affect Panic Mode.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              if (_settingsProvider.targetSkippingAll)
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          const Text("Also skip first target"),
                                          Switch(
                                            value: _settingsProvider.targetSkippingFirst,
                                            onChanged: (value) {
                                              setState(() {
                                                _settingsProvider.changeTargetSkippingFirst = value;
                                              });
                                            },
                                            activeTrackColor: Colors.lightGreenAccent,
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Text(
                                        "If enabled, your first, manually selected target will be skipped as well if it's "
                                        'red/blue. This might be useful if your list is not updated and the target you '
                                        'select is not available. This does NOT affect Panic Mode.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 15),
                              const Divider(),
                              const SizedBox(height: 5),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'RETALIATION SECTION',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Text("Section enabled"),
                                    Switch(
                                      value: _retaliationEnabled,
                                      onChanged: (value) {
                                        Prefs().setRetaliationSectionEnabled(value);
                                        _settingsProvider.setRetaliationSectionEnabled = value;
                                        setState(() {
                                          // We use this for the callback as well to Chaining
                                          _retaliationEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Divider(),
                              const SizedBox(height: 5),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'YATA',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Text("Show YATA icon"),
                                    Switch(
                                      value: _yataTargetsEnabled,
                                      onChanged: (value) {
                                        Prefs().setYataTargetsEnabled(value);
                                        setState(() {
                                          _yataTargetsEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  "If enabled, you'll have access to a 'Y' icon in the top bar from "
                                  'where you can import and export to YATA. Please note that deletions '
                                  'are not propagated between YATA and Torn PDA, but notes are '
                                  'overwritten in either direction.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              /*
                              SizedBox(height: 15),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Torn Attack Central',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Show TAC tab"),
                                    Switch(
                                      value: _tacEnabled,
                                      onChanged: (value) {
                                        Prefs().setTACEnabled(value);
                                        setState(() {
                                          _tacEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'If enabled, you\'ll have access to TAC through a third '
                                  'bottom tab in the Chaining section.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              */
                              const SizedBox(height: 50),
                            ],
                          ),
                        );
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Chaining Options", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
    );
  }

  Future _restorePreferences() async {
    final showTargetsNotes = await Prefs().getShowTargetsNotes();
    final showBlankTargetsNotes = await Prefs().getShowBlankTargetsNotes();
    final showOnlineFactionWarning = await Prefs().getShowOnlineFactionWarning();
    final yataEnabled = await Prefs().getYataTargetsEnabled();
    final retaliationEnabled = await Prefs().getRetaliationSectionEnabled();
    //var tacEnabled = await Prefs().getTACEnabled();

    setState(() {
      _showTargetsNotes = showTargetsNotes;
      _showBlankTargetsNotes = showBlankTargetsNotes;
      _showOnlineFactionWarning = showOnlineFactionWarning;
      _yataTargetsEnabled = yataEnabled;
      _retaliationEnabled = retaliationEnabled;
      //_tacEnabled = tacEnabled;
    });
  }

  _goBack() {
    routeWithDrawer = true;
    routeName = "chaining_targets";
    Navigator.of(context).pop(
      TargetsOptionsReturn()
        ..yataEnabled = _yataTargetsEnabled
        ..retaliationEnabled = _retaliationEnabled,
      //..tacEnabled = _tacEnabled,
    );
  }
}
