// To parse this JSON data, do
//
//     final shortcut = shortcutFromJson(jsonString);

import 'dart:convert';

Shortcut shortcutFromJson(String str) => Shortcut.fromJson(json.decode(str));

String shortcutToJson(Shortcut data) => json.encode(data.toJson());

class Shortcut {
  Shortcut({
    this.active = false,
    this.name = '',
    this.nickname = '',
    this.url = '',
    this.iconUrl = '',
  });

  bool active;
  String name;
  String nickname;
  String url;
  String iconUrl;

  factory Shortcut.fromJson(Map<String, dynamic> json) => Shortcut(
    active: json["active"] == null ? null : json["active"],
    name: json["name"] == null ? null : json["name"],
    nickname: json["nickname"] == null ? null : json["nickname"],
    url: json["url"] == null ? null : json["url"],
    iconUrl: json["iconUrl"] == null ? null : json["iconUrl"],
  );

  Map<String, dynamic> toJson() => {
    "active": active == null ? null : active,
    "name": name == null ? null : name,
    "nickname": nickname == null ? null : nickname,
    "url": url == null ? null : url,
    "iconUrl": iconUrl == null ? null : iconUrl,
  };
}