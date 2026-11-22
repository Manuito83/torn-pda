import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/alert_subscriptions.dart';
import 'package:torn_pda/models/territory_map/alert_topics.dart';
import 'package:torn_pda/providers/territory_alerts_controller.dart';

class AlertKindChips extends StatelessWidget {
  const AlertKindChips({super.key, required this.target});

  final AlertTarget target;

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<TerritoryAlertsController>();
    final kinds = alerts.kindsFor(target);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final kind in AlertKind.values)
          FilterChip(
            visualDensity: VisualDensity.compact,
            label: Text(alertKindLabel(kind)),
            selected: kinds.contains(kind),
            onSelected: (_) => alerts.toggle(target, kind),
          ),
      ],
    );
  }
}

class WatchButton extends StatefulWidget {
  const WatchButton({super.key, required this.target});

  final AlertTarget target;

  @override
  State<WatchButton> createState() => _WatchButtonState();
}

class _WatchButtonState extends State<WatchButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final watching = context.select<TerritoryAlertsController, bool>(
      (alerts) => alerts.enabled && alerts.kindsFor(widget.target).isNotEmpty,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          icon: Icon(watching ? Icons.notifications_active : Icons.notifications_none),
          label: Text(watching ? 'Watching' : 'Watch'),
          onPressed: () => setState(() => _open = !_open),
        ),
        if (_open) AlertKindChips(target: widget.target),
      ],
    );
  }
}
