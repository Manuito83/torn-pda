import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_player_card.dart';
import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/providers/faction_flights_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/territory_map/flights_globe.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_safe_margin.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

const _sheetSize = 0.88;
const _globeShare = 0.42;
const _flatHeight = 210.0;

class FlightsSheet extends StatefulWidget {
  const FlightsSheet({super.key, required this.flights, required this.onClose});

  final FactionFlightsController flights;
  final VoidCallback onClose;

  @override
  State<FlightsSheet> createState() => _FlightsSheetState();
}

class _FlightsSheetState extends State<FlightsSheet> {
  late final _now = ValueNotifier(DateTime.now());
  late final AppLifecycleListener _lifecycle;
  final _flags = <String, ui.Image>{};
  final _groupKeys = <String, GlobalKey>{};
  Timer? _clock;
  bool _shown = false;
  bool _disposed = false;

  bool get _running =>
      _shown && (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: (_) => setState(_syncClock));
    widget.flights.addListener(_loadFlags);
    unawaited(widget.flights.open());
    _loadFlags();
  }

  // Hidden behind the browser too
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shown = TickerMode.valuesOf(context).enabled && Visibility.of(context);
    _syncClock();
  }

  void _syncClock() {
    if (_running) {
      _now.value = DateTime.now();
      _clock ??= Timer.periodic(const Duration(seconds: 1), (_) => _now.value = DateTime.now());
    } else {
      _clock?.cancel();
      _clock = null;
    }
  }

  Future<void> _loadFlags() async {
    final flights = widget.flights.flights;
    if (flights == null) return;
    for (final place in flightFlagPlaces(flights)) {
      if (_flags.containsKey(place)) continue;
      final asset = chatCountryFlag(place);
      if (asset == null) continue;
      try {
        final data = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 42);
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        if (_disposed) return image.dispose();
        _flags[place]?.dispose();
        _flags[place] = image;
        setState(() {});
      } catch (e) {
        debugPrint('faction flights: flag unreadable: $e');
      }
    }
  }

  void _chooseMember(int id, {bool focus = false}) => widget.flights.select(id, focus: focus);

  void _messageMember(int id) {
    _chooseMember(id);
    final known = widget.flights.flights;
    if (!NativeChat.usable || known == null) return;
    final name =
        known.flying.where((f) => f.id == id).firstOrNull?.name ??
        known.abroad.where((m) => m.id == id).firstOrNull?.name;
    countMapUse(mapFlightsDmFeature);
    unawaited(NativeChat.openDm(ChatUser(id: id, name: name ?? 'Player')));
  }

  // Scrolls the list to its group
  void _choosePlace(String? place, {bool focus = false}) {
    widget.flights.selectPlace(place, focus: focus);
    if (place == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final group = _groupKeys[place]?.currentContext;
      if (group == null) return;
      final instant = MediaQuery.disableAnimationsOf(group);
      unawaited(Scrollable.ensureVisible(group, duration: instant ? Duration.zero : const Duration(milliseconds: 300)));
    });
  }

  @override
  void dispose() {
    _disposed = true;
    widget.flights.removeListener(_loadFlags);
    _lifecycle.dispose();
    _clock?.cancel();
    _now.dispose();
    for (final image in _flags.values) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flat = context.select<TerritoryMapController, bool>((c) => c.flatFlights);
    final theme = context.watch<ThemeProvider>();
    return MapSheet(
      flush: true,
      initialSize: _sheetSize,
      maxSize: _sheetSize,
      title: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text('Faction flights', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
      ),
      onClose: widget.onClose,
      pinned: (scroll) => ListenableBuilder(
        listenable: widget.flights,
        builder: (context, _) => LayoutBuilder(
          builder: (context, box) {
            final globe = FlightsGlobe(
              flights: widget.flights,
              flat: flat,
              now: _now,
              running: _running,
              spin: !MediaQuery.disableAnimationsOf(context),
              flags: _flags,
              onMember: _chooseMember,
              onName: _messageMember,
              onPlace: _choosePlace,
            );
            final list = _FlightsList(
              flights: widget.flights,
              now: _now,
              scroll: scroll,
              theme: theme,
              groupKeys: _groupKeys,
              onMember: (id) => _chooseMember(id, focus: true),
              onPlace: (place) => _choosePlace(place, focus: true),
            );
            final wide = box.maxWidth > box.maxHeight * 1.2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Summary(flights: widget.flights, now: _now, theme: theme),
                if (wide)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: globe),
                        VerticalDivider(width: 1, color: theme.mainText.withValues(alpha: 0.2)),
                        Expanded(child: list),
                      ],
                    ),
                  )
                else ...[
                  SizedBox(height: flat ? _flatHeight : box.maxHeight * _globeShare, child: globe),
                  Divider(height: 1, color: theme.mainText.withValues(alpha: 0.2)),
                  Expanded(child: list),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.flights, required this.now, required this.theme});

  final FactionFlightsController flights;
  final ValueNotifier<DateTime> now;
  final ThemeProvider theme;

  @override
  Widget build(BuildContext context) {
    final dim = theme.mainText.withValues(alpha: 0.65);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flights.flights case final known?)
            ValueListenableBuilder(
              valueListenable: now,
              builder: (_, time, _) => Text.rich(
                TextSpan(
                  children: [
                    for (final (text, bold) in flightsSummary(flightsAt(known, time.millisecondsSinceEpoch ~/ 1000)))
                      TextSpan(
                        text: text,
                        style: bold ? TextStyle(color: theme.mainText, fontWeight: FontWeight.w500) : null,
                      ),
                  ],
                ),
                style: TextStyle(color: dim, fontSize: 12.5),
              ),
            ),
          if (flights.answerLoading) const MapLoadNote(loading: true, label: 'Getting arrival times'),
          if (flights.answerError case final error?) MapLoadNote(error: error, onRetry: flights.refresh),
          if (flights.answerNote case final note?) Text(note, style: TextStyle(color: dim, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _FlightsList extends StatelessWidget {
  const _FlightsList({
    required this.flights,
    required this.now,
    required this.scroll,
    required this.theme,
    required this.groupKeys,
    required this.onMember,
    required this.onPlace,
  });

  final FactionFlightsController flights;
  final ValueNotifier<DateTime> now;
  final ScrollController scroll;
  final ThemeProvider theme;
  final Map<String, GlobalKey> groupKeys;
  final ValueChanged<int> onMember;
  final ValueChanged<String> onPlace;

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(color: theme.mainText.withValues(alpha: 0.65), fontSize: 11, letterSpacing: 0.9),
    ),
  );

  Widget _tappable({
    Key? key,
    required bool chosen,
    required VoidCallback onTap,
    required EdgeInsets padding,
    required Widget child,
  }) => Material(
    key: key,
    color: chosen ? theme.mainText.withValues(alpha: 0.1) : Colors.transparent,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );

  Widget _row({
    Key? key,
    required bool chosen,
    required VoidCallback onTap,
    required Color color,
    required String name,
    required String? subtitle,
    required String? flagPlace,
    required String trailing,
    bool quiet = false,
  }) {
    final dim = theme.mainText.withValues(alpha: 0.65);
    final flag = flagPlace == null ? null : chatCountryFlag(flagPlace);
    final flagImage = flag == null ? null : [Image.asset(flag, width: 12, height: 12), const SizedBox(width: 4)];
    return _tappable(
      key: key,
      chosen: chosen,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox.square(dimension: 10),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (subtitle == null) ...?flagImage,
                    Flexible(
                      child: Text(name, style: TextStyle(color: theme.mainText, fontSize: 14)),
                    ),
                  ],
                ),
                if (subtitle != null)
                  Row(
                    children: [
                      ...?flagImage,
                      Flexible(
                        child: Text(subtitle, style: TextStyle(color: dim, fontSize: 12)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            style: TextStyle(
              color: quiet ? dim : theme.mainText,
              fontSize: 13,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: now,
      builder: (context, time, _) {
        final nowSeconds = time.millisecondsSinceEpoch ~/ 1000;
        final known = flights.flights;
        final current = known == null ? null : flightsAt(known, nowSeconds);
        final bottom = mapBottomMargin(context);
        if (current == null || current.isEmpty) {
          return ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
            children: [
              if (current != null && !flights.answerLoading)
                Text(
                  'No one in your faction is flying or abroad',
                  style: TextStyle(color: theme.mainText.withValues(alpha: 0.65)),
                ),
            ],
          );
        }
        final chosen = flights.selected;
        final place = flights.place;
        return SingleChildScrollView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(8, 0, 8, bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (current.flying.isNotEmpty) _section('Flying'),
              for (final flight in flightsInOrder(current.flying))
                _row(
                  chosen: chosen == flight.id,
                  onTap: () => onMember(flight.id),
                  color: flight.hasTime ? flightsFlyingColor : flightsNoTimeColor,
                  name: flight.name,
                  subtitle: '${flight.from} to ${flight.to}',
                  flagPlace: flight.to == tornPlace ? flight.from : flight.to,
                  trailing: flight.hasTime
                      ? 'in ${ChatPlayerCard.span(Duration(seconds: flight.arrival! - nowSeconds))}'
                      : flights.answerLoading
                      ? ''
                      : 'no time',
                  quiet: !flight.hasTime,
                ),
              if (current.abroad.isNotEmpty) _section('Abroad'),
              for (final group in abroadGroups(current.abroad)) ...[
                _row(
                  key: groupKeys.putIfAbsent(group.place, GlobalKey.new),
                  chosen: place == group.place,
                  onTap: () => onPlace(group.place),
                  color: flightsAbroadColor,
                  name: group.place,
                  subtitle: null,
                  flagPlace: group.place,
                  trailing: '${group.members.length}',
                ),
                for (final member in group.members)
                  _tappable(
                    chosen: chosen == member.id,
                    onTap: () => onMember(member.id),
                    padding: const EdgeInsets.fromLTRB(28, 4, 8, 4),
                    child: Text(
                      member.name,
                      style: TextStyle(color: chosen == member.id ? flightsTornColor : theme.mainText, fontSize: 13),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
