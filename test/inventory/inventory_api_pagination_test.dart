// ignore_for_file: depend_on_referenced_packages, non_constant_identifier_names

import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/inventory/inventory_v2_model.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';

/// Tests for the paging of [ApiCallsV2.getUserInventory_v2], with a mocked HTTP client.

class _FakeApiCaller extends ApiCallerController {
  _FakeApiCaller(this.pages);

  final List<String> pages;
  final List<Uri> requested = [];
  int _index = 0;

  @override
  // ignore: must_call_super
  Future<void> onInit() async {}

  @override
  Future<dynamic> enqueueApiCall<T>({
    ApiSelection_v1? apiSelection,
    String? prefix = "",
    int limit = 100,
    int? from,
    ApiSelection_v2? apiSelection_v2,
    Future<chopper.Response<T>> Function(TornV2 client, String apiKey)? apiCall,
    String? forcedApiKey = "",
  }) async {
    final client = TornV2.create(
      baseUrl: Uri.parse('https://api.torn.com/v2'),
      httpClient: MockClient((request) async {
        requested.add(request.url);
        final String body = pages[_index < pages.length ? _index : pages.length - 1];
        _index++;
        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      }),
    );

    final response = await apiCall!(client, "fakeKey");
    return jsonDecode(response.bodyString) as Map<String, dynamic>;
  }
}

String _page(List<int> ids, {String? next, Object? display}) {
  return jsonEncode({
    if (display != null) "display": display,
    "inventory": {
      "items": [
        for (final id in ids)
          {"id": id, "amount": 1, "equipped": false, "name": "Item $id", "faction_owned": false, "uid": id * 10},
      ],
      "timestamp": 1789935348,
    },
    "_metadata": {
      "links": {"prev": null, "next": next},
      "total": ids.length,
    },
  });
}

void main() {
  tearDown(Get.reset);

  test('a single page is returned as is', () async {
    final caller = _FakeApiCaller([
      _page([1, 2, 3]),
    ]);
    Get.put<ApiCallerController>(caller);

    final result = await ApiCallsV2.getUserInventory_v2(cat: "Medical");

    expect(result, isA<InventoryV2Category>());
    expect((result as InventoryV2Category).items.length, 3);
    expect(result.timestamp, 1789935348);
    expect(caller.requested.length, 1);
    expect(caller.requested.first.queryParameters["cat"], "Medical");
    expect(caller.requested.first.queryParameters["selections"], "inventory");
    expect(caller.requested.first.queryParameters["limit"], "250");
    expect(caller.requested.first.queryParameters["offset"], "0");
    expect(result.display, isNull);
  });

  test('follows the next link and joins the items', () async {
    final caller = _FakeApiCaller([
      _page([1, 2], next: "https://api.torn.com/v2/user?selections=inventory&offset=250"),
      _page([3, 4], next: "https://api.torn.com/v2/user?selections=inventory&offset=500"),
      _page([5]),
    ]);
    Get.put<ApiCallerController>(caller);

    final result = await ApiCallsV2.getUserInventory_v2(cat: "Primary") as InventoryV2Category;

    expect(result.items.map((e) => e.id), [1, 2, 3, 4, 5]);
    expect(caller.requested.length, 3);
    // The offset follows the rows actually returned, not the limit asked for
    expect(caller.requested.map((e) => e.queryParameters["offset"]), ["0", "2", "4"]);
  });

  test('stops on an empty page even if next keeps pointing forward', () async {
    final caller = _FakeApiCaller([
      _page([1], next: "https://api.torn.com/v2/user?selections=inventory&offset=250"),
      _page([], next: "https://api.torn.com/v2/user?selections=inventory&offset=500"),
    ]);
    Get.put<ApiCallerController>(caller);

    final result = await ApiCallsV2.getUserInventory_v2(cat: "Primary") as InventoryV2Category;

    expect(result.items.length, 1);
    expect(caller.requested.length, 2);
  });

  test('asks for the display case on the first page only and reads it', () async {
    final caller = _FakeApiCaller([
      _page(
        [1, 2],
        next: "https://api.torn.com/v2/user?selections=inventory&offset=250",
        display: [
          {
            "ID": 261,
            "name": "Wolverine Plushie",
            "type": "Plushie",
            "quantity": 4,
            "circulation": 100,
            "market_price": 6,
          },
          {"ID": 739, "name": "Blood Bag : O-", "type": "Medical", "quantity": 2, "circulation": 1, "market_price": 1},
        ],
      ),
      _page(
        [3],
        display: [
          {"ID": 999, "name": "Not read", "type": "Other", "quantity": 9, "circulation": 1, "market_price": 1},
        ],
      ),
    ]);
    Get.put<ApiCallerController>(caller);

    final result = await ApiCallsV2.getUserInventory_v2(cat: "Plushie", withDisplay: true) as InventoryV2Category;

    expect(caller.requested.map((e) => e.queryParameters["selections"]), ["inventory,display", "inventory"]);
    expect(result.items.map((e) => e.id), [1, 2, 3]);
    expect(result.display!.map((e) => e.id), [261, 739]);
    expect(result.display!.map((e) => e.quantity), [4, 2]);
  });

  test('an empty display case is read as empty, not as missing', () async {
    final caller = _FakeApiCaller([
      _page([1], display: []),
    ]);
    Get.put<ApiCallerController>(caller);

    final result = await ApiCallsV2.getUserInventory_v2(cat: "Plushie", withDisplay: true) as InventoryV2Category;

    expect(result.display, isNotNull);
    expect(result.display, isEmpty);
  });

  test('ignores a display case it did not ask for', () async {
    final caller = _FakeApiCaller([
      _page(
        [1],
        display: [
          {"ID": 261, "quantity": 4},
        ],
      ),
    ]);
    Get.put<ApiCallerController>(caller);

    final result = await ApiCallsV2.getUserInventory_v2(cat: "Plushie") as InventoryV2Category;

    expect(caller.requested.first.queryParameters["selections"], "inventory");
    expect(result.display, isNull);
  });

  test('an unreadable display case does not invalidate the category', () async {
    for (final display in <Object>[
      {"code": 16, "error": "Access level of this key is not high enough"},
      [
        {"ID": 261, "quantity": "many"},
      ],
    ]) {
      Get.put<ApiCallerController>(
        _FakeApiCaller([
          _page([1, 2], display: display),
        ]),
      );

      final result = await ApiCallsV2.getUserInventory_v2(cat: "Plushie", withDisplay: true) as InventoryV2Category;

      expect(result.items.map((e) => e.id), [1, 2]);
      expect(result.display, isNull);
      Get.reset();
    }
  });

  test('returns null when the selection answers with an error node', () async {
    final caller = _FakeApiCaller([
      jsonEncode({
        "inventory": {"code": 21, "error": "Incorrect category"},
        "_metadata": {
          "links": {"prev": null, "next": null},
        },
      }),
    ]);
    Get.put<ApiCallerController>(caller);

    expect(await ApiCallsV2.getUserInventory_v2(cat: "Nonsense"), isNull);
  });
}
