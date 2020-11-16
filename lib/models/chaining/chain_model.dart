// To parse this JSON data, do
//
//     final chainModel = chainModelFromJson(jsonString);

import 'dart:convert';

ChainModel chainModelFromJson(String str) => ChainModel.fromJson(json.decode(str));

String chainModelToJson(ChainModel data) => json.encode(data.toJson());

class ChainModel {
  ChainDetails chain;

  ChainModel({
    this.chain,
  });

  factory ChainModel.fromJson(Map<String, dynamic> json) => ChainModel(
    chain: ChainDetails.fromJson(json["chain"]),
  );

  Map<String, dynamic> toJson() => {
    "chain": chain.toJson(),
  };
}

class ChainDetails {
  int current;
  int max;
  int timeout;
  double modifier;
  int cooldown;
  int start;

  ChainDetails({
    this.current = 0,
    this.max = 0,
    this.timeout = 0,
    this.modifier= 0,
    this.cooldown = 0,
    this.start = 0,
  });

  factory ChainDetails.fromJson(Map<String, dynamic> json) => ChainDetails(
    current: json["current"] == null ? null : json["current"],
    max: json["max"] == null ? null : json["max"],
    timeout: json["timeout"] == null ? null : json["timeout"],
    modifier: json["modifier"] == null ? null : json["modifier"].toDouble(),
    cooldown: json["cooldown"] == null ? null : json["cooldown"],
    start: json["start"] == null ? null : json["start"],
  );

  Map<String, dynamic> toJson() => {
    "current": current == null ? null : current,
    "max": max == null ? null : max,
    "timeout": timeout == null ? null : timeout,
    "modifier": modifier == null ? null : modifier,
    "cooldown": cooldown == null ? null : cooldown,
    "start": start == null ? null : start,
  };
}
