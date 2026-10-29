import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_bubble_glow.dart';
import 'package:torn_pda/widgets/chat/chat_big_window.dart';
import 'package:torn_pda/widgets/chat/chat_icon_menu.dart';
import 'package:torn_pda/widgets/chat/chat_link_window.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/chat_ticker.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/split_divider.dart';

class ChatOverlay extends StatefulWidget {
  const ChatOverlay({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _Floating {
  _Floating(this.frame, this.preset, TickerProvider vsync, {this.min = ChatWindowFrame.minSize, this.bigWindow = false})
    : settle = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 200));

  Rect frame;
  ChatWindowSize? preset;
  final Size min;
  final bool bigWindow;
  bool free = false;
  RectTween? tween;
  final AnimationController settle;
  final FocusScopeNode scope = FocusScopeNode();

  void dispose() {
    settle.dispose();
    scope.dispose();
  }
}

class _LayerRoute extends OverlayRoute<void> {
  _LayerRoute(this.create) : super(requestFocus: false);

  final OverlayEntry Function() create;

  @override
  Iterable<OverlayEntry> createOverlayEntries() => [create()];
}

class _SheetWatch extends NavigatorObserver {
  _SheetWatch(this.changed);

  final VoidCallback changed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) FocusManager.instance.primaryFocus?.unfocus();
    changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => changed();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => changed();
}

class _SheetBack extends PopEntry<Object?> {
  _SheetBack(this.sheets);

  final GlobalKey<NavigatorState> sheets;

  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier(false);

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop) sheets.currentState?.maybePop();
  }
}

class _ChatOverlayState extends State<ChatOverlay> with TickerProviderStateMixin {
  static const Offset _cascade = Offset(24, 32);
  static const double _head = 48;
  static const double _mini = 40;
  static const double _miniTap = 48;
  static const double _miniStep = 48;
  static const int _maxMinis = 3;

  Offset? _dragged;
  final Map<String, _Floating> _windows = {};
  _Floating? _bigWin;
  SplitSide? _bigWindowSide;
  ModalRoute<dynamic>? _backRoute;
  Rect _area = Rect.zero;
  Rect _areaNoKeyboard = Rect.zero;
  bool _menu = false;
  bool _menuRest = false;
  String? _pressed;
  bool _syncing = false;
  bool _noticeShown = false;
  double _textGrow = 1;

  OverlayEntry? _layer;
  final GlobalKey<NavigatorState> _sheets = GlobalKey();
  late final _SheetBack _back = _SheetBack(_sheets);
  late final List<NavigatorObserver> _observers = [_SheetWatch(_watchSheets)];
  ModalRoute<dynamic>? _popRoute;

  @override
  void initState() {
    super.initState();
    NativeChat.navigatorKey = widget.navigatorKey;
    NativeChat.sheetsKey = _sheets;
    chatToastHosted = true;
    NativeChat.rootTop.addListener(_trackWindowBack);
    NativeChat.quickWindows.addListener(_scheduleSync);
    NativeChat.minimized.addListener(_scheduleSync);
    NativeChat.bigWindow.addListener(_scheduleSync);
    NativeChat.tornTabMissing.addListener(_closeSheets);
  }

  @override
  void dispose() {
    if (NativeChat.sheetsKey == _sheets) NativeChat.sheetsKey = null;
    chatToastHosted = false;
    dropChatToast();
    NativeChat.rootTop.removeListener(_trackWindowBack);
    // ignore: deprecated_member_use
    if (_backRoute?.subtreeContext != null) _backRoute!.removeScopedWillPopCallback(_windowBack);
    NativeChat.quickWindows.removeListener(_scheduleSync);
    NativeChat.minimized.removeListener(_scheduleSync);
    NativeChat.bigWindow.removeListener(_scheduleSync);
    NativeChat.tornTabMissing.removeListener(_closeSheets);
    _bigWin?.dispose();
    for (final w in _windows.values) {
      w.dispose();
    }
    if (_popRoute?.isActive ?? false) _popRoute!.unregisterPopEntry(_back);
    _back.canPopNotifier.dispose();
    super.dispose();
  }

  void _closeSheets() {
    if (NativeChat.tornTabMissing.value) _sheets.currentState?.popUntil((route) => route.isFirst);
  }

  void _openChat() {
    final navigator = widget.navigatorKey.currentState;
    StatsController.chat.count('open_bubble');
    if (navigator != null) NativeChat.launch(navigator);
  }

  @override
  void didUpdateWidget(ChatOverlay old) {
    super.didUpdateWidget(old);
    _layer?.markNeedsBuild();
  }

