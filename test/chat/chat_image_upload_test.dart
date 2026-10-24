import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:torn_pda/providers/chat/chat_backup.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/utils/sembast_db.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

import 'chat_fakes.dart';

class _Recorder implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await requestStream?.drain<void>();
    final isCatbox = options.uri.host == 'catbox.moe';
    return ResponseBody.fromString(
      isCatbox
          ? 'https://files.catbox.moe/a.png'
          : jsonEncode({
              'data': {'url': 'https://i.ibb.co/a.png', 'link': 'https://i.imgur.com/a.png'},
            }),
      200,
      headers: {
        Headers.contentTypeHeader: [isCatbox ? Headers.textPlainContentType : Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  useTempPathProvider();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('expiration', () {
    Future<RequestOptions> sent(ChatImageHost host, int expiration) async {
      final recorder = _Recorder();
      ChatImageUpload.dio.httpClientAdapter = recorder;
      await ChatImageUpload.upload(host, Uint8List(4), 'a.png', 'k', expiration: expiration);
      return recorder.requests.single;
    }

    test('sent to ImgBB in seconds', () async {
      for (final seconds in ChatPrefs.imgbbExpirationOptions.where((s) => s > 0)) {
        expect((await sent(ChatImageHost.imgbb, seconds)).uri.queryParameters['expiration'], '$seconds');
      }
    });

    test('not sent with never', () async {
      expect((await sent(ChatImageHost.imgbb, 0)).uri.queryParameters.keys, ['key']);
    });

    test('not sent to other services', () async {
      expect((await sent(ChatImageHost.catbox, 86400)).uri.queryParameters, isEmpty);
      expect((await sent(ChatImageHost.imgur, 86400)).uri.queryParameters, isEmpty);
    });
  });

  group('saved value', () {
    Future<ChatPrefs> loaded() async {
      final prefs = ChatPrefs();
      addTearDown(prefs.dispose);
      await prefs.load();
      return prefs;
    }

    test('defaults to never and survives a restart', () async {
      await PrefsDatabase.clearAll();
      final prefs = await loaded();
      expect(prefs.imgbbExpiration, 0);
      prefs.setImgbbExpiration(604800);
      await Future<void>.delayed(Duration.zero);
      expect((await loaded()).imgbbExpiration, 604800);
    });

    test('service: imgbb when nothing is saved, imgur kept with a Client-ID', () async {
      await PrefsDatabase.clearAll();
      expect((await loaded()).imageHost, ChatImageHost.imgbb);

      await Prefs().setChatImgurClientId('fake-client-id');
      expect((await loaded()).imageHost, ChatImageHost.imgur);

      await Prefs().setChatImageHost('catbox');
      expect((await loaded()).imageHost, ChatImageHost.catbox);

      await PrefsDatabase.clearAll();
      await Prefs().setChatImageHost('imgur');
      expect((await loaded()).imageHost, ChatImageHost.imgur);

      await Prefs().setChatImageHost('gone');
      expect((await loaded()).imageHost, ChatImageHost.imgbb);
    });

    test('a value outside the options is ignored', () async {
      await PrefsDatabase.clearAll();
      final prefs = await loaded();
      prefs.setImgbbExpiration(30);
      expect(prefs.imgbbExpiration, 0);
    });

    test('an old backup without the new values changes nothing', () {
      final prefs = ChatPrefs()
        ..setImgbbExpiration(604800)
        ..setImageHost(ChatImageHost.catbox);
      addTearDown(prefs.dispose);
      prefs.applyBackup(ChatBackup.parse(jsonEncode({'version': 1, 'prefs': {}})), replace: true);
      expect(prefs.imgbbExpiration, 604800);
      expect(prefs.imageHost, ChatImageHost.catbox);
    });

    test('backup', () {
      String backup(Object? value) => jsonEncode({'version': 1, 'prefs': {'imgbbExpiration': value}});
      final source = ChatPrefs()..setImgbbExpiration(2592000);
      addTearDown(source.dispose);
      final saved = (jsonDecode(ChatBackup.export(source, DateTime.utc(2026))) as Map)['prefs'] as Map;
      expect(saved['imgbbExpiration'], 2592000);

      final target = ChatPrefs();
      addTearDown(target.dispose);
      target.applyBackup(ChatBackup.parse(backup(2592000)), replace: true);
      expect(target.imgbbExpiration, 2592000);
      target.applyBackup(ChatBackup.parse(backup(45)), replace: true);
      expect(target.imgbbExpiration, 2592000);
    });
  });
}
