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
      data: theme.brightness == Brightness.dark
          ? chatDarkTheme(theme, extra: extra)
          : theme.copyWith(switchTheme: _chatSwitchTheme),
      child: child,
    );
    if (!touch) return themed;
    return Listener(behavior: HitTestBehavior.translucent, onPointerDown: (_) => NativeChat.touch(), child: themed);
  }
}

// Same as Torn PDA settings
final _chatSwitchTheme = SwitchThemeData(
  thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.green : null),
  trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.lightGreenAccent : null),
);

// Same tones as ThemeProvider
ThemeData chatDarkTheme(ThemeData base, {required bool extra}) {
  final accent = Colors.blueGrey[300]!;
  final canvas = extra ? Colors.black : Colors.grey[900]!;
  final second = extra ? const Color(0xFF0C0C0C) : Colors.grey[800]!;
  final card = extra ? const Color(0xFF0E0E0E) : Colors.grey[800]!;
  final bubble = extra ? Colors.grey[900]! : Colors.grey[800]!;
  final selected = extra ? Colors.blueGrey[800]! : Colors.blueGrey[600]!;
  WidgetStateProperty<Color?> whenSelected(Color color) =>
      WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? color : null);
  return base.copyWith(
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
      fillColor: whenSelected(accent),
      checkColor: const WidgetStatePropertyAll(Colors.black),
    ),
    radioTheme: RadioThemeData(fillColor: whenSelected(accent)),
    progressIndicatorTheme: base.progressIndicatorTheme.copyWith(color: accent),
    tabBarTheme: base.tabBarTheme.copyWith(indicatorColor: accent),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: selected,
      foregroundColor: Colors.white,
    ),
  );
}
