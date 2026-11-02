import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chaining/war_filters.dart';
import 'package:torn_pda/models/chaining/war_settings.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart' show Status;

Member member(
  String name, {
  String online = 'Online',
  String state = 'Okay',
  String color = 'green',
  String? description,
  int? until,
  int level = 10,
  double fairFight = 3,
  bool pinned = false,
  bool hidden = false,
}) => Member(
  name: name,
  level: level,
  fairFight: fairFight,
  pinned: pinned,
  hidden: hidden,
  status: Status(state: state, color: color, description: description ?? state, until: until),
  lastAction: LastAction(status: online),
);

FactionModel faction(String name, Map<String, Member> members, {bool hidden = false}) =>
    FactionModel(name: name, hidden: hidden, leader: 1, coLeader: 2, members: members);

List<String> shown(
  List<FactionModel> factions, {
  int offline = 0,
  int okayRed = 0,
  bool country = false,
  int abroad = 0,
  WarSettings? settings,
  DateTime? now,
}) {
  final members = warMembersShown(
    factions,
    offlineSelector: offline,
    okayRedFilterActive: okayRed,
    countryFilterActive: country,
    abroadFilterActive: abroad,
    playerLocation: 'Torn',
    settings: settings ?? WarSettings(),
    fairFightOf: (m) => m.fairFight ?? -1,
    totalStatsOf: (_) => 0,
    estimatedStatsIndexOf: (_) => -1,
    compare: (a, b) => (b.level ?? 0).compareTo(a.level ?? 0),
    now: now,
  );
  return [for (final m in members) m.name!];
}

void main() {
  test('the online and okay filters keep one side each', () {
    final f = faction('A', {
      '1': member('On', level: 40),
      '2': member('Idle', level: 30, online: 'Idle'),
      '3': member('Off', level: 20, online: 'Offline'),
      '4': member('Hosp', level: 10, state: 'Hospital', color: 'red'),
    });
    expect(shown([f]), ['On', 'Idle', 'Off', 'Hosp']);
    expect(shown([f], offline: 1), ['On', 'Idle', 'Hosp']);
    expect(shown([f], offline: 2), ['Off']);
    expect(shown([f], okayRed: 1), ['On', 'Idle', 'Off']);
    expect(shown([f], okayRed: 2), ['Hosp']);
  });

  test('the country and abroad filters read the status', () {
    final f = faction('A', {
      '1': member('Home', level: 40),
      '2': member('Away', level: 30, state: 'Abroad', description: 'In Mexico'),
      '3': member('Flying', level: 20, state: 'Traveling', description: 'Traveling to Japan'),
      '4': member('Back', level: 10, state: 'Traveling', description: 'Returning to Torn from Japan'),
    });
    expect(shown([f], country: true), ['Home', 'Back']);
    expect(shown([f], abroad: 1), ['Away', 'Flying', 'Back']);
    expect(shown([f], abroad: 2), ['Home']);
  });

  test('hidden factions and members are out, the rest carry their faction', () {
    final a = faction('A', {'11': member('Lead', level: 30), '12': member('Ghost', level: 20, hidden: true)});
    final b = faction('B', {'21': member('Gone')}, hidden: true);
    final result = warMembersShown(
      [a, b],
      offlineSelector: 0,
      okayRedFilterActive: 0,
      countryFilterActive: false,
      abroadFilterActive: 0,
      playerLocation: 'Torn',
      settings: WarSettings(),
      fairFightOf: (_) => -1,
      totalStatsOf: (_) => 0,
      estimatedStatsIndexOf: (_) => -1,
      compare: (_, _) => 0,
    );
    expect(result.single.name, 'Lead');
    expect(result.single.memberId, 11);
    expect(result.single.factionName, 'A');
    expect(result.single.factionLeader, 1);
    expect(result.single.factionColeader, 2);
  });

  test('pinned members come first, each block in order', () {
    final f = faction('A', {
      '1': member('High', level: 50),
      '2': member('PinLow', level: 5, pinned: true),
      '3': member('Mid', level: 20),
      '4': member('PinHigh', level: 15, pinned: true),
    });
    expect(shown([f]), ['PinHigh', 'PinLow', 'High', 'Mid']);
  });

  test('ranges apply only when enabled and use the fair fight given', () {
    final f = faction('A', {
      '1': member('Strong', level: 60, fairFight: 1.2),
      '2': member('Fair', level: 30, fairFight: 3.0),
      '3': member('Unknown', level: 20, fairFight: -1),
    });
    final off = WarSettings(levelRange: const RangeValues(25, 100));
    expect(shown([f], settings: off), ['Strong', 'Fair', 'Unknown']);
    final levels = WarSettings(filtersEnabled: true, levelRange: const RangeValues(25, 100));
    expect(shown([f], settings: levels), ['Strong', 'Fair']);
    final fairFight = WarSettings(filtersEnabled: true, fairFightRange: const RangeValues(2, 5));
    expect(shown([f], settings: fairFight), ['Fair']);
  });

  test('the hospital range counts minutes left from the time given', () {
    final now = DateTime.utc(2026, 11, 2, 12);
    final at = now.millisecondsSinceEpoch ~/ 1000;
    final f = faction('A', {
      '1': member('Soon', level: 40, state: 'Hospital', color: 'red', until: at + 4 * 60),
      '2': member('Long', level: 30, state: 'Hospital', color: 'red', until: at + 90 * 60),
      '3': member('Out', level: 20, state: 'Hospital', color: 'red', until: at - 60),
      '4': member('Okay', level: 10),
    });
    final settings = WarSettings(filtersEnabled: true, hospitalTimeRange: const RangeValues(0, 5));
    expect(shown([f], settings: settings, now: now), ['Soon', 'Out', 'Okay']);
    final later = now.add(const Duration(hours: 2));
    expect(shown([f], settings: settings, now: later), ['Soon', 'Long', 'Out', 'Okay']);
  });
}
