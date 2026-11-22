import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/territory_map/map_economy.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

class TerritoryEconomySection extends StatelessWidget {
  const TerritoryEconomySection({
    super.key,
    required this.code,
    required this.respect,
    required this.state,
    this.showRacket = true,
  });

  final String code;
  final int respect;
  final MapState? state;

  // The rackets view says it above
  final bool showRacket;

  @override
  Widget build(BuildContext context) {
    final ownership = state?.ownership[code];
    final owner = ownership?.factionId ?? 0;
    final since = ownership?.acquiredAt;
    final racket = state?.rackets[code];
    final points = NumberFormat('#,##0', 'en_US');
    final now = DateTime.now().toUtc();

    var earned = '';
    if (owner != 0 && since != null && now.difference(since).inDays > 0) {
      earned =
          ' - ${points.format(respectEarned(respect, since, now))} earned by '
          '${factionTag(state, owner)} in ${now.difference(since).inDays} days';
    }

    return SheetSection(
      'Economy',
      children: [
        Text('$respect respect/day$earned'),
        if (racket != null && showRacket) ...[
          const SizedBox(height: 4),
          Text('${racket.name} (level ${racket.level})', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(racketRewardText(racket)),
        ],
      ],
    );
  }
}
