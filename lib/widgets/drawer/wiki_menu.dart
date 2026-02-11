import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_simple_dialog.dart';

class WikiMenu extends StatefulWidget {
  const WikiMenu({
    super.key,
    required this.themeProvider,
  });

  final ThemeProvider themeProvider;

  static const _pages = {
    "FAQ": "https://wiki.torn.com/wiki/FAQ",
    "Ammo": "https://wiki.torn.com/wiki/Ammo",
    "Annual Competitions": "https://wiki.torn.com/wiki/Annual_Competitions",
    "API": "https://wiki.torn.com/wiki/API",
    "Arca Fortunae": "https://wiki.torn.com/wiki/Arca_Fortunae",
    "Armor": "https://wiki.torn.com/wiki/Armor",
    "Armor Cache": "https://wiki.torn.com/wiki/Armor_Cache",
    "Arrest": "https://wiki.torn.com/wiki/Arrest",
    "Attacking": "https://wiki.torn.com/wiki/Attack",
    "Auction House": "https://wiki.torn.com/wiki/Auction_House",
    "Awards": "https://wiki.torn.com/wiki/Award",
    "Awareness": "https://wiki.torn.com/wiki/Awareness",
    "Battle Stats": "https://wiki.torn.com/wiki/Battle_Stats",
    "Bazaar": "https://wiki.torn.com/wiki/Bazaar",
    "Blackjack": "https://wiki.torn.com/wiki/Blackjack",
    "Bookie": "https://wiki.torn.com/wiki/Bookie",
    "Books": "https://wiki.torn.com/wiki/Books",
    "Bootlegging": "https://wiki.torn.com/wiki/Bootlegging",
    "Bounties": "https://wiki.torn.com/wiki/Bounty",
    "Burglary": "https://wiki.torn.com/wiki/Burglary",
    "Card Skimming": "https://wiki.torn.com/wiki/Card_Skimming",
    "Cars": "https://wiki.torn.com/wiki/Cars",
    "Casino": "https://wiki.torn.com/wiki/Casino",
    "Chain": "https://wiki.torn.com/wiki/Chain",
    "Christmas Town": "https://wiki.torn.com/wiki/Christmas_Town",
    "City": "https://wiki.torn.com/wiki/City",
    "City Bank": "https://wiki.torn.com/wiki/City_Bank",
    "Collectibles": "https://wiki.torn.com/wiki/Collectible#Collectibles",
    "Companies": "https://wiki.torn.com/wiki/Company",
    "Cooldowns": "https://wiki.torn.com/wiki/Item_Cooldowns",
    "Cosmetic Cache": "https://wiki.torn.com/wiki/Cosmetic_Cache",
    "Cracking": "https://wiki.torn.com/wiki/Cracking",
    "Crimes": "https://wiki.torn.com/wiki/Crime",
    "Dirty Bomb": "https://wiki.torn.com/wiki/Dirty_Bomb",
    "Disposal": "https://wiki.torn.com/wiki/Disposal",
    "Donator": "https://wiki.torn.com/wiki/Donator",
    "Drugs": "https://wiki.torn.com/wiki/Drug",
    "Education": "https://wiki.torn.com/wiki/Education",
    "Elimination": "https://wiki.torn.com/wiki/Elimination",
    "Enemies List": "https://wiki.torn.com/wiki/Enemies_List",
    "Energy": "https://wiki.torn.com/wiki/Energy",
    "Faction Challenges": "https://wiki.torn.com/wiki/Faction_Challenges",
    "Factions": "https://wiki.torn.com/wiki/Faction",
    "Forgery": "https://wiki.torn.com/wiki/Forgery",
    "Forums": "https://wiki.torn.com/wiki/Forum",
    "Friends List": "https://wiki.torn.com/wiki/Friends_List",
    "Graffiti": "https://wiki.torn.com/wiki/Graffiti",
    "Gym": "https://wiki.torn.com/wiki/Gym",
    "Hall of Fame": "https://wiki.torn.com/wiki/Hall_of_Fame",
    "Happy": "https://wiki.torn.com/wiki/Happy",
    "High-Low": "https://wiki.torn.com/wiki/High-Low",
    "Hospital": "https://wiki.torn.com/wiki/Hospital",
    "Hospitalize": "https://wiki.torn.com/wiki/Hospitalize",
    "Hunting": "https://wiki.torn.com/wiki/Hunting",
    "Hustling": "https://wiki.torn.com/wiki/Hustling",
    "Items": "https://wiki.torn.com/wiki/Item",
    "Jail": "https://wiki.torn.com/wiki/Jail",
    "Jobs": "https://wiki.torn.com/wiki/Job",
    "Leave": "https://wiki.torn.com/wiki/Leave",
    "Levels": "https://wiki.torn.com/wiki/Levels",
    "Loan Shark": "https://wiki.torn.com/wiki/Loan_Shark",
    "Loot": "https://wiki.torn.com/wiki/Loot",
    "Lottery": "https://wiki.torn.com/wiki/Lottery",
    "Marriage": "https://wiki.torn.com/wiki/Marriage",
    "Merits": "https://wiki.torn.com/wiki/Merit",
    "Messages": "https://wiki.torn.com/wiki/Messages",
    "Missions": "https://wiki.torn.com/wiki/Mission",
    "Mug": "https://wiki.torn.com/wiki/Mug",
    "Nerve": "https://wiki.torn.com/wiki/Nerve",
    "New Player Missions": "https://wiki.torn.com/wiki/New_Player_Missions",
    "Newspaper": "https://wiki.torn.com/wiki/Newspaper",
    "NPC": "https://wiki.torn.com/wiki/NPC",
    "Organized Crimes": "https://wiki.torn.com/wiki/Organized_Crime",
    "Personal Perks": "https://wiki.torn.com/wiki/Personal_Perks",
    "Pickpocketing": "https://wiki.torn.com/wiki/Pickpocketing",
    "Points": "https://wiki.torn.com/wiki/Point#Points_Building",
    "Poker": "https://wiki.torn.com/wiki/Poker",
    "Preferences": "https://wiki.torn.com/wiki/Preferences",
    "Properties": "https://wiki.torn.com/wiki/Property",
    "Property Broker": "https://wiki.torn.com/wiki/Property_Broker",
    "Race Track": "https://wiki.torn.com/wiki/Race_Track",
    "Racket": "https://wiki.torn.com/wiki/Racket",
    "Ranked War": "https://wiki.torn.com/wiki/Ranked_War",
    "Ranks": "https://wiki.torn.com/wiki/Rank",
    "Recruit Citizen": "https://wiki.torn.com/wiki/Recruit_Citizens",
    "Reports": "https://wiki.torn.com/wiki/Reports",
    "Respect": "https://wiki.torn.com/wiki/Respect",
    "Revive": "https://wiki.torn.com/wiki/Revive",
    "Roulette": "https://wiki.torn.com/wiki/Roulette",
    "Russian Roulette": "https://wiki.torn.com/wiki/Russian_Roulette",
    "Scamming": "https://wiki.torn.com/wiki/Scamming",
    "Shoplifting": "https://wiki.torn.com/wiki/Shoplifting",
    "Slots": "https://wiki.torn.com/wiki/Slots",
    "Spin The Wheel": "https://wiki.torn.com/wiki/Spin_The_Wheel",
    "Stock Market": "https://wiki.torn.com/wiki/Stock_Market",
    "Territories": "https://wiki.torn.com/wiki/Territory",
    "Trade": "https://wiki.torn.com/wiki/Trade",
    "Travel": "https://wiki.torn.com/wiki/Travel",
    "Travel - Argentina": "https://wiki.torn.com/wiki/Argentina",
    "Travel - Canada": "https://wiki.torn.com/wiki/Canada",
    "Travel - Cayman Islands": "https://wiki.torn.com/wiki/Cayman_Islands",
    "Travel - China": "https://wiki.torn.com/wiki/China",
    "Travel - Hawaii": "https://wiki.torn.com/wiki/Hawaii",
    "Travel - Japan": "https://wiki.torn.com/wiki/Japan",
    "Travel - Mexico": "https://wiki.torn.com/wiki/Mexico",
    "Travel - South Africa": "https://wiki.torn.com/wiki/South_Africa",
    "Travel - Switzerland": "https://wiki.torn.com/wiki/Switzerland",
    "Travel - UAE": "https://wiki.torn.com/wiki/United_Arab_Emirates",
    "Travel - United Kingdom": "https://wiki.torn.com/wiki/United_Kingdom",
    "War": "https://wiki.torn.com/wiki/War",
    "Weapon Bonus": "https://wiki.torn.com/wiki/Weapon_Bonus",
    "Weapon Experience": "https://wiki.torn.com/wiki/Weapon_Experience",
    "Weapon Mod": "https://wiki.torn.com/wiki/Weapon_Mod",
    "Weapon Stat": "https://wiki.torn.com/wiki/Weapon_Stat",
    "Weapons": "https://wiki.torn.com/wiki/Weapon",
    "Working Stats": "https://wiki.torn.com/wiki/Working_Stats",
  };

