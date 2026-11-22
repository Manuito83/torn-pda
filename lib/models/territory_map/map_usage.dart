import 'package:torn_pda/models/territory_map/alert_topics.dart';
import 'package:torn_pda/models/territory_map/city_heights.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/surroundings_quality.dart';

enum MapOrigin { menu, city, wars }

enum MapFailure { state, history, wars, prices, flights }

const mapFlightsOpenFeature = 'map_flights_open';
const mapFlightsTapFeature = 'map_flights_tap';
const mapFlightsShareOnFeature = 'map_flights_share_on';
const mapFlightsShareOffFeature = 'map_flights_share_off';
const mapFlightsButtonFailFeature = 'map_fail_flights_button';
const mapHistoryFeature = 'map_history';
const mapTimelapseFeature = 'map_timelapse';
const mapCityPickFeature = 'map_city_pick';
const mapSharePictureFeature = 'map_share_picture';
const mapShareLinkFeature = 'map_share_link';
const mapShareVideoFeature = 'map_share_video';
const mapPlaneJokeFeature = 'map_plane_joke';
const map3dSwitchFeature = 'map_3d_switch';
const mapChatCardFeature = 'map_chat_card';
const mapChatInsertFeature = 'map_chat_insert';
const mapShareFactionChatFeature = 'map_share_faction_chat';
const mapFlightsDmFeature = 'map_flights_dm';
const mapChatFactionMinimapFeature = 'map_chat_faction_minimap';
const mapCityFinderOffFeature = 'map_city_finder_off';

String map3dHeightFeature(CityHeight height) => 'map_3d_${height.name}';

// Only these names are counted
const territoryMapFeatures = {
  'map_open_menu',
  'map_open_city',
  'map_open_wars',
  'map_view_normal',
  'map_view_rackets',
  'map_view_sector',
  'map_view_respect',
  'map_view_size',
  'map_view_war',
  'map_view_irradiated',
  'map_view_activity',
  'map_layer_names',
  'map_layer_strip',
  'map_layer_locks',
  'map_layer_city_finder',
  'map_layer_city_sites',
  'map_layer_flights_button',
  'map_layer_flights_flat',
  'map_layer_life',
  'map_layer_planes',
  'map_layer_traffic',
  'map_layer_night',
  'map_layer_gunfire',
  'map_layer_police',
  'map_life_low',
  'map_life_normal',
  'map_life_high',
  'map_quality_full',
  'map_quality_light',
  'map_quality_minimal',
  'map_3d',
  map3dSwitchFeature,
  'map_3d_respect',
  'map_3d_size',
  'map_3d_slots',
  'map_3d_held',
  'map_3d_flat',
  mapPlaneJokeFeature,
  mapFlightsOpenFeature,
  mapFlightsTapFeature,
  mapFlightsShareOnFeature,
  mapFlightsShareOffFeature,
  mapFlightsButtonFailFeature,
  'map_alerts_on',
  'map_alert_war',
  'map_alert_ending',
  'map_alert_owner',
  'map_alert_racket',
  mapHistoryFeature,
  mapTimelapseFeature,
  mapCityPickFeature,
  mapSharePictureFeature,
  mapShareLinkFeature,
  mapShareVideoFeature,
  mapShareFactionChatFeature,
  mapChatCardFeature,
  mapChatInsertFeature,
  mapChatFactionMinimapFeature,
  mapFlightsDmFeature,
  mapCityFinderOffFeature,
  'map_fail_state',
  'map_fail_history',
  'map_fail_wars',
  'map_fail_prices',
  'map_fail_flights',
};

String mapFailureFeature(MapFailure failure) => 'map_fail_${failure.name}';

// City options are null outside city.php
typedef MapSetup = ({
  MapOrigin origin,
  MapView view,
  bool names,
  bool strip,
  bool locks,
  bool? cityFinder,
  bool? citySites,
  bool flightsButton,
  bool flatFlights,
  bool alertsOn,
  Set<AlertKind> alertKinds,
  // Null with city life off
  LifeDensity? life,
  bool planes,
  bool traffic,
  bool night,
  bool gunfire,
  bool police,
  // Null in 2D
  CityHeight? threeD,
  // Null until the surroundings load
  SurroundingsQuality? quality,
});

// What to count when the map opens
List<String> mapOpenFeatures(MapSetup setup) => [
  'map_open_${setup.origin.name}',
  'map_view_${setup.view.name}',
  if (setup.quality case final quality?) 'map_quality_${quality.name}',
  if (setup.names) 'map_layer_names',
  if (setup.strip) 'map_layer_strip',
  if (setup.locks) 'map_layer_locks',
  if (setup.cityFinder == true) 'map_layer_city_finder',
  if (setup.citySites == true) 'map_layer_city_sites',
  if (setup.flightsButton) 'map_layer_flights_button',
  if (setup.flatFlights) 'map_layer_flights_flat',
  if (setup.life case final density?) ...[
    'map_layer_life',
    'map_life_${density.name}',
    if (setup.planes) 'map_layer_planes',
    if (setup.traffic) 'map_layer_traffic',
    if (setup.night) 'map_layer_night',
    if (setup.gunfire) 'map_layer_gunfire',
    if (setup.police) 'map_layer_police',
  ],
  if (setup.threeD case final height?) ...['map_3d', map3dHeightFeature(height)],
  if (setup.alertsOn) ...[
    'map_alerts_on',
    for (final kind in AlertKind.values)
      if (setup.alertKinds.contains(kind)) 'map_alert_${kind.name}',
  ],
];

// User property map_use
String mapUse(Set<MapOrigin> used, {required bool disabled}) {
  if (disabled) return 'off';
  if (used.isEmpty) return 'none';
  return (used.map((origin) => origin.name).toList()..sort()).join('-');
}

// UTC day as 20261108
int mapUsageDay(DateTime time) {
  final utc = time.toUtc();
  return utc.year * 10000 + utc.month * 100 + utc.day;
}

Set<MapOrigin> readMapOrigins(Iterable<String> saved) {
  final known = MapOrigin.values.asNameMap();
  return {for (final name in saved) ?known[name]};
}
