import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_banking.dart';

import 'chat_fakes.dart';

// Port of the userscript's keyword check and getValueFromBankString
Object? _script(String messageText) {
  final normalised = messageText.trim().toLowerCase();
  if (normalised.isEmpty) return null;
  const searchStrings = ['bank', 'banke', 'banker', 'bankers', 'withdraw', 'balance', 'vault'];
  if (!searchStrings.any(normalised.contains)) return null;
  const thousands = ['k', 'thousand', 'thousands'];
  const millions = ['m', 'mil', 'mill', 'million', 'millions'];
  const billions = ['b', 'bn', 'billion', 'billions'];
  const denominations = [...thousands, ...millions, ...billions];
  final seg = denominations.join('|');
  final regex = RegExp(
    '\\b(?:all|max(?:imum)?|full|bal(?:ance)|(?:between\\s+)?(?:[\$£€]\\s*)?(?:\\d{1,3}(?:,\\d{3})+|\\d+(?:\\.\\d+)?)(?:\\s*(?:'
    '$seg'
    '))?\\s*(?:-|to|\u2013|\u2014|and)\\s*(?:[\$£€]\\s*)?(?:\\d{1,3}(?:,\\d{3})+|\\d+(?:\\.\\d+)?)(?:\\s*(?:'
    '$seg'
    '))?|(?:[\$£€]\\s*)?(\\d{1,3}(?:,\\d{3})+|\\d+(?:\\.\\d+)?)(?:\\s*('
    '$seg'
    '))?)\\b',
    caseSensitive: false,
  );
  final matches = regex.allMatches(normalised).toList();
  if (matches.isEmpty) return null;
  final target = matches.firstWhere((m) => denominations.contains(m.group(2)), orElse: () => matches.last);
  if (target.group(1) == null && target.group(2) == null) return 'SEND_FULL';
  var value = double.parse(target.group(1)!.replaceAll(',', ''));
  final sign = target.group(2);
  if (thousands.contains(sign)) value *= 1000;
  if (millions.contains(sign)) value *= 1000000;
  if (billions.contains(sign)) value *= 1000000000;
  return value == 0 ? null : value;
}

const _phrases = [
  'bank 5m please',
  'Banker, can I get 250k',
  'withdraw 2b',
  'vault 3 million',
  'bankers 40 thousand pls',
  'bank 1 mil',
  'bank 2 bn',
  'banker €3bn',
  'send 50000 from the bank',
  'withdraw \$750,000',
  'Bank request: \$5m',
  'can a banker send 2.5m',
  'withdraw 1,500,000',
  'banker \$2,000',
  'banker £750k',
  'bank me 12.5k',
  'BANKER 5M',
  'Withdraw 5 Million',
  'banking 5m',
  'withdrawal 5m',
  'banker 2 of us need 5m',
  '5m for 2 days banker',
  'bank 3 times 10000',
  'banker 50000 more',
  'banker 5 more minutes',
  'the bank closes at 10',
  'vault opens in 3 days',
  'my bank investment ends in 30 days',
  'bank in 2024 was better',
  'chain at 250 then bank',
  'banker withdraw all',
  'vault give me max',
  'withdraw maximum',
  'can i get my full balance banker',
  'check your balance before the war',
  'balance is fine, thanks',
  'the vault is full',
  'bank is all good now',
  'bank between 5m and 10m',
  'bank 5m-10m',
  'bank 5m\u201410m',
  'Banker? 1m to 2m',
  'can someone bank me 5k-10k',
  'bank 5-10m',
  'vault opens in 3 to 5 days',
  'river embankment 5m',
  'bank 0',
  'bank 0.5',
  'bank 99999999999999999999',
  'the banker is asleep',
  'check the vault tomorrow',
  'bal 5m',
  'anyone want 5m of xanax',
  'war starts at 5',
  '',
];

ChatMessage _msg(String id, int sender, String text, {String name = 'Bravo'}) =>
    chatMessage(id, ChatBanking.room, sender: sender, name: name, text: text);