  static bool get _windowsShown => NativeChat.bigWindowShown || NativeChat.quickWindows.value.isNotEmpty;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  // Beats PopScope to the back press
  void _trackWindowBack() {
    final top = NativeChat.rootTop.value;
    final route = _windowsShown && top is ModalRoute ? top : null;
    if (route == _backRoute) return;
    // ignore: deprecated_member_use
    if (_backRoute?.subtreeContext != null) _backRoute!.removeScopedWillPopCallback(_windowBack);
    _backRoute = null;
    if (route == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final visible = mounted && _windowsShown && NativeChat.rootTop.value == route;
      if (!visible || _backRoute == route || route.subtreeContext == null) return;
      // ignore: deprecated_member_use
      _backRoute = route..addScopedWillPopCallback(_windowBack);
    });
  }

  // The front window goes first
  Future<bool> _windowBack() async {
    final yielding =
        !_windowsShown ||
        NativeChat.tornTabMissing.value ||
        NativeChat.popupOnTop ||
        NativeChat.drawerOpen.value ||
        NativeChat.linkWindow.value != null ||
        (_sheets.currentState?.canPop() ?? false);
    if (yielding) return true;
    if (NativeChat.stackOrder.lastOrNull == NativeChat.bigWindowId) {
      NativeChat.bigWindowBack();
    } else if (NativeChat.prefs.canMinimize) {
      NativeChat.minimizeQuickWindow();
    } else {
      NativeChat.closeQuickWindow(NativeChat.quickWindows.value.last);
    }
    return false;
  }

  // Back closes the sheet first
  void _watchSheets() => scheduleMicrotask(() {
    if (!mounted) return;
    final open = _sheets.currentState?.canPop() ?? false;
    final route = _popRoute;
    final top = NativeChat.rootTop.value;
    if (open && route == null && top is ModalRoute && top.isActive) {
      _popRoute = top..registerPopEntry(_back);
    } else if (!open && route != null) {
      if (route.isActive) route.unregisterPopEntry(_back);
      _popRoute = null;
    }
  });

  @override
  Widget build(BuildContext context) {
    final appTime = context.select<SettingsProvider?, (bool, bool)?>(
      (s) => s == null
          ? null
          : (s.currentTimeZone == TimeZoneSetting.tornTime, s.currentTimeFormat == TimeFormatSetting.h12),
    );
    if (appTime case (final tornTime, final h12)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => NativeChat.prefs.followAppTime(tornTime: tornTime, h12: h12));
    }
    final overlay = HeroControllerScope.none(
      child: ChatTheme(
        touch: false,
        child: Navigator(
          key: _sheets,
          clipBehavior: Clip.none,
          requestFocus: false,
          observers: _observers,
          onGenerateInitialRoutes: (_, _) => [_LayerRoute(() => _layer = OverlayEntry(builder: _buildLayer))],
        ),
      ),
    );
    final pip = Get.isRegistered<PipController>() ? Get.find<PipController>() : null;
    return Positioned.fill(
      child: pip == null ? overlay : Obx(() => Offstage(offstage: pip.inPip.value, child: overlay)),
    );
  }

  Widget _buildLayer(BuildContext context) {
    return Stack(
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([
            NativeChat.prefs,
            NativeChat.screenOpen,
            NativeChat.quickWindows,
            NativeChat.bigWindow,
            NativeChat.rootTop,
            NativeChat.homeTop,
            NativeChat.keyValid,
            NativeChat.drawerOpen,
            NativeChat.tornTabMissing,
            NativeChat.tickerDemo,
            splitDividerRect,
          ]),
          builder: (context, _) {
            final covered = NativeChat.popupOnTop || NativeChat.drawerOpen.value;
            final shown = NativeChat.tickerOn || NativeChat.tickerDemo.busy;
            return shown && !covered ? _ticker(context) : const SizedBox.shrink();
          },
        ),
        ListenableBuilder(
          listenable: Listenable.merge([
            NativeChat.controller,
            NativeChat.prefs,
            NativeChat.screenOpen,
            NativeChat.quickWindows,
            NativeChat.bigWindow,
            NativeChat.minimized,
            NativeChat.rootTop,
            NativeChat.homeTop,
            NativeChat.keyValid,
            NativeChat.dialOpen,
            NativeChat.drawerOpen,
            NativeChat.tornTabMissing,
            splitDividerRect,
          ]),
          builder: (context, _) {
            final media = MediaQuery.of(context);
            final safe = _safeOf(media);
            _textGrow = (media.textScaler.scale(14) / 14).clamp(1.0, 2.0);
            final areaBottom = media.size.height - math.max(safe.bottom, media.viewInsets.bottom + 12);
            _area = Rect.fromLTRB(safe.left, safe.top, media.size.width - safe.right, math.max(safe.top, areaBottom));
            _areaNoKeyboard = Rect.fromLTRB(_area.left, _area.top, _area.right, media.size.height - safe.bottom);
            final covered = NativeChat.popupOnTop || NativeChat.dialOpen.value;
            final bigWindow = NativeChat.bigWindow.value;
            final active = !NativeChat.screenOpen.value && NativeChat.usable && !covered;
            final showBubble = active && !_small;
            final paused = NativeChat.tornTabMissing.value;
            final minis = active ? _minis : const <ChatMinimized>[];
            final lead = _lead(active);
            final pressed = minis.take(_maxMinis).toList().indexWhere((m) => m.roomId == _pressed);
            final notice = paused && _windowsShown;
            if (notice && !_noticeShown) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _announce('Chat paused. Back on a Torn tab to keep chatting'),
              );
            }
            _noticeShown = notice;
            return Stack(
              children: [
                if (lead == 1) _miniBubble(context, 0, null, bigWindow: true),
                for (final (i, m) in minis.take(_maxMinis).indexed) _miniBubble(context, i + lead, m),
                if (minis.length > _maxMinis)
                  _miniBubble(context, _maxMinis + lead, null, more: minis.length - _maxMinis),
                if (showBubble) _bubble(context),
                // Windows hide what lies below
                if (!paused && !NativeChat.popupOnTop && !NativeChat.drawerOpen.value && _windowsShown)
                  const Positioned(left: 0, top: 0, child: BlockSemantics()),
                if (notice)
                  _pausedNotice(context, media)
                else if (!paused)
                  for (final id in NativeChat.stackOrder)
                    id == NativeChat.bigWindowId ? _bigWindowView(bigWindow!) : _window(id),
                ValueListenableBuilder(
                  valueListenable: NativeChat.linkWindow,
                  builder: (context, link, _) => link == null
                      ? const Positioned(left: 0, top: 0, child: SizedBox.shrink())
                      : ChatLinkWindow(url: link.url, tap: link.tap, area: _area),
                ),
                if (active && _menu && (!_menuRest || _menuItems.isNotEmpty)) _bubbleMenu(context),
                if (pressed >= 0) _dismiss(context, minis[pressed].roomId, pressed + lead),
                if (lead == 1 && _pressed == NativeChat.bigWindowId) _dismiss(context, NativeChat.bigWindowId, 0),
              ],
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: chatHeldToast,
          builder: (context, toast, _) => toast == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: const Alignment(0, 0.8),
                  child: ChatToastBox(
                    text: toast.text,
                    action: toast.action,
                    onAction: toast.onAction,
                    close: dropChatToast,
                    held: true,
                  ),
                ),
        ),
      ],
    );
  }

  void _announce(String text) {
    if (mounted) SemanticsService.sendAnnouncement(View.of(context), text, Directionality.of(context));
  }

  Widget _pausedNotice(BuildContext context, MediaQueryData media) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme;
    return Positioned(
      left: _area.left + 8,
      right: media.size.width - _area.right + 80,
      bottom: media.size.height - _area.bottom + 8,
      child: Semantics(
        container: true,
        child: Material(
          elevation: 6,
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Chat paused', style: style.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        'Back on a Torn tab to keep chatting',
                        style: style.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: NativeChat.tornTabExists,
                  builder: (context, exists, _) => FilledButton.tonal(
                    onPressed: () => NativeChat.openTornBrowser(keepChat: true),
                    child: Text(exists ? 'Go to Torn' : 'Open Torn'),
                  ),
                ),
                Semantics(
                  container: true,
                  child: IconButton(
                    tooltip: 'Close chat windows',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      NativeChat.closeQuickWindow();
                      if (NativeChat.bigWindowShown) NativeChat.closeBigWindow();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticker(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = NativeChat.prefs.tickerTop;
    if (!top && media.viewInsets.bottom > 0) return const SizedBox.shrink();
    final divider = splitDividerRect.value;
    return Positioned(
      left: media.padding.left + 12,
      right: math.max(media.padding.right + 84, divider == null ? 0 : media.size.width - divider.left + 8),
      top: top ? media.padding.top + kToolbarHeight + 8 : null,
      bottom: top ? null : media.padding.bottom + 96,
      child: Align(
        alignment: top ? Alignment.topLeft : Alignment.bottomLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(360, media.size.width * 0.72)),
          child: ChatTicker(
            chat: NativeChat.controller,
            prefs: NativeChat.prefs,
            onOpen: NativeChat.openQuickWindow,
            onReply: (roomId) => NativeChat.openQuickWindow(roomId, reply: true),
            live: NativeChat.tickerOn,
            demo: NativeChat.tickerDemo,
          ),
        ),
      ),
    );
  }

  // Clear of system bars and notification pull
  EdgeInsets _safeOf(MediaQueryData media) {
    final pad = media.viewPadding;
    final gestures = media.systemGestureInsets;
    return EdgeInsets.fromLTRB(
      pad.left + 8,
      math.max(pad.top, gestures.top) + 16,
      pad.right + 8,
      math.max(pad.bottom, gestures.bottom) + 12,
    );
  }

  Rect _bubbleRange(MediaQueryData media) {
    final safe = _safeOf(media);
    final right = media.size.width - safe.right - _head - ChatUnreadArc.reach;
    final bottom = media.size.height - safe.bottom - _head;
    return Rect.fromLTRB(safe.left, safe.top, math.max(safe.left, right), math.max(safe.top, bottom));
  }

  (double, double) _edges(MediaQueryData media) {
    return (media.viewPadding.left, media.size.width - media.viewPadding.right);
  }

  (Offset, int) get _spot {
    final v = NativeChat.prefs.bubbleSpot.map(double.tryParse).toList();
    if (v.length != 3 || v.contains(null)) return (const Offset(1, 0.7), 0);
    return (Offset(v[0]!.clamp(0.0, 1.0), v[1]!.clamp(0.0, 1.0)), v[2]!.sign.toInt());
  }

  void _setSpot(Offset spot, int dock) {
    NativeChat.prefs.setBubbleSpot([spot.dx.toStringAsFixed(3), spot.dy.toStringAsFixed(3), '$dock']);
    if (dock != 0) _menu = false;
    _pressed = null;
    _layer?.markNeedsBuild();
  }

  Offset _bubbleAt(MediaQueryData media) {
    if (_dragged case final at?) return at;
    final (spot, dock) = _spot;
    final range = _bubbleRange(media);
    final (left, right) = _edges(media);
    final y = range.top + range.height * spot.dy;
    if (dock != 0 && !_small) return Offset((dock < 0 ? left : right) - _head / 2, y);
    var at = Offset(range.left + range.width * spot.dx, y);
    final divider = splitDividerRect.value;
    if (divider != null && at.dx + _head + ChatUnreadArc.reach > divider.left && at.dx < divider.right) {
      // Off the divider, to its nearer side
      final toLeft = at.dx + _head / 2 < divider.center.dx;
      at = Offset(toLeft ? divider.left - _head - ChatUnreadArc.reach - 4 : divider.right + 4, y);
    }
    const width = _head + ChatUnreadArc.reach;
    final bigWindow = NativeChat.bigWindow.value;
    final shownBigWindow = bigWindow != null && !bigWindow.minimized && !bigWindow.full ? _bigWin?.frame : null;
    for (final frame in [..._open.map((w) => w.frame), ?shownBigWindow]) {
      if (!(at & const Size(width, _head)).overlaps(frame)) continue;
      // Beside the window, else above it
      final left = frame.left - width - 4;
      final right = frame.right + 4;
      if (left >= range.left && (at.dx + width / 2 < frame.center.dx || right > range.right)) {
        at = Offset(left, at.dy);
      } else if (right <= range.right) {
        at = Offset(right, at.dy);
      } else {
        at = Offset(at.dx, math.max(range.top, frame.top - _head - 8));
      }
    }
    return at;
  }

  Map<CustomSemanticsAction, VoidCallback> _bubbleMoves(MediaQueryData media) {
    final range = _bubbleRange(media);
    final spot = _spot.$1;
    final at = Rect.fromLTWH(range.left + range.width * spot.dx, range.top + range.height * spot.dy, 0, 0);
    double share(double v, double from, double span) => span > 0 ? ((v - from) / span).clamp(0.0, 1.0) : 0;
    return {
      for (final MapEntry(key: label, value: direction) in ChatWindowFrame.moves(at, range).entries)
        CustomSemanticsAction(label: label): () {
          final to = ChatWindowFrame.nudge(at, range, direction);
          _setSpot(Offset(share(to.left, range.left, range.width), share(to.top, range.top, range.height)), 0);
        },
    };
  }

  void _bubbleDrag(MediaQueryData media, Offset delta) {
    final at = _bubbleAt(media) + delta;
    final range = _bubbleRange(media);
    final (left, right) = _small ? (range.left, range.right) : _edges(media);
    final x = _small ? at.dx.clamp(left, right) : at.dx.clamp(left - _head / 2, right - _head / 2);
    _dragged = Offset(x, at.dy.clamp(range.top, range.bottom));
    _layer?.markNeedsBuild();
  }

  void _bubbleDragEnd(MediaQueryData media) {
    final at = _dragged;
    if (at == null) return;
    _dragged = null;
    final range = _bubbleRange(media);
    final (left, right) = _edges(media);
    final center = at.dx + _head / 2;
    final dock = center < left + 20 ? -1 : (center > right - 20 ? 1 : 0);
    double share(double v, double from, double span) => span > 0 ? ((v - from) / span).clamp(0.0, 1.0) : 0;
    _setSpot(
      Offset(dock != 0 ? (dock + 1) / 2 : share(at.dx, range.left, range.width), share(at.dy, range.top, range.height)),
      dock,
    );
  }

  // After both lists settle
  void _scheduleSync() {
    if (_syncing) return;
    _syncing = true;
    scheduleMicrotask(() {
      _syncing = false;
      if (mounted) _sync();
    });
  }

  void _sync() {
    if (NativeChat.quickWindows.value.isEmpty && !NativeChat.bigWindowShown) {
      _sheets.currentState?.popUntil((route) => route.isFirst);
    }
    final kept = {...NativeChat.quickWindows.value, for (final m in NativeChat.minimized.value) m.roomId};
    _windows.removeWhere((roomId, w) {
      if (kept.contains(roomId)) return false;
      w.dispose();
      return true;
    });
    if (_menuRest && _menuItems.isEmpty) _menu = false;
    final stale = _pressed == NativeChat.bigWindowId
        ? NativeChat.bigWindow.value?.minimized != true
        : !NativeChat.minimized.value.any((m) => m.roomId == _pressed);
    if (stale) _pressed = null;
    _persist();
    final side = NativeChat.bigWindow.value?.side;
    if (_bigWin case final w? when side != null && side != _bigWindowSide) {
      final divider = splitDividerRect.value;
      w.frame = ChatWindowFrame.fit(w.frame, ChatWindowFrame.panel(_areaNoKeyboard, divider, side), min: _minOf(w));
      _layer?.markNeedsBuild();
    }
    _bigWindowSide = side;
    if (NativeChat.bigWindow.value == null) {
      _bigWin?.dispose();
      _bigWin = null;
    }
    _trackWindowBack();
  }

  void _persist() {
    final saved = {for (final entry in NativeChat.prefs.windows) ChatWindowFrame.decode(entry).roomId: entry};
    final rooms = {
      for (final m in NativeChat.minimized.value)
        if (m.window) m.roomId,
      ...NativeChat.quickWindows.value,
      ...NativeChat.reopening,
    };
    NativeChat.prefs.setWindows([
      for (final roomId in rooms)
        if (_windows[roomId] case final w?)
          ChatWindowFrame.encode(roomId, w.frame, w.preset)
        else
          saved[roomId] ?? roomId,
    ]);
    final frame = _bigWin?.frame ?? ChatBigWindow.decode(NativeChat.prefs.bigWindow).frame;
    NativeChat.prefs.setBigWindow(ChatBigWindow.encode(NativeChat.bigWindow.value, frame));
  }

  Iterable<_Floating> get _open => NativeChat.quickWindows.value.map((r) => _windows[r]).nonNulls;

  (Rect, ChatWindowSize?) _template() {
    final front = _open.lastOrNull;
    if (front != null) return (front.frame.shift(_cascade), front.preset);
    final saved = NativeChat.prefs.windowFrame;
    final values = saved.take(4).map(double.tryParse).toList();
    if (saved.length == 5 && !values.contains(null)) {
      return (
        Rect.fromLTWH(values[0]!, values[1]!, values[2]!, values[3]!),
        ChatWindowSize.values.asNameMap()[saved[4]],
      );
    }
    return (_centered(ChatWindowSize.m.size), ChatWindowSize.m);
  }

  Rect _centered(Size size, [SplitSide? panel]) {
    final divider = splitDividerRect.value;
    final side = divider == null ? null : panel ?? NativeChat.focusedSplitSide;
    final center = ChatWindowFrame.panel(_area, divider, side).center.dx;
    return Rect.fromLTWH(center - size.width / 2, _area.top + 40, size.width, size.height);
  }

  _Floating _create(String roomId) {
    final saved = NativeChat.prefs.windows.map(ChatWindowFrame.decode).where((e) => e.roomId == roomId).firstOrNull;
    final (frame, preset) = saved?.frame != null ? (saved!.frame!, saved.preset) : _template();
    var rect = ChatWindowFrame.fit(frame, _area);
    for (var i = 0; i < 4 && _open.any((w) => (w.frame.topLeft - rect.topLeft).distance < 12); i++) {
      rect = rect.shift(_cascade);
      if (rect.bottom > _area.bottom || rect.right > _area.right) {
        rect = Rect.fromLTWH(_area.left + 8.0 * i, _area.top + 8.0 * i, rect.width, rect.height);
      }
    }
    return _float(rect, preset);
  }

  // Big text needs a bigger big window
  Size _minOf(_Floating w) => w.bigWindow ? w.min * _textGrow : w.min;

  _Floating _createBigWindow() {
    final saved = ChatBigWindow.decode(NativeChat.prefs.bigWindow).frame;
    final min = ChatWindowFrame.bigWindowMinSize * _textGrow;
    final divider = splitDividerRect.value;
    final side = divider == null ? null : NativeChat.bigWindow.value?.side ?? NativeChat.focusedSplitSide;
    final panel = ChatWindowFrame.panel(_areaNoKeyboard, divider, side);
    final frame = ChatWindowFrame.fit(saved ?? _centered(const Size(360, 520), side), panel, min: min);
    return _float(frame, null, bigWindow: true);
  }

  _Floating _float(Rect rect, ChatWindowSize? preset, {bool bigWindow = false}) {
    final w = _Floating(
      rect,
      preset,
      this,
      min: bigWindow ? ChatWindowFrame.bigWindowMinSize : ChatWindowFrame.minSize,
      bigWindow: bigWindow,
    );
    w.settle.addListener(() {
      w.frame = w.tween?.transform(Curves.easeOutCubic.transform(w.settle.value)) ?? w.frame;
      _layer?.markNeedsBuild();
    });
    return w;
  }

  void _save(_Floating w) {
    final frame = w.frame;
    if (!w.bigWindow) {
      NativeChat.prefs.setWindowFrame([
        for (final v in [frame.left, frame.top, frame.width, frame.height]) v.toStringAsFixed(1),
        w.preset?.name ?? '',
      ]);
    }
    _persist();
  }

  void _animateTo(_Floating w, Rect target, VoidCallback then) {
    if (_still) {
      w.frame = target;
      _layer?.markNeedsBuild();
      return then();
    }
    w.tween = RectTween(begin: w.frame, end: target);
    w.settle.forward(from: 0).then((_) => then());
  }

  void _next(String roomId) {
    final next = NativeChat.controller.unreadQueue.firstOrNull;
    final w = _windows[roomId];
    if (next == null || w == null) return;
    _windows[next.id] = _windows.remove(roomId)!;
    NativeChat.swapQuickWindow(roomId, next.id);
  }

  void _focus(String id) {
    final others = [
      ..._windows.entries.where((e) => e.key != id).map((e) => e.value),
      if (id != NativeChat.bigWindowId) ?_bigWin,
    ];
    if (others.any((w) => w.scope.hasFocus)) FocusManager.instance.primaryFocus?.unfocus();
    id == NativeChat.bigWindowId ? NativeChat.focusBigWindow() : NativeChat.focusQuickWindow(id);
    final roomId = id == NativeChat.bigWindowId ? NativeChat.bigWindow.value?.roomId : id;
    final chat = NativeChat.controller;
    // Another window may have taken the open
    if (roomId != null && !chat.isLoaded(roomId) && !chat.openFailed(roomId) && !chat.opening(roomId)) {
      chat.openConversation(roomId);
    }
  }

  void _drag(_Floating w, Offset delta) {
    w.settle.stop();
    final room = w.bigWindow ? _areaNoKeyboard : _area;
    final base = w.free ? w.frame : ChatWindowFrame.fit(w.frame, room, min: _minOf(w));
    w.free = true;
    w.frame = ChatWindowFrame.loose(base.shift(delta), room, min: _minOf(w));
    _layer?.markNeedsBuild();
  }

  void _dragEnd(_Floating w, Velocity velocity, VoidCallback? minimize) {
    final frame = w.frame;
    final room = w.bigWindow ? _areaNoKeyboard : _area;
    final speed = velocity.pixelsPerSecond;
    final fling = speed.dx.abs() > 1200 && speed.dx.abs() > 2 * speed.dy.abs();
    if (minimize == null || (!fling && ChatWindowFrame.outside(frame, _area) < 0.35)) {
      return _animateTo(w, ChatWindowFrame.fit(frame, room, min: _minOf(w)), () {
        w.free = false;
        _save(w);
      });
    }
    final right = fling ? speed.dx > 0 : frame.center.dx > _area.center.dx;
    final left = right ? _area.right + 24 : _area.left - frame.width - 24;
    _animateTo(w, Rect.fromLTWH(left, frame.top, frame.width, frame.height), () {
      w.free = false;
      w.frame = ChatWindowFrame.fit(frame, room, min: _minOf(w));
      _save(w);
      minimize();
    });
  }

  void _resize(_Floating w, Offset delta) {
    final room = w.bigWindow ? _areaNoKeyboard : _area;
    final frame = ChatWindowFrame.fit(w.frame, room, min: _minOf(w));
    final min = _minOf(w);
    w.frame = Rect.fromLTWH(
      frame.left,
      frame.top,
      (frame.width + delta.dx).clamp(math.min(min.width, room.width), room.right - frame.left).toDouble(),
      (frame.height + delta.dy).clamp(math.min(min.height, room.height), room.bottom - frame.top).toDouble(),
    );
    w.preset = null;
    _layer?.markNeedsBuild();
  }

  void _cycleSize(_Floating w) {
    final preset = w.preset?.next ?? ChatWindowSize.s;
    final frame = ChatWindowFrame.fit(w.frame, _area);
    final size = preset.size;
    w.preset = preset;
    w.frame = Rect.fromLTWH(frame.center.dx - size.width / 2, frame.top, size.width, size.height);
    _save(w);
    _layer?.markNeedsBuild();
  }

  Map<CustomSemanticsAction, VoidCallback> _moves(_Floating w, Rect frame, Rect room) => {
    for (final MapEntry(key: label, value: direction) in ChatWindowFrame.moves(frame, room).entries)
      CustomSemanticsAction(label: label): () {
        w
          ..settle.stop()
          ..free = false
          ..frame = ChatWindowFrame.nudge(frame, room, direction);
        _save(w);
        _layer?.markNeedsBuild();
      },
  };

  Widget _window(String roomId) {
    final w = _windows[roomId] ??= _create(roomId);
    final minimize = NativeChat.prefs.canMinimize ? () => NativeChat.minimizeQuickWindow(roomId) : null;
    final shown = w.free ? ChatWindowFrame.loose(w.frame, _area) : ChatWindowFrame.fit(w.frame, _area);
    return Positioned.fromRect(
      key: ValueKey(roomId),
      rect: shown,
      child: ChatTaps(
        onDown: () => _focus(roomId),
        child: FocusScope(
          node: w.scope,
          child: Opacity(
            opacity: (1 - ChatWindowFrame.outside(shown, _area)).clamp(0.25, 1.0),
            child: ChatQuickWindow(
              chat: NativeChat.controller,
              roomId: roomId,
              onClose: () => NativeChat.closeQuickWindow(roomId),
              onExpand: () => NativeChat.expandQuickWindow(roomId),
              onNext: () => _next(roomId),
              onMinimize: minimize,
              onDrag: (delta) => _drag(w, delta),
              onDragEnd: (velocity) => _dragEnd(w, velocity, minimize),
              onResize: (delta) => _resize(w, delta),
              onResizeEnd: () => _save(w),
              sizeLabel: w.preset?.label,
              onCycleSize: () => _cycleSize(w),
              moves: _moves(w, shown, _area),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigWindowView(ChatBigWindow bigWindow) {
    final w = _bigWin ??= _createBigWindow();
    final full = bigWindow.full;
    final minimize = NativeChat.prefs.canMinimize ? NativeChat.minimizeBigWindow : null;
    final placed = w.free
        ? ChatWindowFrame.loose(w.frame, _areaNoKeyboard, min: _minOf(w))
        : ChatWindowFrame.fit(w.frame, _areaNoKeyboard, min: _minOf(w));
    final shown = full ? _area : ChatWindowFrame.aboveKeyboard(placed, _area);
    return Positioned.fromRect(
      key: const ValueKey(NativeChat.bigWindowId),
      rect: shown,
      child: ChatTaps(
        onDown: () => _focus(NativeChat.bigWindowId),
        child: FocusScope(
          node: w.scope,
          child: Opacity(
            opacity: (1 - ChatWindowFrame.outside(shown, _area)).clamp(0.25, 1.0),
            child: ChatBigWindowView(
              chat: NativeChat.controller,
              roomId: bigWindow.roomId,
              fullscreen: full,
              onClose: NativeChat.closeBigWindow,
              onMinimize: minimize,
              onFullscreen: NativeChat.toggleBigWindowFull,
              onDrag: full ? null : (delta) => _drag(w, delta),
              onDragEnd: full ? null : (velocity) => _dragEnd(w, velocity, minimize),
              onResize: full ? null : (delta) => _resize(w, delta),
              onResizeEnd: full ? null : () => _save(w),
              moves: full ? null : _moves(w, placed, _areaNoKeyboard),
            ),
          ),
        ),
      ),
    );
  }

  // Sent to Torn once Undo expires
  void _markAllRead(BuildContext context) {
    final count = NativeChat.controller.readable.length;
    HapticFeedback.lightImpact();
    if (count == 0) {
      return chatToast(
        'Nothing to mark as read. Rooms like Global and Trade, hidden rooms and archived chats stay as they are',
      );
    }
    var undone = false;
    chatToast(
      '$count ${count == 1 ? 'chat' : 'chats'} marked as read',
      seconds: 4,
      action: 'Undo',
      onAction: () => undone = true,
      onClose: () {
        if (!undone) Future.microtask(NativeChat.controller.markAllRead);
      },
    );
  }

  void _setMenu(bool value, {bool rest = false}) {
    _menu = value;
    _menuRest = rest;
    _pressed = null;
    _layer?.markNeedsBuild();
  }

  /// Own bubbles, not the big one
  bool get _small => NativeChat.prefs.launcher != ChatLauncher.bubble;

  /// Newest first, pages only when small
  List<ChatMinimized> get _minis => NativeChat.minimized.value.reversed.where((m) => m.window || _small).toList();

  int get _slots => _lead(true) + math.min(_minis.length, _maxMinis + 1);

  // The big window's own bubble sits first
  int _lead(bool shown) => shown && _small && (NativeChat.bigWindow.value?.minimized ?? false) ? 1 : 0;

  List<ChatMinimized> get _menuItems =>
      _menuRest ? _minis.skip(_maxMinis).toList() : NativeChat.minimized.value.reversed.toList();

  // Docked, they tuck in behind the bubble
  Offset _miniAt(MediaQueryData media, int slot) {
    final at = _bubbleAt(media);
    const inset = (_head - _mini) / 2;
    if (_small) {
      // The whole stack stays on screen
      final range = _bubbleRange(media);
      final span = (_slots - 1) * _miniStep;
      final top = math.min(at.dy, math.max(range.top, range.bottom - span));
      return Offset(at.dx + inset, top + inset + slot * _miniStep);
    }
    if (_dragged == null && _spot.$2 != 0) return at + const Offset(inset, inset);
    final below = at.dy + _head / 2 < media.size.height / 2;
    final y = below ? at.dy + _head + 20 + slot * _miniStep : at.dy - 20 - _mini - slot * _miniStep;
    return Offset(at.dx + inset, y);
  }

  Widget _bubble(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = NativeChat.prefs;
    final chat = NativeChat.controller;
    final groups = prefs.bubbleCounts(chat.unreadGroups());
    final total = groups.values.fold(0, (a, b) => a + b);
    final minimized = NativeChat.minimized.value;
    final pages = minimized.where((m) => !m.window).toList();
    final media = MediaQuery.of(context);
    final at = _bubbleAt(media);
    final dock = _dragged == null ? _spot.$2 : 0;
    final failed = chat.connection == ChatConnection.error;
    final holdsBigWindow = !_small && (NativeChat.bigWindow.value?.minimized ?? false);
    final VoidCallback open = holdsBigWindow
        ? NativeChat.restoreBigWindow
        : (pages.isEmpty ? _openChat : () => NativeChat.restore(pages.last));
    final VoidCallback tap = dock != 0
        ? () => _setSpot(_spot.$1, 0)
        : (failed
              ? () {
                  chat.retry();
                  open();
                }
              : open);
    const names = {
      'faction': 'faction',
      'company': 'company',
      'dm': 'private',
      'global': 'Global',
      'trade': 'Trade',
      'poker': 'Poker',
    };
    final spoken = [
      'Chat',
      total == 0 ? 'no unread messages' : (total == 1 ? '1 unread message' : '$total unread messages'),
      for (final e in groups.entries)
        if (e.value > 0 && !prefs.bubbleTotal) '${names[e.key] ?? ChatRooms.labelOf(e.key)} ${e.value}',
      if (holdsBigWindow) 'chat window minimized',
      if (pages.isNotEmpty) '${chat.roomById(pages.last.roomId).name} minimized',
      if (dock != 0) 'tucked at the edge',
      if (chat.stalled) 'no connection' else if (chat.loadingCounts) 'starting',
    ].join(', ');
    return AnimatedPositioned(
      duration: _dragged == null && !_still ? const Duration(milliseconds: 220) : Duration.zero,
      curve: Curves.easeOutCubic,
      left: at.dx,
      top: at.dy - ChatUnreadArc.padTop,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        button: true,
        label: spoken,
        onTap: tap,
        onTapHint: dock != 0
            ? 'bring it back'
            : (failed
                  ? 'try again'
                  : (holdsBigWindow
                        ? 'open the chat window'
                        : (pages.isEmpty ? 'open chat' : 'reopen the minimized chat'))),
        customSemanticsActions: {
          if (dock == 0) const CustomSemanticsAction(label: 'Mark all as read'): () => _markAllRead(context),
          if (dock == 0 && pages.isNotEmpty) const CustomSemanticsAction(label: 'Open chat'): _openChat,
          if (dock == 0)
            CustomSemanticsAction(label: _menu ? 'Hide the chat menu' : 'Show the chat menu'): () => _setMenu(!_menu),
          if (dock == 0) ..._bubbleMoves(media),
        },
        child: GestureDetector(
          onPanUpdate: (d) => _bubbleDrag(media, d.delta),
          onPanEnd: (_) => _bubbleDragEnd(media),
          onPanCancel: () => _bubbleDragEnd(media),
          child: ChatUnreadArc.bubble(
            iconSize: _head,
            groups: groups,
            hidden: dock != 0,
            ringColor: scheme.surface,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ChatBubbleGlow(chat: chat, prefs: prefs, demo: NativeChat.tickerDemo),
                ),
                for (final (i, m) in pages.reversed.skip(1).take(dock == 0 ? 2 : 0).indexed.toList().reversed)
                  Positioned(
                    left: -12.0 * (i + 1),
                    top: 6,
                    child: IgnorePointer(
                      child: Opacity(opacity: 0.85, child: ChatRoomAvatar(room: chat.roomById(m.roomId), size: 36)),
                    ),
                  ),
                Positioned.fill(
                  child: Material(
                    color: scheme.tertiaryContainer,
                    elevation: 6,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: tap,
                      onDoubleTap: dock != 0 ? null : () => _markAllRead(context),
                      onLongPress: dock != 0 ? null : () => _setMenu(!_menu),
                      child: pages.isEmpty || holdsBigWindow
                          ? Icon(Icons.forum_rounded, color: scheme.onTertiaryContainer)
                          : Center(
                              child: IgnorePointer(
                                child: ChatRoomAvatar(room: chat.roomById(pages.last.roomId), size: 40),
                              ),
                            ),
                    ),
                  ),
                ),
                if (dock == 0 && pages.length > 1) Positioned(left: -4, top: -4, child: _count(pages.length, scheme)),
                if (dock == 0 && holdsBigWindow)
                  Positioned(
                    left: _head / 2 - 8,
                    top: _head - 10,
                    child: IgnorePointer(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: ShapeDecoration(
                          color: scheme.primary,
                          shape: const CircleBorder(),
                          shadows: [BoxShadow(color: scheme.surface, spreadRadius: 1.5)],
                        ),
                        child: Icon(Icons.web_asset_rounded, size: 11, color: scheme.onPrimary),
                      ),
                    ),
                  ),
                if (dock != 0 && total > 0)
                  Positioned(left: dock < 0 ? _head - 18 : 0, top: -4, child: _count(total, scheme)),
                if (chat.stalled)
                  Positioned(
                    left: dock < 0 ? _head - 18 : (dock > 0 ? 0 : -4),
                    top: _head - 14,
                    child: IgnorePointer(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: ShapeDecoration(
                          color: scheme.error,
                          shape: const CircleBorder(),
                          shadows: [BoxShadow(color: scheme.surface, spreadRadius: 1.5)],
                        ),
                        child: Icon(Icons.cloud_off_rounded, size: 11, color: scheme.onError),
                      ),
                    ),
                  )
                else if (chat.loadingCounts)
                  Positioned(
                    left: dock < 0 ? _head - 18 : (dock > 0 ? 0 : -4),
                    top: _head - 14,
                    child: IgnorePointer(
                      child: Container(
                        width: 18,
                        height: 18,
                        padding: const EdgeInsets.all(3),
                        decoration: ShapeDecoration(
                          color: scheme.surface,
                          shape: const CircleBorder(),
                          shadows: [BoxShadow(color: scheme.surface, spreadRadius: 1.5)],
                        ),
                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.tertiary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _count(int n, ColorScheme scheme, [bool more = false]) {
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: scheme.primary,
            shape: const StadiumBorder(),
            shadows: [BoxShadow(color: scheme.surface, spreadRadius: 1.5)],
          ),
          child: Text(
            n > 99 ? '99+' : '$n${more ? '+' : ''}',
            style: TextStyle(color: scheme.onPrimary, fontSize: 10, fontWeight: FontWeight.w700, height: 1),
          ),
        ),
      ),
    );
  }

  /// Without [m], the rest or the bigWindow
  Widget _miniBubble(BuildContext context, int slot, ChatMinimized? m, {int more = 0, bool bigWindow = false}) {
    final scheme = Theme.of(context).colorScheme;
    final chat = NativeChat.controller;
    final hidden = !_small && _dragged == null && _spot.$2 != 0;
    final media = MediaQuery.of(context);
    final at = _miniAt(media, slot);
    final size = m == null && !bigWindow ? 32.0 : _mini;
    final (unread, plus) = bigWindow
        ? (NativeChat.prefs.bubbleCounts(chat.unreadGroups()).values.fold(0, (a, b) => a + b), false)
        : (m == null || !chat.countsUnread(m.roomId) ? (0, false) : chat.unreadShown(m.roomId));
    final VoidCallback tap = bigWindow
        ? NativeChat.restoreBigWindow
        : (m == null ? () => _setMenu(true, rest: true) : () => NativeChat.restore(m));
    final typing = m != null && !bigWindow && chat.typingIn(m.roomId).isNotEmpty;
    final spoken = [
      bigWindow ? 'Chat window' : (m == null ? '' : chat.roomById(m.roomId).name),
      'minimized',
      if (typing) chat.roomById(m.roomId).isDm ? 'typing' : 'someone is typing',
      if (unread > 0) unread == 1 && !plus ? '1 unread message' : '$unread${plus ? '+' : ''} unread messages',
    ].join(', ');
    final VoidCallback? hold = m == null && !bigWindow
        ? null
        : () {
            HapticFeedback.selectionClick();
            _menu = false;
            _pressed = bigWindow ? NativeChat.bigWindowId : m!.roomId;
            _layer?.markNeedsBuild();
          };
    return AnimatedPositioned(
      key: ValueKey('mini:${bigWindow ? NativeChat.bigWindowId : (m?.roomId ?? '+')}'),
      duration: _still ? Duration.zero : Duration(milliseconds: _dragged == null ? 220 : 90),
      curve: Curves.easeOutCubic,
      left: at.dx + (_mini - _miniTap) / 2,
      top: at.dy + (_mini - _miniTap) / 2,
      child: IgnorePointer(
        ignoring: hidden,
        child: AnimatedOpacity(
          opacity: hidden ? 0 : 1,
          duration: _still ? Duration.zero : const Duration(milliseconds: 160),
          child: Semantics(
            container: true,
            excludeSemantics: true,
            button: true,
            label: m == null && !bigWindow ? '$more more minimized chats' : spoken,
            onTap: tap,
            customSemanticsActions: {
              if (bigWindow)
                const CustomSemanticsAction(label: 'Dismiss'): NativeChat.closeBigWindow
              else if (m != null)
                const CustomSemanticsAction(label: 'Dismiss'): () => NativeChat.dropMinimized(m.roomId),
              if (_small) ..._bubbleMoves(media),
            },
            // Touch area wider than the circle
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: tap,
              onLongPress: hold,
              onPanUpdate: _small ? (d) => _bubbleDrag(media, d.delta) : null,
              onPanEnd: _small ? (_) => _bubbleDragEnd(media) : null,
              onPanCancel: _small ? () => _bubbleDragEnd(media) : null,
              child: SizedBox.square(
                dimension: _miniTap,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: _still ? 1 : 0.5, end: 1),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Material(
                          color: scheme.tertiaryContainer,
                          elevation: 4,
                          shape: CircleBorder(side: BorderSide(color: scheme.surface, width: 1.5)),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: tap,
                            onLongPress: hold,
                            child: SizedBox.square(
                              dimension: size,
                              child: bigWindow
                                  ? Icon(Icons.forum_rounded, size: 22, color: scheme.onTertiaryContainer)
                                  : m == null
                                  ? Center(
                                      child: Text(
                                        '+$more',
                                        style: TextStyle(
                                          color: scheme.onTertiaryContainer,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : IgnorePointer(
                                      child: ChatRoomAvatar(room: chat.roomById(m.roomId), size: size),
                                    ),
                            ),
                          ),
                        ),
                        if (unread > 0) Positioned(right: -4, top: -4, child: _count(unread, scheme, plus)),
                        if (typing)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: 20,
                              height: 14,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: scheme.surface, width: 1.5),
                              ),
                              child: Icon(Icons.more_horiz_rounded, size: 12, color: scheme.onPrimary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubbleMenu(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final chat = NativeChat.controller;
    final safe = _safeOf(media);
    final at = _bubbleAt(media);
    final right = at.dx + _head / 2 > media.size.width / 2;
    final below = at.dy + _head / 2 < media.size.height / 2;
    final minis = _slots;
    final shift = minis == 0 ? 0.0 : 8 + minis * _miniStep;
    final edge = _small
        ? (below ? _miniAt(media, minis - 1).dy + _mini + 16 : _miniAt(media, 0).dy - 16)
        : (below ? at.dy + _head + 16 + shift : at.dy - 16 - shift);
    final room = below ? media.size.height - safe.bottom - edge : edge - safe.top;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () => _setMenu(false),
        child: Stack(
          children: [
            Positioned(
              left: right ? null : at.dx,
              right: right ? math.max(safe.right, media.size.width - at.dx - _head) : null,
              top: below ? edge : null,
              bottom: below ? null : media.size.height - edge,
              width: 250,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: math.max(120, room)),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHigh,
                  elevation: 8,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(16),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      for (final m in _menuItems)
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(left: 12, right: 4),
                          leading: ChatRoomAvatar(room: chat.roomById(m.roomId), size: 30),
                          title: Text(chat.roomById(m.roomId).name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            tooltip: 'Dismiss',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => NativeChat.dropMinimized(m.roomId),
                          ),
                          onTap: () {
                            _setMenu(false);
                            NativeChat.restore(m);
                          },
                        ),
                      if (_menuItems.isNotEmpty) const Divider(height: 1),
                      ChatLaunchMenu(dense: true, onPick: () => _setMenu(false)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dismiss(BuildContext context, String roomId, int slot) {
    final media = MediaQuery.of(context);
    final scheme = Theme.of(context).colorScheme;
    final at = _miniAt(media, slot);
    final right = at.dx + _mini / 2 > media.size.width / 2;
    void close() {
      _pressed = null;
      _layer?.markNeedsBuild();
    }

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: close,
        child: Stack(
          children: [
            Positioned(
              left: right ? null : at.dx + _mini + 10,
              right: right ? media.size.width - at.dx + 10 : null,
              top: at.dy + _mini / 2 - 24,
              height: 48,
              child: Material(
                color: scheme.surfaceContainerHigh,
                elevation: 8,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    close();
                    roomId == NativeChat.bigWindowId ? NativeChat.closeBigWindow() : NativeChat.dropMinimized(roomId);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.close_rounded, size: 18), SizedBox(width: 6), Text('Dismiss')],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
