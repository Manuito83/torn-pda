import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatTestingSettingsPage extends StatefulWidget {
  const ChatTestingSettingsPage({super.key});

  @override
  State<ChatTestingSettingsPage> createState() => _ChatTestingSettingsPageState();
}

class _ChatTestingSettingsPageState extends State<ChatTestingSettingsPage> {
  final ChatFactionOps _ops = NativeChat.factionOps;
  late final _hits = TextEditingController(text: '${_ops.testChain.hits}');
  late final _max = TextEditingController(text: '${_ops.testChain.bonus ?? 0}');
  late final _seconds = TextEditingController(text: '${_ops.testChain.seconds}');

  bool get _on => _ops.simulated.value != null;

  @override
  void dispose() {
    _hits.dispose();
    _max.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _edit({bool? cooldown, bool? live}) {
    int read(TextEditingController c) => int.tryParse(c.text) ?? 0;
    final max = read(_max);
    final chain = _ops.testChain = ChatChain(
      hits: read(_hits),
      seconds: read(_seconds),
      cooldown: cooldown ?? _ops.testChain.cooldown,
      bonus: max > 0 ? max : null,
    );
    _ops.simulatedLive = live ?? _ops.simulatedLive;
    if (_on) _ops.simulate(chain, live: _ops.simulatedLive);
    setState(() {});
  }

  void _toggle(bool on) {
    _ops.simulate(on ? _ops.testChain : null, live: _ops.simulatedLive);
    setState(() {});
  }

  Future<void> _pickRoom() async {
    final prefs = NativeChat.prefs;
    final dms = NativeChat.controller.conversations.where((r) => r.isDm).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Test faction room'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, ''), child: const Text('Off')),
          for (final dm in dms)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, dm.id),
              child: Text(
                dm.name,
                style: dm.id == prefs.testFactionRoom ? const TextStyle(fontWeight: FontWeight.w700) : null,
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    prefs.setTestFactionRoom(picked.isEmpty ? null : picked);
  }

  Widget _number(String label, TextEditingController controller) => Expanded(
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      onChanged: (_) => _edit(),
      decoration: InputDecoration(isDense: true, labelText: label, border: const OutlineInputBorder()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Testing',
      description: 'Nothing here is saved or backed up',
      builder: (context) {
        final prefs = NativeChat.prefs;
        final room = prefs.testFactionRoom;
        return [
          ListTile(
            title: const Text('Test faction room'),
            subtitle: Text(
              room == null
                  ? 'Off - pick a private chat to act as a second faction room'
                  : NativeChat.controller.roomById(room).name,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _pickRoom,
          ),
          SwitchListTile(
            title: const Text('Simulate chain'),
            subtitle: const Text('Only the chat sees it, never the chain widget or alerts. Off when the app closes'),
            value: _on,
            onChanged: _toggle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              spacing: 8,
              children: [_number('Hits', _hits), _number('Max', _max), _number('Seconds', _seconds)],
            ),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Cooldown'),
            value: _ops.testChain.cooldown,
            onChanged: (on) => _edit(cooldown: on),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Live'),
            value: _ops.simulatedLive,
            onChanged: (on) => _edit(live: on),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Take watch here turns on your real Chain Watcher',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ];
      },
    );
  }
}
