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
          child: GestureDetector(
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
