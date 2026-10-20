// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show DartPluginRegistrant;

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Project imports:
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_reminder.dart';
import 'package:torn_pda/models/chat/chat_send_check.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/chat/chat_push_rules.dart';
import 'package:torn_pda/providers/chat/chat_telemetry.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/torn-pda-native/chat/chat_push.dart';
import 'package:torn_pda/utils/background_prefs.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/settings/alarm_permissions_dialog.dart';

// IDS
// 101 -> 110 profile cooldowns
// 201 travel arrival
// 211 travel departure
// 300 war targets status
// 400 loot
// 499 loot rangers
// 555 chain watcher
// 677000 -> 677999 native chat alerts
// 678000 -> 678999 native chat reminders
// 777 script updates
const webviewNotificationIdPrefix = 88; // 88001, 88002, etc

Future showNotification(Map payload, int notId) async {
  showNotificationBoth(payload, notId);
}

Future showNotificationBoth(Map payload, int notId) async {
  var onTapPayload = '';
  var channelId = '';
  var channelName = '';
  var channelDescription = '';

  String channel = '';
  String messageId = '';
  String tradeId = '';
  String assistId = '';
  String bulkDetails = '';

  if (payload.isNotEmpty) {
    channel = payload["channelId"] ?? '';
    messageId = payload["tornMessageId"] ?? '';
    tradeId = payload["tornTradeId"] ?? '';
    assistId = payload["assistId"] ?? '';
    bulkDetails = payload["bulkDetails"] ?? '';
    if (payload["tornChat"] != null) {
      channel = 'tornChat';
      bulkDetails = payload["message"] ?? 'Chat message received';
    }
  }

  String notificationIcon = "notification_icon";
  Color? notificationColor = Colors.grey;

  if (channel.contains("Alerts energy")) {
    notificationIcon = "notification_energy";
    notificationColor = Colors.green;
    onTapPayload += 'energy';
    channelId = 'Alerts energy';
    channelName = 'Alerts energy';
    channelDescription = 'Automatic alerts for energy';
  } else if (channel.contains("Alerts nerve")) {
    notificationIcon = "notification_nerve";
    notificationColor = Colors.red;
    onTapPayload += 'nerve';
    channelId = 'Alerts nerve';
    channelName = 'Alerts nerve';
    channelDescription = 'Automatic alerts for nerve';
  } else if (channel.contains("Alerts life")) {
    notificationIcon = "notification_life";
    notificationColor = Colors.red;
    onTapPayload += 'life';
    channelId = 'Alerts life';
    channelName = 'Alerts life';
    channelDescription = 'Automatic alerts for life';
  } else if (channel.contains("Alerts travel")) {
    notificationIcon = "notification_travel";
    notificationColor = Colors.blue;
    onTapPayload += 'travel';
    channelId = 'Alerts travel';
    channelName = 'Alerts travel';
    channelDescription = 'Automatic alerts for travel';
  } else if (channel.contains("Alerts restocks")) {
    notificationIcon = "notification_travel";
    notificationColor = Colors.blue;
    onTapPayload += 'restocks';
    channelId = 'Alerts restocks';
    channelName = 'Alerts restocks';
    channelDescription = 'Automatic alerts for foreign restocks';
  } else if (channel.contains("Alerts city shops")) {
    notificationIcon = "notification_city_shops";
    notificationColor = Colors.blue;
    onTapPayload += 'cityShops:${payload["shopId"] ?? ""}';
    channelId = 'Alerts city shops';
    channelName = 'Alerts city shops';
    channelDescription = 'Automatic alerts for city shop restocks';
  } else if (channel.contains("Alerts abroad stay")) {
    notificationIcon = "notification_travel";
    notificationColor = Colors.blue;
    onTapPayload += 'abroadStay';
    channelId = 'Alerts abroad stay';
    channelName = 'Alerts abroad stay';
    channelDescription = 'Automatic reminders while staying abroad';
  } else if (channel.contains("Alerts hospital")) {
    notificationIcon = "notification_hospital";
    notificationColor = Colors.orange[400];
    onTapPayload += 'hospital';
    channelId = 'Alerts hospital';
    channelName = 'Alerts hospital';
    channelDescription = 'Automatic alerts for hospital';
  } else if (channel.contains("Alerts drugs")) {
    notificationIcon = "notification_drugs";
    notificationColor = Colors.pink;
    onTapPayload += 'drugs';
    channelId = 'Alerts drugs';
    channelName = 'Alerts drugs';
    channelDescription = 'Automatic alerts for drugs';
  } else if (channel.contains("Alerts medical")) {
    notificationIcon = "notification_medical";
    notificationColor = Colors.pink;
    onTapPayload += 'medical';
    channelId = 'Alerts medical';
    channelName = 'Alerts medical';
    channelDescription = 'Automatic alerts for medical';
  } else if (channel.contains("Alerts booster")) {
    notificationIcon = "notification_booster";
    notificationColor = Colors.pink;
    onTapPayload += 'booster';
    channelId = 'Alerts booster';
    channelName = 'Alerts booster';
    channelDescription = 'Automatic alerts for booster';
  } else if (channel.contains("Alerts racing")) {
    notificationIcon = "notification_racing";
    notificationColor = Colors.orange[800];
    onTapPayload += 'racing';
    channelId = 'Alerts racing';
    channelName = 'Alerts racing';
    channelDescription = 'Automatic alerts for racing';
  } else if (channel.contains("Alerts messages")) {
    notificationIcon = "notification_messages";
    notificationColor = Colors.purple[700];
    // If payload comes from Firebase with a torn message (mail) id
    if (messageId != '') {
      onTapPayload += 'tornMessageId:$messageId';
    } else {
      onTapPayload += 'tornMessageId:0';
    }
    channelId = 'Alerts messages';
    channelName = 'Alerts messages';
    channelDescription = 'Automatic alerts for messages';
  } else if (channel.contains("Alerts events")) {
    notificationIcon = "notification_events";
    notificationColor = Colors.purple[700];
    onTapPayload += 'events';
    channelId = 'Alerts events';
    channelName = 'Alerts events';
    channelDescription = 'Automatic alerts for events';
  } else if (channel.contains("Alerts trades")) {
    notificationIcon = "notification_trades";
    notificationColor = Colors.green[700];
    // If payload comes from Firebase with a trade id
    if (tradeId != '') {
      onTapPayload += 'tornTradeId:$tradeId';
    } else {
      onTapPayload += 'tornTradeId:0';
    }
    channelId = 'Alerts trades';
    channelName = 'Alerts trades';
    channelDescription = 'Automatic alerts for trades';
  } else if (channel.contains("Alerts refills")) {
    notificationIcon = "notification_refills";
    notificationColor = Colors.blue;
    onTapPayload += 'refills';
    channelId = 'Alerts refills';
    channelName = 'Alerts refills';
    channelDescription = 'Automatic alerts for refills';
  } else if (channel.contains("Alerts stocks")) {
    notificationIcon = "notification_stock_market";
    notificationColor = Colors.green;
    onTapPayload += 'stockMarket';
    channelId = 'Alerts stocks';
    channelName = 'Alerts stocks';
    channelDescription = 'Automatic alerts for stocks';
  } else if (channel.contains("Alerts assists")) {
    notificationIcon = "notification_assists";
    notificationColor = Colors.red;
    onTapPayload += 'assistId:$assistId###assistDetails:${payload["body"]}###bulkDetails:$bulkDetails';
    channelId = 'Alerts assists';
    channelName = 'Alerts assists';
    channelDescription = 'Automatic alerts for assists';
  } else if (channel.contains("Alerts loot")) {
    notificationIcon = "notification_loot";
    notificationColor = Colors.red;
    onTapPayload += 'lootId:$assistId###bulkDetails:$bulkDetails';
    channelId = 'Alerts loot';
    channelName = 'Alerts loot';
    channelDescription = 'Automatic alerts for loot';
  } else if (channel.contains("Alerts retals")) {
    notificationIcon = "notification_retals";
    notificationColor = Colors.red;
    onTapPayload += 'retalId:$assistId###retalsNumber:$bulkDetails';
    channelId = 'Alerts retals';
    channelName = 'Alerts retals';
    channelDescription = 'Automatic alerts for retals';
  } else if (channel.contains("Alerts test")) {
    notificationIcon = "notification_icon";
    notificationColor = Colors.grey;
    channelId = 'Alerts test';
    channelName = 'Alerts test';
    channelDescription = 'Alerts troubleshooting notification';
  } else if (channel.contains("Alerts information")) {
    notificationIcon = "notification_icon";
    notificationColor = Colors.grey;
    channelId = 'Alerts information';
    channelName = 'Alerts information';
    channelDescription = 'Information messages';
  } else if (channel.contains("tornChat")) {
    channelId = "Torn chat";
    channelName = "Torn chat";
    channelDescription = 'Torn chat notifications';
    onTapPayload += payload["nativeChatTap"] ?? 'tornChat';
    notificationIcon = "notification_chat";
    notificationColor = Colors.green;
  } else if (channel.contains("Alerts forums")) {
    notificationIcon = "notification_forums";
    notificationColor = Colors.green;
    onTapPayload += 'forums###$bulkDetails';
    channelId = 'Alerts forums';
    channelName = 'Alerts forums';
    channelDescription = 'Automatic alerts for forums';
  } else if (channel.contains("Alerts work stats")) {
    notificationIcon = "notification_icon";
    notificationColor = Colors.amber;
    channelId = 'Alerts work stats';
    channelName = 'Alerts work stats';
    channelDescription = 'Automatic alerts for work stats targets';
  }

  String title = payload["title"] ?? "";
  String body = payload["body"] ?? "";
  if (channel.contains("tornChat")) {
    List<String> parts = (payload["message"] ?? "").split(":");

    title = parts.isNotEmpty ? parts[0].trim() : "";
    body = parts.length > 1 ? parts.sublist(1).join(":").trim() : "";
  }

  final tone = ChatTone.decode('${payload["chatTone"]}') ?? const ChatTone(ChatSound.silent);

  if (Platform.isAndroid) {
    final modifier = await getNotificationChannelsModifiers();

    // Add s for custom sounds
    if (channelId.contains("travel") || channelId.contains("assists") || channelId.contains("loot")) {
      channelId = "$channelId ${modifier.channelIdModifier} s";
      channelName = "$channelName ${modifier.channelIdModifier} s";
    } else {
      channelId = "$channelId ${modifier.channelIdModifier}";
      channelName = "$channelName ${modifier.channelIdModifier}";
    }

    final platformChannelSpecifics = NotificationDetails(
      android: channel.contains("tornChat")
          ? await _tornChatAndroidDetails(body, tone: tone)
          : AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        styleInformation: const BigTextStyleInformation(''),
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        icon: notificationIcon,
        color: notificationColor,
        ledOnMs: 1000,
        ledOffMs: 500,
        ticker: payload["title"],
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      notId,
      title,
      body,
      platformChannelSpecifics,
      // Set payload to be handled by local notifications
      payload: onTapPayload,
    );
  } else if (Platform.isIOS) {
    var platformChannelSpecifics = const NotificationDetails(
      iOS: DarwinNotificationDetails(presentSound: true, sound: 'slow_spring_board.aiff'),
    );
    if (channelName.contains("travel")) {
      platformChannelSpecifics = const NotificationDetails(
        iOS: DarwinNotificationDetails(presentSound: true, sound: 'aircraft_seatbelt.aiff'),
      );
    } else if (channelName.contains("assists")) {
      platformChannelSpecifics = const NotificationDetails(
        iOS: DarwinNotificationDetails(presentSound: true, sound: 'sword_clash.aiff'),
      );
    } else if (channelName.contains("loot")) {
      platformChannelSpecifics = const NotificationDetails(
        iOS: DarwinNotificationDetails(presentSound: true, sound: 'sword_clash.aiff'),
      );
    } else if (channelName.contains("retals")) {
      platformChannelSpecifics = const NotificationDetails(
        iOS: DarwinNotificationDetails(presentSound: true, sound: 'sword_clash.aiff'),
      );
    } else if (channelName.contains("race")) {
      platformChannelSpecifics = const NotificationDetails(
        iOS: DarwinNotificationDetails(presentSound: true, sound: 'car_start.aiff'),
      );
    } else if (channel.contains("tornChat")) {
      platformChannelSpecifics = NotificationDetails(iOS: _tornChatIosDetails(tone));
    }

    await flutterLocalNotificationsPlugin.show(
      notId,
      title,
      body,
      platformChannelSpecifics,
      // Set payload to be handled by local notifications
      payload: onTapPayload,
    );
  }
}