void main() {
  group('detection matches the userscript', () {
    test('same messages get a button', () {
      for (final text in _phrases) {
        expect(ChatBanking.parse(text) != null, _script(text) != null, reason: text);
      }
    });

    test('same amount when the script has one', () {
      for (final text in _phrases) {
        final script = _script(text);
        if (script is! double || script < 1 || script > 1e15) continue;
        expect(ChatBanking.parse(text)!.amount, script.round(), reason: text);
      }
    });

    test('words for everything ask for the full balance', () {
      for (final text in ['banker withdraw all', 'vault give me max', 'check your balance', 'bank is all good now']) {
        expect(_script(text), 'SEND_FULL', reason: text);
        expect(ChatBanking.parse(text)!.full, isTrue, reason: text);
      }
    });

    test('a range opens the page without an amount', () {
      for (final text in ['bank between 5m and 10m', 'bank 5m-10m', 'Banker? 1m to 2m']) {
        expect(_script(text), 'SEND_FULL', reason: text);
        final request = ChatBanking.parse(text)!;
        expect(request.full, isFalse, reason: text);
        expect(request.amount, isNull, reason: text);
      }
    });

    test('figures the page cannot take give a button without an amount', () {
      expect(ChatBanking.parse('bank 0.5')!.amount, isNull);
      expect(ChatBanking.parse('bank 99999999999999999999')!.amount, isNull);
    });
  });

  group('fixed texts read by the userscript', () {
    test('request texts give their amount', () {
      for (final amount in [500, 250000, 1500000, 1234567, 5000000, 2000000000]) {
        expect(_script(ChatBanking.requestText(amount)), amount, reason: '$amount');
        expect(ChatBanking.parse(ChatBanking.requestText(amount))!.amount, amount, reason: '$amount');
      }
    });

    test('full balance asks for everything', () {
      expect(_script(ChatBanking.fullText), 'SEND_FULL');
    });

    test('cancel and call bankers are not requests', () {
      expect(_script(ChatBanking.cancelText), isNull);
      expect(_script(ChatBanking.callText), isNull);
      expect(ChatBanking.parse(ChatBanking.cancelText), isNull);
      expect(ChatBanking.parse(ChatBanking.callText), isNull);
    });

    test('paid texts are never requests, whatever the name', () {
      for (final name in ['Bravo', 'Banksy', 'all-in', 'Max', 'VaultBoy', '5m']) {
        for (final amount in [null, 5000000]) {
          final text = ChatBanking.paidText(ChatUser(id: 7, name: name), amount);
          expect(_script(text), isNull, reason: text);
          expect(ChatBanking.parse(text), isNull, reason: text);
        }
      }
    });
  });

  group('request state', () {
    test('a request stays open until something closes it', () {
      final states = ChatBanking.derive([_msg('1', 7, 'Bank request: \$5m'), _msg('2', 8, 'gl in the war')]);
      expect(states.keys, ['1']);
      expect(states['1']!.status, ChatBankStatus.open);
      expect(states['1']!.safe, isTrue);
    });

    test('free text requests are not marked safe', () {
      final states = ChatBanking.derive([_msg('1', 7, 'banker can I get 5m')]);
      expect(states['1']!.safe, isFalse);
    });

    test('paid closes the request and keeps who paid', () {
      final paid = ChatBanking.paidText(const ChatUser(id: 7, name: 'Bravo'), 5000000);
      final states = ChatBanking.derive([_msg('1', 7, 'Bank request: \$5m'), _msg('2', 9, paid, name: 'Teller')]);
      expect(states['1']!.status, ChatBankStatus.paid);
      expect(states['1']!.paidBy?.name, 'Teller');
    });

    test('paid with the id only, for names that read as requests', () {
      final paid = ChatBanking.paidText(const ChatUser(id: 7, name: 'Banksy'), 5000000);
      final states = ChatBanking.derive([_msg('1', 7, 'Bank request: \$5m', name: 'Banksy'), _msg('2', 9, paid)]);
      expect(states['1']!.status, ChatBankStatus.paid);
    });

    test('paid for another member leaves the request open', () {
      final paid = ChatBanking.paidText(const ChatUser(id: 8, name: 'Charlie'), 5000000);
      final states = ChatBanking.derive([_msg('1', 7, 'Bank request: \$5m'), _msg('2', 9, paid)]);
      expect(states['1']!.status, ChatBankStatus.open);
    });

    test('paying twice keeps the first banker', () {
      const to = ChatUser(id: 7, name: 'Bravo');
      final states = ChatBanking.derive([
        _msg('1', 7, 'Bank request: \$5m'),
        _msg('2', 9, ChatBanking.paidText(to, 5000000), name: 'Teller'),
        _msg('3', 10, ChatBanking.paidText(to, 5000000), name: 'Other'),
      ]);
      expect(states['1']!.paidBy?.name, 'Teller');
    });

    test('a paid message before the request does not close it', () {
      final states = ChatBanking.derive([
        _msg('1', 9, ChatBanking.paidText(const ChatUser(id: 7, name: 'Bravo'), 5000000)),
        _msg('2', 7, 'Bank request: \$5m'),
      ]);
      expect(states['2']!.status, ChatBankStatus.open);
    });

    test('cancel only works for the one who asked', () {
      final states = ChatBanking.derive([_msg('1', 7, 'Bank request: \$5m'), _msg('2', 8, ChatBanking.cancelText)]);
      expect(states['1']!.status, ChatBankStatus.open);
      final mine = ChatBanking.derive([_msg('1', 7, 'Bank request: \$5m'), _msg('2', 7, ChatBanking.cancelText)]);
      expect(mine['1']!.status, ChatBankStatus.cancelled);
    });

    test('a newer request from the same member replaces the open one', () {
      final paid = ChatBanking.paidText(const ChatUser(id: 7, name: 'Bravo'), 5000000);
      final states = ChatBanking.derive([_msg('1', 7, 'bank 5m'), _msg('2', 7, 'bank 5m please?'), _msg('3', 9, paid)]);
      expect(states['1']!.status, ChatBankStatus.replaced);
      expect(states['2']!.status, ChatBankStatus.paid);
    });

    test('a request after a paid one is open again', () {
      final paid = ChatBanking.paidText(const ChatUser(id: 7, name: 'Bravo'), null);
      final states = ChatBanking.derive([
        _msg('1', 7, ChatBanking.fullText),
        _msg('2', 9, paid),
        _msg('3', 7, 'bank 1m'),
      ]);
      expect(states['1']!.status, ChatBankStatus.paid);
      expect(states['3']!.status, ChatBankStatus.open);
    });

    test('a reply quoting a request is not a new request', () {
      final quoted = '▎ Bravo: Bank request: \$5m\non it';
      final states = ChatBanking.derive([_msg('1', 7, 'Bank request: \$5m'), _msg('2', 9, quoted)]);
      expect(states.keys, ['1']);
    });

    test('a forwarded request is not a request from who forwards it', () {
      final forwarded = 'Forwarded from Faction\nBravo: Bank request: \$5m';
      expect(ChatBanking.derive([_msg('1', 9, forwarded, name: 'Teller')]), isEmpty);
    });

    test('a failed paid message does not count', () {
      final paid = ChatBanking.paidText(const ChatUser(id: 7, name: 'Bravo'), 5000000);
      final failed = ChatMessage(
        id: '2',
        roomId: ChatBanking.room,
        sender: const ChatUser(id: 9, name: 'You'),
        content: paid,
        createdAt: chatNow,
        state: ChatMessageState.failed,
      );
      final states = ChatBanking.derive([_msg('1', 7, 'Bank request: \$5m'), failed]);
      expect(states['1']!.status, ChatBankStatus.open);
    });
  });

  group('typed amount', () {
    test('suffixes and separators', () {
      expect(ChatBanking.parseTyped('5m'), 5000000);
      expect(ChatBanking.parseTyped(' \$2.5M '), 2500000);
      expect(ChatBanking.parseTyped('1,200,000'), 1200000);
      expect(ChatBanking.parseTyped('300 k'), 300000);
      expect(ChatBanking.parseTyped('3 millions'), 3000000);
    });

    test('rejects anything else', () {
      expect(ChatBanking.parseTyped(''), isNull);
      expect(ChatBanking.parseTyped('lots'), isNull);
      expect(ChatBanking.parseTyped('5m please'), isNull);
      expect(ChatBanking.parseTyped('0'), isNull);
    });
  });

  group('link', () {
    String link(ChatBankRequest request) => ChatBanking.link(12345, request);

    test('fills the sender and the amount', () {
      expect(
        link(const ChatBankRequest(5000000)),
        'https://www.torn.com/factions.php?step=your#/tab=controls&giveMoneyTo=12345&money=5000000',
      );
    });

    test('full balance uses the same marker as the userscript', () {
      expect(link(const ChatBankRequest(null, full: true)), endsWith('giveMoneyTo=12345&money=SEND_FULL'));
    });

    test('a range leaves the amount out', () {
      expect(link(const ChatBankRequest(null)), endsWith('giveMoneyTo=12345'));
    });
  });
}
