import 'package:torn_pda/config/secrets.dart';

class WebviewConfig {
  static const String agent = Secrets.userAgent;
  static const String userAgentForUser = Secrets.userAgent;

  Future<void> generateUserAgentForUser() async {
    // Logic to generate or validate user agent can go here
  }
}
