import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class AnnouncementDialog extends StatelessWidget {
  const AnnouncementDialog({
    required ThemeProvider? themeProvider,
    super.key,
  })  : _themeProvider = themeProvider;

  final ThemeProvider? _themeProvider;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
            child: Image.asset(
              "images/icons/torn_pda.png",
              width: 30,
              height: 30,
              //color: _themeProvider.mainText,
            ),
          ),
          const Text("Enjoying Torn PDA?"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Three years of development, more than 100k lines of code, an active Discord community, a beta-testing "
              "team, official dev support... and more than 15k users that enjoy their Torn City game experience daily: "
              "this is what Torn PDA has become thanks to your support, suggestions and comments.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            const Text(
              "THANK YOU!",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            const Text(
              "If you are enjoying the app and wouldn't mind to spend a minute to improve the game we love even more, "
              "I would kindly ask you to spread the word and help us improve. Just that. This is not about donations.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            RichText(
              text: TextSpan(
                text: "Give Torn PDA a thumbs up in the ",
                style: TextStyle(fontSize: 14, color: _themeProvider!.mainText),
                children: <InlineSpan>[
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        const url = 'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0';
                        context.read<WebViewProvider>().openBrowserPreference(
                              context: context,
                              url: url,
                              browserTapType: BrowserTapType.short,
                            );
                      },
                      onLongPress: () {
                        const url = 'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0';
                        context.read<WebViewProvider>().openBrowserPreference(
                              context: context,
                              url: url,
                              browserTapType: BrowserTapType.long,
                            );
                      },
                      child: const Text(
                        'forums',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  ),
                  const TextSpan(
                      text: ", rate the app with your honest opinion, and keep your "
                          "suggestions coming. And do so with any other apps, services, extensions, helpers, spreadsheets,... "
                          "you use. Third-party developers work every day to make the game we all love a bit more enjoyable!",),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Awesome!"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }
}
