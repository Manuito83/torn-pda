import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
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

  final Completer<void> _authenticationTimeoutCompleter = Completer<void>();

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
    log("AUTH_DEBUG: Starting auth recovery", name: "AUTH_DEBUG");

    // Wait for preferences FIRST - this ensures _authRecoveryEnabledRC is loaded
    // before we check widget.enabled
    if (!widget.preferencesCompleter.isCompleted) {
      log("AUTH_DEBUG: Waiting for preferences", name: "AUTH_DEBUG");
      try {
        await widget.preferencesCompleter.future.timeout(const Duration(seconds: 10));
      } catch (_) {
        log("AUTH_DEBUG: Preferences timeout, skipping recovery", name: "AUTH_DEBUG");
        widget.onAuthCompleted?.call();
        return;
      }
    }

    // Kill switch via Remote Config (checked AFTER preferences load)
    if (!widget.enabled) {
      log("AUTH_DEBUG: Auth recovery disabled via Remote Config", name: "AUTH_DEBUG");
      widget.onAuthCompleted?.call();
      return;
    }

    if (Platform.isWindows || _drawerUserChecked) {
      log("AUTH_DEBUG: Early return (Windows or already checked)", name: "AUTH_DEBUG");
      widget.onAuthCompleted?.call();
      return;
    }

    // No API key... no user to recover
    if (!UserHelper.isApiKeyValid) {
      log("AUTH_DEBUG: No valid API key, skipping recovery", name: "AUTH_DEBUG");
      widget.onAuthCompleted?.call();
      return;
    }

    _authRecoveryInProgress = false;

    // Ensure Firebase is ready before any auth operations
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {}

    // [Debug] Force sign-out to simulate lost session
    if (_debugForceSignOut) {
      log("AUTH_DEBUG: Debug flag forcing sign-out", name: "AUTH_DEBUG");
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      _userUid = '';
    }

    // Small delay after app update to let Firebase settle
    // Show loading UI during this delay to prevent Profile from flashing briefly
    if (widget.appHasBeenUpdated) {
      log("AUTH_DEBUG: App updated, adding delay", name: "AUTH_DEBUG");
      if (mounted) setState(() => _hasAuthenticationError = true);
      await Future.delayed(const Duration(seconds: 1));
    }

    // Check if user session already exists
    User? user = FirebaseAuth.instance.currentUser;
    log("AUTH_DEBUG: Initial user check: ${user == null ? 'null' : 'present'}", name: "AUTH_DEBUG");

    // User already exists -> done (no recovery needed)
    if (user != null && !_debugForceSignOut) {
      log("AUTH_DEBUG: User found immediately", name: "AUTH_DEBUG");
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_restoration_success',
        parameters: {
          'method': 'immediate',
          'time_ms': 0,
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
      widget.onAuthCompleted?.call();
      return;
    }

    // After app update, try re-initializing Firebase once more
    if (widget.appHasBeenUpdated) {
      log("AUTH_DEBUG: Re-init due to app update", name: "AUTH_DEBUG");
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        user = FirebaseAuth.instance.currentUser;
        if (user != null && !_debugForceSignOut) {
          log("AUTH_DEBUG: User found after re-init.", name: "AUTH_DEBUG");
          FirebaseAnalytics.instance.logEvent(
            name: 'auth_restoration_success',
            parameters: {
              'method': 'firebase_reinit',
              'time_ms': 0,
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
          widget.onAuthCompleted?.call();
          return;
        }
      } catch (e) {
        log("Firebase re-initialization failed: $e", name: "AUTH CHECKS");
      }
    }

    // No user found yet, enter retry loop
    await _retryUserRecovery();
  }

  // ---------------------------------------------------------------------------
  // ### 2: Retry loop - attempt to recover existing Firebase user session ###
  // ---------------------------------------------------------------------------

  Future<void> _retryUserRecovery() async {
    log("AUTH_DEBUG: Entering retry loop", name: "AUTH_DEBUG");

    if (mounted) {
      setState(() => _hasAuthenticationError = true);
    }

    // Timing synced with AuthenticationLoadingWidget (15s total):
    //   Phase 0 (0-2s)  -> "Checking existing session"
    //   Phase 1 (2-5s)  -> "Retrying sign-in (1/2)"
    //   Phase 2 (5-8s)  -> "Retrying sign-in (2/2)"
    //   Phase 3+ (8-15s) -> Final recovery window
    const retryDelays = [2, 3, 3];
    final retryStopwatch = Stopwatch()..start();
    log("AUTH_DEBUG: Starting retry loop", name: "AUTH_DEBUG");

    for (int attempt = 1; attempt <= retryDelays.length; attempt++) {
      if (_authenticationTimedOut) {
        log("AUTH_DEBUG: Authentication timed out break from loop", name: "AUTH_DEBUG");
        break;
      }

      final delaySeconds = retryDelays[attempt - 1];
      log("AUTH_DEBUG: Waiting $delaySeconds seconds (attempt $attempt)...", name: "AUTH_DEBUG");

      await Future.delayed(Duration(seconds: delaySeconds));

      if (_authenticationTimedOut) break;

      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (e) {
        log("Firebase re-initialization failed on retry attempt $attempt: $e", name: "AUTH CHECKS");
      }

      final user = FirebaseAuth.instance.currentUser;
      log("AUTH_DEBUG: After wait, user is ${user == null ? 'null' : 'present'}", name: "AUTH_DEBUG");

      // Original user recovered - alerts are already linked to this UID
      if (user != null && !_debugForceSignOut) {
        log("AUTH_DEBUG: User recovered in retry loop", name: "AUTH_DEBUG");
        final elapsedMs = retryStopwatch.elapsedMilliseconds;

        FirebaseAnalytics.instance.logEvent(
          name: 'auth_restoration_success',
          parameters: {
            'method': 'retry_exponential_backoff',
            'time_ms': elapsedMs,
            'attempt': attempt,
            'success': 'true',
            'platform': Platform.isIOS ? 'iOS' : 'Android',
            'app_updated': widget.appHasBeenUpdated.toString(),
          },
        );

        await _finalizeOriginalUser(user.uid);
        retryStopwatch.stop();
        return;
      }
    }

    retryStopwatch.stop();

    // Defensive... race condition where timeout occurred during loop iteration?
    if (_authenticationTimedOut) {
      log("AUTH_DEBUG: Already timed out, waiting for ack", name: "AUTH_DEBUG");
      await _awaitAuthTimeoutAck();
      _drawerUserChecked = true;
      return;
    }

    // Retries exhausted without recovering user -> try creating anonymous user
    log("AUTH_DEBUG: retries exhausted, entering final recovery", name: "AUTH_DEBUG");
    await _createAnonymousUserAndRecover();

    // Final recovery also failed -> show timeout UI
    if (_userUid.isEmpty && mounted) {
      log("AUTH_DEBUG: Final recovery failed, showing timeout", name: "AUTH_DEBUG");

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
      log("AUTH_DEBUG: Final recovery in progress, reusing", name: "AUTH_DEBUG");
      return _finalRecoveryFuture!;
    }

    log("AUTH_DEBUG: Starting final recovery", name: "AUTH_DEBUG");
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
        final waitTimer = Stopwatch()..start();
        try {
          await widget.preferencesCompleter.future.timeout(const Duration(seconds: 6));
        } catch (_) {
          log("Final recovery prefs wait timed out after ${waitTimer.elapsed.inSeconds}s", name: "AUTH RECOVERY");
        }
      }

      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (_) {}

      User? user = FirebaseAuth.instance.currentUser;
      retriesUsed = 0;
      log("AUTH_DEBUG: Final recovery - user is ${user == null ? 'null' : 'present'}", name: "AUTH_DEBUG");

      // [Debug] Block anonymous user creation to force timeout UI
      if (_debugBlockAnonCreation) {
        log("AUTH_DEBUG: Debug flag blocking anon creation", name: "AUTH_DEBUG");
        failure = Exception('debug_blocked_recovery');
        return;
      }

      // No existing user -> create anonymous
      if (user == null) {
        log("AUTH_DEBUG: Creating anonymous user", name: "AUTH_DEBUG");
        final AuthService authService = AuthService();
        user = await authService.signInAnon(
          isAppUpdate: widget.appHasBeenUpdated,
          maxRetries: widget.appHasBeenUpdated ? 5 : 3,
        );
        retriesUsed = widget.appHasBeenUpdated ? 5 : 3;
      }

      // Still no user after anonymous sign-in -> fail
      if (user == null) {
        log("AUTH_DEBUG: Failed to create anonymous user", name: "AUTH_DEBUG");
        failure = Exception('final_recovery_no_user');
        return;
      }

      // New anonymous user obtained -> try to recover alerts from previous UID
      log("AUTH_DEBUG: User obtained (${user.uid}), recovering alerts", name: "AUTH_DEBUG");
      await _finalizeNewUserAndRecoverAlerts(user.uid, retriesUsed: retriesUsed);
    } catch (e, s) {
      log("AUTH_DEBUG: Final recovery exception: $e", name: "AUTH_DEBUG");
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
    bool clonedAlerts = false;
    bool snapshotRestored = false;
    String? sourceUid;
    bool platformMatch = true;

    // First: try local snapshot
    snapshotRestored = await _restoreFromLocalSnapshot();
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
    if (apiKey.isNotEmpty && currentUid.isNotEmpty) {
      try {
        final recovery = await _cloneFromApiKey(apiKey: apiKey, currentUid: currentUid)
            .timeout(const Duration(seconds: 6), onTimeout: () => {'hasClonedData': false});

        if (recovery['hasClonedData'] == true) {
          sourceUid = recovery['sourceUid'];
          clonedAlerts = true;
          platformMatch = recovery['platformMatch'] ?? true;
        }
      } catch (_) {}
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
      } catch (_) {}

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
    if (mounted) {
      setState(() => _userUid = uid);
    }

    await FirestoreHelper().setUID(_userUid);
    await _syncProfileToFirebase();

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
    // Source labels: "Firestore" (cloud), "Local" (snapshot), "None"
    final recoverySource = clonedAlerts
        ? 'Firestore'
        : snapshotRestored
            ? 'Local'
            : 'None';

    final success = restoredUser && (clonedAlerts || snapshotRestored);
    final summary = "AuthRecovery outcome | success=$success source=$recoverySource"
        " clonedAlerts=$clonedAlerts snapshot=$snapshotRestored "
        "sourceUid=${sourceUid ?? 'none'} retries=$retries timedOut=$timedOut";
    log(summary, name: "AUTH RECOVERY");

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
