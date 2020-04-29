// To parse this JSON data, do
//
//     final barsModel = barsModelFromJson(jsonString);

import 'dart:convert';

BarsModel barsModelFromJson(String str) => BarsModel.fromJson(json.decode(str));

String barsModelToJson(BarsModel data) => json.encode(data.toJson());

class BarsModel {
  int serverTime;
  // PersonalBars class covers 4 different bars, as the parameters are the same,
  // this might change in the future
  PersonalBars happy;
  PersonalBars life;
  PersonalBars energy;
  PersonalBars nerve;
  ChainBars chain;

  BarsModel({
    this.serverTime,
    this.happy,
    this.life,
    this.energy,
    this.nerve,
    this.chain,
  });

  factory BarsModel.fromJson(Map<String, dynamic> json) => BarsModel(
    serverTime: json["server_time"] == null ? null : json["server_time"],
    happy: json["happy"] == null ? null : PersonalBars.fromJson(json["happy"]),
    life: json["life"] == null ? null : PersonalBars.fromJson(json["life"]),
    energy: json["energy"] == null ? null : PersonalBars.fromJson(json["energy"]),
    nerve: json["nerve"] == null ? null : PersonalBars.fromJson(json["nerve"]),
    chain: json["chain"] == null ? null : ChainBars.fromJson(json["chain"]),
  );

  Map<String, dynamic> toJson() => {
    "server_time": serverTime == null ? null : serverTime,
    "happy": happy == null ? null : happy.toJson(),
    "life": life == null ? null : life.toJson(),
    "energy": energy == null ? null : energy.toJson(),
    "nerve": nerve == null ? null : nerve.toJson(),
    "chain": chain == null ? null : chain.toJson(),
  };
}

class ChainBars {
  int current;
  int maximum;
  int timeout;
  double modifier;
  int cooldown;

  ChainBars({
    this.current,
    this.maximum,
    this.timeout,
    this.modifier,
    this.cooldown,
  });

  factory ChainBars.fromJson(Map<String, dynamic> json) => ChainBars(
    current: json["current"] == null ? null : json["current"],
    maximum: json["maximum"] == null ? null : json["maximum"],
    timeout: json["timeout"] == null ? null : json["timeout"],
    modifier: json["modifier"] == null ? null : json["modifier"].toDouble(),
    cooldown: json["cooldown"] == null ? null : json["cooldown"],
  );

  Map<String, dynamic> toJson() => {
    "current": current == null ? null : current,
    "maximum": maximum == null ? null : maximum,
    "timeout": timeout == null ? null : timeout,
    "modifier": modifier == null ? null : modifier,
    "cooldown": cooldown == null ? null : cooldown,
  };
}

class PersonalBars {
  int current;
  int maximum;
  int increment;
  int interval;
  int ticktime;
  int fulltime;

  PersonalBars({
    this.current,
    this.maximum,
    this.increment,
    this.interval,
    this.ticktime,
    this.fulltime,
  });

  factory PersonalBars.fromJson(Map<String, dynamic> json) => PersonalBars(
    current: json["current"] == null ? null : json["current"],
    maximum: json["maximum"] == null ? null : json["maximum"],
    increment: json["increment"] == null ? null : json["increment"],
    interval: json["interval"] == null ? null : json["interval"],
    ticktime: json["ticktime"] == null ? null : json["ticktime"],
    fulltime: json["fulltime"] == null ? null : json["fulltime"],
  );

  Map<String, dynamic> toJson() => {
    "current": current == null ? null : current,
    "maximum": maximum == null ? null : maximum,
    "increment": increment == null ? null : increment,
    "interval": interval == null ? null : interval,
    "ticktime": ticktime == null ? null : ticktime,
    "fulltime": fulltime == null ? null : fulltime,
  };
}
