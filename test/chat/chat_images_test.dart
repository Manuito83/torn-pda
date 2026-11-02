import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_inbox_snapshot.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_image_store.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';

import 'chat_fakes.dart';

// Two frames of 1x1
final _gif = Uint8List.fromList([
  ...'GIF89a'.codeUnits,
  1, 0, 1, 0, 0x80, 0, 0,
  0, 0, 0, 255, 255, 255,
  0x21, 0xF9, 4, 0, 10, 0, 0, 0, 0x2C, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 2, 0x44, 1, 0,
  0x21, 0xF9, 4, 0, 10, 0, 0, 0, 0x2C, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 2, 0x44, 1, 0,
  0x3B,
]);

Uint8List _bytes(int length) => Uint8List.fromList(List.filled(length, 7));

const _a = 'https://profileimages.torn.com/a.gif';
const _b = 'https://profileimages.torn.com/b.gif';

void main() {
  late Directory root;
  late List<String> fetched;
  late DateTime now;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('chat_images');
    fetched = [];
    now = DateTime(2026, 10, 29, 12);
  });

  tearDown(() => root.delete(recursive: true));

  ChatImageStore store({
    Map<String, Uint8List>? remote,
    int maxBytes = 1 << 20,
    int maxFileBytes = 1 << 20,
    int recentMax = 40,
  }) => ChatImageStore(
    locate: () async => root,
    fetch: (url, max) async {
      fetched.add(url);
      return remote?[url];
    },
    maxBytes: maxBytes,
    maxFileBytes: maxFileBytes,
    recentMax: recentMax,
    clock: () => now,
  );

  test('cached images survive a restart', () async {
    final remote = {_a: _bytes(100)};
    expect(await store(remote: remote).bytes(_a), remote[_a]);
    expect(await store(remote: remote).bytes(_a), remote[_a]);
    expect(await store(remote: remote).bytes(_a), remote[_a]);
    expect(fetched, [_a]);
  });

  test('a new URL downloads again', () async {
    final remote = {_a: _bytes(10), _b: _bytes(20)};
    final s = store(remote: remote);
    expect((await s.bytes(_a))!.length, 10);
    expect((await s.bytes(_b))!.length, 20);
    expect((await s.bytes(_a))!.length, 10);
    expect(fetched, [_a, _b]);
  });

  test('parallel requests for one image share a single download', () async {
    final s = store(remote: {_a: _bytes(10)});
    final all = await Future.wait([s.bytes(_a), s.bytes(_a), s.bytes(_a)]);
    expect(all.every((b) => b?.length == 10), isTrue);
    expect(fetched.length, 1);
  });

  test('a failed download is not stored and is retried after the wait', () async {
    final remote = <String, Uint8List>{};
    final s = store(remote: remote);
    expect(await s.bytes(_a), isNull);
    expect(await s.bytes(_a), isNull);
    expect(fetched.length, 1);
    expect(await s.has(_a), isFalse);

    remote[_a] = _bytes(10);
    now = now.add(const Duration(seconds: 61));
    expect((await s.bytes(_a))!.length, 10);
    expect(fetched.length, 2);
  });

  test('files over the limit and links that are not web are refused', () async {
    final s = store(remote: {_a: _bytes(500)}, maxFileBytes: 100);
    expect(await s.bytes(_a), isNull);
    expect(await s.has(_a), isFalse);
    expect(await s.bytes('file:///etc/hosts'), isNull);
    expect(await s.bytes(''), isNull);
    expect(fetched, [_a]);
  });

  test('over the size limit the least recently used go first', () async {
    const urls = ['https://x.torn.com/1', 'https://x.torn.com/2', 'https://x.torn.com/3', 'https://x.torn.com/4'];
    final remote = {for (final u in urls) u: _bytes(300)};
    final s = store(remote: remote, maxBytes: 1000);
    for (final u in urls.take(3)) {
      await s.bytes(u);
      now = now.add(const Duration(minutes: 1));
    }
    await store(remote: remote, maxBytes: 1000).bytes(urls[0]);
    now = now.add(const Duration(minutes: 1));
    await s.bytes(urls[3]);

    expect([for (final u in urls) await s.has(u)], [true, false, false, true]);
  });

  test('recent avatars keep order, cap and survive a restart', () async {
    final s = store(remote: {for (var i = 0; i < 5; i++) 'https://x.torn.com/$i': _bytes(5)}, recentMax: 3);
    for (var i = 0; i < 5; i++) {
      await s.remember('https://x.torn.com/$i');
    }
    await s.remember('https://x.torn.com/3');
    await s.remember('not a link');
    await s.flush();

    final expected = ['https://x.torn.com/3', 'https://x.torn.com/4', 'https://x.torn.com/2'];
    expect(await s.recent(), expected);
    expect(await store().recent(), expected);
  });

  test('clear empties files and recents', () async {
    final s = store(remote: {_a: _bytes(5)});
    await s.bytes(_a);
    await s.remember(_a);
    await s.clear();
    expect(await s.has(_a), isFalse);
    expect(await s.recent(), isEmpty);
  });

  test('a download in flight when the account is cleared is not saved', () async {
    final asked = Completer<void>();
    final answer = Completer<Uint8List?>();
    final s = ChatImageStore(
      locate: () async => root,
      fetch: (_, _) {
        asked.complete();
        return answer.future;
      },
    );
    final pending = s.bytes(_a);
    await asked.future;
    await s.clear();
    answer.complete(_bytes(10));
    await pending;
    expect(await s.has(_a), isFalse);
  });

  test('an image in flight when the account is forgotten does not land in memory', () async {
    addTearDown(ChatImages.forget);
    final answer = Completer<Uint8List?>();
    final pending = ChatImages.load(_a, download: (_, _) => answer.future);
    ChatImages.forget();
    expect(await ChatImages.load(_a, download: (_, _) async => _bytes(5)), hasLength(5));
    answer.complete(_bytes(10));
    await pending;
    expect(ChatImages.cached(_a), hasLength(5));
  });

  test('leftover temp files are swept when pruning', () async {
    final s = store(remote: {_a: _bytes(300), _b: _bytes(300)}, maxBytes: 500);
    await s.bytes(_a);
    final leftover = File('${root.path}/chat_images/orphan.img.tmp')..writeAsBytesSync(_bytes(5));
    await s.bytes(_b);
    expect(leftover.existsSync(), isFalse);
  });

  testWidgets('an animated image keeps all its frames', (tester) async {
    await tester.runAsync(() async {
      final provider = ChatImage(_a, store: store(remote: {_a: _gif}));
      final decoded = Completer<ui.Codec>();
      provider.loadImage(provider, (buffer, {getTargetSize}) async {
        final codec = await ui.instantiateImageCodecWithSize(buffer, getTargetSize: getTargetSize);
        decoded.complete(codec);
        return codec;
      });
      final codec = await decoded.future.timeout(const Duration(seconds: 5));
      expect(codec.frameCount, 2);
    });
  });

  group('faction', () {
    const rooms = [ChatRoom(id: 'faction', name: 'Faction'), ChatRoom(id: 'global', name: 'Global')];
    const emblem = 'https://factiontags.torn.com/1-2.png';

    ChatRoom factionIn(ChatController chat) => chat.rooms.firstWhere((r) => r.id == 'faction');

    test('emblem survives restart and room list', () {
      final saved = ChatInboxSnapshot(
        owner: 5,
        rooms: [rooms[0].withEmblem(emblem), rooms[1]],
        last: const {},
        unread: const {},
      );
      final restored = ChatInboxSnapshot.decode(saved.encode(), 5)!;
      expect(restored.rooms.first.emblemUrl, emblem);
      expect(ChatInboxSnapshot.decode(saved.encode(), 6), isNull);

      final source = FakeChatSource();
      final chat = ChatController(source, ChatPrefs())..restoreInbox(restored);
      addTearDown(chat.dispose);
      expect(factionIn(chat).emblemUrl, emblem);

      source
        ..emit(const ChatReadyEvent(5))
        ..emit(const ChatRoomsEvent(rooms));
      expect(factionIn(chat).emblemUrl, emblem);
    });

    test('a new URL replaces it and the same one changes nothing', () {
      final source = FakeChatSource();
      final chat = ChatController(source, ChatPrefs());
      addTearDown(chat.dispose);
      source
        ..emit(const ChatReadyEvent(5))
        ..emit(const ChatRoomsEvent(rooms));
      var notified = 0;
      chat.addListener(() => notified++);

      chat.setEmblem('faction', emblem);
      chat.setEmblem('faction', emblem);
      expect(notified, 1);

      chat.setEmblem('faction', 'https://factiontags.torn.com/1-3.png');
      expect(factionIn(chat).emblemUrl, endsWith('1-3.png'));
      chat.setEmblem('faction', null);
      expect(factionIn(chat).emblemUrl, isNull);
    });
  });
}
