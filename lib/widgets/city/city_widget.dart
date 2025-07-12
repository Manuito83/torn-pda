// Flutter imports:
// Package imports:
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
// Project imports:
import 'package:torn_pda/models/items_model.dart';

class CityWidget extends StatefulWidget {
  final InAppWebViewController? controller;
  final List<Item> cityItems;
  final bool error;

  const CityWidget({
    required this.controller,
    required this.cityItems,
    required this.error,
  });

  @override
  CityWidgetState createState() => CityWidgetState();
}

class CityWidgetState extends State<CityWidget> {
  final _scrollController = ScrollController();
  final _moneyFormat = NumberFormat("#,##0", "en_US");

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
        theme: const ExpandableThemeData(
          hasIcon: false,
          iconColor: Colors.grey,
          tapBodyToExpand: true,
          tapHeaderToExpand: true,
          tapBodyToCollapse: true,
        ),
        header: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'City Finder',
                  style: TextStyle(
                    color: Colors.orange,
                  ),
                ),
                Text(
                  '(TAP TO EXPAND)',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 8,
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
              children: _returnItems(true),
            ),
          ),
        ),
        expanded: ConstrainedBox(
          constraints: BoxConstraints.loose(
            Size.fromHeight(MediaQuery.sizeOf(context).height - kToolbarHeight - AppBar().preferredSize.height) / 3,
          ),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 0, 15),
                  child: Column(
                    children: _returnItems(false),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _returnItems(bool onlyTitle) {
    final itemList = <Widget>[];

    // Empty text
    if (widget.cityItems.isEmpty) {
      String noFoundText = "No items found";
      if (widget.error) {
        noFoundText += ", Torn API unavailable (try later)";
      }
      itemList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  noFoundText,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return itemList;
    }

    // Total items and price text
    if (widget.cityItems.length == 1) {
      itemList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Text(
                "Found 1 item",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final itemQuantity = widget.cityItems.length;
      var totalPrice = 0;
      for (final item in widget.cityItems) {
        totalPrice += item.marketValue!;
      }
      itemList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: <Widget>[
              Text(
                "Found $itemQuantity items, total value ",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[300],
                ),
              ),
              Text(
                "\$${_moneyFormat.format(totalPrice)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[300],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (onlyTitle) {
      return itemList;
    }

    // Item rows
    for (final item in widget.cityItems) {
      itemList.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 3, 0, 0),
          child: Row(
            children: <Widget>[
              Text(
                "${item.name}: ",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              Text(
                "\$${_moneyFormat.format(item.marketValue)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return itemList;
  }
}
