// To parse this JSON data, do
//
//     final vaultStatusModel = vaultStatusModelFromJson(jsonString);

import 'dart:convert';

VaultStatusModel vaultStatusModelFromJson(String str) => VaultStatusModel.fromJson(json.decode(str));

String vaultStatusModelToJson(VaultStatusModel data) => json.encode(data.toJson());

class VaultStatusModel {
  VaultStatusModel({
    this.player,
    this.spouse,
    this.timestamp,
    this.total,
    this.error = false,
  });

  int? player;
  int? spouse;
  int? timestamp;
  int? total;
  bool? error;

  factory VaultStatusModel.fromJson(Map<String, dynamic> json) => VaultStatusModel(
        player: json["player"] == null ? null : json["player"],
        spouse: json["spouse"] == null ? null : json["spouse"],
        timestamp: json["timestamp"] == null ? null : json["timestamp"],
        total: json["total"] == null ? null : json["total"],
        error: json["error"] == null ? null : json["error"],
      );

  Map<String, dynamic> toJson() => {
        "player": player == null ? null : player,
        "spouse": spouse == null ? null : spouse,
        "timestamp": timestamp == null ? null : timestamp,
        "total": total == null ? null : total,
        "error": error == null ? null : error,
      };
}
