import 'dart:developer';

import 'package:get/get.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class UserController extends GetxController {
  OwnProfileBasic? _basic;
  OwnProfileBasic? get basic => _basic;

  String? apiKey = "";
  int playerId = 0;
  String playerName = "";
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool get isApiKeyValid => (apiKey?.isNotEmpty ?? false) && (_basic?.userApiKeyValid == true);
  String get safeApiKey => apiKey ?? "";
  int get safePlayerId => playerId;
  String get safePlayerName => playerName;

  Future<void> loadPreferences() async {
    _basic = OwnProfileBasic();

    final savedUser = await Prefs().getOwnDetails();
    if (savedUser != '') {
      try {
        _basic = ownProfileBasicFromJson(savedUser);
      } catch (e) {
        _basic = OwnProfileBasic();
      }
    }

    _syncFromBasic();
    _setupAlternativeKeys();

    if (_basic!.userApiKeyValid == true) {
      await _refreshFromAPI();
    }

    _isLoaded = true;
    update();
  }

  void setUserDetails({required OwnProfileBasic userDetails}) {
    _basic = userDetails;
    _syncFromBasic();
    _saveToStorage();
    update();
  }

  void removeUser() {
    _basic = OwnProfileBasic();
    _syncFromBasic();
    Prefs().setOwnDetails('');
    update();
  }

  void _syncFromBasic() {
    apiKey = _basic?.userApiKey ?? "";
    playerId = _basic?.playerId ?? 0;
    playerName = _basic?.name ?? "";
    if (_basic?.faction?.factionId != null) {
      factionId = _basic!.faction!.factionId!;
    }
    if (_basic?.job?.companyId != null) {
      companyId = _basic!.job!.companyId!;
    }
  }

  Future<void> _setupAlternativeKeys() async {
    final bool yataKeyEnabled = await Prefs().getAlternativeYataKeyEnabled();
    if (yataKeyEnabled) {
      alternativeYataKeyEnabled = true;
      _alternativeYataKey = await Prefs().getAlternativeYataKey();
    } else {
      _alternativeYataKey = _basic?.userApiKey ?? "";
    }

    final bool tornStatsKeyEnabled = await Prefs().getAlternativeTornStatsKeyEnabled();
    if (tornStatsKeyEnabled) {
      alternativeTornStatsKeyEnabled = true;
      _alternativeTornStatsKey = await Prefs().getAlternativeTornStatsKey();
    } else {
      _alternativeTornStatsKey = _basic?.userApiKey ?? "";
    }

    final bool ffScouterKeyEnabled = await Prefs().getAlternativeFFScouterKeyEnabled();
    if (ffScouterKeyEnabled) {
      alternativeFFScouterKeyEnabled = true;
      _alternativeFFScouterKey = await Prefs().getAlternativeFFScouterKey();
    } else {
      _alternativeFFScouterKey = _basic?.userApiKey ?? "";
    }
  }

  Future<void> _refreshFromAPI() async {
    final apiVerify = await ApiCallsV1.getOwnProfileBasic();
    if (apiVerify is OwnProfileBasic) {
      apiVerify.userApiKey = _basic!.userApiKey;
      apiVerify.userApiKeyValid = true;
      _basic = apiVerify;
      _syncFromBasic();
      _saveToStorage();
    }
  }

  void _saveToStorage() {
    if (_basic != null) {
      Prefs().setOwnDetails(ownProfileBasicToJson(_basic!));
    }
  }

  void syncFromProfileBasic(OwnProfileBasic? profile) {
    _basic = profile;
    _syncFromBasic();
    // Removed update() to prevent build cycle conflicts with Provider
  }

  int _factionId = 0;
  int get factionId => _factionId;
  set factionId(int value) {
    _factionId = value;
    _checkIfNewFactionAndReport();
  }

  int _companyId = 0;
  int get companyId => _companyId;
  set companyId(int value) {
    _companyId = value;
    _checkIfNewCompanyAndReport();
  }

  // Alternative keys YATA
  bool alternativeYataKeyEnabled = false;

  String _alternativeYataKey = "";
  String get alternativeYataKey => _alternativeYataKey.trim();
  set alternativeYataKey(String key) {
    _alternativeYataKey = key.trim();
  }

  // Alternative keys TORN STATS
  bool alternativeTornStatsKeyEnabled = false;

  String _alternativeTornStatsKey = "";
  String get alternativeTornStatsKey => _alternativeTornStatsKey.trim();
  set alternativeTornStatsKey(String key) {
    _alternativeTornStatsKey = key.trim();
  }

  // Alternative keys FFScouter
  bool alternativeFFScouterKeyEnabled = false;

  String _alternativeFFScouterKey = "";
  String get alternativeFFScouterKey => _alternativeFFScouterKey.trim();
  set alternativeFFScouterKey(String key) {
    _alternativeFFScouterKey = key.trim();
  }

  Future<void> _checkIfNewFactionAndReport() async {
    final lastKnown = await Prefs().getLastKnownFaction();
    if (lastKnown != _factionId) {
      log("Faction changed from $lastKnown to $_factionId!!");
      Prefs().setLastKnownFaction(_factionId);

      if (_factionId != 0) {
        final sb = Get.find<SendbirdController>();
        sb.updatePushPreferencesAfterFactionChange();
      }
    }
  }

  Future<void> _checkIfNewCompanyAndReport() async {
    final lastKnown = await Prefs().getLastKnownCompany();
    if (lastKnown != _companyId) {
      log("Company changed from $lastKnown to $_companyId!!");
      Prefs().setLastKnownCompany(_companyId);

      if (_companyId != 0) {
        final sb = Get.find<SendbirdController>();
        sb.updatePushPreferencesAfterCompanyChange();
      }
    }
  }
}
