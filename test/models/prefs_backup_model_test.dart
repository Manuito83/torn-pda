import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/backup/prefs_backup_model.dart';

// Made with the 3.x exporter, password "oldpass"
const _xorBackup =
    'FE4UFAAsHBgCIBUVEhoDH0ZKQxcWGw0NHBJRX00cABE+BgAKHjcTExoDGx8oGRIHUVVOPy1DX1EwDgUTCgYDMBoBAhIaHAFOXlISFh4NDRcEPgV'
    'CTUBGLwMSEAQZFC8VGh4KHxARDANRVV1IUj4REgwHEQA+AwEAGAETFRocAU5eUhkcAU1ARi8DEhAEGRQvEhAcHwlGSkMDAQYaBQQEUQ4=';

Map<String, dynamic> _script(String name, String source, {bool war = false}) => {
  'enabled': true,
  'matches': ['*'],
  'name': name,
  'version': '1.0',
  'edited': false,
  'source': source,
  'time': 'end',
  'url': null,
  'isExample': false,
  'customApiKey': 'abc',
  'modes': war ? ['war'] : [],
  'alwaysActive': war,
};

List<dynamic> _scriptsIn(Map<String, dynamic> prefs) {
  final raw = prefs['pda_userScriptsList'] as String;
  return jsonDecode(raw.startsWith('PDA_B64:') ? utf8.decode(base64Decode(raw.substring(8))) : raw) as List;
}

