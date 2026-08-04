// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:torn_pda/models/profile/revive_services/revive_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ReviveProviderInfoText extends StatelessWidget {
  final ReviveProvider provider;

  const ReviveProviderInfoText({required this.provider, super.key});

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13);

    final children = <InlineSpan>[];

    if (provider.forumUrl != null || provider.discordUrl != null) {
      children.add(const TextSpan(text: "\n\nCheck out their "));

      if (provider.forumUrl != null) {
        children.add(
          WidgetSpan(
            child: GestureDetector(
              onTap: () => _openForum(context, BrowserTapType.short),
              onLongPress: () => _openForum(context, BrowserTapType.long),
              child: const Text('forum thread', style: linkStyle),
            ),
          ),
        );
      }

      if (provider.forumUrl != null && provider.discordUrl != null) {
        children.add(const TextSpan(text: ' and '));
      }

      if (provider.discordUrl != null) {
        children.add(
          TextSpan(
            text: 'Discord server',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final url = Uri.parse(provider.discordUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
          ),
        );
      }

      children.add(const TextSpan(text: ' for more information.'));
    }

    children.add(TextSpan(text: "\n\n${provider.priceNote(provider.price(context.read<SettingsProvider>()))}"));

    return RichText(
      text: TextSpan(
        text: provider.description,
        style: TextStyle(color: context.read<ThemeProvider>().mainText, fontSize: 13),
        children: children,
      ),
    );
  }

  void _openForum(BuildContext context, BrowserTapType tapType) {
    final webViewProvider = context.read<WebViewProvider>();
    Navigator.of(context).pop();
    webViewProvider.openBrowserPreference(context: context, url: provider.forumUrl!, browserTapType: tapType);
  }
}
