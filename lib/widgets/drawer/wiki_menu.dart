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
    "Armor": "https://wiki.torn.com/wiki/Armor",
    "Arrest": "https://wiki.torn.com/wiki/Arrest",
    "Attacking": "https://wiki.torn.com/wiki/Attack",
    "Awards": "https://wiki.torn.com/wiki/Award",
    "Awareness": "https://wiki.torn.com/wiki/Awareness",
    "Battle Stats": "https://wiki.torn.com/wiki/Battle_Stats",
    "Books": "https://wiki.torn.com/wiki/Books",
    "Cars": "https://wiki.torn.com/wiki/Cars",
    "Casino": "https://wiki.torn.com/wiki/Casino",
    "City": "https://wiki.torn.com/wiki/City",
    "Collectibles": "https://wiki.torn.com/wiki/Collectible#Collectibles",
    "Companies": "https://wiki.torn.com/wiki/Company",
    "Cooldowns": "https://wiki.torn.com/wiki/Item_Cooldowns",
    "Cosmetic Cache": "https://wiki.torn.com/wiki/Cosmetic_Cache",
    "Crimes": "https://wiki.torn.com/wiki/Crime",
    "Dirty Bomb": "https://wiki.torn.com/wiki/Dirty_Bomb",
    "Donator": "https://wiki.torn.com/wiki/Donator",
    "Drugs": "https://wiki.torn.com/wiki/Drug",
    "Education": "https://wiki.torn.com/wiki/Education",
    "Enemies List": "https://wiki.torn.com/wiki/Enemies_List",
    "Energy": "https://wiki.torn.com/wiki/Energy",
    "Factions": "https://wiki.torn.com/wiki/Faction",
    "Forums": "https://wiki.torn.com/wiki/Forum",
    "Friends List": "https://wiki.torn.com/wiki/Friends_List",
    "Gym": "https://wiki.torn.com/wiki/Gym",
    "Hall of Fame": "https://wiki.torn.com/wiki/Hall_of_Fame",
    "Happy": "https://wiki.torn.com/wiki/Happy",
    "Hospital": "https://wiki.torn.com/wiki/Hospital",
    "Hospitalize": "https://wiki.torn.com/wiki/Hospitalize",
    "Hunting": "https://wiki.torn.com/wiki/Hunting",
    "Items": "https://wiki.torn.com/wiki/Item",
    "Jail": "https://wiki.torn.com/wiki/Jail",
    "Jobs": "https://wiki.torn.com/wiki/Job",
    "Leave": "https://wiki.torn.com/wiki/Leave",
    "Loot": "https://wiki.torn.com/wiki/Loot",
    "Marriage": "https://wiki.torn.com/wiki/Marriage",
    "Merits": "https://wiki.torn.com/wiki/Merit",
    "Missions": "https://wiki.torn.com/wiki/Mission",
    "Mug": "https://wiki.torn.com/wiki/Mug",
    "Nerve": "https://wiki.torn.com/wiki/Nerve",
    "New Player Missions": "https://wiki.torn.com/wiki/New_Player_Missions",
    "Newspaper": "https://wiki.torn.com/wiki/Newspaper",
    "Organized Crimes": "https://wiki.torn.com/wiki/Organized_Crime",
    "Points": "https://wiki.torn.com/wiki/Point#Points_Building",
    "Preferences": "https://wiki.torn.com/wiki/Preferences",
    "Properties": "https://wiki.torn.com/wiki/Property",
    "Race Track": "https://wiki.torn.com/wiki/Race_Track",
    "Racket": "https://wiki.torn.com/wiki/Racket",
    "Ranks": "https://wiki.torn.com/wiki/Rank",
    "Recruit Citizen": "https://wiki.torn.com/wiki/Recruit_Citizens",
    "Reports": "https://wiki.torn.com/wiki/Reports",
    "Stock Market": "https://wiki.torn.com/wiki/Stock_Market",
    "Territories": "https://wiki.torn.com/wiki/Territory",
    "Travel": "https://wiki.torn.com/wiki/Travel",
    "Weapon Mod": "https://wiki.torn.com/wiki/Weapon_Mod",
    "Weapon Stat": "https://wiki.torn.com/wiki/Weapon_Stat",
    "Weapons": "https://wiki.torn.com/wiki/Weapon",
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

  _buildSearchLines(BuildContext context, {String search = ""}) {
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
