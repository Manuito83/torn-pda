import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LootRangersExplanationDialog extends StatelessWidget {
  const LootRangersExplanationDialog({
    @required ThemeProvider themeProvider,
    Key key,
  })  : _themeProvider = themeProvider,
        super(key: key);

  final ThemeProvider _themeProvider;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Loot Rangers"),
      content: SingleChildScrollView(
        child: EasyRichText(
          "The Loot Rangers Discord server is a community of Torn City players who come together to "
          "schedule attacks on the NPCs.\n\nThe group works to coordinate attack times that are most likely "
          "to be successful, taking into account the time zones of Torn players.\n\n"
          "For more details, join the Loot Rangers!",
          defaultStyle: TextStyle(fontSize: 13, color: _themeProvider.mainText),
          patternList: [
            EasyRichTextPattern(
              targetString: 'join the Loot Rangers',
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  Navigator.of(context).pop();
                  if (await canLaunchUrl(Uri.parse("https://discord.gg/guQ6kvK9rs"))) {
                    await launchUrl(Uri.parse("https://discord.gg/guQ6kvK9rs"), mode: LaunchMode.externalApplication);
                  }
                },
              style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
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
