import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/models/chat/chat_template.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Swapped in tests
Future<Object?> Function() chatStatusFetch = ApiCallsV1.getBarsAndPlayerStatus;

int _chainCurrent(ChainStatusController? chain) {
  final chaining = chain != null && (chain.statusActive || chain.watcherActive);
  final details = chain?.chainModel?.chain;
  return chaining && details?.cooldown == 0 ? details?.current ?? 0 : 0;
}

/// Slots from memory, status call if stale
Future<Map<String, String>> chatSlotValues({String? name, String? me, bool fetch = false}) async {
  final chain = Get.isRegistered<ChainStatusController>() ? Get.find<ChainStatusController>() : null;
  var bars = chain?.barsAndStatusModel;
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if (fetch && now - (bars?.serverTime ?? 0) > ChatStatus.barsMaxAge.inSeconds) {
    try {
      final fetched = await chatStatusFetch();
      if (fetched is BarsStatusCooldownsModel) bars = fetched;
    } catch (_) {}
  }
  final user = Get.isRegistered<UserController>() ? Get.find<UserController>() : null;
  final id = [NativeChat.controller.myUserId, user?.playerId].firstWhere((v) => v != null && v > 0, orElse: () => null);
  return ChatTemplate.values(
    now: now,
    bars: bars,
    chainCurrent: _chainCurrent(chain),
    chainSeconds: chain?.currentSecondsCounter ?? 0,
    name: name,
    me: me,
    item: ChatTemplate.lastItem,
    faction: user?.basic?.faction?.factionName,
    bazaar: id == null ? null : chatPlayerUrl('bazaar', id),
    trade: id == null ? null : chatPlayerUrl('trade', id),
    profile: id == null ? null : chatPlayerUrl('profile', id),
  );
}

Future<void> showChatStatusSheet(BuildContext context, ValueChanged<String> onInsert) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _StatusSheet(onInsert: onInsert),
  );
}

class _StatusSheet extends StatefulWidget {
  const _StatusSheet({required this.onInsert});

  final ValueChanged<String> onInsert;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  late final Set<String> _on = {...NativeChat.prefs.statusPieces};
  final ChainStatusController? _chain = Get.isRegistered<ChainStatusController>()
      ? Get.find<ChainStatusController>()
      : null;
  late BarsStatusCooldownsModel? _bars = _chain?.barsAndStatusModel;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final age = now - (_bars?.serverTime ?? 0);
    if (age <= ChatStatus.barsMaxAge.inSeconds) return;
    _loading = true;
    _fetch();
  }

  // One call per sheet, only when stale
  Future<void> _fetch() async {
    Object? fetched;
    try {
      fetched = await chatStatusFetch();
    } catch (_) {
      fetched = null;
    }
    if (!mounted) return;
    setState(() {
      if (fetched is BarsStatusCooldownsModel) _bars = fetched;
      _loading = false;
    });
  }

  List<ChatStatusPiece> _pieces() {
    final bars = _bars;
    if (bars == null) return const [];
    final chain = _chain;
    return ChatStatus.pieces(
      bars: bars,
      now: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      chainCurrent: _chainCurrent(chain),
      chainSeconds: chain?.currentSecondsCounter ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pieces = _pieces();
    final text = ChatStatus.compose(pieces, _on);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Insert my status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (pieces.isEmpty)
              Text(
                'Could not load your status. Check your API key and try again later',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            for (final piece in pieces)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(piece.label),
                secondary: Text(piece.text, style: theme.textTheme.bodySmall),
                value: _on.contains(piece.key),
                onChanged: (value) => setState(() => value == true ? _on.add(piece.key) : _on.remove(piece.key)),
              ),
            if (text.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(text),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: text.isEmpty
                    ? null
                    : () {
                        final keys = pieces.map((p) => p.key).toSet();
                        NativeChat.prefs.setStatusPieces({...NativeChat.prefs.statusPieces.difference(keys), ..._on});
                        Navigator.of(context).pop();
                        widget.onInsert(text);
                      },
                child: const Text('Insert'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
