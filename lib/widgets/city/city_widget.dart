// Flutter imports:
// Package imports:
import 'package:expandable/expandable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
// Project imports:
import 'package:torn_pda/providers/city_pda_map_controller.dart';
import 'package:torn_pda/widgets/city/city_pda_map_button.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';

class CityWidget extends StatefulWidget {
  final CityPdaMapController pdaMap;
  final GlobalKey pdaMapButton;
  final bool showFinder;
  final bool showButton;

  const CityWidget({
    required this.pdaMap,
    required this.pdaMapButton,
    required this.showFinder,
    required this.showButton,
  });

  @override
  CityWidgetState createState() => CityWidgetState();
}

class CityWidgetState extends State<CityWidget> {
  final _scrollController = ScrollController();
  final _moneyFormat = NumberFormat("#,##0", "en_US");
  late final _changes = Listenable.merge([widget.pdaMap, widget.pdaMap.prices]);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _changes,
      builder: (context, _) {
        // Torn's map hidden, nothing to find
        final showFinder = widget.showFinder && !widget.pdaMap.active;
        if (widget.pdaMap.arriving || (!showFinder && !widget.showButton)) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              if (widget.showButton) CityPdaMapButton(key: widget.pdaMapButton, map: widget.pdaMap),
              if (showFinder) ...[
                if (widget.showButton) const SizedBox(height: 8),
                _finder(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _finder(BuildContext context) {
    return Stack(
      children: [
        _cityPanel(context),
        if (widget.pdaMap.prices.found.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              color: Colors.orange,
              tooltip: widget.pdaMap.itemsHidden ? 'Show items on map' : 'Hide items from map',
              icon: Icon(widget.pdaMap.itemsHidden ? Icons.visibility_off : Icons.visibility),
              onPressed: widget.pdaMap.toggleItemsOnMap,
            ),
          ),
      ],
    );
  }

  Widget _mapCleanRow() {
    final clean = widget.pdaMap.mapClean;
    return InkWell(
      onTap: widget.pdaMap.toggleMapClean,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(clean ? Icons.layers_clear : Icons.layers, size: 16, color: Colors.orange),
            const SizedBox(width: 6),
            Text(
              clean ? 'Show territories and rackets' : 'Hide territories and rackets',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cityPanel(BuildContext context) {
    return ExpandablePanel(
      theme: const ExpandableThemeData(
        hasIcon: false,
        iconColor: Colors.grey,
        tapBodyToExpand: true,
        tapHeaderToExpand: true,
        tapBodyToCollapse: true,
      ),
      header: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text('City Finder', style: TextStyle(color: Colors.orange)),
              Text('(TAP TO EXPAND)', style: TextStyle(color: Colors.orange, fontSize: 8)),
            ],
          ),
        ],
      ),
      collapsed: ExpandableButton(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: _returnItems(true)),
        ),
      ),
      expanded: ConstrainedBox(
        constraints: BoxConstraints.loose(
          Size.fromHeight(MediaQuery.sizeOf(context).height - kToolbarHeight - AppBar().preferredSize.height) / 3,
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 0, 15),
                child: Column(children: [_mapCleanRow(), ..._returnItems(false)]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _returnItems(bool onlyTitle) {
    final itemList = <Widget>[];
    final prices = widget.pdaMap.prices;
    final cityItems = prices.found;

    if (prices.loading) return const [MapLoadNote(loading: true, label: 'Loading items')];
    if (prices.failed) {
      return [MapLoadNote(error: 'Torn API unavailable', onRetry: prices.retry)];
    }

    // Empty text
    if (cityItems.isEmpty) {
      itemList.add(
        const Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Flexible(
                child: Text("No items found", style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            ],
          ),
        ),
      );
      return itemList;
    }

    // Total items and price text
    if (cityItems.length == 1) {
      itemList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [Text("Found 1 item", style: TextStyle(fontSize: 12, color: Colors.grey[300]))],
          ),
        ),
      );
    } else {
      final itemQuantity = cityItems.length;
      var totalPrice = 0;
      for (final item in cityItems) {
        totalPrice += item.marketValue!;
      }
      itemList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: <Widget>[
              Text("Found $itemQuantity items, total value ", style: TextStyle(fontSize: 12, color: Colors.grey[300])),
              Text("\$${_moneyFormat.format(totalPrice)}", style: TextStyle(fontSize: 12, color: Colors.green[300])),
            ],
          ),
        ),
      );
    }

    if (onlyTitle) {
      return itemList;
    }

    // Item rows
    for (final item in cityItems) {
      itemList.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 3, 0, 0),
          child: Row(
            children: <Widget>[
              Text("${item.name}: ", style: const TextStyle(fontSize: 12, color: Colors.white)),
              Text(
                "\$${_moneyFormat.format(item.marketValue)}",
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
        ),
      );
    }

    return itemList;
  }
}
