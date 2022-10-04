import 'dart:async';

import 'package:flutter/material.dart';

class Countdown extends StatefulWidget {
  final int seconds;
  final Function callback;

  Countdown({
    @required this.seconds,
    this.callback,
    Key key,
  }) : super(key: key);

  @override
  State<Countdown> createState() => _CurrentRetalExpiryWidgetState();
}

class _CurrentRetalExpiryWidgetState extends State<Countdown> {
  Timer _expiryTicker;

  Widget _currentExpiryWidget;

  int _currentSeconds = 0;

  @override
  void initState() {
    super.initState();
    _expiryTicker = new Timer.periodic(Duration(seconds: 1), (Timer t) => _timerExpiry());
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
      widget.callback();
    }

    setState(() {
      _currentExpiryWidget = Text(
        _currentSeconds.toString(),
      );
    });
  }
}
