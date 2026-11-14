import 'package:flutter/material.dart';

/// Local look of one player in chat
class ChatPersonStyle {
  const ChatPersonStyle({
    this.name = '',
    this.nameColor,
    this.highlight = false,
    this.highlightColor,
    this.nickname = '',
  });

  static const ChatPersonStyle none = ChatPersonStyle();
  static const int nicknameMax = 30;

  static const List<(String, Color)> nameColors = [
    ('Red', Color(0xFFE53935)),
    ('Orange', Color(0xFFFB8C00)),
    ('Yellow', Color(0xFFFDD835)),
    ('Green', Color(0xFF43A047)),
    ('Teal', Color(0xFF00897B)),
    ('Blue', Color(0xFF1E88E5)),
    ('Purple', Color(0xFF8E24AA)),
    ('Pink', Color(0xFFD81B60)),
  ];

  static const List<(String, Color)> highlightColors = [
    ('Red', Color(0xFFFFCDD2)),
    ('Orange', Color(0xFFFFE0B2)),
    ('Yellow', Color(0xFFFFF59D)),
    ('Green', Color(0xFFC8E6C9)),
    ('Teal', Color(0xFFB2DFDB)),
    ('Blue', Color(0xFFBBDEFB)),
    ('Purple', Color(0xFFE1BEE7)),
    ('Pink', Color(0xFFF8BBD0)),
  ];

  /// Last known, for lists
  final String name;
  final Color? nameColor;
  final bool highlight;

  /// Null uses the mention color
  final Color? highlightColor;
  final String nickname;

  bool get isEmpty => nameColor == null && !highlight && nickname.isEmpty;

  ChatPersonStyle copyWith({
    String? name,
    Color? Function()? nameColor,
    bool? highlight,
    Color? Function()? highlightColor,
    String? nickname,
  }) => ChatPersonStyle(
    name: name ?? this.name,
    nameColor: nameColor == null ? this.nameColor : nameColor(),
    highlight: highlight ?? this.highlight,
    highlightColor: highlightColor == null ? this.highlightColor : highlightColor(),
    nickname: nickname == null
        ? this.nickname
        : nickname.trim().substring(0, nickname.trim().length.clamp(0, nicknameMax)),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (nameColor != null) 'color': nameColor!.toARGB32(),
    if (highlight) 'highlight': true,
    if (highlightColor != null) 'highlightColor': highlightColor!.toARGB32(),
    if (nickname.isNotEmpty) 'nickname': nickname,
  };

  static ChatPersonStyle? fromJson(Object? json) {
    if (json is! Map) return null;
    final color = json['color'];
    final highlightColor = json['highlightColor'];
    final style = ChatPersonStyle(
      name: json['name'] is String ? json['name'] as String : '',
      nameColor: color is int ? Color(color) : null,
      highlight: json['highlight'] == true,
      highlightColor: highlightColor is int ? Color(highlightColor) : null,
      nickname: json['nickname'] is String ? json['nickname'] as String : '',
    );
    return style.isEmpty ? null : style;
  }
}
