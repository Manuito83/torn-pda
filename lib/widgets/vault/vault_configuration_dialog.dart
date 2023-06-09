// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/vault/vault_status_model.dart';
import 'package:torn_pda/models/vault/vault_transaction_model.dart';

// Project imports:
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';

class VaultConfigurationDialog extends StatefulWidget {
  final VaultStatusModel vaultStatus;
  final VaultTransactionModel lastTransaction;
  final UserDetailsProvider userProvider;
  final Function callbackShares;

  VaultConfigurationDialog({
    @required this.lastTransaction,
    @required this.vaultStatus,
    @required this.userProvider,
    @required this.callbackShares,
  });

  @override
  _VaultConfigurationDialogState createState() => _VaultConfigurationDialogState();
}

class _VaultConfigurationDialogState extends State<VaultConfigurationDialog> {
  ThemeProvider _themeProvider;

  final _ownAmountController = new TextEditingController();
  final _spouseAmountController = new TextEditingController();
  var _vaultFormKey = GlobalKey<FormState>();

  final _moneyFormat = new NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ownAmountController.dispose();
    _spouseAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                top: 45,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              margin: EdgeInsets.only(top: 30),
              decoration: new BoxDecoration(
                color: _themeProvider.secondBackground,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Form(
                key: _vaultFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                      child: Text(
                        "Total"
                        "\n\$${_moneyFormat.format(widget.lastTransaction.balance)}",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        "${widget.userProvider.basic.name}'s share",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    TextFormField(
                      style: TextStyle(fontSize: 13),
                      controller: _ownAmountController,
                      maxLength: 20,
                      minLines: 1,
                      maxLines: 1,
                      decoration: InputDecoration(
                        prefixText: "\$ ",
                        labelText: widget.vaultStatus.player == null
                            ? "\$ 0"
                            : "\$ ${_moneyFormat.format(widget.vaultStatus.player)}",
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        counterText: "",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(signed: true, decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]?[\d,]*$'))],
                      onChanged: (ownString) {
                        if (ownString.isNotEmpty && ownString != "-") {
                          var ownAmount = _cleanNumber(ownString);
                          ownString = _moneyFormat.format(ownAmount);
                          _ownAmountController.value = TextEditingValue(
                            text: ownString,
                            selection: TextSelection.collapsed(offset: ownString.length),
                          );

                          // Set the other fields value
                          if (ownAmount <= widget.lastTransaction.balance) {
                            setState(() {
                              var spouse = _moneyFormat.format(widget.lastTransaction.balance - ownAmount);
                              _spouseAmountController.text = spouse;
                            });
                          } else {
                            _spouseAmountController.text = "Not enough money!";
                          }
                        }
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        widget.userProvider.basic.married?.spouseId == 0
                            ? "Spouse's share"
                            : "${widget.userProvider.basic.married.spouseName}'s share",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    TextFormField(
                      style: TextStyle(fontSize: 13),
                      controller: _spouseAmountController,
                      maxLength: 20,
                      minLines: 1,
                      maxLines: 2,
                      decoration: InputDecoration(
                        prefixText: "\$ ",
                        labelText: widget.vaultStatus.spouse == null
                            ? "\$ 0"
                            : "\$ ${_moneyFormat.format(widget.vaultStatus.spouse)}",
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        counterText: "",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(signed: true, decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]?[\d,]*$'))],
                      onChanged: (spouseString) {
                        if (spouseString.isNotEmpty && spouseString != "-") {
                          var spouseAmount = _cleanNumber(spouseString);
                          spouseString = _moneyFormat.format(spouseAmount);
                          _spouseAmountController.value = TextEditingValue(
                            text: spouseString,
                            selection: TextSelection.collapsed(offset: spouseString.length),
                          );

                          // Set the other fields value
                          if (spouseAmount <= widget.lastTransaction.balance) {
                            setState(() {
                              var own = _moneyFormat.format(widget.lastTransaction.balance - spouseAmount);
                              _ownAmountController.text = own;
                            });
                          } else {
                            _ownAmountController.text = "Not enough money!";
                          }
                        }
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: Text("Set"),
                          onPressed: () async {
                            var success = false;

                            if (_vaultFormKey.currentState.validate()) {
                              // Check if quantities add correctly, otherwise throw (might happen
                              // if 'own' or 'spouse' are strings (with 'Not enough money!' text)
                              try {
                                var own = _cleanNumber(_ownAmountController.text);
                                var spouse = _cleanNumber(_spouseAmountController.text);
                                if (own + spouse == widget.lastTransaction.balance) {
                                  success = true;
                                }
                              } catch (e) {
                                BotToast.showText(
                                  text: "Error, not saved!",
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.red[700],
                                  duration: Duration(seconds: 3),
                                  contentPadding: EdgeInsets.all(10),
                                );
                              }

                              if (success) {
                                Navigator.of(context).pop();

                                widget.vaultStatus
                                  ..total = widget.lastTransaction.balance
                                  ..timestamp = widget.lastTransaction.date
                                  ..player = _cleanNumber(_ownAmountController.text)
                                  ..spouse = _cleanNumber(_spouseAmountController.text)
                                  ..error = false;
                                widget.callbackShares();

                                BotToast.showText(
                                  text: "Vault distribution saved!",
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                  contentPadding: EdgeInsets.all(10),
                                );
                              }
                            }
                          },
                        ),
                        SizedBox(width: 10),
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _ownAmountController.text = '';
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
                    MdiIcons.safeSquareOutline,
                    color: _themeProvider.secondBackground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _cleanNumber(String text) {
    if (text.isEmpty) return 0;
    var number = text.replaceAll("\$", "").replaceAll(".", "").replaceAll(",", "");
    return int.parse(number);
  }
}
