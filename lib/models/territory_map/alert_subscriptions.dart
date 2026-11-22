import 'package:collection/collection.dart';
import 'package:torn_pda/models/territory_map/alert_topics.dart';

const territoryAlertsChannel = 'Alerts territory';

const _tapPrefix = 'territoryMap:';
final _codePattern = RegExp(r'^[A-Z]{3}$');

typedef AlertTap = ({String territory, int? warId});

class AlertTarget {
  const AlertTarget.territory(this.code) : factionId = 0;
  const AlertTarget.faction(this.factionId) : code = '';

  final String code;
  final int factionId;

  bool get isFaction => code.isEmpty;

  String topic(AlertKind kind) => isFaction ? factionTopic(factionId, kind) : territoryTopic(code, kind);

  @override
  bool operator ==(Object other) => other is AlertTarget && other.code == code && other.factionId == factionId;

  @override
  int get hashCode => Object.hash(code, factionId);
}

String alertKindLabel(AlertKind kind) => switch (kind) {
  AlertKind.war => 'Assaults',
  AlertKind.ending => 'Ending soon',
  AlertKind.owner => 'Owner changes',
  AlertKind.racket => 'Rackets',
};

Map<AlertTarget, Set<AlertKind>> watchedTargets(Iterable<String> topics) {
  final targets = <AlertTarget, Set<AlertKind>>{};
  for (final topic in topics.where(isValidTopic)) {
    final parts = topic.split('.');
    final target = parts[1] == 'f' ? AlertTarget.faction(int.parse(parts[2])) : AlertTarget.territory(parts[2]);
    (targets[target] ??= {}).add(AlertKind.values.byName(parts[3]));
  }
  return targets;
}

// Defaults when joining, none when leaving
List<String> moveFactionTopics(List<String> topics, int from, int to) {
  if (from < 0 || from == to) return topics;
  if (from == 0) return {...topics, for (final kind in defaultFactionAlerts) factionTopic(to, kind)}.toList();
  final old = 'tmap.f.$from.';
  return {
    for (final topic in topics)
      if (!topic.startsWith(old)) topic else if (to > 0) 'tmap.f.$to.${topic.substring(old.length)}',
  }.toList();
}

// Null without a valid territory
AlertTap? readAlertTap(Map data) {
  final code = '${data['territory'] ?? ''}';
  if (!_codePattern.hasMatch(code)) return null;
  final war = int.tryParse('${data['war_id'] ?? ''}');
  return (territory: code, warId: war != null && war > 0 ? war : null);
}

bool isTerritoryAlert(Map data) => data['channelId'] == territoryAlertsChannel;

String alertTapPayload(Map data) {
  final tap = readAlertTap(data);
  return '$_tapPrefix${tap?.territory ?? ''}:${tap?.warId ?? ''}';
}

bool isAlertTapPayload(String payload) => payload.startsWith(_tapPrefix);

AlertTap? readAlertTapPayload(String payload) {
  final parts = payload.substring(_tapPrefix.length).split(':');
  return readAlertTap({'territory': parts.first, 'war_id': parts.elementAtOrNull(1)});
}
