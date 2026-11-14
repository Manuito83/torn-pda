import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:torn_pda/models/userscript_model.dart';

const String backupVersionKey = '_backup_version';
const String backupTimestampKey = '_backup_timestamp';
const String backupProtectionKey = '_backup_protection';
const String backupScopeKey = '_backup_scope';
const String backupFormatSembast = 'sembast_v1';
const String backupProtectionNone = 'none';
const String backupProtectionAesGcm = 'aes-gcm';

const int backupKdfIterations = 100000;
const String _aesBackupPrefix = 'PDA1:';

const String _userScriptsKey = 'pda_userScriptsList';
const String _scriptsB64Prefix = 'PDA_B64:';

const Set<String> foreignExcludedKeys = {
  'pda_ffScouterEnabledStatus',
  'pda_ffScouterPolicyUpdateRequired',
  'pda_browserRemoteDebugging',
};

const String profileDeletionPendingKey = '_profile_deletion_pending';
const Set<String> deviceOnlyKeys = {profileDeletionPendingKey};

Map<String, dynamic> withoutDeviceOnlyKeys(Map<String, dynamic> prefs) =>
    Map<String, dynamic>.from(prefs)..removeWhere((key, _) => deviceOnlyKeys.contains(key));

const Set<String> shareableExcludedKeys = {
  ...foreignExcludedKeys,
  '_local_user_model_snapshot',
  'pda_ownDetails',
  'pda_nativePlayerEmail',
  'pda_lastAuthRedirect',
  'pda_tryAutomaticLogins',
  'pda_playerLastLoginMethod',
  'pda_nativeLoginKeychainMigrated',
  'pda_alternativeYataKeyEnabled',
  'pda_alternativeYataKey',
  'pda_alternativeTornStatsKeyEnabled',
  'pda_alternativeTornStatsKey',
  'pda_alternativeTSCKeyEnabled',
  'pda_alternativeTSCKey',
  'pda_alternativeFFScouterKeyEnabled',
  'pda_alternativeFFScouterKey',
  'pda_scriptCatalogApiKey',
  'pda_scriptCatalogCache',
  'pda_scriptDocsCache',
  'pda_userScriptsGlobalDisableState',
  'pda_webViewSessionCookie',
  'pda_webViewLastActiveTab',
  'pda_webViewMainTab',
  'pda_webViewTabs',
  'pda_splitBrowsersLayout',
  'pda_fcmToken',
  'pda_fcmTokenSynced',
  'pda_iosLiveActivityTravelPushToken',
  'pda_iosLiveActivityRacingPushToken',
  'pda_chatImgurClientId',
  'pda_chatImgbbKey',
  'pda_chatCatboxUserhash',
  'pda_nativeChatDrafts',
  'pda_nativeChatSaved',
  'pda_nativeChatPinnedMessages',
  'pda_nativeChatIgnored',
  'pda_nativeChatFriends',
  'pda_nativeChatPlayerNotes',
  'pda_nativeChatPeople',
  'pda_nativeChatReminders',
  'pda_nativeChatShortcutCache',
  'pda_nativeChatOpens',
  'pda_appIconMenu',
  'pda_nativeChatWindows',
  'pda_nativeChatOnScreen',
  'pda_nativeChatTones',
  'pda_nativeChatMuted',
  'pda_nativeChatMutedUntil',
  'pda_nativeChatPinned',
  'pda_nativeChatPlayerColors',
  'pda_nativeChatCompactMode',
  'pda_nativeChatShowAvatars',
  'pda_nativeChatTextScale',
  'pda_nativeChatBubbleRooms',
  'pda_nativeChatAlertLevels',
  'pda_nativeChatHiddenRooms',
  'pda_nativeChatPausedRooms',
  'pda_nativeChatRoomFilters',
  'pda_nativeChatPausedAt',
  'pda_nativeChatOwner',
  'pda_nativeChatInbox',
};

Map<String, dynamic>? tryDecodeBackupJson(String encoded) {
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return null;
  }
  return null;
}

bool _isAesEnvelope(Map<String, dynamic> map) =>
    map[backupProtectionKey] == backupProtectionAesGcm && map['data'] is String;

/// Plain JSON is never private
bool isEncryptedBackup(String encoded) {
  final map = tryDecodeBackupJson(encoded);
  return map == null || _isAesEnvelope(map);
}

// Always run off the main isolate
DartPbkdf2 _kdf(int iterations) =>
    DartPbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256, pausePeriod: Duration.zero);

Future<String> encryptBackup(String plain, String password, {int iterations = backupKdfIterations}) async {
  final random = Random.secure();
  final salt = List<int>.generate(16, (_) => random.nextInt(256));
  final key = await _kdf(iterations).deriveKeyFromPassword(password: password, nonce: salt);
  final box = await AesGcm.with256bits().encrypt(utf8.encode(plain), secretKey: key);
  return _aesBackupPrefix +
      jsonEncode({
        backupProtectionKey: backupProtectionAesGcm,
        'iterations': iterations,
        'salt': base64Encode(salt),
        'nonce': base64Encode(box.nonce),
        'mac': base64Encode(box.mac.bytes),
        'data': base64Encode(box.cipherText),
      });
}

