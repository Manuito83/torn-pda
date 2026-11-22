import 'dart:convert';
import 'dart:ui';

import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/territory_map/map_coordinates.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

class CitySite {
  CitySite({required this.title, required this.link, required this.point});

  final String title;
  final String link;
  final Offset point;

  String get url => Uri.parse('https://www.torn.com/').resolve(link).toString();
}

// Frame closes, Torn goes there
class CityTornLink {
  CityTornLink(this.url);

  final String url;
}

typedef CityItemPrice = ({String name, int value});

class CityItem {
  CityItem({required this.id, required this.lat, required this.lng, this.price}) : point = latLngToMap(lat, lng);

  final int id;
  final double lat;
  final double lng;
  final Offset point;
  final CityItemPrice? price;
}

class CityRacket {
  CityRacket({required this.name, required this.level, required this.reward});

  final String name;
  final int level;
  final String reward;
}

// Read from the visible city.php
class CityPageData {
  CityPageData({
    required this.time,
    required this.owners,
    required this.irradiated,
    required this.rackets,
    required this.sites,
    required this.items,
  });

  final DateTime time;
  final Map<String, int> owners;
  final Set<String> irradiated;
  final Map<String, CityRacket> rackets;
  final List<CitySite> sites;
  final List<CityItem> items;
}

CityPageData parseCityPageData(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  double number(Object? value) => (value as num).toDouble();
  return CityPageData(
    time: DateTime.fromMillisecondsSinceEpoch((data['time'] as int) * 1000, isUtc: true),
    owners: (data['owners'] as Map<String, dynamic>? ?? {}).cast<String, int>(),
    irradiated: {...(data['irradiated'] as List<dynamic>? ?? []).cast<String>()},
    rackets: {
      for (final e in (data['rackets'] as Map<String, dynamic>? ?? {}).entries)
        e.key: CityRacket(
          name: e.value['name'] as String,
          level: e.value['level'] as int,
          reward: e.value['reward'] as String,
        ),
    },
    sites: [
      for (final s in (data['sites'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>())
        CitySite(title: s['title'] as String, link: s['link'] as String, point: Offset(number(s['x']), number(s['y']))),
    ],
    items: [
      for (final i in (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>())
        CityItem(id: i['id'] as int, lat: number(i['lat']), lng: number(i['lng'])),
    ],
  );
}

// Names and values the City Finder fetched
Map<int, CityItemPrice> cityItemPrices(Iterable<Item> finder) => {
  for (final item in finder)
    if (int.tryParse(item.id ?? '') case final id?) id: (name: item.name ?? '', value: item.marketValue ?? 0),
};

// Ids missing from the API are skipped
List<Item> cityFinderItems(Iterable<Item> all, Iterable<String> onMap) {
  final byId = {for (final item in all) item.id: item};
  return [
    for (final id in onMap)
      if (byId[id] case final item?) item,
  ];
}

CityPageData withItemPrices(CityPageData page, Map<int, CityItemPrice> prices) {
  return CityPageData(
    time: page.time,
    owners: page.owners,
    irradiated: page.irradiated,
    rackets: page.rackets,
    sites: page.sites,
    items: [
      for (final item in page.items) CityItem(id: item.id, lat: item.lat, lng: item.lng, price: prices[item.id]),
    ],
  );
}

const _valueSteps = [10000, 100000, 1000000, 10000000];

// Unknown value counts as 0
int cityValueTier(CityItem item) {
  final value = item.price?.value ?? 0;
  return _valueSteps.where((step) => value >= step).length;
}

// Null when the server data is newer
MapState? pageStateFor(MapState? server, CityPageData page) {
  if (server != null && !page.time.isAfter(dataTime(server))) return null;
  final time = page.time;

  final ownership = {...?server?.ownership};
  page.owners.forEach((code, factionId) {
    final before = ownership[code];
    ownership[code] = Ownership(
      factionId: factionId,
      acquiredAt: before?.factionId == factionId ? before!.acquiredAt : null,
      irradiated: page.irradiated.contains(code),
    );
  });

  final rackets = <String, Racket>{};
  page.rackets.forEach((code, racket) {
    final before = server?.rackets[code];
    final same = before != null && before.name == racket.name;
    rackets[code] = Racket(
      territory: code,
      factionId: ownership[code]?.factionId ?? 0,
      name: racket.name,
      level: racket.level,
      reward: racket.reward,
      changedAt: same ? before.changedAt : time,
      rewardItem: same ? before.rewardItem : null,
    );
  });

  return MapState(
    generatedAt: server?.generatedAt ?? time,
    territoriesVersion: server?.territoriesVersion ?? 0,
    readAt: {...?server?.readAt, 'ownership': time, 'rackets': time},
    ownership: ownership,
    wars: server?.wars ?? const [],
    rackets: rackets,
    factions: server?.factions ?? const {},
    bombs: server?.bombs ?? const [],
    revision: server?.revision ?? 1,
    recentWars: server?.recentWars ?? const [],
  );
}

// Gone: drop it from the PDA map
({bool gone, bool picked, String message}) readPickResult(Object? value) {
  final result = value is Map ? value : const {};
  final text = result['text']?.toString() ?? '';
  return switch (result['status']) {
    'found' => (gone: true, picked: true, message: text.isEmpty ? 'Item picked up' : text),
    'gone' => (gone: true, picked: false, message: 'That item is no longer there'),
    'sent' => (gone: false, picked: false, message: 'Torn is already picking that item up'),
    'timeout' => (gone: false, picked: false, message: "Torn didn't answer, check its map"),
    _ => (gone: false, picked: false, message: text.isEmpty ? 'Torn could not pick it up' : text),
  };
}

const _siteIcons = {
  'page.php?sid=ItemMarket': 'item_market',
  'travelagency.php': 'travel_agency',
  'shops.php?step=bitsnbobs': 'bits_bobs',
  'pmarket.php': 'points_market',
  'dump.php': 'dump',
  'bigalgunshop.php': 'gun_shop',
  'estateagents.php': 'estate_agents',
  'shops.php?step=candy': 'sweet_shop',
  'bank.php': 'bank',
  'points.php': 'points_building',
  'casino.php': 'casino',
  'church.php': 'church',
  'loan.php': 'loan_shark',
  'page.php?sid=racing': 'race_track',
  'shops.php?step=docks': 'docks',
  'page.php?sid=stocks': 'stock_exchange',
  'shops.php?step=pawnshop': 'pawn_shop',
  'museum.php': 'museum',
  'shops.php?step=super': 'super_store',
  'amarket.php': 'auction_house',
  'donator.php': 'donator_house',
  'shops.php?step=clothes': 'tc_clothing',
  'shops.php?step=pharmacy': 'pharmacy',
  'gym.php': 'gym',
  'shops.php?step=jewelry': 'jewelry_store',
  'properties.php': 'property',
  'shops.php?step=cyberforce': 'cyber_force',
  'shops.php?step=postoffice': 'post_office',
  'education.php': 'education',
  'citystats.php': 'city_hall',
  'jailview.php': 'jail',
  'staff.php': 'staff',
  'fans.php': 'community_center',
  'hospitalview.php': 'hospital',
  'page.php?sid=missions': 'missions',
  'messageinc.php': 'msg_inc',
  'wiki': 'visitor_center',
  'committee.php': 'committee',
  'shops.php?step=nikeh': 'sports_shop',
  'archives.php': 'chronicle_archives',
  'shops.php?step=printstore': 'print_store',
};

String? siteIcon(String link) {
  final name = _siteIcons[link.split('#').first];
  return name == null ? null : 'images/icons/map/$name.png';
}
