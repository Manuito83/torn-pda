import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/feedback_upload_queue.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

FeedbackPicked _file(String name, [int size = 100]) => (name: name, path: '/tmp/$name', size: size);

void main() {
  test('refused files stay out', () async {
    final queue = FeedbackUploadQueue(
      pickFiles: () async => [_file('a.png'), _file('notes.txt'), _file('huge.png', 11 * 1024 * 1024)],
    );
    await queue.add();
    expect(queue.picks.map((p) => p.name), ['a.png']);
    expect(queue.problem, isNotNull);
  });

  test('five files at most', () async {
    final queue = FeedbackUploadQueue(pickFiles: () async => [for (var i = 0; i < 7; i++) _file('f$i.png')]);
    await queue.add();
    expect(queue.picks.length, 5);
    expect(queue.isFull, isTrue);
    expect(queue.problem, isNotNull);
    await queue.add();
    expect(queue.picks.length, 5);
  });

  test('retry skips uploaded files', () async {
    final sent = <String>[];
    var failB = true;
    final queue = FeedbackUploadQueue(
      pickFiles: () async => [_file('a.png'), _file('b.mp4'), _file('c.png')],
      upload: (pick, feedbackId, commentId, onProgress) async {
        onProgress(0.5);
        if (pick.name == 'b.mp4' && failB) throw const FeedbackCallError('rate_limited');
        sent.add('${pick.name}@$feedbackId/${commentId ?? '-'}');
      },
    );
    await queue.add();

    expect(await queue.uploadAll('f1', commentId: 'c9'), 1);
    expect(sent, ['a.png@f1/c9', 'c.png@f1/c9']);
    expect(queue.hasPending, isTrue);
    final failed = queue.picks.firstWhere((p) => p.name == 'b.mp4');
    expect(failed.state, FeedbackPickState.failed);
    expect(failed.error, isNotNull);

    failB = false;
    expect(await queue.uploadAll('f1', commentId: 'c9'), 0);
    expect(sent.length, 3);
    expect(sent.last, 'b.mp4@f1/c9');
    expect(queue.hasPending, isFalse);
  });

  test('no removal while uploading', () async {
    late FeedbackUploadQueue queue;
    var removed = false;
    queue = FeedbackUploadQueue(
      pickFiles: () async => [_file('a.png')],
      upload: (pick, feedbackId, commentId, onProgress) async {
        queue.remove(pick);
        removed = queue.picks.isEmpty;
      },
    );
    await queue.add();
    await queue.uploadAll('f1');
    expect(removed, isFalse);
    expect(queue.picks.length, 1);
  });
}
