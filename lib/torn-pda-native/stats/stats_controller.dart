import 'package:torn_pda/config/secrets.dart';

class StatsController {
  void logCheckIn() {
    if (Secrets.statsEndpoint.isNotEmpty) {
      // Future: Implement telemetry logic
    }
  }
  
  void logFirstLoginEver() {
    if (Secrets.statsEndpoint.isNotEmpty) {
      // Future: Implement telemetry logic
    }
  }
  
  void logCheckOut() {
    if (Secrets.statsEndpoint.isNotEmpty) {
      // Future: Implement telemetry logic
    }
  }
}
