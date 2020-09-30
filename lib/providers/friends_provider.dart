import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/models/friends/friends_sort.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/models/friends/friends_backup_model.dart';
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

class UpdateFriendResult {
  bool success;
  int numberErrors;
  int numberSuccessful;

  UpdateFriendResult(
      {@required this.success,
      @required this.numberErrors,
      @required this.numberSuccessful});
}

class FriendsProvider extends ChangeNotifier {
  List<FriendModel> _friends = [];
  UnmodifiableListView<FriendModel> get allFriends =>
      UnmodifiableListView(_friends);

  List<FriendModel> _oldFriendsList = [];

  String _currentFilter = '';
  String get currentFilter => _currentFilter;

  FriendSortType _currentSort;

  OwnProfileModel _userDetails;
  FriendsProvider(this._userDetails) {
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
        await TornApiCaller.friends(_userDetails.userApiKey, friendId)
            .getFriends;

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

  void restoredDeleted() {
    _friends = List<FriendModel>.from(_oldFriendsList);
    _oldFriendsList.clear();
    notifyListeners();
  }

  Future<bool> updateFriend(FriendModel oldFriend) async {
    oldFriend.isUpdating = true;
    notifyListeners();

    try {
      dynamic myUpdatedFriendModel = await TornApiCaller.friends(
              _userDetails.userApiKey, oldFriend.playerId.toString())
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

  Future<UpdateFriendResult> updateAllFriends() async {
    bool wasSuccessful = true;
    int numberOfErrors = 0;
    int numberSuccessful = 0;
    // Activate every single update icon
    for (var fri in _friends) {
      fri.isUpdating = true;
    }
    notifyListeners();
    // Then start the real update
    for (var i = 0; i < _friends.length; i++) {
      try {
        dynamic myUpdatedFriendModel = await TornApiCaller.friends(
                _userDetails.userApiKey, _friends[i].playerId.toString())
            .getFriends;
        if (myUpdatedFriendModel is FriendModel) {
          _getFriendFaction(myUpdatedFriendModel);
          var notes = _friends[i].personalNote;
          var notesColor = _friends[i].personalNoteColor;
          _friends[i] = myUpdatedFriendModel;
          _updateResultAnimation(_friends[i], true);
          _friends[i].personalNote = notes;
          _friends[i].personalNoteColor = notesColor;
          _friends[i].lastUpdated = DateTime.now();
          _saveFriendsSharedPrefs();
          numberSuccessful++;
        } else {
          // myUpdatedFriendModel is ApiError
          _updateResultAnimation(_friends[i], false);
          _friends[i].isUpdating = false;
          numberOfErrors++;
          wasSuccessful = false;
        }
        // Wait for the API limit (100 calls/minute)
        if (_friends.length > 90) {
          await Future.delayed(const Duration(seconds: 1), () {});
        }
      } catch (e) {
        _updateResultAnimation(_friends[i], false);
        _friends[i].isUpdating = false;
        numberOfErrors++;
        wasSuccessful = false;
      }
    }
    return UpdateFriendResult(
      success: wasSuccessful,
      numberErrors: numberOfErrors,
      numberSuccessful: numberSuccessful,
    );
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

  int getFriendNumber() {
    return _friends.length;
  }

  String exportFriends() {
    var output = List<FriendBackup>();
    for (var fri in _friends) {
      var export = FriendBackup();
      export.id = fri.playerId;
      export.notes = fri.personalNote;
      export.notesColor = fri.personalNoteColor;
      output.add(export);
    }
    return friendsBackupModelToJson(FriendsBackupModel(friendBackup: output));
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

  /// CAREFUL!
  void wipeAllFriends() {
    _friends.clear();
  }

  void setFilterText(String newFilter) {
    _currentFilter = newFilter;
    notifyListeners();
  }

  void sortTargets(FriendSortType sortType) {
    _currentSort = sortType;
    switch (sortType) {
      case FriendSortType.levelDes:
        _friends.sort((a, b) => b.level.compareTo(a.level));
        break;
      case FriendSortType.levelAsc:
        _friends.sort((a, b) => a.level.compareTo(b.level));
        break;
      case FriendSortType.factionDes:
        _friends.sort(
            (a, b) => b.faction.factionName.compareTo(a.faction.factionName));
        break;
      case FriendSortType.factionAsc:
        _friends.sort(
            (a, b) => a.faction.factionName.compareTo(b.faction.factionName));
        break;
      case FriendSortType.nameDes:
        _friends.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case FriendSortType.nameAsc:
        _friends.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    _saveSortSharedPrefs();
    _saveFriendsSharedPrefs();
    notifyListeners();
  }

  void _saveSortSharedPrefs() {
    String sortToSave;
    switch (_currentSort) {
      case FriendSortType.levelDes:
        sortToSave = 'levelDes';
        break;
      case FriendSortType.levelAsc:
        sortToSave = 'levelAsc';
        break;
      case FriendSortType.nameDes:
        sortToSave = 'nameDes';
        break;
      case FriendSortType.nameAsc:
        sortToSave = 'nameDes';
        break;
      case FriendSortType.factionDes:
        sortToSave = 'factionDes';
        break;
      case FriendSortType.factionAsc:
        sortToSave = 'factionAsc';
        break;
    }
    SharedPreferencesModel().setFriendsSort(sortToSave);
  }

  Future<void> restorePreferences() async {
    // Friends list
    bool needToSave = false;
    List<String> jsonFriends = await SharedPreferencesModel().getFriendsList();
    for (var jFri in jsonFriends) {
      var thisFriend = friendModelFromJson(jFri);

      // In v1.8.5 we change from blue to orange and we need to do the conversion
      // here. This can be later removed safely at some point.
      if (thisFriend.personalNoteColor == "blue") {
        thisFriend.personalNoteColor = "orange";
        needToSave = true;
      }

      _friends.add(thisFriend);
    }

    if (needToSave) {
      _saveFriendsSharedPrefs();
    }

    // Friends sort
    String friendsSort = await SharedPreferencesModel().getFriendsSort();
    switch (friendsSort) {
      case '':
        _currentSort = FriendSortType.levelDes;
        break;
      case 'levelDes':
        _currentSort = FriendSortType.levelDes;
        break;
      case 'levelAsc':
        _currentSort = FriendSortType.levelAsc;
        break;
      case 'respectDes':
        _currentSort = FriendSortType.factionDes;
        break;
      case 'respectAsc':
        _currentSort = FriendSortType.factionAsc;
        break;
      case 'nameDes':
        _currentSort = FriendSortType.nameDes;
        break;
      case 'nameAsc':
        _currentSort = FriendSortType.nameAsc;
        break;
    }

    // Notification
    notifyListeners();
  }
}
