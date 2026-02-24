import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/firebase_options.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/auth/authentication_loading_widget.dart';
import 'package:torn_pda/widgets/auth/authentication_timeout_widget.dart';

class _AlertsRecoveryOutcome {
  final bool clonedAlerts;
  final bool snapshotRestored;
  final String? sourceUid;
  final bool platformMatch;

  const _AlertsRecoveryOutcome({
    required this.clonedAlerts,
    required this.snapshotRestored,
    required this.sourceUid,
    required this.platformMatch,
  });
}

class AuthRecoveryWidget extends StatefulWidget {
  final Widget child;
  final Completer preferencesCompleter;
  final bool appHasBeenUpdated;

  /// If false, skip all recovery logic and just show child
  final bool enabled;

  /// Called when auth recovery completes (success or user acknowledged timeout)
  final VoidCallback? onAuthCompleted;

  const AuthRecoveryWidget({
    super.key,
    required this.child,
    required this.preferencesCompleter,
    required this.appHasBeenUpdated,
    this.enabled = true,
    this.onAuthCompleted,
  });

  @override
  State<AuthRecoveryWidget> createState() => _AuthRecoveryWidgetState();
}

class _AuthRecoveryWidgetState extends State<AuthRecoveryWidget> {
  // ############## Debug  ##############
  // _debugForceSignOut: Signs out at start (simulates lost session, but allows anon creation)
  // _debugBlockAnonCreation: Prevents anonymous user creation -> forces timeout UI
  // _debugFailLocalRecovery: Local snapshot restore fails
  // _debugFailFirebaseRecovery: Firestore/API clone fails
  static const bool _debugForceSignOut = kDebugMode && false;
  static const bool _debugBlockAnonCreation = kDebugMode && false;
  static const bool _debugFailLocalRecovery = kDebugMode && false;
  static const bool _debugFailFirebaseRecovery = kDebugMode && false;

  // Internal state
  bool _hasAuthenticationError = false;
  bool _authenticationTimedOut = false;
  bool _authRecoveryInProgress = false;
  Future<void>? _finalRecoveryFuture;
  bool _drawerUserChecked = false;
  String _userUid = '';

  // Detailed logging state
  final Stopwatch _totalRecoveryStopwatch = Stopwatch();
  final List<String> _recoveryLog = [];
  bool _isOriginalUserRecovered = false; // true = original session, false = new anonymous
  String? _initialCurrentUserState; // 'null', 'present', or 'error'
  String? _apiKeyStateAtRecovery; // 'valid', 'empty', or 'error'
  int _authStateChangesCount = 0;
  bool? _iosProtectedDataAvailable; // iOS only: tracks if keychain is accessible

  final Completer<void> _authenticationTimeoutCompleter = Completer<void>();

  void _logStep(String step, {Map<String, dynamic>? details}) {
    final elapsed = _totalRecoveryStopwatch.elapsedMilliseconds;
    final entry =
        '[$elapsed ms] $step${details != null ? ' | ${details.entries.map((e) => '${e.key}=${e.value}').join(', ')}' : ''}';
    _recoveryLog.add(entry);
    log(entry, name: 'AUTH_RECOVERY_TRACE');
  }

  /// [iOS only] Check if protected data (Keychain) is available
  /// This is for diagnostics only, to confirm if keychain access issues cause auth loss
  Future<void> _logProtectedDataAvailability() async {
    try {
      const channel = MethodChannel('tornpda/protected_data');
      final bool isAvailable = await channel.invokeMethod('isProtectedDataAvailable') ?? true;
      _iosProtectedDataAvailable = isAvailable;
      _logStep('IOS_PROTECTED_DATA', details: {'available': isAvailable});
    } catch (e) {
      // Channel not implemented yet - just log the error
      _iosProtectedDataAvailable = null;
      _logStep('IOS_PROTECTED_DATA_ERROR', details: {'error': e.toString()});
    }
  }

  @override
  void initState() {
    super.initState();
    _startAuthRecovery();
  }

