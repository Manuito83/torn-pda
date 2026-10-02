import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_bounty_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/widgets/ffscouter/ffscouter_bounty_order_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog_simple.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

final _money = NumberFormat.compactSimpleCurrency(locale: 'en_US');

class FFScouterBountyBoardView extends StatefulWidget {
  const FFScouterBountyBoardView({super.key});

  @override
  State<FFScouterBountyBoardView> createState() => _FFScouterBountyBoardViewState();
}

class _FFScouterBountyBoardViewState extends State<FFScouterBountyBoardView> with AutomaticKeepAliveClientMixin {
  FFScouterBountyBoard? _board;
  FFScouterBountyClaims? _claims;
  bool _loading = false;
  String? _error;
  int? _errorCode;

  bool _policyRead = false;
  bool _accepting = false;

  final Map<int, int> _monitoring = {};
  final Set<int> _claiming = {};

  List<FFScouterSavedBountyOrder> _orders = [];
  final Map<String, FFScouterBountyOrderStatus> _orderStatus = {};

  String get _key => Get.find<UserController>().alternativeFFScouterKey;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await FFScouterComm.getBountyBoard(key: _key);
    final orders = await FFScouterSavedBountyOrder.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _board = result.data ?? _board;
      _claims = result.data?.claims ?? _claims;
      _error = result.success ? null : result.errorMessage;
      _errorCode = result.errorCode;
      _orders = orders;
    });
    _loadOrderStatus();
  }

  Future<void> _loadOrderStatus() async {
    for (final order in _orders) {
      final result = await FFScouterComm.getBountyOrder(token: order.token);
      if (!mounted) return;
      if (result.data != null) setState(() => _orderStatus[order.token] = result.data!);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.read<ThemeProvider>();
    final targets = _board?.targets ?? const <FFScouterBountyTarget>[];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        children: [
          _intro(themeProvider),
          if (_loading && _board == null)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorCode == 86)
            _consentCard(themeProvider)
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          if (_claims != null && (_claims!.pending.isNotEmpty || _claims!.recentHits.isNotEmpty))
            _claimsCard(themeProvider),
          if (_board != null) ...[
            _header("OPEN BOUNTIES"),
            if (targets.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text("There are no open bounties right now", style: TextStyle(color: Colors.grey[600])),
              ),
            for (final target in targets) _targetCard(target, themeProvider),
          ],
          if (_board != null && _orders.isNotEmpty) ...[
            _header("YOUR ORDERS"),
            for (final order in _orders) _orderCard(order),
          ],
        ],
      ),
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.pink[600]),
      ),
    );
  }

  Widget _intro(ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Players put bounties on other players through FFScouter. Hit a target from this list and FFScouter "
              "checks your attacks and pays you the reward. You can also place your own bounties.",
              style: TextStyle(fontSize: 12, color: themeProvider.mainText),
            ),
            if (_board != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Place a bounty"),
                    onPressed: () async {
                      final placed = await showFFScouterBountyOrderDialog(context);
                      if (placed != null && mounted) _load();
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _consentCard(ThemeProvider themeProvider) {
    final textStyle = TextStyle(fontSize: 12, color: themeProvider.mainText);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "To see and hit bounties you first need to accept the Bounty Board rules and data policy.",
              style: TextStyle(fontSize: 13, color: themeProvider.mainText),
            ),
            const SizedBox(height: 10),
            Text(
              "RULES",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.pink[600]),
            ),
            const SizedBox(height: 4),
            for (final rule in const [
              "You must hospitalize the target, no other finishing hit counts",
              "You only get paid if you finish the attack yourself, an assist does not count",
              "Claim the hit right after the attack, or it may not be credited",
              "Bounties are paid first come, first served, so claim without waiting",
              "Payments can take up to 12 hours",
              "Do not delete your API key until all your hits are paid, or they cannot be verified",
              "Questions go to the FFScouter Discord, never by mail to Glasnost",
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("- ", style: textStyle),
                    Expanded(child: Text(rule, style: textStyle)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              "DATA POLICY",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.pink[600]),
            ),
            const SizedBox(height: 4),
            for (final (label, value) in const [
              ("Storage", "Persistent, forever"),
              ("Shared with", "Bounty buyers (attack log data, your ID and name) and service owners (attack log data)"),
              ("Used for", "Community tool, attack confirmation, identity verification"),
              ("API key", "Stored and used only for automation. Limited, Full or Custom (attacks, battlestats)"),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(label, style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Text(value, style: textStyle)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _policyRead,
              onChanged: (value) => setState(() => _policyRead = value ?? false),
              title: Text("I have read the rules and the data policy", style: textStyle),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(onPressed: _disable, child: const Text("Disable")),
                TextButton(
                  onPressed: () => openSimpleWebViewDialog(
                    context: context,
                    url: 'https://ffscouter.com/claim-bounties',
                    title: 'FFScouter bounties',
                  ),
                  child: const Text("Full policy"),
                ),
                ElevatedButton(
                  onPressed: _policyRead && !_accepting ? _acceptPolicy : null,
                  child: _accepting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Accept"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptPolicy() async {
    setState(() => _accepting = true);
    final result = await FFScouterComm.acceptBountyPolicy(key: _key);
    if (!mounted) return;
    setState(() => _accepting = false);
    if (!result.success || result.data != true) {
      BotToast.showText(
        text: result.errorMessage ?? "Error contacting FFScouter",
        contentColor: Colors.red[800]!,
        textStyle: const TextStyle(fontSize: 13, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
      return;
    }
    _load();
  }

  Future<void> _disable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hide the Bounty Board", style: TextStyle(fontSize: 16)),
        content: const Text(
          "The tab disappears from the FFScouter section. You can bring it back from Settings, under the "
          "FFScouter options.",
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Hide")),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<SettingsProvider>().ffScouterBountiesEnabled = false;
  }

  Widget _claimsCard(ThemeProvider themeProvider) {
    final claims = _claims!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header("YOUR HITS"),
        for (final claim in claims.pending)
          Card(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.hourglass_top, color: Colors.orange),
              title: Text(claim.targetName, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                [
                  "Checking your attacks (${claim.successfulChecks}/${claim.requiredChecks})",
                  if (claim.creditedHits > 0) "${claim.creditedHits} hits credited",
                  if (claim.lastFailureReason != null) claim.lastFailureReason!,
                ].join("\n"),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        for (final hit in claims.recentHits)
          Card(
            child: ListTile(
              dense: true,
              leading: Icon(
                hit.payoutStatus == "paid" ? Icons.check_circle : Icons.schedule,
                color: hit.payoutStatus == "paid" ? Colors.green : Colors.blueGrey,
              ),
              title: Text("${hit.targetName}  +${_money.format(hit.reward)}", style: const TextStyle(fontSize: 14)),
              subtitle: Text(switch (hit.payoutStatus) {
                "paid" => "Paid",
                "pending" => "Payment on its way",
                _ => "Waiting for payment",
              }, style: const TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _targetCard(FFScouterBountyTarget target, ThemeProvider themeProvider) {
    final muted = Colors.grey[600];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${target.targetName} [${target.targetId}]",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeProvider.mainText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      "${target.totalRemaining} hits left",
                      if (target.estimate != null) "BS ${formatBigNumbers(target.estimate!)}",
                    ].join("  ·  "),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final tier in target.tiers)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green[700]!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${_money.format(tier.pricePerHit)} x${tier.remaining}",
                            style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  if (target.disabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        target.disabledReason == "buyer" ? "You placed this bounty" : "This bounty is on you",
                        style: TextStyle(fontSize: 11, color: muted, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
            if (!target.disabled)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => _hit(target),
                    child: Text("Hit ${_money.format(target.maxPricePerHit)}"),
                  ),
                  if (_monitoring.containsKey(target.targetId))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _claiming.contains(target.targetId) ? null : () => _claim(target),
                        child: _claiming.contains(target.targetId)
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Claim hit"),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(FFScouterSavedBountyOrder order) {
    final status = _orderStatus[order.token];
    final state = switch (status?.state) {
      "pending_payment" => "Waiting for your Xanax",
      "expired_unpaid" => "Expired without payment",
      "active" => "Live",
      "cancelling" => "Being cancelled",
      "refund_ready" => "Refund ready",
      "completed" => "Completed",
      "cancelled" => "Cancelled",
      _ => "Loading...",
    };
    return Card(
      child: ListTile(
        dense: true,
        title: Text(
          "${status?.targetName.isNotEmpty == true ? status!.targetName : "Player ${order.targetId}"}  "
          "(${order.reference})",
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          [
            state,
            if (status != null) "${status.quantityCredited}/${status.quantity} hits",
            if (status?.state == "pending_payment")
              "${status!.payment.xanaxReceived}/${status.payment.xanaxExpected} Xanax received",
          ].join("  ·  "),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (status?.state == "pending_payment") {
            showFFScouterBountyPaymentDialog(context, order, status!.payment);
          } else {
            openSimpleWebViewDialog(context: context, url: order.url, title: "Order ${order.reference}");
          }
        },
      ),
    );
  }

  Future<void> _hit(FFScouterBountyTarget target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Hit ${target.targetName}", style: const TextStyle(fontSize: 16)),
        content: const Text(
          "You have to hospitalize the target, and only the hit that hospitalizes counts. Assists do not count "
          "either. Come back and claim the hit right after the attack, because bounties are paid first come, "
          "first served.",
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Attack")),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _monitoring[target.targetId] = DateTime.now().millisecondsSinceEpoch ~/ 1000);
    context.read<WebViewProvider>().openBrowserPreference(
      context: context,
      url: 'https://www.torn.com/page.php?sid=attack&user2ID=${target.targetId}',
      browserTapType: BrowserTapType.short,
    );
  }

  Future<void> _claim(FFScouterBountyTarget target) async {
    setState(() => _claiming.add(target.targetId));
    final result = await FFScouterComm.claimBounty(
      key: _key,
      target: target.targetId,
      monitoringStartedAt: _monitoring[target.targetId],
    );
    if (!mounted) return;
    setState(() => _claiming.remove(target.targetId));

    if (!result.success) {
      BotToast.showText(
        text: result.errorMessage ?? "Error contacting FFScouter",
        contentColor: Colors.red[800]!,
        textStyle: const TextStyle(fontSize: 13, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
      if (result.errorCode == 91) _load();
      return;
    }

    setState(() {
      _claims = result.data;
      _monitoring.remove(target.targetId);
    });
    BotToast.showText(
      text: "Hit sent. FFScouter is checking your attack log",
      contentColor: Colors.green[800]!,
      textStyle: const TextStyle(fontSize: 13, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }
}
