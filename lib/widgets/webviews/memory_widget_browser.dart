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
        child: Text(
          'MemErr',
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
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
    final int flutterM = isAndroid ? (_appMem!['dalvikPss'] ?? 0) : (_appMem!['resident'] ?? 0);
    final int nativeM = isAndroid ? (_appMem!['nativePss'] ?? 0) : (_appMem!['compressed'] ?? 0);
    final int graphicsM = isAndroid ? (_appMem!['otherPss'] ?? 0) : (_appMem!['external'] ?? 0);
    final int used = isAndroid
        ? (_appMem!['totalPss'] ?? (flutterM + nativeM + graphicsM))
        : (_appMem!['total'] ?? (flutterM + nativeM + graphicsM));
    final int total = _devMem!['totalMem'] ?? used;

    final String usedStr = MemoryInfo.formatBytes(used, includeUnits: false);
    final String totalStr = MemoryInfo.formatBytes(total);

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
                Text(
                  '$usedStr / $totalStr',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          OverflowBar(
            spacing: 4,
            overflowAlignment: OverflowBarAlignment.start,
            children: [
              Text(
                'Flt:${MemoryInfo.formatBytes(flutterM)}',
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                'Gph:${MemoryInfo.formatBytes(graphicsM)}',
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                'Ntv:${MemoryInfo.formatBytes(nativeM)}',
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
