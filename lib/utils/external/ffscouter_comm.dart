import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:torn_pda/utils/telemetry_sanitize.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_activity_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_bounty_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_flights_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_hit_calling_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_key_models.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_notes_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_stats_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';

class FFScouterResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int? errorCode;
  final int? retryAfterSeconds;

  FFScouterResult({required this.success, this.data, this.errorMessage, this.errorCode, this.retryAfterSeconds});
}

class FFScouterComm {
  static const String _baseUrl = 'https://ffscouter.com/api/v1';
  static const int _referrerPlayerId = 2225097;

  static void _logError(String method, Object e, StackTrace stackTrace) {
    log("FFScouterComm.$method error: $e");
    if (e is SocketException || e is http.ClientException || e is HandshakeException) return;
    FirebaseCrashlytics.instance.recordError(redactUrlQueries("FFScouter $method error: $e"), stackTrace);
  }

  static FFScouterResult<T> _errorResult<T>(http.Response response) {
    try {
      final error = FFScouterErrorResponse.fromJson(json.decode(response.body));
      return FFScouterResult(
        success: false,
        errorMessage: error.displayMessage,
        errorCode: error.code,
        retryAfterSeconds: error.retryAfterSeconds,
      );
    } catch (_) {
      return FFScouterResult(success: false, errorMessage: "FFScouter error (HTTP ${response.statusCode})");
    }
  }

