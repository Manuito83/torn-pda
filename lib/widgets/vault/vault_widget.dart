// Package imports:
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import 'package:torn_pda/models/vault/vault_status_model.dart';
// Project imports:
import 'package:torn_pda/models/vault/vault_transaction_model.dart';
import 'package:torn_pda/pages/vault/vault_configuration_page.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class VaultWidget extends StatefulWidget {
  final List<dom.Element>? vaultHtml;
  final int? playerId;
  final UserDetailsProvider? userProvider;

  const VaultWidget({
    super.key,
    required this.vaultHtml,
    required this.playerId,
    required this.userProvider,
  });

  @override
  VaultWidgetState createState() => VaultWidgetState();
}

class VaultWidgetState extends State<VaultWidget> {
  Future? _vaultAssessed;
  var _vaultStatus = VaultStatusModel();
  bool _firstUse = false;

  final _scrollController = ScrollController();
  final _moneyFormat = NumberFormat("#,##0", "en_US");

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
        theme: const ExpandableThemeData(
          hasIcon: false,
          iconColor: Colors.grey,
          tapBodyToExpand: false,
          tapHeaderToExpand: false,
          tapBodyToCollapse: false,
        ),
        header: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'VAULT SHARE',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
            if (_firstUse)
              const SizedBox.shrink()
            else if (!_firstUse && !_vaultStatus.error!)
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
        expanded: Container(),
      ),
    );
  }

  Widget _vaultMain() {
    return FutureBuilder(
      future: _vaultAssessed,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_vaultStatus.error!) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text(
                    "There was an error identifying your last saved transaction, please reenter "
                    "the current vault distribution again",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                _vaultConfigurationIcon(),
              ],
            );
          }

          if (_firstUse) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Text(
                        "Initialise vault values",
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _vaultConfigurationIcon(),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        "(alternatively, deactivate the widget through the appbar icon)",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                )
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
                        widget.userProvider!.basic!.name!,
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                      Text(
                        "\$${_moneyFormat.format(_vaultStatus.player)}",
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    "\$${_moneyFormat.format(_vaultStatus.total)}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    children: [
                      Text(
                        widget.userProvider!.basic!.married?.spouseId == 0
                            ? "Spouse"
                            : widget.userProvider!.basic!.married!.spouseName!,
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                      Text(
                        "\$${_moneyFormat.format(_vaultStatus.spouse)}",
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        } else {
          return const Row(
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
      },
    );
  }

  Future _buildVault() async {
    // Get the last vault values we saved (if any)
    final savedVault = await Prefs().getVaultShareCurrent();
    if (savedVault.isNotEmpty) {
      _vaultStatus = vaultStatusModelFromJson(savedVault);
    }

    // Transactions list just obtained from the webView
    final transactions = await _getTransactions();

    if (transactions.isNotEmpty) {
      if (savedVault.isNotEmpty) {
        final foundSaved = await _findSavedTransactionAndUpdate(transactions);
        if (!foundSaved) {
          setState(() {
            _vaultStatus.error = true;
          });
        } else {
          setState(() {
            _vaultStatus.error = false;
          });
        }
      } else {
        setState(() {
          // Need to call setState to remove header gear icon (not included in FutureBuilder)
          _firstUse = true;
        });
        _vaultStatus.total = transactions[0].balance!;
      }
    } else {
      setState(() {
        _vaultStatus.error = true;
      });
    }
  }

  Future<List<VaultTransactionModel>> _getTransactions() {
    final transactionList = <VaultTransactionModel>[];
    try {
      for (final trans in widget.vaultHtml!) {
        final String day = trans.querySelector(".date .transaction-date")?.text.trim() ?? "";
        final String hour = trans.querySelector(".date .transaction-time")?.text.trim() ?? "";
        final format = DateFormat("dd/MM/yy HH:mm:ss");
        final date = format.parse("$day $hour", true);

        var playerTransaction = false;
        final String name = trans.querySelector(".user.t-overflow > .d-hide > .user.name")?.attributes["title"] ?? "";
        if (name.contains("[${widget.playerId}]")) {
          playerTransaction = true;
        }

        var isDeposit = false;
        final String type = trans.querySelector(".type")?.text.trim() ?? "";
        if (type.contains("Deposit")) {
          isDeposit = true;
        }

        String amountString = trans.querySelector("li.amount")?.text ?? "";
        amountString = amountString
            .replaceAll("\$", "")
            .replaceAll("\n", "")
            .replaceAll("+", "")
            .replaceAll("-", "")
            .replaceAll(",", "");
        final amount = int.tryParse(amountString);

        String balanceString = trans.querySelector("li.balance")?.text ?? "";
        balanceString = balanceString
            .replaceAll("\$", "")
            .replaceAll("\n", "")
            .replaceAll("+", "")
            .replaceAll("-", "")
            .replaceAll(",", "");
        final balance = int.tryParse(balanceString);

        final thisTransaction = VaultTransactionModel()
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
      if (transactions[t].date == _vaultStatus.timestamp && transactions[t].balance == _vaultStatus.total) {
        indexFound = t;
        break;
      }
    }

    // Apply all the changes until we reach the saved transaction, then save it at the last known
    // The only exception is the index is 0, in which case it's the last transaction and it has
    // already been accounted for
    if (indexFound >= 1) {
      var newPlayerAmount = _vaultStatus.player!;
      var newSpouseAmount = _vaultStatus.spouse!;
      for (var i = 0; i < indexFound; i++) {
        final pendingTrans = transactions[i];
        if (pendingTrans.playerTransaction!) {
          if (pendingTrans.isDeposit!) {
            newPlayerAmount += pendingTrans.amount!;
          } else {
            newPlayerAmount -= pendingTrans.amount!;
          }
        } else {
          if (pendingTrans.isDeposit!) {
            newSpouseAmount += pendingTrans.amount!;
          } else {
            newSpouseAmount -= pendingTrans.amount!;
          }
        }
      }
      // Once all transaction have been applied, confirm we are correct
      final newTotal = newPlayerAmount + newSpouseAmount;
      if (_lastTransaction.balance == newTotal) {
        setState(() {
          _vaultStatus.player = newPlayerAmount;
          _vaultStatus.spouse = newSpouseAmount;
          _vaultStatus.total = _lastTransaction.balance!;
          _vaultStatus.timestamp = _lastTransaction.date!;
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
        _vaultStatus.timestamp = _lastTransaction.date!;
      }
    }

    return GestureDetector(
      child: const Padding(
        padding: EdgeInsets.only(right: 5),
        child: SizedBox(
          height: 20,
          width: 20,
          child: Icon(Icons.settings, size: 16, color: Colors.orange),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return VaultConfigurationPage(
                callback: _configurationCallback,
                userProvider: widget.userProvider,
                vaultStatus: _vaultStatus,
                lastTransaction: _lastTransaction,
              );
            },
          ),
        );
      },
    );
  }

  void _configurationCallback() {
    if (!mounted) return;
    if (_vaultStatus.player == null) {
      setState(() {
        _firstUse = true;
      });
    } else {
      setState(() {
        _firstUse = false;
        _vaultStatus.error = false;
      });
    }
  }
}
