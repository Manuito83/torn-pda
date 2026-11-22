import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/models/territory_map/world_land.dart';
import 'package:torn_pda/providers/faction_flights_controller.dart';

const _onTorn = FactionFlights(
  flying: [Flight(id: 1, name: 'A', from: 'Torn', to: 'Japan')],
);
const _withTime = FactionFlights(
  flying: [Flight(id: 1, name: 'A', from: 'Torn', to: 'Japan', arrival: 99, departed: 9)],
);

class _Source extends FlightsSource {
  _Source({
    this.note,
    this.tornList = _onTorn,
    this.answerCall,
    this.saves = true,
    this.shared = false,
    this.readFails = false,
    this.player = 1,
    this.login = true,
  });

  final bool readFails;
  final int player;
  final bool login;

  final String? note;
  final FactionFlights? tornList;
  final Future<FlightsAnswer> Function()? answerCall;
  final bool? saves;
  final bool? shared;
  int memberCalls = 0;
  int answerCalls = 0;
  int shareReads = 0;
  int shareWrites = 0;

  @override
  Future<bool> loggedIn() async => login;

  @override
  Future<bool?> readShare() async {
    shareReads++;
    if (readFails) throw Exception('down');
    return shared;
  }

  @override
  String? get blocked => note;

  @override
  int get playerId => player;

  @override
  Future<FactionFlights?> members() async {
    memberCalls++;
    return tornList;
  }

  @override
  Future<FlightsAnswer> answer() {
    answerCalls++;
    return answerCall?.call() ?? Future.value((kind: FlightsAnswerKind.ok, flights: _withTime, retryIn: 0));
  }

  @override
  Future<bool?> writeShare(bool share) async {
    shareWrites++;
    return saves;
  }

  @override
  Future<WorldLand> land() async => const WorldLand([]);
}

