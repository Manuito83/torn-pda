// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:expandable/expandable.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:torn_pda/models/items_model.dart';

class VaultWidget extends StatefulWidget {
  //final InAppWebViewController controller;
  //final List<Item> cityItems;
  //final bool error;

  VaultWidget();

  @override
  _VaultWidgetState createState() => _VaultWidgetState();
}

class _VaultWidgetState extends State<VaultWidget> {
  final _scrollController = ScrollController();
  final _moneyFormat = new NumberFormat("#,##0", "en_US");

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
          hasIcon: false,
          iconColor: Colors.grey,
          tapBodyToExpand: true,
          tapHeaderToExpand: true,
          tapBodyToCollapse: true,
        ),
        header: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              children: [
                Text(
                  'VAULT',
                  style: TextStyle(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        collapsed: ExpandableButton(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // TODO
              ],
            ),
          ),
        ),
        expanded: ConstrainedBox(
          constraints: BoxConstraints.loose(Size.fromHeight(
              (MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  AppBar().preferredSize.height)) /
              3),
          child: Scrollbar(
            controller: _scrollController,
            isAlwaysShown: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 0, 15),
                  child: Column(
                    children: [],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
