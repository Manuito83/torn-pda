import 'dart:math' as math;
import 'dart:ui';

import 'package:torn_pda/models/territory_map/map_economy.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

enum MapView { normal, rackets, sector, respect, size, war, irradiated, activity }

enum ActivitySpan { now, week, month }

enum LifeDensity { low, normal, high }

const activityDays = {ActivitySpan.now: 0, ActivitySpan.week: 7, ActivitySpan.month: 28};

enum ShadeKind { faction, ramp, sector, irradiated }

// Step: ramp color or sector color
typedef Shade = ({ShadeKind kind, int step});

typedef ActivitySpot = ({String code, int assaults, DateTime last});

const valueRamp = [Color(0xD93B528B), Color(0xD921918C), Color(0xD95EC962), Color(0xD9B5DE2B), Color(0xD9FDE725)];

const sectorColors = [
  Color(0xCCE57373),
  Color(0xCCFFB74D),
  Color(0xCCFFF176),
  Color(0xCC81C784),
  Color(0xCC4DD0E1),
  Color(0xCC7986CB),
  Color(0xCCBA68C8),
];

Color dimFill({required bool lightTheme}) => lightTheme ? const Color(0x66757575) : const Color(0x80616161);

// Wars and rackets of today only
MapView viewForDay(MapView view, {required bool past}) =>
    past && (view == MapView.war || view == MapView.activity || view == MapView.rackets) ? MapView.normal : view;

bool showsAssaults(MapView view) => view == MapView.normal || view == MapView.war;

// Null: faction colors, missing: grey
Map<String, Shade>? viewShades(
  MapView view, {
  required Map<String, Ownership> ownership,
  required List<TerritoryWar> wars,
  required Map<String, Racket> rackets,
  required Map<String, Territory> territories,
}) {
  Shade ramp(int value, List<int> scale) =>
      (kind: ShadeKind.ramp, step: rampIndex(scaleStep(value, scale), scale.length));

  switch (view) {
    case MapView.normal:
      return null;
    case MapView.war:
      final fighting = factionsAtWar(wars);
      return {
        for (final e in ownership.entries)
          if (fighting.contains(e.value.factionId)) e.key: (kind: ShadeKind.faction, step: 0),
      };
    case MapView.rackets:
      final scale = racketScale(rackets.values);
      return {for (final r in rackets.values) r.territory: ramp(racketDailyValue(r) ?? 0, scale)};
    case MapView.sector:
      return {
        for (final t in territories.values)
          t.code: (kind: ShadeKind.sector, step: (t.sector - 1) % sectorColors.length),
      };
    case MapView.respect:
      final scale = respectScale(territories.values);
      return {for (final t in territories.values) t.code: ramp(t.respect, scale)};
    case MapView.size:
      return {for (final t in territories.values) t.code: ramp(t.size, sizeScale)};
    case MapView.irradiated:
      return {
        for (final e in ownership.entries)
          if (e.value.irradiated) e.key: (kind: ShadeKind.irradiated, step: 0),
      };
    case MapView.activity:
      return const {};
  }
}

List<String> glowingCodes(Map<String, Shade>? shades) => [
  for (final e in shades?.entries ?? const <MapEntry<String, Shade>>[])
    if (e.value.kind == ShadeKind.irradiated) e.key,
];

// War outline wins on own territories
List<String> borderedMine(List<String> mine, Iterable<TerritoryWar> wars, Map<String, Shade>? shades) {
  final atWar = {for (final war in wars) war.territory};
  return [
    for (final code in mine)
      if (!atWar.contains(code) && (shades == null || shades[code]?.kind == ShadeKind.faction)) code,
  ];
}

Set<int> factionsAtWar(Iterable<TerritoryWar> wars) => {
  for (final war in wars) ...[war.aggressor.factionId, war.defender.factionId],
};

// Territory sizes run 1 to 5
const sizeScale = [1, 2, 3, 4, 5];

List<int> racketScale(Iterable<Racket> rackets) => valueScale([for (final r in rackets) ?racketDailyValue(r)]);

List<int> respectScale(Iterable<Territory> territories) => valueScale([for (final t in territories) t.respect]);

// Lowest value of each step, rounded
List<int> valueScale(List<int> values) {
  final sorted = [...values]..sort();
  if (sorted.isEmpty) return const [];
  final steps = valueRamp.length;
  return {for (var s = 0; s < steps; s++) _twoDigits(sorted[sorted.length * s ~/ steps])}.toList();
}

int _twoDigits(int value) {
  if (value < 100) return value;
  final unit = math.pow(10, value.toString().length - 2).toInt();
  return value ~/ unit * unit;
}

int scaleStep(int value, List<int> scale) {
  var step = 0;
  for (var s = 1; s < scale.length; s++) {
    if (value >= scale[s]) step = s;
  }
  return step;
}

// Spread a short scale over the whole ramp
int rampIndex(int step, int steps) {
  final last = valueRamp.length - 1;
  return steps <= 1 ? last : (step * last / (steps - 1)).round();
}

// Assaults started in the span, live ones always
List<RecentWar> assaultsInSpan(
  ActivitySpan span,
  DateTime now, {
  required List<TerritoryWar> current,
  Iterable<RecentWar> ended = const [],
}) {
  final found = <int, RecentWar>{
    for (final war in current)
      war.id: RecentWar(
        id: war.id,
        territory: war.territory,
        start: war.start,
        endedAt: null,
        result: WarResult.inProgress,
        aggressorId: war.aggressor.factionId,
        defenderId: war.defender.factionId,
        score: war.aggressor.score,
        target: war.target,
      ),
  };
  if (span != ActivitySpan.now) {
    final since = now.subtract(Duration(days: activityDays[span]!));
    for (final war in ended) {
      if (!war.start.isBefore(since)) found.putIfAbsent(war.id, () => war);
    }
  }
  return found.values.toList();
}

// Newest first
List<RecentWar> territoryAssaults(
  String code,
  ActivitySpan span,
  DateTime now, {
  required List<TerritoryWar> current,
  Iterable<RecentWar> ended = const [],
}) =>
    [
      for (final war in assaultsInSpan(span, now, current: current, ended: ended))
        if (war.territory == code) war,
    ]..sort((a, b) => b.start.compareTo(a.start));

// Assaults started in the span, busiest first
List<ActivitySpot> activitySpots(
  ActivitySpan span,
  DateTime now, {
  required List<TerritoryWar> current,
  Iterable<RecentWar> ended = const [],
}) {
  final spots = <String, ActivitySpot>{};
  for (final war in assaultsInSpan(span, now, current: current, ended: ended)) {
    final spot = spots[war.territory];
    spots[war.territory] = spot == null
        ? (code: war.territory, assaults: 1, last: war.start)
        : (
            code: war.territory,
            assaults: spot.assaults + 1,
            last: war.start.isAfter(spot.last) ? war.start : spot.last,
          );
  }
  return spots.values.toList()..sort((a, b) => b.assaults.compareTo(a.assaults));
}

// Screen pixels
double spotRadius(int assaults) => math.min(4 + 4 * math.sqrt(assaults), 28);

// Older assaults fade, never below 0.4
double spotAlpha(DateTime last, DateTime now, ActivitySpan span) {
  final days = activityDays[span]!;
  final age = days == 0 ? 0.0 : (now.difference(last).inHours / (days * 24)).clamp(0.0, 1.0);
  return 0.85 - 0.45 * age;
}
