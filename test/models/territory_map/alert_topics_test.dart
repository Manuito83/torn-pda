import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/alert_topics.dart';

void main() {
  test('topic names', () {
    expect(factionTopic(6799, AlertKind.war), 'tmap.f.6799.war');
    expect(territoryTopic('BAA', AlertKind.owner), 'tmap.t.BAA.owner');
    for (final kind in AlertKind.values) {
      expect(isValidTopic(factionTopic(6799, kind)), isTrue);
      expect(isValidTopic(territoryTopic('BAA', kind)), isTrue);
    }
  });

  test('rejects malformed topics', () {
    expect(isValidTopic('tmap.t.baa.owner'), isFalse);
    expect(isValidTopic('tmap.t.BAAA.owner'), isFalse);
    expect(isValidTopic('tmap.f.67a9.war'), isFalse);
    expect(isValidTopic('tmap.f.6799.daily'), isFalse);
  });
}
