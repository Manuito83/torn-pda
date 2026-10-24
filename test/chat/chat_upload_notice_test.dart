import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('blocked notice never offers the blocked service again', () {
    expect(ChatUploadSetupNotice.choices(excluded: ChatImageHost.imgur), [ChatImageHost.imgbb, ChatImageHost.catbox]);
    expect(ChatUploadSetupNotice.choices(excluded: ChatImageHost.catbox), [ChatImageHost.imgbb, ChatImageHost.imgur]);
    expect(ChatUploadSetupNotice.choices(excluded: ChatImageHost.imgbb), [ChatImageHost.catbox, ChatImageHost.imgur]);
    expect(ChatUploadSetupNotice.choices(), [ChatImageHost.imgbb, ChatImageHost.catbox, ChatImageHost.imgur]);
  });

  testWidgets('picking a service in the notice saves it', (tester) async {
    var picked = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: ChatUploadSetupNotice(host: ChatImageHost.imgur, onPicked: () => picked++),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Catbox'));
    await tester.pump();
    expect(NativeChat.prefs.imageHost, ChatImageHost.catbox);
    expect(picked, 1);
  });
}
