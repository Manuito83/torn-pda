// To parse this JSON data, do
//
//     final shortcut = shortcutFromJson(jsonString);

// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:torn_pda/utils/color_json.dart';

Shortcut shortcutFromJson(String str) => Shortcut.fromJson(json.decode(str));

String shortcutToJson(Shortcut data) => json.encode(data.toJson());

class Shortcut {
  Shortcut({
    this.active = false,
    this.visible = true,
    this.name = '',
    this.nickname = '',
    this.url = '',
    this.originalName = '',
    this.originalNickname = '',
    this.originalUrl = '',
    this.iconUrl = '',
    this.color = Colors.grey,
    this.isCustom = false,
    this.addPlayerId = false,
    this.addFactionId = false,
    this.addCompanyId = false,
  });

  bool? active;
  bool? visible;
  String? name;
  String? nickname;
  String? url;
  String? originalName;
  String? originalNickname;
  String? originalUrl;
  String? iconUrl;
  Color? color;
  bool? isCustom;
  bool? addPlayerId;
  bool? addFactionId;
  bool? addCompanyId;

  factory Shortcut.fromJson(Map<String, dynamic> json) => Shortcut(
        active: json["active"],
        visible: json["activeAnimation"],
        name: json["name"],
        nickname: json["nickname"],
        url: json["url"],
        originalName: json["originalName"],
        originalNickname: json["originalNickname"],
        originalUrl: json["originalUrl"],
        iconUrl: json["iconUrl"],
        color: getColorFromJson(json["color"]),
        isCustom: json["isCustom"],
        addPlayerId: json["addPlayerId"],
        addFactionId: json["addFactionId"],
        addCompanyId: json["addCompanyId"],
      );

  Map<String, dynamic> toJson() => {
        "active": active,
        "activeAnimation": visible,
        "name": name,
        "nickname": nickname,
        "url": url,
        "originalName": originalName,
        "originalNickname": originalNickname,
        "originalUrl": originalUrl,
        "iconUrl": iconUrl,
        "color": color?.toString(),
        "isCustom": isCustom,
        "addPlayerId": addPlayerId,
        "addFactionId": addFactionId,
        "addCompanyId": addCompanyId,
      };
}
