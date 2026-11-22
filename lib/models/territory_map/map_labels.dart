import 'dart:ui';

// First placed wins, none overlap
class LabelSpace {
  final _taken = <Rect>[];
  Rect _area = Rect.largest;

  Rect get area => _area;

  void clear([Rect area = Rect.largest]) {
    _taken.clear();
    _area = area;
  }

  // Kept clear even if overlapping
  void block(Rect box) => _taken.add(box);

  bool take(Rect box) {
    if (box.left < _area.left || box.top < _area.top || box.right > _area.right || box.bottom > _area.bottom) {
      return false;
    }
    for (final other in _taken) {
      if (other.overlaps(box)) return false;
    }
    _taken.add(box);
    return true;
  }
}
