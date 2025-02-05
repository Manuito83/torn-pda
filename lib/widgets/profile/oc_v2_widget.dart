import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';

/// Widget that displays a message about an Organized Crime (OC)
/// if the current user is in an OC that is in planning phase.
///
/// It shows a text message with the following format:
/// "OC {ocName} is [planned to start at {time} / ready to start], you are in as a {position} with a pass rate of {successChance}%"
///
/// If less than 24 hours remain until the planned start time
/// the part "planned to start at {time}" is displayed in red
///
class OrganizedCrimeWidget extends StatefulWidget {
  final UserOrganizedCrimeResponse crimeResponse;
  final int playerId;

  const OrganizedCrimeWidget({
    super.key,
    required this.crimeResponse,
    required this.playerId,
  });

  @override
  OrganizedCrimeWidgetState createState() => OrganizedCrimeWidgetState();
}

class OrganizedCrimeWidgetState extends State<OrganizedCrimeWidget> {
  @override
  Widget build(BuildContext context) {
    SettingsProvider settingsProvider = context.read<SettingsProvider>();
    ThemeProvider themeProvider = context.read<ThemeProvider>();

    final ocDynamic = widget.crimeResponse.organizedCrime;

    // If there is no organized crime, notify parent and return an empty widget
    if (ocDynamic == null) {
      final TextSpan noOCText = TextSpan(
        style: const TextStyle(fontSize: 16.0, color: Colors.black),
        children: [
          TextSpan(
            text: "No OC planned!",
            style: TextStyle(fontSize: 14, color: Colors.orange[800]),
          ),
        ],
      );

      return Row(
        children: [
          Icon(MdiIcons.fingerprint),
          const SizedBox(width: 10),
          Flexible(child: RichText(text: noOCText)),
        ],
      );
    }

    final Map<String, dynamic> organizedCrime = ocDynamic as Map<String, dynamic>;

    // Retrieve the list of slots (if null, default to an empty list)
    final List<dynamic> slots = organizedCrime['slots'] as List<dynamic>? ?? [];

    final dynamic playerSlot = slots.firstWhere(
      (slot) => slot['user_id'] == widget.playerId,
      orElse: () => null,
    );

    // If the user is not found in any slot, notify parent and return empty widget
    if (playerSlot == null) {
      return const SizedBox.shrink();
    }

    // At this point, the user is in an OC
    final int readyTimestamp = organizedCrime['ready_at'] as int;
    final DateTime planningDateTime = DateTime.fromMillisecondsSinceEpoch(readyTimestamp * 1000);

    final DateTime now = DateTime.now();
    final bool hasExpired = now.isAfter(planningDateTime);

    bool lessThan24Hours = false;
    if (!hasExpired) {
      final Duration remaining = planningDateTime.difference(now);
      lessThan24Hours = remaining.inHours < 24;
    }

    // Prepares the text span that will display the planning information.
    TextSpan readyTextSpan;

    if (hasExpired) {
      readyTextSpan = const TextSpan(
        text: 'ready to start',
        style: TextStyle(
          fontSize: 14,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      final formattedTime = TimeFormatter(
        inputTime: planningDateTime,
        timeFormatSetting: settingsProvider.currentTimeFormat,
        timeZoneSetting: settingsProvider.currentTimeZone,
      ).formatHourWithDaysElapsed();

      // - The static text "planned to start at "
      // - The formatted time in red if less than 24 hours remain, otherwise in default style
      readyTextSpan = TextSpan(
        children: [
          TextSpan(text: 'planned to start at ', style: TextStyle(fontSize: 14, color: themeProvider.mainText)),
          TextSpan(
            text: formattedTime,
            style: lessThan24Hours
                ? const TextStyle(color: Colors.red, fontSize: 14)
                : TextStyle(color: themeProvider.mainText, fontSize: 14),
          ),
        ],
      );
    }

    // Extract additional data
    final String ocName = organizedCrime['name'] as String? ?? 'OC';
    final String position = playerSlot['position'] as String? ?? '';
    final int successChance = playerSlot['success_chance'] as int? ?? 0;

    final TextSpan messageTextSpan = TextSpan(
      style: const TextStyle(fontSize: 16.0, color: Colors.black),
      children: [
        TextSpan(
          text: "OC '$ocName' is ",
          style: TextStyle(fontSize: 14, color: themeProvider.mainText),
        ),
        readyTextSpan,
        TextSpan(
          text: ', you are in as a $position with a pass rate of $successChance%',
          style: TextStyle(
            fontSize: 14,
            color: themeProvider.mainText,
          ),
        ),
      ],
    );

    return Row(
      children: [
        Icon(MdiIcons.fingerprint),
        const SizedBox(width: 10),
        Flexible(child: RichText(text: messageTextSpan)),
      ],
    );
  }
}
