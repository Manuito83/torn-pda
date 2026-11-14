import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/retal_model.dart';
import 'package:torn_pda/models/chat/chat_hit_target.dart';
import 'package:torn_pda/models/chat/chat_known_targets.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/retals_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/widgets/chaining/chain_attack.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// An armed call opening
Future<void> attackCalledTarget(int id) async {
  final navigator = NativeChat.leaveForBrowser(
    backTo: NativeChat.factionOps.joined.value?.roomId ?? ChatFactionOps.roomId,
  );
  if (navigator == null) return;
  final app = navigator.context;
  final listed = Provider.of<TargetsProvider?>(app, listen: false)?.allTargets.any((t) => t.playerId == id) ?? false;
  final retal = _retals().where((r) => r.retalId == id).firstOrNull;
  final name = knownHitTargets().where((t) => t.id == id).firstOrNull?.name ?? '';
  if (listed) return attackFromTargets(app, id, shortTap: true);
  if (retal != null) return attackFromRetals(app, retal);
  await attackFromWar(app, id, name, shortTap: true);
}

List<Retal> _retals() => Get.isRegistered<RetalsController>() ? Get.find<RetalsController>().retaliationList : const [];

/// Targets, war members and retals
List<ChatHitTarget> knownHitTargets() {
  final context = NativeChat.navigatorKey?.currentContext;
  final targets = context == null ? null : Provider.of<TargetsProvider?>(context, listen: false);
  return [
    if (targets != null) ...targetsOf(targets.allTargets),
    if (Get.isRegistered<WarController>())
      for (final c in Get.find<WarController>().orderedCardsDetails)
        if (c.memberId != null && c.name != null) ChatHitTarget(id: c.memberId!, name: c.name!),
    ...retalHitTargets(_retals()),
  ];
}
