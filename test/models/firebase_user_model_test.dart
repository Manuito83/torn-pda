import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/firebase_user_model.dart';

void main() {
  test('the local alerts copy keeps vibration and the retals host', () {
    final model = FirebaseUserModel()
      ..vibration = 'long'
      ..retalsNotification = true
      ..retalsNotificationHost = true;

    final restored = FirebaseUserModel.fromMap(model.toMap());

    expect(restored.vibration, 'long');
    expect(restored.retalsNotificationHost, isTrue);
  });

  test('copies saved before these fields existed still load', () {
    final restored = FirebaseUserModel.fromMap({'retalsNotification': true});

    expect(restored.vibration, isNull);
    expect(restored.retalsNotificationHost, isFalse);
    expect(restored.retalsNotification, isTrue);
  });
}
