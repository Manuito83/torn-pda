// To parse this JSON data, do
//
//     final userScriptModel = userScriptModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';
import "package:http/http.dart" as http;

UserScriptModel userScriptModelFromJson(String str) => UserScriptModel.fromJson(json.decode(str));

String userScriptModelToJson(UserScriptModel data) => json.encode(data.toJson());

enum UserScriptTime { start, end }

enum UserScriptUpdateStatus {
  upToDate,
  updateAvailable,
  localModified,
  noRemote,
  error,
  updating,
}

class UserScriptModel {
  UserScriptModel(
      {this.enabled = true,
      this.matches = const ["*"],
      required this.name,
      this.version = "0.0.0",
      this.edited = false,
      required this.source,
      this.time = UserScriptTime.end,
      this.url,
      this.updateStatus = UserScriptUpdateStatus.noRemote,
      required this.isExample});

  bool enabled;
  List<String> matches;
  String name;
  String version;
  bool edited;
  String source;
  UserScriptTime time;
  String? url;
  UserScriptUpdateStatus updateStatus;
  bool isExample;

  factory UserScriptModel.fromJson(Map<String, dynamic> json) {
    return UserScriptModel(
        enabled: json["enabled"],
        matches: (json["matches"] as List<dynamic>? ?? tryGetMatches(json["source"])).cast<String>(),
        name: json["name"],
        version: json["version"],
        edited: json["edited"],
        source: json["source"],
        url: json["url"] ?? tryGetUrl(json["source"]),
        updateStatus: UserScriptUpdateStatus.values.byName(json["updateStatus"] ?? "noRemote"),
        isExample: json["isExample"] ?? false,
        time: json["time"] == "start" ? UserScriptTime.start : UserScriptTime.end);
  }

  factory UserScriptModel.fromMetaMap(Map<String, dynamic> metaMap,
      {String? url, UserScriptUpdateStatus updateStatus = UserScriptUpdateStatus.noRemote, bool? isExample}) {
    if (metaMap["name"] == null) {
      throw Exception("No script name found in userscript");
    }
    if (metaMap["source"] == null) {
      // Really should not happen, but who knows...
      throw Exception("No script source found in userscript");
    }
    return UserScriptModel(
      name: metaMap["name"],
      version: metaMap["version"] ?? 0,
      source: metaMap["source"],
      matches: metaMap["matches"] ?? ["*"],
      url: url,
      updateStatus: updateStatus,
      time: metaMap["injectionTime"] == "document-start" ? UserScriptTime.start : UserScriptTime.end,
      isExample: isExample ?? false,
    );
  }

