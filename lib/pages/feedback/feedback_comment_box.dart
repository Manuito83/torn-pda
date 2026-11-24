import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_input.dart';
import 'package:torn_pda/pages/feedback/feedback_attachment_widgets.dart';
import 'package:torn_pda/providers/feedback_upload_queue.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

class FeedbackCommentBox extends StatefulWidget {
  const FeedbackCommentBox({
    super.key,
    required this.feedbackId,
    required this.onCreate,
    required this.onDone,
    this.blockedReason,
  });

  final String feedbackId;

  final Future<String> Function(String text) onCreate;

  final Future<void> Function() onDone;
  final String? blockedReason;

  @override
  State<FeedbackCommentBox> createState() => _FeedbackCommentBoxState();
}

class _FeedbackCommentBoxState extends State<FeedbackCommentBox> {
  final _text = TextEditingController();
  final _queue = FeedbackUploadQueue();
  bool _sending = false;
  String? _error;

  String? _commentId;

  @override
  void initState() {
    super.initState();
    _queue.addListener(_onQueueChange);
  }

  @override
  void dispose() {
    _queue.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onQueueChange() {
    if (_commentId != null && !_queue.hasPending && !_queue.uploading) {
      _commentId = null;
      _queue.clear();
      if (mounted) setState(() => _error = null);
    }
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final created = _commentId ??= await widget.onCreate(_text.text.trim());
      _text.clear();
      final failed = await _queue.uploadAll(widget.feedbackId, commentId: created);
      if (failed == 0) {
        _commentId = null;
        _queue.clear();
      } else {
        _error = failed == 1 ? '1 file failed' : '$failed files failed';
      }
      await widget.onDone();
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
    final retrying = _commentId != null;
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FeedbackPickList(queue: _queue, enabled: !_sending && !retrying),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    enabled: !_sending && !retrying,
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
                        icon: Icon(retrying ? Icons.refresh : Icons.send),
                        tooltip: retrying ? 'Retry' : 'Send',
                        onPressed: retrying || isValidFeedbackComment(_text.text) ? _send : null,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
