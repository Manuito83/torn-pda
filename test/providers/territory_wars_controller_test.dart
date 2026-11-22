import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/war_file.dart';
import 'package:torn_pda/providers/territory_wars_controller.dart';
import 'package:torn_pda/utils/territory_map/territory_map_files.dart';

final _war = File('test/models/territory_map/fixtures/war-46843.json').readAsBytesSync();

class _Files extends TerritoryMapFiles {
  final disk = <String, Uint8List>{};
  final server = <int, bool>{};
  final asked = <int>[];
  bool offline = false;

  @override
  Future<Uint8List?> readCached(String name) async => disk[name];

  @override
  Future<void> writeCached(String name, Uint8List bytes) async => disk[name] = bytes;

  @override
  Future<WarFile> decodeWar(Uint8List bytes) async => parseWarFile(utf8.decode(bytes));

  @override
  Future<({Uint8List? bytes, String etag, bool immutable})?> fetchWar(int id, String etag) async {
    asked.add(id);
    if (offline) throw const SocketException('offline');
    final immutable = server[id];
    return immutable == null ? null : (bytes: _war, etag: 'etag', immutable: immutable);
  }
}

void main() {
  late _Files files;

  setUp(() => files = _Files());

  Future<TerritoryWarsController> openWar(int id) async {
    final wars = TerritoryWarsController(files: files)..open(id);
    await pumpEventQueue();
    wars.close(id);
    return wars;
  }

  test('a closed war is saved and not asked again', () async {
    files.server[1] = true;
    final wars = await openWar(1);
    expect(wars.isFinal(1), isTrue);
    expect(files.disk[warFileName(1)], _war);

    files.asked.clear();
    final again = await openWar(1);
    expect(files.asked, isEmpty);
    expect(again.warFile(1), isNotNull);
  });

  test('a failed war can be retried', () async {
    files
      ..server[3] = true
      ..offline = true;
    final wars = await openWar(3);
    expect(wars.hasFailed(3), isTrue);
    expect(wars.isLoading(3), isFalse);

    files.offline = false;
    await wars.retry(3);
    expect(wars.hasFailed(3), isFalse);
    expect(wars.warFile(3), isNotNull);
  });

  test('a 404 is not published yet, not a failure', () async {
    final wars = await openWar(2);
    expect(wars.isMissing(2), isTrue);
    expect(wars.hasFailed(2), isFalse);
    expect(files.disk, isEmpty);
  });
}
