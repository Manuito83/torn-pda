import 'package:get/get.dart';
import 'package:torn_pda/providers/ffscouter_cache_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

/// FFScouter premium state + the upgrade-promo dismissal flag
/// Premium comes from check-key (is_premium) or premium-only get-stats payloads
/// Going premium resets the dismissal so the promo can reappear if it lapses
class FFScouterPremiumController extends GetxController {
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  bool _promoDismissed = false;
  bool get promoDismissed => _promoDismissed;

  int _lastChecked = 0; // last check-key poll, epoch s
  static const int _checkIntervalSeconds = 6 * 60 * 60;

  bool _checking = false;

  // per-feature enable toggles (default on)
  bool _distributionEnabled = true;
  bool _flightsEnabled = true;
  bool _activityEnabled = true;

  bool get distributionEnabled => _distributionEnabled;
  bool get flightsEnabled => _flightsEnabled;
  bool get activityEnabled => _activityEnabled;

  set distributionEnabled(bool v) {
    _distributionEnabled = v;
    Prefs().setFFScouterPremiumDistribution(v);
    update();
  }

  set flightsEnabled(bool v) {
    _flightsEnabled = v;
    Prefs().setFFScouterPremiumFlights(v);
    update();
  }

  set activityEnabled(bool v) {
    _activityEnabled = v;
    Prefs().setFFScouterPremiumActivity(v);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    _restore();
  }

  Future<void> _restore() async {
    _isPremium = await Prefs().getFFScouterPremiumActive();
    _promoDismissed = await Prefs().getFFScouterPremiumPromoDismissed();
    _lastChecked = await Prefs().getFFScouterPremiumLastChecked();
    _distributionEnabled = await Prefs().getFFScouterPremiumDistribution();
    _flightsEnabled = await Prefs().getFFScouterPremiumFlights();
    _activityEnabled = await Prefs().getFFScouterPremiumActivity();
    update();
  }

  bool get shouldShowPromo => !_isPremium && !_promoDismissed;

  void dismissPromo() {
    if (_promoDismissed) return;
    _promoDismissed = true;
    Prefs().setFFScouterPremiumPromoDismissed(true);
    update();
  }

  /// Premium-only payload seen: the key is premium
  void markPremiumDetected() => _applyPremium(true);

  /// Premium endpoint reported no premium (e.g. flights error 19)
  void markNotPremium() => _applyPremium(false);

  /// Refresh premium via check-key (throttled; [force] skips the throttle)
  Future<void> refreshPremiumStatus({bool force = false}) async {
    if (_checking) return;
    if (!Get.find<FFScouterCacheController>().remoteConfigEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (!force && now - _lastChecked < _checkIntervalSeconds) return;

    final key = Get.find<UserController>().alternativeFFScouterKey;
    if (key.isEmpty) return;

    _checking = true;
    final result = await FFScouterComm.checkKey(key: key);
    _checking = false;

    if (result.success && result.data != null) {
      _lastChecked = now;
      Prefs().setFFScouterPremiumLastChecked(now);
      _applyPremium(result.data!.isPremium);
    }
  }

  void _applyPremium(bool premium) {
    if (premium == _isPremium) return;
    if (premium) {
      // reset dismissal so a later lapse can prompt again
      _promoDismissed = false;
      Prefs().setFFScouterPremiumPromoDismissed(false);
    }
    _isPremium = premium;
    Prefs().setFFScouterPremiumActive(premium);
    update();
  }
}
