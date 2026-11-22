import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';

const _playEvery = Duration(seconds: 1);
const _paintEvery = Duration(milliseconds: 250);
const _pollEvery = Duration(milliseconds: 20);

// Far image redraws after the change
const _redrawWait = Duration(milliseconds: 300);

class TerritoryTimelapseController extends ChangeNotifier {
  TerritoryTimelapseController(this._map, this._history, {this.inCity = false});

  final TerritoryMapController _map;
  final TerritoryHistoryController _history;

  final bool inCity;

  bool open = false;

  // Oldest first, the last one is now
  List<String> days = const [];
  int selected = 0;

  Timer? _player;
  Timer? _paint;
  DateTime _paintedAt = DateTime(0);
  MapState? _paintedState;
  MapHistory? _paintedRecord;
  int _paintedDay = -1;

  bool get playing => _player != null;

  bool get atPresent => selected >= days.length - 1;

  void start() {
    if (open) return;
    open = true;
    _history.addListener(_onHistory);
    _map.addListener(_onMap);
    _history.loadYears();
    _onHistory();
  }

  void stop() {
    if (!open) return;
    _leave();
    _map.showPast(null, null);
    notifyListeners();
  }

  void _leave() {
    open = false;
    _player?.cancel();
    _player = null;
    _paint?.cancel();
    _paint = null;
    _paintedDay = -1;
    _history.removeListener(_onHistory);
    _map.removeListener(_onMap);
  }

  void _onMap() {
    if (_map.overCity && !inCity) return stop();
    _schedulePaint();
  }

  @override
  void dispose() {
    if (open) {
      _leave();
      _map.showPast(null, null, notify: false);
    }
    super.dispose();
  }

  // The chosen day stays as days arrive
  void _onHistory() {
    final now = DateTime.now().toUtc();
    final chosen = days.isEmpty || atPresent ? null : days[selected];
    days = timelapseDays(_history.record?.completeFrom ?? now, now);
    final index = chosen == null ? -1 : days.indexOf(chosen);
    selected = index < 0 ? days.length - 1 : index;
    notifyListeners();
    _schedulePaint();
  }

  void select(int index) {
    selected = index.clamp(0, days.length - 1);
    notifyListeners();
    _schedulePaint();
  }

  // False if the map is gone
  Future<bool> showDay(String day, {bool Function()? cancelled}) async {
    bool stopped() => !open || (cancelled?.call() ?? false);
    pause();
    final index = days.indexOf(day);
    if (index < 0 || stopped()) return false;
    select(index);
    while (_paint != null || _paintedDay != selected) {
      if (stopped()) return false;
      await Future.delayed(_pollEvery);
    }
    await Future.delayed(_redrawWait);
    await WidgetsBinding.instance.endOfFrame;
    return !stopped() && days[selected] == day;
  }

  void play() {
    if (days.length < 2) return;
    if (atPresent) select(0);
    _player = Timer.periodic(_playEvery, (_) {
      select(selected + 1);
      if (atPresent) pause();
    });
    notifyListeners();
  }

  void pause() {
    if (_player == null) return;
    _player!.cancel();
    _player = null;
    notifyListeners();
  }

  // One past day per 250 ms
  void _schedulePaint() {
    if (!open || _paint != null) return;
    if (_paintedState == _map.state && _paintedRecord == _history.record && _paintedDay == selected) return;
    final wait = _paintEvery - DateTime.now().difference(_paintedAt);
    if (wait <= Duration.zero) return _paintDay();
    _paint = Timer(wait, () {
      _paint = null;
      _paintDay();
    });
  }

  void _paintDay() {
    _paintedAt = DateTime.now();
    final present = _paintedState = _map.state;
    final record = _paintedRecord = _history.record;
    _paintedDay = selected;
    if (atPresent || present == null || record == null) return _map.showPast(null, null);
    final day = days[selected];
    _map.showPast(dayStart(day), ownersAt(present.ownership, record.owners, day), inCity: inCity);
  }
}
