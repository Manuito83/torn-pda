// Dart imports:
import 'dart:collection';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Project imports:
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/models/friends/friends_backup_model.dart';
import 'package:torn_pda/models/friends/friends_sort.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
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

class AddFriendsFromFactionResult {
  bool success;
  String? errorReason;
  String? factionId;
  String? factionName;
  int added;
  int alreadyExisting;
  int errors;

  AddFriendsFromFactionResult({
    required this.success,
    this.errorReason,
    this.factionId,
    this.factionName,
    this.added = 0,
    this.alreadyExisting = 0,
    this.errors = 0,
  });
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

  bool _cancelImport = false;

  void cancelImport() {
    _cancelImport = true;
  }

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

      // Save to centralized notes
      if (notes != null && notes.isNotEmpty) {
        final notesController = Get.find<PlayerNotesController>();
        await notesController.setPlayerNote(
          playerId: friendId,
          note: notes,
          color: notesColor ?? '',
          playerName: myNewFriendModel.name ?? 'Unknown Player',
        );
      }

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

  /// Adds all members of a faction to the friends list.
  ///
  /// - If [fromUserId] is true, [inputId] is treated as a player ID and is
  ///   converted to a faction ID via `ApiCallsV1.getTarget()`
  /// - Otherwise [inputId] is treated as a faction ID.
  Future<AddFriendsFromFactionResult> addFriendsFromFaction({
    required String inputId,
    bool fromUserId = false,
    Function(String currentName, int processed, int total)? onProgress,
  }) async {
    _cancelImport = false;
    try {
      String factionId = inputId;

      if (fromUserId) {
        final dynamic target = await ApiCallsV1.getTarget(playerId: inputId);
        if (target is! TargetModel) {
          final myError = target is ApiError ? target : null;
          return AddFriendsFromFactionResult(
            success: false,
            errorReason: myError?.errorReason ?? "Can't locate the given target!",
          );
        }

        final int resolvedFactionId = target.faction?.factionId ?? 0;
        if (resolvedFactionId == 0) {
          return AddFriendsFromFactionResult(
            success: false,
            errorReason: "${target.name} does not belong to a faction!",
          );
        }

        factionId = resolvedFactionId.toString();
      }

      // Retry logic for "Too many requests"
      dynamic factionResult;
      int retries = 0;
      bool factionSuccess = false;

      while (!factionSuccess && retries < 5) {
        factionResult = await ApiCallsV1.getFaction(factionId: factionId);

        if (factionResult is ApiError &&
            (factionResult.errorId == 5 || factionResult.errorReason.toLowerCase().contains('too many requests'))) {
          retries++;
          if (onProgress != null) {
            onProgress('API Limit: Waiting... (Retry $retries)', 0, 1);
          }
          await Future.delayed(Duration(seconds: 5 * retries));
        } else {
          factionSuccess = true;
        }
      }

      if (factionResult is ApiError || (factionResult is FactionModel && factionResult.id == null)) {
        final myError = factionResult is ApiError ? factionResult : null;
        return AddFriendsFromFactionResult(
          success: false,
          factionId: factionId,
          errorReason: myError?.errorReason ?? "Can't locate the given faction!",
        );
      }

      final FactionModel faction = factionResult as FactionModel;
      final memberIds = faction.members?.keys.toList() ?? <String>[];
      if (memberIds.isEmpty) {
        return AddFriendsFromFactionResult(
          success: false,
          factionId: factionId,
          factionName: faction.name,
          errorReason: 'No members found for this faction!',
        );
      }

      int added = 0;
      int alreadyExisting = 0;
      int errors = 0;

      for (final memberId in memberIds) {
        if (_cancelImport) break;

        try {
          if (_friends.any((fri) => fri.playerId.toString() == memberId)) {
            alreadyExisting++;
            if (onProgress != null) {
              onProgress('Skipping existing...', added + alreadyExisting + errors, memberIds.length);
            }
            continue;
          }

          // Retry logic for "Too many requests"
          dynamic friendResult;
          int retries = 0;
          bool success = false;
          bool slowMode = false;

          while (!success && retries < 5) {
            if (_cancelImport) break;

            friendResult = await ApiCallsV1.getFriends(playerId: memberId);

            if (friendResult is ApiError &&
                (friendResult.errorId == 5 || friendResult.errorReason.toLowerCase().contains('too many requests'))) {
              retries++;
              slowMode = true;
              if (onProgress != null) {
                onProgress(
                  'API Limit: Waiting... (Retry $retries)',
                  added + alreadyExisting + errors,
                  memberIds.length,
                );
              }
              await Future.delayed(Duration(seconds: 5 * retries));
            } else {
              success = true;
            }
          }

          if (_cancelImport) break;

          if (friendResult is FriendModel) {
            _getFriendFaction(friendResult);
            _friends.add(friendResult);
            notifyListeners();
            _saveFriendsSharedPrefs();
            added++;
            if (onProgress != null) {
              onProgress(friendResult.name ?? 'Unknown', added + alreadyExisting + errors, memberIds.length);
            }
          } else {
            errors++;
            if (onProgress != null) {
              onProgress('Error fetching...', added + alreadyExisting + errors, memberIds.length);
            }
          }

          // Respect the API limit (100 calls/minute)
          // If we hit the limit (slowMode) or if the list is long, we throttle
          if (slowMode || memberIds.length > 90) {
            await Future.delayed(const Duration(seconds: 1), () {});
          }
        } catch (_) {
          errors++;
        }
      }

      final bool success = added > 0 || alreadyExisting > 0;
      return AddFriendsFromFactionResult(
        success: success,
        factionId: factionId,
        factionName: faction.name,
        added: added,
        alreadyExisting: alreadyExisting,
        errors: errors,
        errorReason: success ? '' : 'No members could be added.',
      );
    } catch (e) {
      return AddFriendsFromFactionResult(
        success: false,
        errorReason: 'Unexpected error while importing: $e',
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
          _friends[i] = myUpdatedFriendModel;
          _updateResultAnimation(_friends[i], true);
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

  int getFriendNumber() {
    return _friends.length;
  }

  String exportFriends() {
    final output = <FriendBackup>[];

    for (final fri in _friends) {
      final notesController = Get.find<PlayerNotesController>();
      final centralizedNote = notesController.getNoteForPlayer(fri.playerId.toString());
      fri.noteBackup = centralizedNote?.note ?? "";
      fri.colorBackup = centralizedNote?.color ?? "";

      final export = FriendBackup();
      export.id = fri.playerId;
      export.notes = fri.noteBackup;
      export.notesColor = fri.colorBackup;

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
    notifyListeners();
    _saveFriendsSharedPrefs();
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
    List<String> jsonFriends = await Prefs().getFriendsList();
    for (final jFri in jsonFriends) {
      final thisFriend = friendModelFromJson(jFri);
      _friends.add(thisFriend);
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

  /// Check if a player ID is in the friends list
  bool isPlayerInFriends(String playerId) {
    return _friends.any((friend) => friend.playerId.toString() == playerId);
  }
}
