import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_faction_roster.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

import 'chat_fakes.dart';

final _now = DateTime.utc(2026, 10, 14, 12);

Map<String, dynamic> _chainJson({int current = 243, int timeout = 100}) => {
  'chain': {
    'id': 7,
    'current': current,
    'max': 250,
    'timeout': timeout,
    'modifier': 1.5,
    'cooldown': 0,
    'start': 1,
    'end': 2,
  },
};

Map<String, dynamic> _member(int id, String action, int ago, String state) => {
  'id': id,
  'name': 'Member$id',
  'position': 'Member',
  'level': 50,
  'days_in_faction': 100,
  'is_revivable': true,
  'is_on_wall': false,
  'is_in_oc': false,
  'has_early_discharge': false,
  'last_action': {'status': action, 'timestamp': _now.millisecondsSinceEpoch ~/ 1000 - ago, 'relative': 'x'},
  'status': {'description': state, 'details': null, 'state': state, 'color': 'green', 'until': null},
  'revive_setting': 'Everyone',
};

FactionMembersResponse _members(List<Map<String, dynamic>> list) => FactionMembersResponse.fromJson({'members': list});

List<FactionMember> _sample() => _members([
  _member(1, 'Offline', 3600, 'Okay'),
  _member(2, 'Online', 10, 'Okay'),
  _member(3, 'Online', 60, 'Hospital'),
  _member(4, 'Idle', 600, 'Abroad'),
  _member(5, 'Offline', 7200, 'Traveling'),
]).members;

void main() {
  useTempPathProvider();

  group('enemy chain line', () {
    test('hits and time left', () {
      final chain = chatEnemyChain(FactionOngoingChainResponse.fromJson(_chainJson()).chain, _now);
      expect(chatEnemyChainLine(chain, _now), 'Enemy chain 243 - 1:40 left');
      expect(chatEnemyChainLine(chain, _now.add(const Duration(seconds: 40))), 'Enemy chain 243 - 1:00 left');
      expect(chatEnemyChainLine(chain, _now.add(const Duration(seconds: 100))), isNull);
    });

    test('no chain, no line', () {
      final none = FactionOngoingChainResponse.fromJson(_chainJson(current: 0, timeout: 0)).chain;
      expect(chatEnemyChain(none, _now), isNull);
      expect(chatEnemyChainLine(null, _now), isNull);
    });
  });

  group('who is around', () {
    test('counts online, hospital and abroad', () {
      expect(chatRosterLine(_sample()), '2 online - 1 in hospital - 2 abroad');
    });

    test('leaves out empty counts', () {
      final calm = _members([_member(1, 'Offline', 5, 'Okay')]).members;
      expect(chatRosterLine(calm), '0 online');
      expect(chatRosterLine(const []), isNull);
    });

    test('sheet is ordered by last action', () {
      expect(chatRosterByAction(_sample()).map((m) => m.id), [2, 3, 4, 1, 5]);
    });

    test('one members call feeds presence and the line', () async {
      final api = FakeApiCaller(
        (url) => {
          'members': [_member(2, 'Online', 10, 'Okay'), _member(3, 'Idle', 60, 'Hospital')],
        },
      );
      Get.put<ApiCallerController>(api);
      addTearDown(Get.reset);
      addTearDown(() => ChatFactionRoster.shared.members = const []);
      final roster = await TornChatApi().roster('faction');
      expect(roster!.map((r) => (r.$1.id, r.$2.presence)), [(2, ChatPresence.online), (3, ChatPresence.idle)]);
      expect(chatRosterLine(ChatFactionRoster.shared.members), '1 online - 1 in hospital');
      expect(api.urls.single.path, '/v2/faction/members');
    });
  });

  group('ChatFactionRoster', () {
    late ChatPrefs prefs;
    late DateTime clock;
    late int chainCalls;
    late Object? chainAnswer;
    late ChatFactionRoster roster;

    setUp(() {
      prefs = ChatPrefs();
      clock = _now;
      chainCalls = 0;
      chainAnswer = FactionOngoingChainResponse.fromJson(_chainJson());
      roster = ChatFactionRoster(
        fetchChain: (id, wanted) async {
          chainCalls++;
          return chainAnswer;
        },
        clock: () => clock,
      );
    });

    tearDown(() => roster.dispose());

    Future<void> tick({int? enemy = 99}) async {
      roster.sync(prefs, enemyId: enemy);
      await Future<void>.delayed(Duration.zero);
    }

    test('chain every 30 seconds', () async {
      await tick();
      expect(chainCalls, 1);
      clock = clock.add(const Duration(seconds: 20));
      await tick();
      expect(chainCalls, 1);
      clock = clock.add(const Duration(seconds: 15));
      await tick();
      expect(chainCalls, 2);
    });

    test('a far chain is asked once a minute', () async {
      chainAnswer = FactionOngoingChainResponse.fromJson(_chainJson(timeout: 600));
      await tick();
      clock = clock.add(const Duration(seconds: 40));
      await tick();
      expect(chainCalls, 1);
      clock = clock.add(const Duration(seconds: 25));
      await tick();
      expect(chainCalls, 2);
    });

    test('nobody looking drops the queued call', () async {
      late bool Function() wanted;
      roster = ChatFactionRoster(
        fetchChain: (id, w) async {
          wanted = w;
          return null;
        },
        clock: () => clock,
      );
      await tick();
      expect(wanted(), isTrue);
      clock = clock.add(const Duration(seconds: 10));
      expect(wanted(), isFalse);
    });

    test('no war, no chain call', () async {
      await tick(enemy: null);
      expect(chainCalls, 0);
      expect(roster.chain, isNull);
    });

    test('chain goes away with the war', () async {
      await tick();
      expect(roster.chain?.hits, 243);
      await tick(enemy: null);
      expect(roster.chain, isNull);
    });

    test('a switch off stops its calls', () async {
      prefs.factionEnemyChain = false;
      await tick();
      expect(chainCalls, 0);
    });

    test('no access, no retry', () async {
      chainAnswer = ApiError(errorId: 16);
      await tick();
      clock = clock.add(const Duration(minutes: 1));
      await tick();
      clock = clock.add(const Duration(minutes: 1));
      await tick();
      expect(chainCalls, 1);
      expect(roster.chain, isNull);
    });

    test('a glitch is tried again later', () async {
      chainAnswer = ApiError(errorId: 100);
      await tick();
      clock = clock.add(const Duration(seconds: 61));
      await tick();
      expect(chainCalls, 2);
    });
  });
}
