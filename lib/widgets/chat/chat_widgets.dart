import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_format.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_mentions.dart';
import 'package:torn_pda/models/chat/chat_player_color.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/models/chat/chat_saved.dart';
import 'package:torn_pda/models/chat/chat_share.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/models/chat/chat_wiki.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_translate.dart';
import 'package:torn_pda/providers/chat/chat_typing_report.dart';
import 'package:torn_pda/widgets/chat/chat_appearance_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_bank_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_loading_phrases.dart';
import 'package:torn_pda/widgets/chat/chat_motion.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/chat_send_check_dialog.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_color_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_company_icons.dart';
import 'package:torn_pda/widgets/chat/chat_compose_tools.dart';
import 'package:torn_pda/widgets/chat/chat_faction_ops_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_price_check_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_wiki_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

final Map<String, ColorScheme> _userSchemes = {};

ColorScheme chatUserScheme(BuildContext context, int userId) {
  final brightness = Theme.of(context).brightness;
  return _userSchemes.putIfAbsent(
    '$userId-${brightness.name}',
    () => ColorScheme.fromSeed(
      seedColor: HSVColor.fromAHSV(1, (userId * 47) % 360, 0.6, 0.8).toColor(),
      brightness: brightness,
    ),
  );
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.user, this.size = 34});

  final ChatUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = chatUserScheme(context, user.id);
    final words = user.name.trim().split(RegExp(r'[\s_\-]+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isEmpty
        ? '?'
        : words.length == 1
        ? words.first.substring(0, words.first.length < 2 ? 1 : 2).toUpperCase()
        : '${words[0][0]}${words[1][0]}'.toUpperCase();
    final fallback = Container(
      alignment: Alignment.center,
      color: scheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: size * 0.36),
      ),
    );
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: user.avatarUrl == null
              ? fallback
              : Image.network(
                  user.avatarUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: (size * 3).round(),
                  errorBuilder: (_, _, _) => fallback,
                  frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : fallback,
                ),
        ),
      ),
    );
  }
}

Future<TimeOfDay?> showChatTimePicker(BuildContext context, TimeOfDay initial) => showTimePicker(
  context: context,
  initialTime: initial,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: !NativeChat.prefs.app12h),
    child: child!,
  ),
);

/// Screen reader time, words instead of "5m"
String _chatSpokenTime(DateTime at) {
  final gap = DateTime.now().difference(at);
  if (gap.inMinutes < 1) return 'just now';
  if (gap.inMinutes < 60) return gap.inMinutes == 1 ? '1 minute ago' : '${gap.inMinutes} minutes ago';
  if (gap.inHours < 24) return gap.inHours == 1 ? '1 hour ago' : '${gap.inHours} hours ago';
  return NativeChat.prefs.stamp(at);
}

