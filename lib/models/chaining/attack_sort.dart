enum AttackSortType {
  levelDes,
  levelAsc,
  respectDes,
  respectAsc,
  dateDes,
  dateAsc
}

class AttackSort {
  AttackSortType type;
  String description;

  AttackSort({this.type}) {
    switch (type) {
      case AttackSortType.levelDes:
        description = 'Sort by level (des)';
        break;
      case AttackSortType.levelAsc:
        description = 'Sort by level (asc)';
        break;
      case AttackSortType.respectDes:
        description = 'Sort by respect (des)';
        break;
      case AttackSortType.respectAsc:
        description = 'Sort by respect (asc)';
        break;
      case AttackSortType.dateDes:
        description = 'Date (des)';
        break;
      case AttackSortType.dateAsc:
        description = 'Date (asc)';
        break;
    }
  }
}