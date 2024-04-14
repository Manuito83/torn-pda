import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';

class StatusColorCounter extends StatefulWidget {
  const StatusColorCounter({
    Key? key,
  }) : super(key: key);

  @override
  State<StatusColorCounter> createState() => StatusColorCounterState();
}

class StatusColorCounterState extends State<StatusColorCounter> {
  ChainStatusProvider? _chainStatusProvider;
  String? _formattedUntil;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: true);

    if (_chainStatusProvider?.statusColorUntil == 0 || _chainStatusProvider == null || _formattedUntil == null) {
      return SizedBox.shrink();
    }

    Color statusColor = Colors.red.shade700;
    switch (_chainStatusProvider?.statusColorCurrent) {
      case PlayerStatusColor.jail:
        statusColor = Colors.brown.shade700;
        break;
      case PlayerStatusColor.travel:
        statusColor = Colors.blue.shade700;
        break;
      default:
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        color: statusColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 3),
          child: Text(
            _formattedUntil!,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _startTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateFormattedUntil();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateFormattedUntil() {
    if (_chainStatusProvider == null) return;
    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int untilSeconds = _chainStatusProvider!.statusColorUntil - currentTime;

    if (untilSeconds <= 0) {
      setState(() {
        _formattedUntil = "END";
      });
      return;
    }

    final int days = untilSeconds ~/ (24 * 3600);
    final int remainingHours = untilSeconds % (24 * 3600) ~/ 3600;
    final int remainingMinutes = (untilSeconds % 3600) ~/ 60;

    if (days > 0) {
      setState(() {
        _formattedUntil = "${days.toString()}d";
      });
    } else if (remainingHours > 0) {
      setState(() {
        _formattedUntil = "${remainingHours.toString()}h";
      });
    } else {
      setState(() {
        _formattedUntil = "${remainingMinutes.toString()}m";
      });
    }
  }
}
