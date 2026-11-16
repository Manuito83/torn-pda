import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/profile/other_profile_model/other_profile_pda.dart';
import 'package:torn_pda/models/profile/own_profile_misc.dart';

void main() {
  Map<String, dynamic> misc(dynamic bazaar) => {'education': <String, dynamic>{}, 'bazaar': bazaar};

  test('bazaar as object with items', () {
    final m = OwnProfileMisc.fromJson(
      misc({
        'exists': true,
        'is_open': true,
        'items': [
          {'id': 180, 'uids': [], 'name': 'Bottle of Beer', 'quantity': 2, 'price': 500000, 'market_price': 919},
        ],
      }),
    );
    expect(m.bazaar!.single.id, 180);
    expect(m.bazaar!.single.quantity, 2);
    expect(m.bazaar!.single.price, 500000);
  });

  test('bazaar weapons priced per uid', () {
    final m = OwnProfileMisc.fromJson(
      misc({
        'items': [
          {
            'id': 1,
            'quantity': 2,
            'price': null,
            'uids': [
              {'uid': 1, 'price': 1000000},
              {'uid': 2, 'price': 3000000},
            ],
          },
        ],
      }),
    );
    expect(m.bazaar!.single.price, 2000000);
  });

  test('chat bazaar item with weapons priced per uid', () {
    final item = BazaarItem.fromJson({
      'id': 1,
      'quantity': 2,
      'price': null,
      'uids': [
        {'uid': 1, 'price': 1000000},
        {'uid': 2, 'price': 3000000},
      ],
    });
    expect(item.price, 2000000);
    expect(BazaarItem.fromJson({'id': 2, 'price': 5}).price, 5);
    expect(BazaarItem.fromJson({'id': 3}).price, 0);
  });

  test('bazaar object without items', () {
    expect(OwnProfileMisc.fromJson(misc({'exists': false, 'is_open': false})).bazaar, isEmpty);
    expect(OwnProfileMisc.fromJson(misc({'code': 16, 'error': 'Access level too low'})).bazaar, isEmpty);
  });

  test('bazaar as legacy list', () {
    final m = OwnProfileMisc.fromJson(
      misc([
        {'ID': 180, 'name': 'Bottle of Beer', 'quantity': 1, 'price': 10, 'UID': 7},
      ]),
    );
    expect(m.bazaar!.single.id, 180);
    expect(m.bazaar!.single.uid, 7);
  });
}
