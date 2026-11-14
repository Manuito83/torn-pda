part of 'firebase_firestore.dart';

extension ProfileDeletion on FirestoreHelper {
  // FCM last, it can hang
  Future<void> deleteProfileAndSignOut() async {
    final done = Completer<void>();
    _keyRemoval = done.future;
    try {
      await _deleteOrLeavePending();
    } finally {
      done.complete();
    }
    unawaited(
      _messaging.deleteToken().timeout(const Duration(seconds: 4)).catchError((e) {
        log("FCM token delete failed: $e");
      }),
    );
  }

  Future<void> resumePendingProfileDeletion() async {
    final done = Completer<void>();
    _keyRemoval = done.future;
    try {
      if (!await PrefsDatabase.getBool(profileDeletionPendingKey, false)) return;
      final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => FirebaseAuth.instance.currentUser,
      );
      if (user == null) {
        await PrefsDatabase.setBool(profileDeletionPendingKey, false);
        return;
      }
      await _deleteOrLeavePending();
    } catch (e) {
      log("Pending profile deletion failed: $e");
    } finally {
      done.complete();
    }
  }

  // True if the session is reused
  Future<bool> waitForKeyRemoval() async {
    while (true) {
      final removal = _keyRemoval;
      await removal;
      final markOnDisk = _profileDeletion == null && await PrefsDatabase.getBool(profileDeletionPendingKey, false);
      if (!identical(removal, _keyRemoval)) continue;
      if (_profileDeletion == null && !markOnDisk) return false;
      _profileDeletion = null;
      unawaited(PrefsDatabase.setBool(profileDeletionPendingKey, false));
      return true;
    }
  }

  Future<void> _deleteOrLeavePending() async {
    _alreadyUploaded = false;
    _lastTokenReconcile = null;
    final delete = _playerDoc()?.delete();
    if (delete == null) return _signOutAndClearMark();
    _profileDeletion = delete;
    try {
      await delete.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      log("Player document delete pending");
      await PrefsDatabase.setBool(profileDeletionPendingKey, true);
      unawaited(_finishPendingDeletion(delete));
      return;
    } catch (e) {
      log("Player document delete failed: $e");
    }
    await _signOutAndClearMark();
  }

  Future<void> _finishPendingDeletion(Future<void> delete) async {
    try {
      await delete;
    } catch (e) {
      log("Player document delete failed: $e");
    }
    if (!identical(_profileDeletion, delete)) return _watchForLateDelete();
    final done = Completer<void>();
    _keyRemoval = done.future;
    try {
      await _signOutAndClearMark();
    } finally {
      done.complete();
    }
  }

  Future<void> _signOutAndClearMark() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      log("Firebase sign out failed: $e");
    }
    _profileDeletion = null;
    await PrefsDatabase.setBool(profileDeletionPendingKey, false);
  }

  Future<void> _watchForLateDelete() async {
    final playerDoc = _playerDoc();
    if (playerDoc == null) return;
    await _reuploadProfile();
    final watch = playerDoc.snapshots().listen(
      (doc) {
        if (!doc.exists && !doc.metadata.isFromCache) unawaited(_reuploadProfile());
      },
      onError: (e) => log("Player document watch failed: $e"),
    );
    await Future.delayed(const Duration(minutes: 2));
    await watch.cancel();
  }

  Future<void> _reuploadProfile() async {
    final profile = UserHelper.basic;
    if (_profileDeletion != null || profile == null || !UserHelper.isApiKeyValid) return;
    try {
      log("Uploading profile again after a late delete");
      await restoreAlertsFromLocalSnapshot(profile.playerId, newSession: true);
      await uploadUsersProfileDetail(profile, userTriggered: true);
      await uploadLastActiveTimeAndTokensToFirebase(DateTime.now().millisecondsSinceEpoch);
      if (Platform.isAndroid) await setVibrationPattern(await Prefs().getVibrationPattern());
    } catch (e) {
      log("Profile upload after a late delete failed: $e");
    }
  }
}
