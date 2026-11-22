import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/webview/hcpp_decision.dart';

void main() {
  test("remote kill switch beats everything", () {
    for (final choice in [-1, 0, 1]) {
      expect(hcppRequested(remoteEnabled: false, remoteDefaultOn: true, userChoice: choice), isFalse);
    }
  });

  test("the user's choice beats the remote default", () {
    expect(hcppRequested(remoteEnabled: true, remoteDefaultOn: false, userChoice: 1), isTrue);
    expect(hcppRequested(remoteEnabled: true, remoteDefaultOn: true, userChoice: 0), isFalse);
  });

  test("untouched follows the remote default", () {
    expect(hcppRequested(remoteEnabled: true, remoteDefaultOn: false, userChoice: -1), isFalse);
    expect(hcppRequested(remoteEnabled: true, remoteDefaultOn: true, userChoice: -1), isTrue);
  });

  _propertyTests();
}

void _propertyTests() {
  String property({
    bool active = false,
    bool tripped = false,
    bool remoteEnabled = true,
    bool remoteDefaultOn = true,
    int userChoice = -1,
  }) => hcppUserProperty(
    active: active,
    tripped: tripped,
    remoteEnabled: remoteEnabled,
    remoteDefaultOn: remoteDefaultOn,
    userChoice: userChoice,
  );

  group("webview_hcpp property", () {
    test("active beats everything", () {
      expect(property(active: true, tripped: true, userChoice: 0, remoteEnabled: false), "active");
    });

    test("the user's no beats the remote switches", () {
      expect(property(userChoice: 0, remoteEnabled: false), "off_user");
      expect(property(userChoice: 0, tripped: true), "off_user");
    });

    test("not requested by remote config", () {
      expect(property(remoteEnabled: false), "off_remote");
      expect(property(remoteEnabled: false, userChoice: 1), "off_remote");
      expect(property(remoteDefaultOn: false), "off_remote");
    });

    test("requested but off: tripped or unsupported", () {
      expect(property(tripped: true), "off_tripped");
      expect(property(userChoice: 1, remoteDefaultOn: false, tripped: true), "off_tripped");
      expect(property(), "unsupported");
      expect(property(userChoice: 1, remoteDefaultOn: false), "unsupported");
    });
  });
}