final _entity = RegExp(r'&(#\d{1,7}|#x[0-9a-f]{1,6}|[a-z]{2,6});', caseSensitive: false);
const _entities = {'nbsp': ' ', 'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'hellip': '...'};

String _decodeEntities(String text) => text.replaceAllMapped(_entity, (m) {
  final name = m.group(1)!.toLowerCase();
  final code = name.startsWith('#x')
      ? int.tryParse(name.substring(2), radix: 16)
      : name.startsWith('#')
      ? int.tryParse(name.substring(1))
      : null;
  if (code != null) return code > 0 && code <= 0x10FFFF ? String.fromCharCode(code) : m.group(0)!;
  return _entities[name] ?? m.group(0)!;
});

String _spokenLink(ChatLink link) {
  final host = link.uri.host.replaceFirst(RegExp(r'^www\.'), '');
  if (link.isImage) return 'image from $host';
  if (link.label case final label?) return '$label link';
  return switch (link.kind) {
    ChatLinkKind.external => 'link to $host',
    ChatLinkKind.torn => 'Torn link',
    _ => 'link to ${link.title.replaceAll(RegExp(r'[\[\]]'), '')}',
  };
}

String chatSpokenText(String text) => [
  for (final part in ChatLink.split(ChatFormat.plain(_decodeEntities(text))))
    part is ChatLink ? _spokenLink(part) : part,
].join().replaceAll(RegExp(r'\s+'), ' ').trim();

Duration chatMotion(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

class ChatPopIn extends StatelessWidget {
  const ChatPopIn({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    excluding: !visible,
    child: IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        scale: visible ? 1 : 0,
        duration: chatMotion(context, const Duration(milliseconds: 180)),
        curve: Curves.easeOutBack,
        child: child,
      ),
    ),
  );
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    this.showSender = true,
    this.highlighted = false,
    this.highlightColor,
    this.searchTerm,
    this.searchCurrent = false,
    this.onLongPress,
    this.presence,
    this.saved = false,
    this.onQuoteTap,
    this.translation,
    this.onTranslationTap,
    this.onReply,
    this.onSwipeLeft,
    this.onForward,
    this.onRetry,
    this.pinned = false,
    this.selected,
  });

  final ChatMessage message;
  final bool isMine;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showSender;

  final bool highlighted;
  final Color? highlightColor;

  final String? searchTerm;
  final bool searchCurrent;

  /// Copies the text when null
  final VoidCallback? onLongPress;

  final ChatPresence? presence;

  final bool saved;

  final VoidCallback? onQuoteTap;

  final ChatTranslation? translation;
  final VoidCallback? onTranslationTap;

  final VoidCallback? onReply;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onForward;

  final VoidCallback? onRetry;
  final bool pinned;

  /// Null outside selection mode
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
            child: message.isLocal
                ? ChatLocalLine(message: message)
                : Text(
                    message.content,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
        ),
      );
    }

    final hasPlayer = message.sender.id > 0;
    final pending = message.state == ChatMessageState.pending;
    final failed = message.state == ChatMessageState.failed;
    final retry = failed ? (onRetry ?? () => NativeChat.controller.resend(message)) : null;
    final palette = chatPalette(context);
    final prefs = NativeChat.prefs;
    final compact = prefs.compactMode;
    final plain = compact && !highlighted;
    final plainText = ChatPlayerColor.contrast(scheme.onSurface, palette.background) >= 4.5
        ? scheme.onSurface
        : (ThemeData.estimateBrightnessForColor(palette.background) == Brightness.dark ? Colors.white : Colors.black);
    final background = plain
        ? palette.background
        : isMine
        ? palette.mineBubble
        : highlighted
        ? highlightColor ?? scheme.tertiaryContainer
        : palette.otherBubble;
    final foreground = plain
        ? plainText
        : isMine
        ? palette.mineText
        : highlighted
        ? highlightColor != null
              ? (ThemeData.estimateBrightnessForColor(highlightColor!) == Brightness.dark ? Colors.white : Colors.black)
              : scheme.onTertiaryContainer
        : palette.otherText;
    const big = Radius.circular(18);
    const small = Radius.circular(5);
    final radius = isMine
        ? BorderRadius.only(
            topLeft: big,
            bottomLeft: big,
            topRight: isFirstInGroup ? big : small,
            bottomRight: isLastInGroup ? const Radius.circular(4) : small,
          )
        : BorderRadius.only(
            topRight: big,
            bottomRight: big,
            topLeft: isFirstInGroup ? big : small,
            bottomLeft: isLastInGroup ? const Radius.circular(4) : small,
          );

    final quote = ChatQuote.parse(message.content);
    final forwarded = quote == null ? ChatQuote.forwarded(message.content) : null;
    final note = theme.textTheme.labelMedium?.copyWith(color: foreground.withValues(alpha: 0.75));
    final body = quote?.body ?? forwarded?.body ?? message.content;
    void copy() {
      Clipboard.setData(ClipboardData(text: message.content));
      chatToast('Message copied', seconds: 1);
    }

    final spoken = [
      isMine ? 'You' : NativeChat.prefs.displayName(message.sender.id, message.sender.name),
      if (presence != null && isFirstInGroup && showSender && !isMine) presence!.name,
      if (quote != null) 'replying to ${quote.author}: ${chatSpokenText(quote.excerpt)}',
      if (forwarded != null) 'forwarded from ${forwarded.from}',
      chatSpokenText(body),
      if (translation?.text case final text?) 'translation: $text',
      _chatSpokenTime(message.createdAt),
      if (highlighted) 'highlighted',
      if (pinned) 'pinned',
      if (saved) 'saved',
      if (pending) 'sending',
      if (failed) 'not sent',
    ].join(', ');
    final actions = <CustomSemanticsAction, VoidCallback>{
      if (onReply != null) const CustomSemanticsAction(label: 'Reply'): onReply!,
      if (onSwipeLeft != null)
        CustomSemanticsAction(
          label: '${chatSwipeLook[NativeChat.prefs.swipeLeft]?.$2 ?? 'Chat'} ${message.sender.name}',
        ): onSwipeLeft!,
      if (retry != null) const CustomSemanticsAction(label: 'Retry'): retry,
      const CustomSemanticsAction(label: 'Copy'): copy,
      if (onForward != null) const CustomSemanticsAction(label: 'Forward'): onForward!,
      if (onLongPress != null) CustomSemanticsAction(label: selected == true ? 'Deselect' : 'Select'): onLongPress!,
      if (quote != null && onQuoteTap != null)
        const CustomSemanticsAction(label: 'Go to the quoted message'): onQuoteTap!,
      if (translation != null && !translation!.isLoading && onTranslationTap != null)
        CustomSemanticsAction(label: translation!.failed ? 'Translate again' : 'Hide translation'): onTranslationTap!,
      if (hasPlayer && !isMine)
        CustomSemanticsAction(label: 'Options for ${message.sender.name}'): () =>
            showChatPlayerActions(context, message.sender),
      for (final link in ChatLink.split(body).whereType<ChatLink>().take(3))
        CustomSemanticsAction(label: 'Open ${link.label ?? link.uri.host}'): () => openChatLink(context, link),
      for (final link in ChatLink.split(body).whereType<ChatLink>().take(3))
        CustomSemanticsAction(label: 'Link options for ${link.label ?? link.uri.host}'): () =>
            showChatLinkMenu(context, link),
      if (ChatWiki.slangIn(message.roomId, NativeChat.prefs.slangEverywhere))
        for (final slang in ChatWiki.split(body).whereType<ChatSlang>().take(3))
          CustomSemanticsAction(label: 'Explain ${slang.term}'): () => showChatSlangSheet(context, slang),
      for (final ref in ChatPlayerRef.split(body).whereType<ChatPlayerRef>())
        CustomSemanticsAction(label: 'Options for ${ref.name}'): () =>
            showChatPlayerActions(context, ChatUser(id: ref.id, name: ref.name)),
      ...chatRefActions(
        context,
        body,
        roomId: message.roomId,
        slang: ChatWiki.slangIn(message.roomId, NativeChat.prefs.slangEverywhere),
      ),
    };
    final quoteBox = quote == null
        ? null
        : GestureDetector(
            onTap: onQuoteTap,
            child: Container(
              margin: const EdgeInsets.only(top: 2, bottom: 4),
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.07),
                border: Border(left: BorderSide(color: foreground.withValues(alpha: 0.45), width: 3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${quote.author}\n',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: quote.excerpt),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: note,
              ),
            ),
          );
    final forwardedRow = forwarded == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shortcut_rounded, size: 14, color: note?.color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Forwarded from ${forwarded.from}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: note?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
    final nameColor = switch (prefs.personOf(message.sender.id).nameColor) {
      final custom? => ChatPlayerColor.tinted(custom, background),
      _ =>
        highlighted
            ? foreground
            : isMine && compact
            ? ChatPlayerColor.tinted(scheme.primary, background)
            : prefs.playerColors
            ? ChatPlayerColor.of(message.sender.id, background)
            : ChatPlayerColor.tinted(chatUserScheme(context, message.sender.id).primary, background),
    };
    final showPlayer = hasPlayer ? () => showChatPlayerActions(context, message.sender) : null;
    final metaColor = foreground.withValues(alpha: 0.6);
    final compactRow = GestureDetector(
      excludeFromSemantics: true,
      onTap: retry,
      onLongPress: onLongPress ?? copy,
      child: Opacity(
        opacity: pending ? 0.75 : 1,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 2, 6, 2),
          decoration: BoxDecoration(
            color: highlighted ? background : null,
            border: searchCurrent
                ? Border.all(color: scheme.primary, width: 2.5)
                : highlighted
                ? Border(left: BorderSide(color: scheme.tertiary, width: 3))
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (prefs.showAvatars && showSender) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: GestureDetector(
                    excludeFromSemantics: true,
                    onTap: showPlayer,
                    child: ChatAvatar(user: message.sender, size: 20),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (quoteBox != null) ExcludeSemantics(child: quoteBox),
                    if (forwardedRow != null) ExcludeSemantics(child: forwardedRow),
                    ChatMessageText(
                      content: body,
                      color: foreground,
                      highlight: searchTerm,
                      slang: ChatWiki.slangIn(message.roomId, prefs.slangEverywhere),
                      roomId: message.roomId,
                      lead: !showSender
                          ? (isMine
                                ? TextSpan(
                                    text: 'You: ',
                                    style: TextStyle(color: metaColor),
                                  )
                                : null)
                          : TextSpan(
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: showPlayer,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
                                      child: Text(
                                        prefs.displayName(message.sender.id, message.sender.name),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: nameColor,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (presence != null)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: ChatPresenceDot(presence: presence!, foreground: foreground),
                                    ),
                                  ),
                                const TextSpan(text: ': '),
                              ],
                            ),
                    ),
                    if (translation != null)
                      ExcludeSemantics(
                        child: ChatTranslationText(
                          translation: translation!,
                          color: foreground,
                          onTap: onTranslationTap,
                        ),
                      ),
                  ],
                ),
              ),
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (failed) Icon(Icons.error_outline_rounded, size: 12, color: scheme.error),
                      if (saved) Icon(Icons.bookmark_rounded, size: 12, color: metaColor),
                      const SizedBox(width: 3),
                      Text(
                        NativeChat.prefs.clock(message.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(color: metaColor),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 3),
                        Icon(pending ? Icons.schedule_rounded : Icons.done_rounded, size: 13, color: metaColor),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final bubble = GestureDetector(
      excludeFromSemantics: true,
      onTap: retry,
      onLongPress: onLongPress ?? copy,
      child: Opacity(
        opacity: pending ? 0.75 : 1,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 7, 10, 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: searchCurrent
                ? Border.all(color: isMine ? Colors.amber : scheme.primary, width: 2.5)
                : highlighted
                ? Border.all(color: scheme.tertiary, width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFirstInGroup && !isMine && showSender)
                ExcludeSemantics(
                  child: GestureDetector(
                    onTap: hasPlayer ? () => showChatPlayerActions(context, message.sender) : null,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              NativeChat.prefs.displayName(message.sender.id, message.sender.name),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: nameColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (presence != null) ...[
                            const SizedBox(width: 5),
                            ChatPresenceDot(presence: presence!, foreground: foreground),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (quoteBox != null) ExcludeSemantics(child: quoteBox),
              if (forwardedRow != null) ExcludeSemantics(child: forwardedRow),
              ChatMessageText(
                content: body,
                color: foreground,
                highlight: searchTerm,
                slang: ChatWiki.slangIn(message.roomId, NativeChat.prefs.slangEverywhere),
                roomId: message.roomId,
              ),
              if (translation != null)
                ExcludeSemantics(
                  child: ChatTranslationText(translation: translation!, color: foreground, onTap: onTranslationTap),
                ),
              const SizedBox(height: 2),
              ExcludeSemantics(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 1,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (failed) ...[
                        Icon(Icons.error_outline_rounded, size: 12, color: scheme.error),
                        const SizedBox(width: 3),
                        Text(
                          'Not sent, tap to retry',
                          style: theme.textTheme.labelSmall?.copyWith(color: scheme.error),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (saved) ...[
                        Icon(Icons.bookmark_rounded, size: 12, color: foreground.withValues(alpha: 0.6)),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        NativeChat.prefs.clock(message.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(color: foreground.withValues(alpha: 0.6)),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 3),
                        Icon(
                          pending ? Icons.schedule_rounded : Icons.done_rounded,
                          size: 13,
                          color: foreground.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final insert = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          child: ChatTradeInsert(
            roomId: message.roomId,
            text: body,
            userId: isMine ? null : message.sender.id,
            color: plainText,
            mine: isMine && !compact,
          ),
        ),
        if (!isMine) Semantics(container: true, child: ChatBankInsert(message: message)),
      ],
    );
    final avatarColumn = !isMine && showSender && prefs.showAvatars;
    return ChatTextScale(
      child: Semantics(
        container: true,
        label: spoken,
        selected: selected,
        onTap: selected == null ? null : onLongPress,
        onLongPress: onLongPress ?? copy,
        onLongPressHint: onLongPress == null ? 'copy' : (selected == true ? 'deselect' : 'select'),
        customSemanticsActions: actions,
        child: IgnorePointer(
          ignoring: selected != null,
          child: compact
              ? Padding(
                  padding: EdgeInsets.only(top: isFirstInGroup ? 3 : 0, bottom: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      compactRow,
                      Padding(
                        padding: EdgeInsets.only(left: prefs.showAvatars && showSender ? 34 : 8, right: 6),
                        child: insert,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.only(left: 8, right: 8, top: isFirstInGroup ? 8 : 1.5, bottom: 1.5),
                  child: Column(
                    crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (avatarColumn) ...[
                            isLastInGroup
                                ? GestureDetector(
                                    excludeFromSemantics: true,
                                    onTap: hasPlayer ? () => showChatPlayerActions(context, message.sender) : null,
                                    onLongPress: hasPlayer
                                        ? () => showChatPlayerActions(context, message.sender)
                                        : null,
                                    child: ChatAvatar(user: message.sender),
                                  )
                                : const SizedBox(width: 34),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                              child: bubble,
                            ),
                          ),
                          if (isMine) const SizedBox(width: 4),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: avatarColumn ? 42 : 0, right: isMine ? 4 : 0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                          child: insert,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class ChatTranslationText extends StatelessWidget {
  const ChatTranslationText({super.key, required this.translation, required this.color, this.onTap});

  final ChatTranslation translation;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.65));
    final from = translation.from;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: color.withValues(alpha: 0.2))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (translation.text case final text?)
              Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (translation.isLoading)
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: note?.color),
                    )
                  else
                    Icon(
                      translation.failed ? Icons.error_outline_rounded : Icons.translate_rounded,
                      size: 12,
                      color: note?.color,
                    ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      translation.isLoading
                          ? 'Translating…'
                          : translation.failed
                          ? 'Could not translate, tap to try again'
                          : '${from == null ? 'Translated' : 'Translated from ${from.toUpperCase()}'}, tap to hide',
                      style: note,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatSwipeReply extends StatefulWidget {
  const ChatSwipeReply({super.key, required this.child, this.onReply, this.onSwipeLeft});

  final Widget child;
  final VoidCallback? onReply;
  final VoidCallback? onSwipeLeft;

  @override
  State<ChatSwipeReply> createState() => _ChatSwipeReplyState();
}

class _ChatSwipeReplyState extends State<ChatSwipeReply> with SingleTickerProviderStateMixin {
  static const double _trigger = 56;
  static const double _max = 76;

  late final AnimationController _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
    ..addListener(() => setState(() => _dx = _from * (1 - _back.value)));
  double _dx = 0;
  double _from = 0;
  bool _armed = false;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    _back.stop();
    final dx = (_dx + d.delta.dx).clamp(widget.onSwipeLeft == null ? 0.0 : -_max, widget.onReply == null ? 0.0 : _max);
    final armed = dx.abs() >= _trigger;
    if (armed && !_armed) HapticFeedback.selectionClick();
    setState(() {
      _dx = dx;
      _armed = armed;
    });
  }

  void _end(DragEndDetails _) {
    if (_armed) (_dx < 0 ? widget.onSwipeLeft : widget.onReply)?.call();
    _armed = false;
    _from = _dx;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _dx = 0);
    } else {
      _back.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Stable tree keeps the bubble's state
    final on = widget.onReply != null || widget.onSwipeLeft != null;
    Widget badge(IconData icon) => Opacity(
      opacity: (_dx.abs() / _trigger).clamp(0.0, 1.0),
      child: CircleAvatar(
        radius: 15,
        backgroundColor: _armed ? scheme.primary : scheme.surfaceContainerHighest,
        child: Icon(icon, size: 18, color: _armed ? scheme.onPrimary : scheme.onSurface),
      ),
    );
    return GestureDetector(
      excludeFromSemantics: true,
      onHorizontalDragUpdate: on ? _update : null,
      onHorizontalDragEnd: on ? _end : null,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dx > 0) Positioned(left: 12, child: badge(Icons.reply_rounded)),
          if (_dx < 0)
            Positioned(right: 12, child: badge(chatSwipeLook[NativeChat.prefs.swipeLeft]?.$1 ?? Icons.chat_rounded)),
          Transform.translate(
            offset: Offset(_dx, 0),
            child: ChatSwiping(on: _dx != 0, child: widget.child),
          ),
        ],
      ),
    );
  }
}

/// True while a message is being swiped
class ChatSwiping extends InheritedWidget {
  const ChatSwiping({super.key, required this.on, required super.child});

  final bool on;

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ChatSwiping>()?.on ?? false;

  @override
  bool updateShouldNotify(ChatSwiping old) => old.on != on;
}

class ChatDaySeparator extends StatelessWidget {
  const ChatDaySeparator({super.key, required this.day, this.compact = false});

  final DateTime day;
  final bool compact;

  static bool sameDay(DateTime a, DateTime b) => NativeChat.prefs.daysFrom(a, b) == 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (NativeChat.prefs.daysFrom(DateTime.now(), day)) {
      0 => 'Today',
      -1 => 'Yesterday',
      _ => DateFormat.yMMMd().format(NativeChat.prefs.wallClock(day)),
    };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Semantics(
            header: true,
            child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface)),
          ),
        ),
      ),
    );
  }
}

