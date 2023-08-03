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
      case ItemsSortType.totalValueDes:
        description = 'Sort by total value (des)';
        break;
      case ItemsSortType.totalValueAsc:
        description = 'Sort by total value (asc)';
        break;
      case ItemsSortType.circulationDes:
        description = 'Sort by circulation (des)';
        break;
      case ItemsSortType.circulationAsc:
        description = 'Sort by circulation (asc)';
        break;
      case ItemsSortType.idDes:
        description = 'Sort by id (des)';
        break;
      case ItemsSortType.idAsc:
        description = 'Sort by id (asc)';
        break;
      default:
        description = 'Sort by name (asc)';
        break;
    }
  }
}
