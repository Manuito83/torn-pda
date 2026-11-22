import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/territory_map/city_map_layer.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';

final _money = NumberFormat('#,##0', 'en_US');

// The items of city.php, over the PDA map
class CityFinderPanel extends StatefulWidget {
  const CityFinderPanel({super.key, required this.layer});

  final CityMapLayer layer;

  @override
  State<CityFinderPanel> createState() => _CityFinderPanelState();
}

class _CityFinderPanelState extends State<CityFinderPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final text = TextStyle(color: themeProvider.mainText, fontSize: 12);
    return ListenableBuilder(
      listenable: widget.layer,
      builder: (context, _) {
        final options = widget.layer.options;
        if (!options.panelVisible) return const SizedBox.shrink();
        final items = [...widget.layer.items]..sort((a, b) => (b.price?.value ?? 0).compareTo(a.price?.value ?? 0));
        final total = items.fold(0, (sum, item) => sum + (item.price?.value ?? 0));
        final prices = widget.layer.prices;
        final count = '${items.length} item${items.length == 1 ? '' : 's'}';
        final summary = items.isEmpty
            ? 'No items found'
            : total == 0
            ? count
            : '$count - \$${_money.format(total)}';
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 260, maxHeight: MediaQuery.sizeOf(context).height / 2),
          child: Material(
            color: themeProvider.secondBackground.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            elevation: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _open = !_open),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('City items', style: TextStyle(color: Colors.orange, fontSize: 12)),
                        Flexible(
                          child: Text('  $summary', style: text, overflow: TextOverflow.ellipsis),
                        ),
                        Icon(_open ? Icons.expand_less : Icons.expand_more, size: 16, color: themeProvider.mainText),
                      ],
                    ),
                  ),
                ),
                if (prices != null && items.isNotEmpty && (prices.loading || prices.failed))
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
                    child: MapLoadNote(
                      loading: prices.loading,
                      label: 'Loading prices',
                      error: prices.failed ? 'Prices unavailable' : null,
                      onRetry: prices.retry,
                    ),
                  ),
                if (_open)
                  InkWell(
                    onTap: options.toggleItems,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text('Show items on the map', style: text)),
                          Switch(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            value: options.showItems,
                            onChanged: (_) => options.toggleItems(),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_open)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [for (final item in items) _itemRow(item, text)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemRow(CityItem item, TextStyle text) {
    final price = item.price;
    return InkWell(
      onTap: () {
        // A long list would cover it
        setState(() => _open = false);
        context.read<TerritoryMapController>().focusPoint(item.point);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.circle, size: 10, color: widget.layer.itemColor(item)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(price?.name ?? 'Item ${item.id}', style: text, overflow: TextOverflow.ellipsis),
            ),
            if (price != null)
              Text('  \$${_money.format(price.value)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
