import 'dart:ui';

import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/models/territory_map/flight_projection.dart';
import 'package:torn_pda/utils/country_check.dart';

const tornPlace = 'Torn';

// Approximate, Torn by the Gulf
const Map<String, LonLat> flightPlaces = {
  tornPlace: (lon: -90, lat: 31),
  'Mexico': (lon: -102, lat: 23),
  'Cayman Islands': (lon: -81.3, lat: 19.3),
  'Canada': (lon: -106, lat: 56),
  'Hawaii': (lon: -156.3, lat: 20.8),
  'United Kingdom': (lon: -2, lat: 54),
  'Argentina': (lon: -64, lat: -34),
  'Switzerland': (lon: 8.2, lat: 46.8),
  'Japan': (lon: 138, lat: 36),
  'China': (lon: 104, lat: 35),
  'UAE': (lon: 54, lat: 24),
  'South Africa': (lon: 24, lat: -29),
};

const _sameName = {'UK': 'United Kingdom', 'United Arab Emirates': 'UAE'};

String flightPlaceName(String name) => _sameName[name] ?? name;

class Flight {
  const Flight({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    this.arrival,
    this.departed,
  });

  final int id;
  final String name;
  final String from;
  final String to;

  // Seconds since epoch
  final int? arrival;
  final int? departed;

  bool get hasTime => arrival != null;
}

class MemberAbroad {
  const MemberAbroad({required this.id, required this.name, required this.at});

  final int id;
  final String name;
  final String at;
}

class FactionFlights {
  const FactionFlights({this.flying = const [], this.abroad = const []});

  final List<Flight> flying;
  final List<MemberAbroad> abroad;

  int get withTime => flying.where((f) => f.hasTime).length;

  // Never says why there's no time
  int get noInfo => flying.length - withTime;

  bool get isEmpty => flying.isEmpty && abroad.isEmpty;
}

typedef TornMember = ({int id, String name, String state, String description});

FactionFlights flightsFromMembers(Iterable<TornMember> members) {
  final flying = <Flight>[];
  final abroad = <MemberAbroad>[];
  for (final member in members) {
    final text = member.description.trim();
    if (member.state == 'Traveling') {
      final trip = parseTrip(text);
      if (trip == null) continue;
      final place = flightPlaceName(trip.$1);
      final back = trip.$2 == TravelDirection.returning;
      flying.add(
        Flight(id: member.id, name: member.name, from: back ? place : tornPlace, to: back ? tornPlace : place),
      );
    } else if (member.state == 'Abroad' && text.startsWith('In ')) {
      abroad.add(MemberAbroad(id: member.id, name: member.name, at: flightPlaceName(text.substring(3))));
    }
  }
  return FactionFlights(flying: flying, abroad: abroad);
}

enum FlightsAnswerKind { ok, noLogin, noKey, noFaction, tornError, limited, unreadable }

typedef FlightsAnswer = ({FlightsAnswerKind kind, FactionFlights? flights, int retryIn});

FlightsAnswer readFlightsAnswer(Object? data) {
  const unreadable = (kind: FlightsAnswerKind.unreadable, flights: null, retryIn: 0);
  if (data is! Map) return unreadable;
  switch (data['status']) {
    case 'no_login':
      return (kind: FlightsAnswerKind.noLogin, flights: null, retryIn: 0);
    case 'no_key':
      return (kind: FlightsAnswerKind.noKey, flights: null, retryIn: 0);
    case 'no_faction':
      return (kind: FlightsAnswerKind.noFaction, flights: null, retryIn: 0);
    case 'torn_error':
      return (kind: FlightsAnswerKind.tornError, flights: null, retryIn: 0);
    case 'limited':
      return (kind: FlightsAnswerKind.limited, flights: null, retryIn: (data['retryIn'] as num?)?.toInt() ?? 60);
    case 'ok':
      try {
        final flying = [
          for (final row in data['flying'] as List)
            Flight(
              id: (row['id'] as num).toInt(),
              name: row['name'] as String,
              from: row['from'] as String,
              to: row['to'] as String,
              arrival: (row['arrival'] as num?)?.toInt(),
              departed: (row['departed'] as num?)?.toInt(),
            ),
        ];
        final abroad = [
          for (final row in data['abroad'] as List)
            MemberAbroad(id: (row['id'] as num).toInt(), name: row['name'] as String, at: row['at'] as String),
        ];
        return (kind: FlightsAnswerKind.ok, flights: FactionFlights(flying: flying, abroad: abroad), retryIn: 0);
      } catch (_) {
        return unreadable;
      }
  }
  return unreadable;
}

// Null when the answer isn't readable
bool? shareAnswerValue(Object? data) {
  if (data is! Map) return null;
  final share = data['share'];
  return share is bool ? share : null;
}

// With no document, nothing to stop
bool shareAnswerSaved(Object? data, {required bool share}) {
  if (data is! Map) return false;
  return data['status'] == 'ok' || (!share && data['status'] == 'no_player');
}

