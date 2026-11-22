import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_input.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

Future<FeedbackItem?> showFeedbackStatusSheet(BuildContext context, FeedbackItem item) {
  return _showSheet(context, _StatusSheet(item: item));
}

Future<FeedbackItem?> showFeedbackTagsSheet(BuildContext context, FeedbackItem item, List<FeedbackTag> tags) {
  return _showSheet(context, _TagsSheet(item: item, tags: tags));
}

Future<FeedbackItem?> _showSheet(BuildContext context, Widget sheet) {
  return showModalBottomSheet<FeedbackItem>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(child: sheet),
    ),
  );
}

String _failure(Object error) {
  if (error is FeedbackCallError && error.reason == 'mod_locked') Get.find<FeedbackAccountController>().markLocked();
  return error is FeedbackCallError ? error.text : feedbackReasonText(null);
}

class _StatusSheet extends StatefulWidget {
  const _StatusSheet({required this.item});

  final FeedbackItem item;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  late FeedbackStatus _status = widget.item.status;
  late final _response = TextEditingController(text: widget.item.response?.text ?? '');
  late final _duplicate = TextEditingController(text: widget.item.duplicateOf ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _response.dispose();
    _duplicate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final item = widget.item;
    final before = item.response?.text ?? '';
    final response = _response.text.trim();
    final request = feedbackStatusRequest(
      feedbackId: item.id,
      status: _status,
      responseText: response == before ? null : response,
      duplicateInput: _duplicate.text,
    );
    if (request == null) return setState(() => _error = feedbackReasonText('invalid-argument'));
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await moderateFeedback('setStatus', request);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _failure(e);
        });
      }
      return;
    }
    if (!mounted) return;
    final name = Get.find<FeedbackAccountController>().account.playerName ?? '';
    final changed = request.containsKey('responseText');
    Navigator.pop(
      context,
      item.copyWith(
        status: _status,
        clearResponse: changed && response.isEmpty,
        response: changed && response.isNotEmpty
            ? FeedbackResponse(text: response, authorName: name, at: DateTime.now())
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: [
            for (final status in FeedbackStatus.values)
              ChoiceChip(
                label: Text(status.label),
                selected: _status == status,
                onSelected: _busy ? null : (_) => setState(() => _status = status),
              ),
          ],
        ),
        if (_status == FeedbackStatus.duplicate)
          TextField(
            controller: _duplicate,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Original id or link'),
          ),
        TextField(
          controller: _response,
          enabled: !_busy,
          maxLength: feedbackResponseMax,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Response'),
        ),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.orange, fontSize: 13)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _TagsSheet extends StatefulWidget {
  const _TagsSheet({required this.item, required this.tags});

  final FeedbackItem item;
  final List<FeedbackTag> tags;

  @override
  State<_TagsSheet> createState() => _TagsSheetState();
}

class _TagsSheetState extends State<_TagsSheet> {
  late final Set<String> _selected = {
    for (final tag in widget.tags)
      if (widget.item.tags.contains(tag.id)) tag.id,
  };
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ids = _selected.toList();
    try {
      await moderateFeedback('setTags', {'feedbackId': widget.item.id, 'tags': ids});
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _failure(e);
        });
      }
      return;
    }
    if (mounted) Navigator.pop(context, widget.item.copyWith(tags: ids));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: [
            for (final tag in widget.tags)
              FilterChip(
                label: Text(tag.name),
                selectedColor: Color(tag.color).withValues(alpha: 0.35),
                selected: _selected.contains(tag.id),
                onSelected: _busy
                    ? null
                    : (on) => setState(() => on ? _selected.add(tag.id) : _selected.remove(tag.id)),
              ),
          ],
        ),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.orange, fontSize: 13)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}