const Duration _groupGap = Duration(minutes: 5);

bool chatSameGroup(ChatMessage? a, ChatMessage? b) {
  if (a == null || b == null || a.isSystem || b.isSystem || a.sender.id != b.sender.id) return false;
  return ChatDaySeparator.sameDay(a.createdAt, b.createdAt) && b.createdAt.difference(a.createdAt).abs() < _groupGap;
}

class ChatUnreadSeparator extends StatelessWidget {
  const ChatUnreadSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final line = Expanded(child: Divider(color: color.withValues(alpha: 0.5), height: 1));
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'New messages',
              style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

class ChatTypingBar extends StatefulWidget {
  const ChatTypingBar({super.key, required this.users});

  final List<ChatUser> users;

  @override
  State<ChatTypingBar> createState() => _ChatTypingBarState();
}

class _ChatTypingBarState extends State<ChatTypingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  void _syncDots() {
    final moving = widget.users.isNotEmpty && !MediaQuery.disableAnimationsOf(context);
    if (moving && !_dots.isAnimating) _dots.repeat();
    if (!moving && _dots.isAnimating) _dots.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDots();
  }

  @override
  void didUpdateWidget(ChatTypingBar old) {
    super.didUpdateWidget(old);
    _syncDots();
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = widget.users;
    final text =
        chatTypingLine([for (final u in users) NativeChat.prefs.displayName(u.id, u.name)], isDm: false) ?? '';
    return AnimatedSize(
      duration: chatMotion(context, const Duration(milliseconds: 200)),
      alignment: Alignment.bottomCenter,
      child: users.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 16, 4),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _dots,
                    builder: (context, _) => Row(
                      children: List.generate(3, (i) {
                        final phase = ((_dots.value * 3) - i) % 3;
                        final lift = phase < 1 ? (1 - (phase - 0.5).abs() * 2) : 0.0;
                        return Container(
                          margin: const EdgeInsets.only(right: 3),
                          width: 6,
                          height: 6,
                          transform: Matrix4.translationValues(0, -3 * lift, 0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.5 + 0.5 * lift),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.roomName,
    required this.enabled,
    required this.onSend,
    this.draft = '',
    this.onDraft,
    this.replyTo,
    this.onCancelReply,
    this.chat,
    this.roomId,
    this.autofocus = false,
    this.focusSignal,
  });

  final String roomName;
  final bool enabled;
  final ValueChanged<String> onSend;

  /// Focus when built and on each ping
  final bool autofocus;
  final ValueListenable<int>? focusSignal;

  final ChatMessage? replyTo;
  final VoidCallback? onCancelReply;

  final String draft;
  final ValueChanged<String>? onDraft;

  final ChatController? chat;
  final String? roomId;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final TextEditingController _text = ChatFormatController(text: widget.draft);
  late bool _hasText = widget.draft.trim().isNotEmpty;
  final FocusNode _focus = FocusNode();
  Timer? _draftTimer;
  String? _mention;
  Timer? _mentionTimer;
  String? _mentionSearched;
  bool _attachOpen = false;
  bool _toolsOpen = false;
  bool _formatOpen = false;
  double? _upload;
  String? _uploadError;
  String? _blockedError;
  ChatImageHost? _blockedHost;

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      final hasText = _text.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
      final mention = ChatMentions.queryAt(_text.value);
      if (mention != _mention) {
        setState(() => _mention = mention);
        _searchMention();
      }
      if (widget.onDraft == null) return;
      _draftTimer?.cancel();
      _draftTimer = Timer(const Duration(milliseconds: 600), _saveDraft);
    });
    ChatShareIn.pending.addListener(_takeShared);
    widget.focusSignal?.addListener(_focus.requestFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeShared());
  }