// Only a Torn login can stop it
bool shareAnswerPending(Object? data) => data is Map && data['status'] == 'pending';

bool shareAnswerNeedsLogin(Object? data) => data is Map && data['status'] == 'no_login';

// Landed ones leave the flying list
FactionFlights flightsAt(FactionFlights flights, int nowSeconds) {
  final landed = flights.flying.where((f) => f.hasTime && f.arrival! <= nowSeconds).toList();
  if (landed.isEmpty) return flights;
  return FactionFlights(
    flying: flights.flying.where((f) => !landed.contains(f)).toList(),
    abroad: [
      ...flights.abroad,
      for (final f in landed)
        if (f.to != tornPlace) MemberAbroad(id: f.id, name: f.name, at: f.to),
    ],
  );
}

// Soonest first, those with no time after
List<Flight> flightsInOrder(List<Flight> flying) {
  final timed = flying.where((f) => f.hasTime).toList()..sort((a, b) => a.arrival!.compareTo(b.arrival!));
  return [...timed, ...flying.where((f) => !f.hasTime)];
}

typedef AbroadGroup = ({String place, List<MemberAbroad> members});

// Biggest first, names in order
List<AbroadGroup> abroadGroups(List<MemberAbroad> abroad) {
  final byPlace = <String, List<MemberAbroad>>{};
  for (final member in abroad) {
    (byPlace[member.at] ??= []).add(member);
  }
  return [
    for (final MapEntry(key: place, value: members) in byPlace.entries)
      (place: place, members: members..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))),
  ]..sort((a, b) {
    final size = b.members.length.compareTo(a.members.length);
    return size != 0 ? size : a.place.compareTo(b.place);
  });
}

// Middle of the route without both times
double flightProgress(Flight flight, int nowSeconds) {
  final arrival = flight.arrival;
  final departed = flight.departed;
  if (arrival == null || departed == null || arrival <= departed) return 0.5;
  return ((nowSeconds - departed) / (arrival - departed)).clamp(0.0, 1.0);
}

// Null for an unknown place
LonLat? flightPosition(Flight flight, int nowSeconds, {double ahead = 0}) {
  final from = flightPlaces[flight.from];
  final to = flightPlaces[flight.to];
  if (from == null || to == null) return null;
  return greatCircle(from, to, (flightProgress(flight, nowSeconds) + ahead).clamp(0.0, 1.0));
}

// Bold pieces marked
List<(String, bool)> flightsSummary(FactionFlights flights) {
  final noInfo = flights.noInfo;
  return [
    ('${flights.flying.length} flying', true),
    (' - ${flights.withTime} with arrival time - ', false),
    ('${flights.abroad.length} abroad', true),
    if (noInfo > 0) (' - $noInfo ${noInfo == 1 ? 'member' : 'members'} with no information available', false),
  ];
}

// What the painter draws and taps hit
class PlaneMark {
  const PlaneMark({required this.flight, required this.at, required this.heading});

  final Flight flight;
  final Offset at;
  final double heading;
}

class AbroadMark {
  const AbroadMark({required this.place, required this.at, required this.members});

  final String place;
  final Offset at;
  final List<MemberAbroad> members;
}

typedef FlightMarks = ({List<PlaneMark> planes, List<AbroadMark> abroad});

// In the order their names are placed
FlightMarks flightMarks(FactionFlights flights, FlightProjection projection, int nowSeconds) {
  final planes = <PlaneMark>[];
  for (final flight in flightsInOrder(flights.flying)) {
    final point = flightPosition(flight, nowSeconds);
    final at = point == null ? null : projection.place(point);
    if (at == null) continue;
    final next = projection.place(flightPosition(flight, nowSeconds, ahead: 0.02)!) ?? at;
    planes.add(PlaneMark(flight: flight, at: at, heading: (next - at).direction));
  }

  final abroad = <AbroadMark>[];
  for (final group in abroadGroups(flights.abroad)) {
    final point = flightPlaces[group.place];
    final at = point == null ? null : projection.place(point);
    if (at != null) abroad.add(AbroadMark(place: group.place, at: at, members: group.members));
  }
  return (planes: planes, abroad: abroad);
}

// Where a list row takes the globe
LonLat? flightFocus(FactionFlights flights, int id, int nowSeconds) {
  for (final flight in flights.flying) {
    if (flight.id == id) return flightPosition(flight, nowSeconds);
  }
  for (final member in flights.abroad) {
    if (member.id == id) return flightPlaces[member.at];
  }
  return null;
}

// Route ends, minus Torn and counts
Set<String> flightFlagPlaces(FactionFlights flights) {
  final abroad = {for (final member in flights.abroad) member.at};
  return {
    for (final flight in flights.flying) ...[flight.from, flight.to],
  }.difference({tornPlace, ...abroad});
}
