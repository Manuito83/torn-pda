enum AlertKind { war, ending, owner, racket }

// Marked when the player turns alerts on
const defaultFactionAlerts = {AlertKind.war, AlertKind.ending, AlertKind.owner};

final _topicPattern = RegExp(r'^tmap\.(f\.[0-9]+|t\.[A-Z]{3})\.(war|ending|owner|racket)$');

String factionTopic(int factionId, AlertKind kind) => 'tmap.f.$factionId.${kind.name}';

String territoryTopic(String code, AlertKind kind) => 'tmap.t.$code.${kind.name}';

bool isValidTopic(String topic) => _topicPattern.hasMatch(topic);
