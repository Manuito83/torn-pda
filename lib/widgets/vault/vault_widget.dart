// Flutter imports:
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:expandable/expandable.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:html/dom.dart' as dom;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/vault/vault_status_model.dart';

// Project imports:
import 'package:torn_pda/models/vault/vault_transaction_model.dart';
import 'package:torn_pda/pages/vault/vault_configuration_page.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class VaultWidget extends StatefulWidget {
  final List<dom.Element> vaultHtml;
  final int playerId;
  final UserDetailsProvider userProvider;

  VaultWidget({
    @required this.vaultHtml,
    @required this.playerId,
    @required this.userProvider,
  });

  @override
  _VaultWidgetState createState() => _VaultWidgetState();
}

class _VaultWidgetState extends State<VaultWidget> {
  Future _vaultAssessed;
  var _vaultStatus = VaultStatusModel();
  bool _firstUse = false;
  bool _notFountError = false;

  final _scrollController = ScrollController();
  final _moneyFormat = new NumberFormat("#,##0", "en_US");

  var _lastTransaction = VaultTransactionModel();

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
          tapBodyToExpand: false,
          tapHeaderToExpand: false,
          tapBodyToCollapse: false,
        ),
        header: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              'VAULT SHARE',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
            if (_firstUse)
              SizedBox.shrink()
            else if (!_firstUse && !_notFountError)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: _vaultConfigurationIcon(),
              ),
          ],
        ),
        collapsed: Padding(
          padding: const EdgeInsets.all(10),
          child: _vaultMain(),
        ),
        expanded: null,
      ),
    );
  }

  Widget _vaultMain() {
    return FutureBuilder(
        future: _vaultAssessed,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_notFountError) {
              return Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      "There was an error identifying your last saved transaction, please reenter "
                      "the current vault distribution again",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 6),
                  _vaultConfigurationIcon(),
                ],
              );
            }

            if (_firstUse) {
              return Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      "Initialise vault values",
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 6),
                  _vaultConfigurationIcon(),
                ],
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        Text(
                          widget.userProvider.basic.name,
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                        Text(
                          "\$${_moneyFormat.format(_vaultStatus.player)}",
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      "\$${_moneyFormat.format(_vaultStatus.total)}",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      children: [
                        Text(
                          widget.userProvider.basic.married.spouseName,
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                        Text(
                          "\$${_moneyFormat.format(_vaultStatus.spouse)}",
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
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
    if (savedVault.isNotEmpty) {
      _vaultStatus = vaultStatusModelFromJson(savedVault);
    }

    // Transactions list just obtained from the webView
    var transactions = await _getTransactions();

    if (transactions.length > 0) {
      if (savedVault.isNotEmpty) {
        var foundSaved = await _findSavedTransactionAndUpdate(transactions);
        if (!foundSaved) {
          setState(() {
            _notFountError = true;
          });
        } else {
          setState(() {
            _notFountError = false;
          });
        }
      } else {
        setState(() {
          // Need to call setState to remove header gear icon (not included in FutureBuilder)
          _firstUse = true;
        });
        _vaultStatus.total = transactions[0].balance;
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
        var date = format.parse(day + " " + hour, true);

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

      // Save the last transaction
      if (transactionList.isNotEmpty) {
        _lastTransaction = transactionList[0];
      }
      return Future<List<VaultTransactionModel>>.value(transactionList);
    } catch (e) {
      return Future<List<VaultTransactionModel>>.value([]);
    }
  }

  Future<bool> _findSavedTransactionAndUpdate(List<VaultTransactionModel> transactions) {
    var indexFound = -1;
    for (var t = 0; t < transactions.length; t++) {
      // Locate our last saved transaction and save its index
      if (transactions[t].date == _vaultStatus.timestamp &&
          transactions[t].balance == _vaultStatus.total) {
        indexFound = t;
        break;
      }
    }

    // Apply all the changes until we reach the saved transaction, then save it at the last known
    // The only exception is the index is 0, in which case it's the last transaction and it has
    // already been accounted for
    if (indexFound >= 1) {
      var newPlayerAmount = _vaultStatus.player;
      var newSpouseAmount = _vaultStatus.spouse;
      for (var i = 0; i < indexFound; i++) {
        var pendingTrans = transactions[i];
        if (pendingTrans.playerTransaction) {
          if (pendingTrans.isDeposit) {
            newPlayerAmount += pendingTrans.amount;
          } else {
            newPlayerAmount -= pendingTrans.amount;
          }
        } else {
          if (pendingTrans.isDeposit) {
            newSpouseAmount += pendingTrans.amount;
          } else {
            newSpouseAmount -= pendingTrans.amount;
          }
        }
      }
      // Once all transaction have been applied, confirm we are correct
      var newTotal = newPlayerAmount + newSpouseAmount;
      if (_lastTransaction.balance == newTotal) {
        setState(() {
          _vaultStatus.player = newPlayerAmount;
          _vaultStatus.spouse = newSpouseAmount;
          _vaultStatus.timestamp = _lastTransaction.balance;
          _vaultStatus.timestamp = _lastTransaction.date;
        });
        Prefs().setVaultShareCurrent(vaultStatusModelToJson(_vaultStatus));
      } else {
        indexFound = -1;
      }
    }

    if (indexFound != -1) {
      return Future.value(true);
    } else {
      return Future.value(false);
    }
  }

  Widget _vaultConfigurationIcon() {
    // If this is the first time we initialise, we are going to pass a timestamp
    if (_vaultStatus.timestamp == null) {
      // If we have transactions, pass the last transaction timestamp
      if (_lastTransaction.date != null) {
        _vaultStatus.timestamp = _lastTransaction.date;
      }
      // Otherwise, pass the current time  // TODO: ????
      else {
        _vaultStatus.timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      }
    }

    return OpenContainer(
      transitionDuration: Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fadeThrough,
      openBuilder: (BuildContext context, VoidCallback _) {
        return VaultConfigurationPage(
          callback: _configurationCallback,
          userProvider: widget.userProvider,
          vaultStatus: _vaultStatus,
        );
      },
      closedElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(56 / 2),
        ),
      ),
      closedColor: Colors.transparent,
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return Padding(
          padding: const EdgeInsets.only(right: 5),
          child: SizedBox(
            height: 20,
            width: 20,
            child: Icon(Icons.settings, size: 16, color: Colors.orange),
          ),
        );
      },
    );
  }

  _configurationCallback() {
    if (_vaultStatus.player == null) {
      setState(() {
        _firstUse = true;
        _notFountError = false;
      });
    } else {
      setState(() {
        _buildVault();
      });
    }
  }
}
