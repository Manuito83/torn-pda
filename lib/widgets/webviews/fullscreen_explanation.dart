import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class FullScreenExplanationDialog extends StatelessWidget {
  const FullScreenExplanationDialog({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      contentPadding: EdgeInsets.only(
        left: 0.0,
        top: 2.0,
        right: 0.0,
        bottom: 2.0,
      ),
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
                    const Text("Full screen...!?\n"),
                    const Text(
                      "You've entered the full screen mode (which is best viewed if using the full browser).\n\n"
                      "Bear in mind that by default, all Torn PDA widgets and Torn chats will be deactivated, so that "
                      "you can concentrate on what's important. If you'd like to change this behavior, you can "
                      "do so in the app's Settings menu!\n\n"
                      "You can also change the safe area's boundaries (top, bottom and sides) you prefer, in case "
                      "you would like to avoid the front-facing camera or notch getting in the way, or if your phone's "
                      "rounded corners make tabs difficult to select.\n\n"
                      "It is also possible to launch the quick or full browser always in full screen mode by default, "
                      "so you can use them for different purposes.\n\n"
                      "You can exit the fullscreen mode by taping again the same icon you just tapped, "
                      "or by double tapping the three-dotted-icon (which is now in orange color), which might be "
                      "faster to do.\n\n"
                      "How do I reload, go forward or back, You may be asking yourself. For reloading, consider "
                      "activating the 'pull-to-refresh' option for the browser. To browse forward or back, try "
                      "a quick left or right swipe gesture over the tab bar!\n\n"
                      "If you need to exit the browser quickly, you can do so also from the quick menu whenever "
                      "you are in full screen mode.",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                    child: Icon(MdiIcons.fullscreen),
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
