import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_reminder.dart';
import 'package:torn_pda/models/chat/chat_send_check.dart';
import 'package:torn_pda/models/chat/chat_short_text.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/chat/chat_push_rules.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_models.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/torn-pda-native/chat/chat_push.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/background_prefs.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

const String _kTornChatDm = 'tornChatDm';
const String discreetChatTitle = 'C';
const String discreetChatBody = ' ';
const String _kTornChatReply = 'tchat_reply_action';

Future<String> _ownApiKey() async {
  try {
    return ownProfileBasicFromJson(await BackgroundPrefs().getOwnDetails()).userApiKey ?? '';
  } catch (_) {
    return '';
  }
}

Future<({int id, String token})?> _replySender() async {
  final token = await readNativeApiToken();
  final id = token == null ? null : playerIdFromApiToken(token);
  return id == null ? null : (id: id, token: token!);
}

Future<AndroidNotificationDetails> tornChatAndroidDetails(
  String body, {
  bool reply = false,
  ChatTone tone = const ChatTone(ChatSound.silent),
}) async {
  final modifier = await getNotificationChannelsModifiers(mod: await BackgroundPrefs().getVibrationPattern());
  final pattern = tone.vibration.pattern;
  final resource = tone.sound.resource ?? 'keyboard';
  return AndroidNotificationDetails(
    tone.channelId(modifier.channelIdModifier),
    tone.channelName(modifier.channelIdModifier),
    channelDescription: 'Torn chat notifications',
    importance: Importance.max,
    playSound: tone.sound != ChatSound.silent,
    sound: RawResourceAndroidNotificationSound(resource),
    enableVibration: tone.vibration != ChatVibration.none,
    vibrationPattern: pattern == null ? modifier.vibrationPattern : Int64List.fromList(pattern),
    icon: 'notification_chat',
    color: Colors.green,
    styleInformation: BigTextStyleInformation(body),
    actions: [
      if (reply)
        const AndroidNotificationAction(
          _kTornChatReply,
          'Reply',
          inputs: [AndroidNotificationActionInput(label: 'Type your reply', allowFreeFormInput: true)],
        ),
    ],
  );
}

DarwinNotificationDetails tornChatIosDetails(ChatTone tone, {bool reply = false}) => DarwinNotificationDetails(
  presentSound: tone.sound != ChatSound.silent,
  sound: '${tone.sound.resource ?? 'keyboard'}.aiff',
  categoryIdentifier: reply ? _kTornChatCategory : null,
);

// Also set by Torn's own APNs pushes
const String _kTornChatCategory = 'TORN_CHAT_DM';

List<DarwinNotificationCategory> darwinNotificationCategories({required bool reply}) => [
  DarwinNotificationCategory(
    _kTornChatCategory,
    actions: [
      if (reply)
        DarwinNotificationAction.text(_kTornChatReply, 'Reply', buttonTitle: 'Send', placeholder: 'Type your reply'),
    ],
  ),
];

// Only way to swap iOS categories
Future<void> registerTornChatCategories({required bool reply}) async {
  try {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.initialize(
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
            notificationCategories: darwinNotificationCategories(reply: reply),
          ),
          onDidReceiveNotificationResponse: handleNotificationResponse,
        );
  } catch (e, stackTrace) {
    logErrorToCrashlytics("Torn chat categories", "$e", stackTrace);
  }
}

// False if not a Torn chat DM
@pragma("vm:entry-point")
Future<bool> showTornChatNotification(Map<String, dynamic> data, {bool foreground = false}) async {
  final push = ChatPush.fromData(data);
  if (push == null || push.message.isEmpty) return false;
  if (foreground && NativeChat.coversDmPush) {
    await StatsController.chat.push('covered_in_app');
    return true;
  }

  // Main isolate prefs are off limits here
  final rules = ChatPushRules.decode(await BackgroundPrefs().getChatPushRules());
  if (!await BackgroundPrefs().getTornChatDmPush()) {
    await StatsController.chat.push('dm_push_off');
    return true;
  }
  if (!rules.allows(push.senderId, DateTime.now())) {
    await StatsController.chat.push('suppressed_rules');
    return true;
  }
  final tone = rules.toneFor(push.senderId);
  final sender = await _replySender();
  final reply = sender != null && await BackgroundPrefs().getNativeChatReplyEnabled();
  final discreet = await BackgroundPrefs().getDiscreetAt();
  final body = discreet ? discreetChatBody : chatShortText(push.message, DateTime.now());
  final android = await tornChatAndroidDetails(body, reply: reply, tone: tone);
  // Same id as the in-app chat alert
  await flutterLocalNotificationsPlugin.show(
    chatAlertId(ChatRoom.dmId(push.senderId)),
    discreet ? discreetChatTitle : push.senderName,
    body,
    NotificationDetails(
      android: android,
      iOS: tornChatIosDetails(tone, reply: reply),
    ),
    payload: jsonEncode({_kTornChatDm: push.senderId, 'name': push.senderName, 'owner': ?sender?.id}),
  );
  await StatsController.chat.push('shown');
  return true;
}

