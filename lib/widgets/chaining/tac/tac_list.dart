// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:torn_pda/models/chaining/tac/tac_target_model.dart';
import 'package:torn_pda/providers/tac_provider.dart';

// Project imports:
import 'package:torn_pda/widgets/chaining/tac/tac_card.dart';

class TacList extends StatelessWidget {
  final List<TacTarget> targets;
  final TacProvider tacProvider;

  TacList({@required this.targets, @required this.tacProvider});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return ListView(children: getChildrenTargets(context));
    } else {
      return ListView(
        children: getChildrenTargets(context),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
      );
    }
  }

  List<Widget> getChildrenTargets(BuildContext _) {
    List<Widget> filteredCards = <Widget>[];
    for (var thisTarget in targets) {
      filteredCards.add(
        TacCard(
          key: UniqueKey(),
          target: thisTarget,
          tacProvider: tacProvider,
        ),
      );
    }
    filteredCards.add(SizedBox(height: 50));
    return filteredCards;
  }
}
