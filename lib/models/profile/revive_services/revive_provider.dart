// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';

class ReviveProvider {
  final String name;
  final String settingsTitle;
  final String icon;
  final String description;
  final String? forumUrl;
  final String? discordUrl;

  // Payment conditions, receiving the current price (from Remote Config)
  final String Function(String price) priceNote;

  final String Function(SettingsProvider settings) price;
  final bool Function(WarController w) isActive;
  final void Function(WarController w, bool value) setActive;

  const ReviveProvider({
    required this.name,
    required this.settingsTitle,
    required this.icon,
    required this.description,
    required this.priceNote,
    required this.price,
    required this.isActive,
    required this.setActive,
    this.forumUrl,
    this.discordUrl,
  });
}

// Shared by most providers
String _payOrBlacklisted(String price) =>
    "Revives cost $price, unless on contract. Refusal to pay will result in getting blacklisted.";

class ReviveProviders {
  // Order in which providers are listed in the settings dialog
  static final List<ReviveProvider> all = [nuke, uhc, wtf, midnightX, wolverines, combatReady, asclepius];

  static final nuke = ReviveProvider(
    name: "Nuke",
    settingsTitle: "Nuke Reviving Services",
    icon: 'images/icons/nuke-revive.png',
    description: "Nuke is a premium Torn reviving service consisting in more than 300 revivers.",
    forumUrl: 'https://www.torn.com/forums.php#/p=threads&f=14&t=16160853&b=0&a=0',
    discordUrl: 'https://discord.gg/qSHjTXx',
    priceNote: (price) =>
        "Each revive must be paid directly to the reviver (unless under a contract with Nuke) and costs $price."
        "\n\nPlease keep in mind if you don't pay for the requested revive, you risk getting blocked from Nuke!",
    price: (s) => s.reviveNukePrice,
    isActive: (w) => w.nukeReviveActive,
    setActive: (w, value) => w.nukeReviveActive = value,
  );

  static final uhc = ReviveProvider(
    name: "UHC",
    settingsTitle: "UHC Reviving Services",
    icon: 'images/icons/uhc_revive.png',
    description: "Universal Health Care (UHC for short) is a revive alliance consisting of several factions.",
    forumUrl: 'https://www.torn.com/forums.php#/p=threads&f=67&t=16192913&b=0&a=0',
    discordUrl: 'https://discord.gg/JJprTpb',
    priceNote: (price) =>
        "Each revive must be paid directly to the reviver and costs $price. There are special prices for faction "
        "contracts (more information in the forums)."
        "\n\nPlease keep in mind if you don't pay for the requested revive, you risk getting blocked from UHC!",
    price: (s) => s.reviveUhcPrice,
    isActive: (w) => w.uhcReviveActive,
    setActive: (w, value) => w.uhcReviveActive = value,
  );

  static final wtf = ReviveProvider(
    name: "WTF",
    settingsTitle: "WTF Reviving Services",
    icon: 'images/icons/wtf_revive.png',
    description:
        "WTF are a collection of factions looking to bolster their ranks with new and veteran "
        "players alike. They provide Reviving and Attacking services.",
    forumUrl: 'https://www.torn.com/forums.php#/p=threads&f=24&t=16012007&b=0&a=0',
    discordUrl: 'https://discord.gg/S5Qp6aZd',
    priceNote: _payOrBlacklisted,
    price: (s) => s.reviveWtfPrice,
    isActive: (w) => w.wtfReviveActive,
    setActive: (w, value) => w.wtfReviveActive = value,
  );

  static final midnightX = ReviveProvider(
    name: "Midnight X",
    settingsTitle: "Midnight X Reviving Services",
    icon: 'images/icons/midnightx_revive.png',
    description:
        "Midnight X is a member of the NITE Family of factions. The majority of their "
        "members are at premium skill levels and stay highly active.",
    forumUrl: 'https://www.torn.com/forums.php#/p=threads&f=10&t=16291239&b=0&a=0',
    discordUrl: 'https://discord.gg/nite',
    priceNote: _payOrBlacklisted,
    price: (s) => s.reviveMidnightPrice,
    isActive: (w) => w.midnightXReviveActive,
    setActive: (w, value) => w.midnightXReviveActive = value,
  );

  static final wolverines = ReviveProvider(
    name: "The Wolverines",
    settingsTitle: "The Wolverines Reviving Services",
    icon: 'images/icons/wolverines_revive.png',
    description:
        "The Wolverines is an independent revive faction that believes that revives should be more accessible.",
    discordUrl: 'https://discord.gg/XmR6TpHXHb',
    priceNote: _payOrBlacklisted,
    price: (s) => s.reviveWolverinesPrice,
    isActive: (w) => w.wolverinesReviveActive,
    setActive: (w, value) => w.wolverinesReviveActive = value,
  );

  static final combatReady = ReviveProvider(
    name: "Combat Ready",
    settingsTitle: "Combat Ready Reviving Services",
    icon: 'images/icons/combat_ready_revive.png',
    description: "Combat Ready is a faction providing revive services.",
    forumUrl: 'https://www.torn.com/forums.php#/p=threads&f=10&t=16541147',
    priceNote: (price) => "Revives cost $price, unless on a contract. Refusal to pay will result in being Blacklisted.",
    price: (s) => s.reviveCombatReadyPrice,
    isActive: (w) => w.combatReadyReviveActive,
    setActive: (w, value) => w.combatReadyReviveActive = value,
  );

  static final asclepius = ReviveProvider(
    name: "Asclepius",
    settingsTitle: "Asclepius Reviving Services",
    icon: 'images/icons/asclepius_revive.png',
    description:
        "Asclepius is an independent revive faction dedicated to providing affordable "
        "healthcare and efficient service to patients all over Torn.",
    forumUrl: 'https://www.torn.com/forums.php#/p=threads&f=10&t=16562082&b=0&a=0',
    discordUrl: 'https://discord.gg/uvfm978f6v',
    priceNote: (price) =>
        "Revives cost $price and are paid directly to the reviver, unless on a contract. Failure to pay will "
        "result in removal from access to their services.",
    price: (s) => s.reviveAsclepiusPrice,
    isActive: (w) => w.asclepiusReviveActive,
    setActive: (w, value) => w.asclepiusReviveActive = value,
  );
}
