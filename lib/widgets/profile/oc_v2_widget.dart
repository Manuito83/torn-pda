import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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
/// If less than 24 hours remain until the planned start time,
/// the part "planned to start at {time}" is displayed in red.
///
/// Additionally, if the user's slot has an item requirement,
/// it appends "Item available" (in green) or "Item missing" (in red)
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

    Map<String, dynamic>? organizedCrimeData;

    if (kDebugMode) {
      // 🔥 🔥 Debug data instead of API data 🔥 🔥
      //organizedCrimeData = _getDebugExample(caseNumber: 3);
    }

    final ocDynamic = organizedCrimeData ?? widget.crimeResponse.organizedCrime;

    if (ocDynamic == null) {
      return Row(
        children: [
          const Icon(MdiIcons.fingerprint),
          const SizedBox(width: 10),
          Flexible(
            child: RichText(
              text: TextSpan(
                text: "No OC planned!",
                style: TextStyle(fontSize: 14, color: Colors.orange[800]),
              ),
            ),
          ),
        ],
      );
    }

    final organizedCrime = ocDynamic as Map<String, dynamic>;
    final slots = organizedCrime['slots'] as List<dynamic>? ?? [];

    final playerSlot = slots.firstWhereOrNull(
      (slot) => slot['user_id'] == widget.playerId,
    );

    if (playerSlot == null) {
      return const SizedBox.shrink();
    }

    int missingSlots = slots.where((slot) => slot['user_id'] == null).length;
    int readyTimestamp = organizedCrime['ready_at'] as int;
    DateTime planningDateTime = DateTime.fromMillisecondsSinceEpoch(readyTimestamp * 1000);

    if (missingSlots > 0) {
      planningDateTime = planningDateTime.add(Duration(hours: 24 * missingSlots));
    }

    final now = DateTime.now();
    final hasExpired = now.isAfter(planningDateTime);
    final remaining = planningDateTime.difference(now);

    Color countdownColor = themeProvider.mainText;
    if (remaining.inHours < 8) {
      countdownColor = Colors.red;
    } else if (remaining.inHours < 12) {
      countdownColor = Colors.orange[700]!;
    } else if (remaining.inHours < 24) {
      countdownColor = Colors.blue[700]!;
    }

    final formattedTime = TimeFormatter(
      inputTime: planningDateTime,
      timeFormatSetting: settingsProvider.currentTimeFormat,
      timeZoneSetting: settingsProvider.currentTimeZone,
    ).formatHourWithDaysElapsed();

    final readyTextSpan = hasExpired
        ? TextSpan(
            text: 'ready to start',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          )
        : TextSpan(
            children: [
              if (missingSlots > 0)
                TextSpan(
                  text: 'incomplete, ',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              TextSpan(
                text: missingSlots > 0 ? 'earliest possible start at ' : 'planned to start at ',
                style: TextStyle(fontSize: 14, color: themeProvider.mainText),
              ),
              TextSpan(
                text: formattedTime,
                style: TextStyle(color: countdownColor, fontSize: 14),
              ),
            ],
          );

    final String ocName = organizedCrime['name'] as String? ?? 'OC';
    final String position = playerSlot['position'] as String? ?? '';
    final int successChance = playerSlot['success_chance'] as int? ?? 0;

    TextSpan? itemRequirementTextSpan;
    if (playerSlot['item_requirement'] != null) {
      final itemRequirement = playerSlot['item_requirement'] as Map<String, dynamic>;
      final bool isAvailable = itemRequirement['is_available'] as bool? ?? false;
      final itemStatus = isAvailable ? 'Item provided' : 'Item missing';
      final itemStatusColor = isAvailable ? Colors.green : Colors.red;
      final itemFontWeight = isAvailable ? FontWeight.normal : FontWeight.bold;

      itemRequirementTextSpan = TextSpan(
        text: itemStatus,
        style: TextStyle(fontSize: 14, color: itemStatusColor, fontWeight: itemFontWeight),
      );
    }

    final messageTextSpan = TextSpan(
      style: const TextStyle(fontSize: 16.0, color: Colors.black),
      children: [
        TextSpan(
          text: "OC '$ocName' is ",
          style: TextStyle(fontSize: 14, color: themeProvider.mainText),
        ),
        readyTextSpan,
        TextSpan(
          text: ', you are in as a $position with a pass rate of $successChance%',
          style: TextStyle(fontSize: 14, color: themeProvider.mainText),
        ),
        if (itemRequirementTextSpan != null) ...[
          TextSpan(
            text: ' - ',
            style: TextStyle(fontSize: 14, color: themeProvider.mainText),
          ),
          itemRequirementTextSpan,
        ],
      ],
    );

    return Row(
      children: [
        const Icon(MdiIcons.fingerprint),
        const SizedBox(width: 10),
        Flexible(child: RichText(text: messageTextSpan)),
      ],
    );
  }

  /// Debug example cases
  // ignore: unused_element
  Map<String, dynamic> _getDebugExample({required int caseNumber}) {
    final now = DateTime.now();

    switch (caseNumber) {
      // Case 1: OC complete
      case 1:
        return {
          'name': 'OC Test 1',
          'difficulty': 7,
          'ready_at': (now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000),
          'slots': [
            {
              'user_id': widget.playerId,
              'position': 'Picklock',
              'success_chance': 76,
              'item_requirement': {'is_available': false}
            },
            {'user_id': 1234, 'position': 'Hacker'},
            {'user_id': 12345, 'position': 'Engineer'},
            {'user_id': 123456, 'position': 'Bomber'},
            {'user_id': 1243567, 'position': 'Muscle'},
            {'user_id': 12345678, 'position': 'Picklock'},
          ],
        };

      // Case 2: OC incomplete (positions missing)
      case 2:
        return {
          'name': 'OC Test 2',
          'difficulty': 8,
          'ready_at': (now.add(const Duration(hours: 6)).millisecondsSinceEpoch ~/ 1000),
          'slots': [
            {
              'user_id': widget.playerId,
              'position': 'Thief',
              'success_chance': 64,
              'item_requirement': {'is_available': false}
            },
            {'user_id': null, 'position': 'Robber'},
            {'user_id': null, 'position': 'Muscle'},
            {'user_id': null, 'position': 'Muscle'},
          ],
        };

      // Case 3: OC complete, less than 12 hours remaining
      case 3:
        return {
          'name': 'OC Test 3',
          'difficulty': 4,
          'ready_at': (now.add(const Duration(hours: 12)).millisecondsSinceEpoch ~/ 1000),
          'slots': [
            {
              'user_id': widget.playerId,
              'position': 'Hustler',
              'success_chance': 83,
              'item_requirement': {'is_available': false}
            },
            {'user_id': 1234, 'position': 'Impersonator'},
            {'user_id': 12345, 'position': 'Muscle'},
            {'user_id': 123456, 'position': 'Muscle'},
          ],
        };

      default:
        return {};
    }
  }
}
