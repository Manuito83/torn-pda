import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/widgets/chat/chat_friends_sheet.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

final _now = DateTime.now();

Map<String, dynamic> _member(
  int id,
  String name,
  String action, {
  String state = 'Okay',
  String description = 'Okay',
  Duration? left,
}) => {
  'id': id,
  'name': name,
  'position': 'Member',
  'level': 50,
  'days_in_faction': 100,
  'is_revivable': true,
  'is_on_wall': false,
  'is_in_oc': false,
  'has_early_discharge': false,
  'last_action': {'status': action, 'timestamp': 1760000000, 'relative': 'x'},
  'status': {
    'description': description,
    'details': null,
    'state': state,
    'color': 'green',
    'until': left == null ? null : _now.add(left).millisecondsSinceEpoch ~/ 1000,
  },
  'revive_setting': 'Everyone',
};

class _Rosters implements ChatApi {
  _Rosters([this.members]);

  final List<Map<String, dynamic>>? members;
  final asked = <String>[];

  @override
  Future<List<(ChatUser, ChatLastAction)>?> roster(String roomId) async {
    asked.add(roomId);
    if (roomId == 'faction') {
      ChatFactionRoster.shared.setMembers(
        FactionMembersResponse.fromJson({
          'members':
              members ?? [_member(1, 'Zed', 'Offline'), _member(2, 'Amy', 'Online'), _member(3, 'Bob', 'Online')],
        }).members,
      );
    }
    return [(const ChatUser(id: 9, name: 'Worker'), const ChatLastAction(ChatPresence.online, null))];
  }

  @override
  Future<List<(ChatUser, ChatLastAction)>?> friends() async => [];

  @override
  Future<ChatLastAction?> lastAction(int userId) async => null;
}

