// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_model.dart';

// Project imports:
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';

class SharePriceDialog extends StatefulWidget {
  final StockMarketStock stock;
  final Function callbackPrices;

  SharePriceDialog({
    @required this.stock,
    @required this.callbackPrices,
  });

  @override
  _SharePriceDialogState createState() => _SharePriceDialogState();
}

class _SharePriceDialogState extends State<SharePriceDialog> {
  ThemeProvider _themeProvider;

  final _gainController = new TextEditingController();
  final _lossController = new TextEditingController();
  var _formKey = GlobalKey<FormState>();

  final _gainFocus = FocusNode();
  final _lossFocus = FocusNode();

  String _gainHint = "";
  String _lossHint = "";

  final _moneyFormat = new NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();

    if (widget.stock.alertGain == null) {
      _gainHint = "\$${widget.stock.currentPrice}";
    } else {
      var gainExisting = "\$${_moneyFormat.format(widget.stock.alertGain)}";
      _gainController.value = TextEditingValue(
        text: gainExisting,
        selection: TextSelection.collapsed(offset: gainExisting.length),
      );
    }

    if (widget.stock.alertLoss == null) {
      _lossHint = "\$${widget.stock.currentPrice}";
    } else {
      var lossExisting = "\$${_moneyFormat.format(widget.stock.alertLoss)}";
      _lossController.value = TextEditingValue(
        text: lossExisting,
        selection: TextSelection.collapsed(offset: lossExisting.length),
      );
    }
  }

  @override
  void dispose() {
    _gainController.dispose();
    _lossController.dispose();
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
                color: _themeProvider.background,
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
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                      child: Text(
                        "Configure your price alerts here."
                        "\n\nUse the red bin icon to the right to remove the current alert.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        "Gain alert price",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Focus(
                            focusNode: _gainFocus,
                            child: TextFormField(
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _cleanNumber(_gainController.text) < widget.stock.currentPrice
                                      ? Colors.orange[800]
                                      : _themeProvider.mainText),
                              controller: _gainController,
                              maxLength: 20,
                              minLines: 1,
                              maxLines: 1,
                              decoration: InputDecoration(
                                labelText: _gainHint,
                                //hintText: _gainHint,
                                counterText: "",
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (gainString) {
                                if (gainString.isNotEmpty || gainString != "\$") {
                                  var gainAmount = _cleanNumber(gainString);
                                  gainString = '\$${_moneyFormat.format(gainAmount)}';
                                  _gainController.value = TextEditingValue(
                                    text: gainString,
                                    selection: TextSelection.collapsed(offset: gainString.length),
                                  );
                                  // Calculate percentage and show as hint
                                  setState(() {
                                    var sign = "";
                                    if (gainAmount > widget.stock.currentPrice) {
                                      sign = "+";
                                    } else if (gainAmount < widget.stock.currentPrice) {
                                      sign = "-";
                                    }
                                    var per = (gainAmount * 100 / widget.stock.currentPrice) - 100;
                                    _gainHint = "$sign${per.floor()}%";
                                  });
                                }
                              },
                              validator: (value) {
                                if (value.isNotEmpty &&
                                    _cleanNumber(_gainController.text) <=
                                        widget.stock.currentPrice) {
                                  return "Must be above current price!";
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                          onPressed: () {
                            _gainController.value = TextEditingValue(
                              text: "",
                              selection: TextSelection.collapsed(offset: 0),
                            );
                            setState(() {
                              _gainHint = "disabled!";
                            });
                            _gainFocus.unfocus();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        "Loss price alert",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Focus(
                            focusNode: _lossFocus,
                            child: TextFormField(
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _cleanNumber(_lossController.text) > widget.stock.currentPrice
                                      ? Colors.orange[800]
                                      : _themeProvider.mainText),
                              controller: _lossController,
                              maxLength: 20,
                              minLines: 1,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: _lossHint,
                                //hintText: _lossHint,
                                counterText: "",
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (lossString) {
                                if (lossString.isNotEmpty || lossString != "\$") {
                                  var lossAmount = _cleanNumber(lossString);
                                  lossString = '\$${_moneyFormat.format(lossAmount)}';
                                  _lossController.value = TextEditingValue(
                                    text: lossString,
                                    selection: TextSelection.collapsed(offset: lossString.length),
                                  );
                                  // Calculate percentage and show as hint
                                  setState(() {
                                    var sign = "";
                                    if (lossAmount > widget.stock.currentPrice) {
                                      sign = "+";
                                    } else if (lossAmount < widget.stock.currentPrice) {
                                      sign = "-";
                                    }
                                    var per = (lossAmount * 100 / widget.stock.currentPrice) - 100;
                                    _lossHint = "$sign${per.floor()}%";
                                  });
                                }
                              },
                              validator: (value) {
                                if (value.isNotEmpty &&
                                    _cleanNumber(_lossController.text) >=
                                        widget.stock.currentPrice) {
                                  return "Must be below current price!";
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                          onPressed: () {
                            _lossController.value = TextEditingValue(
                              text: "",
                              selection: TextSelection.collapsed(offset: 0),
                            );
                            setState(() {
                              _lossHint = "disabled!";
                            });
                            _lossFocus.unfocus();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: Text("Set"),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            bool success = false;

                            // Might be passed as null if we are removing
                            int gain;
                            int loss;

                            try {
                              if (_formKey.currentState.validate()) {
                                String action = "${widget.stock.acronym}-";
                                // If all is empty, we'll delete the
                                if (_gainController.text.isEmpty && _lossController.text.isEmpty) {
                                  action += "remove";
                                } else {
                                  // Set gain
                                  if (_gainController.text.isNotEmpty) {
                                    gain = _cleanNumber(_gainController.text);
                                    action += "G-$gain-";
                                  } else {
                                    action += "G-n-";
                                  }
                                  // Set loss
                                  if (_lossController.text.isNotEmpty) {
                                    loss = _cleanNumber(_lossController.text);
                                    action += "L-${_cleanNumber(_lossController.text)}";
                                  } else {
                                    action += "L-n";
                                  }
                                }
                                // Upload
                                success = await firestore.addStockMarketShare(
                                    widget.stock.acronym, action);
                              }
                            } catch (e) {
                              success = false;
                            }

                            if (success) {
                              widget.callbackPrices(gain, loss);

                              BotToast.showText(
                                text: "Saved ${widget.stock.acronym}!",
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.green,
                                duration: Duration(seconds: 3),
                                contentPadding: EdgeInsets.all(10),
                              );
                            } else {
                              BotToast.showText(
                                text: "There was an error saving ${widget.stock.acronym}, "
                                    "please try again later!",
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.red[800],
                                duration: Duration(seconds: 3),
                                contentPadding: EdgeInsets.all(10),
                              );
                            }
                          },
                        ),
                        SizedBox(width: 10),
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _gainController.text = '';
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
              backgroundColor: _themeProvider.background,
              child: CircleAvatar(
                backgroundColor: _themeProvider.mainText,
                radius: 22,
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: Icon(
                    MdiIcons.chartLine,
                    color: _themeProvider.background,
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
    if (text.isEmpty || text == "\$") return 0;
    var number = text.replaceAll("\$", "").replaceAll(".", "").replaceAll(",", "");
    return int.parse(number);
  }
}
