import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

final firebaseFunctions = _FirebaseFunctions();

class _FirebaseFunctions {
  Future<int> sendAttackAssistMessage({
    @required String attackId,
    @required String attackName,
    @required String attackLevel,
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
    });

    // Data comes with number of people notified
    return results.data;
  }
}
