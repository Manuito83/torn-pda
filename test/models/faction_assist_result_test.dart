import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/faction/faction_assist_result.dart';

void main() {
  test('notified count and null result', () {
    expect(factionAssistResultMessage(1), contains('1 faction member has'));
    expect(factionAssistResultMessage(3), contains('3 faction members have'));
    expect(factionAssistResultMessage(null), factionAssistResultMessage(-99));
  });

  test('attack id keeps only the leading digits', () {
    expect(attackIdFromUrl('https://www.torn.com/loader.php?sid=attack&user2ID=2225097'), '2225097');
    expect(attackIdFromUrl('https://www.torn.com/page.php?sid=attack&user2ID=2225097#/x'), '2225097');
    expect(attackIdFromUrl('https://www.torn.com/page.php?sid=attack&user2ID=2225097&foo=1'), '2225097');
    expect(attackIdFromUrl('https://www.torn.com/page.php?sid=attack&user2ID=abc'), isNull);
  });
}
