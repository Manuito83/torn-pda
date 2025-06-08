import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class StatusColorCounter extends StatefulWidget {
  const StatusColorCounter({
    super.key,
  });

  @override
  State<StatusColorCounter> createState() => StatusColorCounterState();
}

class StatusColorCounterState extends State<StatusColorCounter> {
  final _chainStatusProvider = Get.find<ChainStatusController>();
  bool _providerInitialised = false;

  bool _newKnownTimestamp = false;
  int _newTimeStampCount = 0;

  String? _formattedUntil;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _updateFormattedUntil(_chainStatusProvider.statusColorUntil);
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_providerInitialised) {
      // Activate API queries from the ChainStatusProvider if they are not already active
      _chainStatusProvider.startStatusColorRequests();
      _providerInitialised = true;
    }

    return GetBuilder<ChainStatusController>(
      builder: (controller) {
        bool showNew = false;
        String newText = "HOSP";
        if (_newKnownTimestamp && _newTimeStampCount < 6 && _newTimeStampCount.isEven) {
          showNew = true;
        }

        Color statusColor = Colors.red.shade700;
        switch (controller.statusColorCurrent) {
          case PlayerStatusColor.jail:
            statusColor = Colors.brown.shade700;
            newText = "JAIL";
            break;
          case PlayerStatusColor.travel:
            statusColor = Colors.blue.shade700;
            newText = "TRVL";
            break;
          default:
            break;
        }

        if (_formattedUntil == null) {
          return Container();
        }

        return SizedBox(
          width: 35,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Container(
              color: statusColor,
              child: Padding(
                padding: Platform.isAndroid
                    ? const EdgeInsets.fromLTRB(1, 1.5, 1, 0.5)
                    : const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
                child: Center(
                  child: Text(
                    showNew ? newText : _formattedUntil ?? "",
                    softWrap: false,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Make sure that we are updating from the provider whenever the browser is open
      String currentSource = Get.find<ChainStatusController>().statusUpdateSource;
      bool browserOnTop = context.read<WebViewProvider>().browserShowInForeground;
      if (browserOnTop && currentSource != "provider") {
        Get.find<ChainStatusController>().statusUpdateSource = "provider";
      }

      bool wasBlinking = _newKnownTimestamp;

      // Creates a count so that we can blink the condition (e.g.: "HOSP") whenever it's encountered
      if (_newKnownTimestamp && _newTimeStampCount < 5) {
        _newTimeStampCount++;
      } else if (_newKnownTimestamp && _newTimeStampCount >= 5) {
        _newKnownTimestamp = false;
        _newTimeStampCount = 0;
      }

      // Updates the timer string in the widget
      _updateFormattedUntil(_chainStatusProvider.statusColorUntil);
      if (mounted && (wasBlinking || _newKnownTimestamp)) {
        setState(() {
          // Update for blinks
        });
      }
    });
  }

  void _updateFormattedUntil(int colorUntil) {
    // Trigger new timestamp blinking letters
    if (colorUntil != _chainStatusProvider.lastWidgetKnownTimeStamp) {
      log("New timestamp for status color widget!");
      _newKnownTimestamp = true;
      _newTimeStampCount = 0;
      _chainStatusProvider.lastWidgetKnownTimeStamp = colorUntil;
    }

    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int untilSeconds = colorUntil - currentTime;

    String? newFormattedValue;

    // Timer has recently expired (within the last 60 seconds)
    if (untilSeconds <= 0 && untilSeconds > -60) {
      newFormattedValue = "END";
    }
    // Timer expired more than 60 seconds ago
    else if (untilSeconds <= -60) {
      newFormattedValue = null;
      if (_chainStatusProvider.statusColorIsShown) {
        _chainStatusProvider.statusColorIsShown = false;
      }
    }
    // Timer is still active (untilSeconds > 0)
    else {
      final double days = untilSeconds / (24 * 3600);
      // Remaining time is one day or more
      // Formats "2d" or "1.5d
      if (days >= 1) {
        final formattedDays = days.toStringAsFixed(1);
        final formattedDaysWithoutDecimal =
            formattedDays.endsWith('.0') ? formattedDays.substring(0, formattedDays.length - 2) : formattedDays;
        newFormattedValue = "${formattedDaysWithoutDecimal}d";
      }
      // Remaining time is less than one hour
      // Formats as "23:45"
      else if (untilSeconds <= 3599) {
        final int minutes = untilSeconds ~/ 60;
        final int seconds = untilSeconds % 60;
        newFormattedValue = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      }
      // Remaining time is between one hour and less than one day
      // Formats as "02h30"
      else {
        final int hours = untilSeconds ~/ 3600;
        final int minutes = (untilSeconds % 3600) ~/ 60;
        newFormattedValue = "${hours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}";
      }
    }

    if (mounted && _formattedUntil != newFormattedValue) {
      setState(() {
        _formattedUntil = newFormattedValue;
      });
    }
  }
}
