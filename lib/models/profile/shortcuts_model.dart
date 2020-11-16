// To parse this JSON data, do
//
//     final shortcut = shortcutFromJson(jsonString);

import 'dart:convert';
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
    this.iconUrl = '',
    this.color = Colors.grey,
    this.isCustom = false,
  });

  bool active;
  bool visible;
  String name;
  String nickname;
  String url;
  String iconUrl;
  Color color;
  bool isCustom;

  factory Shortcut.fromJson(Map<String, dynamic> json) => Shortcut(
    active: json["active"] == null ? null : json["active"],
    visible: json["activeAnimation"] == null ? null : json["activeAnimation"],
    name: json["name"] == null ? null : json["name"],
    nickname: json["nickname"] == null ? null : json["nickname"],
    url: json["url"] == null ? null : json["url"],
    iconUrl: json["iconUrl"] == null ? null : json["iconUrl"],
    color: json["color"] == null ? null : Color(int.parse(json["color"].split('(0x')[1].split(')')[0], radix: 16)),
    isCustom: json["isCustom"] == null ? null : json["isCustom"],
  );

  Map<String, dynamic> toJson() => {
    "active": active == null ? null : active,
    "activeAnimation": visible == null ? null : visible,
    "name": name == null ? null : name,
    "nickname": nickname == null ? null : nickname,
    "url": url == null ? null : url,
    "iconUrl": iconUrl == null ? null : iconUrl,
    "color": color == null ? null : color.toString(),
    "isCustom": isCustom == null ? null : isCustom,
  };
}