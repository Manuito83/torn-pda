// To parse this JSON data, do
//
//     final bazaarModel = bazaarModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

BazaarModel bazaarModelFromJson(String str) => BazaarModel.fromJson(json.decode(str));

String bazaarModelToJson(BazaarModel data) => json.encode(data.toJson());

class BazaarModel {
  BazaarModel({
    this.bazaar,
  });

  List<Bazaar> bazaar;

  factory BazaarModel.fromJson(Map<String, dynamic> json) => BazaarModel(
    bazaar: json["bazaar"] == null ? null : List<Bazaar>.from(json["bazaar"].map((x) => Bazaar.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "bazaar": bazaar == null ? null : List<dynamic>.from(bazaar.map((x) => x.toJson())),
  };
}

class Bazaar {
  Bazaar({
    this.id,
    this.name,
    this.type,
    this.quantity,
    this.price,
    this.marketPrice,
  });

  int id;
  String name;
  String type;
  int quantity;
  int price;
  int marketPrice;

  factory Bazaar.fromJson(Map<String, dynamic> json) => Bazaar(
    id: json["ID"] == null ? null : json["ID"],
    name: json["name"] == null ? null : json["name"],
    type: json["type"] == null ? null : json["type"],
    quantity: json["quantity"] == null ? null : json["quantity"],
    price: json["price"] == null ? null : json["price"],
    marketPrice: json["market_price"] == null ? null : json["market_price"],
  );

  Map<String, dynamic> toJson() => {
    "ID": id == null ? null : id,
    "name": name == null ? null : name,
    "type": type == null ? null : type,
    "quantity": quantity == null ? null : quantity,
    "price": price == null ? null : price,
    "market_price": marketPrice == null ? null : marketPrice,
  };
}
