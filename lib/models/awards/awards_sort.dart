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
  AwardsSortType type;
  String description;

  AwardsSort({this.type}) {
    switch (type) {
      case AwardsSortType.percentageDes:
        description = 'Sort by % (des)';
        break;
      case AwardsSortType.percentageAsc:
        description = 'Sort by % (asc)';
        break;
      case AwardsSortType.categoryDes:
        description = 'Sort by category (des)';
        break;
      case AwardsSortType.categoryAsc:
        description = 'Sort by category (asc)';
        break;
      case AwardsSortType.nameDes:
        description = 'Sort by name (des)';
        break;
      case AwardsSortType.nameAsc:
        description = 'Sort by name (asc)';
        break;
      case AwardsSortType.rarityAsc:
        description = 'Sort by rarity (des)';
        break;
      case AwardsSortType.rarityDesc:
        description = 'Sort by rarity (asc)';
        break;
      case AwardsSortType.daysAsc:
        description = 'Sort by days left (des)';
        break;
      case AwardsSortType.daysDes:
        description = 'Sort by days left (asc)';
        break;
    }
  }
}