import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/territory_map/city_heights.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

mixin TerritoryMapSwitches on ChangeNotifier {
  final _prefs = Prefs();

  String savedCamera = '';
  bool showLocks = true;
  bool factionNames = false;
  bool diaryStrip = false;
  bool flightsButton = true;
  bool flatFlights = false;
  bool cityLife = true;
  bool lifePlanes = true;
  bool lifeTraffic = true;
  bool lifeNight = true;
  bool lifeGunfire = true;
  bool lifePolice = true;
  LifeDensity lifeDensity = LifeDensity.normal;

  // Not in release, never saved
  double? debugTctHour;
  MapView view = MapView.normal;
  ActivitySpan activitySpan = ActivitySpan.week;
  bool threeD = false;
  CityHeight cityHeight = CityHeight.respect;

  Future<void> loadSwitches() async {
    final (camera, locks, names, savedView, span, strip, button, flat) = await (
      _prefs.getTerritoryMapCamera(),
      _prefs.getTerritoryMapShowLocks(),
      _prefs.getTerritoryMapFactionNames(),
      _prefs.getTerritoryMapView(),
      _prefs.getTerritoryMapActivitySpan(),
      _prefs.getTerritoryMapDiaryStrip(),
      _prefs.getTerritoryMapFlightsButton(),
      _prefs.getTerritoryMapFlatFlights(),
    ).wait;
    final (life, planes, traffic, density) = await (
      _prefs.getTerritoryMapCityLife(),
      _prefs.getTerritoryMapLifePlanes(),
      _prefs.getTerritoryMapLifeTraffic(),
      _prefs.getTerritoryMapLifeDensity(),
    ).wait;
    final (night, gunfire, police) = await (
      _prefs.getTerritoryMapLifeNight(),
      _prefs.getTerritoryMapLifeGunfire(),
      _prefs.getTerritoryMapLifePolice(),
    ).wait;
    lifeNight = night;
    lifeGunfire = gunfire;
    lifePolice = police;
    final (savedThreeD, height) = await (_prefs.getTerritoryMap3d(), _prefs.getTerritoryMap3dHeight()).wait;
    threeD = savedThreeD;
    cityHeight = CityHeight.values.asNameMap()[height] ?? CityHeight.respect;
    savedCamera = camera;
    showLocks = locks;
    factionNames = names;
    diaryStrip = strip;
    flightsButton = button;
    flatFlights = flat;
    cityLife = life;
    lifePlanes = planes;
    lifeTraffic = traffic;
    lifeDensity = LifeDensity.values.asNameMap()[density] ?? LifeDensity.normal;
    view = MapView.values.asNameMap()[savedView] ?? MapView.normal;
    activitySpan = ActivitySpan.values.asNameMap()[span] ?? ActivitySpan.week;
  }

  // Shades depend on the view
  @protected
  void viewChanged();

  // Saved choices under a shared view
  _Stored? _stored;

  void showTemporarily({required MapView view, required ActivitySpan span, required bool locks, required bool names}) {
    _stored ??= _Stored(this.view, activitySpan, showLocks, factionNames);
    final viewDiffers = this.view != view;
    this.view = view;
    activitySpan = span;
    showLocks = locks;
    factionNames = names;
    if (viewDiffers) viewChanged();
    notifyListeners();
  }

  void restoreSwitches({bool notify = true}) {
    final stored = _stored;
    if (stored == null) return;
    _stored = null;
    final viewDiffers = view != stored.view;
    view = stored.view;
    activitySpan = stored.span;
    showLocks = stored.locks;
    factionNames = stored.names;
    if (viewDiffers) viewChanged();
    if (notify) notifyListeners();
  }

  void setView(MapView value) {
    if (value == view) return;
    view = value;
    _stored?.view = value;
    _prefs.setTerritoryMapView(value.name);
    viewChanged();
    notifyListeners();
  }

  void setActivitySpan(ActivitySpan value) {
    activitySpan = value;
    _stored?.span = value;
    _prefs.setTerritoryMapActivitySpan(value.name);
    notifyListeners();
  }

  void saveCamera(String camera) {
    savedCamera = camera;
    _prefs.setTerritoryMapCamera(camera);
  }

  void toggleLocks() {
    showLocks = !showLocks;
    _stored?.locks = showLocks;
    _prefs.setTerritoryMapShowLocks(showLocks);
    notifyListeners();
  }

  void toggleDiaryStrip() {
    diaryStrip = !diaryStrip;
    _prefs.setTerritoryMapDiaryStrip(diaryStrip);
    notifyListeners();
  }

  void toggleFlightsButton() {
    flightsButton = !flightsButton;
    _prefs.setTerritoryMapFlightsButton(flightsButton);
    notifyListeners();
  }

  void toggleFlatFlights() {
    flatFlights = !flatFlights;
    _prefs.setTerritoryMapFlatFlights(flatFlights);
    notifyListeners();
  }

  void toggleCityLife() {
    cityLife = !cityLife;
    _prefs.setTerritoryMapCityLife(cityLife);
    notifyListeners();
  }

  void toggleLifePlanes() {
    lifePlanes = !lifePlanes;
    _prefs.setTerritoryMapLifePlanes(lifePlanes);
    notifyListeners();
  }

  void toggleLifeTraffic() {
    lifeTraffic = !lifeTraffic;
    _prefs.setTerritoryMapLifeTraffic(lifeTraffic);
    notifyListeners();
  }

  void toggleLifeNight() {
    lifeNight = !lifeNight;
    _prefs.setTerritoryMapLifeNight(lifeNight);
    notifyListeners();
  }

  void toggleLifeGunfire() {
    lifeGunfire = !lifeGunfire;
    _prefs.setTerritoryMapLifeGunfire(lifeGunfire);
    notifyListeners();
  }

  void toggleLifePolice() {
    lifePolice = !lifePolice;
    _prefs.setTerritoryMapLifePolice(lifePolice);
    notifyListeners();
  }

  void setDebugTctHour(double? value) {
    debugTctHour = value;
    notifyListeners();
  }

  void setLifeDensity(LifeDensity value) {
    lifeDensity = value;
    _prefs.setTerritoryMapLifeDensity(value.name);
    notifyListeners();
  }

  void setThreeD(bool value) {
    if (value == threeD) return;
    threeD = value;
    _prefs.setTerritoryMap3d(value);
    notifyListeners();
  }

  void setCityHeight(CityHeight value) {
    cityHeight = value;
    _prefs.setTerritoryMap3dHeight(value.name);
    notifyListeners();
  }

  void toggleFactionNames() {
    factionNames = !factionNames;
    _stored?.names = factionNames;
    _prefs.setTerritoryMapFactionNames(factionNames);
    notifyListeners();
  }
}

class _Stored {
  _Stored(this.view, this.span, this.locks, this.names);

  MapView view;
  ActivitySpan span;
  bool locks;
  bool names;
}
