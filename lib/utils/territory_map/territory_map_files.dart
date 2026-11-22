import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:torn_pda/config/territory_map_config.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/models/territory_map/surroundings_relief.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/models/territory_map/war_file.dart';

const _devBaseUrl = String.fromEnvironment('TERRITORY_MAP_BASE_URL');

const bundledTerritoriesVersion = 1;
const stateFileName = 'state.json.gz';
// Android unpacks .gz assets, keep .bin
const _bundledTerritories = 'assets/territory_map/territories-v$bundledTerritoriesVersion.json.bin';
const _bundledGround = 'assets/territory_map/neutral-v1.json.bin';
const _bundledSurroundings = 'assets/territory_map/surroundings-v1.json.bin';
const _bundledRelief = 'assets/territory_map/surroundings-height-v1.bin';
const _timeout = Duration(seconds: 10);

String territoriesFileName(int version) => 'territories-v$version.json.gz';

String warFileName(int id) => 'war-$id.json.gz';

String changesFileName(String day) => 'changes-$day.json.gz';

String historyFileName(int year) => 'history-$year.json.gz';

TerritoryFile _territoriesFromGzip(Uint8List bytes) => parseTerritoryFile(utf8.decode(gzip.decode(bytes)));

MapState _stateFromGzip(Uint8List bytes) => parseMapState(utf8.decode(gzip.decode(bytes)));

WarFile _warFromGzip(Uint8List bytes) => parseWarFile(utf8.decode(gzip.decode(bytes)));

DayChanges _changesFromGzip(Uint8List bytes) => parseDayChanges(utf8.decode(gzip.decode(bytes)));

MapHistory _historyFromGzip(Uint8List bytes) => parseHistory(utf8.decode(gzip.decode(bytes)));

class TerritoryMapFiles {
  // No header: sample folder only
  TerritoryMapFiles()
    : baseUrl = _devBaseUrl.isNotEmpty
          ? _devBaseUrl
          : territoryMapHeader.isEmpty
          ? '$territoryMapUrl/sample'
          : territoryMapUrl,
      sample = _devBaseUrl.isEmpty && territoryMapHeader.isEmpty;

  final String baseUrl;
  final bool sample;
  late final _headers = {
    if (territoryMapHeader.isNotEmpty && '$baseUrl/'.startsWith('$territoryMapUrl/')) 'x-pda-map': territoryMapHeader,
  };

  Future<Directory> _folder() async {
    final folder = Directory(
      '${(await getApplicationSupportDirectory()).path}/territory_map${sample ? '_sample' : ''}',
    );
    await folder.create(recursive: true);
    return folder;
  }

  Future<File> _file(String name) async => File('${(await _folder()).path}/$name');

  Future<TerritoryFile> decodeTerritories(Uint8List bytes) => compute(_territoriesFromGzip, bytes);

  Future<MapState> decodeState(Uint8List bytes) => compute(_stateFromGzip, bytes);

  Future<WarFile> decodeWar(Uint8List bytes) => compute(_warFromGzip, bytes);

  Future<DayChanges> decodeChanges(Uint8List bytes) => compute(_changesFromGzip, bytes);

  Future<MapHistory> decodeHistory(Uint8List bytes) => compute(_historyFromGzip, bytes);

  Future<Uint8List> readBundledTerritories() async {
    final data = await rootBundle.load(_bundledTerritories);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<CityGround> readBundledGround() async {
    final data = await rootBundle.load(_bundledGround);
    return compute(cityGroundFromGzip, data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<Surroundings> readBundledSurroundings() async {
    final data = await rootBundle.load(_bundledSurroundings);
    return compute(surroundingsFromGzip, data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<Relief> readBundledRelief() async {
    final data = await rootBundle.load(_bundledRelief);
    return compute(reliefFromGzip, data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  // far-day, mid-lights...
  Future<Uint8List> readSurroundingsPhoto(String name) async {
    final data = await rootBundle.load('assets/territory_map/surroundings-$name.webp');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<Uint8List?> readCached(String name) async {
    final file = await _file(name);
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<void> writeCached(String name, Uint8List bytes) async {
    final file = await _file(name);
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
  }

  Future<void> deleteCached(bool Function(String name) test) async {
    await for (final entity in (await _folder()).list()) {
      if (entity is File && test(entity.uri.pathSegments.last)) await entity.delete();
    }
  }

  Future<http.Response> _get(String path, {String etag = ''}) => http
      .get(Uri.parse('$baseUrl/$path'), headers: {..._headers, if (etag.isNotEmpty) 'If-None-Match': etag})
      .timeout(_timeout);

  // Null bytes means 304
  Future<({Uint8List? bytes, String etag})> fetchState(String etag) async {
    final response = await _get(stateFileName, etag: etag);
    if (response.statusCode == 304) return (bytes: null, etag: etag);
    if (response.statusCode == 404) throw const HttpException('none published yet');
    if (response.statusCode != 200) throw HttpException('download failed (${response.statusCode})');
    return (bytes: response.bodyBytes, etag: response.headers['etag'] ?? '');
  }

  // Null when not published yet
  Future<({Uint8List? bytes, String etag, bool immutable})?> _fetchPublished(
    String path,
    String etag,
    String what,
  ) async {
    final response = await _get(path, etag: etag);
    if (response.statusCode == 404) return null;
    if (response.statusCode == 304) return (bytes: null, etag: etag, immutable: false);
    if (response.statusCode != 200) throw HttpException('$what download failed (${response.statusCode})');
    final immutable = response.headers['cache-control']?.contains('immutable') ?? false;
    return (bytes: response.bodyBytes, etag: response.headers['etag'] ?? '', immutable: immutable);
  }

  Future<({Uint8List? bytes, String etag, bool immutable})?> fetchWar(int id, String etag) =>
      _fetchPublished('wars/$id.json.gz', etag, 'war');

  Future<({Uint8List? bytes, String etag, bool immutable})?> fetchChanges(String day, String etag) =>
      _fetchPublished('changes/$day.json.gz', etag, 'changes');

  Future<({Uint8List? bytes, String etag, bool immutable})?> fetchHistory(int year, String etag) =>
      _fetchPublished('history/$year.json.gz', etag, 'history');

  Future<Uint8List> fetchTerritories(int version) async {
    final response = await _get(territoriesFileName(version));
    if (response.statusCode != 200) throw HttpException('shapes download failed (${response.statusCode})');
    return response.bodyBytes;
  }
}
