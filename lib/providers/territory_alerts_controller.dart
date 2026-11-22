import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/alert_subscriptions.dart';
import 'package:torn_pda/models/territory_map/alert_topics.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/user_helper.dart';

const _callTimeout = Duration(seconds: 20);

class TerritoryAlertsController extends ChangeNotifier {
  final _prefs = Prefs();

  bool enabled = false;
  List<String> topics = const [];

  // -1 until alerts are first turned on
  int _faction = -1;
  Future<void>? _loading;
  AlertTap? _tap;
  Future<void> _queue = Future.value();

  Future<void> ready() => _loading ??= _load();

  Future<void> _load() async {
    enabled = await _prefs.getTerritoryMapAlerts();
    topics = [...(await _prefs.getTerritoryMapAlertTopics()).where(isValidTopic)];
    _faction = await _prefs.getTerritoryMapAlertFaction();
    notifyListeners();
  }

  Set<AlertKind> kindsFor(AlertTarget target) => {
    for (final kind in AlertKind.values)
      if (topics.contains(target.topic(kind))) kind,
  };

  // Startup and token refresh, also clears leftovers
  Future<void> resubscribe() async {
    await ready();
    if (!UserHelper.isApiKeyValid) return;
    _followFaction();
    await (enabled ? _subscribe(topics) : _unsubscribe(topics));
    log('Territory alerts: ${enabled ? 'subscribed to' : 'unsubscribed from'} ${topics.length} topics');
  }

  // Heals a key or faction change
  Future<void> followFaction() async {
    await ready();
    if (UserHelper.isApiKeyValid) await _followFaction();
  }

  // Key removed, the next account starts clean
  Future<void> forget() async {
    await ready();
    enabled = false;
    topics = const [];
    _faction = -1;
    _prefs.setTerritoryMapAlerts(false);
    _prefs.setTerritoryMapAlertTopics(const []);
    _prefs.setTerritoryMapAlertFaction(-1);
    _prefs.setTerritoryMapAlertsHinted(false);
    notifyListeners();
  }

  Future<void> _followFaction() {
    final from = _faction;
    final faction = UserHelper.factionId;
    if (from < 0 || from == faction) return _queue;
    _faction = faction;
    _prefs.setTerritoryMapAlertFaction(faction);
    return _changeTopics(moveFactionTopics(topics, from, faction));
  }

  Future<void> setEnabled(bool on) async {
    await ready();
    await _setEnabled(on);
  }

  Future<void> _setEnabled(bool on) {
    var list = topics;
    if (on && _faction < 0) {
      _faction = UserHelper.factionId;
      _prefs.setTerritoryMapAlertFaction(_faction);
      if (_faction > 0) list = moveFactionTopics(list, 0, _faction);
    }
    enabled = on;
    _prefs.setTerritoryMapAlerts(on);
    _setTopics(list);
    return on ? _subscribe(list) : _unsubscribe(list);
  }

  // Adding a watch turns alerts on
  Future<void> toggle(AlertTarget target, AlertKind kind) async {
    await ready();
    final topic = target.topic(kind);
    final add = !topics.contains(topic);
    if (add && !enabled) _setEnabled(true);
    if (add == topics.contains(topic)) return _queue;
    await _changeTopics(add ? [...topics, topic] : [...topics.where((t) => t != topic)]);
  }

  Future<void> remove(AlertTarget target) {
    final gone = [for (final kind in AlertKind.values) target.topic(kind)];
    return _changeTopics([...topics.where((t) => !gone.contains(t))]);
  }

  // Once, with a faction and alerts off
  Future<bool> takeHint() async {
    await ready();
    if (enabled || UserHelper.factionId == 0 || await _prefs.getTerritoryMapAlertsHinted()) return false;
    _prefs.setTerritoryMapAlertsHinted(true);
    return true;
  }

  void openTap(AlertTap tap) {
    _tap = tap;
    notifyListeners();
  }

  AlertTap? takeTap() {
    final tap = _tap;
    _tap = null;
    return tap;
  }

  void _setTopics(List<String> list) {
    topics = list;
    _prefs.setTerritoryMapAlertTopics(list);
    notifyListeners();
  }

  Future<void> _changeTopics(List<String> list) {
    final old = topics;
    _setTopics(list);
    if (!enabled) return _queue;
    _unsubscribe(old.where((t) => !list.contains(t)));
    return _subscribe(list.where((t) => !old.contains(t)));
  }

  Future<void> _subscribe(Iterable<String> list) => _each(list, FirebaseMessaging.instance.subscribeToTopic);

  Future<void> _unsubscribe(Iterable<String> list) => _each(list, FirebaseMessaging.instance.unsubscribeFromTopic);

  // One queue, so calls land in order
  Future<void> _each(Iterable<String> list, Future<void> Function(String) call) {
    final pending = list.toList();
    return _queue = _queue.then((_) async {
      if (Platform.isWindows) return;
      for (final topic in pending) {
        try {
          await call(topic).timeout(_callTimeout);
        } catch (e) {
          log('Territory alerts: $topic failed: $e');
        }
      }
    });
  }
}

// Hiding the map also stops its alerts and flight sharing
void setTerritoryMapDisabled(BuildContext context, bool disable) {
  context.read<SettingsProvider>().changeDisableTerritoryMap = disable;
  if (disable) context.read<TerritoryAlertsController>().setEnabled(false);
}
