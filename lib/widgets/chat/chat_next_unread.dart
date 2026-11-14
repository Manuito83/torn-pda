import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatNextUnreadButton extends StatelessWidget {
  const ChatNextUnreadButton({super.key, required this.count, required this.onNext});

  final int count;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Next unread, $count waiting',
      icon: Badge(
        label: ExcludeSemantics(child: Text(count > 99 ? '99+' : '$count')),
        child: const Icon(Icons.skip_next_rounded),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onNext();
      },
    );
  }
}

/// Swipe in from the right edge
class ChatNextUnreadEdge extends StatelessWidget {
  const ChatNextUnreadEdge({super.key, required this.enabled, required this.onNext, required this.child});

  final bool enabled;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 20,
          // The header button does it for readers
          child: GestureDetector(
            excludeFromSemantics: true,
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > -300) return;
              HapticFeedback.lightImpact();
              onNext();
            },
          ),
        ),
      ],
    );
  }
}

class ChatUnreadAbove extends StatelessWidget {
  const ChatUnreadAbove({super.key, required this.label, required this.onJump, required this.onRead});

  final String label;
  final VoidCallback onJump;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSecondaryContainer;
    return Material(
      color: scheme.secondaryContainer,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            child: InkWell(
              onTap: onJump,
              child: SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_double_arrow_up_rounded, size: 18, color: color),
                      const SizedBox(width: 8),
                      Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Mark as read',
            onPressed: onRead,
            icon: Icon(Icons.close_rounded, size: 18, color: color),
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
