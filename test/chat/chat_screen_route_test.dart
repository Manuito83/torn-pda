import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/widgets/chat/chat_screen_route.dart';

import 'chat_fakes.dart';

void main() {
  group('listenAfterEntrance', () {
    late AnimationController entrance;
    late ChangeNotifier source;
    late int changes;
    late VoidCallback stop;

    setUp(() {
      entrance = AnimationController(vsync: const TestVSync(), duration: const Duration(milliseconds: 450));
      source = ChangeNotifier();
      changes = 0;
      stop = listenAfterEntrance(source, entrance, () => changes++);
    });

    tearDown(() {
      stop();
      entrance.dispose();
      source.dispose();
    });

    test('changes during the entrance wait for it to finish, once', () {
      entrance.forward();
      source
        ..notifyListeners()
        ..notifyListeners();
      expect(changes, 0);

      entrance.value = 1;
      expect(changes, 1);
    });

    test('changes outside the entrance pass straight through', () {
      entrance.value = 1;
      source.notifyListeners();
      expect(changes, 1);

      entrance.reverse();
      source.notifyListeners();
      expect(changes, 2);

      stop();
      source.notifyListeners();
      expect(changes, 2);
    });

    test('a back gesture after the entrance is not held', () {
      entrance.value = 1;
      entrance.value = 0.6;
      expect(entrance.status, AnimationStatus.forward);

      source.notifyListeners();
      expect(changes, 1);
    });
  });

  group('ChatScreenRoute', () {
    late FakeChatSource source;
    late ChatController chat;
    final navigator = GlobalKey<NavigatorState>();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      source = FakeChatSource();
      chat = ChatController(source);
    });

    tearDown(() => chat.dispose());

    Future<void> show(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const SizedBox.expand(key: Key('root')),
      ),
    );

    testWidgets('the first route stays still under it, a chat page does not', (tester) async {
      await show(tester);
      navigator.currentState!.push(
        ChatScreenRoute(
          chat: chat,
          page: const SizedBox.expand(key: Key('list')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(find.byKey(const Key('root'))), Offset.zero);

      await tester.pumpAndSettle();
      navigator.currentState!.push(
        ChatScreenRoute(
          chat: chat,
          page: const SizedBox.expand(key: Key('room')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(find.byKey(const Key('list'))).dx, lessThan(0));
      await tester.pumpAndSettle();
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('its page rebuilds with new data once it has entered', (tester) async {
      var builds = 0;
      await show(tester);
      navigator.currentState!.push(
        ChatScreenRoute(
          chat: chat,
          page: Builder(
            builder: (context) {
              context.watch<ChatController>();
              builds++;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(builds, 1);

      source.emit(const ChatConnectionEvent(ChatConnection.connected));
      await tester.pump(const Duration(milliseconds: 100));
      expect(builds, defaultTargetPlatform == TargetPlatform.iOS ? 2 : 1);

      await tester.pumpAndSettle();
      expect(builds, 2);

      source.emit(const ChatReadyEvent(99));
      await tester.pump();
      expect(builds, 3);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });
}
