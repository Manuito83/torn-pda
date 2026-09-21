// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/models/inventory/inventory_v2_model.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

typedef InventoryCategoryFetcher = Future<InventoryV2Category?> Function(String category, {required bool withDisplay});
typedef InventoryStoreReader = Future<String> Function();
typedef InventoryStoreWriter = Future<void> Function(String value);

class InventoryProvider extends ChangeNotifier {
  InventoryProvider({
    InventoryCategoryFetcher? fetcher,
    DateTime Function()? now,
    InventoryStoreReader? readStore,
    InventoryStoreWriter? writeStore,
  }) : _fetcher = fetcher ?? _fetchFromApi,
       _now = now ?? DateTime.now,
       _readStore = readStore ?? _readFromPrefs,
       _writeStore = writeStore ?? _writeToPrefs;

  static const List<String> apiCategories = [
    "Collectible",
    "Clothing",
    "Other",
    "Tool",
    "Melee",
    "Defensive",
    "Material",
    "Car",
    "Primary",
    "Secondary",
    "Book",
    "Special",
    "Supply Pack",
    "Temporary",
    "Enhancer",
    "Artifact",
    "Flower",
    "Booster",
    "Medical",
    "Candy",
    "Jewelry",
    "Alcohol",
    "Plushie",
    "Drug",
    "Energy Drink",
  ];

  static const int _cacheSeconds = 3600;

  final InventoryCategoryFetcher _fetcher;
  final DateTime Function() _now;
  final InventoryStoreReader _readStore;
  final InventoryStoreWriter _writeStore;

  late final Future<void> restored = _restore();

  Timer? _saveTimer;

  final Map<String, InventoryV2Category> _categories = {};
  final Map<String, DateTime> _loadedAt = {};
  final Set<String> _failed = {};
  final Map<String, Future<void>> _running = {};

  List<InventoryV2DisplayItem>? _display;
  DateTime? _displayLoadedAt;
  bool _displayRequested = false;

  static Future<String> _readFromPrefs() => Prefs().getInventoryCache();
  static Future<void> _writeToPrefs(String raw) async => Prefs().setInventoryCache(raw);

  static Future<InventoryV2Category?> _fetchFromApi(String category, {required bool withDisplay}) async {
    final response = await ApiCallsV2.getUserInventory_v2(cat: category, withDisplay: withDisplay);
    if (response is InventoryV2Category) return response;
    if (response is ApiError) {
      log("Inventory category $category failed: ${response.errorReason}");
    }
    return null;
  }

  bool loaded(String category) => _categories.containsKey(category);

  bool failed(String category) => _failed.contains(category);

  bool get loading => _running.isNotEmpty;

  /// Torn caches each category for an hour starting at the returned timestamp
  bool isFresh(String category) {
    final DateTime? until = freshUntil(category);
    return until != null && _now().isBefore(until);
  }

  /// When Torn's cache for this category expires, null while it is not loaded
  DateTime? freshUntil(String category) {
    final cached = _categories[category];
    if (cached == null) return null;
    return DateTime.fromMillisecondsSinceEpoch((_cacheStart(category, cached) + _cacheSeconds) * 1000);
  }

  /// Earliest moment any of these categories can bring something new, null when none is loaded
  DateTime? nextRefresh(Set<String> categories) {
    DateTime? earliest;
    for (final category in categories) {
      final DateTime? until = freshUntil(category);
      if (until == null) continue;
      if (earliest == null || until.isBefore(earliest)) earliest = until;
    }
    return earliest;
  }

  Future<void> ensureFresh(Set<String> categories) async {
    await restored;

    final List<Future<void>> waiting = [];

    for (final category in categories) {
      Future<void>? call = _running[category];
      if (call == null) {
        if (isFresh(category)) continue;
        final bool withDisplay = _displayIsDue();
        if (withDisplay) _displayRequested = true;
        call = _running[category] = _load(category, withDisplay: withDisplay);
      }
      waiting.add(call);
    }

    await Future.wait(waiting);
  }

  /// The display case comes whole with any category, so one call per batch is enough
  bool _displayIsDue() {
    if (_displayRequested) return false;
    final DateTime? loadedAt = _displayLoadedAt;
    return loadedAt == null || _now().difference(loadedAt).inSeconds >= _cacheSeconds;
  }

  Future<void> _load(String category, {required bool withDisplay}) async {
    try {
      final InventoryV2Category? result = await _fetcher(category, withDisplay: withDisplay);
      if (result == null) {
        _failed.add(category);
      } else {
        _categories[category] = result;
        _loadedAt[category] = _now();
        _failed.remove(category);
        if (result.display != null) {
          _display = result.display;
          _displayLoadedAt = _now();
        }
        _scheduleSave();
      }
    } catch (e, trace) {
      _failed.add(category);
      log("Inventory category $category failed: $e, $trace");
    } finally {
      _running.remove(category);
      if (withDisplay) _displayRequested = false;
    }

    notifyListeners();
  }

