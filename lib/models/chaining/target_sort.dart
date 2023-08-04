enum TargetSortType {
  levelDes,
  levelAsc,
  respectDes,
  respectAsc,
  ffDes,
  ffAsc,
  nameDes,
  nameAsc,
  lifeDes,
  lifeAsc,
  colorAsc,
  colorDes,
  onlineDes,
  onlineAsc,
  notesDes,
  notesAsc,
}

class TargetSort {
  TargetSortType? type;
  late String description;

  TargetSort({this.type}) {
    switch (type) {
      case TargetSortType.levelDes:
        description = 'Sort by level (des)';
      case TargetSortType.levelAsc:
        description = 'Sort by level (asc)';
      case TargetSortType.respectDes:
        description = 'Sort by respect (des)';
      case TargetSortType.respectAsc:
        description = 'Sort by respect (asc)';
      case TargetSortType.ffDes:
        description = 'Sort by fair fight (des)';
      case TargetSortType.ffAsc:
        description = 'Sort by fair fight (asc)';
      case TargetSortType.nameDes:
        description = 'Sort by name (des)';
      case TargetSortType.nameAsc:
        description = 'Sort by name (asc)';
      case TargetSortType.lifeDes:
        description = 'Sort by life (des)';
      case TargetSortType.lifeAsc:
        description = 'Sort by life (asc)';
      case TargetSortType.colorDes:
        description = 'Sort by color (#-R-Y-G)';
      case TargetSortType.colorAsc:
        description = 'Sort by color (G-Y-R-#)';
      case TargetSortType.onlineDes:
        description = 'Sort online';
      case TargetSortType.onlineAsc:
        description = 'Sort offline';
      case TargetSortType.notesDes:
        description = 'Sort by note (des)';
      case TargetSortType.notesAsc:
        description = 'Sort by note (asc)';
      default:
        description = 'Sort by respect (des)';
        break;
    }
  }
}
