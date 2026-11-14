import 'dart:async';

import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_mentions.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/models/chat/chat_share.dart';
import 'package:torn_pda/models/chat/chat_short_text.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/widgets/chat/chat_compose_tools.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_motion.dart';
import 'package:torn_pda/widgets/chat/chat_send_check_dialog.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.roomName,
    required this.enabled,
    required this.onSend,
    this.blockerText,
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
  final String? blockerText;

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
  late final ChatImageUpload _uploads = context.read<ChatImageUpload?>() ?? ChatImageUpload();

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
    NativeChat.controller.sharePending.addListener(_takeShared);
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
      file = await _uploads.pick(fromFiles: fromFiles);
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
      final link = await _uploads.upload(
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
    NativeChat.controller.sharePending.removeListener(_takeShared);
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
                      ? widget.blockerText ?? 'You can\'t write in ${widget.roomName}'
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
                              ChatQuote.excerpt(
                                chatShortText(reply.content, reply.createdAt, clock: chatClockOf(context).clock),
                              ),
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
