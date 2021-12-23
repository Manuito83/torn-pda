// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/pages/quick_items/quick_items_options.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Project imports:
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';

class QuickItemsWidget extends StatefulWidget {
  final String webviewType;
  final InAppWebViewController inAppWebViewController;
  final WebViewController webViewController;

  QuickItemsWidget({
    @required this.webviewType,
    this.inAppWebViewController,
    this.webViewController,
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
          if (_itemsProvider.activeQuickItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _settingsIcon(),
            ),
        ],
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

              if (widget.webviewType == "attacks") {
                widget.webViewController.evaluateJavascript(js);
              } else {
                await widget.inAppWebViewController.evaluateJavascript(source: js);
              }

              _itemsProvider.decreaseInventory(item);
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
                "Configure your preferred quick items",
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
    _itemsProvider.updateInventoryQuantities(fullUpdate: false);
  }

  Widget _settingsIcon() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: OpenContainer(
        transitionDuration: Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return QuickItemsOptions();
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
