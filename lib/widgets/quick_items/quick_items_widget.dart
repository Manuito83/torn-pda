import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/widgets/webviews/explanation_dialog.dart';

class QuickItemsWidget extends StatefulWidget {
  final InAppWebViewController controller;
  final bool appBarTop;
  final bool browserDialog;

  QuickItemsWidget({
    @required this.controller,
    @required this.appBarTop,
    @required this.browserDialog,
  });

  @override
  _QuickItemsWidgetState createState() => _QuickItemsWidgetState();
}

class _QuickItemsWidgetState extends State<QuickItemsWidget> {
  QuickItemsProvider _itemsProvider;

  Timer _inventoryRefreshTimer;

  @override
  void initState() {
    super.initState();
    _inventoryRefreshTimer = new Timer.periodic(
        Duration(seconds: 40), (Timer t) => _refreshInventory());
  }

  @override
  void dispose() {
    _inventoryRefreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _itemsProvider = context.watch<QuickItemsProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(Size.fromHeight(
                (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    AppBar().preferredSize.height)) /
            3),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.center,
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
    );
  }

  List<Widget> _itemButtons() {
    var myList = <Widget>[];

    for (var item in _itemsProvider.activeQuickItems) {
      Color itemColor;
      if (item.inventory == 0) {
        itemColor = Colors.orange[300];
      } else {
        itemColor = Colors.green[300];
      }

      double fontSize = 12;
      var itemQty = item.inventory.toString();
      if (item.inventory > 999 && item.inventory < 100000) {
        itemQty = "${(item.inventory / 1000).truncate().toStringAsFixed(0)}K";
      } else if (item.inventory >= 100000) {
        itemQty = "∞";
      }
      if (item.inventory >= 10000 && item.inventory < 100000) {
        fontSize = 11;
      }
      myList.add(
        Tooltip(
          message: '${item.name}\n\n${item.description}',
          textStyle: TextStyle(color: Colors.white),
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey[700]),
          child: ActionChip(
            elevation: 3,
            avatar: CircleAvatar(
              child: Text(
                itemQty,
                style: TextStyle(
                  fontSize: fontSize,
                  color: itemColor,
                ),
              ),
            ),
            label: item.name.split(' ').length > 1
                ? _splitName(item.name)
                : Text(
                    item.name,
                    softWrap: true,
                    overflow: TextOverflow.clip,
                    maxLines: 2,
                    style: TextStyle(fontSize: 11),
                  ),
            onPressed: () async {
              var js = quickItemsJS(item: item.number.toString());
              await widget.controller.evaluateJavascript(source: js);
              _itemsProvider.decreaseInventory(item);
            },
          ),
        ),
      );
    }

    if (myList.isEmpty) {
      String appBarPosition = "above";
      if (!widget.appBarTop) {
        appBarPosition = "below";
      }

      String explanation =
          "Use the box icon $appBarPosition to configure quick items";
      if (widget.browserDialog) {
        explanation =
            "Use the full browser to configure quick items";
      }

      myList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                explanation,
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
              if (widget.browserDialog)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return BrowserExplanationDialog();
                        },
                      );
                    },
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.orangeAccent,
                    ),
                  ),
                )
              else
                SizedBox.shrink(),
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
    _itemsProvider.updateInventoryQuantities(fullUpdate: false);
  }
}
