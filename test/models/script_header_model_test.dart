import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/models/userscripts/script_header_model.dart';

void main() {
  group('ScriptHeaderModel', () {
    test('parses version with pre-release', () {
      final model = ScriptHeaderModel.fromHeaderText('@version 1.0.0-alpha\n@name Test');
      expect(model.version.major, 1);
      expect(model.version.minor, 0);
      expect(model.version.patch, 0);
      expect(model.version.pre, 'alpha');
    });

    test('parses version without pre-release', () {
      final model = ScriptHeaderModel.fromHeaderText('@version 2.3.4\n@name Test');
      expect(model.version.major, 2);
      expect(model.version.minor, 3);
      expect(model.version.patch, 4);
      expect(model.version.pre, isNull);
    });

    test('compares versions correctly', () {
      final v1 = VersionModel.parse('1.0.0');
      final v2 = VersionModel.parse('1.0.1');
      final v3 = VersionModel.parse('2.0.0');
      final v4 = VersionModel.parse('1.0.0-alpha');

      expect(v1.compareTo(v2), lessThan(0));
      expect(v2.compareTo(v1), greaterThan(0));
      expect(v1.compareTo(v1), equals(0));
      expect(v3.compareTo(v1), greaterThan(0));
      expect(v4.compareTo(v1), lessThan(0)); // pre-release is older
    });

    test('gets header values', () {
      final model = ScriptHeaderModel.fromHeaderText('''
@version 1.0.0
@name Test Script
@match https://example.com/*
@match https://example2.com/*
@grant GM_xmlhttpRequest
@require https://example.com/library.js
''');
      expect(model.getHeader('name'), ['test script']);
      expect(model.getHeader('match'), ['https://example.com/*', 'https://example2.com/*']);
      expect(model.getHeader('grant'), ['gm_xmlhttprequest']);
      expect(model.getHeader('require'), ['https://example.com/library.js']);
    });
  });

  group('UserScriptModel with new fields', () {
    test('parses header with grants and requires', () {
      const source = '''
// ==UserScript==
// @name Test Script
// @version 1.0.0
// @match https://example.com/*
// @grant GM_xmlhttpRequest
// @grant GM_setValue
// @require https://example.com/lib.js
// ==/UserScript==
// Script content here
''';
      final metaMap = UserScriptModel.parseHeader(source);
      expect(metaMap['grants'], ['GM_xmlhttpRequest', 'GM_setValue']);
      expect(metaMap['requires'], ['https://example.com/lib.js']);
    });

    test('improved URL pattern matching', () {
      final model = UserScriptModel(
        name: 'Test',
        source: '// ==UserScript==\n// @name Test\n// ==/UserScript==\n',
        matches: ['*torn.com*', 'torn.com/path*'],
        isExample: false,
      );

      // Test simple wildcard patterns (original behavior)
      expect(model.shouldInject('https://torn.com/'), true);
      expect(model.shouldInject('https://sub.torn.com/'), true);
      expect(model.shouldInject('https://torn.com/path/test'), true);
      expect(model.shouldInject('https://other.com/'), false);
    });

    test('version comparison with VersionModel', () {
      expect(UserScriptModel.isNewerVersion('1.0.1', '1.0.0'), true);
      expect(UserScriptModel.isNewerVersion('2.0.0', '1.9.9'), true);
      expect(UserScriptModel.isNewerVersion('1.0.0', '1.0.0'), false);
      expect(UserScriptModel.isNewerVersion('1.0.0-alpha', '1.0.0'), false); // pre-release is older
      expect(UserScriptModel.isNewerVersion('1.0.0', '1.0.0-alpha'), true);
    });

    test('serializes and deserializes with new fields', () {
      final model = UserScriptModel(
        name: 'Test',
        source: '// ==UserScript==\n// @name Test\n// ==/UserScript==\n',
        version: '1.0.0',
        grants: ['GM_xmlhttpRequest'],
        requires: ['https://example.com/lib.js'],
        isExample: false,
      );

      final json = model.toJson();
      expect(json['grants'], ['GM_xmlhttpRequest']);
      expect(json['requires'], ['https://example.com/lib.js']);

      final restored = UserScriptModel.fromJson(json);
      expect(restored.grants, ['GM_xmlhttpRequest']);
      expect(restored.requires, ['https://example.com/lib.js']);
    });
  });
}
