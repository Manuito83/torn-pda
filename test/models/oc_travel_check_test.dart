import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/travel/foreign_stock_in.dart';
import 'package:torn_pda/models/travel/oc_travel_check.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';

void main() {
  final now = DateTime(2026, 11, 7, 12);
  const me = 1000;

  Map crime({required Duration readyIn, String status = 'Planning', List<int?> members = const [me, 1, 2]}) => {
    'name': 'Blast from the Past',
    'status': status,
    'ready_at': now.add(readyIn).millisecondsSinceEpoch ~/ 1000,
    'slots': [
      for (final id in members)
        {
          'user': id == null ? null : {'id': id},
        },
    ],
  };

  OcTravelCheck? check(Map c) => checkOcBeforeTravel(crime: c, playerId: me, now: now, ticket: TravelTicket.standard);

  test('lists the round trips back in time, shortest first', () {
    final result = check(crime(readyIn: const Duration(hours: 1, minutes: 20)))!;
    expect(result.untilReady, const Duration(hours: 1, minutes: 20));
    expect(result.fits, [CountryName.MEXICO, CountryName.CAYMAN_ISLANDS, CountryName.CANADA]);
    expect(result.incomplete, isFalse);
  });

  test('no warning when every round trip is back in time', () {
    expect(check(crime(readyIn: const Duration(hours: 10))), isNull);
  });

  test('each empty slot adds a day, as in the profile', () {
    final result = check(crime(readyIn: const Duration(hours: -20), status: 'Recruiting', members: [me, null]))!;
    expect(result.incomplete, isTrue);
    expect(result.untilReady, const Duration(hours: 4));
  });
}
