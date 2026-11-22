import 'package:torn_pda/models/territory_map/map_economy.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

// A tapped line opens the assault
typedef ViewLine = ({String text, int? warId});

typedef ViewFacts = ({String title, List<ViewLine> lines});

const _spanText = {
  ActivitySpan.now: 'now',
  ActivitySpan.week: 'in the last 7 days',
  ActivitySpan.month: 'in the last 4 weeks',
};

ViewLine _line(String text, {int? warId}) => (text: text, warId: warId);

// Null when nothing is special
ViewFacts? territoryViewFacts(
  MapView view, {
  required Territory territory,
  required Map<String, Territory> territories,
  required MapState state,
  required ActivitySpan span,
  required DateTime now,
  required Iterable<RecentWar> ended,
  required bool irradiated,
  required DateTime? pastDay,
  required String Function(DateTime at) date,
  required String Function(int factionId) faction,
}) {
  final code = territory.code;
  switch (view) {
    case MapView.normal:
    case MapView.war:
      return null;
    case MapView.rackets:
      final racket = state.rackets[code];
      if (racket == null) return (title: 'Racket', lines: [_line('No racket here')]);
      return (
        title: 'Racket',
        lines: [_line('${racket.name} (level ${racket.level})'), _line(racketRewardText(racket))],
      );
    case MapView.irradiated:
      if (!irradiated) return (title: 'Irradiated', lines: [_line('Not irradiated')]);
      final end = pastDay?.add(const Duration(days: 1));
      final bombs = [
        for (final b in state.bombs)
          if (b.territories.contains(code) && (end == null || b.detonatedAt.isBefore(end))) b,
      ]..sort((a, b) => a.detonatedAt.compareTo(b.detonatedAt));
      if (bombs.isEmpty) return (title: 'Irradiated', lines: [_line('Irradiated')]);
      final bomb = bombs.last;
      return (
        title: 'Irradiated',
        lines: [
          _line('Bomb by ${faction(bomb.factionId)}'),
          _line('Detonated ${date(bomb.detonatedAt)}'),
          if (bomb.territories.length > 1) _line('Hit ${territoryCount(bomb.territories.length)}'),
        ],
      );
    case MapView.sector:
      final inSector = territories.values.where((t) => t.sector == territory.sector).length;
      return (title: 'Sector', lines: [_line('Sector ${territory.sector} - ${territoryCount(inSector)}')]);
    case MapView.size:
      return (title: 'Size', lines: [_line('Size ${territory.size} of ${sizeScale.last}')]);
    case MapView.respect:
      return (title: 'Respect', lines: [_line('${territory.respect} respect a day')]);
    case MapView.activity:
      final assaults = territoryAssaults(code, span, now, current: state.wars, ended: ended);
      return (
        title: 'Activity',
        lines: [
          _line(
            assaults.isEmpty
                ? 'No assaults ${_spanText[span]}'
                : '${assaults.length} ${assaults.length == 1 ? 'assault' : 'assaults'} ${_spanText[span]}',
          ),
          for (final a in assaults)
            _line(
              '${date(a.start)}: ${faction(a.aggressorId)} vs ${faction(a.defenderId)} - ${warOutcomeText(a)}',
              warId: a.id,
            ),
        ],
      );
  }
}
