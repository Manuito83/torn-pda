import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';

class WebviewTerminal extends StatelessWidget {
  const WebviewTerminal({
    super.key,
    required this.context,
    required this.terminalProvider,
  });

  final BuildContext context;
  final TerminalProvider terminalProvider;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (_, value, __) {
        if (value.terminalEnabled) {
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
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
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
              GestureDetector(
                onTap: () {
                  terminalProvider.clearTerminal();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 3, 2, 0),
                  child: Icon(
                    Icons.delete,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
              )
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
