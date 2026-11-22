import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/providers/city_map_options.dart';
import 'package:torn_pda/providers/faction_flights_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

const mapViewStyle = {
  MapView.normal: (icon: Icons.map_outlined, title: 'Factions', text: 'Who holds each territory'),
  MapView.rackets: (icon: Icons.attach_money, title: 'Rackets', text: 'Racket value a day, like land value'),
  MapView.sector: (icon: Icons.grid_view, title: 'Sector', text: 'The seven sectors of the city'),
  MapView.respect: (icon: Icons.star_outline, title: 'Respect', text: 'Respect a day for holding it'),
  MapView.size: (icon: Icons.aspect_ratio, title: 'Size', text: 'Territory size, 1 to 5'),
  MapView.war: (icon: MdiIcons.swordCross, title: 'Wars', text: 'Factions at war, assaults and fronts'),
  MapView.irradiated: (icon: MdiIcons.radioactive, title: 'Irradiated', text: 'Territories hit by a dirty bomb'),
  MapView.activity: (icon: MdiIcons.fire, title: 'Activity', text: 'Where the assaults are'),
};

const _spanLabels = {ActivitySpan.now: 'Now', ActivitySpan.week: '7 days', ActivitySpan.month: '4 weeks'};

const _densityLabels = {LifeDensity.low: 'Low', LifeDensity.normal: 'Normal', LifeDensity.high: 'High'};

class MapOptionsSheet extends StatelessWidget {
  const MapOptionsSheet({super.key, required this.onClose, required this.flights, this.city});

  final VoidCallback onClose;
  final FactionFlightsController flights;

