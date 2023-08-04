// Flutter imports:
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
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
  final UserDetailsProvider? userProvider;
  final Function callbackShares;

  const VaultConfigurationDialog({
    required this.lastTransaction,
    required this.vaultStatus,
    required this.userProvider,
    required this.callbackShares,
  });

  @override
  _VaultConfigurationDialogState createState() => _VaultConfigurationDialogState();
}

class _VaultConfigurationDialogState extends State<VaultConfigurationDialog> {
  late ThemeProvider _themeProvider;

  final _ownAmountController = TextEditingController();
  final _spouseAmountController = TextEditingController();
  final _vaultFormKey = GlobalKey<FormState>();

  final _moneyFormat = NumberFormat("#,##0", "en_US");

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
    _themeProvider = Provider.of<ThemeProvider>(context);
    return SingleChildScrollView(
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
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        "${widget.userProvider!.basic!.name}'s share",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    TextFormField(
                      style: const TextStyle(fontSize: 13),
                      controller: _ownAmountController,
                      maxLength: 20,
                      minLines: 1,
                      decoration: InputDecoration(
                        prefixText: "\$ ",
                        labelText: widget.vaultStatus.player == null
                            ? "\$ 0"
                            : "\$ ${_moneyFormat.format(widget.vaultStatus.player)}",
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        counterText: "",
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]?[\d,]*$'))],
                      onChanged: (ownString) {
                        if (ownString.isNotEmpty && ownString != "-") {
                          final ownAmount = _cleanNumber(ownString);
                          ownString = _moneyFormat.format(ownAmount);
                          _ownAmountController.value = TextEditingValue(
                            text: ownString,
                            selection: TextSelection.collapsed(offset: ownString.length),
                          );

                          // Set the other fields value
                          if (ownAmount <= widget.lastTransaction.balance!) {
                            setState(() {
                              final spouse = _moneyFormat.format(widget.lastTransaction.balance! - ownAmount);
                              _spouseAmountController.text = spouse;
                            });
                          } else {
                            _spouseAmountController.text = "Not enough money!";
                          }
                        }
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        widget.userProvider!.basic!.married?.spouseId == 0
                            ? "Spouse's share"
                            : "${widget.userProvider!.basic!.married!.spouseName}'s share",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    TextFormField(
                      style: const TextStyle(fontSize: 13),
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
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]?[\d,]*$'))],
                      onChanged: (spouseString) {
                        if (spouseString.isNotEmpty && spouseString != "-") {
                          final spouseAmount = _cleanNumber(spouseString);
                          spouseString = _moneyFormat.format(spouseAmount);
                          _spouseAmountController.value = TextEditingValue(
                            text: spouseString,
                            selection: TextSelection.collapsed(offset: spouseString.length),
                          );

                          // Set the other fields value
                          if (spouseAmount <= widget.lastTransaction.balance!) {
                            setState(() {
                              final own = _moneyFormat.format(widget.lastTransaction.balance! - spouseAmount);
                              _ownAmountController.text = own;
                            });
                          } else {
                            _ownAmountController.text = "Not enough money!";
                          }
                        }
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Set"),
                          onPressed: () async {
                            var success = false;

                            if (_vaultFormKey.currentState!.validate()) {
                              // Check if quantities add correctly, otherwise throw (might happen
                              // if 'own' or 'spouse' are strings (with 'Not enough money!' text)
                              try {
                                final own = _cleanNumber(_ownAmountController.text);
                                final spouse = _cleanNumber(_spouseAmountController.text);
                                if (own + spouse == widget.lastTransaction.balance) {
                                  success = true;
                                }
                              } catch (e) {
                                BotToast.showText(
                                  text: "Error, not saved!",
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.red[700]!,
                                  duration: const Duration(seconds: 3),
                                  contentPadding: const EdgeInsets.all(10),
                                );
                              }

                              if (success) {
                                Navigator.of(context).pop();

                                widget.vaultStatus
                                  ..total = widget.lastTransaction.balance!
                                  ..timestamp = widget.lastTransaction.date!
                                  ..player = _cleanNumber(_ownAmountController.text)
                                  ..spouse = _cleanNumber(_spouseAmountController.text)
                                  ..error = false;
                                widget.callbackShares();

                                BotToast.showText(
                                  text: "Vault distribution saved!",
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                  contentPadding: const EdgeInsets.all(10),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          child: const Text("Cancel"),
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
    final number = text.replaceAll("\$", "").replaceAll(".", "").replaceAll(",", "");
    return int.parse(number);
  }
}
