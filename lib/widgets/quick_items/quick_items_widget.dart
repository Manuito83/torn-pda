// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Project imports:
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/quick_item_model.dart';
import 'package:torn_pda/pages/quick_items/quick_items_options.dart';
import 'package:torn_pda/providers/quick_items_faction_provider.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';

class QuickItemsWidget extends StatefulWidget {
  final InAppWebViewController? inAppWebViewController;
  final WebViewController? webViewController;
  final bool faction;

  const QuickItemsWidget({
    required this.faction,
    this.inAppWebViewController,
    this.webViewController,
  });

  @override
  QuickItemsWidgetState createState() => QuickItemsWidgetState();
}

class QuickItemsWidgetState extends State<QuickItemsWidget> {
  late QuickItemsProvider _itemsProvider;
  late QuickItemsProviderFaction _itemsProviderFaction;

  late Timer _inventoryRefreshTimer;

  final _scrollController = ScrollController();
  bool _pickerActive = false;
  bool _pickerBusy = false;
  bool _cleanupHandlerAttached = false;

  @override
  void initState() {
    super.initState();
    _registerPickerCleanupHandler();
    _inventoryRefreshTimer = Timer.periodic(const Duration(seconds: 40), (Timer t) => _refreshInventory());
  }

  @override
  void didUpdateWidget(covariant QuickItemsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inAppWebViewController != oldWidget.inAppWebViewController) {
      _cleanupHandlerAttached = false;
      _registerPickerCleanupHandler();
    }
  }

  @override
  void dispose() {
    _inventoryRefreshTimer.cancel();
    _disablePickerSilently();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _itemsProvider = context.watch<QuickItemsProvider>();
    _itemsProviderFaction = context.watch<QuickItemsProviderFaction>();
    return Container(
      decoration: _pickerActive
          ? BoxDecoration(
              border: Border.all(color: Colors.orangeAccent, width: 1),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(
                Size.fromHeight(
                      MediaQuery.sizeOf(context).height - kToolbarHeight - AppBar().preferredSize.height,
                    ) /
                    3,
              ),
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 5,
                    runSpacing: context.read<ThemeProvider>().useMaterial3 ? 2 : -5,
                    children: _itemButtons(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _itemButtons() {
    final myList = <Widget>[];

    List<QuickItem> itemList = <QuickItem>[];
    if (widget.faction) {
      itemList = List.from(_itemsProviderFaction.activeQuickItemsFaction);
    } else {
      itemList = List.from(_itemsProvider.activeQuickItems);
    }

    if (itemList.isEmpty) {
      myList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!widget.faction) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pickerChip(allowSingleTap: true),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        'Tap to add quick items from your list',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Configure your faction's armoury quick items",
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                    const SizedBox(width: 8),
                    _settingsIcon(),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

      return myList;
    }

    if (!widget.faction) {
      myList.add(_pickerChip());
    }

    for (final item in itemList) {
      Color? qtyColor;
      if (item.inventory == 0) {
        qtyColor = Colors.orange[300];
      } else {
        qtyColor = Colors.green[300];
      }

      double qtyFontSize = 12;
      String? itemQty;
      if (!item.isLoadout! && !widget.faction) {
        // Unique equip variants: hide aggregated counts when instanceId is known
        final hasInstance = item.instanceId != null && item.instanceId!.isNotEmpty;
        if (hasInstance) {
          itemQty = null;
        } else if (item.inventory == null) {
          itemQty = null;
        } else {
          itemQty = item.inventory.toString();
          if (item.inventory! > 999 && item.inventory! < 100000) {
            itemQty = "${(item.inventory! / 1000).truncate().toStringAsFixed(0)}K";
          } else if (item.inventory! >= 100000) {
            itemQty = "∞";
          }
          if (item.inventory! >= 10000 && item.inventory! < 100000) {
            qtyFontSize = 11;
          }
        }
      }

      myList.add(
        Tooltip(
          message: '${item.name}\n\n${item.description}',
          textStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey[700]),
          child: ActionChip(
            elevation: 3,
            padding: const EdgeInsets.all(4),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            side: item.isLoadout! || item.isEnergyPoints! || item.isNervePoints!
                ? const BorderSide(color: Colors.blue)
                : null,
            avatar: item.isLoadout!
                    // Personal inventory was removed from the API, so add a check until it's restored
                    // https://www.torn.com/forums.php#/p=threads&f=63&t=16146310&b=0&a=0&start=20&to=24014610
                    ||
                    (!item.isLoadout! && !widget.faction && itemQty == null)
                ? null
                : widget.faction
                    ? item.isEnergyPoints! || item.isNervePoints!
                        ? Icon(
                            MdiIcons.alphaPCircleOutline,
                            color: item.isEnergyPoints! ? Colors.green : Colors.red,
                          )
                        : CircleAvatar(
                            child: Image.asset(
                              'images/icons/faction.png',
                              width: 12,
                              color: Colors.white,
                            ),
                          )
                    : CircleAvatar(
                        child: Text(
                          itemQty!,
                          style: TextStyle(
                            fontSize: qtyFontSize,
                            color: qtyColor,
                          ),
                        ),
                      ),
            label: item.isLoadout!
                ? Text(
                    item.loadoutName ?? "",
                    style: const TextStyle(fontSize: 11),
                  )
                : item.isEnergyPoints! || item.isNervePoints!
                    ? Text(
                        item.isEnergyPoints! ? "E Refill" : "N Refill",
                        style: const TextStyle(fontSize: 11),
                      )
                    : item.name!.split(' ').length > 1
                        ? _splitName(item.name!.replaceAll("Blood Bag : ", "Blood: "))
                        : Text(
                            item.name!.replaceAll("Blood Bag : ", "Blood: "),
                            softWrap: true,
                            overflow: TextOverflow.clip,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 11),
                          ),
            onPressed: () async {
              if (item.isLoadout!) {
                final js = changeLoadOutJS(item: item.name!.split(" ")[1], attackWebview: false);
                await widget.inAppWebViewController!.evaluateJavascript(source: js);
              } else {
                final isEquip = item.itemType == ItemType.PRIMARY ||
                    item.itemType == ItemType.SECONDARY ||
                    item.itemType == ItemType.MELEE ||
                    item.itemType == ItemType.DEFENSIVE ||
                    item.itemType == ItemType.TEMPORARY;
                final js = quickItemsJS(
                  item: item.number.toString(),
                  faction: widget.faction,
                  eRefill: item.isEnergyPoints,
                  nRefill: item.isNervePoints,
                  instanceId: item.instanceId,
                  isEquip: isEquip,
                  refreshAfterEquip: _itemsProvider.refreshAfterEquip,
                );
                await widget.inAppWebViewController!.evaluateJavascript(source: js);
                if (!widget.faction) {
                  _itemsProvider.decreaseInventory(item);
                }
              }
            },
          ),
        ),
      );
    }

    return myList;
  }

  Widget _splitName(String name) {
    final splits = name.split(" ");
    final middle = (splits.length / 2).round();
    var upperString = '';
    var lowerString = '';
    for (var i = 0; i < middle; i++) {
      if (i > 0) {
        upperString += " ";
      }
      upperString += splits[i];
    }
    for (var i = middle; i < splits.length; i++) {
      if (i > middle) {
        lowerString += " ";
      }
      lowerString += splits[i];
    }

    return Column(
      children: [
        Text(upperString, style: const TextStyle(fontSize: 11)),
        Text(lowerString, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  void _refreshInventory() {
    if (!widget.faction) {
      _itemsProvider.updateInventoryQuantities();
    }
  }

  void _registerPickerCleanupHandler() {
    final controller = widget.inAppWebViewController;
    if (controller == null || _cleanupHandlerAttached) return;
    try {
      controller.addJavaScriptHandler(
        handlerName: 'quickItemPickerCleanup',
        callback: (args) {
          if (mounted) {
            setState(() {
              _pickerActive = false;
              _pickerBusy = false;
            });
          }
          return {'status': 'ok'};
        },
      );
      _cleanupHandlerAttached = true;
    } catch (_) {}
  }

  Widget _pickerChip({bool allowSingleTap = false}) {
    final icon = _pickerActive ? Icons.close : Icons.add;
    final borderColor = _pickerActive ? Colors.redAccent : Colors.green[600];

    return Padding(
      padding: EdgeInsets.only(top: allowSingleTap ? 6 : 10, right: 14),
      child: InkWell(
        onTap: _pickerBusy
            ? null
            : () {
                if (!_pickerActive) {
                  if (allowSingleTap) {
                    _togglePicker(true);
                  } else {
                    BotToast.showText(
                      text: 'Hold to activate!',
                      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                      contentColor: Colors.blue[700]!,
                      duration: const Duration(seconds: 2),
                      contentPadding: const EdgeInsets.all(12),
                    );
                  }
                } else {
                  _togglePicker(false);
                }
              },
        onLongPress: _pickerBusy || _pickerActive || allowSingleTap ? null : () => _togglePicker(true),
        customBorder: const CircleBorder(),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor ?? Colors.green, width: 1.6),
            color: Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: borderColor, size: 16),
        ),
      ),
    );
  }

  Future<void> _togglePicker(bool enable) async {
    if (widget.inAppWebViewController == null) return;
    setState(() {
      _pickerBusy = true;
    });
    try {
      final result = await widget.inAppWebViewController!.evaluateJavascript(
        source: quickItemPickerJS(enable: enable),
      );
      if (!mounted) return;
      final resultStr = result?.toString();

      // Check if page is in grid/thumbnails mode
      if (resultStr == 'grid-mode') {
        BotToast.showText(
          text: 'Quick item picker requires List view mode. Please switch from Grid to List view.',
          textStyle: const TextStyle(fontSize: 14, color: Colors.white),
          contentColor: Colors.orange[800]!,
          duration: const Duration(seconds: 4),
          contentPadding: const EdgeInsets.all(12),
        );
        return;
      }

      final nextActive = enable && resultStr != 'picker-disabled';
      setState(() {
        _pickerActive = nextActive;
      });
      if (nextActive) {
        BotToast.showText(
          text: 'Choose the items you want to add from your items list',
          textStyle: const TextStyle(fontSize: 14, color: Colors.white),
          contentColor: Colors.blue[800]!,
          duration: const Duration(seconds: 3),
          contentPadding: const EdgeInsets.all(12),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pickerActive = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _pickerBusy = false;
        });
      }
    }
  }

  Future<void> _disablePickerSilently() async {
    if (!_pickerActive || widget.inAppWebViewController == null) return;
    try {
      await widget.inAppWebViewController!.evaluateJavascript(
        source: quickItemPickerJS(enable: false),
      );
    } catch (_) {
      // Ignore errors on dispose
    }
  }

  Widget _settingsIcon() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: OpenContainer(
        transitionDuration: const Duration(milliseconds: 300),
        transitionType: ContainerTransitionType.fade,
        openBuilder: (BuildContext context, VoidCallback _) {
          return QuickItemsOptions(
            isFaction: widget.faction,
          );
        },
        closedElevation: 0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        closedColor: Colors.transparent,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return const Padding(
            padding: EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(Icons.settings, size: 16, color: Colors.orange),
            ),
          );
        },
      ),
    );
  }
}
