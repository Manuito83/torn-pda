import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class TabsExcessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TabsExcessDialog({
    super.key,
    this.actionLabel,
    this.onAction,
    this.title = "Too many tabs?",
    this.message = "Remember you can close tabs by double or triple tapping them!\n\nSee Tips for more information!",
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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
                    Text("$title\n"),
                    Text(message, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (actionLabel != null && onAction != null)
                          TextButton(
                            child: Text(actionLabel!),
                            onPressed: () {
                              onAction!();
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
