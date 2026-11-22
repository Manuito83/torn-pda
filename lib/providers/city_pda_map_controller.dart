import 'dart:async';

import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/main.dart' show logAndShowToUser;
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/territory_map/city_map_hole.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/city_item_prices.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/utils/js_snippets/city_map_snippets.dart';
import 'package:torn_pda/utils/js_snippets/js_snippets.dart';
import 'package:torn_pda/utils/js_snippets/remote_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/torn_web.dart';

const _pictureWait = Duration(seconds: 2);

typedef CityFrame = ({Future<Object?> closed, Future<String?> picture, Future<void> shown});

typedef CityFramePusher =
    CityFrame Function(
      CityPageData page,
      String? hole,
      Future<Object?> Function(CityItem item) pick, {
      required bool arrival,
    });

// One per tab, outlives the widget
class CityPdaMapController extends ChangeNotifier {
  CityPdaMapController({
    required InAppWebViewController? Function() web,
    required this.pushFrame,
    required this.mayAutoOpen,
    required this.toast,
    required Future<List<Item>> Function() fetchItems,
    Future<bool> Function()? opensAlways,
    Future<bool> Function()? mapDisabled,
    Future<dynamic> Function(bool value)? saveMapClean,
    this.debugToast,
  }) : _fetchItems = fetchItems,
       _web = web,
       _opensAlways = opensAlways ?? Prefs().getCityOpensPdaMap,
       _mapDisabled = mapDisabled ?? Prefs().getDisableTerritoryMap,
       _saveMapClean = saveMapClean ?? Prefs().setCityMapCleanView;

  final InAppWebViewController? Function() _web;
  final CityFramePusher pushFrame;
  final bool Function() mayAutoOpen;
  final void Function(String text) toast;
  final void Function(String text)? debugToast;
  final Future<bool> Function() _opensAlways;
  final Future<bool> Function() _mapDisabled;
  final Future<dynamic> Function(bool value) _saveMapClean;

  final Future<List<Item>> Function() _fetchItems;

  late final prices = CityItemPrices(
    _fetchItems,
    onFailed: () {
      if (_active) countMapFailure(MapFailure.prices);
    },
  );

  // Territories and rackets off on Torn's map
  bool mapClean = false;

  // Rings off on Torn's map
  bool itemsHidden = false;

  // Without the finder, no rings on Torn's map
  bool finderOn = true;

  bool _frameOpen = false;
  bool _active = false;
  bool _arriving = false;
  bool _hidesEarly = false;
  bool _disposed = false;

  // Why the hole was filled or not
  String _closeReason = 'late';

  // Torn's map is hidden behind ours
  bool get active => _active;

  // Nothing above the page yet
  bool get arriving => _arriving;

  // The next city document starts hidden
  bool get hidesEarly => _hidesEarly;

  void _setActive(bool active) {
    final arriving = _arriving && active;
    if ((active == _active && arriving == _arriving) || _disposed) return;
    _active = active;
    _arriving = arriving;
    notifyListeners();
  }

  void _beginArrival() {
    if (_disposed) return;
    _active = true;
    _arriving = true;
    notifyListeners();
  }

  void _endArrival() {
    if (!_arriving || _disposed) return;
    _arriving = false;
    notifyListeners();
  }

  // Off in Settings, never on its own
  Future<bool> _opens() async => !await _mapDisabled() && await _opensAlways();

  // Counts from the next document on
  Future<void> syncEarlyHide() => _run(() async {
    final web = _web();
    if (web == null) return;
    final opens = await _opens();
    _hidesEarly = opens;
    await web.removeUserScriptsByGroupName(groupName: cityMapEarlyHideGroup);
    if (!opens) return;
    await web.addUserScript(
      userScript: UserScript(
        groupName: cityMapEarlyHideGroup,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        source: oncePerDocument(cityMapEarlyHideGroup, cityMapEarlyHideJS()),
      ),
    );
  });

  void toggleMapClean() {
    mapClean = !mapClean;
    _saveMapClean(mapClean);
    _web()?.evaluateJavascript(source: cityMapCleanJS(hidden: mapClean));
    notifyListeners();
  }

  void toggleItemsOnMap() {
    itemsHidden = !itemsHidden;
    _web()?.evaluateJavascript(source: toggleCityItemsHighlightJS(hidden: itemsHidden));
    notifyListeners();
  }

  // True when Torn's map went hidden
  Future<bool> hideForArrival() async {
    try {
      final web = _web();
      if (web == null || !await _onTorn()) return false;
      if (await web.evaluateJavascript(source: cityMapArrivedJS) == true) return false;
      final opens = await _opens();
      // May be hidden by an old script
      await web.evaluateJavascript(source: cityMapPauseJS(paused: opens));
      if (opens) _beginArrival();
      return opens;
    } catch (e) {
      debugPrint('city pda map: $e');
      return false;
    }
  }

