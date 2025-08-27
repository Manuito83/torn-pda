import 'dart:developer';

class EducationV2 {
  final List<int> complete;
  final CurrentEducation? current;

  EducationV2({
    required this.complete,
    this.current,
  });

  factory EducationV2.fromJson(Map<String, dynamic> json) {
    try {
      return EducationV2(
        complete: List<int>.from((json['complete'] ?? []).map((x) => x)),
        current: json['current'] != null ? CurrentEducation.fromJson(json['current']) : null,
      );
    } catch (e) {
      log('Error parsing EducationV2: $e');
      return EducationV2(complete: <int>[], current: null);
    }
  }

  Map<String, dynamic> toJson() => {
        "complete": List<dynamic>.from(complete.map((x) => x)),
        "current": current?.toJson(),
      };
}

class CurrentEducation {
  final int id;
  final int until;

  CurrentEducation({
    required this.id,
    required this.until,
  });

  factory CurrentEducation.fromJson(Map<String, dynamic> json) => CurrentEducation(
        id: json['id'] ?? 0,
        until: json['until'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "until": until,
      };
}
