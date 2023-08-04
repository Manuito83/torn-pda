import 'dart:async';

import 'package:flutter/material.dart';

class Countdown extends StatefulWidget {
  final int seconds;
  final Function? callback;

  const Countdown({
    required this.seconds,
    this.callback,
    super.key,
  });

  @override
  State<Countdown> createState() => _CurrentRetalExpiryWidgetState();
}

class _CurrentRetalExpiryWidgetState extends State<Countdown> {
  Timer? _expiryTicker;

  late Widget _currentExpiryWidget;

  int _currentSeconds = 0;

  @override
  void initState() {
    super.initState();
    _expiryTicker = Timer.periodic(const Duration(seconds: 1), (Timer t) => _timerExpiry());
    _currentSeconds = widget.seconds;
    _currentExpiryWidget = Text(
      _currentSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _expiryTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _currentExpiryWidget;
  }

  void _timerExpiry() {
    if (!mounted) return;

    if (_currentSeconds > 0) {
      _currentSeconds--;
    } else {
      _currentSeconds = widget.seconds;
      widget.callback!();
    }

    setState(() {
      _currentExpiryWidget = Text(
        _currentSeconds.toString(),
      );
    });
  }
}
