import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_help.dart';
import 'package:torn_pda/widgets/chat/chat_logo_bubble.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Once, unless [always]
Future<void> showChatIntro(BuildContext context, {bool always = false}) async {
  if (!always) {
    if (NativeChat.prefs.introSeen) return;
    NativeChat.prefs.setIntroSeen(true);
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ChatIntro(welcome: !always),
  );
}

class ChatHideWebChatTile extends StatelessWidget {
  const ChatHideWebChatTile({super.key, required this.title, this.contentPadding});

  final String title;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final WebViewProvider web;
    try {
      web = context.read<WebViewProvider>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: web,
      builder: (context, _) => SwitchListTile(
        title: Text(title),
        subtitle: const Text('In all tabs. Each tab\'s chat icon can still bring it back'),
        contentPadding: contentPadding,
        value: web.chatRemovalActiveGlobal,
        onChanged: web.setChatHiddenEverywhere,
      ),
    );
  }
}

class _ChatIntro extends StatelessWidget {
  const _ChatIntro({required this.welcome});

  final bool welcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    Widget entry(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: scheme.secondaryContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(text, style: small),
              ],
            ),
          ),
        ],
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('In-app chat', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Read and write Torn chat without its panel', style: small),
          const SizedBox(height: 2),
          Text('It needs a Torn page open in the browser', style: small),
          const SizedBox(height: 18),
          if (welcome)
            for (final e in chatHelp.where((e) => e.spots.contains(ChatHelpSpot.intro))) entry(e.icon, e.title, e.text)
          else
            for (final group in ChatHelpGroup.values)
              ExpansionTile(
                title: Text(group.title, style: theme.textTheme.titleMedium),
                initiallyExpanded: group == ChatHelpGroup.start,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 4),
                shape: const Border(),
                collapsedShape: const Border(),
                children: [for (final e in chatHelp.where((e) => e.group == group)) entry(e.icon, e.title, e.text)],
              ),
          if (welcome) ...[
            const ChatHideWebChatTile(title: 'Hide Torn\'s web chat in browser tabs', contentPadding: EdgeInsets.zero),
            ListenableBuilder(
              listenable: NativeChat.prefs,
              builder: (context, _) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Open the chat from', style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 6),
                        const ChatLauncherPicker(),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Ticker'),
                    subtitle: const Text('A line for each new message. Tap one to read it'),
                    contentPadding: EdgeInsets.zero,
                    value: NativeChat.prefs.ticker,
                    onChanged: NativeChat.prefs.setTicker,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
          ),
        ],
      ),
    );
  }
}