void main() {
  group('private backups', () {
    test('a new backup opens with its password and nothing else', () async {
      final plain = jsonEncode({'pda_ownDetails': 'details', backupScopeKey: 'private'});
      final encrypted = await encryptBackup(plain, 'right', iterations: 1000);

      expect(isEncryptedBackup(encrypted), isTrue);
      expect(encrypted, isNot(contains('details')));
      expect((await decryptBackup(encrypted, 'right'))['pda_ownDetails'], 'details');
      await expectLater(decryptBackup(encrypted, 'wrong'), throwsA(anything));
    });

    test('a new backup is neither JSON nor base64', () async {
      final encrypted = await encryptBackup('{}', 'pass', iterations: 1000);
      expect(tryDecodeBackupJson(encrypted), isNull);
      expect(() => base64Decode(encrypted), throwsFormatException);
    });

    test('a backup made before 4.0.0 still opens', () async {
      expect(isEncryptedBackup(_xorBackup), isTrue);
      final prefs = await decryptBackup(_xorBackup, 'oldpass');
      expect(prefs['pda_ownDetails'], 'details');
      await expectLater(decryptBackup(_xorBackup, 'nope'), throwsA(anything));
    });

    test('a file asking for an absurd amount of work is refused', () async {
      final encrypted = await encryptBackup('{}', 'pass', iterations: 1000);
      final prefix = encrypted.substring(0, encrypted.indexOf('{'));
      final envelope = jsonDecode(encrypted.substring(prefix.length)) as Map<String, dynamic>;
      envelope['iterations'] = 1 << 40;
      await expectLater(decryptBackup(prefix + jsonEncode(envelope), 'pass'), throwsFormatException);
    });
  });

  test('private backup passwords need eight characters', () {
    expect(isBackupPasswordTooShort('seven77'), isTrue);
    expect(isBackupPasswordTooShort('eight888'), isFalse);
  });

  group('own backup', () {
    final mine = jsonEncode({'player_id': 1, 'userApiKey': 'key-one'});
    final backup = {'pda_ownDetails': mine};

    test('same player is own', () {
      expect(isOwnBackup(backup, mine), isTrue);
    });

    test('fresh install is own', () {
      expect(isOwnBackup(backup, ''), isTrue);
      expect(isFreshInstall(''), isTrue);
      expect(isFreshInstall(mine), isFalse);
    });

    test('active scripts are listed', () {
      final prefs = {
        'pda_userScriptsList': jsonEncode([
          _script('Plain', 'console.log(1)'),
          _script('Off', 'console.log(2)')..['enabled'] = false,
          _script('War only', 'console.log(3)', war: true)..['enabled'] = false,
        ]),
      };
      expect(activeScripts(prefs), ['Plain', 'War only']);
    });

    test('another or no player is foreign', () {
      expect(isOwnBackup(backup, jsonEncode({'player_id': 2, 'userApiKey': 'key-one'})), isFalse);
      expect(isOwnBackup({'pda_theme': 'dark'}, mine), isFalse);
    });

    test('changed key is foreign', () {
      expect(isOwnBackup(backup, jsonEncode({'player_id': 1, 'userApiKey': 'key-two'})), isFalse);
    });

    test('no key is foreign', () {
      final keyless = {'pda_ownDetails': jsonEncode({'player_id': 1})};
      expect(isOwnBackup(keyless, mine), isFalse);
      expect(isOwnBackup(keyless, jsonEncode({'player_id': 1, 'userApiKey': ''})), isFalse);
    });

    test('foreign keeps settings, scripts off', () {
      final prefs = withScriptsDisabled({
        'pda_ownDetails': mine,
        'pda_userScriptsList': jsonEncode([_script('A', '###PDA-APIKEY###')]),
      });
      expect(prefs['pda_ownDetails'], mine);
      expect(_scriptsIn(prefs).single['enabled'], isFalse);
      expect(scriptsUsingApiKey(prefs), ['A']);
    });
  });

  test('the pending profile deletion mark never travels in a backup', () {
    final prefs = withoutDeviceOnlyKeys({profileDeletionPendingKey: true, 'pda_ownDetails': 'details'});
    expect(prefs.keys, ['pda_ownDetails']);
  });

  group('shareable import', () {
    final shared = {
      'pda_userScriptsList': jsonEncode([
        _script('TornTools Helper', "const key = '###PDA-APIKEY###';"),
        _script('War helper', 'console.log(1)', war: true),
      ]),
      'pda_tryAutomaticLogins': true,
      'pda_ownDetails': 'other details',
      'pda_userScriptsGlobalDisableState': jsonEncode({'TornTools Helper': true}),
      'pda_theme': 'dark',
      backupVersionKey: backupFormatSembast,
      backupProtectionKey: 'xor',
      backupScopeKey: 'private',
    };

    test('a plain file is never private', () {
      expect(isEncryptedBackup(jsonEncode(shared)), isFalse);
    });

    test('only keys a shareable export can carry get through', () {
      final prefs = shareablePrefs(shared, forImport: true);

      expect(prefs['pda_theme'], 'dark');
      expect(prefs.containsKey('pda_tryAutomaticLogins'), isFalse);
      expect(prefs.containsKey('pda_ownDetails'), isFalse);
      expect(prefs.containsKey('pda_userScriptsGlobalDisableState'), isFalse);
    });

    test('scripts come in off, no modes, no keys', () {
      final scripts = _scriptsIn(shareablePrefs(shared, forImport: true));

      expect(scripts.length, 2);
      for (final script in scripts) {
        expect(script['enabled'], isFalse);
        expect(script['alwaysActive'], isFalse);
        expect(script['modes'], isEmpty);
        expect(script['customApiKey'], '');
      }
    });

    test('scripts saved in base64 stay in base64', () {
      final list = jsonEncode([_script('A', 'x')]);
      final prefs = shareablePrefs({
        'pda_userScriptsList': 'PDA_B64:${base64Encode(utf8.encode(list))}',
      }, forImport: true);

      expect(prefs['pda_userScriptsList'], startsWith('PDA_B64:'));
      expect(_scriptsIn(prefs).single['enabled'], isFalse);
    });

    test('unreadable script list is dropped', () {
      final prefs = shareablePrefs({'pda_userScriptsList': '[{"enabled": tr', 'pda_theme': 'dark'}, forImport: true);
      expect(prefs.containsKey('pda_userScriptsList'), isFalse);
      expect(prefs['pda_theme'], 'dark');
    });

    test('names the scripts that read the API key', () {
      expect(scriptsUsingApiKey(shareablePrefs(shared, forImport: true)), ['TornTools Helper']);
    });

    test('own backup names only running scripts', () {
      final prefs = {
        'pda_userScriptsList': jsonEncode([
          _script('On', "const key = '###PDA-APIKEY###';"),
          _script('Off', "const key = '###PDA-APIKEY###';")..['enabled'] = false,
          _script('No key', 'console.log(1)'),
        ]),
      };
      expect(scriptsUsingApiKey(prefs, onlyActive: true), ['On']);
    });

    test('a script in a mode counts as running', () {
      final prefs = {
        'pda_userScriptsList': jsonEncode([
          _script('War only', "const key = '###PDA-APIKEY###';", war: true)
            ..['enabled'] = false
            ..['alwaysActive'] = false,
        ]),
      };
      expect(scriptsUsingApiKey(prefs, onlyActive: true), ['War only']);
    });

    test('export keeps scripts, drops keys', () {
      final script = _scriptsIn(shareablePrefs(shared)).first;
      expect(script['enabled'], isTrue);
      expect(script['customApiKey'], '');
    });
  });
}