  @override
  void didUpdateWidget(ChatComposer old) {
    super.didUpdateWidget(old);
    if (widget.replyTo != null && widget.replyTo?.id != old.replyTo?.id) {
      if (_focus.hasFocus) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      } else {
        _focus.requestFocus();
      }
    }
    if (widget.enabled && !old.enabled) _takeShared();
    if (old.roomId != null && old.roomId != widget.roomId) old.chat?.typingStopped(old.roomId!);
  }

  void _saveDraft() {
    _draftTimer?.cancel();
    _draftTimer = null;
    widget.onDraft?.call(_text.text);
  }

  List<ChatUser> _recent(String query) {
    final chat = widget.chat;
    final roomId = widget.roomId;
    if (chat == null || roomId == null) return const [];
    final roster = chat.rosterOf(roomId).where((u) => !chat.isHidden(u)).toList();
    return ChatMentions.rank(ChatMentions.candidates(chat.visibleMessagesFor(roomId), chat.myUserId, roster), query);
  }

  List<ChatUser> _suggestions() {
    final chat = widget.chat;
    final query = _mention;
    if (chat == null || query == null) return const [];
    final found = chat.searchQuery == query ? chat.searchResults ?? const <ChatUser>[] : const <ChatUser>[];
    return ChatMentions.rank([..._recent(query), ...found.where((u) => u.id != chat.myUserId)], query);
  }

  void _searchMention() {
    _mentionTimer?.cancel();
    final chat = widget.chat;
    final query = _mention;
    if (chat == null) return;
    if (query == null || query.length < 2) {
      if (_mentionSearched case final searched?) chat.endSearch(searched);
      _mentionSearched = null;
      return;
    }
    if (_recent(query).length >= 3) return;
    _mentionTimer = Timer(const Duration(milliseconds: 400), () {
      _mentionSearched = query;
      chat.search(query);
    });
  }

  Future<void> _uploadFrom({required bool fromFiles}) async {
    setState(() => _uploadError = null);
    final PlatformFile? file;
    try {
      file = await ChatImageUpload.pick(fromFiles: fromFiles);
    } catch (_) {
      if (mounted) setState(() => _uploadError = 'Could not open the picker');
      return;
    }
    if (file == null || !mounted) return;
    await _uploadBytes(file.bytes ?? Uint8List(0), file.name);
  }

  Future<void> _uploadBytes(Uint8List bytes, String name) async {
    final host = NativeChat.prefs.imageHost;
    setState(() => _upload = 0);
    try {
      final link = await ChatImageUpload.upload(
        host,
        bytes,
        name,
        NativeChat.prefs.credentialFor(host),
        expiration: NativeChat.prefs.imgbbExpiration,
        onProgress: (p) {
          if (mounted) setState(() => _upload = p);
        },
      );
      if (!mounted) return;
      _insert(link);
      setState(() {
        _attachOpen = false;
        _blockedHost = null;
      });
    } on ChatUploadError catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.message;
          _blockedError = e.blocked ? e.message : null;
          _blockedHost = e.blocked ? host : null;
        });
      }
    } finally {
      if (mounted) setState(() => _upload = null);
    }
  }

  Future<void> _takeShared() async {
    final roomId = widget.roomId;
    if (!mounted || !widget.enabled || roomId == null) return;
    final shared = ChatShareIn.take(roomId);
    if (shared == null) return;
    if (shared.text.isNotEmpty) _insert(shared.text);
    final image = shared.image;
    if (image == null) return _focus.requestFocus();
    final host = NativeChat.prefs.imageHost;
    if (host.needsCredential && NativeChat.prefs.credentialFor(host).isEmpty) {
      return setState(() => _attachOpen = true);
    }
    final upload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload the shared image?'),
        content: Text(
          'It goes to ${host.label} and anyone with the link can see it. The link stays in the message box, '
          'nothing is sent',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Upload')),
        ],
      ),
    );
    if (upload != true || !mounted) return;
    setState(() {
      _attachOpen = true;
      _uploadError = null;
    });
    final Uint8List bytes;
    try {
      bytes = await ChatShareIn.readImage(image);
    } catch (e) {
      if (mounted) setState(() => _uploadError = _sharedImageError(e is PlatformException ? e.code : ''));
      return;
    }
    final ext = ChatShared.imageExtension(bytes);
    if (!mounted) return;
    if (ext == null) return setState(() => _uploadError = _sharedImageError(''));
    await _uploadBytes(bytes, 'shared.$ext');
  }

  static String _sharedImageError(String code) => switch (code) {
    'too_big' => 'The shared image is over 32 MB',
    'rejected' => 'Only images shared from other apps can be uploaded',
    _ => 'Could not read the shared image, only PNG, JPEG, GIF and WEBP',
  };

  void _insert(String text) {
    final value = _text.value;
    final at = value.selection.isValid ? value.selection.end : value.text.length;
    final before = value.text.substring(0, at);
    final insert = '${before.isEmpty || before.endsWith(' ') || before.endsWith('\n') ? '' : ' '}$text ';
    _text.value = TextEditingValue(
      text: before + insert + value.text.substring(at),
      selection: TextSelection.collapsed(offset: at + insert.length),
    );
  }

  String? get _replyName {
    final id = widget.roomId;
    final chat = widget.chat;
    final reply = widget.replyTo?.sender;
    if (reply != null && reply.id != chat?.myUserId && reply.name.isNotEmpty) return reply.name;
    return id == null || chat == null || ChatRoom.peerIdOf(id) == null ? null : chat.roomById(id).name;
  }

  void _insertEmoji(String emoji) {
    final value = _text.value;
    final sel = value.selection.isValid ? value.selection : TextSelection.collapsed(offset: value.text.length);
    _text.value = TextEditingValue(
      text: value.text.replaceRange(sel.start, sel.end, emoji),
      selection: TextSelection.collapsed(offset: sel.start + emoji.length),
    );
  }

  void _insertTool(String text) {
    _insert(text);
    setState(() => _toolsOpen = false);
    _focus.requestFocus();
  }

  @override
  void dispose() {
    final id = widget.roomId;
    if (id != null) widget.chat?.typingStopped(id);
    _mentionTimer?.cancel();
    if (_mentionSearched case final searched?) {
      final chat = widget.chat;
      scheduleMicrotask(() => chat?.endSearch(searched));
    }
    _draftTimer?.cancel();
    if (_draftTimer != null) {
      final save = widget.onDraft;
      final text = _text.text;
      scheduleMicrotask(() => save?.call(text));
    }
    ChatShareIn.pending.removeListener(_takeShared);
    widget.focusSignal?.removeListener(_focus.requestFocus);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final enter = event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!enter || !widget.enabled || !_text.value.composing.isCollapsed) return KeyEventResult.ignored;
    if (View.of(context).viewInsets.bottom > 0) return KeyEventResult.ignored;
    if (!NativeChat.prefs.hardwareEnterSends(shift: HardwareKeyboard.instance.isShiftPressed)) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) _send();
    return KeyEventResult.handled;
  }

  void _send() {
    if (!_hasText) return;
    final name = widget.roomName;
    sendChatChecked(context, _text.text, roomId: widget.roomId, roomName: name, onSend: widget.onSend).then((sent) {
      if (!sent || !mounted) return;
      _text.clear();
      if (widget.onDraft != null) _saveDraft();
    });
  }

  Widget _attachPanel(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final upload = _upload;
    final host = NativeChat.prefs.imageHost;
    final Widget content;
    if (upload != null) {
      content = Row(
        children: [
          Icon(Icons.cloud_upload_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(child: LinearProgressIndicator(value: upload > 0 && upload < 1 ? upload : null)),
          const SizedBox(width: 10),
          Text(upload > 0 && upload < 1 ? 'Uploading ${(upload * 100).round()}%' : 'Uploading', style: small),
        ],
      );
    } else if (host.needsCredential && NativeChat.prefs.credentialFor(host).isEmpty) {
      content = ChatUploadSetupNotice(
        host: host,
        excluded: _blockedHost,
        onPicked: () {
          if (mounted) setState(() {});
        },
      );
    } else {
      final error = _uploadError;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            children: [
              TextButton.icon(
                onPressed: () => _uploadFrom(fromFiles: false),
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text('Gallery'),
              ),
              TextButton.icon(
                onPressed: () => _uploadFrom(fromFiles: true),
                icon: const Icon(Icons.folder_open_outlined, size: 20),
                label: const Text('Files'),
              ),
            ],
          ),
          if (error != null && error == _blockedError && _blockedHost == host)
            ChatUploadSetupNotice(
              host: host,
              blockedMessage: error,
              onPicked: () {
                if (mounted) {
                  setState(() {
                    _uploadError = null;
                    _blockedError = null;
                  });
                }
              },
            )
          else
            Text(
              error ?? 'The image goes to ${host.label} and anyone with the link can see it',
              style: error == null ? small : small?.copyWith(color: scheme.error),
            ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6, left: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reply = widget.replyTo;
    final suggestions = _suggestions();
    final chat = widget.chat;
    final lookingUp = chat != null && _mention != null && chat.searching && chat.searchQuery == _mention;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Attach an image',
          onPressed: widget.enabled && _upload == null
              ? () => setState(() {
                  _attachOpen = !_attachOpen;
                  _toolsOpen = false;
                  _uploadError = null;
                  _blockedHost = null;
                })
              : null,
          icon: Icon(_attachOpen ? Icons.close_rounded : Icons.add_photo_alternate_outlined),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          padding: EdgeInsets.zero,
        ),
        IconButton(
          tooltip: 'Quick actions',
          onPressed: widget.enabled
              ? () => setState(() {
                  _toolsOpen = !_toolsOpen;
                  _attachOpen = false;
                })
              : null,
          icon: Icon(_toolsOpen ? Icons.close_rounded : Icons.bolt_rounded),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          padding: EdgeInsets.zero,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onKey,
              child: TextField(
                controller: _text,
                focusNode: _focus,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                onChanged: (value) {
                  NativeChat.touch();
                  final id = widget.roomId;
                  if (id != null) widget.chat?.typed(id, value);
                },
                minLines: 1,
                maxLines: MediaQuery.textScalerOf(context).scale(1) >= 1.5 ? 3 : 5,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                textInputAction: NativeChat.prefs.softAction,
                onEditingComplete: NativeChat.prefs.enterSendsSoft ? _send : null,
                decoration: InputDecoration(
                  hintText: !widget.enabled
                      ? 'You can\'t write in ${widget.roomName}'
                      : box.maxWidth < 220
                      ? 'Message'
                      : 'Message ${widget.roomName}',
                  hintMaxLines: 1,
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    tooltip: 'Text format',
                    onPressed: widget.enabled ? () => setState(() => _formatOpen = !_formatOpen) : null,
                    icon: Icon(Icons.text_format_rounded, color: _formatOpen ? scheme.primary : null),
                  ),
                  suffixIconConstraints: const BoxConstraints.tightFor(width: 48, height: 48),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        AnimatedScale(
          scale: _hasText ? 1 : 0.85,
          duration: chatMotion(context, const Duration(milliseconds: 150)),
          child: IconButton.filled(
            tooltip: 'Send',
            onPressed: _hasText && widget.enabled ? _send : null,
            icon: const Icon(Icons.send_rounded),
            iconSize: 22,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          ),
        ),
      ],
    );
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scrolls when big text fills the screen
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_attachOpen || _upload != null) _attachPanel(context),
                      if (_toolsOpen && widget.enabled)
                        ChatComposeTools(
                          onInsert: _insertTool,
                          onEmoji: _insertEmoji,
                          chat: widget.chat,
                          name: _replyName,
                          roomId: widget.roomId,
                        ),
                      if (_formatOpen && widget.enabled) ChatFormatBar(controller: _text, focus: _focus),
                      if (_mention != null && (suggestions.isNotEmpty || lookingUp))
                        Container(
                          height: MediaQuery.textScalerOf(context).scale(48),
                          margin: const EdgeInsets.only(bottom: 6, left: 6),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final user in suggestions)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: MergeSemantics(
                                    child: GestureDetector(
                                      onLongPress: () => showChatPlayerActions(context, user),
                                      child: ActionChip(
                                        avatar: ChatAvatar(user: user, size: 24),
                                        label: Text(user.name, semanticsLabel: 'Mention ${user.name}'),
                                        onPressed: () {
                                          _text.value = ChatMentions.insert(_text.value, user.name);
                                          _focus.requestFocus();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              if (lookingUp)
                                const Padding(
                                  padding: EdgeInsets.all(11),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (reply != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    border: Border(left: BorderSide(color: scheme.primary, width: 3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Replying to ${reply.sender.name}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              ChatQuote.excerpt(reply.content),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cancel reply',
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: widget.onCancelReply,
                      ),
                    ],
                  ),
                ),
              row,
            ],
          ),
        ),
      ),
    );
  }
}

