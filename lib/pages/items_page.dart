// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/user_controller.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/emoji_parser.dart';
import 'package:torn_pda/widgets/items/item_card.dart';

class ItemsPage extends StatefulWidget {
  ItemsPage({Key key}) : super(key: key);

  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> with WidgetsBindingObserver {
  List<Item> _allItems = <Item>[];

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;
  UserController _u = Get.put(UserController());

  Future _loadedApiItems;

  @override
  void initState() {
    super.initState();
    _loadedApiItems = _getAllTornItems();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    return Scaffold(
      drawer: Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: FutureBuilder(
        future: _loadedApiItems,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _itemsMain();
          } else {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      leading: IconButton(
        icon: Icon(Icons.dehaze),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      title: Text('Items'),
    );
  }

  Widget _itemsMain() {
    return Column(
      children: [
        Text("HEADER"),
        Expanded(
          child: ListView.builder(
            itemCount: _allItems.length,
            //shrinkWrap: true,
            //physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return ItemCard(
                item: _allItems[index],
                settingsProvider: _settingsProvider,
                themeProvider: _themeProvider,
                apiKey: _u.apiKey,
              );
            },
          ),
        ),
      ],
    );
  }

  Future _getAllTornItems() async {
    var allTornItems = await TornApiCaller.items(_u.apiKey).getItems;
    if (allTornItems is ItemsModel) {
      allTornItems.items.forEach((itemNumber, itemProperties) {
        itemProperties.name = EmojiParser.fix(itemProperties.name);
        itemProperties.id = itemNumber;
        _allItems.add(itemProperties);
      });
      _allItems.sort((a, b) => a.name.compareTo(b.name));
      return true;
    }
    return false;
  }
}