  // Runs once per document
  Future<void> arrive() async {
    final web = _web();
    final opens = await _opens();
    if (web == null || _frameOpen || _disposed) return _endArrival();
    if (!await _onTorn()) return leave();
    if (await web.evaluateJavascript(source: cityMapFirstArrivalJS) != true) return _endArrival();
    if (itemsHidden) {
      itemsHidden = false;
      notifyListeners();
    }
    if (!opens) {
      if (_active) await showTornMap();
      return;
    }
    _setActive(true);
    if (mayAutoOpen()) return open(arrival: true);
    _endArrival();
    await _fillHole();
  }

  void leave() => _setActive(false);

  Future<void> onPageAction(Object? action, {required bool isMainFrame}) async {
    if (!isMainFrame || !await _onTorn()) return;
    // Old scripts may still ask
    final off = await _mapDisabled();
    if (action == 'open' && !off) await open();
    if ((action == 'torn' || (action == 'open' && off)) && !_frameOpen) await showTornMap();
  }

  Future<bool> _onTorn() async => isTornUrl((await _web()?.getUrl())?.toString());

  // Reads only this visible page, no fetch
  Future<void> open({bool arrival = false}) async {
    final web = _web();
    if (web == null || _frameOpen) return;
    _frameOpen = true;
    // An arrival has no hole yet
    final wasActive = _active && !arrival;
    var opened = false;
    var picture = Future.value(false);
    Object? result;
    _closeReason = 'late';
    try {
      await web.evaluateJavascript(source: cityMapPauseJS(paused: true));
      final dynamic json = await web.evaluateJavascript(source: cityMapDataJS());
      final dynamic hole = await web.evaluateJavascript(source: cityMapRectJS());
      final page = withItemPrices(parseCityPageData(json.toString()), prices.byItem);
      final frame = pushFrame(page, hole?.toString(), _pick, arrival: arrival);
      opened = true;
      _setActive(true);
      // Arriving, the hole waits for the close
      unawaited(arrival ? frame.shown.then((_) => _endArrival()) : _fillHole());
      picture = frame.picture.then(_sendPicture).catchError((_) {
        _closeReason = 'picture failed';
        return false;
      });
      result = await frame.closed;
    } catch (e) {
      debugPrint('city pda map: $e');
    } finally {
      _frameOpen = false;
      _endArrival();
    }
    if (!opened) {
      toast("Torn's map is not ready yet");
      if (!wasActive) await showTornMap();
      return;
    }
    switch (result) {
      case CitySite(:final url):
        await _load(url);
      case CityTornLink(:final url):
        await _followLink(url);
      default:
        if (!_active) return;
        // No picture, no hole
        final pictured = await picture.timeout(_pictureWait, onTimeout: () => false);
        await _reportClose(pictured);
        if (!pictured) await showTornMap();
    }
  }

  Future<void> _reportClose(bool pictured) async {
    if (!logAndShowToUser) return;
    String? rect;
    try {
      rect = '${await _web()?.evaluateJavascript(source: cityMapRectJS())}';
    } catch (_) {}
    debugToast?.call(cityCloseLine(hole: pictured, reason: _closeReason, rect: rect));
  }

  Future<Object?> _pick(CityItem item) async {
    final result = await _web()?.callAsyncJavaScript(
      functionBody: cityItemPickJS(),
      arguments: {'id': item.id, 'lat': item.lat, 'lng': item.lng},
    );
    return result?.value;
  }

  // Without a hole, no way back
  Future<bool> _fillHole({String? picture}) async {
    var filled = true;
    await _run(() async {
      final web = _web();
      if (web == null) return;
      await web.evaluateJavascript(source: cityMapPauseJS(paused: true));
      final result = await web.callAsyncJavaScript(functionBody: cityMapHoleJS(), arguments: {'picture': picture});
      filled = result?.value != false;
    });
    if (!filled && !_frameOpen) await showTornMap();
    return filled;
  }

  // Open in Torn may come first
  Future<bool> _sendPicture(String? picture) async {
    if (picture == null) {
      _closeReason = 'no picture';
      return false;
    }
    if (!_active) {
      _closeReason = 'not active';
      return false;
    }
    final filled = await _fillHole(picture: picture);
    _closeReason = filled ? 'hole filled' : 'hole refused, box too big or no map';
    return filled;
  }

  Future<void> showTornMap() => _run(() async {
    _setActive(false);
    final web = _web();
    if (web == null) return;
    await web.evaluateJavascript(source: cityMapPauseJS(paused: false));
    if (finderOn) await web.evaluateJavascript(source: highlightCityItemsJS());
    await web.evaluateJavascript(source: cityMapCleanJS(hidden: mapClean));
  });

  Future<void> _followLink(String url) async {
    final territory = cityLinkTerritory(url);
    if (territory == null) return _load(url);
    await showTornMap();
    await _run(() async {
      await _web()?.callAsyncJavaScript(functionBody: cityMapFocusJS(), arguments: {'code': territory});
    });
  }

  Future<void> _load(String url) => _run(() async {
    await _web()?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  });

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('city pda map: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    prices.dispose();
    super.dispose();
  }
}
