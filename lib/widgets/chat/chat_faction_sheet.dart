import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_faction_roster.dart';
import 'package:torn_pda/models/chat/chat_link_info.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/widgets/chat/chat_faction_roster_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

Future<void> showChatFactionSheet(BuildContext context, ChatLink link) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
  builder: (_) => _FactionSheet(link: link, parent: context),
);

class _FactionSheet extends StatefulWidget {
  const _FactionSheet({required this.link, required this.parent});

  final ChatLink link;
  final BuildContext parent;

  @override
  State<_FactionSheet> createState() => _FactionSheetState();
}

class _FactionSheetState extends State<_FactionSheet> {
  late final Future<ChatFactionFacts?> _facts = _loadFacts();
  late final Future<List<FactionMember>?> _members = _loadMembers();
  late final bool _own = widget.link.id == ChatLink.ownFaction;
  late final ChatFactionRoster _roster = _own
      ? ChatFactionRoster.shared
      : ChatFactionRoster(fetchMembers: () => ChatFactionRoster.membersOf(widget.link.id!, fresh: true));

  Future<ChatFactionFacts?> _loadFacts() async {
    try {
      final json = await ChatLinkPreviews.fetchFaction(widget.link.id!).timeout(const Duration(seconds: 20));
      return json == null ? null : ChatLinkInfo.factionFacts(json);
    } catch (_) {
      return null;
    }
  }

  Future<List<FactionMember>?> _loadMembers() async {
    try {
      final recent = _own ? ChatFactionRoster.shared.recentMembers() : null;
      if (recent != null) return recent;
      final members = await ChatFactionRoster.membersOf(widget.link.id!).timeout(const Duration(seconds: 20));
      if (members != null && mounted) _roster.setMembers(members);
      return members;
    } catch (_) {
      return null;
    }
  }

  void _player(int id, String name) {
    Navigator.of(context).pop();
    if (widget.parent.mounted) showChatPlayerActions(widget.parent, ChatUser(id: id, name: name));
  }

  Widget _leaderTile(String role, IconData icon, int id, List<FactionMember>? members) {
    final name = members?.where((m) => m.id == id).firstOrNull?.name;
    return ListTile(
      leading: Icon(icon),
      title: Text(name == null ? role : '$role: $name'),
      subtitle: Text('[$id]'),
      onTap: () => _player(id, name ?? 'Player'),
    );
  }

  Widget _membersTile(List<FactionMember> members) {
    return ListTile(
      leading: const Icon(Icons.groups_rounded),
      title: Text('Members (${members.length})'),
      subtitle: const Text('Status, filters and sorting'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showChatFactionMembers(context, prefs: NativeChat.prefs, roster: _roster),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: FutureBuilder<ChatFactionFacts?>(
          future: _facts,
          builder: (context, snapshot) {
            final facts = snapshot.data;
            final loading = snapshot.connectionState != ConnectionState.done;
            final id = facts?.id ?? widget.link.id!;
            return FutureBuilder<List<FactionMember>?>(
              future: _members,
              builder: (context, membersSnapshot) {
                final members = membersSnapshot.data;
                final membersLoading = membersSnapshot.connectionState != ConnectionState.done;
                final counts = members == null ? const <({String label, int count})>[] : chatRosterCounts(members);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.shield_rounded),
                      title: Text(facts?.title ?? widget.link.title),
                      subtitle: Text(
                        loading
                            ? 'Loading'
                            : facts == null
                            ? "Couldn't load the faction"
                            : '[$id]',
                      ),
                      trailing: loading
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : facts == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              tooltip: 'Copy ID',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: '$id'));
                                chatToast('ID copied', seconds: 1);
                              },
                            ),
                    ),
                    if (facts != null) ...[
                      for (final line in [
                        ...facts.lines,
                        if (counts.isNotEmpty) counts.map((c) => '${c.count} ${c.label}').join(' - '),
                      ])
                        Padding(
                          padding: const EdgeInsets.fromLTRB(72, 0, 16, 6),
                          child: Text(line, style: theme.textTheme.bodyMedium),
                        ),
                      if (facts.leader case final leader?) _leaderTile('Leader', Icons.person_rounded, leader, members),
                      if (facts.coLeader case final coLeader?)
                        _leaderTile('Co-leader', Icons.person_outline_rounded, coLeader, members),
                      if (members != null && members.isNotEmpty)
                        _membersTile(members)
                      else if (membersLoading)
                        const ListTile(
                          leading: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          title: Text('Loading members'),
                        )
                      else
                        const ListTile(leading: Icon(Icons.groups_rounded), title: Text("Couldn't load the members")),
                    ],
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.open_in_new_rounded),
                      title: const Text('Open faction page'),
                      onTap: () {
                        Navigator.of(context).pop();
                        NativeChat.openLink(widget.link.url, always: true);
                      },
                      onLongPress: () {
                        Navigator.of(context).pop();
                        NativeChat.openUrl(widget.link.url, tap: BrowserTapType.long);
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
