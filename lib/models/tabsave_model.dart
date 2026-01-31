// To parse this JSON data, do
//
//     final tabSaveModel = tabSaveModelFromJson(jsonString);

import 'dart:convert';

import 'package:flutter/material.dart';

TabSaveModel tabSaveModelFromJson(String str) => TabSaveModel.fromJson(json.decode(str));

String tabSaveModelToJson(TabSaveModel data) => json.encode(data.toJson());

class TabSaveModel {
  TabSaveModel({
    this.tabsSave,
  });

  List<TabsSave>? tabsSave;

  factory TabSaveModel.fromJson(Map<String, dynamic> json) => TabSaveModel(
        tabsSave:
            json["tabsSave"] == null ? null : List<TabsSave>.from(json["tabsSave"].map((x) => TabsSave.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "tabsSave": tabsSave == null ? null : List<dynamic>.from(tabsSave!.map((x) => x.toJson())),
      };
}

class TabsSave {
  TabsSave({
    this.tabUid,
    this.tabKey,
    this.url,
    this.pageTitle,
    this.chatRemovalActive,
    this.historyBack,
    this.historyForward,
    this.isLocked = false,
    this.isLockFull = false,
    this.customName = "",
    this.customNameInTitle = false,
    this.customNameInTab = true,
    this.lastUsedTime = 0,
  });

  String? tabUid;
  GlobalKey? tabKey;
  String? url;
  String? pageTitle;
  bool? chatRemovalActive;
  List<String?>? historyBack;
  List<String?>? historyForward;
  bool isLocked;
  bool isLockFull;
  String customName;
  bool customNameInTitle;
  bool customNameInTab;
  int lastUsedTime;

  factory TabsSave.fromJson(Map<String, dynamic> json) => TabsSave(
        tabUid: json["tabUid"],
        tabKey: json["tabKey"],
        url: json["url"],
        pageTitle: json["pageTitle"],
        chatRemovalActive: json["chat"],
        historyBack: json["historyBack"] == null ? null : List<String>.from(json["historyBack"].map((x) => x)),
        historyForward: json["historyForward"] == null ? null : List<String>.from(json["historyForward"].map((x) => x)),
        isLocked: json["isLocked"] ?? false,
        isLockFull: json["isLockFull"] ?? false,
        customName: json["customName"] ?? "",
        customNameInTitle: json["customNameInTitle"] ?? false,
        customNameInTab: json["customNameInTab"] ?? true,
        lastUsedTime: json["lastUsedTime"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "tabUid": tabUid,
        "tabKey": tabKey,
        "url": url,
        "pageTitle": pageTitle,
        "chat": chatRemovalActive,
        "historyBack": historyBack == null ? null : List<dynamic>.from(historyBack!.map((x) => x)),
        "historyForward": historyForward == null ? null : List<dynamic>.from(historyForward!.map((x) => x)),
        "isLocked": isLocked,
        "isLockFull": isLockFull,
        "customName": customName,
        "customNameInTitle": customNameInTitle,
        "customNameInTab": customNameInTab,
        "lastUsedTime": lastUsedTime,
      };
}
