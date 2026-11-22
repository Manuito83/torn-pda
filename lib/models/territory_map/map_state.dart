import 'dart:convert';

import 'package:torn_pda/models/territory_map/recent_war.dart';

export 'package:torn_pda/models/territory_map/recent_war.dart';

const staleDataAfter = Duration(minutes: 15);

class Ownership {
  Ownership({required this.factionId, required this.acquiredAt, required this.irradiated});

  final int factionId;
  final DateTime? acquiredAt;
  final bool irradiated;
}

class WarSide {
  WarSide({
    required this.factionId,
    required this.score,
    required this.chain,
    required this.wall,
    required this.ratePerMinute,
  });

  final int factionId;
  final int score;
  final int chain;
  final int wall;
  final double ratePerMinute;
}

class TerritoryWar {
  TerritoryWar({
    required this.id,
    required this.territory,
    required this.start,
    required this.scheduledEnd,
    required this.target,
    required this.aggressor,
    required this.defender,
    required this.scoreAt,
    this.idle,
  });

  final int id;
  final String territory;
  final DateTime start;
  final DateTime scheduledEnd;
  final int target;
  final WarSide aggressor;
  final WarSide defender;
  final DateTime scoreAt;

  // Null before revision 2
  final WarIdle? idle;
}

class WarIdle {
  WarIdle({required this.noAttackersSince, required this.scoreChangedAt});

  final DateTime? noAttackersSince;
  final DateTime scoreChangedAt;
}

enum RewardType { item, points, money }

class RewardItem {
  RewardItem({required this.type, required this.id, required this.name, required this.quantity, required this.price});

  final RewardType type;
  final int id;
  final String name;
  final int quantity;
  final int price;
}

class Racket {
  Racket({
    required this.territory,
    required this.factionId,
    required this.name,
    required this.level,
    required this.reward,
    required this.changedAt,
    this.rewardItem,
  });

  final String territory;
  final int factionId;
  final String name;
  final int level;
  final String reward;
  final DateTime changedAt;
  final RewardItem? rewardItem;
}

class MapFaction {
  MapFaction({
    required this.id,
    required this.name,
    required this.tag,
    required this.tagImage,
    required this.respect,
    required this.rank,
    required this.members,
  });

  final int id;
  final String? name;
  final String? tag;
  final String? tagImage;
  final int? respect;
  final int? rank;
  final int? members;
}

class DirtyBomb {
  DirtyBomb({
    required this.id,
    required this.detonatedAt,
    required this.factionId,
    required this.respectLost,
    required this.territories,
  });

  final int id;
  final DateTime detonatedAt;
  final int factionId;
  final int respectLost;
  final List<String> territories;
}

class MapState {
  MapState({
    required this.generatedAt,
    required this.territoriesVersion,
    required this.readAt,
    required this.ownership,
    required this.wars,
    required this.rackets,
    required this.factions,
    required this.bombs,
    this.revision = 1,
    this.recentWars = const [],
  });

  final int revision;
  final List<RecentWar> recentWars;
  final DateTime generatedAt;
  final int territoriesVersion;
  final Map<String, DateTime> readAt;
  final Map<String, Ownership> ownership;
  final List<TerritoryWar> wars;
  final Map<String, Racket> rackets;
  final Map<int, MapFaction> factions;
  final List<DirtyBomb> bombs;
}

DateTime unixTime(Object? seconds) => DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000, isUtc: true);