  static Future<FFScouterResult<T>> _send<T>(
    String method,
    Future<http.Response> Function() request,
    T Function(dynamic decoded) parse, {
    int timeout = 15,
  }) async {
    try {
      final response = await request().timeout(Duration(seconds: timeout));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return FFScouterResult(success: true, data: parse(json.decode(response.body)));
      }
      return _errorResult(response);
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      _logError(method, e, stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  static Uri _uri(String path, String key, [Map<String, String> params = const {}]) =>
      Uri.parse('$_baseUrl/$path').replace(queryParameters: {'key': key, ...params});

  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  /// Fetches battle stats estimates for up to 205 targets at once
  /// Rate limit: 120 requests per minute
  static Future<FFScouterResult<List<FFScouterPlayerStats>>> getStats({
    required String key,
    required List<int> targetIds,
    int timeout = 20,
  }) async {
    try {
      if (targetIds.isEmpty || targetIds.length > 205) {
        return FFScouterResult(success: false, errorMessage: "Target list must contain between 1 and 205 IDs");
      }

      final targetsParam = targetIds.join(',');
      final uri = Uri.parse('$_baseUrl/get-stats?key=$key&targets=$targetsParam');

      final response = await http.get(uri).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final stats = ffScouterStatsFromJson(response.body);
        return FFScouterResult(success: true, data: stats);
      } else {
        return _errorResult(response);
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      _logError("getStats", e, stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  /// Fetches recommended targets based on filter criteria
  /// Rate limit: 25 requests per minute
  static Future<FFScouterResult<FFScouterTargetsResponse>> getTargets({
    required String key,
    String? preset,
    int? minLevel,
    int? maxLevel,
    int? inactiveOnly,
    double? minFf,
    double? maxFf,
    int? limit,
    int? factionless,
    int timeout = 20,
  }) async {
    try {
      final queryParams = <String, String>{'key': key};

      if (preset != null) {
        queryParams['preset'] = preset;
      } else {
        if (minLevel != null) queryParams['minlevel'] = minLevel.toString();
        if (maxLevel != null) queryParams['maxlevel'] = maxLevel.toString();
        if (inactiveOnly != null) queryParams['inactiveonly'] = inactiveOnly.toString();
        if (minFf != null) queryParams['minff'] = minFf.toStringAsFixed(2);
        if (maxFf != null) queryParams['maxff'] = maxFf.toStringAsFixed(2);
        if (factionless != null) queryParams['factionless'] = factionless.toString();
      }

      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$_baseUrl/get-targets').replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = ffScouterTargetsFromJson(response.body);
        return FFScouterResult(success: true, data: data);
      } else {
        return _errorResult(response);
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      _logError("getTargets", e, stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  /// Checks whether an API key is registered with FFScouter
  /// Rate limit: 20 requests per minute
  static Future<FFScouterResult<FFScouterCheckKeyResponse>> checkKey({required String key, int timeout = 15}) async {
    try {
      final uri = Uri.parse('$_baseUrl/check-key?key=$key');
      final response = await http.get(uri).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = ffScouterCheckKeyFromJson(response.body);
        return FFScouterResult(success: true, data: data);
      } else {
        return _errorResult(response);
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      _logError("checkKey", e, stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  /// Registers an API key with FFScouter
  /// Rate limit: 10 requests per minute
  /// IMPORTANT: The user MUST have agreed to FFScouter's data policy and terms
  static Future<FFScouterResult<FFScouterRegisterResponse>> registerKey({required String key, int timeout = 20}) async {
    try {
      final uri = Uri.parse('$_baseUrl/register');
      final body = json.encode({'key': key, 'agree_to_data_policy': true, 'signup_source': 'TornPDA'});

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = ffScouterRegisterFromJson(response.body);
        return FFScouterResult(success: true, data: data);
      } else {
        return _errorResult(response);
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      _logError("registerKey", e, stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  /// Per-player activity buckets (premium), bucket = 300/900/3600
  static Future<FFScouterResult<FFScouterActivityResponse>> getActivityPlayer({
    required String key,
    required int target,
    required int start,
    required int end,
    int bucket = 900,
    int timeout = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/activity/player').replace(
        queryParameters: {
          'key': key,
          'target': target.toString(),
          'start': start.toString(),
          'end': end.toString(),
          'bucket': bucket.toString(),
        },
      );
      final response = await http.get(uri).timeout(Duration(seconds: timeout));
      if (response.statusCode == 200) {
        return FFScouterResult(success: true, data: ffScouterActivityFromJson(response.body));
      } else {
        return _errorResult(response);
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      _logError("getActivityPlayer", e, stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  /// Faction activity buckets (premium), bucket = 300/900/3600
  static Future<FFScouterResult<FFScouterActivityResponse>> getActivityFaction({
    required String key,
    required int factionId,
    required int start,
    required int end,
    int bucket = 3600,
    int timeout = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/activity/faction').replace(
        queryParameters: {
          'key': key,
          'faction_id': factionId.toString(),
          'start': start.toString(),
          'end': end.toString(),
          'bucket': bucket.toString(),
        },
      );
      final response = await http.get(uri).timeout(Duration(seconds: timeout));
      if (response.statusCode == 200) {
        return FFScouterResult(success: true, data: ffScouterActivityFromJson(response.body));
      } else {
        return _errorResult(response);
      }
    } on TimeoutException {
      return FFScouterResult(success: false, errorMessage: "Request timed out, please try again");
    } catch (e, stackTrace) {
      _logError("getActivityFaction", e, stackTrace);
      return FFScouterResult(success: false, errorMessage: "Error contacting FFScouter: $e");
    }
  }

  static Future<FFScouterResult<List<FFScouterFlightsResponse>>> getPlayerFlightsBatch({
    required String key,
    required List<int> targets,
  }) {
    return _send(
      "getPlayerFlightsBatch",
      () => http.get(_uri('player-flights/batch', key, {'targets': targets.join(',')})),
      ffScouterFlightsBatchFromJson,
    );
  }

  static Future<FFScouterResult<FFScouterStatsHistory>> getStatsHistory({
    required String key,
    required int target,
    int limit = 100,
  }) {
    return _send(
      "getStatsHistory",
      () => http.get(_uri('get-stats-history', key, {'target': '$target', 'limit': '$limit'})),
      (decoded) => FFScouterStatsHistory.fromJson(decoded),
    );
  }

  static Future<FFScouterResult<FFScouterNotesPage>> getNotes({
    required String key,
    List<int>? targets,
    int? playerId,
    int page = 1,
  }) {
    final params = <String, String>{'page': '$page', 'limit': '100'};
    if (playerId != null) {
      params['target_type'] = 'player';
      params['target_id'] = '$playerId';
    } else if (targets != null) {
      params['targets'] = targets.join(',');
    }
    return _send(
      "getNotes",
      () => http.get(_uri('notes', key, params)),
      (decoded) => FFScouterNotesPage.fromJson(decoded),
    );
  }

  static Future<FFScouterResult<FFScouterNotesInfo>> getNotesInfo({required String key}) {
    return _send(
      "getNotesInfo",
      () => http.get(_uri('notes/info', key)),
      (decoded) => FFScouterNotesInfo.fromJson(decoded),
    );
  }

  static Future<FFScouterResult<FFScouterNote>> createNote({
    required String key,
    required int playerId,
    required String scope,
    required String content,
  }) {
    final body = json.encode({'scope': scope, 'target_type': 'player', 'target_id': playerId, 'content': content});
    return _send(
      "createNote",
      () => http.post(_uri('notes', key), headers: _jsonHeaders, body: body),
      (decoded) => FFScouterNote.fromJson((decoded["note"] as Map).cast()),
    );
  }

  static Future<FFScouterResult<bool>> deleteNote({required String key, required String uuid}) {
    return _send("deleteNote", () => http.post(_uri('notes/$uuid/delete', key)), (_) => true);
  }

  static Future<FFScouterResult<FFScouterHitClaims>> getHitClaims({required String key}) {
    return _send(
      "getHitClaims",
      () => http.get(_uri('hit-calling/claims', key)),
      (decoded) => FFScouterHitClaims.fromJson(decoded),
    );
  }

  static Future<FFScouterResult<FFScouterHitClaimResult>> claimHit({required String key, required int target}) {
    return _send(
      "claimHit",
      () => http.post(
        _uri('hit-calling/claim', key),
        headers: _jsonHeaders,
        body: json.encode({'key': key, 'target_player_id': target}),
      ),
      (decoded) => FFScouterHitClaimResult.fromJson(decoded),
    );
  }

  static Future<FFScouterResult<bool>> unclaimHit({required String key, required int target}) {
    return _send(
      "unclaimHit",
      () => http.post(
        _uri('hit-calling/unclaim', key),
        headers: _jsonHeaders,
        body: json.encode({'target_player_id': target}),
      ),
      (_) => true,
    );
  }

  static Future<FFScouterResult<bool>> wipeHitClaims({required String key}) {
    return _send(
      "wipeHitClaims",
      () => http.post(_uri('hit-calling/wipe', key), headers: _jsonHeaders, body: json.encode({'key': key})),
      (_) => true,
    );
  }

  static Future<FFScouterResult<FFScouterBountyBoard>> getBountyBoard({required String key}) {
    return _send(
      "getBountyBoard",
      () => http.get(_uri('bounties/seller/board', key)),
      (decoded) => FFScouterBountyBoard.fromJson(decoded),
    );
  }

  static Future<FFScouterResult<bool>> acceptBountyPolicy({required String key}) {
    return _send(
      "acceptBountyPolicy",
      () => http.post(
        Uri.parse('$_baseUrl/bounties/seller/policy/accept'),
        headers: _jsonHeaders,
        body: json.encode({'key': key, 'i_have_read_rules_and_data_policy': true}),
      ),
      (decoded) => decoded is Map && decoded["ok"] == true,
    );
  }

  static Future<FFScouterResult<FFScouterBountyClaims>> claimBounty({
    required String key,
    required int target,
    int? monitoringStartedAt,
  }) {
    return _send(
      "claimBounty",
      () => http.post(
        Uri.parse('$_baseUrl/bounties/seller/claims'),
        headers: _jsonHeaders,
        body: json.encode({
          'key': key,
          'target_player_id': target,
          if (monitoringStartedAt != null) 'monitoring_started_at': monitoringStartedAt,
          'referrer_player_id': _referrerPlayerId,
        }),
      ),
      (decoded) => FFScouterBountyClaims.fromJson((decoded["claims"] as Map).cast()),
    );
  }

  static Future<FFScouterResult<FFScouterBountyQuote>> quoteBounty({required int quantity, required int pricePerHit}) {
    return _send(
      "quoteBounty",
      () => http.get(
        Uri.parse(
          '$_baseUrl/bounties/orders/quote',
        ).replace(queryParameters: {'quantity': '$quantity', 'price_per_hit': '$pricePerHit'}),
      ),
      (decoded) => FFScouterBountyQuote.fromJson(decoded),
    );
  }

  static Future<FFScouterResult<FFScouterBountyNewOrder>> orderBounty({
    required int target,
    required int quantity,
    required int pricePerHit,
  }) {
    return _send(
      "orderBounty",
      () => http.post(
        Uri.parse('$_baseUrl/bounties/orders'),
        headers: _jsonHeaders,
        body: json.encode({
          'target_player_id': target,
          'quantity': quantity,
          'price_per_hit': pricePerHit,
          'referrer_player_id': _referrerPlayerId,
        }),
      ),
      (decoded) => FFScouterBountyNewOrder.fromJson(decoded),
    );
  }

  static Future<FFScouterResult<FFScouterBountyOrderStatus>> getBountyOrder({required String token}) {
    return _send(
      "getBountyOrder",
      () => http.get(Uri.parse('$_baseUrl/bounties/orders/$token')),
      (decoded) => FFScouterBountyOrderStatus.fromJson(decoded),
    );
  }
}
