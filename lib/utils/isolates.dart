import 'package:torn_pda/models/faction/faction_crimes_model.dart';

Future<dynamic> isolateDecodeFactionCrimes(List<dynamic> input) async {
  var crimesModel = FactionCrimesModel.fromJson(input[0], input[1]);
  if (crimesModel.crimes == null) return null;
  return crimesModel;
}
