import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/basic_profile_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

enum PipMode { chain, player, stakeouts }

class PipPlayer {
  PipPlayer({required this.id, required this.name});

  final int id;
  String name;
  String? state;
  String description = '';
  int until = 0;
  DateTime? changedAt;
  bool error = false;

  bool get highlighted => changedAt != null && DateTime.now().difference(changedAt!) < PipController.highlightDuration;

  bool get confined => const ['Hospital', 'Jail', 'Federal'].contains(state);

  int get remaining => until - DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

class PipController extends GetxController {
  static const _channel = MethodChannel('tornpda.pip');
  static const highlightDuration = Duration(seconds: 30);
  static const bannerDuration = Duration(seconds: 10);
  static const maxPlayers = 4;

  bool supported = false;
  final inPip = false.obs;
  PipMode mode = PipMode.chain;

  List<PipPlayer> players = [];

  int stakeoutPlayers = 0;
  int? stakeoutId;
  String stakeoutName = '';
  List<String> stakeoutLines = [];
  DateTime? stakeoutAt;
  DateTime? stakeoutChangedAt;
  int stakeoutCount = 0;
  DateTime? bannerAt;

  Timer? _playerTimer;
  Timer? _actionsTimer;
  String? _autoEnterKey;
  bool _fetching = false;

  List<PipPlayer> get sortedPlayers {
    int key(PipPlayer p) => p.confined && p.remaining > 0 ? p.remaining : 0;
    final indexed = players.indexed.toList()
      ..sort((a, b) {
        final byTime = key(a.$2).compareTo(key(b.$2));
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });
    return [for (final (_, player) in indexed) player];
  }

  PipPlayer? get profilePlayer {
    if (players.length == 1) return players.first;
    final changed = players.where((p) => p.highlighted).toList();
    if (changed.isEmpty) return null;
    return changed.reduce((a, b) => a.changedAt!.isAfter(b.changedAt!) ? a : b);
  }

  bool get stakeoutHighlighted =>
      stakeoutChangedAt != null && DateTime.now().difference(stakeoutChangedAt!) < highlightDuration;

  bool get bannerVisible => bannerAt != null && DateTime.now().difference(bannerAt!) < bannerDuration;

  @override
  void onInit() {
    super.onInit();
    _channel.setMethodCallHandler(_handleNativeCall);
    Get.find<ChainStatusController>().addListener(syncAutoEnter);
    if (!Platform.isAndroid) return;
    _channel.invokeMethod<bool>('isSupported').then((value) {
      supported = value ?? false;
      update();
      syncAutoEnter();
    });
  }

  @override
  void onClose() {
    _playerTimer?.cancel();
    _actionsTimer?.cancel();
    super.onClose();
  }

  Future<void> openChain() async {
    mode = PipMode.chain;
    _playerTimer?.cancel();
    final chain = Get.find<ChainStatusController>();
    chain.pipVisible = true;
    if (!chain.statusActive) await chain.activateChainWidgetStatusRequests();
    if (!await _enter()) _releaseChain();
  }

