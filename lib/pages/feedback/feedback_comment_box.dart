import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_input.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

class FeedbackCommentBox extends StatefulWidget {
  const FeedbackCommentBox({super.key, required this.onSend, this.blockedReason});

  final Future<void> Function(String text) onSend;
  final String? blockedReason;

  @override
  State<FeedbackCommentBox> createState() => _FeedbackCommentBoxState();
}

class _FeedbackCommentBoxState extends State<FeedbackCommentBox> {
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSend(_text.text.trim());
      _text.clear();
    } catch (e) {
      _error = e is FeedbackCallError ? e.text : feedbackReasonText(null);
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final blocked = widget.blockedReason;
    if (blocked != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(feedbackReasonText(blocked), style: const TextStyle(color: Colors.orange, fontSize: 13)),
      );
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_error!, style: const TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    enabled: !_sending,
                    maxLength: feedbackCommentMax,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(hintText: 'Comment', counterText: ''),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: isValidFeedbackComment(_text.text) ? _send : null,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
