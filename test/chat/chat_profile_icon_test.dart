import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_icon_menu.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/chat_profile_icon.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  group('profile chat icon', () {
    bool handle(
      Object? raw, {
      ChatProfileIcon choice = ChatProfileIcon.pda,
      bool usable = true,
      bool connected = true,
      void Function(String)? open,
    }) => handleChatProfileIcon(raw, choice: choice, usable: usable, connected: connected, open: open ?? (_) {});

    test('opens the private chat of that player', () {
      final opened = <String>[];
      expect(handle('3330200', open: opened.add), isTrue);
      expect(handle(42, open: opened.add), isTrue);
      expect(opened, ['dm:3330200', 'dm:42']);
    });

    test('leaves the click to Torn when the choice is Torn', () {
      final opened = <String>[];
      expect(handle('42', choice: ChatProfileIcon.torn, open: opened.add), isFalse);
      expect(opened, isEmpty);
    });

    test('leaves the click to Torn when the chat is off or not connected', () {
      final opened = <String>[];
      expect(handle('42', usable: false, open: opened.add), isFalse);
      expect(handle('42', connected: false, open: opened.add), isFalse);
      expect(opened, isEmpty);
    });

    test('only real player ids are taken', () {
      final opened = <String>[];
      for (final raw in [null, '', '0', '-5', '12abc', '1 2', '1234567890123456789', 4.5, true, <String>[]]) {
        expect(handle(raw, open: opened.add), isFalse, reason: '$raw');
      }
      expect(opened, isEmpty);
    });
  });

  group('browser icon toggle', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      NativeChat.bigWindow.value = null;
      NativeChat.quickWindows.value = [];
    });

    tearDown(() {
      NativeChat.bigWindow.value = null;
      NativeChat.quickWindows.value = [];
    });

    test('opens when closed and closes when shown', () {
      expect(NativeChat.toggleBigWindow(), isTrue);
      expect(NativeChat.bigWindowShown, isTrue);

      expect(NativeChat.toggleBigWindow(), isFalse);
      expect(NativeChat.bigWindow.value, isNull);
    });

    test('restores a minimized window with its room', () {
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('dm:7');
      NativeChat.minimizeBigWindow();

      expect(NativeChat.toggleBigWindow(), isTrue);
      expect(NativeChat.bigWindowShown, isTrue);
      expect(NativeChat.bigWindow.value?.roomId, 'dm:7');
    });

    test('closes a window that no panel owns, from either panel', () {
      NativeChat.openBigWindow();
      expect(NativeChat.toggleBigWindow(side: SplitSide.right), isFalse);
      expect(NativeChat.bigWindow.value, isNull);
    });

    test('brings a covered window to the front and closes it only from the top', () {
      NativeChat.openBigWindow();
      NativeChat.openQuickWindow('dm:9');
      expect(NativeChat.stackOrder.last, 'dm:9');

      expect(NativeChat.toggleBigWindow(), isTrue);
      expect(NativeChat.stackOrder.last, NativeChat.bigWindowId);

      expect(NativeChat.toggleBigWindow(), isFalse);
      expect(NativeChat.bigWindow.value, isNull);
    });

    test('the other panel moves the window instead of closing it', () {
      NativeChat.openBigWindow(side: SplitSide.left);
      expect(NativeChat.toggleBigWindow(side: SplitSide.right), isTrue);
      expect(NativeChat.bigWindow.value?.side, SplitSide.right);

      expect(NativeChat.toggleBigWindow(side: SplitSide.right), isFalse);
      expect(NativeChat.bigWindow.value, isNull);
    });
  });

  group('unread badge', () {
    Future<void> mount(WidgetTester tester, int unread) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(width: 24, height: 24, key: Key('left')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ChatIconWithBadge(
                  key: const Key('slot'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  unread: unread,
                  counts: const {},
                  brightness: Brightness.light,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(width: 24, height: 24, key: Key('right')),
              ),
            ],
          ),
        ),
      ),
    );

    testWidgets('counts up to 99 and then shows 99+', (tester) async {
      for (final (unread, shown) in [(1, '1'), (9, '9'), (10, '10'), (99, '99'), (250, '99+')]) {
        await mount(tester, unread);
        expect(find.text(shown), findsOneWidget, reason: '$unread');
      }
    });

    testWidgets('keeps its size and never changes the slot of the icon', (tester) async {
      Future<(Size, Size)> measure(int count) async {
        await mount(tester, count);
        return (tester.getSize(find.byKey(const Key('slot'))), tester.getSize(find.byType(ChatIconBadge)));
      }

      final (slotOne, badgeOne) = await measure(1);
      final (slotMany, badgeMany) = await measure(250);
      expect(slotMany, slotOne);
      expect(badgeMany.height, badgeOne.height);
      expect(badgeMany.height, greaterThanOrEqualTo(16));

      final badge = tester.getRect(find.byType(ChatIconBadge));
      expect(badge.right, lessThan(tester.getRect(find.byKey(const Key('right'))).left));
      expect(badge.top, greaterThanOrEqualTo(0));
      expect(
        tester.getRect(find.byKey(const Key('slot'))).center.dy,
        tester.getRect(find.byKey(const Key('left'))).center.dy,
      );
    });
  });
}
