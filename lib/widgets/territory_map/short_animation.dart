import 'dart:async';

import 'package:flutter/widgets.dart';

// About 8 frames a second, for 10 s
const shortAnimationEvery = Duration(milliseconds: 125);
const _framesPerRun = 80;

// Hidden behind the browser too
bool animationsShown(BuildContext context) =>
    TickerMode.valuesOf(context).enabled && Visibility.of(context) && !MediaQuery.disableAnimationsOf(context);

bool get appResumed =>
    (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) == AppLifecycleState.resumed;

// Ticks for a short run while seen
class ShortAnimation {
  ShortAnimation({required this.inView, required this.onTick}) {
    _lifecycle = AppLifecycleListener(onStateChange: (_) => sync());
  }

  final bool Function() inView;
  final VoidCallback onTick;
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;
  bool _shown = false;
  int _framesLeft = _framesPerRun;

  // From didChangeDependencies
  void showIn(BuildContext context) {
    final shown = animationsShown(context);
    if (shown && !_shown) _framesLeft = _framesPerRun;
    _shown = shown;
    sync();
  }

  void restart() => _framesLeft = _framesPerRun;

  void sync() {
    if (_shown && appResumed && _framesLeft > 0 && inView()) {
      _timer ??= Timer.periodic(shortAnimationEvery, (_) {
        onTick();
        if (--_framesLeft > 0) return;
        _timer?.cancel();
        _timer = null;
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    _lifecycle.dispose();
    _timer?.cancel();
  }
}
