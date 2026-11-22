import 'package:torn_pda/models/territory_map/city_sky.dart';

const _gib = 1 << 30;

enum SurroundingsQuality {
  full(midShare: 1, near: true, stripShare: 1, atlasShare: 1, outside: fullOutside),
  light(
    midShare: 0.6,
    near: false,
    stripShare: 0.6,
    atlasShare: 0.6,
    outside: (ships: 11, clouds: 0, shadows: 6, glints: 0, cars: 0.5),
  ),
  minimal(midShare: 0, near: false, stripShare: 0.35, atlasShare: 0.4, outside: noOutside);

  const SurroundingsQuality({
    required this.midShare,
    required this.near,
    required this.stripShare,
    required this.atlasShare,
    required this.outside,
  });

  // Zero skips the mid photo
  final double midShare;
  final bool near;
  final double stripShare;

  // 3D ground texture
  final double atlasShare;
  final OutsideBudget outside;
}

// Android reports less than it sells, iOS not
SurroundingsQuality surroundingsQualityFor(int? totalMemory, {bool exact = false}) {
  if (totalMemory == null) return SurroundingsQuality.light;
  if (totalMemory < (exact ? 2.5 : 3) * _gib) return SurroundingsQuality.minimal;
  if (totalMemory < (exact ? 3.5 : 5) * _gib) return SurroundingsQuality.light;
  return SurroundingsQuality.full;
}
