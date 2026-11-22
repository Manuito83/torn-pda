import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart' show selectNotificationStream;
import 'package:torn_pda/models/territory_map/alert_subscriptions.dart';
import 'package:torn_pda/models/territory_map/map_share.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_share_controller.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

// Null with the map off
TerritoryMapController? _mapOf(BuildContext context) {
  try {
    if (context.read<SettingsProvider>().disableTerritoryMap) return null;
    return context.read<TerritoryMapController>();
  } on ProviderNotFoundException {
    return null;
  }
}

bool territoryMapOn(BuildContext context) => _mapOf(context) != null;

// Empty territory only opens the map
bool openMapTerritory([String territory = '']) {
  if (NativeChat.leaveForBrowser() == null) return false;
  selectNotificationStream.add(alertTapPayload({'territory': territory}));
  return true;
}

void openMapView(BuildContext context, SharedMapView view) {
  final share = context.read<TerritoryShareController>();
  if (openMapTerritory()) share.receive(view);
}

void openMapFaction(BuildContext context, int factionId) {
  final share = context.read<TerritoryShareController>();
  if (openMapTerritory()) share.receiveFaction(factionId);
}
