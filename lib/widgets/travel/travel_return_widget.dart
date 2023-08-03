import 'package:flutter/material.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';

class TravelReturnWidget extends StatelessWidget {
  const TravelReturnWidget({
    Key? key,
    required this.destination,
    required this.settingsProvider,
    required this.dateTimeArrival,
  }) : super(key: key);

  final String? destination;
  final SettingsProvider? settingsProvider;
  final DateTime? dateTimeArrival;

  @override
  Widget build(BuildContext context) {
    // Return time line
    String? formattedReturn = "";
    Widget returnWidget = SizedBox.shrink();
    if (destination != "Torn") {
      int tornBackMinutes = TravelTimes.travelTimeMinutesOneWay(
        countryName: destination!,
        ticket: settingsProvider!.travelTicket,
      );
      DateTime returnTime = dateTimeArrival!.add(Duration(minutes: tornBackMinutes));
      formattedReturn = TimeFormatter(
        inputTime: returnTime,
        timeFormatSetting: settingsProvider!.currentTimeFormat,
        timeZoneSetting: settingsProvider!.currentTimeZone,
      ).formatHour;
      returnWidget = Text(
        '(earliest return ~$formattedReturn)',
        style: TextStyle(
          fontSize: 11.5,
        ),
      );
    }
    return returnWidget;
  }
}
