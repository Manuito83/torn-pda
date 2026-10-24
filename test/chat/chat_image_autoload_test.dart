import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_backup.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/utils/sembast_db.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());
  tearDown(() {
    NativeChat.prefs
      ..imagesPrivate = true
      ..imagesPublic = false;
  });

  const dm = ChatRoom(id: 'dm:42', name: 'Alpha', type: ChatRoomType.dm);
  const faction = ChatRoom(id: 'faction', name: 'Faction');
  const company = ChatRoom(id: 'company', name: 'Company');
  const friends = ChatRoom(id: '1234', name: 'Friends', type: ChatRoomType.custom);
  const global = ChatRoom(id: 'global', name: 'Global');
  const unknown = ChatRoom(id: 'somethingnew', name: 'New');

  bool loads(String url, ChatRoom? room, {bool inPrivate = true, bool inPublic = false}) {
    NativeChat.prefs
      ..imagesPrivate = inPrivate
      ..imagesPublic = inPublic;
    return ChatImages.autoLoads(ChatLink.parse(url)!, room);
  }

  group('rooms', () {
    test('closed rooms', () {
      expect([dm, faction, company, friends].map(ChatImages.closedRoom), everyElement(isTrue));
      expect([global, unknown, null].map(ChatImages.closedRoom), everyElement(isFalse));
    });
  });

  group('auto load', () {
    test('known hosts', () {
      for (final room in [dm, faction, company, friends]) {
        expect(loads('https://i.imgur.com/a.png', room), isTrue);
        expect(loads('https://www.torn.com/images/v2/a.gif', room), isTrue);
      }
      expect(loads('https://i.imgur.com/a.png', dm, inPrivate: false), isFalse);
    });

    test('unknown host', () {
      expect(loads('https://i.example.org/pics/cat.png', dm, inPrivate: true, inPublic: true), isFalse);
      expect(loads('https://i.example.org/pics/cat.png', global, inPrivate: true, inPublic: true), isFalse);
    });

    test('public rooms', () {
      expect(loads('https://i.imgur.com/a.png', global), isFalse);
      expect(loads('https://i.imgur.com/a.png', unknown), isFalse);
      expect(loads('https://i.imgur.com/a.png', null), isFalse);
      expect(loads('https://i.imgur.com/a.png', global, inPublic: true), isTrue);
      expect(loads('https://i.imgur.com/a.png', global, inPrivate: false, inPublic: true), isTrue);
    });

    test('whole host match', () {
      expect(loads('https://media3.giphy.com/a.gif', dm), isTrue);
      expect(loads('https://media.giphy.com/a.gif', dm), isTrue);
      expect(loads('https://media.tenor.com/a.gif', dm), isTrue);
      expect(loads('https://cdn.discordapp.com/a.png', dm), isTrue);
      expect(loads('https://media.discordapp.net/a.png', dm), isTrue);
      expect(loads('https://files.catbox.moe/a.png', dm), isTrue);
      expect(loads('https://litter.catbox.moe/a.png', dm), isTrue);
      expect(loads('https://i.ibb.co/a.png', dm), isTrue);
      expect(loads('https://i.imgur.com.evil.example/a.png', dm), isFalse);
      expect(loads('https://evil-i.imgur.com/a.png', dm), isFalse);
      expect(loads('https://imgur.com/a.png', dm), isFalse);
      expect(loads('https://catbox.moe/a.png', dm), isFalse);
      expect(loads('https://mediax.giphy.com/a.gif', dm), isFalse);
    });
  });

  group('old setting', () {
    test('mapping', () {
      expect(ChatPrefs.imagesFromLegacy('never'), (false, false));
      expect(ChatPrefs.imagesFromLegacy('always'), (true, true));
      expect(ChatPrefs.imagesFromLegacy('torn'), (true, false));
      expect(ChatPrefs.imagesFromLegacy(null), (true, false));
    });

    test('migration on load', () async {
      Future<ChatPrefs> loaded() async {
        final prefs = ChatPrefs();
        addTearDown(prefs.dispose);
        await prefs.load();
        return prefs;
      }

      await PrefsDatabase.clearAll();
      var prefs = await loaded();
      expect((prefs.imagesPrivate, prefs.imagesPublic), (true, false));

      await PrefsDatabase.setString('pda_nativeChatImageAutoLoad', 'never');
      prefs = await loaded();
      expect((prefs.imagesPrivate, prefs.imagesPublic), (false, false));

      await PrefsDatabase.setString('pda_nativeChatImageAutoLoad', 'always');
      prefs = await loaded();
      expect((prefs.imagesPrivate, prefs.imagesPublic), (true, true));

      prefs
        ..setImagesPrivate(false)
        ..setImagesPublic(false);
      await Future<void>.delayed(Duration.zero);
      prefs = await loaded();
      expect((prefs.imagesPrivate, prefs.imagesPublic), (false, false));
    });
  });

  group('backups', () {
    String backup(Map<String, Object?> prefs) => jsonEncode({'version': 1, 'prefs': prefs});

    (bool, bool) restored(Map<String, Object?> prefs) {
      final target = ChatPrefs();
      addTearDown(target.dispose);
      target.applyBackup(ChatBackup.parse(backup(prefs)), replace: true);
      return (target.imagesPrivate, target.imagesPublic);
    }

    test('old copy', () {
      expect(restored({'imageAutoLoad': 'never'}), (false, false));
      expect(restored({'imageAutoLoad': 'always'}), (true, true));
      expect(restored({'imageAutoLoad': 'torn'}), (true, false));
    });

    test('unknown old value', () {
      expect(restored({'imageAutoLoad': 'sometimes'}), (true, false));
      expect(restored({}), (true, false));
    });

    test('new values win', () {
      expect(restored({'imageAutoLoad': 'never', 'imagesPrivate': true, 'imagesPublic': true}), (true, true));
    });

    test('new copy', () {
      final prefs = ChatPrefs()
        ..setImagesPrivate(false)
        ..setImagesPublic(true);
      addTearDown(prefs.dispose);
      final saved = (jsonDecode(ChatBackup.export(prefs, DateTime.utc(2026))) as Map)['prefs'] as Map;
      expect(saved['imagesPrivate'], false);
      expect(saved['imagesPublic'], true);
    });
  });
}
