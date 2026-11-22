import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/territory_map/alert_subscriptions.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/models/territory_map/map_video.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/war_fronts.dart';
import 'package:torn_pda/providers/city_item_prices.dart';
import 'package:torn_pda/providers/faction_flights_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_alerts_controller.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_map_orientation.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/providers/territory_share_controller.dart';
import 'package:torn_pda/providers/territory_timelapse_controller.dart';
import 'package:torn_pda/providers/territory_video_controller.dart';
import 'package:torn_pda/providers/territory_wars_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/territory_map/map_video_encoder.dart';
import 'package:torn_pda/utils/territory_map/territory_map_share.dart';
import 'package:torn_pda/utils/territory_map/territory_map_video_share.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/territory_map/activity_layer.dart';
import 'package:torn_pda/widgets/territory_map/assault_locks_layer.dart';
import 'package:torn_pda/widgets/territory_map/city_finder_panel.dart';
import 'package:torn_pda/widgets/territory_map/city_map_layer.dart';
import 'package:torn_pda/widgets/territory_map/diary_sheet.dart';
import 'package:torn_pda/widgets/territory_map/diary_strip.dart';
import 'package:torn_pda/widgets/territory_map/faction_sheet.dart';
import 'package:torn_pda/widgets/territory_map/flights_button.dart';
import 'package:torn_pda/widgets/territory_map/flights_sheet.dart';
import 'package:torn_pda/widgets/territory_map/map_3d_switch.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_options_sheet.dart';
import 'package:torn_pda/widgets/territory_map/map_safe_margin.dart';
import 'package:torn_pda/widgets/territory_map/map_share_button.dart';
import 'package:torn_pda/widgets/territory_map/rackets_sheet.dart';
import 'package:torn_pda/widgets/territory_map/territory_alerts_sheet.dart';
import 'package:torn_pda/widgets/territory_map/territory_map_3d_view.dart';
import 'package:torn_pda/widgets/territory_map/territory_map_legend.dart';
import 'package:torn_pda/widgets/territory_map/territory_map_search.dart';
import 'package:torn_pda/widgets/territory_map/territory_map_view.dart';
import 'package:torn_pda/widgets/territory_map/territory_sheet.dart';
import 'package:torn_pda/widgets/territory_map/timelapse_bar.dart';
import 'package:torn_pda/widgets/territory_map/video_dialogs.dart';
import 'package:torn_pda/widgets/territory_map/war_arrows_layer.dart';
import 'package:torn_pda/widgets/territory_map/war_sheet.dart';
import 'package:torn_pda/widgets/territory_map/wars_sheet.dart';

// Torn's own wait is 15 s
const _pickTimeout = Duration(seconds: 20);
const _photosWait = Duration(seconds: 2);

const _flightsButtonGap = 14.0;

// Life in shared pictures and videos
const _lifeInShares = false;

enum _MapList { rackets, wars, diary, layers, alerts, flights }

class TerritoryMapPage extends StatefulWidget {
  const TerritoryMapPage({
    super.key,
    this.calledFromMenu = false,
    this.city,
    this.cityPrices,
    this.pickItem,
    this.mapKey,
    this.lifeHidden,
  });

  final bool calledFromMenu;

  // Opened above city.php, pops the tapped site
  final CityPageData? city;
  final CityItemPrices? cityPrices;
  final Future<Object?> Function(CityItem item)? pickItem;

  // For the picture left in city.php
  final GlobalKey? mapKey;
  final ValueNotifier<bool>? lifeHidden;

  @override
  State<TerritoryMapPage> createState() => _TerritoryMapPageState();
}

