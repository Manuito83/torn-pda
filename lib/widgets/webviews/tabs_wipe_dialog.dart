import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

enum TabsWipeTimeRange {
  any,
  oneDay,
  twoDays,
  threeDays,
  fiveDays,
  sevenDays,
  fifteenDays,
  oneMonth,
}

extension TabsWipeTimeRangeExtension on TabsWipeTimeRange {
  String get displayName {
    switch (this) {
      case TabsWipeTimeRange.any:
        return 'Any';
      case TabsWipeTimeRange.oneDay:
        return '1 day';
      case TabsWipeTimeRange.twoDays:
        return '2 days';
      case TabsWipeTimeRange.threeDays:
        return '3 days';
      case TabsWipeTimeRange.fiveDays:
        return '5 days';
      case TabsWipeTimeRange.sevenDays:
        return '7 days';
      case TabsWipeTimeRange.fifteenDays:
        return '15 days';
      case TabsWipeTimeRange.oneMonth:
        return '1 month';
      default:
        return '';
    }
  }

  Duration get duration {
    switch (this) {
      case TabsWipeTimeRange.any:
        return Duration.zero;
      case TabsWipeTimeRange.oneDay:
        return Duration(days: 1);
      case TabsWipeTimeRange.twoDays:
        return Duration(days: 2);
      case TabsWipeTimeRange.threeDays:
        return Duration(days: 3);
      case TabsWipeTimeRange.fiveDays:
        return Duration(days: 5);
      case TabsWipeTimeRange.sevenDays:
        return Duration(days: 7);
      case TabsWipeTimeRange.fifteenDays:
        return Duration(days: 15);
      case TabsWipeTimeRange.oneMonth:
        return Duration(days: 30);
      default:
        return Duration.zero;
    }
  }
}

class TabsWipeDialog extends StatefulWidget {
  const TabsWipeDialog({super.key});

  @override
  TabsWipeDialogState createState() => TabsWipeDialogState();
}

class TabsWipeDialogState extends State<TabsWipeDialog> {
  bool wipeLockedTabs = false;
  TabsWipeTimeRange selectedTimeRange = TabsWipeTimeRange.any;
  final List<TabsWipeTimeRange> timeRanges = [
    TabsWipeTimeRange.any,
    TabsWipeTimeRange.oneDay,
    TabsWipeTimeRange.twoDays,
    TabsWipeTimeRange.threeDays,
    TabsWipeTimeRange.fiveDays,
    TabsWipeTimeRange.sevenDays,
    TabsWipeTimeRange.fifteenDays,
    TabsWipeTimeRange.oneMonth,
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
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
                margin: const EdgeInsets.only(top: 30),
                decoration: BoxDecoration(
                  color: themeProvider.secondBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text("Wipe Tabs\n"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Include locked tabs"),
                        const SizedBox(width: 15),
                        Switch(
                          value: wipeLockedTabs,
                          onChanged: (value) {
                            setState(() {
                              wipeLockedTabs = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: Text("Inactive for")),
                        DropdownButton<TabsWipeTimeRange>(
                          value: selectedTimeRange,
                          items: timeRanges.map((TabsWipeTimeRange range) {
                            return DropdownMenuItem<TabsWipeTimeRange>(
                              value: range,
                              child: Text(range.displayName),
                            );
                          }).toList(),
                          onChanged: (TabsWipeTimeRange? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedTimeRange = newValue;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text(
                            "Wipe!",
                            style: TextStyle(
                              color: Colors.red[800],
                            ),
                          ),
                          onPressed: () {
                            webViewProvider.wipeTabs(
                              includeLockedTabs: wipeLockedTabs,
                              timeRange: selectedTimeRange,
                            );

                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: themeProvider.secondBackground,
                child: CircleAvatar(
                  backgroundColor: themeProvider.mainText,
                  radius: 22,
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: Icon(MdiIcons.tabRemove),
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
