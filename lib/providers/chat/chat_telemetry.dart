import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:torn_pda/main.dart' show analytics;
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/utils/background_prefs.dart';

class ChatTelemetry {
  ChatTelemetry._();

  static const Set<String> _outcomes = {
    'connected',
    'no_core',
    'needs_browser',
    'two_factor',
    '401',
    'offline',
    'torn_down',
    'rooms_error',
  };
  static const Set<String> _replies = {
    'sent',
    'http_3xx',
    'http_4xx',
    'http_5xx',
    'timeout',
    'network',
    'key_risk',
    'account_changed',
    'disabled',
    'no_key',
    'error',
  };

  static Map<String, int>? _counts;
  static String? _mode;
  static DateTime _next = DateTime(0);
  static bool _connected = false;

  @visibleForTesting
  static void Function(String name, Map<String, Object> params)? debugSink;

  @visibleForTesting
  static void reset() {
    _counts = null;
    _mode = null;
    _next = DateTime(0);
    _connected = false;
  }

  /// Main isolate only
  static void event(String name, Map<String, Object> params) {
    if (debugSink != null) return debugSink!(name, params);
    try {
      analytics?.logEvent(name: name, parameters: params).catchError((_) {});
    } catch (_) {}
  }

  static String _known(Object? value, Set<String> known) => known.contains(value) ? value as String : 'other';

  static void health(Map data) {
    switch (data['fact']) {
      case 'connect':
        final outcome = _known(data['outcome'], _outcomes);
        if (outcome == 'connected' && _connected) return;
        if (outcome == 'connected') _connected = true;
        final ms = data['ms'] is int ? data['ms'] as int : 0;
        event('chat_connect', {
          'outcome': outcome,
          'ms_bucket': ms < 5000 ? '<5s' : (ms < 15000 ? '<15s' : (ms < 60000 ? '<60s' : '>60s')),
          'cold': data['cold'] == true ? 1 : 0,
        });
      case 'lost':
        event('chat_session_lost', {
          'reason': _known(data['reason'], _outcomes.difference({'connected', 'rooms_error'})),
          'autologin': _known(data['autologin'], const {'ok', 'failed', 'skipped'}),
        });
      case 'stuck':
        event('chat_stuck', {
          'kind': _known(data['kind'], const {'session_retries', 'recreate_limit'}),
        });
    }
  }

  static Future<void> _note(String entry) async {
    try {
      await BackgroundPrefs().addChatTelemetry(entry);
    } catch (_) {}
  }

  /// Any isolate
  static Future<void> push(String result) => _note('push|$result');

  static Future<void> reply(String result, {required bool main}) async {
    final path = Platform.isAndroid ? 'android_bg' : (main ? 'ios_main' : 'ios_headless');
    if (!main) return _note('reply|$path|$result');
    event('chat_reply', {'path': path, 'outcome': _known(result, _replies)});
    if (result == 'sent') await count('notif_reply');
  }

  static Future<Map<String, int>> _stored() async {
    if (_counts != null) return _counts!;
    final raw = await BackgroundPrefs().getChatCounts();
    final decoded = raw.isEmpty ? null : jsonDecode(raw);
    // Two early counts share the first load
    return _counts ??= decoded is Map
        ? {for (final e in decoded.entries) '${e.key}': e.value is int ? e.value as int : 0}
        : {};
  }

  /// Daily totals, main isolate only
  static Future<void> count(String key, [int by = 1]) async {
    try {
      final counts = await _stored();
      counts[key] = (counts[key] ?? 0) + by;
      await BackgroundPrefs().setChatCounts(jsonEncode(counts));
    } catch (_) {}
  }

  static String roomKind(String roomId) {
    if (ChatRoom.peerIdOf(roomId) != null) return 'dm';
    return const {'faction', 'company', 'global', 'trade'}.contains(roomId) ? roomId : 'other';
  }

  /// What background isolates left
  static Future<void> flush() async {
    final pushes = <String, int>{};
    try {
      for (final entry in await BackgroundPrefs().takeChatTelemetry()) {
        final parts = entry.split('|');
        final key = 'push_${parts.last}';
        if (parts.first == 'push' && parts.length == 2) pushes[key] = (pushes[key] ?? 0) + 1;
        if (parts.first != 'reply' || parts.length != 3) continue;
        event('chat_reply', {'path': parts[1], 'outcome': _known(parts[2], _replies)});
        if (parts[2] == 'sent') await count('notif_reply');
      }
    } catch (_) {}
    for (final e in pushes.entries) {
      await count(e.key, e.value);
    }
  }

  static String _modeOf(ChatPrefs prefs, {required bool remote}) {
    if (!remote) return 'remote_off';
    if (prefs.inAppEnabled) return 'in_app';
    return prefs.dmPush ? 'dm_push_only' : 'off';
  }

