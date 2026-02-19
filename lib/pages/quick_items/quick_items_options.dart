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
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/quick_item_model.dart';
import 'package:torn_pda/providers/quick_items_faction_provider.dart';
// Project imports:
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/quick_items/loadouts_name_dialog.dart';

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

  bool _isEquip(QuickItem item) {
    final type = item.itemType;
    return type == ItemType.PRIMARY ||
        type == ItemType.SECONDARY ||
        type == ItemType.MELEE ||
        type == ItemType.DEFENSIVE ||
        type == ItemType.TEMPORARY;
  }

  Widget? _statLine(QuickItem item) {
    if (!_isEquip(item)) return null;

    double? dmg = item.damage;
    double? acc = item.accuracy;
    double? def = item.defense;

    String fmt(double? v) => v == null ? '?' : v.toStringAsFixed(1);

    final parts = <String>[];
    if (dmg != null || acc != null) {
      if (dmg != null) parts.add('DMG ${fmt(dmg)}');
      if (acc != null) parts.add('ACC ${fmt(acc)}');
    }
    if (def != null) parts.add('DEF ${fmt(def)}');
    final text = parts.isEmpty ? '' : parts.join(' | ');

    if (text.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: _themeProvider!.mainText,
        ),
      ),
    );
  }

  Widget _enableSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.power_settings_new, size: 20),
          title: const Text('Enable quick items', style: TextStyle(fontSize: 13)),
          trailing: Switch(
            value: false,
            onChanged: (value) {
              if (widget.isFaction) {
                _settingsProvider.quickItemsFactionEnabled = value;
              } else {
                _settingsProvider.quickItemsEnabled = value;
              }
            },
            activeTrackColor: Colors.lightGreenAccent,
            activeThumbColor: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _optionsCard() {
    return Consumer2<QuickItemsProvider, SettingsProvider>(
      builder: (context, itemsProvider, settingsProvider, child) {
        final quickItemsEnabled =
            widget.isFaction ? settingsProvider.quickItemsFactionEnabled : settingsProvider.quickItemsEnabled;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                leading: const Icon(Icons.settings, size: 20),
                title: const Text('OPTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Enable quick items', style: TextStyle(fontSize: 13)),
                    trailing: Switch(
                      value: quickItemsEnabled,
                      onChanged: (value) {
                        if (widget.isFaction) {
                          settingsProvider.quickItemsFactionEnabled = value;
                        } else {
                          settingsProvider.quickItemsEnabled = value;
                        }
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeThumbColor: Colors.green,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Refresh after equipping', style: TextStyle(fontSize: 13)),
                    subtitle: const Text(
                      'Auto-refresh after each equip (slower). Loadout changes always refresh.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                    trailing: Switch(
                      value: itemsProvider.refreshAfterEquip,
                      onChanged: (value) {
                        itemsProvider.setRefreshAfterEquip(value);
                      },
                    ),
                  ),
                  if (settingsProvider.quickItemsInventoryCheckEnabled)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Hide inventory count', style: TextStyle(fontSize: 13)),
                      subtitle: const Text(
                        'Hide item quantities from the quick items chips.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                      trailing: Switch(
                        value: itemsProvider.hideInventoryCount,
                        onChanged: (value) {
                          itemsProvider.setHideInventoryCount(value);
                        },
                      ),
                    ),
                  if (!widget.isFaction)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Long-press to add items', style: TextStyle(fontSize: 13)),
                      subtitle: const Text(
                        'Replace the (+) button with a long-press gesture anywhere on the widget. '
                        'Tap or long-press again to exit add mode.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                      trailing: Switch(
                        value: itemsProvider.longPressToAdd,
                        onChanged: (value) {
                          if (value) {
                            _showLongPressConfirmationDialog(context, itemsProvider);
                          } else {
                            itemsProvider.setLongPressToAdd(false);
                          }
                        },
                      ),
                    ),
                  if (!widget.isFaction && itemsProvider.longPressToAdd)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Long-press anywhere on the quick items bar to activate the item picker. '
                        'Tap or long-press again to exit add mode.',
                        style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLongPressConfirmationDialog(BuildContext context, QuickItemsProvider itemsProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _LongPressConfirmationDialog(
          onConfirmed: () {
            itemsProvider.setLongPressToAdd(true);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _settingsProvider = Provider.of<SettingsProvider>(context);
    final quickItemsEnabled =
        widget.isFaction ? _settingsProvider.quickItemsFactionEnabled : _settingsProvider.quickItemsEnabled;
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
                      const SizedBox(height: 10),
                      if (!widget.isFaction && !quickItemsEnabled) _enableSwitch(),
                      if (!widget.isFaction && quickItemsEnabled) _optionsCard(),
                      if (!quickItemsEnabled)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text(
                              'Quick Items deactivated',
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      if (quickItemsEnabled) ...[
                        if (!widget.isFaction) const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: SizedBox(
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text("ACTIVE QUICK ITEMS"),
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
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: Text(
                              widget.isFaction
                                  ? 'No quick items active, add some below!'
                                  : 'No quick items yet. Add them from Items with the "+" button, or pick loadouts below.',
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(widget.isFaction ? "ALL AVAILABLE ITEMS" : "LOADOUTS"),
                        ),
                        const SizedBox(height: 10),
                        if ((!widget.isFaction && _itemsProvider!.fullQuickItems.isEmpty) ||
                            (widget.isFaction && _itemsProviderFaction.fullQuickItemsFaction.isEmpty))
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(50),
                              child: Column(
                                children: [
                                  Text('Loading loadouts...'),
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
          Navigator.of(context).pop();
        },
      ),
      actions: <Widget>[
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
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: item.isEnergyPoints! || item.isNervePoints! ? 20 : 0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                                          errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined),
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
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Card(
                          shape: item.isLoadout!
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.blue, width: 1),
                                )
                              : RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                                    errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined),
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
                                                item.isLoadout! ? item.loadoutName ?? "" : item.name ?? "",
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
                                      if (_statLine(item) != null) _statLine(item)!,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (!item.isLoadout!)
                                  GestureDetector(
                                    onTap: () {
                                      BotToast.showText(
                                        text: '${item.name}\n\n${item.description}',
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
                                              errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined),
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
            Consumer<QuickItemsProvider>(
              builder: (context, itemsProvider, child) {
                final loadoutCards = <Widget>[];
                for (final item in itemsProvider.fullQuickItems) {
                  if (!item.isLoadout!) continue;
                  loadoutCards.add(
                    AnimatedOpacity(
                      opacity: item.visible! ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        height: 60,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.blue, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: item.isLoadout!
                                      ? Image.asset(
                                          'images/icons/loadout.png',
                                          width: 25,
                                          height: 25,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined),
                                        )
                                      : Image.asset(
                                          'images/torn_items/small/${item.number}_small.png',
                                          width: 35,
                                          height: 35,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.name ?? '',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: !item.visible!
                                      ? null
                                      : () async {
                                          setState(() {
                                            item.visible = false;
                                          });

                                          await Future.delayed(const Duration(milliseconds: 200));

                                          setState(() {
                                            itemsProvider.activateQuickItem(item);
                                          });

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
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: loadoutCards,
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
    return true;
  }
}

class _LongPressConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirmed;

  const _LongPressConfirmationDialog({required this.onConfirmed});

  @override
  State<_LongPressConfirmationDialog> createState() => _LongPressConfirmationDialogState();
}

class _LongPressConfirmationDialogState extends State<_LongPressConfirmationDialog> with TickerProviderStateMixin {
  late AnimationController _progressController;
  bool _confirmed = false;
  bool _holding = false;

  static const _holdDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: _holdDuration);
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_confirmed) {
        setState(() => _confirmed = true);
        widget.onConfirmed();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _onPointerDown() {
    setState(() => _holding = true);
    _progressController.forward(from: _progressController.value);
  }

  void _onPointerUp() {
    if (!_confirmed) {
      setState(() => _holding = false);
      _progressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Long-press mode', style: TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'If you enable this, the (+) button will be replaced. '
            'You will need to long-press anywhere on the quick items bar to activate the item picker.\n\n'
            'Once in add mode, tap or long-press anywhere to exit.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressController.value,
                      minHeight: 8,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _holding ? Colors.orange : Colors.orange.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTapDown: (_) => _onPointerDown(),
                    onTapUp: (_) => _onPointerUp(),
                    onTapCancel: _onPointerUp,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _holding ? Colors.orange[800] : Colors.orange[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _holding ? 'Keep holding...' : 'Hold to confirm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
