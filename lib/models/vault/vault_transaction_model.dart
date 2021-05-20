// To parse this JSON data, do
//
//     final vaultModel = vaultModelFromJson(jsonString);

import 'dart:convert';

VaultTransactionModel vaultTransactionModelFromJson(String str) => VaultTransactionModel.fromJson(json.decode(str));

String vaultTransactionModelToJson(VaultTransactionModel data) => json.encode(data.toJson());

class VaultTransactionModel {
  VaultTransactionModel({
    this.date,
    this.playerTransaction,
    this.amount,
    this.isDeposit,
    this.balance,
  });

  int date;
  bool playerTransaction;
  int amount;
  bool isDeposit;
  int balance;

  factory VaultTransactionModel.fromJson(Map<String, dynamic> json) => VaultTransactionModel(
    date: json["date"] == null ? null : json["date"],
    playerTransaction: json["playerTransaction"] == null ? null : json["playerTransaction"],
    amount: json["amount"] == null ? null : json["amount"],
    isDeposit: json["isDeposit"] == null ? null : json["isDeposit"],
    balance: json["balance"] == null ? null : json["balance"],
  );

  Map<String, dynamic> toJson() => {
    "date": date == null ? null : date,
    "playerTransaction": playerTransaction == null ? null : playerTransaction,
    "amount": amount == null ? null : amount,
    "isDeposit": isDeposit == null ? null : isDeposit,
    "balance": balance == null ? null : balance,
  };
}
