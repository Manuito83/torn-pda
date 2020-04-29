enum TargetSort {
  levelDes,
  levelAsc,
  respectDes,
  respectAsc,
  nameDes,
  nameAsc
}

class TargetSortPopup {
  TargetSort type;
  String description;

  TargetSortPopup({this.type}) {
    switch (type) {
      case TargetSort.levelDes:
        description = 'Sort by level (des)';
        break;
      case TargetSort.levelAsc:
        description = 'Sort by level (asc)';
        break;
      case TargetSort.respectDes:
        description = 'Sort by respect (des)';
        break;
      case TargetSort.respectAsc:
        description = 'Sort by respect (asc)';
        break;
      case TargetSort.nameDes:
        description = 'Sort by name (des)';
        break;
      case TargetSort.nameAsc:
        description = 'Sort by name (asc)';
        break;
    }
  }
}