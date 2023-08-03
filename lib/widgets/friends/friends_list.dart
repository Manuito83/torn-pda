// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/widgets/friends/friend_card.dart';

class FriendsList extends StatelessWidget {
  final List<FriendModel> friends;

  FriendsList({required this.friends});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return ListView(children: getChildrenFriends(context));
    } else {
      return ListView(
        children: getChildrenFriends(context),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
      );
    }
  }

  List<Widget> getChildrenFriends(BuildContext _) {
    var friendsProvider = Provider.of<FriendsProvider>(_, listen: false);
    String filter = friendsProvider.currentFilter;
    List<Widget> filteredCards = <Widget>[];
    for (var thisFriend in friends) {
      if (thisFriend.name!.toUpperCase().contains(filter.toUpperCase())) {
        filteredCards.add(FriendCard(friendModel: thisFriend));
      }
    }
    // Avoid collisions with SnackBar
    filteredCards.add(SizedBox(height: 50));
    return filteredCards;
  }
}
