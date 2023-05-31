// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/chain_panic_target_model.dart';

// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/widgets/chaining/target_card.dart';

class TargetsList extends StatefulWidget {
  final List<TargetModel> targets;

  TargetsList({@required this.targets});

  @override
  State<TargetsList> createState() => _TargetsListState();
}

class _TargetsListState extends State<TargetsList> {
  TargetsProvider _targetsProvider;
  ChainStatusProvider _chainStatusProvider;

  @override
  void initState() {
    super.initState();
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: widget.targets.length,
        itemBuilder: (context, index) {
          return SlidableCard(index, context);
        },
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: widget.targets.length,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return SlidableCard(index, context);
        },
      );
    }
  }

  Widget SlidableCard(int index, BuildContext context) {
    if (!widget.targets[index].name.toUpperCase().contains(_targetsProvider.currentWordFilter.toUpperCase()) ||
        _targetsProvider.currentColorFilterOut.contains(widget.targets[index].personalNoteColor)) {
      return SizedBox.shrink();
    }

    return Slidable(
      closeOnScroll: false,
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            label: 'Remove',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (context) {
              _targetsProvider.deleteTarget(widget.targets[index]);
              BotToast.showText(
                text: 'Deleted ${widget.targets[index].name}!',
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.orange[800],
                duration: Duration(seconds: 5),
                contentPadding: EdgeInsets.all(10),
              );
            },
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.5,
        children: [
          _chainStatusProvider.panicTargets.where((t) => t.name == widget.targets[index].name).length == 0
              ? SlidableAction(
                  label: 'Add to panic!',
                  backgroundColor: Colors.blue,
                  icon: MdiIcons.alphaPCircleOutline,
                  onPressed: (context) {
                    String message = "Added ${widget.targets[index].name} as a Panic Mode target!";
                    Color messageColor = Colors.green;

                    if (_chainStatusProvider.panicTargets.length < 10) {
                      setState(() {
                        _chainStatusProvider.addPanicTarget(
                          PanicTargetModel()
                            ..name = widget.targets[index].name
                            ..level = widget.targets[index].level
                            ..id = widget.targets[index].playerId
                            ..factionName = widget.targets[index].faction.factionName,
                        );
                      });
                    } else {
                      message = "There are already 10 targets in the Panic Mode list, remove some!";
                      messageColor = Colors.orange[700];
                    }

                    BotToast.showText(
                      text: message,
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: messageColor,
                      duration: Duration(seconds: 5),
                      contentPadding: EdgeInsets.all(10),
                    );
                  },
                )
              : SlidableAction(
                  label: 'PANIC TARGET',
                  backgroundColor: Colors.blue,
                  icon: MdiIcons.alphaPCircleOutline,
                  onPressed: (context) {
                    String message = "Removed ${widget.targets[index].name} as a Panic Mode target!";
                    Color messageColor = Colors.green;

                    setState(() {
                      _chainStatusProvider.removePanicTarget(
                        PanicTargetModel()
                          ..name = widget.targets[index].name
                          ..level = widget.targets[index].level
                          ..id = widget.targets[index].playerId
                          ..factionName = widget.targets[index].faction.factionName,
                      );
                    });

                    BotToast.showText(
                      text: message,
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: messageColor,
                      duration: Duration(seconds: 5),
                      contentPadding: EdgeInsets.all(10),
                    );
                  },
                ),
        ],
      ),
      child: TargetCard(
        key: UniqueKey(),
        targetModel: widget.targets[index],
      ),
    );
  }

  List<Widget> getChildrenTargets(BuildContext _) {
    var targetsProvider = Provider.of<TargetsProvider>(_, listen: false);
    String filter = targetsProvider.currentWordFilter;
    List<Widget> filteredCards = <Widget>[];
    for (var thisTarget in widget.targets) {
      if (thisTarget.name.toUpperCase().contains(filter.toUpperCase())) {
        if (!targetsProvider.currentColorFilterOut.contains(thisTarget.personalNoteColor)) {
          filteredCards.add(TargetCard(key: UniqueKey(), targetModel: thisTarget));
        }
      }
    }
    // Avoid collisions with SnackBar
    filteredCards.add(SizedBox(height: 50));
    return filteredCards;
  }
}
