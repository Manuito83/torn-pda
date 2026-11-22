import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/city_heights.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';

const _accent = Color(0xFF78909C);

const cityHeightNames = {
  CityHeight.respect: 'Respect',
  CityHeight.size: 'Size',
  CityHeight.slots: 'Slots',
  CityHeight.held: 'Held',
  CityHeight.flat: 'Flat',
};

class _Segments<T> extends StatelessWidget {
  const _Segments({required this.values, required this.selected, required this.onPick});

  final Map<T, String> values;
  final T selected;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final MapEntry(key: value, value: label) in values.entries)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(value),
              child: Container(
                constraints: const BoxConstraints(minWidth: 34),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == selected ? _accent : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: value == selected ? Colors.black : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MapDimensionSwitch extends StatelessWidget {
  const MapDimensionSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final threeD = context.select<TerritoryMapController, bool>((c) => c.threeD);
    return _Segments<bool>(
      values: const {false: '2D', true: '3D'},
      selected: threeD,
      onPick: (value) {
        if (value && !threeD) countMapUse(map3dSwitchFeature);
        context.read<TerritoryMapController>().setThreeD(value);
      },
    );
  }
}

class CityHeightSwitch extends StatelessWidget {
  const CityHeightSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final height = context.select<TerritoryMapController, CityHeight>((c) => c.cityHeight);
    return _Segments<CityHeight>(
      values: cityHeightNames,
      selected: height,
      onPick: (value) {
        if (value == height) return;
        countMapUse(map3dHeightFeature(value));
        context.read<TerritoryMapController>().setCityHeight(value);
      },
    );
  }
}
