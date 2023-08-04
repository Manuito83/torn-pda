// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/widgets/chaining/attack_card.dart';

class AttacksList extends StatelessWidget {
  final List<Attack> attacks;

  const AttacksList({required this.attacks});

  @override
  Widget build(BuildContext context) {
    if (attacks.isEmpty) {
      return Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 80.0, bottom: 20),
            child: CircularProgressIndicator(),
          ),
          const Text('Getting last attacks...'),
          _apiErrorWarning(context),
        ],
      );
    } else {
      return ListView(
        shrinkWrap: true,
        children: getChildrenTargets(context),
      );
    }
  }

  List<Widget> getChildrenTargets(BuildContext _) {
    // We'll use attack provider to get all the attacks
    final attacksProvider = Provider.of<AttacksProvider>(_, listen: false);
    // Also filtering words and type (all attacks or only those not added)
    final wordFilter = attacksProvider.currentFilter;
    final typeFilter = attacksProvider.currentTypeFilter;

    // Target provider is use to compare with the actual targets added to the
    // targets page, in case we want to filter them out
    final targetsProvider = Provider.of<TargetsProvider>(_, listen: false);
    final targetList = targetsProvider.allTargets;

    // Final list we'll show
    List<Widget> filteredCards = <Widget>[];

    for (final thisAttack in attacks) {
      bool addThisAttack = true;
      // If we are applying a filter to show only new targets, we loop
      // all the targets and discard if they have been added already
      if (typeFilter == AttackTypeFilter.unknownTargets) {
        for (final tar in targetList) {
          if (tar.playerId.toString() == thisAttack.targetId) {
            addThisAttack = false;
          }
        }
      }
      // Filter by search text and discard if it does not match
      if (!thisAttack.targetName!.toUpperCase().contains(wordFilter.toUpperCase())) {
        addThisAttack = false;
      }
      // Finally, add to list if it qualifies
      if (addThisAttack) {
        filteredCards.add(AttackCard(attackModel: thisAttack));
      }
    }
    // Avoid collisions with SnackBar
    filteredCards.add(const SizedBox(height: 50));
    return filteredCards;
  }

  Widget _apiErrorWarning(BuildContext _) {
    final attacksProvider = Provider.of<AttacksProvider>(_, listen: false);
    if (attacksProvider.getApiError) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Column(
                children: [
                  const Text(
                    'API ERROR',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    attacksProvider.getApiErrorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
