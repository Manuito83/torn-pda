import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_model.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';
import 'package:torn_pda/widgets/alerts/share_price_dialog.dart';

class SharePriceCard extends StatefulWidget {
  final StockMarketStock stock;

  const SharePriceCard({@required this.stock});

  @override
  _SharePriceCardState createState() => _SharePriceCardState();
}

class _SharePriceCardState extends State<SharePriceCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: widget.stock.alertGain != null || widget.stock.alertLoss != null
                ? Colors.blue
                : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ExpandablePanel(
            theme: ExpandableThemeData(
              hasIcon: false,
            ),
            collapsed: null,
            expanded: expanded(),
            header: header(),
          ),
        ),
      ),
    );
  }

  Widget header() {
    Widget gain = SizedBox.shrink();
    if (widget.stock.owned == 1) {
      var priceGain = widget.stock.gain.toInt();
      gain = Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          "[\$${formatProfit(priceGain.abs())}, ${widget.stock.percentageGain.toStringAsFixed(2)}%]",
          style: TextStyle(
            color: priceGain >= 0 ? Colors.green[700] : Colors.red[700],
            fontSize: 12,
          ),
        ),
      );
    }

    return Column(
      children: [
        // First Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text("(${widget.stock.acronym}) ", style: TextStyle(fontSize: 12)),
                Text(widget.stock.name, style: TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              children: [
                if (widget.stock.owned == 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      "OWNED",
                      style: TextStyle(color: Colors.green[700], fontSize: 10),
                    ),
                  ),
                Icon(Icons.arrow_drop_down_circle_outlined, size: 16),
              ],
            ),
          ],
        ),
        SizedBox(height: 2),
        // Second Row
        Row(
          children: [
            Text(
              "Price: \$${widget.stock.currentPrice}",
              style: TextStyle(fontSize: 12),
            ),
            gain,
          ],
        ),
      ],
    );
  }

  Widget expanded() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: Icon(MdiIcons.vectorPolylineEdit),
            onPressed: () {
              _showSharePriceDialog();
            },
          ),
          SizedBox(width: 20),
          Column(
            children: [
              Row(
                children: [
                  Text("Gain alert: ", style: TextStyle(fontSize: 12)),
                  if (widget.stock.alertGain == null)
                    Row(
                      children: [
                        Text("not set", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Text("TODO!", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                      ],
                    )
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text("Loss alert: ", style: TextStyle(fontSize: 12)),
                  if (widget.stock.alertGain == null)
                    Row(
                      children: [
                        Text("not set", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Text("TODO!", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
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

  void onCallbackPrices(int gain, int loss) {
    setState(() {
      widget.stock.alertGain = gain;
      widget.stock.alertLoss = loss;
    });
  }
}
