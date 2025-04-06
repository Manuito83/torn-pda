// ignore: depend_on_referenced_packages
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/webview/webview_notification_helper.dart';

class WebviewHandlers {
  static void addTornPDACheckHandler({
    required InAppWebViewController webview,
  }) {
    webview.addJavaScriptHandler(
      handlerName: 'isTornPDA',
      callback: (args) async {
        return {'isTornPDA': true};
      },
    );
  }

  static void addPageReloadHandler({
    required InAppWebViewController webview,
  }) {
    webview.addJavaScriptHandler(
      handlerName: 'reloadPage',
      callback: (args) async {
        webview.reload();
      },
    );
  }

  /// Registers the Copy to Clipboard handler
  static void addCopyToClipboardHandler({
    required InAppWebViewController webview,
  }) {
    webview.addJavaScriptHandler(
      handlerName: 'copyToClipboard',
      callback: (args) {
        String copy = args.toString();
        if (copy.startsWith("[")) {
          copy = copy.replaceFirst("[", "");
          copy = copy.substring(0, copy.length - 1);
        }
        Clipboard.setData(ClipboardData(text: copy));
      },
    );
  }

  /// Registers the Theme Change handler
  ///
  /// [setStateCallback]: Callback to update the UI
  static void addThemeChangeHandler({
    required InAppWebViewController webview,
    required void Function(VoidCallback fn) setStateCallback,
    required ThemeProvider themeProvider,
    required SettingsProvider settingsProvider,
  }) {
    webview.addJavaScriptHandler(
      handlerName: 'webThemeChange',
      callback: (args) {
        if (!settingsProvider.syncTornWebTheme) return;
        if (args.contains("dark")) {
          // Change to a dark theme only if currently in light mode.
          if (themeProvider.currentTheme == AppTheme.light) {
            if (settingsProvider.darkThemeToSyncFromWeb == "dark") {
              themeProvider.changeTheme = AppTheme.dark;
              log("Web theme changed to dark!");
            } else {
              themeProvider.changeTheme = AppTheme.extraDark;
              log("Web theme changed to extra dark!");
            }
          }
        } else if (args.contains("light")) {
          themeProvider.changeTheme = AppTheme.light;
          log("Web theme changed to light!");
        }
        // Triggers setstate via callback
        setStateCallback(() {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: themeProvider.statusBar,
              systemNavigationBarColor: themeProvider.statusBar,
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
            ),
          );
        });
      },
    );
  }

  /// Registers Notification handlers
  static void addNotificationHandlers({
    required InAppWebViewController webview,
    required FlutterLocalNotificationsPlugin notificationsPlugin,
    required Function assessNotificationPermissions,
  }) {
    webview.addJavaScriptHandler(
      handlerName: 'scheduleNotification',
      callback: (args) async {
        if (args.isEmpty) {
          final errorMsg = 'No arguments provided for scheduleNotification';
          log('[PDA Handler Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }
        final params = args[0];
        List<String> missingParams = [];
        if (params['title'] == null) missingParams.add('title');
        if (params['id'] == null) missingParams.add('id');
        if (params['timestamp'] == null) missingParams.add('timestamp');

        if (missingParams.isNotEmpty) {
          final errorMsg = 'Missing required parameter(s): ${missingParams.join(', ')}';
          log('[PDA Handler Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        final id = params['id'];
        if (id is! int || id < 0 || id > 9999) {
          final errorMsg = 'Parameter "id" must be an integer between 0 and 9999';
          log('[PDA Handler Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        final timestamp = params['timestamp'];
        if (timestamp is! int || timestamp < DateTime.now().millisecondsSinceEpoch) {
          final errorMsg = 'Parameter "timestamp" must be a future Unix timestamp in milliseconds';
          log('[PDA Handler Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        final urlCallbackParam = params['urlCallback'];
        if (urlCallbackParam != null && urlCallbackParam is! String) {
          final errorMsg = 'Parameter "urlCallback" must be a string';
          log('[PDA Handler Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }
        final urlCallback = urlCallbackParam ?? '';

        // Combine timestamp and urlCallback in the payload using "##-88-##" as delimiter
        final combinedPayload = "$timestamp##-88-##$urlCallback";

        final result = await WebviewNotificationsHelper.scheduleJsNotification(
          title: params['title'],
          subtitle: params['subtitle'] ?? '',
          id: id,
          timestampMillis: timestamp,
          overwriteID: params['overwriteID'] ?? false,
          launchNativeToast: params['launchNativeToast'] ?? true,
          toastMessage: params['toastMessage'] ?? '',
          toastColor: params['toastColor'] ?? 'blue',
          toastDurationSeconds: params['toastDurationSeconds'] ?? 3,
          assessNotificationPermissions: assessNotificationPermissions,
          payload: combinedPayload,
        );

        if (result.startsWith('Error')) {
          log('[Notification Error] $result');
          return {'status': 'error', 'message': result};
        }

        log('[Notification Success] $result');
        return {'status': 'success', 'message': result};
      },
    );

    webview.addJavaScriptHandler(
      handlerName: 'cancelNotification',
      callback: (args) async {
        if (args.isEmpty || args[0]['id'] == null) {
          final errorMsg = 'Missing required parameter "id"';
          log('[PDA Handler Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        final int id = args[0]['id'];
        if (id < 0 || id > 9999) {
          final errorMsg = 'Parameter "id" must be between 0 and 9999';
          log('[PDA Handler Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        final int finalId = int.parse('$webviewNotificationIdPrefix$id');
        final pendingNotifications = await notificationsPlugin.pendingNotificationRequests();

        final exists = pendingNotifications.any((notif) => notif.id == finalId);
        if (!exists) {
          final errorMsg = 'Notification with ID $id does not exist';
          log('[Notification Cancel Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        await notificationsPlugin.cancel(finalId);
        final successMsg = 'Notification with ID $id cancelled successfully';
        log('[Notification Cancel Success] $successMsg');
        return {'status': 'success', 'message': successMsg};
      },
    );

    webview.addJavaScriptHandler(
      handlerName: 'getNotification',
      callback: (args) async {
        if (args.isEmpty || args[0]['id'] == null) {
          final errorMsg = 'Missing required parameter "id"';
          log('[PDA Handler Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        final int id = args[0]['id'];
        if (id < 0 || id > 9999) {
          final errorMsg = 'Parameter "id" must be between 0 and 9999';
          log('[PDA Handler Error] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        final int finalId = int.parse('$webviewNotificationIdPrefix$id');
        final pendingNotifications = await notificationsPlugin.pendingNotificationRequests();

        final notif = pendingNotifications.firstWhereOrNull(
          (notif) => notif.id == finalId,
        );

        if (notif == null) {
          final errorMsg = 'Notification with ID $id does not exist';
          log('[Notification Query] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        // Split the payload using the "##-88-##" delimiter to extract the timestamp and URL
        final payloadParts = (notif.payload ?? '').split('##-88-##');
        final timestampMillis = int.tryParse(payloadParts.first) ?? 0;

        final successMsg = 'Notification with ID $id found';
        log('[Notification Query] $successMsg');
        return {
          'status': 'success',
          'message': successMsg,
          'data': {
            'id': id,
            'timestamp': timestampMillis,
            'title': notif.title,
            'body': notif.body,
          },
        };
      },
    );

    webview.addJavaScriptHandler(
      handlerName: 'setAlarm',
      callback: (args) async {
        if (!Platform.isAndroid) {
          const errorMsg = 'Error: Alarms are only supported on Android';
          log('[Alarm Handler] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        if (args.isEmpty || args[0]['timestamp'] == null) {
          const errorMsg = 'Missing required parameter: timestamp';
          log('[Alarm Handler] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        final result = await WebviewNotificationsHelper.setAndroidAlarm(
          timestampMillis: args[0]['timestamp'],
          vibrate: args[0]['vibrate'] ?? true,
          sound: args[0]['sound'] ?? true,
          message: args[0]['message'] ?? 'TORN PDA Alarm',
        );

        if (result.startsWith('Error')) {
          log('[Alarm Handler Error] $result');
          return {'status': 'error', 'message': result};
        }

        log('[Alarm Handler Success] $result');
        return {'status': 'success', 'message': result};
      },
    );

    webview.addJavaScriptHandler(
      handlerName: 'setTimer',
      callback: (args) async {
        if (!Platform.isAndroid) {
          const errorMsg = 'Error: Timers are only supported on Android';
          log('[Timer Handler] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        if (args.isEmpty || args[0]['seconds'] == null) {
          const errorMsg = 'Missing required parameter: seconds';
          log('[Timer Handler] $errorMsg');
          return {'status': 'error', 'message': errorMsg};
        }

        final result = await WebviewNotificationsHelper.setAndroidTimer(
          seconds: args[0]['seconds'],
          message: args[0]['message'] ?? 'TORN PDA Timer',
        );

        if (result.startsWith('Error')) {
          log('[Timer Handler Error] $result');
          return {'status': 'error', 'message': result};
        }

        log('[Timer Handler Success] $result');
        return {'status': 'success', 'message': result};
      },
    );

    webview.addJavaScriptHandler(
      handlerName: 'getPlatform',
      callback: (args) async {
        String platform;
        if (Platform.isAndroid) {
          platform = 'Android';
        } else if (Platform.isIOS) {
          platform = 'iOS';
        } else if (Platform.isWindows) {
          platform = 'Windows';
        } else {
          platform = 'Unknown';
        }
        log('[JS Handler] Platform queried: $platform');
        return {'status': 'success', 'platform': platform};
      },
    );
  }

  /// Registers the Loadout Change handler
  ///
  /// [reloadCallback]: Callback to trigger reload action in web
  static void addLoadoutChangeHandler({
    required InAppWebViewController webview,
    required VoidCallback reloadCallback,
  }) {
    webview.addJavaScriptHandler(
      handlerName: 'loadoutChangeHandler',
      callback: (args) async {
        if (args.isNotEmpty) {
          final String message = args[0];
          if (message.contains("equippedSet")) {
            final regex = RegExp(r'"equippedSet":(\d)');
            final match = regex.firstMatch(message);
            if (match != null) {
              final loadout = match.group(1);
              reloadCallback();
              BotToast.showText(
                text: "Loadout $loadout activated!",
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.blue[600]!,
                duration: const Duration(seconds: 1),
                contentPadding: const EdgeInsets.all(10),
              );
              return;
            }
          }
        }
        BotToast.showText(
          text: "There was a problem activating the loadout, are you already using it?",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.red[600]!,
          contentPadding: const EdgeInsets.all(10),
        );
      },
    );
  }

  /// Registers the Script API handlers for HTTP GET, POST and JavaScript evaluation
  static void addScriptApiHandlers({
    required InAppWebViewController webview,
  }) {
    // HTTP GET Handler
    webview.addJavaScriptHandler(
      handlerName: 'PDA_httpGet',
      callback: (args) async {
        final http.Response resp = await http.get(
          WebUri(args[0]),
          headers: Map<String, String>.from(args[1]),
        );
        return _makeScriptApiResponse(resp);
      },
    );

    // HTTP POST Handler
    webview.addJavaScriptHandler(
      handlerName: 'PDA_httpPost',
      callback: (args) async {
        Object? body = args[2];
        if (body is Map<String, dynamic>) {
          body = Map<String, String>.from(body);
        }
        final http.Response resp = await http.post(
          WebUri(args[0]),
          headers: Map<String, String>.from(args[1]),
          body: body,
        );
        return _makeScriptApiResponse(resp);
      },
    );

    // Evaluate JavaScript Handler
    webview.addJavaScriptHandler(
      handlerName: 'PDA_evaluateJavascript',
      callback: (args) async {
        webview.evaluateJavascript(source: args[0]);
        return;
      },
    );
  }

  /// Helper method to create a Script API response similar to GM_xmlHttpRequest()
  static Map<String, dynamic> _makeScriptApiResponse(http.Response resp) {
    return {
      'status': resp.statusCode,
      'statusText': resp.reasonPhrase,
      'responseText': resp.body,
      'responseHeaders': resp.headers.keys.map((key) => '$key: ${resp.headers[key]}').join("\r\n")
    };
  }

  /// Registers a Toast Handler that shows a toast message using BotToast
  static void addToastHandler({
    required InAppWebViewController webview,
  }) {
    webview.addJavaScriptHandler(
      handlerName: 'showToast',
      callback: (args) {
        final params = args.isNotEmpty && args[0] is Map ? args[0] as Map : {};

        final String? text = params['text'] as String?;
        if (text == null || text.trim().isEmpty) {
          log('Toast Handler: No message provided, toast aborted');
          return {'status': 'error', 'message': 'Toast requires a non-empty "text" parameter'};
        }

        final bool clickClose = params['clickClose'] is bool ? params['clickClose'] as bool : false;
        final int seconds = params['seconds'] is int ? params['seconds'] as int : 3;

        final bgColorMap = params['bgColor'] is Map ? params['bgColor'] as Map : null;
        final textColorMap = params['textColor'] is Map ? params['textColor'] as Map : null;

        final bgColor = bgColorMap != null
            ? Color.fromARGB(
                bgColorMap['a'] ?? 255,
                bgColorMap['r'] ?? 0,
                bgColorMap['g'] ?? 0,
                bgColorMap['b'] ?? 255,
              )
            : Colors.blue;

        final textColor = textColorMap != null
            ? Color.fromARGB(
                textColorMap['a'] ?? 255,
                textColorMap['r'] ?? 255,
                textColorMap['g'] ?? 255,
                textColorMap['b'] ?? 255,
              )
            : Colors.white;

        BotToast.showText(
          clickClose: clickClose,
          text: text,
          textStyle: TextStyle(
            fontSize: 14,
            color: textColor,
          ),
          contentColor: bgColor,
          duration: Duration(seconds: seconds),
          contentPadding: const EdgeInsets.all(10),
        );

        return {'status': 'success', 'message': 'Toast displayed successfully'};
      },
    );
  }
}