Future<void> cancelChatNotifications() async {
  try {
    final active = await flutterLocalNotificationsPlugin.getActiveNotifications();
    final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    for (final id in {...active.map((n) => n.id), ...pending.map((n) => n.id)}) {
      if (id != null &&
          (id == _chatWatchAlarmId || id >= chatAlertIdBase && id < ChatReminders.idBase + ChatReminders.idSpan)) {
        await flutterLocalNotificationsPlugin.cancel(id);
      }
    }
  } catch (_) {}
}

Future<void> _scheduleChatNotice(int id, DateTime at, String title, String body, String payload) async {
  final modifier = await getNotificationChannelsModifiers();
  final channelId = 'Chat reminders ${modifier.channelIdModifier}';
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(at, tz.local),
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        channelDescription: 'Reminders set from chat messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'notification_chat',
        color: Colors.green,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(presentSound: true),
    ),
    payload: payload,
    androidScheduleMode: exactAlarmsPermissionAndroid
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

Future<void> scheduleChatReminder(ChatReminder reminder) async {
  // Discreet is judged at fire time too
  final discreet = await BackgroundPrefs().getDiscreetAt(reminder.at);
  await _scheduleChatNotice(
    reminder.id,
    reminder.at,
    discreet ? 'R' : 'Reminder from ${reminder.author}',
    discreet ? ' ' : reminder.excerpt,
    ChatReminders.payload(reminder.roomId, reminder.messageId),
  );
}

const int _chatWatchAlarmId = 556;

// Five minutes ahead, null cancels
Future<void> setChatWatchAlarm(ChatWatcher? watch, String roomId, String until) async {
  const id = _chatWatchAlarmId;
  await flutterLocalNotificationsPlugin.cancel(id);
  final at = watch?.until.subtract(chatWatchWarning);
  if (watch == null || at == null || !at.isAfter(DateTime.now())) return;
  final discreet = await BackgroundPrefs().getDiscreetAt(at);
  await _scheduleChatNotice(
    id,
    at,
    discreet ? 'W' : 'Chain watch',
    discreet ? ' ' : 'Your chain watch ends at $until. Extend it or leave in the chat',
    ChatReminders.payload(roomId, watch.messageId),
  );
}

// Null when not a Torn chat notification
Future<(int, String?)?> handleTornChatResponse(NotificationResponse response, {bool prefsReadable = true}) async {
  final Object? decoded;
  try {
    decoded = jsonDecode(response.payload ?? '');
  } catch (_) {
    return null;
  }
  if (decoded is! Map || decoded[_kTornChatDm] is! int) return null;
  final int userId = decoded[_kTornChatDm];

  final text = response.input?.trim() ?? '';
  if (response.actionId == _kTornChatReply && text.isNotEmpty && response.id != null) {
    final status = await _tornChatReplyStatus(userId, text, owner: decoded['owner'], prefsReadable: prefsReadable);
    if (status != null) {
      await _showTornChatReplyStatus(response.id!, '${decoded['name'] ?? 'Torn chat'}', status, response.payload);
    }
  }
  return (userId, decoded['name'] is String ? decoded['name'] as String : null);
}

// Android replies, sent without opening the app
Future<void> chatBackgroundResponse(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  // Prefs database belongs to the main isolate
  await handleTornChatResponse(response, prefsReadable: false);
}

