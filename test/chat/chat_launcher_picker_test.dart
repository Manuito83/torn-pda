import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_alerts_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_logo_bubble.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

Set<T> _selected<T>(WidgetTester tester) => tester.widget<SegmentedButton<T>>(find.byType(SegmentedButton<T>)).selected;

void main() {
  useTempPathProvider();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() {
    NativeChat.prefs.setLauncher(ChatLauncher.bubble);
    NativeChat.prefs.setGlowMode(ChatGlowMode.ticker);
    NativeChat.screenOpen.value = false;
  });

  testWidgets('launcher picker follows the tap', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ChatLauncherPicker())));
    await tester.tap(find.text('Browser'));
    await tester.pump();
    expect(NativeChat.prefs.launcher, ChatLauncher.browser);
    await tester.tap(find.text('Menu header'));
    await tester.pump();
    expect(NativeChat.prefs.launcher, ChatLauncher.menuHeader);
    await tester.tap(find.text('Menu header'));
    await tester.pump();
    expect(NativeChat.prefs.launcher, ChatLauncher.menuHeader);
  });

  testWidgets('glow picker follows the tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ChatGlowSettings())),
      ),
    );
    await tester.tap(find.text('Off'));
    await tester.pump();
    expect(_selected<ChatGlowMode>(tester), {ChatGlowMode.off});
  });
}
