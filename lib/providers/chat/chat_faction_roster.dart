import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/api_v2/torn_v2.enums.swagger.dart' as enums;
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_faction_events.dart';
import 'package:torn_pda/models/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/utils/app_lifecycle.dart';

class ChatFactionRoster extends ChangeNotifier {
  ChatFactionRoster({
    Future<Object?> Function(int enemyId, bool Function() wanted)? fetchChain,
    Future<List<FactionMember>?> Function()? fetchMembers,
    DateTime Function()? clock,
  }) : _fetchChain = fetchChain ?? _chainCall,
       _fetchMembers = fetchMembers ?? _membersCall,
       _clock = clock ?? DateTime.now;

  static final ChatFactionRoster shared = ChatFactionRoster();

  static const Duration _chainEvery = Duration(seconds: 30);
  static const Duration _chainCalm = Duration(minutes: 1);
  static const Duration _chainSoon = Duration(minutes: 2);
  static const Duration _refreshGap = Duration(seconds: 5);
  static const Duration _openEvery = Duration(seconds: 20);

  final Future<Object?> Function(int enemyId, bool Function() wanted) _fetchChain;
  final Future<List<FactionMember>?> Function() _fetchMembers;
  final DateTime Function() _clock;

  ChatEnemyChain? chain;

  List<FactionMember> members = const [];
  DateTime? membersAt;
  DateTime? _askedAt;
  bool refreshing = false;
  bool refreshFailed = false;
  bool _chainDenied = false;
  bool _chainLoading = false;
  int? _chainFor;
  DateTime? _chainAsked;
  DateTime _seen = DateTime.fromMillisecondsSinceEpoch(0);
  int _generation = 0;

  bool get _watched => _clock().difference(_seen) < const Duration(seconds: 5);

  static bool get _away => appInBackground() || ChatLinkPreviews.busy;

  void sync(ChatPrefs prefs, {required int? enemyId}) {
    if (_away) return;
    final now = _clock();
    _seen = now;

    if (!prefs.factionEnemyChain) _chainDenied = false;

    final wantChain = prefs.inAppEnabled && prefs.factionEnemyChain && enemyId != null && !_chainDenied;
    if (!wantChain) {
      _chainFor = null;
      _chainAsked = null;
      if (chain != null) {
        chain = null;
        notifyListeners();
      }
    } else if (!_chainLoading && (_chainFor != enemyId || now.difference(_chainAsked!) >= _chainGap(now))) {
      if (_chainFor != enemyId && chain != null) {
        chain = null;
        notifyListeners();
      }
      _loadChain(enemyId, now);
    }
  }

  void setMembers(List<FactionMember> list) {
    members = list;
    membersAt = _clock();
    refreshFailed = false;
    notifyListeners();
  }

  /// Nothing left from the old account
  void clear() {
    _generation++;
    members = const [];
    membersAt = null;
    _askedAt = null;
    refreshFailed = false;
    chain = null;
    _chainFor = null;
    _chainAsked = null;
    _chainDenied = false;
    notifyListeners();
  }

  /// Null when stale
  List<FactionMember>? recentMembers({Duration within = const Duration(seconds: 30)}) {
    final at = membersAt;
    if (at == null || members.isEmpty) return null;
    return _clock().difference(at) < within ? members : null;
  }

  Future<List<FactionMember>?> loadMembers() async {
    final generation = _generation;
    final list = await _fetchMembers();
    if (list == null || generation != _generation) return null;
    setMembers(list);
    return list;
  }

  bool _quietFor(Duration gap) => [?membersAt, ?_askedAt].every((at) => _clock().difference(at) >= gap);

  bool get canRefresh => !refreshing && (refreshFailed || _quietFor(_refreshGap));

  /// Ticked while the list is open
  void keepFresh() {
    if (!_away && _quietFor(_openEvery)) refresh();
  }

  Future<void> refresh() async {
    if (!canRefresh) return;
    _askedAt = _clock();
    refreshing = true;
    notifyListeners();
    var arrived = false;
    try {
      arrived = await loadMembers() != null;
    } finally {
      refreshing = false;
      refreshFailed = !arrived;
      notifyListeners();
    }
  }

  Duration _chainGap(DateTime now) {
    final left = chain?.breaksAt.difference(now);
    return left != null && left < _chainSoon ? _chainEvery : _chainCalm;
  }

  Future<void> _loadChain(int enemyId, DateTime now) async {
    _chainLoading = true;
    _chainFor = enemyId;
    _chainAsked = now;
    try {
      final response = await _fetchChain(enemyId, () => _chainFor == enemyId && _watched);
      if (_chainFor != enemyId) return;
      if (response is ApiError) {
        if (chatFactionEventsDenied(response.errorId)) _chainDenied = true;
        return;
      }
      if (response is! FactionOngoingChainResponse) return;
      chain = chatEnemyChain(response.chain, _clock());
      notifyListeners();
    } finally {
      _chainLoading = false;
    }
  }

  static Future<Object?> _chainCall(int enemyId, bool Function() wanted) => ChatLinkPreviews.queued<Object>(
    () => Get.find<ApiCallerController>().enqueueApiCall<dynamic>(
      apiSelection_v2: ApiSelection_v2.factionChain,
      apiCall: (client, apiKey) => client.factionIdChainGet(id: enemyId),
    ),
    wanted,
  );

  static Future<List<FactionMember>?> _membersCall() async {
    final response = await Get.find<ApiCallerController>().enqueueApiCall<dynamic>(
      apiSelection_v2: ApiSelection_v2.factionMembers,
      // Timestamp skips Torn's 30 s cache
      apiCall: (client, apiKey) => client.factionMembersGet(
        striptags: enums.ApiStripTagsTrue.$false,
        timestamp: '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      ),
    );
    return response is FactionMembersResponse ? response.members : null;
  }
}
