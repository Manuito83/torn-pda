import 'dart:math';

import 'package:get/get.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/providers/feedback_pager.dart';
import 'package:torn_pda/utils/feedback_firestore.dart';
import 'package:torn_pda/utils/feedback_functions.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

const _staleAfter = Duration(minutes: 2);

class FeedbackController extends GetxController {
  FeedbackController({
    Future<FeedbackPage<FeedbackItem>> Function(FeedbackFilter filter, Object? cursor)? fetchPage,
    Future<FeedbackPage<FeedbackItem>> Function(Object? cursor)? fetchMine,
    Future<List<FeedbackTag>> Function()? fetchTags,
    Future<String> Function()? loadFilter,
    Future<void> Function(String value)? saveFilter,
    void Function(List<String> ids)? onLoaded,
    Future<int?> Function(String id, void Function(int delta) onDelta)? toggleVote,
  }) : _toggleVote = toggleVote ?? _toggleAccountVote,
       _fetchPage = fetchPage ?? fetchFeedbackPage,
       _fetchMine = fetchMine ?? fetchMineFeedback,
       _fetchTags = fetchTags ?? fetchFeedbackTags,
       _loadFilter = loadFilter ?? Prefs().getFeedbackFilter,
       _saveFilter = saveFilter ?? Prefs().setFeedbackFilter,
       _onLoaded = onLoaded ?? _askAccount;

  final Future<FeedbackPage<FeedbackItem>> Function(FeedbackFilter filter, Object? cursor) _fetchPage;
  final Future<FeedbackPage<FeedbackItem>> Function(Object? cursor) _fetchMine;
  final Future<List<FeedbackTag>> Function() _fetchTags;
  final Future<String> Function() _loadFilter;
  final Future<void> Function(String value) _saveFilter;
  final void Function(List<String> ids) _onLoaded;
  final Future<int?> Function(String id, void Function(int delta) onDelta) _toggleVote;

  FeedbackFilter _filter = const FeedbackFilter();
  late FeedbackPager<FeedbackItem> _pager = _newPager();
  List<FeedbackTag> _tags = [];
  bool _tagsLoading = false;
  bool _tagsLoaded = false;
  bool _restored = false;
  String? _pendingOpenId;

  FeedbackFilter get filter => _filter;
  FeedbackPager<FeedbackItem> get pager => _pager;
  List<FeedbackTag> get tags => _tags;

  static void _askAccount(List<String> ids) => Get.find<FeedbackAccountController>().load(ids);

  static Future<int?> _toggleAccountVote(String id, void Function(int delta) onDelta) {
    return Get.find<FeedbackAccountController>().toggleVote(id, onDelta: onDelta);
  }

  FeedbackPager<FeedbackItem> _newPager() {
    final filter = _filter;
    final fetch = filter.tab == FeedbackTab.mine ? _fetchMine : (Object? cursor) => _fetchPage(filter, cursor);
    return FeedbackPager<FeedbackItem>(fetch)..addListener(_onPagerChange);
  }

  void _onPagerChange() {
    update();
    if (_pager.loading || _pager.failed) return;
    _onLoaded([for (final item in _pager.items) item.id]);
    _loadTags();
  }

  FeedbackTag? tagFor(String id) => _tags.where((tag) => tag.id == id).firstOrNull;

  // Called when the section shows
  Future<void> open() async {
    if (!_restored) {
      _restored = true;
      await _restoreFilter();
    }
    final loadedAt = _pager.loadedAt;
    final stale = loadedAt == null || DateTime.now().difference(loadedAt) > _staleAfter;
    if (!_pager.loading && stale) _pager.reload();
    _loadTags();
  }

  Future<void> _restoreFilter() async {
    try {
      final saved = FeedbackFilter.decode(await _loadFilter());
      if (saved.encode() == _filter.encode()) return;
      _filter = saved;
      _pager.dispose();
      _pager = _newPager();
      update();
    } catch (_) {
      // Defaults stay
    }
  }

  void setFilter(FeedbackFilter value) {
    _filter = value;
    _pager.dispose();
    _pager = _newPager();
    _pager.reload();
    update();
    _saveFilter(value.encode()).catchError((_) {});
  }

  void reload() => _pager.reload();

  void patchItem(String id, FeedbackItem Function(FeedbackItem item) change) {
    _pager.patch((item) => item.id == id, change);
  }

  void removeItem(String id) => _pager.remove((item) => item.id == id);

  // New count, null if ignored
  Future<int?> vote(String id, {void Function(int delta)? onDelta}) async {
    final count = await _toggleVote(id, (delta) {
      patchItem(id, (item) => item.copyWith(votesCount: max(0, item.votesCount + delta)));
      onDelta?.call(delta);
    });
    if (count != null) patchItem(id, (item) => item.copyWith(votesCount: count));
    return count;
  }

  // Opened by the list page
  void requestOpen(String id) {
    _pendingOpenId = id;
    update();
  }

  String? takePendingOpen() {
    final id = _pendingOpenId;
    _pendingOpenId = null;
    return id;
  }

  bool get hasPendingOpen => _pendingOpenId != null;

  Future<void> _loadTags() async {
    if (_tagsLoading || _tagsLoaded) return;
    _tagsLoading = true;
    try {
      _tags = await _fetchTags();
      _tagsLoaded = true;
      update();
    } catch (_) {
      // The tag filter just stays hidden
    }
    _tagsLoading = false;
  }

  @override
  void onClose() {
    _pager.dispose();
    super.onClose();
  }
}
