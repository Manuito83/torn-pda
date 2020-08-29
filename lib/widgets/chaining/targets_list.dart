import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/widgets/chaining/target_card.dart';

class TargetsList extends StatelessWidget {
  final List<TargetModel> targets;

  TargetsList({@required this.targets});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: getChildrenTargets(context),
    );
  }

  List<Widget> getChildrenTargets(BuildContext _) {
    var targetsProvider = Provider.of<TargetsProvider>(_, listen: false);
    String filter = targetsProvider.currentFilter;
    List<Widget> filteredCards = List<Widget>();
    for (var thisTarget in targets) {
      if (thisTarget.name.toUpperCase().contains(filter.toUpperCase())) {
        filteredCards.add(TargetCard(key: UniqueKey(), targetModel: thisTarget));
      }
    }
    // Avoid collisions with SnackBar
    filteredCards.add(SizedBox(height: 50));
    return filteredCards;
  }
}