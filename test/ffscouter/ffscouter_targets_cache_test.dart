import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_cache.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';

void main() {
  test('a saved list comes back with its fields', () {
    final saved = encodeFFScouterTargets([
      FFScouterTarget(
        playerId: 1,
        name: 'Ana',
        level: 20,
        fairFight: 2.5,
        bsEstimate: 1500000,
        statusState: 'Hospital',
        statusUntil: 1700000000,
      ),
      FFScouterTarget(playerId: 2, name: 'Bo'),
    ]);
    final back = decodeFFScouterTargets(saved);
    expect(back.map((t) => t.playerId), [1, 2]);
    expect(back.first.fairFight, 2.5);
    expect(back.first.statusUntil, 1700000000);
    expect(back.last.bsEstimate, isNull);
  });

  test('empty and corrupt caches read as nothing, and nothing saves as JSON', () {
    expect(encodeFFScouterTargets(const []), '[]');
    expect(decodeFFScouterTargets(''), isEmpty);
    expect(decodeFFScouterTargets('[]'), isEmpty);
    expect(decodeFFScouterTargets('{oops'), isEmpty);
    expect(decodeFFScouterTargets('{"a": 1}'), isEmpty);
  });
}
