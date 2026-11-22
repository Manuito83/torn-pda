import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';
import 'package:torn_pda/providers/feedback_controller.dart';
import 'package:torn_pda/providers/feedback_pager.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

FeedbackItem _item(String id) => FeedbackItem.fromMap(id, {'title': id});

void main() {
  test('pager loads, adds the next page and stops at the end', () async {
    final cursors = <Object?>[];
    final pager = FeedbackPager<String>((cursor) async {
      cursors.add(cursor);
      return cursor == null
          ? const FeedbackPage(items: ['a', 'b'], cursor: 'c1', hasMore: true)
          : const FeedbackPage(items: ['c'], cursor: 'c2', hasMore: false);
    });

    await pager.reload();
    expect(pager.items, ['a', 'b']);
    expect(pager.hasMore, isTrue);

    await pager.loadMore();
    await pager.loadMore();
    expect(pager.items, ['a', 'b', 'c']);
    expect(cursors, [null, 'c1']);
  });

  test('failed first load shows an error and retry recovers', () async {
    var fail = true;
    final pager = FeedbackPager<String>((_) async {
      if (fail) throw TimeoutException('slow');
      return const FeedbackPage(items: ['a'], cursor: null, hasMore: false);
    });

    await pager.reload();
    expect(pager.failed, isTrue);
    expect(pager.errorText, feedbackErrorText('timeout'));

    fail = false;
    await pager.reload();
    expect(pager.failed, isFalse);
    expect(pager.items, ['a']);
  });

  test('failed next page keeps the items and can retry', () async {
    var calls = 0;
    final pager = FeedbackPager<String>((cursor) async {
      calls++;
      if (calls == 2) throw StateError('boom');
      return FeedbackPage(items: [cursor == null ? 'a' : 'b'], cursor: 'c', hasMore: cursor == null);
    });

    await pager.reload();
    await pager.loadMore();
    expect(pager.moreFailed, isTrue);
    expect(pager.items, ['a']);

    await pager.loadMore();
    expect(pager.moreFailed, isFalse);
    expect(pager.items, ['a', 'b']);
  });

  test('an old answer never overwrites a newer reload', () async {
    final first = Completer<FeedbackPage<String>>();
    var calls = 0;
    final pager = FeedbackPager<String>((_) {
      calls++;
      return calls == 1 ? first.future : Future.value(const FeedbackPage(items: ['new'], cursor: null, hasMore: false));
    });

    final slow = pager.reload();
    await pager.reload();
    first.complete(const FeedbackPage(items: ['old'], cursor: null, hasMore: false));
    await slow;
    expect(pager.items, ['new']);
  });

  test('controller restarts the list when the filter changes', () async {
    final seen = <FeedbackStatus?>[];
    final controller = FeedbackController(
      fetchPage: (filter, _) async {
        seen.add(filter.status);
        return FeedbackPage(items: [_item('x')], cursor: null, hasMore: false);
      },
      fetchTags: () async => [const FeedbackTag(id: 'ui', name: 'UI', color: 0xFF2196F3)],
      loadFilter: () async => '',
      saveFilter: (_) async {},
      onLoaded: (_) {},
    );

    await controller.open();
    await Future<void>.delayed(Duration.zero);
    controller.setFilter(controller.filter.withStatus(FeedbackStatus.started));
    await Future<void>.delayed(Duration.zero);

    expect(seen, [null, FeedbackStatus.started]);
    expect(controller.pager.items.single.id, 'x');
    expect(controller.tagFor('ui')?.name, 'UI');
  });

  test('controller restores and saves the filter', () async {
    final saved = <String>[];
    final asked = <List<String>>[];
    final tabs = <FeedbackTab>[];
    final controller = FeedbackController(
      fetchPage: (filter, _) async {
        tabs.add(filter.tab);
        return FeedbackPage(items: [_item('x')], cursor: null, hasMore: false);
      },
      fetchMine: (_) async {
        tabs.add(FeedbackTab.mine);
        return FeedbackPage(items: [_item('m')], cursor: null, hasMore: false);
      },
      fetchTags: () async => [],
      loadFilter: () async => const FeedbackFilter(sort: FeedbackSort.recent).encode(),
      saveFilter: (value) async => saved.add(value),
      onLoaded: asked.add,
    );

    await controller.open();
    await Future<void>.delayed(Duration.zero);
    expect(controller.filter.sort, FeedbackSort.recent);
    expect(asked.last, ['x']);

    controller.setFilter(controller.filter.withTab(FeedbackTab.mine));
    await Future<void>.delayed(Duration.zero);
    expect(tabs, [FeedbackTab.active, FeedbackTab.mine]);
    expect(saved.single, 'mine|||recent');
    expect(asked.last, ['m']);
  });

  test('vote moves count then takes server count', () async {
    final seen = <int>[];
    late FeedbackController controller;
    controller = FeedbackController(
      fetchPage: (_, _) async => FeedbackPage(items: [_item('x')], cursor: null, hasMore: false),
      fetchTags: () async => [],
      loadFilter: () async => '',
      saveFilter: (_) async {},
      onLoaded: (_) {},
      toggleVote: (_, onDelta) async {
        onDelta(1);
        seen.add(controller.pager.items.single.votesCount);
        return 7;
      },
    );

    await controller.open();
    await Future<void>.delayed(Duration.zero);
    expect(await controller.vote('x'), 7);
    expect(seen, [1]);
    expect(controller.pager.items.single.votesCount, 7);
  });

  test('pager reports a locked moderator session', () async {
    var locked = 0;
    final pager = FeedbackPager<String>(
      (_) async => throw const FeedbackCallError('mod_locked'),
      onModLocked: () => locked++,
    );

    await pager.reload();
    expect(locked, 1);
    expect(pager.failed, isTrue);
  });
}
