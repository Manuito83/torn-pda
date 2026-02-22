// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/appwidget/appwidget_api_model.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/appwidget/installed_widgets_info.dart';
import 'package:torn_pda/utils/background_prefs.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:workmanager/workmanager.dart';

const String iOSRankedWarWidgetRefreshTaskID = "com.manuito.tornpda.ranked_widget_refresh";

const bool _debugWidgetCooldowns = false;

Future<List<HomeWidgetInfo>> pdaWidget_numberInstalled() async {
  // Check whether the user is using a widget
  return await HomeWidget.getInstalledWidgets();
}

/// Returns the raw list of installed Home Widgets (Android/iOS)
/// Called from:
/// - _updateWidgetsInBackgroundAndroid/_updateWidgetsInBackgroundIOS to early-exit if no widgets
/// - External UI (e.g. Drawer) to check if any widget is present
/// Purpose: Quickly determine if any widget exists before scheduling/doing work
Future<List<HomeWidgetInfo>> getInstalledHomeWidgets() async {
  return await HomeWidget.getInstalledWidgets();
}

// =================================================================================
// Workmanager entry point (router for background tasks on both platforms)
// =================================================================================

/// Workmanager entrypoint that routes background tasks to the proper platform implementation.
/// Called from:
/// - main.dart → Workmanager().initialize(widgetBackgroundTaskDispatcher)
/// Purpose: Single entry-point for Android/iOS background tasks (must be a VM entry-point).
@pragma("vm:entry-point")
void widgetBackgroundTaskDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((taskName, inputData) async {
    log("Workmanager callbackDispatcher triggered for task: $taskName");

    if (Platform.isAndroid) {
      return await _updateWidgetsInBackgroundAndroid(taskName, inputData);
    } else if (Platform.isIOS) {
      return await _updateWidgetsInBackgroundIOS(taskName, inputData);
    }

    return Future.value(true);
  });
}

// =================================================================================
// Background update logic for ANDROID
// =================================================================================

/// Android background worker.
/// Called from:
/// - widgetBackgroundTaskDispatcher (when Platform.isAndroid)
/// Purpose:
/// - For the periodic task ('wm_backgroundUpdate'): fetch data then schedule short one-off follow-ups
///   (3/6/9/12 min) to smooth the refresh cadence.
/// - For one-offs ('wm_backgroundUpdate_X'): just fetch data.
/// Why Android differs: WorkManager allows fairly flexible scheduling; we layer one-offs between periodic runs.
Future<bool> _updateWidgetsInBackgroundAndroid(String taskName, Map<String, dynamic>? inputData) async {
  DateTime now = DateTime.now();
  String timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  log("Android Widget $taskName update @$timeString");

  if (taskName == 'com.tornpda.liveactivity.arrival_backup') {
    return await _handleLiveActivityBackup(inputData);
  }

  if ((await getInstalledHomeWidgets()).isEmpty) {
    return true;
  }

  if (taskName == 'wm_backgroundUpdate') {
    await fetchAndPersistWidgetData();

    await Workmanager().registerOneOffTask('pdaWidget_background_3', 'wm_backgroundUpdate_3',
        initialDelay: const Duration(minutes: 3));
    await Workmanager().registerOneOffTask('pdaWidget_background_6', 'wm_backgroundUpdate_6',
        initialDelay: const Duration(minutes: 6));
    await Workmanager().registerOneOffTask('pdaWidget_background_9', 'wm_backgroundUpdate_9',
        initialDelay: const Duration(minutes: 9));
    await Workmanager().registerOneOffTask('pdaWidget_background_12', 'wm_backgroundUpdate_12',
        initialDelay: const Duration(minutes: 12));
  } else if (taskName.contains("wm_backgroundUpdate_")) {
    // If it is a one-off task, only update
    await fetchAndPersistWidgetData();
  }

  return true;
}

// =================================================================================
// Background update logic for iOS
// =================================================================================

/// iOS background worker.
/// Called from:
/// - widgetBackgroundTaskDispatcher (when Platform.isIOS)
/// Purpose:
/// - Perform a fetch attempt and return success/failure so the system can infer rescheduling.
/// Why iOS differs: iOS background execution is budgeted and opportunistic; we avoid chaining one-offs and
/// simply report success/failure to let the system decide future runs.
Future<bool> _updateWidgetsInBackgroundIOS(String taskName, Map<String, dynamic>? inputData) async {
  DateTime now = DateTime.now();
  String timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  log("iOS Widget BGProcessingTask update @$timeString - Task: $taskName");

  if ((await getInstalledHomeWidgets()).isEmpty) {
    return true;
  }

  try {
    await fetchAndPersistWidgetData();
    return true;
  } catch (e, s) {
    log("Error during iOS background data fetch: $e\n$s");
    return false;
  }
}

