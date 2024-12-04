// Dart imports:
import 'dart:collection';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/models/friends/friends_backup_model.dart';
import 'package:torn_pda/models/friends/friends_sort.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class AddFriendResult {
  bool success;
  String? errorReason = "";
  String? friendId = "";
  String? friendName = "";

  AddFriendResult({required this.success, this.errorReason, this.friendId, this.friendName});
}

class UpdateFriendResult {
  bool success;
  int numberErrors;
  int numberSuccessful;

  UpdateFriendResult({required this.success, required this.numberErrors, required this.numberSuccessful});
}

class FriendsProvider extends ChangeNotifier {
  bool _initialized = false;
  bool get initialized => _initialized;

  List<FriendModel> _friends = [];
  UnmodifiableListView<FriendModel> get allFriends => UnmodifiableListView(_friends);

  List<FriendModel> _oldFriendsList = [];

  String _currentFilter = '';
  String get currentFilter => _currentFilter;

  FriendSortType? _currentSort;

  /// If providing [notes] or [notesColor], ensure that they are within 200
  /// chars and of an acceptable color (green, blue, red).
  Future<AddFriendResult> addFriend(String friendId, {String? notes = '', String? notesColor = ''}) async {
    for (final fri in _friends) {
      if (fri.playerId.toString() == friendId) {
        return AddFriendResult(
          success: false,
          errorReason: 'Friend already exists!',
        );
      }
    }

    final dynamic myNewFriendModel = await ApiCallsV1.getFriends(playerId: friendId);

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
      final myError = myNewFriendModel as ApiError;
      notifyListeners();
      return AddFriendResult(
        success: false,
        errorReason: myError.errorReason,
      );
    }
  }

  void deleteFriend(FriendModel? friend) {
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
      final dynamic myUpdatedFriendModel = await ApiCallsV1.getFriends(playerId: oldFriend.playerId.toString());
      if (myUpdatedFriendModel is FriendModel) {
        _getFriendFaction(myUpdatedFriendModel);
        _friends[_friends.indexOf(oldFriend)] = myUpdatedFriendModel;
        final newFriend = _friends[_friends.indexOf(myUpdatedFriendModel)];
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
    for (final fri in _friends) {
      fri.isUpdating = true;
    }
    notifyListeners();
    // Then start the real update
    for (var i = 0; i < _friends.length; i++) {
      try {
        final dynamic myUpdatedFriendModel = await ApiCallsV1.getFriends(playerId: _friends[i].playerId.toString());
        if (myUpdatedFriendModel is FriendModel) {
          _getFriendFaction(myUpdatedFriendModel);
          final notes = _friends[i].personalNote;
          final notesColor = _friends[i].personalNoteColor;
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
    if (myNewFriendModel.faction!.factionId != 0) {
      myNewFriendModel.hasFaction = true;
    } else {
      myNewFriendModel.hasFaction = false;
    }
  }

  void setFriendNote(FriendModel friend, String note, String? color) {
    friend.personalNote = note;
    friend.personalNoteColor = color;
    _saveFriendsSharedPrefs();
    notifyListeners();
  }

  int getFriendNumber() {
    return _friends.length;
  }

  String exportFriends() {
    final output = <FriendBackup>[];
    for (final fri in _friends) {
      final export = FriendBackup();
      export.id = fri.playerId;
      export.notes = fri.personalNote;
      export.notesColor = fri.personalNoteColor;
      output.add(export);
    }
    return friendsBackupModelToJson(FriendsBackupModel(friendBackup: output));
  }

  void _saveFriendsSharedPrefs() {
    List<String> newPrefs = <String>[];
    for (final fri in _friends) {
      newPrefs.add(friendModelToJson(fri));
    }
    Prefs().setFriendsList(newPrefs);
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
        _friends.sort((a, b) => b.level!.compareTo(a.level!));
      case FriendSortType.levelAsc:
        _friends.sort((a, b) => a.level!.compareTo(b.level!));
      case FriendSortType.factionDes:
        _friends.sort((a, b) => b.faction!.factionName!.compareTo(a.faction!.factionName!));
      case FriendSortType.factionAsc:
        _friends.sort((a, b) => a.faction!.factionName!.compareTo(b.faction!.factionName!));
      case FriendSortType.nameDes:
        _friends.sort((a, b) => b.name!.toLowerCase().compareTo(a.name!.toLowerCase()));
      case FriendSortType.nameAsc:
        _friends.sort((a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));
    }
    _saveSortSharedPrefs();
    _saveFriendsSharedPrefs();
    notifyListeners();
  }

  void _saveSortSharedPrefs() {
    late String sortToSave;
    switch (_currentSort!) {
      case FriendSortType.levelDes:
        sortToSave = 'levelDes';
      case FriendSortType.levelAsc:
        sortToSave = 'levelAsc';
      case FriendSortType.nameDes:
        sortToSave = 'nameDes';
      case FriendSortType.nameAsc:
        sortToSave = 'nameDes';
      case FriendSortType.factionDes:
        sortToSave = 'factionDes';
      case FriendSortType.factionAsc:
        sortToSave = 'factionAsc';
    }
    Prefs().setFriendsSort(sortToSave);
  }

  Future<void> initFriends() async {
    // Friends list
    bool needToSave = false;
    List<String> jsonFriends = await Prefs().getFriendsList();
    for (final jFri in jsonFriends) {
      final thisFriend = friendModelFromJson(jFri);

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
    final String friendsSort = await Prefs().getFriendsSort();
    switch (friendsSort) {
      case '':
        _currentSort = FriendSortType.levelDes;
      case 'levelDes':
        _currentSort = FriendSortType.levelDes;
      case 'levelAsc':
        _currentSort = FriendSortType.levelAsc;
      case 'respectDes':
        _currentSort = FriendSortType.factionDes;
      case 'respectAsc':
        _currentSort = FriendSortType.factionAsc;
      case 'nameDes':
        _currentSort = FriendSortType.nameDes;
      case 'nameAsc':
        _currentSort = FriendSortType.nameAsc;
    }

    _initialized = true;

    // Notification
    notifyListeners();
  }
}
