import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_search.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class TerritoryMapSearchField extends StatelessWidget {
  const TerritoryMapSearchField({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: 'Territory, faction or tag',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }
}

class TerritoryMapSearchResults extends StatelessWidget {
  const TerritoryMapSearchResults({super.key, required this.query, required this.onPicked});

  final String query;
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final themeProvider = context.watch<ThemeProvider>();
    final state = controller.state;
    final file = controller.territories;
    if (file == null || query.trim().isEmpty) return const SizedBox.shrink();

    final hits = searchMap(query, file.territories.keys, state?.factions ?? const {}, controller.owned);
    return Material(
      color: themeProvider.secondBackground,
      elevation: 6,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
        child: hits.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Nothing found', style: TextStyle(color: themeProvider.mainText)),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: hits.length,
                itemBuilder: (context, i) {
                  final hit = hits[i];
                  return SearchHitTile(
                    hit: hit,
                    color: themeProvider.mainText,
                    onTap: () {
                      if (hit.code case final code?) {
                        controller.focusTerritory(code);
                      } else {
                        controller.focusFaction(hit.factionId!);
                        controller.showFaction(hit.factionId);
                      }
                      onPicked();
                    },
                  );
                },
              ),
      ),
    );
  }
}

class SearchHitTile extends StatelessWidget {
  const SearchHitTile({super.key, required this.hit, this.color, required this.onTap});

  final SearchHit hit;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final state = controller.state;
    final code = hit.code;
    final factionId = code == null ? hit.factionId! : state?.ownership[code]?.factionId ?? 0;
    final count = controller.owned[factionId]?.length ?? 0;
    return ListTile(
      dense: true,
      enabled: onTap != null,
      leading: Icon(code == null ? Icons.groups : Icons.crop_square, color: color),
      title: Text(
        code ?? factionLabel(state, factionId),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        code == null
            ? territoryCount(count)
            : factionId == 0
            ? 'No owner'
            : factionLabel(state, factionId),
        style: TextStyle(color: color),
      ),
      onTap: onTap,
    );
  }
}
