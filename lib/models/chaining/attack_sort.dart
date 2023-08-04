enum AttackSortType { levelDes, levelAsc, respectDes, respectAsc, dateDes, dateAsc }

class AttackSort {
  AttackSortType? type;
  late String description;

  AttackSort({this.type}) {
    switch (type) {
      case AttackSortType.levelDes:
        description = 'Sort by level (des)';
      case AttackSortType.levelAsc:
        description = 'Sort by level (asc)';
      case AttackSortType.respectDes:
        description = 'Sort by respect (des)';
      case AttackSortType.respectAsc:
        description = 'Sort by respect (asc)';
      case AttackSortType.dateDes:
        description = 'Date (des)';
      case AttackSortType.dateAsc:
        description = 'Date (asc)';
      default:
        description = 'Sort by respect (des)';
    }
  }
}
