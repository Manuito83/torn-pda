import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/memory_info.dart';

class MemoryWidgetBrowser extends StatefulWidget {
  const MemoryWidgetBrowser({super.key});

  @override
  MemoryWidgetBrowserState createState() => MemoryWidgetBrowserState();
}

class MemoryWidgetBrowserState extends State<MemoryWidgetBrowser> {
  Timer? _timer;
  Map<String, int>? _appMem;
  Map<String, int>? _devMem;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<WebViewProvider>(context, listen: false);
      if (prov.browserShowInForeground) _updateMemory();
    });
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final prov = Provider.of<WebViewProvider>(context, listen: false);
      if (prov.browserShowInForeground) _updateMemory();
    });
  }

  Future<void> _updateMemory() async {
    final appInfo = await MemoryInfo.getMemoryInfoDetailed();
    final devInfo = await MemoryInfo.getDeviceMemoryInfo();
    if (!mounted) return;
    setState(() {
      if (appInfo == null || devInfo == null) {
        _hasError = true;
      } else {
        _hasError = false;
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
    if (_hasError) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('MemErr', style: TextStyle(fontSize: 12, color: Colors.red)),
      );
    }
    if (_appMem == null || _devMem == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final bool isAndroid = Platform.isAndroid;

    final int seg1 = isAndroid ? (_appMem!['dalvikPss'] ?? 0) : (_appMem!['private'] ?? 0);
    final int seg2 = isAndroid ? (_appMem!['nativePss'] ?? 0) : (_appMem!['compressed'] ?? 0);
    final int seg3 = isAndroid ? (_appMem!['otherPss'] ?? 0) : (_appMem!['external'] ?? 0);
    final int usedM =
        isAndroid ? (_appMem!['totalPss'] ?? (seg1 + seg2 + seg3)) : (_appMem!['total'] ?? (seg1 + seg2 + seg3));

    final int deviceTotal = _devMem!['totalMem'] ?? _devMem!['total'] ?? 0;

    String fmtTotal(int bytes) {
      final mb = bytes / (1024 * 1024);
      if (mb >= 1024) {
        final gb = mb / 1024;
        return '${gb.toStringAsFixed(1)} GB';
      }
      return '${mb.toStringAsFixed(0)} MB';
    }

    final String totalStr = deviceTotal > 0 ? fmtTotal(deviceTotal) : '?';

    String fmtUsed(int bytes) {
      final mb = bytes / (1024 * 1024);
      if (mb >= 1024) {
        final gb = mb / 1024;
        return gb.toStringAsFixed(1);
      }
      bool showMB = totalStr.contains('GB');
      return '${mb.toStringAsFixed(0)}${showMB ? ' MB' : ''}';
    }

    final String usedStr = fmtUsed(usedM);

    final String l1 = isAndroid ? 'F' : 'P';
    final String l2 = isAndroid ? 'N' : 'C';
    final String l3 = isAndroid ? 'G' : 'E';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.memory, size: 16),
                const SizedBox(width: 4),
                Text('$usedStr / $totalStr', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          OverflowBar(
            spacing: 4,
            overflowAlignment: OverflowBarAlignment.start,
            children: [
              Text('$l1:${fmtTotal(seg1)}', style: const TextStyle(fontSize: 10)),
              Text('$l3:${fmtTotal(seg3)}', style: const TextStyle(fontSize: 10)),
              Text('$l2:${fmtTotal(seg2)}', style: const TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
