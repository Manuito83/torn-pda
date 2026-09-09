// Dart imports:
import 'dart:async';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/material.dart';

/// Recovery of a tab being rebuilt after a renderer death (Android): keeps the last frame
/// on screen, retries the main frame and reports both ends to Crashlytics
///
/// The placeholder and the recovery have separate lives. Android reports a connection or DNS
/// failure well after the frame is stale, so the cover goes away early while the retries stay armed
class WebviewRecovery {
  // Waits before each retry
  static const List<int> _retryDelaysSeconds = [2, 5, 10];
  static const Duration _placeholderTimeout = Duration(seconds: 8);
  static const Duration _loadStopGrace = Duration(seconds: 2);
  static const Duration _totalTimeout = Duration(seconds: 120);

  final String reason;

  final String Function() urlToReload;
  final int Function() tabCount;

  final void Function(String url) onReload;

  final VoidCallback onChanged;
  final void Function(String message) onLog;

  Uint8List? _snapshot;
  final bool _hadSnapshot;
  final DateTime _startedAt = DateTime.now();
  bool _active = true;
  bool _covering = true;
  bool _retrying = false;
  bool _errorPending = false;
  bool _failed = false;
  int _retries = 0;
  String? _lastResultLogged;
  Timer? _placeholderTimer;
  Timer? _loadStopTimer;
  Timer? _retryTimer;
  Timer? _totalTimer;

  WebviewRecovery({
    required this.reason,
    required this.urlToReload,
    required this.tabCount,
    required this.onReload,
    required this.onChanged,
    required this.onLog,
    Uint8List? snapshot,
  }) : _snapshot = snapshot,
       _hadSnapshot = snapshot != null {
    _placeholderTimer = Timer(_placeholderTimeout, _hidePlaceholder);
    _totalTimer = Timer(_totalTimeout, _onTotalTimeout);
    onLog("PDA tab rebuild start: reason=$reason snapshot=$_hadSnapshot tabs=${tabCount()}");
  }

  bool get active => _active;

  bool get failed => _failed;

  /// The old frame is still covering the page, so touches must not reach it
  bool get covering => _active && _covering;

  /// Once the cover is gone only the bar is left, and only while there is something to say
  bool get visible => _active && (_covering || _retrying);

  /// The document on screen is an error page
  bool get waitingRetry => _failed || _errorPending || (_retryTimer?.isActive ?? false);
  Uint8List? get snapshot => _snapshot;
  int get retryNumber => _retries;
  int get retryTotal => _retryDelaysSeconds.length;

  /// A load started, so any scheduled retry is stale
  void onLoadStart() {
    if (!_active) return;
    _retryTimer?.cancel();
    _loadStopTimer?.cancel();
    _errorPending = false;
    if (_failed) {
      _failed = false;
      onChanged();
    }
  }

  /// Start of onLoadStop: its remaining work can throw, so [onLoadStopEnd] may never arrive
  void onLoadStopBegin() {
    if (!_active || _failed || _errorPending) return;
    if (_retryTimer?.isActive ?? false) return;
    _loadStopTimer?.cancel();
    _loadStopTimer = Timer(_loadStopGrace, () => _close(result: "ok", detail: "loadstop_fallback"));
  }

  /// End of onLoadStop: the page is really there, the placeholder can go
  void onLoadStopEnd() {
    if (!_active || _failed || _errorPending) return;
    if (_retryTimer?.isActive ?? false) return;
    _close(result: "ok");
  }

  /// Main frame error: schedule the next retry, or give up and wait for a tap
  void onLoadFailure(String detail) {
    if (!_active || _failed) return;
    _loadStopTimer?.cancel();
    _retryTimer?.cancel();
    _errorPending = true;
    _retrying = true;

    if (_retries >= _retryDelaysSeconds.length) {
      _close(result: "failed", detail: detail);
      return;
    }

    _retryTimer = Timer(Duration(seconds: _retryDelaysSeconds[_retries]), _startAttempt);
    _retries++;
    onChanged();
  }

  /// Tap on the failed bar: retry now instead of waiting
  void retryFromUser() {
    if (!_active) return;
    _retryTimer?.cancel();
    _startAttempt();
  }

  void dismissByUser() {
    if (!_active) return;
    _close(result: "dismissed");
  }

  void dispose() {
    _placeholderTimer?.cancel();
    _loadStopTimer?.cancel();
    _retryTimer?.cancel();
    _totalTimer?.cancel();
    _releaseSnapshot();
    _active = false;
  }

  void _hidePlaceholder() {
    if (!_active || !_covering) return;
    _covering = false;
    _releaseSnapshot();
    onChanged();
  }

  void _onTotalTimeout() {
    if (_failed) {
      _end();
      return;
    }
    _close(result: "timeout", detail: "total");
  }

  void _releaseSnapshot() {
    final Uint8List? bytes = _snapshot;
    _snapshot = null;
    if (bytes != null) MemoryImage(bytes).evict();
  }

  void _startAttempt() {
    if (!_active) return;
    final String target = urlToReload();
    if (target.isEmpty) {
      _close(result: "failed", detail: "no_url");
      return;
    }

    _failed = false;
    onChanged();
    onReload(target);
  }

  /// A failed close keeps the recovery alive (the tap can still fix it)
  void _close({required String result, String detail = ""}) {
    if (!_active) return;
    _placeholderTimer?.cancel();
    _loadStopTimer?.cancel();
    _retryTimer?.cancel();

    // Failing and then recovering must log twice, retrying three times must not
    if (_lastResultLogged != result) {
      _lastResultLogged = result;
      onLog(
        "PDA tab rebuild end: reason=$reason result=$result "
        "ms=${DateTime.now().difference(_startedAt).inMilliseconds} retries=$_retries "
        "snapshot=$_hadSnapshot tabs=${tabCount()} detail=$detail",
      );
    }

    if (result == "failed") {
      _failed = true;
      _covering = false;
      _releaseSnapshot();
      onChanged();
      return;
    }

    _end();
  }

  void _end() {
    _totalTimer?.cancel();
    _covering = false;
    _releaseSnapshot();
    _active = false;
    onChanged();
  }
}

class WebviewRecoveryOverlay extends StatelessWidget {
  final WebviewRecovery recovery;

  /// Used when there is no snapshot, so the tab never shows as a blank page
  final Color background;

  const WebviewRecoveryOverlay({required this.recovery, required this.background, super.key});

  @override
  Widget build(BuildContext context) {
    final Widget bar = Align(alignment: Alignment.topCenter, child: _statusBar());

    if (!recovery.covering) return bar;

    final Uint8List? snapshot = recovery.snapshot;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (snapshot != null)
            Image.memory(
              snapshot,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => ColoredBox(color: background),
            )
          else
            ColoredBox(color: background),
          // Dims the old frame, so it does not seem to be a live page
          if (snapshot != null) ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
          bar,
        ],
      ),
    );
  }

  Widget _statusBar() {
    final bool failed = recovery.failed;

    return Container(
      width: double.infinity,
      color: failed ? Colors.red[900]!.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.72),
      padding: const EdgeInsets.only(left: 14, right: 4, top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: failed ? recovery.retryFromUser : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (failed)
                    const Icon(Icons.refresh, size: 15, color: Colors.white)
                  else
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _message,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: recovery.dismissByUser,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String get _message {
    if (recovery.failed) return "Tab could not be reloaded. Tap to retry";
    if (recovery.retryNumber > 0) return "Reloading tab (retry ${recovery.retryNumber} of ${recovery.retryTotal})";
    return "Reloading tab";
  }
}