/// Handles widget deep-links/intents coming from HomeWidget (e.g., tap reload).
/// Called from:
/// - main.dart → HomeWidget.registerInteractivityCallback(onWidgetInteractivityCallback)
/// Purpose: Toggle the 'reloading' flag, fetch data, and notify widgets to redraw.
@pragma("vm:entry-point")
FutureOr<void> onWidgetInteractivityCallback(Uri? data) async {
  if (data == null) return;

  if (data.host == 'reload_clicked' || data.path.contains('reload_clicked')) {
    log("onWidgetInteractivityCallback: BACKGROUND RELOAD - reload_clicked detected");
    HomeWidget.saveWidgetData<bool>('reloading', true);
    HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
    HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');

    await fetchAndPersistWidgetData();

    HomeWidget.saveWidgetData<bool>('reloading', false);
    HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
    HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');
  }
}

/// Fetches API data and persists it for installed widgets (main + ranked war).
/// Called from:
/// - Background workers on both platforms
/// - syncBackgroundRefreshWithWidgetInstallation (when app is active to force an immediate refresh)
/// - onWidgetInteractivityCallback (manual refresh)
/// Purpose:
/// - Detect which widgets are installed
/// - Read API key from Prefs, fetch data, write shared data via HomeWidget.saveWidgetData
/// - Update widgets after persisting data
Future<void> fetchAndPersistWidgetData() async {
  try {
    final installedWidgets = await getInstalledWidgetsInfo();
    if (!installedWidgets.anyWidgetInstalled) {
      return;
    }

    final bool isPdaWidgetInstalled = installedWidgets.isPdaWidgetInstalled;
    final bool isRankedWarWidgetInstalled = installedWidgets.isRankedWarWidgetInstalled;

    String apiKey = "";
    var savedUserRaw = await BackgroundPrefs().getOwnDetails();
    if (savedUserRaw.isNotEmpty) {
      try {
        apiKey = ownProfileBasicFromJson(savedUserRaw).userApiKey ?? "";
      } catch (e) {
        apiKey = "";
      }
    }

    // Set last updated time globally for all widgets that might need it
    String restoredTimeFormat = await BackgroundPrefs().getDefaultTimeFormat();
    TimeFormatSetting timePrefs = restoredTimeFormat == '24' ? TimeFormatSetting.h24 : TimeFormatSetting.h12;
    DateFormat formatter;
    switch (timePrefs) {
      case TimeFormatSetting.h24:
        formatter = DateFormat('HH:mm');
        break;
      case TimeFormatSetting.h12:
        formatter = DateFormat('hh:mm a');
        break;
    }
    bool timeZoneIsLocal = (await BackgroundPrefs().getDefaultTimeZone()) != 'torn';
    HomeWidget.saveWidgetData<String>(
        'last_updated',
        "${formatter.format(timeZoneIsLocal ? DateTime.now() : DateTime.now().toUtc())} "
            "${timeZoneIsLocal ? 'LT' : 'TCT'}");

    if (apiKey.isEmpty) {
      if (isPdaWidgetInstalled) {
        HomeWidget.saveWidgetData<bool>('main_layout_visibility', false);
        HomeWidget.saveWidgetData<bool>('error_layout_visibility', true);
        HomeWidget.saveWidgetData<String>('error_message', "No API key found!");
      }
      if (isRankedWarWidgetInstalled) {
        HomeWidget.saveWidgetData<bool>('rw_widget_visibility', false);
      }
    } else {
      if (isPdaWidgetInstalled) {
        await _refreshMainPdaWidgetData(apiKey);
      }
      if (isRankedWarWidgetInstalled) {
        await _refreshRankedWarWidgetData(savedUserRaw, apiKey);
      }
    }
  } catch (e, t) {
    log("ERROR AT API WIDGET: $e, $t");
    HomeWidget.saveWidgetData<bool>('reloading', false);
  }

  HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
  HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');
}

