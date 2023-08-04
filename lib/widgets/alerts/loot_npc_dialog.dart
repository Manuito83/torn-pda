// Flutter imports:
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/target_model.dart';

// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';

class NpcAlertModel {
  String name = "";
  String id = "";
  bool level4 = false;
  bool level5 = false;
}

class LootAlertsDialog extends StatefulWidget {
  final FirebaseUserModel? userModel;

  const LootAlertsDialog({required this.userModel});

  @override
  _LootAlertsDialogState createState() => _LootAlertsDialogState();
}

class _LootAlertsDialogState extends State<LootAlertsDialog> {
  FirebaseUserModel? _firebaseUserModel;

  final List<NpcAlertModel> _npcAlertModelList = <NpcAlertModel>[];

  Future? _npcsInitialised;

  @override
  void initState() {
    super.initState();
    _firebaseUserModel = widget.userModel;
    _npcsInitialised = _initialiseNpcs();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Loot alerts"),
      content: SizedBox(
        width: double.maxFinite,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Choose which NPCs and levels you would like to be alerted about",
                  style: TextStyle(fontSize: 14),
                ),
                FutureBuilder(
                  future: _npcsInitialised,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (_npcAlertModelList.isEmpty) {
                        return const Text(
                          "\nError!\n\nThere was a problem retrieving your current configuration from the database. "
                          "\n\nPlease check your internet connection or use the hammer icon at the top to reset your alert "
                          "preferences.",
                          style: TextStyle(fontSize: 14, color: Colors.red),
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _npcAlertModelList.length,
                            itemBuilder: (context, index) {
                              return NpcAlertConfigLine(
                                npcAlertModel: _npcAlertModelList[index],
                                npcLineNumber: index,
                                firebaseUserModel: _firebaseUserModel,
                              );
                            },
                          ),
                        );
                      }
                    }
                    return const Padding(
                      padding: EdgeInsets.only(top: 30.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 15),
                          Text(
                            "Retrieving configuration...",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: TextButton(
            child: const Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        )
      ],
    );
  }

  Future _initialiseNpcs() async {
    // Get current NPCs
    final String dbNpcsResult = (await FirebaseDatabase.instance.ref().child("loot/npcs").once()).snapshot.value as String;
    final List npcIds = dbNpcsResult.replaceAll(" ", "").split(",");

    // Get npc names. First with the known ones, then calling the API as last resort
    for (final String id in npcIds as Iterable<String>) {
      String? name = "";
      if (id == "4") {
        name = "Duke";
      } else if (id == "15") {
        name = "Leslie";
      } else if (id == "17") {
        name = "Easter Bunny";
      } else if (id == "19") {
        name = "Jimmy";
      } else if (id == "20") {
        name = "Fernando";
      } else if (id == "21") {
        name = "Tiny";
      } else {
        final tornTarget = await Get.find<ApiCallerController>().getTarget(playerId: id);
        if (tornTarget is TargetModel) {
          name = tornTarget.name;
        } else {
          continue;
        }
      }

      // Initialise model list
      final NpcAlertModel thisModel = NpcAlertModel();
      thisModel.id = id;
      thisModel.name = name!;

      // See if the user has any alert active for this NPC in the realtime database
      final firestoreActive = _firebaseUserModel!.lootAlerts;
      if (firestoreActive.contains("$id:4")) {
        thisModel.level4 = true;
      }

      if (firestoreActive.contains("$id:5")) {
        thisModel.level5 = true;
      }

      _npcAlertModelList.add(thisModel);
    }
  }
}

class NpcAlertConfigLine extends StatefulWidget {
  final NpcAlertModel npcAlertModel;
  final int npcLineNumber;
  final FirebaseUserModel? firebaseUserModel;

  const NpcAlertConfigLine({
    required this.npcAlertModel,
    required this.npcLineNumber,
    required this.firebaseUserModel,
    super.key,
  });

  @override
  State<NpcAlertConfigLine> createState() => _NpcAlertConfigLineState();
}

class _NpcAlertConfigLineState extends State<NpcAlertConfigLine> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: widget.npcLineNumber == 0 ? 15 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              widget.npcAlertModel.name,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Column(
            children: [
              if (widget.npcLineNumber == 0)
                const Baseline(
                  baseline: 0,
                  baselineType: TextBaseline.alphabetic,
                  child: Text(
                    "LEVEL 4",
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              Switch(
                value: widget.firebaseUserModel!.lootAlerts.contains("${widget.npcAlertModel.id}:4"),
                onChanged: (value) {
                  setState(() {
                    firestore.toggleNpcAlert(id: widget.npcAlertModel.id, level: 4, active: value);
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 15),
          Column(
            children: [
              if (widget.npcLineNumber == 0)
                const Baseline(
                  baseline: 0,
                  baselineType: TextBaseline.alphabetic,
                  child: Text(
                    "LEVEL 5",
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              Switch(
                value: widget.firebaseUserModel!.lootAlerts.contains("${widget.npcAlertModel.id}:5"),
                onChanged: (value) {
                  setState(() {
                    firestore.toggleNpcAlert(id: widget.npcAlertModel.id, level: 5, active: value);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
