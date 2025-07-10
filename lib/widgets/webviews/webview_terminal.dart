import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebviewTerminal extends StatefulWidget {
  const WebviewTerminal({
    super.key,
    required this.webviewKey,
    required this.terminalProvider,
    required this.webViewController,
  });

  final TerminalProvider terminalProvider;
  final Key? webviewKey;
  final InAppWebViewController? webViewController;

  @override
  WebviewTerminalState createState() => WebviewTerminalState();
}

class WebviewTerminalState extends State<WebviewTerminal> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.webviewKey == null || widget.webViewController == null) {
      return const SizedBox.shrink();
    }

    double containerHeight = isExpanded ? 280 : 140;

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
                height: containerHeight,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Consumer<TerminalProvider>(
                              builder: (context, provider, child) {
                                return SelectableText(
                                  provider.getTerminal(widget.webviewKey!),
                                  style: const TextStyle(color: Colors.green, fontSize: 13),
                                  textAlign: TextAlign.left,
                                );
                              },
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
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          isExpanded ? Icons.compress : Icons.expand,
                          color: Colors.yellow[800],
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final TextEditingController jsController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return TerminalDialog(widget: widget, jsController: jsController);
                          },
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.fullscreen,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: (widget.terminalProvider.getTerminal(widget.webviewKey!)),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.share,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        widget.terminalProvider.clearTerminal(widget.webviewKey!);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.delete,
                          color: Colors.orange,
                          size: 18,
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

class TerminalDialog extends StatelessWidget {
  const TerminalDialog({
    super.key,
    required this.widget,
    required this.jsController,
  });

  final WebviewTerminal widget;
  final TextEditingController jsController;

  @override
  Widget build(BuildContext context) {
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
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Consumer<TerminalProvider>(
                  builder: (context, provider, child) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: SelectableText(
                        provider.getTerminal(widget.webviewKey!),
                        style: const TextStyle(color: Colors.green, fontSize: 13),
                        textAlign: TextAlign.left,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: jsController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Enter JS code',
                labelStyle: TextStyle(color: Colors.green[800]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green[800]!),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    String jsCodeRaw = jsController.text;
                    // Replace curly quotes (both double and single) with standard quotes
                    String jsCode = jsCodeRaw.replaceAll(RegExp(r'[“”]'), '"').replaceAll(RegExp(r'[‘’]'), "'");
                    widget.webViewController!.evaluateJavascript(source: jsCode);
                    jsController.clear();
                  },
                  icon: Icon(Icons.send, size: 16, color: Colors.green[800]),
                ),
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(text: widget.terminalProvider.getTerminal(widget.webviewKey!)),
            );
          },
          child: const Text('Copy All'),
        ),
        TextButton(
          onPressed: () {
            widget.terminalProvider.clearTerminal(widget.webviewKey!);
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
