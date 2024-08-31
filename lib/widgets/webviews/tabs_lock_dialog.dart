import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class TabsLockDialog extends StatelessWidget {
  const TabsLockDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      contentPadding: const EdgeInsets.only(
        top: 2.0,
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
                    const Text("You locked your first tab!\n"),
                    const Text(
                      "But how does it work...?\n\n"
                      //
                      "You can lock your tabs (except for the first one) by using the lock icon in the tab menu.\n\n"
                      "There two ways in which you can lock your tabs.\n\n"
                      //
                      "POSITIONAL LOCK:\n\n"
                      "Activated by a single tap in the lock icon: this will lock your tab so that it can't be moved "
                      "(you can still exchange it's position with other locked tabs) or closed. The tab will move "
                      "to the first position available in your tab list, and a small orange lock icon will appear.\n\n"
                      //
                      "FULL LOCK:\n\n"
                      "Activated by a long-press in the lock icon: on top of the behavior you get with the "
                      "positional lock, your tab will be locked in the current website/section you are visiting "
                      "and you will not be able to browse to other web sections. You will be able to reload the page and "
                      "still be able to browse through the pages of multi-page sections "
                      "(e.g.: forums, hospital, jail, items...) and such.\n\n"
                      "When the full lock is active, a red lock will appear in your tab.\n\n"
                      "Note: there are a couple of ways to override this behavior without unlocking the tab. You can either "
                      "tap the 'override!' button in the warning dialog that shows if you try to browse with a full lock, or "
                      "you can configure exceptions in Settings / Advanced Browser Settings, to allow navigation between "
                      "specific pairs or URLs.",
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
                    child: Icon(MdiIcons.lock),
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
