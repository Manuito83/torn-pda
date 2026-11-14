import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/terminal_provider.dart';

void main() {
  test('keeps only the newest entries once the terminal is full', () {
    final terminal = TerminalProvider();
    const key = ValueKey('tab');

    for (int i = 0; i < maxTerminalEntries + 5; i++) {
      terminal.addInstruction(key, 'line $i');
    }

    final entries = terminal.getTerminal(key).split('\n\n').where((e) => e.isNotEmpty).toList();
    expect(entries.length, maxTerminalEntries);
    expect(entries.first, '[OUT] < line ${maxTerminalEntries + 4}');
    expect(entries.last, '[OUT] < line 5');
  });
}
