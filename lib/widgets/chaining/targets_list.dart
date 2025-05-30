// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:get/get.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/chain_panic_target_model.dart';

// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/widgets/chaining/target_card.dart';

class TargetsList extends StatefulWidget {
  final List<TargetModel> targets;

  const TargetsList({required this.targets});

  @override
  State<TargetsList> createState() => TargetsListState();
}

class TargetsListState extends State<TargetsList> {
  late TargetsProvider _targetsProvider;
  final _chainStatusProvider = Get.find<ChainStatusController>();

  @override
  void initState() {
    super.initState();
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.orientationOf(context) == Orientation.portrait) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: widget.targets.length,
        itemBuilder: (context, index) {
          return slidableCard(index, context);
        },
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: widget.targets.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return slidableCard(index, context);
        },
      );
    }
  }

  Widget slidableCard(int index, BuildContext context) {
    if (!widget.targets[index].name!.toUpperCase().contains(_targetsProvider.currentWordFilter.toUpperCase()) ||
        _targetsProvider.currentColorFilterOut.contains(widget.targets[index].personalNoteColor)) {
      return const SizedBox.shrink();
    }

    return Slidable(
      key: ValueKey(widget.targets[index].playerId),
      closeOnScroll: false,
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            label: 'Remove',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (context) {
              BotToast.showText(
                text: 'Deleted ${widget.targets[index].name}!',
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.orange[800]!,
                duration: const Duration(seconds: 5),
                contentPadding: const EdgeInsets.all(10),
              );
              _targetsProvider.deleteTarget(widget.targets[index]);
            },
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (_chainStatusProvider.panicTargets.where((t) => t.name == widget.targets[index].name).isEmpty)
            SlidableAction(
              label: 'Add to panic!',
              backgroundColor: Colors.blue,
              icon: MdiIcons.alphaPCircleOutline,
              onPressed: (context) {
                String message = "Added ${widget.targets[index].name} as a Panic Mode target!";
                Color? messageColor = Colors.green;

                if (_chainStatusProvider.panicTargets.length < 10) {
                  setState(() {
                    _chainStatusProvider.addPanicTarget(
                      PanicTargetModel()
                        ..name = widget.targets[index].name
                        ..level = widget.targets[index].level
                        ..id = widget.targets[index].playerId
                        ..factionName = widget.targets[index].faction!.factionName,
                    );
                  });
                } else {
                  message = "There are already 10 targets in the Panic Mode list, remove some!";
                  messageColor = Colors.orange[700];
                }

                BotToast.showText(
                  text: message,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: messageColor!,
                  duration: const Duration(seconds: 5),
                  contentPadding: const EdgeInsets.all(10),
                );
              },
            )
          else
            SlidableAction(
              label: 'PANIC TARGET',
              backgroundColor: Colors.blue,
              icon: MdiIcons.alphaPCircleOutline,
              onPressed: (context) {
                final String message = "Removed ${widget.targets[index].name} as a Panic Mode target!";
                const Color messageColor = Colors.green;

                setState(() {
                  _chainStatusProvider.removePanicTarget(
                    PanicTargetModel()
                      ..name = widget.targets[index].name
                      ..level = widget.targets[index].level
                      ..id = widget.targets[index].playerId
                      ..factionName = widget.targets[index].faction!.factionName,
                  );
                });

                BotToast.showText(
                  text: message,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: messageColor,
                  duration: const Duration(seconds: 5),
                  contentPadding: const EdgeInsets.all(10),
                );
              },
            ),
        ],
      ),
      child: TargetCard(
        key: ValueKey(widget.targets[index].playerId),
        targetModel: widget.targets[index],
      ),
    );
  }
}
