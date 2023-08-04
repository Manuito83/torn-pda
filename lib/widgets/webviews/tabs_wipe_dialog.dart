import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class TabsWipeDialog extends StatelessWidget {
  const TabsWipeDialog({super.key});

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
                    const Text("Remove all tabs!\n"),
                    const Text(
                      "This will remove all your tabs, are you sure?\n\n"
                      "Note: if you are looking to remove just some of them, remember you can do it with a double-tap!",
                      style: TextStyle(fontSize: 14),
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
                            webViewProvider.wipeTabs();
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
                  child: const SizedBox(
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
