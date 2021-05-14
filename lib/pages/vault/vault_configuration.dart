// Flutter imports:
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/models/vault/vault_status_model.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/vault/vault_configuration_dialog.dart';

class VaultConfiguration extends StatefulWidget {
  final Function callback;
  final UserDetailsProvider userProvider;
  final int totalInVault;

  VaultConfiguration({
    @required this.callback,
    @required this.userProvider,
    @required this.totalInVault,
  });

  @override
  _VaultConfigurationState createState() => _VaultConfigurationState();
}

class _VaultConfigurationState extends State<VaultConfiguration> {
  var _savedVault = VaultStatusModel();

  final _moneyFormat = new NumberFormat("#,##0", "en_US");

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
                            SizedBox(height: 10),
                            _setupContainer(),
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
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("Vault configuration"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          widget.callback();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _setupContainer() {
    if (widget.totalInVault == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                "There was an error detecting the total amount of money available in the vault, "
                "please close the browser and try again!",
                style: TextStyle(
                  color: Colors.red[700],
                ),
              ),
            )
          ],
        ),
      );
    }

    Widget top = SizedBox.shrink();
    Widget share = SizedBox.shrink();
    Widget options = SizedBox.shrink();

    // If we have never initialise (or we deleted) the share
    if (_savedVault.timestamp == null) {
      top = Text("You have not initialised the vault share yet!");
      share = Column(
        children: [
          Text("Total: \$${_moneyFormat.format(widget.totalInVault)}"),
          SizedBox(height: 10),
          Text("${widget.userProvider.basic.name}: ?"),
          Text("${widget.userProvider.basic.married.spouseName}: ?"),
        ],
      );
      options = ElevatedButton(
        child: Text("Initialise"),
        onPressed: () {
          _showVaultConfigurationDialog();
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                top,
                SizedBox(height: 20),
                share,
                SizedBox(height: 20),
                options,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future _restorePreferences() async {
    // Get the last vault values we saved (if any)
    var savedVault = await Prefs().getVaultShareCurrent();
    _savedVault = vaultStatusModelFromJson(savedVault);
  }

  Future<void> _showVaultConfigurationDialog() async {
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
          content: VaultConfigurationDialog(
            total: widget.totalInVault,
            vaultStatus: _savedVault,
            userProvider: widget.userProvider,
            callbackShares: _onDialogSendData,
          ),
        );
      },
    );
  }

  _onDialogSendData (List<int> shares) {
    print(shares); // TODO
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
