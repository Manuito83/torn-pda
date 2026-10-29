import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:chopper/chopper.dart' as chopper;
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:html/parser.dart' as html;
import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_bazaar.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_price_check.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_cache_model.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';
import 'package:torn_pda/providers/ffscouter_cache_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';

class ChatBounty {
  final int total;
  final int count;

  const ChatBounty(this.total, this.count);

  static ChatBounty? parse(Map<String, dynamic> json) {
    final list = json['bounties'];
    if (list is! List) return null;
    var total = 0;
    var count = 0;
    for (final bounty in list) {
      final reward = bounty is Map ? bounty['reward'] : null;
      if (reward is! num || reward <= 0) continue;
      total += reward.toInt();
      count++;
    }
    return count == 0 ? null : ChatBounty(total, count);
  }

  String get text => 'Bounty ${ChatMoneyRef.format(total)}${count > 1 ? ' ($count listed)' : ''}';
}

class ChatLinkInfo {
  final String title;
  final String? detail;
  final ChatPresence? presence;
  final String? imageUrl;
  final List<String> extra;

  final ChatStatusClock? clock;
  final String? lead;

  const ChatLinkInfo(
    this.title, {
    this.detail,
    this.presence,
    this.imageUrl,
    this.extra = const [],
    this.clock,
    this.lead,
    this.settled = false,
    this.bazaar,
    this.kicker,
  });

  /// Overrides the label above the title
  final String? kicker;

  final ChatBazaar? bazaar;

  /// Won't change any more
  final bool settled;

  String? detailAt(DateTime now) {
    if (clock == null) return detail;
    final text = [?lead, ?clock!.at(now)].join(' - ');
    return text.isEmpty ? null : text;
  }

  static final NumberFormat _number = NumberFormat.decimalPattern('en_US');

  static ChatLinkInfo? player(ChatLinkKind kind, Map<String, dynamic> json, [ChatBounty? bounty]) {
    // v1 sends it flat
    final profile = json['profile'] is Map ? json['profile'] as Map : json;
    final name = profile['name'];
    if (name is! String || name.isEmpty) return null;
    final id = profile['id'] ?? profile['player_id'];
    final level = profile['level'];
    final status = profile['status'] is Map ? profile['status']['description'] : null;
    final presence = ChatPresence.parse(profile['last_action'] is Map ? profile['last_action']['status'] : null);
    final title = id == null ? name : '$name [$id]';
    if (kind == ChatLinkKind.bazaar) {
      final parsed = ChatBazaar.parse(json);
      final count = parsed?.items.length;
      final detail = switch (count) {
        null => null,
        0 => parsed!.open ? 'Empty' : 'Closed',
        1 => '1 item',
        _ => '$count items',
      };
      return ChatLinkInfo('Bazaar of $title', detail: detail, presence: presence, bazaar: parsed);
    }
    final parts = [if (level != null) 'Lvl $level', if (status is String && status.isNotEmpty) status];
    return ChatLinkInfo(
      kind == ChatLinkKind.attack ? 'Attack $title' : title,
      detail: parts.isEmpty ? null : parts.join(' - '),
      presence: presence,
      extra: [if (bounty != null) bounty.text],
      clock: ChatStatusClock.parse(profile['status'] is Map ? profile['status'] as Map : null),
      lead: level == null ? null : 'Lvl $level',
    );
  }