  /// Settings worth a report, as short options
  static Map<String, String> _options(ChatPrefs p) {
    final replies = p.listReplyCount;
    final hidden = ChatPrefs.globalRooms.where(p.hiddenRooms.contains).toList()..sort();
    return {
      'launcher': p.launcher.name,
      'ticker': p.ticker ? 'on' : 'off',
      'ticker_tap': p.tickerTap.name,
      'ticker_top': p.tickerTop ? 'on' : 'off',
      'glow': p.glowMode.name,
      'bubble_total': p.bubbleTotal ? 'on' : 'off',
      'notif_tap': p.notificationTap.name,
      'dm_push': p.dmPush ? 'on' : 'off',
      'alert_notify': p.alertNotify ? 'on' : 'off',
      'vibrate': p.alertVibrate ? 'on' : 'off',
      'sound': p.soundForAll ? p.soundForAllType.name : 'per_room',
      'room_tones': p.tones.isEmpty ? 'off' : 'on',
      'quiet_hours': p.quietHours ? 'on' : 'off',
      'mentions': p.mentions ? 'on' : 'off',
      'shortcuts': p.shortcuts ? 'on' : 'off',
      'quick_rows': '${p.quickRows}',
      'quick_types': p.quickRowsShown.map((r) => r.name).join('-'),
      'bazaar_analysis': p.bazaarAnalysis ? 'on' : 'off',
      'price_check': p.priceCheck ? 'on' : 'off',
      'item_price': p.itemPrice ? 'on' : 'off',
      'translate': p.messageActionHidden.contains('translate') ? 'off' : (p.translateTo.isEmpty ? 'device' : 'fixed'),
      'text_size': p.textScale < 0.95 ? 'small' : (p.textScale > 1.05 ? 'large' : 'normal'),
      'list_text_size': p.listTextScale < 0.95 ? 'small' : (p.listTextScale > 1.05 ? 'large' : 'normal'),
      'list_replies': !p.listReply ? 'off' : (replies <= 3 ? '1-3' : (replies <= 10 ? '4-10' : '11-20')),
      'preview_lines': '${p.previewLines}',
      'hidden_social': hidden.isEmpty ? 'none' : hidden.join('-'),
      'globals': p.globalsPlacement.name,
      'friends_tab': p.friendsTab.isEmpty ? 'auto' : p.friendsTab,
      'friends_sort': p.friendsSort,
      'swipe_left': p.swipeLeft.name,
      'images': p.imageAutoLoad.name,
      'link_previews': p.linkPreviews.name,
      'link_window': p.linkWindow ? 'on' : 'off',
      'image_host': p.imageHost.name,
      'compact': p.compactMode ? 'on' : 'off',
      'avatars': p.showAvatars ? 'on' : 'off',
      'faction_events': p.factionEvents ? 'on' : 'off',
      'faction_chain': p.factionChain ? 'on' : 'off',
      'warn_key': p.warnApiKey ? 'on' : 'off',
    };
  }

  static Future<void> _queue = Future.value();

  /// Once a day, or when the mode changes
  static Future<void> report(ChatPrefs prefs, {required bool remote, required bool loaded}) =>
      _queue = _queue.then((_) => _report(prefs, remote: remote, loaded: loaded)).catchError((_) {});

  static Future<void> _report(ChatPrefs prefs, {required bool remote, required bool loaded}) async {
    final mode = _modeOf(prefs, remote: remote);
    final now = DateTime.now();
    if (mode == _mode && now.isBefore(_next)) return;
    final store = BackgroundPrefs();
    final int last;
    final String lastMode;
    try {
      last = await store.getChatDaily();
      lastMode = await store.getChatMode();
    } catch (_) {
      return;
    }
    if (mode == _mode && now.isBefore(_next)) return;
    final due = now.millisecondsSinceEpoch - last >= Duration.millisecondsPerDay;
    _mode = mode;
    _next = (due ? now : DateTime.fromMillisecondsSinceEpoch(last)).add(const Duration(days: 1));
    if (!due && mode == lastMode) return;

    await store.setChatMode(mode);
    try {
      if (debugSink == null) await analytics?.setUserProperty(name: 'chat_mode', value: mode);
    } catch (_) {}
    if (lastMode.isNotEmpty && mode != lastMode) event('chat_mode_changed', {'mode': mode});
    if (!due) return;
    await store.setChatDaily(now.millisecondsSinceEpoch);

    // Defaults stay silent
    if (loaded) {
      final defaults = _options(ChatPrefs());
      _options(prefs).forEach((setting, option) {
        if (option != defaults[setting]) event('chat_setting_daily', {'setting': setting, 'option': option});
      });
    }

    await flush();
    final Map<String, int> counts;
    try {
      counts = await _stored();
    } catch (_) {
      return;
    }
    counts.forEach((key, value) {
      if (value <= 0) return;
      key.startsWith('push_')
          ? event('chat_push_daily', {'outcome': key.substring(5), 'count': value})
          : event('chat_usage_daily', {'feature': key, 'count': value});
    });
    counts.clear();
    try {
      await store.setChatCounts('');
    } catch (_) {}
  }
}
