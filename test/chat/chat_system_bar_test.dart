import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_intro_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

const _bar = 48.0;
const _screen = Size(400, 800);

void main() {
  useTempPathProvider();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  void threeButtonBar(WidgetTester tester) {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: _bar);
    tester.view.viewPadding = const FakeViewPadding(bottom: _bar);
    addTearDown(tester.view.reset);
  }

  Widget app(Widget home) => ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: MaterialApp(home: ChatTheme(child: home)),
  );

  testWidgets('last settings row clears the system bar', (tester) async {
    threeButtonBar(tester);
    await tester.pumpWidget(
      app(
        ChatSettingsSubpage(
          title: 'Long',
          builder: (_) => [for (var i = 0; i < 40; i++) ListTile(title: Text('Row $i'))],
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pump();
    expect(tester.getBottomLeft(find.text('Row 39')).dy, lessThanOrEqualTo(_screen.height - _bar));
  });

  testWidgets('welcome button clears the system bar', (tester) async {
    threeButtonBar(tester);
    late BuildContext context;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    showChatIntro(context, always: true);
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Got it');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(button).dy, lessThanOrEqualTo(_screen.height - _bar));
  });

  testWidgets('upload notice offers the upload settings', (tester) async {
    final key = GlobalKey<NavigatorState>();
    NativeChat.navigatorKey = key;
    addTearDown(() => NativeChat.navigatorKey = null);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          navigatorKey: key,
          home: const Scaffold(body: ChatUploadSetupNotice(host: ChatImageHost.imgur)),
        ),
      ),
    );
    await tester.tap(find.text('Image upload settings'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Image upload')), findsOneWidget);
  });
}
