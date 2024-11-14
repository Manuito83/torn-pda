import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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

  bool _sendBirdNotificationsEnabled = true;
  bool get sendBirdNotificationsEnabled => _sendBirdNotificationsEnabled;
  sendBirdNotificationsToogle({required bool enabled}) async {
    if (enabled) {
      bool success = await register();
      if (success) {
        await Prefs().setSendbirdNotificationsEnabled(enabled);
        _sendBirdNotificationsEnabled = true;
      } else {
        toastification.show(
          closeOnClick: true,
          alignment: Alignment.bottomCenter,
          title: Column(
            children: [
              Icon(
                Icons.lock,
                color: Colors.orange,
              ),
              SizedBox(height: 10),
              Text("There was an error activating chat notifications!"),
            ],
          ),
        );
      }
    } else {
      await sendbirdUnregisterFCMToken();
      _sendBirdNotificationsEnabled = false;
    }
    update();
  }

  Future init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      _sendbirdAppId = Env.sendbirdAppId;
      _sendbirdAppToken = Env.sendbirdAppToken;

      if (_sendbirdAppId.isEmpty || _sendbirdAppToken.isEmpty) {
        log("Empty Sendbird env. variables, can't init!");
        return;
      }

      await SendbirdChat.init(appId: _sendbirdAppId);
    } catch (e) {
      log("Can't initialise Sendbird: $e");
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

        // Get a new session token if ours is older than  7 days
        String? sendBirdSessionToken;
        final tokenAge = await _calculateStoredSendbirdTokenAge();
        if (tokenAge < Duration(days: 7)) {
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
      log("Can't connect to Sendbird: $e");
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
        log("Sendbird token obtained: ${response.data['token']}");
        Prefs().setSendbirdSessionToken(response.data['token']);
        Prefs().setSendbirdTokenTimestamp(DateTime.now().millisecondsSinceEpoch);
        return response.data['token'];
      } else {
        log("Sendbird unexpected response: ${response.statusCode}");
      }
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          log("Sendbird connection timed out");
          break;
        default:
          log("Sendbird crash: $e");
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
        log("Failed to register push token with Sendbird: [Status != completed]");
      }
      return true;
    } catch (e) {
      log("Failed to register push token with Sendbird: $e");
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
      log("Failed to unregister Sendbird push token: $e");
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
      log("Can't connect to Sendbird: $e");
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
