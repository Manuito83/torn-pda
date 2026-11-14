import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_script_link.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/settings/userscripts_add_dialog.dart';

class ChatScriptCard extends StatelessWidget {
  const ChatScriptCard({super.key, required this.link, required this.color});

  final ChatLink link;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final script = ChatScriptLink.of(link)!;
    final scriptsContext = NativeChat.navigatorKey?.currentContext;
    final provider = scriptsContext == null ? null : Provider.of<UserScriptsProvider>(scriptsContext, listen: false);
    return ListenableBuilder(
      listenable: provider ?? Listenable.merge(const []),
      builder: (context, _) {
        final installed = provider != null && script.installedIn(provider.userScriptList.map((s) => s.url));
        return Material(
          color: color.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withValues(alpha: 0.18)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.code_rounded, size: 20, color: color.withValues(alpha: 0.85)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'USERSCRIPT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color.withValues(alpha: 0.65),
                              letterSpacing: 0.4,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            script.name ?? 'Userscript',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'From ${script.host}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!script.trusted)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Scripts can read your account. Only install from people you trust',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: installed
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 18, color: color.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text('Installed', style: theme.textTheme.bodyMedium?.copyWith(color: color)),
                          ],
                        )
                      : FilledButton.tonal(
                          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => UserScriptsAddDialog(
                              editingExistingScript: false,
                              defaultUrl: script.installUrl,
                              defaultPage: 1,
                            ),
                          ),
                          child: const Text('Install in PDA'),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
