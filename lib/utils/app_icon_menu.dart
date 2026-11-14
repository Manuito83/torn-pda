import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Chats without a title are left out
List<ShortcutItem> appIconMenuItems(List<String> slots, String? Function(String roomId) chatTitle) => [
  for (final (i, type) in slots.indexed)
    if (slots.indexOf(type) == i)
      if (AppIconMenuController.sections.where((s) => s.type == type).firstOrNull case final section?)
        section
      else if (type.startsWith(NativeChat.shortcutPrefix))
        if (chatTitle(type.substring(NativeChat.shortcutPrefix.length)) case final title?)
          ShortcutItem(type: type, localizedTitle: title, icon: 'action_torn'),
];

class AppIconMenuController extends GetxController {
  AppIconMenuController({Future<void> Function(List<ShortcutItem> items)? setItems})
    : _setItems = setItems ?? const QuickActions().setShortcutItems;

  static const List<ShortcutItem> sections = [
    ShortcutItem(type: 'open_torn', localizedTitle: 'Torn Home', icon: "action_torn"),
    ShortcutItem(type: 'open_gym', localizedTitle: 'Gym', icon: "action_gym"),
    ShortcutItem(type: 'open_crimes', localizedTitle: 'Crimes', icon: "action_crimes"),
    ShortcutItem(type: 'open_travel', localizedTitle: 'Travel', icon: "action_travel"),
  ];

  static const int size = 4;

  final Future<void> Function(List<ShortcutItem> items) _setItems;

  /// Shortcut types, empty for none
  final ValueNotifier<List<String>> slots = ValueNotifier([for (final s in sections) s.type]);

  Future<void>? _loaded;

  Future<void> load() => _loaded ??= Prefs()
      .getAppIconMenu()
      .then((saved) {
        if (saved.length == size) slots.value = saved;
      })
      .catchError((_) {});

  Future<void> publish() async {
    await load();
    final list = appIconMenuItems(slots.value, NativeChat.shortcutTitle);
    // Titles for the next cold start
    if (NativeChat.usable) {
      NativeChat.prefs.setShortcutCache([
        for (final item in list)
          if (item.type.startsWith(NativeChat.shortcutPrefix))
            '${item.type.substring(NativeChat.shortcutPrefix.length)}|${item.localizedTitle}',
      ]);
    }
    try {
      await _setItems(list);
    } catch (_) {
      // Platforms without app icon shortcuts
    }
  }

  Future<void> setSlots(List<String> value) async {
    await load();
    slots.value = List.of(value);
    await Prefs().setAppIconMenu(slots.value);
    await publish();
  }

  Future<void> setSlot(int index, String type) async {
    await load();
    await setSlots([...slots.value]..[index] = type);
  }
}
