// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class SharePriceOptions extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SettingsProvider settingsProvider;
  final Function stockMarketInMenuCallback;

  SharePriceOptions(this.themeProvider, this.settingsProvider, this.stockMarketInMenuCallback);

  @override
  _SharePriceOptionsState createState() => _SharePriceOptionsState();
}

class _SharePriceOptionsState extends State<SharePriceOptions> {
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
                  color: widget.themeProvider.background,
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'OPTIONS',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "Add stock market to main app menu",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Switch(
                            value: widget.settingsProvider.stockExchangeInMenu,
                            onChanged: (enabled) {
                              setState(() {
                                widget.stockMarketInMenuCallback(enabled);
                              });
                            },
                          ),
                        ],
                      ),
                      Divider(),
                      TextButton(
                        child: Text(
                          "Close",
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: widget.themeProvider.background,
                child: CircleAvatar(
                  backgroundColor: widget.themeProvider.background,
                  radius: 22,
                  child: SizedBox(
                    height: 34,
                    width: 34,
                    child: Icon(Icons.settings),
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
