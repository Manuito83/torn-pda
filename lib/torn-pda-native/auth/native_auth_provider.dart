import 'package:flutter/material.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_models.dart';
import 'package:torn_pda/config/secrets.dart';

class NativeAuthProvider extends ChangeNotifier {
  bool get tryAutomaticLogins => false;
  DateTime lastAuthRedirect = DateTime.now().subtract(const Duration(days: 1));
  int authErrorsInSession = 0;

  Future<void> loadPreferences() async {}

  Future<TornLoginResponseContainer> requestTornRecurrentInitData({
    required BuildContext context,
    required GetInitDataModel loginData,
  }) async {
    // If a secret URL is provided, we could implement a real call here.
    // For now, we return a mock success if the secret URL is placeholder/empty,
    // or a redirect if the URL exists.
    if (Secrets.nativeAuthBaseUrl.isNotEmpty) {
      return TornLoginResponseContainer(
        success: true,
        authUrl: "${Secrets.nativeAuthBaseUrl}?playerId=${loginData.playerId}&token=${loginData.sToken}&redirect=",
      );
    }

    return TornLoginResponseContainer(
      success: false,
      message: "Native auth not configured in secrets.dart",
    );
  }
}
