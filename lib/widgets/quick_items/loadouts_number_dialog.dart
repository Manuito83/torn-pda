import 'package:flutter/material.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class LoadoutsNumberDialog extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final QuickItemsProvider? itemsProvider;

  LoadoutsNumberDialog({required this.themeProvider, required this.itemsProvider, Key? key}) : super(key: key);

  @override
  _LoadoutsNumberDialogState createState() => _LoadoutsNumberDialogState();
}

class _LoadoutsNumberDialogState extends State<LoadoutsNumberDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: EdgeInsets.only(top: 15),
                decoration: new BoxDecoration(
                  color: widget.themeProvider!.secondBackground,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: const Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To make the card compact
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        "Number of loadouts to show:",
                        style: TextStyle(fontSize: 12, color: widget.themeProvider!.mainText),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(widget.itemsProvider!.numberOfLoadoutsToShow.toString()),
                    Slider(
                      value: widget.itemsProvider!.numberOfLoadoutsToShow.toDouble(),
                      min: 2,
                      max: 9,
                      divisions: 7,
                      onChanged: (value) {
                        setState(() {
                          widget.itemsProvider!.setNumberOfLoadoutsToShow(value.toInt());
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "NOTE: you can upgrade your loadout capacity in the Points Building.\n\nActivating a loadout that "
                        "is over your current capacity will result in your last loadout being activated instead.",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: widget.themeProvider!.secondBackground,
                child: CircleAvatar(
                  backgroundColor: widget.themeProvider!.secondBackground,
                  radius: 22,
                  child: SizedBox(
                    height: 34,
                    width: 34,
                    child: Image.asset(
                      'images/icons/loadout.png',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
