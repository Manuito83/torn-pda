import 'dart:async';
import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_bounty_model.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog_simple.dart';

final _money = NumberFormat.simpleCurrency(locale: 'en_US', decimalDigits: 0);

class FFScouterSavedBountyOrder {
  final String token;
  final String reference;
  final String url;
  final int targetId;

  FFScouterSavedBountyOrder({required this.token, required this.reference, required this.url, required this.targetId});

  factory FFScouterSavedBountyOrder.fromJson(Map<String, dynamic> json) => FFScouterSavedBountyOrder(
    token: json["token"] ?? "",
    reference: json["reference"] ?? "",
    url: json["url"] ?? "",
    targetId: json["target"] ?? 0,
  );

  Map<String, dynamic> toJson() => {"token": token, "reference": reference, "url": url, "target": targetId};

  static Future<List<FFScouterSavedBountyOrder>> load() async {
    final raw = await Prefs().getFFScouterBountyOrders();
    final orders = <FFScouterSavedBountyOrder>[];
    for (final item in raw) {
      try {
        orders.add(FFScouterSavedBountyOrder.fromJson(json.decode(item)));
      } catch (_) {}
    }
    return orders;
  }

  static Future<void> save(List<FFScouterSavedBountyOrder> orders) async {
    await Prefs().setFFScouterBountyOrders(orders.take(20).map((o) => json.encode(o.toJson())).toList());
  }
}

/// Places an order and then shows how to pay for it. Returns the order, if one was placed
Future<FFScouterSavedBountyOrder?> showFFScouterBountyOrderDialog(BuildContext context) async {
  final placed = await showDialog<(FFScouterSavedBountyOrder, FFScouterBountyPayment)>(
    context: context,
    builder: (_) => const _BountyOrderDialog(),
  );
  if (placed == null) return null;
  if (context.mounted) await showFFScouterBountyPaymentDialog(context, placed.$1, placed.$2);
  return placed.$1;
}

class _BountyOrderDialog extends StatefulWidget {
  const _BountyOrderDialog();

  @override
  State<_BountyOrderDialog> createState() => _BountyOrderDialogState();
}

class _BountyOrderDialogState extends State<_BountyOrderDialog> {
  final _target = TextEditingController();
  final _hits = TextEditingController(text: "10");
  final _price = TextEditingController(text: "500000");

  Timer? _debounce;
  FFScouterBountyQuote? _quote;
  String? _error;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _requestQuote();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _target.dispose();
    _hits.dispose();
    _price.dispose();
    super.dispose();
  }

  int? get _targetId => int.tryParse(_target.text.trim());
  int? get _quantity => int.tryParse(_hits.text.trim());
  int? get _pricePerHit => int.tryParse(_price.text.trim());

  void _requestQuote() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final quantity = _quantity;
      final price = _pricePerHit;
      if (quantity == null || price == null) {
        setState(() => _quote = null);
        return;
      }
      final result = await FFScouterComm.quoteBounty(quantity: quantity, pricePerHit: price);
      if (!mounted) return;
      setState(() {
        _quote = result.data;
        _error = result.success ? null : result.errorMessage;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    return AlertDialog(
      title: const Text("Place a bounty", style: TextStyle(fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Other players get paid for every hit on your target. FFScouter checks the hits and pays them. "
              "You pay with Xanax once the order is placed.",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            _field(_target, "Target player ID"),
            _field(_hits, "Number of hits (1-1000)", onChanged: _requestQuote),
            _field(_price, "Reward per hit (\$300,000 - \$10,000,000)", onChanged: _requestQuote),
            const SizedBox(height: 8),
            if (quote != null) ...[
              _row("Rewards", _money.format(quote.subtotal)),
              _row("Fee (${(quote.feePercent * 100).round()}%)", _money.format(quote.feeAmount)),
              _row("Total", _money.format(quote.totalPayable), bold: true),
              _row("Paid with", "${quote.expectedXanax} Xanax", bold: true),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
        TextButton(
          onPressed: _placing || quote == null || _targetId == null ? null : _place,
          child: _placing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Place order"),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, {VoidCallback? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 14),
        onChanged: (_) {
          setState(() {});
          onChanged?.call();
        },
        decoration: InputDecoration(isDense: true, border: const OutlineInputBorder(), labelText: label),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  Future<void> _place() async {
    final quote = _quote!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Place order?", style: TextStyle(fontSize: 16)),
        content: Text(
          "${_quantity!} hits on player ${_targetId!} for ${_money.format(_pricePerHit!)} each. "
          "You will need to send ${quote.expectedXanax} Xanax to pay for it.",
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Place order")),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _placing = true;
      _error = null;
    });
    final result = await FFScouterComm.orderBounty(
      target: _targetId!,
      quantity: _quantity!,
      pricePerHit: _pricePerHit!,
    );
    if (!mounted) return;
    if (!result.success || result.data == null) {
      setState(() {
        _placing = false;
        _error = result.errorMessage;
      });
      return;
    }

    final order = result.data!;
    final saved = FFScouterSavedBountyOrder(
      token: order.statusToken,
      reference: order.reference,
      url: order.statusUrl,
      targetId: _targetId!,
    );
    await FFScouterSavedBountyOrder.save([saved, ...await FFScouterSavedBountyOrder.load()]);
    if (!mounted) return;
    Navigator.of(context).pop((saved, order.payment));
  }
}

Future<void> showFFScouterBountyPaymentDialog(
  BuildContext context,
  FFScouterSavedBountyOrder order,
  FFScouterBountyPayment payment,
) {
  final deadline = payment.deadline != null
      ? DateFormat('HH:mm, d MMM').format(DateTime.fromMillisecondsSinceEpoch(payment.deadline! * 1000, isUtc: true))
      : null;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("Order ${order.reference}", style: const TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Send ${payment.xanaxExpected - payment.xanaxReceived} Xanax with this exact message"
            "${deadline != null ? " before $deadline TCT" : ""}:",
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          SelectableText(payment.message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "The order page on FFScouter shows who to send them to. The bounty goes live once it is fully paid.",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: payment.message));
            BotToast.showText(text: "Message copied");
          },
          child: const Text("Copy message"),
        ),
        TextButton(
          onPressed: () => openSimpleWebViewDialog(context: ctx, url: order.url, title: "Order ${order.reference}"),
          child: const Text("Order page"),
        ),
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close")),
      ],
    ),
  );
}
