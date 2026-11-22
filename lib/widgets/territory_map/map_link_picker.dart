import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_pictures.dart';
import 'package:torn_pda/models/territory_map/map_share.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_search.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_share_controller.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/territory_map_search.dart';

const _timeout = Duration(seconds: 15);

// Null when nothing is picked
Future<String?> showMapLinkPicker(BuildContext context) => showModalBottomSheet<String>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const _MapLinkPicker(),
);

class _MapLinkPicker extends StatefulWidget {
  const _MapLinkPicker();

  @override
  State<_MapLinkPicker> createState() => _MapLinkPickerState();
}

class _MapLinkPickerState extends State<_MapLinkPicker> {
  final TextEditingController _query = TextEditingController();
  late final TerritoryMapController _map;
  SharedMapView? _current;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _map = context.read<TerritoryMapController>();
    _current = context.read<TerritoryShareController>().capture(_map);
    _loading = _map.territories == null || _map.state == null;
    if (_loading) _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_failed) {
      setState(() {
        _failed = false;
        _loading = true;
      });
    }
    try {
      await _map.openWithState(this, myFactionId: UserHelper.factionId, timeout: _timeout);
    } catch (e) {
      debugPrint('territory map: link picker failed: $e');
    } finally {
      _map.close(this);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = _map.territories == null || _map.state == null;
    });
  }

  SharedMapView? _faction(int factionId, MapState state) {
    final file = _map.territories!;
    final picture = factionPicture(factionId, state, file.territories, minSize: smallestPicture(file.bounds));
    return picture == null ? null : SharedMapView(camera: picture.area);
  }

  void _pick(SharedMapView view) => Navigator.of(context).pop(buildMapLink(view));

  // Null for a faction with nothing
  VoidCallback? _onHit(SearchHit hit, MapState state) {
    final code = hit.code;
    final file = _map.territories!;
    final bounds = code == null ? null : file.territories[code]?.bounds;
    final view = code == null
        ? _faction(hit.factionId!, state)
        : bounds == null
        ? null
        : SharedMapView(
            camera: roomAround(bounds, minSize: smallestPicture(file.bounds)),
            territory: code,
          );
    return view == null ? null : () => _pick(view);
  }

  Widget _option(IconData icon, String title, String? subtitle, SharedMapView view) => ListTile(
    dense: true,
    leading: Icon(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: subtitle == null ? null : Text(subtitle),
    onTap: () => _pick(view),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = _map.territories;
    final state = _map.state;
    final query = _query.text.trim();
    final myFaction = UserHelper.factionId;
    final mine = state == null || myFaction == 0 ? null : _faction(myFaction, state);
    final current = _current;

    Widget body;
    if (_loading) {
      body = const Padding(padding: EdgeInsets.all(12), child: MapLoadNote(loading: true));
    } else if (_failed || file == null || state == null) {
      body = Center(
        child: MapLoadNote(error: 'Map not available', onRetry: _load),
      );
    } else if (query.isEmpty) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mine != null) _option(Icons.shield_outlined, 'My faction', factionLabel(state, myFaction), mine),
          if (current != null) _option(Icons.crop_free_rounded, 'Current map view', null, current),
        ],
      );
    } else {
      final hits = searchMap(query, file.territories.keys, state.factions, _map.owned);
      body = hits.isEmpty
          ? const Padding(padding: EdgeInsets.all(16), child: Text('Nothing found'))
          : Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [for (final hit in hits) SearchHitTile(hit: hit, onTap: _onHit(hit, state))],
              ),
            );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Territory map', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  enabled: !_loading && !_failed,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Territory, faction or tag',
                  ),
                ),
                const SizedBox(height: 4),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
