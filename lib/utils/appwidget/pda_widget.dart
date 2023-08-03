import 'dart:developer';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/appwidget/appwidget_api_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:workmanager/workmanager.dart';

Future<int?> pdaWidget_numberInstalled() async {
  // Check whether the user is using a widget
  return await HomeWidget.getWidgetCount(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
}

/// Used for Background Updates using Workmanager Plugin
@pragma("vm:entry-point")
void pdaWidget_backgroundUpdate() {
  Workmanager().executeTask((taskName, inputData) async {
    //DateTime now = DateTime.now();
    //String timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    //log("Widget $taskName update @$timeString ");

    int? count = await pdaWidget_numberInstalled();
    if (count == 0) return true;

    // If it is the main task, update and setup several one-off tasks
    if (taskName == "wm_backgroundUpdate") {
      // Fetch Torn and update
      await pdaWidget_fetchData();

      // Set up several one-off tasks
      await Workmanager().registerOneOffTask(
        'pdaWidget_background_3',
        'wm_backgroundUpdate_3',
        initialDelay: Duration(minutes: 3),
      );

      await Workmanager().registerOneOffTask(
        'pdaWidget_background_6',
        'wm_backgroundUpdate_6',
        initialDelay: Duration(minutes: 6),
      );

      await Workmanager().registerOneOffTask(
        'pdaWidget_background_9',
        'wm_backgroundUpdate_9',
        initialDelay: Duration(minutes: 9),
      );

      await Workmanager().registerOneOffTask(
        'pdaWidget_background_12',
        'wm_backgroundUpdate_12',
        initialDelay: Duration(minutes: 12),
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
void pdaWidget_callback(Uri? data) async {
  log(data.toString());
  if (data!.host == 'reload-clicked') {
    HomeWidget.saveWidgetData<bool>('reloading', true);
    HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
    await pdaWidget_fetchData();
    HomeWidget.saveWidgetData<bool>('reloading', false);
    HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
  }
}

Future<void> pdaWidget_fetchData() async {
  try {
    await Prefs().reload();
    String? apiKey = "";
    var savedUser = await Prefs().getOwnDetails();
    if (savedUser != '') {
      apiKey = ownProfileBasicFromJson(savedUser).userApiKey;
    }

    if (apiKey!.isNotEmpty) {
      // NOTE: we don't use the ApiCallerController with Getx here, but instead call directly
      var user = await ApiCallerController().getAppWidgetInfo(forcedApiKey: apiKey, limit: 0);

      if (user is ApiError) {
        if (user.errorId == 100) {
          // Retry in case of timeout
          log("Widget timed out, retrying once after 5 seconds");
          await Future.delayed(Duration(seconds: 5));
        }
      }

      if (user is AppWidgetApiModel) {
        HomeWidget.saveWidgetData<bool>('main_layout_visibility', true);
        HomeWidget.saveWidgetData<bool>('error_layout_visibility', false);

        String? statusDescription = user.status!.description;
        String? state = user.status!.state;
        String country = countryCheck(state: state, description: statusDescription);

        if (!country.contains("Torn")) {
          // We are flying abroad or in another country

          // And not in a (foreign hospital)
          if (state != "Hospital") {
            var dateTimeArrival = DateTime.fromMillisecondsSinceEpoch(user.travel!.timestamp! * 1000);
            var timeDifference = dateTimeArrival.difference(DateTime.now());
            String twoDigits(int n) => n.toString().padLeft(2, "0");
            String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
            if (statusDescription!.contains("Traveling to")) {
              statusDescription = statusDescription.replaceAll("Traveling to ", "");
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

          if (statusDescription!.contains("Returning to")) {
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
            if (user.status!.color == "red") {
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
        HomeWidget.saveWidgetData<String>('status_color', user.status!.color);

        // Messages and events
        int? unreadMessages = user.messages?.length;
        HomeWidget.saveWidgetData<int>('messages', unreadMessages ?? 0);

        int? unreadEvents = user.events?.length;
        HomeWidget.saveWidgetData<int>('events', unreadEvents ?? 0);

        // Energy
        int? currentEnergy = user.energy!.current;
        int? maxEnergy = user.energy!.maximum;
        HomeWidget.saveWidgetData<int>('energy_current', currentEnergy);
        HomeWidget.saveWidgetData<int>('energy_max', maxEnergy);
        HomeWidget.saveWidgetData<String>('energy_text', "$currentEnergy/$maxEnergy");

        // Nerve
        int? currentNerve = user.nerve!.current;
        int? maxNerve = user.nerve!.maximum;
        HomeWidget.saveWidgetData<int>('nerve_current', currentNerve);
        HomeWidget.saveWidgetData<int>('nerve_max', maxNerve);
        HomeWidget.saveWidgetData<String>('nerve_text', "$currentNerve/$maxNerve");

        // Happy
        int? currentHappy = user.happy!.current;
        int? maxHappy = user.happy!.maximum;
        HomeWidget.saveWidgetData<int>('happy_current', currentHappy);
        HomeWidget.saveWidgetData<int>('happy_max', maxHappy);
        HomeWidget.saveWidgetData<String>('happy_text', "$currentHappy");

        // Life
        int? currentLife = user.life!.current;
        int? maxLife = user.life!.maximum;
        HomeWidget.saveWidgetData<int>('life_current', currentLife);
        HomeWidget.saveWidgetData<int>('life_max', maxLife);
        HomeWidget.saveWidgetData<String>('life_text', "$currentLife");

        // Chain
        int currentChain = user.chain!.current!;

        // We do it manually to avoid an extra API call to Faction/Chain
        // (in User/Bars the chain max is the one achieved by the user)
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
        if (user.chain!.cooldown! > 0) {
          HomeWidget.saveWidgetData<String>('chain_text', "COOLDOWN");
        } else {
          HomeWidget.saveWidgetData<String>('chain_text', "$currentChain");
        }

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
          if (onHand < 10000) {
            money = "\$${(onHand / 1000).toStringAsFixed(1)}K";
          } else {
            money = "\$${(onHand / 1000).toStringAsFixed(0)}K";
          }
        } else {
          money = "\$$onHand";
        }
        HomeWidget.saveWidgetData<String>('money', money);

        // Last Updated
        String restoredTimeFormat = await Prefs().getDefaultTimeFormat();
        TimeFormatSetting timePrefs = restoredTimeFormat == '24' ? TimeFormatSetting.h24 : TimeFormatSetting.h12;
        late DateFormat formatter;
        switch (timePrefs) {
          case TimeFormatSetting.h24:
            formatter = DateFormat('HH:mm');
            break;
          case TimeFormatSetting.h12:
            formatter = DateFormat('HH:mm a');
            break;
        }
        HomeWidget.saveWidgetData<String>('last_updated', "${formatter.format(DateTime.now())} LT");

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
            timeZoneSetting: TimeZoneSetting.localTime,
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
        // Send total number of shortcuts to determine whether the section is present
        HomeWidget.saveWidgetData<int>('shortcuts_number', shortcuts.length);

        // Reset all shortcuts
        for (int i = 0; i < 9; i++) {
          HomeWidget.saveWidgetData<String>('shortcut${i + 1}_name', "");
          HomeWidget.saveWidgetData<String>('shortcut${i + 1}_url', "");
        }

        // Set the current active shortcuts
        for (int i = 0; i < shortcuts.length; i++) {
          HomeWidget.saveWidgetData<String>('shortcut${i + 1}_name', shortcuts[i].nickname);
          String? url = shortcuts[i].url;
          if (shortcuts[i].addPlayerId != null) {
            // Avoid null objects coming before the introduction of this replacement (v2.9.4)
            if (shortcuts[i].addPlayerId!) {
              url = url!.replaceAll("##P##", user.playerId.toString());
            }
            if (shortcuts[i].addFactionId!) {
              url = url!.replaceAll("##F##", user.faction!.factionId.toString());
            }
            if (shortcuts[i].addCompanyId!) {
              url = url!.replaceAll("##C##", user.job!.companyId.toString());
            }
          }
          HomeWidget.saveWidgetData<String>('shortcut${i + 1}_url', url);
        }
      } else {
        // In case of API error
        var error = user as ApiError;
        HomeWidget.saveWidgetData<bool>('main_layout_visibility', false);
        HomeWidget.saveWidgetData<bool>('error_layout_visibility', true);
        HomeWidget.saveWidgetData<String>('error_message', "API error: ${error.errorReason}");
      }
    } else {
      // If API key is empty
      HomeWidget.saveWidgetData<bool>('main_layout_visibility', false);
      HomeWidget.saveWidgetData<bool>('error_layout_visibility', true);
      HomeWidget.saveWidgetData<String>('error_message', "No API key found!");
    }
  } catch (e) {
    log("ERROR AT API WIDGET: $e");
    HomeWidget.saveWidgetData<bool>('reloading', false);
  }

  // Update widget
  HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
}

/// Start the main background task
void pdaWidget_startBackgroundUpdate() async {
  await Workmanager().cancelAll();
  Workmanager().registerPeriodicTask('pdaWidget_background', 'wm_backgroundUpdate');
}

void pdaWidget_handleBackgroundUpdateStatus() async {
  log("Handling appWidget background status!");

  if ((await pdaWidget_numberInstalled())! > 0) {
    log("Widget installed: calling appWidget background task");
    HomeWidget.saveWidgetData<bool>('background_active', true);
    pdaWidget_startBackgroundUpdate();
  } else {
    bool backgroundActive = (await HomeWidget.getWidgetData<bool>('background_active', defaultValue: false))!;
    if (backgroundActive) {
      log("Widget not present and service running: disabling appWidget background task");
      await Workmanager().cancelAll();
      HomeWidget.saveWidgetData<bool>('background_active', false);
    }
  }

  // In case reloading gets stuck, cancel it after opening the app
  HomeWidget.saveWidgetData<bool>('reloading', false);

  HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
}
