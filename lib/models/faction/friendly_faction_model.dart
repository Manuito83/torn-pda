// To parse this JSON data, do
//
//     final friendlyFaction = friendlyFactionFromJson(jsonString);

// Dart imports:
import 'dart:convert';

FriendlyFaction friendlyFactionFromJson(String str) => FriendlyFaction.fromJson(json.decode(str));

String friendlyFactionToJson(FriendlyFaction data) => json.encode(data.toJson());

class FriendlyFaction {
  FriendlyFaction({
    this.name,
    this.id,
  });

  String? name;
  int? id;

  factory FriendlyFaction.fromJson(Map<String, dynamic> json) => FriendlyFaction(
    name: json["name"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "id": id,
  };
}