  @override
  void dispose() {
    if (!_authenticationTimeoutCompleter.isCompleted) {
      _authenticationTimeoutCompleter.complete();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ### 1: Decide if auth recovery is needed ###
  // ---------------------------------------------------------------------------

  Future<void> _startAuthRecovery() async {
    _totalRecoveryStopwatch.start();
    _logStep('START', details: {
      'appUpdated': widget.appHasBeenUpdated,
      'platform': Platform.isIOS ? 'iOS' : 'Android',
    });

    // Capture API key state early
    _apiKeyStateAtRecovery = UserHelper.isApiKeyValid ? 'valid' : 'empty';
    _logStep('API_KEY_STATE', details: {'state': _apiKeyStateAtRecovery});

    // Wait for preferences FIRST - this ensures _authRecoveryEnabledRC is loaded
    // before we check widget.enabled
    if (!widget.preferencesCompleter.isCompleted) {
      _logStep('WAITING_PREFS');
      try {
        await widget.preferencesCompleter.future.timeout(const Duration(seconds: 10));
        _logStep('PREFS_LOADED');
      } catch (_) {
        _logStep('PREFS_TIMEOUT');
        _flushLogToCrashlytics(outcome: 'prefs_timeout');
        widget.onAuthCompleted?.call();
        return;
      }
    }

    // Kill switch via Remote Config (checked AFTER preferences load)
    if (!widget.enabled) {
      _logStep('DISABLED_RC');
      widget.onAuthCompleted?.call();
      return;
    }

    if (Platform.isWindows || _drawerUserChecked) {
      _logStep('EARLY_RETURN', details: {'reason': Platform.isWindows ? 'windows' : 'already_checked'});
      widget.onAuthCompleted?.call();
      return;
    }

    // No API key... no user to recover
    if (!UserHelper.isApiKeyValid) {
      _logStep('NO_API_KEY');
      widget.onAuthCompleted?.call();
      return;
    }

    _authRecoveryInProgress = false;

    // Ensure Firebase is ready before any auth operations
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _logStep('FIREBASE_INIT_OK');
    } catch (e) {
      _logStep('FIREBASE_INIT_ERROR', details: {'error': e.toString()});
    }

    // [Debug] Force sign-out to simulate lost session
    if (_debugForceSignOut) {
      _logStep('DEBUG_FORCE_SIGNOUT');
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('Auth recovery: debug force signout error: $e');
      }
      _userUid = '';
    }

    // Small delay after app update to let Firebase settle
    // Show loading UI during this delay to prevent Profile from flashing briefly
    if (widget.appHasBeenUpdated) {
      _logStep('APP_UPDATE_DELAY_START');
      if (mounted) setState(() => _hasAuthenticationError = true);
      await Future.delayed(const Duration(seconds: 1));
      _logStep('APP_UPDATE_DELAY_END');
    }

    // [iOS only] Log protected data availability for diagnostics
    if (Platform.isIOS) {
      await _logProtectedDataAvailability();
    }

    // Check if user session already exists
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
      _initialCurrentUserState = user == null ? 'null' : 'present';
    } catch (e) {
      _initialCurrentUserState = 'error';
      _logStep('CURRENT_USER_ERROR', details: {'error': e.toString()});
    }
    _logStep('INITIAL_USER_CHECK', details: {'state': _initialCurrentUserState, 'uid': user?.uid ?? 'none'});

    // User already exists -> done (no recovery needed)
    if (user != null && !_debugForceSignOut) {
      _isOriginalUserRecovered = true;
      _logStep('USER_FOUND_IMMEDIATE', details: {'uid': user.uid});
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_restoration_success',
        parameters: {
          'method': 'immediate',
          'time_ms': _totalRecoveryStopwatch.elapsedMilliseconds,
          'success': 'true',
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'app_updated': widget.appHasBeenUpdated.toString(),
        },
      );

