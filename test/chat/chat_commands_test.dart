import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_commands.dart';
import 'package:torn_pda/models/chat/chat_quick_rows.dart';

void main() {
  test('only a slash at the very start is a command', () {
    expect(ChatCommands.typed('/wiki xanax'), (name: 'wiki', args: 'xanax'));
    expect(ChatCommands.typed('/'), (name: '', args: ''));
    expect(ChatCommands.typed('/WI'), (name: 'wi', args: ''));
    expect(ChatCommands.typed('/player  Bob Smith '), (name: 'player', args: 'Bob Smith'));
    expect(ChatCommands.typed('see /wiki'), isNull);
    expect(ChatCommands.typed('/path/to/file'), isNull);
    expect(ChatCommands.typed('1/2 done'), isNull);
    expect(ChatCommands.typed('//comment'), isNull);
  });

  test('names that start with it come first', () {
    final actions = ChatCommands.actionsIn(chatQuickActionIds);
    expect(ChatCommands.matchActions('p', actions), ['price', 'player', 'script', 'map']);
    expect(ChatCommands.matchActions('', ['wiki', 'time']), ['wiki', 'time']);
    expect(ChatCommands.matchActions('zz', actions), isEmpty);
  });

  test('replies match the whole typed text', () {
    const replies = ['On my way', 'Price?', 'Thanks for the xanax'];
    expect(ChatCommands.matchReplies((name: 'on', args: 'my'), replies), ['On my way']);
    expect(ChatCommands.matchReplies((name: 'x', args: ''), replies), ['Thanks for the xanax']);
    expect(ChatCommands.matchReplies((name: '', args: ''), replies), replies);
  });
}
