import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_timelapse_controller.dart';

class _History extends TerritoryHistoryController {
  MapHistory? current;

  @override
  MapHistory? get record => current;

  @override
  Future<void> loadYears() async {}

  // Older days arrive
  void arrive(int daysBack) {
    current = _record(daysBack);
    notifyListeners();
  }
}

MapHistory _record(int daysBack) {
  final now = DateTime.now().toUtc();
  return MapHistory(
    year: now.year,
    generatedAt: now,
    completeFrom: now.subtract(Duration(days: daysBack)),
    wars: const [],
    owners: const [],
    rackets: const [],
    bombs: const [],
    factions: const {},
  );
}

Future<void> _pump(WidgetTester tester, Duration time) async {
  for (var left = time; left > Duration.zero; left -= const Duration(milliseconds: 50)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _History history;
  late TerritoryTimelapseController timelapse;

  setUp(() {
    history = _History()..current = _record(5);
    timelapse = TerritoryTimelapseController(TerritoryMapController(), history)..start();
  });

  tearDown(() => timelapse.stop());

  testWidgets('older days arriving while a day is shown do not hang it', (tester) async {
    final day = timelapse.days[2];
    bool? shown;
    timelapse.showDay(day).then((value) => shown = value);
    await tester.pump();
    history.arrive(40);
    await _pump(tester, const Duration(seconds: 3));
    expect(shown, isTrue);
    expect(timelapse.days[timelapse.selected], day);
  });

  testWidgets('a cancel ends the wait', (tester) async {
    var cancelled = false;
    bool? shown;
    timelapse.showDay(timelapse.days.first, cancelled: () => cancelled).then((value) => shown = value);
    await tester.pump();
    cancelled = true;
    await _pump(tester, const Duration(seconds: 1));
    expect(shown, isFalse);
  });

  testWidgets('a day that is not there is refused', (tester) async {
    expect(await timelapse.showDay('1999-01-01'), isFalse);
  });

  testWidgets('closing the map ends the wait', (tester) async {
    bool? shown;
    timelapse.showDay(timelapse.days.first).then((value) => shown = value);
    await tester.pump();
    timelapse.stop();
    await _pump(tester, const Duration(seconds: 1));
    expect(shown, isFalse);
  });
}
