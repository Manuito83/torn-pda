import 'dart:ui';

import 'package:torn_pda/models/territory_map/map_dates.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/providers/settings_provider.dart';

const mapLinkScheme = 'tornpda';
const mapLinkHost = 'map';
const _webHosts = {'tornpda.com', 'www.tornpda.com'};

const layerLocks = 'locks';
const layerNames = 'names';
const layerCity = 'city';
const _allLayers = {layerLocks, layerNames, layerCity};

final _codePattern = RegExp(r'^[A-Z]{3}$');

const _sceneRange = (min: -8000.0, max: 20000.0);
const _extentRange = (min: 20.0, max: 30000.0);

class SharedMapView {
  const SharedMapView({
    required this.camera,
    this.view = MapView.normal,
    this.span = ActivitySpan.week,
    this.territory,
    this.warId,
    this.layers = const {},
  });

  // Visible area in scene units
  final Rect camera;
  final MapView view;

  // Only matters in the activity view
  final ActivitySpan span;
  final String? territory;
  final int? warId;
  final Set<String> layers;
}

String buildMapLink(SharedMapView view) {
  final center = view.camera.center;
  final params = <String, String>{
    'x': '${center.dx.round()}',
    'y': '${center.dy.round()}',
    'w': '${view.camera.width.round()}',
    'h': '${view.camera.height.round()}',
    if (view.view != MapView.normal) 'v': view.view.name,
    if (view.view == MapView.activity) 'span': view.span.name,
    if (view.territory != null) 't': view.territory!,
    if (view.warId != null) 'war': '${view.warId}',
    if (view.layers.isNotEmpty) 'l': (view.layers.toList()..sort()).join(','),
  };
  return Uri(scheme: 'https', host: 'tornpda.com', path: '/map/', queryParameters: params).toString();
}

bool _isMapLink(Uri uri) {
  if (uri.scheme == mapLinkScheme) return uri.host == mapLinkHost;
  return uri.scheme == 'https' && _webHosts.contains(uri.host) && (uri.path == '/map' || uri.path == '/map/');
}

// Null for a bad link
SharedMapView? readMapLink(String link) {
  final uri = Uri.tryParse(link.trim());
  if (uri == null || !_isMapLink(uri)) return null;
  final query = uri.queryParameters;

  double? number(String key, ({double min, double max}) range) {
    final value = double.tryParse(query[key] ?? '');
    return value != null && value >= range.min && value <= range.max ? value : null;
  }

  final x = number('x', _sceneRange);
  final y = number('y', _sceneRange);
  final w = number('w', _extentRange);
  final h = number('h', _extentRange);
  if (x == null || y == null || w == null || h == null) return null;

  final territory = query['t'];
  final war = int.tryParse(query['war'] ?? '');
  return SharedMapView(
    camera: Rect.fromCenter(center: Offset(x, y), width: w, height: h),
    view: MapView.values.asNameMap()[query['v']] ?? MapView.normal,
    span: ActivitySpan.values.asNameMap()[query['span']] ?? ActivitySpan.week,
    territory: territory != null && _codePattern.hasMatch(territory) ? territory : null,
    warId: war != null && war > 0 ? war : null,
    layers: {...(query['l'] ?? '').split(',').where(_allLayers.contains)},
  );
}

// Text sent along with the link
String mapShareMessage(SharedMapView view) =>
    'Torn PDA map${view.territory == null ? '' : ' (${view.territory})'}\n${buildMapLink(view)}';

// Torn time, whoever reads it
String mapPictureCaption({required DateTime now, DateTime? pastDay}) {
  const zone = TimeZoneSetting.tornTime;
  if (pastDay != null) return 'Map - as of ${mapDate(pastDay, zone)}';
  return 'Map - ${mapDate(now, zone, pattern: 'd MMM y HH:mm')} TCT';
}
