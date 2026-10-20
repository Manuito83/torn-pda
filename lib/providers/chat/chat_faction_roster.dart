import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_faction_events.dart';
import 'package:torn_pda/models/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

class ChatFactionRoster extends ChangeNotifier {
  ChatFactionRoster({
    Future<Object?> Function(int enemyId, bool Function() wanted)? fetchChain,
    DateTime Function()? clock,
  }) : _fetchChain = fetchChain ?? _chainCall,
       _clock = clock ?? DateTime.now;

  static final ChatFactionRoster shared = ChatFactionRoster();

  static const Duration _chainEvery = Duration(seconds: 30);
  static const Duration _chainCalm = Duration(minutes: 1);
  static const Duration _chainSoon = Duration(minutes: 2);

  final Future<Object?> Function(int enemyId, bool Function() wanted) _fetchChain;
  final DateTime Function() _clock;

  ChatEnemyChain? chain;

  List<FactionMember> members = const [];
  DateTime? membersAt;
  bool _chainDenied = false;
  bool _chainLoading = false;
  int? _chainFor;
  DateTime? _chainAsked;
  DateTime _seen = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _watched => _clock().difference(_seen) < const Duration(seconds: 5);

  void sync(ChatPrefs prefs, {required int? enemyId}) {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || ChatLinkPreviews.busy) return;
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
    notifyListeners();
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
}
