import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:torn_pda/pages/chat/chat_settings_page.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatIconButton extends StatelessWidget {
  const ChatIconButton({
    super.key,
    required this.color,
    required this.hiddenInTab,
    required this.hiddenEverywhere,
    required this.onHideInTab,
    required this.onHideEverywhere,
    this.alwaysShown = true,
    this.tabUid,
  });

  final Color color;
  final bool hiddenInTab;
  final bool hiddenEverywhere;
  final ValueChanged<bool> onHideInTab;
  final ValueChanged<bool> onHideEverywhere;

  final bool alwaysShown;

  /// Browser tab that holds the icon
  final String? tabUid;

  static bool get _isLauncher => NativeChat.usable && NativeChat.prefs.launcher == ChatLauncher.browser;

  static final Listenable _changes = Listenable.merge([
    NativeChat.remoteEnabled,
    NativeChat.keyValid,
    NativeChat.controller,
    NativeChat.prefs,
  ]);

  void _onTap(BuildContext context) {
    if (NativeChat.prefs.inAppEnabled) {
      StatsController.chat.count('open_big_window');
      NativeChat.openBigWindow(side: tabUid == null ? null : NativeChat.splitSideOfTab(tabUid!));
    } else {
      _showChatIconMenu(context, this);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _changes,
    builder: (context, _) {
      final launcher = _isLauncher;
      if (!alwaysShown && !launcher) return const SizedBox.shrink();
      final counts = launcher
          ? NativeChat.prefs.bubbleCounts(NativeChat.controller.unreadGroups())
          : const <String, int>{};
      final unread = counts.values.fold(0, (a, b) => a + b);
      final brightness = Theme.of(context).brightness;
      final struck = hiddenInTab && !NativeChat.prefs.inAppEnabled;
      Widget icon = Icon(struck ? Icons.comments_disabled_outlined : Icons.chat_bubble_outline_rounded, color: color);
      if (unread > 0) {
        icon = Badge.count(
          count: unread,
          maxCount: 99,
          backgroundColor: Colors.red[400],
          textColor: Colors.white,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              icon,
              if (!NativeChat.prefs.bubbleTotal)
                Positioned(
                  right: -4,
                  bottom: -3,
                  child: Row(
                    spacing: 2,
                    children: [
                      for (final group in ChatPrefs.bubbleOptions)
                        if ((counts[group] ?? 0) > 0)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: chatGroupColors(group, brightness).$1,
                              shape: BoxShape.circle,
                            ),
                          ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }
      return Semantics(
        container: true,
        button: true,
        label: [
          'Chat',
          if (unread > 0) '$unread unread',
          if (hiddenInTab) 'Torn\'s chat hidden in this tab',
        ].join(', '),
        onTap: () => _onTap(context),
        onTapHint: NativeChat.prefs.inAppEnabled ? 'open the chat window' : 'open the chat menu',
        onLongPress: () => _showChatIconMenu(context, this),
        onLongPressHint: 'open the chat menu',
        customSemanticsActions: {
          CustomSemanticsAction(
            label: hiddenInTab ? 'Show Torn\'s chat in this tab' : 'Hide Torn\'s chat in this tab',
          ): () =>
              onHideInTab(!hiddenInTab),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: () => _onTap(context),
          onDoubleTap: () => onHideInTab(!hiddenInTab),
          onLongPress: () => _showChatIconMenu(context, this),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: icon),
        ),
      );
    },
  );
}

Future<void> _showChatIconMenu(BuildContext context, ChatIconButton icon) {
  final navigator = Navigator.of(context);
  return showModalBottomSheet(
    context: NativeChat.sheetsContext ?? context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: NativeChat.prefs,
      builder: (context, _) {
        final theme = Theme.of(context);
        final inApp = NativeChat.prefs.inAppEnabled;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.forum_rounded),
                title: const Text('In-app chat'),
                subtitle: inApp ? null : const Text('Off, only Torn\'s own chat is used'),
                value: inApp,
                onChanged: NativeChat.setEnabled,
              ),
              if (inApp)
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: const Text('Open the full chat'),
                  onTap: () {
                    Navigator.pop(context);
                    StatsController.chat.count('open_browser');
                    NativeChat.open(navigator);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Chat settings'),
                onTap: () {
                  Navigator.pop(context);
                  showChatSettings(navigator);
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('Torn\'s chat', style: theme.textTheme.titleSmall),
              ),
              ListTile(
                leading: Icon(icon.hiddenInTab ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                title: Text(icon.hiddenInTab ? 'Show chat in this tab' : 'Hide chat in this tab'),
                onTap: () {
                  Navigator.pop(context);
                  icon.onHideInTab(!icon.hiddenInTab);
                },
              ),
              ListTile(
                leading: Icon(icon.hiddenEverywhere ? Icons.layers_rounded : Icons.layers_clear_rounded),
                title: Text(icon.hiddenEverywhere ? 'Show chat in every tab' : 'Hide chat in every tab'),
                subtitle: const Text('Torn\'s chat is not loaded at all while hidden'),
                onTap: () {
                  Navigator.pop(context);
                  icon.onHideEverywhere(!icon.hiddenEverywhere);
                },
              ),
              const Divider(),
              _GestureLegend(inApp: inApp),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ),
  );
}

class _GestureLegend extends StatelessWidget {
  const _GestureLegend({required this.inApp});

  final bool inApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final gestures = [
      ('Tap', inApp ? 'Open the chat window' : 'Open this menu'),
      ('Double tap', 'Hide or show Torn\'s chat in this tab'),
      ('Long press', 'Open this menu'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chat icon gestures', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final (gesture, action) in gestures)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(gesture, style: muted?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Expanded(child: Text(action, style: muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
