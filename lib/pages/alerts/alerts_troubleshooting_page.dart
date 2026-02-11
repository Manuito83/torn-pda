import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/live_activities/live_update_models.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/user_helper.dart';

enum _MockLiveUpdateDirection {
  outbound,
  returnToTorn,
  repatriation,
}

class _MockTravelScenario {
  final String label;
  final String description;
  final int secondsRemaining;
  final bool defaultHasArrived;

  const _MockTravelScenario({
    required this.label,
    required this.description,
    required this.secondsRemaining,
    required this.defaultHasArrived,
  });
}

class AlertsTroubleshootingPage extends StatefulWidget {
  final FirebaseUserModel? firebaseUserModel;
  final Function reassignFirebaseUserModelCallback;

  const AlertsTroubleshootingPage({
    required this.firebaseUserModel,
    required this.reassignFirebaseUserModelCallback,
    super.key,
  });

  @override
  State<AlertsTroubleshootingPage> createState() => _AlertsTroubleshootingPageState();
}

class _AlertsTroubleshootingPageState extends State<AlertsTroubleshootingPage> {
  // Automatic notifications state
  bool _isTestingNotification = false;
  bool _isResetting = false;

  // Live Updates mock testing state
  static const List<_MockTravelScenario> _mockTravelScenarioPresets = [
    _MockTravelScenario(
      label: "Already landed",
      description: "Simulates the message after touchdown.",
      secondsRemaining: 0,
      defaultHasArrived: true,
    ),
    _MockTravelScenario(
      label: "Final approach (< 1 min)",
      description: "Matches the less-than-a-minute warning.",
      secondsRemaining: 45,
      defaultHasArrived: false,
    ),
    _MockTravelScenario(
      label: "Landing in 1 minute",
      description: "Uses the one minute remaining wording.",
      secondsRemaining: 75,
      defaultHasArrived: false,
    ),
    _MockTravelScenario(
      label: "Landing in ~5 minutes",
      description: "Typical mid-flight alert with a few minutes to go.",
      secondsRemaining: 300,
      defaultHasArrived: false,
    ),
    _MockTravelScenario(
      label: "Landing in ~15 minutes",
      description: "Longer lead time for extended flights.",
      secondsRemaining: 900,
      defaultHasArrived: false,
    ),
  ];

  final TextEditingController _mockLiveUpdateLocationController = TextEditingController(text: "Mexico");
  _MockTravelScenario _selectedMockTravelScenario =
      _mockTravelScenarioPresets.length > 1 ? _mockTravelScenarioPresets[1] : _mockTravelScenarioPresets.first;
  _MockLiveUpdateDirection _mockLiveUpdateDirection = _MockLiveUpdateDirection.outbound;
  bool _mockLiveUpdateHasArrived =
      (_mockTravelScenarioPresets.length > 1 ? _mockTravelScenarioPresets[1] : _mockTravelScenarioPresets.first)
          .defaultHasArrived;
  bool _sendingMockLiveUpdate = false;
  LiveUpdateRequestStatus? _lastMockLiveUpdateStatus;
  LiveUpdateUnsupportedReason? _lastMockLiveUpdateReason;
  String? _lastMockLiveUpdateSessionId;

  @override
  void dispose() {
    _mockLiveUpdateLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On Android, show TabView with two tabs
    // On iOS, show both sections in a single scrollable view
    if (Platform.isAndroid) {
      return _buildAndroidLayout();
    } else {
      return _buildIosLayout();
    }
  }

