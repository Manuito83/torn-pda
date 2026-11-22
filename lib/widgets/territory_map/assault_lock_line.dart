import 'dart:async';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/territory_map/assault_locks.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/utils/time_formatter.dart';

class AssaultLockLine extends StatefulWidget {
  const AssaultLockLine({super.key, required this.code});

  final String code;

  @override
  State<AssaultLockLine> createState() => _AssaultLockLineState();
}

class _AssaultLockLineState extends State<AssaultLockLine> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final settings = context.watch<SettingsProvider>();
    final state = controller.state;
    if (state == null) return const SizedBox.shrink();
    final now = DateTime.now().toUtc();
    final lock = territoryLock(widget.code, state.wars, state.recentWars, now);
    final mine = controller.myFactionId == 0
        ? null
        : factionLock(controller.myFactionId, widget.code, state.recentWars, now);

    var text = 'Open to assault';
    if (lock?.reason == LockReason.assault) {
      text = 'Under assault, then locked for 72 h';
    } else if (lock != null) {
      final until = mine ?? lock.until;
      final time = TimeFormatter(
        inputTime: until,
        timeFormatSetting: settings.currentTimeFormat,
        timeZoneSetting: settings.currentTimeZone,
      );
      final ended = state.recentWars.firstWhereOrNull((w) => w.id == lock.warId)?.endedAt;
      text =
          '${mine == null ? "Can't be assaulted" : "Your faction can't assault it"} '
          'until ${time.formatHour} ${time.formatDayWeek}, in ${chatSpan(until.difference(now))}'
          '${ended == null ? '' : ' (war ended ${chatSpan(now.difference(ended))} ago)'}';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(color: lock == null ? Colors.green : Colors.orange[800], fontWeight: FontWeight.w600),
      ),
    );
  }
}
