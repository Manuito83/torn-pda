import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:torn_pda/models/territory_map/assault_locks.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/models/territory_map/faction_colors.dart';
import 'package:torn_pda/models/territory_map/faction_graph.dart';
import 'package:torn_pda/models/territory_map/map_pictures.dart';
import 'package:torn_pda/models/territory_map/map_state.dart' as map_state;
import 'package:torn_pda/models/territory_map/map_state.dart' show MapState;
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/models/territory_map/surroundings_quality.dart';
import 'package:torn_pda/models/territory_map/surroundings_relief.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/models/territory_map/territory_index.dart';
import 'package:torn_pda/providers/faction_flights_controller.dart';
import 'package:torn_pda/providers/territory_map_switches.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/utils/memory_info.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/territory_map/territory_map_files.dart';

const _forcedQuality = String.fromEnvironment('TERRITORY_MAP_QUALITY');
const _refreshEvery = Duration(minutes: 2);
const _refreshIfOlderThan = Duration(seconds: 60);
const _locksEvery = Duration(minutes: 1);

class TerritoryMapController extends ChangeNotifier with TerritoryMapSwitches {
  TerritoryMapController({TerritoryMapFiles? files}) : _files = files ?? TerritoryMapFiles();

  final TerritoryMapFiles _files;
  final _prefs = Prefs();
  final lastFlights = LastFlightsAnswer();

  TerritoryFile? territories;
  Map<String, Path> paths = const {};

  // Only those on the city edge
  Map<String, Path> outlines = const {};
  TerritoryIndex? index;
  Map<int, int> colors = const {};
  Map<int, List<String>> owned = const {};

  // Neighbor factions today, not the past day
  Map<int, Set<int>> borders = const {};
  String? lastError;
  String? selected;
  int? openFaction;
  int? openWar;
  int? highlighted;
  int myFactionId = 0;
  Set<String> locked = const {};

  // Bumped when shapes or owners change
  int dataVersion = 0;

  // Null in the normal view
  Map<String, Shade>? shades;

  // Set while looking at a past day
  DateTime? pastDay;
  Map<String, map_state.Ownership>? _pastOwners;
  Map<int, int> _presentColors = const {};

  Rect? focus;
  int focusRequest = 0;

  Future<void>? _loading;
  Timer? _refreshTimer;
  Timer? _locksTimer;
  final _openPages = <Object>{};
  final _cityPages = <Object>{};
  bool _refreshing = false;
  DateTime? _savedAt;
  String _etag = '';

  MapState? _serverState;
  CityPageData? _page;
  MapState? _pageState;

  MapState? get state => _pageState ?? _serverState;

  bool get ready => territories != null;

  bool get refreshing => _refreshing;

  // Our own ground, loaded by the map
  CityGround? ground;
  List<GroundCell> groundCells = const [];
  Surroundings? surroundings;
  SurroundingsQuality surroundingsQuality = SurroundingsQuality.full;
  List<StripCell> stripCells = const [];
  Map<String, ClosurePath> closurePaths = const {};
  Future<void>? _groundLoading;
  Relief? relief;
  Future<void>? _reliefLoading;

  bool get sample => _files.sample;

  DateTime? get dataTime => state == null ? null : map_state.dataTime(state!);

  bool get isStale => state == null || map_state.isStale(state!, DateTime.now().toUtc());

  Map<String, map_state.Ownership> get displayOwnership => _pastOwners ?? state?.ownership ?? const {};

  List<map_state.TerritoryWar> get shownWars =>
      pastDay == null && showsAssaults(view) ? state?.wars ?? const [] : const [];

  MapView get shownView => viewForDay(view, past: pastDay != null);

  bool get overCity => _cityPages.isNotEmpty;

  void openCity(Object page) {
    _cityPages.add(page);
    showPast(null, null, notify: false);
    notifyListeners();
  }

