import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

class ChatFactionEventsFold extends StatefulWidget {
  const ChatFactionEventsFold({super.key, required this.events});

  final List<ChatMessage> events;

  @override
  State<ChatFactionEventsFold> createState() => _ChatFactionEventsFoldState();
}

class _ChatFactionEventsFoldState extends State<ChatFactionEventsFold> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = widget.events.length;
    final label = count == 1 ? '1 faction event' : '$count faction events';
    final style = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
      child: Center(
        child: Container(
          decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                expanded: _open,
                label: label,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _open = !_open),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_outlined, size: 18, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(label, style: style),
                          Icon(
                            _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_open)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final e in widget.events)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${DateFormat.Hm().format(e.createdAt)}  ${e.content}', style: style),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Only you see this',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatFactionEventsSetting extends StatelessWidget {
  const ChatFactionEventsSetting({super.key, required this.prefs});

  final ChatPrefs prefs;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Faction events in chat'),
      subtitle: Text(
        prefs.factionEventsDenied
            ? 'Your API key cannot read faction news. Give it faction access, then turn this on again'
            : 'Joins, leaves, chain and war news in the faction chat, grouped in one line. Needs faction API access',
      ),
      value: prefs.factionEvents,
      onChanged: prefs.setFactionEvents,
    );
  }
}
