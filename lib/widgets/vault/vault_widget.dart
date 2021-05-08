// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:expandable/expandable.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:html/dom.dart' as dom;
import 'package:torn_pda/models/vault/vault_status_model.dart';

// Project imports:
import 'package:torn_pda/models/vault/vault_transaction_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class VaultWidget extends StatefulWidget {
  final List<dom.Element> vaultHtml;
  final int playerId;

  VaultWidget({
    @required this.vaultHtml,
    @required this.playerId,
  });

  @override
  _VaultWidgetState createState() => _VaultWidgetState();
}

class _VaultWidgetState extends State<VaultWidget> {
  Future _vaultAssessed;
  final _vaultStatus = VaultStatusModel();
  bool _firstUse = false;

  final _scrollController = ScrollController();
  final _moneyFormat = new NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();
    _vaultAssessed = _buildVault();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ExpandablePanel(
        theme: ExpandableThemeData(
          hasIcon: false,
          iconColor: Colors.grey,
          tapBodyToExpand: true,
          tapHeaderToExpand: true,
          tapBodyToCollapse: true,
        ),
        header: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              children: [
                Text(
                  'VAULT SHARE',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        collapsed: ExpandableButton(
          //TODO: do we need this to be expandable button?
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _vaultMain(),
          ),
        ),
        // TODO: do we need this?
        expanded: ConstrainedBox(
          constraints: BoxConstraints.loose(Size.fromHeight((MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  AppBar().preferredSize.height)) /
              3),
          child: Scrollbar(
            controller: _scrollController,
            isAlwaysShown: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 0, 15),
                  child: Column(
                    children: [],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _vaultMain() {
    Widget vault = SizedBox.shrink();
    if (_firstUse) {
      vault = Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              "Please use the vault button (appbar, full browser) to configure the money "
              "shared with your spouse (or to deactivate this widget)",
              style: TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ),
        ],
      );
    } else {
      vault = Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              // TODO!!!
              _vaultStatus.total.toString(),
              style: TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ),
        ],
      );
    }

    return FutureBuilder(
        future: _vaultAssessed,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return vault;
          } else {
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(color: Colors.grey),
                ),
              ],
            );
          }
        });
  }

  Future _buildVault() async {
    // Get the last vault values we saved (if any)
    var savedVault = await Prefs().getVaultShareCurrent();

    // Transactions list just obtained from the webView
    var transactions = await _getTransactions();

    if (transactions.length > 0) {
      if (savedVault.isNotEmpty) {
        // TODO
      } else {
        _firstUse = true;
      }
    } else {
      // TODO: implement error
    }
  }

  Future<List<VaultTransactionModel>> _getTransactions() {
    var transactionList = <VaultTransactionModel>[];
    try {
      for (var trans in widget.vaultHtml) {
        var day = trans.querySelector(".date .transaction-date")?.text?.trim();
        var hour = trans.querySelector(".date .transaction-time")?.text?.trim();
        var format = DateFormat("dd/MM/yy HH:mm:ss");
        var date = format.parse(day + " " + hour);

        var playerTransaction = false;
        var name = trans
            .querySelector(".user.t-overflow > .d-hide > .user.name > span")
            ?.attributes["title"];
        if (name.contains("[${widget.playerId}]")) {
          playerTransaction = true;
        }

        var isDeposit = false;
        var type = trans.querySelector(".type")?.text?.trim();
        if (type.contains("Deposit")) {
          isDeposit = true;
        }

        var amountString = trans.querySelector("li.amount")?.text;
        amountString = amountString
            .replaceAll("\$", "")
            .replaceAll("\n", "")
            .replaceAll("+", "")
            .replaceAll("-", "")
            .replaceAll(",", "");
        var amount = int.tryParse(amountString);

        var balanceString = trans.querySelector("li.balance")?.text;
        balanceString = balanceString
            .replaceAll("\$", "")
            .replaceAll("\n", "")
            .replaceAll("+", "")
            .replaceAll("-", "")
            .replaceAll(",", "");
        var balance = int.tryParse(balanceString);

        var thisTransaction = VaultTransactionModel()
          ..date = date.millisecondsSinceEpoch
          ..playerTransaction = playerTransaction
          ..amount = amount
          ..isDeposit = isDeposit
          ..balance = balance;

        transactionList.add(thisTransaction);
      }
      return Future<List<VaultTransactionModel>>.value(transactionList);
    } catch (e) {
      return Future<List<VaultTransactionModel>>.value([]);
    }
  }
}
