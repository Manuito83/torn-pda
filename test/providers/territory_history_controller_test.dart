import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/utils/territory_map/territory_map_files.dart';

Uint8List body(String day) => utf8.encode('{"format": 1, "day": "$day", "generated_at": 0, "changes": []}');

class _Files extends TerritoryMapFiles {
  final disk = <String, Uint8List>{};
  final server = <String, bool>{};
  final asked = <String>[];
  bool offline = false;

  @override
  Future<Uint8List?> readCached(String name) async => disk[name];

  @override
  Future<void> writeCached(String name, Uint8List bytes) async => disk[name] = bytes;

  @override
  Future<void> deleteCached(bool Function(String name) test) async => disk.removeWhere((name, _) => test(name));

  @override
  Future<DayChanges> decodeChanges(Uint8List bytes) async => parseDayChanges(utf8.decode(bytes));

  final years = <int, Uint8List>{};
  final closedYears = <int>{};
  final yearsAsked = <int>[];

  @override
  Future<MapHistory> decodeHistory(Uint8List bytes) async => parseHistory(utf8.decode(bytes));

  @override
  Future<({Uint8List? bytes, String etag, bool immutable})?> fetchHistory(int year, String etag) async {
    yearsAsked.add(year);
    if (offline) throw const SocketException('offline');
    final bytes = years[year];
    return bytes == null ? null : (bytes: bytes, etag: '', immutable: closedYears.contains(year));
  }

  @override
  Future<({Uint8List? bytes, String etag, bool immutable})?> fetchChanges(String day, String etag) async {
    asked.add(day);
    if (offline) throw const SocketException('offline');
    final immutable = server[day];
    if (immutable == null) return null;
    if (etag == 'etag-$day') return (bytes: null, etag: etag, immutable: false);
    return (bytes: body(day), etag: 'etag-$day', immutable: immutable);
  }
}

void main() {
  final now = DateTime.now().toUtc();
  String daysAgo(int n) => dayKey(now.subtract(Duration(days: n)));
  DateTime from(int n) => now.subtract(Duration(days: n));
  late _Files files;
  late TerritoryHistoryController history;
  late DateTime clock;
  List<String> loaded() => [for (final day in history.days) day.day];
  void wait(Duration time) => clock = clock.add(time);

  setUp(() {
    files = _Files();
    clock = now;
    history = TerritoryHistoryController(files: files, clock: () => clock);
  });

  test('saved days show without network', () async {
    files.disk[changesFileName(daysAgo(2))] = body(daysAgo(2));
    files.offline = true;
    await history.load(from(2));
    expect(loaded(), [daysAgo(2)]);
    expect(history.failed, isTrue);
    expect(files.asked, [daysAgo(0)]);
  });

  test('a 404 is missing for good only after 22 days', () async {
    files.server.addAll({daysAgo(0): false, daysAgo(2): true, daysAgo(4): true});
    await history.load(from(25));
    expect(history.someDaysMissing, isTrue);
    expect(files.disk[changesFileName(daysAgo(24))], isEmpty);
    expect(files.disk.keys, isNot(contains(changesFileName(daysAgo(3)))));
  });

  test('late missing days are asked again every 3 hours', () async {
    files.server.addAll({daysAgo(0): false, daysAgo(2): true, daysAgo(4): true});
    await history.load(from(25));
    files.asked.clear();
    wait(const Duration(minutes: 10));
    await history.load(from(25));
    expect(files.asked, contains(daysAgo(1)));
    expect(files.asked, isNot(contains(daysAgo(3))));
    expect(files.asked, isNot(contains(daysAgo(24))));
    files.asked.clear();
    wait(const Duration(hours: 3));
    await history.load(from(25));
    expect(files.asked, contains(daysAgo(3)));
  });

  test('an open day is not asked twice within a minute', () async {
    files.server[daysAgo(0)] = false;
    await history.load(from(0));
    await history.load(from(0));
    expect(files.asked, [daysAgo(0)]);
    wait(const Duration(minutes: 1));
    await history.load(from(0));
    expect(files.asked, [daysAgo(0), daysAgo(0)]);
    expect(loaded(), [daysAgo(0)]);
  });

  test('only immutable days are saved for good', () async {
    files.server.addAll({daysAgo(0): false, daysAgo(1): false, daysAgo(2): true, daysAgo(3): false});
    await history.load(from(3));
    expect(files.disk.keys, isNot(contains(changesFileName(daysAgo(3)))));
    files.asked.clear();
    wait(const Duration(minutes: 1));
    await history.load(from(3));
    expect(files.asked, contains(daysAgo(3)));
    expect(files.asked, isNot(contains(daysAgo(2))));
  });

  test('an unreadable saved day is asked again', () async {
    files.disk[changesFileName(daysAgo(2))] = utf8.encode('broken');
    files.server.addAll({daysAgo(0): false, daysAgo(1): false, daysAgo(2): true});
    await history.load(from(2));
    expect(loaded(), contains(daysAgo(2)));
    expect(files.disk[changesFileName(daysAgo(2))], body(daysAgo(2)));
  });

  test('year file, then only the days after it', () async {
    files.years[now.year] = utf8.encode(
      '{"format": 1, "year": ${now.year}, "generated_at": 0, "complete_from": 0, "through": "${daysAgo(3)}"}',
    );
    files.server.addAll({daysAgo(0): false, daysAgo(1): false, daysAgo(2): true});
    await history.loadYears();
    expect(files.asked, [daysAgo(0), daysAgo(1), daysAgo(2)]);
    expect(history.record!.completeFrom, DateTime.utc(1970));
  });

  test('days that failed can be retried at once', () async {
    files
      ..server[daysAgo(1)] = true
      ..offline = true;
    await history.load(from(1));
    expect(history.failed, isTrue);
    expect(history.loading, isFalse);
    expect(loaded(), isEmpty);

    files.offline = false;
    history.retryDays();
    await history.load(from(1));
    expect(history.failed, isFalse);
    expect(loaded(), contains(daysAgo(1)));
  });

  test('years asked once an hour, again right after a failure', () async {
    files.offline = true;
    await history.loadYears();
    expect(history.yearsFailed, isTrue);
    files.offline = false;
    files.yearsAsked.clear();
    await history.loadYears();
    expect(files.yearsAsked, isNotEmpty);
    expect(history.yearsFailed, isFalse);
    files.yearsAsked.clear();
    await history.loadYears();
    expect(files.yearsAsked, isEmpty);
  });

  test('years arriving after the last page closed are not kept', () async {
    files.years[now.year] = utf8.encode('{"format": 1, "year": ${now.year}, "generated_at": 0, "complete_from": 0}');
    files.server[daysAgo(0)] = false;
    final loading = history.loadYears();
    history.close(Object());
    await loading;
    expect(history.record!.completeFrom, isNot(DateTime.utc(1970)));
    files.yearsAsked.clear();
    await history.loadYears();
    expect(files.yearsAsked, isNotEmpty);
    expect(history.record!.completeFrom, DateTime.utc(1970));
  });

  test('a closed year is saved and not asked again', () async {
    final last = now.year - 1;
    files.years[last] = utf8.encode('{"format": 1, "year": $last, "generated_at": 0, "complete_from": 0}');
    files.closedYears.add(last);
    await history.loadYears();
    expect(files.disk[historyFileName(last)], files.years[last]);

    final fresh = TerritoryHistoryController(files: files);
    files.yearsAsked.clear();
    await fresh.loadYears();
    expect(files.yearsAsked, isNot(contains(last)));
  });
}
