import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

// Switches of the PDA map above city.php
class CityMapOptions extends ChangeNotifier {
  final _prefs = Prefs();
  bool _disposed = false;

  bool showItems = true;
  bool showPanel = true;
  bool showSites = false;
  bool opensAlways = false;

  // City Finder of the app options
  bool finderOn = true;

  bool get panelVisible => finderOn && showPanel;

  bool get itemsVisible => panelVisible && showItems;

  Future<void> load() async {
    final (items, panel, sites, opens, finder) = await (
      _prefs.getCityMapShowItems(),
      _prefs.getCityMapShowPanel(),
      _prefs.getCityMapShowSites(),
      _prefs.getCityOpensPdaMap(),
      _prefs.getCityEnabled(),
    ).wait;
    if (_disposed) return;
    showItems = items;
    showPanel = panel;
    showSites = sites;
    opensAlways = opens;
    finderOn = finder;
    notifyListeners();
  }

  void togglePanel() {
    showPanel = !showPanel;
    if (!showPanel) countMapUse(mapCityFinderOffFeature);
    _prefs.setCityMapShowPanel(showPanel);
    notifyListeners();
  }

  void toggleItems() {
    showItems = !showItems;
    _prefs.setCityMapShowItems(showItems);
    notifyListeners();
  }

  void toggleSites() {
    showSites = !showSites;
    _prefs.setCityMapShowSites(showSites);
    notifyListeners();
  }

  void toggleOpensAlways() {
    opensAlways = !opensAlways;
    _prefs.setCityOpensPdaMap(opensAlways);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
