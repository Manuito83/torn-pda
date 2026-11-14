import 'package:flutter/widgets.dart';

/// Unknown state counts as shown
bool appInBackground() => switch (WidgetsBinding.instance.lifecycleState) {
  AppLifecycleState.paused || AppLifecycleState.hidden || AppLifecycleState.detached => true,
  _ => false,
};
