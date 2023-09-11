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
        player: json["player"],
        spouse: json["spouse"],
        timestamp: json["timestamp"],
        total: json["total"],
        error: json["error"],
      );

  Map<String, dynamic> toJson() => {
        "player": player,
        "spouse": spouse,
        "timestamp": timestamp,
        "total": total,
        "error": error,
      };
}
