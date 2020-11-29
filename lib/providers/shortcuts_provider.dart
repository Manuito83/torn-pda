import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ShortcutsProvider extends ChangeNotifier {
  List<Shortcut> _allShortcuts = [];
  UnmodifiableListView<Shortcut> get allShortcuts =>
      UnmodifiableListView(_allShortcuts);

  List<Shortcut> _activeShortcuts = [];
  UnmodifiableListView<Shortcut> get activeShortcuts =>
      UnmodifiableListView(_activeShortcuts);

  String _shortcutTile = 'both';
  String get shortcutTile => _shortcutTile;

  String _shortcutMenu = 'carousel';
  String get shortcutMenu => _shortcutMenu;

  OwnProfileModel _userDetails;

  ShortcutsProvider() {
    // CLEAN LIST, only for debug
    // SharedPreferencesModel().setActiveShortcutsList([]);
    //////////////////////////////////////////////////////

    _initializeStockShortcuts();
  }

  void activateShortcut(Shortcut activeShortcut) {
    activeShortcut.active = true;
    _activeShortcuts.add(activeShortcut);
    _saveListAfterChanges();
    notifyListeners();
  }

  void deactivateShortcut(Shortcut inactiveShortcut) {
    inactiveShortcut.active = false;
    _activeShortcuts.remove(inactiveShortcut);
    _saveListAfterChanges();
    notifyListeners();
  }

  void wipeAllShortcuts() {
    for (var short in activeShortcuts) {
      short.active = false;
      //_activeShortcuts.remove(short);
    }
    _activeShortcuts.clear();
    _saveListAfterChanges();
    notifyListeners();
  }

  void reorderShortcut(Shortcut movedShortcut, int oldIndex, int newIndex) {
    _activeShortcuts.removeAt(oldIndex);
    _activeShortcuts.insert(newIndex, movedShortcut);
    _saveListAfterChanges();
    notifyListeners();
  }

  void changeShortcutTile(String choice) {
    _shortcutTile = choice;
    SharedPreferencesModel().setShortcutTile(choice);
    notifyListeners();
  }

  void changeShortcutMenu(String choice) {
    _shortcutMenu = choice;
    SharedPreferencesModel().setShortcutMenu(choice);
    notifyListeners();
  }

  void _saveListAfterChanges() {
    var saveList = List<String>();
    for (var short in activeShortcuts) {
      var save = shortcutToJson(short);
      saveList.add(save);
    }
    SharedPreferencesModel().setActiveShortcutsList(saveList);
  }

  Future _initializeStockShortcuts() async {
    _shortcutTile = await SharedPreferencesModel().getShortcutTile();
    _shortcutMenu = await SharedPreferencesModel().getShortcutMenu();
    _userDetails =
        ownProfileModelFromJson(await SharedPreferencesModel().getOwnDetails());

    _configureStockShortcuts();

    // In order to properly reconnect saved shortcuts with the stock ones (so that
    // one is a reference of the other), once we load from shared preferences,
    // we look for the stock counterpart and activate it from scratch
    var savedLoad = await SharedPreferencesModel().getActiveShortcutsList();
    for (var savedShortRaw in savedLoad) {
      var savedShort = shortcutFromJson(savedShortRaw);
      if (savedShort.isCustom) {
        activateShortcut(savedShort);
      } else {
        for (var stockShort in _allShortcuts) {
          if (savedShort.name == stockShort.name) {
            activateShortcut(stockShort);
          }
        }
      }
    }
  }

  void _configureStockShortcuts() {
    _allShortcuts.addAll({
      Shortcut()
        ..name = "Home"
        ..nickname = "Home"
        ..url = "https://www.torn.com/"
        ..iconUrl = "images/icons/home/home.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Messages"
        ..nickname = "Messages"
        ..url = "https://www.torn.com/messages.php"
        ..iconUrl = "images/icons/home/messages.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Messages: Compose"
        ..nickname = "Compose Message"
        ..url = "https://www.torn.com/messages.php#/p=compose"
        ..iconUrl = "images/icons/home/messages.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Events"
        ..nickname = "Events"
        ..url = "https://www.torn.com/events.php"
        ..iconUrl = "images/icons/home/events.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Awards"
        ..nickname = "Awards"
        ..url = "https://www.torn.com/awards.php"
        ..iconUrl = "images/icons/home/awards.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "City"
        ..nickname = "City"
        ..url = "https://www.torn.com/city.php"
        ..iconUrl = "images/icons/home/city.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Job"
        ..nickname = "Job"
        ..url = "https://www.torn.com/jobs.php"
        ..iconUrl = "images/icons/home/job.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Gym"
        ..nickname = "Gym"
        ..url = "https://www.torn.com/gym.php"
        ..iconUrl = "images/icons/map/gym.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Property"
        ..nickname = "Property"
        ..url = "https://www.torn.com/properties.php"
        ..iconUrl = "images/icons/map/property.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Education"
        ..nickname = "Education"
        ..url = "https://www.torn.com/education.php"
        ..iconUrl = "images/icons/map/education.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Crimes"
        ..nickname = "Crimes"
        ..url = "https://www.torn.com/crimes.php#/step=main"
        ..iconUrl = "images/icons/home/crimes.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Missions"
        ..nickname = "Missions"
        ..url = "https://www.torn.com/loader.php?sid=missions"
        ..iconUrl = "images/icons/home/missions.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Bounties: List"
        ..nickname = "Bounties"
        ..url = "https://www.torn.com/bounties.php#!p=main"
        ..iconUrl = "images/icons/home/bounty.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Bounties: Place"
        ..nickname = "Place Bounty"
        ..url = "https://www.torn.com/bounties.php#/p=add"
        ..iconUrl = "images/icons/home/bounty.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Newspaper"
        ..nickname = "Newspaper"
        ..url = "https://www.torn.com/newspaper.php"
        ..iconUrl = "images/icons/home/newspaper.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Newspaper: Ads"
        ..nickname = "Newspaper Ads"
        ..url = "https://www.torn.com/newspaper_class.php"
        ..iconUrl = "images/icons/home/newspaper.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Newspaper: Jobs"
        ..nickname = "Newspaper Jobs"
        ..url = "https://www.torn.com/joblist.php#!p=main"
        ..iconUrl = "images/icons/home/newspaper.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Jail"
        ..nickname = "Jail"
        ..url = "https://www.torn.com/jailview.php"
        ..iconUrl = "images/icons/map/jail.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Hospital"
        ..nickname = "Hospital"
        ..url = "https://www.torn.com/hospitalview.php"
        ..iconUrl = "images/icons/map/hospital.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Laptop"
        ..nickname = "Laptop"
        ..url = "https://www.torn.com/laptop.php"
        ..iconUrl = "images/icons/home/laptop.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Personal Stats"
        ..nickname = "Personal Stats"
        ..url = "https://www.torn.com/personalstats.php?ID=${_userDetails.playerId}&stats=useractivity&from=1%20month"
        ..iconUrl = "images/icons/home/stats.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Hall of Fame"
        ..nickname = "HoF"
        ..url = "https://www.torn.com/halloffame.php"
        ..iconUrl = "images/icons/home/hall_fame.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Friends"
        ..nickname = "Friends"
        ..url = "https://www.torn.com/friendlist.php"
        ..iconUrl = "images/icons/home/friends.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Enemies"
        ..nickname = "Enemies"
        ..url = "https://www.torn.com/blacklist.php"
        ..iconUrl = "images/icons/home/enemies.png"
        ..color = Colors.grey[600],
      Shortcut()
        ..name = "Forums"
        ..nickname = "Forums"
        ..url = "https://www.torn.com/forums.php"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: General"
        ..nickname = "General"
        ..url = "https://www.torn.com/forums.php?p=forums&f=2&b=0&a=0"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: Own posts"
        ..nickname = "Own Posts"
        ..url =
            "https://www.torn.com/forums.php#!p=search&q=by:${_userDetails.playerId}&f=0&y=0"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: My faction"
        ..nickname = "Faction"
        ..url =
            "https://www.torn.com/forums.php?p=forums&f=999&b=1&a=${_userDetails.faction.factionId}"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: My company"
        ..nickname = "Company"
        ..url =
            "https://www.torn.com/forums.php?p=forums&f=999&b=2&a=${_userDetails.job.companyId}"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: Donator"
        ..nickname = "Donator"
        ..url = "https://www.torn.com/forums.php?p=forums&f=8&b=0&a=0"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: Questions and answers"
        ..nickname = "Q&A"
        ..url = "https://www.torn.com/forums.php?p=forums&f=3&b=0&a=0"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: Trading"
        ..nickname = "Trading"
        ..url = "https://www.torn.com/forums.php?p=forums&f=10&b=0&a=0"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: Faction recruitment"
        ..nickname = "Factions"
        ..url = "https://www.torn.com/forums.php?p=forums&f=24&b=0&a=0"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: Company recruitment"
        ..nickname = "Companies"
        ..url = "https://www.torn.com/forums.php?p=forums&f=46&b=0&a=0"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: Tools"
        ..nickname = "Tools"
        ..url = "https://www.torn.com/forums.php?p=forums&f=67&b=0&a=0"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.brown,
      Shortcut()
        ..name = "Forums: Torn PDA"
        ..nickname = "Torn PDA"
        ..url =
            "https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0"
        ..iconUrl = "images/icons/home/forums.png"
        ..color = Colors.pink,
      Shortcut()
        ..name = "Faction"
        ..nickname = "Faction"
        ..url = "https://www.torn.com/factions.php?step=your"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Territory"
        ..nickname = "Territory"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=territory"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Crimes"
        ..nickname = "Faction Crimes"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=crimes"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Weapons"
        ..nickname = "Faction Weapons"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=weapons"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Armor"
        ..nickname = "Faction Armor"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=armour"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Temporary"
        ..nickname = "Faction Temporary"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=temporary"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Medical"
        ..nickname = "Faction Medical"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Drugs"
        ..nickname = "Faction Drugs"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=drugs"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Boosters"
        ..nickname = "Faction Boosters"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=boosters"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Cesium"
        ..nickname = "Faction Cesium"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=cesium"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Points"
        ..nickname = "Faction Points"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=points"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Faction: Deposit"
        ..nickname = "Faction Deposit"
        ..url = "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=donate"
        ..iconUrl = "images/icons/home/faction.png"
        ..color = Colors.blueGrey,
      Shortcut()
        ..name = "Vault: Property"
        ..nickname = "Property"
        ..url = "https://www.torn.com/properties.php#/p=options&tab=vault"
        ..iconUrl = "images/icons/home/vault.png"
        ..color = Colors.blue[200],
      Shortcut()
        ..name = "Vault: Company"
        ..nickname = "Company"
        ..url = "https://www.torn.com/companies.php#/option=funds"
        ..iconUrl = "images/icons/home/vault.png"
        ..color = Colors.blue[200],
      Shortcut()
        ..name = "Vault: Faction"
        ..nickname = "Faction"
        ..url =
            "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=donate"
        ..iconUrl = "images/icons/home/vault.png"
        ..color = Colors.blue[200],
      Shortcut()
        ..name = "Trades"
        ..nickname = "Trades"
        ..url = "https://www.torn.com/trade.php"
        ..iconUrl = "images/icons/inventory/trades.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Bazaar"
        ..nickname = "Bazaar"
        ..url = "https://www.torn.com/bazaar.php#/"
        ..iconUrl = "images/icons/inventory/bazaar.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Bazaar: Add items"
        ..nickname = "Bazaar Add"
        ..url = "https://www.torn.com/bazaar.php#/add"
        ..iconUrl = "images/icons/inventory/bazaar.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Bazaar: Manage"
        ..nickname = "Bazaar Manage"
        ..url = "https://www.torn.com/bazaar.php#/manage"
        ..iconUrl = "images/icons/inventory/bazaar.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Ammo"
        ..nickname = "Ammo"
        ..url = "https://www.torn.com/page.php?sid=ammo"
        ..iconUrl = "images/icons/inventory/ammo.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items"
        ..nickname = "Items"
        ..url = "https://www.torn.com/item.php"
        ..iconUrl = "images/icons/home/items.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Primary weapon"
        ..nickname = "Primary"
        ..url = "https://www.torn.com/item.php#primary-items"
        ..iconUrl = "images/icons/inventory/primary.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Secondary weapon"
        ..nickname = "Secondary"
        ..url = "https://www.torn.com/item.php#secondary-items"
        ..iconUrl = "images/icons/inventory/secondary.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Melee weapon"
        ..nickname = "Melee"
        ..url = "https://www.torn.com/item.php#melee-items"
        ..iconUrl = "images/icons/inventory/melee.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Temporary weapon"
        ..nickname = "Temporary"
        ..url = "https://www.torn.com/item.php#temporary-items"
        ..iconUrl = "images/icons/inventory/temporary.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Armor"
        ..nickname = "Armor"
        ..url = "https://www.torn.com/item.php#armour-items"
        ..iconUrl = "images/icons/inventory/armor.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Clothing"
        ..nickname = "Clothing"
        ..url = "https://www.torn.com/item.php#clothes-items"
        ..iconUrl = "images/icons/inventory/clothing.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Medical"
        ..nickname = "Medical"
        ..url = "https://www.torn.com/item.php#medical-items"
        ..iconUrl = "images/icons/inventory/medical.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Drugs"
        ..nickname = "Drugs"
        ..url = "https://www.torn.com/item.php#drugs-items"
        ..iconUrl = "images/icons/inventory/drugs.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Energy drink"
        ..nickname = "Energy"
        ..url = "https://www.torn.com/item.php#energy-d-items"
        ..iconUrl = "images/icons/inventory/energy.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Alcohol"
        ..nickname = "Alcohol"
        ..url = "https://www.torn.com/item.php#alcohol-items"
        ..iconUrl = "images/icons/inventory/alcohol.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Candy"
        ..nickname = "Candy"
        ..url = "https://www.torn.com/item.php#candy-items"
        ..iconUrl = "images/icons/inventory/candy.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Boosters"
        ..nickname = "Boosters"
        ..url = "https://www.torn.com/item.php#boosters-items"
        ..iconUrl = "images/icons/inventory/boosters.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Enhancer"
        ..nickname = "Enhancer"
        ..url = "https://www.torn.com/item.php#enhancers-items"
        ..iconUrl = "images/icons/inventory/enhancer.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Supply packs"
        ..nickname = "Supply"
        ..url = "https://www.torn.com/item.php#supply-pck-items"
        ..iconUrl = "images/icons/inventory/supply_packs.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Electronics"
        ..nickname = "Elec"
        ..url = "https://www.torn.com/item.php#electrical-items"
        ..iconUrl = "images/icons/inventory/electronics.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Jewelry"
        ..nickname = "Jewelry"
        ..url = "https://www.torn.com/item.php#jewelry-items"
        ..iconUrl = "images/icons/inventory/jewelry.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Flowers"
        ..nickname = "Flowers"
        ..url = "https://www.torn.com/item.php#flowers-items"
        ..iconUrl = "images/icons/inventory/flowers.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Plushies"
        ..nickname = "Plushies"
        ..url = "https://www.torn.com/item.php#plushies-items"
        ..iconUrl = "images/icons/inventory/plushies.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Viruses"
        ..nickname = "Viruses"
        ..url = "https://www.torn.com/item.php#viruses-items"
        ..iconUrl = "images/icons/inventory/viruses.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Artifacts"
        ..nickname = "Artifacts"
        ..url = "https://www.torn.com/item.php#artifacts-items"
        ..iconUrl = "images/icons/inventory/artifacts.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Books"
        ..nickname = "Books"
        ..url = "https://www.torn.com/item.php#books-items"
        ..iconUrl = "images/icons/inventory/books.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Special"
        ..nickname = "Special"
        ..url = "https://www.torn.com/item.php#special-items"
        ..iconUrl = "images/icons/inventory/special.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Miscellaneous"
        ..nickname = "Misc"
        ..url = "https://www.torn.com/item.php#miscellaneous-items"
        ..iconUrl = "images/icons/inventory/misc.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Cars"
        ..nickname = "Cars"
        ..url = "https://www.torn.com/item.php#cars-item"
        ..iconUrl = "images/icons/inventory/cars.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Items: Collectibles"
        ..nickname = "Collect"
        ..url = "https://www.torn.com/item.php#collectibles-items"
        ..iconUrl = "images/icons/inventory/collectibles.png"
        ..color = Colors.purple[200],
      Shortcut()
        ..name = "Casino"
        ..nickname = "Casino"
        ..url = "https://www.torn.com/casino.php"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Slots"
        ..nickname = "Slots"
        ..url = "https://www.torn.com/loader.php?sid=slots"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Roulette"
        ..nickname = "Roulette"
        ..url = "https://www.torn.com/loader.php?sid=roulette"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: High-Low"
        ..nickname = "High-low"
        ..url = "https://www.torn.com/loader.php?sid=highlow"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Keno"
        ..nickname = "Keno"
        ..url = "https://www.torn.com/loader.php?sid=keno"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Craps"
        ..nickname = "Craps"
        ..url = "https://www.torn.com/loader.php?sid=craps"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Bookie"
        ..nickname = "Bookie"
        ..url = "https://www.torn.com/bookies.php"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Lottery"
        ..nickname = "Lottery"
        ..url = "https://www.torn.com/loader.php?sid=lottery"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Blackjack"
        ..nickname = "Blackjack"
        ..url = "https://www.torn.com/loader.php?sid=blackjack"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Poker"
        ..nickname = "Poker"
        ..url = "https://www.torn.com/loader.php?sid=holdem"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Russian Roulette"
        ..nickname = "Russian Roulette"
        ..url = "https://www.torn.com/page.php?sid=russianRoulette"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Spin the Wheel"
        ..nickname = "Spin Wheel"
        ..url = "https://www.torn.com/loader.php?sid=spinTheWheel"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Auction House"
        ..nickname = "Auction"
        ..url = "https://www.torn.com/amarket.php"
        ..iconUrl = "images/icons/map/auction_house.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Big Al's Gun Shop"
        ..nickname = "Gun Shop"
        ..url = "https://www.torn.com/bigalgunshop.php"
        ..iconUrl = "images/icons/map/gun_shop.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Bits 'n' Bobs"
        ..nickname = "Bits Bobs"
        ..url = "https://www.torn.com/shops.php?step=bitsnbobs"
        ..iconUrl = "images/icons/map/bits_bobs.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Cyber Force"
        ..nickname = "Cyber"
        ..url = "https://www.torn.com/shops.php?step=cyberforce"
        ..iconUrl = "images/icons/map/cyber_force.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Docks"
        ..nickname = "Docks"
        ..url = "https://www.torn.com/shops.php?step=docks"
        ..iconUrl = "images/icons/map/docks.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Estate Agents"
        ..nickname = "Estate"
        ..url = "https://www.torn.com/estateagents.php"
        ..iconUrl = "images/icons/map/estate_agents.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Item Market"
        ..nickname = "Market"
        ..url = "https://www.torn.com/imarket.php"
        ..iconUrl = "images/icons/map/item_market.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Jewelry Store"
        ..nickname = "Jewelry"
        ..url = "https://www.torn.com/shops.php?step=jewelry"
        ..iconUrl = "images/icons/map/jewelry_store.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Pawn Shop"
        ..nickname = "Pawn"
        ..url = "https://www.torn.com/shops.php?step=pawnshop"
        ..iconUrl = "images/icons/map/pawn_shop.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Pharmacy"
        ..nickname = "Pharmacy"
        ..url = "https://www.torn.com/shops.php?step=pharmacy"
        ..iconUrl = "images/icons/map/pharmacy.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Points Building"
        ..nickname = "Building"
        ..url = "https://www.torn.com/points.php"
        ..iconUrl = "images/icons/map/points_building.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Points Market"
        ..nickname = "Market"
        ..url = "https://www.torn.com/pmarket.php"
        ..iconUrl = "images/icons/map/points_market.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Post Office"
        ..nickname = "Post"
        ..url = "https://www.torn.com/shops.php?step=postoffice"
        ..iconUrl = "images/icons/map/post_office.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Super Store"
        ..nickname = "Super"
        ..url = "https://www.torn.com/shops.php?step=super"
        ..iconUrl = "images/icons/map/super_store.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Sweet Shop"
        ..nickname = "Sweets"
        ..url = "https://www.torn.com/shops.php?step=candy"
        ..iconUrl = "images/icons/map/sweet_shop.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "TC Clothing"
        ..nickname = "Clothing"
        ..url = "https://www.torn.com/shops.php?step=clothes"
        ..iconUrl = "images/icons/map/tc_clothing.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Token Shop"
        ..nickname = "Token Shop"
        ..url = "https://www.torn.com/token_shop.php"
        ..iconUrl = "images/icons/map/token_shop.png"
        ..color = Colors.yellow[700],
      Shortcut()
        ..name = "Church"
        ..nickname = "Church"
        ..url = "https://www.torn.com/church.php"
        ..iconUrl = "images/icons/map/church.png"
        ..color = Colors.purple[700],
      Shortcut()
        ..name = "Dump"
        ..nickname = "Dump"
        ..url = "https://www.torn.com/dump.php"
        ..iconUrl = "images/icons/map/dump.png"
        ..color = Colors.purple[700],
      Shortcut()
        ..name = "Loan Shark"
        ..nickname = "Loan Shark"
        ..url = "https://www.torn.com/loan.php"
        ..iconUrl = "images/icons/map/loan_shark.png"
        ..color = Colors.purple[700],
      Shortcut()
        ..name = "Travel Agency"
        ..nickname = "Travel"
        ..url = "https://www.torn.com/travelagency.php"
        ..iconUrl = "images/icons/map/travel_agency.png"
        ..color = Colors.purple[700],
      Shortcut()
        ..name = "Chronicle Archives"
        ..nickname = "Chronicle Archives"
        ..url = "https://www.torn.com/archives.php"
        ..iconUrl = "images/icons/map/chronicle_archives.png"
        ..color = Colors.green[700],
      Shortcut()
        ..name = "Community Center"
        ..nickname = "Community Center"
        ..url = "https://www.torn.com/fans.php"
        ..iconUrl = "images/icons/map/community_center.png"
        ..color = Colors.green[700],
      Shortcut()
        ..name = "Museum"
        ..nickname = "Museum"
        ..url = "https://www.torn.com/museum.php"
        ..iconUrl = "images/icons/map/community_center.png"
        ..color = Colors.green[700],
      Shortcut()
        ..name = "Race Track"
        ..nickname = "Race Track"
        ..url = "https://www.torn.com/loader.php?sid=racing"
        ..iconUrl = "images/icons/map/race_track.png"
        ..color = Colors.green[700],
      Shortcut()
        ..name = "Nikeh Sports Shop"
        ..nickname = "Sports Shop"
        ..url = "https://www.torn.com/shops.php?step=pharmacy"
        ..iconUrl = "images/icons/map/sports_shop.png"
        ..color = Colors.green[700],
      Shortcut()
        ..name = "Bank"
        ..nickname = "Bank"
        ..url = "https://www.torn.com/bank.php"
        ..iconUrl = "images/icons/map/bank.png"
        ..color = Colors.blue[700],
      Shortcut()
        ..name = "Donator House"
        ..nickname = "Donator House"
        ..url = "https://www.torn.com/donator.php"
        ..iconUrl = "images/icons/map/donator_house.png"
        ..color = Colors.blue[700],
      Shortcut()
        ..name = "Msg Inc"
        ..nickname = "Msg Inc"
        ..url = "https://www.torn.com/messageinc.php"
        ..iconUrl = "images/icons/map/msg_inc.png"
        ..color = Colors.blue[700],
      Shortcut()
        ..name = "Stock Exchange"
        ..nickname = "Stock Exchange"
        ..url = "https://www.torn.com/stockexchange.php"
        ..iconUrl = "images/icons/map/stock_exchange.png"
        ..color = Colors.blue[700],
      Shortcut()
        ..name = "Stock Exchange: Portfolio"
        ..nickname = "Portfolio"
        ..url = "https://www.torn.com/stockexchange.php?step=portfolio"
        ..iconUrl = "images/icons/map/stock_exchange.png"
        ..color = Colors.blue[700],
      Shortcut()
        ..name = "City Hall"
        ..nickname = "City Hall"
        ..url = "https://www.torn.com/citystats.php"
        ..iconUrl = "images/icons/map/city_hall.png"
        ..color = Colors.red[200],
      Shortcut()
        ..name = "Committee"
        ..nickname = "Committee"
        ..url = "https://www.torn.com/committee.php"
        ..iconUrl = "images/icons/map/committee.png"
        ..color = Colors.red[200],
      Shortcut()
        ..name = "Staff"
        ..nickname = "Staff"
        ..url = "https://www.torn.com/staff.php"
        ..iconUrl = "images/icons/map/staff.png"
        ..color = Colors.red[200],
      Shortcut()
        ..name = "Visitor Center"
        ..nickname = "Visitor Center"
        ..url = "https://www.torn.com/wiki"
        ..iconUrl = "images/icons/map/visitor_center.png"
        ..color = Colors.red[200],
    });
  }
}
