import 'package:flutter/material.dart';
import 'package:torn_pda/models/chaining/war_sort.dart';

class WarSettings {
  // 1. Sorting Logic
  bool okayTargetsAtTop;
  WarSortType secondarySortForOkay;

  // 2. Smart Score Weights (-1.0 to 1.0)
  // Negative = Prioritize Low, Positive = Prioritize High
  double weightHospitalTime;
  double weightLife;
  double weightStats;
  double weightFairFight;
  double weightLevel;

  // Stats Split
  double weightStrength;
  double weightDefense;
  double weightSpeed;
  double weightDexterity;
  double weightEstimatedStats;

  // 3. Range Filters (null means no filter)
  bool filtersEnabled;
  RangeValues? levelRange;
  RangeValues? respectRange;
  RangeValues? lifeRange;
  RangeValues? statsRange;
  RangeValues? estimatedStatsRange;
  RangeValues? strengthRange;
  RangeValues? defenseRange;
  RangeValues? speedRange;
  RangeValues? dexterityRange;
  RangeValues? hospitalTimeRange; // In minutes
  RangeValues? lastActionRange; // In minutes
  RangeValues? fairFightRange;

  // Favorites
  List<String> favoriteSorts;

  // UI State
  int lastSettingsTabIndex;

  WarSettings({
    this.okayTargetsAtTop = false,
    this.secondarySortForOkay = WarSortType.levelDes,
    this.weightHospitalTime = 0.0,
    this.weightLife = 0.0,
    this.weightStats = 0.0,
    this.weightFairFight = 0.0,
    this.weightLevel = 0.0,
    this.weightStrength = 0.0,
    this.weightDefense = 0.0,
    this.weightSpeed = 0.0,
    this.weightDexterity = 0.0,
    this.weightEstimatedStats = 0.0,
    this.filtersEnabled = false,
    this.levelRange,
    this.respectRange,
    this.lifeRange,
    this.statsRange,
    this.estimatedStatsRange,
    this.strengthRange,
    this.defenseRange,
    this.speedRange,
    this.dexterityRange,
    this.hospitalTimeRange,
    this.lastActionRange,
    this.fairFightRange,
    List<String>? favoriteSorts,
    this.lastSettingsTabIndex = 0,
  }) : favoriteSorts = favoriteSorts ?? [];

  Map<String, dynamic> toJson() => {
        'okayTargetsAtTop': okayTargetsAtTop,
        'secondarySortForOkay': secondarySortForOkay.index,
        'weightHospitalTime': weightHospitalTime,
        'weightLife': weightLife,
        'weightStats': weightStats,
        'weightFairFight': weightFairFight,
        'weightLevel': weightLevel,
        'weightStrength': weightStrength,
        'weightDefense': weightDefense,
        'weightSpeed': weightSpeed,
        'weightDexterity': weightDexterity,
        'weightEstimatedStats': weightEstimatedStats,
        'filtersEnabled': filtersEnabled,
        'levelRange': levelRange != null ? {'start': levelRange!.start, 'end': levelRange!.end} : null,
        'respectRange': respectRange != null ? {'start': respectRange!.start, 'end': respectRange!.end} : null,
        'lifeRange': lifeRange != null ? {'start': lifeRange!.start, 'end': lifeRange!.end} : null,
        'statsRange': statsRange != null ? {'start': statsRange!.start, 'end': statsRange!.end} : null,
        'estimatedStatsRange':
            estimatedStatsRange != null ? {'start': estimatedStatsRange!.start, 'end': estimatedStatsRange!.end} : null,
        'strengthRange': strengthRange != null ? {'start': strengthRange!.start, 'end': strengthRange!.end} : null,
        'defenseRange': defenseRange != null ? {'start': defenseRange!.start, 'end': defenseRange!.end} : null,
        'speedRange': speedRange != null ? {'start': speedRange!.start, 'end': speedRange!.end} : null,
        'dexterityRange': dexterityRange != null ? {'start': dexterityRange!.start, 'end': dexterityRange!.end} : null,
        'hospitalTimeRange':
            hospitalTimeRange != null ? {'start': hospitalTimeRange!.start, 'end': hospitalTimeRange!.end} : null,
        'lastActionRange':
            lastActionRange != null ? {'start': lastActionRange!.start, 'end': lastActionRange!.end} : null,
        'fairFightRange': fairFightRange != null ? {'start': fairFightRange!.start, 'end': fairFightRange!.end} : null,
        'favoriteSorts': favoriteSorts,
        'lastSettingsTabIndex': lastSettingsTabIndex,
      };

  factory WarSettings.fromJson(Map<String, dynamic> json) {
    RangeValues? parseRange(dynamic value) {
      if (value == null) return null;
      return RangeValues(value['start'], value['end']);
    }

    return WarSettings(
      okayTargetsAtTop: json['okayTargetsAtTop'] ?? false,
      secondarySortForOkay: WarSortType.values[json['secondarySortForOkay'] ?? WarSortType.levelDes.index],
      weightHospitalTime: json['weightHospitalTime'] ?? 0.0,
      weightLife: json['weightLife'] ?? 0.0,
      weightStats: json['weightStats'] ?? 0.0,
      weightFairFight: json['weightFairFight'] ?? 0.0,
      weightLevel: json['weightLevel'] ?? 0.0,
      weightStrength: json['weightStrength'] ?? 0.0,
      weightDefense: json['weightDefense'] ?? 0.0,
      weightSpeed: json['weightSpeed'] ?? 0.0,
      weightDexterity: json['weightDexterity'] ?? 0.0,
      weightEstimatedStats: json['weightEstimatedStats'] ?? 0.0,
      filtersEnabled: json['filtersEnabled'] ?? false,
      levelRange: parseRange(json['levelRange']),
      respectRange: parseRange(json['respectRange']),
      lifeRange: parseRange(json['lifeRange']),
      statsRange: parseRange(json['statsRange']),
      estimatedStatsRange: parseRange(json['estimatedStatsRange']),
      strengthRange: parseRange(json['strengthRange']),
      defenseRange: parseRange(json['defenseRange']),
      speedRange: parseRange(json['speedRange']),
      dexterityRange: parseRange(json['dexterityRange']),
      hospitalTimeRange: parseRange(json['hospitalTimeRange']),
      lastActionRange: parseRange(json['lastActionRange']),
      fairFightRange: parseRange(json['fairFightRange']),
      favoriteSorts: (json['favoriteSorts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lastSettingsTabIndex: json['lastSettingsTabIndex'] ?? 0,
    );
  }
}
