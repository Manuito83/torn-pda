import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/pages/settings/app_icon_menu_page.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  final published = <List<String>>[];
  final titles = <String>[];

  setUp(() {
    published.clear();
    titles.clear();
    AppIconMenu.setItems = (items) async {
      published.add([for (final i in items) i.type]);
      titles.addAll(items.map((i) => i.localizedTitle));
    };
    NativeChat.prefs.inAppEnabled = true;
    NativeChat.keyValid.value = true;
    NativeChat.prefs.shortcutCache = [];
  });

  test('a change before the saved menu loads builds on it', () async {
    await Prefs().setAppIconMenu(['open_travel', '', 'chat:dm:7', 'open_torn']);
    NativeChat.prefs.shortcutCache = ['dm:7|Bravo'];
    await Future.wait([AppIconMenu.publish(), AppIconMenu.setSlot(1, 'open_gym')]);
    expect(AppIconMenu.slots.value, ['open_travel', 'open_gym', 'chat:dm:7', 'open_torn']);
    expect(published.first, ['open_travel', 'chat:dm:7', 'open_torn']);
    expect(published.last, ['open_travel', 'open_gym', 'chat:dm:7', 'open_torn']);
    expect(titles.take(3), ['Travel', 'Bravo', 'Torn Home']);
  });

  test('only sections and chats with a title make it to the menu', () {
    final names = {'faction': 'Faction', 'dm:7': 'Bravo'};
    final items = AppIconMenu.items(['chat:dm:7', '', 'open_gym', 'chat:company', 'open_old'], (id) => names[id]);
    expect([for (final i in items) (i.type, i.localizedTitle)], [('chat:dm:7', 'Bravo'), ('open_gym', 'Gym')]);

    final twice = AppIconMenu.items(['open_gym', 'chat:dm:7', 'open_gym', 'chat:dm:7'], (id) => names[id]);
    expect(twice.map((i) => i.type), ['open_gym', 'chat:dm:7']);
  });

  test('a chat has a title only while the chat can open it', () {
    expect(NativeChat.shortcutTitle('faction'), 'Faction');
    expect(NativeChat.shortcutTitle('dm:7'), isNull);
    NativeChat.prefs.shortcutCache = ['dm:7|Bravo'];
    expect(NativeChat.shortcutTitle('dm:7'), 'Bravo');

    NativeChat.prefs.setRoomState('faction', ChatRoomState.hidden);
    addTearDown(() => NativeChat.prefs.setRoomState('faction', ChatRoomState.live));
    expect(NativeChat.shortcutTitle('faction'), isNull);

    NativeChat.keyValid.value = false;
    expect(NativeChat.shortcutTitle('dm:7'), isNull);
    NativeChat.keyValid.value = true;
    NativeChat.prefs.inAppEnabled = false;
    expect(NativeChat.shortcutTitle('dm:7'), isNull);
  });

  test('changing a slot publishes again and keeps the chat title for a cold start', () async {
    await AppIconMenu.setSlots([for (final s in AppIconMenu.sections) s.type]);
    await AppIconMenu.setSlot(1, 'chat:faction');
    expect(published.last, ['open_torn', 'chat:faction', 'open_crimes', 'open_travel']);
    expect(await Prefs().getAppIconMenu(), ['open_torn', 'chat:faction', 'open_crimes', 'open_travel']);
    expect(NativeChat.prefs.shortcutCache, ['faction|Faction']);

    NativeChat.keyValid.value = false;
    await AppIconMenu.setSlot(3, '');
    expect(published.last, ['open_torn', 'open_crimes']);
    expect(NativeChat.prefs.shortcutCache, ['faction|Faction']);
  });
}
