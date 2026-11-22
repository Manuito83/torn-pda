import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/territory_map/assault_math.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

class AssaultPlannerSection extends StatefulWidget {
  const AssaultPlannerSection({
    super.key,
    required this.slots,
    required this.owner,
    required this.state,
    required this.locked,
    this.war,
  });

  final int slots;
  final int owner;
  final MapState state;
  final bool locked;
  final TerritoryWar? war;

  @override
  State<AssaultPlannerSection> createState() => _AssaultPlannerSectionState();
}

class _AssaultPlannerSectionState extends State<AssaultPlannerSection> {
  late int _attackers = (widget.war?.aggressor.wall ?? 5).clamp(0, widget.slots);
  late int _defenders = (widget.war?.defender.wall ?? 0).clamp(0, widget.slots - _attackers);

  @override
  Widget build(BuildContext context) {
    final war = widget.war;
    final now = DateTime.now().toUtc();
    final target = war?.target ?? targetFor(widget.slots);
    final remaining = war == null ? target : target - projectedScore(war, now);
    final left = war == null ? warLength : war.scheduledEnd.difference(now);
    final eta = timeToTarget(remaining, _attackers, _defenders);
    final members = widget.state.factions[widget.owner]?.members;
    final points = NumberFormat('#,##0', 'en_US');

    final String goal;
    if (war == null) {
      final needed = attackersNeeded(target, _defenders, warLength, widget.slots);
      final defenders = '$_defenders ${_defenders == 1 ? 'defender' : 'defenders'}';
      goal = needed == null
          ? 'Not possible within 72 h with $defenders, even with a full wall'
          : 'To finish within 72 h you need at least $needed ${needed == 1 ? 'attacker' : 'attackers'} '
                'with $defenders';
    } else {
      final needed = attackersNeeded(remaining, war.defender.wall, left, widget.slots);
      final more = needed == null ? 0 : needed - war.aggressor.wall;
      goal = needed == null && left > Duration.zero
          ? 'Not possible before the deadline, even with a full wall'
          : more > 0
          ? 'To end before the deadline you need $more more on the wall'
          : '';
    }

    return SheetSection(
      'Assault planner',
      children: [
        if (widget.locked) Text('Locked now: numbers for when it opens', style: TextStyle(color: Colors.orange[800])),
        Text(
          'Target ${points.format(target)} points (${widget.slots} slots)'
          '${members == null ? '' : ' - Defenders: ${factionLabel(widget.state, widget.owner)}, $members members'}',
        ),
        Wrap(
          spacing: 16,
          children: [
            _WallCounter('On your wall', _attackers, widget.slots - _defenders, (v) => setState(() => _attackers = v)),
            _WallCounter('On theirs', _defenders, widget.slots - _attackers, (v) => setState(() => _defenders = v)),
          ],
        ),
        Text(
          eta == null
              ? 'Never: you need more attackers than defenders'
              : !finishesWithin(remaining, _attackers, _defenders, left, widget.slots)
              ? 'Too slow: the assault fails at ${war == null ? '72 h' : 'the deadline'}'
              : 'About ${chatSpan(eta)} at that pace',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (goal.isNotEmpty) Text(goal),
      ],
    );
  }
}

class _WallCounter extends StatelessWidget {
  const _WallCounter(this.label, this.value, this.max, this.onChanged);

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
