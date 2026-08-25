import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/userscripts/script_catalog_model.dart';

/// Tests for [ScriptCatalog] parsing and for the catalog file
///
String _catalogJson({int schemaVersion = 1, bool enabled = true, List<Map<String, dynamic>>? scripts}) {
  return json.encode({
    "schemaVersion": schemaVersion,
    "enabled": enabled,
    "updated": "2026-08-14",
    "provider": {
      "name": "TornTools",
      "author": "DeKleineKobini",
      "description": "desc",
      "links": {"forum": "https://forum", "github": "https://github"},
    },
    "categories": [
      {"id": "items", "name": "Items & Market"},
      {"id": "travel", "name": "Travel"},
    ],
    "scripts":
        scripts ??
        [
          {
            "id": "torntools.item-values",
            "greasyforkId": 582355,
            "name": "Item Values",
            "description": "Show item values.",
            "category": "items",
            "downloadUrl": "https://update.greasyfork.org/scripts/582355/x.user.js",
            "pageUrl": "https://greasyfork.org/scripts/582355-x",
            "matches": ["https://*.torn.com/item.php*"],
          },
        ],
  });
}

void main() {
  group('ScriptCatalog.tryParse', () {
    test('parses a well-formed catalog', () {
      final catalog = ScriptCatalog.tryParse(_catalogJson());

      expect(catalog, isNotNull);
      expect(catalog!.enabled, isTrue);
      expect(catalog.provider.name, 'TornTools');
      expect(catalog.provider.forum, 'https://forum');
      expect(catalog.scripts.length, 1);
      expect(catalog.scripts.first.name, 'Item Values');
    });

    test('treats an empty link as absent so no dead chips are shown', () {
      final raw = json.decode(_catalogJson()) as Map<String, dynamic>;
      (raw["provider"] as Map<String, dynamic>)["links"] = {"forum": "", "github": "https://github"};
      final catalog = ScriptCatalog.tryParse(json.encode(raw));

      expect(catalog!.provider.forum, isNull);
      expect(catalog.provider.github, 'https://github');
      expect(catalog.provider.discord, isNull);
    });

    test('rejects a schema newer than we understand', () {
      expect(ScriptCatalog.tryParse(_catalogJson(schemaVersion: 99)), isNull);
    });

    test('rejects a catalog with no usable scripts', () {
      expect(ScriptCatalog.tryParse(_catalogJson(scripts: [])), isNull);
    });

    test('rejects malformed JSON instead of throwing', () {
      expect(ScriptCatalog.tryParse('{not json'), isNull);
      expect(ScriptCatalog.tryParse(''), isNull);
      expect(ScriptCatalog.tryParse('[]'), isNull);
    });

    test('drops individual entries that lack the fields we need', () {
      final catalog = ScriptCatalog.tryParse(
        _catalogJson(
          scripts: [
            {"id": "good", "name": "Good", "downloadUrl": "https://x/y.user.js", "category": "items"},
            {"id": "", "name": "No id", "downloadUrl": "https://x/y.user.js"},
            {"id": "no-url", "name": "No url", "downloadUrl": ""},
          ],
        ),
      );

      expect(catalog, isNotNull);
      expect(catalog!.scripts.length, 1);
      expect(catalog.scripts.first.id, 'good');
    });

    test('keeps the disabled flag so the section can be switched off remotely', () {
      final catalog = ScriptCatalog.tryParse(_catalogJson(enabled: false));
      expect(catalog, isNotNull);
      expect(catalog!.enabled, isFalse);
    });

    test('populatedCategories skips categories with no scripts', () {
      final catalog = ScriptCatalog.tryParse(_catalogJson())!;
      expect(catalog.populatedCategories.map((c) => c.id), ['items']);
    });
  });

  group('greasyforkIdFromUrl', () {
    test('reads the id from an update.greasyfork download URL', () {
      expect(
        CatalogScript.greasyforkIdFromUrl('https://update.greasyfork.org/scripts/581399/TORN%3A%20x.user.js'),
        581399,
      );
    });

    test('reads the id from a locale-prefixed page URL', () {
      expect(CatalogScript.greasyforkIdFromUrl('https://greasyfork.org/en/scripts/581399-torn-x'), 581399);
    });

    test('reads the id from a URL with no locale', () {
      expect(CatalogScript.greasyforkIdFromUrl('https://greasyfork.org/scripts/581399-torn-x'), 581399);
    });

    test('returns null for unrelated or missing URLs', () {
      expect(CatalogScript.greasyforkIdFromUrl(null), isNull);
      expect(CatalogScript.greasyforkIdFromUrl('https://github.com/Manuito83/torn-pda/raw/master/a.js'), isNull);
    });
  });

  group('whereItRuns', () {
    CatalogScript scriptWithMatches(List<String> matches) {
      final raw = json.decode(_catalogJson()) as Map<String, dynamic>;
      (raw["scripts"] as List<dynamic>)[0]["matches"] = matches;
      return ScriptCatalog.tryParse(json.encode(raw))!.scripts.first;
    }

    test('turns a plain page into a readable name', () {
      expect(scriptWithMatches(['https://*.torn.com/bank.php*']).whereItRuns, ['Bank']);
    });

    test('reports a bare wildcard as everywhere', () {
      final script = scriptWithMatches(['*']);
      expect(script.isGlobal, isTrue);
      expect(script.whereItRuns, [CatalogScript.everywhere]);
    });

    test('reports a whole-domain wildcard as everywhere', () {
      expect(scriptWithMatches(['*://*.torn.com/*']).isGlobal, isTrue);
    });

    test('reports the https whole-domain wildcard as everywhere too', () {
      final script = scriptWithMatches(['https://*.torn.com/*']);
      expect(script.isGlobal, isTrue);
      expect(script.whereItRuns, [CatalogScript.everywhere]);
    });

    test('a script bound to a page is not global', () {
      expect(scriptWithMatches(['https://*.torn.com/bank.php*']).isGlobal, isFalse);
    });

    test('uses the sid parameter when the page is page.php', () {
      expect(scriptWithMatches(['https://*.torn.com/page.php?sid=travel*']).whereItRuns, ['Travel']);
    });

    test('uses the list type when the sid is a generic list', () {
      expect(scriptWithMatches(['https://*.torn.com/page.php?sid=list&type=enemies*']).whereItRuns, ['Enemies']);
    });

    test('splits camel case names', () {
      expect(scriptWithMatches(['https://*.torn.com/page.php?sid=ItemMarket*']).whereItRuns, ['Item market']);
    });

    test('survives a duplicated .php in the script header', () {
      expect(scriptWithMatches(['https://*.torn.com/bigalgunshop.php.php*']).whereItRuns, ["Big Al's"]);
    });

    test('lists every distinct page, without repeats', () {
      final script = scriptWithMatches([
        'https://*.torn.com/item.php*',
        'https://*.torn.com/bazaar.php*',
        'https://*.torn.com/item.php?step=1*',
      ]);
      expect(script.whereItRuns, ['Items', 'Bazaar']);
    });
  });

  group('the catalog file shipped with the app', () {
    late ScriptCatalog catalog;

    setUpAll(() {
      final file = File('userscripts/catalog/torntools.json');
      expect(file.existsSync(), isTrue, reason: 'the bundled catalog asset must exist');
      catalog = ScriptCatalog.tryParse(file.readAsStringSync())!;
    });

    test('parses and is enabled', () {
      expect(catalog.enabled, isTrue);
      expect(catalog.schemaVersion, ScriptCatalog.supportedSchemaVersion);
      expect(catalog.scripts, isNotEmpty);
    });

    test('every script has a Greasy Fork download URL and an id we can match', () {
      for (final script in catalog.scripts) {
        expect(script.downloadUrl, startsWith('https://update.greasyfork.org/scripts/'), reason: script.name);
        expect(script.greasyforkId, greaterThan(0), reason: script.name);
        expect(
          CatalogScript.greasyforkIdFromUrl(script.downloadUrl),
          script.greasyforkId,
          reason: '${script.name} download URL must resolve to its declared id',
        );
      }
    });

    test('script ids and Greasy Fork ids are unique', () {
      expect(catalog.scripts.map((s) => s.id).toSet().length, catalog.scripts.length);
      expect(catalog.scripts.map((s) => s.greasyforkId).toSet().length, catalog.scripts.length);
    });

    test('every script points at a category the catalog declares', () {
      final known = catalog.categories.map((c) => c.id).toSet();
      for (final script in catalog.scripts) {
        expect(known, contains(script.category), reason: '${script.name} uses an unknown category');
      }
    });
  });
}
