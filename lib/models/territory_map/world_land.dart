import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class LandRing {
  LandRing(this.lonLat, this.unit);

  // Flat lon, lat in degrees
  final Float64List lonLat;

  // Flat x, y, z on the unit sphere
  final Float64List unit;

  int get length => lonLat.length ~/ 2;
}

class WorldName {
  const WorldName(this.name, this.lon, this.lat, this.minLabel);

  final String name;
  final double lon;
  final double lat;

  // Web map zoom where it fits
  final double minLabel;
}

class WorldLand {
  const WorldLand(this.polygons, {this.names = const []});

  final List<List<LandRing>> polygons;

  // Biggest countries first
  final List<WorldName> names;
}

WorldLand worldLandFromGzip(Uint8List bytes, {Uint8List? names}) {
  final polygons = jsonDecode(utf8.decode(gzip.decode(bytes))) as List;
  return WorldLand(
    [
      for (final polygon in polygons) [for (final ring in polygon as List) _ring((ring as List).cast<int>())],
    ],
    names: names == null
        ? const []
        : [
            for (final row in jsonDecode(utf8.decode(gzip.decode(names))) as List)
              WorldName(row[0] as String, (row[1] as int) / 100, (row[2] as int) / 100, (row[3] as int) / 10),
          ],
  );
}

LandRing _ring(List<int> hundredths) {
  final count = hundredths.length ~/ 2;
  final lonLat = Float64List(count * 2);
  final unit = Float64List(count * 3);
  for (var i = 0; i < count; i++) {
    final lon = hundredths[i * 2] / 100;
    final lat = hundredths[i * 2 + 1] / 100;
    lonLat[i * 2] = lon;
    lonLat[i * 2 + 1] = lat;
    final lambda = lon * pi / 180;
    final phi = lat * pi / 180;
    unit[i * 3] = cos(phi) * cos(lambda);
    unit[i * 3 + 1] = cos(phi) * sin(lambda);
    unit[i * 3 + 2] = sin(phi);
  }
  return LandRing(lonLat, unit);
}