void main() {
  test('one Torn call per map open, none without key or faction', () async {
    final source = _Source();
    final flights = FactionFlightsController(source: source);
    await flights.loadCount();
    await flights.loadCount();
    expect(source.memberCalls, 1);
    expect(flights.flyingNow, 1);

    final without = _Source(note: 'no faction');
    final blocked = FactionFlightsController(source: without);
    await blocked.loadCount();
    await blocked.open();
    expect(without.memberCalls, 0);
    expect(without.answerCalls, 0);
    expect(blocked.flyingNow, isNull);
    expect(blocked.answerNote, 'no faction');
  });

  test('Torn failing leaves the button with no number and marks it', () async {
    final flights = FactionFlightsController(source: _Source(tornList: null));
    await flights.loadCount();
    expect(flights.membersFailed, isTrue);
    expect(flights.flyingNow, isNull);
  });

  test('reopening the sheet right away does not call the function again', () async {
    final source = _Source();
    final flights = FactionFlightsController(source: source);
    await flights.open();
    await flights.open();
    expect(source.answerCalls, 1);
    expect(flights.flights!.withTime, 1);
  });

  test('the Torn list stays when the function fails, with an error and retry', () async {
    var failing = true;
    final source = _Source(
      answerCall: () async {
        if (failing) throw Exception('down');
        return (kind: FlightsAnswerKind.ok, flights: _withTime, retryIn: 0);
      },
    );
    final flights = FactionFlightsController(source: source);
    await flights.loadCount();
    await flights.open();
    expect(flights.answerError, isNotNull);
    expect(flights.answerLoading, isFalse);
    expect(flights.flights!.flying.length, 1);

    failing = false;
    await flights.refresh();
    expect(flights.answerError, isNull);
    expect(flights.flights!.withTime, 1);
  });

  test('without a Torn login the list stays, with no times and a sign in note', () async {
    final source = _Source(answerCall: () async => (kind: FlightsAnswerKind.noLogin, flights: null, retryIn: 0));
    final flights = FactionFlightsController(source: source);
    await flights.loadCount();
    await flights.open();
    expect(flights.answerNote, contains('Settings > Torn Authentication'));
    expect(flights.answerError, isNull);
    expect(flights.flights!.flying.length, 1);
    expect(flights.flights!.withTime, 0);

    await flights.open();
    expect(source.answerCalls, 2);
  });

  test('without a Torn login the switch stays off and says how to sign in', () async {
    final source = _Source(shared: null, login: false);
    final flights = FactionFlightsController(source: source);
    await flights.loadShare();
    expect(flights.share, isNull);
    expect(flights.shareError, contains('Settings > Torn Authentication'));

    flights.share = true;
    await flights.setShare(false);
    expect(flights.share, isFalse);

    await flights.setShare(true);
    expect(flights.share, isFalse);
    expect(flights.shareError, contains('Settings > Torn Authentication'));
    expect(source.shareWrites, 1);
  });

  test('a slow member list never overwrites the times', () async {
    final flights = FactionFlightsController(source: _Source());
    await flights.open();
    await flights.loadCount();
    expect(flights.flights!.withTime, 1);
  });

  test('the button only counts who is still flying', () async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final flights = FactionFlightsController(
      source: _Source(
        tornList: FactionFlights(
          flying: [
            Flight(id: 1, name: 'A', from: 'Torn', to: 'Japan', arrival: now - 5),
            Flight(id: 2, name: 'B', from: 'Torn', to: 'Japan', arrival: now + 500),
            const Flight(id: 3, name: 'C', from: 'Torn', to: 'China'),
          ],
        ),
      ),
    );
    await flights.loadCount();
    expect(flights.flyingNow, 2);
  });

  test('the switch shows the real value and reads it only once', () async {
    final source = _Source(shared: true);
    final flights = FactionFlightsController(source: source);
    await flights.loadShare();
    await flights.loadShare();
    expect(flights.share, isTrue);
    expect(source.shareReads, 1);
  });

  test('a failed read blocks the switch until the next open', () async {
    final source = _Source(readFails: true);
    final flights = FactionFlightsController(source: source);
    await flights.loadShare();
    expect(flights.share, isNull);
    expect(flights.shareError, isNotNull);
    expect(flights.shareBusy, isFalse);

    await flights.loadShare();
    expect(source.shareReads, 2);
  });

  test('sharing only flips once the document took it', () async {
    final refused = FactionFlightsController(source: _Source(saves: false))..share = false;
    await refused.setShare(true);
    expect(refused.share, isFalse);
    expect(refused.shareError, isNotNull);

    final saved = FactionFlightsController(source: _Source())..share = false;
    await saved.setShare(true);
    expect(saved.share, isTrue);
    expect(saved.shareError, isNull);
  });

  test('with no answer the switch reads the real value again', () async {
    final source = _Source(saves: null, shared: true);
    final flights = FactionFlightsController(source: source)..share = false;
    await flights.setShare(true);
    expect(flights.share, isNull);
    expect(flights.shareError, isNotNull);

    await flights.loadShare();
    expect(flights.share, isTrue);
    expect(flights.shareError, isNull);
  });

  test('another account asks again within the limit', () async {
    final last = LastFlightsAnswer();
    final first = FactionFlightsController(source: _Source(), last: last);
    await first.open();
    first.dispose();

    final other = _Source(player: 2);
    final second = FactionFlightsController(source: other, last: last);
    await second.loadCount();
    expect(other.memberCalls, 1);
    await second.open();
    expect(other.answerCalls, 1);
  });

  test('a new page reuses a recent answer', () async {
    final last = LastFlightsAnswer();
    final source = _Source();
    final first = FactionFlightsController(source: source, last: last);
    await first.open();
    first.dispose();

    final second = FactionFlightsController(source: source, last: last);
    await second.loadCount();
    expect(second.flights!.withTime, 1);
    await second.open();
    expect(source.answerCalls, 1);
    expect(source.memberCalls, 0);
    expect(second.answerError, isNull);
    expect(second.flights!.withTime, 1);
  });

  test('a country and a member are never chosen together', () {
    final controller = FactionFlightsController(source: _Source());
    controller.select(1);
    controller.selectPlace('Japan');
    expect((controller.selected, controller.place), (null, 'Japan'));

    controller.select(1);
    expect((controller.selected, controller.place), (1, null));

    controller.selectPlace(null);
    expect((controller.selected, controller.place), (1, null));
  });
}
