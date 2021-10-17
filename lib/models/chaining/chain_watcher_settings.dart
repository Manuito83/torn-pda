// To parse this JSON data, do
//
//     final chainWatcherModel = chainWatcherModelFromJson(jsonString);

import 'dart:convert';

ChainWatcherSettings chainWatcherModelFromJson(String str) => ChainWatcherSettings.fromJson(json.decode(str));

String chainWatcherModelToJson(ChainWatcherSettings data) => json.encode(data.toJson());

class ChainWatcherSettings {
  ChainWatcherSettings({
    this.green2Enabled,
    this.green2Max,
    this.green2Min,
    this.orange1Enabled,
    this.orange1Max,
    this.orange1Min,
    this.orange2Enabled,
    this.orange2Max,
    this.orange2Min,
    this.red1Enabled,
    this.red1Max,
    this.red1Min,
    this.red2Enabled,
    this.red2Max,
    this.red2Min,
  });

  bool green2Enabled;
  double green2Max;
  double green2Min;
  bool orange1Enabled;
  double orange1Max;
  double orange1Min;
  bool orange2Enabled;
  double orange2Max;
  double orange2Min;
  bool red1Enabled;
  double red1Max;
  double red1Min;
  bool red2Enabled;
  double red2Max;
  double red2Min;

  factory ChainWatcherSettings.fromJson(Map<String, dynamic> json) => ChainWatcherSettings(
        green2Enabled: json["green2Enabled"] == null ? true : json["green2Enabled"],
        green2Max: json["green2Max"] == null ? 150 : json["green2Max"],
        green2Min: json["green2Min"] == null ? 120 : json["green2Min"],
        orange1Enabled: json["orange1Enabled"] == null ? true : json["orange1Enabled"],
        orange1Max: json["orange1Max"] == null ? 120 : json["orange1Max"],
        orange1Min: json["orange1Min"] == null ? 90 : json["orange1Min"],
        orange2Enabled: json["orange2Enabled"] == null ? true : json["orange2Enabled"],
        orange2Max: json["orange2Max"] == null ? 90 : json["orange2Max"],
        orange2Min: json["orange2Min"] == null ? 60 : json["orange2Min"],
        red1Enabled: json["red1Enabled"] == null ? true : json["red1Enabled"],
        red1Max: json["red1Max"] == null ? 60 : json["red1Max"],
        red1Min: json["red1Min"] == null ? 30 : json["red1Min"],
        red2Enabled: json["red2Enabled"] == null ? true : json["red2Enabled"],
        red2Max: json["red2Max"] == null ? 30 : json["red2Max"],
        red2Min: json["red2Min"] == null ? 0 : json["red2Min"],
      );

  Map<String, dynamic> toJson() => {
        "green2Enabled": green2Enabled == null ? null : green2Enabled,
        "green2Max": green2Max == null ? null : green2Max,
        "green2Min": green2Min == null ? null : green2Min,
        "orange1Enabled": orange1Enabled == null ? null : orange1Enabled,
        "orange1Max": orange1Max == null ? null : orange1Max,
        "orange1Min": orange1Min == null ? null : orange1Min,
        "orange2Enabled": orange2Enabled == null ? null : orange2Enabled,
        "orange2Max": orange2Max == null ? null : orange2Max,
        "orange2Min": orange2Min == null ? null : orange2Min,
        "red1Enabled": red1Enabled == null ? null : red1Enabled,
        "red1Max": red1Max == null ? null : red1Max,
        "red1Min": red1Min == null ? null : red1Min,
        "red2Enabled": red2Enabled == null ? null : red2Enabled,
        "red2Max": red2Max == null ? null : red2Max,
        "red2Min": red2Min == null ? null : red2Min,
      };
}
