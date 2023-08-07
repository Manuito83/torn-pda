import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_model.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';
import 'package:torn_pda/widgets/alerts/share_price_dialog.dart';

class SharePriceCard extends StatefulWidget {
  final StockMarketStock stock;

  const SharePriceCard({required this.stock});

  @override
  SharePriceCardState createState() => SharePriceCardState();
}

class SharePriceCardState extends State<SharePriceCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: widget.stock.alertGain != null || widget.stock.alertLoss != null ? Colors.blue : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ExpandablePanel(
            theme: const ExpandableThemeData(
              hasIcon: false,
            ),
            collapsed: Container(),
            expanded: expanded(),
            header: header(),
          ),
        ),
      ),
    );
  }

  Widget header() {
    Widget gain = const SizedBox.shrink();
    if (widget.stock.owned == 1) {
      final priceGain = widget.stock.gain!.toInt();
      gain = Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          "[\$${formatProfit(inputInt: priceGain.abs())}, ${widget.stock.percentageGain!.toStringAsFixed(2)}%]",
          style: TextStyle(
            color: priceGain >= 0 ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // First Row
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("(${widget.stock.acronym}) ", style: const TextStyle(fontSize: 12)),
                Text(widget.stock.name!, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 2),
            // Second Row
            Row(
              children: [
                Text(
                  "Price: \$${widget.stock.currentPrice}",
                  style: const TextStyle(fontSize: 12),
                ),
                gain,
              ],
            ),
          ],
        ),
        Column(
          children: [
            Row(
              children: [
                if (widget.stock.owned == 1)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          "OWNED (x${formatProfit(inputInt: widget.stock.sharesOwned)})",
                          style: const TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          "\$${formatProfit(inputDouble: widget.stock.sharesOwned! * widget.stock.currentPrice!)}",
                          style: const TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                const Icon(Icons.arrow_drop_down_circle_outlined, size: 16),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget expanded() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(MdiIcons.vectorPolylineEdit),
            onPressed: () {
              _showSharePriceDialog();
            },
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("Gain alert: ", style: TextStyle(fontSize: 12)),
                  if (widget.stock.alertGain == null)
                    const Row(
                      children: [
                        Text("not set", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Text("\$${removeZeroDecimals(widget.stock.alertGain)}", style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),
                      ],
                    )
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("Loss alert: ", style: TextStyle(fontSize: 12)),
                  if (widget.stock.alertLoss == null)
                    const Row(
                      children: [
                        Text("not set", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Text("\$${removeZeroDecimals(widget.stock.alertLoss)}", style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),
                      ],
                    )
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showSharePriceDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SharePriceDialog(
            stock: widget.stock,
            callbackPrices: onCallbackPrices,
          ),
        );
      },
    );
  }

  void onCallbackPrices(double gain, double loss) {
    setState(() {
      widget.stock.alertGain = gain;
      widget.stock.alertLoss = loss;
    });
  }

  String removeZeroDecimals(double? input) {
    return input.toString().replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "");
  }
}
