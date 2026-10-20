import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';

enum ChatWatchCondition {
  online('Notify me when online'),
  okay('Notify me when out of hospital'),
  freed('Notify me when out of jail'),
  landed('Notify me when landed');

  const ChatWatchCondition(this.label);

  final String label;

  static ChatWatchCondition forKind(ChatStatusKind? kind) => switch (kind) {
    ChatStatusKind.hospital => okay,
    ChatStatusKind.jail => freed,
    ChatStatusKind.travel => landed,
    _ => online,
  };
}

/// One tap toggles the stakeout
class ChatWatchButton extends StatefulWidget {
  const ChatWatchButton({super.key, required this.id});

  final int id;

  @override
  State<ChatWatchButton> createState() => _ChatWatchButtonState();
}

class _ChatWatchButtonState extends State<ChatWatchButton> {
  ChatPlayerCard? _card;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _card = ChatPlayerCards.peek(widget.id);
    ChatPlayerCards.load(widget.id).then((card) {
      if (mounted && card != null) setState(() => _card = card);
    });
  }

  Future<void> _toggle(StakeoutsController stakeouts, bool watched) async {
    if (watched) {
      final index = stakeouts.stakeouts.indexWhere((s) => s.id == '${widget.id}');
      final removed = stakeouts.stakeouts[index];
      stakeouts.removeStakeout(removeId: removed.id);
      chatToast(
        'Stopped watching',
        seconds: 5,
        action: 'Undo',
        onAction: () {
          if (stakeouts.stakeouts.any((s) => s.id == removed.id)) return;
          stakeouts.stakeouts.insert(index.clamp(0, stakeouts.stakeouts.length), removed);
          stakeouts.savePreferences();
          stakeouts.update();
        },
      );
      return;
    }
    final condition = ChatWatchCondition.forKind(_card?.kind);
    setState(() => _busy = true);
    final result = await stakeouts.addStakeout(inputId: '${widget.id}');
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.success) {
      chatToast('Could not watch: ${result.error.isEmpty ? 'try again' : result.error}');
      return;
    }
    final stakeout = stakeouts.stakeouts.firstWhere((s) => s.id == '${widget.id}');
    switch (condition) {
      case ChatWatchCondition.online:
        await stakeouts.setOnline(stakeout: stakeout, onlineEnabled: true);
      case ChatWatchCondition.okay || ChatWatchCondition.freed:
        await stakeouts.setOkay(stakeout: stakeout, okayEnabled: true);
      case ChatWatchCondition.landed:
        await stakeouts.setLanded(stakeout: stakeout, landedEnabled: true);
    }
    if (!mounted) return;
    chatToast(stakeouts.stakeoutsEnabled == true ? 'Watching' : 'Watching, but stakeouts are off in Torn PDA');
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StakeoutsController>()) return const SizedBox.shrink();
    return GetBuilder<StakeoutsController>(
      builder: (stakeouts) {
        final watched = stakeouts.stakeouts.any((s) => s.id == '${widget.id}');
        final label = watched ? 'Watching' : ChatWatchCondition.forKind(_card?.kind).label;
        final icon = Icon(watched ? Icons.visibility_rounded : Icons.visibility_outlined);
        final onPressed = _busy ? null : () => _toggle(stakeouts, watched);
        return _ChatToggleChip(label: label, icon: icon, selected: watched, busy: _busy, onPressed: onPressed);
      },
    );
  }
}

/// Target and friend toggles, one tap each
class ChatPlayerListToggles extends StatefulWidget {
  const ChatPlayerListToggles({super.key, required this.id});

  final int id;

  @override
  State<ChatPlayerListToggles> createState() => _ChatPlayerListTogglesState();
}

class _ChatPlayerListTogglesState extends State<ChatPlayerListToggles> {
  bool _busyTarget = false;
  bool _busyFriend = false;

  Future<void> _toggleTarget(TargetsProvider targets, bool isTarget) async {
    if (isTarget) {
      final removed = targets.allTargets.firstWhere((t) => t.playerId == widget.id);
      targets.deleteTargetById('${widget.id}');
      chatToast('Removed from targets', seconds: 5, action: 'Undo', onAction: () => targets.restoreTarget(removed));
      return;
    }
    setState(() => _busyTarget = true);
    final attacks = await targets.getAttacks();
    final result = await targets.addTarget(targetId: '${widget.id}', attacks: attacks);
    if (!mounted) return;
    setState(() => _busyTarget = false);
    chatToast(result.success ? 'Added to targets' : 'Could not add: ${result.errorReason}');
  }

  Future<void> _toggleFriend(FriendsProvider friends, bool isFriend) async {
    if (isFriend) {
      final removed = friends.allFriends.firstWhere((f) => f.playerId == widget.id);
      friends.deleteFriend(removed);
      chatToast('Removed from friends', seconds: 5, action: 'Undo', onAction: () => friends.restoreFriend(removed));
      return;
    }
    setState(() => _busyFriend = true);
    final result = await friends.addFriend('${widget.id}');
    if (!mounted) return;
    setState(() => _busyFriend = false);
    chatToast(result.success ? 'Added to friends' : 'Could not add: ${result.errorReason}');
  }

  @override
  Widget build(BuildContext context) {
    final targets = context.watch<TargetsProvider?>();
    final friends = context.watch<FriendsProvider?>();
    final isTarget = targets?.allTargets.any((t) => t.playerId == widget.id) ?? false;
    final isFriend = friends?.allFriends.any((f) => f.playerId == widget.id) ?? false;
    return Wrap(
      spacing: 8,
      children: [
        if (targets != null)
          _ChatToggleChip(
            label: isTarget ? 'Target' : 'Add target',
            icon: Icon(isTarget ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded),
            selected: isTarget,
            busy: _busyTarget,
            onPressed: _busyTarget ? null : () => _toggleTarget(targets, isTarget),
          ),
        if (friends != null)
          _ChatToggleChip(
            label: isFriend ? 'Friend' : 'Add friend',
            icon: Icon(isFriend ? Icons.favorite_rounded : Icons.favorite_border_rounded),
            selected: isFriend,
            busy: _busyFriend,
            onPressed: _busyFriend ? null : () => _toggleFriend(friends, isFriend),
          ),
      ],
    );
  }
}

class _ChatToggleChip extends StatelessWidget {
  const _ChatToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final Icon icon;
  final bool selected;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      toggled: selected,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: selected ? scheme.secondaryContainer : null,
          foregroundColor: selected ? scheme.onSecondaryContainer : scheme.primary,
        ),
        onPressed: onPressed,
        icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : icon,
        label: Text(label),
      ),
    );
  }
}
