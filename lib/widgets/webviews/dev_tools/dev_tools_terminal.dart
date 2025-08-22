import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart'; // Asegúrate de que la ruta sea correcta

class DevToolsTerminalTab extends StatefulWidget {
  final InAppWebViewController? webViewController;
  final Key? webviewKey; // Necesitamos la key para identificar el terminal correcto

  const DevToolsTerminalTab({
    super.key,
    required this.webViewController,
    required this.webviewKey,
  });

  @override
  State<DevToolsTerminalTab> createState() => _DevToolsTerminalTabState();
}

class _DevToolsTerminalTabState extends State<DevToolsTerminalTab> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _commandHistory = [];
  int _historyIndex = 0;

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _evaluateJavaScript(String source) async {
    if (widget.webViewController == null || source.trim().isEmpty) return;

    final terminalProvider = context.read<TerminalProvider>();

    String jsCode = source.replaceAll(RegExp(r'[“”]'), '"').replaceAll(RegExp(r'[‘’]'), "'");

    terminalProvider.addInstruction(widget.webviewKey, "[IN]  > $jsCode");
    if (_commandHistory.isEmpty || _commandHistory.last != jsCode) {
      _commandHistory.add(jsCode);
    }
    _historyIndex = _commandHistory.length;
    _scrollToTop();

    widget.webViewController!.evaluateJavascript(source: jsCode);

    _commandController.clear();
    _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    final terminalProvider = context.watch<TerminalProvider>();
    final terminalText = terminalProvider.getTerminal(widget.webviewKey);
    final lines = terminalText.split('\n\n').where((line) => line.isNotEmpty).toList();

    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: SelectionArea(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final isInput = line.startsWith("[IN]");
                final isError = line.startsWith("[ERR]");

                String symbol = "◀";
                Color symbolColor = Colors.grey.shade600;

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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectionContainer.disabled(
                          child: Container(
                            width: 24,
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
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cleanText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: isError ? Colors.red : context.read<ThemeProvider>().mainText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Divider(height: 1),
        _buildInputBar(terminalProvider),
      ],
    );
  }

  Widget _buildInputBar(TerminalProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      color: context.read<ThemeProvider>().canvas,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _commandController,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Execute JavaScript...',
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _evaluateJavaScript(value);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: "Previous command",
            onPressed: () {
              if (_commandHistory.isEmpty) return;
              _historyIndex--;
              if (_historyIndex < 0) _historyIndex = 0;
              _commandController.text = _commandHistory[_historyIndex];
              _commandController.selection = TextSelection.fromPosition(
                TextPosition(
                  offset: _commandController.text.length,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: "Next command",
            onPressed: () {
              if (_commandHistory.isEmpty) return;
              _historyIndex++;
              if (_historyIndex >= _commandHistory.length) {
                _historyIndex = _commandHistory.length;
                _commandController.clear();
              } else {
                _commandController.text = _commandHistory[_historyIndex];
                _commandController.selection = TextSelection.fromPosition(
                  TextPosition(
                    offset: _commandController.text.length,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Clear terminal",
            onPressed: () {
              provider.clearTerminal(widget.webviewKey);
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: "Execute",
            onPressed: () => _evaluateJavaScript(_commandController.text),
          ),
        ],
      ),
    );
  }
}
