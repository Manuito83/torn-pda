import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';
import 'package:torn_pda/models/chaining/retal_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/chat/chat_hit_target.dart';
import 'package:torn_pda/models/faction/faction_model.dart';

/// Chaining targets in the Targets order
List<ChatHitTarget> targetsOf(List<TargetModel> targets) => [
  for (final t in targets)
    if (t.playerId != null && t.name != null)
      ChatHitTarget.fromStatus(
        id: t.playerId!,
        name: t.name!,
        level: t.level,
        state: t.status?.state,
        until: t.status?.until,
        description: t.status?.description,
      ),
];

/// War members, given in the page order
List<ChatHitTarget> enemiesOf(Iterable<Member> members) => [
  for (final m in members)
    if (m.memberId != null && m.name != null)
      ChatHitTarget.fromStatus(
        id: m.memberId!,
        name: m.name!,
        level: m.level,
        state: m.status?.state,
        until: m.status?.until,
        description: m.status?.description,
      ),
];

List<ChatHitTarget> retalHitTargets(List<Retal> retals) => [
  for (final r in retals)
    if (r.retalId != null && r.name != null)
      ChatHitTarget.fromStatus(
        id: r.retalId!,
        name: r.name!,
        level: r.level,
        state: r.status.state,
        until: r.status.until,
        description: r.status.description,
      ),
];

List<ChatHitTarget> finderHitTargets(List<FFScouterTarget> found) => [
  for (final t in found)
    if (t.playerId != null && t.name != null)
      ChatHitTarget.fromStatus(
        id: t.playerId!,
        name: t.name!,
        level: t.level,
        state: t.statusState,
        until: t.statusUntil,
        description: t.statusDescription,
      ),
];