  static ChatLinkInfo? faction(Map<String, dynamic> json, [DateTime? now]) {
    final basic = json['basic'];
    if (basic is! Map) return null;
    final name = basic['name'];
    if (name is! String || name.isEmpty) return null;
    final tag = basic['tag'];
    final members = basic['members'];
    final capacity = basic['capacity'];
    final respect = basic['respect'];
    final rank = basic['rank'] is Map ? basic['rank']['name'] : null;
    final detail = [
      if (members is int) capacity is int && capacity > 0 ? '$members/$capacity members' : '$members members',
      if (respect is int) 'Respect ${respect >= 1000 ? ChatPriceCheck.short(respect) : respect}',
      if (rank is String && rank.isNotEmpty) rank,
    ];

    final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final ranked = json['wars'] is Map ? json['wars']['ranked'] : null;
    final List<Map> sides = ranked is Map && ranked['factions'] is List
        ? (ranked['factions'] as List).whereType<Map>().toList()
        : [];
    final start = ranked is Map ? ranked['start'] : null;
    final end = ranked is Map ? ranked['end'] : null;
    final live = start is int && start <= seconds && (end is! int || end == 0 || end > seconds);
    String? war;
    if (live && sides.length == 2) {
      final mine = sides.firstWhere((f) => f['id'] == basic['id'], orElse: () => sides.first);
      final other = sides.firstWhere((f) => f != mine);
      if (other['name'] is String) {
        String score(Map side) => _number.format(side['score'] is num ? (side['score'] as num).toInt() : 0);
        war = 'War vs ${other['name']}: ${score(mine)} - ${score(other)}';
      }
    }
    final chain = json['chain'] is Map ? json['chain']['current'] : null;
    return ChatLinkInfo(
      tag is String && tag.isNotEmpty ? '$name [$tag]' : name,
      detail: detail.isEmpty ? null : detail.join(' - '),
      extra: [?war, if (chain is int && chain > 0) 'Chain $chain'],
    );
  }

  static ChatLinkInfo? company(Map<String, dynamic> json) {
    final profile = json['profile'];
    if (profile is! Map) return null;
    final name = profile['name'];
    if (name is! String || name.isEmpty) return null;
    final stars = profile['rating'];
    final type = profile['type'] is Map ? profile['type']['name'] : null;
    final staff = profile['employees'] is Map ? profile['employees'] : const {};
    final director = profile['director'] is Map ? profile['director'] : const {};
    final typeText = [if (stars is int && stars > 0) '$stars*', if (type is String && type.isNotEmpty) type].join(' ');
    final detail = [
      if (typeText.isNotEmpty) typeText,
      if (staff['hired'] is int && staff['capacity'] is int) '${staff['hired']}/${staff['capacity']} staff',
    ];
    final boss = director['name'];
    return ChatLinkInfo(
      name,
      detail: detail.isEmpty ? null : detail.join(' - '),
      extra: [
        if (boss is String && boss.isNotEmpty) 'Director $boss${director['id'] is int ? ' [${director['id']}]' : ''}',
      ],
    );
  }

  static ChatLinkInfo? item(ChatLink link, ItemsModel catalog) {
    final items = catalog.items;
    if (items == null) return null;
    Item? found = link.id == null ? null : items['${link.id}'];
    if (found == null && link.id == null) {
      final name = link.title.toLowerCase();
      found = items.values.where((i) => i.name?.toLowerCase() == name).firstOrNull;
    }
    final name = found?.name;
    if (found == null || name == null || name.isEmpty) return null;
    final value = found.marketValue;
    return ChatLinkInfo(name, detail: value == null || value <= 0 ? 'Item market' : 'Market \$${_number.format(value)}');
  }

  static ChatLinkInfo? forum(ForumThreadExtended thread, [String? section]) {
    final title = html.parseFragment(thread.title).text?.trim() ?? '';
    if (title.isEmpty) return null;
    final author = thread.author.username;
    final posts = thread.posts == 1 ? '1 post' : '${_number.format(thread.posts)} posts';
    return ChatLinkInfo(title, detail: author.isEmpty ? posts : 'by $author - $posts', kicker: _forumKicker(section));
  }

  static ChatLinkInfo? forumSection(ForumCategoriesResponse$Categories$Item section) {
    final name = html.parseFragment(section.title).text?.trim() ?? '';
    if (name.isEmpty) return null;
    return ChatLinkInfo(name, detail: section.threads == 1 ? '1 thread' : '${_number.format(section.threads)} threads');
  }

  static ChatLinkInfo? forumPlaced(ChatLink link, String? section) =>
      section == null ? null : ChatLinkInfo(link.title, kicker: _forumKicker(section));

  static String? _forumKicker(String? section) {
    final name = section == null ? '' : html.parseFragment(section).text?.trim() ?? '';
    return name.isEmpty ? null : 'Torn forum - $name';
  }

