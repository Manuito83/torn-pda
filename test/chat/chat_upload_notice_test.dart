import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';

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
}
