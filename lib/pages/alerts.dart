// Package imports:
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/faction/faction_attacks_model.dart';
// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/pages/alerts/alerts_troubleshooting_page.dart';
import 'package:torn_pda/pages/alerts/stockmarket_alerts_page.dart';
import 'package:torn_pda/pages/cityshops/city_shops_page.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/city_shops_daily_limit.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/live_activities/live_activity_racing_controller.dart';
import 'package:torn_pda/utils/live_activities/live_activity_travel_controller.dart';
import 'package:torn_pda/widgets/alerts/alert_cards.dart';
import 'package:torn_pda/widgets/alerts/discreet_info.dart';
import 'package:torn_pda/widgets/alerts/events_filter_dialog.dart';
import 'package:torn_pda/widgets/alerts/loot_npc_dialog.dart';
import 'package:torn_pda/widgets/alerts/refills_requested_dialog.dart';
import 'package:torn_pda/widgets/alerts/sendbird_dnd_dialog.dart';
import 'package:torn_pda/widgets/alerts/work_stats_targets_dialog.dart';
import 'package:torn_pda/widgets/loot/loot_rangers_explanation.dart';

class AlertsSettings extends StatefulWidget {
  final Function stockMarketInMenuCallback;

  const AlertsSettings(this.stockMarketInMenuCallback);

  @override
  AlertsSettingsState createState() => AlertsSettingsState();
}

class AlertsSettingsState extends State<AlertsSettings> {
  FirebaseUserModel? _firebaseUserModel;

  Future? _getFirebaseAndTornDetails;

  bool _factionApiAccess = false;
  bool _factionApiAccessCheckError = false;

  late SettingsProvider _settingsProvider;
  ThemeProvider? _themeProvider;
  late WebViewProvider _webViewProvider;

  final _scrollController = ScrollController();
  final _scrollControllerRetalsGeneral = ScrollController();
  final _scrollControllerRetalsNotification = ScrollController();
  final _scrollControllerRetalsDonor = ScrollController();

  bool _togglingSendbirdNotifications = false;

  String? _lootAheadSelection;
  String? _lootRangersAheadSelection;
  bool _aheadSelectionsInitialised = false;
  bool _cityShopAutoPause = false;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    final sbController = Get.find<SendbirdController>();
    _getFirebaseAndTornDetails = Future.wait([
      FirestoreHelper().getUserProfile(),
      _getFactionApiAccess(),
      sbController.updateFactionAndCompanyPreferences(),
    ]);

    analytics?.logScreenView(screenName: 'alerts');

    Prefs().getCityShopAutoPauseEnabled().then((value) {
      if (mounted) setState(() => _cityShopAutoPause = value);
    });