      setState(() {
        _userUid = user!.uid;
        _hasAuthenticationError = false;
      });
      await FirestoreHelper().setUID(_userUid);
      _drawerUserChecked = true;
      _totalRecoveryStopwatch.stop();
      widget.onAuthCompleted?.call();
      return;
    }

    // After app update, try re-initializing Firebase once more
    if (widget.appHasBeenUpdated) {
      _logStep('APP_UPDATE_REINIT_START');
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        user = FirebaseAuth.instance.currentUser;
        if (user != null && !_debugForceSignOut) {
          _isOriginalUserRecovered = true;
          _logStep('USER_FOUND_REINIT', details: {'uid': user.uid});
          FirebaseAnalytics.instance.logEvent(
            name: 'auth_restoration_success',
            parameters: {
              'method': 'firebase_reinit',
              'time_ms': _totalRecoveryStopwatch.elapsedMilliseconds,
              'success': 'true',
              'platform': Platform.isIOS ? 'iOS' : 'Android',
              'app_updated': 'true',
            },
          );

          setState(() {
            _userUid = user!.uid;
            _hasAuthenticationError = false;
          });
          await FirestoreHelper().setUID(_userUid);
          _drawerUserChecked = true;
          _totalRecoveryStopwatch.stop();
          widget.onAuthCompleted?.call();
          return;
        }
        _logStep('APP_UPDATE_REINIT_NO_USER');
      } catch (e) {
        _logStep('APP_UPDATE_REINIT_ERROR', details: {'error': e.toString()});
      }
    }

    // No user found yet, enter retry loop
    await _retryUserRecovery();
  }

  // ---------------------------------------------------------------------------
  // ### 2: Retry loop - attempt to recover existing Firebase user session ###
  // ---------------------------------------------------------------------------

  Future<void> _retryUserRecovery() async {
    _logStep('RETRY_LOOP_START');

    if (mounted) {
      setState(() => _hasAuthenticationError = true);
    }

    // Extended timing for post-update recovery:
    //   Phase 0 (0-2s)  -> "Checking existing session"
    //   Phase 1 (2-5s)  -> "Retrying sign-in (1/3)"
    //   Phase 2 (5-8s)  -> "Retrying sign-in (2/3)"
    //   Phase 3 (8-12s) -> "Retrying sign-in (3/3)" [EXTENDED for app updates]
    //   Phase 4+ (12-20s) -> Final recovery window
    final retryDelays = widget.appHasBeenUpdated ? [2, 3, 3, 4] : [2, 3, 3];

    for (int attempt = 1; attempt <= retryDelays.length; attempt++) {
      if (_authenticationTimedOut) {
        _logStep('RETRY_TIMEOUT_BREAK', details: {'attempt': attempt});
        break;
      }

      final delaySeconds = retryDelays[attempt - 1];
      _logStep('RETRY_WAIT_START', details: {'attempt': attempt, 'delay': delaySeconds});

      await Future.delayed(Duration(seconds: delaySeconds));

      if (_authenticationTimedOut) break;

      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (e) {
        _logStep('RETRY_FIREBASE_INIT_ERROR', details: {'attempt': attempt, 'error': e.toString()});
      }

      // Check currentUser
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (e) {
        _logStep('RETRY_CURRENT_USER_ERROR', details: {'attempt': attempt, 'error': e.toString()});
      }

      // Also listen to authStateChanges briefly to catch delayed auth events
      if (user == null && attempt == retryDelays.length) {
        _logStep('RETRY_CHECKING_AUTH_STREAM');
        try {
          user = await FirebaseAuth.instance.authStateChanges().first.timeout(
                const Duration(seconds: 2),
                onTimeout: () => null,
              );
          _authStateChangesCount++;
        } catch (e) {
          _logStep('RETRY_AUTH_STREAM_ERROR', details: {'error': e.toString()});
        }
      }

      _logStep('RETRY_USER_CHECK', details: {
        'attempt': attempt,
        'userState': user == null ? 'null' : 'present',
        'uid': user?.uid ?? 'none',
      });

      // Original user recovered - alerts are already linked to this UID
      if (user != null && !_debugForceSignOut) {
        _isOriginalUserRecovered = true;
        _logStep('RETRY_USER_RECOVERED', details: {'attempt': attempt, 'uid': user.uid});

        FirebaseAnalytics.instance.logEvent(
          name: 'auth_restoration_success',
          parameters: {
            'method': 'retry_exponential_backoff',
            'time_ms': _totalRecoveryStopwatch.elapsedMilliseconds,
            'attempt': attempt,
            'success': 'true',
            'platform': Platform.isIOS ? 'iOS' : 'Android',
            'app_updated': widget.appHasBeenUpdated.toString(),
          },
        );

        await _finalizeOriginalUser(user.uid);
        return;
      }
    }

    // Defensive... race condition where timeout occurred during loop iteration?
    if (_authenticationTimedOut) {
      _logStep('RETRY_ALREADY_TIMED_OUT');
      await _awaitAuthTimeoutAck();
      _drawerUserChecked = true;
      return;
    }

    // Retries exhausted without recovering user -> try creating anonymous user
    _logStep('RETRY_EXHAUSTED_CREATING_ANON', details: {'totalAttempts': retryDelays.length});
    await _createAnonymousUserAndRecover();

    // Final recovery also failed -> show timeout UI
    if (_userUid.isEmpty && mounted) {
      _logStep('FINAL_RECOVERY_FAILED_SHOWING_TIMEOUT');

      setState(() {
        _authenticationTimedOut = true;
        _hasAuthenticationError = false;
      });

      _logResults(
        restoredUser: false,
        clonedAlerts: false,
        snapshotRestored: false,
        sourceUid: null,
        platformMatch: true,
        retries: retryDelays.length,
        timedOut: true,
        failure: Exception('auth_recovery_final_timeout'),
      );

      await _awaitAuthTimeoutAck();
    }

    _drawerUserChecked = true;
  }

  // -----------------------------------------------------------------------------
  // ### 3: Create anonymous user if no session was recovered ###
  // -----------------------------------------------------------------------------

  Future<void> _createAnonymousUserAndRecover() {
    if (_finalRecoveryFuture != null) {
      _logStep('ANON_CREATION_REUSING_FUTURE');
      return _finalRecoveryFuture!;
    }

    _logStep('ANON_CREATION_START');
    _finalRecoveryFuture = _executeAnonymousUserCreation();
    return _finalRecoveryFuture!;
  }

  Future<void> _executeAnonymousUserCreation() async {
    if (mounted) {
      setState(() => _authRecoveryInProgress = true);
    }

    int retriesUsed = 0;
    Exception? failure;

    try {
      if (!widget.preferencesCompleter.isCompleted) {
        _logStep('ANON_WAITING_PREFS');
        try {
          await widget.preferencesCompleter.future.timeout(const Duration(seconds: 6));
          _logStep('ANON_PREFS_LOADED');
        } catch (_) {
          _logStep('ANON_PREFS_TIMEOUT');
        }
      }

      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (e) {
        debugPrint('Auth recovery: anonymous Firebase init error: $e');
      }

      // Final check before creating anonymous - maybe user appeared now
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (e) {
        _logStep('ANON_CURRENT_USER_ERROR', details: {'error': e.toString()});
      }

      _logStep('ANON_PRE_CREATE_CHECK', details: {
        'userState': user == null ? 'null' : 'present',
        'uid': user?.uid ?? 'none',
        'apiKeyValid': UserHelper.isApiKeyValid,
      });

      // [Debug] Block anonymous user creation to force timeout UI
      if (_debugBlockAnonCreation) {
        _logStep('DEBUG_BLOCK_ANON');
        failure = Exception('debug_blocked_recovery');
        return;
      }

      // No existing user -> create anonymous
      if (user == null) {
        _isOriginalUserRecovered = false; // Mark that we're creating a NEW user
        _logStep('ANON_CREATING_USER');
        final AuthService authService = AuthService();
        user = await authService.signInAnon(
          isAppUpdate: widget.appHasBeenUpdated,
          maxRetries: widget.appHasBeenUpdated ? 5 : 3,
        );
        retriesUsed = widget.appHasBeenUpdated ? 5 : 3;
        _logStep('ANON_SIGN_IN_RESULT', details: {
          'success': user != null,
          'uid': user?.uid ?? 'none',
          'retries': retriesUsed,
        });
      } else {
        // User appeared! This is actually the original user recovered late
        _isOriginalUserRecovered = true;
        _logStep('ANON_USER_APPEARED_LATE', details: {'uid': user.uid});
      }

      // Still no user after anonymous sign-in -> fail
      if (user == null) {
        _logStep('ANON_CREATION_FAILED');
        failure = Exception('final_recovery_no_user');
        return;
      }

      // User obtained -> finalize (either original recovered late, or new anonymous)
      if (_isOriginalUserRecovered) {
        _logStep('ANON_FINALIZING_ORIGINAL_USER', details: {'uid': user.uid});
        await _finalizeOriginalUser(user.uid);
      } else {
        _logStep('ANON_FINALIZING_NEW_USER', details: {'uid': user.uid});
        await _finalizeNewUserAndRecoverAlerts(user.uid, retriesUsed: retriesUsed);
      }
    } catch (e, s) {
      _logStep('ANON_EXCEPTION', details: {'error': e.toString()});
      failure = Exception('final_recovery_exception');
      _logResults(
        restoredUser: _userUid.isNotEmpty,
        clonedAlerts: false,
        snapshotRestored: false,
        sourceUid: null,
        platformMatch: true,
        retries: retriesUsed,
        timedOut: _authenticationTimedOut,
        failure: failure,
        stack: s,
      );
    } finally {
      _drawerUserChecked = true;
      if (mounted) {
        setState(() => _authRecoveryInProgress = false);
      }
      _finalRecoveryFuture = null;
    }
  }

  Future<_AlertsRecoveryOutcome> _tryRecoverAlerts({required String currentUid}) async {
    _logStep('ALERTS_RECOVERY_START', details: {'currentUid': currentUid});

    bool clonedAlerts = false;
    bool snapshotRestored = false;
    String? sourceUid;
    bool platformMatch = true;

    // First: try local snapshot
    _logStep('ALERTS_TRYING_LOCAL_SNAPSHOT');
    snapshotRestored = await _restoreFromLocalSnapshot();
    _logStep('ALERTS_LOCAL_SNAPSHOT_RESULT', details: {'restored': snapshotRestored});

    if (snapshotRestored) {
      clonedAlerts = true;
      return _AlertsRecoveryOutcome(
        clonedAlerts: clonedAlerts,
        snapshotRestored: snapshotRestored,
        sourceUid: sourceUid,
        platformMatch: platformMatch,
      );
    }

    // Second: try Firestore clone (6s timeout)
    final apiKey = UserHelper.apiKey;
    _logStep('ALERTS_TRYING_FIRESTORE_CLONE', details: {
      'hasApiKey': apiKey.isNotEmpty,
      'hasUid': currentUid.isNotEmpty,
    });

    if (apiKey.isNotEmpty && currentUid.isNotEmpty) {
      try {
        final recovery = await _cloneFromApiKey(apiKey: apiKey, currentUid: currentUid)
            .timeout(const Duration(seconds: 6), onTimeout: () {
          _logStep('ALERTS_CLONE_TIMEOUT');
          return {'hasClonedData': false};
        });

        _logStep('ALERTS_CLONE_RESULT', details: {
          'hasClonedData': recovery['hasClonedData'],
          'sourceUid': recovery['sourceUid'] ?? 'none',
        });

        if (recovery['hasClonedData'] == true) {
          sourceUid = recovery['sourceUid'];
          clonedAlerts = true;
          platformMatch = recovery['platformMatch'] ?? true;
        }
      } catch (e) {
        _logStep('ALERTS_CLONE_ERROR', details: {'error': e.toString()});
      }
    } else {
      _logStep('ALERTS_CLONE_SKIPPED', details: {
        'reason': apiKey.isEmpty ? 'no_api_key' : 'no_uid',
      });
    }

    return _AlertsRecoveryOutcome(
      clonedAlerts: clonedAlerts,
      snapshotRestored: snapshotRestored,
      sourceUid: sourceUid,
      platformMatch: platformMatch,
    );
  }

  void _showAlertsNotRecoveredWarning() {
    if (!mounted) return;
    BotToast.showText(
      text: "There was an issues recovering your user preferences from the server.\n\n"
          "This might happen if your device lost or tried to restore data from a backup.\n\n"
          "Torn PDA managed to recover your user, but Alerts (automatic notifications) "
          "could not be restored.\n\nPlease reconfigure them in the Alerts section.",
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      clickClose: false,
      contentColor: Colors.orange[700]!,
      duration: const Duration(seconds: 10),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Future<Map<String, dynamic>> _cloneFromApiKey({
    required String apiKey,
    required String currentUid,
  }) async {
    if (apiKey.isEmpty || currentUid.isEmpty) {
      return {'hasClonedData': false};
    }

    try {
      final devicePlatform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'windows';

      try {
        await FirebaseFirestore.instance.collection('players').doc(currentUid).set(
          {'apiKey': apiKey, 'platform': devicePlatform},
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Auth recovery: Firestore player set error: $e');
      }

      final result = await firebaseFunctions.lookupUserByApiKey(
        apiKey: apiKey,
        currentUid: currentUid,
        platform: devicePlatform,
      );

      final String? sourceUid = result?["uid"]?.toString();

      Map<String, dynamic>? data;
      final rawData = result?["data"];
      if (rawData is Map) {
        data = rawData.map((key, value) => MapEntry(key.toString(), value));
      }

      if (sourceUid == null || sourceUid.isEmpty || sourceUid == currentUid || data == null || data.isEmpty) {
        return {'hasClonedData': false};
      }

      final sourcePlatform = data['platform']?.toString();
      if (sourcePlatform != null && sourcePlatform.isNotEmpty && sourcePlatform != devicePlatform) {
        return {'hasClonedData': false};
      }

      if (_debugFailFirebaseRecovery) {
        throw Exception('debug_fail_firebase_recovery');
      }

      final cloned = await FirestoreHelper().applyAlertsFromPayload(data, resetRestockTimestamps: true);
      if (!cloned) {
        return {'hasClonedData': false};
      }

      return {
        'hasClonedData': true,
        'sourceUid': sourceUid,
        'platformMatch': sourcePlatform == null || sourcePlatform.isEmpty || sourcePlatform == devicePlatform,
      };
    } catch (e, s) {
      log("cloneFromApiKey failed: $e", stackTrace: s, name: "AUTH RECOVERY");
      return {'hasClonedData': false};
    }
  }

  // ---------------------------------------------------------------------------
  // ### 4a: Original user recovered - just set UID and sync ###
  // ---------------------------------------------------------------------------

  Future<void> _finalizeOriginalUser(String uid) async {
    _logStep('FINALIZE_ORIGINAL_USER', details: {'uid': uid});
    _isOriginalUserRecovered = true;

    if (mounted) {
      setState(() => _userUid = uid);
    }

    await FirestoreHelper().setUID(_userUid);
    await _syncProfileToFirebase();

    _totalRecoveryStopwatch.stop();
    _logStep('ORIGINAL_USER_FINALIZED', details: {'totalTimeMs': _totalRecoveryStopwatch.elapsedMilliseconds});

    // Log success to Crashlytics
    _flushLogToCrashlytics(outcome: 'original_user_recovered', recoverySource: 'original');

    _drawerUserChecked = true;
    widget.onAuthCompleted?.call();

    if (mounted) {
      setState(() {
        _hasAuthenticationError = false;
        _authenticationTimedOut = false;
        _authRecoveryInProgress = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // ### 4b: New anonymous user - try to recover alerts from previous UID ###
  // ---------------------------------------------------------------------------

  Future<void> _finalizeNewUserAndRecoverAlerts(String uid, {required int retriesUsed}) async {
    if (mounted) {
      setState(() => _userUid = uid);
    }

    await FirestoreHelper().setUID(_userUid);

    // Try to recover alerts (local snapshot first, then Firestore)
    final outcome = await _tryRecoverAlerts(currentUid: _userUid);
    await _syncProfileToFirebase();

    // Warn user if alerts could not be recovered
    final alertsRecovered = outcome.clonedAlerts || outcome.snapshotRestored;
    if (!alertsRecovered) {
      _showAlertsNotRecoveredWarning();
    }

    _logResults(
      restoredUser: true,
      clonedAlerts: outcome.clonedAlerts,
      snapshotRestored: outcome.snapshotRestored,
      sourceUid: outcome.sourceUid,
      platformMatch: outcome.platformMatch,
      retries: retriesUsed,
      timedOut: _authenticationTimedOut,
      failure: alertsRecovered ? null : Exception('alerts_not_recovered'),
    );

    _drawerUserChecked = true;
    widget.onAuthCompleted?.call();

    if (mounted) {
      setState(() {
        _hasAuthenticationError = false;
        _authenticationTimedOut = false;
        _authRecoveryInProgress = false;
      });
    }
  }

  Future<bool> _restoreFromLocalSnapshot() async {
    final snapshot = await FirestoreHelper().loadLocalSnapshot();
    if (snapshot == null || _debugFailLocalRecovery) {
      return false;
    }

    final restored = await FirestoreHelper().applyAlertsFromPayload(
      snapshot.toMap(),
      resetRestockTimestamps: true,
    );
    log("AUTH_DEBUG: Local snapshot restore: $restored", name: "AUTH_DEBUG");
    return restored;
  }

  Future<void> _syncProfileToFirebase() async {
    final savedKey = UserHelper.apiKey;
    if (savedKey.isEmpty) return;

    try {
      final dynamic prof = await ApiCallsV1.getOwnProfileBasic();
      if (prof is OwnProfileBasic) {
        prof
          ..userApiKey = savedKey
          ..userApiKeyValid = true;
        await FirestoreHelper().uploadUsersProfileDetail(prof, userTriggered: true);
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await FirestoreHelper().uploadLastActiveTimeAndTokensToFirebase(now);
    } catch (e, s) {
      log("Failed to sync profile: $e", name: "AUTH CHECKS", stackTrace: s);
    }
  }

  // ---------------------------------------------------------------------------
  // ### 5: Crashlytics logging ###
  // ---------------------------------------------------------------------------

  void _logResults({
    required bool restoredUser,
    required bool clonedAlerts,
    required bool snapshotRestored,
    required bool platformMatch,
    required int retries,
    required bool timedOut,
    String? sourceUid,
    Exception? failure,
    StackTrace? stack,
  }) {
    _totalRecoveryStopwatch.stop();

    // Source labels: "Firestore" (cloud), "Local" (snapshot), "None"
    final recoverySource = clonedAlerts
        ? 'Firestore'
        : snapshotRestored
            ? 'Local'
            : 'None';

    final success = restoredUser && (clonedAlerts || snapshotRestored);

    _logStep('FINAL_RESULT', details: {
      'success': success,
      'recoverySource': recoverySource,
      'isOriginalUser': _isOriginalUserRecovered,
      'totalTimeMs': _totalRecoveryStopwatch.elapsedMilliseconds,
    });

    // Always flush detailed log to Crashlytics for debugging
    _flushLogToCrashlytics(
      outcome: success ? 'success' : (failure?.toString() ?? 'failed'),
      recoverySource: recoverySource,
    );

    final summary = "AuthRecovery outcome | success=$success source=$recoverySource"
        " clonedAlerts=$clonedAlerts snapshot=$snapshotRestored "
        "sourceUid=${sourceUid ?? 'none'} retries=$retries timedOut=$timedOut"
        " isOriginalUser=$_isOriginalUserRecovered totalMs=${_totalRecoveryStopwatch.elapsedMilliseconds}";
    log(summary, name: "AUTH RECOVERY");

    FirebaseAnalytics.instance.logEvent(
      name: success ? 'auth_recovery_success' : 'auth_recovery_failed',
      parameters: {
        'recoverySource': recoverySource,
        'restoredUser': restoredUser.toString(),
        'clonedAlerts': clonedAlerts.toString(),
        'snapshotRestored': snapshotRestored.toString(),
        'retries': retries,
        'timedOut': timedOut.toString(),
        'sourceUid': sourceUid ?? 'none',
        'isOriginalUser': _isOriginalUserRecovered.toString(),
        'totalTimeMs': _totalRecoveryStopwatch.elapsedMilliseconds,
        'platform': Platform.isIOS ? 'iOS' : 'Android',
        'appUpdated': widget.appHasBeenUpdated.toString(),
        'initialUserState': _initialCurrentUserState ?? 'unknown',
        'apiKeyState': _apiKeyStateAtRecovery ?? 'unknown',
      },
    );

    if (success) {
      FirebaseCrashlytics.instance.recordError(
        Exception('auth_recovery_fallback_success'),
        stack ?? StackTrace.current,
        reason: 'Auth recovery success via $recoverySource',
        information: [
          'recoverySource: $recoverySource',
          'restoredUser: $restoredUser',
          'clonedAlerts: $clonedAlerts',
          'snapshotRestored: $snapshotRestored',
          'retries: $retries',
          'timedOut: $timedOut',
          'sourceUid: ${sourceUid ?? 'none'}',
          'isOriginalUser: $_isOriginalUserRecovered',
          'totalTimeMs: ${_totalRecoveryStopwatch.elapsedMilliseconds}',
          'initialUserState: ${_initialCurrentUserState ?? 'unknown'}',
          'apiKeyState: ${_apiKeyStateAtRecovery ?? 'unknown'}',
        ],
        fatal: false,
      );
      return;
    }

    FirebaseCrashlytics.instance.recordError(
      failure ?? Exception('auth_recovery_failed'),
      stack ?? StackTrace.current,
      reason: 'Auth recovery failed via $recoverySource',
      information: [
        'recoverySource: $recoverySource',
        'restoredUser: $restoredUser',
        'clonedAlerts: $clonedAlerts',
        'snapshotRestored: $snapshotRestored',
        'retries: $retries',
        'timedOut: $timedOut',
        'sourceUid: ${sourceUid ?? 'none'}',
        'isOriginalUser: $_isOriginalUserRecovered',
        'totalTimeMs: ${_totalRecoveryStopwatch.elapsedMilliseconds}',
        'initialUserState: ${_initialCurrentUserState ?? 'unknown'}',
        'apiKeyState: ${_apiKeyStateAtRecovery ?? 'unknown'}',
      ],
      fatal: false,
    );
  }

  /// Sends the detailed recovery log to Crashlytics for debugging
  void _flushLogToCrashlytics({required String outcome, String? recoverySource}) {
    if (_recoveryLog.isEmpty) return;

    // Combine log entries (limit to last 50 to avoid huge payloads)
    final logEntries = _recoveryLog.length > 50 ? _recoveryLog.sublist(_recoveryLog.length - 50) : _recoveryLog;

    FirebaseCrashlytics.instance.log('AUTH_RECOVERY_TRACE: outcome=$outcome');
    for (final entry in logEntries) {
      FirebaseCrashlytics.instance.log(entry);
    }

    FirebaseCrashlytics.instance.recordError(
      Exception('auth_recovery_trace_$outcome'),
      StackTrace.current,
      reason: 'Auth recovery trace',
      information: [
        'outcome: $outcome',
        'recoverySource: ${recoverySource ?? 'unknown'}',
        'platform: ${Platform.isIOS ? 'iOS' : 'Android'}',
        'appUpdated: ${widget.appHasBeenUpdated}',
        'totalSteps: ${_recoveryLog.length}',
        'totalTimeMs: ${_totalRecoveryStopwatch.elapsedMilliseconds}',
        'initialUserState: ${_initialCurrentUserState ?? 'unknown'}',
        'apiKeyState: ${_apiKeyStateAtRecovery ?? 'unknown'}',
        'isOriginalUser: $_isOriginalUserRecovered',
        'authStateChangesCount: $_authStateChangesCount',
        if (Platform.isIOS) 'iosProtectedDataAvailable: ${_iosProtectedDataAvailable ?? 'unknown'}',
      ],
      fatal: false,
    );
  }

  Future<void> _awaitAuthTimeoutAck() async {
    if (_authenticationTimeoutCompleter.isCompleted) return;

    try {
      await _authenticationTimeoutCompleter.future.timeout(const Duration(seconds: 35));
    } on TimeoutException {
      if (!_authenticationTimeoutCompleter.isCompleted) {
        _authenticationTimeoutCompleter.complete();
      }
    }
  }

  void _handleAuthenticationTimeoutAcknowledged() {
    if (!_authenticationTimeoutCompleter.isCompleted) {
      _authenticationTimeoutCompleter.complete();
    }

    // Notify parent that auth flow is complete
    widget.onAuthCompleted?.call();

    if (mounted) {
      setState(() {
        _authenticationTimedOut = false;
        _hasAuthenticationError = false;
        _drawerUserChecked = true;
      });
    }
  }

  void _startFinalRecoveryWindow() {
    if (_authenticationTimedOut || _drawerUserChecked) {
      return;
    }
    _createAnonymousUserAndRecover();
  }

  // --
  // UI
  // --

  Widget _buildScaffoldWrapper({required ThemeProvider themeProvider, required Widget content}) {
    return Container(
      color: themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : themeProvider.canvas
          : themeProvider.canvas,
      child: SafeArea(
        child: Scaffold(
          body: Container(
            color: themeProvider.canvas,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final webViewProvider = context.watch<WebViewProvider>();

    // Show loading during recovery in progress
    if (_authRecoveryInProgress) {
      return _buildScaffoldWrapper(
        themeProvider: themeProvider,
        content: AuthenticationLoadingWidget(
          themeProvider: themeProvider,
          onCaptiveFinished: null,
          onFinalWindowStarted: _startFinalRecoveryWindow,
        ),
      );
    }

    // Show timeout screen with "Understood" button
    if (_authenticationTimedOut) {
      return _buildScaffoldWrapper(
        themeProvider: themeProvider,
        content: AuthenticationTimeoutWidget(
          themeProvider: themeProvider,
          webViewProvider: webViewProvider,
          onUnderstoodPressed: _handleAuthenticationTimeoutAcknowledged,
        ),
      );
    }

    // Show loading/sync screen during retry loop
    if (_hasAuthenticationError) {
      return _buildScaffoldWrapper(
        themeProvider: themeProvider,
        content: AuthenticationLoadingWidget(
          themeProvider: themeProvider,
          onCaptiveFinished: _handleAuthenticationTimeoutAcknowledged,
          onFinalWindowStarted: _startFinalRecoveryWindow,
        ),
      );
    }

    // Auth is OK - show the child
    return widget.child;
  }
}