MapState parseMapState(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  if (data['format'] != 1) {
    throw FormatException('Unknown map state format: ${data['format']}');
  }

  WarSide side(Map<String, dynamic> row, Object? rate) => WarSide(
    factionId: row['id'] as int,
    score: row['score'] as int,
    chain: row['chain'] as int,
    wall: row['wall'] as int,
    ratePerMinute: (rate as num? ?? 0).toDouble(),
  );

  RewardItem? rewardItem(Map<String, dynamic>? row) {
    final type = RewardType.values.asNameMap()[row?['type']];
    if (row == null || type == null) return null;
    return RewardItem(
      type: type,
      id: row['id'] as int,
      name: row['name'] as String,
      quantity: row['quantity'] as int,
      price: row['price'] as int,
    );
  }

  return MapState(
    revision: data['revision'] as int? ?? 1,
    generatedAt: unixTime(data['generated_at']),
    territoriesVersion: data['territories_version'] as int,
    readAt: {for (final e in (data['read_at'] as Map<String, dynamic>).entries) e.key: unixTime(e.value)},
    ownership: {
      for (final e in (data['ownership'] as Map<String, dynamic>).entries)
        e.key: Ownership(
          factionId: (e.value as List<dynamic>)[0] as int,
          acquiredAt: e.value[1] == 0 ? null : unixTime(e.value[1]),
          irradiated: e.value[2] != 0,
        ),
    },
    wars: [
      for (final w in (data['wars'] as List<dynamic>).cast<Map<String, dynamic>>())
        TerritoryWar(
          id: w['id'] as int,
          territory: w['territory'] as String,
          start: unixTime(w['start']),
          scheduledEnd: unixTime(w['scheduled_end']),
          target: w['target'] as int,
          aggressor: side(w['aggressor'] as Map<String, dynamic>, w['rate']?['aggressor']),
          defender: side(w['defender'] as Map<String, dynamic>, w['rate']?['defender']),
          scoreAt: unixTime(w['score_at']),
          idle: w['idle'] == null
              ? null
              : WarIdle(
                  noAttackersSince: w['idle']['no_attackers_since'] == null
                      ? null
                      : unixTime(w['idle']['no_attackers_since']),
                  scoreChangedAt: unixTime(w['idle']['score_changed_at']),
                ),
        ),
    ],
    recentWars: [
      for (final w in (data['recent_wars'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        RecentWar(
          id: w['id'] as int,
          territory: w['territory'] as String,
          start: unixTime(w['start']),
          endedAt: unixTime(w['ended_at']),
          result: warResultFrom(w['result'] as String?),
          aggressorId: w['aggressor'] as int,
          defenderId: w['defender'] as int,
          score: w['score'] as int,
          target: w['target'] as int,
        ),
    ],
    rackets: {
      for (final e in (data['rackets'] as Map<String, dynamic>).entries)
        e.key: Racket(
          territory: e.key,
          factionId: e.value['faction_id'] as int,
          name: e.value['name'] as String,
          level: e.value['level'] as int,
          reward: e.value['reward'] as String,
          changedAt: unixTime(e.value['changed_at']),
          rewardItem: rewardItem(e.value['reward_item'] as Map<String, dynamic>?),
        ),
    },
    factions: {
      for (final e in (data['factions'] as Map<String, dynamic>).entries)
        int.parse(e.key): MapFaction(
          id: int.parse(e.key),
          name: e.value['name'] as String?,
          tag: e.value['tag'] as String?,
          tagImage: e.value['tag_image'] as String?,
          respect: e.value['respect'] as int?,
          rank: e.value['rank'] as int?,
          members: e.value['members'] as int?,
        ),
    },
    bombs: [
      for (final b in (data['bombs'] as List<dynamic>).cast<Map<String, dynamic>>())
        DirtyBomb(
          id: b['id'] as int,
          detonatedAt: unixTime(b['detonated_at']),
          factionId: b['faction_id'] as int,
          respectLost: b['respect_lost'] as int,
          territories: (b['territories'] as List<dynamic>).cast<String>(),
        ),
    ],
  );
}

// Older of the ownership and wars reads
DateTime dataTime(MapState state) {
  final ownership = state.readAt['ownership'];
  final wars = state.readAt['wars'];
  if (ownership == null || wars == null) return ownership ?? wars ?? state.generatedAt;
  return ownership.isBefore(wars) ? ownership : wars;
}

bool isStale(MapState state, DateTime now) => now.difference(dataTime(state)) > staleDataAfter;

// Names covers factions gone from the state
String factionLabel(MapState? state, int factionId, {Map<int, MapFaction>? names}) {
  final faction = state?.factions[factionId] ?? names?[factionId];
  final name = faction?.name ?? 'Faction $factionId';
  return faction?.tag == null ? name : '[${faction!.tag}] $name';
}

String factionTag(MapState? state, int factionId, {Map<int, MapFaction>? names}) {
  final tag = (state?.factions[factionId] ?? names?[factionId])?.tag;
  return tag == null ? factionLabel(state, factionId, names: names) : '[$tag]';
}

String territoryCount(int count) => '$count ${count == 1 ? 'territory' : 'territories'}';

// Only what changes the fills
bool sameOwners(Map<String, Ownership> a, Map<String, Ownership> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null || other.factionId != entry.value.factionId || other.irradiated != entry.value.irradiated) {
      return false;
    }
  }
  return true;
}
