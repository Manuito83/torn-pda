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

  String _sendbirdAppId = "";
  String _sendbirdAppToken = "";

  bool webviewInForeground = false;

  bool doNotDisturbEnabled = false;
  TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 0, minute: 0);
  String timeZoneName = DateTime.now().timeZoneName;

  bool _excludeFactionMessages = false;
  bool get excludeFactionMessages => _excludeFactionMessages;
  set excludeFactionMessages(bool value) {
    _excludeFactionMessages = value;
    Prefs().setSendbirdExcludeFactionMessages(value);
    update();
  }

  bool _excludeCompanyMessages = false;
  bool get excludeCompanyMessages => _excludeCompanyMessages;
  set excludeCompanyMessages(bool value) {
    _excludeCompanyMessages = value;
    Prefs().setSendbirdExcludeCompanyMessages(value);
    update();
  }

  bool _sendBirdNotificationsEnabled = false;
  bool get sendBirdNotificationsEnabled => _sendBirdNotificationsEnabled;
  sendBirdNotificationsToggle({required bool enabled}) async {
    if (enabled) {
      bool success = await register();
      if (success) {
        await Prefs().setSendbirdNotificationsEnabled(true);
        _sendBirdNotificationsEnabled = true;
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
      await sendbirdUnregisterFCMToken();
      await Prefs().setSendbirdNotificationsEnabled(false);
      _sendBirdNotificationsEnabled = false;
    }
    update();
  }

  Future init() async {
    if (_initialised) return;
    _initialised = true;

    _excludeFactionMessages = await Prefs().getSendbirdExcludeFactionMessages();
    _excludeCompanyMessages = await Prefs().getSendbirdExcludeCompanyMessages();
    _sendBirdNotificationsEnabled = await Prefs().getSendbirdNotificationsEnabled();

    try {
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
        String playerId = Get.find<UserController>().playerId.toString();
        if (playerId == "0") {
          throw ("Invalid player ID, can't connect to Sendbird!");
        }

        // Get a new session token if ours is older than 7 days
        String? sendBirdSessionToken;
        final tokenAge = await _calculateStoredSendbirdTokenAge();
        if (tokenAge < const Duration(days: 7)) {
          sendBirdSessionToken = await Prefs().getSendbirdSessionToken();
          log("Using saved Sendbird session token (days: ${tokenAge.inDays})");
        } else {
          sendBirdSessionToken = await sendbirdGetNewUserSessionToken(_sendbirdAppId, _sendbirdAppToken, playerId);
          log("Getting new Sendbird session token (days: ${tokenAge.inDays})");
        }

        if (sendBirdSessionToken != null) {
          await connect(playerId, sendBirdSessionToken);
          await sendbirdRegisterFCMToken();

          // Add a user event handler with a unique identifier
          SendbirdChat.addChannelHandler(
            'channel_handler',
            SendbirdChannelHandler(),
          );

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
        Prefs().setSendbirdSessionToken(response.data['token']);
        Prefs().setSendbirdTokenTimestamp(DateTime.now().millisecondsSinceEpoch);
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

  Future<bool> sendbirdRegisterFCMToken() async {
    try {
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
      return true;
    } catch (e) {
      logToUser("Failed to register push token with Sendbird: $e");
    }
    return false;
  }

  Future<void> sendbirdUnregisterFCMToken() async {
    try {
      // Get the push token based on platform
      String? fcmToken = await _getFCMToken();
      if (fcmToken == null) throw ("could not get FCM token");

      await SendbirdChat.unregisterPushToken(
        token: fcmToken,
        type: Platform.isAndroid ? PushTokenType.fcm : PushTokenType.apns,
      );
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

  sendMessage({required String channelUrl, required String message}) async {
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
}

class SendbirdChannelHandler extends BaseChannelHandler {
  @override
  void onMessageReceived(BaseChannel channel, BaseMessage message) {
    SendbirdController sb = Get.find<SendbirdController>();
    if (sb.webviewInForeground) return;
    if (!sb.sendBirdNotificationsEnabled) return;

    log('Message received in channel ${channel.channelUrl}: ${message.message}');
    showSendbirdNotification(message.sender?.nickname ?? "Chat", message.message, channel.channelUrl);
  }
}