/// Schedules periodic background refresh according to platform.
/// Called from:
/// - syncBackgroundRefreshWithWidgetInstallation (when at least one widget is installed)
/// Purpose:
/// - Android: one periodic task; one-offs are scheduled inside the worker
/// - iOS: register BG task for RankedWar only if installed (system decides cadence/budget)
Future<void> startBackgroundRefresh() async {
  final installedWidgets = await getInstalledWidgetsInfo();
  if (!installedWidgets.anyWidgetInstalled) {
    return;
  }

  try {
    if (Platform.isAndroid) {
      await cancelAllWidgetBackgroundTasks();
      Workmanager().registerPeriodicTask(
        "pdaWidget_background",
        'wm_backgroundUpdate',
      );
    } else if (Platform.isIOS) {
      final active = await Workmanager().printScheduledTasks();
      if (installedWidgets.isRankedWarWidgetInstalled) {
        if (!active.contains(iOSRankedWarWidgetRefreshTaskID)) {
          Workmanager().registerPeriodicTask(
            iOSRankedWarWidgetRefreshTaskID,
            iOSRankedWarWidgetRefreshTaskID,
          );
        }
      }
    }
  } catch (e) {
    log("Error starting background update: $e");
  }
}

/// Aligns background tasks with actual widget installation state and can force an immediate refresh when app is active.
/// Called from:
/// - main.dart at startup
/// - drawer.dart on resume lifecycle
/// Purpose:
/// - Start tasks if any widget is present; cancel if none
/// - Toggle 'reloading' and force a foreground refresh to keep widgets fresh while app is open
Future<void> syncBackgroundRefreshWithWidgetInstallation() async {
  log("Handling appWidget background status!");

  final installedWidgets = await getInstalledWidgetsInfo();

  if (installedWidgets.anyWidgetInstalled) {
    await HomeWidget.saveWidgetData<bool>('background_active', true);
    await startBackgroundRefresh();
  } else {
    bool wasBackgroundActive = await HomeWidget.getWidgetData<bool>('background_active', defaultValue: false) ?? false;
    if (wasBackgroundActive) {
      log("No widgets present but service was active: disabling all background tasks");
      await cancelAllWidgetBackgroundTasks();
      await HomeWidget.saveWidgetData<bool>('background_active', false);
    }
  }

  if (installedWidgets.anyWidgetInstalled) {
    await HomeWidget.saveWidgetData<bool>('reloading', true);
    await HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
    await HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');

    await fetchAndPersistWidgetData();

    await HomeWidget.saveWidgetData<bool>('reloading', false);
    await HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
    await HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');
  } else {
    await HomeWidget.saveWidgetData<bool>('reloading', false);
    await HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
    await HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');
  }
}

/// Cancels all platform-specific background tasks related to widgets.
/// Called from:
/// - startBackgroundRefresh (to avoid duplicates)
/// - syncBackgroundRefreshWithWidgetInstallation (when no widgets installed)
/// Purpose: Keep WorkManager/BG tasks clean and not duplicated.
Future<void> cancelAllWidgetBackgroundTasks() async {
  if (Platform.isAndroid) {
    await Workmanager().cancelByUniqueName('pdaWidget_background');
    await Workmanager().cancelByUniqueName('pdaWidget_background_3');
    await Workmanager().cancelByUniqueName('pdaWidget_background_6');
    await Workmanager().cancelByUniqueName('pdaWidget_background_9');
    await Workmanager().cancelByUniqueName('pdaWidget_background_12');
  } else if (Platform.isIOS) {
    await Workmanager().cancelByUniqueName(iOSRankedWarWidgetRefreshTaskID);
  }
}

