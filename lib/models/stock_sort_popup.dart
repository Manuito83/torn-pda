enum StockSort {
  country,
  name,
  type,
  price,
  value,
  profit,
}

class StockSortPopup {
  StockSort type;
  String description;

  StockSortPopup({this.type}) {
    switch (type) {
      case StockSort.country:
        description = 'Sort by country';
        break;
      case StockSort.name:
        description = 'Sort by name';
        break;
      case StockSort.type:
        description = 'Sort by type';
        break;
      case StockSort.price:
        description = 'Sort by price';
        break;
      case StockSort.value:
        description = 'Sort by value';
        break;
      case StockSort.profit:
        description = 'Sort by profit';
        break;
    }
  }
}