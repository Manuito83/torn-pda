import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/city_item_prices.dart';

Item _item(String id, int value) => Item(name: 'Item $id', marketValue: value)..id = id;

void main() {
  test('nothing waits while the items are on their way', () async {
    final answer = Completer<List<Item>>();
    final prices = CityItemPrices(() => answer.future);
    final done = prices.load(['1']);
    expect(prices.loading, isTrue);
    expect(prices.found, isEmpty);

    answer.complete([_item('1', 500), _item('2', 900)]);
    await done;
    expect(prices.loading, isFalse);
    expect(prices.failed, isFalse);
    expect(prices.found.map((i) => i.id), ['1']);
    expect(prices.byItem[2]?.value, 900);
  });

  test('an API that never answers fails on time and can be retried', () async {
    var hang = true;
    final prices = CityItemPrices(
      () => hang ? Completer<List<Item>>().future : Future.value([_item('1', 500)]),
      timeout: const Duration(milliseconds: 10),
    );
    await prices.load(['1']);
    expect(prices.loading, isFalse);
    expect(prices.failed, isTrue);

    hang = false;
    await prices.retry();
    expect(prices.failed, isFalse);
    expect(prices.found, hasLength(1));
  });

  test('an API error is a failure, not an exception', () async {
    final prices = CityItemPrices(() async => throw StateError('items unavailable'));
    await prices.load(['1']);
    expect(prices.failed, isTrue);
  });

  test('known prices survive a failed refresh', () async {
    var fail = false;
    final prices = CityItemPrices(() async {
      if (fail) throw StateError('items unavailable');
      return [_item('1', 500), _item('2', 900)];
    });
    await prices.load(['1']);

    fail = true;
    final next = prices.load(['2']);
    expect(prices.loading, isFalse);
    await next;
    expect(prices.failed, isFalse);
    expect(prices.found.map((i) => i.id), ['2']);
  });

  test('a late answer from an old document is dropped', () async {
    final first = Completer<List<Item>>();
    final answers = [
      first.future,
      Future.value([_item('2', 900)]),
    ];
    final prices = CityItemPrices(() => answers.removeAt(0));
    final old = prices.load(['1']);
    await prices.load(['2']);

    first.complete([_item('1', 500)]);
    await old;
    expect(prices.byItem.keys, [2]);
  });
}
