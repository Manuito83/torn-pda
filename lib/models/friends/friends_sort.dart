enum FriendSortType {
  levelDes,
  levelAsc,
  nameDes,
  nameAsc,
  factionDes,
  factionAsc,
}

class FriendSort {
  FriendSortType? type;
  late String description;

  FriendSort({this.type}) {
    switch (type) {
      case FriendSortType.levelDes:
        description = 'Sort by level (des)';
      case FriendSortType.levelAsc:
        description = 'Sort by level (asc)';
      case FriendSortType.nameDes:
        description = 'Sort by name (des)';
      case FriendSortType.nameAsc:
        description = 'Sort by name (asc)';
      case FriendSortType.factionDes:
        description = 'Sort by faction (des)';
      case FriendSortType.factionAsc:
        description = 'Sort by faction (asc)';
      default:
        description = 'Sort by level (asc)';
        break;
    }
  }
}
