import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart' show readNativeApiToken;
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

const _callTimeout = Duration(seconds: 25);

typedef ShareCall = Future<Object?> Function(bool share);

Future<Object?> _callFunction(bool share) async => firebaseFunctions.setShareFlights(share, await readNativeApiToken());

Future<Object?> _readFunction() async => firebaseFunctions.getShareFlights(await readNativeApiToken());

// Null without login, throws if unreadable
Future<bool?> readFlightSharing({Future<Object?> Function() call = _readFunction}) async {
  final answer = await call();
  if (shareAnswerNeedsLogin(answer)) return null;
  final share = shareAnswerValue(answer);
  if (share == null) throw const FormatException('unreadable sharing answer');
  return share;
}

// True when taken, null without answer
Future<bool?> writeFlightSharing(bool share, {ShareCall call = _callFunction}) async {
  try {
    final answer = await call(share).timeout(_callTimeout);
    if (shareAnswerPending(answer)) {
      await Prefs().setTerritoryMapShareStopPending(true);
      return true;
    }
    if (!shareAnswerSaved(answer, share: share)) return false;
    // This choice replaces a stop still pending
    await Prefs().setTerritoryMapShareStopPending(false);
    return true;
  } catch (e) {
    debugPrint('faction flights: sharing not saved: $e');
    return null;
  }
}

// Map disabled, survives a failed call
Future<void> stopSharingFlights({ShareCall call = _callFunction}) async {
  try {
    await Prefs().setTerritoryMapShareStopPending(true);
  } catch (e) {
    debugPrint('faction flights: stop not noted: $e');
  }
  await writeFlightSharing(false, call: call);
}

// At app open and resume, login or not
Future<void> retryStopSharingFlights({ShareCall call = _callFunction}) async {
  try {
    if (await Prefs().getTerritoryMapShareStopPending()) await writeFlightSharing(false, call: call);
  } catch (e) {
    debugPrint('faction flights: stop not retried: $e');
  }
}
