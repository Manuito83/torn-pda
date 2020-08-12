import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';

class CityWidget extends StatefulWidget {
  final InAppWebViewController controller;

  CityWidget({
    @required this.controller,
  });

  @override
  _CityWidgetState createState() => _CityWidgetState();
}

class _CityWidgetState extends State<CityWidget> {
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
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(Size.fromHeight(
            (MediaQuery.of(context).size.height -
                kToolbarHeight -
                AppBar().preferredSize.height)) /
            3),
        child: Scrollbar(
          controller: _scrollController,
          isAlwaysShown: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: <Widget>[
                Text(
                  'City Finder',
                  style: TextStyle(
                    color: Colors.orange,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(child: Text('aaa')),
                      Flexible(child: Text('aaa')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
