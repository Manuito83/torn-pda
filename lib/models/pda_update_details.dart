// Dart imports:
import 'dart:convert';

class PdaUpdateDetails {
  final int latestVersionCode;
  final String latestVersionName;
  final bool isIosUpdate;
  final bool isAndroidUpdate;
  final List<String> changelog;

  PdaUpdateDetails({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.isIosUpdate,
    required this.isAndroidUpdate,
    required this.changelog,
  });

  factory PdaUpdateDetails.fromJson(Map<String, dynamic> json) {
    return PdaUpdateDetails(
      latestVersionCode: json['latest_version_code'] ?? 0,
      latestVersionName: json['latest_version_name'] ?? '',
      isIosUpdate: json['isIosUpdate'] ?? false,
      isAndroidUpdate: json['isAndroidUpdate'] ?? false,
      changelog: List<String>.from(json['changelog'] ?? []),
    );
  }

  static PdaUpdateDetails? fromJsonString(String jsonString) {
    if (jsonString.isEmpty) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return PdaUpdateDetails.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}
