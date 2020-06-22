import 'dart:convert';
import '../../main.dart';

ForeignStockOutModel foreignStockOutModelFromJson(String str) =>
    ForeignStockOutModel.fromJson(json.decode(str));

String foreignStockOutModelToJson(ForeignStockOutModel data) =>
    json.encode(data.toJson());

class ForeignStockOutItem {
  int id;
  int quantity;
  int cost;

  ForeignStockOutItem({
    this.id,
    this.quantity,
    this.cost,
  });

  factory ForeignStockOutItem.fromJson(Map<String, dynamic> json) =>
      ForeignStockOutItem(
        id: json["id"],
        quantity: json["quantity"],
        cost: json["cost"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "quantity": quantity,
        "cost": cost,
      };
}

class ForeignStockOutModel {
  String client;
  String version;
  String authorName;
  int authorId;
  String country;
  List<ForeignStockOutItem> items;

  ForeignStockOutModel(
      {this.client,
      this.version,
      this.authorName,
      this.authorId,
      this.country,
      this.items}) {
    client = "Torn PDA";
    version = appVersion;
    items = List<ForeignStockOutItem>();
  }

  factory ForeignStockOutModel.fromJson(Map<String, dynamic> json) =>
      ForeignStockOutModel(
        client: json["client"],
        version: json["version"],
        authorName: json["author_name"],
        authorId: json["author_id"],
        country: json["country"],
        items: List<ForeignStockOutItem>.from(
            json["items"].map((x) => ForeignStockOutItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "client": client,
        "version": version,
        "author_name": authorName,
        "author_id": authorId,
        "country": country,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}
