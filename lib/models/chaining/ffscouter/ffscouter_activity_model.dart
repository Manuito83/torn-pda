import 'dart:convert';

/// activity/player or activity/faction response (premium)
class FFScouterActivityResponse {
  final FFScouterActivityMeta? meta;
  final List<FFScouterActivityBucket> buckets;

  FFScouterActivityResponse({this.meta, this.buckets = const []});

  factory FFScouterActivityResponse.fromJson(Map<String, dynamic> json) => FFScouterActivityResponse(
    meta: json["meta"] != null ? FFScouterActivityMeta.fromJson(json["meta"]) : null,
    buckets: json["buckets"] is List
        ? (json["buckets"] as List).map((e) => FFScouterActivityBucket.fromJson(e)).toList()
        : const [],
  );
}

FFScouterActivityResponse ffScouterActivityFromJson(String str) => FFScouterActivityResponse.fromJson(json.decode(str));

class FFScouterActivityMeta {
  final String? subjectType;
  final int? subjectId;
  final int? start;
  final int? end;
  final int? bucketSeconds;
  final int? bucketCount;
  final bool? truncated;
  final int? memberCount; // faction only

  FFScouterActivityMeta({
    this.subjectType,
    this.subjectId,
    this.start,
    this.end,
    this.bucketSeconds,
    this.bucketCount,
    this.truncated,
    this.memberCount,
  });

  factory FFScouterActivityMeta.fromJson(Map<String, dynamic> json) => FFScouterActivityMeta(
    subjectType: json["subject_type"],
    subjectId: json["subject_id"],
    start: json["start"],
    end: json["end"],
    bucketSeconds: json["bucket_seconds"],
    bucketCount: json["bucket_count"],
    truncated: json["truncated"],
    memberCount: json["member_count"],
  );
}

class FFScouterActivityBucket {
  final int ts; // bucket start, epoch s
  final int activityScore; // player 0/1, faction = active member count
  final int? activePlayers;
  final double? activeRatio;

  FFScouterActivityBucket({required this.ts, this.activityScore = 0, this.activePlayers, this.activeRatio});

  factory FFScouterActivityBucket.fromJson(Map<String, dynamic> json) => FFScouterActivityBucket(
    ts: json["ts"] ?? 0,
    activityScore: json["activity_score"] ?? 0,
    activePlayers: json["active_players"],
    activeRatio: (json["active_ratio"] as num?)?.toDouble(),
  );
}

/// Typical-day activity folded across days, one slot per bucket in TCT (0..1)
class FFScouterActivityPattern {
  final int bucketSeconds;
  final List<double> slots;

  FFScouterActivityPattern({required this.bucketSeconds, required this.slots});

  bool get hasData => slots.any((v) => v > 0);
  int get slotCount => slots.length;

  /// Overall activity level (0..1), mean of all slots
  double get overallActivity => slots.isEmpty ? 0 : slots.reduce((a, b) => a + b) / slots.length;

  /// 0..1 for the slot containing [ts] (defaults to now)
  double valueAt([int? ts]) {
    if (slots.isEmpty) return 0;
    final t = ts ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return slots[((t % 86400) ~/ bucketSeconds) % slots.length];
  }

  /// Slot index of peak activity, or -1 when empty
  int get peakSlot {
    if (slots.isEmpty) return -1;
    var best = 0;
    for (var i = 1; i < slots.length; i++) {
      if (slots[i] > slots[best]) best = i;
    }
    return best;
  }

  /// Epoch-second time-of-day for the start of slot [i] (TCT)
  int slotTodSeconds(int i) => i * bucketSeconds;

  /// Average activity per hour-of-day (0..1), 24 entries
  List<double> hourly() {
    final perHour = (3600 ~/ bucketSeconds).clamp(1, 720);
    return List<double>.generate(24, (h) {
      double sum = 0;
      int n = 0;
      for (int i = 0; i < perHour; i++) {
        final idx = h * perHour + i;
        if (idx < slots.length) {
          sum += slots[idx];
          n++;
        }
      }
      return n == 0 ? 0 : sum / n;
    });
  }

  factory FFScouterActivityPattern.fold(
    FFScouterActivityResponse res,
    double Function(FFScouterActivityBucket) scoreOf,
  ) {
    final bs = res.meta?.bucketSeconds ?? 300;
    final n = (86400 / bs).floor();
    final sum = List<double>.filled(n, 0);
    final cnt = List<int>.filled(n, 0);
    for (final b in res.buckets) {
      final i = ((b.ts % 86400) ~/ bs) % n;
      sum[i] += scoreOf(b);
      cnt[i] += 1;
    }
    return FFScouterActivityPattern(
      bucketSeconds: bs,
      slots: List<double>.generate(n, (i) => cnt[i] == 0 ? 0 : sum[i] / cnt[i]),
    );
  }
}