  Widget _buildAndroidLayout() {
    // Only show tabs if Live Updates are supported (Android 8+, API 26)
    final bool liveUpdatesSupported = kSdkAndroid >= 26;

    if (!liveUpdatesSupported) {
      // Same layout as iOS - just notifications, no tabs
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("Troubleshooting", style: TextStyle(color: Colors.white)),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAutomaticNotificationsContentInner(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("Troubleshooting", style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Automatic Notifications"),
              Tab(text: "Live Updates"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildAutomaticNotificationsContent(),
            _buildLiveUpdatesContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildIosLayout() {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Troubleshooting", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAutomaticNotificationsContentInner(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutomaticNotificationsContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
        child: _buildAutomaticNotificationsContentInner(),
      ),
    );
  }

  Widget _buildAutomaticNotificationsContentInner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "If you are having issues receiving alerts, it could be due to several causes. This section will guide "
          "you to try to resolve the problem.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        const Text(
          "To start with, please tap the following button to send yourself a test notification:",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton(
            child: _isTestingNotification
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text("Test Notification"),
            onPressed: _isTestingNotification ? null : _testNotification,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Did it reach you?",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "If it did, it means the server can reach your device with no issues. However, if you are still not getting "
          "other app notifications, please verify that they are correctly selected in the Alerts section and "
          "that your device main settings are not blocking or muting Torn PDA. Otherwise, keep reading.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        const Text(
          "If the test failed or other notifications are not getting in, there might be a communication issue "
          "going on with the server. Please consider the following steps:",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        const Text(
          "1) In case this could be due a misconfiguration at server level, please tap the Soft Reset button "
          "below. Torn PDA will try to reconfigure your user. If you get a success message, please retry "
          "the test notification. Otherwise, keep reading.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton(
            child: _isResetting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text("Soft Reset"),
            onPressed: _isResetting ? null : _softReset,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "2) You can manually force a user reconfiguration in the server by going to Settings in Torn PDA.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        const Text(
          "Start by reloading your API Key (expand the API section at the top and tap 'Reload'). "
          "If that does not solve the problem (check once again the Test Notification here), "
          "remove your API Key (tap the bin icon) and insert it once again.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        const Text(
          "3) Lastly, make sure your device or network configuration (router) is not blocking the Google Cloud or Google "
          "Services, since the Alerts server is hosted there. Some users might use a firewall to block Google "
          "or even download the app from an alternative app store; if that's your case, be aware that you might "
          "be unable to receive Alerts.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        const Text(
          "If all of this fails, there might be a bigger issue happening with your local Torn PDA installation. "
          "Please consider uninstalling the app and installing it again. Before you do so, make sure you backup "
          "whatever option you like in the cloud (you can do this in Settings).",
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLiveUpdatesContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
        child: _buildLiveUpdatesContentInner(),
      ),
    );
  }

  Widget _buildLiveUpdatesContentInner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Use this tester to confirm Travel Live Updates are working on this device.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _mockLiveUpdateLocationController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: "Foreign location",
            hintText: "Mexico",
            helperText: "Used as the destination when traveling abroad or as the origin when returning to Torn.",
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<_MockLiveUpdateDirection>(
          decoration: const InputDecoration(labelText: "Direction"),
          isExpanded: true,
          initialValue: _mockLiveUpdateDirection,
          items: const [
            DropdownMenuItem(
              value: _MockLiveUpdateDirection.outbound,
              child: Text("Traveling abroad"),
            ),
            DropdownMenuItem(
              value: _MockLiveUpdateDirection.returnToTorn,
              child: Text("Returning to Torn"),
            ),
            DropdownMenuItem(
              value: _MockLiveUpdateDirection.repatriation,
              child: Text("Repatriating from hospital"),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _mockLiveUpdateDirection = value;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<_MockTravelScenario>(
          decoration: const InputDecoration(labelText: "Scenario"),
          isExpanded: true,
          initialValue: _selectedMockTravelScenario,
          items: _mockTravelScenarioPresets
              .map(
                (scenario) => DropdownMenuItem<_MockTravelScenario>(
                  value: scenario,
                  child: Text(scenario.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedMockTravelScenario = value;
              _mockLiveUpdateHasArrived = value.defaultHasArrived;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            _selectedMockTravelScenario.description,
            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text("Mark session as arrived"),
          subtitle: Text(
            "Useful to preview the landed state and capsule copy.",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          value: _mockLiveUpdateHasArrived,
          onChanged: (value) {
            setState(() {
              _mockLiveUpdateHasArrived = value;
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sendingMockLiveUpdate ? null : _sendMockLiveUpdate,
                icon: _sendingMockLiveUpdate
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_sendingMockLiveUpdate ? "Starting..." : "Start"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _endMockLiveUpdate,
                icon: const Icon(Icons.stop),
                label: const Text("End"),
              ),
            ),
          ],
        ),
        if (_lastMockLiveUpdateStatus != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _describeLastMockLiveUpdate(),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  // Automatic notifications methods
  Future<void> _testNotification() async {
    bool success = false;

    setState(() {
      _isTestingNotification = true;
    });

    success = await firebaseFunctions.sendAlertsTroubleshootingTest();

    if (success) {
      BotToast.showText(
        text: "Request sent, please wait for a few seconds...",
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.green[800]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }

    if (!success) {
      BotToast.showText(
        text: "There was a problem sending the request, no communication with the server!",
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.orange[800]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }

    setState(() {
      _isTestingNotification = false;
    });
  }

  Future<void> _softReset() async {
    setState(() {
      _isResetting = true;
    });

    try {
      final savedKey = UserHelper.apiKey;

      final dynamic myProfile = await ApiCallsV1.getOwnProfileBasic();

      if (myProfile is OwnProfileBasic) {
        myProfile
          ..userApiKey = savedKey
          ..userApiKeyValid = true;

        FirebaseUserModel? fb = await FirestoreHelper().uploadUsersProfileDetail(myProfile, userTriggered: true);
        widget.reassignFirebaseUserModelCallback(fb);
        await FirestoreHelper().uploadLastActiveTimeAndTokensToFirebase(DateTime.now().millisecondsSinceEpoch);

        if (Platform.isAndroid) {
          final alertsVibration = await Prefs().getVibrationPattern();
          reconfigureNotificationChannels(mod: alertsVibration);
          FirestoreHelper().setVibrationPattern(alertsVibration);
        }

        BotToast.showText(
          text: "Reset successful",
          textStyle: const TextStyle(fontSize: 14, color: Colors.white),
          contentColor: Colors.green[800]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );

        setState(() {
          _isResetting = false;
        });
        return;
      }
    } catch (e) {
      // Fall through to error message
    }

    BotToast.showText(
      text: "There was an error updating the database, try again later!",
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: Colors.orange[800]!,
      duration: const Duration(seconds: 5),
      contentPadding: const EdgeInsets.all(10),
    );

    setState(() {
      _isResetting = false;
    });
  }

  // Live Updates mock methods
  Future<void> _sendMockLiveUpdate() async {
    final bool liveUpdatesSupported = (Platform.isAndroid && kSdkAndroid >= 26) || (Platform.isIOS && kSdkIos >= 16.2);
    if (!liveUpdatesSupported) {
      BotToast.showText(text: "Live Updates are only available on Android 8+ or iOS 16.2+.");
      return;
    }

    if (_sendingMockLiveUpdate) return;

    final LiveActivityBridgeController? controller = _ensureLiveActivityBridge();
    if (controller == null) {
      BotToast.showText(text: "Live Update bridge is unavailable.");
      return;
    }

    final scenario = _selectedMockTravelScenario;
    final bool hasArrived = _mockLiveUpdateHasArrived;
    final String foreignLocation = _mockLiveUpdateLocationController.text.trim().isEmpty
        ? "Mexico"
        : _mockLiveUpdateLocationController.text.trim();

    final int nowSeconds = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final int arrivalTimestamp = hasArrived ? nowSeconds : nowSeconds + scenario.secondsRemaining;
    final int travelDuration = (scenario.secondsRemaining > 0 ? scenario.secondsRemaining + 600 : 1800);
    final int departureTimestamp = arrivalTimestamp - travelDuration;

    final Map<String, dynamic> args = _buildMockLiveUpdateArgs(
      foreignLocation: foreignLocation,
      direction: _mockLiveUpdateDirection,
      arrivalTimestamp: arrivalTimestamp,
      departureTimestamp: departureTimestamp,
      hasArrived: hasArrived,
    );

    FocusScope.of(context).unfocus();
    setState(() {
      _sendingMockLiveUpdate = true;
    });

    try {
      controller.initializeHandler();
      final LiveUpdateStartResult result = await controller.startActivity(arguments: args);
      if (!mounted) return;
      setState(() {
        _sendingMockLiveUpdate = false;
        _lastMockLiveUpdateStatus = result.status;
        _lastMockLiveUpdateReason = result.reason;
        if (result.sessionId != null) {
          _lastMockLiveUpdateSessionId = result.sessionId;
        }
      });

      if (result.isSuccess) {
        BotToast.showText(text: "Mock Live Update ${result.status.name} (${result.sessionId ?? "no session"})");
      } else {
        final reason = result.reason != null ? " (${_formatUnsupportedReason(result.reason!)})" : "";
        BotToast.showText(text: "Live Update unsupported$reason");
      }
    } catch (error, stackTrace) {
      log("Mock Live Update failed: $error");
      logErrorToCrashlytics("Mock Live Update failed", error, stackTrace);
      if (mounted) {
        setState(() {
          _sendingMockLiveUpdate = false;
        });
      } else {
        _sendingMockLiveUpdate = false;
      }
      BotToast.showText(text: "Unable to start Live Update");
    }
  }

  Future<void> _endMockLiveUpdate() async {
    final LiveActivityBridgeController? controller = _ensureLiveActivityBridge();
    if (controller == null) {
      BotToast.showText(text: "Live Update bridge is unavailable.");
      return;
    }

    try {
      final result = await controller.endActivity(sessionId: _lastMockLiveUpdateSessionId);
      if (result.success) {
        setState(() {
          _lastMockLiveUpdateSessionId = null;
          _lastMockLiveUpdateStatus = null;
          _lastMockLiveUpdateReason = null;
        });
        BotToast.showText(text: "Live Update ended");
      } else {
        final reason = result.reason != null ? " (${_formatUnsupportedReason(result.reason!)})" : "";
        BotToast.showText(text: "Unable to end Live Update$reason");
      }
    } catch (error, stackTrace) {
      log("Ending Live Update failed: $error");
      logErrorToCrashlytics("Ending Live Update failed", error, stackTrace);
      BotToast.showText(text: "Error ending Live Update");
    }
  }

  LiveActivityBridgeController? _ensureLiveActivityBridge() {
    try {
      if (Get.isRegistered<LiveActivityBridgeController>()) {
        return Get.find<LiveActivityBridgeController>();
      }
      return Get.put(LiveActivityBridgeController(), permanent: true);
    } catch (error, stackTrace) {
      log("Unable to obtain LiveActivityBridgeController: $error");
      logErrorToCrashlytics("LiveActivityBridgeController missing", error, stackTrace);
      return null;
    }
  }

  Map<String, dynamic> _buildMockLiveUpdateArgs({
    required String foreignLocation,
    required _MockLiveUpdateDirection direction,
    required int arrivalTimestamp,
    required int departureTimestamp,
    required bool hasArrived,
  }) {
    final String normalizedForeign = foreignLocation.isEmpty ? "Abroad" : foreignLocation;
    final int nowSeconds = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final int travelDuration = arrivalTimestamp - departureTimestamp;
    String currentDestinationDisplayName;
    String currentDestinationFlagAsset;
    String originDisplayName;
    String originFlagAsset;
    String vehicleAssetName;
    String activityStateTitle;
    int? earliestReturnTimestamp;
    bool showProgressBar = !hasArrived;

    final bool isChristmasSeason = _isChristmasSeason();

    switch (direction) {
      case _MockLiveUpdateDirection.outbound:
        currentDestinationDisplayName = normalizedForeign;
        currentDestinationFlagAsset = _flagAssetForLocation(normalizedForeign);
        originDisplayName = "Torn";
        originFlagAsset = "ball_torn";
        vehicleAssetName = isChristmasSeason ? "sleigh" : "plane_right";
        activityStateTitle = hasArrived ? "Arrived in" : "Traveling to";
        if (!hasArrived) {
          earliestReturnTimestamp = arrivalTimestamp + travelDuration.abs();
        }
        break;
      case _MockLiveUpdateDirection.returnToTorn:
        currentDestinationDisplayName = "Torn";
        currentDestinationFlagAsset = "ball_torn";
        originDisplayName = normalizedForeign.isEmpty ? "Abroad" : normalizedForeign;
        originFlagAsset = normalizedForeign.isEmpty ? "world_origin_icon" : _flagAssetForLocation(normalizedForeign);
        vehicleAssetName = isChristmasSeason ? "sleigh" : "plane_left";
        activityStateTitle = hasArrived ? "Returned to" : "Returning to";
        break;
      case _MockLiveUpdateDirection.repatriation:
        currentDestinationDisplayName = "Torn";
        currentDestinationFlagAsset = "ball_torn";
        originDisplayName = "Hospital";
        originFlagAsset = "hospital_origin_icon";
        vehicleAssetName = isChristmasSeason ? "sleigh" : "plane_left";
        activityStateTitle = hasArrived ? "Repatriated to" : "Repatriating to";
        break;
    }

    final args = <String, dynamic>{
      'currentDestinationDisplayName': currentDestinationDisplayName,
      'currentDestinationFlagAsset': currentDestinationFlagAsset,
      'originDisplayName': originDisplayName,
      'originFlagAsset': originFlagAsset,
      'arrivalTimeTimestamp': arrivalTimestamp,
      'departureTimeTimestamp': departureTimestamp,
      'currentServerTimestamp': nowSeconds,
      'vehicleAssetName': vehicleAssetName,
      'activityStateTitle': activityStateTitle,
      'showProgressBar': showProgressBar,
      'hasArrived': hasArrived,
    };

    if (earliestReturnTimestamp != null) {
      args['earliestReturnTimestamp'] = earliestReturnTimestamp;
    }

    return args;
  }

  String _flagAssetForLocation(String location) {
    if (location.isEmpty) return "ball_torn";
    String normalized = location.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    switch (normalized) {
      case 'united-kingdom':
        normalized = 'uk';
        break;
      case 'cayman-islands':
        normalized = 'cayman';
        break;
      case 'united-arab-emirates':
        normalized = 'uae';
        break;
      case 'south-africa':
        normalized = 'south-africa';
        break;
    }
    return "ball_$normalized";
  }

  bool _isChristmasSeason() {
    final now = DateTime.now();
    final christmasStart = DateTime(now.year, 12, 19);
    final christmasEnd = DateTime(now.year, 12, 31, 23, 59, 59);
    return now.isAfter(christmasStart) && now.isBefore(christmasEnd);
  }

  String _describeLastMockLiveUpdate() {
    final status = _lastMockLiveUpdateStatus;
    if (status == null) return "";
    final buffer = StringBuffer("Last request: ${status.name.toUpperCase()}");
    if (_lastMockLiveUpdateReason != null) {
      buffer.write(" • ${_formatUnsupportedReason(_lastMockLiveUpdateReason!)}");
    }
    if (_lastMockLiveUpdateSessionId != null) {
      buffer.write(" • session $_lastMockLiveUpdateSessionId");
    }
    return buffer.toString();
  }

  String _formatUnsupportedReason(LiveUpdateUnsupportedReason reason) {
    switch (reason) {
      case LiveUpdateUnsupportedReason.apiTooOld:
        return "API too old";
      case LiveUpdateUnsupportedReason.oemUnavailable:
        return "OEM capsule unavailable";
      case LiveUpdateUnsupportedReason.permissionDenied:
        return "Permission denied";
      case LiveUpdateUnsupportedReason.batteryRestricted:
        return "Battery optimization";
      case LiveUpdateUnsupportedReason.internalError:
        return "Internal error";
      case LiveUpdateUnsupportedReason.unknown:
        return "Unknown reason";
    }
  }
}
