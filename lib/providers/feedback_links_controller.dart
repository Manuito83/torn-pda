import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/feedback/feedback_attachment.dart';
import 'package:torn_pda/utils/feedback_attachment_functions.dart';

const _idsPerCall = 50;

const _linkMargin = Duration(minutes: 1);

class FeedbackLinksController extends ChangeNotifier {
  FeedbackLinksController(this.feedbackId, {Future<FeedbackLinks> Function(String id, List<String> commentIds)? fetch})
    : _fetch = fetch ?? fetchFeedbackLinks;

  final String feedbackId;
  final Future<FeedbackLinks> Function(String id, List<String> commentIds) _fetch;

  FeedbackLinks _links = const FeedbackLinks();
  bool _loading = false;
  bool _failed = false;
  bool _disposed = false;

  bool get loading => _loading;
  bool get failed => _failed;

  List<FeedbackAttachment> itemLinks(List<FeedbackAttachment> own) => _links.linked(own, null);

  List<FeedbackAttachment> commentLinks(String commentId, List<FeedbackAttachment> own) {
    return _links.linked(own, commentId);
  }

  Future<void> ensure({
    required List<FeedbackAttachment> item,
    required Map<String, List<FeedbackAttachment>> comments,
    bool retry = false,
  }) async {
    if (_failed && !retry) return;
    final now = DateTime.now().add(_linkMargin);
    bool stale(List<FeedbackAttachment> own, List<FeedbackAttachment> linked) {
      return own.any((attachment) => !linked.any((l) => l.id == attachment.id && l.hasLinkAt(now)));
    }

    final wanted = [
      for (final entry in comments.entries)
        if (stale(entry.value, _links.comments[entry.key] ?? const [])) entry.key,
    ];
    final itemStale = stale(item, _links.item);
    if (_loading || (!itemStale && wanted.isEmpty)) return;
    _loading = true;
    _failed = false;
    _notify();
    try {
      final merged = <String, List<FeedbackAttachment>>{..._links.comments};
      var itemLinks = _links.item;
      for (var from = 0; from == 0 || from < wanted.length; from += _idsPerCall) {
        final chunk = wanted.skip(from).take(_idsPerCall).toList();
        final fresh = await _fetch(feedbackId, chunk);
        itemLinks = fresh.item;
        merged.addAll(fresh.comments);
      }
      _links = FeedbackLinks(item: itemLinks, comments: merged);
    } catch (_) {
      _failed = true;
    }
    _loading = false;
    _notify();
  }

  // Valid link for one file
  Future<String?> freshUrl(
    FeedbackAttachment attachment, {
    String? commentId,
    required List<FeedbackAttachment> item,
    required Map<String, List<FeedbackAttachment>> comments,
  }) async {
    FeedbackAttachment? found() {
      final own = commentId == null ? item : comments[commentId] ?? const <FeedbackAttachment>[];
      final linked = commentId == null ? itemLinks(own) : commentLinks(commentId, own);
      return linked.where((a) => a.id == attachment.id).firstOrNull;
    }

    if (found()?.hasLinkAt(DateTime.now().add(_linkMargin)) != true) {
      await ensure(item: item, comments: comments, retry: true);
    }
    return found()?.url;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
