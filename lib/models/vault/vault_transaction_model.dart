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

  int? date;
  bool? playerTransaction;
  int? amount;
  bool? isDeposit;
  int? balance;

  factory VaultTransactionModel.fromJson(Map<String, dynamic> json) => VaultTransactionModel(
    date: json["date"],
    playerTransaction: json["playerTransaction"],
    amount: json["amount"],
    isDeposit: json["isDeposit"],
    balance: json["balance"],
  );

  Map<String, dynamic> toJson() => {
    "date": date,
    "playerTransaction": playerTransaction,
    "amount": amount,
    "isDeposit": isDeposit,
    "balance": balance,
  };
}
