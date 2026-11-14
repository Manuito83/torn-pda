part of 'firebase_firestore.dart';

const String _kLocalUserSnapshot = "_local_user_model_snapshot";

extension LocalAlertsSnapshot on FirestoreHelper {
  Future<void> persistLocalSnapshot() async {
    final model = _firebaseUserModel;
    if (model == null) return;
    try {
      final jsonStr = jsonEncode({
        ...model.toMap(),
        "life": model.life?.current,
        "playerId": model.playerId ?? UserHelper.playerId,
      }, toEncodable: (value) => value is Timestamp ? value.millisecondsSinceEpoch : value);
      await PrefsDatabase.setString(_kLocalUserSnapshot, jsonStr);
    } catch (e) {
      log("Snapshot save failed: $e");
    }
  }

  Future<FirebaseUserModel?> loadLocalSnapshot() async {
    try {
      final jsonStr = await PrefsDatabase.getString(_kLocalUserSnapshot, "");
      if (jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr);
      return FirebaseUserModel.fromMap(map);
    } catch (e) {
      log("Snapshot load failed: $e");
      return null;
    }
  }

  // Same player, no document yet
  Future<FirebaseUserModel?> restoreAlertsFromLocalSnapshot(int? playerId, {required bool newSession}) async {
    final playerDoc = _playerDoc();
    if (playerDoc == null || playerId == null || playerId <= 0) return null;
    try {
      final snapshot = await loadLocalSnapshot();
      if (snapshot == null || snapshot.playerId != playerId) return null;
      if (!newSession) {
        final exists = await playerDoc
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 8))
            .then(
              (doc) => doc.exists,
              onError: (_) async {
                if (_firebaseUserModel != null) return true;
                return playerDoc
                    .get(const GetOptions(source: Source.cache))
                    .then((doc) => doc.exists, onError: (_) => false);
              },
            );
        if (exists) return null;
      }
      // Queued locally, it reaches the server later
      final applied = await applyAlertsFromPayload(
        snapshot.toMap(),
        resetRestockTimestamps: true,
      ).timeout(const Duration(seconds: 8), onTimeout: () => true);
      return applied ? snapshot : null;
    } catch (e) {
      log("Local alerts restore failed: $e");
      return null;
    }
  }
}
