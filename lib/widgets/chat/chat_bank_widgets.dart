import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_banking.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Buttons under a money request, for bankers
class ChatBankInsert extends StatelessWidget {
  const ChatBankInsert({super.key, required this.message});

  final ChatMessage message;

  static const Key buttonKey = ValueKey('bank-give');
  static const Key paidKey = ValueKey('bank-paid');

  @visibleForTesting
  static ChatController Function() chat = () => NativeChat.controller;

  ChatBankEntry? _entry() {
    final list = chat().messagesFor(message.roomId);
    return ChatBanking.states(list)[message.id] ?? ChatBanking.derive([message])[message.id];
  }

  Future<void> _markPaid(BuildContext context, int? amount) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _BankPaidDialog(to: message.sender, amount: amount),
    );
    if (text != null) chat().send(text, to: message.roomId);
  }

  Future<void> _giveAgain(BuildContext context, ChatBankEntry entry, String paidBy) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Already paid'),
        content: Text('$paidBy marked this request as paid. Open the vault page anyway?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Open')),
        ],
      ),
    );
    if (go == true) NativeChat.openLink(ChatBanking.link(message.sender.id, entry.request));
  }

  @override
  Widget build(BuildContext context) {
    final prefs = NativeChat.prefs;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        if (!prefs.factionBanker || !ChatBanking.appliesTo(message.roomId)) return const SizedBox.shrink();
        return ListenableBuilder(listenable: chat(), builder: (context, _) => _buttons(context));
      },
    );
  }

  Widget _buttons(BuildContext context) {
    final entry = _entry();
    if (entry == null || entry.status == ChatBankStatus.replaced) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final amount = entry.request.amount;
    final hidden = ChatSwiping.of(context);
    final muted = theme.textTheme.labelMedium?.copyWith(color: theme.hintColor);
    final paidBy = entry.paidBy;
    final paidName = paidBy == null ? 'Someone' : NativeChat.prefs.displayName(paidBy.id, paidBy.name);
    final giveLabel = amount == null ? 'Give money' : 'Give ${ChatBanking.figure(amount)}';
    final children = switch (entry.status) {
      ChatBankStatus.open => [
        if (entry.safe)
          Tooltip(
            message: 'Request in the PDA format',
            child: Icon(Icons.verified_outlined, size: 18, color: theme.colorScheme.primary),
          ),
        ActionChip(
          key: buttonKey,
          avatar: const Icon(Icons.account_balance_outlined, size: 18),
          label: Text(giveLabel),
          onPressed: () => NativeChat.openLink(ChatBanking.link(message.sender.id, entry.request)),
        ),
        ActionChip(
          key: paidKey,
          avatar: const Icon(Icons.done_rounded, size: 18),
          label: const Text('Mark as paid'),
          onPressed: () => _markPaid(context, amount),
        ),
      ],
      ChatBankStatus.paid => [
        ActionChip(
          key: buttonKey,
          avatar: Icon(Icons.account_balance_outlined, size: 18, color: theme.hintColor),
          label: Text(giveLabel, style: muted),
          onPressed: () => _giveAgain(context, entry, paidName),
        ),
        Icon(Icons.check_circle_outline_rounded, size: 16, color: theme.hintColor),
        Text(paidBy == null ? 'Paid' : 'Paid by $paidName', style: muted),
      ],
      _ => [Icon(Icons.block_rounded, size: 16, color: theme.hintColor), Text('Cancelled', style: muted)],
    };
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedOpacity(
        opacity: hidden ? 0 : 1,
        duration: chatMotion(context, const Duration(milliseconds: 120)),
        child: Padding(
          padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
          child: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: children),
        ),
      ),
    );
  }
}

class _BankPaidDialog extends StatefulWidget {
  const _BankPaidDialog({required this.to, required this.amount});

  final ChatUser to;
  final int? amount;

  @override
  State<_BankPaidDialog> createState() => _BankPaidDialogState();
}

class _BankPaidDialogState extends State<_BankPaidDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.amount == null ? '' : ChatBanking.grouped(widget.amount!),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _blank => _text.text.trim().isEmpty;

  int? get _amount => ChatBanking.parseTyped(_text.text);

  @override
  Widget build(BuildContext context) {
    final valid = _blank || _amount != null;
    final text = ChatBanking.paidText(widget.to, _blank ? null : _amount);
    return AlertDialog(
      title: const Text('Mark as paid'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _text,
            keyboardType: TextInputType.text,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Amount paid (optional)',
              prefixText: '\$ ',
              errorText: valid ? null : 'Enter an amount like 5m or 250000',
            ),
          ),
          const SizedBox(height: 12),
          Text('Sends to the faction chat:', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: valid ? () => Navigator.of(context).pop(text) : null, child: const Text('Send')),
      ],
    );
  }
}

/// Composer text, null when cancelled
Future<String?> showChatBankRequest(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _BankRequestDialog());

class _BankRequestDialog extends StatefulWidget {
  const _BankRequestDialog();

  @override
  State<_BankRequestDialog> createState() => _BankRequestDialogState();
}

class _BankRequestDialogState extends State<_BankRequestDialog> {
  final TextEditingController _text = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = ChatBanking.parseTyped(_text.text);
    if (amount == null) return setState(() => _invalid = true);
    Navigator.of(context).pop(ChatBanking.requestText(amount));
  }

  @override
  Widget build(BuildContext context) {
    Widget quick(IconData icon, String label, String text) => ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      onPressed: () => Navigator.of(context).pop(text),
    );
    return AlertDialog(
      title: const Text('Request money'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_invalid) setState(() => _invalid = false);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Amount',
              hintText: 'For example 5m, 250k or 1,500,000',
              prefixText: '\$ ',
              errorText: _invalid ? 'Enter an amount like 5m or 250000' : null,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              quick(Icons.account_balance_wallet_outlined, 'Request full balance', ChatBanking.fullText),
              quick(Icons.undo_rounded, 'Cancel request', ChatBanking.cancelText),
              quick(Icons.campaign_outlined, 'Call bankers', ChatBanking.callText),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Add to message')),
      ],
    );
  }
}
