import 'package:torn_pda/models/travel/foreign_stock_in.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';

class OcTravelCheck {
  final String name;
  final Duration untilReady;
  final bool incomplete;
  final List<CountryName> fits;

  const OcTravelCheck({required this.name, required this.untilReady, required this.incomplete, required this.fits});
}

OcTravelCheck? checkOcBeforeTravel({
  required Object? crime,
  required int playerId,
  required DateTime now,
  required TravelTicket ticket,
  double reductionPercent = 0,
}) {
  if (crime is! Map) return null;
  final readyAt = crime['ready_at'];
  if (readyAt is! int) return null;
  if (crime['status'] != 'Recruiting' && crime['status'] != 'Planning') return null;

  final slots = crime['slots'] is List ? crime['slots'] as List : const [];
  final playerIn = slots.any((s) => s is Map && s['user'] is Map && s['user']['id'] == playerId);
  if (!playerIn) return null;

  // Same estimate as the profile: a day per empty slot
  final emptySlots = slots.where((s) => s is Map && s['user'] == null).length;
  var untilReady = DateTime.fromMillisecondsSinceEpoch(
    readyAt * 1000,
  ).add(Duration(hours: 24 * emptySlots)).difference(now);
  if (untilReady.inMinutes <= 0) untilReady = Duration.zero;

  final roundTrips = <CountryName, int>{
    for (final country in CountryName.values)
      if (country != CountryName.TORN)
        country:
            2 *
            TravelTimes.travelTimeMinutesOneWay(
              countryCode: country,
              ticket: ticket,
              reductionPercent: reductionPercent,
            ),
  };
  final fits = roundTrips.keys.where((c) => roundTrips[c]! <= untilReady.inMinutes).toList()
    ..sort((a, b) => roundTrips[a]!.compareTo(roundTrips[b]!));
  if (fits.length == roundTrips.length) return null;

  return OcTravelCheck(
    name: crime['name'] as String? ?? 'OC',
    untilReady: untilReady,
    incomplete: emptySlots > 0,
    fits: fits,
  );
}
