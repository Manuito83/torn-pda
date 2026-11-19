import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_bazaar.dart';

Map<String, dynamic> row(int id, String name, int price, int market, [int quantity = 1]) => {
  'ID': id,
  'name': name,
  'type': 'Drug',
  'quantity': quantity,
  'price': price,
  'market_price': market,
};

Map<String, dynamic> profile(List<Map<String, dynamic>> rows, {Object? open = 1}) => {
  'bazaar_is_open': open,
  'bazaar': rows,
};

void main() {
  group('parse', () {
    test('a closed bazaar has no items', () {
      final bazaar = ChatBazaar.parse(profile([row(1, 'A', 1040, 1000)], open: 0))!;
      expect(bazaar.open, isFalse);
      expect(bazaar.items, isEmpty);
    });

    test('open without a list is open, not empty', () {
      final bazaar = ChatBazaar.parse({'bazaar_is_open': true})!;
      expect(bazaar.listed, isFalse);
    });

    test('an empty list on an open bazaar is open, never empty', () {
      final bazaar = ChatBazaar.parse(profile([], open: true))!;
      expect(bazaar.open, isTrue);
      expect(bazaar.listed, isFalse);
      expect(ChatBazaar.parse({'bazaar_is_open': true, 'bazaar': []})!.listed, isFalse);
      expect(ChatBazaar.parse({'bazaar': []}), isNull);
    });

    test('a list with items keeps them', () {
      final bazaar = ChatBazaar.parse(profile([row(1, 'A', 1040, 1000), row(2, 'B', 5, 5)]))!;
      expect(bazaar.listed, isTrue);
      expect(bazaar.items, hasLength(2));
    });

    test('v2 object with lowercase ids', () {
      final bazaar = ChatBazaar.parse({
        'bazaar': {
          'exists': true,
          'is_open': true,
          'items': [
            {'id': 180, 'name': 'Beer', 'type': 'Alcohol', 'quantity': 1, 'price': 500, 'market_price': 400},
          ],
        },
      })!;
      expect(bazaar.open, isTrue);
      expect(bazaar.items.single.id, 180);
      expect(ChatBazaar.parse({'bazaar': {'is_open': false, 'items': []}})!.open, isFalse);
    });

    test('a player without a bazaar is null even if is_open says true', () {
      expect(ChatBazaar.parse({'bazaar_exists': false, 'bazaar_is_open': true, 'bazaar': []}), isNull);
      expect(
        ChatBazaar.parse({
          'bazaar': {'exists': false, 'is_open': true, 'items': []},
        }),
        isNull,
      );
    });

    test('no bazaar in the profile is null', () {
      expect(ChatBazaar.parse({'profile': {}}), isNull);
    });
  });

  group('page filler', () {
    test('a name with quotes and slashes stays one string', () {
      const name = 'Bob\'s "Plush" \\ line\nbreak';
      final script = ChatBazaar.fillScript(name);
      final start = script.indexOf('var n=') + 6;
      final literal = script.substring(start, script.indexOf(',t=0'));
      expect(jsonDecode(literal), name);
    });
  });
}
