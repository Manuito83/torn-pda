import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/alert_topics.dart';
import 'package:torn_pda/models/territory_map/city_heights.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/surroundings_quality.dart';

MapSetup _setup({
  MapOrigin origin = MapOrigin.menu,
  MapView view = MapView.normal,
  bool locks = false,
  bool? cityFinder,
  bool? citySites,
  bool alertsOn = false,
  Set<AlertKind> kinds = const {},
  LifeDensity? life,
  bool planes = false,
  CityHeight? threeD,
  SurroundingsQuality? quality,
}) => (
  origin: origin,
  view: view,
  names: false,
  strip: false,
  locks: locks,
  cityFinder: cityFinder,
  citySites: citySites,
  flightsButton: false,
  flatFlights: false,
  alertsOn: alertsOn,
  alertKinds: kinds,
  life: life,
  planes: planes,
  traffic: false,
  night: false,
  gunfire: false,
  police: false,
  threeD: threeD,
  quality: quality,
);

void main() {
  group('counts at open', () {
    test('origin and view always, layers only when on', () {
      expect(mapOpenFeatures(_setup()), ['map_open_menu', 'map_view_normal']);
      expect(mapOpenFeatures(_setup(origin: MapOrigin.wars, view: MapView.activity, locks: true)), [
        'map_open_wars',
        'map_view_activity',
        'map_layer_locks',
      ]);
    });

    test('city layers count only when on', () {
      final features = mapOpenFeatures(_setup(origin: MapOrigin.city, cityFinder: true, citySites: false));
      expect(features, ['map_open_city', 'map_view_normal', 'map_layer_city_finder']);
    });

    test('alert kinds count only with alerts on', () {
      const kinds = {AlertKind.racket, AlertKind.war};
      expect(mapOpenFeatures(_setup(kinds: kinds)), isNot(contains('map_alert_war')));
      expect(
        mapOpenFeatures(_setup(alertsOn: true, kinds: kinds)),
        containsAllInOrder(['map_alerts_on', 'map_alert_war', 'map_alert_racket']),
      );
    });

    test('city life switches count only with city life on', () {
      expect(mapOpenFeatures(_setup(planes: true)), isNot(contains('map_layer_planes')));
      expect(mapOpenFeatures(_setup(life: LifeDensity.high, planes: true)), [
        'map_open_menu',
        'map_view_normal',
        'map_layer_life',
        'map_life_high',
        'map_layer_planes',
      ]);
    });

    test('quality counts once known', () {
      expect(mapOpenFeatures(_setup()), isNot(contains(startsWith('map_quality_'))));
      expect(mapOpenFeatures(_setup(quality: SurroundingsQuality.light)), [
        'map_open_menu',
        'map_view_normal',
        'map_quality_light',
      ]);
    });

    test('every name that can come out is allowed', () {
      final all = <String>{};
      for (final origin in MapOrigin.values) {
        for (final (i, view) in MapView.values.indexed) {
          all.addAll(
            mapOpenFeatures((
              origin: origin,
              view: view,
              life: LifeDensity.values[i % LifeDensity.values.length],
              planes: true,
              traffic: true,
              night: true,
              gunfire: true,
              police: true,
              threeD: CityHeight.values[i % CityHeight.values.length],
              quality: SurroundingsQuality.values[i % SurroundingsQuality.values.length],
              names: true,
              strip: true,
              locks: true,
              cityFinder: true,
              citySites: true,
              flightsButton: true,
              flatFlights: true,
              alertsOn: true,
              alertKinds: AlertKind.values.toSet(),
            )),
          );
        }
      }
      all.addAll(MapFailure.values.map(mapFailureFeature));
      expect(territoryMapFeatures.containsAll(all), isTrue);
    });
  });

  group('user property', () {
    test('off beats everything, none before the first use', () {
      expect(mapUse({MapOrigin.menu}, disabled: true), 'off');
      expect(mapUse({}, disabled: false), 'none');
    });

    test('origins are joined in a fixed order', () {
      expect(mapUse({MapOrigin.menu}, disabled: false), 'menu');
      expect(mapUse({MapOrigin.wars, MapOrigin.menu, MapOrigin.city}, disabled: false), 'city-menu-wars');
    });

    test('saved origins ignore unknown names', () {
      expect(readMapOrigins(['city', 'gone', 'menu']), {MapOrigin.city, MapOrigin.menu});
    });
  });
}