  // City options only above city.php
  final CityMapOptions? city;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final themeProvider = context.watch<ThemeProvider>();
    final text = themeProvider.mainText;
    final header = TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14);

    Widget title(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(label, style: header),
    );

    Widget layer(String label, IconData icon, bool value, VoidCallback onTap, {String? subtitle}) {
      return SwitchListTile(
        secondary: Icon(icon, color: text),
        title: Text(label, style: TextStyle(color: text)),
        subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(color: text.withValues(alpha: 0.7))),
        value: value,
        onChanged: (_) => onTap(),
      );
    }

    return MapSheet(
      flush: true,
      title: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text('Map options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      onClose: onClose,
      children: [
        title('Map view'),
        for (final MapEntry(key: view, value: style) in mapViewStyle.entries) ...[
          ListTile(
            leading: Icon(style.icon, color: text),
            title: Text(style.title, style: TextStyle(color: text)),
            subtitle: Text(style.text, style: TextStyle(color: text.withValues(alpha: 0.7))),
            trailing: view == controller.view ? Icon(Icons.check_circle, color: text) : null,
            selected: view == controller.view,
            onTap: () => controller.setView(view),
          ),
          if (view == MapView.activity && controller.view == MapView.activity)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
              child: SegmentedButton<ActivitySpan>(
                segments: [for (final e in _spanLabels.entries) ButtonSegment(value: e.key, label: Text(e.value))],
                selected: {controller.activitySpan},
                showSelectedIcon: false,
                onSelectionChanged: (picked) => controller.setActivitySpan(picked.first),
              ),
            ),
        ],
        const Divider(),
        title('Layers'),
        if (controller.threeD && city == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Locks, war arrows, activity and lit windows at night show in 2D only',
              style: TextStyle(color: text.withValues(alpha: 0.7), fontSize: 12),
            ),
          ),
        if (city case final options?)
          ListenableBuilder(
            listenable: options,
            builder: (context, _) => Column(
              children: [
                layer('City Finder', Icons.search, options.showPanel, options.togglePanel),
                layer(
                  'Open the map when entering the city',
                  Icons.open_in_full,
                  options.opensAlways,
                  options.toggleOpensAlways,
                ),
                layer('City sites', Icons.place_outlined, options.showSites, options.toggleSites),
              ],
            ),
          ),
        layer('Faction names', Icons.abc, controller.factionNames, controller.toggleFactionNames),
        layer(
          'Since you last looked',
          Icons.history,
          controller.diaryStrip,
          controller.toggleDiaryStrip,
          subtitle: 'A strip at the bottom with what changed',
        ),
        layer(
          'Assault locks',
          Icons.lock_clock,
          controller.showLocks,
          controller.toggleLocks,
          subtitle: 'Territories locked 72 h after a war',
        ),
        const Divider(),
        title('City life'),
        layer(
          'Show city life',
          Icons.emoji_transportation,
          controller.cityLife,
          controller.toggleCityLife,
          subtitle: 'Planes, traffic, night, gunfire and police',
        ),
        if (controller.cityLife) ...[
          layer('Planes', Icons.flight, controller.lifePlanes, controller.toggleLifePlanes),
          layer('Traffic', Icons.directions_car_outlined, controller.lifeTraffic, controller.toggleLifeTraffic),
          layer(
            'Night',
            Icons.nightlight_outlined,
            controller.lifeNight,
            controller.toggleLifeNight,
            subtitle: 'City lights after dark, Torn time',
          ),
          if (!kReleaseMode && controller.lifeNight)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 16, 0),
              child: Row(
                children: [
                  Text(
                    controller.debugTctHour == null
                        ? 'TCT now'
                        : 'TCT ${controller.debugTctHour!.toStringAsFixed(1)} h',
                    style: TextStyle(color: text, fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: controller.debugTctHour ?? 12,
                      max: 24,
                      divisions: 96,
                      onChanged: controller.setDebugTctHour,
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.restore), onPressed: () => controller.setDebugTctHour(null)),
                ],
              ),
            ),
          layer(
            'Gunfire',
            MdiIcons.pistol,
            controller.lifeGunfire,
            controller.toggleLifeGunfire,
            subtitle: 'More where the real wars are',
          ),
          layer(
            'Police',
            Icons.local_police_outlined,
            controller.lifePolice,
            controller.toggleLifePolice,
            subtitle: 'Patrols with flashing lights',
          ),
          ListTile(
            leading: Icon(Icons.tune, color: text),
            title: Text('Density', style: TextStyle(color: text)),
            subtitle: Text(
              'More cars, flights, gunfire and patrols',
              style: TextStyle(color: text.withValues(alpha: 0.7)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
            child: SegmentedButton<LifeDensity>(
              segments: [
                for (final e in _densityLabels.entries) ButtonSegment(value: e.key, label: Text(e.value)),
              ],
              selected: {controller.lifeDensity},
              showSelectedIcon: false,
              onSelectionChanged: (picked) => controller.setLifeDensity(picked.first),
            ),
          ),
        ],
        const Divider(),
        title('Faction flights'),
        layer(
          'Flights globe button',
          Icons.public,
          controller.flightsButton,
          controller.toggleFlightsButton,
          subtitle: 'Round button at the bottom right of the map',
        ),
        layer(
          'Flat map',
          Icons.map_outlined,
          controller.flatFlights,
          controller.toggleFlatFlights,
          subtitle: 'Off: 3D globe that turns',
        ),
        ListenableBuilder(
          listenable: flights,
          builder: (context, _) => SwitchListTile(
            secondary: Icon(Icons.flight_takeoff, color: text),
            title: Text('Share my flights with my faction', style: TextStyle(color: text)),
            subtitle: Text(
              flights.shareError ??
                  (flights.share == null
                      ? 'Loading'
                      : flights.shareBusy
                      ? 'Saving'
                      : 'Your arrival time, only while you fly'),
              style: TextStyle(color: text.withValues(alpha: 0.7)),
            ),
            value: flights.share ?? false,
            onChanged: flights.share == null || flights.shareBusy ? null : flights.setShare,
          ),
        ),
      ],
    );
  }
}
