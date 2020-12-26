import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';

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
                '${item.inventory}',
                style: TextStyle(
                  fontSize: 12,
                  color: itemColor,
                ),
              ),
            ),
            label: SizedBox(
              child: item.name.split(' ').length > 1
                  ? _splitName(item.name)
                  : Text(
                      item.name,
                      softWrap: true,
                      overflow: TextOverflow.clip,
                      maxLines: 2,
                      style: TextStyle(fontSize: 11),
                    ),
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
      String appBarPosition = "top";
      if (!widget.appBarTop) {
        appBarPosition = "bottom";
      }

      String explanation = "Use the options at the $appBarPosition to configure quick items";
      if (widget.browserDialog) {
        explanation = "Open a full browser (long press) to configure your quick items for the first time";
      }

      myList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Text(
            explanation,
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 12,
            ),
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
}
