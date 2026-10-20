import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatFilterStrip extends StatelessWidget {
  const ChatFilterStrip({
    super.key,
    required this.hidden,
    required this.revealed,
    required this.onToggle,
    required this.onEdit,
  });

  final int hidden;
  final bool revealed;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSecondaryContainer);
    return Material(
      color: scheme.secondaryContainer,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_rounded, size: 16, color: scheme.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          revealed ? 'Filter paused - tap to apply' : '$hidden hidden by the filter - tap to show all',
                          style: style,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(tooltip: 'Edit filter', icon: const Icon(Icons.tune_rounded), onPressed: onEdit),
        ],
      ),
    );
  }
}

Future<void> showChatRoomFilter(BuildContext context, ChatRoom room) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(child: _ChatFilterSheet(room: room)),
    ),
  );
}

class _ChatFilterSheet extends StatelessWidget {
  const _ChatFilterSheet({required this.room});

  final ChatRoom room;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NativeChat.prefs,
      builder: (context, _) {
        final filter = NativeChat.prefs.filterOf(room.id);
        void save({List<String>? show, List<String>? hide}) =>
            NativeChat.prefs.setFilter(room.id, show: show ?? filter.show, hide: hide ?? filter.hide);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filter ${room.name}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Whole words, any case. Your own messages, mentions and highlight words always show',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _TermList(
                title: 'Show only',
                hint: 'Add a term to show only matches',
                terms: filter.show,
                onChanged: (v) => save(show: v),
              ),
              const SizedBox(height: 16),
              _TermList(
                title: 'Hide',
                hint: 'Add a term to hide',
                terms: filter.hide,
                onChanged: (v) => save(hide: v),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TermList extends StatefulWidget {
  const _TermList({required this.title, required this.hint, required this.terms, required this.onChanged});

  final String title;
  final String hint;
  final List<String> terms;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TermList> createState() => _TermListState();
}

class _TermListState extends State<_TermList> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _add() {
    final clean = _text.text.trim();
    _text.clear();
    if (clean.isEmpty || widget.terms.any((t) => t.toLowerCase() == clean.toLowerCase())) return;
    widget.onChanged([...widget.terms, clean]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
        if (widget.terms.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final t in widget.terms)
                InputChip(
                  label: Text(t),
                  deleteButtonTooltipMessage: 'Remove $t',
                  onDeleted: () => widget.onChanged(widget.terms.where((x) => x != t).toList()),
                ),
            ],
          ),
        TextField(
          controller: _text,
          maxLength: ChatPrefs.maxWordLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _add(),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            isDense: true,
            suffixIcon: IconButton(tooltip: 'Add', icon: const Icon(Icons.add_rounded), onPressed: _add),
          ),
        ),
      ],
    );
  }
}
