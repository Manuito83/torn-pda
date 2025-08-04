// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/appwidget/appwidget_api_model.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:workmanager/workmanager.dart';

Future<List<HomeWidgetInfo>> pdaWidget_numberInstalled() async {
  // Check whether the user is using a widget
  return await HomeWidget.getInstalledWidgets();
}

/// Used for Background Updates using Workmanager Plugin
@pragma("vm:entry-point")
void pdaWidget_backgroundUpdate() {
  Workmanager().executeTask((taskName, inputData) async {
    //DateTime now = DateTime.now();
    //String timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    //log("Widget $taskName update @$timeString ");

    if ((await pdaWidget_numberInstalled()).isEmpty) return true;

    // If it is the main task, update and setup several one-off tasks
    if (taskName == "wm_backgroundUpdate") {
      // Fetch Torn and update
      await pdaWidget_fetchData();

      // Set up several one-off tasks
      await Workmanager().registerOneOffTask(
        'pdaWidget_background_3',
        'wm_backgroundUpdate_3',
        initialDelay: const Duration(minutes: 3),
      );

      await Workmanager().registerOneOffTask(
        'pdaWidget_background_6',
        'wm_backgroundUpdate_6',
        initialDelay: const Duration(minutes: 6),
      );

      await Workmanager().registerOneOffTask(
        'pdaWidget_background_9',
        'wm_backgroundUpdate_9',
        initialDelay: const Duration(minutes: 9),
      );

      await Workmanager().registerOneOffTask(
        'pdaWidget_background_12',
        'wm_backgroundUpdate_12',
        initialDelay: const Duration(minutes: 12),
      );
    } else if (taskName.contains("wm_backgroundUpdate_")) {
      // If it is a one-off task, only update
      await pdaWidget_fetchData();
    }

    return true;
  });
}

/// Called when Doing Background Work initiated from Widget
@pragma("vm:entry-point")
FutureOr<void> pdaWidget_callback(Uri? data) async {
  if (data == null) return;
  log(data.toString());
  // Note: URI does not support ':' as other intents, hence the underscore
  if (data.host == 'reload_clicked') {
    HomeWidget.saveWidgetData<bool>('reloading', true);
    HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
    HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');
    await pdaWidget_fetchData();
    HomeWidget.saveWidgetData<bool>('reloading', false);
    HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
    HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');
  }
}

