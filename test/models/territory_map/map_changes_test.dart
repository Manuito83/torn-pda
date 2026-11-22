import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

void main() {
  final day = parseDayChanges(File('test/models/territory_map/fixtures/changes-2026-11-04.json').readAsStringSync());
  MapChange row(String territory, String kind) =>
      day.changes.firstWhere((c) => c.territory == territory && c.kind == kind);

  group('parseDayChanges', () {
    test('revision 2', () {
      expect(day.revision, 2);
      expect(day.changes.length, 20);
      expect(day.factions[36811]!.tag, 'UNT');
      expect(day.factions[8085]!.tag, isNull);
      expect(row('ZHB', 'owner').previousFactionId, 0);
      expect(row('IFE', 'level').extra!['name'], 'Bootleg Distillery I');
      expect(day.changes.firstWhere((c) => c.source == 'bomb').territory, isNull);
    });

    test('revision 1 rows have no extra column', () {
      const json = '''
      {"format": 1, "day": "2026-11-04", "generated_at": 1793827054,
       "changes": [[1793800660, "racket", "FWG", "level", 44817, 44817, null, null]]}''';
      final old = parseDayChanges(json);
      expect(old.revision, 1);
      expect(old.factions, isEmpty);
      expect(old.changes.single.extra, isNull);
      expect(classify(old.changes.single), ChangeKind.racketLevel);
    });
  });

  test('classify', () {
    expect(classify(row('CNF', 'owner')), ChangeKind.conquest);
    expect(classify(row('QWF', 'owner')), ChangeKind.transfer);
    expect(classify(row('MVE', 'owner')), ChangeKind.abandoned);
    expect(classify(row('ZHB', 'owner')), ChangeKind.claimed);
    expect(classify(row('OIB', 'owner')), ChangeKind.claimed);
    expect(classify(row('AAA', 'owner')), isNull);
    expect(classify(row('FWG', 'level')), ChangeKind.racketUp);
    expect(classify(row('IFE', 'level')), ChangeKind.racketDown);
    expect(classify(day.changes.firstWhere((c) => c.source == 'racket' && c.territory == 'QWF')), isNull);
    expect(classify(row('DJA', 'end:end_with_peace_treaty')), ChangeKind.assaultTruce);
  });

  test('summarize counts by kind since a time', () {
    expect(summarize(day.changes, unixTime(1793796000)), {
      ChangeKind.assaultSucceeded: 1,
      ChangeKind.conquest: 1,
      ChangeKind.assaultTruce: 1,
      ChangeKind.racketUp: 1,
      ChangeKind.racketDown: 1,
      ChangeKind.racketNew: 1,
      ChangeKind.transfer: 1,
      ChangeKind.bomb: 1,
      ChangeKind.irradiated: 1,
    });
    final wholeDay = summarize(day.changes, unixTime(0));
    expect(wholeDay[ChangeKind.assaultStarted], 3);
    expect(wholeDay[ChangeKind.assaultFailed], 2);
    expect(wholeDay[ChangeKind.claimed], 2);
  });

  test('netGains', () {
    final gains = netGains(day.changes);
    expect(gains[13665], 2);
    expect(gains[8085], -1);
    expect(gains[7990], 1);
    expect(gains[38662], -1);
    expect(gains.containsKey(0), isFalse);
  });

  test('undoOwners', () {
    final acquired = unixTime(1793796349);
    final ownership = {
      'CNF': Ownership(factionId: 7990, acquiredAt: acquired, irradiated: false),
      'QWF': Ownership(factionId: 26312, acquiredAt: acquired, irradiated: false),
      'RFG': Ownership(factionId: 36811, acquiredAt: acquired, irradiated: true),
    };
    final before = undoOwners(ownership, day.changes);

    expect(before['CNF']!.factionId, 38662);
    expect(before['CNF']!.acquiredAt, isNull);
    expect(before['QWF']!.factionId, 21234);
    expect(before['RFG']!.irradiated, isFalse);
    expect(before['RFG']!.factionId, 36811);
    expect(before.containsKey('ZHB'), isFalse);
  });
}