  static ChatLinkInfo? attackLog(Map<String, dynamic> json) {
    final log = json['attacklog'];
    if (log is! Map) return null;
    final actions = log['log'] is List ? (log['log'] as List).whereType<Map>().toList() : <Map>[];
    final summary = log['summary'] is List ? (log['summary'] as List).whereType<Map>().toList() : <Map>[];
    if (actions.isEmpty && summary.isEmpty) return null;
    int total(String key) => summary.fold(0, (sum, s) => sum + (s[key] is int ? s[key] as int : 0));
    num at(Map a) => a['timestamp'] is num ? a['timestamp'] as num : 0;
    final last = actions.isEmpty ? null : actions.reduce((a, b) => at(b) > at(a) ? b : a);
    String who(Object? p) =>
        p is Map && p['name'] is String ? '${p['name']}${p['id'] is int ? ' [${p['id']}]' : ''}' : 'Someone';
    const verbs = {'hosp': 'hospitalized', 'mug': 'mugged', 'leave': 'left', 'lost': 'lost to'};
    final verb = verbs[last?['action']];
    final text = last?['text'];
    final hits = total('hits');
    return ChatLinkInfo(
      verb != null
          ? '${who(last!['attacker'])} $verb ${who(last['defender'])}'
          : text is String && text.isNotEmpty
          ? text
          : 'Attack log',
      detail: summary.isEmpty
          ? null
          : '${hits == 1 ? '1 hit' : '$hits hits'}, ${total('misses')} missed - ${_number.format(total('damage'))} dmg',
      settled: true,
    );
  }

  static ChatLinkInfo? chainReport(Map<String, dynamic> json, [DateTime? now]) {
    final report = json['chainreport'];
    if (report is! Map || report['details'] is! Map) return null;
    final details = report['details'] as Map;
    if (details['chain'] is! int) return null;
    final attackers = report['attackers'] is List ? (report['attackers'] as List).length : 0;
    final (start, end) = (report['start'], report['end']);
    final best = details['best'];
    final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final detail = [
      if (attackers > 0) attackers == 1 ? '1 attacker' : '$attackers attackers',
      if (best is num) 'best hit ${best.toStringAsFixed(1)}',
    ];
    return ChatLinkInfo(
      [
        'Chain ${details['chain']}',
        if (details['respect'] is num) '${_number.format((details['respect'] as num).round())} respect',
        if (start is int && end is int && end > start) chatSpan(Duration(seconds: end - start)),
      ].join(' - '),
      detail: detail.isEmpty ? null : detail.join(' - '),
      settled: end is int && end > 0 && seconds - end > 600,
    );
  }

  static ChatLinkInfo? warReport(Map<String, dynamic> json) {
    final report = json['rankedwarreport'];
    if (report is! Map) return null;
    final sides = report['factions'] is List ? (report['factions'] as List).whereType<Map>().toList() : <Map>[];
    if (sides.length != 2 || sides.any((f) => f['name'] is! String)) return null;
    String score(Map f) => _number.format(f['score'] is num ? (f['score'] as num).toInt() : 0);
    final winner = sides.where((f) => f['id'] == report['winner']).firstOrNull;
    final rank = winner?['rank'];
    final (before, after) = rank is Map ? (rank['before'], rank['after']) : (null, null);
    final detail = [
      if (winner != null) '${winner['name']} won${report['forfeit'] == true ? ' by forfeit' : ''}',
      if (before is String && after is String && before != after) '$before to $after',
    ];
    return ChatLinkInfo(
      '${sides[0]['name']} ${score(sides[0])} : ${score(sides[1])} ${sides[1]['name']}',
      detail: detail.isEmpty ? null : detail.join(' - '),
      settled: report['end'] is int && (report['end'] as int) > 0,
    );
  }

  static ChatLinkInfo? page(String source, Uri base) {
    final doc = html.parse(source);
    String? meta(String key) {
      final tag = doc.querySelector('meta[property="$key"]') ?? doc.querySelector('meta[name="$key"]');
      final content = tag?.attributes['content']?.trim();
      return content == null || content.isEmpty ? null : content;
    }

    final title = meta('og:title') ?? meta('twitter:title') ?? doc.querySelector('title')?.text.trim();
    if (title == null || title.isEmpty) return null;
    final image = meta('og:image') ?? meta('twitter:image');
    final imageUri = image == null ? null : Uri.tryParse(image);
    final resolved = imageUri == null ? null : base.resolveUri(imageUri);
    return ChatLinkInfo(
      title.length > 150 ? '${title.substring(0, 147)}…' : title,
      detail: base.host,
      imageUrl: resolved != null && (resolved.scheme == 'https' || resolved.scheme == 'http') ? '$resolved' : null,
    );
  }

