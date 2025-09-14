// firebase_rtdb.dart

import 'dart:developer';
import 'package:firebase_database/firebase_database.dart';

class FirebaseRtdbHelper {
  static final FirebaseRtdbHelper _instance = FirebaseRtdbHelper._internal();
  FirebaseRtdbHelper._internal();

  factory FirebaseRtdbHelper() {
    return _instance;
  }

  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  /// Syncs the arrival timestamp of a locally started Live Activity with Realtime Database
  /// This prevents the server from sending a duplicate Push-to-Start notification
  Future<void> liveActivityTravelTimestampSync({
    required String uid,
    required int arrivalTimestamp,
  }) async {
    final DatabaseReference ref = _rtdb.ref("live_activities/travel_status/$uid");

    try {
      log("RTDB Helper: Syncing LA arrival timestamp ($arrivalTimestamp) for user $uid...");

      await ref.set({
        "arrivalTimestamp": arrivalTimestamp,
      });

      log("RTDB Helper: LA timestamp synced successfully for user $uid");
    } catch (e) {
      log("RTDB Helper: Error syncing LA timestamp for user $uid: $e");
    }
  }

  /// Cleans up the Live Activity status from Realtime Database when the trip ends
  Future<void> liveActivityClearTimeStamp({required String uid}) async {
    final DatabaseReference ref = _rtdb.ref("live_activities/travel_status/$uid");

    try {
      log("RTDB Helper: Clearing LA status from RTDB for user $uid...");
      await ref.remove();
      log("RTDB Helper: LA status cleared successfully for user $uid");
    } catch (e) {
      log("RTDB Helper: Error clearing LA status from RTDB for user $uid: $e");
    }
  }

  /// Get foreign stocks data from Torn PDA Database (Realtime Database) as fallback
  Future<Map<String, dynamic>?> getTornPDAStocksData() async {
    try {
      final DatabaseReference ref = _rtdb.ref().child('stocks/restocks');
      final DataSnapshot snapshot = await ref.get().timeout(const Duration(seconds: 4));

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        if (data is Map) {
          // Safely convert to Map<String, dynamic>
          Map<String, dynamic> result = {};
          data.forEach((key, value) {
            if (key != null && value != null) {
              String keyStr = key.toString();
              if (value is Map) {
                Map<String, dynamic> valueMap = {};
                value.forEach((k, v) {
                  if (k != null) {
                    valueMap[k.toString()] = v;
                  }
                });
                result[keyStr] = valueMap;
              } else {
                result[keyStr] = value;
              }
            }
          });
          return result;
        }
      }
      return null;
    } catch (e) {
      log('Error fetching Torn PDA stocks data: $e');
      return null;
    }
  }
}
