import 'dart:async';

import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class AuthenticationLoadingWidget extends StatefulWidget {
  final ThemeProvider themeProvider;
  final VoidCallback? onCaptiveFinished;

  const AuthenticationLoadingWidget({
    super.key,
    required this.themeProvider,
    this.onCaptiveFinished,
  });

  @override
  State<AuthenticationLoadingWidget> createState() => _AuthenticationLoadingWidgetState();
}

class _AuthenticationLoadingWidgetState extends State<AuthenticationLoadingWidget> with TickerProviderStateMixin {
  static const int _captiveDurationSeconds = 10;
  late List<AnimationController> _waveControllers;
  late List<Animation<double>> _waveAnimations;
  Timer? _captiveTimer;
  bool _hasNotifiedCompletion = false;
  int _secondsRemaining = _captiveDurationSeconds;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCaptiveTimer();
  }

  void _initializeAnimations() {
    _waveControllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 1500 + (index * 200)),
        vsync: this,
      );
    });

    _waveAnimations = _waveControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    for (int i = 0; i < _waveControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _waveControllers[i].repeat();
        }
      });
    }
  }

  void _startCaptiveTimer() {
    _captiveTimer?.cancel();
    _secondsRemaining = _captiveDurationSeconds;
    _hasNotifiedCompletion = false;

    _captiveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextRemaining = _captiveDurationSeconds - timer.tick;
      if (nextRemaining <= 0) {
        setState(() {
          _secondsRemaining = 0;
        });
        timer.cancel();
        _notifyCaptiveFinished();
      } else {
        setState(() {
          _secondsRemaining = nextRemaining;
        });
      }
    });
  }

  void _notifyCaptiveFinished() {
    if (_hasNotifiedCompletion) return;
    _hasNotifiedCompletion = true;
    widget.onCaptiveFinished?.call();
  }

  @override
  void dispose() {
    _captiveTimer?.cancel();
    for (final controller in _waveControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Syncing your session...',
          style: TextStyle(
            color: widget.themeProvider.mainText,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 30),
        const CircularProgressIndicator(),
        const SizedBox(height: 30),
        _buildSignalRow(),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "We're reloading your preferences from the server",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.themeProvider.mainText.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Please keep the app open (${_secondsRemaining}s)',
          style: TextStyle(
            color: widget.themeProvider.mainText.withValues(alpha: 0.7),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSignalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                AnimatedBuilder(
                  animation: _waveAnimations[i],
                  builder: (context, child) {
                    return Container(
                      width: 20 + (_waveAnimations[i].value * (20 + i * 10)),
                      height: 20 + (_waveAnimations[i].value * (20 + i * 10)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.themeProvider.mainText.withValues(
                            alpha: (1.0 - _waveAnimations[i].value) * 0.5,
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              Icon(
                Icons.cell_tower,
                size: 28,
                color: widget.themeProvider.mainText,
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const Image(
              image: AssetImage('images/icons/torn_pda.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
