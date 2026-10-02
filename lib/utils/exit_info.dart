import 'dart:developer';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ExitInfo {
  static const MethodChannel _platform = MethodChannel('tornpda.channel');

  static Future<void> reportPreviousExits() async {
    if (!Platform.isAndroid) return;
    try {
      final exits = await _platform.invokeListMethod<Map>('getProcessExitReasons');
      if (exits == null || exits.isEmpty) return;

      final int lastRendererGoneMs = await Prefs().getLastRendererGoneMs();
      for (final exit in exits) {
        // ApplicationExitInfo.REASON_SIGNALED
        if (exit['reason'] != 2) continue;

        final int status = exit['status'] as int;
        final int importance = exit['importance'] as int;
        final int timestamp = exit['timestamp'] as int;
        final int secsSinceRg = lastRendererGoneMs > 0 && lastRendererGoneMs <= timestamp
            ? (timestamp - lastRendererGoneMs) ~/ 1000
            : -1;

        // Background kills might be noise unless a renderer death just happened
        if (importance > 200 && (secsSinceRg < 0 || secsSinceRg > 60)) continue;

        log("App killed by signal: status=$status importance=$importance secsSinceRg=$secsSinceRg");
        FirebaseCrashlytics.instance.recordError(
          "AppKilledSignaled reason=2 status=$status importance=$importance "
          "timestamp=${DateTime.fromMillisecondsSinceEpoch(timestamp).toUtc().toIso8601String()} "
          "secsSinceRg=$secsSinceRg description=${exit['description']}",
          null,
          reason: "Android process killed by signal in a previous session",
          fatal: false,
        );
        analytics?.logEvent(
          name: "app_killed_signaled",
          parameters: {"importance": importance, "status": status, "secs_since_rg": secsSinceRg},
        );
      }
    } catch (e) {
      log("Error reporting previous exits: $e");
    }
  }
}
