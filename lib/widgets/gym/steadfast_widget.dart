// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/perks/user_perks_model.dart';
import 'package:torn_pda/providers/api_caller.dart';

class SteadfastDetails {
  int? strength = 0;
  int? speed = 0;
  int? defense = 0;
  int? dexterity = 0;
}

class GymWidget extends StatefulWidget {
  GymWidget({
    Key? key,
  }) : super(key: key);

  @override
  _GymWidgetState createState() => _GymWidgetState();
}

class _GymWidgetState extends State<GymWidget> {
  Future? _steadFastFetched;
  SteadfastDetails? _steadfastDetails;

  @override
  void initState() {
    super.initState();
    _steadFastFetched = _fetchSteadFast();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _steadFastFetched,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_steadfastDetails == null) {
            return SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Steadfast: ", style: TextStyle(color: Colors.orange, fontSize: 11)),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text("STR ${_steadfastDetails!.strength}%, ", style: TextStyle(color: Colors.white, fontSize: 11)),
                      Text("DEF ${_steadfastDetails!.defense}%, ", style: TextStyle(color: Colors.white, fontSize: 11)),
                      Text("SPD ${_steadfastDetails!.speed}%, ", style: TextStyle(color: Colors.white, fontSize: 11)),
                      Text("DEX ${_steadfastDetails!.dexterity}%", style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _fetchSteadFast() async {
    dynamic perksResponse = await Get.find<ApiCallerController>().getUserPerks();

    if (perksResponse is ApiError) {
      return;
    }

    UserPerksModel perks = perksResponse as UserPerksModel;

    int? strength = 0;
    int? speed = 0;
    int? defense = 0;
    int? dexterity = 0;

    try {
      RegExp reg = RegExp(r"([0-9]+)%");
      for (String perk in perks.factionPerks!) {
        if (perk.contains("strength gym gains")) {
          var matches = reg.firstMatch(perk)!;
          strength = int.tryParse(matches.group(1)!);
        } else if (perk.contains("speed gym gains")) {
          var matches = reg.firstMatch(perk)!;
          speed = int.tryParse(matches.group(1)!);
        } else if (perk.contains("defense gym gains")) {
          var matches = reg.firstMatch(perk)!;
          defense = int.tryParse(matches.group(1)!);
        } else if (perk.contains("dexterity gym gains")) {
          var matches = reg.firstMatch(perk)!;
          dexterity = int.tryParse(matches.group(1)!);
        }
      }

      if (strength! > 0 || speed! > 0 || defense! > 0 || dexterity! > 0) {
        _steadfastDetails = SteadfastDetails()
          ..strength = strength
          ..speed = speed
          ..defense = defense
          ..dexterity = dexterity;
      }
    } catch (e) {
      // No steadfast returned
    }
  }
}