class _TerritoryMapPageState extends State<TerritoryMapPage> with WidgetsBindingObserver {
  late final TerritoryMapController _controller;
  late final TerritoryHistoryController _history;
  late final TerritoryAlertsController _alerts;
  late final TerritoryShareController _share;
  late final _mapKey = widget.mapKey ?? GlobalKey();
  final _legendKey = GlobalKey();
  bool _takingPicture = false;
  final _search = TextEditingController();
  bool _searching = false;
  CityMapLayer? _cityLayer;
  late final _locksLayer = AssaultLocksLayer(_controller);
  WarArrowsLayer? _warLayer;
  late final _activityLayer = ActivityLayer(_controller, _history);
  bool _frontsAsked = false;
  bool _yearsAsked = false;
  bool _picking = false;
  _MapList? _list;
  late final _timelapse = TerritoryTimelapseController(_controller, _history, inCity: widget.city != null);
  final _video = TerritoryVideoController(StoryMapVideoEncoder());
  late final TerritoryMapOrientation _orientation;
  late final _flights = FactionFlightsController(last: _controller.lastFlights);

  WebViewProvider? _browser;
  bool _behindBrowser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = context.read<TerritoryMapController>();
    _orientation = TerritoryMapOrientation(context.read<SettingsProvider>());
    _alerts = context.read<TerritoryAlertsController>()..addListener(_applyAlertTap);
    _share = context.read<TerritoryShareController>()..addListener(_applySharedView);
    widget.lifeHidden?.addListener(_onLifeHidden);
    _openMap();
    _history = context.read<TerritoryHistoryController>()..open(this, moveLastLook: widget.city == null);
    final city = widget.city;
    if (city != null) _cityLayer = CityMapLayer(city, _controller, prices: widget.cityPrices)..loadImages();
    if (widget.calledFromMenu) {
      _browser = context.read<WebViewProvider>()..addListener(_onBrowser);
      _onBrowser();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _browser?.removeListener(_onBrowser);
    widget.lifeHidden?.removeListener(_onLifeHidden);
    _video.dispose();
    _timelapse.dispose();
    _flights.dispose();
    _orientation.release();
    _controller.close(this);
    _controller.closeCity(this);
    _alerts.removeListener(_applyAlertTap);
    _share.removeListener(_applySharedView);
    if (widget.city == null) WidgetsBinding.instance.addPostFrameCallback((_) => _controller.restoreSwitches());
    _history.close(this);
    _cityLayer?.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_behindBrowser) {
      _controller.open(this, myFactionId: UserHelper.factionId);
      context.read<TerritoryWarsController>().resume();
      _history.resume();
    } else if (state == AppLifecycleState.paused) {
      _controller.close(this);
      context.read<TerritoryWarsController>().pause();
      _history.pause();
      _timelapse.pause();
      _video.cancel();
    }
  }

  void _onLifeHidden() {
    if (mounted) setState(() {});
  }

  bool get _showLife => (_lifeInShares || !_takingPicture) && !(widget.lifeHidden?.value ?? false);

  void _onBrowser() {
    final browser = _browser!;
    final behind = browser.browserShowInForeground && !browser.webViewSplitActive;
    if (behind == _behindBrowser) return;
    _behindBrowser = behind;
    final wars = context.read<TerritoryWarsController>();
    if (behind) {
      _controller.close(this);
      wars.pause();
      _history.cover(this);
      _orientation.release();
      _video.cancel();
      if (_timelapse.open) setState(_timelapse.stop);
    } else {
      _orientation.resume();
      _controller.open(this, myFactionId: UserHelper.factionId);
      wars.resume();
      _history.uncover(this);
    }
  }

  Future<void> _openMap() async {
    await _controller.open(this, myFactionId: UserHelper.factionId);
    if (!mounted) return;
    if (widget.city != null) _controller.openCity(this);
    _applyAlertTap();
    _applySharedView();
    _alerts.followFaction();
    unawaited(_countOpen());
    final settings = context.read<SettingsProvider>();
    if (!settings.disableTerritoryMap && _controller.flightsButton) unawaited(_flights.loadCount());
    if (widget.city == null && !_behindBrowser && await _alerts.takeHint() && mounted) {
      showTerritoryAlertsHint(() => _showList(_MapList.alerts));
    }
  }

  Future<void> _countOpen() async {
    await _alerts.ready();
    final city = _cityLayer?.options;
    await city?.load();
    await _controller.loadGround();
    if (!mounted) return;
    final origin = widget.calledFromMenu
        ? MapOrigin.menu
        : widget.city != null
        ? MapOrigin.city
        : MapOrigin.wars;
    await context.read<TerritoryMapUsage>().opened((
      origin: origin,
      view: _controller.view,
      names: _controller.factionNames,
      strip: _controller.diaryStrip,
      locks: _controller.showLocks,
      cityFinder: city?.panelVisible,
      citySites: city?.showSites,
      flightsButton: _controller.flightsButton,
      flatFlights: _controller.flatFlights,
      alertsOn: _alerts.enabled,
      alertKinds: {for (final kinds in watchedTargets(_alerts.topics).values) ...kinds},
      life: _controller.cityLife ? _controller.lifeDensity : null,
      planes: _controller.lifePlanes,
      traffic: _controller.lifeTraffic,
      night: _controller.lifeNight,
      gunfire: _controller.lifeGunfire,
      police: _controller.lifePolice,
      threeD: _controller.threeD && widget.city == null ? _controller.cityHeight : null,
      quality: _controller.surroundings == null ? null : _controller.surroundingsQuality,
    ));
  }

  // Wait a frame or focus is lost
  Future<void> _applyAlertTap() async {
    if (widget.city != null || !_controller.ready) return;
    final tap = _alerts.takeTap();
    if (tap == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _list = null);
    _controller.focusTerritory(tap.territory);
    if (tap.warId case final war?) _controller.showWar(war);
  }

  // Link from another player
  Future<void> _applySharedView() async {
    if (widget.city != null || !_controller.ready) return;
    final view = _share.takePending();
    final faction = _share.takePendingFaction();
    if (view == null && faction == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _list = null);
    if (_timelapse.open) _timelapse.stop();
    _controller.showPast(null, null);
    if (view != null) _share.show(view, _controller);
    if (faction != null) {
      _controller.focusFaction(faction);
      _controller.showFaction(faction);
    }
  }

  bool get _canShareVideo =>
      canShareVideo(isAndroid: Platform.isAndroid, isIos: Platform.isIOS, androidSdk: kSdkAndroid);

  Future<void> _shareVideo() async {
    _showList(null);
    final range = await showVideoRangeDialog(context, _history);
    if (range == null || !mounted) return;
    countMapUse(mapShareVideoFeature);
    final barWasOpen = _timelapse.open;
    if (!barWasOpen) setState(_timelapse.start);
    await shareMapVideo(
      context,
      _mapKey,
      _legendKey,
      _readyForPicture,
      _timelapse,
      _video,
      range: range,
      restore: (chosen) async {
        if (!mounted) return;
        if (!barWasOpen) return setState(_timelapse.stop);
        if (_timelapse.open) await _timelapse.showDay(chosen);
      },
    );
  }

  Future<void> _readyForPicture(bool ready) async {
    if (!mounted) return;
    setState(() => _takingPicture = ready);
    await WidgetsBinding.instance.endOfFrame;
    if (!ready) return;
    await _share.photosLoaded().timeout(_photosWait, onTimeout: () {});
    await WidgetsBinding.instance.endOfFrame;
  }

  // One tap, one item
  Future<void> _onCityTap(Object hit) async {
    final pick = widget.pickItem;
    if (hit is! CityItem) return Navigator.pop(context, hit);
    if (pick == null || _picking) return;
    setState(() => _picking = true);
    final answer = await pick(
      hit,
    ).timeout(_pickTimeout, onTimeout: () => const {'status': 'timeout'}).catchError((_) => null);
    final result = readPickResult(answer);
    _picking = false;
    if (!mounted) return;
    setState(() {});
    if (result.picked) countMapUse(mapCityPickFeature);
    if (result.gone) _cityLayer?.removeItem(hit);
    BotToast.showText(text: result.message, contentColor: Colors.grey[700]!, duration: const Duration(seconds: 4));
  }

  void _showList(_MapList? list) {
    if (list == _MapList.diary) countMapUse(mapHistoryFeature);
    if (list == _MapList.layers) unawaited(_flights.loadShare());
    // Button may have just been turned on
    if (list == null && _controller.flightsButton && !context.read<SettingsProvider>().disableTerritoryMap) {
      unawaited(_flights.loadCount());
    }
    _controller.select(null);
    setState(() => _list = list);
  }

  void _stopSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = false;
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final showLocks = context.select<TerritoryMapController, bool>((c) => c.showLocks);
    final view = context.select<TerritoryMapController, MapView>((c) => c.shownView);
    final yearsWanted = context.select<TerritoryMapController, bool>(
      (c) => c.shownView == MapView.activity && c.activitySpan != ActivitySpan.now,
    );
    final past = context.select<TerritoryMapController, bool>((c) => c.pastDay != null);
    // Picking city items needs the flat map
    final threeD = widget.city == null && context.select<TerritoryMapController, bool>((c) => c.threeD);
    final lightTheme = themeProvider.currentTheme == AppTheme.light;
    if (_warLayer?.lightTheme != lightTheme) {
      _warLayer = WarArrowsLayer(_controller, _history, lightTheme: lightTheme);
    }
    if (view == MapView.war && !_frontsAsked) {
      _frontsAsked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _history.load(DateTime.now().toUtc().subtract(frontDays)));
    }
    if (yearsWanted && !_yearsAsked) {
      _yearsAsked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _history.loadYears());
    }
    return Scaffold(
      backgroundColor: themeProvider.canvas,
      appBar: settings.appBarTop ? _appBar(settings) : null,
      bottomNavigationBar: settings.appBarTop
          ? null
          : SizedBox(height: AppBar().preferredSize.height, child: _appBar(settings)),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                key: _mapKey,
                child: threeD
                    ? TerritoryMap3dView(showLife: _showLife)
                    : TerritoryMapView(
                        extraLayers: [
                          if (showLocks && !past) _locksLayer,
                          if (view == MapView.war) _warLayer!,
                          if (view == MapView.activity) _activityLayer,
                          ?_cityLayer,
                        ],
                        onLayerTap: _onCityTap,
                        showLife: _showLife,
                      ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 96,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TerritoryMapDataChip(),
                  if (widget.city == null) const Padding(padding: EdgeInsets.only(top: 4), child: MapDimensionSwitch()),
                  if (threeD) const Padding(padding: EdgeInsets.only(top: 4), child: CityHeightSwitch()),
                  if (yearsWanted) const MapHistoryChip(years: true),
                  if (view == MapView.war) const MapHistoryChip(years: false),
                  if (_picking) const MapLoadChip(loading: true, label: 'Picking up the item'),
                  // Items are of now
                  if (_cityLayer case final layer? when !past)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: CityFinderPanel(layer: layer),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: RepaintBoundary(
                key: _legendKey,
                child: TerritoryMapLegend(forceOpen: _takingPicture),
              ),
            ),
            Consumer<TerritoryMapController>(
              builder: (context, controller, _) {
                final faction = controller.openFaction;
                final code = controller.selected;
                final showFlights = controller.flightsButton && !settings.disableTerritoryMap && !_timelapse.open;
                if (controller.openWar case final war?) return WarSheet(key: ValueKey(war), warId: war);
                if (faction != null) return FactionSheet(factionId: faction);
                if (code != null) return TerritorySheet(code: code);
                return switch (_list) {
                  _MapList.rackets => RacketsSheet(onClose: () => _showList(null)),
                  _MapList.wars => WarsSheet(onClose: () => _showList(null)),
                  _MapList.diary => DiarySheet(onClose: () => _showList(null)),
                  _MapList.layers => MapOptionsSheet(
                    onClose: () => _showList(null),
                    flights: _flights,
                    city: _cityLayer?.options,
                  ),
                  _MapList.alerts => TerritoryAlertsSheet(onClose: () => _showList(null)),
                  _MapList.flights => FlightsSheet(flights: _flights, onClose: () => _showList(null)),
                  null => Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: 8,
                        right: showFlights ? flightsButtonSize + _flightsButtonGap + 8 : 8,
                        bottom: mapBottomMargin(context),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: _timelapse.open
                              ? TimelapseBar(timelapse: _timelapse, onClose: () => setState(_timelapse.stop))
                              : controller.diaryStrip
                              ? DiaryStrip(onOpen: () => _showList(_MapList.diary))
                              : const SizedBox.shrink(),
                        ),
                      ),
                      if (showFlights)
                        Positioned(
                          right: _flightsButtonGap,
                          bottom: mapBottomMargin(context) + 10,
                          child: FlightsButton(
                            flights: _flights,
                            theme: themeProvider,
                            onTap: () => _showList(_MapList.flights),
                          ),
                        ),
                    ],
                  ),
                };
              },
            ),
            if (_searching)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TerritoryMapSearchResults(query: _search.text, onPicked: _stopSearch),
              ),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(SettingsProvider settings) {
    final myFaction = context.select<TerritoryMapController, int>((c) => c.myFactionId);
    final alertsOn = context.select<TerritoryAlertsController, bool>((c) => c.enabled);
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: settings.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: _searching
          ? TerritoryMapSearchField(controller: _search, onChanged: (_) => setState(() {}))
          : const Text('Map', style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: Icon(
          widget.calledFromMenu
              ? Icons.menu
              : widget.city != null
              ? Icons.close
              : Icons.arrow_back,
        ),
        onPressed: () {
          if (!widget.calledFromMenu) {
            Navigator.pop(context);
            return;
          }
          final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
          if (context.read<WebViewProvider>().splitScreenAndBrowserLeft()) {
            scaffoldState?.openEndDrawer();
          } else {
            scaffoldState?.openDrawer();
          }
        },
      ),
      actions: [
        if (_searching)
          IconButton(icon: const Icon(Icons.close), onPressed: _stopSearch)
        else ...[
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Map options',
            onPressed: () => _showList(_MapList.layers),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(MdiIcons.swordCross),
            tooltip: 'Assaults',
            onPressed: () => _showList(_MapList.wars),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => _showList(_MapList.diary),
          ),
          ListenableBuilder(
            listenable: NativeChat.controller,
            builder: (context, _) => MapShareButton(
              onPicture: () {
                countMapUse(mapSharePictureFeature);
                shareMapPicture(context, _mapKey, _legendKey, _readyForPicture);
              },
              onView: () {
                countMapUse(mapShareLinkFeature);
                shareMapView(context);
              },
              onVideo: _canShareVideo ? _shareVideo : null,
              onChat: NativeChat.canShareToFaction
                  ? () {
                      countMapUse(mapShareFactionChatFeature);
                      sendMapViewToFaction(context);
                    }
                  : null,
            ),
          ),
          PopupMenuButton<VoidCallback>(
            style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
            tooltip: 'More',
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              mapMenuItem(Icons.search, 'Search', () => setState(() => _searching = true)),
              mapMenuItem(
                Icons.screen_rotation,
                _orientation.landscape ? 'Default orientation' : 'Landscape',
                _orientation.toggle,
              ),
              mapMenuItem(Icons.attach_money, 'Rackets', () => _showList(_MapList.rackets)),
              if (!_timelapse.open)
                mapMenuItem(Icons.timelapse, 'Map over time', () {
                  countMapUse(mapTimelapseFeature);
                  _showList(null);
                  _timelapse.start();
                }, subtitle: 'Play the map day by day'),
              mapMenuItem(
                alertsOn ? Icons.notifications_active : Icons.notifications_none,
                alertsOn ? 'Territory alerts: on' : 'Territory alerts: off',
                () => _showList(_MapList.alerts),
              ),
              if (myFaction != 0) mapMenuItem(Icons.my_location, 'My faction', () => _focusMyFaction(myFaction)),
            ],
          ),
        ],
      ],
    );
  }

  void _focusMyFaction(int myFaction) {
    if (_controller.focusFaction(myFaction, highlight: false)) return;
    BotToast.showText(
      clickClose: true,
      text: 'Your faction holds no territories',
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: Colors.grey[700]!,
      duration: const Duration(seconds: 3),
      contentPadding: const EdgeInsets.all(10),
    );
  }
}
