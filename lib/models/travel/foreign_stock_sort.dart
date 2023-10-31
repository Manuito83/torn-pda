enum StockSortType { country, name, type, quantity, price, value, profit, arrivalTime, inventoryQuantity }

class StockSort {
  StockSortType? type;
  String? description;

  StockSort({this.type}) {
    switch (type) {
      case StockSortType.country:
        description = 'Sort by country';
      case StockSortType.name:
        description = 'Sort by name';
      case StockSortType.type:
        description = 'Sort by type';
      case StockSortType.quantity:
        description = 'Sort by quantity (abroad)';
      case StockSortType.price:
        description = 'Sort by price';
      case StockSortType.value:
        description = 'Sort by value';
      case StockSortType.profit:
        description = 'Sort by profit';
      case StockSortType.arrivalTime:
        description = 'Sort by arrival time';
      /*
      case StockSortType.inventoryQuantity:
        description = 'Sort by quantity (inventory)';
      */
      default:
        description = 'Sort by name';
        break;
    }
  }
}
