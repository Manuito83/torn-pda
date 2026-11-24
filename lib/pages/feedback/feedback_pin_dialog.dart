import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_input.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

Future<void> showFeedbackPinDialog(BuildContext context, FeedbackPinMode mode) {
  return showDialog<void>(
    context: context,
    builder: (_) => _FeedbackPinDialog(mode: mode),
  );
}

class _FeedbackPinDialog extends StatefulWidget {
  const _FeedbackPinDialog({required this.mode});

  final FeedbackPinMode mode;

  @override
  State<_FeedbackPinDialog> createState() => _FeedbackPinDialogState();
}

class _FeedbackPinDialogState extends State<_FeedbackPinDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  FeedbackPinMode get _mode => widget.mode;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  bool get _valid => isFeedbackPinFormValid(_mode, current: _current.text, next: _next.text, repeat: _repeat.text);

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final account = Get.find<FeedbackAccountController>();
    try {
      switch (_mode) {
        case FeedbackPinMode.unlock:
          await account.unlock(_current.text);
        case FeedbackPinMode.set:
          await account.setPin(_next.text);
        case FeedbackPinMode.change:
          await account.setPin(_next.text, current: _current.text);
        case FeedbackPinMode.remove:
          await account.removePin(_current.text);
      }
    } catch (e) {
      if (!mounted) return;
      final reason = e is FeedbackCallError ? e.reason : null;
      setState(() {
        _busy = false;
        _error = _mode == FeedbackPinMode.set && reason == 'pin_required'
            ? 'You already have a PIN'
            : feedbackReasonText(reason);
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    if (_mode != FeedbackPinMode.unlock) {
      BotToast.showText(text: _mode == FeedbackPinMode.remove ? 'PIN removed' : 'PIN saved');
    }
  }

  Widget _field(TextEditingController controller, String label, {String? helper}) {
    return TextField(
      controller: controller,
      enabled: !_busy,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
      decoration: InputDecoration(labelText: label, helperText: helper, counterText: ''),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (title, line) = switch (_mode) {
      FeedbackPinMode.unlock => ('Unlock moderation', null),
      FeedbackPinMode.set => ('Set PIN', 'You will need it to sign in on the web'),
      FeedbackPinMode.change => ('Change PIN', 'Signs you out on the web'),
      FeedbackPinMode.remove => ('Remove PIN', 'Your API key alone will sign you in on the web'),
    };
    final asksCurrent = _mode != FeedbackPinMode.set;
    final asksNext = _mode == FeedbackPinMode.set || _mode == FeedbackPinMode.change;
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (line != null) Text(line, style: const TextStyle(fontSize: 13)),
            if (asksCurrent) _field(_current, _mode == FeedbackPinMode.unlock ? 'PIN' : 'Current PIN'),
            if (asksNext) ...[_field(_next, 'New PIN', helper: '6 to 12 digits'), _field(_repeat, 'Repeat new PIN')],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.orange, fontSize: 13)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: _valid && !_busy ? _submit : null,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(switch (_mode) {
                  FeedbackPinMode.unlock => 'Unlock',
                  FeedbackPinMode.set || FeedbackPinMode.change => 'Save',
                  FeedbackPinMode.remove => 'Remove',
                }),
        ),
      ],
    );
  }
}
