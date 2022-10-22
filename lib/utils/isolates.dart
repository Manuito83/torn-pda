import 'package:torn_pda/models/faction/faction_crimes_model.dart';

Future<dynamic> isolateDecodeFactionCrimes(List<dynamic> input) async {
  return FactionCrimesModel.fromJson(input[0], input[1]);
}
