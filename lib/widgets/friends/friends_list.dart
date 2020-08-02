import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/widgets/friends/friend_card.dart';

class FriendsList extends StatelessWidget {
  final List<FriendModel> friends;

  FriendsList({@required this.friends});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: getChildrenFriends(context),
    );
  }

  List<Widget> getChildrenFriends(BuildContext _) {
    var friendsProvider = Provider.of<FriendsProvider>(_, listen: false);
    String filter = friendsProvider.currentFilter;
    List<Widget> filteredCards = List<Widget>();
    for (var thisFriend in friends) {
      if (thisFriend.name.toUpperCase().contains(filter.toUpperCase())) {
        filteredCards.add(FriendCard(friendModel: thisFriend));
      }
    }
    // Avoid collisions with SnackBar
    filteredCards.add(SizedBox(height: 50));
    return filteredCards;
  }
}