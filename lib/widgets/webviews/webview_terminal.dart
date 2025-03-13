import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:share_plus/share_plus.dart'; // Import for sharing content
import 'package:flutter/services.dart'; // Import for clipboard functionality

class WebviewTerminal extends StatelessWidget {
  const WebviewTerminal({
    super.key,
    required this.terminalProvider,
  });

  final TerminalProvider terminalProvider;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (_, settings, __) {
        if (settings.terminalEnabled) {
          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: Colors.green[900]!),
                ),
                height: 140,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: SelectableText(
                              terminalProvider.terminal,
                              style: const TextStyle(color: Colors.green, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 3,
                right: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.green[900]!, width: 2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              title: const Text(
                                'Terminal',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.grey[900]!,
                              content: SizedBox(
                                width: double.maxFinite,
                                height: double.infinity,
                                child: SingleChildScrollView(
                                  child: Consumer<TerminalProvider>(
                                    builder: (context, terminal, child) {
                                      return SelectableText(
                                        terminal.terminal,
                                        style: const TextStyle(color: Colors.green, fontSize: 13),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: terminalProvider.terminal));
                                  },
                                  child: const Text('Copy All'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    terminalProvider.clearTerminal();
                                  },
                                  child: const Text('Clear'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.open_in_full,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Share.share(terminalProvider.terminal);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.share,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        terminalProvider.clearTerminal();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.delete,
                          color: Colors.orange,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