/// Throws on a wrong password
Future<Map<String, dynamic>> decryptBackup(String encoded, String password) async {
  if (!encoded.startsWith(_aesBackupPrefix)) return _decryptXor(encoded, password);
  final envelope = tryDecodeBackupJson(encoded.substring(_aesBackupPrefix.length));
  if (envelope == null || !_isAesEnvelope(envelope)) throw const FormatException('Unsupported backup');

  final iterations = envelope['iterations'];
  if (iterations is! int || iterations < 1 || iterations > backupKdfIterations * 10) {
    throw const FormatException('Unsupported backup');
  }
  final key = await _kdf(
    iterations,
  ).deriveKeyFromPassword(password: password, nonce: base64Decode(envelope['salt'] as String));
  final box = SecretBox(
    base64Decode(envelope['data'] as String),
    nonce: base64Decode(envelope['nonce'] as String),
    mac: Mac(base64Decode(envelope['mac'] as String)),
  );
  final plain = await AesGcm.with256bits().decrypt(box, secretKey: key);
  return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
}

// Backups made before 4.0.0
Map<String, dynamic> _decryptXor(String encoded, String password) {
  final cipher = base64Decode(encoded);
  final keyBytes = utf8.encode(password);
  if (keyBytes.isEmpty) throw const FormatException('Missing decryption key');
  final plain = List<int>.generate(cipher.length, (i) => cipher[i] ^ keyBytes[i % keyBytes.length]);
  return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
}

/// [forImport] also turns every script off
Map<String, dynamic> shareablePrefs(Map<String, dynamic> prefs, {bool forImport = false}) {
  final result = Map<String, dynamic>.from(prefs)..removeWhere((key, _) => shareableExcludedKeys.contains(key));
  if (forImport) return withScriptsDisabled(result);
  return _changeScripts(result, (entry) => entry..['customApiKey'] = '', dropUnreadable: false);
}

/// Unreadable scripts are dropped
Map<String, dynamic> withScriptsDisabled(Map<String, dynamic> prefs) => _changeScripts(prefs, (entry) {
  final script = UserScriptModel.fromJson(entry)..customApiKey = '';
  disableRestoredScript(script);
  return script.toJson();
}, dropUnreadable: true);

Map<String, dynamic> _changeScripts(
  Map<String, dynamic> prefs,
  Map<String, dynamic> Function(Map<String, dynamic> entry) change, {
  required bool dropUnreadable,
}) {
  final result = Map<String, dynamic>.from(prefs);
  final raw = result[_userScriptsKey];
  if (raw is! String || raw.isEmpty) {
    if (dropUnreadable) result.remove(_userScriptsKey);
    return result;
  }

  try {
    final scripts = <Map<String, dynamic>>[];
    for (final entry in _decodeScripts(raw)) {
      if (entry is! Map) continue;
      try {
        scripts.add(change(Map<String, dynamic>.from(entry)));
      } catch (_) {
        continue;
      }
    }
    final encoded = jsonEncode(scripts);
    result[_userScriptsKey] = raw.startsWith(_scriptsB64Prefix)
        ? '$_scriptsB64Prefix${base64Encode(utf8.encode(encoded))}'
        : encoded;
  } catch (_) {
    if (dropUnreadable) result.remove(_userScriptsKey);
  }
  return result;
}

({int? playerId, String apiKey}) _ownerIn(Object? ownDetails) {
  if (ownDetails is! String || ownDetails.isEmpty) return (playerId: null, apiKey: '');
  try {
    final details = jsonDecode(ownDetails) as Map;
    final id = details['player_id'];
    final key = details['userApiKey'];
    return (playerId: id is int ? id : null, apiKey: key is String ? key : '');
  } catch (_) {
    return (playerId: null, apiKey: '');
  }
}

bool isOwnBackup(Map<String, dynamic> backup, String currentOwnDetails) {
  final backupOwner = _ownerIn(backup['pda_ownDetails']);
  if (backupOwner.playerId == null) return false;
  final current = _ownerIn(currentOwnDetails);
  // Fresh installs accept any player
  if (isFreshInstall(currentOwnDetails)) return true;
  return current.playerId == backupOwner.playerId &&
      backupOwner.apiKey.isNotEmpty &&
      backupOwner.apiKey == current.apiKey;
}

bool isFreshInstall(String currentOwnDetails) => _ownerIn(currentOwnDetails).playerId == null;

const int minBackupPasswordLength = 8;
const String backupPasswordTooShortMessage = 'The key needs at least $minBackupPasswordLength characters';

bool isBackupPasswordTooShort(String password) => password.length < minBackupPasswordLength;

bool _isActive(UserScriptModel script) => script.enabled || script.alwaysActive || script.modes.isNotEmpty;

List<String> scriptsUsingApiKey(Map<String, dynamic> prefs, {bool onlyActive = false}) => _scriptNames(
  prefs,
  (script) => script.source.contains(apiKeyPlaceholder) && (!onlyActive || _isActive(script)),
);

List<String> activeScripts(Map<String, dynamic> prefs) => _scriptNames(prefs, _isActive);

List<String> _scriptNames(Map<String, dynamic> prefs, bool Function(UserScriptModel script) keep) {
  final raw = prefs[_userScriptsKey];
  if (raw is! String || raw.isEmpty) return const [];
  final names = <String>[];
  try {
    for (final entry in _decodeScripts(raw)) {
      if (entry is! Map) continue;
      try {
        final script = UserScriptModel.fromJson(Map<String, dynamic>.from(entry));
        if (keep(script)) names.add(script.name);
      } catch (_) {
        continue;
      }
    }
  } catch (_) {
    return const [];
  }
  return names;
}

List<dynamic> _decodeScripts(String raw) {
  final json = raw.startsWith(_scriptsB64Prefix)
      ? utf8.decode(base64Decode(raw.substring(_scriptsB64Prefix.length)))
      : raw;
  final decoded = jsonDecode(json);
  if (decoded is! List) throw const FormatException('Scripts are not a list');
  return decoded;
}
