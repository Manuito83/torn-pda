/// [userChoice]: -1 untouched, 0 off, 1 on
bool hcppRequested({required bool remoteEnabled, required bool remoteDefaultOn, required int userChoice}) {
  if (!remoteEnabled) return false;
  if (userChoice == -1) return remoteDefaultOn;
  return userChoice == 1;
}

/// Value of the `webview_hcpp` user property, by priority
String hcppUserProperty({
  required bool active,
  required bool tripped,
  required bool remoteEnabled,
  required bool remoteDefaultOn,
  required int userChoice,
}) {
  if (active) return "active";
  if (userChoice == 0) return "off_user";
  if (!hcppRequested(remoteEnabled: remoteEnabled, remoteDefaultOn: remoteDefaultOn, userChoice: userChoice)) {
    return "off_remote";
  }
  return tripped ? "off_tripped" : "unsupported";
}