  static Future<({bool success, String message, UserScriptModel? model})> fromURL(String url, {bool? isExample}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final metaMap = UserScriptModel.parseHeader(response.body);
        return (
          success: true,
          message: "Success",
          model: UserScriptModel.fromMetaMap(metaMap,
              url: url, updateStatus: UserScriptUpdateStatus.upToDate, isExample: isExample ?? false),
        );
      } else {
        return (
          success: false,
          message: "Server responded with error code: ${response.statusCode}",
          model: null,
        );
      }
    } catch (e) {
      return (
        success: false,
        message: "Error: $e",
        model: null,
      );
    }
  }

  static bool isNewerVersion(String version1, String version2) {
    final versionRegex = RegExp(r"^(?:\d+\.)+\d+$");
    if (!versionRegex.hasMatch(version1) || !versionRegex.hasMatch(version2)) {
      // Can't compare versions if they don't match the regex, so just return true if they are different
      return version1 != version2;
    }
    final List<String> version1List = version1.split(".");
    final List<String> version2List = version2.split(".");
    for (int i = 0; i < version1List.length; i++) {
      if (int.parse(version1List[i]) > int.parse(version2List[i])) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "matches": matches,
        "name": name,
        "version": version,
        "edited": edited,
        "source": source,
        "url": url,
        "updateStatus": updateStatus.name,
        "isExample": isExample,
        "time": time == UserScriptTime.start ? "start" : "end",
      };

  static Map<String, dynamic> parseHeader(String source) {
    // Thanks to [ViolentMonkey](https://github.com/violentmonkey/violentmonkey) for the following two regexes
    String? meta =
        RegExp(r"((?:^|\n)\s*\/\/\x20==UserScript==)([\s\S]*?\n)\s*\/\/\x20==\/UserScript==|$").stringMatch(source);
    if (meta == null || meta.isEmpty) {
      throw Exception("No header found in userscript.");
    }
    Iterable<RegExpMatch> metaMatches = RegExp(r"^(?:^|\n)\s*\/\/\x20(@\S+)(.*)$", multiLine: true).allMatches(meta);
    Map<String, dynamic> metaMap = {"@match": <String>[]};
    for (final match in metaMatches) {
      if (match.groupCount < 2) {
        continue;
      }
      if (match.group(1) == null || match.group(2) == null) {
        continue;
      }
      if (match.group(1)?.toLowerCase() == "@match") {
        metaMap["@match"].add(match.group(2)!.trim());
      } else {
        metaMap[match.group(1)!.trim().toLowerCase()] = match.group(2)!.trim();
      }
    }
    return {
      "name": metaMap["@name"],
      "version": metaMap["@version"],
      "author": metaMap["@author"],
      "matches": metaMap["@match"].isEmpty ? ["*"] : metaMap["@match"],
      "injectionTime": metaMap["@run-at"] ?? "document-end",
      "downloadURL": metaMap["@downloadurl"],
      "updateURL": metaMap["@updateurl"],
      "source": source,
    };
  }

  shouldInject(String url, [UserScriptTime? time]) => matches
      .any((match) => (match == "*" || url.contains(match.replaceAll("*", ""))) && (this.time == time || time == null));

  void update({
    bool? enabled,
    List<String>? matches,
    String? name,
    String? version,
    bool? edited,
    String? source,
    UserScriptTime? time,
    String? url,
    required UserScriptUpdateStatus updateStatus,
  }) {
    if (source != null) {
      this.source = source;
      try {
        final metaMap = UserScriptModel.parseHeader(source);
        if (metaMap["version"] != null) {
          this.version = metaMap["version"];
        }
        if (metaMap["matches"] != null) {
          this.matches = metaMap["matches"];
        }
        if (metaMap["name"] != null) {
          this.name = metaMap["name"];
        }
        if (metaMap["injectionTime"] != null) {
          this.time = metaMap["injectionTime"] == "document-start" ? UserScriptTime.start : UserScriptTime.end;
        }
        if (metaMap["downloadURL"] != null) {
          this.url = metaMap["downloadURL"];
        }
      } catch (e) {
        // Do nothing
      }
    }
    if (enabled != null) {
      this.enabled = enabled;
    }
    if (matches != null) {
      this.matches = matches;
    }
    if (name != null) {
      this.name = name;
    }
    if (version != null) {
      this.version = version;
    }
    if (edited != null) {
      this.edited = edited;
    }
    if (time != null) {
      this.time = time;
    }
    if (url != null) {
      this.url = url;
    }
    this.updateStatus = updateStatus;
  }

  Future<bool> canUpdate() async {
    if (url == null) {
      return false;
    }
    final response = await http.get(Uri.parse(url!));
    if (response.statusCode == 200) {
      final metaMap = UserScriptModel.parseHeader(response.body);
      if (metaMap["version"] == null) {
        return false;
      }
      return UserScriptModel.isNewerVersion(
        metaMap["version"],
        version,
      );
    } else {
      return false;
    }
  }

  static tryGetMatches(String source) {
    try {
      final metaMap = UserScriptModel.parseHeader(source);
      return metaMap["matches"] ?? const ["*"];
    } catch (e) {
      return const ["*"];
    }
  }

  static tryGetUrl(String source) {
    try {
      final metaMap = UserScriptModel.parseHeader(source);
      return metaMap["downloadURL"];
    } catch (e) {
      return null;
    }
  }
}
