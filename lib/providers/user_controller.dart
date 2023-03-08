import 'package:get/get.dart';

class UserController extends GetxController {
  String apiKey = "";

  // Alternative keys YATA
  bool _alternativeYataKeyEnabled = false;
  bool get alternativeYataKeyEnabled => _alternativeYataKeyEnabled;
  set alternativeYataKeyEnabled(bool enabled) {
    _alternativeYataKeyEnabled = enabled;
    update();
  }

  String _alternativeYataKey = "";
  String get alternativeYataKey => _alternativeYataKey;
  set alternativeYataKey(String key) {
    _alternativeYataKey = key;
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
  String get alternativeTornStatsKey => _alternativeTornStatsKey;
  set alternativeTornStatsKey(String key) {
    _alternativeTornStatsKey = key;
    update();
  }
}
