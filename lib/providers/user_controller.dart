import 'dart:developer';

import 'package:get/get.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class UserController extends GetxController {
  String? apiKey = "";
  int playerId = 0;
  String playerName = "";

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
  bool _alternativeYataKeyEnabled = false;
  bool get alternativeYataKeyEnabled => _alternativeYataKeyEnabled;
  set alternativeYataKeyEnabled(bool enabled) {
    _alternativeYataKeyEnabled = enabled;
    update();
  }

  String _alternativeYataKey = "";
  String get alternativeYataKey => _alternativeYataKey.trim();
  set alternativeYataKey(String key) {
    _alternativeYataKey = key.trim();
    update();
  }

  // Alternative keys TORN STATS
  bool _alternativeTornStatsKeyEnabled = false;
  bool get alternativeTornStatsKeyEnabled => _alternativeTornStatsKeyEnabled;
  set alternativeTornStatsKeyEnabled(bool enabled) {
    _alternativeTornStatsKeyEnabled = enabled;
    update();
  }

  String _alternativeTornStatsKey = "";
  String get alternativeTornStatsKey => _alternativeTornStatsKey.trim();
  set alternativeTornStatsKey(String key) {
    _alternativeTornStatsKey = key.trim();
    update();
  }

  // Alternative keys Torn Spies Central
  bool _alternativeTSCKeyEnabled = false;
  bool get alternativeTSCKeyEnabled => _alternativeTSCKeyEnabled;
  set alternativeTSCKeyEnabled(bool enabled) {
    _alternativeTSCKeyEnabled = enabled;
    update();
  }

  String _alternativeTSCKey = "";
  String get alternativeTSCKey => _alternativeTSCKey.trim();
  set alternativeTSCKey(String key) {
    _alternativeTSCKey = key.trim();
    update();
  }

  _checkIfNewFactionAndReport() async {
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

  _checkIfNewCompanyAndReport() async {
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
