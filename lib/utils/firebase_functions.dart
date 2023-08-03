import 'package:cloud_functions/cloud_functions.dart';

final firebaseFunctions = _FirebaseFunctions();

class _FirebaseFunctions {
  Future<int> sendAttackAssistMessage({
    required String attackId,
    String? attackName = "",
    String attackLevel = "",
    String attackLife = "",
    String attackAge = "",
    String estimatedStats = "",
    String xanax = "unk",
    String refills = "unk",
    String drinks = "unk",
    String exactStats = "",
  }) async {
    HttpsCallable callable = FirebaseFunctions.instanceFor(
      region: 'us-east4',
    ).httpsCallable(
      'factionAssist-sendAssistMessage',
    );

    HttpsCallableResult results = await callable.call(<String, dynamic>{
      'attackId': attackId,
      'attackName': attackName,
      'attackLevel': attackLevel,
      'attackLife': attackLife,
      'attackAge': attackAge,
      'estimatedStats': estimatedStats,
      'xanax': xanax,
      'refills': refills,
      'drinks': drinks,
      'exactStats': exactStats,
    });

    // Data comes with number of people notified
    return results.data;
  }
}
