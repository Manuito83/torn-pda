import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

Future<void> publishCrashlyticsIdentity(int playerId) async {
  if (Platform.isWindows) return;
  try {
    final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setUserIdentifier(playerId == 0 ? "" : playerId.toString());

    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.length >= 5) {
      await crashlytics.setCustomKey("uid_tail", uid.substring(uid.length - 5));
    }
  } catch (_) {}
}

/// Startup errors happen before the profile syncs, so we need this from the
/// stored profile as soon as Firebase is up
Future<void> seedCrashlyticsIdentityFromStorage() async {
  if (Platform.isWindows) return;
  try {
    final String stored = await Prefs().getOwnDetails();
    if (stored.isEmpty) return;
    final dynamic playerId = (jsonDecode(stored) as Map<String, dynamic>)["player_id"];
    if (playerId is! int || playerId == 0) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(playerId.toString());
  } catch (_) {}
}
