import 'package:bot_toast/bot_toast.dart';
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
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/number_formatter.dart';

class ItemCard extends StatefulWidget {
  final Item item;
  final SettingsProvider settingsProvider;
  final ThemeProvider themeProvider;
  final String apiKey;
  final bool inventorySuccess;
  final bool pinned;

  ItemCard({
    @required this.item,
    @required this.settingsProvider,
    @required this.themeProvider,
    @required this.apiKey,
    @required this.inventorySuccess,
    @required this.pinned,
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
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: widget.pinned ? Colors.green : Colors.blue,
                width: 2,
              ),
            ),
          ),
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
                            Column(
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
                                Text(
                                  "[ID ${widget.item.id}]",
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.brown[300],
                                  ),
                                ),
                              ],
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
                                  Row(
                                    children: [
                                      Text(
                                        "Circulation: ${formatBigNumbers(widget.item.circulation)}",
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      _rarityIcon(),
                                    ],
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
                                  color: widget.item.circulation == 0
                                      ? Colors.red[400]
                                      : widget.inventorySuccess
                                          ? widget.item.inventoryOwned > 0
                                              ? Colors.green
                                              : widget.themeProvider.mainText
                                          : widget.themeProvider.mainText,
                                  height: 14,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.inventorySuccess ? "(inv: x${widget.item.inventoryOwned})" : "(inv: error)",
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
        ),
      ),
    );
  }

  Widget _footerWidget() {
    Widget description = Padding(
      padding: EdgeInsetsDirectional.only(top: 15),
      child: Text(
        HtmlParser.fix(widget.item.description),
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 10,
        ),
      ),
    );

    Widget requirement = SizedBox.shrink();
    if (widget.item.requirement.isNotEmpty) {
      requirement = Padding(
        padding: EdgeInsetsDirectional.only(top: 15),
        child: Text(
          HtmlParser.fix("Requirement: ${widget.item.name}"),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 10,
          ),
        ),
      );
    }

    Widget effect = SizedBox.shrink();
    if (widget.item.effect.isNotEmpty) {
      effect = Padding(
        padding: EdgeInsetsDirectional.only(top: 15),
        child: Text(
          HtmlParser.fix("Effect: ${widget.item.effect}"),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 10,
          ),
        ),
      );
    }

    Widget weaponType = SizedBox.shrink();
    if (widget.item.weaponType != null) {
      effect = Padding(
        padding: EdgeInsetsDirectional.only(top: 15),
        child: Text(
          HtmlParser.fix("Weapon type: ${widget.item.weaponType}"),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 10,
          ),
        ),
      );
    }

    Widget coverage = SizedBox.shrink();
    if (widget.item.coverage != null) {
      effect = Padding(
        padding: EdgeInsetsDirectional.only(top: 15),
        child: Column(
          children: [
            Text("Full body coverage: ${widget.item.coverage.fullBodyCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Head coverage: ${widget.item.coverage.headCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Throat coverage: ${widget.item.coverage.throatCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Foot coverage: ${widget.item.coverage.footCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Leg coverage: ${widget.item.coverage.legCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Hand coverage: ${widget.item.coverage.handCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Arm coverage: ${widget.item.coverage.armCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Heart coverage: ${widget.item.coverage.heartCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Stomach coverage: ${widget.item.coverage.stomachCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Chest coverage: ${widget.item.coverage.chestCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
            Text("Groin coverage: ${widget.item.coverage.groinCoverage}",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
          ],
        ),
      );
    }

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
        for (var m in _marketItem.itemmarket) {
          if (mIndex >= 3) break;
          mIndex++;
          marketList.add(
            Text(
              "${m.quantity}x \$${decimalFormat.format(m.cost)}",
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  bazaarHeader,
                  SizedBox(height: 2),
                  bazaarColumn,
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 40,
                  child: VerticalDivider(
                    color: Colors.black,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  marketHeader,
                  SizedBox(height: 2),
                  marketColumn,
                ],
              ),
            ],
          ),
          description,
          effect,
          requirement,
          weaponType,
          coverage,
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

  Widget _rarityIcon() {
    String file;
    String message;
    if (widget.item.circulation < 100) {
      file = "extremely_rare";
      message = "Extremely rare";
    } else if (widget.item.circulation >= 100 && widget.item.circulation < 500) {
      file = "very_rare";
      message = "Very rar";
    } else if (widget.item.circulation >= 500 && widget.item.circulation < 1000) {
      file = "rare";
      message = "Rare";
    } else if (widget.item.circulation >= 1000 && widget.item.circulation < 2500) {
      file = "limited";
      message = "Limited";
    } else if (widget.item.circulation >= 2500 && widget.item.circulation < 5000) {
      file = "uncommon";
      message = "Uncommon";
    } else if (widget.item.circulation >= 5000 && widget.item.circulation < 500000) {
      file = "common";
      message = "Common";
    } else {
      file = "very_common";
      message = "Very common";
    }

    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: GestureDetector(
        onTap: () {
          BotToast.showText(
            text: message,
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey,
            duration: Duration(seconds: 1),
            contentPadding: EdgeInsets.all(10),
          );
        },
        child: Image.asset(
          "images/icons/rarity/${file}.png",
          width: 12,
        ),
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
