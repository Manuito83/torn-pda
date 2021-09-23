import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class WarController extends GetxController {
  List<FactionModel> factions = <FactionModel>[];
  List<int> filteredOutFactions = <int>[]; // TODO: to share prefs

  @override
  void onInit() {
    super.onInit();
    initialiseFactions();
  }

  Future<String> addFaction(String apiKey, String factionId) async {
    // Return custom error code if faction already exists
    for (FactionModel faction in factions) {
      if (faction.id == factionId) {
        return "error_existing";
      }
    }

    final apiResult = await TornApiCaller.faction(apiKey, factionId).getFaction;
    if (apiResult == ApiError) {
      return "";
    }

    final faction = apiResult as FactionModel;
    factions.add(faction);
    update();
    savePreferences();
    return faction.name;
  }

  void removeFaction(int removeId) {
    factions.removeWhere((f) => f.id == removeId);
    update();
  }

  void filterFaction(int factionId) {
    if (filteredOutFactions.contains(factionId)) {
      filteredOutFactions.remove(factionId);
    } else {
      filteredOutFactions.add(factionId);
    }
    update();
  }

  Future initialiseFactions() async {
    List<String> saved = await Prefs().getWarFactions();
    saved.forEach((element) {
      factions.add(factionModelFromJson(element));
    });
  }

  void savePreferences() {
    List<String> factionList = [];
    factions.forEach((element) {
      factionList.add(factionModelToJson(element));
    });
    Prefs().setWarFactions(factionList);
  }
}
