import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/inventory/inventory_v2_model.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/inventory_provider.dart';

/// Tests for [InventoryProvider] with the API call injected.

InventoryV2Item _item({required int id, int amount = 1, String? uid, bool factionOwned = false}) {
  return InventoryV2Item(
    id: id,
    amount: amount,
    equipped: false,
    name: "Item $id",
    factionOwned: factionOwned,
    uid: uid,
  );
}

InventoryV2DisplayItem _displayItem({required int id, int quantity = 1}) {
  return InventoryV2DisplayItem(id: id, quantity: quantity);
}

int get _nowSeconds => DateTime.now().millisecondsSinceEpoch ~/ 1000;

class _FakeApi {
  _FakeApi(this.responses, {this.display});

  /// Category to the payload it answers with, null meaning a failed call
  final Map<String, InventoryV2Category?> responses;

  /// What the display case answers with when a call asks for it, null meaning it fails
  List<InventoryV2DisplayItem>? display;

  final Map<String, int> calls = {};
  final List<String> displayCalls = [];
  final Map<String, Completer<void>> gates = {};

  Future<InventoryV2Category?> fetch(String category, {required bool withDisplay}) async {
    calls[category] = (calls[category] ?? 0) + 1;
    if (withDisplay) displayCalls.add(category);
    final gate = gates[category];
    if (gate != null) await gate.future;
    if (!responses.containsKey(category)) throw StateError("no fixture for $category");
    final InventoryV2Category? response = responses[category];
    if (response == null) return null;
    return InventoryV2Category(
      items: response.items,
      timestamp: response.timestamp,
      display: withDisplay ? display : null,
    );
  }
}

class _FakeStore {
  _FakeStore([this.value = ""]);

  String value;
  int writes = 0;
  int reads = 0;

  Future<String> read() async {
    reads++;
    return value;
  }

  Future<void> write(String raw) async {
    value = raw;
    writes++;
  }
}

/// Every provider a test builds gets a store of its own, so nothing reaches the real preferences
InventoryProvider _newProvider({InventoryCategoryFetcher? fetcher, DateTime Function()? now, _FakeStore? store}) {
  final _FakeStore backing = store ?? _FakeStore();
  return InventoryProvider(fetcher: fetcher, now: now, readStore: backing.read, writeStore: backing.write);
}

