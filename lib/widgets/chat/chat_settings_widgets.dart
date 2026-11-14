import 'package:flutter/material.dart';
import 'package:torn_pda/widgets/chat/chat_help.dart';

class ChatSettingsText extends StatelessWidget {
  const ChatSettingsText(this.text, {super.key, this.style}) : _hint = false;

  const ChatSettingsText.hint(this.text, {super.key}) : style = null, _hint = true;

  final String text;
  final TextStyle? style;
  final bool _hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final look = _hint ? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant) : style;
    return Semantics(container: true, child: Text(text, style: look));
  }
}

class ChatSettingsTile extends StatelessWidget {
  const ChatSettingsTile({super.key, required this.title, this.subtitle, required this.control});

  final String title;
  final String? subtitle;
  final Widget Function(bool below) control;

  @override
  Widget build(BuildContext context) {
    final text = subtitle == null ? null : Text(subtitle!);
    if (!chatLargeText(MediaQuery.textScalerOf(context))) {
      return ListTile(title: Text(title), subtitle: text, trailing: control(false));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(title: Text(title), subtitle: text),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: control(true)),
      ],
    );
  }
}