  void closeCity(Object page) {
    if (!_cityPages.remove(page) || _cityPages.isNotEmpty) return;
    // The page behind repaints the present
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  void showPast(DateTime? day, Map<String, map_state.Ownership>? owners, {bool notify = true, bool inCity = false}) {
    if (owners != null && overCity && !inCity) return;
    if (owners == null && _pastOwners == null) return;
    pastDay = owners == null ? null : day;
    _pastOwners = owners;
    _colorDisplay();
    if (notify) notifyListeners();
  }

  Future<void> open(Object page, {required int myFactionId}) async {
    _openPages.add(page);
    if (this.myFactionId != myFactionId) {
      this.myFactionId = myFactionId;
      _recolor();
    }
    await (_loading ??= _load());
    if (_openPages.isEmpty || _refreshTimer != null) return;

    final savedAt = _savedAt;
    if (savedAt == null || DateTime.now().difference(savedAt) > _refreshIfOlderThan) unawaited(refresh());
    _refreshTimer = Timer.periodic(_refreshEvery, (_) => refresh());
    _locksTimer = Timer.periodic(_locksEvery, (_) {
      if (_updateLocks()) notifyListeners();
    });
  }

  // Also waits for a first state
  Future<void> openWithState(Object page, {required int myFactionId, required Duration timeout}) async {
    await open(page, myFactionId: myFactionId).timeout(timeout);
    if (state != null) return;
    final done = Completer<void>();
    void check() {
      if (!done.isCompleted && (state != null || (lastError != null && !_refreshing))) done.complete();
    }

    addListener(check);
    if (!_refreshing) unawaited(refresh());
    check();
    return done.future.timeout(timeout).whenComplete(() => removeListener(check));
  }

  void close(Object page) {
    _openPages.remove(page);
    if (_openPages.isNotEmpty) return;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _locksTimer?.cancel();
    _locksTimer = null;
  }

  // Locks expire without a new state
  bool _updateLocks() {
    final current = state;
    final fresh = current == null ? const <String>{} : lockedCodes(current, DateTime.now().toUtc());
    if (setEquals(fresh, locked)) return false;
    locked = fresh;
    return true;
  }

  void select(String? code) {
    selected = code;
    openFaction = null;
    openWar = null;
    if (code == null) highlighted = null;
    notifyListeners();
  }

  void showFaction(int? factionId) {
    openFaction = factionId;
    if (factionId != null) openWar = null;
    if (factionId == null) highlighted = null;
    notifyListeners();
  }

  // Closing it goes back to the territory
  void showWar(int? warId) {
    openWar = warId;
    notifyListeners();
  }

  void focusTerritory(String code) {
    final territory = territories?.territories[code];
    if (territory == null) return;
    selected = code;
    openFaction = null;
    openWar = null;
    _focusOn(territory.bounds);
  }

  // False when the faction holds nothing
  bool focusFaction(int factionId, {bool highlight = true}) {
    final file = territories;
    final area = file == null ? null : boundsOf(owned[factionId] ?? const [], file.territories);
    if (area == null) return false;
    if (highlight) highlighted = factionId;
    _focusOn(area);
    return true;
  }

  void focusPoint(Offset point) => _focusOn(Rect.fromCenter(center: point, width: 200, height: 200));

  void _focusOn(Rect area) {
    focus = area;
    focusRequest++;
    notifyListeners();
  }

  // Fresher owners and rackets from city.php
  void showPage(CityPageData page) {
    _page = page;
    _applyPage();
    notifyListeners();
  }

  void hidePage(CityPageData page) {
    if (_page != page) return;
    _page = null;
    _applyPage();
    notifyListeners();
  }

  void _applyPage() {
    final page = _page;
    _pageState = page == null ? null : pageStateFor(_serverState, page);
    _updateLocks();
    _recolor();
  }

  Future<CityMesh>? _mesh;
  TerritoryFile? _meshFile;

  // Tops and walls for 3D, once per file
  Future<CityMesh> cityMesh(TerritoryFile file) {
    if (!identical(file, _meshFile)) {
      final mesh = compute(buildCityMesh, file);
      _meshFile = file;
      _mesh = mesh;
      unawaited(
        mesh.then(
          (_) {},
          onError: (_) {
            if (!identical(_mesh, mesh)) return;
            _mesh = null;
            _meshFile = null;
          },
        ),
      );
    }
    return _mesh!;
  }

  // City ground and what lies around it
  Future<void> loadGround() => _groundLoading ??= () async {
    try {
      final loaded = await _files.readBundledGround();
      groundCells = buildGroundCells(loaded);
      ground = loaded;
    } catch (e) {
      debugPrint('territory map: ground unreadable: $e');
    }
    try {
      final loaded = await _files.readBundledSurroundings();
      stripCells = buildStripCells(loaded);
      closurePaths = buildClosurePaths(loaded);
      final memory = await MemoryInfo.getDeviceMemoryInfo();
      surroundingsQuality =
          SurroundingsQuality.values.asNameMap()[_forcedQuality] ??
          surroundingsQualityFor(memory?['totalMem'], exact: Platform.isIOS);
      surroundings = loaded;
    } catch (e) {
      debugPrint('territory map: surroundings unreadable: $e');
    }
    notifyListeners();
  }();

  // Only the 3D view needs heights
  Future<void> loadRelief() => _reliefLoading ??= () async {
    try {
      relief = await _files.readBundledRelief();
    } catch (e) {
      debugPrint('territory map: relief unreadable: $e');
    }
    notifyListeners();
  }();

  Future<Uint8List> surroundingsPhoto(String name) => _files.readSurroundingsPhoto(name);

  Future<void> retry() async {
    lastError = null;
    notifyListeners();
    await (_loading ??= _load());
    await refresh();
  }

  Future<void> _load() async {
    var version = 0;
    try {
      final (etag, savedAt, savedVersion, _) = await (
        _prefs.getTerritoryMapStateEtag(),
        _prefs.getTerritoryMapStateSavedAt(),
        _prefs.getTerritoryMapVersion(),
        loadSwitches(),
      ).wait;
      _etag = etag;
      _savedAt = savedAt == 0 ? null : DateTime.fromMillisecondsSinceEpoch(savedAt);
      version = savedVersion;
    } catch (e) {
      debugPrint('territory map: saved settings unreadable: $e');
    }

    TerritoryFile? file;
    if (version > bundledTerritoriesVersion) {
      try {
        final cached = await _files.readCached(territoriesFileName(version));
        if (cached != null) file = await _files.decodeTerritories(cached);
      } catch (e) {
        debugPrint('territory map: saved shapes unreadable: $e');
        lastError = 'saved shapes unreadable';
      }
    }
    try {
      file ??= await _files.decodeTerritories(await _files.readBundledTerritories());
    } catch (e) {
      debugPrint('territory map: shapes unreadable: $e');
      countMapFailure(MapFailure.state);
      lastError = 'shapes unreadable';
      _loading = null;
      notifyListeners();
      return;
    }

    try {
      final cached = await _files.readCached(stateFileName);
      if (cached != null) _serverState = await _files.decodeState(cached);
    } catch (e) {
      _savedAt = null;
      _etag = '';
      debugPrint('territory map: saved data unreadable: $e');
      lastError = 'saved data unreadable';
    }

    _setTerritories(file);
    _applyPage();
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_refreshing || territories == null) return;
    _refreshing = true;
    // Later refreshes must not rebuild the map
    if (_serverState == null || lastError != null) notifyListeners();
    try {
      final download = await _files.fetchState(_serverState == null ? '' : _etag);
      final bytes = download.bytes;
      if (bytes != null) {
        final fresh = await _files.decodeState(bytes);
        await _files.writeCached(stateFileName, bytes);
        _etag = download.etag;
        await _prefs.setTerritoryMapStateEtag(_etag);
        final before = state;
        _serverState = fresh;
        _pageState = _page == null ? null : pageStateFor(fresh, _page!);
        _updateLocks();
        if (before == null || !map_state.sameOwners(before.ownership, state!.ownership)) {
          _recolor();
        } else {
          _reshade();
        }
      }
      _savedAt = DateTime.now();
      await _prefs.setTerritoryMapStateSavedAt(_savedAt!.millisecondsSinceEpoch);
      lastError = null;

      final wanted = state?.territoriesVersion ?? 0;
      if (wanted > territories!.version) await _updateTerritories(wanted);
    } catch (e) {
      debugPrint('territory map: refresh failed: $e');
      // Offline refreshes repeat, count the first
      if (lastError == null) countMapFailure(MapFailure.state);
      lastError = e is HttpException ? e.message : 'download failed';
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  // Old shapes stay until these parse
  Future<void> _updateTerritories(int version) async {
    final bytes = await _files.fetchTerritories(version);
    final file = await _files.decodeTerritories(bytes);
    await _files.writeCached(territoriesFileName(version), bytes);
    await _prefs.setTerritoryMapVersion(version);
    _setTerritories(file);
  }

  void _setTerritories(TerritoryFile file) {
    territories = file;
    paths = {for (final t in file.territories.values) t.code: buildTerritoryPath(t)};
    outlines = {
      for (final t in file.territories.values)
        if (buildTerritoryOutline(t, file.bounds) case final outline?) t.code: outline,
    };
    index = TerritoryIndex(file.territories.values, paths);
    if (selected != null && !file.territories.containsKey(selected)) selected = null;
    _recolor();
  }

  void _recolor() {
    final file = territories;
    final current = state;
    if (file != null && current != null) {
      _presentColors = assignFactionColors(current.ownership, file.territories, myFactionId: myFactionId);
      borders = factionAdjacency(current.ownership, file.territories);
    }
    _colorDisplay();
  }

  // Factions still around keep their color
  void _colorDisplay() {
    final file = territories;
    final past = _pastOwners;
    colors = file == null || past == null
        ? _presentColors
        : assignFactionColors(past, file.territories, myFactionId: myFactionId, keep: _presentColors);
    owned = territoriesOf(displayOwnership);
    shades = _viewShades();
    dataVersion++;
  }

  @override
  void viewChanged() {
    shades = _viewShades();
    dataVersion++;
  }

  // Wars and rackets change without new owners
  void _reshade() {
    final fresh = _viewShades();
    if (mapEquals(fresh, shades)) return;
    shades = fresh;
    dataVersion++;
  }

  Map<String, Shade>? _viewShades() => viewShades(
    shownView,
    ownership: displayOwnership,
    wars: shownWars,
    rackets: state?.rackets ?? const {},
    territories: territories?.territories ?? const {},
  );
}
