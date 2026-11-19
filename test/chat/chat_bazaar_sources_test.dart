import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_bazaar_sources.dart';

void main() {
  Map<String, dynamic> body({Object? exists = true, Object? open = true}) => {
    'bazaar_timestamp': 1795032205,
    'bazaar_delay': 99999,
    'bazaar_is_open': ?open,
    'bazaar_exists': ?exists,
    'bazaar': [],
  };

  test('reads the four outcomes', () {
    expect(chatBazaarState(body()), ChatBazaarState.open);
    expect(chatBazaarState(body(open: false)), ChatBazaarState.closed);
    expect(chatBazaarState(body(exists: false)), ChatBazaarState.none);
  });

  test('is_open means nothing without a bazaar', () {
    expect(chatBazaarState(body(exists: false, open: true)), ChatBazaarState.none);
    expect(chatBazaarState(body(exists: false, open: false)), ChatBazaarState.none);
  });

  test('missing fields are unknown', () {
    expect(chatBazaarState(body(exists: null)), ChatBazaarState.unknown);
    expect(chatBazaarState(body(open: null)), ChatBazaarState.unknown);
    expect(chatBazaarState(<String, dynamic>{}), ChatBazaarState.unknown);
  });

  test('wrong types are unknown', () {
    expect(chatBazaarState(body(exists: 1)), ChatBazaarState.unknown);
    expect(chatBazaarState(body(open: 'true')), ChatBazaarState.unknown);
    expect(chatBazaarState(body(open: 0)), ChatBazaarState.unknown);
    expect(chatBazaarState(null), ChatBazaarState.unknown);
    expect(chatBazaarState([body()]), ChatBazaarState.unknown);
  });

  test('an error answer is unknown', () {
    expect(
      chatBazaarState({
        'error': {'code': 2, 'error': 'Incorrect Key'},
      }),
      ChatBazaarState.unknown,
    );
    expect(chatBazaarState({...body(), 'error': {}}), ChatBazaarState.unknown);
  });
}