// Null when sent
Future<String?> _tornChatReplyStatus(
  int userId,
  String text, {
  Object? owner,
  bool checkOwner = true,
  bool prefsReadable = true,
}) async {
  final result = await _tornChatReply(userId, text, owner: owner, checkOwner: checkOwner, prefsReadable: prefsReadable);
  await StatsController.chat.reply(result, main: prefsReadable);
  return switch (result) {
    'sent' => null,
    'disabled' => 'Not sent: open the chat to reply',
    'account_changed' => 'Not sent: account changed',
    'key_risk' => 'Not sent: looks like an API key. Open the chat to send it',
    'no_token' || 'expired' => 'Open Torn PDA to reply',
    _ => 'Reply failed: $text',
  };
}

Future<String> _tornChatReply(
  int userId,
  String text, {
  required Object? owner,
  required bool checkOwner,
  required bool prefsReadable,
}) async {
  if (!await BackgroundPrefs().getNativeChatReplyEnabled()) return 'disabled';
  final sender = await _replySender();
  if (sender == null) return 'no_token';
  if (checkOwner && owner != sender.id) return 'account_changed';
  final warn = !prefsReadable || await Prefs().getNativeChatWarnApiKey();
  if (warn && ChatSendCheck.keyRisk(text, ownKey: await _ownApiKey()) != ChatKeyRisk.none) return 'key_risk';
  return ChatPush.reply(userId, text, sender.token);
}

Future<void> _showTornChatReplyStatus(int id, String name, String status, String? payload) async {
  final discreet = await BackgroundPrefs().getDiscreetAt();
  if (discreet && status.startsWith('Reply failed')) status = 'Reply failed';
  await flutterLocalNotificationsPlugin.show(
    id,
    discreet ? discreetChatTitle : name,
    status,
    NotificationDetails(
      android: Platform.isAndroid ? await tornChatAndroidDetails(status) : null,
      iOS: const DarwinNotificationDetails(),
    ),
    payload: payload,
  );
}

const MethodChannel _chatReplyChannel = MethodChannel('tornpda/chat_reply');

// iOS replies, relayed by AppDelegate
void listenTornChatReplies({bool prefsReadable = true}) {
  _chatReplyChannel.setMethodCallHandler((call) async {
    if (call.method == 'reply' && call.arguments is Map) {
      await _handleIosTornChatReply(Map<String, dynamic>.from(call.arguments), prefsReadable: prefsReadable);
    }
    return null;
  });
}

Future<void> chatReplyMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  // Prefs database belongs to the main isolate
  listenTornChatReplies(prefsReadable: false);
  await _chatReplyChannel.invokeMethod('ready');
}

Future<void> _handleIosTornChatReply(Map<String, dynamic> args, {required bool prefsReadable}) async {
  var counted = false;
  try {
    final text = '${args['text'] ?? ''}'.trim();
    int? userId;
    String name = 'Torn chat';
    Object? owner;
    final local = args['payload'];
    if (local is String) {
      final decoded = jsonDecode(local);
      if (decoded is! Map || decoded[_kTornChatDm] is! int) return;
      userId = decoded[_kTornChatDm];
      if (decoded['name'] is String) name = decoded['name'];
      owner = decoded['owner'];
    } else {
      final push = ChatPush.fromData(args);
      userId = push?.senderId;
      if (push != null) name = push.senderName;
    }
    if (userId == null || text.isEmpty) return;

    final status = await _tornChatReplyStatus(
      userId,
      text,
      owner: owner,
      checkOwner: local is String,
      prefsReadable: prefsReadable,
    );
    counted = true;
    if (status == null) return;
    final sender = await _replySender();
    await _showTornChatReplyStatus(
      chatAlertId(ChatRoom.dmId(userId)),
      name,
      status,
      jsonEncode({_kTornChatDm: userId, 'name': name, 'owner': ?sender?.id}),
    );
  } catch (_) {
    if (!counted) await StatsController.chat.reply('error', main: prefsReadable);
  }
}

/// Notification tap in a killed state
Future<void> handleNotificationTap(NotificationResponse? notificationResponse) async {
  if (notificationResponse == null) return;
  final chatTap = await handleTornChatResponse(notificationResponse);
  if (chatTap != null) selectNotificationStream.add(NativeChat.dmTapPayload(chatTap.$1, chatTap.$2));
}
