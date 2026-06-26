import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_activity_model.dart';
import 'package:torn_pda/providers/ffscouter_activity_controller.dart';
import 'package:torn_pda/providers/ffscouter_premium_controller.dart';

/// Activity icon for a player: colour = how likely online right now (green rarely, red usually), tap for the day chart
class FFScouterActivityBadge extends StatefulWidget {
  final int playerId;
  final String? playerName;

  /// Strong enemy: shows a flame instead of the dot when active now
  final bool isTopHitter;

  const FFScouterActivityBadge({super.key, required this.playerId, this.playerName, this.isTopHitter = false});

  @override
  State<FFScouterActivityBadge> createState() => _FFScouterActivityBadgeState();
}

class _FFScouterActivityBadgeState extends State<FFScouterActivityBadge> {
  final FFScouterActivityController _activity = Get.find<FFScouterActivityController>();
  final FFScouterPremiumController _premium = Get.find<FFScouterPremiumController>();

  FFScouterActivityPattern? _pattern;
  bool _loadStarted = false;

  @override
  void initState() {
    super.initState();
    if (_premium.isPremium && _premium.activityEnabled) {
      _load();
    } else {
      _premium.refreshPremiumStatus();
    }
  }

  Future<void> _load() async {
    _loadStarted = true;
    final p = await _activity.playerPattern(widget.playerId);
    if (!mounted) return;
    setState(() => _pattern = p);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FFScouterPremiumController>(
      builder: (premium) {
        if (!premium.isPremium || !premium.activityEnabled) return const SizedBox.shrink();
        if (!_loadStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loadStarted) _load();
          });
        }
        final p = _pattern;
        if (p == null || !p.hasData) return const SizedBox.shrink();
        final v = p.valueAt();
        final topActive = widget.isTopHitter && v >= 0.6;
        final c = topActive ? Colors.red : _colorFor(v);
        return InkWell(
          onTap: () => _showDetails(p),
          borderRadius: BorderRadius.circular(5),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: c.withValues(alpha: 0.55)),
            ),
            child: Icon(topActive ? Icons.local_fire_department : Icons.bar_chart_rounded, size: 14, color: c),
          ),
        );
      },
    );
  }

  Color _colorFor(double v) {
    if (v >= 0.6) return Colors.red;
    if (v >= 0.3) return Colors.orange;
    return Colors.green;
  }

  void _showDetails(FFScouterActivityPattern p) {
    final hourly = p.hourly();
    final nowHour = DateTime.now().toUtc().hour;
    final peakHour = _peakHour(hourly);
    final nowPct = (p.valueAt() * 100).round();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            widget.playerName == null ? "Activity (TCT)" : "${widget.playerName} activity (TCT)",
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Now: ~$nowPct% likely active", style: const TextStyle(fontSize: 13)),
              Text(
                "Most active around ${peakHour.toString().padLeft(2, '0')}:00",
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: _HourlyBars(hourly: hourly, nowHour: nowHour),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("00", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  Text("12", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  Text("23", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close"))],
        );
      },
    );
  }

  int _peakHour(List<double> hourly) {
    var best = 0;
    for (var i = 1; i < hourly.length; i++) {
      if (hourly[i] > hourly[best]) best = i;
    }
    return best;
  }
}

class _HourlyBars extends StatelessWidget {
  final List<double> hourly;
  final int nowHour;

  const _HourlyBars({required this.hourly, required this.nowHour});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(24, (h) {
        final v = hourly[h].clamp(0.0, 1.0);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              height: (56 * v).clamp(2.0, 56.0),
              decoration: BoxDecoration(
                color: h == nowHour ? Colors.blue : Colors.blue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      }),
    );
  }
}
