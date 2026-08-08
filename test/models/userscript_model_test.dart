import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';

/// Tests for [UserScriptModel] — header parsing, version comparison and URL
/// matching logic.
///
/// These are all pure Dart, no device or network required.
/// Run with:  flutter test test/models/userscript_model_test.dart

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal valid userscript source for test fixtures.
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
  return UserScriptModel(
    name: 'stub',
    source: '',
    isExample: false,
    matches: matches,
    time: time,
    enabled: enabled,
  );
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
      expect(
        () => UserScriptModel.parseHeader('just some random JS'),
        throwsException,
      );
    });

    test('extracts downloadURL', () {
      final source = _script(downloadUrl: 'https://example.com/script.js');
      final meta = UserScriptModel.parseHeader(source);
      expect(meta['downloadURL'], 'https://example.com/script.js');
    });

    test('collects grants and requires in declaration order', () {
      final source = _script(
        grants: ['GM_xmlhttpRequest', 'GM.setValue'],
        requires: [
          'https://cdn.example.com/first.js',
          'https://cdn.example.com/second.js',
        ],
      );

      final meta = UserScriptModel.parseHeader(source);
      expect(meta['grants'], ['GM_xmlhttpRequest', 'GM.setValue']);
      expect(meta['requires'], [
        'https://cdn.example.com/first.js',
        'https://cdn.example.com/second.js',
      ]);
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
  // shouldInject (exercises the @match pattern engine)
  // -------------------------------------------------------------------------
  group('shouldInject', () {
    test('wildcard "*" matches any URL', () {
      final m = _model(matches: ['*']);
      expect(m.shouldInject('https://www.torn.com/anything'), isTrue);
      expect(m.shouldInject('http://example.com'), isTrue);
    });

    test('standard Tampermonkey pattern with scheme wildcard', () {
      final m = _model(matches: ['*://www.torn.com/*']);
      expect(m.shouldInject('https://www.torn.com/profiles.php'), isTrue);
      expect(m.shouldInject('http://www.torn.com/page'), isTrue);
      expect(m.shouldInject('https://www.example.com/page'), isFalse);
    });

    test('explicit https scheme rejects http', () {
      final m = _model(matches: ['https://www.torn.com/*']);
      expect(m.shouldInject('https://www.torn.com/page'), isTrue);
      expect(m.shouldInject('http://www.torn.com/page'), isFalse);
    });

    test('subdomain wildcard *.torn.com matches subdomains correctly', () {
      // PR #409 implemented proper regex-based matching for wildcard patterns.
      // *.torn.com should match any subdomain of torn.com (including bare torn.com).
      final m = _model(matches: ['*://*.torn.com/*']);
      expect(m.shouldInject('https://www.torn.com/page'), isTrue);
      expect(m.shouldInject('https://api.torn.com/user'), isTrue);
      expect(m.shouldInject('https://torn.com/page'), isTrue);
      // Should NOT match other domains
      expect(m.shouldInject('https://nottorn.com/page'), isFalse);
    });

    test('path-specific pattern', () {
      final m = _model(matches: ['*://www.torn.com/profiles.php*']);
      expect(m.shouldInject('https://www.torn.com/profiles.php?XID=123'), isTrue);
      expect(m.shouldInject('https://www.torn.com/page.php'), isFalse);
    });

    test('legacy pattern without protocol (backwards compat)', () {
      final m = _model(matches: ['www.torn.com/*']);
      expect(m.shouldInject('https://www.torn.com/page'), isTrue);
      expect(m.shouldInject('http://www.torn.com/page'), isTrue);
    });

    test('disabled script never injects', () {
      final m = _model(matches: ['*'], enabled: false);
      expect(m.shouldInject('https://anything.com'), isFalse);
    });

    test('respects injection time filter', () {
      final m = _model(matches: ['*'], time: UserScriptTime.end);
      expect(m.shouldInject('https://torn.com', UserScriptTime.end), isTrue);
      expect(m.shouldInject('https://torn.com', UserScriptTime.start), isFalse);
      // null time means "don't filter"
      expect(m.shouldInject('https://torn.com', null), isTrue);
    });

    test('multiple match patterns — any match suffices', () {
      final m = _model(matches: [
        'https://www.torn.com/*',
        'https://api.torn.com/*',
      ]);
      expect(m.shouldInject('https://www.torn.com/page'), isTrue);
      expect(m.shouldInject('https://api.torn.com/user'), isTrue);
      expect(m.shouldInject('https://example.com/'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // tryGet* helpers
  // -------------------------------------------------------------------------
  group('tryGet helpers', () {
    test('tryGetMatches returns matches from valid script', () {
      final source = _script(match: 'https://www.torn.com/*');
      expect(UserScriptModel.tryGetMatches(source), ['https://www.torn.com/*']);
    });

    test('tryGetMatches returns ["*"] for garbage input', () {
      expect(UserScriptModel.tryGetMatches('not a script'), ['*']);
    });

    test('tryGetVersion returns version string', () {
      expect(UserScriptModel.tryGetVersion(_script(version: '3.2.1')), '3.2.1');
    });

    test('tryGetVersion returns null for garbage', () {
      expect(UserScriptModel.tryGetVersion('nope'), isNull);
    });

    test('tryGetUrl returns download URL', () {
      final s = _script(downloadUrl: 'https://example.com/s.js');
      expect(UserScriptModel.tryGetUrl(s), 'https://example.com/s.js');
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
      final source = _script(
        grants: ['GM_xmlhttpRequest'],
        requires: ['https://cdn.example.com/lib.js'],
      );
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
  });
}
