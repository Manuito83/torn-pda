import 'package:flutter/material.dart';

class TargetsFilters {
  bool enabled;
  RangeValues? levelRange;
  RangeValues? lifeRange;
  RangeValues? fairFightRange;
  RangeValues? hospitalTimeRange; // minutes

  TargetsFilters({
    this.enabled = false,
    this.levelRange,
    this.lifeRange,
    this.fairFightRange,
    this.hospitalTimeRange,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'levelRange': levelRange != null ? {'start': levelRange!.start, 'end': levelRange!.end} : null,
      'lifeRange': lifeRange != null ? {'start': lifeRange!.start, 'end': lifeRange!.end} : null,
      'fairFightRange': fairFightRange != null ? {'start': fairFightRange!.start, 'end': fairFightRange!.end} : null,
      'hospitalTimeRange':
          hospitalTimeRange != null ? {'start': hospitalTimeRange!.start, 'end': hospitalTimeRange!.end} : null,
    };
  }

  factory TargetsFilters.fromJson(Map<String, dynamic> json) {
    RangeValues? parseRange(dynamic value) {
      if (value == null) return null;
      return RangeValues((value['start'] as num).toDouble(), (value['end'] as num).toDouble());
    }

    return TargetsFilters(
      enabled: json['enabled'] ?? false,
      levelRange: parseRange(json['levelRange']),
      lifeRange: parseRange(json['lifeRange']),
      fairFightRange: parseRange(json['fairFightRange']),
      hospitalTimeRange: parseRange(json['hospitalTimeRange']),
    );
  }
}