Future<void> _open(WidgetTester tester, _Rosters api, String tab, {bool settle = true}) async {
  NativeChat.prefs.friendsTab = tab;
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chat = ChatController(FakeChatSource(), null, api);
  addTearDown(chat.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<ChatController>.value(
          value: chat,
          child: ChatFriendsSheet(api: api),
        ),
      ),
    ),
  );
  // Settling never ends once a countdown ticks
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Iterable<String?> _names(WidgetTester tester) => tester
    .widgetList<ListTile>(find.byType(ListTile))
    .map((t) => ((t.title as Row).children.first as Expanded).child)
    .map((w) => (w as Text).data);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    chatCompanyCache = null;
    NativeChat.prefs.friendsSort = 'status';
    ChatFactionRoster.shared.members = const [];
    ChatFactionRoster.shared.membersAt = null;
  });

  testWidgets('faction tab lists its members online first', (tester) async {
    final api = _Rosters();
    await _open(tester, api, 'faction');
    expect(api.asked, ['faction']);
    expect(_names(tester), ['Amy', 'Bob', 'Zed']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('company is asked only when opened, once within the cache', (tester) async {
    final api = _Rosters();
    await _open(tester, api, 'torn');
    expect(api.asked, isEmpty);

    await tester.tap(find.text('Company'));
    await tester.pumpAndSettle();
    expect(api.asked, ['company']);
    expect(find.text('Worker'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Company'));
    await tester.pumpAndSettle();
    expect(api.asked, ['company']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fresh faction data is not asked again', (tester) async {
    final api = _Rosters();
    ChatFactionRoster.shared.setMembers(
      FactionMembersResponse.fromJson({
        'members': [_member(2, 'Amy', 'Online')],
      }).members,
    );
    await _open(tester, api, 'faction');
    expect(api.asked, isEmpty);
    expect(find.text('Amy'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  final mixed = [
    _member(1, 'Zed', 'Offline', state: 'Hospital', left: const Duration(hours: 1)),
    _member(2, 'Amy', 'Online'),
    _member(3, 'Bob', 'Offline'),
    _member(4, 'Cal', 'Online', state: 'Traveling', description: 'Traveling to Japan'),
    _member(5, 'Dan', 'Online', state: 'Hospital', left: const Duration(minutes: 5)),
    _member(6, 'Eve', 'Idle', state: 'Jail', left: const Duration(minutes: 20)),
    _member(7, 'Fay', 'Online', state: 'Abroad', description: 'In Japan'),
  ];

  testWidgets('status order', (tester) async {
    final api = _Rosters(mixed);
    await _open(tester, api, 'faction', settle: false);
    expect(_names(tester), ['Amy', 'Bob', 'Dan', 'Zed', 'Eve', 'Cal', 'Fay']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('remembers the chosen order', (tester) async {
    final calm = [
      _member(2, 'Amy', 'Online'),
      _member(3, 'Bob', 'Offline'),
      _member(4, 'Cal', 'Online', state: 'Traveling', description: 'Traveling to Japan'),
      _member(7, 'Fay', 'Online', state: 'Abroad', description: 'In Japan'),
    ];
    await _open(tester, _Rosters(calm), 'faction');
    expect(_names(tester), ['Amy', 'Bob', 'Cal', 'Fay']);
    await tester.tap(find.byTooltip('Sort by'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(PopupMenuItem<String>), matching: find.text('Online')));
    await tester.pumpAndSettle();
    expect(_names(tester), ['Amy', 'Cal', 'Fay', 'Bob']);
    await tester.pumpWidget(const SizedBox());

    await _open(tester, _Rosters(calm), 'faction');
    expect(_names(tester), ['Amy', 'Cal', 'Fay', 'Bob']);
    await tester.pumpWidget(const SizedBox());
  });

  test('past until', () {
    final now = DateTime.utc(2026, 10, 19, 12);
    final out = ChatPlayerStatus.from('Hospital', 'In hospital', now.millisecondsSinceEpoch ~/ 1000 - 10)!;
    final still = ChatPlayerStatus.from('Hospital', 'In hospital', now.millisecondsSinceEpoch ~/ 1000 + 90)!;
    expect(out.left(now), isNull);
    expect(out.label(now), 'Hospital');
    expect(still.label(now), 'Hospital 1m 30s');
    expect(ChatPlayerStatus.compare(still, out, now), isNegative);
    expect(ChatPlayerStatus.compare(out, ChatPlayerStatus.from('Okay', 'Okay', null), now), isPositive);
  });

  test('company rows carry the employee status', () async {
    Get.put<ApiCallerController>(
      FakeApiCaller(
        (_) => {
          'company_employees': {
            '11': {
              'name': 'Ann',
              'position': 'Director',
              'days_in_company': 3,
              'wage': 100,
              'manual_labor': 1,
              'intelligence': 1,
              'endurance': 1,
              'effectiveness': <String, dynamic>{},
              'last_action': {'status': 'Online', 'timestamp': 1760000000, 'relative': 'x'},
              'status': {
                'description': 'In hospital for 2 mins',
                'details': '',
                'state': 'Hospital',
                'color': 'red',
                'until': 1760000120,
              },
            },
            '12': {
              'name': 'Ben',
              'position': 'Clerk',
              'days_in_company': 3,
              'wage': 100,
              'manual_labor': 1,
              'intelligence': 1,
              'endurance': 1,
              'effectiveness': <String, dynamic>{},
              'last_action': {'status': 'Offline', 'timestamp': 1760000000, 'relative': 'x'},
              'status': {'description': 'Okay', 'details': '', 'state': 'Okay', 'color': 'green', 'until': 0},
            },
          },
        },
      ),
    );
    addTearDown(Get.reset);
    final rows = (await TornChatApi().roster('company'))!;
    expect(rows.map((r) => (r.$1.id, r.$1.playerStatus?.state, r.$1.playerStatus?.until?.millisecondsSinceEpoch)), [
      (11, 'Hospital', 1760000120000),
      (12, 'Okay', null),
    ]);
  });
}
