import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:torn_pda/models/chat/chat_template.dart';
import 'package:torn_pda/providers/chat/chat_backup.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/utils/sembast_db.dart';
import 'package:torn_pda/widgets/chat/chat_help.dart';
import 'package:torn_pda/widgets/chat/chat_slot_sheet.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  ChatPrefs actionRows() => ChatPrefs()..quickRowTypes = List.filled(3, ChatQuickRow.actions);

  group('rows', () {
    const order = ['price', 'player', ChatPrefs.rowBreak2, 'tab', ChatPrefs.rowBreak3, 'status', 'wiki'];

    test('the breaks split three rows', () {
      expect(ChatPrefs.splitQuickRows(order, rows: 3), [
        ['price', 'player'],
        ['tab'],
        ['status', 'wiki'],
      ]);
    });

    test('fewer rows ignore the extra breaks', () {
      expect(ChatPrefs.splitQuickRows(order, rows: 2), [
        ['price', 'player'],
        ['tab', 'status', 'wiki'],
      ]);
      expect(ChatPrefs.splitQuickRows(order, rows: 1), [
        ['price', 'player', 'tab', 'status', 'wiki'],
      ]);
    });

    test('saved order without breaks is all row 1', () {
      expect(ChatPrefs.splitQuickRows(['price', 'tab'], rows: 3), [
        ['price', 'tab'],
        <String>[],
        <String>[],
      ]);
    });

    test('a break at the top leaves row 1 empty', () {
      expect(ChatPrefs.splitQuickRows([ChatPrefs.rowBreak2, 'price'], rows: 2), [
        <String>[],
        ['price'],
      ]);
    });

    test('going to three rows adds the new break inside the last row', () {
      final prefs = actionRows()..setQuickRows(2);
      final second = prefs.quickOrder.indexOf(ChatPrefs.rowBreak2);
      prefs.setQuickRows(3);
      final split = ChatPrefs.splitQuickRows(prefs.quickOrder, rows: 3);
      expect(prefs.quickOrder.indexOf(ChatPrefs.rowBreak2), second);
      expect(split.map((r) => r.isNotEmpty), [true, true, true]);
    });

    test('row 3 cannot end up above row 2', () {
      final prefs = actionRows()..setQuickRows(3);
      final editor = prefs.quickEditor;
      prefs.moveQuickAction(editor.indexOf(ChatPrefs.rowBreak3), editor.indexOf(ChatPrefs.rowBreak2));
      expect(prefs.quickOrder.indexOf(ChatPrefs.rowBreak2), lessThan(prefs.quickOrder.indexOf(ChatPrefs.rowBreak3)));
    });

    test('rows survive a backup', () {
      final prefs = actionRows()..setQuickRows(3);
      prefs.moveQuickAction(0, prefs.quickOrder.length - 1);
      final copy = ChatPrefs()..applyBackup(ChatBackup.parse(ChatBackup.export(prefs, DateTime(2026))), replace: true);
      expect(copy.quickRows, 3);
      expect(copy.quickRowTypes, prefs.quickRowTypes);
      expect(copy.quickOrder, prefs.quickOrder);
    });

    test('dragging with a break hidden keeps its place', () {
      final prefs = actionRows()..setQuickRows(2);
      final at = prefs.quickOrder.indexOf(ChatPrefs.rowBreak2);
      prefs.setQuickRows(1);
      prefs.moveQuickAction(0, 1);
      expect(prefs.quickOrder.indexOf(ChatPrefs.rowBreak2), at);
    });

    test('only action rows take the breaks', () {
      final prefs = ChatPrefs()..setQuickRows(3);
      prefs.setQuickRowTypes([ChatQuickRow.actions, ChatQuickRow.emoji, ChatQuickRow.actions]);
      expect(prefs.actionRows, 2);
      expect(prefs.quickEditor, contains(ChatPrefs.rowBreak2));
      expect(prefs.quickEditor, isNot(contains(ChatPrefs.rowBreak3)));
      prefs.setQuickRowTypes([ChatQuickRow.emoji, ChatQuickRow.replies, ChatQuickRow.emoji]);
      expect(prefs.actionRows, 0);
      expect(prefs.quickEditor, isNot(contains(ChatPrefs.rowBreak2)));
    });

    test('an old copy with rows turns them all into actions', () {
      final json = jsonEncode({
        'version': 1,
        'prefs': {'quickRows': 2},
      });
      final prefs = ChatPrefs()..applyBackup(ChatBackup.parse(json), replace: true);
      expect(prefs.quickRowTypes, List.filled(3, ChatQuickRow.actions));
      expect(prefs.quickRows, 2);
    });

    group('saved value', () {
      setUp(PrefsDatabase.clearAll);

      Future<ChatPrefs> loaded() async {
        final prefs = ChatPrefs();
        addTearDown(prefs.dispose);
        await prefs.load();
        return prefs;
      }

      test('nothing saved means actions, emoji and replies with examples', () async {
        final prefs = await loaded();
        expect(prefs.quickRows, 3);
        expect(prefs.quickRowTypes, [ChatQuickRow.actions, ChatQuickRow.emoji, ChatQuickRow.replies]);
        expect(prefs.quickHidden, {'emoji', 'replies'});
        expect(prefs.quickReplies, isNotEmpty);
        expect((await loaded()).quickRowTypes, prefs.quickRowTypes);
      });

      test('deleting every reply leaves the list empty', () async {
        final first = await loaded();
        for (final reply in [...first.quickReplies]) {
          first.removeQuickReply(reply);
        }
        await Future<void>.delayed(Duration.zero);
        expect((await loaded()).quickReplies, isEmpty);
      });

      test('picked row types survive a reload', () async {
        final first = await loaded();
        first.setQuickRowTypes([ChatQuickRow.replies, ChatQuickRow.actions, ChatQuickRow.emoji]);
        await Future<void>.delayed(Duration.zero);
        final again = await loaded();
        expect(again.quickRowTypes, first.quickRowTypes);
        expect(again.quickHidden, {'emoji', 'replies'});
      });
    });
  });

  group('disabled', () {
    ChatPrefs prefs(List<String> order, {int rows = 1}) => actionRows()
      ..quickOrder = order
      ..quickRows = rows;

    test('the editor lists disabled ones under the break', () {
      final p = prefs(['price', 'tab', ChatPrefs.rowBreak2, 'status'], rows: 2)..quickHidden = {'tab'};
      expect(p.quickEditor, ['price', ChatPrefs.rowBreak2, 'status', ChatPrefs.offBreak, 'tab']);
    });

    test('turning off drops it below and turning on makes it last', () {
      final p = prefs(['price', 'tab', 'status']);
      p.setQuickActionShown('tab', false);
      expect(p.quickEditor, ['price', 'status', ChatPrefs.offBreak, 'tab']);
      p.setQuickActionShown('tab', true);
      expect(p.quickEditor, ['price', 'status', 'tab', ChatPrefs.offBreak]);
    });

    test('turning on goes after an empty last row', () {
      final p = prefs(['price', ChatPrefs.rowBreak2, 'tab'], rows: 2)..quickHidden = {'tab'};
      p.setQuickActionShown('tab', true);
      expect(ChatPrefs.splitQuickRows(p.quickOrder, rows: 2)[1], ['tab']);
    });

    test('dragging across the break turns it off or on', () {
      final p = prefs(['price', 'tab', 'status']);
      p.moveQuickAction(0, 3);
      expect(p.quickOff('price'), isTrue);
      expect(p.itemPrice, isFalse);
      expect(p.quickEditor, ['tab', 'status', ChatPrefs.offBreak, 'price']);
      p.moveQuickAction(3, 0);
      expect(p.quickOff('price'), isFalse);
      expect(p.quickEditor, ['price', 'tab', 'status', ChatPrefs.offBreak]);
    });

    test('a row break cannot go below the break', () {
      final p = prefs(['price', ChatPrefs.rowBreak2, 'tab'], rows: 2);
      p.moveQuickAction(1, 3);
      expect(p.quickEditor, ['price', 'tab', ChatPrefs.rowBreak2, ChatPrefs.offBreak]);
    });
  });

  group('guide', () {
    List<String> titles(List<ChatHelpEntry> list) => [for (final e in list) e.title];
    const actions = ChatQuickRow.actions;

    test('guide order', () {
      final guide = quickGuide(
        order: ['status', 'price', ChatPrefs.rowBreak2, 'time', 'wiki'],
        rows: [actions, ChatQuickRow.emoji, ChatQuickRow.replies, actions],
        isOff: {'price', 'time'}.contains,
      );
      expect(guide.rows.map(titles), [
        ['Status'],
        ['Emojis'],
        ['Replies'],
        ['Torn wiki'],
      ]);
      expect(titles(guide.off), ['Item price', 'Time']);
    });

    test('one action row puts everything enabled in it', () {
      final guide = quickGuide(order: ['tab', ChatPrefs.rowBreak2, 'status'], rows: [actions], isOff: (_) => false);
      expect(guide.rows.map(titles), [
        ['Share tab or script', 'Status'],
      ]);
    });

    test('no action rows leaves nothing disabled to list', () {
      final guide = quickGuide(order: ['status'], rows: [ChatQuickRow.emoji], isOff: (_) => true);
      expect(guide.rows.map(titles), [
        ['Emojis'],
      ]);
      expect(guide.off, isEmpty);
    });

    test('tab and script share an entry until both are off', () {
      final one = quickGuide(order: ['tab', 'script'], rows: [actions], isOff: {'tab'}.contains);
      expect(titles(one.rows.first), ['Share tab or script']);
      expect(one.off, isEmpty);
      final both = quickGuide(order: ['tab', 'script'], rows: [actions], isOff: {'tab', 'script'}.contains);
      expect(both.rows.first, isEmpty);
      expect(titles(both.off), ['Share tab or script']);
    });
  });

  group('price steps', () {
    test('rounds to whole dollars', () {
      expect(ChatTemplate.percent(850000, 7), 909500);
      expect(ChatTemplate.percent(999, -1), 989);
      expect(ChatTemplate.percent(1500, -99), 15);
    });

    testWidgets('price steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatSlotSheet(reply: 'Yours for {price}', values: {}, asks: ['price']),
          ),
        ),
      );
      String field() => tester.widget<TextField>(find.byType(TextField)).controller!.text;
      Future<void> tap(String label) async {
        await tester.tap(find.widgetWithText(OutlinedButton, label));
        await tester.pump();
      }

      await tester.enterText(find.byType(TextField), '1000000');
      await tester.pump();
      await tap('+1%');
      await tap('+1%');
      await tap('+5%');
      expect(field(), r'$1,070,000');
      expect(find.text('+7%'), findsOneWidget);

      await tap('-5%');
      expect(field(), r'$1,020,000');

      await tester.enterText(find.byType(TextField), '2000');
      await tester.pump();
      expect(find.text('+2%'), findsNothing);
      await tap('+5%');
      expect(field(), r'$2,100');

      await tap('+5%');
      await tester.tap(find.text('+10%'));
      await tester.pump();
      expect(field(), r'$2,000');
      expect(find.text('+10%'), findsNothing);
    });
  });
}
