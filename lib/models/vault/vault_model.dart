// To parse this JSON data, do
//
//     final vaultModel = vaultModelFromJson(jsonString);

import 'dart:convert';

VaultModel vaultModelFromJson(String str) => VaultModel.fromJson(json.decode(str));

String vaultModelToJson(VaultModel data) => json.encode(data.toJson());

class VaultModel {
  VaultModel({
    this.date,
    this.playerTransaction,
    this.amount,
    this.isDeposit,
    this.marketPrice,
    this.balance,
  });

  int date;
  bool playerTransaction;
  int amount;
  bool isDeposit;
  int marketPrice;
  int balance;

  factory VaultModel.fromJson(Map<String, dynamic> json) => VaultModel(
    date: json["date"] == null ? null : json["date"],
    playerTransaction: json["playerTransaction"] == null ? null : json["playerTransaction"],
    amount: json["amount"] == null ? null : json["amount"],
    isDeposit: json["isDeposit"] == null ? null : json["isDeposit"],
    marketPrice: json["market_price"] == null ? null : json["market_price"],
    balance: json["balance"] == null ? null : json["balance"],
  );

  Map<String, dynamic> toJson() => {
    "date": date == null ? null : date,
    "playerTransaction": playerTransaction == null ? null : playerTransaction,
    "amount": amount == null ? null : amount,
    "isDeposit": isDeposit == null ? null : isDeposit,
    "market_price": marketPrice == null ? null : marketPrice,
    "balance": balance == null ? null : balance,
  };
}
