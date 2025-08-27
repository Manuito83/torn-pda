import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityHandler {
  bool connectivityCheckEnabled = false;

  static final ConnectivityHandler instance = ConnectivityHandler._();
  ConnectivityHandler._();

  final ValueNotifier<bool> hasConnection = ValueNotifier(false);
  final Completer<void> _initializationCompleter = Completer<void>();
  Future<void> get initializationFuture => _initializationCompleter.future;

  StreamSubscription<InternetStatus>? _internetSubscription;

  Future<void> initialize() async {
    if (_initializationCompleter.isCompleted) return;

    try {
      _internetSubscription = InternetConnection().onStatusChange.listen((InternetStatus status) {
        final isConnected = status == InternetStatus.connected;
        if (hasConnection.value != isConnected) {
          log(name: "CONNECTIVITY", 'Internet status changed to: $isConnected');
          hasConnection.value = isConnected;
        }
      });

      hasConnection.value = await InternetConnection().hasInternetAccess;

      log(
        name: "CONNECTIVITY",
        'Initial internet status: ${hasConnection.value ? "connected" : "disconnected"}',
      );
    } catch (e) {
      log(name: "CONNECTIVITY", 'Error initializing connectivity: $e');
    } finally {
      _initializationCompleter.complete();
    }
  }

  Future<void> waitForInternetConnection({Duration? timeout}) async {
    if (hasConnection.value) {
      return;
    }

    log(name: "CONNECTIVITY", 'No internet. Waiting for it to be established...');
    final completer = Completer<void>();

    void listener() {
      if (hasConnection.value && !completer.isCompleted) {
        log(name: "CONNECTIVITY", 'Internet connection established!');
        completer.complete();
      }
    }

    try {
      hasConnection.addListener(listener);

      if (timeout != null) {
        await completer.future.timeout(timeout);
      } else {
        await completer.future;
      }
    } on TimeoutException {
      log(name: "CONNECTIVITY", 'Timeout waiting for internet after ${timeout?.inSeconds ?? 0} seconds.');
    } finally {
      hasConnection.removeListener(listener);
    }
  }

  void dispose() {
    _internetSubscription?.cancel();
  }
}
