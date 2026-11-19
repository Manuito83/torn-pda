import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/remote_announcement.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class RemoteAnnouncementDialog extends StatelessWidget {
  const RemoteAnnouncementDialog({required this.announcement, super.key});

  final RemoteAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final url = announcement.url;
    return AlertDialog(
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
            child: Image.asset("images/icons/torn_pda.png", width: 30, height: 30),
          ),
          Flexible(child: Text(announcement.title)),
        ],
      ),
      content: SingleChildScrollView(child: Text(announcement.body, style: const TextStyle(fontSize: 14))),
      actions: [
        if (url != null)
          TextButton(
            child: Text(announcement.button ?? "Open"),
            onPressed: () {
              context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: url,
                browserTapType: BrowserTapType.short,
              );
              Navigator.of(context).pop();
            },
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(child: const Text("Ok"), onPressed: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }
}
