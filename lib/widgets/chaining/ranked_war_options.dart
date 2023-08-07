// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class RankedWarOptions extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final SettingsProvider? settingsProvider;

  const RankedWarOptions(
    this.themeProvider,
    this.settingsProvider,
  );

  @override
  RankedWarOptionsState createState() => RankedWarOptionsState();
}

class RankedWarOptionsState extends State<RankedWarOptions> {
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
                padding: const EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: widget.themeProvider!.secondBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'OPTIONS',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              "Add ranked wars to main app menu",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Switch(
                            value: widget.settingsProvider!.rankedWarsInMenu,
                            onChanged: (enabled) {
                              setState(() {
                                widget.settingsProvider!.changeRankedWarsInMenu = enabled;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      TextButton(
                        child: const Text(
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
                backgroundColor: widget.themeProvider!.secondBackground,
                child: CircleAvatar(
                  backgroundColor: widget.themeProvider!.secondBackground,
                  radius: 22,
                  child: const SizedBox(
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
