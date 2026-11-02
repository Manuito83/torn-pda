import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:chopper/chopper.dart' as chopper;
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:torn_pda/models/chat/chat_chain_report.dart';
import 'package:torn_pda/models/chat/chat_link_info.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
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

class _Job<T> {
  final Future<T?> Function() task;
  final List<bool Function()> wanted;
  final Completer<T?> done = Completer();
  bool dropped = false;

  _Job(this.task, bool Function() first) : wanted = [first];

  bool get alive => wanted.any((w) => w());
}

// Expiring value, retried after failure
class _Cached<T> {
  _Cached(this.life, this.fetch, {this.keepStale = false});

  final Duration life;
  final Future<T?> Function() fetch;
  final bool keepStale;
  (DateTime, T)? _known;
  Future<T?>? _loading;
  DateTime? _retry;

  Future<T?> get() async {
    final known = _known;
    if (known != null && DateTime.now().isBefore(known.$1)) return known.$2;
    final stale = keepStale ? known?.$2 : null;
    final retry = _retry;
    if (retry != null && DateTime.now().isBefore(retry)) return stale;
    return _loading ??= _refresh(stale).whenComplete(() => _loading = null);
  }

  Future<T?> _refresh(T? stale) async {
    T? value;
    try {
      value = await fetch();
    } catch (_) {}
    final now = DateTime.now();
    if (value != null) _known = (now.add(life), value);
    _retry = value == null ? now.add(const Duration(minutes: 5)) : null;
    return value ?? stale;
  }

  void reset() {
    _known = null;
    _loading = null;
    _retry = null;
  }
}

class _Queue {
  Duration gap;
  int perMinute;
  final ListQueue<_Job> _jobs = ListQueue();
  final ListQueue<DateTime> _recent = ListQueue();
  bool _running = false;
  int _epoch = 0;

  _Queue(this.gap, this.perMinute);

  void add(_Job job) {
    _jobs.addFirst(job);
    if (!_running) _run();
  }

  /// Pending jobs end as dropped
  void reset(Duration gap, int perMinute) {
    this.gap = gap;
    this.perMinute = perMinute;
    for (final job in _jobs) {
      job.dropped = true;
      job.done.complete(null);
    }
    _jobs.clear();
    _recent.clear();
    _epoch++;
    _running = false;
  }

  Future<void> _run() async {
    final epoch = _epoch;
    _running = true;
    while (_jobs.isNotEmpty && epoch == _epoch) {
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
    if (epoch == _epoch) _running = false;
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
  static int _generation = 0;
  static final _sections = _Cached<Map<int, ForumCategoriesResponse$Categories$Item>>(
    const Duration(hours: 12),
    () async {
      final list = await fetchForumSections();
      return list == null ? null : {for (final c in list) c.id: c};
    },
    keepStale: true,
  );
  static final _catalog = _Cached<ItemsModel>(const Duration(hours: 1), () => fetchItems());

  static final _Queue _torn = _Queue(const Duration(milliseconds: 1200), 20);
  static final _Queue _web = _Queue(const Duration(milliseconds: 300), 30);
  static final _Queue _ff = _Queue(const Duration(milliseconds: 500), 20);

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

  static Future<T?> _settle<T>(_Job<T> job, void Function(T?) store, void Function() done) {
    final generation = _generation;
    return job.done.future
        .then(
          (value) {
            if (!job.dropped && generation == _generation) store(value);
            return value;
          },
          onError: (_) {
            if (generation == _generation) store(null);
            return null;
          },
        )
        .whenComplete(() {
          if (generation == _generation) done();
        });
  }

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
        final report = ChatChainReport.parse((await fetchChainReport(link.id!))?['chainreport']);
        return report == null ? null : ChatLinkInfo.chainReport(report);
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

  static Future<Map<int, ForumCategoriesResponse$Categories$Item>?> forumSections() => _sections.get();

  static Future<ItemsModel?> catalogItems() => _catalog.get();

  static Future<Map<String, dynamic>?> _get(
    String path,
    ApiSelection_v2 selection, [
    String? selections,
    Map<String, String>? query,
    bool keepError = false,
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
    if (keepError && response is ApiError) {
      return {
        'error': {'code': response.errorId, 'error': response.errorReason},
      };
    }
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

  static Future<Map<String, dynamic>?> _ownChainReport() =>
      _get('/faction/chainreport', ApiSelection_v2.factionBasic, null, null, true);

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
    final generation = _generation;
    final job = _Job<Object>(() async {
      await load();
      return null;
    }, wanted);
    _torn.add(job);
    return _inventoryRunning[category] = job.done.future
        .then((_) {
          if (job.dropped && generation == _generation) _inventoryTried.remove(category);
        }, onError: (_) {})
        .whenComplete(() {
          if (generation == _generation) _inventoryRunning.remove(category);
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

  /// Nothing cached from the old account
  static void forget() {
    _generation++;
    _cache.clear();
    _loading.clear();
    ChatPlayerCards.forget();
    _ffAsked.clear();
    _markets.clear();
    _marketLoading.clear();
    _inventoryTried.clear();
    _inventoryRunning.clear();
    asked.clear();
  }

  static void resetForTests() {
    forget();
    _sections.reset();
    _catalog.reset();
    ChatPlayerCards.resetForTests();
    fetchFaction = _faction;
    fetchCompany = _company;
    fetchItems = _items;
    fetchForumSections = _forumCategories;
    fetchThread = _thread;
    fetchPage = _page;
    fetchVideo = _video;
    fetchMarket = _market;
    fetchAttackLog = _attackLog;
    fetchChainReport = _chainReport;
    fetchWarReport = _warReport;
    fetchOwnChainReport = _ownChainReport;
    fetchOwnWars = _ownWars;
    pdaCalls = _pdaCalls;
    _pdaWatch?.cancel();
    _pdaWatch = null;
    _pdaRecent.clear();
    _torn.reset(Duration.zero, 1000);
    _web.reset(Duration.zero, 1000);
    _ff.reset(Duration.zero, 1000);
  }
}