  static ChatLinkInfo video(String id, Map<String, dynamic>? json) {
    final title = json?['title'] is String ? (json!['title'] as String).trim() : '';
    final author = json?['author_name'] is String ? (json!['author_name'] as String).trim() : '';
    return ChatLinkInfo(
      title.isEmpty ? 'YouTube video' : (title.length > 150 ? '${title.substring(0, 147)}…' : title),
      detail: author.isEmpty ? null : author,
      imageUrl: 'https://img.youtube.com/vi/$id/hqdefault.jpg',
    );
  }
}

class _Job<T> {
  final Future<T?> Function() task;
  final List<bool Function()> wanted;
  final Completer<T?> done = Completer();
  bool dropped = false;

  _Job(this.task, bool Function() first) : wanted = [first];

  bool get alive => wanted.any((w) => w());
}

class _Queue {
  final Duration gap;
  final int perMinute;
  final ListQueue<_Job> _jobs = ListQueue();
  final ListQueue<DateTime> _recent = ListQueue();
  bool _running = false;

  _Queue(this.gap, this.perMinute);

  void add(_Job job) {
    _jobs.addFirst(job);
    if (!_running) _run();
  }

  Future<void> _run() async {
    _running = true;
    while (_jobs.isNotEmpty) {
      final job = _jobs.removeFirst();
      if (!job.alive) {
        job.dropped = true;
        job.done.complete(null);
        continue;
      }
      while (_recent.isNotEmpty && DateTime.now().difference(_recent.first) > const Duration(minutes: 1)) {
        _recent.removeFirst();
      }
      if (_recent.length >= perMinute) {
        _jobs.addFirst(job);
        await Future.delayed(const Duration(minutes: 1) - DateTime.now().difference(_recent.first));
        continue;
      }
      _recent.add(DateTime.now());
      try {
        job.done.complete(await job.task());
      } catch (e, trace) {
        job.done.completeError(e, trace);
      }
      await Future.delayed(gap);
    }
    _running = false;
  }
}

class ChatLinkPreviews {
  ChatLinkPreviews._();

  static const int _maxEntries = 400;
  static const int _pageBytes = 256 * 1024;

  static Future<Map<String, dynamic>?> Function(int id) fetchFaction = _faction;
  static Future<Map<String, dynamic>?> Function(int id) fetchCompany = _company;
  static Future<ItemsModel?> Function() fetchItems = _items;
  static Future<List<ForumCategoriesResponse$Categories$Item>?> Function() fetchForumSections = _forumCategories;
  static Future<ForumThreadExtended?> Function(int id) fetchThread = _thread;
  static Future<String?> Function(Uri uri) fetchPage = _page;
  static Future<Map<String, dynamic>?> Function(String id) fetchVideo = _video;
  static Future<List<Object>?> Function(int id) fetchMarket = _market;
  static Future<Map<String, dynamic>?> Function(String code) fetchAttackLog = _attackLog;
  static Future<Map<String, dynamic>?> Function(int id) fetchChainReport = _chainReport;
  static Future<Map<String, dynamic>?> Function(int id) fetchWarReport = _warReport;
  static Future<Map<String, dynamic>?> Function() fetchOwnChainReport = _ownChainReport;
  static Future<Map<String, dynamic>?> Function() fetchOwnWars = _ownWars;

  static final LinkedHashMap<String, (DateTime, ChatLinkInfo?)> _cache = LinkedHashMap();
  static final Map<String, _Job<ChatLinkInfo>> _loading = {};
  static final Map<int, DateTime> _ffAsked = {};
  static final Map<int, (DateTime, List<Object>?)> _markets = {};
  static final Map<int, _Job<List<Object>>> _marketLoading = {};
  static final Map<String, DateTime> _inventoryTried = {};
  static final Map<String, Future<void>> _inventoryRunning = {};
  static (DateTime, Map<int, ForumCategoriesResponse$Categories$Item>)? _sections;
  static Future<Map<int, ForumCategoriesResponse$Categories$Item>?>? _sectionsLoading;
  static DateTime? _sectionsRetry;
  static (DateTime, ItemsModel)? _catalog;
  static Future<ItemsModel?>? _catalogLoading;
  static DateTime? _catalogRetry;

