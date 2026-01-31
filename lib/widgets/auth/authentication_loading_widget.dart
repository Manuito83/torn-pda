import 'dart:async';

import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';

enum _PhaseStatus { pending, active, completed }

class AuthenticationLoadingWidget extends StatefulWidget {
  final ThemeProvider themeProvider;
  final VoidCallback? onCaptiveFinished;
  final VoidCallback? onFinalWindowStarted;

  const AuthenticationLoadingWidget({
    super.key,
    required this.themeProvider,
    this.onCaptiveFinished,
    this.onFinalWindowStarted,
  });

  @override
  State<AuthenticationLoadingWidget> createState() => _AuthenticationLoadingWidgetState();
}

class _AuthenticationLoadingWidgetState extends State<AuthenticationLoadingWidget> with TickerProviderStateMixin {
  static const int _captiveDurationSeconds = 15;
  static const int _finalWindowSeconds = 7; // trigger final recovery from second 8 onward
  static const List<String> _phases = [
    'Checking existing session',
    'Reconnecting...',
    'Still trying...',
    'Checking local data',
    'Syncing from cloud',
    'Creating new session',
  ];
  late List<AnimationController> _waveControllers;
  late List<Animation<double>> _waveAnimations;
  Timer? _captiveTimer;
  bool _hasNotifiedCompletion = false;
  bool _finalWindowNotified = false;
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
      if (!_finalWindowNotified && nextRemaining <= _finalWindowSeconds) {
        _finalWindowNotified = true;
        widget.onFinalWindowStarted?.call();
      }
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
        const SizedBox(height: 24),
        _buildPhases(),
      ],
    );
  }

  Widget _buildPhases() {
    final activeIndex = _currentPhaseIndex();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _phases.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final status = index < activeIndex
              ? _PhaseStatus.completed
              : index == activeIndex
                  ? _PhaseStatus.active
                  : _PhaseStatus.pending;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhaseIcon(status),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _phaseColor(status),
                      fontSize: 14,
                      fontWeight: status == _PhaseStatus.active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  int _currentPhaseIndex() {
    if (_finalWindowNotified) return _phases.length - 1;

    if (_secondsRemaining > 12) return 0; // Initial checks
    if (_secondsRemaining > 9) return 1; // Retry 1
    if (_secondsRemaining > 6) return 2; // Retry 2
    if (_secondsRemaining > 3) return 3; // Local snapshot
    return 4; // Cloud sync before final window
  }

  Color _phaseColor(_PhaseStatus status) {
    switch (status) {
      case _PhaseStatus.completed:
        return widget.themeProvider.mainText.withValues(alpha: 0.6);
      case _PhaseStatus.active:
        return widget.themeProvider.mainText;
      case _PhaseStatus.pending:
        return widget.themeProvider.mainText.withValues(alpha: 0.45);
    }
  }

  Widget _buildPhaseIcon(_PhaseStatus status) {
    switch (status) {
      case _PhaseStatus.completed:
        return Icon(Icons.check_circle, color: widget.themeProvider.mainText.withValues(alpha: 0.7), size: 18);
      case _PhaseStatus.active:
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(widget.themeProvider.mainText),
          ),
        );
      case _PhaseStatus.pending:
        return Icon(Icons.radio_button_unchecked,
            color: widget.themeProvider.mainText.withValues(alpha: 0.35), size: 18);
    }
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
