import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/user_details_model.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

// TODO: CONFIGURE FOR APP RELEASE
final String appVersion = '1.4.1';
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
        // UserDetailsProvider has to go first to initialize the others!
        ChangeNotifierProvider<UserDetailsProvider>(
            create: (context) => UserDetailsProvider()),
        ChangeNotifierProxyProvider<UserDetailsProvider, TargetsProvider>(
          create: (context) => TargetsProvider(UserDetailsModel()),
          update: (BuildContext context, UserDetailsProvider userProvider,
                  TargetsProvider targetsProvider) =>
              TargetsProvider(userProvider.myUser),
        ),
        ChangeNotifierProxyProvider<UserDetailsProvider, AttacksProvider>(
          create: (context) => AttacksProvider(UserDetailsModel()),
          update: (BuildContext context, UserDetailsProvider userProvider,
                  AttacksProvider attacksProvider) =>
              AttacksProvider(userProvider.myUser),
        ),
        ChangeNotifierProvider<ThemeProvider>(
            create: (context) => ThemeProvider()),
        ChangeNotifierProvider<SettingsProvider>(
            create: (context) => SettingsProvider()),
        ChangeNotifierProxyProvider<UserDetailsProvider, FriendsProvider>(
          create: (context) => FriendsProvider(UserDetailsModel()),
          update: (BuildContext context, UserDetailsProvider userProvider,
                  FriendsProvider friendsProvider) =>
              FriendsProvider(userProvider.myUser),
        ),
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
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
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
