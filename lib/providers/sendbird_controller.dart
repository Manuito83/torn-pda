import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/env/env.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class SendbirdController extends GetxController {
  bool _initialised = false;
  bool _connected = false;

  String _sendbirdAppId = "";
  String _sendbirdAppToken = "";

  bool webviewInForeground = false;

  bool doNotDisturbEnabled = false;
  TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 0, minute: 0);
  String timeZoneName = DateTime.now().timeZoneName;

  final _uc = Get.find<UserController>();

  bool _excludeFactionMessages = false;
  bool get excludeFactionMessages => _excludeFactionMessages;
  set excludeFactionMessages(bool exclude) {
    if (_uc.factionId == 0) {
      toastification.show(
        closeOnClick: true,
        type: ToastificationType.error,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 10),
        title: const Text(
          "No faction found!\n\n"
          "If you just joined one, please reload your API key or relaunch the app and retry",
          maxLines: 10,
        ),
      );
      _excludeFactionMessages = false;
      update();
      return;
    }

    _excludeFactionMessages = exclude;

    _setChannelPushPreference(exclude: exclude, channelUrl: "faction-${_uc.factionId}");
    Prefs().setSendbirdExcludeFactionMessages(exclude);

    update();
  }

  bool _excludeCompanyMessages = false;
  bool get excludeCompanyMessages => _excludeCompanyMessages;
  set excludeCompanyMessages(bool exclude) {
    if (_uc.companyId == 0) {
      toastification.show(
        closeOnClick: true,
        type: ToastificationType.error,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 10),
        title: const Text(
          "No company found!\n\n"
          "If you just joined one, please reload your API key or relaunch the app and retry",
          maxLines: 10,
        ),
      );
      _excludeCompanyMessages = false;
      update();
      return;
    }

    _excludeCompanyMessages = exclude;

    _setChannelPushPreference(exclude: exclude, channelUrl: "company-${_uc.companyId}");
    Prefs().setSendbirdExcludeCompanyMessages(exclude);

    update();
  }

  bool _excludeEliminationMessages = false;
  bool get excludeEliminationMessages => _excludeEliminationMessages;
  set excludeEliminationMessages(bool exclude) {
    _excludeEliminationMessages = exclude;
    Prefs().setSendbirdExcludeEliminationMessages(exclude);
    update();

    _updateEliminationPushPreference(exclude);
  }

  bool _sendBirdPushAndroidRemoteConfigEnabled = true;
  bool get sendBirdPushAndroidRemoteConfigEnabled => _sendBirdPushAndroidRemoteConfigEnabled;
  set sendBirdPushAndroidRemoteConfigEnabled(bool enabled) {
    _sendBirdPushAndroidRemoteConfigEnabled = enabled;
    if (!enabled && Platform.isAndroid && _connected) {
      // Triggers this ASAP, instead of waiting for user to re-register when relaunching app
      sendbirdUnregisterFCMTokenAndChannel();
    }
  }

  bool _sendBirdPushIOSRemoteConfigEnabled = true;
  bool get sendBirdPushIOSRemoteConfigEnabled => _sendBirdPushIOSRemoteConfigEnabled;
  set sendBirdPushIOSRemoteConfigEnabled(bool enabled) {
    _sendBirdPushIOSRemoteConfigEnabled = enabled;
    if (!enabled && Platform.isIOS && _connected) {
      // Triggers this ASAP, instead of waiting for user to re-register when relaunching app
      sendbirdUnregisterFCMTokenAndChannel();
    }
  }

  bool _sendBirdNotificationsEnabled = false;
  bool get sendBirdNotificationsEnabled => _sendBirdNotificationsEnabled;
  Future<void> sendBirdNotificationsToggle({required bool enabled}) async {
    if (enabled) {
      bool success = await register();
      success = await sendbirdRegisterFCMTokenAndChannel();
      if (success) {
        await Prefs().setSendbirdNotificationsEnabled(true);
        _sendBirdNotificationsEnabled = true;

        _checkAndUpdateServerFactionPushPreferences();
        _checkAndUpdateServerCompanyPushPreferences();
        _checkAndUpdateServerEliminationPushPreferences();
      } else {
        toastification.show(
          closeOnClick: true,
          alignment: Alignment.bottomCenter,
          title: const Text(
            "There was an error activating chat notifications!",
            maxLines: 2,
          ),
        );
      }
    } else {
      await sendbirdUnregisterFCMTokenAndChannel();
      await Prefs().setSendbirdNotificationsEnabled(false);
      _sendBirdNotificationsEnabled = false;
    }
    update();
  }

  Future init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      _excludeFactionMessages = await Prefs().getSendbirdExcludeFactionMessages();
      _excludeCompanyMessages = await Prefs().getSendbirdExcludeCompanyMessages();
      _excludeEliminationMessages = await Prefs().getSendbirdExcludeEliminationMessages();
      _sendBirdNotificationsEnabled = await Prefs().getSendbirdNotificationsEnabled();

      _sendbirdAppId = Env.sendbirdAppId;
      _sendbirdAppToken = Env.sendbirdAppToken;

      if (_sendbirdAppId.isEmpty || _sendbirdAppToken.isEmpty) {
        logToUser("Empty Sendbird env. variables, can't init!");
        return;
      }

      await SendbirdChat.init(
        appId: _sendbirdAppId,
        options: SendbirdChatOptions(
          // No need to save cache for offline view
          useCollectionCaching: false,
        ),
      );
    } catch (e) {
      logToUser("Can't initialise Sendbird: $e");
    }
  }

  @override
  void dispose() async {
    await SendbirdChat.disconnect();
    super.dispose();
  }

  Future register() async {
    try {
      if (_sendbirdAppId.isNotEmpty && _sendbirdAppToken.isNotEmpty) {
        if (_uc.playerId == 0) {
          throw ("Invalid player ID, can't connect to Sendbird!");
        }

        // Get a new session token if ours is older than 7 days
        String? sendBirdSessionToken;
        final tokenAge = await _calculateStoredSendbirdTokenAge();
        if (tokenAge < const Duration(days: 7)) {
          sendBirdSessionToken = await Prefs().getSendbirdSessionToken();
          log("Using saved Sendbird session token (days: ${tokenAge.inDays})");
        } else {
          sendBirdSessionToken =
              await sendbirdGetNewUserSessionToken(_sendbirdAppId, _sendbirdAppToken, _uc.playerId.toString());
          log("Getting new Sendbird session token (days: ${tokenAge.inDays})");
        }

        if (sendBirdSessionToken != null) {
          await connect(_uc.playerId.toString(), sendBirdSessionToken);

          // Only register FCM token if notifications are enabled
          // (we use Sendbird also to share chaining attacks)
          if (_sendBirdNotificationsEnabled) {
            // Remote Config
            if ((Platform.isAndroid && !_sendBirdPushAndroidRemoteConfigEnabled) ||
                (Platform.isIOS && !_sendBirdPushIOSRemoteConfigEnabled)) {
              await sendbirdUnregisterFCMTokenAndChannel();
              return false;
            }

            await sendbirdRegisterFCMTokenAndChannel();

            // Refresh notification preferences!!
            // The server setting is per user, so we need to maintain coherence between installations
            // Also, we need to recheck (and resync) when the user changes faction or company
            await _checkAndUpdateServerFactionPushPreferences();
            await _checkAndUpdateServerCompanyPushPreferences();
            await _checkAndUpdateServerEliminationPushPreferences();
          } else {
            await sendbirdUnregisterFCMTokenAndChannel();
          }

          // Add a user event handler with a unique identifier
          SendbirdChat.removeChannelHandler('channel_handler');
          SendbirdChat.addChannelHandler(
            'channel_handler',
            SendbirdChannelHandler(),
          );

          debugPrintChannels();

          return true;
        } else {
          throw ("Can't get Sendbird session token!");
        }
      }
    } catch (e) {
      logToUser("Can't connect to Sendbird: $e");
    }
    return false;
  }

  Future<String?> sendbirdGetNewUserSessionToken(
    String applicationId,
    String apiToken,
    String userId,
  ) async {
    final dio = Dio();
    final url = 'https://api-$applicationId.sendbird.com/v3/users/$userId/token';

    try {
      final response = await dio.post(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json; charset=utf-8', 'Api-Token': apiToken},
        ),
        data: {}, // Empty, but needed for Sendbird to work
      );

      if (response.statusCode == 200) {
        logToUser("Sendbird token obtained: ${response.data['token']}");
        await Prefs().setSendbirdSessionToken(response.data['token']);
        await Prefs().setSendbirdTokenTimestamp(DateTime.now().millisecondsSinceEpoch);
        return response.data['token'];
      } else {
        logToUser("Sendbird unexpected response: ${response.statusCode}");
      }
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          logToUser("Sendbird connection timed out");
          break;
        default:
          logToUser("Sendbird crash: $e");
          break;
      }
    }
    return null;
  }

  Future<bool> sendbirdRegisterFCMTokenAndChannel() async {
    try {
      // Remote Config
      if ((Platform.isAndroid && !_sendBirdPushAndroidRemoteConfigEnabled) ||
          (Platform.isIOS && !_sendBirdPushIOSRemoteConfigEnabled)) {
        return false;
      }

      // Get the push token based on platform
      String? fcmToken = await _getFCMToken();
      if (fcmToken == null || fcmToken.isEmpty) throw ("could not get FCM token");

      // Register push token with Sendbird
      final regStatus = await SendbirdChat.registerPushToken(
        type: Platform.isAndroid ? PushTokenType.fcm : PushTokenType.apns,
        token: fcmToken,
      );

      if (regStatus == PushTokenRegistrationStatus.success) {
        log("Successfully registered user FCM token with Sendbird!");

        // Ensure it's not just mentions
        await SendbirdChat.setPushTriggerOption(PushTriggerOption.all);
      } else {
        logToUser("Failed to register push token with Sendbird: [Status != completed]");
      }

      // Add channel
      createSendBirdNotificationsChannel();

      return true;
    } catch (e) {
      logToUser("Failed to register push token with Sendbird: $e");
    }
    return false;
  }

  Future<void> sendbirdUnregisterFCMTokenAndChannel() async {
    try {
      // Get the push token based on platform
      String? fcmToken = await _getFCMToken();
      if (fcmToken == null) throw ("could not get FCM token");

      await SendbirdChat.unregisterPushToken(
        token: fcmToken,
        type: Platform.isAndroid ? PushTokenType.fcm : PushTokenType.apns,
      );

      // Delete channel
      removeSendBirdNotificationsChannel();

      log("Sendbird push notifications disabled and token removed");
    } catch (e) {
      logToUser("Failed to unregister Sendbird push token: $e");
    }
  }

  Future<String?> _getFCMToken() async {
    String? fcmToken;
    if (Platform.isAndroid) {
      fcmToken = await Prefs().getFCMToken();
    } else if (Platform.isIOS) {
      // We don't use Prefs() because we don't store the APNS token there (is does not have any other issues as of PDA v3.5.3)
      fcmToken = await FirebaseMessaging.instance.getAPNSToken();
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      return null;
    }

    return fcmToken;
  }

  Future connect(String playerId, String sendbirdSessionToken) async {
    try {
      final connectionState = SendbirdChat.getConnectionState();
      if (connectionState == MyConnectionState.open) {
        log("Already connected to Sendbird, no need to retry!");
        return;
      }

      await SendbirdChat.connect(playerId, accessToken: sendbirdSessionToken);

      _connected = true;
      log("Connected Sendbird");
    } catch (e) {
      logToUser("Can't connect to Sendbird: $e");
    }
  }

  Future<Duration> _calculateStoredSendbirdTokenAge() async {
    final tokenTimestamp = await Prefs().getSendbirdTokenTimestamp();
    final tokenDate = DateTime.fromMillisecondsSinceEpoch(tokenTimestamp);
    final currentDate = DateTime.now();
    return currentDate.difference(tokenDate);
  }

  Future<void> debugPrintChannels() async {
    try {
      final query = GroupChannelListQuery()
        ..limit = 100
        ..includeEmpty = true
        ..myMemberStateFilter = MyMemberStateFilter.joined;

      List<GroupChannel> channels = [];
      while (query.hasNext) {
        final list = await query.next();
        channels.addAll(list);
      }

      log("--- SENDBIRD DEBUG CHANNELS (${channels.length}) ---");
      for (var c in channels) {
        log("Channel: ${c.channelUrl} (Name: ${c.name})");
      }
      log("---------------------------------------------------");
    } catch (e) {
      logToUser("Error debugging channels: $e");
    }
  }

  Future<void> sendMessage({required String channelUrl, required String message}) async {
    try {
      final connectionState = SendbirdChat.getConnectionState();
      if (connectionState != MyConnectionState.open) {
        if (!initialized) {
          await register();
        }
      }
      GroupChannel replyChannel = await GroupChannel.getChannel(channelUrl);
      replyChannel.sendUserMessage(UserMessageCreateParams(message: message));
    } catch (e) {
      logToUser("$e");
    }
  }

  Future<bool> getDoNotDisturbSettings() async {
    try {
      final result = await SendbirdChat.getDoNotDisturb();
      doNotDisturbEnabled = result.isDoNotDisturbOn;
      startTime = TimeOfDay(hour: result.startHour ?? 0, minute: result.startMin ?? 0);
      endTime = TimeOfDay(hour: result.endHour ?? 0, minute: result.endMin ?? 0);
      timeZoneName = await getLocalTimeZone();
      update();
    } catch (e) {
      logToUser("Sendbird: error getting Do Not Disturb: $e");
      return false;
    }
    return true;
  }

  Future<bool> setDoNotDisturbSettings(bool enabled, TimeOfDay start, TimeOfDay end) async {
    try {
      String timezone = await getLocalTimeZone();
      await SendbirdChat.setDoNotDisturb(
        enable: enabled,
        startHour: start.hour,
        startMin: start.minute,
        endHour: end.hour,
        endMin: end.minute,
        timezone: timezone,
      );
      doNotDisturbEnabled = enabled;
      startTime = start;
      endTime = end;
      timeZoneName = timezone;
      update();
      log("Sendbird: do not disturb updated");
    } catch (e) {
      logToUser("Sendbird: error updating Do Not Disturb: $e");
      return false;
    }
    return true;
  }

  Future<String> getLocalTimeZone() async {
    final location = await FlutterTimezone.getLocalTimezone();
    return location;
  }

  Future<bool> _setChannelPushPreference({
    required String channelUrl,
    required bool exclude,
  }) async {
    String playerId = Get.find<UserController>().playerId.toString();
    if (playerId == "0") {
      throw ("Invalid player ID, can't connect to Sendbird!");
    }

    final preference = exclude ? "off" : "all";

    final dio = Dio();
    final url = 'https://api-$_sendbirdAppId.sendbird.com/v3/users/$playerId/push_preference/$channelUrl';

    try {
      final response = await dio.put(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Api-Token': _sendbirdAppToken,
          },
        ),
        data: {
          "push_trigger_option": preference,
        },
      );

      if (response.statusCode == 200) {
        logToUser("Sendbird API Success: Push preference for user '$playerId' on "
            "channel '$channelUrl' updated to '$preference'. Response: ${response.data}");
        return true;
      } else {
        logToUser("Sendbird API Error: Unexpected response status ${response.statusCode} "
            "for user '$playerId' on channel '$channelUrl'. Response: ${response.data}");
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = "Sendbird API DioException for user '$playerId' "
          "on channel '$channelUrl': ${e.message}";
      if (e.response != null) {
        errorMessage += "\nStatus: ${e.response?.statusCode}\nData: ${e.response?.data}";
      }
      logToUser(errorMessage);

      return false;
    } catch (e) {
      logToUser("Sendbird API: General error for user '$playerId' on channel '$channelUrl': $e");
      return false;
    }
  }

  Future<String> _getChannelPushPreference({
    required String channelUrl,
    required bool exclude,
  }) async {
    String playerId = Get.find<UserController>().playerId.toString();
    if (playerId == "0") {
      throw ("Invalid player ID, can't connect to Sendbird!");
    }

    final dio = Dio();
    final url = 'https://api-$_sendbirdAppId.sendbird.com/v3/users/$playerId/push_preference/$channelUrl';

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Api-Token': _sendbirdAppToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        logToUser("Sendbird API Success: Retrieved push preference for user '$playerId' on "
            "channel '$channelUrl'. Response: ${response.data['push_trigger_option']}");
        return response.data['push_trigger_option'];
      } else {
        logToUser("Sendbird API Error: Unexpected response status ${response.statusCode} "
            "for user '$playerId' on channel '$channelUrl'. Response: ${response.data}");
        return "";
      }
    } on DioException catch (e) {
      String errorMessage = "Sendbird API DioException for user '$playerId' "
          "on channel '$channelUrl': ${e.message}";
      if (e.response != null) {
        errorMessage += "\nStatus: ${e.response?.statusCode}\nData: ${e.response?.data}";
      }
      logToUser(errorMessage);

      return "";
    } catch (e) {
      logToUser("Sendbird API: General error for user '$playerId' on channel '$channelUrl': $e");
      return "";
    }
  }

  Future<String?> _getEliminationChannelUrl() async {
    try {
      final query = GroupChannelListQuery()
        ..limit = 100
        ..includeEmpty = true
        ..myMemberStateFilter = MyMemberStateFilter.joined;

      while (query.hasNext) {
        final list = await query.next();
        for (var channel in list) {
          if (channel.channelUrl.startsWith("elimination-")) {
            return channel.channelUrl;
          }
        }
      }
    } catch (e) {
      logToUser("Error getting elimination channel: $e");
    }
    return null;
  }

  Future<void> _updateEliminationPushPreference(bool exclude) async {
    String? channelUrl = await _getEliminationChannelUrl();
    if (channelUrl != null) {
      _setChannelPushPreference(exclude: exclude, channelUrl: channelUrl);
    }
  }

  Future<void> _checkAndUpdateServerFactionPushPreferences() async {
    if (_uc.factionId != 0) {
      // We first get the current preference, which might have been set by another installation
      String factionExcludedAPI = await _getChannelPushPreference(
        channelUrl: "faction-${_uc.factionId}",
        exclude: _excludeFactionMessages,
      );

      if (factionExcludedAPI.isNotEmpty) {
        final incomingFactionExcluded = factionExcludedAPI.isNotEmpty
            ? factionExcludedAPI == "off"
                ? true
                : false
            : false;

        // If it does not match the current preference, we update it
        if (incomingFactionExcluded != _excludeFactionMessages) {
          _excludeFactionMessages = incomingFactionExcluded;
          update();
          Prefs().setSendbirdExcludeFactionMessages(incomingFactionExcluded);
        }
      }
    }
  }

  Future<void> _checkAndUpdateServerCompanyPushPreferences() async {
    if (_uc.companyId != 0) {
      // We first get the current preference, which might have been set by another installation
      String companyExcludedAPI = await _getChannelPushPreference(
        channelUrl: "company-${_uc.companyId}",
        exclude: _excludeCompanyMessages,
      );

      if (companyExcludedAPI.isNotEmpty) {
        final incomingCompanyExcluded = companyExcludedAPI.isNotEmpty
            ? companyExcludedAPI == "off"
                ? true
                : false
            : false;

        // If it does not match the current preference, we update it
        if (incomingCompanyExcluded != _excludeCompanyMessages) {
          _excludeCompanyMessages = incomingCompanyExcluded;
          update();
          Prefs().setSendbirdExcludeCompanyMessages(incomingCompanyExcluded);
        }
      }
    }
  }

  Future<void> _checkAndUpdateServerEliminationPushPreferences() async {
    String? channelUrl = await _getEliminationChannelUrl();
    if (channelUrl != null) {
      // We first get the current preference, which might have been set by another installation
      String eliminationExcludedAPI = await _getChannelPushPreference(
        channelUrl: channelUrl,
        exclude: _excludeEliminationMessages,
      );

      if (eliminationExcludedAPI.isNotEmpty) {
        final incomingEliminationExcluded = eliminationExcludedAPI.isNotEmpty
            ? eliminationExcludedAPI == "off"
                ? true
                : false
            : false;

        // If it does not match the current preference, we update it
        if (incomingEliminationExcluded != _excludeEliminationMessages) {
          _excludeEliminationMessages = incomingEliminationExcluded;
          update();
          Prefs().setSendbirdExcludeEliminationMessages(incomingEliminationExcluded);
        }
      }
    }
  }

  Future<void> updateFactionAndCompanyPreferences() async {
    await _checkAndUpdateServerFactionPushPreferences();
    await _checkAndUpdateServerCompanyPushPreferences();
    await _checkAndUpdateServerEliminationPushPreferences();
  }

  /// If we have changed faction, we need to update the push preferences for the faction channel
  /// Based on the current existing preference in this app installation
  Future<void> updatePushPreferencesAfterFactionChange() async {
    // If notifications are not enabled, it could be because
    //   - It's either the first app run
    //   - They were disabled and we don't really care
    // ... in both cases, there is no need to update: when the user enables them globally, he'll either
    //     see them enabled (and can act) or will get a disabled update if another installation changed them)
    if (!_sendBirdNotificationsEnabled) return;

    _setChannelPushPreference(exclude: _excludeFactionMessages, channelUrl: "faction-${_uc.factionId}");
  }

  /// If we have changed company, we need to update the push preferences for the company channel
  /// Based on the current existing preference in this app installation
  Future<void> updatePushPreferencesAfterCompanyChange() async {
    // If notifications are not enabled, it could be because
    //   - It's either the first app run
    //   - They were disabled and we don't really care
    // ... in both cases, there is no need to update: when the user enables them globally, he'll either
    //     see them enabled (and can act) or will get a disabled update if another installation changed them)
    if (!_sendBirdNotificationsEnabled) return;

    _setChannelPushPreference(exclude: _excludeCompanyMessages, channelUrl: "company-${_uc.companyId}");
  }
}

class SendbirdChannelHandler extends BaseChannelHandler {
  @override
  void onMessageReceived(BaseChannel channel, BaseMessage message) async {
    final sendBirdNotificationsEnabled = await Prefs().getSendbirdNotificationsEnabled();
    if (!sendBirdNotificationsEnabled) return;

    SendbirdController sb = Get.find<SendbirdController>();
    if (sb.webviewInForeground) return;

    log('Message received in channel ${channel.channelUrl}: ${message.message}');
    showSendbirdNotification(message.sender?.nickname ?? "Chat", message.message, channel.channelUrl);
  }
}
