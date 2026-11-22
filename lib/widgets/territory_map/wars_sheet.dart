import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/war_file.dart';
import 'package:torn_pda/models/territory_map/war_progress.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';
import 'package:torn_pda/widgets/territory_map/war_sheet.dart';

class WarsSheet extends StatefulWidget {
  const WarsSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<WarsSheet> createState() => _WarsSheetState();
}

class _WarsSheetState extends State<WarsSheet> {
  bool _hideStalled = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final state = controller.state;
    final now = DateTime.now().toUtc();
    final myFaction = controller.myFactionId;
    final all = state?.wars ?? const <TerritoryWar>[];
    final stalled = {
      for (final war in all)
        if (isStalled(war, now)) war.id,
    };
    final wars = [
      for (final war in sortedWars(all, myFaction))
        if (!_hideStalled || !stalled.contains(war.id)) war,
    ];

    Widget label(String text, Color color) => Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );

    return MapSheet(
      title: const Text('Assaults', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      onClose: widget.onClose,
      children: [
        Row(
          children: [
            Expanded(child: Text('${all.length} in progress, ${stalled.length} stalled')),
            FilterChip(
              visualDensity: VisualDensity.compact,
              label: const Text('Hide stalled'),
              selected: _hideStalled,
              onSelected: (value) => setState(() => _hideStalled = value),
            ),
          ],
        ),
        if (state == null)
          const MapStateNote()
        else if (wars.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('No assaults right now')),
        for (final war in wars)
          InkWell(
            onTap: () {
              controller.focusTerritory(war.territory);
              controller.showWar(war.id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${war.territory} - Sector ${controller.territories?.territories[war.territory]?.sector ?? '?'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isFactionWar(war, myFaction)) label('Mine', Colors.green),
                      if (stalled.contains(war.id)) label('Stalled', Colors.grey),
                    ],
                  ),
                  Text('${factionTag(state, war.aggressor.factionId)} → ${factionTag(state, war.defender.factionId)}'),
                  WarProgressLines(war: war),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
