import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_flights_model.dart';
import 'package:torn_pda/providers/ffscouter_flights_controller.dart';
import 'package:torn_pda/providers/ffscouter_premium_controller.dart';

/// Remaining-time chip (blue) + info button, sits left of the card's travel
/// icon. Premium only; nothing when not traveling.
class FFScouterFlightInfo extends StatefulWidget {
  final int playerId;

  /// Target is in transit (caller derives this from travel status).
  final bool isTraveling;

  const FFScouterFlightInfo({super.key, required this.playerId, required this.isTraveling});

  @override
  State<FFScouterFlightInfo> createState() => _FFScouterFlightInfoState();
}

class _FFScouterFlightInfoState extends State<FFScouterFlightInfo> {
  final FFScouterFlightsController _flights = Get.find<FFScouterFlightsController>();
  final FFScouterPremiumController _premium = Get.find<FFScouterPremiumController>();

  FFScouterFlightsResponse? _data;
  bool _loading = false;
  bool _loadStarted = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (!widget.isTraveling) return;
    if (_premium.isPremium) {
      _load();
    } else {
      _premium.refreshPremiumStatus();
    }
    // tick the countdown
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _loadStarted = true;
    setState(() => _loading = true);
    final data = await _flights.fetch(widget.playerId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTraveling) return const SizedBox.shrink();
    return GetBuilder<FFScouterPremiumController>(
      builder: (premium) {
        if (!premium.isPremium) return const SizedBox.shrink();
        // premium known late: fetch now
        if (!_loadStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loadStarted) _load();
          });
        }
        return _content();
      },
    );
  }

  Widget _content() {
    if (_loading && _data == null) {
      return const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2));
    }

    final flight = _data?.current;
    final arrival = flight?.estimatedArrival;
    if (flight == null || arrival == null) return const SizedBox.shrink();

    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = arrival - nowSec;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          remaining > 0 ? _fmtRemaining(remaining) : "now",
          style: TextStyle(color: Colors.blue[600], fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 2),
        InkWell(
          onTap: () => _showDetails(flight, arrival),
          child: Icon(Icons.info_outline, size: 14, color: Colors.blue[300]),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showDetails(FFScouterFlight flight, int arrival) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("FFScouter flight", style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Landing", "~${_fmtTct(arrival)} TCT"),
              if (flight.hasArrivalWindow)
                _detailRow(
                  "Window",
                  "${_fmtTct(flight.earliestArrivalTime!)} - ${_fmtTct(flight.latestArrivalTime!)} TCT",
                ),
              if (flight.statusDescription != null && flight.statusDescription!.isNotEmpty)
                _detailRow("Status", flight.statusDescription!),
              if (flight.travelMethod != null && flight.travelMethod!.isNotEmpty)
                _detailRow("Method", flight.travelMethod!),
              if (flight.bookLikelyBeingUsed == true) _detailRow("Travel book", "Likely in use"),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close"))],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  /// HH:MM in TCT (UTC).
  String _fmtTct(int epochSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true);
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _fmtRemaining(int seconds) {
    final m = seconds ~/ 60;
    if (m < 1) return "<1m";
    if (m < 60) return "${m}m";
    final h = m ~/ 60;
    return "${h}h ${m % 60}m";
  }
}