Future<void> pdaWidget_fetchData() async {
  try {
    final installedWidgets = await HomeWidget.getInstalledWidgets();
    if (installedWidgets.isEmpty) {
      log("No widgets installed. Aborting fetch.");
      return;
    }

    bool isPdaWidgetInstalled =
        installedWidgets.any((w) => w.androidClassName != null && w.androidClassName!.contains('HomeWidgetTornPda'));
    bool isRankedWarWidgetInstalled =
        installedWidgets.any((w) => w.androidClassName != null && w.androidClassName!.contains('HomeWidgetRankedWar'));

    String apiKey = "";
    var savedUserRaw = await Prefs().getOwnDetails();
    if (savedUserRaw.isNotEmpty) {
      apiKey = ownProfileBasicFromJson(savedUserRaw).userApiKey ?? "";
    }

    // Set last updated time globally for all widgets that might need it
    String restoredTimeFormat = await Prefs().getDefaultTimeFormat();
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
    bool timeZoneIsLocal = (await Prefs().getDefaultTimeZone()) != 'torn';
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
      // API Key is present, fetch data based on installed widgets

      // Fetch main widget data if installed
      if (isPdaWidgetInstalled) {
        log("PDA Widget is installed. Fetching its data...");
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
          String restoredTimeFormat = await Prefs().getDefaultTimeFormat();
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

          bool timeZoneIsLocal = (await Prefs().getDefaultTimeZone()) != 'torn';
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

          // SHORTCUTS
          var savedShortcuts = await Prefs().getActiveShortcutsList();
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

      // Fetch ranked war data if installed
      if (isRankedWarWidgetInstalled) {
        log("Ranked War Widget is installed. Fetching its data...");
        var user = ownProfileBasicFromJson(savedUserRaw);
        final dynamic warResponse = await ApiCallsV1.getAppWidgetRankedWars(forcedApiKey: apiKey);

        // Get the faction ID to be used for the check
        int? factionIdForCheck = user.faction?.factionId;

        // --- DEBUG: RANKED WAR WIDGET ---
        if (kDebugMode) {
          //factionIdForCheck = 1234;
        }
        // --- END DEBUG ---

        bool warFound = false;
        if (warResponse is RankedWarsModel && factionIdForCheck != null) {
          for (final warMap in warResponse.rankedwars!.entries) {
            // Use the potentially overridden faction ID for the check
            if (warMap.value.factions!.containsKey(factionIdForCheck.toString())) {
              final ts = DateTime.now().millisecondsSinceEpoch;
              final war = warMap.value;
              final warStarts = war.war!.start! * 1000;

              final bool warIsUpcoming = warStarts > ts;
              final bool warIsActive = warStarts < ts && war.war!.end == 0;

              if (warIsUpcoming || warIsActive) {
                warFound = true;
                HomeWidget.saveWidgetData<bool>('rw_widget_visibility', true);

                WarFaction playerFaction = WarFaction();
                WarFaction enemyFaction = WarFaction();
                war.factions!.forEach((id, factionData) {
                  // Use the overridden ID again to correctly identify the player's faction
                  if (id == factionIdForCheck.toString()) {
                    playerFaction = factionData;
                  } else {
                    enemyFaction = factionData;
                  }
                });

                if (warIsUpcoming) {
                  HomeWidget.saveWidgetData<String>('rw_state', 'upcoming');
                  final timeDifference = DateTime.fromMillisecondsSinceEpoch(warStarts).difference(DateTime.now());
                  String twoDigits(int n) => n.toString().padLeft(2, "0");
                  String countdown =
                      '${timeDifference.inDays}d ${twoDigits(timeDifference.inHours.remainder(24))}h ${twoDigits(timeDifference.inMinutes.remainder(60))}m';
                  countdown = countdown.replaceAll("0d ", "");
                  HomeWidget.saveWidgetData<String>('rw_countdown_string', "Starts in $countdown");
                } else {
                  // warIsActive
                  HomeWidget.saveWidgetData<String>('rw_state', 'active');
                  HomeWidget.saveWidgetData<int>('rw_player_score', playerFaction.score);
                  HomeWidget.saveWidgetData<int>('rw_enemy_score', enemyFaction.score);
                  HomeWidget.saveWidgetData<String>('rw_player_faction_tag',
                      "[${playerFaction.name!.substring(0, math.min(playerFaction.name!.length, 4))}]");
                  HomeWidget.saveWidgetData<String>('rw_enemy_faction_name', enemyFaction.name);
                  HomeWidget.saveWidgetData<int>('rw_target_score', war.war!.target);
                }
                break; // exit loop once war is found
              }
            }
          }
        }

        if (!warFound) {
          // No relevant war found, hide content
          HomeWidget.saveWidgetData<bool>('rw_widget_visibility', false);
        }
      }
    }
  } catch (e, t) {
    log("ERROR AT API WIDGET: $e, $t");
    HomeWidget.saveWidgetData<bool>('reloading', false);
  }

  // Update widgets
  HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
  HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');
}

/// Start the main background task
void pdaWidget_startBackgroundUpdate() async {
  await cancelAllWidgetTasks();
  Workmanager().registerPeriodicTask('pdaWidget_background', 'wm_backgroundUpdate');
}

void pdaWidget_handleBackgroundUpdateStatus() async {
  log("Handling appWidget background status!");

  if ((await pdaWidget_numberInstalled()).isNotEmpty) {
    log("Widget installed: calling appWidget background task");
    HomeWidget.saveWidgetData<bool>('background_active', true);
    pdaWidget_startBackgroundUpdate();
  } else {
    bool backgroundActive = await HomeWidget.getWidgetData<bool>('background_active', defaultValue: false) ?? false;
    if (backgroundActive) {
      log("Widget not present and service running: disabling appWidget background task");
      await cancelAllWidgetTasks();
      HomeWidget.saveWidgetData<bool>('background_active', false);
    }
  }

  // In case reloading gets stuck, cancel it after opening the app
  HomeWidget.saveWidgetData<bool>('reloading', false);

  HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
  HomeWidget.updateWidget(name: 'HomeWidgetRankedWar', iOSName: 'HomeWidgetRankedWar');
}

/// Avoids conflicts with other background tasks we might implement in the future!
Future<void> cancelAllWidgetTasks() async {
  await Workmanager().cancelByUniqueName('pdaWidget_background');
  await Workmanager().cancelByUniqueName('pdaWidget_background_3');
  await Workmanager().cancelByUniqueName('pdaWidget_background_6');
  await Workmanager().cancelByUniqueName('pdaWidget_background_9');
  await Workmanager().cancelByUniqueName('pdaWidget_background_12');
}
