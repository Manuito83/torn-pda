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

  const FriendsList({required this.friends});

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    final String filter = friendsProvider.currentFilter;

    // Filter friends by name
    final filteredFriends = friends
        .where((f) => f.name!.toUpperCase().contains(filter.toUpperCase()))
        .toList();

    // +1 for bottom padding SizedBox
    final itemCount = filteredFriends.length + 1;

    if (MediaQuery.orientationOf(context) == Orientation.portrait) {
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == filteredFriends.length) {
            // Avoid collisions with SnackBar
            return const SizedBox(height: 50);
          }
          return FriendCard(friendModel: filteredFriends[index]);
        },
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == filteredFriends.length) {
            // Avoid collisions with SnackBar
            return const SizedBox(height: 50);
          }
          return FriendCard(friendModel: filteredFriends[index]);
        },
      );
    }
  }
}
