enum WarSortType {
  levelDes,
  levelAsc,
  respectDes,
  respectAsc,
  nameDes,
  nameAsc,
  colorAsc,
  colorDes,
}

class WarSort {
  WarSortType type;
  String description;

  WarSort({this.type}) {
    switch (type) {
      case WarSortType.levelDes:
        description = 'Sort by level (des)';
        break;
      case WarSortType.levelAsc:
        description = 'Sort by level (asc)';
        break;
      case WarSortType.respectDes:
        description = 'Sort by respect (des)';
        break;
      case WarSortType.respectAsc:
        description = 'Sort by respect (asc)';
        break;
      case WarSortType.nameDes:
        description = 'Sort by name (des)';
        break;
      case WarSortType.nameAsc:
        description = 'Sort by name (asc)';
        break;
      case WarSortType.colorDes:
        description = 'Sort by color (#-R-Y-G)';
        break;
      case WarSortType.colorAsc:
        description = 'Sort by color (G-Y-R-#)';
        break;
    }
  }
}
