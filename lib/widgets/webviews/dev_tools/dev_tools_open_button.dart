import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart'; // Asegúrate de que la ruta es correcta

class DevToolsCooldownButton extends StatefulWidget {
  final VoidCallback onPressed;

  const DevToolsCooldownButton({super.key, required this.onPressed});

  @override
  State<DevToolsCooldownButton> createState() => _DevToolsCooldownButtonState();
}

class _DevToolsCooldownButtonState extends State<DevToolsCooldownButton> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime endTime) {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = endTime.difference(DateTime.now()).inSeconds;
      if (remaining >= 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining = remaining;
          });
        }
      } else {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WebViewProvider>(
      builder: (context, webViewProvider, child) {
        final cooldownTime = webViewProvider.devToolsReopenTime;
        final bool isDisabled = cooldownTime != null;

        if (isDisabled) {
          if (_timer == null) {
            _secondsRemaining = cooldownTime.difference(DateTime.now()).inSeconds;
            _startTimer(cooldownTime);
          }
        } else if (!isDisabled && _timer != null) {
          _timer?.cancel();
          _timer = null;
        }

        Widget buttonChild;
        if (isDisabled) {
          buttonChild = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Text("Dev Tools in $_secondsRemaining s"),
            ],
          );
        } else {
          buttonChild = const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build_circle_outlined),
              SizedBox(width: 8),
              Text("Open Dev Tools"),
            ],
          );
        }

        return ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          child: buttonChild,
        );
      },
    );
  }
}
