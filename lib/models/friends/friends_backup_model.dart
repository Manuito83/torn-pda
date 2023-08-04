// To parse this JSON data, do
//
//     final FriendsBackupModel = FriendsBackupModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

FriendsBackupModel friendsBackupModelFromJson(String str) => FriendsBackupModel.fromJson(json.decode(str));

String friendsBackupModelToJson(FriendsBackupModel data) => json.encode(data.toJson());

class FriendsBackupModel {
  List<FriendBackup>? friendBackup;

  FriendsBackupModel({
    this.friendBackup,
  });

  factory FriendsBackupModel.fromJson(Map<String, dynamic> json) => FriendsBackupModel(
        friendBackup: json["friend_backup"] == null
            ? null
            : List<FriendBackup>.from(json["friend_backup"].map((x) => FriendBackup.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "friend_backup": List<dynamic>.from(friendBackup!.map((x) => x.toJson())),
      };
}

class FriendBackup {
  int? id;
  String? notes;
  String? notesColor;

  FriendBackup({
    this.id,
    this.notes,
    this.notesColor,
  });

  factory FriendBackup.fromJson(Map<String, dynamic> json) => FriendBackup(
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
