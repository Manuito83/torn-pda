enum AttackSort {
  levelDes,
  levelAsc,
  respectDes,
  respectAsc,
  dateDes,
  dateAsc
}

class AttackSortPopup {
  AttackSort type;
  String description;

  AttackSortPopup({this.type}) {
    switch (type) {
      case AttackSort.levelDes:
        description = 'Sort by level (des)';
        break;
      case AttackSort.levelAsc:
        description = 'Sort by level (asc)';
        break;
      case AttackSort.respectDes:
        description = 'Sort by respect (des)';
        break;
      case AttackSort.respectAsc:
        description = 'Sort by respect (asc)';
        break;
      case AttackSort.dateDes:
        description = 'Date (des)';
        break;
      case AttackSort.dateAsc:
        description = 'Date (asc)';
        break;
    }
  }
}