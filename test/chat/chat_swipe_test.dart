import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_price_check_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    NativeChat.prefs
      ..swipeLeft = ChatSwipeAction.message
      ..linkWindow = true;
    NativeChat.linkWindow.value = null;
    NativeChat.quickWindows.value = const [];
  });

  group('gesture', () {
    Future<void> drag(WidgetTester tester, {VoidCallback? left, VoidCallback? reply, double dx = -120}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatSwipeReply(
            onReply: reply,
            onSwipeLeft: left,
            child: const ColoredBox(key: Key('bubble'), color: Colors.white, child: SizedBox(height: 60, width: 300)),
          ),
        ),
      );
      await tester.drag(find.byKey(const Key('bubble')), Offset(dx, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('left past the trigger runs the left action', (tester) async {
      var left = 0;
      var reply = 0;
      await drag(tester, left: () => left++, reply: () => reply++);
      expect([left, reply], [1, 0]);
    });

    testWidgets('right still replies', (tester) async {
      var left = 0;
      var reply = 0;
      await drag(tester, left: () => left++, reply: () => reply++, dx: 120);
      expect([left, reply], [0, 1]);
    });

    testWidgets('a short left drag does nothing', (tester) async {
      var left = 0;
      await drag(tester, left: () => left++, dx: -30);
      expect(left, 0);
    });

    testWidgets('a left drag without left action does not reply', (tester) async {
      var reply = 0;
      await drag(tester, reply: () => reply++);
      expect(reply, 0);
    });

    testWidgets('what PDA added hides while dragging and comes back', (tester) async {
      final fetchItems = ChatLinkPreviews.fetchItems;
      addTearDown(() {
        ChatLinkPreviews.fetchItems = fetchItems;
        ChatLinkPreviews.resetForTests();
      });
      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchItems = () async => ItemsModel(items: {'206': Item(name: 'Xanax', marketValue: 830000)});
      NativeChat.prefs.priceCheck = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatSwipeReply(
              onReply: () {},
              child: const Column(
                children: [
                  ColoredBox(key: Key('bubble'), color: Colors.white, child: SizedBox(height: 60, width: 300)),
                  ChatTradeInsert(roomId: 'trade', text: 'WTS Xanax 800k', userId: null, color: Colors.black),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double shown() => tester
          .widget<AnimatedOpacity>(
            find.ancestor(of: find.textContaining('market'), matching: find.byType(AnimatedOpacity)),
          )
          .opacity;
      expect(shown(), 1);
      final finger = await tester.startGesture(tester.getCenter(find.byKey(const Key('bubble'))));
      await finger.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(shown(), 0);
      await finger.up();
      await tester.pumpAndSettle();
      expect(shown(), 1);
    });
  });

  group('who can be swiped', () {
    final other = chatMessage('1', 'global', sender: 7, name: 'Bravo');

    test('a public message from someone else', () {
      expect(chatSwipeLeft(other, mine: false), isNotNull);
    });

    test('not in a private chat', () {
      expect(chatSwipeLeft(chatMessage('1', 'dm:7', sender: 7), mine: false), isNull);
    });

    test('not my own message', () {
      expect(chatSwipeLeft(other, mine: true), isNull);
    });

    test('chat opens a window for the private chat', () {
      chatSwipeLeft(other, mine: false)!();
      expect(NativeChat.quickWindows.value, ['dm:7']);
      expect(NativeChat.linkWindow.value, isNull);
    });

    test('web actions open the small browser', () {
      NativeChat.prefs.swipeLeft = ChatSwipeAction.attack;
      chatSwipeLeft(other, mine: false)!();
      expect(NativeChat.linkWindow.value?.url, 'https://www.torn.com/page.php?sid=attack&user2ID=7');
      expect(NativeChat.quickWindows.value, isEmpty);
    });

    test('the small browser opens even with link previews off', () {
      NativeChat.prefs
        ..linkWindow = false
        ..swipeLeft = ChatSwipeAction.bazaar;
      chatSwipeLeft(other, mine: false)!();
      expect(NativeChat.linkWindow.value?.url, 'https://www.torn.com/bazaar.php?userId=7');
    });
  });

  group('setting', () {
    test('an empty or old saved value loads as Chat', () async {
      for (final saved in ['', 'reply']) {
        await Prefs().setNativeChatSwipeLeft(saved);
        final loaded = ChatPrefs();
        await loaded.load();
        expect(loaded.swipeLeft, ChatSwipeAction.message);
      }
    });
  });
}
