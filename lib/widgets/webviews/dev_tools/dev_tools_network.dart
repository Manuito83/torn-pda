// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mime/mime.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

enum SortColumn { name, type, start, time }

class DevToolsNetworkTab extends StatefulWidget {
  final InAppWebViewController? webViewController;
  const DevToolsNetworkTab({super.key, required this.webViewController});

  @override
  State<DevToolsNetworkTab> createState() => _DevToolsNetworkTabState();
}

class _DevToolsNetworkTabState extends State<DevToolsNetworkTab> {
  SortColumn _currentSortColumn = SortColumn.start;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadSortPrefs();
  }

  Future<List<dynamic>> _fetchPerformanceEntries() async {
    if (widget.webViewController == null) return [];
    try {
      final result = await widget.webViewController!
          .evaluateJavascript(source: 'JSON.stringify(performance.getEntriesByType("resource"))');
      if (result != null && result is String) {
        return jsonDecode(result) as List<dynamic>;
      }
    } catch (e) {
      debugPrint("Could not fetch performance entries: $e");
    }
    return [];
  }

  Future<void> _loadSortPrefs() async {
    final prefs = Prefs();
    final savedColumn = await prefs.getDevToolsNetworkSortColumn();
    final savedAscending = await prefs.getDevToolsNetworkSortAscending();
    if (!mounted) return;
    setState(() {
      final clampedIndex = min(max(savedColumn, 0), SortColumn.values.length - 1);
      _currentSortColumn = SortColumn.values[clampedIndex];
      _isAscending = savedAscending;
    });
  }

  Future<void> _onSort(SortColumn column) async {
    var nextColumn = _currentSortColumn;
    var nextAscending = _isAscending;
    if (_currentSortColumn == column) {
      nextAscending = !_isAscending;
    } else {
      nextColumn = column;
      nextAscending = true;
    }

    setState(() {
      _currentSortColumn = nextColumn;
      _isAscending = nextAscending;
    });

    await Prefs().setDevToolsNetworkSortColumn(nextColumn.index);
    await Prefs().setDevToolsNetworkSortAscending(nextAscending);
  }

  String _formatMilliseconds(num ms) {
    if (ms < 1000) return "${ms.toStringAsFixed(0)} ms";
    if (ms < 60000) return "${(ms / 1000).toStringAsFixed(1)} s";
    return "${(ms / 60000).toStringAsFixed(1)} m";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.webViewController == null) {
      return const Center(child: Text("WebView not available."));
    }

    return FutureBuilder<List<dynamic>>(
      future: _fetchPerformanceEntries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No network activity recorded yet."),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  onPressed: () => setState(() {}),
                )
              ],
            ),
          );
        }

        final resources = snapshot.data!;

        resources.sort((a, b) {
          final mapA = a as Map<String, dynamic>;
          final mapB = b as Map<String, dynamic>;
          int comparison = 0;
          switch (_currentSortColumn) {
            case SortColumn.name:
              final nameA = (mapA['name'] as String? ?? '').split('/').last;
              final nameB = (mapB['name'] as String? ?? '').split('/').last;
              comparison = nameA.compareTo(nameB);
              break;
            case SortColumn.type:
              final typeA = mapA['initiatorType'] as String? ?? '';
              final typeB = mapB['initiatorType'] as String? ?? '';
              comparison = typeA.compareTo(typeB);
              break;
            case SortColumn.start:
              final startA = mapA['startTime'] as num? ?? 0;
              final startB = mapB['startTime'] as num? ?? 0;
              comparison = startA.compareTo(startB);
              break;
            case SortColumn.time:
              final timeA = mapA['duration'] as num? ?? 0;
              final timeB = mapB['duration'] as num? ?? 0;
              comparison = timeA.compareTo(timeB);
              break;
          }
          return _isAscending ? comparison : -comparison;
        });

        return Column(
          children: [
            SizedBox(
              height: 240,
              child: _buildColumnChart(resources),
            ),
            const Divider(height: 1, thickness: 1),
            _buildTableHeader(),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.separated(
                  itemCount: resources.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final resource = resources[index] as Map<String, dynamic>? ?? {};
                    return _buildDataRow(resource);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColumnChart(List<dynamic> resources) {
    double maxDuration = 0;
    for (var res in resources) {
      final duration = (res['duration'] as num? ?? 0).toDouble();
      if (duration > maxDuration) maxDuration = duration;
    }
    if (maxDuration <= 0) maxDuration = 100;

    final double minBarHeight = maxDuration * 0.05;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: resources.length * 25.0,
          child: BarChart(
            BarChartData(
              maxY: maxDuration + minBarHeight,
              barGroups: List.generate(resources.length, (index) {
                final resource = resources[index] as Map<String, dynamic>;
                final duration = (resource['duration'] as num? ?? 0).toDouble();
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (duration < 0 ? 0 : duration) + minBarHeight,
                      color: _getColorForType(resource['initiatorType'] as String? ?? 'other'),
                      width: 12,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value > maxDuration) return const SizedBox.shrink();
                      return Text(_formatMilliseconds(value), style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final resource = resources[group.x] as Map<String, dynamic>;
                    final urlString = resource['name'] as String? ?? '';
                    final duration = (resource['duration'] as num? ?? 0);
                    return BarTooltipItem(
                      '${urlString.split('/').last.split('?').first}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      children: <TextSpan>[
                        TextSpan(
                          text: _formatMilliseconds(duration < 0 ? 0 : duration),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 11),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case "script":
        return Colors.orange;
      case "css":
        return Colors.blue;
      case "img":
        return Colors.purple;
      case "fetch":
      case "xmlhttprequest":
        return Colors.green;
      case "link":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          _buildSortableHeader("Name", SortColumn.name, 4),
          _buildSortableHeader("Type", SortColumn.type, 2, alignment: TextAlign.center),
          _buildSortableHeader("Start", SortColumn.start, 2, alignment: TextAlign.right),
          _buildSortableHeader("Time", SortColumn.time, 2, alignment: TextAlign.right),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String title, SortColumn column, int flex, {TextAlign alignment = TextAlign.left}) {
    final bool isActive = _currentSortColumn == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _onSort(column),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: alignment == TextAlign.right
                ? MainAxisAlignment.end
                : (alignment == TextAlign.center ? MainAxisAlignment.center : MainAxisAlignment.start),
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isActive) const SizedBox(width: 4),
              if (isActive) Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> resource) {
    final urlString = resource['name'] as String? ?? '';
    final url = Uri.tryParse(urlString);
    if (url == null) return const SizedBox.shrink();

    final path = url.path;
    final resourceName = path.substring(path.lastIndexOf('/') + 1).split('?').first;
    final domain = url.host.replaceFirst("www.", "");
    final mimeType = lookupMimeType(url.path);
    final initiatorType = resource['initiatorType'] as String? ?? 'other';
    final startTime = resource['startTime'] as num? ?? 0;
    final duration = resource['duration'] as num? ?? 0;
    final isImage = mimeType?.startsWith("image/") ?? false;

    Widget getIconWidget() {
      if (isImage) {
        final isSvg = mimeType == 'image/svg+xml';
        return SizedBox(
          width: 20,
          height: 20,
          child: isSvg
              ? SvgPicture.network(urlString, placeholderBuilder: (_) => const Icon(Icons.image_outlined, size: 20))
              : Image.network(urlString,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey.shade700)),
        );
      }
      IconData iconData;
      switch (initiatorType) {
        case "script":
          iconData = Icons.code;
          break;
        case "css":
          iconData = Icons.style;
          break;
        case "xmlhttprequest":
          iconData = Icons.sync_alt;
          break;
        case "link":
          iconData = Icons.link;
          break;
        case "fetch":
          iconData = Icons.http;
          break;
        case "font":
          iconData = Icons.font_download_outlined;
          break;
        default:
          iconData = Icons.insert_drive_file_outlined;
      }
      return Icon(iconData, size: 20, color: Colors.grey.shade700);
    }

    return InkWell(
      onTap: () => _showNetworkResourceDetails(resource),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  getIconWidget(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resourceName.isEmpty ? domain : resourceName,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(domain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                flex: 2,
                child: Text(initiatorType,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13))),
            Expanded(
                flex: 2,
                child: Text(_formatMilliseconds(startTime),
                    textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
            Expanded(
                flex: 2,
                child: Text(_formatMilliseconds(duration < 0 ? 0 : duration),
                    textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  void _showNetworkResourceDetails(Map<String, dynamic> resource) {
    final urlString = resource['name'] as String? ?? 'N/A';
    final duration = resource['duration'] as num? ?? 0;
    final startTime = resource['startTime'] as num? ?? 0;
    final entryType = resource['entryType'] as String? ?? 'N/A';
    final initiatorType = resource['initiatorType'] as String? ?? 'N/A';
    final transferSize = resource['transferSize'] as num? ?? 0;
    final decodedBodySize = resource['decodedBodySize'] as num? ?? 0;
    final mimeType = lookupMimeType(urlString);
    final isImage = mimeType?.startsWith("image/") ?? false;
    final isSvg = mimeType == 'image/svg+xml';

    final redirectTime = (resource['redirectEnd'] - resource['redirectStart'])?.toDouble() ?? 0.0;
    final dnsTime = (resource['domainLookupEnd'] - resource['domainLookupStart'])?.toDouble() ?? 0.0;
    final connectTime = (resource['connectEnd'] - resource['connectStart'])?.toDouble() ?? 0.0;
    final requestTime = (resource['responseStart'] - resource['requestStart'])?.toDouble() ?? 0.0;
    final responseTime = (resource['responseEnd'] - resource['responseStart'])?.toDouble() ?? 0.0;
    final bool hasTimingData =
        redirectTime > 0 || dnsTime > 0 || connectTime > 0 || requestTime > 0 || responseTime > 0;

    String formatBytes(num bytes) {
      if (bytes <= 0) return "0 B";
      const suffixes = ["B", "KB", "MB", "GB"];
      var i = (bytes.abs() == 0) ? 0 : (log(bytes.abs()) / log(1024)).floor();
      return "${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}";
    }

    showDialog(
      context: context,
      builder: (context) {
        bool isZoomed = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget imageWidget = isSvg
                ? SvgPicture.network(
                    urlString,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Image.network(
                    urlString,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );

            return AlertDialog(
              title: const Text("Resource Details"),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    if (isImage)
                      GestureDetector(
                        onTap: () => setDialogState(() => isZoomed = !isZoomed),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.fastOutSlowIn,
                          tween: Tween<double>(
                            begin: 100.0,
                            end: isZoomed ? MediaQuery.sizeOf(context).height * 0.5 : 100.0,
                          ),
                          builder: (BuildContext context, double height, Widget? child) {
                            return SizedBox(
                              height: height,
                              child: child,
                            );
                          },
                          child: InteractiveViewer(
                            panEnabled: isZoomed,
                            scaleEnabled: isZoomed,
                            child: imageWidget,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildDetailRow("URL:", urlString),
                    _buildDetailRow("Entry Type:", entryType),
                    _buildDetailRow("Initiator:", initiatorType),
                    _buildDetailRow("Start Time:", _formatMilliseconds(startTime)),
                    _buildDetailRow("Total Duration:", _formatMilliseconds(duration < 0 ? 0 : duration)),
                    _buildDetailRow("Transfer Size:", formatBytes(transferSize)),
                    _buildDetailRow("Decoded Size:", formatBytes(decodedBodySize)),
                    if (hasTimingData) ...[
                      const Divider(height: 24),
                      const Text("Timing Breakdown", style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildTimingBar("Redirect", redirectTime, duration.toDouble()),
                      _buildTimingBar("DNS Lookup", dnsTime, duration.toDouble()),
                      _buildTimingBar("Connection", connectTime, duration.toDouble()),
                      _buildTimingBar("Request Sent", requestTime, duration.toDouble()),
                      _buildTimingBar("Response", responseTime, duration.toDouble()),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: urlString));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('URL copied to clipboard')));
                    },
                    child: const Text("Copy URL")),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close")),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTimingBar(String label, double time, double totalTime) {
    if (time < 0) time = 0;
    final percentage = totalTime > 0 ? (time / totalTime) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(_formatMilliseconds(time), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage > 1.0 ? 1.0 : percentage,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
