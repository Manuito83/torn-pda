// To parse this JSON data, do
//
//     final targetsBackupModel = targetsBackupModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

TargetsBackupModel targetsBackupModelFromJson(String str) => TargetsBackupModel.fromJson(json.decode(str));

String targetsBackupModelToJson(TargetsBackupModel data) => json.encode(data.toJson());

class TargetsBackupModel {
  List<TargetBackup>? targetBackup;

  TargetsBackupModel({
    this.targetBackup,
  });

  factory TargetsBackupModel.fromJson(Map<String, dynamic> json) => TargetsBackupModel(
        targetBackup: json["target_backup"] == null
            ? null
            : List<TargetBackup>.from(json["target_backup"].map((x) => TargetBackup.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "target_backup": targetBackup == null ? null : List<dynamic>.from(targetBackup!.map((x) => x.toJson())),
      };
}

class TargetBackup {
  int? id;
  String? notes;
  String? notesColor;

  TargetBackup({
    this.id,
    this.notes,
    this.notesColor,
  });

  factory TargetBackup.fromJson(Map<String, dynamic> json) => TargetBackup(
        id: json["id"],
        notes: json["notes"],
        notesColor: json["notes_color"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "notes": notes,
        "notes_color": notesColor,
      };
}
