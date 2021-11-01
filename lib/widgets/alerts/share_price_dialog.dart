// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/services.dart';
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

  bool _inputCashGain = true;
  bool _inputCashLoss = true;

  final _gainController = new TextEditingController();
  final _lossController = new TextEditingController();
  var _formKey = GlobalKey<FormState>();

  final _gainFocus = FocusNode();
  final _lossFocus = FocusNode();

  String _gainHintCash = "";
  String _gainHintPercent = "";
  String _lossHintCash = "";
  String _lossHintPercent = "";

  @override
  void initState() {
    super.initState();

    if (widget.stock.alertGain == null) {
      double initCash = widget.stock.currentPrice + 10;
      double initPercent = (widget.stock.currentPrice + 10) * 100 / widget.stock.currentPrice - 100;
      _gainHintCash = "\$${removeZeroDecimals(initCash)}";
      _gainHintPercent = "+${initPercent.toStringAsFixed(2)}%";
    } else {
      String gainExisting = "${(removeZeroDecimals(widget.stock.alertGain))}";
      _gainController.value = TextEditingValue(
        text: gainExisting,
        selection: TextSelection.collapsed(offset: gainExisting.length),
      );
      _gainHintCash = "\$${removeZeroDecimals(widget.stock.alertGain)}";
      _gainHintPercent = "+${(widget.stock.alertGain * 100 / widget.stock.currentPrice - 100).toStringAsFixed(2)}%";
    }

    if (widget.stock.alertLoss == null) {
      double initCash = widget.stock.currentPrice - 10;
      double initPercent = (widget.stock.currentPrice - 10) * 100 / widget.stock.currentPrice - 100;
      _lossHintCash = "\$${removeZeroDecimals(initCash)}";
      _lossHintPercent = "${initPercent.toStringAsFixed(2)}%";
    } else {
      String lossExisting = "${(removeZeroDecimals(widget.stock.alertLoss))}";
      _lossController.value = TextEditingValue(
        text: lossExisting,
        selection: TextSelection.collapsed(offset: lossExisting.length),
      );
      _lossHintCash = "\$${removeZeroDecimals(widget.stock.alertLoss)}";
      _lossHintPercent = "${(widget.stock.alertLoss * 100 / widget.stock.currentPrice - 100).toStringAsFixed(2)}%";
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
                        "Configure your price alerts here. "
                        "Use the red bin icon to the right to remove the current alert."
                        "\n\n"
                        "${widget.stock.acronym}'s price: \$${widget.stock.currentPrice}",
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
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Text(
                        '${_inputCashGain ? _gainHintPercent.isEmpty ? "" : "($_gainHintPercent)" : _gainHintCash.isEmpty ? "" : "($_gainHintCash)"}',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Focus(
                            focusNode: _gainFocus,
                            child: TextFormField(
                              style: TextStyle(
                                fontSize: 13,
                                color: _returnColor(fromGain: true),
                              ),
                              controller: _gainController,
                              maxLength: 7,
                              minLines: 1,
                              maxLines: 1,
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                                prefixText: _inputCashGain ? "\$ " : "\% ",
                                labelText: _inputCashGain ? _gainHintCash : _gainHintPercent,
                                labelStyle: TextStyle(fontStyle: FontStyle.italic),
                                //hintText: _gainHint,
                                counterText: "",
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\+?\d+(\.)?(\d{1,2})?'),
                                )
                              ],
                              onChanged: (gainString) {
                                if (gainString.isNotEmpty) {
                                  var gainInput = _cleanNumberAbs(gainString);

                                  // We update the hints independently of if we are inputting cash or percentage,
                                  // so that we keep both always up to date
                                  // Percentage hint
                                  var sign = "";
                                  if (gainInput > widget.stock.currentPrice) {
                                    sign = "+";
                                  }
                                  var percentage = (gainInput * 100 / widget.stock.currentPrice) - 100;

                                  // Cash hint
                                  double cash = 0;
                                  if (_inputCashGain) {
                                    cash = gainInput;
                                  } else {
                                    cash = (gainInput * widget.stock.currentPrice / 100) + widget.stock.currentPrice;
                                  }

                                  setState(() {
                                    // Update both hints
                                    _gainHintPercent = "$sign${percentage.toStringAsFixed(2)}%";
                                    _gainHintCash = "\$${cash.toStringAsFixed(2)}";

                                    // If we are inserting percentage, make sure there is a "+" sign in the
                                    // actual text field (automatically, as we don't allow the user to input "+")
                                    if (!_inputCashGain && !_gainController.text.contains("+")) {
                                      String addSign = "\+${_gainController.text}";
                                      _gainController.value = TextEditingValue(
                                        text: addSign,
                                        selection: TextSelection.collapsed(offset: addSign.length),
                                      );
                                    }
                                  });
                                } else {
                                  setState(() {
                                    _gainHintCash = "";
                                    _gainHintPercent = "";
                                  });
                                }
                              },
                              validator: (value) {
                                double priceValidator = _cleanNumber(_gainController.text);
                                if (!_inputCashGain) {
                                  priceValidator =
                                      (priceValidator * widget.stock.currentPrice / 100) + widget.stock.currentPrice;
                                }
                                if (value.isNotEmpty && priceValidator <= widget.stock.currentPrice) {
                                  return "Must be above ${widget.stock.currentPrice}!";
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: _inputCashGain ? Icon(MdiIcons.percent) : Icon(MdiIcons.cash),
                          onPressed: () {
                            setState(() {
                              _inputCashGain = !_inputCashGain;

                              // If the text field is not empty (using only hints), it is not enough to update
                              // just the hints. We need to update the text field as well
                              if (_gainController.text.isNotEmpty) {
                                if (_inputCashGain) {
                                  // Change from percentage to cash
                                  _gainHintPercent = "${_gainController.text}%";
                                  var newText = _gainHintCash.replaceAll("\$", "").replaceAll("%", "");
                                  _gainController.value = TextEditingValue(
                                    text: newText,
                                    selection: TextSelection.collapsed(offset: newText.length),
                                  );
                                } else {
                                  // Change from cash to percentage
                                  _gainHintCash = "\$${_gainController.text}";
                                  var newText = _gainHintPercent.replaceAll("\$", "").replaceAll("%", "");
                                  _gainController.value = TextEditingValue(
                                    text: newText,
                                    selection: TextSelection.collapsed(offset: newText.length),
                                  );
                                }
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                          onPressed: () {
                            _gainController.value = TextEditingValue(
                              text: "",
                              selection: TextSelection.collapsed(offset: 0),
                            );
                            setState(() {
                              _gainHintCash = "";
                              _gainHintPercent = "";
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
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Text(
                        '${_inputCashLoss ? _lossHintPercent.isEmpty ? "" : "($_lossHintPercent)" : _lossHintCash.isEmpty ? "" : "($_lossHintCash)"}',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Focus(
                            focusNode: _lossFocus,
                            child: TextFormField(
                              style: TextStyle(
                                fontSize: 13,
                                color: _returnColor(fromGain: false),
                              ),
                              controller: _lossController,
                              maxLength: 7,
                              minLines: 1,
                              maxLines: 2,
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                                prefixText: _inputCashLoss ? "\$ " : "\% ",
                                labelText: _inputCashLoss ? _lossHintCash : _lossHintPercent,
                                labelStyle: TextStyle(fontStyle: FontStyle.italic),
                                //hintText: _lossHint,
                                counterText: "",
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\-?\d+(\.)?(\d{1,2})?'),
                                )
                              ],
                              onChanged: (lossString) {
                                if (lossString.isNotEmpty) {
                                  var lossInput = _cleanNumberAbs(lossString);

                                  // We update the hints independently of if we are inputting cash or percentage,
                                  // so that we keep both always up to date
                                  // Percentage hint
                                  var sign = "";
                                  if (lossInput > widget.stock.currentPrice) {
                                    sign = "+";
                                  }
                                  var percentage = (lossInput * 100 / widget.stock.currentPrice) - 100;

                                  // Cash hint
                                  double cash = 0;
                                  if (_inputCashLoss) {
                                    cash = lossInput;
                                  } else {
                                    cash = widget.stock.currentPrice - (lossInput * widget.stock.currentPrice / 100);
                                  }

                                  setState(() {
                                    // Update both hints
                                    _lossHintPercent = "$sign${percentage.toStringAsFixed(2)}%";
                                    _lossHintCash = "\$${cash.toStringAsFixed(2)}";

                                    // If we are inserting percentage, make sure there is a "+" sign in the
                                    // actual text field (automatically, as we don't allow the user to input "+")
                                    if (!_inputCashLoss && !_lossController.text.contains("-")) {
                                      String addSign = "\-${_lossController.text}";
                                      _lossController.value = TextEditingValue(
                                        text: addSign,
                                        selection: TextSelection.collapsed(offset: addSign.length),
                                      );
                                    }
                                  });
                                } else {
                                  setState(() {
                                    _lossHintCash = "";
                                    _lossHintPercent = "";
                                  });
                                }
                              },
                              validator: (value) {
                                double priceValidator = _cleanNumber(_lossController.text);
                                if (!_inputCashLoss) {
                                  priceValidator =
                                      widget.stock.currentPrice + (priceValidator * widget.stock.currentPrice / 100);
                                }
                                if (value.isNotEmpty && priceValidator >= widget.stock.currentPrice) {
                                  return "Must be below ${widget.stock.currentPrice}!";
                                }
                                if (value.isNotEmpty && priceValidator <= 0) {
                                  return "Must be above \$0!";
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: _inputCashLoss ? Icon(MdiIcons.percent) : Icon(MdiIcons.cash),
                          onPressed: () {
                            setState(() {
                              _inputCashLoss = !_inputCashLoss;

                              // If the text field is not empty (using only hints), it is not enough to update
                              // just the hints. We need to update the text field as well
                              if (_lossController.text.isNotEmpty) {
                                if (_inputCashLoss) {
                                  // Change from percentage to cash
                                  _lossHintPercent = "${_lossController.text}%";
                                  var newText = _lossHintCash.replaceAll("\$", "").replaceAll("%", "");
                                  _lossController.value = TextEditingValue(
                                    text: newText,
                                    selection: TextSelection.collapsed(offset: newText.length),
                                  );
                                } else {
                                  // Change from cash to percentage
                                  _lossHintCash = "\$${_lossController.text}";
                                  var newText = _lossHintPercent.replaceAll("\$", "").replaceAll("%", "");
                                  _lossController.value = TextEditingValue(
                                    text: newText,
                                    selection: TextSelection.collapsed(offset: newText.length),
                                  );
                                }
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                          onPressed: () {
                            _lossController.value = TextEditingValue(
                              text: "",
                              selection: TextSelection.collapsed(offset: 0),
                            );
                            setState(() {
                              _lossHintCash = "";
                              _lossHintPercent = "";
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
                            bool success = false;

                            // Might be passed as null if we are removing
                            double gain;
                            double loss;

                            try {
                              if (_formKey.currentState.validate()) {
                                Navigator.of(context).pop();
                                String action = "${widget.stock.acronym}-";
                                // If all is empty, we'll delete the
                                if (_gainController.text.isEmpty && _lossController.text.isEmpty) {
                                  action += "remove";
                                } else {
                                  // Set gain
                                  if (_gainController.text.isNotEmpty) {
                                    gain = _cleanNumberAbs(_gainController.text);
                                    if (!_inputCashGain) {
                                      gain = (gain * widget.stock.currentPrice / 100) + widget.stock.currentPrice;
                                      gain = _cleanNumberAbs(gain.toStringAsFixed(2));
                                    }
                                    action += "G-$gain-";
                                  } else {
                                    action += "G-n-";
                                  }
                                  // Set loss
                                  if (_lossController.text.isNotEmpty) {
                                    loss = _cleanNumberAbs(_lossController.text);
                                    if (!_inputCashLoss) {
                                      loss = widget.stock.currentPrice - (loss * widget.stock.currentPrice / 100);
                                      loss = _cleanNumberAbs(loss.toStringAsFixed(2));
                                    }
                                    action += "L-${_cleanNumberAbs(loss.toStringAsFixed(2))}";
                                  } else {
                                    action += "L-n";
                                  }
                                }
                                // Upload
                                success = await firestore.addStockMarketShare(widget.stock.acronym, action);
                              } else {
                                // Return with no validation
                                return;
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

  double _cleanNumber(String text) {
    if (text.isEmpty) return 0;
    return double.parse(text);
  }

  double _cleanNumberAbs(String text) {
    if (text.isEmpty) return 0;
    return double.parse(text).abs();
  }

  String removeZeroDecimals(double input) {
    return input.toString().replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "");
  }

  Color _returnColor({@required bool fromGain}) {
    if (fromGain) {
      if (_cleanNumber(_gainHintCash.replaceAll("\$", "")) < widget.stock.currentPrice) {
        return Colors.orange[800];
      }
    } else if (!fromGain) {
      double lossCheck = _cleanNumber(_lossHintCash.replaceAll("\$", ""));
      if (lossCheck > widget.stock.currentPrice || lossCheck <= 0) {
        return Colors.orange[800];
      }
    }

    return _themeProvider.mainText;
  }
}
