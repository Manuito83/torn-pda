import 'package:flutter/material.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';

class TravelReturnWidget extends StatelessWidget {
  const TravelReturnWidget({
    super.key,
    required this.destination,
    required this.settingsProvider,
    required this.dateTimeArrival,
    this.departed,
    this.timestamp,
  });

  final String? destination;
  final SettingsProvider? settingsProvider;
  final DateTime? dateTimeArrival;
  final int? departed;
  final int? timestamp;

  @override
  Widget build(BuildContext context) {
    // Return time line
    String? formattedReturn = "";
    Widget returnWidget = const SizedBox.shrink();
    if (destination != "Torn") {
      // Return lasts as long as outbound
      int tornBackSeconds = (timestamp ?? 0) - (departed ?? 0);
      if ((departed ?? 0) <= 0 || tornBackSeconds <= 0) {
        tornBackSeconds = TravelTimes.travelTimeMinutesOneWay(
              countryName: destination!,
              ticket: settingsProvider!.travelTicket,
            ) *
            60;
      }
      final DateTime returnTime = dateTimeArrival!.add(Duration(seconds: tornBackSeconds));
      formattedReturn = TimeFormatter(
        inputTime: returnTime,
        timeFormatSetting: settingsProvider!.currentTimeFormat,
        timeZoneSetting: settingsProvider!.currentTimeZone,
      ).formatHour;
      returnWidget = Text(
        '(earliest return ~$formattedReturn)',
        style: const TextStyle(
          fontSize: 11.5,
        ),
      );
    }
    return returnWidget;
  }
}
