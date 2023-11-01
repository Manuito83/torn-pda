// To parse this JSON data, do
//
//     final chainWatcherModel = chainWatcherModelFromJson(jsonString);

import 'dart:convert';

ChainWatcherSettings chainWatcherModelFromJson(String str) => ChainWatcherSettings.fromJson(json.decode(str));

String chainWatcherModelToJson(ChainWatcherSettings data) => json.encode(data.toJson());

class ChainWatcherSettings {
  ChainWatcherSettings({
    this.green2Enabled = true,
    this.green2Max = 150,
    this.green2Min = 120,
    this.orange1Enabled = true,
    this.orange1Max = 120,
    this.orange1Min = 90,
    this.orange2Enabled = true,
    this.orange2Max = 90,
    this.orange2Min = 60,
    this.red1Enabled = true,
    this.red1Max = 60,
    this.red1Min = 30,
    this.red2Enabled = true,
    this.red2Max = 30,
    this.red2Min = 0,
    this.panicEnabled = false,
    this.panicValue = 40,
    this.apiFailureAlert = true,
    this.apiFailurePanic = true,
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
  bool panicEnabled;
  double panicValue;
  bool apiFailureAlert;
  bool apiFailurePanic;

  factory ChainWatcherSettings.fromJson(Map<String, dynamic> json) => ChainWatcherSettings(
        green2Enabled: json["green2Enabled"] ?? true,
        green2Max: json["green2Max"] ?? 150,
        green2Min: json["green2Min"] ?? 120,
        orange1Enabled: json["orange1Enabled"] ?? true,
        orange1Max: json["orange1Max"] ?? 120,
        orange1Min: json["orange1Min"] ?? 90,
        orange2Enabled: json["orange2Enabled"] ?? true,
        orange2Max: json["orange2Max"] ?? 90,
        orange2Min: json["orange2Min"] ?? 60,
        red1Enabled: json["red1Enabled"] ?? true,
        red1Max: json["red1Max"] ?? 60,
        red1Min: json["red1Min"] ?? 30,
        red2Enabled: json["red2Enabled"] ?? true,
        red2Max: json["red2Max"] ?? 30,
        red2Min: json["red2Min"] ?? 0,
        panicEnabled: json["panicEnabled"] ?? true,
        panicValue: json["panicValue"] ?? 40,
        apiFailureAlert: json["apiFailureAlert"] ?? true,
        apiFailurePanic: json["apiFailurePanic"] ?? true,
      );

  Map<String, dynamic> toJson() => {
        "green2Enabled": green2Enabled,
        "green2Max": green2Max,
        "green2Min": green2Min,
        "orange1Enabled": orange1Enabled,
        "orange1Max": orange1Max,
        "orange1Min": orange1Min,
        "orange2Enabled": orange2Enabled,
        "orange2Max": orange2Max,
        "orange2Min": orange2Min,
        "red1Enabled": red1Enabled,
        "red1Max": red1Max,
        "red1Min": red1Min,
        "red2Enabled": red2Enabled,
        "red2Max": red2Max,
        "red2Min": red2Min,
        "panicEnabled": panicEnabled,
        "panicValue": panicValue,
        "apiFailureAlert": apiFailureAlert,
        "apiFailurePanic": apiFailurePanic,
      };
}
