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
              SelectionArea(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 2, color: Colors.green[900]!),
                  ),
                  height: containerHeight,
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 5,
                              right: 5,
                              bottom: 5,
                              top: 5,
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Consumer<TerminalProvider>(
                                    builder: (context, provider, child) {
                                      final terminalText = provider.getTerminal(widget.webviewKey!);
                                      final lines =
                                          terminalText.split('\n\n').where((line) => line.isNotEmpty).toList();

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: lines.map((line) {
                                          final isInput = line.startsWith("[IN]");
                                          final isError = line.startsWith("[ERR]");

                                          String symbol = "◀";
                                          Color symbolColor = Colors.grey.shade400;

                                          if (isInput) {
                                            symbol = "▶";
                                            symbolColor = Colors.blue;
                                          } else if (isError) {
                                            symbol = "!";
                                            symbolColor = Colors.red;
                                          }

                                          final cleanText =
                                              line.replaceFirst(RegExp(r'^\[(IN|OUT|ERR)\]\s*[><!]\s*'), '');

                                          return IntrinsicHeight(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 1.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SelectionContainer.disabled(
                                                    child: Container(
                                                      width: 20,
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          right: BorderSide(
                                                            color: symbolColor.withValues(alpha: 0.2),
                                                            width: 2,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Align(
                                                        alignment: Alignment.topLeft,
                                                        child: Text(
                                                          symbol,
                                                          style: TextStyle(
                                                            color: symbolColor,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      cleanText,
                                                      style: TextStyle(
                                                        color: isError ? Colors.red : Colors.green,
                                                        fontSize: 13,
                                                      ),
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 3,
                right: 2,
                left: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          context.read<SettingsProvider>().changeTerminalEnabled = false;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                    Row(
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
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: Column(
          children: [
            Expanded(
              child: SelectionArea(
                child: SingleChildScrollView(
                  child: Consumer<TerminalProvider>(
                    builder: (context, provider, child) {
                      final terminalText = provider.getTerminal(widget.webviewKey!);
                      final lines = terminalText.split('\n\n').where((line) => line.isNotEmpty).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: lines.map((line) {
                          final isInput = line.startsWith("[IN]");
                          final isError = line.startsWith("[ERR]");

                          String symbol = "◀";
                          Color symbolColor = Colors.grey.shade400;

                          if (isInput) {
                            symbol = "▶";
                            symbolColor = Colors.blue;
                          } else if (isError) {
                            symbol = "!";
                            symbolColor = Colors.red;
                          }

                          final cleanText = line.replaceFirst(RegExp(r'^\[(IN|OUT|ERR)\]\s*[><!]\s*'), '');

                          return IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectionContainer.disabled(
                                    child: Container(
                                      width: 20,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: symbolColor.withValues(alpha: 0.2),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          symbol,
                                          style: TextStyle(
                                            color: symbolColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      cleanText,
                                      style: TextStyle(
                                        color: isError ? Colors.red : Colors.green,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
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
