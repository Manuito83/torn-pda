// Dart imports:
import 'dart:async';
import 'dart:developer';

// Flutter imports:
import 'package:flutter/material.dart';

/// Drawer dialog queue to ensure dialogs are shown sequentially
/// without overlapping. There's a 500ms startup delay to allow proper
/// priority ordering during app initialization (i.e.: the app update dialog
/// has priority but will want to show after getting remote config, so wait for it here)
class DialogQueue {
  static final List<_DialogRequest> _pendingDialogs = [];
  static bool _isDialogActive = false;
  static Timer? _startupTimer;
  static bool _startupDelayActive = false;
  static VoidCallback? _onQueueEmptyCallback;

  /// Auth gate to wait for AuthRecoveryWidget to complete before showing dialogs
  /// This prevents dialogs from appearing over the auth loading/timeout screens
  ///
  /// The 15-second timeout is in case AuthRecoveryWidget fails to
  /// complete the gate. If the timeout fires while
  /// the user is reading the "Understood" timeout screen, dialogs may appear over it
  static Completer<void>? _authGate;

  static void setOnQueueEmptyCallback(VoidCallback? callback) {
    _onQueueEmptyCallback = callback;
  }

  /// Set the auth gate that dialogs will wait for before showing
  /// Call [completeAuthGate] when auth recovery is complete
  static void setAuthGate(Completer<void> gate) {
    _authGate = gate;
  }

  /// Complete the auth gate, allowing queued dialogs to start showing
  static void completeAuthGate() {
    if (_authGate != null && !_authGate!.isCompleted) {
      log("DialogQueue: Auth gate completed");
      _authGate!.complete();
    }
  }

  /// 500ms startup delay to allow dialogs to accumulate before processing
  static void startCollectingDialogs() {
    if (_startupDelayActive) return;
    _startupDelayActive = true;
    _startupTimer?.cancel();
    _startupTimer = Timer(const Duration(milliseconds: 500), () {
      _startupDelayActive = false;
      _processNext();
    });
  }

  /// Priority-based
  static void enqueue({
    required Future<bool> Function() dialogFunction,
    required String dialogName,
    required BuildContext context,
    int priority = 0,
  }) {
    log("DialogQueue: Enqueuing dialog '$dialogName' with priority $priority");

    final request = _DialogRequest(
      dialogFunction: dialogFunction,
      dialogName: dialogName,
      context: context,
      priority: priority,
    );

    // Priority (higher numbers first)
    int insertIndex = _pendingDialogs.length;
    for (int i = 0; i < _pendingDialogs.length; i++) {
      if (_pendingDialogs[i].priority < priority) {
        insertIndex = i;
        break;
      }
    }

    _pendingDialogs.insert(insertIndex, request);

    // Only process if startup delay is over and no dialog is active
    if (!_startupDelayActive) {
      _processNext();
    }
  }

  static Future<void> _processNext() async {
    if (_startupDelayActive || _isDialogActive) {
      return;
    }

    // Wait for auth gate if set (with 15s safety timeout)
    if (_authGate != null && !_authGate!.isCompleted) {
      log("DialogQueue: Waiting for auth gate...");
      try {
        await _authGate!.future.timeout(const Duration(seconds: 15));
      } on TimeoutException {
        log("DialogQueue: Auth gate timeout (15s), proceeding anyway");
      }
    }

    if (_pendingDialogs.isEmpty) {
      // Queue is empty, callback!
      if (_onQueueEmptyCallback != null) {
        log("DialogQueue: Queue is empty, executing onQueueEmpty callback");
        final callback = _onQueueEmptyCallback;
        _onQueueEmptyCallback = null;
        callback!();
      }
      return;
    }

    final request = _pendingDialogs.removeAt(0);

    // Check if context is still valid
    if (!request.context.mounted) {
      log("DialogQueue: Context for '${request.dialogName}' is no longer mounted, skipping");
      _processNext();
      return;
    }

    _isDialogActive = true;
    log("DialogQueue: Showing dialog '${request.dialogName}'");

    request.dialogFunction().then((wasShown) {
      log("DialogQueue: Dialog '${request.dialogName}' processed successfully");
      _isDialogActive = false;

      // Next dialog after a small delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _processNext();
      });
    }).catchError((error) {
      log("DialogQueue: Error in dialog '${request.dialogName}': $error");
      _isDialogActive = false;

      Future.delayed(const Duration(milliseconds: 100), () {
        _processNext();
      });
    });
  }
}

class _DialogRequest {
  final Future<bool> Function() dialogFunction;
  final String dialogName;
  final BuildContext context;
  final int priority;

  _DialogRequest({
    required this.dialogFunction,
    required this.dialogName,
    required this.context,
    required this.priority,
  });
}
