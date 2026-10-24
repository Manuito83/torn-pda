import 'package:flutter/material.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatSettingsSubpage extends StatelessWidget {
  const ChatSettingsSubpage({super.key, required this.title, this.description, required this.builder});

  final String title;
  final String? description;
  final List<Widget> Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListenableBuilder(
        listenable: Listenable.merge([NativeChat.prefs, NativeChat.controller]),
        builder: (context, _) => ListView(
          padding: EdgeInsets.only(top: 6, bottom: 24 + MediaQuery.paddingOf(context).bottom),
          children: [if (description != null) ChatSettingsNote(description!), ...builder(context)],
        ),
      ),
    );
  }
}

class ChatSettingsLink extends StatelessWidget {
  const ChatSettingsLink({super.key, this.leading, required this.title, this.subtitle, this.page, this.onTap})
    : assert(page != null || onTap != null);

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? page;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap ?? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatTheme(child: page!))),
    );
  }
}

class ChatSettingsHeading extends StatelessWidget {
  const ChatSettingsHeading(this.title, {super.key, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatSettingsNote extends StatelessWidget {
  const ChatSettingsNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}
