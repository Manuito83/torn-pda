import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_hit_target.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_player_card_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';

class ChatHitPicker extends StatefulWidget {
  const ChatHitPicker({
    super.key,
    required this.targets,
    required this.card,
    required this.ops,
    required this.prefs,
    required this.empty,
    required this.onAttack,
    this.onCalled,
    this.canCall = true,
    this.roomId = ChatFactionOps.roomId,
    this.header = const [],
  });

  /// In the page order
  final List<ChatHitTarget> targets;
  final Widget Function(ChatHitTarget target) card;
  final ChatFactionOps ops;
  final ChatPrefs prefs;
  final String roomId;

  /// Shown without targets
  final String empty;

  /// Scrolls above the targets
  final List<Widget> header;

  final bool canCall;
  final ValueChanged<ChatHitTarget> onAttack;
  final VoidCallback? onCalled;

  @override
  State<ChatHitPicker> createState() => _ChatHitPickerState();
}

class _ChatHitPickerState extends State<ChatHitPicker> {
  static const _choices = [10, 20, 30, 60];

  int? _picked;
  int _seconds = 30;
  bool _custom = false;
  bool _whenOut = false;
  final TextEditingController _customText = TextEditingController(text: '45');
  Timer? _refresh;

  @override
  void dispose() {
    _refresh?.cancel();
    _customText.dispose();
    super.dispose();
  }

  /// Null when empty or 0
  int? _secsFor(int? out) {
    if (_whenOut && out != null) return out;
    if (!_custom) return _seconds;
    final typed = int.tryParse(_customText.text) ?? 0;
    return typed < 1 ? null : math.min(typed, chatHitCallMax);
  }

  void _select(ChatHitTarget target) => setState(() => _picked = target.id);

  void _announce(ChatHitTarget target, int seconds) {
    widget.ops.callHit(target, seconds, room: widget.roomId, link: widget.prefs.hitCallLink);
    widget.onCalled?.call();
  }

  void _planRefresh(DateTime? at) {
    _refresh?.cancel();
    if (at == null) return;
    _refresh = Timer(at.difference(DateTime.now()), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
    final now = DateTime.now();
    final list = widget.targets;
    final target =
        list.where((t) => t.id == _picked).firstOrNull ?? (list.isEmpty ? null : list[chatFirstReady(list, now)]);
    _planRefresh(chatNextReadyChange(list, now));
    final header = widget.header;
    final empty = Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(widget.empty, style: muted),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (list.isEmpty && header.isEmpty)
          empty
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(top: header.isEmpty ? 6 : 0),
              itemCount: header.length + (list.isEmpty ? 1 : list.length),
              itemBuilder: (context, i) => i < header.length
                  ? header[i]
                  : list.isEmpty
                  ? empty
                  : _row(list[i - header.length], list[i - header.length].id == target?.id),
            ),
          ),
        ChatTicking(
          until: target?.until,
          builder: (context) {
            final out = target == null ? null : chatSecondsUntilOut(target, DateTime.now());
            final whenOut = _whenOut && out != null;
            final seconds = _secsFor(out);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('in', style: muted),
                      for (final s in _choices)
                        ChoiceChip(
                          label: Text('${s}s'),
                          selected: !_custom && !whenOut && _seconds == s,
                          onSelected: (_) => setState(() {
                            _custom = false;
                            _whenOut = false;
                            _seconds = s;
                          }),
                        ),
                      if (out != null)
                        ChoiceChip(
                          label: Text('When out (${out}s)'),
                          selected: whenOut,
                          onSelected: (_) => setState(() {
                            _custom = false;
                            _whenOut = true;
                          }),
                        ),
                      if (_custom)
                        SizedBox(
                          width: 76,
                          child: TextField(
                            controller: _customText,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Seconds',
                              suffixText: 's',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                          ),
                        )
                      else
                        ChoiceChip(
                          label: const Text('...', semanticsLabel: 'Other time'),
                          selected: false,
                          onSelected: (_) => setState(() {
                            _custom = true;
                            _whenOut = false;
                          }),
                        ),
                      FilterChip(
                        label: const Text('Link'),
                        tooltip: 'Attack link for the web chat. Without it, PDA joins only targets in Targets or War',
                        selected: widget.prefs.hitCallLink,
                        onSelected: (on) => setState(() => widget.prefs.setHitCallLink(on)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: chatSecondaryButton(scheme),
                          onPressed: !widget.canCall || target == null || seconds == null || !widget.ops.chat.available
                              ? null
                              : () => _announce(
                                  target,
                                  _whenOut ? chatSecondsUntilOut(target, DateTime.now()) ?? seconds : seconds,
                                ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: Text(
                            seconds == null ? 'Hitting' : 'Hitting in ${seconds}s',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: target == null ? null : () => widget.onAttack(target),
                          icon: const Icon(MaterialCommunityIcons.sword_cross),
                          label: Text(
                            target == null ? 'Attack' : 'Attack ${target.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: 12 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  Widget _row(ChatHitTarget t, bool selected) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _select(t),
      child: Row(
        children: [
          Semantics(
            button: true,
            selected: selected,
            inMutuallyExclusiveGroup: true,
            label: t.name,
            onTapHint: 'pick as the target',
            onTap: () => _select(t),
            excludeSemantics: true,
            child: SizedBox(
              width: 36,
              child: Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ),
          ),
          Expanded(child: widget.card(t)),
        ],
      ),
    );
  }
}
