// Flutter imports:
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class TSCInfoDialog extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final ThemeProvider themeProvider;

  TSCInfoDialog({
    super.key,
    required this.settingsProvider,
    required this.themeProvider,
  });

  @override
  State<TSCInfoDialog> createState() => _TSCInfoDialogState();
}

class _TSCInfoDialogState extends State<TSCInfoDialog> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Torn Spies Central"),
      content: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EasyRichText(
                  "The Torn Spies Central implementation in Torn PDA is part of a bigger stats estimation algorithm "
                  "developed by Mavri, which you can review in its own forum thread.\n\n"
                  "IMPORTANT: please be aware that by making use of TSC in Torn PDA, your API Key WILL be shared "
                  "with TSC.\n\nAs with other service providers, you can configure an alternative API Key in Torn "
                  "PDA Settings. A Limited key is needed.",
                  patternList: [
                    EasyRichTextPattern(
                      targetString: 'Mavri',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue[400],
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          Navigator.of(context).pop();
                          const url = 'https://www.torn.com/profiles.php?XID=2402357';
                          await context.read<WebViewProvider>().openBrowserPreference(
                                context: context,
                                url: url,
                                browserTapType: BrowserTapType.short,
                              );
                        },
                    ),
                    EasyRichTextPattern(
                      targetString: 'forum thread',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue[400],
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          Navigator.of(context).pop();
                          const url = 'https://www.torn.com/forums.php#/p=threads&f=67&t=16290287&b=0&a=0';
                          await context.read<WebViewProvider>().openBrowserPreference(
                                context: context,
                                url: url,
                                browserTapType: BrowserTapType.short,
                              );
                        },
                    ),
                    const EasyRichTextPattern(
                      targetString: 'IMPORTANT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  defaultStyle: TextStyle(
                    fontSize: 14,
                    color: widget.themeProvider.mainText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.settingsProvider.tscEnabledStatus != 1)
          TextButton(
            child: const Text("Enable"),
            onPressed: () {
              widget.settingsProvider.tscEnabledStatus = 1;
              Navigator.of(context).pop();
            },
          ),
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
