import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/userscript_model.dart';

// Page-side @match check run in Node
const _patterns = <List<String>>[
  ['*://www.torn.com/*'],
  ['https://www.torn.com/*'],
  ['*://*.torn.com/*'],
  ['*://www.torn.com/profiles.php*'],
  ['https://www.torn.com/page.php?sid=slots'],
  ['https://www.torn.com/gym.php'],
  ['www.torn.com/page.php?sid=racing'],
  ['*.torn.com/forums.php*'],
  ['http*://www.torn.com/*'],
  ['http://localhost:8080/*'],
  ['*://www.torn.com/*sid=attack*'],
  ['https://www.torn.com/loader.php?sid=crimes*', 'https://www.torn.com/page.php?sid=crimes*'],
  ['https://www.torn.com/item.php', 'https://www.torn.com/factions.php?step=your*'],
  ['torn'],
  [r'https://www.torn.com/a(b)[c]{d}+$^.php*'],
  ['https://www.torn.com/factions.php?step=your#/tab=armoury'],
  ['https://www.torn.com/page.php?sid=crimes#/cracking', 'https://www.torn.com/gym.php'],
];

const _urls = <String>[
  'https://www.torn.com/',
  'https://www.torn.com/index.php',
  'https://www.torn.com/profiles.php?XID=1',
  'https://www.torn.com/profiles.php?XID=1#/p=x',
  'https://www.torn.com/page.php?sid=slots',
  'https://www.torn.com/page.php?sid=slots#/spin',
  'https://www.torn.com/page.php?sid=slotsX',
  'https://www.torn.com/page.php?sid=racing',
  'https://www.torn.com/page.php?sid=crimes#/searchforcash',
  'https://www.torn.com/page.php?sid=crimes#/cracking',
  'https://www.torn.com/loader.php?sid=crimes',
  'https://www.torn.com/loader.php?sid=attack&user2ID=1',
  'https://www.torn.com/factions.php?step=your#/tab=armoury',
  'https://www.torn.com/factions.php#/sid=attack',
  'https://www.torn.com/gym.php',
  'https://www.torn.com/gym.php#x',
  'https://www.torn.com/item.php',
  'https://www.torn.com/forums.php#/p=threads',
  'https://torn.com/forums.php',
  'https://api.torn.com/user',
  'https://www.torn.com:443/page.php',
  'http://www.torn.com/index.php',
  'http://localhost:8080/a',
  'http://localhost:9090/a',
  'https://nottorn.com/page',
  'https://www.torn.com/a(b)[c]{d}+\$^.php?x',
];

void main() {
  test('the page check gives the same answer as matchesTarget', () async {
    final cases = <Map<String, dynamic>>[];
    for (final matches in _patterns) {
      final model = UserScriptModel(name: 'g', source: '', isExample: false, matches: matches);
      final guard = model.matchGuardJs;
      for (final url in _urls) {
        cases.add({'matches': matches, 'url': url, 'guard': guard, 'dart': model.matchesTarget(url)});
      }
    }

    final dir = Directory.systemTemp.createTempSync('pda_guard');
    addTearDown(() => dir.deleteSync(recursive: true));
    final input = File('${dir.path}/cases.json')..writeAsStringSync(jsonEncode(cases));
    final script = File('${dir.path}/run.js')
      ..writeAsStringSync('''
const cases = JSON.parse(require("fs").readFileSync(process.argv[2], "utf8"));
const out = cases.map((c) => c.guard === null ? true : !!new Function("location", "return " + c.guard)({ href: c.url }));
console.log(JSON.stringify(out));
''');
    final ProcessResult result;
    try {
      result = await Process.run('node', [script.path, input.path]);
    } on ProcessException {
      markTestSkipped('node is not installed');
      return;
    }
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final js = (jsonDecode(result.stdout as String) as List).cast<bool>();

    final wrong = [
      for (var i = 0; i < cases.length; i++)
        if (js[i] != cases[i]['dart'])
          '${cases[i]['matches']} ${cases[i]['url']}: dart ${cases[i]['dart']}, js ${js[i]}',
    ];
    expect(wrong, isEmpty);
    expect(cases.where((c) => c['dart'] == true).length, greaterThan(0));
    expect(cases.where((c) => c['dart'] == false).length, greaterThan(0));
  });
}