class ChatStateMessage extends StatelessWidget {
  const ChatStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.busy = false,
    this.phrases = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool busy;
  final bool phrases;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: busy
                  ? null
                  : BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.07), shape: BoxShape.circle),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.onSurface),
                    )
                  : Icon(icon, size: 36, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (busy && phrases) const ChatLoadingPhrase(active: true, centered: true),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ChatLoadFailed extends StatelessWidget {
  const ChatLoadFailed({super.key, required this.name, required this.onRetry, this.compact = false});

  final String name;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retry = TextButton(onPressed: onRetry, child: const Text('Try again'));
    if (compact) {
      final style = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
      return Row(children: [Expanded(child: Text('Could not load $name', style: style)), retry]);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text('Could not load $name', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ),
          retry,
        ],
      ),
    );
  }
}

class ChatStartingBar extends StatelessWidget {
  const ChatStartingBar({super.key, required this.starting, this.phrases = true});

  final bool starting;
  final bool phrases;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 2,
        child: starting ? const LinearProgressIndicator(minHeight: 2, semanticsLabel: 'Starting chat') : null,
      ),
      if (phrases) ChatLoadingPhrase(active: starting),
    ],
  );
}

class ChatLoadingPhrase extends StatefulWidget {
  const ChatLoadingPhrase({super.key, required this.active, this.centered = false});

  final bool active;
  final bool centered;

  @override
  State<ChatLoadingPhrase> createState() => _ChatLoadingPhraseState();
}

class _ChatLoadingPhraseState extends State<ChatLoadingPhrase> {
  static const Duration _wait = Duration(seconds: 5);
  static const Duration _every = Duration(seconds: 3);

  Timer? _timer;
  int? _phrase;

  @override
  void initState() {
    super.initState();
    if (widget.active) _arm();
  }

  @override
  void didUpdateWidget(ChatLoadingPhrase old) {
    super.didUpdateWidget(old);
    if (widget.active == old.active) return;
    widget.active ? _arm() : _stop();
  }

  void _arm() {
    _timer = Timer(_wait, () {
      _next();
      _timer = Timer.periodic(_every, (_) => _next());
    });
  }

