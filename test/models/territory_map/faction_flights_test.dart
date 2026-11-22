import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/models/territory_map/flight_projection.dart';

const _now = 1000000;

Flight _flight(int id, {String from = 'Torn', String to = 'Japan', int? arrival, int? departed}) =>
    Flight(id: id, name: 'P$id', from: from, to: to, arrival: arrival, departed: departed);

void main() {
  test('reads the wordings Torn really sends', () {
    final flights = flightsFromMembers([
      (id: 1, name: 'A', state: 'Traveling', description: 'Traveling from Torn to United Kingdom'),
      (id: 2, name: 'B', state: 'Traveling', description: 'Traveling from UAE to Torn'),
      (id: 3, name: 'C', state: 'Abroad', description: 'In South Africa'),
      (id: 4, name: 'D', state: 'Okay', description: 'Okay'),
      (id: 5, name: 'E', state: 'Hospital', description: 'In a Japanese hospital for 3 minutes'),
    ]);
    expect(flights.flying.map((f) => (f.from, f.to)), [('Torn', 'United Kingdom'), ('UAE', 'Torn')]);
    expect(flights.abroad.single.at, 'South Africa');
  });

  test('reads the answer and counts with and without time', () {
    final answer = readFlightsAnswer({
      'status': 'ok',
      'flying': [
        {'id': 1, 'name': 'A', 'from': 'Torn', 'to': 'Japan', 'arrival': _now + 60, 'departed': _now - 60},
        {'id': 2, 'name': 'B', 'from': 'Torn', 'to': 'China'},
      ],
      'abroad': [
        {'id': 3, 'name': 'C', 'at': 'Mexico'},
      ],
    });
    expect(answer.kind, FlightsAnswerKind.ok);
    expect(answer.flights!.withTime, 1);
    expect(answer.flights!.noInfo, 1);
  });

  test('a broken or limited answer is not taken as data', () {
    expect(readFlightsAnswer('nope').kind, FlightsAnswerKind.unreadable);
    expect(readFlightsAnswer({'status': 'unavailable'}).kind, FlightsAnswerKind.unreadable);
    expect(readFlightsAnswer({'status': 'no_login'}).kind, FlightsAnswerKind.noLogin);
    expect(readFlightsAnswer({'status': 'ok', 'flying': 'x'}).kind, FlightsAnswerKind.unreadable);
    final limited = readFlightsAnswer({'status': 'limited', 'retryIn': 40});
    expect(limited.kind, FlightsAnswerKind.limited);
    expect(limited.retryIn, 40);
  });

  test('a landed flight goes abroad, or vanishes when back in Torn', () {
    final flights = FactionFlights(
      flying: [
        _flight(1, arrival: _now - 1),
        _flight(2, from: 'China', to: 'Torn', arrival: _now - 1),
        _flight(3, arrival: _now + 10),
        _flight(4),
      ],
    );
    final later = flightsAt(flights, _now);
    expect(later.flying.map((f) => f.id), [3, 4]);
    expect(later.abroad.single.id, 1);
    expect(later.abroad.single.at, 'Japan');
  });

  test('order is soonest first, then no time', () {
    final order = flightsInOrder([_flight(1), _flight(2, arrival: _now + 90), _flight(3, arrival: _now + 10)]);
    expect(order.map((f) => f.id), [3, 2, 1]);
  });

  test('a plane sits where the clock says, in the middle without a time', () {
    final flight = _flight(1, arrival: _now + 100, departed: _now - 300);
    expect(flightProgress(flight, _now), 0.75);
    expect(flightProgress(flight, _now + 1000), 1);
    expect(flightProgress(_flight(2), _now), 0.5);
    expect(flightProgress(_flight(3, arrival: _now + 100), _now), 0.5);
    expect(flightPosition(_flight(4, to: 'Atlantis'), _now), isNull);
  });

  test('groups abroad go biggest first, names in order', () {
    final groups = abroadGroups(const [
      MemberAbroad(id: 1, name: 'zed', at: 'Mexico'),
      MemberAbroad(id: 2, name: 'Bram', at: 'Japan'),
      MemberAbroad(id: 3, name: 'aldous', at: 'Japan'),
      MemberAbroad(id: 4, name: 'Kaz', at: 'China'),
    ]);
    expect(groups.map((g) => g.place), ['Japan', 'China', 'Mexico']);
    expect(groups.first.members.map((m) => m.name), ['aldous', 'Bram']);
  });

  test('marks leave out the far side, planes soonest first', () {
    final flights = FactionFlights(
      flying: [
        _flight(2, from: 'Torn', to: 'Mexico'),
        _flight(1, arrival: _now + 100, departed: _now - 100),
      ],
      abroad: const [
        MemberAbroad(id: 3, name: 'C', at: 'Argentina'),
        MemberAbroad(id: 4, name: 'D', at: 'China'),
      ],
    );
    final marks = flightMarks(flights, GlobeProjection(lon: -80, lat: 0, size: const Size(400, 400)), _now);
    expect(marks.abroad.map((m) => m.place), ['Argentina']);
    expect(marks.planes.map((p) => p.flight.id), [1, 2]);
  });

  test('a row takes the globe to the plane or the country', () {
    final flights = FactionFlights(
      flying: [_flight(1, arrival: _now + 100, departed: _now - 100)],
      abroad: const [MemberAbroad(id: 2, name: 'B', at: 'Mexico')],
    );
    expect(flightFocus(flights, 2, _now), flightPlaces['Mexico']);
    expect(flightFocus(flights, 1, _now)!.lat, greaterThan(40));
    expect(flightFocus(flights, 9, _now), isNull);
  });

  test('flags go at route ends, not on Torn or where a count sits', () {
    final flights = FactionFlights(
      flying: [
        _flight(1, to: 'Japan'),
        _flight(2, from: 'China', to: 'Torn'),
      ],
      abroad: const [MemberAbroad(id: 3, name: 'C', at: 'China')],
    );
    expect(flightFlagPlaces(flights), {'Japan'});
  });
}
