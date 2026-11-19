import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chat/chat_bazaar_sources.dart';
import 'package:torn_pda/models/chat/chat_source_brake.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';

const _source = 'torn_v1';

bool _never() => false;

Future<dynamic> _askTorn(int sellerId) {
  if (!Get.isRegistered<ApiCallerController>()) return Future.value(ApiError(errorId: 999));
  return Get.find<ApiCallerController>().enqueueApiCall(apiSelection: ApiSelection_v1.bazaar, prefix: '$sellerId');
}

void _tellCrashlytics(String source, String reason) {
  if (Platform.isWindows) return;
  FirebaseCrashlytics.instance.recordError(
    'Chat bazaar source $source braked: $reason (https://api.torn.com/user/<id>?selections=bazaar)',
    null,
  );
}

/// Bazaar state per seller, null if unknown
class ChatBazaarController extends GetxController {
  ChatBazaarController({
    this.fetch = _askTorn,
    this.report = _tellCrashlytics,
    this.now = DateTime.now,
    this.busy = _never,
    this.timeout = const Duration(seconds: 8),
  });

  static const Duration _life = Duration(minutes: 5);
  static const Duration _failLife = Duration(minutes: 2);
  static const int _maxEntries = 400;

  final Future<dynamic> Function(int sellerId) fetch;
  final void Function(String source, String reason) report;
  final DateTime Function() now;
  final bool Function() busy;
  final Duration timeout;

  final Map<int, (DateTime, ChatBazaarState?)> _known = {};
  final Map<int, Future<ChatBazaarState?>> _loading = {};
  ChatBrake _brake = const ChatBrake();
  int _generation = 0;

  Future<ChatBazaarState?> state(int sellerId) {
    final hit = _known[sellerId];
    if (hit != null && now().isBefore(hit.$1)) return Future.value(hit.$2);
    final generation = _generation;
    return _loading[sellerId] ??= _ask(sellerId, generation).whenComplete(() {
      if (generation == _generation) _loading.remove(sellerId);
    });
  }

  Future<ChatBazaarState?> _ask(int sellerId, int generation) async {
    if (_brake.blocks(now()) || busy()) return null;
    final failuresBefore = _brake.failures;
    ChatBazaarState? result;
    String? fault;
    try {
      final response = await fetch(sellerId).timeout(timeout);
      if (response is ApiError) {
        if (chatBazaarSourceFault(response.errorId)) {
          fault = switch (response.errorId) {
            100 => 'timeout',
            0 => 'no connection',
            _ => 'torn error ${response.errorId}',
          };
        }
      } else {
        final read = chatBazaarState(response);
        if (read == ChatBazaarState.unknown) {
          fault = 'unexpected reply';
        } else {
          result = read;
        }
      }
    } on TimeoutException {
      fault = 'timeout';
    } catch (e) {
      fault = 'exception ${e.runtimeType}';
    }
    if (generation != _generation) return result;

    if (result != null) {
      _brake = const ChatBrake();
    } else if (fault != null && _brake.failures == failuresBefore) {
      // Parallel failures count once
      _brake = _brake.failed(now());
      if (_brake.persistent) {
        try {
          report(_source, fault);
        } catch (_) {}
      }
    }
    _known[sellerId] = (now().add(result == null ? _failLife : _life), result);
    while (_known.length > _maxEntries) {
      _known.remove(_known.keys.first);
    }
    return result;
  }

  /// Drops the old account's data
  void forget() {
    _generation++;
    _known.clear();
    _loading.clear();
  }
}
