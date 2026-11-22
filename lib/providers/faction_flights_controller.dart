import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:torn_pda/models/api_v2/torn_v2.enums.swagger.dart' as enums;
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/models/territory_map/world_land.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/flights_sharing.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart' show readNativeApiToken;
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/user_helper.dart';

const _worldLandAsset = 'assets/territory_map/world-land-110m.json.bin';
const _worldNamesAsset = 'assets/territory_map/world-names.json.bin';
const _membersTimeout = Duration(seconds: 15);
const _answerTimeout = Duration(seconds: 35);
const _shareReadTimeout = Duration(seconds: 25);
const _shareWriteTimeout = Duration(seconds: 30);
const _noKeyNote = 'Add your API key to see flights';
const _noFactionNote = 'You are not in a faction';
const _noTimesError = 'Could not get arrival times';
const _noLoginNote = 'Sign in at Settings > Torn Authentication to see arrival times';
const _shareNoLoginNote = 'Sign in at Settings > Torn Authentication to share';

// Just over the server's limit per player
const _answerFreshFor = Duration(seconds: 65);

// Where the data comes from
class FlightsSource {
  const FlightsSource();

  // Why nothing can be asked, if so
  String? get blocked => UserHelper.apiKey.isEmpty
      ? _noKeyNote
      : UserHelper.factionId == 0
      ? _noFactionNote
      : null;

  int get playerId => UserHelper.playerId;

  // Null when Torn doesn't answer
  Future<FactionFlights?> members() async {
    final response = await Get.find<ApiCallerController>().enqueueApiCall<dynamic>(
      apiSelection_v2: ApiSelection_v2.factionMembers,
      apiCall: (client, apiKey) => client.factionMembersGet(striptags: enums.ApiStripTagsTrue.$true),
    );
    if (response is! FactionMembersResponse) return null;
    return flightsFromMembers(
      response.members.map((m) => (id: m.id, name: m.name, state: m.status.state, description: m.status.description)),
    );
  }

  Future<bool> loggedIn() async => await readNativeApiToken() != null;

  Future<FlightsAnswer> answer() async {
    final token = await readNativeApiToken();
    if (token == null) return (kind: FlightsAnswerKind.noLogin, flights: null, retryIn: 0);
    return readFlightsAnswer(await firebaseFunctions.getFactionFlights(token));
  }

  // Null without a Torn login
  Future<bool?> readShare() async {
    await retryStopSharingFlights();
    return readFlightSharing();
  }

  Future<bool?> writeShare(bool share) => writeFlightSharing(share);

  Future<WorldLand> land() async {
    final land = await rootBundle.load(_worldLandAsset);
    final names = await rootBundle.load(_worldNamesAsset);
    return compute(_readWorld, (
      land.buffer.asUint8List(land.offsetInBytes, land.lengthInBytes),
      names.buffer.asUint8List(names.offsetInBytes, names.lengthInBytes),
    ));
  }
}

WorldLand _readWorld((Uint8List, Uint8List) bytes) => worldLandFromGzip(bytes.$1, names: bytes.$2);

// Outlives the page, like the server's limit
class LastFlightsAnswer {
  FactionFlights? flights;
  DateTime? at;
  int? playerId;
}

class FactionFlightsController extends ChangeNotifier {
  FactionFlightsController({this.source = const FlightsSource(), LastFlightsAnswer? last})
    : _last = last ?? LastFlightsAnswer();

  final FlightsSource source;
  final LastFlightsAnswer _last;

  FactionFlights? flights;
  WorldLand? land;

  bool _countAsked = false;
  bool membersLoading = false;
  bool membersFailed = false;

  bool answerLoading = false;
  String? answerError;
  String? answerNote;

  bool? share;
  bool shareBusy = false;
  String? shareError;

  // A member or a country, never both
  int? selected;
  int focusRequest = 0;
  String? place;
  int placeFocus = 0;

  bool _disposed = false;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Empty button without key or faction
  int? get flyingNow {
    final known = flights;
    return known == null ? null : flightsAt(known, DateTime.now().millisecondsSinceEpoch ~/ 1000).flying.length;
  }

