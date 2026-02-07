import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class FFScouterInfoDialog extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final ThemeProvider themeProvider;

  const FFScouterInfoDialog({
    super.key,
    required this.settingsProvider,
    required this.themeProvider,
  });

  @override
  State<FFScouterInfoDialog> createState() => _FFScouterInfoDialogState();
}

class _FFScouterInfoDialogState extends State<FFScouterInfoDialog> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.themeProvider.mainText;
    final mutedColor = Colors.grey[500];
    final linkColor = Colors.blue[400];

    return AlertDialog(
      title: const Text("FFScouter"),
      content: SizedBox(
        width: double.maxFinite,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ABOUT ---
                  _sectionHeader("ABOUT"),
                  const SizedBox(height: 6),
                  Text(
                    "FFScouter is a free tool designed to help estimate the difficulty and battle stats "
                    "of your opponents. Using this tool will not expose any information about yourself to "
                    "other players, nor will you be able to view information about others except battle stat "
                    "estimates. Your actual battle stats, and those of others, will remain private.",
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Any stat estimates made via the free API are available for any person or group to access "
                    "and use, free of charge, for any purpose.",
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "FFScouter is not affiliated with Torn, it is an independent community tool.",
                    style: TextStyle(fontSize: 13, color: mutedColor, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),

                  // --- SETUP IN TORN PDA ---
                  _sectionHeader("SETUP IN TORN PDA"),
                  const SizedBox(height: 6),
                  Text(
                    "IMPORTANT: by enabling FFScouter in Torn PDA, your API Key WILL be shared with "
                    "FFScouter. You need to register your key at the FFScouter website before using this service.",
                    style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You can configure an alternative API Key in Torn PDA Settings (Alternative API Keys section). "
                    "A Custom key is recommended (you can create one at the FFScouter website).",
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 16),

                  // --- TERMS AND CONDITIONS ---
                  _sectionHeader("TERMS AND CONDITIONS"),
                  const SizedBox(height: 6),
                  Text(
                    "By using FFScouter you agree to the following:",
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  _bulletPoint(
                    "FFScouter will make API requests to Torn using your API key to obtain information "
                    "about you and your attacks. These requests may be made up to 13 times per day.",
                    textColor,
                  ),
                  _bulletPoint(
                    "Your data will be used to make predictions about the battle stats of people who "
                    "you attack, or who have attacked you. These estimates will then become public.",
                    textColor,
                  ),
                  _bulletPoint(
                    "The battle stat predictions of other people will be provided to other users of "
                    "FFScouter (the general public). These estimates, once made, belong to FFScouter.",
                    textColor,
                  ),
                  _bulletPoint(
                    "By using FFScouter, you are contributing to a shared pool of stat estimates. "
                    "Using it will not update your own public stat estimates and your own raw battle "
                    "stats will never be provided to anyone else.",
                    textColor,
                  ),
                  _bulletPoint(
                    "Data may also be used to train a machine learning model to improve accuracy. "
                    "This model may only be accessible to fee paying users of FFScouter.",
                    textColor,
                  ),
                  _bulletPoint(
                    "You can remove your API key at any time by deleting or pausing it in the Torn "
                    "API Settings page. Your private information will be deleted at the next update attempt.",
                    textColor,
                  ),
                  const SizedBox(height: 16),

                  // --- DATA POLICY ---
                  _sectionHeader("DATA POLICY"),
                  const SizedBox(height: 6),
                  _dataRow("Player ID", "Stored forever, visible to general public", textColor),
                  _dataRow("Battle Stats", "Stored until account deletion, owners only", textColor),
                  _dataRow("BSS Private", "Stored until account deletion, owners only", textColor),
                  _dataRow("BSS Public", "Stored forever, visible to general public", textColor),
                  _dataRow("Attacks", "Temporary (<10 sec), never stored to database", textColor),
                  _dataRow("API Key", "Stored until deletion, owners only (debugging)", textColor),
                  _dataRow("Personal Stats", "Stored until deletion, AI training only", textColor),
                  const SizedBox(height: 8),
                  Text(
                    "Your attack history is never saved to the database, shared, or sold. "
                    "Your own bss_public is not updated by registering; it is generated by other users' estimates.",
                    style: TextStyle(fontSize: 12, color: mutedColor, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),

                  // --- API KEY ---
                  _sectionHeader("API KEY REQUIREMENTS"),
                  const SizedBox(height: 6),
                  Text(
                    "Recommended: Custom key with selections: basic, battlestats, attacks, hof, personalstats.",
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Limited and Full keys also work, but Custom is recommended.",
                    style: TextStyle(fontSize: 12, color: mutedColor, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),

                  // --- TORN PDA INTEGRATION ---
                  _sectionHeader("TORN PDA INTEGRATION"),
                  const SizedBox(height: 6),
                  Text(
                    "Prefer FFScouter battle score",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "When enabled, war/retal cards and profile checks will show the FFScouter battle score "
                    "estimate (e.g. ~12.5M) in orange instead of the vague estimated range (e.g. 2M-25M) for "
                    "unspied targets. The same value is used for sorting, filters (Total Stats slider), and SmartScore. "
                    "Disabling this setting clears the local cache.",
                    style: TextStyle(fontSize: 12, color: textColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Override old spies",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "When the 'Prefer FFScouter' option is active, a slider lets you choose a spy age threshold "
                    "(1–12 months). If a target's spied stats are older than that threshold and FFScouter has a "
                    "battle score estimate, the FFS value will replace the spied stats on the card. "
                    "A small clock icon indicates the override. Sorting, filters, and SmartScore also use the "
                    "FFS value in that case. Set to 'Off' to always keep spied stats regardless of age.",
                    style: TextStyle(fontSize: 12, color: textColor),
                  ),
                  const SizedBox(height: 16),

                  // --- DEVELOPER ---
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    "FFScouter is developed by Glasnost [1844049].",
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: "Visit ffscouter.com for full details",
                        style: TextStyle(
                          fontSize: 14,
                          color: linkColor,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            Navigator.of(context).pop();
                            const url = 'https://ffscouter.com';
                            await context.read<WebViewProvider>().openBrowserPreference(
                                  context: context,
                                  url: url,
                                  browserTapType: BrowserTapType.short,
                                );
                          },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (widget.settingsProvider.ffScouterEnabledStatus != 1)
          TextButton(
            child: const Text("Accept & Enable"),
            onPressed: () {
              widget.settingsProvider.ffScouterEnabledStatus = 1;
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
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _bulletPoint(String text, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String category, String details, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              category,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Expanded(
            child: Text(
              details,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}