/// Fetches Ranked War data and persists it for the Ranked War widget.
/// Called from:
/// - fetchAndPersistWidgetData (only if the Ranked War widget is installed)
/// Purpose: Find a relevant upcoming/active war for the user’s faction and store a compact snapshot.
Future<void> _refreshRankedWarWidgetData(String savedUserRaw, String apiKey) async {
  OwnProfileBasic user;
  try {
    user = ownProfileBasicFromJson(savedUserRaw);
  } catch (e) {
    user = OwnProfileBasic();
  }
  final dynamic warResponse = await ApiCallsV1.getAppWidgetRankedWars(forcedApiKey: apiKey);

  // Get the faction ID to be used for the check
  int? factionIdForCheck = user.faction?.factionId;

  // --- DEBUG: RANKED WAR WIDGET ---
  if (kDebugMode) {
    factionIdForCheck = 52726;
  }
  // --- END DEBUG ---

  bool warFound = false;
  bool finishedWarFound = false;
  if (warResponse is RankedWarsModel && factionIdForCheck != null) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    RankedWar? finishedWar;
    for (final warMap in warResponse.rankedwars!.entries) {
      if (warMap.value.factions!.containsKey(factionIdForCheck.toString())) {
        final war = warMap.value;
        final warStarts = war.war!.start! * 1000;
        final warEnds = war.war!.end! * 1000;

        final bool warIsUpcoming = warStarts > ts;
        final bool warIsActive = warStarts < ts && war.war!.end == 0;
        final bool warIsFinished = war.war!.end != 0 && (ts - warEnds < 48 * 3600 * 1000);

        WarFaction playerFaction = WarFaction();
        WarFaction enemyFaction = WarFaction();
        war.factions!.forEach((id, factionData) {
          if (id == factionIdForCheck.toString()) {
            playerFaction = factionData;
          } else {
            enemyFaction = factionData;
          }
        });

        if (warIsUpcoming || warIsActive) {
          warFound = true;
          HomeWidget.saveWidgetData<bool>('rw_widget_visibility', true);

          if (warIsUpcoming) {
            HomeWidget.saveWidgetData<String>('rw_state', 'upcoming');
            final timeDifference = DateTime.fromMillisecondsSinceEpoch(warStarts).difference(DateTime.now());
            String countdown;
            if (timeDifference.inMinutes < 15) {
              if (Platform.isIOS) {
                countdown = "About to start!";
              } else {
                countdown = "about to start!";
              }
            } else if (timeDifference.inMinutes < 45) {
              if (Platform.isIOS) {
                countdown = "Less than 1h!";
              } else {
                countdown = "in less than 1h!";
              }
            } else {
              String twoDigits(int n) => n.toString().padLeft(2, "0");
              if (timeDifference.inDays > 0) {
                if (Platform.isIOS) {
                  countdown = '${timeDifference.inDays}d ${twoDigits(timeDifference.inHours.remainder(24))}h';
                } else {
                  countdown = 'in ${timeDifference.inDays}d ${twoDigits(timeDifference.inHours.remainder(24))}h';
                }
              } else {
                if (Platform.isIOS) {
                  countdown = '${twoDigits(timeDifference.inHours)}h';
                } else {
                  countdown = 'in ${twoDigits(timeDifference.inHours)}h';
                }
              }
              countdown = countdown.replaceAll("0d ", "");
            }
            HomeWidget.saveWidgetData<String>('rw_countdown_string', countdown);

            final warStartDateTime = DateTime.fromMillisecondsSinceEpoch(warStarts);
            final dateFormat = DateFormat('MMM d, HH:mm');
            // Use same timezone preference as other widget times
            bool timeZoneIsLocal = (await BackgroundPrefs().getDefaultTimeZone()) != 'torn';
            final displayDateTime = timeZoneIsLocal ? warStartDateTime : warStartDateTime.toUtc();
            HomeWidget.saveWidgetData<String>('rw_date_string', dateFormat.format(displayDateTime));

            final bool lessThan24h = warStarts - ts < 86400000;
            HomeWidget.saveWidgetData<bool>('rw_upcoming_soon', lessThan24h);

            HomeWidget.saveWidgetData<String>('rw_player_faction_tag', user.faction!.factionTag);
            HomeWidget.saveWidgetData<String>('rw_enemy_faction_name', enemyFaction.name);
            HomeWidget.saveWidgetData<int>('rw_player_chain', 0);
          } else {
            HomeWidget.saveWidgetData<String>('rw_state', 'active');
            HomeWidget.saveWidgetData<int>('rw_player_score', playerFaction.score);
            HomeWidget.saveWidgetData<int>('rw_enemy_score', enemyFaction.score);
            HomeWidget.saveWidgetData<String>('rw_player_faction_tag', user.faction!.factionTag);
            HomeWidget.saveWidgetData<String>('rw_enemy_faction_name', enemyFaction.name);
            HomeWidget.saveWidgetData<int>('rw_target_score', war.war!.target);
            HomeWidget.saveWidgetData<int>('rw_player_chain', playerFaction.chain ?? 0);
          }
          break;
        } else if (warIsFinished && !finishedWarFound) {
          // Save the most recent finished war within 48h
          finishedWar = war;
          finishedWarFound = true;
        }
      }
    }
    if (!warFound && finishedWarFound && finishedWar != null) {
      HomeWidget.saveWidgetData<bool>('rw_widget_visibility', true);
      HomeWidget.saveWidgetData<String>('rw_state', 'finished');
      WarFaction playerFaction = WarFaction();
      WarFaction enemyFaction = WarFaction();
      finishedWar.factions!.forEach((id, factionData) {
        if (id == factionIdForCheck.toString()) {
          playerFaction = factionData;
        } else {
          enemyFaction = factionData;
        }
      });
      HomeWidget.saveWidgetData<int>('rw_player_score', playerFaction.score);
      HomeWidget.saveWidgetData<int>('rw_enemy_score', enemyFaction.score);
      HomeWidget.saveWidgetData<String>('rw_player_faction_tag', user.faction!.factionTag);
      HomeWidget.saveWidgetData<String>('rw_enemy_faction_name', enemyFaction.name);
      HomeWidget.saveWidgetData<int>('rw_target_score', finishedWar.war!.target);
      // Winner
      String winner = "";
      if (playerFaction.score != null && enemyFaction.score != null) {
        winner = playerFaction.score! > enemyFaction.score! ? playerFaction.name ?? "" : enemyFaction.name ?? "";
      }
      HomeWidget.saveWidgetData<String>('rw_winner', winner);
      // End date
      final warEndDateTime = DateTime.fromMillisecondsSinceEpoch(finishedWar.war!.end! * 1000);
      final dateFormat = DateFormat('MMM d, HH:mm');
      // Use same timezone preference as other widget times
      bool timeZoneIsLocal = (await BackgroundPrefs().getDefaultTimeZone()) != 'torn';
      final displayDateTime = timeZoneIsLocal ? warEndDateTime : warEndDateTime.toUtc();
      HomeWidget.saveWidgetData<String>('rw_end_date_string', dateFormat.format(displayDateTime));
    }
  }
  if (!warFound && !finishedWarFound) {
    HomeWidget.saveWidgetData<bool>('rw_widget_visibility', false);
    HomeWidget.saveWidgetData<int>('rw_player_chain', 0);
  }
}

