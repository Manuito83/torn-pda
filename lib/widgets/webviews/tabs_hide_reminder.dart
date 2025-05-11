import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class TabsHideReminderDialog extends StatefulWidget {
  const TabsHideReminderDialog({super.key});

  @override
  TabsHideReminderDialogState createState() => TabsHideReminderDialogState();
}

class TabsHideReminderDialogState extends State<TabsHideReminderDialog> {
  int _countdown = 8;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

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
                    const Text("You have hidden your tabs!\n"),
                    const Text(
                      "Just a quick reminder (in case you still have not reviewed the Tips section): swiping up/down "
                      "the title bar will hide/show your tab bar, so that you can enjoy more space when needed!\n\n"
                      "This feature can be completely disabled in Settings.",
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text(_countdown > 0 ? "Close ($_countdown)" : "Close"),
                          onPressed: _countdown > 0
                              ? null
                              : () {
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
