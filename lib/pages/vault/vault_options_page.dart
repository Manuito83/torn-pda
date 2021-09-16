// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class VaultOptionsPage extends StatefulWidget {
  final bool vaultDetected;
  final Function callback;

  VaultOptionsPage({@required this.vaultDetected, @required this.callback});

  @override
  _VaultOptionsPageState createState() => _VaultOptionsPageState();
}

class _VaultOptionsPageState extends State<VaultOptionsPage> {
  bool _vaultEnabled = true;

  SettingsProvider _settingsProvider;
  Future _preferencesLoaded;

  @override
  void initState() {
    super.initState();
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: SafeArea(
        top: _settingsProvider.appBarTop ? false : true,
        bottom: true,
        child: Scaffold(
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
                child: FutureBuilder(
                  future: _preferencesLoaded,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (!widget.vaultDetected)
                              Column(
                                children: [
                                  SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    child: Text(
                                      "NOTE: Torn PDA did not detect a vault in your property, either "
                                      "because there is none, you don\'t have access to it or there "
                                      "no transactions listed.",
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text("Use vault share"),
                                  Switch(
                                    value: _vaultEnabled,
                                    onChanged: (value) {
                                      Prefs().setVaultEnabled(value);
                                      setState(() {
                                        _vaultEnabled = value;
                                      });
                                    },
                                    activeTrackColor: Colors.lightGreenAccent,
                                    activeColor: Colors.green,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 50),
                          ],
                        ),
                      );
                    } else {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
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
      brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Text("Vault options"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          widget.callback();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future _restorePreferences() async {
    var vaultEnabled = await Prefs().getVaultEnabled();
    setState(() {
      _vaultEnabled = vaultEnabled;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
