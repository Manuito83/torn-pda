// To parse this JSON data, do
//
//     final shortcut = shortcutFromJson(jsonString);

// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

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

  bool active;
  bool visible;
  String name;
  String nickname;
  String url;
  String originalName;
  String originalNickname;
  String originalUrl;
  String iconUrl;
  Color color;
  bool isCustom;
  bool addPlayerId;
  bool addFactionId;
  bool addCompanyId;

  factory Shortcut.fromJson(Map<String, dynamic> json) => Shortcut(
        active: json["active"] == null ? null : json["active"],
        visible: json["activeAnimation"] == null ? null : json["activeAnimation"],
        name: json["name"] == null ? null : json["name"],
        nickname: json["nickname"] == null ? null : json["nickname"],
        url: json["url"] == null ? null : json["url"],
        originalName: json["originalName"] == null ? null : json["originalName"],
        originalNickname: json["originalNickname"] == null ? null : json["originalNickname"],
        originalUrl: json["originalUrl"] == null ? null : json["originalUrl"],
        iconUrl: json["iconUrl"] == null ? null : json["iconUrl"],
        color: json["color"] == null ? null : Color(int.parse(json["color"].split('(0x')[1].split(')')[0], radix: 16)),
        isCustom: json["isCustom"] == null ? null : json["isCustom"],
        addPlayerId: json["addPlayerId"],
        addFactionId: json["addFactionId"],
        addCompanyId: json["addCompanyId"],
      );

  Map<String, dynamic> toJson() => {
        "active": active == null ? null : active,
        "activeAnimation": visible == null ? null : visible,
        "name": name == null ? null : name,
        "nickname": nickname == null ? null : nickname,
        "url": url == null ? null : url,
        "originalName": originalName == null ? null : originalName,
        "originalNickname": originalNickname == null ? null : originalNickname,
        "originalUrl": originalUrl == null ? null : originalUrl,
        "iconUrl": iconUrl == null ? null : iconUrl,
        "color": color == null ? null : color.toString(),
        "isCustom": isCustom == null ? null : isCustom,
        "addPlayerId": addPlayerId,
        "addFactionId": addFactionId,
        "addCompanyId": addCompanyId,
      };
}
