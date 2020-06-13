import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/providers/api_key_provider.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

// TODO: CONFIGURE FOR APP RELEASE
final String appVersion = '1.2.0';
final bool appNeedsChangelog = true;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
  );

  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    selectNotificationSubject.add(payload);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TargetsProvider>(
            create: (context) => TargetsProvider()),
        ChangeNotifierProvider<AttacksProvider>(
            create: (context) => AttacksProvider()),
        ChangeNotifierProvider<ThemeProvider>(
            create: (context) => ThemeProvider()),
        ChangeNotifierProvider<SettingsProvider>(
            create: (context) => SettingsProvider()),
        ChangeNotifierProvider<ApiKeyProvider>(
            create: (context) => ApiKeyProvider()),
        ChangeNotifierProvider<FriendsProvider>(
            create: (context) => FriendsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return MaterialApp(
      title: 'Torn PDA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: _themeProvider.currentTheme == AppTheme.light
            ? Brightness.light
            : Brightness.dark,
      ),
      home: Container(
        color: Colors.black,
        child: SafeArea(
          top: false,
          right: false,
          left: false,
          bottom: true,
          child: DrawerPage(),
        ),
      ),
    );
  }
}
