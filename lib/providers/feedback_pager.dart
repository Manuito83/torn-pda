import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

typedef FeedbackPageFetch<T> = Future<FeedbackPage<T>> Function(Object? cursor);

class FeedbackPager<T> extends ChangeNotifier {
  FeedbackPager(this._fetch, {this.onModLocked});

  final FeedbackPageFetch<T> _fetch;
  final VoidCallback? onModLocked;

  List<T> _items = [];
  Object? _cursor;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _moreFailed = false;
  String? _errorCode;
  bool _failed = false;
  bool _disposed = false;
  int _run = 0;
  DateTime? _loadedAt;

  List<T> get items => _items;
  bool get hasMore => _hasMore;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get moreFailed => _moreFailed;
  bool get failed => _failed;
  String get errorText => feedbackErrorText(_errorCode);
  DateTime? get loadedAt => _loadedAt;

  Future<void> reload() async {
    final run = ++_run;
    _loading = true;
    _loadingMore = false;
    _moreFailed = false;
    _failed = false;
    _notify();
    try {
      final page = await _fetch(null);
      if (run != _run) return;
      _items = page.items;
      _cursor = page.cursor;
      _hasMore = page.hasMore;
      _loadedAt = DateTime.now();
    } catch (e) {
      if (run != _run) return;
      _failed = true;
      _errorCode = _failureCode(e);
    }
    _loading = false;
    _notify();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loading || _loadingMore) return;
    final run = _run;
    _loadingMore = true;
    _moreFailed = false;
    _notify();
    try {
      final page = await _fetch(_cursor);
      if (run != _run) return;
      _items = [..._items, ...page.items];
      _cursor = page.cursor;
      _hasMore = page.hasMore;
    } catch (e) {
      if (run != _run) return;
      _moreFailed = true;
      _errorCode = _failureCode(e);
    }
    _loadingMore = false;
    _notify();
  }

  void patch(bool Function(T item) matches, T Function(T item) change) {
    _items = [for (final item in _items) matches(item) ? change(item) : item];
    _notify();
  }

  void remove(bool Function(T item) matches) {
    _items = _items.where((item) => !matches(item)).toList();
    _notify();
  }

  String? _failureCode(Object error) {
    if (error is TimeoutException) return 'timeout';
    if (error is FeedbackCallError) {
      if (error.reason == 'mod_locked') onModLocked?.call();
      return error.reason;
    }
    return error is FirebaseException ? error.code : null;
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
