import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ItemCard extends StatefulWidget {
  final Item item;
  final SettingsProvider? settingsProvider;
  final ThemeProvider? themeProvider;
  final bool inventorySuccess;
  final bool pinned;

  const ItemCard({
    required this.item,
    required this.settingsProvider,
    required this.themeProvider,
    required this.inventorySuccess,
    required this.pinned,
    super.key,
  });

  @override
  ItemCardState createState() => ItemCardState();
}

class ItemCardState extends State<ItemCard> {
  final _expandableController = ExpandableController();

  Future? _footerInformationRetrieved;
  bool _footerSuccessful = false;

  late ItemMarket _marketItem;

  final decimalFormat = NumberFormat("#,##0", "en_US");

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
            collapsed: Container(),
            theme: ExpandableThemeData(iconColor: widget.themeProvider!.mainText),
            header: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
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
                                  padding: const EdgeInsets.all(2),
                                  child: Image.asset(
                                    'images/torn_items/small/${widget.item.id}_small.png',
                                    width: 35,
                                    height: 35,
                                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                      return const Padding(
                                        padding: EdgeInsets.only(left: 10),
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.name!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Value: \$${decimalFormat.format(widget.item.marketValue)}",
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      SizedBox(width: 5),
                                      if (widget.item.sellPrice != null && widget.item.sellPrice! > 0)
                                        Text(
                                          "(Sell @ \$${decimalFormat.format(widget.item.sellPrice)})",
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Circulation: ${formatBigNumbers(widget.item.circulation!)}",
                                        style: const TextStyle(fontSize: 10),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            child: GestureDetector(
                              child: Column(
                                children: [
                                  Image.asset(
                                    'images/icons/map/item_market.png',
                                    color: widget.item.circulation == 0
                                        ? Colors.red[400]
                                        : widget.inventorySuccess
                                            ? widget.item.inventoryOwned > 0
                                                ? Colors.green
                                                : widget.themeProvider!.mainText
                                            : widget.themeProvider!.mainText,
                                    height: 14,
                                  ),
                                  const SizedBox(height: 4),
                                  if (widget.inventorySuccess)
                                    Text(
                                      "inv: x${widget.item.inventoryOwned}",
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  if (widget.item.totalValue > 0)
                                    Text(
                                      "\$${formatBigNumbers(widget.item.totalValue)}",
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                ],
                              ),
                              onTap: () async {
                                final url =
                                    "https://www.torn.com/imarket.php#/p=shop&step=shop&type=&searchname=${widget.item.name}";

                                context.read<WebViewProvider>().openBrowserPreference(
                                      context: context,
                                      url: url,
                                      browserTapType: BrowserTapType.short,
                                    );
                              },
                              onLongPress: () async {
                                final url =
                                    "https://www.torn.com/imarket.php#/p=shop&step=shop&type=&searchname=${widget.item.name}";
                                context.read<WebViewProvider>().openBrowserPreference(
                                      context: context,
                                      url: url,
                                      browserTapType: BrowserTapType.long,
                                    );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
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
                    return const Center(
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
    final Widget description = Padding(
      padding: const EdgeInsetsDirectional.only(top: 15),
      child: Text(
        HtmlParser.fix(widget.item.description),
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 10,
        ),
      ),
    );

    Widget requirement = const SizedBox.shrink();
    if (widget.item.requirement!.isNotEmpty) {
      requirement = Padding(
        padding: const EdgeInsetsDirectional.only(top: 15),
        child: Text(
          HtmlParser.fix("Requirement: ${widget.item.name}"),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 10,
          ),
        ),
      );
    }

    Widget effect = const SizedBox.shrink();
    if (widget.item.effect!.isNotEmpty) {
      effect = Padding(
        padding: const EdgeInsetsDirectional.only(top: 15),
        child: Text(
          HtmlParser.fix("Effect: ${widget.item.effect}"),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 10,
          ),
        ),
      );
    }

    const Widget weaponType = SizedBox.shrink();
    if (widget.item.weaponType != null) {
      effect = Padding(
        padding: const EdgeInsetsDirectional.only(top: 15),
        child: Text(
          HtmlParser.fix("Weapon type: ${widget.item.weaponType}"),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 10,
          ),
        ),
      );
    }

    const Widget coverage = SizedBox.shrink();
    if (widget.item.coverage != null) {
      effect = Padding(
        padding: const EdgeInsetsDirectional.only(top: 15),
        child: Column(
          children: [
            Text(
              "Full body coverage: ${widget.item.coverage!.fullBodyCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Head coverage: ${widget.item.coverage!.headCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Throat coverage: ${widget.item.coverage!.throatCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Foot coverage: ${widget.item.coverage!.footCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Leg coverage: ${widget.item.coverage!.legCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Hand coverage: ${widget.item.coverage!.handCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Arm coverage: ${widget.item.coverage!.armCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Heart coverage: ${widget.item.coverage!.heartCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Stomach coverage: ${widget.item.coverage!.stomachCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Chest coverage: ${widget.item.coverage!.chestCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
            Text(
              "Groin coverage: ${widget.item.coverage!.groinCoverage}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
            ),
          ],
        ),
      );
    }

    if (_footerSuccessful) {
      // Market
      const Widget marketHeader = Text(
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

      List<Widget> marketList = <Widget>[];
      var mIndex = 0;
      for (final m in _marketItem.listings!) {
        if (mIndex >= 3) break;
        mIndex++;

        final Map<String, dynamic> item = m as Map<String, dynamic>;
        final int amount = item['amount'] as int;
        final int price = item['price'] as int;

        marketList.add(
          Text(
            "${amount}x @ \$${decimalFormat.format(price)}",
            style: const TextStyle(
              fontSize: 10,
            ),
          ),
        );
      }
      marketColumn = Column(children: marketList);

      return Column(
        children: [
          if (marketList.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    marketHeader,
                    const SizedBox(height: 2),
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
    if (widget.item.circulation == 0) {
      return const SizedBox.shrink();
    } else if (widget.item.circulation == 1) {
      file = "one_of_a_kind";
      message = "One of a kind";
    } else if (widget.item.circulation! > 1 && widget.item.circulation! < 100) {
      file = "extremely_rare";
      message = "Extremely rare";
    } else if (widget.item.circulation! >= 100 && widget.item.circulation! < 500) {
      file = "very_rare";
      message = "Very rare";
    } else if (widget.item.circulation! >= 500 && widget.item.circulation! < 1000) {
      file = "rare";
      message = "Rare";
    } else if (widget.item.circulation! >= 1000 && widget.item.circulation! < 2500) {
      file = "limited";
      message = "Limited";
    } else if (widget.item.circulation! >= 2500 && widget.item.circulation! < 5000) {
      file = "uncommon";
      message = "Uncommon";
    } else if (widget.item.circulation! >= 5000 && widget.item.circulation! < 500000) {
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
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey,
            duration: const Duration(seconds: 1),
            contentPadding: const EdgeInsets.all(10),
          );
        },
        child: Image.asset(
          "images/icons/rarity/$file.png",
          width: 12,
        ),
      ),
    );
  }

  Future _getFooterInformation() async {
    try {
      final apiResponse = await ApiCallsV2.getMarketItemApi_v2(
        payload: {
          "id": int.tryParse(widget.item.id!) ?? 0,
        },
      );

      if (apiResponse is MarketItemMarketResponse) {
        setState(() {
          _footerSuccessful = true;
          _marketItem = apiResponse.itemmarket!;
        });
      }
    } catch (e) {
      log("Error calling getMarketItemApi_v2: $e");
    }
    setState(() {});
    return;
  }
}
