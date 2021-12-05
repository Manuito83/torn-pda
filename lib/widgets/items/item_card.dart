import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/src/provider.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/market/market_item_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/number_formatter.dart';

class ItemCard extends StatefulWidget {
  final Item item;
  final SettingsProvider settingsProvider;
  final ThemeProvider themeProvider;
  final String apiKey;

  ItemCard({
    @required this.item,
    @required this.settingsProvider,
    @required this.themeProvider,
    @required this.apiKey,
    Key key,
  }) : super(key: key);

  @override
  _ItemCardState createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  var _expandableController = ExpandableController();

  Future _footerInformationRetrieved;
  bool _footerSuccessful = false;

  MarketItemModel _marketItem;

  final decimalFormat = new NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();
    _expandableController.addListener(() {
      if (_expandableController.expanded == true) {
        _footerInformationRetrieved = _getFooterInformation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpandablePanel(
        controller: _expandableController,
        collapsed: null,
        theme: ExpandableThemeData(iconColor: widget.themeProvider.mainText),
        header: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(2),
                          child: Image.asset(
                            'images/torn_items/small/${widget.item.id}_small.png',
                            width: 35,
                            height: 35,
                            errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text("?"),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.name,
                                style: TextStyle(fontSize: 13),
                              ),
                              Text(
                                "Value: \$${decimalFormat.format(widget.item.marketValue)}",
                                style: TextStyle(fontSize: 10),
                              ),
                              Text(
                                "Circulation: ${formatBigNumbers(widget.item.circulation)}",
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        child: Column(
                          children: [
                            Image.asset(
                              'images/icons/map/item_market.png',
                              color: widget.themeProvider.mainText,
                              height: 14,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "(inv: x${widget.item.inventoryOwned})",
                              style: TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                        onTap: () async {
                          var url =
                              "https://www.torn.com/imarket.php#/p=shop&step=shop&type=&searchname=${widget.item.name}";
                          var dialog = widget.settingsProvider.useQuickBrowser || false;
                          context.read<WebViewProvider>().openBrowserPreference(
                                context: context,
                                url: url,
                                useDialog: dialog,
                                awaitable: true,
                              );
                        },
                        onLongPress: () async {
                          var url =
                              "https://www.torn.com/imarket.php#/p=shop&step=shop&type=&searchname=${widget.item.name}";
                          context.read<WebViewProvider>().openBrowserPreference(
                                context: context,
                                url: url,
                                useDialog: false,
                                awaitable: true,
                              );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(width: 10),
            ],
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: FutureBuilder(
            future: _footerInformationRetrieved,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return _footerWidget();
              } else {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _footerWidget() {
    Widget description = Padding(
      padding: EdgeInsetsDirectional.only(top: 15),
      child: Text(
        widget.item.description,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 10,
        ),
      ),
    );

    if (_footerSuccessful) {
      // Bazaar
      Widget bazaarHeader = Text(
        "Bazaar",
        style: TextStyle(
          fontSize: 12,
        ),
      );
      Widget bazaarColumn = Text(
        "Nothing found",
        style: TextStyle(
          fontSize: 10,
          color: Colors.orange[800],
        ),
      );
      if (_marketItem.bazaar != null) {
        List<Widget> bazaarList = <Widget>[];
        var bIndex = 0;
        for (var b in _marketItem.bazaar) {
          if (bIndex >= 3) break;
          bIndex++;
          bazaarList.add(
            Text(
              "${b.quantity}x \$${decimalFormat.format(b.cost)}",
              style: TextStyle(
                fontSize: 10,
              ),
            ),
          );
        }
        bazaarColumn = Column(children: bazaarList);
      }

      // Market
      Widget marketHeader = Text(
        "Market",
        style: TextStyle(
          fontSize: 12,
        ),
      );
      Widget marketColumn = Text(
        "Nothing found",
        style: TextStyle(
          fontSize: 10,
          color: Colors.orange[800],
        ),
      );
      if (_marketItem.itemmarket != null) {
        List<Widget> marketList = <Widget>[];
        var mIndex = 0;
        for (var b in _marketItem.itemmarket) {
          if (mIndex >= 3) break;
          mIndex++;
          marketList.add(
            Text(
              "${b.quantity}x \$${decimalFormat.format(b.cost)}",
              style: TextStyle(
                fontSize: 10,
              ),
            ),
          );
        }
        marketColumn = Column(children: marketList);
      }

      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  bazaarHeader,
                  SizedBox(height: 2),
                  bazaarColumn,
                ],
              ),
              Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: VerticalDivider(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  marketHeader,
                  SizedBox(height: 2),
                  marketColumn,
                ],
              ),
            ],
          ),
          description,
        ],
      );
    }

    return Center(
      child: Column(
        children: [
          Text(
            "ERROR: could not contact API to retrieve bazaar and market details!",
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange[800],
            ),
          ),
          description,
        ],
      ),
    );
  }

  Future _getFooterInformation() async {
    var apiResponse = await TornApiCaller.marketItem(widget.apiKey, widget.item.id).getMarketItem;
    if (apiResponse is MarketItemModel) {
      setState(() {
        _footerSuccessful = true;
        _marketItem = apiResponse;
      });
    }
    setState(() {});
    return;
  }
}