class VibrationModifier {
  String? channelIdModifier;
  Int64List? vibrationPattern;
}

Future<VibrationModifier> getNotificationChannelsModifiers({String? mod = ""}) async {
  var savedPattern = mod;
  if (mod == "") {
    savedPattern = await Prefs().getVibrationPattern();
  }

  final vibrationPatternLong = Int64List(8);
  vibrationPatternLong[0] = 0;
  vibrationPatternLong[1] = 400;
  vibrationPatternLong[2] = 400;
  vibrationPatternLong[3] = 600;
  vibrationPatternLong[4] = 400;
  vibrationPatternLong[5] = 800;
  vibrationPatternLong[6] = 400;
  vibrationPatternLong[7] = 1000;

  final vibrationPatternMedium = Int64List(5);
  vibrationPatternMedium[0] = 0;
  vibrationPatternMedium[1] = 400;
  vibrationPatternMedium[2] = 400;
  vibrationPatternMedium[3] = 400;
  vibrationPatternMedium[4] = 400;

  final vibrationPatternShort = Int64List(2);
  vibrationPatternShort[0] = 0;
  vibrationPatternShort[1] = 400;

  final vibrationPatternOff = Int64List(1);
  vibrationPatternOff[0] = 0;

  final modifier = VibrationModifier();
  if (savedPattern == "no-vib") {
    modifier.channelIdModifier = "no-vib";
    modifier.vibrationPattern = vibrationPatternOff;
  } else if (savedPattern == "short") {
    modifier.channelIdModifier = "short";
    modifier.vibrationPattern = vibrationPatternShort;
  } else if (savedPattern == "medium") {
    modifier.channelIdModifier = "medium";
    modifier.vibrationPattern = vibrationPatternMedium;
  } else if (savedPattern == "long") {
    modifier.channelIdModifier = "long";
    modifier.vibrationPattern = vibrationPatternLong;
  }

  return modifier;
}