void main() {
  group('ensure and cache', () {
    test('calls the API once and serves the second ensure from cache', () async {
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
      });
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical"});
      await provider.ensureFresh({"Medical"});

      expect(api.calls["Medical"], 1);
      expect(provider.loaded("Medical"), isTrue);
      expect(provider.failed("Medical"), isFalse);
      expect(provider.quantity(739, "Medical"), 50);
    });

    test('refetches a category whose Torn timestamp is older than an hour', () async {
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds - 3601),
      });
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical"});
      expect(provider.isFresh("Medical"), isFalse);

      await provider.ensureFresh({"Medical"});
      expect(api.calls["Medical"], 2);
    });

    test('two simultaneous calls share a single request', () async {
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
      });
      api.gates["Medical"] = Completer<void>();
      final provider = _newProvider(fetcher: api.fetch);

      final first = provider.ensureFresh({"Medical"});
      final second = provider.ensureFresh({"Medical"});
      api.gates["Medical"]!.complete();
      await Future.wait([first, second]);

      expect(api.calls["Medical"], 1);
      expect(provider.quantity(739, "Medical"), 50);
    });
  });

  group('quantity', () {
    test('adds stacked rows, unique rows and faction owned ones', () async {
      final api = _FakeApi({
        "Primary": InventoryV2Category(
          items: [
            _item(id: 61, uid: "9001"),
            _item(id: 61, uid: "9002"),
            _item(id: 61, uid: "9003", factionOwned: true),
            _item(id: 62, uid: "9004"),
          ],
          timestamp: _nowSeconds,
        ),
        "Medical": InventoryV2Category(
          items: [_item(id: 739, amount: 50), _item(id: 66, amount: 3, factionOwned: true)],
          timestamp: _nowSeconds,
        ),
      });
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Primary", "Medical"});

      expect(provider.quantity(61, "Primary"), 3);
      expect(provider.quantity(62, "Primary"), 1);
      expect(provider.quantity(739, "Medical"), 50);
      expect(provider.quantity(66, "Medical"), 3);
    });

    test('returns null while the category is not loaded', () async {
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
        "Drug": InventoryV2Category(items: const [], timestamp: _nowSeconds),
      });
      final provider = _newProvider(fetcher: api.fetch);

      expect(provider.quantity(739, "Medical"), isNull);
      await provider.ensureFresh({"Medical"});
      expect(provider.quantity(197, "Drug"), isNull);
    });

    test('returns zero for a loaded category that does not hold the item', () async {
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
        "Drug": InventoryV2Category(items: const [], timestamp: _nowSeconds),
      });
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical", "Drug"});

      expect(provider.quantity(4, "Medical"), 0);
      expect(provider.quantity(197, "Drug"), 0);
    });

    test('only counts the category asked for', () async {
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
        "Drug": InventoryV2Category(items: const [], timestamp: _nowSeconds),
      });
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical", "Drug"});

      expect(provider.quantity(739, "Drug"), 0);
      expect(provider.quantity(739, "Medical"), 50);
    });

    test('clear drops the cache', () async {
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
      });
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical"});
      provider.clear();

      expect(provider.loaded("Medical"), isFalse);
      expect(provider.quantity(739, "Medical"), isNull);
    });
  });

  group('failures', () {
    test('a failed category does not affect the others', () async {
      final api = _FakeApi({
        "Medical": null,
        "Drug": InventoryV2Category(items: [_item(id: 197, amount: 2)], timestamp: _nowSeconds),
      });
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical", "Drug"});

      expect(provider.failed("Medical"), isTrue);
      expect(provider.loaded("Medical"), isFalse);
      expect(provider.loaded("Drug"), isTrue);
      expect(provider.quantity(739, "Medical"), isNull);
      expect(provider.quantity(197, "Drug"), 2);
    });

    test('a throwing category is marked as failed and retried on the next call', () async {
      final api = _FakeApi({"Drug": InventoryV2Category(items: const [], timestamp: _nowSeconds)});
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Melee"});
      expect(provider.failed("Melee"), isTrue);

      await provider.ensureFresh({"Melee"});
      expect(api.calls["Melee"], 2);
    });

    test('a failed category is retried while the fresh ones are left alone', () async {
      final int seconds = _nowSeconds;
      final api = _FakeApi({"Medical": null, "Drug": InventoryV2Category(items: const [], timestamp: seconds)});
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical", "Drug"});
      expect(api.calls["Medical"], 1);
      expect(api.calls["Drug"], 1);
      expect(provider.failed("Medical"), isTrue);

      api.responses["Medical"] = InventoryV2Category(items: [_item(id: 1, amount: 3)], timestamp: seconds);
      await provider.ensureFresh({"Medical", "Drug"});

      expect(api.calls["Medical"], 2);
      expect(api.calls["Drug"], 1);
      expect(provider.failed("Medical"), isFalse);
      expect(provider.quantity(1, "Medical"), 3);
    });
  });

  group('display case', () {
    test('adds the display case to the inventory quantity', () async {
      final api = _FakeApi(
        {
          "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
          "Drug": InventoryV2Category(items: const [], timestamp: _nowSeconds),
        },
        display: [
          _displayItem(id: 739, quantity: 3),
          _displayItem(id: 4, quantity: 2),
          _displayItem(id: 197, quantity: 6),
        ],
      );
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical", "Drug"});

      expect(provider.quantity(739, "Medical"), 53);
      expect(provider.quantity(4, "Medical"), 2);
      expect(provider.quantity(5, "Medical"), 0);
      expect(provider.quantity(197, "Drug"), 6);
    });

    test('is asked on the first call of a batch and not on the following ones', () async {
      final categories = {"Medical", "Drug", "Candy", "Alcohol", "Flower"};
      final api = _FakeApi({
        for (final category in categories) category: InventoryV2Category(items: const [], timestamp: _nowSeconds),
      }, display: const []);
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh(categories);

      expect(api.calls.length, 5);
      expect(api.displayCalls, ["Medical"]);
    });

    test('is not asked twice while the first call is still in flight', () async {
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: const [], timestamp: _nowSeconds),
        "Drug": InventoryV2Category(items: const [], timestamp: _nowSeconds),
      }, display: const []);
      api.gates["Medical"] = Completer<void>();
      final provider = _newProvider(fetcher: api.fetch);

      final first = provider.ensureFresh({"Medical"});
      final second = provider.ensureFresh({"Drug"});
      api.gates["Medical"]!.complete();
      await Future.wait([first, second]);

      expect(api.displayCalls, ["Medical"]);
    });

    test('is asked again only once it is an hour old', () async {
      DateTime now = DateTime(2026, 9, 21, 12);
      final api = _FakeApi(
        {
          "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
          "Drug": InventoryV2Category(items: const [], timestamp: _nowSeconds),
          "Candy": InventoryV2Category(items: const [], timestamp: _nowSeconds),
          "Alcohol": InventoryV2Category(items: const [], timestamp: _nowSeconds),
        },
        display: [_displayItem(id: 739, quantity: 3)],
      );
      final provider = _newProvider(fetcher: api.fetch, now: () => now);

      await provider.ensureFresh({"Medical"});
      expect(provider.quantity(739, "Medical"), 53);

      api.display = [_displayItem(id: 739, quantity: 5)];
      now = now.add(const Duration(minutes: 59, seconds: 59));
      await provider.ensureFresh({"Drug"});
      expect(api.displayCalls, ["Medical"]);
      expect(provider.quantity(739, "Medical"), 53);

      now = now.add(const Duration(seconds: 1));
      await provider.ensureFresh({"Candy"});
      expect(api.displayCalls, ["Medical", "Candy"]);
      expect(provider.quantity(739, "Medical"), 55);

      await provider.ensureFresh({"Alcohol"});
      expect(api.displayCalls, ["Medical", "Candy"]);
    });

    test('a display case that fails does not invalidate the category and is asked again next batch', () async {
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
        "Drug": InventoryV2Category(items: const [], timestamp: _nowSeconds),
      });
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical"});
      expect(provider.loaded("Medical"), isTrue);
      expect(provider.failed("Medical"), isFalse);
      expect(provider.quantity(739, "Medical"), 50);

      api.display = [_displayItem(id: 739, quantity: 3)];
      await provider.ensureFresh({"Drug"});
      expect(api.displayCalls, ["Medical", "Drug"]);
      expect(provider.quantity(739, "Medical"), 53);
    });

    test('a failed category call does not leave the display case blocked', () async {
      final api = _FakeApi(
        {"Medical": null, "Drug": InventoryV2Category(items: const [], timestamp: _nowSeconds)},
        display: [_displayItem(id: 197, quantity: 2)],
      );
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical"});
      await provider.ensureFresh({"Drug"});

      expect(api.displayCalls, ["Medical", "Drug"]);
      expect(provider.quantity(197, "Drug"), 2);
    });

    test('clear drops the display case', () async {
      final api = _FakeApi(
        {
          "Medical": InventoryV2Category(items: [_item(id: 739, amount: 50)], timestamp: _nowSeconds),
        },
        display: [_displayItem(id: 739, quantity: 3)],
      );
      final provider = _newProvider(fetcher: api.fetch);

      await provider.ensureFresh({"Medical"});
      provider.clear();
      api.display = null;
      await provider.ensureFresh({"Medical"});

      expect(api.displayCalls, ["Medical", "Medical"]);
      expect(provider.quantity(739, "Medical"), 50);
    });
  });

  group('freshUntil and nextRefresh', () {
    test('an hour after the Torn timestamp, not after the call', () async {
      DateTime now = DateTime(2026, 9, 20, 12);
      // Torn generated this payload ten minutes before we asked for it
      final int tornTimestamp = now.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000;
      final api = _FakeApi({"Medical": InventoryV2Category(items: const [], timestamp: tornTimestamp)});
      final provider = _newProvider(fetcher: api.fetch, now: () => now);

      await provider.ensureFresh({"Medical"});
      expect(provider.freshUntil("Medical"), DateTime.fromMillisecondsSinceEpoch((tornTimestamp + 3600) * 1000));

      now = now.add(const Duration(minutes: 49, seconds: 59));
      expect(provider.isFresh("Medical"), isTrue);
      now = now.add(const Duration(seconds: 1));
      expect(provider.isFresh("Medical"), isFalse);
    });

    test('is null while the category is not loaded', () {
      final provider = _newProvider(fetcher: _FakeApi({}).fetch);
      expect(provider.freshUntil("Medical"), isNull);
      expect(provider.nextRefresh({"Medical"}), isNull);
    });

    test('nextRefresh returns the earliest of the loaded categories and ignores the rest', () async {
      final DateTime now = DateTime(2026, 9, 20, 12);
      final int seconds = now.millisecondsSinceEpoch ~/ 1000;
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: const [], timestamp: seconds - 1800),
        "Drug": InventoryV2Category(items: const [], timestamp: seconds - 600),
        "Candy": null,
      });
      final provider = _newProvider(fetcher: api.fetch, now: () => now);

      await provider.ensureFresh({"Medical", "Drug", "Candy"});

      // Medical was generated first, so it is the first one able to bring something new
      expect(provider.nextRefresh({"Medical", "Drug", "Candy"}), provider.freshUntil("Medical"));
      expect(provider.nextRefresh({"Drug", "Candy"}), provider.freshUntil("Drug"));
      expect(provider.nextRefresh({"Candy"}), isNull);
    });
  });

  group('stored cache', () {
    // dispose flushes the write that is waiting for its debounce
    Future<void> flush(InventoryProvider provider) async {
      provider.dispose();
      await pumpEventQueue();
    }

    test('saves what it loaded and a new provider serves it without calling the API', () async {
      final store = _FakeStore();
      final int seconds = _nowSeconds;
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 1, amount: 5), _item(id: 2)], timestamp: seconds),
      });

      final provider = _newProvider(fetcher: api.fetch, store: store);
      await provider.ensureFresh({"Medical"});
      await flush(provider);
      expect(store.value, isNotEmpty);

      final freshApi = _FakeApi({"Medical": null});
      final restored = _newProvider(fetcher: freshApi.fetch, store: store);
      await restored.restored;

      expect(restored.loaded("Medical"), isTrue);
      expect(restored.isFresh("Medical"), isTrue);
      expect(restored.quantity(1, "Medical"), 5);
      expect(restored.quantity(2, "Medical"), 1);

      await restored.ensureFresh({"Medical"});
      expect(freshApi.calls["Medical"], isNull);
    });

    test('one write per burst of categories', () async {
      final store = _FakeStore();
      final categories = {"Medical", "Drug", "Candy"};
      final api = _FakeApi({
        for (final category in categories) category: InventoryV2Category(items: const [], timestamp: _nowSeconds),
      });

      final provider = _newProvider(fetcher: api.fetch, store: store);
      await provider.ensureFresh(categories);
      await flush(provider);

      expect(store.writes, 1);
    });

    test('discards a stored category whose hour has already passed', () async {
      DateTime now = DateTime(2026, 9, 20, 12);
      final store = _FakeStore();
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 1)], timestamp: now.millisecondsSinceEpoch ~/ 1000),
      });

      final provider = _newProvider(fetcher: api.fetch, now: () => now, store: store);
      await provider.ensureFresh({"Medical"});
      await flush(provider);

      now = now.add(const Duration(minutes: 59, seconds: 59));
      final onTime = _newProvider(fetcher: api.fetch, now: () => now, store: store);
      await onTime.restored;
      expect(onTime.loaded("Medical"), isTrue);

      now = now.add(const Duration(seconds: 2));
      final tooLate = _newProvider(fetcher: api.fetch, now: () => now, store: store);
      await tooLate.restored;
      expect(tooLate.loaded("Medical"), isFalse);
    });

    test('restores the display case and still adds it to the quantity', () async {
      final store = _FakeStore();
      final int seconds = _nowSeconds;
      final api = _FakeApi(
        {
          "Medical": InventoryV2Category(items: [_item(id: 1, amount: 2)], timestamp: seconds),
        },
        display: [_displayItem(id: 1, quantity: 3)],
      );

      final provider = _newProvider(fetcher: api.fetch, store: store);
      await provider.ensureFresh({"Medical"});
      expect(provider.quantity(1, "Medical"), 5);
      await flush(provider);

      final restored = _newProvider(fetcher: _FakeApi({}).fetch, store: store);
      await restored.restored;
      expect(restored.quantity(1, "Medical"), 5);
    });

    test('clear empties the store so another API key does not read it', () async {
      final store = _FakeStore();
      final api = _FakeApi({
        "Medical": InventoryV2Category(items: [_item(id: 1)], timestamp: _nowSeconds),
      });

      final provider = _newProvider(fetcher: api.fetch, store: store);
      await provider.ensureFresh({"Medical"});
      provider.clear();
      await pumpEventQueue();

      final afterClear = _newProvider(fetcher: api.fetch, store: store);
      await afterClear.restored;
      expect(afterClear.loaded("Medical"), isFalse);
    });

    test('a payload it cannot read is dropped instead of kept around to fail again', () async {
      for (final raw in ["not json", "[]", '{"c":{"Medical":{"t":$_nowSeconds,"i":[[1,1],"nope"]}}}']) {
        final store = _FakeStore(raw);
        final provider = _newProvider(fetcher: _FakeApi({}).fetch, store: store);
        await provider.restored;

        expect(provider.loaded("Medical"), isFalse, reason: raw);
        expect(store.value, isEmpty, reason: raw);
      }
    });

    test('a row layout it does not expect drops the cache instead of misreading it', () async {
      // What a later version would write if it started storing a third field per row
      final store = _FakeStore('{"c":{"Medical":{"t":$_nowSeconds,"i":[[180,5,true]]}}}');
      final provider = _newProvider(fetcher: _FakeApi({}).fetch, store: store);
      await provider.restored;

      expect(provider.loaded("Medical"), isFalse);
      expect(store.value, isEmpty);
    });

    test('an empty store restores nothing and gets in nobody\'s way', () async {
      final api = _FakeApi({"Medical": InventoryV2Category(items: const [], timestamp: _nowSeconds)});
      final provider = _newProvider(fetcher: api.fetch);

      await provider.restored;
      expect(provider.loaded("Medical"), isFalse);

      await provider.ensureFresh({"Medical"});
      expect(provider.loaded("Medical"), isTrue);
    });

    test('the disk is not read on construction, only when something needs it', () async {
      final store = _FakeStore('{"c":{"Medical":{"t":$_nowSeconds,"i":[[1,4]]}}}');
      final provider = _newProvider(fetcher: _FakeApi({}).fetch, store: store);
      expect(store.reads, 0);

      // Anything that needs the cache triggers the read, and only the first one does
      expect(provider.quantity(1, "Medical"), isNull);
      await provider.ensureFresh({"Medical"});
      expect(store.reads, 1);
      expect(provider.quantity(1, "Medical"), 4);

      await provider.restored;
      expect(store.reads, 1);
    });
  });

  group('categoryOf', () {
    test('maps every catalog item type to an API category except Unused', () {
      final provider = _newProvider(fetcher: (_, {required withDisplay}) async => null);

      for (final type in ItemType.values) {
        final String? category = provider.categoryOf(type.name);
        if (type == ItemType.UNUSED) {
          expect(category, isNull);
        } else {
          expect(InventoryProvider.apiCategories, contains(category), reason: type.name);
        }
      }

      final mapped = ItemType.values.where((type) => type != ItemType.UNUSED).map((t) => provider.categoryOf(t.name));
      expect(mapped.toSet(), InventoryProvider.apiCategories.toSet());
    });

    test('maps the catalog display names like the enum names', () {
      final provider = _newProvider(fetcher: (_, {required withDisplay}) async => null);

      typeValues.map.forEach((displayName, type) {
        expect(provider.categoryOf(displayName), provider.categoryOf(type.name), reason: displayName);
      });
      expect(provider.categoryOf("Unused"), isNull);
      expect(provider.categoryOf("Nonsense"), isNull);
    });
  });
}
