import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/memory_info.dart';

class MemoryBarWidgetDrawer extends StatefulWidget {
  const MemoryBarWidgetDrawer({super.key});

  @override
  MemoryBarWidgetDrawerState createState() => MemoryBarWidgetDrawerState();
}

class MemoryBarWidgetDrawerState extends State<MemoryBarWidgetDrawer> {
  Timer? _timer;
  Map<String, int>? _appMem;
  Map<String, int>? _devMem;
  bool _memError = false;

  @override
  void initState() {
    super.initState();
    final initialProvider = Provider.of<WebViewProvider>(context, listen: false);
    if (!initialProvider.browserShowInForeground || initialProvider.webViewSplitActive) {
      _fetchAll();
    }
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final prov = Provider.of<WebViewProvider>(context, listen: false);
      if (!prov.browserShowInForeground || prov.webViewSplitActive) {
        _fetchAll();
      }
    });
  }

  Future<void> _fetchAll() async {
    final appInfo = await MemoryInfo.getMemoryInfoDetailed();
    final devInfo = await MemoryInfo.getDeviceMemoryInfo();
    if (!mounted) return;

    setState(() {
      _memError = appInfo == null || devInfo == null;
      _appMem = appInfo;
      _devMem = devInfo;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (_memError) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            children: [
              Text('MEMORY USAGE', style: TextStyle(fontSize: 12, color: Colors.red)),
              Text('Error: unable to fetch memory info', style: TextStyle(fontSize: 12, color: Colors.red)),
            ],
          ),
        ),
      );
    }
    if (_appMem == null || _devMem == null) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final bool isAndroid = Platform.isAndroid;
    late final int seg1M, seg2M, seg3M;
    late final String seg1Name, seg2Name, seg3Name;
    if (isAndroid) {
      seg1M = _appMem!['dalvikPss'] ?? 0;
      seg2M = _appMem!['nativePss'] ?? 0;
      seg3M = _appMem!['otherPss'] ?? 0;
      seg1Name = 'Flutter';
      seg2Name = 'Native';
      seg3Name = 'Graphics';
    } else {
      seg1M = _appMem!['private'] ?? 0;
      seg2M = _appMem!['compressed'] ?? 0;
      seg3M = _appMem!['external'] ?? 0;
      seg1Name = 'Private';
      seg2Name = 'Compr.';
      seg3Name = 'External';
    }
    final int usedM =
        isAndroid ? (_appMem!['totalPss'] ?? (seg1M + seg2M + seg3M)) : (_appMem!['total'] ?? (seg1M + seg2M + seg3M));
    final int deviceTotal = _devMem!['totalMem'] ?? _devMem!['total'] ?? 0;
    final int deviceFree = _devMem!['availMem'] ?? 0;

    double ratio(int part, int whole) => whole > 0 ? (part / whole).clamp(0, 1) : 0;
    int flex(double r) => (r * 1000).round();
    final int f1 = flex(ratio(seg1M, deviceTotal));
    final int f2 = flex(ratio(seg2M, deviceTotal));
    final int f3 = flex(ratio(seg3M, deviceTotal));
    final int fFree = flex(ratio(deviceFree, deviceTotal));
    final int fRem = (1000 - f1 - f2 - f3 - fFree).clamp(0, 1000);

    const blue = Colors.blue;
    const orange = Colors.orange;
    const green = Colors.green;
    const purple = Colors.purple;
    Widget dot(Color c) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('MEMORY USAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('USED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(_fmt(usedM), style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(children: [
              if (f1 > 0) Expanded(flex: f1, child: Container(color: blue, height: 6)),
              if (f2 > 0) Expanded(flex: f2, child: Container(color: orange, height: 6)),
              if (f3 > 0) Expanded(flex: f3, child: Container(color: green, height: 6)),
              if (fRem > 0) Expanded(flex: fRem, child: Container(color: Colors.black12, height: 6)),
              if (fFree > 0) Expanded(flex: fFree, child: Container(color: purple, height: 6)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(deviceTotal > 0 ? _fmt(deviceTotal) : '—', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  dot(blue),
                  Flexible(child: Text('$seg1Name: ${_fmt(seg1M)}', style: const TextStyle(fontSize: 12)))
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  dot(orange),
                  Flexible(child: Text('$seg2Name: ${_fmt(seg2M)}', style: const TextStyle(fontSize: 12)))
                ]),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  dot(green),
                  Flexible(
                      child: Text('$seg3Name: ${_fmt(seg3M)}',
                          style: const TextStyle(fontSize: 12), textAlign: TextAlign.end))
                ]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  dot(purple),
                  Flexible(
                      child: Text('Free: ${_fmt(deviceFree)}',
                          style: const TextStyle(fontSize: 12), textAlign: TextAlign.end))
                ]),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),
      ],
    );
  }
}