Future configureNotificationChannels({String? mod = ""}) async {
  List<AndroidNotificationChannel> channels = [];

  final modifier = await getNotificationChannelsModifiers(mod: mod);

  channels.add(
    AndroidNotificationChannel(
      'Alerts test ${modifier.channelIdModifier}',
      'Alerts test ${modifier.channelIdModifier}',
      description: 'Alerts troubleshooting notification',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts travel ${modifier.channelIdModifier} s',
      'Alerts travel ${modifier.channelIdModifier} s',
      description: 'Automatic alerts for travel',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('aircraft_seatbelt'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts restocks ${modifier.channelIdModifier}',
      'Alerts restocks ${modifier.channelIdModifier}',
      description: 'Automatic alerts for foreign restocks',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts city shops ${modifier.channelIdModifier}',
      'Alerts city shops ${modifier.channelIdModifier}',
      description: 'Automatic alerts for city shop restocks',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts abroad stay ${modifier.channelIdModifier}',
      'Alerts abroad stay ${modifier.channelIdModifier}',
      description: 'Automatic reminders while staying abroad',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual travel ${modifier.channelIdModifier} s',
      'Manual travel ${modifier.channelIdModifier} s',
      description: 'Manual notifications for travel',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('aircraft_seatbelt'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual flight departure ${modifier.channelIdModifier} s',
      'Manual flight departure ${modifier.channelIdModifier} s',
      description: 'Manual notifications for delayed flight departure',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('aircraft_seatbelt'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts energy ${modifier.channelIdModifier}',
      'Alerts energy ${modifier.channelIdModifier}',
      description: 'Automatic alerts for energy',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual energy ${modifier.channelIdModifier}',
      'Manual energy ${modifier.channelIdModifier}',
      description: 'Manual notifications for energy',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts nerve ${modifier.channelIdModifier}',
      'Alerts nerve ${modifier.channelIdModifier}',
      description: 'Automatic alerts for nerve',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual nerve ${modifier.channelIdModifier}',
      'Manual nerve ${modifier.channelIdModifier}',
      description: 'Manual notifications for nerve',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts hospital ${modifier.channelIdModifier}',
      'Alerts hospital ${modifier.channelIdModifier}',
      description: 'Automatic alerts for hospital',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual hospital ${modifier.channelIdModifier}',
      'Manual hospital ${modifier.channelIdModifier}',
      description: 'Manual notifications for hospital',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual jail ${modifier.channelIdModifier}',
      'Manual jail ${modifier.channelIdModifier}',
      description: 'Manual notifications for jail',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual war ${modifier.channelIdModifier}',
      'Manual war ${modifier.channelIdModifier}',
      description: 'Manual notifications for war',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual race start ${modifier.channelIdModifier}',
      'Manual race start ${modifier.channelIdModifier}',
      description: 'Manual notifications for race start',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('car_start'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts drugs ${modifier.channelIdModifier}',
      'Alerts drugs ${modifier.channelIdModifier}',
      description: 'Automatic alerts for drugs',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual drugs ${modifier.channelIdModifier}',
      'Manual drugs ${modifier.channelIdModifier}',
      description: 'Manual notifications for drugs',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts racing ${modifier.channelIdModifier}',
      'Alerts racing ${modifier.channelIdModifier}',
      description: 'Automatic alerts for racing',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('car_start'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts messages ${modifier.channelIdModifier}',
      'Alerts messages ${modifier.channelIdModifier}',
      description: 'Automatic alerts for messages',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts events ${modifier.channelIdModifier}',
      'Alerts events ${modifier.channelIdModifier}',
      description: 'Automatic alerts for events',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts trades ${modifier.channelIdModifier}',
      'Alerts trades ${modifier.channelIdModifier}',
      description: 'Automatic alerts for trades',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts loot ${modifier.channelIdModifier} s',
      'Alerts loot ${modifier.channelIdModifier} s',
      description: 'Automatic alerts for loot',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('sword_clash'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual loot ${modifier.channelIdModifier}',
      'Manual loot ${modifier.channelIdModifier}',
      description: 'Manual notifications for loot',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('sword_clash'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual life ${modifier.channelIdModifier}',
      'Manual life ${modifier.channelIdModifier}',
      description: 'Manual notifications for life',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts life ${modifier.channelIdModifier}',
      'Alerts life ${modifier.channelIdModifier}',
      description: 'Automatic alerts for life',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts medical ${modifier.channelIdModifier}',
      'Alerts medical ${modifier.channelIdModifier}',
      description: 'Automatic alerts for medical',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual medical ${modifier.channelIdModifier}',
      'Manual medical ${modifier.channelIdModifier}',
      description: 'Manual notifications for medical',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts booster ${modifier.channelIdModifier}',
      'Alerts booster ${modifier.channelIdModifier}',
      description: 'Automatic alerts for booster',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual booster ${modifier.channelIdModifier}',
      'Manual booster ${modifier.channelIdModifier}',
      description: 'Manual notifications for booster',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts stale user ${modifier.channelIdModifier}',
      'Alerts stale user ${modifier.channelIdModifier}',
      description: 'Automatic alerts for inactivity',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts refills ${modifier.channelIdModifier}',
      'Alerts refills ${modifier.channelIdModifier}',
      description: 'Automatic alerts for refills',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts stocks ${modifier.channelIdModifier}',
      'Alerts stocks ${modifier.channelIdModifier}',
      description: 'Automatic alerts for stocks',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts assists ${modifier.channelIdModifier} s',
      'Alerts assists ${modifier.channelIdModifier} s',
      description: 'Automatic alerts for assists',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('sword_clash'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts retals ${modifier.channelIdModifier} s',
      'Alerts retals ${modifier.channelIdModifier} s',
      description: 'Automatic alerts for retals',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('sword_clash'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual chain ${modifier.channelIdModifier}',
      'Manual chain ${modifier.channelIdModifier}',
      description: 'Manual notifications for chain',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Stakeouts ${modifier.channelIdModifier}',
      'Stakeouts ${modifier.channelIdModifier}',
      description: 'Stakeout alerts',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual scripts ${modifier.channelIdModifier}',
      'Manual scripts ${modifier.channelIdModifier}',
      description: 'Manual notifications for scripts',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts forums ${modifier.channelIdModifier} s',
      'Alerts forums ${modifier.channelIdModifier}',
      description: 'Automatic alerts for forums',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  if (NativeChat.compiled) {
    // Sendbird era ids keep user customizations
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(
          const AndroidNotificationChannelGroup('sendbird', 'Torn chat', description: 'Torn chat notifications'),
        );
    channels.add(
      AndroidNotificationChannel(
        'Torn chat ${modifier.channelIdModifier} s',
        'Torn chat ${modifier.channelIdModifier} s',
        groupId: 'sendbird',
        description: 'Torn chat notifications',
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('keyboard'),
        vibrationPattern: modifier.vibrationPattern,
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
      ),
    );
  }

  channels.add(
    AndroidNotificationChannel(
      'Manual scripts ${modifier.channelIdModifier}',
      'Manual scripts ${modifier.channelIdModifier}',
      description: 'Manual notifications for scripts',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual webview ${modifier.channelIdModifier}',
      'Manual webview ${modifier.channelIdModifier}',
      description: 'Manual notifications from browser',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts information ${modifier.channelIdModifier} s',
      'Alerts information ${modifier.channelIdModifier} s',
      description: 'Information messages',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('aircraft_seatbelt'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts work stats ${modifier.channelIdModifier}',
      'Alerts work stats ${modifier.channelIdModifier}',
      description: 'Automatic alerts for work stats targets',
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: modifier.vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  for (final channel in channels) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

Future reconfigureNotificationChannels({String? mod}) async {
  if (Platform.isAndroid) {
    const platform = MethodChannel('tornpda.channel');
    platform.invokeMethod('deleteNotificationChannels');
    configureNotificationChannels(mod: mod);
  }
}

Future assessExactAlarmsPermissionsAndroid(BuildContext context, SettingsProvider settingsProvider) async {
  final androidImplementation = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!;
  exactAlarmsPermissionAndroid = await androidImplementation.canScheduleExactNotifications() ?? false;

  if (!exactAlarmsPermissionAndroid) {
    // 0 > Never requested
    // 1 > Native permission requested
    // 2 > Torn PDA dialog shown
    int permissionLevel = settingsProvider.exactPermissionDialogShownAndroid;

    // If we never requested permission before, show the system dialog
    if (permissionLevel == 0) {
      exactAlarmsPermissionAndroid = await androidImplementation.requestExactAlarmsPermission() ?? false;
      settingsProvider.exactPermissionDialogShownAndroid = 1;
    }
    // If system dialog was shown, show own Torn PDA dialog
    else if (permissionLevel == 1) {
      await showDialog(
        useRootNavigator: false,
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlarmPermissionsDialog();
        },
      );
    }
  }
}

/// Android alarm for targets the system clock cannot hold as SET_TIMER is capped at 86400 seconds
Future<void> scheduleAlarmGradeNotificationAndroid({
  required int notificationId,
  required String channelName,
  required String channelDescription,
  required String title,
  required String body,
  required DateTime targetTime,
  required String payload,
  required String sound,
  bool playSound = true,
  bool vibrate = true,
  String icon = 'notification_icon',
}) async {
  if (!Platform.isAndroid) return;

  final modifier = await getNotificationChannelsModifiers();
  final channelId = "$channelName ${modifier.channelIdModifier}";

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    channelId,
    channelId,
    channelDescription: channelDescription,
    importance: Importance.max,
    priority: Priority.max,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    playSound: playSound,
    sound: playSound ? RawResourceAndroidNotificationSound(sound) : null,
    enableVibration: vibrate,
    vibrationPattern: vibrate ? modifier.vibrationPattern : null,
    // FLAG_INSISTENT, repeats until dismissed, bounded by timeoutAfter so that it cannot ring forever
    additionalFlags: Int32List.fromList([4]),
    timeoutAfter: 600000,
    icon: icon,
    color: Colors.grey,
    ledColor: const Color.fromARGB(255, 255, 0, 0),
    ledOnMs: 1000,
    ledOffMs: 500,
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    notificationId,
    title,
    body,
    tz.TZDateTime.from(targetTime, tz.local),
    NotificationDetails(android: androidPlatformChannelSpecifics),
    payload: payload,
    androidScheduleMode: exactAlarmsPermissionAndroid
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

const String _kTornChatDm = 'tornChatDm';
const String _kTornChatReply = 'tchat_reply_action';

Future<({int id, String key})> _ownAccount() async {
  try {
    final own = ownProfileBasicFromJson(await BackgroundPrefs().getOwnDetails());
    return (id: own.playerId ?? 0, key: own.userApiKey ?? '');
  } catch (_) {
    return (id: 0, key: '');
  }
}

Future<AndroidNotificationDetails> _tornChatAndroidDetails(
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

DarwinNotificationDetails _tornChatIosDetails(ChatTone tone, {bool reply = false}) => DarwinNotificationDetails(
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

// False if not a Torn chat DM
@pragma("vm:entry-point")
Future<bool> showTornChatNotification(Map<String, dynamic> data, {bool foreground = false}) async {
  final push = ChatPush.fromData(data);
  if (push == null || push.message.isEmpty) return false;
  if (foreground && NativeChat.coversDmPush) {
    await ChatTelemetry.push('covered_in_app');
    return true;
  }

  // Main isolate prefs are off limits here
  final rules = ChatPushRules.decode(await BackgroundPrefs().getChatPushRules());
  if (!await BackgroundPrefs().getTornChatDmPush()) {
    await ChatTelemetry.push('dm_push_off');
    return true;
  }
  if (!rules.allows(push.senderId, DateTime.now())) {
    await ChatTelemetry.push('suppressed_rules');
    return true;
  }
  final tone = rules.toneFor(push.senderId);
  final own = await _ownAccount();
  final reply = own.key.isNotEmpty && await Prefs().getNativeChatReplyEnabled();
  final android = await _tornChatAndroidDetails(push.message, reply: reply, tone: tone);
  // Same id as the in-app chat alert
  await flutterLocalNotificationsPlugin.show(
    677000 + ChatRoom.dmId(push.senderId).hashCode.abs() % 1000,
    push.senderName,
    push.message,
    NotificationDetails(
      android: android,
      iOS: _tornChatIosDetails(tone, reply: reply),
    ),
    payload: jsonEncode({_kTornChatDm: push.senderId, 'name': push.senderName, 'owner': own.id}),
  );
  await ChatTelemetry.push('shown');
  return true;
}

Future<void> cancelChatNotifications() async {
  try {
    final active = await flutterLocalNotificationsPlugin.getActiveNotifications();
    final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    for (final id in {...active.map((n) => n.id), ...pending.map((n) => n.id)}) {
      if (id != null && id >= 677000 && id < ChatReminders.idBase + ChatReminders.idSpan) {
        await flutterLocalNotificationsPlugin.cancel(id);
      }
    }
  } catch (_) {}
}

Future<void> scheduleChatReminder(ChatReminder reminder, {bool discreet = false}) async {
  final modifier = await getNotificationChannelsModifiers();
  final channelId = 'Chat reminders ${modifier.channelIdModifier}';
  await flutterLocalNotificationsPlugin.zonedSchedule(
    reminder.id,
    discreet ? 'R' : 'Reminder from ${reminder.author}',
    discreet ? ' ' : reminder.excerpt,
    tz.TZDateTime.from(reminder.at, tz.local),
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        channelDescription: 'Reminders set from chat messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'notification_chat',
        color: Colors.green,
        styleInformation: BigTextStyleInformation(discreet ? ' ' : reminder.excerpt),
      ),
      iOS: const DarwinNotificationDetails(presentSound: true),
    ),
    payload: ChatReminders.payload(reminder.roomId, reminder.messageId),
    androidScheduleMode: exactAlarmsPermissionAndroid
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
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
@pragma('vm:entry-point')
Future<void> tornChatBackgroundResponse(NotificationResponse response) async {
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
  await ChatTelemetry.reply(result, main: prefsReadable);
  return switch (result) {
    'sent' => null,
    'disabled' => 'Not sent: open the chat to reply',
    'account_changed' => 'Not sent: account changed',
    'key_risk' => 'Not sent: looks like an API key. Open the chat to send it',
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
  if (!await Prefs().getNativeChatReplyEnabled()) return 'disabled';
  final own = await _ownAccount();
  final warn = !prefsReadable || await Prefs().getNativeChatWarnApiKey();
  final keyRisk = warn ? ChatSendCheck.keyRisk(text, ownKey: own.key) : ChatKeyRisk.none;
  if (checkOwner && owner != own.id) return 'account_changed';
  if (keyRisk != ChatKeyRisk.none) return 'key_risk';
  if (own.key.isEmpty) return 'no_key';
  return ChatPush.reply(userId, text, own.key);
}

Future<void> _showTornChatReplyStatus(int id, String name, String status, String? payload) async {
  await flutterLocalNotificationsPlugin.show(
    id,
    name,
    status,
    NotificationDetails(
      android: Platform.isAndroid ? await _tornChatAndroidDetails(status) : null,
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

// Headless entry point for AppDelegate
@pragma('vm:entry-point')
Future<void> tornChatReplyMain() async {
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
    final own = await _ownAccount();
    await _showTornChatReplyStatus(
      677000 + ChatRoom.dmId(userId).hashCode.abs() % 1000,
      name,
      status,
      jsonEncode({_kTornChatDm: userId, 'name': name, 'owner': own.id}),
    );
  } catch (_) {
    if (!counted) await ChatTelemetry.reply('error', main: prefsReadable);
  }
}

/// Notification tap in a killed state
Future<void> handleNotificationTap(NotificationResponse? notificationResponse) async {
  if (notificationResponse == null) return;
  final chatTap = await handleTornChatResponse(notificationResponse);
  if (chatTap != null) selectNotificationStream.add(NativeChat.dmTapPayload(chatTap.$1, chatTap.$2));
}
