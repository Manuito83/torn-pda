import 'package:flutter/material.dart';
import 'package:torn_pda/models/loot/loot_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class LootFilterDialog extends StatefulWidget {
  final Map<String, LootModel> allNpcs;
  final List<String> filteredNpcs;

  LootFilterDialog({@required this.allNpcs, @required this.filteredNpcs});

  @override
  _LootFilterDialogState createState() => _LootFilterDialogState();
}

class _LootFilterDialogState extends State<LootFilterDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Filter out NPCs"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "Choose if you would like to filter OUT NPCs (only currently active NPCs are shown)",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _npcs(),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: TextButton(
            child: Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        )
      ],
    );
  }

  Column _npcs() {
    var npcRows = <Widget>[];

    widget.allNpcs.forEach((key, value) {
      npcRows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(value.name),
            Switch(
              value: widget.filteredNpcs.contains(key) ? true : false,
              onChanged: (value) {
                if (value) {
                  setState(() {
                    widget.filteredNpcs.add(key);
                  });
                } else {
                  setState(() {
                    widget.filteredNpcs.remove(key);
                  });
                }
                Prefs().setLootFiltered(widget.filteredNpcs);
              },
              activeTrackColor: Colors.redAccent[100],
              activeColor: Colors.red,
              inactiveThumbColor: Colors.green[100],
            ),
          ],
        ),
      );
    });

    return Column(
      children: npcRows,
    );
  }
}
