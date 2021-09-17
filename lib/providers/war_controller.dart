import 'package:get/get.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/utils/api_caller.dart';

class WarController extends GetxController {
  RxList<FactionModel> factions = RxList<FactionModel>().obs();

  String addFaction(String apiKey, String factionId) {
    final apiResult = TornApiCaller.faction(apiKey, factionId).getFaction;
    if (apiResult == ApiError) {
      return "";
    } else if (apiResult == FactionModel) {
      final faction = apiResult as FactionModel;
      factions.add(faction);
      return faction.name;
    }
  }
}
