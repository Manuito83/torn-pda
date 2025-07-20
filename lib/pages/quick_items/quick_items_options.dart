// Flutter imports:
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/quick_item_model.dart';
import 'package:torn_pda/providers/quick_items_faction_provider.dart';
// Project imports:
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/quick_items/loadouts_name_dialog.dart';
import 'package:torn_pda/widgets/quick_items/loadouts_number_dialog.dart';

class QuickItemsOptions extends StatefulWidget {
  final bool isFaction;

  const QuickItemsOptions({required this.isFaction});

  @override
  QuickItemsOptionsState createState() => QuickItemsOptionsState();
}

class QuickItemsOptionsState extends State<QuickItemsOptions> {
  late SettingsProvider _settingsProvider;
  QuickItemsProvider? _itemsProvider;
  late QuickItemsProviderFaction _itemsProviderFaction;
  ThemeProvider? _themeProvider;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _itemsProvider = Provider.of<QuickItemsProvider>(context, listen: false);
    _itemsProviderFaction = Provider.of<QuickItemsProviderFaction>(context, listen: false);

    if (!widget.isFaction) {
      _itemsProvider!.updateInventoryQuantities(fullUpdate: true);
    }

    _searchController.addListener(onSearchInputTextChange);

    routeWithDrawer = false;
    routeName = "quick_items";
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _willPopCallback();
      },
      child: Container(
        color: _themeProvider!.currentTheme == AppTheme.light
            ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : isStatusBarShown
                    ? _themeProvider!.statusBar
                    : _themeProvider!.canvas
            : _themeProvider!.canvas,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: _themeProvider!.canvas,
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: Container(
              color: _themeProvider!.canvas,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text("QUICK ITEMS ACTIVE"),
                              Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  'SWIPE TO REMOVE',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  'LONG-PRESS TO SORT',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if ((!widget.isFaction && _itemsProvider!.activeQuickItems.isEmpty) ||
                          (widget.isFaction && _itemsProviderFaction.activeQuickItemsFaction.isEmpty))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 10, 0, 10),
                          child: Text(
                            'No quick items active, add some below!',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        _activeCardsList(),
                      const SizedBox(height: 40),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text("ALL AVAILABLE ITEMS"),
                      ),
                      const SizedBox(height: 10),
                      if ((!widget.isFaction && _itemsProvider!.fullQuickItems.isEmpty) ||
                          (widget.isFaction && _itemsProviderFaction.fullQuickItemsFaction.isEmpty))
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: Column(
                              children: [
                                Text('Loading available items...'),
                                SizedBox(height: 40),
                                CircularProgressIndicator(),
                                SizedBox(height: 40),
                                Text(
                                  'If this takes too long, there might be a connection '
                                  'problem or Torn API might be down. Close the browser '
                                  'completely and try again in a while!',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        _allCardsList(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: widget.isFaction
          ? const Text("Quick faction items", style: TextStyle(color: Colors.white))
          : const Text("Quick items", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
      actions: <Widget>[
        if (!widget.isFaction)
          IconButton(
            icon: Image.asset(
              'images/icons/loadout.png',
            ),
            onPressed: () async {
              _openLoadoutsNumberDialog();
            },
          ),
        IconButton(
          icon: Icon(
            Icons.delete,
            color: _themeProvider!.buttonText,
          ),
          onPressed: () async {
            if ((!widget.isFaction && _itemsProvider!.activeQuickItems.isEmpty) ||
                (widget.isFaction && _itemsProviderFaction.activeQuickItemsFaction.isEmpty)) {
              BotToast.showText(
                text: 'You have no active quick items, activate some!',
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.orange[800]!,
                contentPadding: const EdgeInsets.all(10),
              );
            } else {
              _openWipeDialog();
            }
          },
        ),
      ],
    );
  }

  Padding _activeCardsList() {
    if (widget.isFaction) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Consumer<QuickItemsProviderFaction>(
          builder: (context, itemsProviderFaction, child) {
            final activeItems = <Widget>[];
            for (final item in itemsProviderFaction.activeQuickItemsFaction) {
              activeItems.add(
                Scrollable(
                  key: UniqueKey(),
                  viewportBuilder: (BuildContext context, ViewportOffset position) => Slidable(
                    startActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          backgroundColor: Colors.red,
                          icon: Icons.remove_circle_outline_outlined,
                          onPressed: (context) {
                            itemsProviderFaction.deactivateQuickItem(item);
                          },
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 60,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: item.isEnergyPoints! || item.isNervePoints! ? 20 : 0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: item.isEnergyPoints! || item.isNervePoints!
                                      ? SizedBox(
                                          width: 25,
                                          child: Icon(
                                            MdiIcons.alphaPCircleOutline,
                                            color: item.isEnergyPoints! ? Colors.green : Colors.red,
                                          ),
                                        )
                                      : Image.asset(
                                          'images/torn_items/small/${item.number}_small.png',
                                          width: 35,
                                          height: 35,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                item.name!,
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const SizedBox(width: 10),
                                const Icon(Icons.reorder),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Container(
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (int oldIndex, int newIndex) {
                  if (oldIndex < newIndex) {
                    // removing the item at oldIndex will shorten the list by 1
                    newIndex -= 1;
                  }
                  itemsProviderFaction.reorderQuickItem(
                    itemsProviderFaction.activeQuickItemsFaction[oldIndex],
                    oldIndex,
                    newIndex,
                  );
                },
                children: activeItems,
              ),
            );
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Consumer<QuickItemsProvider>(
          builder: (context, itemsProvider, child) {
            final activeItems = <Widget>[];
            for (final item in itemsProvider.activeQuickItems) {
              activeItems.add(
                Scrollable(
                  key: UniqueKey(),
                  viewportBuilder: (BuildContext context, ViewportOffset position) => Slidable(
                    startActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          backgroundColor: Colors.red,
                          icon: Icons.remove_circle_outline_outlined,
                          onPressed: (context) {
                            _itemsProvider!.deactivateQuickItem(item);
                          },
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 60,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: item.isLoadout! ? 20 : 0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Image.asset(
                                    item.isLoadout!
                                        ? 'images/icons/loadout.png'
                                        : 'images/torn_items/small/${item.number}_small.png',
                                    width: item.isLoadout! ? 25 : 35,
                                    height: item.isLoadout! ? 25 : 35,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                item.isLoadout! ? item.loadoutName! : item.name!,
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!item.isLoadout! && item.inventory != null)
                                        Text(
                                          "(inv: x${item.inventory})",
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (!item.isLoadout!)
                                  GestureDetector(
                                    onTap: () {
                                      BotToast.showText(
                                        text: '${item.name}\n\n${item.description}',
                                        /* Inventory not shown in API v2 yet
                                          text: '${item.name}\n\n${item.description}\n\n'
                                          'You have ${item.inventory} in your inventory',
                                        */
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                        contentColor: Colors.green[800]!,
                                        duration: const Duration(seconds: 5),
                                        contentPadding: const EdgeInsets.all(10),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.info_outline,
                                      size: 19,
                                    ),
                                  )
                                else if (item.isLoadout!)
                                  GestureDetector(
                                    onTap: () {
                                      _openLoadoutsNameDialog(item);
                                    },
                                    child: const Icon(
                                      Icons.edit,
                                      size: 19,
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                const Icon(Icons.reorder),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Container(
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (int oldIndex, int newIndex) {
                  if (oldIndex < newIndex) {
                    // removing the item at oldIndex will shorten the list by 1
                    newIndex -= 1;
                  }
                  _itemsProvider!.reorderQuickItem(
                    itemsProvider.activeQuickItems[oldIndex],
                    oldIndex,
                    newIndex,
                  );
                },
                children: activeItems,
              ),
            );
          },
        ),
      );
    }
  }

  Padding _allCardsList() {
    if (widget.isFaction) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                maxLength: 30,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: "Search",
                  counterText: "",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(6.0),
                    ),
                  ),
                ),
              ),
            ),
            Consumer<QuickItemsProviderFaction>(
              builder: (context, itemsProviderFaction, child) {
                final allQuickItems = <Widget>[];
                for (final item in itemsProviderFaction.fullQuickItemsFaction) {
                  if (item.name!.toLowerCase().contains(_itemsProviderFaction.searchFilter.toLowerCase())) {
                    if (item.active!) {
                      continue;
                    }

                    allQuickItems.add(
                      AnimatedOpacity(
                        opacity: item.visible! ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          height: 60,
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: item.isEnergyPoints! || item.isNervePoints! ? 20 : 0),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: item.isEnergyPoints! || item.isNervePoints!
                                          ? SizedBox(
                                              width: 25,
                                              child: Icon(
                                                MdiIcons.alphaPCircleOutline,
                                                color: item.isEnergyPoints! ? Colors.green : Colors.red,
                                              ),
                                            )
                                          : Image.asset(
                                              'images/torn_items/small/${item.number}_small.png',
                                              width: 35,
                                              height: 35,
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.name!,
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!item.isLoadout!)
                                      GestureDetector(
                                        onTap: () {
                                          BotToast.showText(
                                            text: '${item.name}\n\n${item.description}\n\n',
                                            textStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                            contentColor: Colors.green[800]!,
                                            duration: const Duration(seconds: 5),
                                            contentPadding: const EdgeInsets.all(10),
                                          );
                                        },
                                        child: const Icon(
                                          Icons.info_outline,
                                          size: 19,
                                        ),
                                      ),
                                    TextButton(
                                      onPressed: !item.visible!
                                          // Avoid double press
                                          ? null
                                          : () async {
                                              // Start animation
                                              setState(() {
                                                item.visible = false;
                                              });

                                              await Future.delayed(const Duration(milliseconds: 300));

                                              setState(() {
                                                itemsProviderFaction.activateQuickItem(item);
                                              });

                                              // Reset visibility after animation
                                              item.visible = true;
                                            },
                                      child: Text(
                                        'ADD',
                                        style: TextStyle(color: Colors.green[500]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }
                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: allQuickItems,
                );
              },
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                maxLength: 30,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: "Search",
                  counterText: "",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(6.0),
                    ),
                  ),
                ),
              ),
            ),
            Consumer<QuickItemsProvider>(
              builder: (context, itemsProvider, child) {
                final allQuickItems = <Widget>[];
                for (final item in itemsProvider.fullQuickItems) {
                  if (item.name!.toLowerCase().contains(_itemsProvider!.searchFilter.toLowerCase())) {
                    if (item.active! ||
                        (item.isLoadout! && item.loadoutNumber! > itemsProvider.numberOfLoadoutsToShow)) {
                      continue;
                    }

                    allQuickItems.add(
                      AnimatedOpacity(
                        opacity: item.visible! ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          height: 60,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: item.isLoadout! ? 20 : 0),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Image.asset(
                                        item.isLoadout!
                                            ? 'images/icons/loadout.png'
                                            : 'images/torn_items/small/${item.number}_small.png',
                                        width: item.isLoadout! ? 25 : 35,
                                        height: item.isLoadout! ? 25 : 35,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.name!,
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!item.isLoadout! && item.inventory != null)
                                            Text(
                                              "(inv: x${item.inventory})",
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (!item.isLoadout!)
                                      GestureDetector(
                                        onTap: () {
                                          BotToast.showText(
                                            text: '${item.name}\n\n${item.description}',
                                            /* Inventory not shown in API v2 yet
                                            text: '${item.name}\n\n${item.description}\n\n'
                                                'You have ${item.inventory} in your inventory',
                                            */
                                            textStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                            contentColor: Colors.green[800]!,
                                            duration: const Duration(seconds: 5),
                                            contentPadding: const EdgeInsets.all(10),
                                          );
                                        },
                                        child: const Icon(
                                          Icons.info_outline,
                                          size: 19,
                                        ),
                                      ),
                                    TextButton(
                                      onPressed: !item.visible!
                                          // Avoid double press
                                          ? null
                                          : () async {
                                              // Start animation
                                              setState(() {
                                                item.visible = false;
                                              });

                                              await Future.delayed(const Duration(milliseconds: 300));

                                              setState(() {
                                                itemsProvider.activateQuickItem(item);
                                              });

                                              // Reset visibility after animation
                                              item.visible = true;
                                            },
                                      child: Text(
                                        'ADD',
                                        style: TextStyle(color: Colors.green[500]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }
                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: allQuickItems,
                );
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openWipeDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: _themeProvider!.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "This will reset all your quick items and order, "
                            "are you sure?",
                            style: TextStyle(fontSize: 12, color: _themeProvider!.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Reset!"),
                              onPressed: () {
                                if (widget.isFaction) {
                                  _itemsProviderFaction.wipeAllQuickItems();
                                } else {
                                  _itemsProvider!.wipeAllQuickItems();
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Oh no!"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider!.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider!.secondBackground,
                      radius: 22,
                      child: const SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(Icons.delete_forever_outlined),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLoadoutsNumberDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return LoadoutsNumberDialog(
          themeProvider: _themeProvider,
          itemsProvider: _itemsProvider,
        );
      },
    );
  }

  Future<void> _openLoadoutsNameDialog(QuickItem item) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return LoadoutsNameDialog(
          themeProvider: _themeProvider,
          quickItemsProvider: _itemsProvider,
          loadout: item,
        );
      },
    );
  }

  void onSearchInputTextChange() {
    if (widget.isFaction) {
      _itemsProviderFaction.setFilterText(_searchController.text);
    } else {
      _itemsProvider!.setFilterText(_searchController.text);
    }
  }

  Future<bool> _willPopCallback() async {
    _searchController.text = "";
    Navigator.of(context).pop();
    return true;
  }
}
