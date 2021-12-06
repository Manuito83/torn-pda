// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/inventory_model.dart';
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
  InventoryModel _inventory = InventoryModel();

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;
  UserController _u = Get.put(UserController());

  String _currentSearchFilter = '';
  final _searchController = new TextEditingController();
  final _searchFocusNode = FocusNode();

  Future _loadedApiItems;
  bool _itemsSuccess = false;
  bool _inventorySuccess = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadedApiItems = _getAllItems();
    _searchController.addListener(onSearchInputTextChange);
    analytics.setCurrentScreen(screenName: 'items');
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
            if (_itemsSuccess) {
              return _itemsMain();
            }
            return _errorMain();
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
        _searchBar(),
        Expanded(
          child: ListView.builder(
            itemCount: _allItems.length,
            itemBuilder: (context, index) {
              bool inFilter = _allItems[index].name.toLowerCase().contains(_currentSearchFilter);
              if (inFilter) {
                return ItemCard(
                  item: _allItems[index],
                  settingsProvider: _settingsProvider,
                  themeProvider: _themeProvider,
                  apiKey: _u.apiKey,
                  inventorySuccess: _inventorySuccess,
                );
              }
              return SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Focus(
        focusNode: _searchFocusNode,
        child: TextField(
          controller: _searchController,
          maxLength: 30,
          decoration: InputDecoration(
            isDense: true,
            labelText: "Search",
            counterText: "",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(6.0),
              ),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _searchController.text = "";
                  _searchFocusNode.unfocus();
                });
              },
              icon: Icon(Icons.clear),
            ),
          ),
        ),
      ),
    );
  }

  void onSearchInputTextChange() {
    setState(() {
      _currentSearchFilter = _searchController.text.toLowerCase();
    });
  }

  Future _getAllItems() async {
    // First get all Torn items
    var apiItems = await TornApiCaller.items(_u.apiKey).getItems;
    var apiInventory = await TornApiCaller.items(_u.apiKey).getInventory;

    if (apiItems is! ItemsModel) {
      ApiError error = apiItems as ApiError;
      _errorMessage = error.errorReason;
      return;
    } else {
      _itemsSuccess = true;
    }

    apiItems.items.forEach((id, details) {
      details.name = EmojiParser.fix(details.name);
      details.id = id;

      // Inventory details
      if (apiInventory is InventoryModel) {
        InventoryModel inv = apiInventory;
        // Bazaar
        Inventory bazaar = inv.inventory.firstWhere((i) => i.id.toString() == id, orElse: () => null);
        bazaar == null ? details.inventoryOwned = 0 : details.inventoryOwned = bazaar.quantity;
        // Cabinet
        DisplayCabinet cabinet = inv.display.firstWhere((i) => i.id.toString() == id, orElse: () => null);
        cabinet == null ? details.inventoryOwned += 0 : details.inventoryOwned += cabinet.quantity;
        _inventorySuccess = true;
      }

      _allItems.add(details);
    });
    // Sort them
    _allItems.sort((a, b) => a.name.compareTo(b.name));
  }

  Widget _errorMain() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 50),
        Text(
          'OOPS!',
          style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          child: Column(
            children: [
              Text(
                'There was an error: $_errorMessage\n\n'
                'If you have good Internet connectivity, it might be an issue with Torn\'s API.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }
}
