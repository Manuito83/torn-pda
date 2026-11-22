import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/alert_subscriptions.dart';
import 'package:torn_pda/models/territory_map/alert_topics.dart';

void main() {
  test('groups watched topics by territory and faction', () {
    final targets = watchedTargets(['tmap.t.RCD.war', 'tmap.t.RCD.racket', 'tmap.f.6799.owner', 'tmap.f.6799.bomb']);
    expect(targets, {
      const AlertTarget.territory('RCD'): {AlertKind.war, AlertKind.racket},
      const AlertTarget.faction(6799): {AlertKind.owner},
    });
  });

  test('faction topics follow the player', () {
    final topics = ['tmap.f.10.war', 'tmap.f.10.owner', 'tmap.t.RCD.war', 'tmap.f.20.war'];
    expect(moveFactionTopics(topics, 10, 20), ['tmap.f.20.war', 'tmap.f.20.owner', 'tmap.t.RCD.war']);
    expect(moveFactionTopics(topics, 10, 0), ['tmap.t.RCD.war', 'tmap.f.20.war']);
    expect(moveFactionTopics(topics, -1, 20), topics);
  });

  test('joining a faction marks the default kinds', () {
    expect(moveFactionTopics(['tmap.t.RCD.war', 'tmap.f.20.war'], 0, 20), [
      'tmap.t.RCD.war',
      'tmap.f.20.war',
      'tmap.f.20.ending',
      'tmap.f.20.owner',
    ]);
  });

  test('reads the tap from the function data', () {
    expect(readAlertTap({'territory': 'RCD', 'war_id': '31547'}), (territory: 'RCD', warId: 31547));
    expect(readAlertTap({'territory': 'QFA', 'war_id': ''}), (territory: 'QFA', warId: null));
    expect(readAlertTap({'territory': 'rcd', 'war_id': '31547'}), isNull);
    expect(readAlertTap({}), isNull);
  });

  test('foreground tap payload round trip', () {
    final payload = alertTapPayload({'territory': 'RCD', 'war_id': '32115'});
    expect(isAlertTapPayload(payload), isTrue);
    expect(readAlertTapPayload(payload), (territory: 'RCD', warId: 32115));
    expect(readAlertTapPayload(alertTapPayload({'territory': ''})), isNull);
  });
}
