// To parse this JSON data, do
//
//     final statsChartTornStats = statsChartTornStatsFromJson(jsonString);

import 'dart:convert';

StatsChartTornStats statsChartTornStatsFromJson(String str) => StatsChartTornStats.fromJson(json.decode(str));

String statsChartTornStatsToJson(StatsChartTornStats data) => json.encode(data.toJson());

class StatsChartTornStats {
  StatsChartTornStats({
    this.status,
    this.message,
    this.shareHof,
    this.data,
  });

  bool? status;
  String? message;
  int? shareHof;
  List<Datum>? data;

  factory StatsChartTornStats.fromJson(Map<String, dynamic> json) => StatsChartTornStats(
        status: json["status"] == null ? null : json["status"],
        message: json["message"] == null ? null : json["message"],
        shareHof: json["share_hof"] == null ? null : json["share_hof"],
        data: json["data"] == null ? null : List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status == null ? null : status,
        "message": message == null ? null : message,
        "share_hof": shareHof == null ? null : shareHof,
        "data": data == null ? null : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class Datum {
  Datum({
    this.strength,
    this.defense,
    this.speed,
    this.dexterity,
    this.total,
    this.timestamp,
  });

  int? strength;
  int? defense;
  int? speed;
  int? dexterity;
  int? total;
  int? timestamp;

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        strength: json["strength"] == null ? null : json["strength"],
        defense: json["defense"] == null ? null : json["defense"],
        speed: json["speed"] == null ? null : json["speed"],
        dexterity: json["dexterity"] == null ? null : json["dexterity"],
        total: json["total"] == null ? null : json["total"],
        timestamp: json["timestamp"] == null ? null : json["timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "strength": strength == null ? null : strength,
        "defense": defense == null ? null : defense,
        "speed": speed == null ? null : speed,
        "dexterity": dexterity == null ? null : dexterity,
        "total": total == null ? null : total,
        "timestamp": timestamp == null ? null : timestamp,
      };
}
