import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

import 'sample_data.dart';

// Trimmed from a real city.php read
const _page = '''
{"time": 1794060914,
 "owners": {"IFE": 7835, "RCD": 51387, "AAB": 0, "AFG": 0},
 "irradiated": ["AAB"],
 "rackets": {"IFE": {"name": "Bootleg Distillery I", "level": 1, "reward": "10x Bottle of Moonshine daily"},
             "RCD": {"name": "Street Surgeon IV", "level": 4, "reward": "40x Melatonin daily"}},
 "sites": [{"title": "AUCTION HOUSE", "link": "amarket.php#itemtab=weapons&start=0", "x": 2848.5, "y": 1022}],
 "items": [{"id": 380, "lat": 21.892084251561464, "lng": -28.212890625000004}]}''';

void main() {
  final server = sampleState();
  final page = parseCityPageData(_page);

  test('parse', () {
    expect(page.owners['RCD'], 51387);
    expect(page.rackets['RCD']!.level, 4);
    expect(page.items.single.id, 380);
    expect(page.sites.single.url, 'https://www.torn.com/amarket.php#itemtab=weapons&start=0');
    expect(siteIcon(page.sites.single.link), 'images/icons/map/auction_house.png');
    expect(siteIcon('newplace.php'), isNull);
  });

  test('missing sections', () {
    final empty = parseCityPageData('{"time": 1}');
    expect(empty.owners, isEmpty);
    expect(empty.items, isEmpty);
  });

  test('page newer than the server', () {
    final state = pageStateFor(server, page)!;
    expect(state.ownership['IFE']!.acquiredAt, server.ownership['IFE']!.acquiredAt);
    expect(state.ownership['RCD']!.factionId, 51387);
    expect(state.ownership['RCD']!.acquiredAt, isNull);
    expect(state.ownership['AAB']!.irradiated, isTrue);
    expect(state.ownership['AFG']!.irradiated, isFalse);
    expect(state.ownership['BAA']!.factionId, server.ownership['BAA']!.factionId);
    expect(state.ownership.length, server.ownership.length);

    expect(state.rackets.keys, {'IFE', 'RCD'});
    expect(state.rackets['IFE']!.changedAt, server.rackets['IFE']!.changedAt);
    expect(state.rackets['RCD']!.changedAt, page.time);
    expect(state.rackets['RCD']!.factionId, 51387);

    expect(state.wars, same(server.wars));
    expect(dataTime(state), dataTime(server));
  });

  test('keeps revision 2 fields from the server', () {
    const json = '''
    {"format": 1, "revision": 2, "generated_at": 1000, "territories_version": 1, "read_at": {}, "ownership": {},
     "wars": [],
     "recent_wars": [{"id": 46801, "territory": "QFA", "start": 50, "ended_at": 800, "result": "success_assault",
                      "aggressor": 36811, "defender": 9032, "score": 300000, "target": 300000}],
     "rackets": {
       "IFE": {"faction_id": 7835, "name": "Bootleg Distillery I", "level": 1, "reward": "10x Bottle of Moonshine daily",
               "changed_at": 500, "reward_item": {"type": "item", "id": 206, "name": "Bottle of Moonshine",
               "quantity": 10, "price": 5500, "priced_at": "2026-11-07"}},
       "RCD": {"faction_id": 8315, "name": "Money Launderer III", "level": 3, "reward": "\$40,000,000 daily",
               "changed_at": 500, "reward_item": {"type": "money", "id": 0, "name": "Money",
               "quantity": 40000000, "price": 1, "priced_at": "2026-11-07"}}},
     "factions": {}, "bombs": []}''';
    final state = pageStateFor(parseMapState(json), page)!;
    expect(state.revision, 2);
    expect(state.recentWars.single.id, 46801);
    expect(state.rackets['IFE']!.rewardItem!.id, 206);
    expect(state.rackets['RCD']!.rewardItem, isNull);
  });

  test('server newer than the page', () {
    final old = parseCityPageData(_page.replaceFirst('1794060914', '1793820000'));
    expect(pageStateFor(server, old), isNull);
  });

  test('pick results', () {
    final found = readPickResult({'status': 'found', 'text': 'You found a Small First Aid Kit'});
    expect(found.gone, isTrue);
    expect(found.picked, isTrue);
    expect(found.message, 'You found a Small First Aid Kit');
    expect(readPickResult({'status': 'gone'}).gone, isTrue);
    expect(readPickResult({'status': 'gone'}).picked, isFalse);
    expect(readPickResult({'status': 'error', 'text': 'Error! Something went wrong'}).gone, isFalse);
    expect(readPickResult(null).gone, isFalse);
  });

  test('finder prices and value tiers', () {
    final prices = cityItemPrices([
      Item(id: '380', name: 'Tavor TAR-21', marketValue: 1500000),
      Item(id: 'x', name: 'Broken', marketValue: 5),
    ]);
    expect(prices.keys, [380]);

    final priced = withItemPrices(page, prices);
    expect(priced.items.single.price!.name, 'Tavor TAR-21');
    expect(priced.items.single.point, page.items.single.point);
    expect(cityValueTier(priced.items.single), 3);
    expect(cityValueTier(page.items.single), 0);

    CityItem worth(int value) => CityItem(id: 1, lat: 0, lng: 0, price: (name: '', value: value));
    expect(cityValueTier(worth(9999)), 0);
    expect(cityValueTier(worth(10000)), 1);
    expect(cityValueTier(worth(20000000)), 4);
  });

  test('the finder keeps the map order and skips ids the API lacks', () {
    Item item(String id) => Item(name: id)..id = id;
    final found = cityFinderItems([item('1'), item('2'), item('3')], ['3', '9', '1', '3']);
    expect(found.map((i) => i.id), ['3', '1', '3']);
  });

  test('no server data yet', () {
    final state = pageStateFor(null, page)!;
    expect(state.ownership.keys, {'IFE', 'RCD', 'AAB', 'AFG'});
    expect(state.factions, isEmpty);
    expect(dataTime(state), page.time);
  });
}
