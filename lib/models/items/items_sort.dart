enum ItemsSortType {
  nameDes,
  nameAsc,
  categoryDes,
  categoryAsc,
  ownedDes,
  ownedAsc,
  valueDes,
  valueAsc,
  circulationDes,
  circulationAsc,
}

class ItemsSort {
  ItemsSortType type;
  String description;

  ItemsSort({this.type}) {
    switch (type) {
      case ItemsSortType.nameDes:
        description = 'Sort by name (des)';
        break;
      case ItemsSortType.nameAsc:
        description = 'Sort by name (asc)';
        break;
      case ItemsSortType.categoryDes:
        description = 'Sort by category (des)';
        break;
      case ItemsSortType.categoryAsc:
        description = 'Sort by category (asc)';
        break;
      case ItemsSortType.ownedDes:
        description = 'Sort by inventory (des)';
        break;
      case ItemsSortType.ownedAsc:
        description = 'Sort by inventory (asc)';
        break;
      case ItemsSortType.valueDes:
        description = 'Sort by value (des)';
        break;
      case ItemsSortType.valueAsc:
        description = 'Sort by value (asc)';
        break;
      case ItemsSortType.circulationDes:
        description = 'Sort by circulation (des)';
        break;
      case ItemsSortType.circulationAsc:
        description = 'Sort by circulation (asc)';
        break;
    }
  }
}
