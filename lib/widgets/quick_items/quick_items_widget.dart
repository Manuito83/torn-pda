// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/quick_item_model.dart';
import 'package:torn_pda/pages/quick_items/quick_items_options.dart';
import 'package:torn_pda/providers/quick_items_faction_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Project imports:
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';

class QuickItemsWidget extends StatefulWidget {
  final InAppWebViewController inAppWebViewController;
  final WebViewController webViewController;
  final bool faction;

  QuickItemsWidget({
    @required this.faction,
    this.inAppWebViewController,
    this.webViewController,
  });

  @override
  _QuickItemsWidgetState createState() => _QuickItemsWidgetState();
}

class _QuickItemsWidgetState extends State<QuickItemsWidget> {
  QuickItemsProvider _itemsProvider;
  QuickItemsProviderFaction _itemsProviderFaction;

  Timer _inventoryRefreshTimer;

  @override
  void initState() {
    super.initState();
    _inventoryRefreshTimer = new Timer.periodic(Duration(seconds: 40), (Timer t) => _refreshInventory());
  }

  @override
  void dispose() {
    _inventoryRefreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _itemsProvider = context.watch<QuickItemsProvider>();
    _itemsProviderFaction = context.watch<QuickItemsProviderFaction>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(Size.fromHeight(
                      (MediaQuery.of(context).size.height - kToolbarHeight - AppBar().preferredSize.height)) /
                  3),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 5,
                    runSpacing: -10,
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
    var myList = <Widget>[];

    List<QuickItem> itemList = <QuickItem>[];
    if (widget.faction) {
      itemList = List.from(_itemsProviderFaction.activeQuickItemsFaction);
    } else {
      itemList = List.from(_itemsProvider.activeQuickItems);
    }

    for (var item in itemList) {
      Color qtyColor;
      if (item.inventory == 0) {
        qtyColor = Colors.orange[300];
      } else {
        qtyColor = Colors.green[300];
      }

      double qtyFontSize = 12;
      var itemQty = item.inventory.toString();
      if (!item.isLoadout && !widget.faction) {
        if (item.inventory > 999 && item.inventory < 100000) {
          itemQty = "${(item.inventory / 1000).truncate().toStringAsFixed(0)}K";
        } else if (item.inventory >= 100000) {
          itemQty = "∞";
        }
        if (item.inventory >= 10000 && item.inventory < 100000) {
          qtyFontSize = 11;
        }
      }

      item.name = item.name.replaceAll("Blood Bag : ", "Blood: ");

      myList.add(
        Tooltip(
          message: '${item.name}\n\n${item.description}',
          textStyle: TextStyle(color: Colors.white),
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey[700]),
          child: ActionChip(
            elevation: 3,
            side: item.isLoadout || item.isPoints ? BorderSide(color: Colors.blue) : null,
            avatar: item.isLoadout
                ? null
                : widget.faction
                    ? item.isPoints
                        ? Icon(
                            MdiIcons.alphaPCircleOutline,
                            color: Colors.blueAccent,
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
                          itemQty,
                          style: TextStyle(
                            fontSize: qtyFontSize,
                            color: qtyColor,
                          ),
                        ),
                      ),
            label: item.isLoadout
                ? Text(
                    item.loadoutName,
                    style: TextStyle(fontSize: 11),
                  )
                : item.isPoints
                    ? Text(
                        "Refill",
                        style: TextStyle(fontSize: 11),
                      )
                    : item.name.split(' ').length > 1
                        ? _splitName(item.name)
                        : Text(
                            item.name,
                            softWrap: true,
                            overflow: TextOverflow.clip,
                            maxLines: 2,
                            style: TextStyle(fontSize: 11),
                          ),
            onPressed: () async {
              if (item.isLoadout) {
                var js = changeLoadOutJS(item: item.name.split(" ")[1], attackWebview: false);
                await widget.inAppWebViewController.evaluateJavascript(source: js);
              } else {
                var js = quickItemsJS(item: item.number.toString(), faction: widget.faction, refill: item.isPoints);
                await widget.inAppWebViewController.evaluateJavascript(source: js);
                if (!widget.faction) {
                  _itemsProvider.decreaseInventory(item);
                }
              }
            },
          ),
        ),
      );
    }

    if (myList.isEmpty) {
      myList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.faction
                    ? "Configure your faction's armoury quick items"
                    : "Configure your preferred quick items",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
              _settingsIcon(),
            ],
          ),
        ),
      );
    }

    return myList;
  }

  Widget _splitName(String name) {
    var splits = name.split(" ");
    var middle = (splits.length / 2).round();
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
        Text(upperString, style: TextStyle(fontSize: 11)),
        Text(lowerString, style: TextStyle(fontSize: 11)),
      ],
    );
  }

  _refreshInventory() {
    if (!widget.faction) {
      _itemsProvider.updateInventoryQuantities(fullUpdate: false);
    }
  }

  Widget _settingsIcon() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: OpenContainer(
        transitionDuration: Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
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
          return Padding(
            padding: const EdgeInsets.only(right: 5),
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
