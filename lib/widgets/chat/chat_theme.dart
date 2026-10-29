import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

// Torn PDA palette for the chat
class ChatTheme extends StatelessWidget {
  const ChatTheme({super.key, required this.child, this.touch = true});

  final Widget child;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra =
        theme.brightness == Brightness.dark && context.watch<ThemeProvider?>()?.currentTheme == AppTheme.extraDark;
    final themed = Theme(
      data: theme.brightness == Brightness.dark ? chatDarkTheme(theme, extra: extra) : _chatLightTheme(theme),
      child: child,
    );
    if (!touch) return themed;
    return ChatTaps(behavior: HitTestBehavior.translucent, child: themed);
  }
}

/// Taps touch the chat, drags never do
class ChatTaps extends StatefulWidget {
  const ChatTaps({super.key, required this.child, this.onDown, this.behavior = HitTestBehavior.deferToChild});

  final Widget child;
  final VoidCallback? onDown;
  final HitTestBehavior behavior;

  @override
  State<ChatTaps> createState() => _ChatTapsState();
}

class _ChatTapsState extends State<ChatTaps> {
  final Map<int, Offset> _down = {};

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: widget.behavior,
      onPointerDown: (e) {
        _down[e.pointer] = e.position;
        widget.onDown?.call();
      },
      onPointerUp: (e) {
        final start = _down.remove(e.pointer);
        if (start != null && (e.position - start).distance < kTouchSlop) NativeChat.touch();
      },
      onPointerCancel: (e) => _down.remove(e.pointer),
      child: widget.child,
    );
  }
}

// Same as Torn PDA settings
final _chatSwitchTheme = SwitchThemeData(
  thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.green : null),
  trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.lightGreenAccent : null),
);

WidgetStateProperty<Color?> _whenSelected(Color color) =>
    WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? color : null);

ThemeData _chatLightTheme(ThemeData base) {
  final strong = Colors.blueGrey[700]!;
  final text = base.colorScheme.onSurface;
  final segmentText = WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return text.withValues(alpha: 0.38);
    return states.contains(WidgetState.selected) ? Colors.white : text;
  });
  return _readableButtons(
    base.copyWith(
      switchTheme: _chatSwitchTheme,
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: _whenSelected(strong),
          foregroundColor: segmentText,
          iconColor: segmentText,
        ),
      ),
    ),
    strong,
  );
}

ThemeData _readableButtons(ThemeData theme, Color color) {
  final text = theme.textButtonTheme.style;
  final outlined = theme.outlinedButtonTheme.style;
  return theme.copyWith(
    textButtonTheme: text?.foregroundColor != null
        ? null
        : TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: color).merge(text)),
    outlinedButtonTheme: outlined?.foregroundColor != null
        ? null
        : OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: color).merge(outlined)),
  );
}

// Same tones as ThemeProvider
ThemeData chatDarkTheme(ThemeData base, {required bool extra}) {
  final accent = Colors.blueGrey[300]!;
  final canvas = extra ? Colors.black : Colors.grey[900]!;
  final second = extra ? const Color(0xFF0C0C0C) : Colors.grey[800]!;
  final card = extra ? const Color(0xFF0E0E0E) : Colors.grey[800]!;
  final bubble = extra ? Colors.grey[900]! : Colors.grey[800]!;
  final selected = extra ? Colors.blueGrey[800]! : Colors.blueGrey[600]!;
  final dark = base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      secondary: accent,
      onSecondary: Colors.black,
      secondaryContainer: accent,
      onSecondaryContainer: Colors.black,
      tertiary: accent,
      onTertiary: Colors.black,
      tertiaryContainer: selected,
      onTertiaryContainer: Colors.white,
      primaryContainer: extra ? selected : null,
      onPrimaryContainer: extra ? Colors.white : null,
      surface: card,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: second,
      surfaceContainer: card,
      surfaceContainerHigh: bubble,
      surfaceContainerHighest: bubble,
    ),
    scaffoldBackgroundColor: canvas,
    canvasColor: canvas,
    cardColor: card,
    dialogTheme: base.dialogTheme.copyWith(backgroundColor: second),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(backgroundColor: canvas, modalBackgroundColor: canvas),
    switchTheme: _chatSwitchTheme,
    checkboxTheme: CheckboxThemeData(
      fillColor: _whenSelected(accent),
      checkColor: const WidgetStatePropertyAll(Colors.black),
    ),
    radioTheme: RadioThemeData(fillColor: _whenSelected(accent)),
    progressIndicatorTheme: base.progressIndicatorTheme.copyWith(color: accent),
    tabBarTheme: base.tabBarTheme.copyWith(indicatorColor: accent),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: selected,
      foregroundColor: Colors.white,
    ),
  );
  return _readableButtons(dark, Colors.blueGrey[200]!);
}
