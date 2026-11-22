import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/territory_map/faction_colors.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/models/territory_map/war_fronts.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/territory_map/activity_layer.dart';
import 'package:torn_pda/widgets/territory_map/assault_locks_layer.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/war_arrows_layer.dart';

const _warnAmber = Color(0xFF925A00);

class TerritoryMapDataChip extends StatefulWidget {
  const TerritoryMapDataChip({super.key});

  @override
  State<TerritoryMapDataChip> createState() => _TerritoryMapDataChipState();
}

class _TerritoryMapDataChipState extends State<TerritoryMapDataChip> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final settings = context.watch<SettingsProvider>();
    final prefix = controller.sample ? 'Sample data' : 'Data';
    final time = controller.dataTime;
    final error = controller.lastError;
    if (time == null && error == null) {
      return MapLoadChip(loading: controller.refreshing, label: 'Loading map data');
    }

    final warn = error != null || controller.isStale;
    var text = '$prefix: $error';
    if (time != null) {
      final age = DateTime.now().difference(time);
      final hour = TimeFormatter(
        inputTime: time,
        timeFormatSetting: settings.currentTimeFormat,
        timeZoneSetting: settings.currentTimeZone,
      ).formatHour;
      text = '$prefix $hour - ${age.inMinutes < 1 ? 'just now' : '${chatSpan(age)} ago'}';
      if (warn) text += ' - showing last data';
    }
    return GestureDetector(
      onTap: error == null ? null : controller.retry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: warn ? _warnAmber : Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            if (error != null) const Icon(Icons.refresh, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class TerritoryMapLegend extends StatefulWidget {
  const TerritoryMapLegend({super.key, this.forceOpen = false});

  // Open for the shared picture
  final bool forceOpen;

  @override
  State<TerritoryMapLegend> createState() => _TerritoryMapLegendState();
}

class _TerritoryMapLegendState extends State<TerritoryMapLegend> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final open = _open || widget.forceOpen;
    final themeProvider = context.watch<ThemeProvider>();
    final lightTheme = themeProvider.currentTheme == AppTheme.light;
    final hasFaction = context.select<TerritoryMapController, bool>((c) => c.myFactionId != 0);
    final showLocks = context.select<TerritoryMapController, bool>((c) => c.showLocks && c.pastDay == null);
    final view = context.select<TerritoryMapController, MapView>((c) => c.shownView);
    final span = context.select<TerritoryMapController, ActivitySpan>((c) => c.activitySpan);
    final rackets = context.select<TerritoryMapController, Map<String, Racket>>((c) => c.state?.rackets ?? const {});
    final border = lightTheme ? Colors.black : Colors.white;
    final textStyle = TextStyle(color: themeProvider.mainText, fontSize: 12);
    final frame = Border.all(color: themeProvider.mainText.withValues(alpha: 0.6), width: 1);
    final dim = dimFill(lightTheme: lightTheme);
    final file = context.select<TerritoryMapController, TerritoryFile?>((c) => c.territories);
    final scale = switch (view) {
      MapView.rackets => racketScale(rackets.values),
      MapView.respect => respectScale(file?.territories.values ?? const []),
      MapView.size => sizeScale,
      _ => const <int>[],
    };
    Color ramp(int step) => valueRamp[rampIndex(step, scale.length)];

    Widget spot(String label, int assaults) {
      final radius = spotRadius(assaults);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: spotRadius(9) * 2,
              child: Center(
                child: CircleAvatar(radius: radius, backgroundColor: activityColor.withValues(alpha: 0.85)),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: textStyle),
          ],
        ),
      );
    }

    Widget arrow(String label, Color color, {double progress = 0.5}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 12,
              child: CustomPaint(painter: _ArrowSwatch(color, progress, lightTheme ? Colors.white : Colors.black)),
            ),
            const SizedBox(width: 6),
            Text(label, style: textStyle),
          ],
        ),
      );
    }

    Widget row(String label, Color fill, {Color? outline, bool dot = false, Widget? swatch}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 12,
              decoration: BoxDecoration(
                color: fill,
                border: outline == null ? frame : Border.all(color: outline, width: 2),
              ),
              child: dot ? const Center(child: CircleAvatar(radius: 3, backgroundColor: Colors.red)) : swatch,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: themeProvider.mainText, fontSize: 12)),
          ],
        ),
      );
    }

    return Material(
      color: themeProvider.secondBackground.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Legend', style: TextStyle(color: themeProvider.mainText, fontSize: 12)),
                  Icon(open ? Icons.expand_less : Icons.expand_more, size: 16, color: themeProvider.mainText),
                ],
              ),
              if (open) ...[
                ...switch (view) {
                  MapView.normal => [
                    if (hasFaction) row('My faction', fillColor(mineColor, lightTheme: lightTheme), outline: border),
                    row('No owner', unownedFill),
                    row('Irradiated', irradiatedFill(lightTheme: lightTheme)),
                  ],
                  MapView.war => [
                    row('At war', fillColor(7, lightTheme: lightTheme)),
                    row('Not at war', dim),
                    for (final style in momentumStyle.values) arrow(style.label, style.color),
                    Text('Fill: how far the assault has got', style: textStyle),
                    arrow('Conquests - last ${frontDays.inDays} days', Colors.grey, progress: 1),
                  ],
                  MapView.rackets => [
                    for (final (i, bound) in scale.indexed) row('\$${formatBigNumbers(bound)}+ a day', ramp(i)),
                    row('No racket', dim),
                  ],
                  MapView.sector => [
                    for (final (i, color) in sectorColors.indexed) row('Sector ${i + 1}', color),
                  ],
                  MapView.respect => [
                    for (final (i, bound) in scale.indexed) row('$bound+ respect a day', ramp(i)),
                  ],
                  MapView.size => [
                    for (final (i, size) in scale.indexed) row('Size $size', ramp(i)),
                  ],
                  MapView.irradiated => [
                    row('Irradiated', irradiatedFill(lightTheme: lightTheme)),
                    row('Not irradiated', dim),
                  ],
                  MapView.activity => [
                    Text(
                      span == ActivitySpan.now ? 'Assaults now' : 'Assaults, last ${activityDays[span]} days',
                      style: textStyle,
                    ),
                    spot('1', 1),
                    spot('4', 4),
                    spot('9', 9),
                  ],
                },
                if (showsAssaults(view)) row('Assault', Colors.transparent, outline: Colors.red, dot: true),
                if (showLocks)
                  row('Locked: 72 h after a war', Colors.transparent, swatch: CustomPaint(painter: LockHatchSwatch())),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Straight arrow, filled up to progress
class _ArrowSwatch extends CustomPainter {
  _ArrowSwatch(this.color, this.progress, this.empty);

  final Color color;
  final double progress;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final head = w - h * 0.7;
    final top = h * 0.3;
    final bottom = h * 0.7;
    final outline = Path()
      ..moveTo(0, top)
      ..lineTo(head, top)
      ..lineTo(head, 0)
      ..lineTo(w, h / 2)
      ..lineTo(head, h)
      ..lineTo(head, bottom)
      ..lineTo(0, bottom)
      ..close();
    canvas
      ..drawPath(outline, Paint()..color = empty.withValues(alpha: 0.6))
      ..save()
      ..clipPath(outline)
      ..drawRect(Rect.fromLTWH(0, 0, w * progress, h), Paint()..color = color)
      ..restore()
      ..drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color,
      );
  }

  @override
  bool shouldRepaint(_ArrowSwatch old) => old.color != color || old.progress != progress || old.empty != empty;
}
