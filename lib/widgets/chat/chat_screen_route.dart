import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';

class ChatScreenRoute<T> extends MaterialPageRoute<T> {
  ChatScreenRoute({required this.chat, required Widget page}) : super(builder: (_) => page);

  final ChatController chat;

  bool _overRoot = false;
  CurvedAnimation? _rootFade;

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    _overRoot = defaultTargetPlatform == TargetPlatform.android && _keepsBelowStill(previousRoute);
    super.didChangePrevious(previousRoute);
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      !_keepsBelowStill(previousRoute) && super.canTransitionFrom(previousRoute);

  @override
  Widget buildContent(BuildContext context) => InheritedProvider<ChatController>.value(
    value: chat,
    startListening: (element, value) => listenAfterEntrance(
      value,
      defaultTargetPlatform == TargetPlatform.android ? animation! : kAlwaysCompleteAnimation,
      element.markNeedsNotifyDependents,
    ),
    child: ChatTheme(child: super.buildContent(context)),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transition = super.buildTransitions(context, animation, secondaryAnimation, child);
    if (!_overRoot) return transition;
    // Root page fade, without moving it
    final fade = _rootFade ??= CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.25),
      reverseCurve: const Interval(0.25, 1),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: fade,
          child: ColoredBox(color: Theme.of(context).colorScheme.surface),
        ),
        transition,
      ],
    );
  }

  @override
  void dispose() {
    _rootFade?.dispose();
    super.dispose();
  }
}

bool _keepsBelowStill(Route<dynamic>? below) => below is PageRoute && below.isFirst;

VoidCallback listenAfterEntrance(Listenable source, Animation<double> entrance, VoidCallback onChange) {
  var held = false;
  // A back gesture also reports forward
  var entered = false;
  void changed() {
    if (!entered && entrance.status == AnimationStatus.forward) {
      held = true;
    } else {
      onChange();
    }
  }

  void settled(AnimationStatus status) {
    if (status == AnimationStatus.forward) return;
    entered = true;
    if (!held) return;
    held = false;
    onChange();
  }

  source.addListener(changed);
  entrance.addStatusListener(settled);
  return () {
    source.removeListener(changed);
    entrance.removeStatusListener(settled);
  };
}
