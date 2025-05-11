// Flutter imports:
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/models/vault/vault_status_model.dart';
import 'package:torn_pda/models/vault/vault_transaction_model.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/vault/vault_configuration_dialog.dart';

class VaultConfigurationPage extends StatefulWidget {
  final Function callback;
  final UserDetailsProvider? userProvider;
  final VaultStatusModel vaultStatus;
  final VaultTransactionModel lastTransaction;

  const VaultConfigurationPage({
    required this.callback,
    required this.userProvider,
    required this.vaultStatus,
    required this.lastTransaction,
  });

  @override
  VaultConfigurationPageState createState() => VaultConfigurationPageState();
}

class VaultConfigurationPageState extends State<VaultConfigurationPage> {
  final _moneyFormat = NumberFormat("#,##0", "en_US");

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context);
    return WillPopScope(
      onWillPop: _willPopCallback,
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
                color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      _setupContainer(),
                      const SizedBox(height: 50),
                    ],
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
      title: const Text("Vault configuration", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          widget.callback();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _setupContainer() {
    // Check for null both the current total and last transaction (in case it can't be detected)
    if (widget.vaultStatus.total == null || widget.lastTransaction.balance == null) {
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

    Widget top = const SizedBox.shrink();
    Widget topError = const SizedBox.shrink();
    Widget share = const SizedBox.shrink();
    Widget options = const SizedBox.shrink();

    final spouseName =
        widget.userProvider!.basic!.married?.spouseId == 0 ? "Spouse" : widget.userProvider!.basic!.married!.spouseName;

    // If we have never initialise (or we deleted) the share
    if (widget.vaultStatus.player == null) {
      top = const Text("You have not initialised the vault share yet!");
      share = Column(
        children: [
          Text("Total: \$${_moneyFormat.format(widget.lastTransaction.balance)}"),
          const SizedBox(height: 10),
          Text("${widget.userProvider!.basic!.name}: ?"),
          Text("$spouseName: ?"),
        ],
      );
      options = ElevatedButton(
        child: const Text("Initialise"),
        onPressed: () {
          _showVaultConfigurationDialog();
        },
      );
    } else {
      var firstButtonText = "Change";
      final time = DateTime.fromMillisecondsSinceEpoch(widget.vaultStatus.timestamp!);
      final formatter = TimeFormatter(
        inputTime: time,
        timeFormatSetting: _settingsProvider.currentTimeFormat,
        timeZoneSetting: _settingsProvider.currentTimeZone,
      );

      if (!widget.vaultStatus.error!) {
        top = Text("Last transaction on ${formatter.formatMonthDay} @${formatter.formatHour}");
        share = Column(
          children: [
            Text("Total: \$${_moneyFormat.format(widget.vaultStatus.total)}"),
            const SizedBox(height: 10),
            Text("${widget.userProvider!.basic!.name}: "
                "${_moneyFormat.format(widget.vaultStatus.player)}"),
            Text("$spouseName: "
                "${_moneyFormat.format(widget.vaultStatus.spouse)}"),
          ],
        );
      } else {
        top = Text(
          "There was an error identifying your last saved transaction (this might happen if "
          "there are too many transactions since the last time you visited the vault).\n\n"
          "Last known distribution on ${formatter.formatMonthDay} @${formatter.formatHour}",
          style: TextStyle(
            color: Colors.orange[800],
          ),
        );
        topError = Column(
          children: [
            Text(
              "Total: \$${_moneyFormat.format(widget.vaultStatus.total)}",
              style: TextStyle(
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${widget.userProvider!.basic!.name}: "
              "${_moneyFormat.format(widget.vaultStatus.player)}",
              style: TextStyle(
                color: Colors.orange[800],
              ),
            ),
            Text(
              "$spouseName: "
              "${_moneyFormat.format(widget.vaultStatus.spouse)}",
              style: TextStyle(
                color: Colors.orange[800],
              ),
            ),
          ],
        );
        share = Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            children: [
              const Divider(),
              const SizedBox(height: 20),
              const Text("Please, calculate your totals from the last known transaction (above) and reset the vault "
                  "distribution with the correct values"),
              const SizedBox(height: 20),
              Text("In the vault now: \$${_moneyFormat.format(widget.lastTransaction.balance)}"),
              const SizedBox(height: 10),
              Text("${widget.userProvider!.basic!.name}: ?"),
              Text("$spouseName: ?"),
            ],
          ),
        );
        firstButtonText = "Reset";
      }

      options = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text(firstButtonText),
            onPressed: () {
              _showVaultConfigurationDialog();
            },
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            child: const Icon(Icons.delete_outline),
            onPressed: () {
              _showResetVaultConfiguration();
            },
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              children: [
                top,
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: topError,
                ),
                share,
                const SizedBox(height: 20),
                options,
              ],
            ),
          ),
        ],
      ),
    );
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
            lastTransaction: widget.lastTransaction,
            vaultStatus: widget.vaultStatus,
            userProvider: widget.userProvider,
            callbackShares: _onDialogSendData,
          ),
        );
      },
    );
  }

  Future<void> _showResetVaultConfiguration() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset vault distribution"),
          content: const Text("Caution: this will reset your vault distribution!"),
          actions: [
            TextButton(
              child: const Text("Do it!"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  widget.vaultStatus
                    ..player = null
                    ..spouse = null;
                  if (widget.vaultStatus.error!) {
                    widget.vaultStatus.total = widget.lastTransaction.balance;
                  }
                });
                Prefs().setVaultShareCurrent("");
              },
            ),
            TextButton(
              child: const Text("Oh no!"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _onDialogSendData() {
    setState(() {
      // Shares info has been added
    });

    final save = vaultStatusModelToJson(widget.vaultStatus);
    Prefs().setVaultShareCurrent(save);
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
