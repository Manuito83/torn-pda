import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';

/// Tests for [UserScriptModel]: header parsing, version comparison and URL
/// matching logic

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal valid userscript source for test fixtures
String _script({
  String name = 'Test Script',
  String version = '1.0.0',
  String match = '*',
  String runAt = 'document-end',
  String? downloadUrl,
  List<String> grants = const [],
  List<String> requires = const [],
  String body = 'console.log("hi");',
}) {
  final lines = <String>[
    '// ==UserScript==',
    '// @name         $name',
    '// @version      $version',
    '// @match        $match',
    '// @run-at       $runAt',
    if (downloadUrl != null) '// @downloadurl  $downloadUrl',
    for (final grant in grants) '// @grant        $grant',
    for (final require in requires) '// @require      $require',
    '// ==/UserScript==',
    body,
  ];
  return lines.join('\n');
}

UserScriptModel _model({
  List<String> matches = const ['*'],
  UserScriptTime time = UserScriptTime.end,
  bool enabled = true,
}) {
  return UserScriptModel(name: 'stub', source: '', isExample: false, matches: matches, time: time, enabled: enabled);
}

// ---------------------------------------------------------------------------
// parseHeader
// ---------------------------------------------------------------------------
void main() {
  group('parseHeader', () {
    test('extracts name, version, author from a well-formed header', () {
      final source = _script(name: 'My Script', version: '2.3.1');
      final meta = UserScriptModel.parseHeader(source);

      expect(meta['name'], 'My Script');
      expect(meta['version'], '2.3.1');
    });

    test('collects multiple @match entries into a list', () {
      final source = [
        '// ==UserScript==',
        '// @name         Multi',
        '// @version      1.0.0',
        '// @match        https://www.torn.com/*',
        '// @match        https://api.torn.com/*',
        '// ==/UserScript==',
      ].join('\n');

      final meta = UserScriptModel.parseHeader(source);
      expect(meta['matches'], ['https://www.torn.com/*', 'https://api.torn.com/*']);
    });

    test('defaults matches to ["*"] when no @match present', () {
      final source = [
        '// ==UserScript==',
        '// @name         NoMatch',
        '// @version      0.1',
        '// ==/UserScript==',
      ].join('\n');

      final meta = UserScriptModel.parseHeader(source);
      expect(meta['matches'], ['*']);
    });

    test('throws when source has no header block', () {
      expect(() => UserScriptModel.parseHeader('just some random JS'), throwsException);
    });

    test('extracts downloadURL', () {
      final source = _script(downloadUrl: 'https://example.com/script.js');
      final meta = UserScriptModel.parseHeader(source);
      expect(meta['downloadURL'], 'https://example.com/script.js');
    });

    test('collects grants and requires in declaration order', () {
      final source = _script(
        grants: ['GM_xmlhttpRequest', 'GM.setValue'],
        requires: ['https://cdn.example.com/first.js', 'https://cdn.example.com/second.js'],
      );

      final meta = UserScriptModel.parseHeader(source);
      expect(meta['grants'], ['GM_xmlhttpRequest', 'GM.setValue']);
      expect(meta['requires'], ['https://cdn.example.com/first.js', 'https://cdn.example.com/second.js']);
    });

    test('returns document-end as default injection time', () {
      final source = [
        '// ==UserScript==',
        '// @name         NoRunAt',
        '// @version      1.0',
        '// ==/UserScript==',
      ].join('\n');

      final meta = UserScriptModel.parseHeader(source);
      expect(meta['injectionTime'], 'document-end');
    });
  });

  // -------------------------------------------------------------------------
  // isNewerVersion
  // -------------------------------------------------------------------------
  group('isNewerVersion', () {
    test('detects newer major', () {
      expect(UserScriptModel.isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('detects newer minor', () {
      expect(UserScriptModel.isNewerVersion('1.3.0', '1.2.9'), isTrue);
    });

    test('detects newer patch', () {
      expect(UserScriptModel.isNewerVersion('1.0.2', '1.0.1'), isTrue);
    });

    test('same version returns false', () {
      expect(UserScriptModel.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    });

    test('older version returns false', () {
      expect(UserScriptModel.isNewerVersion('1.0.0', '1.0.1'), isFalse);
    });

    test('non-semver strings fall back to inequality check', () {
      // When the format doesn't match the digit regex, it just returns v1 != v2
      expect(UserScriptModel.isNewerVersion('abc', 'def'), isTrue);
      expect(UserScriptModel.isNewerVersion('same', 'same'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // matchesTarget (exercises the @match pattern engine)
  // -------------------------------------------------------------------------
  group('matchesTarget', () {
    test('wildcard "*" matches any URL', () {
      final m = _model(matches: ['*']);
      expect(m.matchesTarget('https://www.torn.com/anything'), isTrue);
      expect(m.matchesTarget('http://example.com'), isTrue);
    });

    test('standard Tampermonkey pattern with scheme wildcard', () {
      final m = _model(matches: ['*://www.torn.com/*']);
      expect(m.matchesTarget('https://www.torn.com/profiles.php'), isTrue);
      expect(m.matchesTarget('http://www.torn.com/page'), isTrue);
      expect(m.matchesTarget('https://www.example.com/page'), isFalse);
    });

    test('explicit https scheme rejects http', () {
      final m = _model(matches: ['https://www.torn.com/*']);
      expect(m.matchesTarget('https://www.torn.com/page'), isTrue);
      expect(m.matchesTarget('http://www.torn.com/page'), isFalse);
    });

    test('subdomain wildcard *.torn.com matches subdomains correctly', () {
      // PR #409 implemented proper regex-based matching for wildcard patterns.
      // *.torn.com should match any subdomain of torn.com (including bare torn.com).
      final m = _model(matches: ['*://*.torn.com/*']);
      expect(m.matchesTarget('https://www.torn.com/page'), isTrue);
      expect(m.matchesTarget('https://api.torn.com/user'), isTrue);
      expect(m.matchesTarget('https://torn.com/page'), isTrue);
      // Should NOT match other domains
      expect(m.matchesTarget('https://nottorn.com/page'), isFalse);
    });

    test('path-specific pattern', () {
      final m = _model(matches: ['*://www.torn.com/profiles.php*']);
      expect(m.matchesTarget('https://www.torn.com/profiles.php?XID=123'), isTrue);
      expect(m.matchesTarget('https://www.torn.com/page.php'), isFalse);
    });

    test('legacy pattern without protocol (backwards compat)', () {
      final m = _model(matches: ['www.torn.com/*']);
      expect(m.matchesTarget('https://www.torn.com/page'), isTrue);
      expect(m.matchesTarget('http://www.torn.com/page'), isTrue);
    });

    test('ignores the #hash, as Tampermonkey does', () {
      final m = _model(matches: ['https://www.torn.com/page.php?sid=slots']);
      expect(m.matchesTarget('https://www.torn.com/page.php?sid=slots'), isTrue);
      expect(m.matchesTarget('https://www.torn.com/page.php?sid=slots#/spin'), isTrue);
      expect(m.matchesTarget('https://www.torn.com/page.php?sid=slotsX'), isFalse);
      final legacy = _model(matches: ['www.torn.com/gym.php']);
      expect(legacy.matchesTarget('https://www.torn.com/gym.php#x'), isTrue);
    });

    test('a pattern cannot match inside the #hash', () {
      final m = _model(matches: ['*://www.torn.com/*sid=attack*']);
      expect(m.matchesTarget('https://www.torn.com/loader.php?sid=attack&user2ID=1'), isTrue);
      expect(m.matchesTarget('https://www.torn.com/factions.php#/sid=attack'), isFalse);
    });

    test('http*:// matches http and https', () {
      final m = _model(matches: ['http*://www.torn.com/*']);
      expect(m.matchesTarget('https://www.torn.com/page'), isTrue);
      expect(m.matchesTarget('http://www.torn.com/page'), isTrue);
      expect(m.matchesTarget('ftp://www.torn.com/page'), isFalse);
    });

    test('matches any port unless the pattern has one', () {
      final m = _model(matches: ['*://*.torn.com/*']);
      expect(m.matchesTarget('https://www.torn.com:443/page'), isTrue);
      final withPort = _model(matches: ['http://localhost:8080/*']);
      expect(withPort.matchesTarget('http://localhost:8080/a'), isTrue);
      expect(withPort.matchesTarget('http://localhost:9090/a'), isFalse);
    });

    test('respects injection time filter', () {
      final m = _model(matches: ['*'], time: UserScriptTime.end);
      expect(m.matchesTarget('https://torn.com', UserScriptTime.end), isTrue);
      expect(m.matchesTarget('https://torn.com', UserScriptTime.start), isFalse);
      // null time means "don't filter"
      expect(m.matchesTarget('https://torn.com', null), isTrue);
    });

    test('multiple match patterns — any match suffices', () {
      final m = _model(matches: ['https://www.torn.com/*', 'https://api.torn.com/*']);
      expect(m.matchesTarget('https://www.torn.com/page'), isTrue);
      expect(m.matchesTarget('https://api.torn.com/user'), isTrue);
      expect(m.matchesTarget('https://example.com/'), isFalse);
    });

    test('follows a new @match list after the first check', () {
      final m = _model(matches: ['*://www.torn.com/item.php*']);
      expect(m.matchesTarget('https://www.torn.com/item.php'), isTrue);

      m.update(matches: ['*://www.torn.com/index.php*'], updateStatus: UserScriptUpdateStatus.noRemote);
      expect(m.matchesTarget('https://www.torn.com/item.php'), isFalse);
      expect(m.matchesTarget('https://www.torn.com/index.php'), isTrue);
    });
  });

  group('staleScriptGroups', () {
    test('drops what does not match the next page, deleted scripts included', () {
      final items = UserScriptModel(
        name: 'items',
        source: '',
        isExample: false,
        matches: ['*://www.torn.com/item.php*'],
        time: UserScriptTime.start,
      );
      final everywhere = UserScriptModel(name: 'all', source: '', isExample: false, time: UserScriptTime.start);

      final stale = staleScriptGroups(
        [items.storageId, everywhere.storageId, 'deleted-script'],
        [items, everywhere],
        'https://www.torn.com/index.php',
      );

      expect(stale, [items.storageId, 'deleted-script']);
    });
  });

  // -------------------------------------------------------------------------
  // tryGet* helpers
  // -------------------------------------------------------------------------
  group('tryGet helpers', () {
    test('tryGetMatches returns ["*"] for garbage input', () {
      expect(UserScriptModel.tryGetMatches('not a script'), ['*']);
    });

    test('tryGetVersion returns null for garbage', () {
      expect(UserScriptModel.tryGetVersion('nope'), isNull);
    });

    test('tryGetUrl returns null when missing', () {
      expect(UserScriptModel.tryGetUrl(_script()), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // JSON round-trip
  // -------------------------------------------------------------------------
  group('JSON serialization', () {
    test('toJson → fromJson round-trip preserves fields', () {
      final original = UserScriptModel(
        name: 'Round Trip',
        version: '1.2.3',
        source: _script(name: 'Round Trip', version: '1.2.3'),
        matches: ['https://www.torn.com/*'],
        time: UserScriptTime.start,
        enabled: true,
        isExample: false,
        customApiKey: 'testkey',
        customApiKeyCandidate: true,
        grants: ['GM_xmlhttpRequest'],
        requires: ['https://cdn.example.com/lib.js'],
      );

      final json = original.toJson();
      final restored = UserScriptModel.fromJson(json);

      expect(restored.name, original.name);
      expect(restored.version, original.version);
      expect(restored.matches, original.matches);
      expect(restored.time, original.time);
      expect(restored.enabled, original.enabled);
      expect(restored.isExample, original.isExample);
      expect(restored.customApiKey, original.customApiKey);
      expect(restored.customApiKeyCandidate, original.customApiKeyCandidate);
      expect(restored.grants, original.grants);
      expect(restored.requires, original.requires);
    });

    test('fromMetaMap carries grants and requires into the model', () {
      final source = _script(grants: ['GM_xmlhttpRequest'], requires: ['https://cdn.example.com/lib.js']);
      final meta = UserScriptModel.parseHeader(source);

      final model = UserScriptModel.fromMetaMap(meta, isExample: false);

      expect(model.grants, ['GM_xmlhttpRequest']);
      expect(model.requires, ['https://cdn.example.com/lib.js']);
    });
  });

  group('source adaptation', () {
    test('replaces the PDA API key placeholder before injection', () {
      final provider = UserScriptsProvider();
      final adapted = provider.adaptSource(
        source: 'const key = "###PDA-APIKEY###";',
        scriptFinalApiKey: 'abc123',
        storageId: 'test-sid',
      );

      expect(adapted, contains('const key = "abc123";'));
      expect(adapted, isNot(contains('###PDA-APIKEY###')));
      expect(adapted, startsWith('(function() {'));
      expect(adapted, endsWith('}());'));
    });

    test('normalizes smart quotes before injection', () {
      final provider = UserScriptsProvider();
      final adapted = provider.adaptSource(
        source: 'const text = “value”; const other = ‘x’;',
        scriptFinalApiKey: 'unused',
        storageId: 'test-sid',
      );

      expect(adapted, contains('const text = "value";'));
      expect(adapted, contains("const other = 'x';"));
    });

    test('keeps a source without key or smart quotes as the same string', () {
      const source = 'const a = "b";';
      expect(identical(UserScriptsProvider.adaptBody(source, 'k'), source), isTrue);
    });

    test('caches the adapted source until the source or the key changes', () {
      final model = _model();
      var calls = 0;
      String adapt(String s, String k) {
        calls++;
        return UserScriptsProvider.adaptBody(s, k);
      }

      model.source = 'key = "###PDA-APIKEY###";';
      expect(model.adaptedBody('k1', adapt), 'key = "k1";');
      expect(model.adaptedBody('k1', adapt), 'key = "k1";');
      expect(calls, 1);

      expect(model.adaptedBody('k2', adapt), 'key = "k2";');
      expect(calls, 2);

      model.source = 'key = “###PDA-APIKEY###”;';
      expect(model.adaptedBody('k2', adapt), 'key = "k2";');
      expect(calls, 3);
    });
  });

  // -------------------------------------------------------------------------
  // tryGetUpdateUrl
  // -------------------------------------------------------------------------
  group('tryGetUpdateUrl', () {
    test('extracts updateURL from the header', () {
      const source =
          '// ==UserScript==\n'
          '// @name         Test\n'
          '// @version      1.0.0\n'
          '// @downloadURL  https://update.greasyfork.org/scripts/1/Test.user.js\n'
          '// @updateURL    https://update.greasyfork.org/scripts/1/Test.meta.js\n'
          '// ==/UserScript==\n';

      expect(UserScriptModel.tryGetUpdateUrl(source), 'https://update.greasyfork.org/scripts/1/Test.meta.js');
    });

    test('returns null when the script declares no updateURL', () {
      final source = _script(downloadUrl: 'https://example.com/s.user.js');
      expect(UserScriptModel.tryGetUpdateUrl(source), isNull);
    });

    test('returns null on a source with no header at all', () {
      expect(UserScriptModel.tryGetUpdateUrl('console.log("no header");'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Naming on updates
  // -------------------------------------------------------------------------
  group('name on remote updates', () {
    test('takes the name from the header, long TornTools names included', () {
      final model = UserScriptModel(
        name: 'City Items',
        source: _script(name: 'TORN: TornTools - City Items', version: '1.0.0'),
        isExample: false,
        version: '1.0.0',
      );
      model.update(
        source: _script(name: 'TORN: TornTools - City Items', version: '1.1.0'),
        updateStatus: UserScriptUpdateStatus.upToDate,
      );

      expect(model.name, 'TORN: TornTools - City Items');
      expect(model.version, '1.1.0');
    });
  });

  // -------------------------------------------------------------------------
  // Install date
  // -------------------------------------------------------------------------
  group('installedAt', () {
    test('survives a save and load round trip', () {
      final model = UserScriptModel(name: 'Dated', source: '', isExample: false, installedAt: 1756800000000);
      expect(UserScriptModel.fromJson(model.toJson()).installedAt, 1756800000000);
    });

    test('reads as 0 when the saved data predates the field', () {
      final legacy = {
        "enabled": true,
        "matches": ["*"],
        "name": "Old",
        "version": "1.0.0",
        "edited": false,
        "source": "",
        "url": null,
        "updateStatus": "noRemote",
        "isExample": false,
        "time": "end",
      };
      expect(UserScriptModel.fromJson(legacy).installedAt, 0);
    });
  });

  // -------------------------------------------------------------------------
  // matchesQuery (the search box on the scripts page)
  // -------------------------------------------------------------------------
  group('matchesQuery', () {
    final m = UserScriptModel(
      name: 'City Items',
      source: 'function run() { console.log("hi"); }',
      isExample: false,
    );

    test('empty query matches everything', () {
      expect(m.matchesQuery(''), isTrue);
      expect(m.matchesQuery('   '), isTrue);
    });

    test('matches the name, ignoring case', () {
      expect(m.matchesQuery('city'), isTrue);
      expect(m.matchesQuery('ITEMS'), isTrue);
      expect(m.matchesQuery('bazaar'), isFalse);
    });

    test('only looks inside the code when asked to', () {
      expect(m.matchesQuery('console.log'), isFalse);
      expect(m.matchesQuery('console.log', inSource: true), isTrue);
    });

    test('code search is a plain substring, dots included', () {
      expect(m.matchesQuery('CONSOLE.LOG', inSource: true), isTrue);
      expect(m.matchesQuery('consolelog', inSource: true), isFalse);
      expect(m.matchesQuery('function run', inSource: true), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Modes
  // -------------------------------------------------------------------------
  group('modes', () {
    final legacy = {
      "enabled": true,
      "matches": ["*"],
      "name": "Old",
      "version": "1.0.0",
      "edited": false,
      "source": "",
      "url": null,
      "updateStatus": "noRemote",
      "isExample": false,
      "time": "end",
    };

    test('survive a save and load round trip', () {
      final model = UserScriptModel(
        name: 'Modes',
        source: '',
        isExample: false,
        modes: {warModeId, 'casino'},
        alwaysActive: true,
      );
      final loaded = UserScriptModel.fromJson(model.toJson());
      expect(loaded.modes, {warModeId, 'casino'});
      expect(loaded.alwaysActive, isTrue);
    });

    test('a saved warEnabled true keeps the script inside war mode', () {
      expect(UserScriptModel.fromJson({...legacy, "warEnabled": true}).modes, {warModeId});
    });

    test('a saved warEnabled true is merged with the new list', () {
      final loaded = UserScriptModel.fromJson({
        ...legacy,
        "warEnabled": true,
        "modes": ['casino'],
      });
      expect(loaded.modes, {warModeId, 'casino'});
    });

    test('read as empty when the saved data predates the fields', () {
      final loaded = UserScriptModel.fromJson(legacy);
      expect(loaded.modes, isEmpty);
      expect(loaded.alwaysActive, isFalse);
    });
  });

  group('saved modes', () {
    test('custom modes survive a save and load round trip', () {
      const modes = [UserScriptMode(id: 'a1', name: 'Casino'), UserScriptMode(id: 'b2', name: 'Racing')];
      final loaded = userScriptModesFromJson(userScriptModesToJson(modes));
      expect([for (final m in loaded) (m.id, m.name)], [('a1', 'Casino'), ('b2', 'Racing')]);
    });

    test('broken saved modes load as none', () {
      expect(userScriptModesFromJson(''), isEmpty);
      expect(userScriptModesFromJson('{"id": "a1"}'), isEmpty);
    });

    test('active mode survives a save and load round trip', () {
      for (final (mode, id) in [
        (ScriptsBulkMode.none, warModeId),
        (ScriptsBulkMode.globalDisable, warModeId),
        (ScriptsBulkMode.scriptMode, warModeId),
        (ScriptsBulkMode.scriptMode, 'a1'),
      ]) {
        final loaded = bulkModeFromPrefs(bulkModeToPrefs(mode, id));
        expect(loaded.mode, mode);
        expect(loaded.modeId, mode == ScriptsBulkMode.scriptMode ? id : null);
      }
    });

    test('"warMode" reads as war mode', () {
      final loaded = bulkModeFromPrefs('warMode');
      expect(loaded.mode, ScriptsBulkMode.scriptMode);
      expect(loaded.modeId, warModeId);
    });
  });
}
