enum ItemsSortType {
  nameDes,
  nameAsc,
  categoryDes,
  categoryAsc,
  ownedDes,
  ownedAsc,
  valueDes,
  valueAsc,
  totalValueDes,
  totalValueAsc,
  circulationDes,
  circulationAsc,
  idDes,
  idAsc,
}

class ItemsSort {
  ItemsSortType? type;
  late String description;

  ItemsSort({this.type}) {
    switch (type) {
      case ItemsSortType.nameDes:
        description = 'Sort by name (des)';
      case ItemsSortType.nameAsc:
        description = 'Sort by name (asc)';
      case ItemsSortType.categoryDes:
        description = 'Sort by category (des)';
      case ItemsSortType.categoryAsc:
        description = 'Sort by category (asc)';
      case ItemsSortType.ownedDes:
        description = 'Sort by inventory (des)';
      case ItemsSortType.ownedAsc:
        description = 'Sort by inventory (asc)';
      case ItemsSortType.valueDes:
        description = 'Sort by value (des)';
      case ItemsSortType.valueAsc:
        description = 'Sort by value (asc)';
      case ItemsSortType.totalValueDes:
        description = 'Sort by total value (des)';
      case ItemsSortType.totalValueAsc:
        description = 'Sort by total value (asc)';
      case ItemsSortType.circulationDes:
        description = 'Sort by circulation (des)';
      case ItemsSortType.circulationAsc:
        description = 'Sort by circulation (asc)';
      case ItemsSortType.idDes:
        description = 'Sort by id (des)';
      case ItemsSortType.idAsc:
        description = 'Sort by id (asc)';
      default:
        description = 'Sort by name (asc)';
        break;
    }
  }
}
