import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class AppIconMenu {
  AppIconMenu._();

  static const List<ShortcutItem> sections = [
    ShortcutItem(type: 'open_torn', localizedTitle: 'Torn Home', icon: "action_torn"),
    ShortcutItem(type: 'open_gym', localizedTitle: 'Gym', icon: "action_gym"),
    ShortcutItem(type: 'open_crimes', localizedTitle: 'Crimes', icon: "action_crimes"),
    ShortcutItem(type: 'open_travel', localizedTitle: 'Travel', icon: "action_travel"),
  ];

  static const int size = 4;

  /// Shortcut types, empty for none
  static final ValueNotifier<List<String>> slots = ValueNotifier([for (final s in sections) s.type]);

  static Future<void>? _loaded;

  @visibleForTesting
  static Future<void> Function(List<ShortcutItem> items) setItems = const QuickActions().setShortcutItems;

  /// Chats without a title are left out
  static List<ShortcutItem> items(List<String> slots, String? Function(String roomId) chatTitle) => [
    for (final (i, type) in slots.indexed)
      if (slots.indexOf(type) == i)
        if (sections.where((s) => s.type == type).firstOrNull case final section?)
          section
        else if (type.startsWith(NativeChat.shortcutPrefix))
          if (chatTitle(type.substring(NativeChat.shortcutPrefix.length)) case final title?)
            ShortcutItem(type: type, localizedTitle: title, icon: 'action_torn'),
  ];

  static Future<void> load() => _loaded ??= Prefs()
      .getAppIconMenu()
      .then((saved) {
        if (saved.length == size) slots.value = saved;
      })
      .catchError((_) {});

  static Future<void> publish() async {
    await load();
    final list = items(slots.value, NativeChat.shortcutTitle);
    // Titles for the next cold start
    if (NativeChat.usable) {
      NativeChat.prefs.setShortcutCache([
        for (final item in list)
          if (item.type.startsWith(NativeChat.shortcutPrefix))
            '${item.type.substring(NativeChat.shortcutPrefix.length)}|${item.localizedTitle}',
      ]);
    }
    try {
      await setItems(list);
    } catch (_) {}
  }

  static Future<void> setSlots(List<String> value) async {
    await load();
    slots.value = List.of(value);
    await Prefs().setAppIconMenu(slots.value);
    await publish();
  }

  static Future<void> setSlot(int index, String type) async {
    await load();
    await setSlots([...slots.value]..[index] = type);
  }
}

class AppIconMenuPage extends StatelessWidget {
  const AppIconMenuPage({super.key});

  Future<void> _pick(BuildContext context, int index) async {
    final slots = AppIconMenu.slots.value;
    final current = slots[index];
    final rooms = NativeChat.usable
        ? NativeChat.controller.conversations.where((r) => !NativeChat.prefs.hiddenRooms.contains(r.id)).toList()
        : const [];
    Widget option(String type, String title) {
      final taken = type.isNotEmpty && type != current && slots.contains(type);
      return ListTile(
        title: Text(title),
        subtitle: taken ? Text('Already in slot ${slots.indexOf(type) + 1}') : null,
        enabled: !taken,
        trailing: type == current ? const Icon(Icons.check_rounded) : null,
        onTap: () => Navigator.of(context).pop(type),
      );
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final section in AppIconMenu.sections) option(section.type, section.localizedTitle),
            if (rooms.isNotEmpty) ...[
              const Divider(),
              ListTile(dense: true, title: Text('Chats', style: Theme.of(context).textTheme.labelLarge)),
              for (final room in rooms) option(NativeChat.shortcutPrefix + room.id, room.name),
            ],
            const Divider(),
            option('', 'Empty'),
          ],
        ),
      ),
    );
    if (picked != null && picked != current) AppIconMenu.setSlot(index, picked);
  }

  Widget _slot(BuildContext context, int index, String type) {
    final chat = type.startsWith(NativeChat.shortcutPrefix);
    final title = chat
        ? NativeChat.shortcutTitle(type.substring(NativeChat.shortcutPrefix.length))
        : AppIconMenu.sections.where((s) => s.type == type).firstOrNull?.localizedTitle;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(radius: 14, child: Text('${index + 1}')),
        title: Text(title ?? (chat ? 'Chat not available' : 'Empty')),
        subtitle: chat ? Text(title == null ? 'Tap to pick another one' : 'Chat') : null,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _pick(context, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App icon menu')),
      body: FutureBuilder(
        future: AppIconMenu.load(),
        builder: (context, loaded) => loaded.connectionState != ConnectionState.done
            ? const Center(child: CircularProgressIndicator())
            : ListenableBuilder(
                listenable: Listenable.merge([
                  AppIconMenu.slots,
                  NativeChat.controller,
                  NativeChat.prefs,
                  NativeChat.keyValid,
                ]),
                builder: (context, _) {
                  final slots = AppIconMenu.slots.value;
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('Long press the Torn PDA icon on your home screen to jump to these'),
                      ),
                      for (var i = 0; i < slots.length; i++) _slot(context, i, slots[i]),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
