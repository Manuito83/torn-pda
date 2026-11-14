import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/utils/app_icon_menu.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class AppIconMenuPage extends StatelessWidget {
  const AppIconMenuPage({super.key});

  Future<void> _pick(BuildContext context, int index) async {
    final menu = Get.find<AppIconMenuController>();
    final slots = menu.slots.value;
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
            for (final section in AppIconMenuController.sections) option(section.type, section.localizedTitle),
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
    if (picked != null && picked != current) menu.setSlot(index, picked);
  }

  Widget _slot(BuildContext context, int index, String type) {
    final chat = type.startsWith(NativeChat.shortcutPrefix);
    final title = chat
        ? NativeChat.shortcutTitle(type.substring(NativeChat.shortcutPrefix.length))
        : AppIconMenuController.sections.where((s) => s.type == type).firstOrNull?.localizedTitle;
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
    final menu = Get.find<AppIconMenuController>();
    return Scaffold(
      appBar: AppBar(title: const Text('App icon menu')),
      body: FutureBuilder(
        future: menu.load(),
        builder: (context, loaded) => loaded.connectionState != ConnectionState.done
            ? const Center(child: CircularProgressIndicator())
            : ListenableBuilder(
                listenable: Listenable.merge([
                  menu.slots,
                  NativeChat.controller,
                  NativeChat.prefs,
                  NativeChat.keyValid,
                ]),
                builder: (context, _) {
                  final slots = menu.slots.value;
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
