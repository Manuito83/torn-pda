import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:torn_pda/utils/memory_info.dart';

class MemoryBarWidget extends StatefulWidget {
  const MemoryBarWidget({super.key});
  @override
  MemoryBarWidgetState createState() => MemoryBarWidgetState();
}

class MemoryBarWidgetState extends State<MemoryBarWidget> {
  Timer? _timer;
  Map<String, int>? _appMem;
  Map<String, int>? _devMem;
  bool _memError = false;

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchAll());
  }

  Future<void> _fetchAll() async {
    final appInfo = await MemoryInfo.getMemoryInfoDetailed();
    final devInfo = await MemoryInfo.getDeviceMemoryInfo();
    if (!mounted) return;

    setState(() {
      if (appInfo == null || devInfo == null) {
        _memError = true;
      } else {
        _memError = false;
        _appMem = appInfo;
        _devMem = devInfo;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_memError) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            children: [
              Text(
                'MEMORY USAGE',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              Text(
                'Error: unable to fetch memory info',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
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
    final int a1 = isAndroid ? (_appMem!['dalvikPss'] ?? 0) : (_appMem!['resident'] ?? 0);
    final int a2 = isAndroid ? (_appMem!['nativePss'] ?? 0) : (_appMem!['compressed'] ?? 0);
    final int a3 = isAndroid ? (_appMem!['otherPss'] ?? 0) : (_appMem!['external'] ?? 0);
    final int aT = isAndroid ? (_appMem!['totalPss'] ?? (a1 + a2 + a3)) : (_appMem!['total'] ?? (a1 + a2 + a3));

    final int deviceTotal = _devMem!['totalMem'] ?? aT;
    final int deviceFree = _devMem!['availMem'] ?? 0;

    double safeFraction(int used, int total) {
      if (total <= 0) return 0;
      final f = used / total;
      return f.isFinite ? f.clamp(0.0, 1.0) : 0;
    }

    int flexOf(double f) => (f * 1000).round().clamp(0, 1000);
    final dFlex = flexOf(safeFraction(a1, deviceTotal));
    final nFlex = flexOf(safeFraction(a2, deviceTotal));
    final sFlex = flexOf(safeFraction(a3, deviceTotal));
    final freeFlex = flexOf(safeFraction(deviceFree, deviceTotal));
    final usedSum = dFlex + nFlex + sFlex;
    final remFlex = (1000 - usedSum - freeFlex).clamp(0, 1000);

    final String usedStr = MemoryInfo.formatBytes(aT);
    final String totalStr = MemoryInfo.formatBytes(deviceTotal);

    const blue = Colors.blue;
    const orange = Colors.orange;
    const darkGreen = Colors.green;
    const purple = Colors.purple;

    Widget legendDot(Color color) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
              Text(usedStr, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(children: [
              if (dFlex > 0) Expanded(flex: dFlex, child: Container(color: blue, height: 6)),
              if (nFlex > 0) Expanded(flex: nFlex, child: Container(color: orange, height: 6)),
              if (sFlex > 0) Expanded(flex: sFlex, child: Container(color: darkGreen, height: 6)),
              if (remFlex > 0) Expanded(flex: remFlex, child: Container(color: Colors.black12, height: 6)),
              if (freeFlex > 0) Expanded(flex: freeFlex, child: Container(color: purple, height: 6)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(totalStr, style: const TextStyle(fontSize: 12)),
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
                  legendDot(blue),
                  Flexible(
                    child: Text(
                      'Dart VM: ${MemoryInfo.formatBytes(a1)}',
                      style: const TextStyle(fontSize: 12),
                      softWrap: true,
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  legendDot(orange),
                  Flexible(
                    child: Text(
                      'Native Heap: ${MemoryInfo.formatBytes(a2)}',
                      style: const TextStyle(fontSize: 12),
                      softWrap: true,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  legendDot(darkGreen),
                  Flexible(
                    child: Text(
                      'Graphics: ${MemoryInfo.formatBytes(a3)}',
                      style: const TextStyle(fontSize: 12),
                      softWrap: true,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  legendDot(purple),
                  Flexible(
                    child: Text(
                      'Free: ${MemoryInfo.formatBytes(deviceFree)}',
                      style: const TextStyle(fontSize: 12),
                      softWrap: true,
                      textAlign: TextAlign.end,
                    ),
                  ),
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
