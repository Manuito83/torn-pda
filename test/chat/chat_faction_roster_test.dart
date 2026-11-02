import 'dart:async';

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
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

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

Map<String, dynamic> _member(
  int id,
  String action,
  int ago,
  String state, {
  String? name,
  String? description,
  String? details,
  int? outIn,
  String position = 'Member',
  int level = 50,
}) => {
  'id': id,
  'name': name ?? 'Member$id',
  'position': position,
  'level': level,
  'days_in_faction': 100,
  'is_revivable': true,
  'is_on_wall': false,
  'is_in_oc': false,
  'has_early_discharge': false,
  'last_action': {'status': action, 'timestamp': _now.millisecondsSinceEpoch ~/ 1000 - ago, 'relative': 'x'},
  'status': {
    'description': description ?? state,
    'details': details,
    'state': state,
    'color': 'green',
    'until': outIn == null ? null : _now.millisecondsSinceEpoch ~/ 1000 + outIn,
  },
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
    String line(List<FactionMember> members) =>
        chatRosterCounts(members).map((c) => '${c.count} ${c.label}').join(' - ');

    test('counts online, hospital and abroad', () {
      expect(line(_sample()), '2 online - 1 in hospital - 2 abroad');
    });

    test('leaves out empty counts', () {
      final calm = _members([_member(1, 'Offline', 5, 'Okay')]).members;
      expect(line(calm), '0 online');
      expect(chatRosterCounts(const []), isEmpty);
    });

    test('forgetting the account drops the old faction', () {
      ChatFactionRoster.shared.setMembers(_sample());
      NativeChat.controller.backTo = 'faction';
      NativeChat.factionOps.retalShared.value = {'local-retal-77-1'};
      NativeChat.forgetAccount();
      expect(ChatFactionRoster.shared.recentMembers(), isNull);
      expect(ChatFactionRoster.shared.members, isEmpty);
      expect(NativeChat.controller.backTo, isNull);
      expect(NativeChat.factionOps.retalShared.value, isEmpty);
    });

    test('one members call feeds presence and the line', () async {
      final api = FakeApiCaller(
        (url) => {
          'members': [_member(2, 'Online', 10, 'Okay'), _member(3, 'Idle', 60, 'Hospital')],
        },
      );
      Get.put<ApiCallerController>(api);
      addTearDown(Get.reset);
      addTearDown(ChatFactionRoster.shared.clear);
      final roster = await TornChatApi(ChatPrefs()).roster('faction');
      expect(roster!.map((r) => (r.$1.id, r.$2.presence)), [(2, ChatPresence.online), (3, ChatPresence.idle)]);
      expect(line(ChatFactionRoster.shared.members), '1 online - 1 in hospital');
      expect(api.urls.single.path, '/v2/faction/members');
    });

    test('refresh asks again inside the 30 second reuse', () async {
      final api = FakeApiCaller(
        (url) => {
          'members': [_member(2, 'Online', 10, 'Okay')],
        },
      );
      Get.put<ApiCallerController>(api);
      addTearDown(Get.reset);
      addTearDown(ChatFactionRoster.shared.clear);
      final roster = ChatFactionRoster.shared;
      await TornChatApi(ChatPrefs()).roster('faction');
      final before = DateTime.now().subtract(const Duration(seconds: 10));
      roster.membersAt = before;
      await roster.refresh();
      expect(api.urls, hasLength(2));
      expect(roster.membersAt!.isAfter(before), isTrue);
    });
  });

  group('members sheet', () {
    List<int> ids(List<FactionMember> list) => list.map((m) => m.id).toList();

    test('days in faction read as years, months and days', () {
      expect(chatRosterTenure(2210), '6y 0m 18d');
      expect(chatRosterTenure(400), '1y 1m 3d');
      expect(chatRosterTenure(104), '3m 12d');
      expect(chatRosterTenure(30), '30d');
      expect(chatRosterTenure(31), '1m 0d');
      expect(chatRosterTenure(0), '0d');
    });

    test('filters add up across groups', () {
      final list = _members([
        _member(1, 'Online', 10, 'Okay'),
        _member(2, 'Online', 10, 'Hospital', outIn: 60),
        _member(3, 'Offline', 10, 'Okay'),
        _member(4, 'Online', 10, 'Okay'),
      ]).members;
      bool fits(FactionMember m, Map<String, String> f, [String q = '']) => chatRosterMatches(m, f, q);
      expect(ids(list.where((m) => fits(m, {'presence': 'online', 'state': 'okay'})).toList()), [1, 4]);
      expect(ids(list.where((m) => fits(m, {}, 'member3')).toList()), [3]);
      expect(ids(list.where((m) => fits(m, {}, '4')).toList()), [4]);
    });

    test('abroad and in Torn leave a foreign hospital apart', () {
      final list = _members([
        _member(1, 'Online', 10, 'Traveling', description: 'Traveling to Japan'),
        _member(2, 'Online', 10, 'Abroad', description: 'In Japan'),
        _member(3, 'Online', 10, 'Hospital', description: 'In a Japanese hospital for 12 mins', outIn: 60),
        _member(4, 'Online', 10, 'Okay'),
      ]).members;
      expect(ids(list.where((m) => chatRosterMatches(m, {'travel': 'away'}, '')).toList()), [1, 2]);
      expect(ids(list.where((m) => chatRosterMatches(m, {'travel': 'home'}, '')).toList()), [4]);
      expect(ids(list.where((m) => chatRosterMatches(m, {'country': 'Japan'}, '')).toList()), [1, 2, 3]);
    });

    test('the plane knows the way home in both formats', () {
      final list = _members([
        _member(1, 'Online', 10, 'Traveling', description: 'Traveling from Torn to Japan'),
        _member(2, 'Online', 10, 'Traveling', description: 'Traveling from South Africa to Torn'),
        _member(3, 'Online', 10, 'Traveling', description: 'Returning to Torn from Mexico'),
        _member(4, 'Online', 10, 'Hospital', description: 'In a Japanese hospital for 12 mins', outIn: 60),
        _member(5, 'Online', 10, 'Hospital', description: 'In hospital for 12 mins', outIn: 60),
      ]).members;
      expect(list.map(chatRosterTrip), [
        ('Japan', TravelDirection.outbound),
        ('South Africa', TravelDirection.returning),
        ('Mexico', TravelDirection.returning),
        ('Japan', TravelDirection.none),
        null,
      ]);
    });

    test('leaves hospital first keeps the rest last both ways', () {
      final list = _members([
        _member(1, 'Online', 10, 'Okay', name: 'Abe'),
        _member(2, 'Online', 10, 'Hospital', outIn: 600),
        _member(3, 'Online', 10, 'Hospital', outIn: 60),
        _member(4, 'Online', 10, 'Jail', outIn: 30),
      ]).members;
      expect(ids(chatRosterSorted(list, 'hospital', reversed: false)), [3, 2, 1, 4]);
      expect(ids(chatRosterSorted(list, 'hospital', reversed: true)), [2, 3, 1, 4]);
    });

    test('a stay already over leads the status order', () {
      final list = _members([
        _member(1, 'Online', 10, 'Okay'),
        _member(2, 'Online', 10, 'Hospital', outIn: 120),
        _member(3, 'Online', 10, 'Hospital', outIn: -30),
      ]).members;
      expect(ids(chatRosterSorted(list, 'status', reversed: false)), [1, 3, 2]);
    });

    test('ties go by name whatever the direction', () {
      final list = _members([
        _member(1, 'Online', 10, 'Okay', name: 'cora', level: 20),
        _member(2, 'Online', 10, 'Okay', name: 'Bert', level: 20),
        _member(3, 'Online', 10, 'Okay', name: 'Ann', level: 90),
      ]).members;
      expect(ids(chatRosterSorted(list, 'level', reversed: false)), [3, 2, 1]);
      expect(ids(chatRosterSorted(list, 'level', reversed: true)), [2, 1, 3]);
      expect(ids(chatRosterSorted(list, 'name', reversed: true)), [1, 2, 3]);
    });

    test('position puts leaders first, then the rarest', () {
      final list = _members([
        _member(1, 'Online', 10, 'Okay', position: 'Seaman'),
        _member(2, 'Online', 10, 'Okay', position: 'Seaman'),
        _member(3, 'Online', 10, 'Okay', position: 'Officer'),
        _member(4, 'Online', 10, 'Okay', position: 'Co-leader'),
        _member(5, 'Online', 10, 'Okay', position: 'Leader'),
      ]).members;
      expect(ids(chatRosterSorted(list, 'position', reversed: false)), [5, 4, 3, 1, 2]);
    });

    test('status line', () {
      String line(Map<String, dynamic> json, [DateTime? at]) =>
          chatRosterStatus(_members([json]).members.single, at ?? _now);
      final hospital = _member(
        1,
        'Online',
        10,
        'Hospital',
        description: 'In an Argentinian hospital for 11 mins ',
        details: 'Attacked by someone',
        outIn: 647,
      );
      expect(line(hospital), 'Hospital 10m 47s');
      expect(line(hospital, _now.add(const Duration(minutes: 11))), 'Hospital');
      expect(
        chatRosterStatus(_members([hospital]).members.single, _now, spoken: true),
        'Hospital in Argentina - out in 11 minutes',
      );
      expect(
        line(_member(2, 'Online', 10, 'Traveling', description: 'Traveling from South Africa to Torn')),
        'From South Africa',
      );
      expect(
        line(_member(3, 'Online', 10, 'Traveling', description: 'Returning to Torn from Japan')),
        'From Japan',
      );
      expect(line(_member(4, 'Online', 10, 'Traveling', description: 'Traveling to Japan')), 'To Japan');
      expect(
        line(_member(5, 'Online', 10, 'Federal', description: 'In federal jail for 2 days')),
        'In federal jail for 2 days',
      );
    });

    test('who put them in hospital, with their id', () {
      ChatRosterCause? cause(String details) =>
          chatRosterCause(_members([_member(1, 'Online', 10, 'Hospital', details: details)]).members.single);
      expect(
        cause('Mugged by <a href = "http://www.torn.com/profiles.php?XID=2076124">kunagisa</a>'),
        (before: 'Mugged by ', by: 'kunagisa', byId: 2076124, after: ''),
      );
      expect(cause('Attacked by someone'), (before: 'Attacked by someone', by: '', byId: null, after: ''));
      expect(
        cause('Hit by <a href="/profiles.php?XID=7">Tom &amp; Jerry</a> &quot;twice&quot;'),
        (before: 'Hit by ', by: 'Tom & Jerry', byId: 7, after: ' "twice"'),
      );
      expect(cause('By <a href="/profiles.php?XID=12345678901">Big</a>'), (before: 'By Big', by: '', byId: null, after: ''));
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

    test('a list that lands after forgetting the account is dropped', () async {
      final answer = Completer<List<FactionMember>?>();
      roster = ChatFactionRoster(fetchMembers: () => answer.future, clock: () => clock);
      final loading = roster.loadMembers();
      roster.clear();
      answer.complete(_sample());
      expect(await loading, isNull);
      expect(roster.members, isEmpty);
      expect(roster.recentMembers(), isNull);
    });

    test('refresh waits 5 seconds after the last list', () async {
      var calls = 0;
      roster = ChatFactionRoster(
        fetchMembers: () async {
          calls++;
          return _sample();
        },
        clock: () => clock,
      );
      await roster.refresh();
      clock = clock.add(const Duration(seconds: 3));
      await roster.refresh();
      expect(calls, 1);
      clock = clock.add(const Duration(seconds: 3));
      await roster.refresh();
      expect(calls, 2);
    });

    test('a failed refresh can be tried again at once', () async {
      var fail = true;
      roster = ChatFactionRoster(
        fetchMembers: () async => fail ? null : _sample(),
        clock: () => clock,
      );
      await roster.refresh();
      expect((roster.refreshFailed, roster.canRefresh), (true, true));
      fail = false;
      await roster.refresh();
      expect((roster.refreshFailed, roster.canRefresh), (false, false));
    });

    test('the open list asks every 20 seconds, failed or not', () async {
      var calls = 0;
      roster = ChatFactionRoster(
        fetchMembers: () async {
          calls++;
          return null;
        },
        clock: () => clock,
      );
      Future<void> second() async {
        clock = clock.add(const Duration(seconds: 1));
        roster.keepFresh();
        await Future<void>.delayed(Duration.zero);
      }

      await second();
      expect(calls, 1);
      for (var i = 0; i < 19; i++) {
        await second();
      }
      expect(calls, 1);
      await second();
      expect(calls, 2);
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
