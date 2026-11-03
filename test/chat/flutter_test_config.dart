import 'dart:async';

import 'package:torn_pda/widgets/chat/native_chat.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  NativeChat.session.engineOverride = true;
  await testMain();
}
