import 'dart:convert';

FFScouterTargetsResponse ffScouterTargetsFromJson(String str) => FFScouterTargetsResponse.fromJson(json.decode(str));

class FFScouterTargetsResponse {
  FFScouterTargetsParameters? parameters;
  List<FFScouterTarget>? targets;

  FFScouterTargetsResponse({this.parameters, this.targets});

  factory FFScouterTargetsResponse.fromJson(Map<String, dynamic> json) => FFScouterTargetsResponse(
        parameters: json["parameters"] != null ? FFScouterTargetsParameters.fromJson(json["parameters"]) : null,
        targets: json["targets"] != null
            ? List<FFScouterTarget>.from(json["targets"].map((x) => FFScouterTarget.fromJson(x)))
            : null,
      );
}

class FFScouterTargetsParameters {
  String? preset;
  int? minlevel;
  int? maxlevel;
  int? inactiveonly;
  double? minff;
  double? maxff;
  int? limit;
  int? factionless;
  int? generatedAt;

  FFScouterTargetsParameters({
    this.preset,
    this.minlevel,
    this.maxlevel,
    this.inactiveonly,
    this.minff,
    this.maxff,
    this.limit,
    this.factionless,
    this.generatedAt,
  });

  factory FFScouterTargetsParameters.fromJson(Map<String, dynamic> json) => FFScouterTargetsParameters(
        preset: json["preset"],
        minlevel: json["minlevel"],
        maxlevel: json["maxlevel"],
        inactiveonly: json["inactiveonly"],
        minff: json["minff"]?.toDouble(),
        maxff: json["maxff"]?.toDouble(),
        limit: json["limit"],
        factionless: json["factionless"],
        generatedAt: json["generated_at"],
      );
}

class FFScouterTarget {
  int? playerId;
  String? name;
  int? level;
  double? fairFight;
  int? bssPublic;
  int? bssPublicTimestamp;
  int? bsEstimate;
  String? bsEstimateHuman;
  int? lastAction;

  // Enriched fields from Torn API refresh
  String? statusState;
  String? statusColor;
  String? statusDescription;
  int? statusUntil;
  String? lastActionStatus; // Online, Idle, Offline
  String? factionName;
  int? factionId;
  int? companyId;
  String? companyName;
  int? statusLastUpdated; // epoch seconds of when we last refreshed

  // Transient UI flag (not persisted)
  bool justUpdated = false;

  FFScouterTarget({
    this.playerId,
    this.name,
    this.level,
    this.fairFight,
    this.bssPublic,
    this.bssPublicTimestamp,
    this.bsEstimate,
    this.bsEstimateHuman,
    this.lastAction,
    this.statusState,
    this.statusColor,
    this.statusDescription,
    this.statusUntil,
    this.lastActionStatus,
    this.factionName,
    this.factionId,
    this.companyId,
    this.companyName,
    this.statusLastUpdated,
  });

  factory FFScouterTarget.fromJson(Map<String, dynamic> json) => FFScouterTarget(
        playerId: json["player_id"],
        name: json["name"],
        level: json["level"],
        fairFight: json["fair_fight"]?.toDouble(),
        bssPublic: json["bss_public"],
        bssPublicTimestamp: json["bss_public_timestamp"],
        bsEstimate: json["bs_estimate"],
        bsEstimateHuman: json["bs_estimate_human"],
        lastAction: json["last_action"],
        statusState: json["status_state"],
        statusColor: json["status_color"],
        statusDescription: json["status_description"],
        statusUntil: json["status_until"],
        lastActionStatus: json["last_action_status"],
        factionName: json["faction_name"],
        factionId: json["faction_id"],
        companyId: json["company_id"],
        companyName: json["company_name"],
        statusLastUpdated: json["status_last_updated"],
      );

  Map<String, dynamic> toJson() => {
        "player_id": playerId,
        "name": name,
        "level": level,
        "fair_fight": fairFight,
        "bss_public": bssPublic,
        "bss_public_timestamp": bssPublicTimestamp,
        "bs_estimate": bsEstimate,
        "bs_estimate_human": bsEstimateHuman,
        "last_action": lastAction,
        "status_state": statusState,
        "status_color": statusColor,
        "status_description": statusDescription,
        "status_until": statusUntil,
        "last_action_status": lastActionStatus,
        "faction_name": factionName,
        "faction_id": factionId,
        "company_id": companyId,
        "company_name": companyName,
        "status_last_updated": statusLastUpdated,
      };

  /// Merge live data from TargetModel into this target
  void updateFromTargetModel(dynamic targetModel) {
    statusState = targetModel.status?.state;
    statusColor = targetModel.status?.color;
    statusDescription = targetModel.status?.description;
    statusUntil = targetModel.status?.until;
    lastActionStatus = targetModel.lastAction?.status;
    factionName = targetModel.faction?.factionName;
    factionId = targetModel.faction?.factionId;
    companyId = targetModel.job?.companyId;
    companyName = targetModel.job?.companyName;
    statusLastUpdated = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  bool get hasStatus => statusState != null || lastActionStatus != null;
}