  @override
  State<WikiMenu> createState() => _WikiMenuState();
}

class _WikiMenuState extends State<WikiMenu> {
  final _wikiExpController = ExpandableController();
  final _searchController = TextEditingController();

  List<Widget> _searchLines = <Widget>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _buildSearchLines(context, search: _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.book_outlined,
        color: widget.themeProvider.mainText,
      ),
      title: ExpandablePanel(
        theme: ExpandableThemeData(
          iconColor: widget.themeProvider.mainText,
          animationDuration: const Duration(milliseconds: 1),
        ),
        controller: _wikiExpController,
        collapsed: const Text(
          "Wiki",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        expanded: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 14, bottom: 14),
                  child: Text(
                    "Wiki",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
            TextFormField(
              controller: _searchController,
              style: TextStyle(fontSize: 12, color: widget.themeProvider.mainText),
              maxLength: 40,
              maxLines: 1,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (value) {
                if (value.isEmpty) return;
                String url = "https://wiki.torn.com/mediawiki/index.php?search=$value";
                openWebViewSimpleDialog(
                  context: context,
                  initUrl: url,
                );
              },
              decoration: const InputDecoration(
                counterText: "",
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Search',
                labelStyle: TextStyle(fontSize: 12),
              ),
              validator: (value) {
                if (value == null) return null;
                if (value.replaceAll(' ', '').isEmpty) {
                  return "Cannot be empty!";
                }
                return null;
              },
            ),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _searchLines,
            )
          ],
        ),
      ),
      onTap: () {
        _wikiExpController.toggle();
        _searchController.clear();
      },
    );
  }

  void _buildSearchLines(BuildContext context, {String search = ""}) {
    List<Widget> items = <Widget>[];

    WikiMenu._pages.forEach((key, value) {
      addItem() {
        items.add(
          GestureDetector(
            onTap: () {
              openWebViewSimpleDialog(
                context: context,
                initUrl: value,
              );
            },
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        key,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (search.isEmpty || (search.isNotEmpty && key.toLowerCase().contains(_searchController.text.toLowerCase()))) {
        addItem();
      }
    });

    setState(() {
      _searchLines = List.from(items);
    });
  }
}
