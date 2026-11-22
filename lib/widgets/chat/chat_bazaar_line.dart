import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/chat/chat_bazaar_sources.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Seller bazaar state, nothing if unknown
class ChatBazaarLine extends StatefulWidget {
  const ChatBazaarLine({super.key, required this.sellerId, required this.item, this.style, this.prefix = ''});

  final int sellerId;
  final String item;
  final TextStyle? style;
  final String prefix;

  @override
  State<ChatBazaarLine> createState() => _ChatBazaarLineState();
}

class _ChatBazaarLineState extends State<ChatBazaarLine> {
  bool _loading = true;
  ChatBazaarState? _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await ChatLinkPreviews.bazaar.state(widget.sellerId);
    if (mounted) {
      setState(() {
        _state = state;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 4, left: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: 80, child: LinearProgressIndicator(minHeight: 2)),
        ),
      );
    }
    final text = switch (_state) {
      ChatBazaarState.open => 'Bazaar open',
      ChatBazaarState.closed => 'Bazaar closed',
      ChatBazaarState.none => 'No bazaar',
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text('${widget.prefix}$text', style: widget.style),
          if (_state == ChatBazaarState.open)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () =>
                  NativeChat.openLink(chatPlayerUrl('bazaar', widget.sellerId)!, always: true, fill: widget.item),
              child: const Text('Open bazaar'),
            ),
        ],
      ),
    );
  }
}
