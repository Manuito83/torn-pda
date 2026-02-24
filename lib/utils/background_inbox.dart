import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

const String _kPendingStockUpdateInboxKey = 'pda_pending_stock_updates';
const String _kStockChannelSubstring = 'Alerts stocks';
const String _kSendbirdKey = 'sendbird';
const String _kMessageBodyKey = 'message';
const String _kChannelIdKey = 'channelId';

/// Background entry point for FCM messages in a headless isolate
/// Pattern for data pushes:
/// - Enqueue raw payloads in an inbox (SharedPreferences)
/// - Do not touch Sembast on this isolate to avoid corruption
/// - On app launch, drain the inbox on the main isolate (see `drainFcmInbox`).
@pragma('vm:entry-point')
Future<void> messagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = message.data;

  try {
    await _handleStockAlert(data, message.notification);
  } catch (e) {
    debugPrint('FCM stock alert error: $e');
  }

  try {
    await _handleSendbirdAlert(data);
  } catch (e) {
    debugPrint('FCM sendbird alert error: $e');
  }
}

/// Drain FCM inboxes on the main isolate
Future<void> drainFcmInbox() async {
  await _drainStockInbox();

  // ... future inboxes...
}

Future<void> _drainStockInbox() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_kPendingStockUpdateInboxKey);

    if (pending == null || pending.isEmpty) return;

    final existing = await Prefs().getDataStockMarket();
    final combined = existing.isNotEmpty ? "$existing\n${pending.join('\n')}" : pending.join('\n');

    await Prefs().setDataStockMarket(combined);
    await prefs.remove(_kPendingStockUpdateInboxKey);
  } catch (e) {
    debugPrint('Drain stock inbox error: $e');
  }
}

Future<void> _handleStockAlert(Map<String, dynamic> data, RemoteNotification? notification) async {
  final channelId = data[_kChannelIdKey] as String?;
  if (channelId?.contains(_kStockChannelSubstring) != true) return;

  final body = notification?.body;
  if (body == null || body.isEmpty) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kPendingStockUpdateInboxKey) ?? <String>[];
    existing.add(body);
    await prefs.setStringList(_kPendingStockUpdateInboxKey, existing);
  } catch (e) {
    debugPrint('Handle stock alert error: $e');
  }
}

Future<void> _handleSendbirdAlert(Map<String, dynamic> data) async {
  final rawSendbird = data[_kSendbirdKey];
  if (rawSendbird == null) return;

  final sendbirdData = jsonDecode(rawSendbird);
  final channelUrl = sendbirdData['channel']['channel_url'];

  final rawMessage = data[_kMessageBodyKey];
  if (rawMessage is! String || rawMessage.isEmpty) return;

  final parts = rawMessage.split(":");
  final sender = parts.isNotEmpty ? parts[0].trim() : "";
  final msg = parts.length > 1 ? parts.sublist(1).join(":").trim() : "";

  await showSendbirdNotification(sender, msg, channelUrl, fromBackground: true);
}
