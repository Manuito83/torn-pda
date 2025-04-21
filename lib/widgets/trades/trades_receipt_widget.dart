import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_receipt.dart';
import 'package:torn_pda/utils/external/torn_exchange_comm.dart';

class TradeReceiptData {
  final String message;
  final String url;

  TradeReceiptData({
    required this.message,
    required this.url,
  });
}

class TradeReceiptRow extends StatefulWidget {
  final Widget clipboardIcon;
  final TornExchangeReceiptOutModel tornExchangeOutModel;

  const TradeReceiptRow({
    super.key,
    required this.clipboardIcon,
    required this.tornExchangeOutModel,
  });

  @override
  State<TradeReceiptRow> createState() => _TradeReceiptRowState();
}

class _TradeReceiptRowState extends State<TradeReceiptRow> {
  TradeReceiptData? _receiptData;

  static const ttColor = Color(0xffd186cf);

  bool _isFetching = false;

  void _copyToClipboard(String content, String successMessage, {int seconds = 5}) {
    Clipboard.setData(ClipboardData(text: content));
    BotToast.showText(
      text: successMessage,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.green,
      duration: Duration(seconds: seconds),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  /// Torn Exchange changes the URL everytime we call the getReceipt endpoint
  /// With this approach we make sure to just call once and use the URL for two buttons
  Future<void> _fetchReceipt() async {
    if (_receiptData != null) {
      return;
    }
    if (_isFetching) {
      return;
    }

    setState(() => _isFetching = true);

    try {
      final receiptOut = widget.tornExchangeOutModel;

      final receipt = await TornExchangeComm.getReceipt(receiptOut);

      if (receipt.serverError) {
        BotToast.showText(
          text: "There was an error getting your receipt, no information copied!",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );
      } else {
        String message = receipt.tradeMessage;
        final url = "https://www.tornexchange.com/receipt/${receipt.receiptId}";

        if (message.isEmpty) {
          message = "Thanks for the trade! Your receipt is available at $url\n\n"
              "Note: this is a default receipt template, you can create your own in Torn Exchange";
        }

        setState(() {
          _receiptData = TradeReceiptData(message: message, url: url);
        });
      }
    } catch (e) {
      BotToast.showText(
        text: "Error getting your receipt: $e",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    } finally {
      setState(() => _isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // FIRST BUTTON
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: widget.clipboardIcon,
        ),
        // SECOND BUTTON
        SizedBox(
          height: 23,
          width: 23,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 23,
            icon: const Icon(
              Icons.receipt_long_outlined,
              size: 23,
              color: ttColor,
            ),
            onPressed: () async {
              await _fetchReceipt();
              if (_receiptData != null) {
                _copyToClipboard(
                  _receiptData!.message,
                  "Receipt copied to clipboard:\n\n${_receiptData!.message}",
                  seconds: 8,
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        // THIRD BUTTON
        SizedBox(
          height: 23,
          width: 23,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 23,
            icon: const Icon(
              MdiIcons.webCheck,
              size: 23,
              color: ttColor,
            ),
            onPressed: () async {
              await _fetchReceipt();
              if (_receiptData != null) {
                _copyToClipboard(
                  _receiptData!.url,
                  "Receipt URL copied to clipboard:\n\n${_receiptData!.url}",
                  seconds: 5,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
