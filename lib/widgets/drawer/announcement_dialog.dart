import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementDialog extends StatelessWidget {
  const AnnouncementDialog({
    @required ThemeProvider themeProvider,
    Key key,
  })  : _themeProvider = themeProvider,
        super(key: key);

  final ThemeProvider _themeProvider;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(2, 2, 8, 2),
            child: Image.asset(
              "images/icons/torn_pda.png",
              width: 30,
              height: 30,
              //color: _themeProvider.mainText,
            ),
          ),
          Text("Enjoying Torn PDA?"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "Three years of development, more than 100k lines of code, an active Discord community, a beta-testing "
              "team, official dev support... and more than 15k users that enjoy their Torn City game experience daily: "
              "this is what Torn PDA has become thanks to your support, suggestions and comments.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            Text(
              "THANK YOU!",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            Text(
              "If you are enjoying the app and wouldn't mind to spend a minute to improve the game we love even more, "
              "I would kindly ask you to spread the word and help us improve. Just that. This is not about donations.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            EasyRichText(
              "Give Torn PDA a thumbs up in the forums, rate the app with your honest opinion, and keep your "
              "suggestions coming. And do so with any other apps, services, extensions, helpers, spreadsheets,... "
              "you use. Third-party developers work every day to make the game we all love a bit more enjoyable!",
              defaultStyle: TextStyle(fontSize: 14, color: _themeProvider.mainText),
              patternList: [
                EasyRichTextPattern(
                  targetString: 'forums',
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      var url = 'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0';
                      await context.read<WebViewProvider>().openBrowserPreference(
                            context: context,
                            url: url,
                            useDialog: context.read<SettingsProvider>().useQuickBrowser,
                          );
                    },
                  style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: Text("Awesome!"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }
}