  void _next() {
    final count = chatLoadingPhrases.length;
    var pick = math.Random().nextInt(count);
    if (pick == _phrase) pick = (pick + 1) % count;
    setState(() => _phrase = pick);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _phrase = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = widget.active ? _phrase : null;
    if (phrase == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: widget.centered ? const EdgeInsets.only(top: 24) : const EdgeInsets.fromLTRB(12, 4, 12, 2),
        child: Text(
          chatLoadingPhrases[phrase],
          textAlign: TextAlign.center,
          maxLines: widget.centered ? null : 1,
          overflow: widget.centered ? null : TextOverflow.ellipsis,
          style: (widget.centered ? theme.textTheme.bodyLarge : theme.textTheme.labelSmall)?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class ChatSessionMessage extends StatelessWidget {
  const ChatSessionMessage({super.key, required this.state});

  final ChatConnection state;

  @override
  Widget build(BuildContext context) {
    final twoFactor = state == ChatConnection.twoFactor;
    final browser = twoFactor || state == ChatConnection.needsBrowser;
    if (state == ChatConnection.offline || state == ChatConnection.tornDown) {
      final offline = state == ChatConnection.offline;
      return ChatStateMessage(
        icon: offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
        title: offline ? 'No connection, retrying' : 'Torn is not responding, retrying',
        subtitle: offline
            ? 'The chat connects by itself as soon as the network is back'
            : 'Torn may be down for maintenance. The chat tries again by itself',
        action: TextButton(onPressed: () => NativeChat.setEnabled(false), child: const Text('Turn off chat')),
      );
    }
    return ChatStateMessage(
      icon: browser ? Icons.password_rounded : Icons.lock_outline_rounded,
      title: twoFactor
          ? 'Enter your 2FA code in the browser'
          : browser
          ? 'Finish logging in to Torn'
          : 'Not logged in to Torn',
      subtitle: twoFactor
          ? 'Open the Torn PDA browser, enter the code there and the chat connects by itself'
          : browser
          ? 'Torn wants one more step. '
                'Open the browser, finish logging in there and the chat connects by itself'
          : 'The chat uses your Torn login, like the website. Go to Settings > Torn Authentication and sign in '
                'with Google${Platform.isIOS ? ', Apple' : ''} or your Torn email and password. '
                'The chat then connects by itself',
      action: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (browser)
            const FilledButton.tonal(onPressed: NativeChat.openTornBrowser, child: Text('Open browser'))
          else ...[
            const FilledButton.tonal(onPressed: NativeChat.openSettings, child: Text('Open Settings')),
            const OutlinedButton(onPressed: NativeChat.openTornBrowser, child: Text('Open browser')),
          ],
          TextButton(onPressed: () => NativeChat.setEnabled(false), child: const Text('Turn off chat')),
        ],
      ),
    );
  }
}

class ChatPausedGate extends StatefulWidget {
  const ChatPausedGate({super.key, required this.child});

  final Widget child;

  @override
  State<ChatPausedGate> createState() => _ChatPausedGateState();
}

class _ChatPausedGateState extends State<ChatPausedGate> {
  @override
  void initState() {
    super.initState();
    NativeChat.tornTabMissing.addListener(_closePopups);
  }

  @override
  void dispose() {
    NativeChat.tornTabMissing.removeListener(_closePopups);
    super.dispose();
  }

  void _closePopups() {
    if (!NativeChat.tornTabMissing.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((route) => route is! PopupRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ValueListenableBuilder(
      valueListenable: NativeChat.tornTabMissing,
      child: widget.child,
      builder: (context, paused, page) => Stack(
        children: [
          Positioned.fill(
            child: ExcludeFocus(
              excluding: paused,
              child: IgnorePointer(
                ignoring: paused,
                child: ExcludeSemantics(
                  excluding: paused,
                  child: ImageFiltered(
                    enabled: paused,
                    imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10, tileMode: TileMode.decal),
                    child: page,
                  ),
                ),
              ),
            ),
          ),
          if (paused)
            Positioned.fill(
              child: ColoredBox(
                color: scheme.scrim.withValues(alpha: 0.4),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Material(
                        color: scheme.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(Icons.tab_unselected_rounded, size: 40, color: scheme.onSurfaceVariant),
                              const SizedBox(height: 14),
                              Text(
                                'No Torn tab open',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Chat needs a Torn page open in the browser.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 20),
                              ValueListenableBuilder(
                                valueListenable: NativeChat.tornTabExists,
                                builder: (context, exists, _) => FilledButton(
                                  style: _pausedButton,
                                  onPressed: NativeChat.goToTornTab,
                                  child: Text(exists ? 'Go to Torn tab' : 'Open Torn tab'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                style: _pausedButton,
                                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                                child: const Text('Close chat'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final _pausedButton = ButtonStyle(
  minimumSize: const WidgetStatePropertyAll(Size.fromHeight(46)),
  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
);

Color chatPresenceColor(ChatPresence presence, Color foreground) => switch (presence) {
  ChatPresence.online => Colors.green,
  ChatPresence.idle => Colors.amber.shade700,
  ChatPresence.offline => foreground.withValues(alpha: 0.4),
};

/// Shape tells the state apart without color
class ChatPresenceDot extends StatelessWidget {
  const ChatPresenceDot({
    super.key,
    required this.presence,
    required this.foreground,
    this.size = 10,
    this.spoken = false,
  });

  final ChatPresence presence;
  final Color foreground;
  final double size;

  /// Off when the parent already says it
  final bool spoken;

  @override
  Widget build(BuildContext context) => Icon(
    switch (presence) {
      ChatPresence.online => Icons.circle,
      ChatPresence.idle => Icons.dark_mode_rounded,
      ChatPresence.offline => Icons.circle_outlined,
    },
    size: size,
    color: chatPresenceColor(presence, foreground),
    semanticLabel: spoken ? presence.name : null,
  );
}

class ChatConnectionLine extends StatelessWidget {
  const ChatConnectionLine({required this.state, this.presence, this.lastSeen, this.style, this.short = false});

  final ChatConnection state;
  final ChatPresence? presence;
  final TextStyle? style;

  /// Just the time away, for tight headers
  final bool short;

  /// Shown unless online
  final DateTime? lastSeen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = DefaultTextStyle.of(context).style.color ?? scheme.onSurface;
    final (String text, Color color) = switch (state) {
      ChatConnection.connected => switch (presence) {
        null => ('Connected', Colors.green),
        final p => (_withSeen(p), chatPresenceColor(p, foreground)),
      },
      ChatConnection.connecting => ('Connecting…', foreground.withValues(alpha: 0.4)),
      ChatConnection.starting => ('Starting…', foreground.withValues(alpha: 0.4)),
      ChatConnection.disconnected => ('Offline, reconnecting…', scheme.error),
      ChatConnection.noSession => ('Not logged in to Torn', scheme.error),
      ChatConnection.needsBrowser => ('Torn login not finished', scheme.error),
      ChatConnection.twoFactor => ('2FA code pending', scheme.error),
      ChatConnection.offline => ('No connection, retrying…', scheme.error),
      ChatConnection.tornDown => ('Torn is not responding, retrying…', scheme.error),
      ChatConnection.error => ('Connection problem', scheme.error),
    };
    return Row(
      children: [
        AnimatedContainer(
          duration: chatMotion(context, const Duration(milliseconds: 300)),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (style ?? theme.textTheme.labelMedium)?.copyWith(color: foreground),
          ),
        ),
      ],
    );
  }

  String _withSeen(ChatPresence p) {
    final label = switch (p) {
      ChatPresence.online => 'Online',
      ChatPresence.idle => 'Idle',
      ChatPresence.offline => 'Offline',
    };
    final seen = lastSeen;
    if (p == ChatPresence.online || seen == null) return label;
    final ago = ChatLastAction.ago(seen, DateTime.now());
    if (short) {
      return ago == null
          ? label
          : p == ChatPresence.offline
          ? '$ago ago'
          : '$label, $ago ago';
    }
    return '$label, last seen ${ago == null ? 'just now' : '$ago ago'}';
  }
}

IconData chatRoomIcon(String roomId, [String? glyph]) {
  if (roomId == 'company') {
    final type = chatOwnCompanyIcon();
    if (type != null) return type;
  }
  if (roomId == ChatRooms.travel) return Icons.flight_rounded;
  if (const {'faction', 'company', 'dm', ChatRooms.newPlayers, 'hospital', 'jail'}.contains(roomId)) glyph = null;
  switch (glyph) {
    case 'globe':
      return Icons.public_rounded;
    case 'trade':
      return Icons.sync_alt_rounded;
    case 'casino':
      return Icons.casino_rounded;
    case 'person':
      return Icons.person_rounded;
    case 'building':
      return Icons.business_rounded;
  }
  switch (roomId) {
    case 'global':
      return Icons.public_rounded;
    case 'trade':
      return Icons.storefront_rounded;
    case 'poker':
      return Icons.casino_rounded;
    case 'faction':
      return Icons.shield_rounded;
    case 'company':
      return Icons.business_center_rounded;
    case 'dm':
      return Icons.person_rounded;
    case ChatRooms.newPlayers:
      return Icons.school_rounded;
    case 'hospital':
      return Icons.local_hospital_rounded;
    case 'jail':
      return Icons.lock_rounded;
  }
  return Icons.forum_rounded;
}

class ChatRoomGlyph extends StatelessWidget {
  const ChatRoomGlyph({
    super.key,
    required this.roomId,
    this.glyph,
    this.emblemUrl,
    this.size = 24,
    this.color,
    this.fallback,
  });

  ChatRoomGlyph.of(ChatRoom room, {super.key, this.size = 24, this.color, this.fallback})
    : roomId = room.id,
      glyph = room.icon,
      emblemUrl = room.emblemUrl;

  final String roomId;
  final String? glyph;
  final String? emblemUrl;

  /// Height, the emblem is wider
  final double size;
  final Color? color;

  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final icon = fallback ?? Icon(chatRoomIcon(roomId, glyph), size: size, color: color);
    if (emblemUrl == null) return icon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.14),
      child: Image.network(
        emblemUrl!,
        width: size * 25 / 19,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => icon,
        frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : icon,
      ),
    );
  }
}

String? chatTravelFlag(ChatRoom room) {
  if (room.id != ChatRoom.travelId) return null;
  final name = room.name.trim().toLowerCase().replaceAll(' ', '-');
  final file = switch (name) {
    'uk' || 'united-kingdom' => 'uk',
    'uae' || 'united-arab-emirates' => 'uae',
    'cayman' || 'cayman-islands' => 'cayman',
    'argentina' || 'canada' || 'china' || 'hawaii' || 'japan' || 'mexico' || 'south-africa' || 'switzerland' => name,
    _ => null,
  };
  return file == null ? null : 'images/flags/ball/ball_$file.png';
}

class ChatRoomAvatar extends StatelessWidget {
  const ChatRoomAvatar({super.key, required this.room, this.size = 48});

  final ChatRoom room;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (room.peer != null) return ChatAvatar(user: room.peer!, size: size);
    final scheme = Theme.of(context).colorScheme;
    final disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.secondaryContainer, shape: BoxShape.circle),
      child: Icon(
        room.isDm ? Icons.person_rounded : chatRoomIcon(room.id, room.icon),
        size: size * 0.5,
        color: scheme.onSecondaryContainer,
      ),
    );
    final flag = chatTravelFlag(room);
    if (flag != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            disc,
            Positioned(
              right: 0,
              bottom: 0,
              child: Image.asset(
                flag,
                width: size * 0.42,
                height: size * 0.42,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
          ],
        ),
      );
    }
    if (room.isDm || room.emblemUrl == null) return disc;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: ChatRoomGlyph.of(room, size: size * 19 / 25, fallback: disc),
      ),
    );
  }
}

(Color, Color) chatGroupColors(String group, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final own = ChatRooms.remoteOf(group)?.color;
  if (own != null) {
    return (own, ThemeData.estimateBrightnessForColor(own) == Brightness.dark ? Colors.white : Colors.black);
  }
  switch (group) {
    case 'faction':
      return (dark ? Colors.blue[300]! : const Color(0xFF2A72D0), dark ? const Color(0xFF0B1F3A) : Colors.white);
    case 'company':
      return (dark ? Colors.orange[300]! : const Color(0xFFF29D0C), const Color(0xFF3A2800));
    case 'global':
      return (dark ? Colors.deepPurple[200]! : const Color(0xFF7362E8), dark ? const Color(0xFF1A1240) : Colors.white);
    case 'trade':
      return (dark ? Colors.green[300]! : const Color(0xFF188452), dark ? const Color(0xFF062A19) : Colors.white);
    case 'poker':
      return (dark ? Colors.brown[200]! : Colors.brown[600]!, dark ? const Color(0xFF2A1A14) : Colors.white);
    case ChatRooms.travel:
      return (dark ? Colors.lightBlue[200]! : const Color(0xFF0A7FB5), dark ? const Color(0xFF06263A) : Colors.white);
    case ChatRooms.newPlayers:
      return (dark ? Colors.lightGreen[300]! : const Color(0xFF4C8A0F), dark ? const Color(0xFF1A2E05) : Colors.white);
    case 'hospital':
      return (dark ? Colors.pink[200]! : const Color(0xFFAD1457), dark ? const Color(0xFF3A0620) : Colors.white);
    case 'jail':
      return (dark ? Colors.blueGrey[200]! : const Color(0xFF546E7A), dark ? const Color(0xFF1C262B) : Colors.white);
  }
  return (dark ? Colors.red[300]! : const Color(0xFFD92B50), dark ? const Color(0xFF3A0611) : Colors.white);
}

class ChatUnreadArc extends StatelessWidget {
  const ChatUnreadArc({
    super.key,
    required this.counts,
    required this.child,
    this.glyphs = const {},
    this.ringColor,
    this.iconSize = 48,
    this.row = false,
  });

  /// Counts as the bubble settings ask
  factory ChatUnreadArc.bubble({
    required Map<String, int> groups,
    required Widget child,
    bool hidden = false,
    Color? ringColor,
    double iconSize = 48,
    bool row = false,
  }) {
    final prefs = NativeChat.prefs;
    final chat = NativeChat.controller;
    return ChatUnreadArc(
      iconSize: iconSize,
      counts: hidden
          ? const {}
          : prefs.bubbleTotal
          ? {'total': groups.values.fold(0, (a, b) => a + b)}
          : {for (final room in ChatPrefs.bubbleOptions) room: groups[room] ?? 0},
      glyphs: prefs.bubbleTotal
          ? const {}
          : {for (final room in ChatPrefs.bubbleOptions) room: room == 'dm' ? null : chat.roomById(room).icon},
      ringColor: ringColor,
      row: row,
      child: child,
    );
  }

  final Map<String, int> counts;
  final Map<String, String?> glyphs;
  final Widget child;
  final Color? ringColor;
  final double iconSize;

  /// Pills only, side by side
  final bool row;

  static const double _dot = 20;
  static const double _gap = 6;
  static const double _stepDegrees = 42;
  static const double padTop = 8;
  static const double reach = _gap + _dot;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = counts.entries.where((e) => e.value > 0).toList();
    final r = iconSize / 2;
    final radius = r + _gap;
    final ring = ringColor ?? theme.colorScheme.surface;
    Widget pill(String group, int n) {
      final (background, foreground) = chatGroupColors(group, theme.brightness);
      final style = TextStyle(color: foreground, fontSize: 10, fontWeight: FontWeight.w700, height: 1);
      return Container(
        height: _dot,
        constraints: const BoxConstraints(minWidth: _dot),
        padding: const EdgeInsets.symmetric(horizontal: 3.5),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: background,
          shape: const StadiumBorder(),
          shadows: [BoxShadow(color: ring, spreadRadius: 2)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (group != 'total')
              ChatRoomGlyph(roomId: group, glyph: glyphs[group], size: 10, color: foreground.withValues(alpha: 0.85)),
            Text(n > 99 ? '99+' : '$n', style: style),
          ],
        ),
      );
    }

    if (row) {
      return Material(
        type: MaterialType.transparency,
        child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [for (final e in shown) pill(e.key, e.value)]),
      );
    }
    final angles = [for (var i = 0; i < shown.length; i++) ((shown.length - 1) / 2 - i) * _stepDegrees * math.pi / 180];
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: iconSize + _gap + _dot + 16,
        height: iconSize + 2 * padTop,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: 0, top: padTop, width: iconSize, height: iconSize, child: child),
            for (final (i, e) in shown.indexed)
              Positioned(
                left: r + radius * math.cos(angles[i]) - _dot / 2,
                top: padTop + r - radius * math.sin(angles[i]) - _dot / 2,
                child: pill(e.key, e.value),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatConversationTile extends StatelessWidget {
  const ChatConversationTile({
    super.key,
    required this.room,
    required this.last,
    required this.unread,
    required this.myUserId,
    required this.onTap,
    this.onLongPress,
    this.pinned = false,
    this.muted = false,
    this.snoozed = false,
    this.frozen = false,
    this.mentioned = false,
    this.draft = '',
    this.awayLine,
    this.typing = const [],
    this.actions = const {},
    this.dot = false,
    this.more = false,
    this.expanded = false,
    this.hidePreview = false,
    this.onExpand,
  });

  final ChatRoom room;
  final ChatMessage? last;
  final int unread;

  /// No icon when null
  final VoidCallback? onExpand;
  final bool expanded;

  final bool hidePreview;

  /// Older messages may not be loaded
  final bool more;

  /// No count, Torn never marks it read
  final bool dot;
  final int? myUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool pinned;
  final bool muted;
  final bool snoozed;
  final bool frozen;
  final bool mentioned;
  final String draft;

  /// Replaces the preview
  final String? awayLine;

  /// Who is typing, replaces everything else
  final List<ChatUser> typing;

  /// For screen readers, the swipe actions
  final Map<CustomSemanticsAction, VoidCallback> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = last;
    final peer = room.isDm ? ChatRoom.peerIdOf(room.id) : null;
    final name = peer == null ? room.name : NativeChat.prefs.displayName(peer, room.name);
    final hasDraft = draft.trim().isNotEmpty;
    final typingLine = chatTypingLine([
      for (final u in typing) NativeChat.prefs.displayName(u.id, u.name),
    ], isDm: room.isDm);
    String preview([String Function(String) text = ChatFormat.plain]) {
      if (awayLine != null) return awayLine!;
      if (m == null) return room.isDm ? 'Private chat' : 'Tap to read';
      if (myUserId != null && m.sender.id == myUserId) return 'You: ${text(m.content)}';
      if (!room.isDm && !m.isSystem) {
        return '${NativeChat.prefs.displayName(m.sender.id, m.sender.name)}: ${text(m.content)}';
      }
      return text(m.content);
    }

    final highlight = unread > 0;
    final hidden = hidePreview && !hasDraft;
    // Fades when the last message changes, not per draft key
    final previewKey = typingLine != null
        ? 'typing'
        : hasDraft
        ? 'draft'
        : awayLine != null
        ? 'away'
        : m == null
        ? 'none'
        : m.reqId ?? m.id;
    Widget line(Key? key) => Text.rich(
      key: key,
      TextSpan(
        children: [
          if (hasDraft)
            TextSpan(
              text: 'Draft: ',
              style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
            ),
          if (!hasDraft && awayLine != null)
            for (final (i, part) in awayLine!.split(' - ').indexed) ...[
              if (i > 0) const TextSpan(text: ' - '),
              TextSpan(
                text: part,
                style: part.endsWith('mention you')
                    ? TextStyle(color: scheme.tertiary, fontWeight: FontWeight.w700)
                    : null,
              ),
            ]
          else
            TextSpan(text: (hasDraft ? draft : preview()).replaceAll('\n', ' ')),
        ],
      ),
      maxLines: NativeChat.prefs.previewLines,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    );

    final spoken = [
      name,
      if (highlight)
        dot
            ? 'new messages'
            : unread == 1 && !more
            ? '1 unread message'
            : '$unread${more ? '+' : ''} unread messages',
      if (mentioned) 'you were mentioned',
      if (typingLine != null && !hidden)
        typingLine
      else if (hasDraft)
        'draft: $draft'
      else if (!hidden)
        preview(chatSpokenText),
      if (m != null) _chatSpokenTime(m.createdAt),
      if (pinned) 'pinned',
      if (muted) snoozed ? 'snoozed' : 'muted',
      if (frozen) 'frozen',
    ].join(', ');
    final row = Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: spoken,
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressHint: onLongPress == null ? null : 'more options',
      customSemanticsActions: actions,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, onExpand == null ? 16 : 0, 10),
          child: Row(
            children: [
              ChatRoomAvatar(room: room),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (frozen) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.ac_unit_rounded, size: 15, color: scheme.onSurfaceVariant),
                              ],
                            ],
                          ),
                        ),
                        if (m != null)
                          Text(
                            _when(m.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: highlight ? scheme.primary : scheme.onSurfaceVariant,
                              fontWeight: highlight ? FontWeight.w700 : null,
                            ),
                          ),
                      ],
                    ),
                    if (!hidden) const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: hidden
                              ? const SizedBox.shrink()
                              : AnimatedSwitcher(
                                  duration: chatMotionSet(context).line,
                                  layoutBuilder: (current, previous) => Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [...previous, ?current],
                                  ),
                                  child: typingLine == null
                                      ? line(ValueKey(previewKey))
                                      : Stack(
                                          key: const ValueKey('typing'),
                                          alignment: Alignment.topLeft,
                                          children: [
                                            // Holds the replaced line's height
                                            Opacity(opacity: 0, child: line(null)),
                                            Text(
                                              typingLine,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: scheme.primary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                        ),
                        if (muted) ...[
                          const SizedBox(width: 6),
                          Icon(
                            snoozed ? Icons.snooze_rounded : Icons.notifications_off_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                        if (pinned) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.push_pin_rounded, size: 16, color: scheme.onSurfaceVariant),
                        ],
                        if (mentioned) ...[
                          const SizedBox(width: 6),
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: scheme.tertiary,
                            child: Icon(Icons.alternate_email_rounded, size: 14, color: scheme.onTertiary),
                          ),
                        ],
                        if (highlight && dot) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: muted ? scheme.onSurfaceVariant : scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ] else if (highlight) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: muted
                                  ? ChatPlayerColor.tinted(scheme.onSurfaceVariant, scheme.surface)
                                  : ChatPlayerColor.tinted(scheme.primary, scheme.onPrimary),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread${more ? '+' : ''}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: muted ? scheme.surface : scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (onExpand == null) return row;
    return Row(
      children: [
        Expanded(child: row),
        // Own node, not merged into the slidable
        Semantics(
          container: true,
          expanded: expanded,
          child: IconButton(
            tooltip: expanded ? 'Close quick reply to $name' : 'Quick reply to $name',
            onPressed: onExpand,
            color: expanded ? scheme.primary : scheme.onSurfaceVariant,
            icon: AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: chatMotion(context, const Duration(milliseconds: 200)),
              child: const Icon(Icons.expand_more_rounded),
            ),
          ),
        ),
      ],
    );
  }

  String _when(DateTime at) {
    final now = DateTime.now();
    final prefs = NativeChat.prefs;
    if (prefs.daysFrom(now, at) == 0) return prefs.clock(at);
    if (now.difference(at).inDays < 7) return DateFormat.E().format(prefs.wallClock(at));
    return DateFormat.yMd().format(prefs.wallClock(at));
  }
}

