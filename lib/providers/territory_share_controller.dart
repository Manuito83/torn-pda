import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/territory_map/map_share.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';

class TerritoryShareController extends ChangeNotifier {
  // One per map, last is on top
  final _readers = <Rect? Function()>[];

  // Camera the view must fly to
  Rect? camera;
  int cameraRequest = 0;

  SharedMapView? _pending;

  void addReader(Rect? Function() reader) => _readers.add(reader);

  void removeReader(Rect? Function() reader) => _readers.remove(reader);

  // Landscape still loading, per map
  final _photoWaits = <Future<void> Function()>[];

  void addPhotosWait(Future<void> Function() wait) => _photoWaits.add(wait);

  void removePhotosWait(Future<void> Function() wait) => _photoWaits.remove(wait);

  Future<void> photosLoaded() => _photoWaits.lastOrNull?.call() ?? Future.value();

  // Null without a map on screen
  SharedMapView? capture(TerritoryMapController map) {
    final camera = _readers.lastOrNull?.call();
    if (camera == null) return null;
    return SharedMapView(
      camera: camera,
      view: map.view,
      span: map.activitySpan,
      territory: map.selected,
      warId: map.openWar,
      layers: {if (map.showLocks) layerLocks, if (map.factionNames) layerNames},
    );
  }

  void receive(SharedMapView view) {
    _pending = view;
    _pendingFaction = null;
    notifyListeners();
  }

  SharedMapView? takePending() {
    final view = _pending;
    _pending = null;
    return view;
  }

  int? _pendingFaction;

  void receiveFaction(int factionId) {
    _pendingFaction = factionId;
    _pending = null;
    notifyListeners();
  }

  int? takePendingFaction() {
    final faction = _pendingFaction;
    _pendingFaction = null;
    return faction;
  }

  // Not saved, gone when the map closes
  void show(SharedMapView view, TerritoryMapController map) {
    map.showTemporarily(
      view: view.view,
      span: view.view == MapView.activity ? view.span : map.activitySpan,
      locks: view.layers.contains(layerLocks),
      names: view.layers.contains(layerNames),
    );
    final known = map.territories?.territories.containsKey(view.territory) ?? false;
    map.select(known ? view.territory : null);
    if (view.warId != null) map.showWar(view.warId);
    camera = view.camera;
    cameraRequest++;
    notifyListeners();
  }
}
