import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/friend_model.dart';
import 'package:torn_pda/models/friends_sort.dart';
import 'package:torn_pda/providers/api_key_provider.dart';
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
  UnmodifiableListView<FriendModel> get allFriends =>
      UnmodifiableListView(_friends);

  List<FriendModel> _oldFriendsList = [];

  String _currentFilter = '';
  String get currentFilter => _currentFilter;

  FriendSort _currentSort;

  ApiKeyProvider _apiKeyProvider;

  String _userKey;
  FriendsProvider(this._userKey) {
    print('Initialising FriendsProvider with key: $_userKey'); // TODO: DELETE
    restorePreferences();
  }

  /// If providing [notes] or [notesColor], ensure that they are within 200
  /// chars and of an acceptable color (green, blue, red).
  Future<AddFriendResult> addFriend(String friendId,
      {String notes = '', String notesColor = ''}) async {
    for (var fri in _friends) {
      if (fri.playerId.toString() == friendId) {
        return AddFriendResult(
          success: false,
          errorReason: 'Friend already exists!',
        );
      }
    }

    dynamic myNewFriendModel =
        await TornApiCaller.friends(_userKey, friendId).getFriends;

    if (myNewFriendModel is FriendModel) {
      _getFriendFaction(myNewFriendModel);
      myNewFriendModel.personalNote = notes;
      myNewFriendModel.personalNoteColor = notesColor;
      _friends.add(myNewFriendModel);
      //sortFriends(_currentSort);
      notifyListeners();
      _saveFriendsSharedPrefs();
      return AddFriendResult(
        success: true,
        friendId: myNewFriendModel.playerId.toString(),
        friendName: myNewFriendModel.name,
      );
    } else {
      // myNewFriendModel is ApiError
      var myError = myNewFriendModel as ApiError;
      notifyListeners();
      return AddFriendResult(
        success: false,
        errorReason: myError.errorReason,
      );
    }
  }

  void deleteFriend(FriendModel friend) {
    _oldFriendsList = List<FriendModel>.from(_friends);
    _friends.remove(friend);
    notifyListeners();
    _saveFriendsSharedPrefs();
  }

  Future<bool> updateFriend(FriendModel oldFriend) async {
    oldFriend.isUpdating = true;
    notifyListeners();

    try {
      dynamic myUpdatedFriendModel =
      await TornApiCaller.friends(_userKey, oldFriend.playerId.toString())
          .getFriends;
      if (myUpdatedFriendModel is FriendModel) {
        _getFriendFaction(myUpdatedFriendModel);
        _friends[_friends.indexOf(oldFriend)] = myUpdatedFriendModel;
        var newFriend = _friends[_friends.indexOf(myUpdatedFriendModel)];
        _updateResultAnimation(newFriend, true);
        newFriend.personalNote = oldFriend.personalNote;
        newFriend.personalNoteColor = oldFriend.personalNoteColor;
        newFriend.lastUpdated = DateTime.now();
        _saveFriendsSharedPrefs();
        return true;
      } else {
        // myUpdatedFriendModel is ApiError
        oldFriend.isUpdating = false;
        _updateResultAnimation(oldFriend, false);
        return false;
      }
    } catch (e) {
      oldFriend.isUpdating = false;
      _updateResultAnimation(oldFriend, false);
      return false;
    }
  }

  void _getFriendFaction(FriendModel myNewFriendModel) {
    if (myNewFriendModel.faction.factionId != 0) {
      myNewFriendModel.hasFaction = true;
    } else {
      myNewFriendModel.hasFaction = false;
    }
  }

  void setFriendNote(FriendModel friend, String note, String color) {
    friend.personalNote = note;
    friend.personalNoteColor = color;
    _saveFriendsSharedPrefs();
    notifyListeners();
  }

  void _saveFriendsSharedPrefs() {
    List<String> newPrefs = List<String>();
    for (var fri in _friends) {
      newPrefs.add(friendModelToJson(fri));
    }
    SharedPreferencesModel().setFriendsList(newPrefs);
  }

  Future<void> _updateResultAnimation(FriendModel friend, bool success) async {
    if (success) {
      friend.justUpdatedWithSuccess = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 5), () {});
      friend.justUpdatedWithSuccess = false;
      notifyListeners();
    } else {
      friend.justUpdatedWithError = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 15), () {});
      friend.justUpdatedWithError = false;
      notifyListeners();
    }
  }

  void _saveSortSharedPrefs() {
    /*
    String sortToSave;
    switch (_currentSort) {
      case TargetSort.levelDes:
        sortToSave = 'levelDes';
        break;
      case TargetSort.levelAsc:
        sortToSave = 'levelAsc';
        break;
      case TargetSort.respectDes:
        sortToSave = 'respectDes';
        break;
      case TargetSort.respectAsc:
        sortToSave = 'respectDes';
        break;
      case TargetSort.nameDes:
        sortToSave = 'nameDes';
        break;
      case TargetSort.nameAsc:
        sortToSave = 'nameDes';
        break;
    }
    SharedPreferencesModel().setTargetSort(sortToSave);
    */
  }

  Future<void> restorePreferences() async {
    // Target list
    List<String> jsonFriends = await SharedPreferencesModel().getFriendsList();
    for (var jFri in jsonFriends) {
      _friends.add(friendModelFromJson(jFri));
    }

    /*
    // Target sort
    String targetSort = await SharedPreferencesModel().getTargetSort();
    switch (targetSort) {
      case '':
        _currentSort = TargetSort.levelDes;
        break;
      case 'levelDes':
        _currentSort = TargetSort.levelDes;
        break;
      case 'levelAsc':
        _currentSort = TargetSort.levelAsc;
        break;
      case 'respectDes':
        _currentSort = TargetSort.respectDes;
        break;
      case 'respectAsc':
        _currentSort = TargetSort.respectAsc;
        break;
      case 'nameDes':
        _currentSort = TargetSort.nameDes;
        break;
      case 'nameAsc':
        _currentSort = TargetSort.nameAsc;
        break;
    }
    */
    // Notification
    notifyListeners();
  }
}