  bool get _answerFresh {
    final at = _last.at;
    return at != null && _last.playerId == source.playerId && DateTime.now().difference(at) < _answerFreshFor;
  }

  // One Torn call for each map open
  Future<void> loadCount() async {
    if (_countAsked || source.blocked != null) return;
    _countAsked = true;
    if (_answerFresh) {
      flights = _last.flights;
      _changed();
      return;
    }
    membersLoading = true;
    _changed();
    FactionFlights? read;
    try {
      read = await source.members().timeout(_membersTimeout);
    } catch (e) {
      debugPrint('faction flights: members failed: $e');
    }
    membersLoading = false;
    membersFailed = read == null;
    if (membersFailed) countMapUse(mapFlightsButtonFailFeature);
    // The sheet's answer has the times
    if (!_answerFresh && read != null) flights = read;
    _changed();
  }

  // Sheet opened
  Future<void> open() async {
    countMapUse(mapFlightsOpenFeature);
    selected = null;
    place = null;
    unawaited(_loadLand());
    answerNote = source.blocked;
    if (answerNote != null) {
      _changed();
      return;
    }
    if (_answerFresh) {
      flights = _last.flights;
      _changed();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (answerLoading) return;
    answerLoading = true;
    answerError = null;
    answerNote = null;
    _changed();
    try {
      final answer = await source.answer().timeout(_answerTimeout);
      switch (answer.kind) {
        case FlightsAnswerKind.ok:
          flights = answer.flights;
          _last
            ..flights = flights
            ..at = DateTime.now()
            ..playerId = source.playerId;
        case FlightsAnswerKind.noLogin:
          answerNote = _noLoginNote;
        case FlightsAnswerKind.noKey:
          answerNote = _noKeyNote;
        case FlightsAnswerKind.noFaction:
          flights = null;
          _last
            ..flights = null
            ..at = null;
          answerNote = _noFactionNote;
        case FlightsAnswerKind.limited:
          answerError = 'Too soon, try again in ${answer.retryIn} s';
        case FlightsAnswerKind.tornError || FlightsAnswerKind.unreadable:
          answerError = _noTimesError;
          countMapFailure(MapFailure.flights);
      }
    } catch (e) {
      debugPrint('faction flights: answer failed: $e');
      answerError = _noTimesError;
      countMapFailure(MapFailure.flights);
    }
    answerLoading = false;
    _changed();
  }

  Future<void> _loadLand() async {
    if (land != null) return;
    try {
      land = await source.land();
      _changed();
    } catch (e) {
      debugPrint('faction flights: land unreadable: $e');
    }
  }

  void select(int id, {bool focus = false}) {
    countMapUse(mapFlightsTapFeature);
    selected = id;
    place = null;
    if (focus) focusRequest++;
    _changed();
  }

  void selectPlace(String? value, {bool focus = false}) {
    place = value;
    if (value != null) selected = null;
    if (focus) placeFocus++;
    _changed();
  }

  Future<void> loadShare() async {
    if (share != null || shareBusy) return;
    shareBusy = true;
    shareError = null;
    _changed();
    try {
      share = await source.readShare().timeout(_shareReadTimeout);
      if (share == null) shareError = _shareNoLoginNote;
    } catch (e) {
      debugPrint('faction flights: share unreadable: $e');
      shareError = 'Could not read this setting';
    }
    shareBusy = false;
    _changed();
  }

  Future<void> setShare(bool value) async {
    if (shareBusy) return;
    shareBusy = true;
    shareError = null;
    _changed();
    if (value && !await source.loggedIn()) {
      shareError = _shareNoLoginNote;
      shareBusy = false;
      _changed();
      return;
    }
    bool? saved;
    try {
      saved = await source.writeShare(value).timeout(_shareWriteTimeout);
    } catch (e) {
      debugPrint('faction flights: share not saved: $e');
    }
    if (saved == true) {
      share = value;
      countMapUse(value ? mapFlightsShareOnFeature : mapFlightsShareOffFeature);
    } else if (saved == false) {
      shareError = 'Could not save, try again';
    } else {
      shareError = 'Could not save, reopen to check';
      // May have saved, read it next open
      share = null;
    }
    shareBusy = false;
    _changed();
  }
}
