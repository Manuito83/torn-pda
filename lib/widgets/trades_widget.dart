import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';

class TradesWidget extends StatefulWidget {
  final int leftMoney;
  final List<TradeItem> leftItems;

  TradesWidget({
    @required this.leftMoney,
    @required this.leftItems,
  });

  @override
  _TradesWidgetState createState() => _TradesWidgetState();
}

class _TradesWidgetState extends State<TradesWidget> {
  var _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ExpandablePanel(
        theme: ExpandableThemeData(
          hasIcon: true,
          iconColor: Colors.grey,
          tapBodyToExpand: true,
          tapBodyToCollapse: true,
        ),
        header: Column(
          children: <Widget>[
            Text(
              'Trade Calculator',
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
            Row(
              children: <Widget>[
                _leftTotal(),
              ],
            ),
          ],
        ),
        expanded: ConstrainedBox(
          constraints: BoxConstraints.loose(Size.fromHeight(200)),
          child: Scrollbar(
            controller: _scrollController,
            isAlwaysShown: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: _leftItems(),
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        'RIGHT',
                        style: TextStyle(
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leftTotal() {
    return Text(
      widget.leftMoney.toString(),
      style: TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  List<Widget> _leftItems() {
    var items = List<Widget>();

    if (widget.leftItems.isEmpty) {
      items.add(SizedBox.shrink());
      return items;
    }

    for (var item in widget.leftItems) {
      items.add(Text(
        item.name,
        style: TextStyle(
          color: Colors.green,
        ),
      ));
    }

    return items;
  }
}
