enum FriendSortType {
  levelDes,
  levelAsc,
  nameDes,
  nameAsc,
  factionDes,
  factionAsc,
}

class FriendSort {
  FriendSortType type;
  String description;

  FriendSort({this.type}) {
    switch (type) {
      case FriendSortType.levelDes:
        description = 'Sort by level (des)';
        break;
      case FriendSortType.levelAsc:
        description = 'Sort by level (asc)';
        break;
      case FriendSortType.nameDes:
        description = 'Sort by name (des)';
        break;
      case FriendSortType.nameAsc:
        description = 'Sort by name (asc)';
        break;
      case FriendSortType.factionDes:
        description = 'Sort by faction (des)';
        break;
      case FriendSortType.factionAsc:
        description = 'Sort by faction (asc)';
        break;
    }
  }
}