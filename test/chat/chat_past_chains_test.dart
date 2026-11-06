import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_chain_report.dart';
import 'package:torn_pda/models/chat/chat_past_chains.dart';
import 'package:torn_pda/providers/chat/chat_past_chains.dart';

Map<String, dynamic> _chain(int id, int start, {int hits = 100, int length = 3600}) => {
  'id': id,
  'chain': hits,
  'respect': 250.5,
  'start': start,
  'end': start + length,
};

Map<String, dynamic> _list(List<Map<String, dynamic>> chains, {Object? prev}) => {
  'chains': chains,
  '_metadata': {
    'links': {'prev': prev, 'next': null},
  },
};

void main() {
  group('chatParsePastChains', () {
    test('sorts newest first and skips rows without id', () {
      final page = chatParsePastChains(
        _list([
          _chain(1, 1000),
          {'chain': 5},
          _chain(3, 3000),
          _chain(2, 2000),
        ]),
      );
      expect(page!.chains.map((c) => c.id), [3, 2, 1]);
    });

    test('keeps only paging parameters of the prev link', () {
      final page = chatParsePastChains(
        _list([_chain(1, 1000)], prev: 'https://api.torn.com/v2/faction/chains?limit=20&sort=desc&to=999&key=SECRET'),
      );
      expect(page!.older, {'limit': '20', 'sort': 'desc', 'to': '999'});
    });

    test('no prev link means the end', () {
      expect(chatParsePastChains(_list([_chain(1, 1000)]))!.older, isNull);
    });

    test('an error answer is not a page', () {
      expect(
        chatParsePastChains({
          'error': {'code': 7, 'error': 'Incorrect ID-entity relation'},
        }),
        isNull,
      );
    });
  });

  test('merging an overlapping page keeps each chain once', () {
    final have = chatParsePastChains(_list([_chain(3, 3000), _chain(2, 2000)]))!.chains;
    final more = chatParsePastChains(_list([_chain(2, 2000), _chain(1, 1000)]))!.chains;
    expect(chatMergePastChains(have, more).map((c) => c.id), [3, 2, 1]);
  });

  test('date, hour and length read in TCT', () {
    final chain = chatParsePastChains(_list([_chain(1, 1767191400, length: 22320)]))!.chains.single;
    expect(chatPastChainWhen(chain), '31 Dec 2025 - 14:30 TCT - 6h 12m');
  });

  group('ChatPastChains', () {
    Map<String, dynamic> report(int id) => {
      'chainreport': {
        'id': id,
        'start': 1000,
        'end': 2000,
        'details': {'chain': 100, 'respect': 250.5, 'best': 9.0},
      },
    };

    test('asks for each report once', () async {
      var calls = 0;
      final chains = ChatPastChains(
        fetchList: (_) async => null,
        fetchReport: (id) async {
          calls++;
          return report(id);
        },
      );
      final both = await Future.wait([chains.report(7), chains.report(7)]);
      final again = await chains.report(7);
      expect(both.first, same(both.last));
      expect(again, same(both.first));
      expect(calls, 1);
    });

    test('a failed report is asked again next time', () async {
      var calls = 0;
      final chains = ChatPastChains(
        fetchList: (_) async => null,
        fetchReport: (id) async => ++calls == 1 ? null : report(id),
      );
      expect(await chains.report(7), isNull);
      expect(await chains.report(7), isNotNull);
    });

    test('loading more follows the prev link and stops when nothing is new', () async {
      final queries = <Map<String, String>>[];
      final chains = ChatPastChains(
        fetchList: (query) async {
          queries.add(query);
          return query.containsKey('to')
              ? _list([_chain(1, 1000)])
              : _list([_chain(3, 3000), _chain(2, 2000)], prev: 'https://x/faction/chains?limit=20&to=1999');
        },
        fetchReport: (_) async => null,
      );
      await chains.refresh();
      expect(chains.hasMore, isTrue);
      await chains.loadMore();
      expect(chains.chains.map((c) => c.id), [3, 2, 1]);
      expect(chains.hasMore, isFalse);
      expect(queries.last['to'], '1999');
    });

    test('forgetting the account clears everything and asks the report again', () async {
      var calls = 0;
      final chains = ChatPastChains(
        fetchList: (_) async => _list([_chain(1, 1000)], prev: 'https://x/faction/chains?limit=20&to=999'),
        fetchReport: (id) async {
          calls++;
          return report(id);
        },
      );
      await chains.refresh();
      await chains.report(7);
      chains.forget();
      expect(chains.chains, isEmpty);
      expect(chains.hasMore, isFalse);
      expect(chains.problem, isNull);
      expect(chains.cachedReport(7), isNull);
      await chains.report(7);
      expect(calls, 2);
    });

    test('an API error is reported with Torn reason and keeps the list', () async {
      var fail = false;
      final chains = ChatPastChains(
        fetchList: (_) async => fail
            ? {
                'error': {'code': 7, 'error': 'Incorrect ID-entity relation'},
              }
            : _list([_chain(1, 1000)]),
        fetchReport: (_) async => null,
      );
      await chains.refresh();
      fail = true;
      await chains.refresh();
      expect(chains.chains, hasLength(1));
      expect(chains.problemDetail, chatReportReason(7, 'Incorrect ID-entity relation'));
    });
  });
}