/// Fetches main PDA widget data and persists it for the main widget.
/// Called from:
/// - fetchAndPersistWidgetData (only if the main PDA widget is installed)
/// Purpose: Build status/counters/shortcuts snapshot for the main widget UI.
Future<void> _refreshMainPdaWidgetData(String apiKey) async {
  var user = await ApiCallsV1.getAppWidgetInfo(forcedApiKey: apiKey, limit: 0);

  if (user is ApiError) {
    if (user.errorId == 100) {
      // Retry in case of timeout
      log("Widget timed out, retrying once after 5 seconds");
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  if (user is AppWidgetApiModel) {
    HomeWidget.saveWidgetData<bool>('main_layout_visibility', true);
    HomeWidget.saveWidgetData<bool>('error_layout_visibility', false);

    String statusDescription = user.status!.description!;
    String state = user.status!.state!;
    String country = countryCheck(state: state, description: statusDescription);

    if (!country.contains("Torn")) {
      // We are flying abroad or in another country

      // And not in a (foreign hospital)
      if (state != "Hospital") {
        var dateTimeArrival = DateTime.fromMillisecondsSinceEpoch(user.travel!.timestamp! * 1000);
        var timeDifference = dateTimeArrival.difference(DateTime.now());
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
        if (statusDescription.contains("Traveling to")) {
          statusDescription = statusDescription.replaceAll("Traveling to ", "");

          // Shorten certain destinations so that we leave as much space as possible for the time
          statusDescription = statusDescription.replaceAll("Cayman Islands", "Cayman");
          statusDescription = statusDescription.replaceAll("South Africa", "S. Africa");
          statusDescription = statusDescription.replaceAll("United Kingdom", "UK");

          statusDescription += ' in ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
          statusDescription = statusDescription.replaceAll("00h ", "");
          HomeWidget.saveWidgetData<String>("travel", "right");
        } else if (state == "Abroad") {
          statusDescription = "Visiting $country";
          HomeWidget.saveWidgetData<String>("travel", "visiting");
        }
      } else {
        // Special case for when we are hospitalized abroad
        var hospitalRelease = DateTime.fromMillisecondsSinceEpoch(user.status!.until! * 1000);
        var timeDifference = hospitalRelease.difference(DateTime.now());
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
        statusDescription = "Hospital in $country: ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m";
        statusDescription = statusDescription.replaceAll("00h ", "");
      }
    } else {
      // Country is reported as Torn

      if (statusDescription.contains("Returning to")) {
        // Are we flying back?
        var dateTimeArrival = DateTime.fromMillisecondsSinceEpoch(user.travel!.timestamp! * 1000);
        var timeDifference = dateTimeArrival.difference(DateTime.now());
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
        statusDescription = "Torn in";
        statusDescription += ' ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
        statusDescription = statusDescription.replaceAll("00h ", "");
        HomeWidget.saveWidgetData<String>("travel", "left");
      } else {
        // We at home in Torn
        HomeWidget.saveWidgetData<String>("travel", "no");

        // Red status in Torn (hospital/jail)
        if (user.status!.color! == "red") {
          bool repatriated = false;
          if (user.travel!.timeLeft! > 0) {
            // Repatriated
            repatriated = true;
            var dateTimeArrival = DateTime.fromMillisecondsSinceEpoch(user.travel!.timestamp! * 1000);
            var timeDifference = dateTimeArrival.difference(DateTime.now());
            String twoDigits(int n) => n.toString().padLeft(2, "0");
            String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
            statusDescription = "Repatriated in";
            statusDescription += ' ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
            statusDescription = statusDescription.replaceAll("00h ", "");
            HomeWidget.saveWidgetData<String>("travel", "left");
          }

          var redEnd = DateTime.fromMillisecondsSinceEpoch(user.status!.until! * 1000);
          var timeDifference = redEnd.difference(DateTime.now());
          String twoDigits(int n) => n.toString().padLeft(2, "0");
          String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
          if (state == "Hospital" && !repatriated) {
            statusDescription = 'Hospital for ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
          } else if (state == "Jail") {
            statusDescription = 'Jail for ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
          }
        }
      }
    }

    HomeWidget.saveWidgetData<String>('country', country);
    HomeWidget.saveWidgetData<String>('status', statusDescription);
    HomeWidget.saveWidgetData<String>('status_color', user.status!.color!);

    // Racing
    String racingStatus = "none";
    String racingString = "";
    if (user.icons?.icon17 != null) {
      racingStatus = "in_progress";
      racingString = user.icons!.icon17!;
    } else if (user.icons?.icon18 != null) {
      racingStatus = "completed";
      racingString = user.icons!.icon18!;
    }
    HomeWidget.saveWidgetData<String>('racing', racingStatus);
    HomeWidget.saveWidgetData<String>('racing_string', racingString);

    // Messages and events
    int unreadMessages = user.messages?.length ?? 0;
    HomeWidget.saveWidgetData<int>('messages', unreadMessages);

    int unreadEvents = user.events?.length ?? 0;
    HomeWidget.saveWidgetData<int>('events', unreadEvents);

    // Energy
    int currentEnergy = user.energy!.current!;
    int maxEnergy = user.energy!.maximum!;
    HomeWidget.saveWidgetData<int>('energy_current', currentEnergy);
    HomeWidget.saveWidgetData<int>('energy_max', maxEnergy);
    HomeWidget.saveWidgetData<String>('energy_text', "$currentEnergy/$maxEnergy");

    // Nerve
    int currentNerve = user.nerve!.current!;
    int maxNerve = user.nerve!.maximum!;
    HomeWidget.saveWidgetData<int>('nerve_current', currentNerve);
    HomeWidget.saveWidgetData<int>('nerve_max', maxNerve);
    HomeWidget.saveWidgetData<String>('nerve_text', "$currentNerve/$maxNerve");

    // Happy
    int currentHappy = user.happy!.current!;
    int maxHappy = user.happy!.maximum!;
    HomeWidget.saveWidgetData<int>('happy_current', currentHappy);
    HomeWidget.saveWidgetData<int>('happy_max', maxHappy);
    HomeWidget.saveWidgetData<String>('happy_text', "$currentHappy");

    // Life
    int currentLife = user.life!.current!;
    int maxLife = user.life!.maximum!;
    HomeWidget.saveWidgetData<int>('life_current', currentLife);
    HomeWidget.saveWidgetData<int>('life_max', maxLife);
    HomeWidget.saveWidgetData<String>('life_text', "$currentLife");

    // Chain
    int currentChain = user.chain!.current!;
    int maxChain = 10;
    if (currentChain >= 10 && currentChain < 25) {
      maxChain = 25;
    } else if (currentChain >= 25 && currentChain < 50) {
      maxChain = 50;
    } else if (currentChain >= 50 && currentChain < 100) {
      maxChain = 100;
    } else if (currentChain >= 100 && currentChain < 250) {
      maxChain = 250;
    } else if (currentChain >= 250 && currentChain < 500) {
      maxChain = 500;
    } else if (currentChain >= 500 && currentChain < 1000) {
      maxChain = 1000;
    } else if (currentChain >= 1000 && currentChain < 2500) {
      maxChain = 2500;
    } else if (currentChain >= 2500 && currentChain < 5000) {
      maxChain = 5000;
    } else if (currentChain >= 5000 && currentChain < 10000) {
      maxChain = 10000;
    } else if (currentChain >= 10000 && currentChain < 25000) {
      maxChain = 25000;
    } else if (currentChain >= 25000 && currentChain < 50000) {
      maxChain = 50000;
    } else if (currentChain >= 50000 && currentChain < 100000) {
      maxChain = 100000;
    }

    HomeWidget.saveWidgetData<int>('chain_current', currentChain);
    HomeWidget.saveWidgetData<int>('chain_max', maxChain);
    HomeWidget.saveWidgetData<String>('chain_text', user.chain!.cooldown! > 0 ? "COOLDOWN" : "$currentChain");

    // Money
    String money = "0";
    int onHand = user.moneyOnhand!;
    if (onHand >= 1000000000000) {
      money = "\$${(onHand / 1000000000000).toStringAsFixed(1)}T";
    } else if (onHand >= 1000000000) {
      money = "\$${(onHand / 1000000000).toStringAsFixed(1)}B";
    } else if (onHand >= 1000000) {
      money = "\$${(onHand / 1000000).toStringAsFixed(1)}M";
    } else if (onHand >= 1000) {
      money = "\$${(onHand / 1000).toStringAsFixed(onHand < 10000 ? 1 : 0)}K";
    } else {
      money = "\$$onHand";
    }
    HomeWidget.saveWidgetData<String>('money', money);

    // Last Updated
    String restoredTimeFormat = await BackgroundPrefs().getDefaultTimeFormat();
    TimeFormatSetting timePrefs = restoredTimeFormat == '24' ? TimeFormatSetting.h24 : TimeFormatSetting.h12;
    DateFormat formatter;
    switch (timePrefs) {
      case TimeFormatSetting.h24:
        formatter = DateFormat('HH:mm');
        break;
      case TimeFormatSetting.h12:
        formatter = DateFormat('hh:mm a');
        break;
    }

    bool timeZoneIsLocal = (await BackgroundPrefs().getDefaultTimeZone()) != 'torn';
    HomeWidget.saveWidgetData<String>(
        'last_updated',
        "${formatter.format(timeZoneIsLocal ? DateTime.now() : DateTime.now().toUtc())} "
            "${timeZoneIsLocal ? 'LT' : 'TCT'}");

    // COOLDOWNS HELPER FUNCTIONS
    String timeFormatted(DateTime timeEnd) {
      var timeDifference = timeEnd.difference(DateTime.now());
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
      String diff = '';
      if (timeDifference.inMinutes < 1) {
        diff = ', in a few seconds';
      } else if (timeDifference.inMinutes >= 1 && timeDifference.inHours < 24) {
        diff = ', in ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
      } else {
        var dayWeek = TimeFormatter(
          inputTime: timeEnd,
          timeFormatSetting: TimeFormatSetting.h24,
          timeZoneSetting: TimeZoneSetting.localTime,
        ).formatDayWeek;
        diff = ' $dayWeek, in '
            '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
      }
      return diff;
    }

    String formattedTime(DateTime dateTime) {
      var formatted = TimeFormatter(
        inputTime: dateTime,
        timeFormatSetting: timePrefs,
        timeZoneSetting: timeZoneIsLocal ? TimeZoneSetting.localTime : TimeZoneSetting.tornTime,
      ).formatHour;
      return "$formatted${timeFormatted(dateTime)}";
    }

    // COOLDOWNS - DRUGS
    int drugLevel = 0;
    String drugString = "Drug cooldown: ";
    if (user.icons!.icon49 != null) {
      drugLevel = 1;
    } else if (user.icons!.icon50 != null) {
      drugLevel = 2;
    } else if (user.icons!.icon51 != null) {
      drugLevel = 3;
    } else if (user.icons!.icon52 != null) {
      drugLevel = 4;
    } else if (user.icons!.icon53 != null) {
      drugLevel = 5;
    }

    var drugEnd = DateTime.now().add(Duration(seconds: user.cooldowns!.drug!));
    var formattedDrugEnd = formattedTime(drugEnd);
    drugString += formattedDrugEnd;

    HomeWidget.saveWidgetData<int>('drug_level', drugLevel);
    HomeWidget.saveWidgetData<String>('drug_string', drugString);

    // COOLDOWNS - MEDICAL
    int medicalLevel = 0;
    String medicalString = "Medical cooldown: ";
    if (user.icons!.icon44 != null) {
      medicalLevel = 1;
    } else if (user.icons!.icon45 != null) {
      medicalLevel = 2;
    } else if (user.icons!.icon46 != null) {
      medicalLevel = 3;
    } else if (user.icons!.icon47 != null) {
      medicalLevel = 4;
    } else if (user.icons!.icon48 != null) {
      medicalLevel = 5;
    }

    var medicalEnd = DateTime.now().add(Duration(seconds: user.cooldowns!.medical!));
    var formattedMedicalEnd = formattedTime(medicalEnd);
    medicalString += formattedMedicalEnd;

    HomeWidget.saveWidgetData<int>('medical_level', medicalLevel);
    HomeWidget.saveWidgetData<String>('medical_string', medicalString);

    // COOLDOWNS - BOOSTER
    int boosterLevel = 0;
    String boosterString = "Booster cooldown: ";
    if (user.icons!.icon39 != null) {
      boosterLevel = 1;
    } else if (user.icons!.icon40 != null) {
      boosterLevel = 2;
    } else if (user.icons!.icon41 != null) {
      boosterLevel = 3;
    } else if (user.icons!.icon42 != null) {
      boosterLevel = 4;
    } else if (user.icons!.icon43 != null) {
      boosterLevel = 5;
    }

    var boosterEnd = DateTime.now().add(Duration(seconds: user.cooldowns!.booster!));
    var formattedBoosterEnd = formattedTime(boosterEnd);
    boosterString += formattedBoosterEnd;

    HomeWidget.saveWidgetData<int>('booster_level', boosterLevel);
    HomeWidget.saveWidgetData<String>('booster_string', boosterString);

    // --- DEBUG: FORCE ALL COOLDOWN ICONS VISIBLE ---
    if (kDebugMode && _debugWidgetCooldowns) {
      drugLevel = 3;
      medicalLevel = 2;
      boosterLevel = 4;
      racingStatus = "in_progress";
      racingString = "Racing - starts in 2:30";
      HomeWidget.saveWidgetData<int>('drug_level', drugLevel);
      HomeWidget.saveWidgetData<int>('medical_level', medicalLevel);
      HomeWidget.saveWidgetData<int>('booster_level', boosterLevel);
      HomeWidget.saveWidgetData<String>('racing', racingStatus);
      HomeWidget.saveWidgetData<String>('racing_string', racingString);
    }
    // --- END DEBUG ---

    // SHORTCUTS
    var savedShortcuts = await BackgroundPrefs().getActiveShortcutsList();
    List<Shortcut> shortcuts = <Shortcut>[];
    for (var savedShortRaw in savedShortcuts) {
      shortcuts.add(shortcutFromJson(savedShortRaw));
    }
    HomeWidget.saveWidgetData<int>('shortcuts_number', shortcuts.length);
    for (int i = 0; i < 9; i++) {
      HomeWidget.saveWidgetData<String>('shortcut${i + 1}_name', "");
      HomeWidget.saveWidgetData<String>('shortcut${i + 1}_url', "");
    }
    for (int i = 0; i < shortcuts.length; i++) {
      HomeWidget.saveWidgetData<String>('shortcut${i + 1}_name', shortcuts[i].nickname);
      String url = shortcuts[i].url!;
      if (shortcuts[i].addPlayerId == true) url = url.replaceAll("##P##", user.playerId.toString());
      if (shortcuts[i].addFactionId == true) url = url.replaceAll("##F##", user.faction!.factionId.toString());
      if (shortcuts[i].addCompanyId == true) url = url.replaceAll("##C##", user.job!.companyId.toString());
      HomeWidget.saveWidgetData<String>('shortcut${i + 1}_url', url);
    }
  } else {
    // In case of API error
    var error = user as ApiError;
    HomeWidget.saveWidgetData<bool>('main_layout_visibility', false);
    HomeWidget.saveWidgetData<bool>('error_layout_visibility', true);
    HomeWidget.saveWidgetData<String>('error_message', "API error: ${error.errorReason}");
  }
}

Future<bool> _handleLiveActivityBackup(Map<String, dynamic>? inputData) async {
  log("LiveActivity Backup Task triggered!");
  // 1. Get stored backup
  final backupJson = await Prefs().getLiveActivityCurrentTripBackup();
  if (backupJson == null || backupJson.isEmpty) {
    log("LiveActivity Backup: No stored trip found. Aborting.");
    return true;
  }

  try {
    // 2. Parse backup
    final Map<String, dynamic> args = jsonDecode(backupJson);

    // 4. Force "hasArrived" = true
    args['hasArrived'] = true;

    // 5. Send to Native
    // We instantiate Controller directly. It's a GetxController but we don't need DI here.
    final bridge = LiveActivityBridgeController();

    log("LiveActivity Backup: Sending FORCED ARRIVAL update to native layer.");
    await bridge.startActivity(arguments: args);

    // 6. Clear backup
    await Prefs().setLiveActivityCurrentTripBackup(null);
  } catch (e) {
    log("LiveActivity Backup Error: $e");
  }

  return true;
}
