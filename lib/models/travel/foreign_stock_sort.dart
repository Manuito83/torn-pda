enum StockSortType {
  country,
  name,
  type,
  quantity,
  price,
  value,
  profit,
}

class StockSort {
  StockSortType type;
  String description;

  StockSort({this.type}) {
    switch (type) {
      case StockSortType.country:
        description = 'Sort by country';
        break;
      case StockSortType.name:
        description = 'Sort by name';
        break;
      case StockSortType.type:
        description = 'Sort by type';
        break;
      case StockSortType.quantity:
        description = 'Sort by quantity';
        break;
      case StockSortType.price:
        description = 'Sort by price';
        break;
      case StockSortType.value:
        description = 'Sort by value';
        break;
      case StockSortType.profit:
        description = 'Sort by profit';
        break;
    }
  }
}