  static _Queue _torn = _Queue(const Duration(milliseconds: 1200), 20);
  static _Queue _web = _Queue(const Duration(milliseconds: 300), 30);
  static _Queue _ff = _Queue(const Duration(milliseconds: 500), 20);

  static final Set<String> asked = {};

  static const int _busyCalls = 70;

  static int Function() pdaCalls = _pdaCalls;
  static final ListQueue<DateTime> _pdaRecent = ListQueue();
  static StreamSubscription<int>? _pdaWatch;

  static bool get busy => pdaCalls() > _busyCalls;

  static int _pdaCalls() {
    if (_pdaWatch == null && Get.isRegistered<ApiCallerController>()) {
      var replay = true;
      _pdaWatch = Get.find<ApiCallerController>().callCountStream.listen((count) {
        final now = DateTime.now();
        // First value is the minute so far
        for (var i = replay ? count : 1; i > 0; i--) {
          _pdaRecent.add(now);
        }
        replay = false;
      });
    }
    final now = DateTime.now();
    while (_pdaRecent.isNotEmpty && now.difference(_pdaRecent.first) >= const Duration(minutes: 1)) {
      _pdaRecent.removeFirst();
    }
    return _pdaRecent.length;
  }

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.stream,
      maxRedirects: 3,
      headers: {'User-Agent': 'Mozilla/5.0 (compatible; TornPDA link preview)', 'Accept': 'text/html'},
    ),
  );

  static String? keyOf(ChatLink link) => switch (link.kind) {
    ChatLinkKind.player ||
    ChatLinkKind.attack ||
    ChatLinkKind.bazaar ||
    ChatLinkKind.faction ||
    ChatLinkKind.company ||
    ChatLinkKind.chainReport ||
    ChatLinkKind.warReport when link.id != null => '${link.kind.name}:${link.id}',
    ChatLinkKind.forum when link.id != null => 'forum:${link.id}',
    ChatLinkKind.forum when link.forumId != null => 'forumSection:${link.forumId}',
    ChatLinkKind.attackLog when link.logCode != null => 'attackLog:${link.logCode}',
    ChatLinkKind.item when link.id != null || !link.title.startsWith('Item') => 'item:${link.id ?? link.title}',
    ChatLinkKind.external when link.videoId != null => 'video:${link.videoId}',
    ChatLinkKind.external when link.warning == null => 'web:${link.url}',
    _ => null,
  };

  static Duration _ttl(ChatLink link, ChatLinkInfo? info) => info == null
      ? const Duration(minutes: 5)
      : switch (link.kind) {
          ChatLinkKind.external => const Duration(minutes: 30),
          ChatLinkKind.item => const Duration(hours: 1),
          ChatLinkKind.forum => link.id == null ? const Duration(hours: 6) : const Duration(minutes: 15),
          ChatLinkKind.attackLog ||
          ChatLinkKind.chainReport ||
          ChatLinkKind.warReport when info.settled => const Duration(hours: 2),
          _ => const Duration(minutes: 3),
        };

  static (ChatLinkInfo?,)? cached(ChatLink link) {
    final key = keyOf(link);
    if (key == null) return null;
    final hit = _cache.remove(key);
    if (hit == null || DateTime.now().isAfter(hit.$1)) return null;
    _cache[key] = hit;
    return (hit.$2,);
  }

  static Future<ChatLinkInfo?> load(ChatLink link, bool Function() wanted) {
    final key = keyOf(link);
    if (key == null) return Future.value();
    final hit = cached(link);
    if (hit != null) return Future.value(hit.$1);
    final running = _loading[key];
    if (running != null) {
      running.wanted.add(wanted);
      return running.done.future;
    }
    final job = _Job<ChatLinkInfo>(() => _resolve(link), wanted);
    _loading[key] = job;
    (link.isTorn ? _torn : _web).add(job);
    return _settle(job, (info) => _store(key, link, info), () => _loading.remove(key));
  }

  static Future<T?> _settle<T>(_Job<T> job, void Function(T?) store, void Function() done) => job.done.future
      .then(
        (value) {
          if (!job.dropped) store(value);
          return value;
        },
        onError: (_) {
          store(null);
          return null;
        },
      )
      .whenComplete(done);

  static Future<T?> queued<T>(Future<T?> Function() task, bool Function() wanted) async {
    T? result;
    final job = _Job(() async {
      result = await task();
      return null;
    }, wanted);
    _torn.add(job);
    try {
      await job.done.future;
    } catch (_) {
      return null;
    }
    return result;
  }

  static void _store(String key, ChatLink link, ChatLinkInfo? info) {
    _cache[key] = (DateTime.now().add(_ttl(link, info)), info);
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  static Future<ChatLinkInfo?> _resolve(ChatLink link) async {
    switch (link.kind) {
      case ChatLinkKind.player || ChatLinkKind.attack || ChatLinkKind.bazaar:
        final json = await ChatPlayerCards.json(link.id!);
        if (json == null) return null;
        return ChatLinkInfo.player(link.kind, json, link.kind == ChatLinkKind.bazaar ? null : ChatBounty.parse(json));
      case ChatLinkKind.faction:
        final json = await fetchFaction(link.id!);
        return json == null ? null : ChatLinkInfo.faction(json);
      case ChatLinkKind.company:
        final json = await fetchCompany(link.id!);
        return json == null ? null : ChatLinkInfo.company(json);
      case ChatLinkKind.item:
        final catalog = await catalogItems();
        return catalog == null ? null : ChatLinkInfo.item(link, catalog);
      case ChatLinkKind.forum when link.id == null:
        final section = (await forumSections())?[link.forumId];
        return section == null ? null : ChatLinkInfo.forumSection(section);
      case ChatLinkKind.forum:
        final thread = await fetchThread(link.id!);
        final sections = await forumSections();
        final name = sections?[thread?.forumId ?? link.forumId]?.title;
        return thread == null ? ChatLinkInfo.forumPlaced(link, name) : ChatLinkInfo.forum(thread, name);
      case ChatLinkKind.attackLog:
        final json = await fetchAttackLog(link.logCode!);
        return json == null ? null : ChatLinkInfo.attackLog(json);
      case ChatLinkKind.chainReport:
        final json = await fetchChainReport(link.id!);
        return json == null ? null : ChatLinkInfo.chainReport(json);
      case ChatLinkKind.warReport:
        final json = await fetchWarReport(link.id!);
        return json == null ? null : ChatLinkInfo.warReport(json);
      case ChatLinkKind.external when link.videoId != null:
        final id = link.videoId!;
        Map<String, dynamic>? json;
        try {
          json = await fetchVideo(id);
        } catch (_) {}
        return ChatLinkInfo.video(id, json);
      case ChatLinkKind.external:
        final source = await fetchPage(link.uri);
        return source == null ? null : ChatLinkInfo.page(source, link.uri);
      default:
        return null;
    }
  }

  static Future<ChatBounty?> bountyOf(int id) async {
    final json = await ChatPlayerCards.json(id);
    return json == null ? null : ChatBounty.parse(json);
  }

  static Future<FFScouterCacheEntry?> fairFight(int id) async {
    if (!Get.isRegistered<FFScouterCacheController>() || !Get.isRegistered<UserController>()) return null;
    final cache = Get.find<FFScouterCacheController>();
    final asked = _ffAsked[id];
    final again = asked == null || DateTime.now().difference(asked) > const Duration(minutes: 5);
    final key = Get.find<UserController>().alternativeFFScouterKey;
    if (!cache.hasFresh(id) && !cache.keyNotRegistered && key.isNotEmpty && again) {
      _ffAsked[id] = DateTime.now();
      final job = _Job<int>(() => cache.ensureFresh([id]), () => true);
      _ff.add(job);
      try {
        await job.done.future;
      } catch (_) {}
    }
    return cache.get(id);
  }

  static Future<Map<int, ForumCategoriesResponse$Categories$Item>?> forumSections() async {
    final known = _sections;
    if (known != null && DateTime.now().isBefore(known.$1)) return known.$2;
    final retry = _sectionsRetry;
    if (retry != null && DateTime.now().isBefore(retry)) return known?.$2;
    return _sectionsLoading ??= _fetchSections()
        .then((sections) {
          final now = DateTime.now();
          if (sections != null) _sections = (now.add(const Duration(hours: 12)), sections);
          _sectionsRetry = sections == null ? now.add(const Duration(minutes: 5)) : null;
          return sections ?? known?.$2;
        })
        .whenComplete(() => _sectionsLoading = null);
  }

  static Future<Map<int, ForumCategoriesResponse$Categories$Item>?> _fetchSections() async {
    try {
      final list = await fetchForumSections();
      return list == null ? null : {for (final c in list) c.id: c};
    } catch (_) {
      return null;
    }
  }

  static Future<ItemsModel?> catalogItems() async {
    final catalog = _catalog;
    if (catalog != null && DateTime.now().isBefore(catalog.$1)) return catalog.$2;
    final retry = _catalogRetry;
    if (retry != null && DateTime.now().isBefore(retry)) return null;
    return _catalogLoading ??= _fetchCatalog()
        .then((items) {
          final now = DateTime.now();
          if (items != null) _catalog = (now.add(const Duration(hours: 1)), items);
          _catalogRetry = items == null ? now.add(const Duration(minutes: 5)) : null;
          return items;
        })
        .whenComplete(() => _catalogLoading = null);
  }

  static Future<ItemsModel?> _fetchCatalog() async {
    try {
      return await fetchItems();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _get(
    String path,
    ApiSelection_v2 selection, [
    String? selections,
    Map<String, String>? query,
  ]) async {
    final response = await Get.find<ApiCallerController>().enqueueApiCall<dynamic>(
      apiSelection_v2: selection,
      apiCall: (client, apiKey) => client.client.send<dynamic, dynamic>(
        chopper.Request(
          'GET',
          Uri.parse(path),
          client.client.baseUrl,
          parameters: {'selections': ?selections, ...?query, 'comment': 'PDA-App'},
        ),
      ),
    );
    return response is Map<String, dynamic> ? response : null;
  }

  static Future<Map<String, dynamic>?> _company(int id) =>
      _get('/company/$id/profile', ApiSelection_v2.otherUserProfile);

  static Future<Map<String, dynamic>?> _faction(int id) =>
      _get('/faction/$id', ApiSelection_v2.factionBasic, 'basic,wars,chain');

  // Newest first
  static Future<Map<String, dynamic>?> _attackLog(String code) => _get(
    '/torn/attacklog',
    ApiSelection_v2.otherUserProfile,
    null,
    {'log': code, 'sort': 'DESC', 'striptags': 'true'},
  );

  static Future<Map<String, dynamic>?> _chainReport(int id) =>
      _get('/faction/$id/chainreport', ApiSelection_v2.factionBasic);

  static Future<Map<String, dynamic>?> _warReport(int id) =>
      _get('/faction/$id/rankedwarreport', ApiSelection_v2.factionBasic);

  static Future<Map<String, dynamic>?> _ownWars() => _get('/faction/rankedwars', ApiSelection_v2.factionBasic);

  static Future<Map<String, dynamic>?> _ownChainReport() => _get('/faction/chainreport', ApiSelection_v2.factionBasic);

  static Future<ForumThreadExtended?> _thread(int id) async {
    final response = await Get.find<ApiCallerController>().enqueueApiCall<ForumThreadResponse>(
      apiSelection_v2: ApiSelection_v2.forumThread,
      apiCall: (client, apiKey) => client.forumThreadIdThreadGet(threadId: id),
    );
    return response is ForumThreadResponse ? response.thread : null;
  }

  static Future<List<ForumCategoriesResponse$Categories$Item>?> _forumCategories() async {
    final response = await Get.find<ApiCallerController>().enqueueApiCall<ForumCategoriesResponse>(
      apiSelection_v2: ApiSelection_v2.forumCategories,
      apiCall: (client, apiKey) => client.forumCategoriesGet(comment: 'PDA-App'),
    );
    return response is ForumCategoriesResponse ? response.categories : null;
  }

  static Future<List<Object>?> marketListings(int id, bool Function() wanted) {
    final hit = _markets[id];
    if (hit != null && DateTime.now().isBefore(hit.$1)) return Future.value(hit.$2);
    final running = _marketLoading[id];
    if (running != null) {
      running.wanted.add(wanted);
      return running.done.future;
    }
    final job = _Job<List<Object>>(() => fetchMarket(id), wanted);
    _marketLoading[id] = job;
    _torn.add(job);
    return _settle(
      job,
      (listings) => _markets[id] = (DateTime.now().add(const Duration(minutes: 2)), listings),
      () => _marketLoading.remove(id),
    );
  }

  static Future<void> askInventory(String category, Future<void> Function() load, bool Function() wanted) {
    final running = _inventoryRunning[category];
    if (running != null) return running;
    final last = _inventoryTried[category];
    if (last != null && DateTime.now().difference(last) < const Duration(hours: 1)) return Future.value();
    _inventoryTried[category] = DateTime.now();
    final job = _Job<Object>(() async {
      await load();
      return null;
    }, wanted);
    _torn.add(job);
    return _inventoryRunning[category] = job.done.future
        .then((_) {
          if (job.dropped) _inventoryTried.remove(category);
        }, onError: (_) {})
        .whenComplete(() {
          _inventoryRunning.remove(category);
        });
  }

  static Future<List<Object>?> _market(int id) async {
    if (id == ChatPriceCheck.pointsId) {
      return ChatPriceCheck.pointsListings(await _get('/market', ApiSelection_v2.marketItem, 'pointsmarket'));
    }
    final response = await ApiCallsV2.getMarketItemApi_v2(payload: {'id': id});
    return response is MarketItemMarketResponse ? response.itemmarket.listings : null;
  }

  static Future<ItemsModel?> _items() async {
    final items = await ApiCallsV1.getItems();
    return items is ItemsModel ? items : null;
  }

  /// Each redirect is checked too
  static Future<Response<T>> getPublic<T>(
    Dio dio,
    Uri uri, {
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    var url = uri;
    for (var hop = 0; ; hop++) {
      if (!ChatLink.isPublic(url)) throw ArgumentError('not a public address');
      final response = await dio.getUri<T>(
        url,
        options: (options ?? Options()).copyWith(
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      final status = response.statusCode ?? 0;
      final location = response.headers.value('location');
      if (status < 300 || location == null) return response;
      final body = response.data;
      if (body is ResponseBody) body.stream.listen(null).cancel();
      if (hop >= 3) throw ArgumentError('too many redirects');
      url = url.resolve(location);
    }
  }

  static Future<String?> _page(Uri uri) async {
    final url = uri.replace(scheme: 'https');
    final response = await getPublic<ResponseBody>(_dio, url);
    final type = response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ?? '';
    if (!type.contains('text/html') && !type.contains('xhtml')) return null;
    final body = response.data;
    if (body == null) return null;
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in body.stream) {
      bytes.add(chunk);
      if (bytes.length >= _pageBytes) break;
      if (utf8.decode(chunk, allowMalformed: true).toLowerCase().contains('</head>')) break;
    }
    return utf8.decode(bytes.takeBytes(), allowMalformed: true);
  }

  static Future<Map<String, dynamic>?> _video(String id) async {
    final url = Uri.https('www.youtube.com', '/oembed', {
      'url': 'https://www.youtube.com/watch?v=$id',
      'format': 'json',
    });
    final response = await _dio.getUri<dynamic>(
      url,
      options: Options(responseType: ResponseType.json, headers: {'Accept': 'application/json'}),
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  static void resetForTests() {
    _cache.clear();
    _loading.clear();
    ChatPlayerCards.resetForTests();
    _ffAsked.clear();
    _markets.clear();
    _marketLoading.clear();
    _inventoryTried.clear();
    _inventoryRunning.clear();
    _sections = null;
    _sectionsLoading = null;
    _sectionsRetry = null;
    _catalog = null;
    _catalogLoading = null;
    _catalogRetry = null;
    asked.clear();
    _pdaWatch?.cancel();
    _pdaWatch = null;
    _pdaRecent.clear();
    pdaCalls = _pdaCalls;
    _torn = _Queue(Duration.zero, 1000);
    _web = _Queue(Duration.zero, 1000);
    _ff = _Queue(Duration.zero, 1000);
  }
}
