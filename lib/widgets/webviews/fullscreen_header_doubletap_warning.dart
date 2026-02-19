import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class FullScreenHeaderDoubleTapWarningDialog extends StatefulWidget {
  const FullScreenHeaderDoubleTapWarningDialog({super.key});

  @override
  FullScreenHeaderDoubleTapWarningDialogState createState() => FullScreenHeaderDoubleTapWarningDialogState();
}

class FullScreenHeaderDoubleTapWarningDialogState extends State<FullScreenHeaderDoubleTapWarningDialog> {
  int _countdown = 8;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_countdown > 0 && mounted) {
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
                    const Text(
                      "Warning!\n",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "You are about to disable the double-tap on Torn's header bar as a method to exit full screen mode.\n\n"
                      "Please make sure you have at least one other way to exit full screen mode, such as:\n\n"
                      "• Long-pressing the ellipsis (...) button in the tab bar\n\n"
                      "• Using the Floating Action Button\n\n"
                      "• Swiping down from the top of the screen (device-dependent)\n\n"
                      "If you don't have any of these alternatives configured, you could get stuck in full screen mode "
                      "and may need to restart or reinstall the app!",
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          child: Text(
                            _countdown > 0 ? "Disable ($_countdown)" : "Disable",
                            style: TextStyle(
                              color: _countdown > 0 ? Colors.grey : Colors.orange[700],
                            ),
                          ),
                          onPressed: _countdown > 0
                              ? null
                              : () {
                                  Navigator.of(context).pop(true);
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
                    child: Icon(MdiIcons.alertOutline),
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
