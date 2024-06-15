class YataStatsResponse {
  bool success;
  YataStatsResponseSuccess? data;
  YataStatsError? error;

  YataStatsResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory YataStatsResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return YataStatsResponse(
        success: false,
        error: YataStatsError.fromJson(json['error']),
      );
    } else {
      return YataStatsResponse(
        success: true,
        data: YataStatsResponseSuccess.fromJson(json),
      );
    }
  }
}

class YataStatsResponseSuccess {
  Map<String, YataStatsData> data;

  YataStatsResponseSuccess({
    required this.data,
  });

  factory YataStatsResponseSuccess.fromJson(Map<String, dynamic> json) => YataStatsResponseSuccess(
        data: Map.fromEntries(json.entries.map((e) => MapEntry(e.key, YataStatsData.fromJson(e.value)))),
      );

  Map<String, dynamic> toJson() => {
        for (var entry in data.entries) entry.key: entry.value.toJson(),
      };
}

class YataStatsData {
  int? total;
  int? score;
  String? type;
  int? skewness;
  int? timestamp;
  int? version;

  YataStatsData({
    required this.total,
    required this.score,
    required this.type,
    required this.skewness,
    required this.timestamp,
    required this.version,
  });

  factory YataStatsData.fromJson(Map<String, dynamic> json) => YataStatsData(
        total: json["total"],
        score: json["score"],
        type: json["type"],
        skewness: json["skewness"],
        timestamp: json["timestamp"],
        version: json["version"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "score": score,
        "type": type,
        "skewness": skewness,
        "timestamp": timestamp,
        "version": version,
      };
}

class YataStatsError {
  int? code;
  String? error;

  YataStatsError({
    required this.code,
    required this.error,
  });

  factory YataStatsError.fromJson(Map<String, dynamic> json) => YataStatsError(
        code: json["code"],
        error: json["error"],
      );
}
