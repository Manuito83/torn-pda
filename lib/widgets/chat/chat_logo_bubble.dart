import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/widgets/chat/chat_icon_menu.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Circle and tail as one outline
Path chatSpeechBubble(Offset center, double radius, Offset tip) {
  final distance = (tip - center).distance;
  if (distance <= radius * 1.1) return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  final toTip = (tip - center).direction;
  final half = math.acos(radius / distance) * 0.7;
  // Tangents meet here
  final elbow = center + Offset.fromDirection(toTip, radius / math.cos(half));
  final from = center + Offset.fromDirection(toTip - half, radius);
  return Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(elbow.dx, elbow.dy, tip.dx, tip.dy)
    ..quadraticBezierTo(
      elbow.dx,
      elbow.dy,
      center.dx + radius * math.cos(toTip + half),
      center.dy + radius * math.sin(toTip + half),
    )
    ..arcTo(Rect.fromCircle(center: center, radius: radius), toTip + half, 2 * math.pi - 2 * half, false)
    ..close();
}

void _openChat(BuildContext context) {
  final navigator = NativeChat.navigatorKey?.currentState ?? Navigator.of(context);
  Navigator.of(context).pop();
  StatsController.chat.count(NativeChat.prefs.launcher == ChatLauncher.menuBar ? 'open_menu_bar' : 'open_menu_header');
  NativeChat.launch(navigator);
}

void _showMenu(BuildContext context) => showChatLaunchMenu(context, onPick: Navigator.of(context).pop);

final Listenable _shownWhen = Listenable.merge([
  NativeChat.remoteEnabled,
  NativeChat.keyValid,
  NativeChat.controller,
  NativeChat.prefs,
]);

/// Drawer logo, bubble in the header option
class ChatLogoBubble extends StatelessWidget {
  const ChatLogoBubble({super.key});

  // Fractions of the logo side
  static const _mouth = Offset(0.52, 0.52);
  static const _center = Offset(0.8, 0.36);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = math.min(constraints.maxWidth, constraints.maxHeight);
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : side;
      final logo = Offset((width - side) / 2, 0);
      final head = (side * 0.38).clamp(36.0, 48.0).toDouble();
      return SizedBox(
        width: width,
        height: side,
        child: ListenableBuilder(
          listenable: _shownWhen,
          builder: (context, _) {
            final shown = NativeChat.usable && NativeChat.prefs.launcher == ChatLauncher.menuHeader;
            final groups = NativeChat.prefs.bubbleCounts(NativeChat.controller.unreadGroups());
            final unread = groups.values.fold(0, (a, b) => a + b);
            final arc = head + ChatUnreadArc.reach;
            final left = (logo.dx + _center.dx * side - head / 2).clamp(0.0, math.max(0.0, width - arc)).toDouble();
            final center = Offset(left + head / 2, _center.dy * side);
            void open() => _openChat(context);
            void menu() => _showMenu(context);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: logo.dx,
                  top: 0,
                  width: side,
                  height: side,
                  child: const Image(image: AssetImage('images/icons/torn_pda.png'), fit: BoxFit.fill),
                ),
                if (shown)
                  Positioned.fill(
                    child: ChatTheme(
                      touch: false,
                      child: Builder(
                        builder: (context) {
                          final scheme = Theme.of(context).colorScheme;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _SpeechBubblePainter(
                                      path: chatSpeechBubble(center, head / 2, logo + _mouth * side),
                                      color: scheme.tertiaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: left,
                                top: center.dy - head / 2 - ChatUnreadArc.padTop,
                                child: Semantics(
                                  container: true,
                                  button: true,
                                  excludeSemantics: true,
                                  label: unread == 0 ? 'Chat' : 'Chat, $unread unread',
                                  onTap: open,
                                  onLongPress: menu,
                                  child: ChatUnreadArc.bubble(
                                    iconSize: head,
                                    groups: groups,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: open,
                                      onLongPress: menu,
                                      child: Icon(Icons.forum_rounded, color: scheme.onTertiaryContainer),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    },
  );
}

class _SpeechBubblePainter extends CustomPainter {
  _SpeechBubblePainter({required this.path, required this.color});

  final Path path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SpeechBubblePainter old) => old.path != path || old.color != color;
}

/// Thin chat row in the drawer list
class ChatMenuBar extends StatelessWidget {
  const ChatMenuBar({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _shownWhen,
    builder: (context, _) {
      if (!NativeChat.usable || NativeChat.prefs.launcher != ChatLauncher.menuBar) return const SizedBox.shrink();
      final groups = NativeChat.prefs.bubbleCounts(NativeChat.controller.unreadGroups());
      final unread = groups.values.fold(0, (a, b) => a + b);
      return ChatTheme(
        touch: false,
        child: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Semantics(
                container: true,
                button: true,
                excludeSemantics: true,
                label: unread == 0 ? 'Chat' : 'Chat, $unread unread',
                onTap: () => _openChat(context),
                onLongPress: () => _showMenu(context),
                child: Material(
                  color: scheme.tertiaryContainer,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openChat(context),
                    onLongPress: () => _showMenu(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(Icons.forum_rounded, size: 18, color: scheme.onTertiaryContainer),
                          const SizedBox(width: 10),
                          Text(
                            'Chat',
                            style: TextStyle(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          ChatUnreadArc.bubble(
                            groups: groups,
                            row: true,
                            ringColor: scheme.tertiaryContainer,
                            child: const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

class ChatLauncherPicker extends StatelessWidget {
  const ChatLauncherPicker({super.key});

  // Four do not fit in one row
  static const _rows = [
    [(ChatLauncher.bubble, 'Bubble'), (ChatLauncher.browser, 'Browser')],
    [(ChatLauncher.menuHeader, 'Menu header'), (ChatLauncher.menuBar, 'Menu bar')],
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: NativeChat.prefs,
    builder: (context, _) => Column(
      spacing: 8,
      children: [
        for (final row in _rows)
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ChatLauncher>(
              showSelectedIcon: false,
              emptySelectionAllowed: true,
              style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4))),
              segments: [for (final (value, label) in row) ButtonSegment(value: value, label: Text(label))],
              selected: {NativeChat.prefs.launcher}.intersection({for (final (value, _) in row) value}),
              onSelectionChanged: (v) {
                if (v.isNotEmpty) NativeChat.prefs.setLauncher(v.first);
              },
            ),
          ),
      ],
    ),
  );
}
