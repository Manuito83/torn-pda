import 'dart:math';
import 'dart:ui';

typedef Horizon = ({double flat, double length});

const _hazeReach = 8200.0;
const _hazePower = 1.6;
const _pastHorizon = 450.0;
const _insideFarImage = 100.0;

double distanceToRect(Offset point, Rect rect) =>
    (point - Offset(point.dx.clamp(rect.left, rect.right), point.dy.clamp(rect.top, rect.bottom))).distance;

// Map distance for a world distance
double horizonDistance(double distance, Horizon horizon) => distance <= horizon.flat
    ? distance
    : horizon.flat + horizon.length * (1 - exp(-(distance - horizon.flat) / horizon.length));

// How big things look that far out
double horizonSize(double distance, Horizon horizon) =>
    distance <= horizon.flat ? 1 : exp(-(distance - horizon.flat) / horizon.length);

double haze(double distance) => 1 - exp(-pow(distance / _hazeReach, _hazePower));

// Opacity left after the haze takes its bite
double hazeFade(double distance, double bite) => max(0.0, 1 - haze(distance) * bite);

// World point squeezed towards the horizon
Offset towardsHorizon(Offset world, Rect bounds, Horizon horizon) {
  final nearest = Offset(world.dx.clamp(bounds.left, bounds.right), world.dy.clamp(bounds.top, bounds.bottom));
  final away = world - nearest;
  final distance = away.distance;
  if (distance <= horizon.flat) return world;
  return nearest + away * (horizonDistance(distance, horizon) / distance);
}

({Offset at, double size, double distance}) squeezed(Offset world, Rect bounds, Horizon horizon) {
  final distance = distanceToRect(world, bounds);
  return (at: towardsHorizon(world, bounds, horizon), size: horizonSize(distance, horizon), distance: distance);
}

// Never past horizon or far photo
Rect viewReach(Rect bounds, Horizon horizon, Rect far) {
  final past = horizon.flat + horizon.length + _pastHorizon;
  return Rect.fromLTRB(
    max(bounds.left - past, far.left + _insideFarImage),
    max(bounds.top - past, far.top + _insideFarImage),
    min(bounds.right + past, far.right - _insideFarImage),
    min(bounds.bottom + past, far.bottom - _insideFarImage),
  );
}
