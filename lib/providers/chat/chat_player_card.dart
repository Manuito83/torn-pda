import 'dart:async';

import 'package:get/get.dart';
import 'package:torn_pda/models/chat/chat_player_card.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/user_controller.dart';

class ChatPlayerCards {
  static const Duration _ttl = Duration(minutes: 3);
  static const Duration _failTtl = Duration(seconds: 30);

  static const String _base = 'profile,bazaar,bounties';
  static bool _discordRejected = false;

  static Future<Map<String, dynamic>?> Function(int id) fetch = _fetch;

  static final Map<int, (DateTime, Map<String, dynamic>?, ChatPlayerCard?)> _cache = {};
  static final Map<int, Future<Map<String, dynamic>?>> _loading = {};
  static int _generation = 0;

  static ChatPlayerCard? peek(int id) {
    final hit = _cache[id];
    return hit != null && DateTime.now().difference(hit.$1) < _ttl ? hit.$3 : null;
  }

  static Map<String, dynamic>? peekJson(int id) {
    final hit = _cache[id];
    return hit != null && DateTime.now().difference(hit.$1) < _ttl ? hit.$2 : null;
  }

  static Future<ChatPlayerCard?> load(int id, {Duration maxAge = _ttl}) async {
    await json(id, maxAge: maxAge);
    return _cache[id]?.$3;
  }

  static Future<Map<String, dynamic>?> json(int id, {Duration maxAge = _ttl, bool retry = false}) {
    final hit = _cache[id];
    if (hit != null &&
        !(retry && hit.$2 == null && DateTime.now().difference(hit.$1) > const Duration(seconds: 5)) &&
        DateTime.now().difference(hit.$1) < (hit.$2 == null ? _failTtl : maxAge)) {
      return Future.value(hit.$2);
    }
    final generation = _generation;
    return _loading[id] ??= _run(id, generation).whenComplete(() {
      if (generation == _generation) _loading.remove(id);
    });
  }

  static Future<Map<String, dynamic>?> _run(int id, int generation) async {
    final asked = DateTime.now();
    Map<String, dynamic>? json;
    try {
      json = await fetch(id);
    } catch (_) {}
    if (generation == _generation) _cache[id] = (asked, json, json == null ? null : ChatPlayerCard.fromJson(json));
    return json;
  }

  static Future<Map<String, dynamic>?> _fetch(int id) async {
    Future<dynamic> ask(String selections) => Get.find<ApiCallerController>().enqueueApiCall<dynamic>(
      apiSelection_v2: ApiSelection_v2.otherUserProfile,
      apiCall: (client, apiKey) => client.userGet(id: '$id', selections: selections),
    );
    final generation = _generation;
    var response = await ask(_discordRejected ? _base : '$_base,discord');
    if (response is ApiError && response.errorId == 4 && !_discordRejected) {
      response = await ask(_base);
      if (generation == _generation) _discordRejected = response is Map<String, dynamic>;
    }
    if (response is! Map<String, dynamic>) return null;
    final mine = Get.isRegistered<UserController>() && Get.find<UserController>().playerId == id;
    // Torn hides other players' bazaar items
    return mine ? response : ({...response}..remove('bazaar'));
  }

  /// Nothing cached from the old account
  static void forget() {
    _generation++;
    _cache.clear();
    _loading.clear();
    _discordRejected = false;
  }

  static void resetForTests() {
    forget();
    fetch = _fetch;
  }
}
