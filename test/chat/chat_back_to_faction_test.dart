import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/pages/chat/chat_page.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  setUp(() {
    NativeChat.prefs
      ..inAppEnabled = true
      ..launcher = ChatLauncher.browser
      ..miniBubbles = false
      ..reopenChats = false
      ..onScreen = []
      ..windows = []
      ..bigWindow = [];
    NativeChat.keyValid.value = true;
    NativeChat.restoreWindows();
  });

  tearDown(() {
    NativeChat.closeBigWindow();
    NativeChat.closeQuickWindow();
    NativeChat.minimized.value = const [];
  });

  Future<GlobalKey<NavigatorState>> start(WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    NativeChat.navigatorKey = key;
    addTearDown(() => NativeChat.navigatorKey = null);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [BotToastNavigatorObserver()],
        builder: BotToastInit(),
        home: const SizedBox(),
      ),
    );
    return key;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('after leaving for an attack, the full chat opens Faction once', (tester) async {
    Get.put<ApiCallerController>(FakeApiCaller((_) => null));
    addTearDown(Get.reset);
    final key = await start(tester);
    NativeChat.prefs.launcherTap = ChatLauncherTap.full;
    NativeChat.leaveForBrowser(backTo: 'faction');

    NativeChat.launch(key.currentState!);
    await settle(tester);
    expect(find.byType(ChatConversationPage), findsOneWidget);
    expect(NativeChat.controller.currentRoomId, 'faction');

    key.currentState!.popUntil((route) => route.isFirst);
    await settle(tester);
    expect(NativeChat.screenOpen.value, isFalse);

    NativeChat.launch(key.currentState!);
    await settle(tester);
    expect(find.byType(ChatPage), findsOneWidget);
    expect(find.byType(ChatConversationPage), findsNothing);

    key.currentState!.popUntil((route) => route.isFirst);
    await settle(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the chat window does the same', (tester) async {
    final key = await start(tester);
    NativeChat.prefs.launcherTap = ChatLauncherTap.window;
    NativeChat.leaveForBrowser(backTo: 'faction');

    NativeChat.launch(key.currentState!);
    await tester.pump();
    expect(NativeChat.bigWindow.value?.roomId, 'faction');

    NativeChat.closeBigWindow();
    await tester.pump();
    NativeChat.launch(key.currentState!);
    await tester.pump();
    expect(NativeChat.bigWindowShown, isTrue);
    expect(NativeChat.bigWindow.value?.roomId, isNull);
  });
}
