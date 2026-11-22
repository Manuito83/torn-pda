import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/alert_subscriptions.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/territory_alerts_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';
import 'package:torn_pda/widgets/territory_map/watch_button.dart';

// From the alerts settings; the map hosts the sheet itself
Future<void> showTerritoryAlertsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheet) => TerritoryAlertsSheet(onClose: () => Navigator.pop(sheet)),
  );
}

void showTerritoryAlertsHint(VoidCallback onSetUp) {
  BotToast.showNotification(
    leading: (_) => const Icon(Icons.notifications_active_outlined, color: Colors.white),
    title: (_) => const Text(
      "Get alerts for your faction's assaults?",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    subtitle: (_) =>
        const Text('Assaults, endings and owner changes. Also in the More menu', style: TextStyle(color: Colors.white)),
    trailing: (cancel) => TextButton(
      onPressed: () {
        cancel();
        onSetUp();
      },
      child: const Text('Set up'),
    ),
    backgroundColor: Colors.grey[800],
    duration: const Duration(seconds: 10),
  );
}

class TerritoryAlertsSheet extends StatefulWidget {
  const TerritoryAlertsSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<TerritoryAlertsSheet> createState() => _TerritoryAlertsSheetState();
}

class _TerritoryAlertsSheetState extends State<TerritoryAlertsSheet> {
  @override
  void initState() {
    super.initState();
    context.read<TerritoryAlertsController>().followFaction();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<TerritoryAlertsController>();
    final themeProvider = context.watch<ThemeProvider>();
    final state = context.select<TerritoryMapController, MapState?>((c) => c.state);
    final myFaction = UserHelper.factionId;
    final watched = watchedTargets(alerts.topics)..remove(AlertTarget.faction(myFaction));
    const header = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);

    return MapSheet(
      title: const Text('Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      onClose: widget.onClose,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Territory alerts', style: TextStyle(color: themeProvider.mainText)),
          subtitle: const Text('Assaults and territory changes, delivered a few minutes after they happen'),
          value: alerts.enabled,
          onChanged: alerts.setEnabled,
        ),
        if (myFaction != 0) ...[
          const SizedBox(height: 8),
          const Text('Your faction', style: header),
          const SizedBox(height: 6),
          AlertKindChips(target: AlertTarget.faction(myFaction)),
        ],
        const SizedBox(height: 14),
        const Text('Watching', style: header),
        if (watched.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Use Watch on a territory or a faction to follow it'),
          ),
        for (final MapEntry(key: target, value: kinds) in watched.entries)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              target.isFaction ? factionLabel(state, target.factionId) : target.code,
              style: TextStyle(color: themeProvider.mainText),
            ),
            subtitle: Text(kinds.map(alertKindLabel).join(', ')),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: themeProvider.mainText),
              tooltip: 'Stop watching',
              onPressed: () => alerts.remove(target),
            ),
          ),
      ],
    );
  }
}
