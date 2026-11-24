import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/feedback/feedback_attachment.dart';
import 'package:torn_pda/providers/feedback_links_controller.dart';

const _url = 'https://storage.googleapis.com/b/o?sig=1';

FeedbackAttachment _own(String id) => FeedbackAttachment(id: id, name: '$id.png', contentType: 'image/png', size: 1);

FeedbackAttachment _linked(String id, DateTime expires) =>
    FeedbackAttachment(id: id, name: '$id.png', contentType: 'image/png', size: 1, url: _url, expiresAt: expires);

void main() {
  test('links are asked once while they are valid', () async {
    final calls = <List<String>>[];
    final controller = FeedbackLinksController(
      'f1',
      fetch: (id, commentIds) async {
        calls.add(commentIds);
        final later = DateTime.now().add(const Duration(minutes: 15));
        return FeedbackLinks(
          item: [_linked('a', later)],
          comments: {
            for (final c in commentIds) c: [_linked('x', later)],
          },
        );
      },
    );
    final item = [_own('a')];
    final comments = {
      'c1': [_own('x')],
    };

    await controller.ensure(item: item, comments: comments);
    await controller.ensure(item: item, comments: comments);

    expect(calls, [
      ['c1'],
    ]);
    expect(controller.itemLinks(item).single.url, _url);
    expect(controller.commentLinks('c1', comments['c1']!).single.url, _url);
  });

  test('links about to expire are asked again', () async {
    var calls = 0;
    final controller = FeedbackLinksController(
      'f1',
      fetch: (id, commentIds) async {
        calls++;
        return FeedbackLinks(item: [_linked('a', DateTime.now().add(const Duration(seconds: 30)))]);
      },
    );
    final item = [_own('a')];
    await controller.ensure(item: item, comments: const {});
    await controller.ensure(item: item, comments: const {});
    expect(calls, 2);
  });

  test('after a failure it waits to be asked, then recovers', () async {
    var fail = true;
    var calls = 0;
    final controller = FeedbackLinksController(
      'f1',
      fetch: (id, commentIds) async {
        calls++;
        if (fail) throw Exception('offline');
        return FeedbackLinks(item: [_linked('a', DateTime.now().add(const Duration(minutes: 15)))]);
      },
    );
    final item = [_own('a')];

    await controller.ensure(item: item, comments: const {});
    await controller.ensure(item: item, comments: const {});
    expect(calls, 1);
    expect(controller.failed, isTrue);

    fail = false;
    final url = await controller.freshUrl(item.single, item: item, comments: const {});
    expect(url, _url);
    expect(controller.failed, isFalse);
  });

  test('chunks of 50 comments, item links once per call', () async {
    final sizes = <int>[];
    final controller = FeedbackLinksController(
      'f1',
      fetch: (id, commentIds) async {
        sizes.add(commentIds.length);
        final later = DateTime.now().add(const Duration(minutes: 15));
        return FeedbackLinks(
          comments: {
            for (final c in commentIds) c: [_linked('x', later)],
          },
        );
      },
    );
    final comments = {
      for (var i = 0; i < 120; i++) 'c$i': [_own('x')],
    };
    await controller.ensure(item: const [], comments: comments);
    expect(sizes, [50, 50, 20]);
    expect(controller.commentLinks('c119', comments['c119']!).single.url, _url);
  });
}
