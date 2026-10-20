import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_format.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/models/chat/chat_wiki.dart';
import 'package:torn_pda/providers/chat/chat_translate.dart';
import 'package:torn_pda/utils/js_snippets/js_snippets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';

import 'chat_fakes.dart';

const _b = ChatFormat.bold;
const _i = ChatFormat.italic;

TextEditingValue _sel(String text, int start, [int? end]) => TextEditingValue(
  text: text,
  selection: TextSelection(baseOffset: start, extentOffset: end ?? start),
);

List<ChatTimeRef> _times(String text) => ChatTimeRef.split(text).whereType<ChatTimeRef>().toList();

List<String> _slang(String text) => [for (final p in ChatWiki.split(text).whereType<ChatSlang>()) p.raw];

ChatMessage _m(String text, {String name = 'Alpha', bool system = false}) => ChatMessage(
  id: text,
  roomId: 'global',
  sender: ChatUser(id: 1, name: name),
  content: text,
  createdAt: chatNow,
  isSystem: system,
);

void main() {
  group('format', () {
    test('styles render without their markers', () {
      expect(ChatFormat.runs('hello there'), [('hello there', 0)]);
      expect(ChatFormat.runs('a **b** c'), [('a ', 0), ('b', _b), (' c', 0)]);
      expect(ChatFormat.runs('*it*'), [('it', _i)]);
      expect(ChatFormat.runs('~~no~~ yes'), [('no', ChatFormat.strike), (' yes', 0)]);
      expect(ChatFormat.runs('__under__'), [('under', ChatFormat.underline)]);
      expect(ChatFormat.runs('***both***'), [('both', _b | _i)]);
      expect(ChatFormat.runs('**bold *and italic***'), [('bold ', _b), ('and italic', _b | _i)]);
      expect(ChatFormat.runs('*a\nb*'), [('a\nb', _i)]);
      final (styles, markers) = ChatFormat.scan('**a**');
      expect(markers, [true, true, false, true, true]);
      expect(styles[2], _b);
    });

    test('lonely and unclosed markers stay as typed', () {
      for (final text in ['2 * 3 = 6', '**open', 'a ~ b', '__ x__', '*\nb*']) {
        expect(ChatFormat.plain(text), text);
      }
    });

    test('links keep markers', () {
      expect(ChatFormat.plain('see https://example.com/a__b__c'), 'see https://example.com/a__b__c');
      expect(ChatFormat.plain('[x](https://e.com/**y**)'), '[x](https://e.com/**y**)');
      final runs = ChatFormat.runs('**https://www.torn.com/profiles.php?XID=1**');
      expect(runs, [('https://www.torn.com/profiles.php?XID=1', _b)]);
      expect(ChatLink.split(runs.single.$1).single, isA<ChatLink>());
    });

    test('wraps the selection or inserts a selected placeholder', () {
      final word = ChatFormat.wrap(_sel('say hello now', 4, 9), '**', 'bold');
      expect(word.text, 'say **hello** now');
      expect(word.selection.textInside(word.text), 'hello');
      expect(ChatFormat.wrap(_sel('say hello now', 3, 10), '*', 'italic').text, 'say *hello* now');
      final empty = ChatFormat.wrap(_sel('hi ', 3), '~~', 'strikethrough');
      expect(empty.text, 'hi ~~strikethrough~~');
      expect(empty.selection.textInside(empty.text), 'strikethrough');
    });

    test('marked text unwraps and bold and italic stack', () {
      expect(ChatFormat.wrap(_sel('a **b** c', 4, 5), '**', 'bold').text, 'a b c');
      expect(ChatFormat.wrap(_sel('a **b** c', 2, 7), '**', 'bold').text, 'a b c');
      expect(ChatFormat.wrap(_sel('a *b* c', 3, 4), '*', 'italic').text, 'a b c');
      expect(ChatFormat.wrap(_sel('**b**', 2, 3), '*', 'italic').text, '***b***');
      expect(ChatFormat.wrap(_sel('*b*', 1, 2), '**', 'bold').text, '***b***');
      expect(ChatFormat.wrap(_sel('***b***', 3, 4), '*', 'italic').text, '**b**');
      expect(ChatFormat.wrap(_sel('***b***', 3, 4), '**', 'bold').text, '*b*');
    });

    test('a link takes the selection as label or as address', () {
      final empty = ChatFormat.link(_sel('', 0));
      expect(empty.text, '[text](https://)');
      expect(empty.selection.textInside(empty.text), 'text');
      final label = ChatFormat.link(_sel('my bazaar', 3, 9));
      expect(label.text, 'my [bazaar](https://)');
      expect(label.selection.baseOffset, label.text.length - 1);
      final url = ChatFormat.link(_sel('https://www.torn.com', 0, 20));
      expect(url.text, '[text](https://www.torn.com)');
      expect(url.selection.textInside(url.text), 'text');
    });
  });

  group('TCT times', () {
    test('recognises the usual forms', () {
      for (final (text, h, m) in [
        ('18:00 TCT', 18, 0),
        ('meet at 3:15 tct', 3, 15),
        ('18:00 TC', 18, 0),
        ('18:00TCT', 18, 0),
        ('18:00 tc please', 18, 0),
        ('18h TCT', 18, 0),
        ('18h30 tct', 18, 30),
        ('3pm TCT', 15, 0),
        ('3:15 PM tct', 15, 15),
        ('12am tct', 0, 0),
        ('war at (23:59 TCT)', 23, 59),
      ]) {
        final found = _times(text);
        expect(found, hasLength(1), reason: text);
        expect((found.first.hour, found.first.minute), (h, m), reason: text);
      }
      final parts = ChatTimeRef.split('see you 18:00 TCT ok');
      expect(parts, ['see you ', isA<ChatTimeRef>(), ' ok']);
      expect((parts[1] as ChatTimeRef).raw, '18:00 TCT');
      expect(_times('18:00 TCT or 20:30 tct').map((r) => r.hour), [18, 20]);
    });

    test('ignores times without TCT, impossible or with a date', () {
      for (final text in [
        '18:00',
        'at 3:15',
        '18 TCT',
        '5 tc',
        '1000 TCT',
        '18:00 TCP',
        '18:00 tcting',
        'x18:00 TCT',
        '25:00 TCT',
        '12:60 TCT',
        '13pm TCT',
        '0am TCT',
        '2026-10-15 18:00 TCT',
        '15/10 at 18:00 tct',
        'on Oct 15, 18:00 TCT',
      ]) {
        expect(_times(text), isEmpty, reason: text);
      }
    });

    test('a passed hour moves to tomorrow unless it just started', () {
      const ref = ChatTimeRef(18, 0, '18:00 TCT');
      expect(ref.occurrence(DateTime.utc(2026, 10, 14, 10)), DateTime.utc(2026, 10, 14, 18));
      expect(ref.occurrence(DateTime.utc(2026, 10, 14, 18, 40)), DateTime.utc(2026, 10, 14, 18));
      expect(ref.occurrence(DateTime.utc(2026, 10, 14, 20)), DateTime.utc(2026, 10, 15, 18));
    });

    test('relative text', () {
      final now = DateTime.utc(2026, 10, 14, 10);
      for (final (offset, text) in [
        (const Duration(hours: 2, minutes: 5), 'in 2h 5m'),
        (const Duration(hours: 3), 'in 3h'),
        (const Duration(minutes: -20), '20m ago'),
        (const Duration(seconds: 20), 'now'),
        (const Duration(hours: -47, minutes: -59), '47h 59m ago'),
        (const Duration(hours: -124, minutes: -34), '5d ago'),
      ]) {
        expect(ChatTimeRef.relative(now.add(offset), now), text);
      }
    });

    test('local text marks another day and inserted text is UTC', () {
      final now = DateTime(2026, 10, 14, 10);
      expect(ChatTimeRef.local(DateTime(2026, 10, 14, 7, 5), now), '07:05');
      expect(ChatTimeRef.local(DateTime(2026, 10, 15, 7, 5), now), '07:05 tomorrow');
      expect(ChatTimeRef.insertText(DateTime.utc(2026, 10, 14, 7, 5)), '07:05 TCT');
      expect(ChatTimeRef.insertText(DateTime(2026, 10, 14, 7, 5).toUtc()), matches(RegExp(r'^\d\d:\d\d TCT$')));
    });
  });

  group('quotes', () {
    test('a reply quotes the author and only the last answer', () {
      final text = ChatQuote.reply(_m('hello\nthere'), '  hi  ');
      expect(text, '▎ Alpha: hello there\nhi');
      final parsed = ChatQuote.parse(text)!;
      expect((parsed.author, parsed.excerpt, parsed.body), ('Alpha', 'hello there', 'hi'));
      expect(ChatQuote.reply(_m('▎ Bravo: first\nsecond'), 'third'), '▎ Alpha: second\nthird');
      expect(ChatQuote.parse('just text'), isNull);
      expect(ChatQuote.parse('> not a quote\nbody'), isNull);
      expect(ChatQuote.parse('> Alpha: only the quote\n'), isNull);
    });

    test('old and new quote marks both parse', () {
      for (final mark in ['>', '▎']) {
        final parsed = ChatQuote.parse('$mark Bravo: earlier\nanswer')!;
        expect((parsed.author, parsed.excerpt, parsed.body), ('Bravo', 'earlier', 'answer'));
      }
      final quotedQuote = ChatQuote.parse(ChatQuote.reply(_m('> Bravo: nested: text'), 'ok'))!;
      expect((quotedQuote.author, quotedQuote.excerpt, quotedQuote.body), ('Alpha', '> Bravo: nested: text', 'ok'));
      final legacy = _m('> Alpha: hello\nreply', name: 'Bravo');
      expect(ChatQuote.source([_m('hello'), legacy], legacy)?.id, 'hello');
    });

    test('long reply excerpt', () {
      final long = _m('a' * 200);
      final excerpt = ChatQuote.excerpt(long.content);
      expect(excerpt.length, ChatQuote.excerptLength);
      expect(excerpt.endsWith('…'), isTrue);
      final reply = _m(ChatQuote.reply(long, 'ok'), name: 'Bravo');
      expect(ChatQuote.source([long, reply], reply)?.id, long.id);
    });

    test('forward format', () {
      final text = ChatQuote.forward('Faction', [_m('one'), _m('two', name: 'Bravo'), _m('Joined', system: true)]);
      expect(text, 'Forwarded from Faction\nAlpha: one\nBravo: two\nJoined');
      final parsed = ChatQuote.forwarded(text)!;
      expect((parsed.from, parsed.body), ('Faction', 'Alpha: one\nBravo: two\nJoined'));
      expect(ChatQuote.forward('Global', [_m('> Bravo: q\nanswer')]), 'Forwarded from Global\nAlpha: answer');
      expect(ChatQuote.forwarded('Forwarded from nowhere'), isNull);
      expect(ChatQuote.forwarded('hello'), isNull);
    });

    test('the original is the newest match before the reply', () {
      final old = _m('hello there');
      final again = ChatMessage(
        id: 'again',
        roomId: 'global',
        sender: const ChatUser(id: 1, name: 'Alpha'),
        content: 'hello there',
        createdAt: chatNow,
      );
      final reply = _m(ChatQuote.reply(old, 'hi'), name: 'Charlie');
      final messages = [old, again, _m('hello there', name: 'Bravo'), reply, _m('hello there!')];
      expect(ChatQuote.source(messages, reply)?.id, 'again');
      final orphan = _m(ChatQuote.reply(_m('gone'), 'ok'), name: 'Bravo');
      expect(ChatQuote.source([_m('other'), orphan], orphan), isNull);
      expect(ChatQuote.source([_m('plain')], _m('plain')), isNull);
    });
  });

  group('slang', () {
    test('finds whole terms and keeps the text around them', () {
      const text = 'Join an OC, buy xanax at the bazaar';
      final parts = ChatWiki.split(text);
      expect(parts.whereType<ChatSlang>().map((s) => s.raw), ['OC', 'xanax', 'bazaar']);
      expect(parts.map((p) => p is ChatSlang ? p.raw : p).join(), text);
      expect(_slang('BOC OCD xanaxes ocean'), isEmpty);
      expect(ChatWiki.split('xanax').whereType<ChatSlang>().single.term, 'xanax');
    });

    test('slang case and plural rules', () {
      expect(_slang('se me ha caído el pi y el oc'), isEmpty);
      expect(_slang('SE and PI'), ['SE', 'PI']);
      expect(_slang('RW for sale, 100% MV, DM me'), ['RW', 'MV', 'DM']);
      expect(_slang('mv dm Mv nw bb an ls ee eod'), isEmpty);
      expect(_slang('Xanax and BAZAAR, two plushies, 3 OCs'), ['Xanax', 'BAZAAR', 'plushies', 'OCs']);
    });

    test('trade, forum and attack slang', () {
      for (final (text, terms) in [
        ('NW check, 5m obo, bump, mugs', ['NW', 'obo', 'bump', 'mugs']),
        ('happy jumps with e cans, then hosp him', ['happy jumps', 'e cans', 'hosp']),
        ('we can go', <String>[]),
        ('RW for 5.8M / BB, B/O 140m, 10 e-cans, ecan, bbucks', ['RW', 'BB', 'B/O', 'e-cans', 'ecan', 'bbucks']),
        ('buying BCTs and a BCT', ['BCTs', 'BCT']),
        ('10* LS and AN hiring, high EE, PSF, EOD set, RW caches', ['LS', 'AN', 'EE', 'PSF', 'EOD', 'RW', 'caches']),
        ('SED to dodge, good RoI, retals, hire a merc', ['SED', 'RoI', 'retals', 'merc']),
      ]) {
        expect(_slang(text), terms, reason: text);
      }
    });

    test('links to the article and to the wiki search', () {
      expect(
        ChatWiki.split('FHC').whereType<ChatSlang>().single.url,
        'https://wiki.torn.com/wiki/Feathery_Hotel_Coupon',
      );
      final uri = ChatWiki.searchLink(' fair fight ');
      expect((uri.host, uri.path), ('wiki.torn.com', '/index.php'));
      expect(uri.queryParameters, {'search': 'fair fight', 'title': 'Special:Search'});
      expect(ChatWiki.articles('xan'), ['Xanax']);
      expect(ChatWiki.articles('FF'), ['Fair Fight']);
      expect(ChatWiki.articles('chain'), ['Chain']);
      expect(ChatWiki.articles('MV'), ['Items']);
      expect(ChatWiki.articles('mug'), ['Mug']);
      expect(ChatWiki.articles('x'), isEmpty);
    });
  });

  group('translation', () {
    test('Google and MyMemory answers parse', () {
      expect(
        ChatTranslator.parseGoogle([
          [
            ['Hello, how are you? ', 'hola, ¿qué tal? ', null],
            ['This is a test', 'Esto es una prueba', null],
          ],
          null,
          'es',
        ]),
        ('Hello, how are you? This is a test', 'es'),
      );
      expect(ChatTranslator.parseGoogle({'error': 1}), isNull);
      expect(ChatTranslator.parseGoogle([[]]), isNull);
      expect(
        ChatTranslator.parseMyMemory({
          'responseStatus': 200,
          'responseData': {'translatedText': 'hello', 'detectedLanguage': 'es'},
        }),
        ('hello', 'es'),
      );
      expect(ChatTranslator.parseMyMemory({'responseStatus': 429, 'responseData': {}}), isNull);
    });

    test('is fetched once per language and retried after a failure', () async {
      final asked = <String>[];
      var fail = true;
      final translator = ChatTranslator(
        fetch: (text, target) async {
          asked.add('$target:$text');
          return fail ? null : ('[$target] $text', 'es');
        },
      );

      expect(translator.shownFor('m1', 'en'), isNull);
      final pending = translator.show('m1', 'hola', 'en');
      expect(translator.shownFor('m1', 'en')!.isLoading, isTrue);
      await pending;
      expect(translator.shownFor('m1', 'en')!.failed, isTrue);

      fail = false;
      await translator.show('m1', 'hola', 'en');
      expect(translator.shownFor('m1', 'en')!.text, '[en] hola');
      expect(translator.shownFor('m1', 'en')!.from, 'es');

      translator.hide('m1');
      expect(translator.shownFor('m1', 'en'), isNull);
      await translator.show('m1', 'hola', 'en');
      expect(asked, ['en:hola', 'en:hola']);

      await translator.show('m1', 'hola', 'fr');
      expect(asked.last, 'fr:hola');
    });
  });

  testWidgets('tapping a TCT time or a slang term explains it', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessageText(content: 'join the OC at 18:00 TCT', color: Colors.black, slang: true),
        ),
      ),
    );
    await tester.tapOnText(find.textRange.ofSubstring('18:00 TCT'));
    await tester.pumpAndSettle();
    expect(find.textContaining('your time'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tapOnText(find.textRange.ofSubstring('OC'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Organized crime'), findsOneWidget);
  });

  test('highlight words reach the web chat as a JSON literal', () {
    final words = ['a"b', r'c\d', r'$e', "f'g", 'h\ni'];
    final script = chatHighlightJS(highlights: jsonEncode(words));
    expect(script, contains(jsonEncode(words)));
    expect(script, isNot(contains('\nh\ni')));
  });
}
