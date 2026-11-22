import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_economy.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

class RacketsSheet extends StatefulWidget {
  const RacketsSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<RacketsSheet> createState() => _RacketsSheetState();
}

class _RacketsSheetState extends State<RacketsSheet> {
  bool _byFaction = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final state = controller.state;
    String ownerTag(int factionId) => factionTag(state, factionId);

    Widget row(String text, String money, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text(money, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );

    return MapSheet(
      title: const Text('Rackets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      onClose: widget.onClose,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Top rackets'),
              selected: !_byFaction,
              onSelected: (_) => setState(() => _byFaction = false),
            ),
            ChoiceChip(
              label: const Text('By faction'),
              selected: _byFaction,
              onSelected: (_) => setState(() => _byFaction = true),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (state == null)
          const MapStateNote()
        else if (_byFaction)
          for (final income in topFactionIncome(state))
            row(factionLabel(state, income.factionId), '\$${formatBigNumbers(income.money)}/day', () {
              controller.showFaction(income.factionId);
              controller.focusFaction(income.factionId);
            })
        else
          for (final racket in topRackets(state))
            row(
              '${racket.territory} - ${racket.name} - ${ownerTag(racket.factionId)}',
              '\$${formatBigNumbers(racketDailyValue(racket)!)}/day',
              () => controller.focusTerritory(racket.territory),
            ),
      ],
    );
  }
}
