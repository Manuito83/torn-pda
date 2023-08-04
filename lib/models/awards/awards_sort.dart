enum AwardsSortType {
  percentageDes,
  percentageAsc,
  categoryDes,
  categoryAsc,
  nameDes,
  nameAsc,
  rarityAsc,
  rarityDesc,
  daysAsc,
  daysDes,
}

class AwardsSort {
  AwardsSortType? type;
  late String description;

  AwardsSort({this.type}) {
    switch (type) {
      case AwardsSortType.percentageDes:
        description = 'Sort by % (des)';
      case AwardsSortType.percentageAsc:
        description = 'Sort by % (asc)';
      case AwardsSortType.categoryDes:
        description = 'Sort by category (des)';
      case AwardsSortType.categoryAsc:
        description = 'Sort by category (asc)';
      case AwardsSortType.nameDes:
        description = 'Sort by name (des)';
      case AwardsSortType.nameAsc:
        description = 'Sort by name (asc)';
      case AwardsSortType.rarityAsc:
        description = 'Sort by rarity (des)';
      case AwardsSortType.rarityDesc:
        description = 'Sort by rarity (asc)';
      case AwardsSortType.daysDes:
        description = 'Sort by days left (des)';
      case AwardsSortType.daysAsc:
        description = 'Sort by days left (asc)';
      default:
        description = 'Sort by % (des)';
        break;
    }
  }
}