  /// Null while the category is not loaded; 0 when it is loaded and does not hold the item
  int? quantity(int itemId, String category) {
    final InventoryV2Category? data = _categories[category];
    if (data == null) return null;

    int total = 0;
    for (final item in data.items) {
      if (item.id == itemId) total += item.amount;
    }
    for (final item in _display ?? const <InventoryV2DisplayItem>[]) {
      if (item.id == itemId) total += item.quantity;
    }
    return total;
  }

  /// Maps an Item.type from the app catalog ("Energy Drink" or "ENERGY_DRINK") to an API category
  String? categoryOf(String itemType) {
    final String needle = itemType.replaceAll("_", " ").trim().toLowerCase();
    for (final category in apiCategories) {
      if (category.toLowerCase() == needle) return category;
    }
    return null;
  }

  void clear() {
    _saveTimer?.cancel();
    _running.clear();
    _categories.clear();
    _loadedAt.clear();
    _failed.clear();
    _display = null;
    _displayLoadedAt = null;
    _displayRequested = false;
    unawaited(_save());
    notifyListeners();
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      unawaited(_save());
    }
    super.dispose();
  }

  // One write per burst of categories
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () => unawaited(_save()));
  }

  Future<void> _save() async {
    try {
      final Map<String, dynamic> categories = {};
      _categories.forEach((category, data) {
        categories[category] = {
          "t": _cacheStart(category, data),
          "i": [
            for (final item in data.items) [item.id, item.amount],
          ],
        };
      });

      final Map<String, dynamic> payload = {"c": categories};

      final List<InventoryV2DisplayItem>? display = _display;
      final DateTime? displayAt = _displayLoadedAt;
      if (display != null && displayAt != null) {
        payload["d"] = {
          "t": displayAt.millisecondsSinceEpoch ~/ 1000,
          "i": [
            for (final item in display) [item.id, item.quantity],
          ],
        };
      }

      await _writeStore(jsonEncode(payload));
    } catch (e, trace) {
      log("Inventory cache could not be saved: $e, $trace");
    }
  }

  /// Anything over an hour old is dropped: Torn's own cache expired too
  Future<void> _restore() async {
    bool anything = false;
    try {
      final String raw = await _readStore();
      if (raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) throw const FormatException("not a cache");

      final int nowSeconds = _now().millisecondsSinceEpoch ~/ 1000;

      final display = decoded["d"];
      if (display is Map<String, dynamic>) {
        final int start = (display["t"] as num?)?.toInt() ?? 0;
        if (nowSeconds < start + _cacheSeconds) {
          _display = _rows(display["i"]).map((r) => InventoryV2DisplayItem(id: r[0], quantity: r[1])).toList();
          _displayLoadedAt = DateTime.fromMillisecondsSinceEpoch(start * 1000);
          anything = true;
        }
      }

      final categories = decoded["c"];
      if (categories is Map<String, dynamic>) {
        categories.forEach((category, value) {
          if (value is! Map<String, dynamic>) return;
          final int start = (value["t"] as num?)?.toInt() ?? 0;
          if (nowSeconds >= start + _cacheSeconds) return;

          _categories[category] = InventoryV2Category(
            items: _rows(value["i"])
                .map((r) => InventoryV2Item(id: r[0], amount: r[1], equipped: false, name: "", factionOwned: false))
                .toList(),
            timestamp: start,
          );
          _loadedAt[category] = DateTime.fromMillisecondsSinceEpoch(start * 1000);
          anything = true;
        });
      }
    } catch (e, trace) {
      log("Inventory cache could not be read, dropping it: $e, $trace");
      anything = false;
      await _drop();
    }

    if (anything) notifyListeners();
  }

  int _cacheStart(String category, InventoryV2Category data) {
    if (data.timestamp > 0) return data.timestamp;
    return (_loadedAt[category] ?? _now()).millisecondsSinceEpoch ~/ 1000;
  }

  Iterable<List<int>> _rows(dynamic raw) sync* {
    if (raw is! List) throw const FormatException("rows are not a list");
    for (final row in raw) {
      if (row is! List || row.length != 2 || row[0] is! num || row[1] is! num) {
        throw const FormatException("unexpected row");
      }
      yield [(row[0] as num).toInt(), (row[1] as num).toInt()];
    }
  }

  Future<void> _drop() async {
    _categories.clear();
    _loadedAt.clear();
    _display = null;
    _displayLoadedAt = null;
    try {
      await _writeStore("");
    } catch (e, trace) {
      log("Inventory cache could not be dropped: $e, $trace");
    }
  }
}
