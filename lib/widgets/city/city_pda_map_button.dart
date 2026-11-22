import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/providers/city_pda_map_controller.dart';

class CityPdaMapButton extends StatelessWidget {
  const CityPdaMapButton({super.key, required this.map});

  final CityPdaMapController map;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange,
        side: const BorderSide(color: Colors.orange),
        minimumSize: const Size.fromHeight(40),
      ),
      icon: const Icon(Icons.map),
      label: const Text('Map', style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: map.open,
    );
    if (!map.active) return button;
    return Row(
      children: [
        Expanded(child: button),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.orange),
          onPressed: map.showTornMap,
          child: const Text("Torn's map"),
        ),
      ],
    );
  }
}
