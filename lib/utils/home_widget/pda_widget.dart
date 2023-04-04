import 'dart:developer';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:workmanager/workmanager.dart';

Future<int> pdaWidget_numberInstalled() async {
  // Check whether the user is using a widget
  return await HomeWidget.getWidgetCount(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
}

/// Used for Background Updates using Workmanager Plugin
@pragma("vm:entry-point")
void pdaWidget_backgroundUpdate() {
  Workmanager().executeTask((taskName, inputData) async {
    DateTime now = DateTime.now();
    String timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    log("Widget $taskName update @$timeString ");

    int count = await pdaWidget_numberInstalled();
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
void pdaWidget_callback(Uri data) async {
  log(data.toString());

  if (data.host == 'reload-clicked') {
    pdaWidget_fetchData();
  } else if (data.host == 'energy-box-clicked') {
    log("energy_box");
  }
}

Future<void> pdaWidget_fetchData() async {
  await Prefs().reload();
  String apiKey = "";
  var savedUser = await Prefs().getOwnDetails();
  if (savedUser != '') {
    apiKey = ownProfileBasicFromJson(savedUser).userApiKey;
  }

  if (apiKey.isNotEmpty) {
    var apiResponse = await TornApiCaller().getOwnProfileExtended(limit: 3, forcedApiKey: apiKey);
    if (apiResponse is OwnProfileExtended) {
      HomeWidget.saveWidgetData<bool>('main_layout_visibility', true);
      HomeWidget.saveWidgetData<bool>('error_layout_visibility', false);

      //HomeWidget.saveWidgetData<String>('title', apiResponse.name);
      String statusDescription = apiResponse.status.description;
      String state = apiResponse.status.state;
      String country = countryCheck(state: state, description: statusDescription);

      if (!country.contains("Torn")) {
        if (state != "Hospital") {
          var dateTimeArrival = DateTime.fromMillisecondsSinceEpoch(apiResponse.travel.timestamp * 1000);
          var timeDifference = dateTimeArrival.difference(DateTime.now());
          String twoDigits(int n) => n.toString().padLeft(2, "0");
          String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
          if (statusDescription.contains("Traveling to")) {
            statusDescription = statusDescription.replaceAll("Traveling to", "");
            statusDescription += ' in ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
          } else if (statusDescription.contains("Returning to")) {
            statusDescription = "Torn in";
            statusDescription += ' ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
          } else if (state == "Abroad") {
            statusDescription = "Visiting $country";
          }
        } else {
          // Special case for when we are hospitalized abroad
          var hospitalRelease = DateTime.fromMillisecondsSinceEpoch(apiResponse.status.until * 1000);
          var timeDifference = hospitalRelease.difference(DateTime.now());
          String twoDigits(int n) => n.toString().padLeft(2, "0");
          String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
          statusDescription = "Hospital in $country: ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m";
        }
      } else if (apiResponse.status.color == "red") {
        var redEnd = DateTime.fromMillisecondsSinceEpoch(apiResponse.status.until * 1000);
        var timeDifference = redEnd.difference(DateTime.now());
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
        if (apiResponse.status.state.contains("Hospital")) {
          statusDescription = 'Hospital for ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
        } else if (statusDescription.contains("Jail")) {
          statusDescription = 'Jail for ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
        }
      }
      HomeWidget.saveWidgetData<String>('country', country);
      HomeWidget.saveWidgetData<String>('status', statusDescription);
      HomeWidget.saveWidgetData<String>('status_color', apiResponse.status.color);

      // Energy
      int currentEnergy = apiResponse.energy.current;
      int maxEnergy = apiResponse.energy.maximum;
      HomeWidget.saveWidgetData<int>('energy_current', currentEnergy);
      HomeWidget.saveWidgetData<int>('energy_max', maxEnergy);
      HomeWidget.saveWidgetData<String>('energy_text', "$currentEnergy/$maxEnergy");

      // Nerve
      int currentNerve = apiResponse.nerve.current;
      int maxNerve = apiResponse.nerve.maximum;
      HomeWidget.saveWidgetData<int>('nerve_current', currentNerve);
      HomeWidget.saveWidgetData<int>('nerve_max', maxNerve);
      HomeWidget.saveWidgetData<String>('nerve_text', "$currentNerve/$maxNerve");

      // Happy
      int currentHappy = apiResponse.happy.current;
      int maxHappy = apiResponse.happy.maximum;
      HomeWidget.saveWidgetData<int>('happy_current', currentHappy);
      HomeWidget.saveWidgetData<int>('happy_max', maxHappy);
      HomeWidget.saveWidgetData<String>('happy_text', "$currentHappy");

      // Life
      int currentLife = apiResponse.life.current;
      int maxLife = apiResponse.life.maximum;
      HomeWidget.saveWidgetData<int>('life_current', currentLife);
      HomeWidget.saveWidgetData<int>('life_max', maxLife);
      HomeWidget.saveWidgetData<String>('life_text', "$currentLife");

      // Last Updated
      String restoredTimeFormat = await Prefs().getDefaultTimeFormat();
      TimeFormatSetting timePrefs = restoredTimeFormat == '24' ? TimeFormatSetting.h24 : TimeFormatSetting.h12;
      DateFormat formatter;
      switch (timePrefs) {
        case TimeFormatSetting.h24:
          formatter = DateFormat('HH:mm');
          break;
        case TimeFormatSetting.h12:
          formatter = DateFormat('HH:mm a');
          break;
      }
      HomeWidget.saveWidgetData<String>('last_updated', "@${formatter.format(DateTime.now())} LT");
    } else {
      // In case of API error
      var error = apiResponse as ApiError;
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

  // Update widget
  HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
}

void pdaWidget_startBackgroundUpdate() async {
  await Workmanager().cancelAll();
  // Start the main background task
  Workmanager().registerPeriodicTask('pdaWidget_background', 'wm_backgroundUpdate');
}

void pdaWidget_handleBackgroundUpdateStatus() async {
  log("Handling appWidget background status!");

  int numberInstalled = await pdaWidget_numberInstalled();
  bool backgroundActive = await HomeWidget.getWidgetData<bool>('background_active', defaultValue: false);

  if (numberInstalled > 0) {
    log("Enabling appWidget background task (widget installed)");
    HomeWidget.saveWidgetData<bool>('background_active', true);
    pdaWidget_startBackgroundUpdate();
    HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
  } else if (numberInstalled == 0 && backgroundActive) {
    log("Disabling appWidget background task (no widget present)");
    HomeWidget.saveWidgetData<bool>('background_active', false);
    await Workmanager().cancelAll();
    HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
  }
}
