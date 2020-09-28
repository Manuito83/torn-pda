enum TargetSortType {
  levelDes,
  levelAsc,
  respectDes,
  respectAsc,
  nameDes,
  nameAsc,
  colorAsc,
  colorDes,
}

class TargetSort {
  TargetSortType type;
  String description;

  TargetSort({this.type}) {
    switch (type) {
      case TargetSortType.levelDes:
        description = 'Sort by level (des)';
        break;
      case TargetSortType.levelAsc:
        description = 'Sort by level (asc)';
        break;
      case TargetSortType.respectDes:
        description = 'Sort by respect (des)';
        break;
      case TargetSortType.respectAsc:
        description = 'Sort by respect (asc)';
        break;
      case TargetSortType.nameDes:
        description = 'Sort by name (des)';
        break;
      case TargetSortType.nameAsc:
        description = 'Sort by name (asc)';
        break;
      case TargetSortType.colorDes:
        description = 'Sort by color (R-Y-G-B)';
        break;
      case TargetSortType.colorAsc:
        description = 'Sort by color (B-G-Y-R)';
        break;
    }
  }
}