class ChatPinnedBar extends StatelessWidget {
  const ChatPinnedBar({super.key, required this.pin, required this.onTap, required this.onUnpin});

  final ChatSaved pin;
  final VoidCallback onTap;
  final VoidCallback onUnpin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 14, right: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Icon(Icons.push_pin_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pin.author.isEmpty ? 'Pinned message' : pin.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      pin.excerpt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(tooltip: 'Unpin', icon: const Icon(Icons.close_rounded, size: 20), onPressed: onUnpin),
            ],
          ),
        ),
      ),
    );
  }
}

/// Announces new messages in the open chat
class ChatArrivals extends StatefulWidget {
  const ChatArrivals({super.key, required this.chat, required this.roomId, required this.child});

  final ChatController chat;
  final String roomId;
  final Widget child;

  static const Duration batch = Duration(seconds: 2);

  @override
  State<ChatArrivals> createState() => _ChatArrivalsState();
}

class _ChatArrivalsState extends State<ChatArrivals> {
  String? _lastId;
  final List<ChatMessage> _waiting = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lastId = widget.chat.visibleMessagesFor(widget.roomId).lastOrNull?.id;
    widget.chat.addListener(_check);
  }

  @override
  void didUpdateWidget(ChatArrivals old) {
    super.didUpdateWidget(old);
    if (old.chat == widget.chat && old.roomId == widget.roomId) return;
    old.chat.removeListener(_check);
    _timer?.cancel();
    _timer = null;
    _waiting.clear();
    _lastId = widget.chat.visibleMessagesFor(widget.roomId).lastOrNull?.id;
    widget.chat.addListener(_check);
  }

  @override
  void dispose() {
    widget.chat.removeListener(_check);
    _timer?.cancel();
    super.dispose();
  }

  void _check() {
    final chat = widget.chat;
    final list = chat.visibleMessagesFor(widget.roomId);
    final last = list.lastOrNull;
    if (last == null || last.id == _lastId) return;
    final from = _lastId == null ? -1 : list.lastIndexWhere((m) => m.id == _lastId);
    _lastId = last.id;
    // First page or reload, nothing new
    if (from < 0 || !SemanticsBinding.instance.semanticsEnabled) return;
    final room = chat.roomById(widget.roomId);
    final all = room.isDm || room.id == 'faction' || room.id == 'company';
    _waiting.addAll(
      list.skip(from + 1).where((m) => !m.isSystem && m.sender.id != chat.myUserId && (all || chat.matchOf(m) != null)),
    );
    if (_waiting.isNotEmpty) _timer ??= Timer(ChatArrivals.batch, _announce);
  }

  void _announce() {
    _timer = null;
    if (!mounted || _waiting.isEmpty) return;
    final last = _waiting.last;
    final count = _waiting.length;
    final text = count == 1
        ? '${last.sender.name}: ${chatSpokenText(ChatQuote.excerpt(last.content))}'
        : _waiting.every((m) => m.sender.id == last.sender.id)
        ? '$count new messages from ${last.sender.name}'
        : '$count new messages, the last from ${last.sender.name}';
    _waiting.clear();
    SemanticsService.sendAnnouncement(View.of(context), text, Directionality.of(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Private chats left waiting for a reply
class ChatWaitingStrip extends StatefulWidget {
  const ChatWaitingStrip({
    super.key,
    required this.waiting,
    required this.onOpen,
    required this.onDismiss,
    required this.onDismissAll,
  });

  final List<(ChatRoom, ChatMessage)> waiting;
  final void Function(String roomId) onOpen;
  final void Function(String roomId) onDismiss;
  final VoidCallback onDismissAll;

  @override
  State<ChatWaitingStrip> createState() => _ChatWaitingStripState();
}

class _ChatWaitingStripState extends State<ChatWaitingStrip> {
  static bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.waiting.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    return Material(
      color: scheme.surfaceContainerLow,
      child: Column(
        children: [
          ListTile(
            minTileHeight: 48,
            leading: Icon(Icons.hourglass_top_rounded, color: scheme.primary),
            title: Text('Waiting for you (${widget.waiting.length})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expanded) TextButton(onPressed: widget.onDismissAll, child: const Text('Dismiss all')),
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            for (final (room, last) in widget.waiting)
              Dismissible(
                key: ValueKey('waiting-${room.id}-${last.id}'),
                background: ColoredBox(color: scheme.surfaceContainerHighest),
                onDismissed: (_) => widget.onDismiss(room.id),
                child: ListTile(
                  minTileHeight: 48,
                  dense: true,
                  leading: ChatRoomAvatar(room: room, size: 32),
                  title: Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ChatTimeRef.relative(last.createdAt, now),
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      IconButton(
                        tooltip: 'Dismiss',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => widget.onDismiss(room.id),
                      ),
                    ],
                  ),
                  onTap: () => widget.onOpen(room.id),
                ),
              ),
          Divider(height: 1, color: scheme.outlineVariant),
        ],
      ),
    );
  }
}

Future<void> showChatArchived(BuildContext context, void Function(String roomId) onOpen) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheet) => ListenableBuilder(
      listenable: Listenable.merge([NativeChat.prefs, NativeChat.controller]),
      builder: (_, _) {
        final rooms = NativeChat.controller.archivedDms;
        if (rooms.isEmpty) {
          return const ChatStateMessage(
            icon: Icons.archive_outlined,
            title: 'Nothing archived',
            subtitle: 'Archived private chats show up here',
          );
        }
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
          children: [
            for (final room in rooms)
              ListTile(
                leading: ChatRoomAvatar(room: room, size: 40),
                title: Text(NativeChat.prefs.displayName(ChatRoom.peerIdOf(room.id) ?? 0, room.name)),
                onTap: () {
                  Navigator.pop(sheet);
                  onOpen(room.id);
                },
                trailing: TextButton(
                  onPressed: () => NativeChat.prefs.setArchived(room.id, false),
                  child: const Text('Unarchive'),
                ),
              ),
          ],
        );
      },
    ),
  );
}

Future<void> showChatHiddenRooms(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheet) => ListenableBuilder(
      listenable: Listenable.merge([NativeChat.prefs, NativeChat.controller]),
      builder: (_, _) {
        final rooms = NativeChat.controller.hiddenRooms;
        if (rooms.isEmpty) {
          return const ChatStateMessage(
            icon: Icons.visibility_outlined,
            title: 'No hidden rooms',
            subtitle: 'Hidden rooms show up here',
          );
        }
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
          children: [
            for (final room in rooms)
              ListTile(
                leading: ChatRoomAvatar(room: room, size: 40),
                title: Text(room.name),
                trailing: TextButton(
                  onPressed: () => NativeChat.prefs.setRoomState(room.id, ChatRoomState.live),
                  child: const Text('Show'),
                ),
              ),
          ],
        );
      },
    ),
  );
}