    routeWithDrawer = true;
    routeName = "alerts";
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollControllerRetalsGeneral.dispose();
    _scrollControllerRetalsNotification.dispose();
    _scrollControllerRetalsDonor.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider!.canvas,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(height: AppBar().preferredSize.height, child: buildAppBar())
          : null,
      body: Container(
        color: _themeProvider!.canvas,
        child: FutureBuilder(
          future: _getFirebaseAndTornDetails,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data != null && snapshot.data[0] is FirebaseUserModel) {
                _firebaseUserModel ??= snapshot.data[0] as FirebaseUserModel?;

                if (!_aheadSelectionsInitialised && _firebaseUserModel != null) {
                  const lootAllowed = {"180", "360", "600"};
                  const lrAllowed = {"180", "360", "600"};

                  final lootInit = (_firebaseUserModel!.lootAlertAheadSeconds ?? 360).toString();
                  final lrInit = (_firebaseUserModel!.lootRangersAheadSeconds ?? 180).toString();

                  _lootAheadSelection = lootAllowed.contains(lootInit) ? lootInit : "360";
                  _lootRangersAheadSelection = lrAllowed.contains(lrInit) ? lrInit : "180";

                  _aheadSelectionsInitialised = true;
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _summaryHeader(),
                      if (_liveActivitiesSupported()) _liveActivitiesCard(),
                      _barsCard(),
                      _travelCard(),
                      _factionCard(),
                      _socialCard(),
                      _otherCard(),
                      const SizedBox(height: 60),
                    ],
                  ),
                );
              } else {
                return _connectError();
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  bool _liveActivitiesSupported() {
    return (Platform.isIOS && kSdkIos >= 16.2) || (Platform.isAndroid && kSdkAndroid >= 26);
  }

  bool get _sendbirdOn => Get.find<SendbirdController>().sendBirdNotificationsEnabled;

  int _countOn(List<bool?> flags) => flags.where((f) => f == true).length;

  List<bool?> _barsFlags() {
    final m = _firebaseUserModel!;
    return [
      m.energyNotification,
      m.nerveNotification,
      m.lifeNotification,
      m.drugsNotification,
      m.medicalNotification,
      m.boosterNotification,
      m.hospitalNotification,
      m.refillsNotification,
    ];
  }

  List<bool?> _travelFlags() {
    final m = _firebaseUserModel!;
    return [
      m.travelNotification,
      m.foreignRestockNotification,
      m.cityShopRestockNotification,
      m.abroadStayNotification,
    ];
  }

  List<bool?> _factionFlags() {
    final m = _firebaseUserModel!;
    return [
      m.retalsNotification,
      m.factionAssistMessage,
      m.lootAlerts.isNotEmpty,
      m.lootRangersAlerts,
      m.racingNotification,
    ];
  }

  List<bool?> _socialFlags() {
    final m = _firebaseUserModel!;
    return [m.messagesNotification, m.eventsNotification, _sendbirdOn, m.forumsSubscription];
  }

  List<bool?> _otherFlags() => [_firebaseUserModel!.workStatsNotification];

  Widget _summaryHeader() {
    final m = _firebaseUserModel!;
    final all = [..._barsFlags(), ..._travelFlags(), ..._factionFlags(), ..._socialFlags(), ..._otherFlags()];
    final on = _countOn(all);
    final muted = _themeProvider!.mainText.withValues(alpha: 0.78);

    final chips = <Widget>[];
    if (m.cityShopMutedUntil > DateTime.now().millisecondsSinceEpoch) {
      chips.add(const AlertChip("City shops paused until 00:00 TCT", kind: AlertChipKind.critical));
    }
    if ((m.retalsNotification ?? false) && !_factionApiAccess) {
      chips.add(const AlertChip("Retaliation: no faction API access", kind: AlertChipKind.warning));
    }
    if (m.discreet) chips.add(const AlertChip("Discreet mode"));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "$on",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: on == 1 ? " alert on" : " alerts on", style: const TextStyle(fontSize: 16)),
                TextSpan(
                  text: "  of ${all.length}",
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
          ),
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 6, runSpacing: 6, children: chips),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "Alerts are automatic notifications that you only need to activate once. They usually arrive earlier "
              "than manual notifications, but may be delayed by network status or device throttling.",
              style: TextStyle(fontSize: 12, height: 1.35, color: muted),
            ),
          ),
          Row(
            children: [
              const Text("Discreet alerts", style: TextStyle(fontSize: 14)),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  showDialog(
                    useRootNavigator: false,
                    context: context,
                    builder: (BuildContext context) {
                      return DiscreetInfo();
                    },
                  );
                },
              ),
              const Spacer(),
              Switch(
                value: m.discreet,
                onChanged: (value) {
                  setState(() {
                    m.discreet = value;
                  });
                  FirestoreHelper().toggleDiscreet(value);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.green[600],
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  AlertGroupCard _card({
    required IconData icon,
    required String title,
    List<bool?>? flags,
    required List<Widget> children,
  }) {
    return AlertGroupCard(
      icon: icon,
      title: title,
      on: flags == null ? null : _countOn(flags),
      total: flags?.length,
      children: children,
      theme: _themeProvider!,
    );
  }

  AlertSubRows _subRows(List<Widget> children) => AlertSubRows(theme: _themeProvider!, children: children);

  Widget _chevron() =>
      Icon(Icons.keyboard_arrow_right_outlined, color: _themeProvider!.mainText.withValues(alpha: 0.78));

  // ##### BARS & COOLDOWNS #####

  Widget _barsCard() {
    final m = _firebaseUserModel!;
    return _card(
      icon: Icons.bolt_outlined,
      title: "Bars & cooldowns",
      flags: _barsFlags(),
      children: [
        AlertRow(
          title: "Energy full",
          subtitle: "Get notified once you reach full energy",
          value: m.energyNotification ?? false,
          onChanged: (value) {
            setState(() => m.energyNotification = value);
            FirestoreHelper().subscribeToEnergyNotification(value);
          },
        ),
        AlertRow(
          title: "Nerve full",
          subtitle: "Get notified once you reach full nerve",
          value: m.nerveNotification ?? false,
          onChanged: (value) {
            setState(() => m.nerveNotification = value);
            FirestoreHelper().subscribeToNerveNotification(value);
          },
        ),
        AlertRow(
          title: "Life full",
          subtitle: "Get notified once you reach full life",
          value: m.lifeNotification ?? false,
          onChanged: (value) {
            setState(() => m.lifeNotification = value);
            FirestoreHelper().subscribeToLifeNotification(value);
          },
        ),
        if (m.lifeNotification ?? false) _subRows([_lifeTapSelector()]),
        AlertRow(
          title: "Drugs cooldown",
          subtitle: "Get notified when your drugs cooldown has expired",
          value: m.drugsNotification ?? false,
          onChanged: (value) {
            setState(() => m.drugsNotification = value);
            FirestoreHelper().subscribeToDrugsNotification(value);
          },
        ),
        if (m.drugsNotification ?? false) _subRows([_drugsTapSelector()]),
        AlertRow(
          title: "Medical cooldown",
          subtitle: "Get notified when your medical cooldown has expired",
          value: m.medicalNotification ?? false,
          onChanged: (value) {
            setState(() => m.medicalNotification = value);
            FirestoreHelper().subscribeToMedicalNotification(value);
          },
        ),
        if (m.medicalNotification ?? false) _subRows([_medicalTapSelector()]),
        AlertRow(
          title: "Booster cooldown",
          subtitle: "Get notified when your booster cooldown has expired",
          value: m.boosterNotification ?? false,
          onChanged: (value) {
            setState(() => m.boosterNotification = value);
            FirestoreHelper().subscribeToBoosterNotification(value);
          },
        ),
        if (m.boosterNotification ?? false) _subRows([_boosterTapSelector()]),
        AlertRow(
          title: "Hospital admission and release",
          subtitle: "If you are offline, you'll be notified if you are hospitalized, revived or out of hospital",
          value: m.hospitalNotification ?? false,
          onChanged: (value) {
            setState(() => m.hospitalNotification = value);
            FirestoreHelper().subscribeToHospitalNotification(value);
          },
        ),
        AlertRow(
          title: "Refills",
          subtitle: "Get notified if you still have unused refills",
          value: m.refillsNotification ?? false,
          onChanged: (value) {
            setState(() => m.refillsNotification = value);
            FirestoreHelper().subscribeToRefillsNotification(value);
          },
        ),
        if (m.refillsNotification ?? false) _subRows([_refillsTimeSelector(), _refillsChooser()]),
      ],
    );
  }

  static const List<DropdownMenuItem<String>> _cooldownTapItems = [
    DropdownMenuItem(
      value: "app",
      child: SizedBox(
        width: 110,
        child: Text("App", textAlign: TextAlign.right, style: TextStyle(fontSize: 14)),
      ),
    ),
    DropdownMenuItem(
      value: "itemsOwn",
      child: SizedBox(
        width: 110,
        child: Text("Own items", textAlign: TextAlign.right, style: TextStyle(fontSize: 14)),
      ),
    ),
    DropdownMenuItem(
      value: "itemsFaction",
      child: SizedBox(
        width: 110,
        child: Text("Faction items", textAlign: TextAlign.right, style: TextStyle(fontSize: 14)),
      ),
    ),
  ];

  Widget _lifeTapSelector() {
    return _notificationDestinationSelector(
      value: _settingsProvider.lifeNotificationTapAction,
      onChanged: (value) {
        setState(() {
          _settingsProvider.lifeNotificationTapAction = value;
        });
      },
      items: const [
        ..._cooldownTapItems,
        DropdownMenuItem(
          value: "factionMain",
          child: SizedBox(
            width: 110,
            child: Text("Faction page", textAlign: TextAlign.right, style: TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _drugsTapSelector() {
    return _notificationDestinationSelector(
      value: _settingsProvider.drugsNotificationTapAction,
      onChanged: (value) {
        setState(() {
          _settingsProvider.drugsNotificationTapAction = value;
        });
      },
      items: _cooldownTapItems,
    );
  }

  Widget _medicalTapSelector() {
    return _notificationDestinationSelector(
      value: _settingsProvider.medicalNotificationTapAction,
      onChanged: (value) {
        setState(() {
          _settingsProvider.medicalNotificationTapAction = value;
        });
      },
      items: _cooldownTapItems,
    );
  }

  Widget _boosterTapSelector() {
    return _notificationDestinationSelector(
      value: _settingsProvider.boosterNotificationTapAction,
      onChanged: (value) {
        setState(() {
          _settingsProvider.boosterNotificationTapAction = value;
        });
      },
      items: _cooldownTapItems,
    );
  }

  Widget _refillsTimeSelector() {
    return AlertRow(
      sub: true,
      title: "Reminder time",
      trailing: DropdownButton<int>(
        value: _firebaseUserModel?.refillsTime,
        underline: const SizedBox.shrink(),
        isDense: true,
        items: [
          for (int hour = 16; hour <= 23; hour++)
            DropdownMenuItem(
              value: hour,
              child: SizedBox(
                width: 80,
                child: Text("$hour:00 TCT", textAlign: TextAlign.right, style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
        onChanged: (value) async {
          setState(() {
            _firebaseUserModel?.refillsTime = value;
          });
          FirestoreHelper().setRefillTime(value);
        },
      ),
    );
  }

  Widget _refillsChooser() {
    return AlertRow(
      sub: true,
      title: "Choose refills",
      trailing: _chevron(),
      onTap: () {
        showDialog(
          useRootNavigator: false,
          context: context,
          builder: (BuildContext context) {
            return RefillsRequestedDialog(userModel: _firebaseUserModel);
          },
        );
      },
    );
  }

  // ##### TRAVEL & SHOPS #####

  Widget _travelCard() {
    final m = _firebaseUserModel!;
    return _card(
      icon: Icons.flight_takeoff_outlined,
      title: "Travel & shops",
      flags: _travelFlags(),
      children: [
        AlertRow(
          title: "Travel",
          subtitle: "Get notified just before you arrive",
          value: m.travelNotification ?? false,
          onChanged: (value) {
            setState(() => m.travelNotification = value);
            FirestoreHelper().subscribeToTravelNotification(value);
          },
        ),
        if (m.travelNotification ?? false) _subRows([_travelStocksSelector(), _travelNotificationTapSelector()]),
        AlertRow(
          title: "Foreign stocks",
          subtitle:
              "Get notified whenever new stocks are put in the market abroad. To follow specific items, "
              "go to the stocks page (Travel section) and activate the ones you are interested in",
          value: m.foreignRestockNotification ?? false,
          onChanged: (value) {
            setState(() => m.foreignRestockNotification = value);
            FirestoreHelper().subscribeToForeignRestockNotification(value);
          },
        ),
        if (m.foreignRestockNotification ?? false) _foreignRestockOptions(),
        AlertRow(
          title: "City shops",
          subtitle: "Get notified about restocks of city shop items you follow",
          value: m.cityShopRestockNotification ?? false,
          onChanged: (value) {
            setState(() => m.cityShopRestockNotification = value);
            FirestoreHelper().subscribeToCityShopRestockNotification(value).then((success) {
              if (!success && mounted) {
                setState(() => m.cityShopRestockNotification = !value);
                _cityShopUpdateFailedToast();
              }
            });
          },
        ),
        if (m.cityShopRestockNotification ?? false) _cityShopOptions(),
        AlertRow(
          title: "Abroad stay reminders",
          subtitle:
              "Get reminded at the intervals you choose after landing abroad, so you don't forget you are "
              "sitting there. Reminders restart on every trip and stop once you return to Torn",
          value: m.abroadStayNotification ?? false,
          onChanged: (value) {
            setState(() => m.abroadStayNotification = value);
            FirestoreHelper().subscribeToAbroadStayNotification(value);
          },
        ),
        if (m.abroadStayNotification ?? false) _abroadStayOptions(),
      ],
    );
  }

  Widget _travelNotificationTapSelector() {
    return _notificationDestinationSelector(
      value: _settingsProvider.travelNotificationTapAction,
      onChanged: (value) {
        setState(() {
          _settingsProvider.travelNotificationTapAction = value;
        });
      },
      items: _travelTapDestinationItems,
      helperText: _travelTapDestinationExplanation,
    );
  }

  Widget _travelStocksSelector() {
    return AlertRow(
      sub: true,
      title: "Include stocks at destination",
      subtitle:
          "The landing notification will also tell you which of the items you follow are in stock at "
          "your destination",
      value: _firebaseUserModel!.travelStocksInNotification,
      onChanged: (include) {
        setState(() {
          _firebaseUserModel!.travelStocksInNotification = include;
        });
        FirestoreHelper().changeTravelStocksInNotification(include);
      },
    );
  }

  Widget _foreignRestockOptions() {
    final m = _firebaseUserModel!;
    final bool onlyCurrentCountry = m.foreignRestockNotificationOnlyCurrentCountry ?? false;

    return _subRows([
      AlertRow(
        sub: true,
        title: "Limit to current country",
        subtitle: "Only items restocked in the country you are flying to or staying in",
        value: onlyCurrentCountry,
        onChanged: (limit) {
          setState(() {
            m.foreignRestockNotificationOnlyCurrentCountry = limit;
            if (!limit) m.foreignRestockNotificationOnlyLanded = false;
          });
          FirestoreHelper().changeForeignRestockNotificationOnlyCurrentCountry(limit);
        },
      ),
      if (onlyCurrentCountry)
        AlertRow(
          sub: true,
          title: "Alert while still flying",
          subtitle:
              "If off, alerts start once you have landed, so you are not told about a restock you cannot "
              "buy from while in the air",
          value: !m.foreignRestockNotificationOnlyLanded,
          onChanged: (whileFlying) {
            setState(() {
              m.foreignRestockNotificationOnlyLanded = !whileFlying;
            });
            FirestoreHelper().changeForeignRestockNotificationOnlyLanded(!whileFlying);
          },
        ),
      AlertRow(
        sub: true,
        title: "Alert also when items sell out",
        subtitle: "Useful to estimate when the next restock is due",
        value: m.foreignRestockNotificationSellout,
        onChanged: (sellout) {
          setState(() {
            m.foreignRestockNotificationSellout = sellout;
          });
          FirestoreHelper().changeForeignRestockSellout(sellout);
        },
      ),
    ]);
  }

  void _cityShopUpdateFailedToast() {
    BotToast.showText(
      clickClose: true,
      text: "Could not update, check your connection",
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: Colors.orange[900]!,
      duration: const Duration(seconds: 4),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  String _cityShopHourLabel(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, "0");
    final m = (minutes % 60).toString().padLeft(2, "0");
    return "$h:$m";
  }

  // TCT minutes of the day to the device's local time
  String _cityShopLocalLabel(int tctMinutes) {
    final local = (tctMinutes + DateTime.now().timeZoneOffset.inMinutes) % 1440;
    return _cityShopHourLabel(local < 0 ? local + 1440 : local);
  }

  Widget _cityShopHoursExtra() {
    final from = _firebaseUserModel!.cityShopHoursFrom;
    final to = _firebaseUserModel!.cityShopHoursTo;
    String hint = "${_cityShopLocalLabel(from)} to ${_cityShopLocalLabel(to)} in your local time";
    if (from == to) {
      hint = "Same start and end means the whole day";
    } else if (from > to) {
      hint += ", crossing midnight";
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton(
              onPressed: () => _pickCityShopHour(from: true),
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text("From ${_cityShopHourLabel(from)} TCT", style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _pickCityShopHour(from: false),
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text("To ${_cityShopHourLabel(to)} TCT", style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(hint, style: TextStyle(fontSize: 11.5, color: _themeProvider!.mainText.withValues(alpha: 0.78))),
        ),
      ],
    );
  }

  Widget _cityShopMutedRow() {
    final mutedUntil = _firebaseUserModel!.cityShopMutedUntil;
    final muted = mutedUntil > DateTime.now().millisecondsSinceEpoch;
    return AlertRow(
      sub: true,
      title: muted ? "Paused until 00:00 TCT" : "Done for today",
      titleColor: muted ? Colors.red[400] : null,
      boldTitle: muted,
      subtitle: muted
          ? "No city shop alerts until the daily purchase limit resets"
          : "Pause all city shop alerts until the 100 items limit resets at 00:00 TCT",
      trailing: TextButton(onPressed: () => _setCityShopMuted(!muted), child: Text(muted ? "Resume" : "Pause")),
    );
  }

  void _setCityShopMuted(bool mute) {
    final previous = _firebaseUserModel!.cityShopMutedUntil;
    final until = mute ? CityShopDailyLimit.nextTctMidnightMs() : 0;
    setState(() {
      _firebaseUserModel!.cityShopMutedUntil = until;
    });
    FirestoreHelper().setCityShopMutedUntil(until).then((success) {
      if (!success && mounted) {
        setState(() {
          _firebaseUserModel!.cityShopMutedUntil = previous;
        });
        _cityShopUpdateFailedToast();
      }
    });
  }

  Future<void> _pickCityShopHour({required bool from}) async {
    final current = from ? _firebaseUserModel!.cityShopHoursFrom : _firebaseUserModel!.cityShopHoursTo;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: ThemeData.from(
              colorScheme: _themeProvider!.currentTheme == AppTheme.light
                  ? const ColorScheme.light()
                  : const ColorScheme.dark(),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    final previous = current;
    setState(() {
      if (from) {
        _firebaseUserModel!.cityShopHoursFrom = minutes;
      } else {
        _firebaseUserModel!.cityShopHoursTo = minutes;
      }
    });
    _saveCityShopHours(revertFrom: from ? previous : null, revertTo: from ? null : previous);
  }

  // Writes the three hour fields together; on failure restores whichever value changed
  void _saveCityShopHours({bool? revertEnabled, int? revertFrom, int? revertTo}) {
    final model = _firebaseUserModel!;
    FirestoreHelper()
        .setCityShopHours(
          enabled: model.cityShopHoursEnabled,
          fromMin: model.cityShopHoursFrom,
          toMin: model.cityShopHoursTo,
        )
        .then((success) {
          if (success || !mounted) return;
          setState(() {
            if (revertEnabled != null) model.cityShopHoursEnabled = revertEnabled;
            if (revertFrom != null) model.cityShopHoursFrom = revertFrom;
            if (revertTo != null) model.cityShopHoursTo = revertTo;
          });
          _cityShopUpdateFailedToast();
        });
  }

  Widget _cityShopOptions() {
    final m = _firebaseUserModel!;
    return _subRows([
      AlertRow(
        sub: true,
        title: "Only notify when in stock",
        subtitle: "Skip the early warning, notify only when the restock is seen",
        value: m.cityShopOnlyConfirmed,
        onChanged: (onlyConfirmed) {
          setState(() => m.cityShopOnlyConfirmed = onlyConfirmed);
          FirestoreHelper().setCityShopOnlyConfirmed(onlyConfirmed).then((success) {
            if (!success && mounted) {
              setState(() => m.cityShopOnlyConfirmed = !onlyConfirmed);
              _cityShopUpdateFailedToast();
            }
          });
        },
      ),
      AlertRow(
        sub: true,
        title: "Only when in Torn",
        subtitle: "Skip alerts while flying or abroad",
        value: m.cityShopOnlyInTorn,
        onChanged: (onlyInTorn) {
          setState(() => m.cityShopOnlyInTorn = onlyInTorn);
          FirestoreHelper().setCityShopOnlyInTorn(onlyInTorn).then((success) {
            if (!success && mounted) {
              setState(() => m.cityShopOnlyInTorn = !onlyInTorn);
              _cityShopUpdateFailedToast();
            }
          });
        },
      ),
      AlertRow(
        sub: true,
        title: "Only between certain hours",
        subtitle: "Torn City Time. Alerts outside the range are skipped, not delayed",
        value: m.cityShopHoursEnabled,
        onChanged: (enabled) {
          setState(() => m.cityShopHoursEnabled = enabled);
          _saveCityShopHours(revertEnabled: !enabled);
        },
        extra: m.cityShopHoursEnabled ? _cityShopHoursExtra() : null,
      ),
      _cityShopMutedRow(),
      AlertRow(
        sub: true,
        title: "Auto-pause at the daily limit",
        titleTrailing: const AlertChip("experimental", kind: AlertChipKind.warning),
        subtitle:
            "Counts what you buy in city shops from the browser and pauses alerts at 100 items, or as soon "
            "as Torn reports the limit",
        value: _cityShopAutoPause,
        onChanged: (enabled) {
          setState(() => _cityShopAutoPause = enabled);
          Prefs().setCityShopAutoPauseEnabled(enabled);
        },
      ),
      AlertRow(
        sub: true,
        title: "Choose the items to follow",
        subtitle: "Browse city shop items, filter by shop or mode, and pick the ones you want alerts for",
        trailing: _chevron(),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CityShopsPage()));
        },
      ),
    ]);
  }

  Widget _travelLiveActivityTapSelector() {
    return _notificationDestinationSelector(
      value: _settingsProvider.travelLiveActivityTapAction,
      onChanged: (value) {
        setState(() {
          _settingsProvider.travelLiveActivityTapAction = value;
        });
      },
      items: _travelTapDestinationItems,
      label: Platform.isAndroid ? "Live Update tap opens" : "Live Activity tap opens",
      helperText: _travelTapDestinationExplanation,
    );
  }

  static const String _travelTapDestinationExplanation =
      "If set to Foreign Stocks, this only applies while flying abroad. The page will show all items filtered "
      "to your destination country, and trips back to Torn will still open the browser.";

  static const List<DropdownMenuItem<String>> _travelTapDestinationItems = [
    DropdownMenuItem(
      value: "browser",
      child: SizedBox(
        width: 110,
        child: Text("Browser", textAlign: TextAlign.right, style: TextStyle(fontSize: 14)),
      ),
    ),
    DropdownMenuItem(
      value: "foreignStocks",
      child: SizedBox(
        width: 110,
        child: Text("Foreign Stocks", textAlign: TextAlign.right, style: TextStyle(fontSize: 14)),
      ),
    ),
  ];

  // Selectable intervals (in minutes) for the abroad-stay reminder.
  static const List<(int minutes, String label)> _abroadStayIntervalChoices = [
    (5, '5 min'),
    (15, '15 min'),
    (30, '30 min'),
    (60, '1 h'),
    (360, '6 h'),
    (720, '12 h'),
    (1440, '24 h'),
  ];

  Widget _abroadStayOptions() {
    final selected = _firebaseUserModel!.abroadStayIntervals.toSet();
    return _subRows([
      AlertRow(
        sub: true,
        title: "Remind me at",
        extra: Wrap(
          spacing: 6,
          runSpacing: -4,
          children: _abroadStayIntervalChoices.map((choice) {
            final isSelected = selected.contains(choice.$1);
            return FilterChip(
              label: Text(choice.$2, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              visualDensity: VisualDensity.compact,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selected.add(choice.$1);
                  } else {
                    selected.remove(choice.$1);
                  }
                  // Keep the list deterministic (ascending order) before persisting.
                  final ordered = selected.toList()..sort();
                  _firebaseUserModel!.abroadStayIntervals = ordered;
                });
                final ordered = selected.toList()..sort();
                FirestoreHelper().setAbroadStayIntervals(ordered);
              },
            );
          }).toList(),
        ),
      ),
      AlertRow(
        sub: true,
        title: "Include hospital stays",
        subtitle: "If off, reminders pause while you are hospitalised abroad and resume once you are out",
        value: _firebaseUserModel!.abroadStayIncludeHospital,
        onChanged: (include) {
          setState(() {
            _firebaseUserModel!.abroadStayIncludeHospital = include;
          });
          FirestoreHelper().setAbroadStayIncludeHospital(include);
        },
      ),
    ]);
  }

  Widget _notificationDestinationSelector({
    required String value,
    required ValueChanged<String?> onChanged,
    required List<DropdownMenuItem<String>> items,
    String label = "Notification tap opens",
    String? helperText,
  }) {
    return AlertRow(
      sub: true,
      title: label,
      subtitle: helperText,
      trailing: DropdownButton<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        isDense: true,
      ),
    );
  }

  // ##### LIVE ACTIVITIES #####

  Widget _liveActivitiesCard() {
    String laHeader =
        "Live activities will only start if you have Torn PDA open in the foreground when they take place. "
        "You'll see them in the lock screen and the dynamic island (if supported)";

    if (Platform.isIOS && kSdkIos >= 17.2) {
      laHeader =
          "Live activities start immediately if you have Torn PDA open in the foreground, or after a few minutes "
          "when it's in the background or completely closed. They show in the lock screen and dynamic island.";
    } else if (Platform.isAndroid) {
      laHeader =
          "Live Updates show a persistent notification with a countdown timer for your travel. They are triggered "
          "when Torn PDA is in the foreground while you are already traveling. With battery optimization enabled, "
          "the update might stop when the app is in the background.";
    }

    final bool travelOn = Platform.isAndroid
        ? _settingsProvider.androidLiveActivityTravelEnabled
        : _settingsProvider.iosLiveActivityTravelEnabled;
    final bool racingOn = Platform.isAndroid
        ? _settingsProvider.androidLiveActivityRacingEnabled
        : _settingsProvider.iosLiveActivityRacingEnabled;

    return _card(
      icon: Icons.timelapse_outlined,
      title: Platform.isAndroid ? "Live Updates" : "Live Activities",
      flags: [travelOn, racingOn],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Text(
            laHeader,
            style: TextStyle(fontSize: 11.5, height: 1.35, color: _themeProvider!.mainText.withValues(alpha: 0.78)),
          ),
        ),
        AlertRow(
          title: "Travel",
          subtitle: "Countdown to your destination",
          value: travelOn,
          onChanged: (enabled) async {
            if (Platform.isAndroid) {
              setState(() {
                _settingsProvider.androidLiveActivityTravelEnabled = enabled;
              });
            } else {
              setState(() {
                // This setter will eventually also get or delete token from Firestore
                _settingsProvider.iosLiveActivityTravelEnabled = enabled;
              });
            }

            final bool nowEnabled = Platform.isAndroid
                ? _settingsProvider.androidLiveActivityTravelEnabled
                : _settingsProvider.iosLiveActivityTravelEnabled;

            if (nowEnabled) {
              if (Platform.isAndroid) {
                _checkAndroidBatteryOptimization();
              }

              await Get.find<LiveActivityTravelController>().activate();
              Get.find<LiveActivityBridgeController>().initializeHandler();
            } else {
              Get.find<LiveActivityTravelController>().deactivate();
            }
          },
        ),
        if (travelOn) _subRows([_travelLiveActivityTapSelector()]),
        AlertRow(
          title: "Racing",
          subtitle: "Progress of your current race",
          value: racingOn,
          onChanged: (enabled) async {
            setState(() {
              if (Platform.isAndroid) {
                _settingsProvider.androidLiveActivityRacingEnabled = enabled;
              } else {
                _settingsProvider.iosLiveActivityRacingEnabled = enabled;
              }
            });

            final bool racingEnabled = Platform.isAndroid
                ? _settingsProvider.androidLiveActivityRacingEnabled
                : _settingsProvider.iosLiveActivityRacingEnabled;

            if (racingEnabled) {
              if (Platform.isAndroid) {
                _checkAndroidBatteryOptimization();
              }
              await Get.find<LiveActivityRacingController>().activate();
              Get.find<LiveActivityBridgeController>().initializeHandler();
            } else {
              Get.find<LiveActivityRacingController>().deactivate();
            }
          },
        ),
      ],
    );
  }

  // ##### FACTION & COMBAT #####

  Widget _factionCard() {
    final m = _firebaseUserModel!;
    return _card(
      icon: Icons.shield_outlined,
      title: "Faction & combat",
      flags: _factionFlags(),
      children: [
        AlertRow(
          title: "Retaliation",
          titleTrailing: GestureDetector(
            child: Icon(Icons.info_outline_rounded, size: 20, color: _factionApiAccess ? Colors.green : Colors.orange),
            onTap: () async {
              await showDialog(
                useRootNavigator: false,
                context: context,
                builder: (BuildContext context) {
                  return _retalsGeneralExplanation();
                },
              );
            },
          ),
          subtitle: "Get notified whenever it is possible to initiate a retaliation attack",
          value: m.retalsNotification ?? false,
          onChanged: _onRetalsToggled,
        ),
        if ((m.retalsNotification ?? false) && _factionApiAccess) _retalsOptions(),
        AlertRow(
          title: "Faction assist messages",
          subtitle: "Receive attack assist messages manually triggered by your faction mates",
          value: m.factionAssistMessage ?? false,
          onChanged: (value) {
            setState(() => m.factionAssistMessage = value);
            FirestoreHelper().toggleFactionAssistMessage(value);
          },
        ),
        AlertRow(
          title: "Loot",
          subtitle: "Get notified when an NPC is about to reach level 4 or 5",
          value: m.lootAlerts.isNotEmpty,
          onChanged: (value) async {
            await showDialog(
              useRootNavigator: false,
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return LootAlertsDialog(userModel: _firebaseUserModel);
              },
            );
            setState(() {
              // Refresh lootAlerts (check or uncheck box)
            });
          },
        ),
        if (m.lootAlerts.isNotEmpty)
          _subRows([AlertRow(sub: true, title: "Lead time", trailing: _lootAheadDropdown())]),
        AlertRow(
          title: "Loot Rangers attack",
          titleTrailing: GestureDetector(
            onTap: () async {
              await showDialog(
                useRootNavigator: false,
                context: context,
                builder: (BuildContext context) {
                  return LootRangersExplanationDialog(themeProvider: _themeProvider);
                },
              );
            },
            child: const Icon(Icons.info_outline, size: 20),
          ),
          subtitle: "Get notified shortly before a Loot Ranger attack, including attack order",
          value: m.lootRangersAlerts ?? false,
          onChanged: (value) {
            setState(() => m.lootRangersAlerts = value);
            FirestoreHelper().subscribeToLootRangersNotification(value);
          },
        ),
        if (m.lootRangersAlerts ?? false)
          _subRows([AlertRow(sub: true, title: "Lead time", trailing: _lootRangersAheadDropdown())]),
        AlertRow(
          title: "Racing",
          subtitle: "Get notified when you cross the finish line",
          value: m.racingNotification ?? false,
          onChanged: (value) {
            setState(() => m.racingNotification = value);
            FirestoreHelper().subscribeToRacingNotification(value);
          },
        ),
      ],
    );
  }

  Future<void> _onRetalsToggled(bool enabled) async {
    if (!enabled) {
      setState(() {
        _firebaseUserModel?.retalsNotification = enabled;
      });
      FirestoreHelper().toggleRetaliationNotification(enabled);
      return;
    }

    if (_factionApiAccess) {
      setState(() {
        _firebaseUserModel?.retalsNotification = enabled;
      });
      FirestoreHelper().toggleRetaliationNotification(enabled);

      // Makes sure to scroll down so that the new 2 options are visible
      _scrollController.animateTo(
        _scrollController.offset + 100,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
      );
    } else {
      String message = "";
      int seconds = 0;

      if (!_factionApiAccessCheckError) {
        setState(() {
          _firebaseUserModel?.retalsNotification = enabled;
        });
        FirestoreHelper().toggleRetaliationNotification(enabled, host: false);
        message =
            "You have no faction API permissions (talk to your leadership about it).\n\n"
            "This alert has been activated, but it won't work unless someone with proper "
            "permissions in your faction activates it as well.";
        seconds = 10;
      } else {
        message =
            "It's not possible to activate this alert now (Torn PDA can't verify whether "
            "you have proper Faction API permissions).\n\nPlease try again later!";
        seconds = 6;
      }

      BotToast.showText(
        clickClose: true,
        text: message,
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.orange[900]!,
        duration: Duration(seconds: seconds),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  Widget _retalsOptions() {
    return _subRows([
      AlertRow(
        sub: true,
        title: "Single target opens browser",
        titleTrailing: GestureDetector(
          child: const Icon(Icons.info_outline_rounded, size: 18),
          onTap: () async {
            await showDialog(
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) {
                return _retalsNotificationExplanation();
              },
            );
          },
        ),
        value: _settingsProvider.singleRetaliationOpensBrowser,
        onChanged: (enabled) {
          setState(() {
            _settingsProvider.setSingleRetaliationOpensBrowser = enabled;
          });
        },
      ),
      AlertRow(
        sub: true,
        title: "Only as API permission donor",
        titleTrailing: GestureDetector(
          child: const Icon(Icons.info_outline_rounded, size: 18),
          onTap: () async {
            await showDialog(
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) {
                return _retalsDonorExplanation();
              },
            );
          },
        ),
        value: _firebaseUserModel?.retalsNotificationDonor ?? false,
        onChanged: (enabled) {
          if (enabled) {
            BotToast.showText(
              text:
                  "Please make sure that you understand the consequences of this setting "
                  "by reading the information dialog.\n\n"
                  "You will NOT receive relation alerts.",
              textStyle: const TextStyle(fontSize: 14, color: Colors.white),
              contentColor: Colors.blue,
              duration: const Duration(seconds: 6),
              contentPadding: const EdgeInsets.all(10),
            );
          }
          setState(() {
            _firebaseUserModel?.retalsNotificationDonor = enabled;
          });
          FirestoreHelper().toggleRetaliationDonor(enabled);
        },
      ),
    ]);
  }

  // ##### SOCIAL #####

  Widget _socialCard() {
    final m = _firebaseUserModel!;
    return _card(
      icon: Icons.forum_outlined,
      title: "Social",
      flags: _socialFlags(),
      children: [
        AlertRow(
          title: "Messages",
          subtitle: "Get notified when you receive new messages",
          value: m.messagesNotification ?? false,
          onChanged: (value) {
            setState(() => m.messagesNotification = value);
            FirestoreHelper().subscribeToMessagesNotification(value);
          },
        ),
        AlertRow(
          title: "Events",
          subtitle: "Get notified when you receive new events",
          value: m.eventsNotification ?? false,
          onChanged: (value) {
            setState(() => m.eventsNotification = value);
            FirestoreHelper().subscribeToEventsNotification(value);
          },
        ),
        if (m.eventsNotification ?? false)
          _subRows([
            AlertRow(
              sub: true,
              title: "Filter out events",
              trailing: _chevron(),
              onTap: () {
                showDialog(
                  useRootNavigator: false,
                  context: context,
                  builder: (BuildContext context) {
                    return EventsFilterDialog(userModel: _firebaseUserModel);
                  },
                );
              },
            ),
          ]),
        GetBuilder(init: SendbirdController(), builder: (sendbird) => _tornChatRows(sendbird)),
        AlertRow(
          title: "Forums subscribed threads",
          subtitle:
              "Get notified about new posts in threads you are subscribed to. Checks run every 15 minutes "
              "to avoid excessive API load",
          value: m.forumsSubscription ?? false,
          onChanged: (value) {
            setState(() => m.forumsSubscription = value);
            FirestoreHelper().subscribeToForumsSubcriptionsNotification(value);
          },
        ),
      ],
    );
  }

  Widget _tornChatRows(SendbirdController sendbird) {
    final bool available =
        (Platform.isAndroid && sendbird.sendBirdPushAndroidRemoteConfigEnabled) ||
        (Platform.isIOS && sendbird.sendBirdPushIOSRemoteConfigEnabled);

    if (!available) {
      return AlertRow(
        title: "Torn chat messages",
        subtitle:
            "Notifications for Torn chat messages are temporarily disabled. You can find more information "
            "in the forums or Discord. Apologies for the inconvenience.",
        subtitleColor: _themeProvider!.getTextColor(Colors.orange[900]!),
        value: false,
      );
    }

    final String otherDevicesNote =
        "NOTE: this will affect all installations of Torn PDA & ${Platform.isAndroid ? 'Lite' : 'City'} in other "
        "devices that you use with this player account";

    AlertRow excludeRow({
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return AlertRow(
        sub: true,
        title: title,
        subtitle: value ? "$subtitle. $otherDevicesNote" : subtitle,
        subtitleColor: value ? _themeProvider!.getTextColor(Colors.orange[900]!) : null,
        value: value,
        onChanged: onChanged,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AlertRow(
          title: "Torn chat messages",
          subtitle: "Enable notifications for Torn chat messages",
          value: sendbird.sendBirdNotificationsEnabled,
          trailing: _togglingSendbirdNotifications
              ? const Padding(
                  padding: EdgeInsets.only(right: 14.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : null,
          onChanged: (enabled) async {
            setState(() {
              _togglingSendbirdNotifications = true;
            });
            await sendbird.sendBirdNotificationsToggle(enabled: enabled);
            setState(() {
              _togglingSendbirdNotifications = false;
            });
          },
        ),
        if (sendbird.sendBirdNotificationsEnabled)
          _subRows([
            AlertRow(
              sub: true,
              title: "Do not disturb",
              trailing: Icon(Icons.more_time_outlined, color: _themeProvider!.mainText.withValues(alpha: 0.78)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SendbirdDoNotDisturbDialog();
                  },
                );
              },
            ),
            excludeRow(
              title: "Exclude faction messages",
              subtitle: "Faction messages won't be shown",
              value: sendbird.excludeFactionMessages,
              onChanged: (enabled) => sendbird.excludeFactionMessages = enabled,
            ),
            excludeRow(
              title: "Exclude company messages",
              subtitle: "Company messages won't be shown",
              value: sendbird.excludeCompanyMessages,
              onChanged: (enabled) => sendbird.excludeCompanyMessages = enabled,
            ),
            excludeRow(
              title: "Exclude Elimination event messages",
              subtitle: "Elimination event messages won't be shown",
              value: sendbird.excludeEliminationMessages,
              onChanged: (enabled) => sendbird.excludeEliminationMessages = enabled,
            ),
          ]),
      ],
    );
  }

  // ##### OTHER #####

  Widget _otherCard() {
    final m = _firebaseUserModel!;
    return _card(
      icon: Icons.tune_outlined,
      title: "Other",
      flags: _otherFlags(),
      children: [
        AlertRow(
          title: "Stock market gain/loss",
          subtitle: "Configure price gain/loss alerts for any traded company",
          trailing: _chevron(),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return StockMarketAlertsPage(
                    fbUser: _firebaseUserModel,
                    calledFromMenu: false,
                    stockMarketInMenuCallback: widget.stockMarketInMenuCallback,
                  );
                },
              ),
            );
          },
        ),
        AlertRow(
          title: "Work stats targets",
          subtitle:
              "Get notified once your manual labor, intelligence or endurance reach the values you choose. "
              "Each target is cleared as soon as it's reached, and the alert switches itself off when no targets "
              "are left",
          value: m.workStatsNotification ?? false,
          onChanged: (value) => _onWorkStatsToggled(value),
        ),
        if (m.workStatsNotification ?? false) _subRows([_workStatsTargets()]),
      ],
    );
  }

  Future<void> _checkAndroidBatteryOptimization() async {
    const channel = MethodChannel('tornpda.channel');
    try {
      final bool isRestricted = await channel.invokeMethod('checkBatteryOptimization');
      if (isRestricted && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Battery Optimization Detected"),
            content: const Text(
              "To ensure Live Updates work correctly in the background, please disable battery optimization for Torn PDA.",
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  channel.invokeMethod('openBatterySettings');
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Ignore errors
    }
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text('Alerts', style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
          if (scaffoldState != null) {
            if (_webViewProvider.webViewSplitActive &&
                _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
              scaffoldState.openEndDrawer();
            } else {
              scaffoldState.openDrawer();
            }
          }
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.handyman),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AlertsTroubleshootingPage(
                  firebaseUserModel: _firebaseUserModel,
                  reassignFirebaseUserModelCallback: _reassignUserAfterTsm,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showDialog(
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) {
                return _alertsInfoDialog();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _connectError() {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('There was an error contacting the server!', style: TextStyle(color: Colors.red)),
          SizedBox(height: 20),
          Text('Please try again later.', style: TextStyle(color: Colors.red)),
          SizedBox(height: 20),
          Text(
            'If this problem reoccurs, please log out from Torn API (remove '
            'you API Key in the Settings section and insert it again). Sorry for '
            'the inconvenience!',
          ),
        ],
      ),
    );
  }

  Widget _alertsInfoDialog() {
    return AlertDialog(
      title: const Text("Alerts", style: TextStyle(fontSize: 18)),
      content: const SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Note: if you don't use Torn PDA for more than 5 days, "
                "all notifications will be turned off automatically. "
                "\n\nThis is to prevent the over usage of resources. "
                "Please make sure you return back to the app once a "
                "week to get uninterrupted service.",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _reassignUserAfterTsm(FirebaseUserModel fb) {
    setState(() {
      _firebaseUserModel = fb;
    });
  }

  AlertDialog _retalsGeneralExplanation() {
    return AlertDialog(
      title: const Text("Retaliation alerts"),
      content: Scrollbar(
        controller: _scrollControllerRetalsGeneral,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollControllerRetalsGeneral,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NOTE: you will not receive retaliation alerts when traveling, nor when the attack took place abroad "
                  "and you are in Torn, nor if the attack took place in Torn and you are abroad.\n\nHowever, due to API limits, "
                  "you might receive spurious notifications when you are abroad but in a different country from the attack.\n\n"
                  "Depending on your API permissions, more detailed information about the attack, location, etc., "
                  "will be available in the Chaining section of the app, as explained below:\n\n",
                  style: TextStyle(fontSize: 13),
                ),
                if (!_factionApiAccess)
                  const Text(
                    "You DO NOT HAVE Faction API access\n\n",
                    style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    "You HAVE Faction API access\n\n",
                    style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                if (!_factionApiAccess)
                  const Text(
                    "For retaliation notifications to work, at least one member of your faction with API access "
                    " privileges must have this alert active in Torn PDA. If this condition is not met at some point, "
                    "Torn PDA will notify you about it so that you can discuss this internally.\n\n",
                    style: TextStyle(fontSize: 13),
                  )
                else
                  const Text(
                    "For retaliation notifications to work, at least one member of your faction with API access "
                    " privileges must have this alert active in Torn PDA. This can be you or any other member.\n\n",
                    style: TextStyle(fontSize: 13),
                  ),
                if (!_factionApiAccess)
                  const Text(
                    "As you have no Faction API access, but the above criteria is met, you will be able to receive "
                    "notifications, but you won't be able to access the Retaliation target list (in Chaining).",
                    style: TextStyle(fontSize: 13),
                  )
                else
                  const Text(
                    "Members of your faction with no Faction API access will be able to receive "
                    "notifications, but they won't be able to access the Retaliation target list (in Chaining).",
                    style: TextStyle(fontSize: 13),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  AlertDialog _retalsNotificationExplanation() {
    return AlertDialog(
      title: const Text("Retaliation notification"),
      content: Scrollbar(
        controller: _scrollControllerRetalsNotification,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollControllerRetalsNotification,
          child: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "By default, on tapping a retaliation notification you will be redirected to the Retaliation "
                  "section (inside of Chaining); this is independent of how many targets are available for retaliation "
                  "at the same time.\n\nIn this section you can have a look at the stats, target status, etc."
                  "\n\nHowever, if you enable this option, retaliation notifications with a single target "
                  "will automatically open the browser and take you straight to the attack page.\n\n"
                  "NOTE: this will have no effect if you have no faction API permissions, as the browser will "
                  "open in any case.",
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  AlertDialog _retalsDonorExplanation() {
    return AlertDialog(
      title: const Text("Retaliation API Faction permissions donor"),
      content: Scrollbar(
        controller: _scrollControllerRetalsDonor,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollControllerRetalsDonor,
          child: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "As explained in the Retalation Alerts information dialog, as a member of your faction with the "
                  "required Faction API access, your API key send retaliation notifications to faction members. "
                  "This will work as long as retalation alerts are active.\n\n"
                  "However, if you personally would prefer NOT to receive these notifications but continue to act "
                  "as a Faction API permission donor (so that the server can still notify other members), make "
                  "sure to activate this option.",
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  Widget _lootAheadDropdown() {
    final options = <Map<String, String>>[
      {"value": "180", "label": "3 minutes"},
      {"value": "360", "label": "6 minutes"},
      {"value": "600", "label": "10 minutes"},
    ];

    return DropdownButton<String>(
      value: _lootAheadSelection,
      items: options.map((opt) => DropdownMenuItem<String>(value: opt["value"], child: Text(opt["label"]!))).toList(),
      onChanged: (value) {
        if (value == null) return;
        final int? seconds = int.tryParse(value);
        if (seconds == null) return;
        setState(() {
          _lootAheadSelection = value;
          _firebaseUserModel?.lootAlertAheadSeconds = seconds;
        });
        FirestoreHelper().setLootAlertAheadSeconds(seconds);
      },
    );
  }

  Widget _lootRangersAheadDropdown() {
    final options = <Map<String, String>>[
      {"value": "180", "label": "3 minutes"},
      {"value": "360", "label": "6 minutes"},
      {"value": "600", "label": "10 minutes"},
    ];

    return DropdownButton<String>(
      value: _lootRangersAheadSelection,
      items: options.map((opt) => DropdownMenuItem<String>(value: opt["value"], child: Text(opt["label"]!))).toList(),
      onChanged: (value) {
        if (value == null) return;
        final int? seconds = int.tryParse(value);
        if (seconds == null) return;
        setState(() {
          _lootRangersAheadSelection = value;
          _firebaseUserModel?.lootRangersAheadSeconds = seconds;
        });
        FirestoreHelper().setLootRangersAheadSeconds(seconds);
      },
    );
  }

  bool _anyWorkStatsTarget() {
    return _firebaseUserModel!.workStatsManualLaborTarget > 0 ||
        _firebaseUserModel!.workStatsIntelligenceTarget > 0 ||
        _firebaseUserModel!.workStatsEnduranceTarget > 0;
  }

  void _workStatsToast(String message) {
    BotToast.showText(
      clickClose: true,
      text: message,
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: Colors.orange[900]!,
      duration: const Duration(seconds: 4),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Future<bool> _showWorkStatsTargetsDialog() async {
    final saved = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return WorkStatsTargetsDialog(userModel: _firebaseUserModel);
      },
    );
    return saved == true;
  }

  Future<void> _onWorkStatsToggled(bool enabled) async {
    if (!enabled) {
      setState(() {
        _firebaseUserModel?.workStatsNotification = false;
      });
      FirestoreHelper().subscribeToWorkStatsNotification(false);
      return;
    }

    if (!_anyWorkStatsTarget()) {
      final saved = await _showWorkStatsTargetsDialog();
      if (!saved || !_anyWorkStatsTarget()) {
        _workStatsToast("Set at least one target to enable this alert");
        return;
      }
    }

    setState(() {
      _firebaseUserModel?.workStatsNotification = true;
    });
    FirestoreHelper().subscribeToWorkStatsNotification(true);
  }

  Widget _workStatsTargets() {
    final formatter = NumberFormat("#,##0", "en_US");

    String targetLabel(int target) => target > 0 ? formatter.format(target) : "not set";

    return AlertRow(
      sub: true,
      title: "Targets",
      subtitle:
          "Manual labor: ${targetLabel(_firebaseUserModel!.workStatsManualLaborTarget)}\n"
          "Intelligence: ${targetLabel(_firebaseUserModel!.workStatsIntelligenceTarget)}\n"
          "Endurance: ${targetLabel(_firebaseUserModel!.workStatsEnduranceTarget)}",
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () async {
          final saved = await _showWorkStatsTargetsDialog();
          if (!saved) return;
          setState(() {});
          if (!_anyWorkStatsTarget()) {
            setState(() {
              _firebaseUserModel?.workStatsNotification = false;
            });
            FirestoreHelper().subscribeToWorkStatsNotification(false);
            _workStatsToast("Work stats alert disabled, as you removed all targets");
          }
        },
      ),
    );
  }

  Future _getFactionApiAccess() async {
    // Assess whether we have permits
    final attacksResult = await ApiCallsV1.getFactionAttacks();
    if (attacksResult is FactionAttacksModel) {
      _factionApiAccess = true;
    } else if (attacksResult is ApiError) {
      _factionApiAccess = false;
      if (!attacksResult.errorReason.contains("incorrect ID-entity relation")) {
        _factionApiAccessCheckError = true;
      }
    }
  }
}
