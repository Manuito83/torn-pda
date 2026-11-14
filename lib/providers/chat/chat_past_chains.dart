import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/chat/chat_chain_report.dart';
import 'package:torn_pda/models/chat/chat_past_chains.dart';

class ChatPastChains extends ChangeNotifier {
  ChatPastChains({required this.fetchList, required this.fetchReport});

  final Future<Map<String, dynamic>?> Function(Map<String, String> query) fetchList;
  final Future<Map<String, dynamic>?> Function(int id) fetchReport;

  List<ChatPastChain> chains = const [];
  bool loading = false;
  bool loadingMore = false;

  /// Null if the last call worked
  String? problem;
  String? problemDetail;

  Map<String, String>? _older;
  final Map<int, ChatChainReport> _reports = {};
  final Map<int, Future<ChatChainReport?>> _reportCalls = {};

  bool get hasMore => _older != null;

  void forget() {
    chains = const [];
    loading = false;
    loadingMore = false;
    problem = null;
    problemDetail = null;
    _older = null;
    _reports.clear();
    _reportCalls.clear();
    notifyListeners();
  }

  /// A finished chain never changes
  ChatChainReport? cachedReport(int id) => _reports[id];

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    final page = await _page({'limit': '$chatPastChainsPageSize', 'sort': 'desc'});
    loading = false;
    if (page != null) {
      chains = page.chains;
      _older = page.older;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    final query = _older;
    if (query == null || loading || loadingMore) return;
    loadingMore = true;
    notifyListeners();
    final page = await _page(query);
    loadingMore = false;
    if (page != null) {
      final merged = chatMergePastChains(chains, page.chains);
      // Nothing new means the end
      _older = merged.length == chains.length ? null : page.older;
      chains = merged;
    }
    notifyListeners();
  }

  Future<ChatPastChainsPage?> _page(Map<String, String> query) async {
    final json = await fetchList(query);
    final page = chatParsePastChains(json);
    final error = json?['error'];
    if (page != null) {
      problem = null;
      problemDetail = null;
    } else {
      problem = "Couldn't load past chains";
      if (error is Map) {
        final code = error['code'] is int ? error['code'] as int : null;
        problemDetail = chatReportReason(code, '${error['error'] ?? ''}');
      } else {
        problemDetail = 'Check your connection and try again';
      }
    }
    return page;
  }

  /// Null if unreadable, not cached
  Future<ChatChainReport?> report(int id) {
    final known = _reports[id];
    if (known != null) return Future.value(known);
    return _reportCalls[id] ??= _loadReport(id);
  }

  Future<ChatChainReport?> _loadReport(int id) async {
    try {
      final report = ChatChainReport.parse((await fetchReport(id))?['chainreport']);
      if (report != null) _reports[id] = report;
      return report;
    } finally {
      _reportCalls.remove(id);
    }
  }
}