  Future<void> watchPlayers(List<PipPlayer> picked) async {
    mode = PipMode.player;
    _releaseChain();
    players = [
      for (final player in picked.take(maxPlayers))
        (inPip.value ? players.firstWhereOrNull((p) => p.id == player.id) : null) ?? player,
    ];
    _playerTimer?.cancel();
    _playerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_fetching) _fetchPlayers();
    });
    await _fetchPlayers();
    if (!await _enter()) _playerTimer?.cancel();
  }

  Future<void> openStakeouts({required int players}) async {
    mode = PipMode.stakeouts;
    stakeoutPlayers = players;
    _playerTimer?.cancel();
    _releaseChain();
    await _enter();
  }

  void stakeoutAlert({required int? id, required String name, required List<String> lines}) {
    final now = DateTime.now();
    stakeoutCount = stakeoutHighlighted ? stakeoutCount + 1 : 1;
    stakeoutId = id;
    stakeoutName = name;
    stakeoutLines = lines;
    stakeoutAt = now;
    stakeoutChangedAt = now;
    if (inPip.value && mode != PipMode.stakeouts) bannerAt = now;
    update();
    if (inPip.value && mode == PipMode.stakeouts) _enter();
    _refreshActionsLater(PipMode.stakeouts);
  }

  void syncAutoEnter() {
    if (!supported || inPip.value) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final armed = settings.pipEnabled && settings.pipAutoEnter && Get.find<ChainStatusController>().watcherActive;
    final actions = armed ? _actionsFor(PipMode.chain) : <Map<String, String>>[];
    final key = actions.map((a) => a['id']).join(',');
    if (key == _autoEnterKey) return;
    _autoEnterKey = key;
    _channel.invokeMethod('autoEnter', {'enabled': armed, 'actions': actions});
  }

  Future<void> expand() async {
    await _channel.invokeMethod('expand');
  }

  Future<void> _fetchPlayers() async {
    _fetching = true;
    var changed = false;
    try {
      await Future.wait([
        for (final player in List.of(players))
          ApiCallsV1.getOtherProfileBasic(playerId: player.id.toString()).then((response) {
            if (!players.contains(player)) return;
            if (response is! BasicProfileModel || response.status == null) {
              player.error = true;
              log("PiP: player ${player.id} fetch failed");
              return;
            }
            player.error = false;
            final newState = response.status!.state;
            if (player.state != null && newState != player.state) {
              player.changedAt = DateTime.now();
              changed = true;
            }
            player.state = newState;
            player.name = response.name ?? player.name;
            player.description = response.status!.description ?? '';
            player.until = response.status!.until ?? 0;
          }),
      ]);
    } finally {
      _fetching = false;
    }
    update();
    if (changed && players.length > 1 && inPip.value && mode == PipMode.player) {
      _enter();
      _refreshActionsLater(PipMode.player);
    }
  }

  void _refreshActionsLater(PipMode pipMode) {
    _actionsTimer?.cancel();
    _actionsTimer = Timer(highlightDuration, () {
      if (inPip.value && mode == pipMode) _enter();
    });
  }

  List<Map<String, String>> _actionsFor(PipMode pipMode) {
    final chain = Get.find<ChainStatusController>();
    return [
      if ((pipMode == PipMode.player && profilePlayer != null) ||
          (pipMode == PipMode.stakeouts && stakeoutHighlighted && stakeoutId != null))
        {'id': 'profile', 'title': 'Profile'},
      if (pipMode == PipMode.chain && chain.panicModeActive && chain.panicTargets.isNotEmpty)
        {'id': 'panic', 'title': 'Panic attack'},
      {'id': 'open', 'title': 'Open PDA'},
    ];
  }

  Future<bool> _enter() async {
    if (!Platform.isAndroid || !supported) return false;
    final actions = _actionsFor(mode);

    // Before the window shrinks
    final wasInPip = inPip.value;
    inPip.value = true;
    update();
    bool entered = false;
    try {
      entered = await _channel.invokeMethod<bool>('enter', {'actions': actions}) ?? false;
    } on PlatformException catch (e) {
      log("PiP: enter failed: ${e.message}");
    }
    if (!entered && !wasInPip) {
      inPip.value = false;
      BotToast.showText(
        text: 'Could not open the floating window, check that picture-in-picture is allowed for Torn PDA',
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.orange[700]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }
    return entered;
  }

  void _releaseChain() {
    final chain = Get.find<ChainStatusController>();
    if (!chain.pipVisible) return;
    chain.pipVisible = false;
    chain.tryToDeactivateStatus();
  }

  void _autoEnterChain() {
    mode = PipMode.chain;
    _playerTimer?.cancel();
    final chain = Get.find<ChainStatusController>();
    chain.pipVisible = true;
    if (!chain.statusActive) chain.activateChainWidgetStatusRequests();
    inPip.value = true;
    update();
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'autoEntering':
        _autoEnterChain();
      case 'changed':
        final bool active = call.arguments as bool;
        if (active && !inPip.value) _autoEnterChain();
        if (!active) {
          // The window grows after this
          final view = WidgetsBinding.instance.platformDispatcher.views.first;
          final pipWidth = view.physicalSize.width;
          for (var i = 0; i < 20 && view.physicalSize.width <= pipWidth; i++) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
        inPip.value = active;
        if (!active) {
          _playerTimer?.cancel();
          _playerTimer = null;
          _actionsTimer?.cancel();
          for (final player in players) {
            player.changedAt = null;
          }
          stakeoutChangedAt = null;
          bannerAt = null;
          _releaseChain();
          _autoEnterKey = null;
          syncAutoEnter();
        }
      case 'action':
        final id = mode == PipMode.stakeouts ? stakeoutId : profilePlayer?.id;
        for (final player in players) {
          player.changedAt = null;
        }
        stakeoutChangedAt = null;
        if (call.arguments == 'panic') {
          await Get.find<ChainStatusController>().launchPanicAttack();
          return;
        }
        if (call.arguments == 'profile' && id != null) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            Provider.of<WebViewProvider>(context, listen: false).openBrowserPreference(
              context: context,
              url: 'https://www.torn.com/profiles.php?XID=$id',
              browserTapType: BrowserTapType.short,
            );
          }
        }
        await expand();
    }
  }
}
