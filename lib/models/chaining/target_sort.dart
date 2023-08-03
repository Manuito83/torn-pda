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
      case TargetSortType.ffDes:
        description = 'Sort by fair fight (des)';
        break;
      case TargetSortType.ffAsc:
        description = 'Sort by fair fight (asc)';
        break;
      case TargetSortType.nameDes:
        description = 'Sort by name (des)';
        break;
      case TargetSortType.nameAsc:
        description = 'Sort by name (asc)';
        break;
      case TargetSortType.lifeDes:
        description = 'Sort by life (des)';
        break;
      case TargetSortType.lifeAsc:
        description = 'Sort by life (asc)';
        break;
      case TargetSortType.colorDes:
        description = 'Sort by color (#-R-Y-G)';
        break;
      case TargetSortType.colorAsc:
        description = 'Sort by color (G-Y-R-#)';
        break;
      case TargetSortType.onlineDes:
        description = 'Sort online';
        break;
      case TargetSortType.onlineAsc:
        description = 'Sort offline';
        break;
      case TargetSortType.notesDes:
        description = 'Sort by note (des)';
        break;
      case TargetSortType.notesAsc:
        description = 'Sort by note (asc)';
        break;
      default:
        description = 'Sort by respect (des)';
        break;
    }
  }
}
