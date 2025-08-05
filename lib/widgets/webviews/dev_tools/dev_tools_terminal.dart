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

    terminalProvider.addInstruction(widget.webviewKey, "[IN]  > $source");
    if (_commandHistory.isEmpty || _commandHistory.last != source) {
      _commandHistory.add(source);
    }
    _historyIndex = _commandHistory.length;
    _scrollToTop();

    try {
      final result = await widget.webViewController!.evaluateJavascript(source: source);
      terminalProvider.addInstruction(widget.webviewKey, "[OUT] < ${result?.toString() ?? 'null'}");
    } catch (e) {
      terminalProvider.addInstruction(widget.webviewKey, "[ERR] ! ${e.toString()}");
    }

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
          child: ListView.builder(
            controller: _scrollController,
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              final isInput = line.startsWith("[IN]  >");
              final isError = line.startsWith("[ERR] !");

              IconData iconData = Icons.keyboard_arrow_left;
              Color iconColor = Colors.grey.shade600;
              if (isInput) {
                iconData = Icons.keyboard_arrow_right;
                iconColor = Colors.blue;
              } else if (isError) {
                iconData = Icons.error_outline;
                iconColor = Colors.red;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconData, size: 16, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        line.substring(7),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: isError ? Colors.red : context.read<ThemeProvider>().mainText,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
