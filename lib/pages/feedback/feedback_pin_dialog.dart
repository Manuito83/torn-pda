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

  String get _title => switch (_mode) {
    FeedbackPinMode.unlock => 'Unlock moderation',
    FeedbackPinMode.change => 'PIN',
    FeedbackPinMode.remove => 'Remove PIN',
  };

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
        case FeedbackPinMode.change:
          await setFeedbackPin(_next.text, current: _current.text.isEmpty ? null : _current.text);
          account.markLocked();
        case FeedbackPinMode.remove:
          await removeFeedbackPin(_current.text);
          account.markLocked();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is FeedbackCallError ? e.text : feedbackReasonText(null);
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    if (_mode != FeedbackPinMode.unlock) {
      BotToast.showText(text: _mode == FeedbackPinMode.change ? 'PIN saved' : 'PIN removed');
    }
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      enabled: !_busy,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
      decoration: InputDecoration(labelText: label, counterText: ''),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_current, _mode == FeedbackPinMode.unlock ? 'PIN' : 'Current PIN'),
            if (_mode == FeedbackPinMode.change) ...[_field(_next, 'New PIN'), _field(_repeat, 'Repeat new PIN')],
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
                  FeedbackPinMode.change => 'Save',
                  FeedbackPinMode.remove => 'Remove',
                }),
        ),
      ],
    );
  }
}
