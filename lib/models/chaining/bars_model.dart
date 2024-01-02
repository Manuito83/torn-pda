// To parse this JSON data, do
//
//     final barsModel = barsModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

BarsModel barsModelFromJson(String str) => BarsModel.fromJson(json.decode(str));

String barsModelToJson(BarsModel data) => json.encode(data.toJson());

class BarsModel {
  int? serverTime;
  // PersonalBars class covers 4 different bars, as the parameters are the same,
  // this might change in the future
  PersonalBars? happy;
  PersonalBars? life;
  PersonalBars? energy;
  PersonalBars? nerve;
  ChainBars? chain;

  BarsModel({
    this.serverTime,
    this.happy,
    this.life,
    this.energy,
    this.nerve,
    this.chain,
  });

  factory BarsModel.fromJson(Map<String, dynamic> json) => BarsModel(
        serverTime: json["server_time"],
        happy: json["happy"] == null ? null : PersonalBars.fromJson(json["happy"]),
        life: json["life"] == null ? null : PersonalBars.fromJson(json["life"]),
        energy: json["energy"] == null ? null : PersonalBars.fromJson(json["energy"]),
        nerve: json["nerve"] == null ? null : PersonalBars.fromJson(json["nerve"]),
        chain: json["chain"] == null ? null : ChainBars.fromJson(json["chain"]),
      );

  Map<String, dynamic> toJson() => {
        "server_time": serverTime,
        "happy": happy?.toJson(),
        "life": life?.toJson(),
        "energy": energy?.toJson(),
        "nerve": nerve?.toJson(),
        "chain": chain?.toJson(),
      };
}

class ChainBars {
  int? current;
  int? maximum;
  int? timeout;
  double? modifier;
  int? cooldown;

  ChainBars({
    this.current,
    this.maximum,
    this.timeout,
    this.modifier,
    this.cooldown,
  });

  factory ChainBars.fromJson(Map<String, dynamic> json) => ChainBars(
        current: json["current"],
        maximum: json["maximum"],
        timeout: json["timeout"],
        modifier: json["modifier"]?.toDouble(),
        cooldown: json["cooldown"],
      );

  Map<String, dynamic> toJson() => {
        "current": current,
        "maximum": maximum,
        "timeout": timeout,
        "modifier": modifier,
        "cooldown": cooldown,
      };
}

class PersonalBars {
  int? current;
  int? maximum;
  int? increment;
  int? interval;
  int? ticktime;
  int? fulltime;

  PersonalBars({
    this.current,
    this.maximum,
    this.increment,
    this.interval,
    this.ticktime,
    this.fulltime,
  });

  factory PersonalBars.fromJson(Map<String, dynamic> json) => PersonalBars(
        current: json["current"],
        maximum: json["maximum"],
        increment: json["increment"],
        interval: json["interval"],
        ticktime: json["ticktime"],
        fulltime: json["fulltime"],
      );

  Map<String, dynamic> toJson() => {
        "current": current,
        "maximum": maximum,
        "increment": increment,
        "interval": interval,
        "ticktime": ticktime,
        "fulltime": fulltime,
      };
}
