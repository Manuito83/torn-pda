import 'package:flutter/material.dart';

class BrowserReloadButton extends StatelessWidget {
  const BrowserReloadButton({required this.isReloading, required this.color, required this.onPressed, super.key});

  final bool isReloading;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      tooltip: isReloading ? 'Reloading page' : 'Reload page',
      // Stays tappable while reloading: hammering refresh is how users get an
      // unresponsive page moving again, so the spinner is feedback, not a lock
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: isReloading
            ? SizedBox(
                key: const ValueKey('browser-reload-progress'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(color)),
              )
            : Icon(Icons.refresh, key: const ValueKey('browser-reload-icon'), color: color),
      ),
    );
  }
}
