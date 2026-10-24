import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_big_window.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  late List<String> reports;
  late DateTime now;
  late BigWindowKeyboardProbe saved;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    reports = [];
    now = DateTime(2026, 10, 24);
    saved = BigWindowKeyboardProbe.instance;
    BigWindowKeyboardProbe.instance = BigWindowKeyboardProbe(reports.add, clock: () => now);
  });

  tearDown(() => BigWindowKeyboardProbe.instance = saved);

  Future<ChatController> pumpWindow(WidgetTester tester) async {
    final source = FakeChatSource();
    final chat = ChatController(source, ChatPrefs());
    source.emit(const ChatReadyEvent(99));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 520,
            child: ChatBigWindowView(chat: chat, roomId: 'dm:7', fullscreen: false, onClose: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    return chat;
  }

  Future<void> close(WidgetTester tester, ChatController chat) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    chat.dispose();
    debugDefaultTargetPlatformOverride = null;
  }

  testWidgets('a field that drops focus right away is reported once', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final chat = await pumpWindow(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    now = now.add(const Duration(milliseconds: 300));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(reports, hasLength(1));
    expect(reports.single, contains('ms: 300'));
    expect(reports.single, contains('fieldGone: false'));

    await tester.tap(find.byType(TextField));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(reports, hasLength(1));

    await close(tester, chat);
  });

  testWidgets('a window that goes away under the field sends nothing', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final chat = await pumpWindow(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(reports, isEmpty);

    BigWindowKeyboardProbe.instance.focused();
    now = now.add(const Duration(milliseconds: 200));
    BigWindowKeyboardProbe.instance.lost(fieldGone: false, fullscreen: false);
    expect(reports, hasLength(1));

    await close(tester, chat);
  });

  testWidgets('a slow blur or a keyboard already open is left alone', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final chat = await pumpWindow(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    now = now.add(const Duration(seconds: 2));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 150);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(reports, isEmpty);

    await close(tester, chat);
  });
}
