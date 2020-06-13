import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/friend_model.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class AddFriendResult {
  bool success;
  String errorReason = "";
  String friendId = "";
  String friendName = "";

  AddFriendResult(
      {@required this.success,
        this.errorReason,
        this.friendId,
        this.friendName});
}

class FriendsProvider extends ChangeNotifier {
  List<FriendModel> _friends = [];
  UnmodifiableListView<FriendModel> get allTargets =>
      UnmodifiableListView(_friends);

  List<FriendModel> _oldFriendsList = [];

  String _currentFilter = '';
  String get currentFilter => _currentFilter;

  //FriendsSort _currentSort;

  String userKey = '';
  FriendsProvider() {
    restoreSharedPreferences();
  }

  /// If providing [notes] or [notesColor], ensure that they are within 200
  /// chars and of an acceptable color (green, blue, red).
  Future<AddFriendResult> addTarget(String friendId,
      {String notes = '', String notesColor = ''}) async {

    }
  }

  Future<void> restoreSharedPreferences() async {

}