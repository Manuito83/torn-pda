// To parse this JSON data, do
//
//     final tabSaveModel = tabSaveModelFromJson(jsonString);

import 'dart:convert';

TabSaveModel tabSaveModelFromJson(String str) => TabSaveModel.fromJson(json.decode(str));

String tabSaveModelToJson(TabSaveModel data) => json.encode(data.toJson());

class TabSaveModel {
  TabSaveModel({
    this.tabsSave,
  });

  List<TabsSave> tabsSave;

  factory TabSaveModel.fromJson(Map<String, dynamic> json) => TabSaveModel(
    tabsSave: json["tabsSave"] == null ? null : List<TabsSave>.from(json["tabsSave"].map((x) => TabsSave.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "tabsSave": tabsSave == null ? null : List<dynamic>.from(tabsSave.map((x) => x.toJson())),
  };
}

class TabsSave {
  TabsSave({
    this.url,
    this.chat,
    this.historyBack,
    this.historyForward,
  });

  String url;
  bool chat;
  List<String> historyBack;
  List<String> historyForward;

  factory TabsSave.fromJson(Map<String, dynamic> json) => TabsSave(
    url: json["url"] == null ? null : json["url"],
    chat: json["chat"] == null ? null : json["chat"],
    historyBack: json["historyBack"] == null ? null : List<String>.from(json["historyBack"].map((x) => x)),
    historyForward: json["historyForward"] == null ? null : List<String>.from(json["historyForward"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "url": url == null ? null : url,
    "chat": chat == null ? null : chat,
    "historyBack": historyBack == null ? null : List<dynamic>.from(historyBack.map((x) => x)),
    "historyForward": historyForward == null ? null : List<dynamic>.from(historyForward.map((x) => x)),
  };
}
