String? attackIdFromUrl(String url) => RegExp(r'user2ID=(\d+)').firstMatch(url)?.group(1);

// Members notified, error code or null
String factionAssistResultMessage(int? result) {
  if (result != null && result > 0) {
    return "$result faction member${result == 1 ? " has" : "s have"} been notified!";
  }
  switch (result) {
    case 0:
      return "No faction member could be notified (not using Torn PDA or assists off)!";
    case -1:
      return "Could not find your faction's details, please try again!";
    case -2:
      return "Torn rejected your API key, please update it in Settings";
    case -3:
      return "Torn API is not responding, please try again later";
    case -4:
      return "Hourly assist limit reached, please try again later";
    case -5:
      return "Torn API key limit reached (100 calls/min), try again in a minute";
    default:
      return "Assistance could not be requested, please try again later";
  }
}

// Seconds to show the result
int factionAssistToastSeconds(int? result) => result == -5 ? 10 : 5;
