import 'package:material_ui/material_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/territory_map/map_safe_margin.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

Widget mapChips(List<(String, VoidCallback)> items) {
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final (label, onPressed) in items)
        ActionChip(visualDensity: VisualDensity.compact, label: Text(label), onPressed: onPressed),
    ],
  );
}

// Closes on release below this
const _closeBelow = 0.1;

class MapSheet extends StatefulWidget {
  const MapSheet({
    super.key,
    required this.title,
    this.url,
    required this.onClose,
    this.children = const [],
    this.flush = false,
    this.initialSize,
    this.maxSize = 0.7,
    this.pinned,
  });

  final Widget title;
  final String? url;
  final VoidCallback onClose;
  final List<Widget> children;

  // Rows bring their own side padding
  final bool flush;
  final double? initialSize;
  final double maxSize;

  // Fixed body, only its list scrolls
  final Widget Function(ScrollController scroll)? pinned;

  @override
  State<MapSheet> createState() => _MapSheetState();
}

class _MapSheetState extends State<MapSheet> {
  final _sheet = DraggableScrollableController();
  double _extent = 1;
  bool _closed = false;

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _dragHeader(DragUpdateDetails details) {
    if (_sheet.isAttached) _sheet.jumpTo(_sheet.size - _sheet.pixelsToSize(details.delta.dy));
  }

  void _endHeaderDrag(DragEndDetails _) {
    if (!_sheet.isAttached) return;
    if (_sheet.size < widget.maxSize * 0.6) return _close();
    _sheet.jumpTo(widget.maxSize);
  }

  void _openInTorn(String url, BrowserTapType tap) {
    // Above city.php the frame closes too
    final overCity = context.read<TerritoryMapController>().overCity;
    if (overCity && tap == BrowserTapType.short) {
      Navigator.pop(context, CityTornLink(url));
      return;
    }
    context.read<WebViewProvider>().openBrowserPreference(context: context, url: url, browserTapType: tap);
    if (overCity) Navigator.pop(context);
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    widget.onClose();
  }

  bool _onNotification(Notification notification) {
    if (notification is DraggableScrollableNotification) {
      _extent = notification.extent;
      if (_extent <= notification.minExtent) _close();
    } else if (notification is ScrollEndNotification && notification.depth == 0 && _extent < _closeBelow) {
      _close();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final side = widget.flush ? 0.0 : 16.0;
    final pinned = widget.pinned;
    final handle = Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
      ),
    );
    final header = Padding(
      padding: EdgeInsets.only(left: side, right: 8),
      child: Row(
        children: [
          Expanded(child: widget.title),
          if (widget.url case final url?)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: themeProvider.mainText,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(MdiIcons.openInNew, size: 16),
              label: const Text('Open in Torn', style: TextStyle(fontSize: 12)),
              onPressed: () => _openInTorn(url, BrowserTapType.short),
              onLongPress: () => _openInTorn(url, BrowserTapType.long),
            ),
          IconButton(
            icon: Icon(Icons.close, color: themeProvider.mainText),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
    return NotificationListener<Notification>(
      onNotification: _onNotification,
      child: LayoutBuilder(
        builder: (context, box) => DraggableScrollableSheet(
          controller: _sheet,
          initialChildSize: widget.initialSize ?? (landscape ? 0.28 : 0.45),
          minChildSize: 0,
          maxChildSize: widget.maxSize,
          builder: (context, scroll) => Material(
            color: themeProvider.secondBackground,
            elevation: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: pinned == null ? Clip.none : Clip.antiAlias,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: themeProvider.mainText, fontSize: 13),
              child: pinned != null
                  // Full height, dragging slides, not squeezes
                  ? OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: box.maxHeight * widget.maxSize,
                      maxHeight: box.maxHeight * widget.maxSize,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: _dragHeader,
                            onVerticalDragEnd: _endHeaderDrag,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(children: [handle, header]),
                            ),
                          ),
                          Expanded(child: pinned(scroll)),
                        ],
                      ),
                    )
                  : ListView(
                      controller: scroll,
                      padding: EdgeInsets.fromLTRB(0, 6, 0, mapBottomMargin(context)),
                      children: [
                        handle,
                        header,
                        Padding(
                          padding: EdgeInsets.only(left: side, right: widget.flush ? 0 : 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widget.children),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SheetSection extends StatelessWidget {
  const SheetSection(this.title, {super.key, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}
