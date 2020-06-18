// To parse this JSON data, do
//
//     final FriendsBackupModel = FriendsBackupModelFromJson(jsonString);

import 'dart:convert';

FriendsBackupModel friendsBackupModelFromJson(String str) => FriendsBackupModel.fromJson(json.decode(str));

String friendsBackupModelToJson(FriendsBackupModel data) => json.encode(data.toJson());

class FriendsBackupModel {
  List<FriendBackup> friendBackup;

  FriendsBackupModel({
    this.friendBackup,
  });

  factory FriendsBackupModel.fromJson(Map<String, dynamic> json) => FriendsBackupModel(
    friendBackup: json["friend_backup"] == null ? null : List<FriendBackup>.from(json["friend_backup"].map((x) => FriendBackup.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "friend_backup": FriendBackup == null ? null : List<dynamic>.from(friendBackup.map((x) => x.toJson())),
  };
}

class FriendBackup {
  int id;
  String notes;
  String notesColor;

  FriendBackup({
    this.id,
    this.notes,
    this.notesColor,
  });

  factory FriendBackup.fromJson(Map<String, dynamic> json) => FriendBackup(
    id: json["id"] == null ? null : json["id"],
    notes: json["notes"] == null ? null : json["notes"],
    notesColor: json["notes_color"] == null ? null : json["notes_color"],
  );

  Map<String, dynamic> toJson() => {
    "id": id == null ? null : id,
    "notes": notes == null ? null : notes,
    "notes_color": notesColor == null ? null : notesColor,
  };
}
