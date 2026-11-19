import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/remote_announcement.dart';

void main() {
  final now = DateTime.utc(2026, 11, 20);

  bool shows(String raw, {int player = 1, String platform = 'android', int build = 712, String seen = ''}) =>
      RemoteAnnouncement.parse(
        raw,
      )?.appliesTo(playerId: player, platform: platform, build: build, now: now, seenId: seen) ??
      false;

  group('parse', () {
    test('empty, invalid or incomplete gives null', () {
      expect(RemoteAnnouncement.parse(''), isNull);
      expect(RemoteAnnouncement.parse('not json'), isNull);
      expect(RemoteAnnouncement.parse('[1]'), isNull);
      expect(RemoteAnnouncement.parse('{"id":"a","title":"t"}'), isNull);
      expect(RemoteAnnouncement.parse('{"id":"","title":"t","body":"b"}'), isNull);
    });

    test('bad optional fields give null', () {
      expect(RemoteAnnouncement.parse('{"id":"a","title":"t","body":"b","until":"soon"}'), isNull);
      expect(RemoteAnnouncement.parse('{"id":"a","title":"t","body":"b","players":["x"]}'), isNull);
      expect(RemoteAnnouncement.parse('{"id":"a","title":"t","body":"b","url":"torn"}'), isNull);
      expect(RemoteAnnouncement.parse('{"id":"a","title":"t","body":"b","minBuild":"7"}'), isNull);
    });

    test('full message', () {
      final a = RemoteAnnouncement.parse(
        '{"id":"a","title":"t","body":"b","url":"https://www.torn.com","button":"Open",'
        '"platforms":["Android"],"minBuild":700,"maxBuild":720,"until":"2026-12-01T00:00:00Z","players":[1,"2"]}',
      )!;
      expect(a.platforms, {'android'});
      expect(a.players, {1, 2});
      expect(a.until, DateTime.utc(2026, 12, 1));
      expect(a.button, 'Open');
    });
  });

  group('appliesTo', () {
    const base = '{"id":"a","title":"t","body":"b"';

    test('only id and texts: everybody', () {
      expect(shows('$base}'), isTrue);
    });

    test('seen id', () {
      expect(shows('$base}', seen: 'a'), isFalse);
      expect(shows('$base}', seen: 'old'), isTrue);
    });

    test('platform', () {
      expect(shows('$base,"platforms":["ios"]}'), isFalse);
      expect(shows('$base,"platforms":["ios"]}', platform: 'ios'), isTrue);
      expect(shows('$base,"platforms":[]}'), isTrue);
    });

    test('build range is inclusive', () {
      expect(shows('$base,"minBuild":713}'), isFalse);
      expect(shows('$base,"minBuild":712,"maxBuild":712}'), isTrue);
      expect(shows('$base,"maxBuild":711}'), isFalse);
    });

    test('until', () {
      expect(shows('$base,"until":"2026-11-19T23:59:00Z"}'), isFalse);
      expect(shows('$base,"until":"2026-11-21T00:00:00Z"}'), isTrue);
    });

    test('players', () {
      expect(shows('$base,"players":[2225097]}', player: 2225097), isTrue);
      expect(shows('$base,"players":[2225097]}', player: 5), isFalse);
      expect(shows('$base,"players":[2225097]}', player: 0), isFalse);
      expect(shows('$base,"players":[]}', player: 5), isTrue);
    });
  });
}
