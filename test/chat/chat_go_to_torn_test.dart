import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  late WebViewProvider web;
  var live = true;

  setUp(() async {
    await Prefs().setWebViewSecondaryTabs('{"tabsSave":[]}');
    await Prefs().setWebViewMainTab('{"tabsSave":[]}');
    await Prefs().setSplitBrowsersLayout('');
    await Prefs().setWebViewLastActiveTab(0);
    NativeChat.resetTabs();
    NativeChat.prefs.inAppEnabled = true;
    NativeChat.keyValid.value = true;
    live = true;
  });

  tearDown(() {
    NativeChat.resetTabs();
    NativeChat.isLive = NativeChat.tabAlive;
  });

  Future<GlobalKey<NavigatorState>> start(WidgetTester tester) async {
    web = (await tester.runAsync(() async {
      final provider = WebViewProvider()..splitScreenPosition = WebViewSplitPosition.left;
      await provider.addTab(url: 'https://www.torn.com/index.php', tabUid: 'tab0');
      return provider;
    }))!;
    NativeChat.isLive = (_) => live;
    NativeChat.watchTabs(web);
    final key = GlobalKey<NavigatorState>();
    NativeChat.navigatorKey = key;
    addTearDown(() => NativeChat.navigatorKey = null);
    await tester.pumpWidget(
      ChangeNotifierProvider<WebViewProvider>.value(
        value: web,
        child: MaterialApp(navigatorKey: key, home: const SizedBox()),
      ),
    );
    return key;
  }

  testWidgets('goToTornTab reopens over a live tab', (tester) async {
    live = false;
    final key = await start(tester);
    unawaited(NativeChat.open(key.currentState!, roomId: 'global'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(NativeChat.controller.currentRoomId, 'global');

    unawaited(NativeChat.goToTornTab());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(NativeChat.screenOpen.value, isFalse);
    expect(web.browserShowInForeground, isTrue);

    live = true;
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(NativeChat.screenOpen.value, isTrue);
    expect(NativeChat.controller.currentRoomId, 'global');
    key.currentState!.popUntil((route) => route.isFirst);
    await tester.pump(const Duration(seconds: 1));
  });
}
