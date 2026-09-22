class FFScouterNote {
  final String uuid;
  final String scope;
  final String targetType;
  final int targetId;
  final String content;
  final int createdAt;
  final int? deletedAt;
  final String? authorName;
  final bool canSoftDelete;

  FFScouterNote({
    required this.uuid,
    required this.scope,
    required this.targetType,
    required this.targetId,
    required this.content,
    required this.createdAt,
    this.deletedAt,
    this.authorName,
    this.canSoftDelete = false,
  });

  factory FFScouterNote.fromJson(Map<String, dynamic> json) => FFScouterNote(
    uuid: json["uuid"] ?? "",
    scope: json["scope"] ?? "personal",
    targetType: json["target_type"] ?? "player",
    targetId: json["target_id"] ?? 0,
    content: json["content"] ?? "",
    createdAt: json["created_at"] ?? 0,
    deletedAt: json["deleted_at"],
    authorName: json["author_name"],
    canSoftDelete: json["can_soft_delete"] ?? false,
  );

  bool get isPersonal => scope == "personal";
  bool get isFaction => scope == "faction";
  bool get isTeam => scope == "ffscouter";
}

class FFScouterNotesPage {
  final List<FFScouterNote> notes;
  final int totalPages;

  FFScouterNotesPage({required this.notes, required this.totalPages});

  factory FFScouterNotesPage.fromJson(Map<String, dynamic> json) {
    final pagination = json["pagination"] is Map ? json["pagination"] as Map : const {};
    return FFScouterNotesPage(
      notes: json["notes"] is List
          ? (json["notes"] as List).whereType<Map>().map((e) => FFScouterNote.fromJson(e.cast())).toList()
          : const [],
      totalPages: pagination["total_pages"] ?? 0,
    );
  }
}

class FFScouterNotesInfo {
  final int personalUsed;
  final int personalLimit;
  final bool inFaction;
  final bool canPostFaction;

  FFScouterNotesInfo({
    required this.personalUsed,
    required this.personalLimit,
    required this.inFaction,
    required this.canPostFaction,
  });

  factory FFScouterNotesInfo.fromJson(Map<String, dynamic> json) {
    final personal = json["personal"] is Map ? json["personal"] as Map : const {};
    final faction = json["faction"] is Map ? json["faction"] as Map : null;
    return FFScouterNotesInfo(
      personalUsed: personal["used"] ?? 0,
      personalLimit: personal["limit"] ?? 0,
      inFaction: faction != null,
      canPostFaction: faction?["can_post"] ?? false,
    );
  }
}
