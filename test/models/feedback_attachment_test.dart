import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/feedback/feedback_attachment.dart';

const _link = 'https://storage.googleapis.com/torn-pda-manuito.appspot.com/feedback_attachments/a/b?X-Goog=1';

Map<String, dynamic> _ticket({String url = _link, String method = 'PUT', Object? headers}) => {
  'attachmentId': 'att1',
  'uploadUrl': url,
  'method': method,
  'headers': headers ?? {'Content-Type': 'image/png', 'x-goog-content-length-range': '10,10'},
};

void main() {
  test('content type follows the extension, any case', () {
    expect(feedbackContentType('Crash.PNG'), 'image/png');
    expect(feedbackContentType('a.b.jpeg'), 'image/jpeg');
    expect(feedbackContentType('clip.mov'), 'video/quicktime');
    expect(feedbackContentType('notes.txt'), isNull);
    expect(feedbackContentType('png'), isNull);
  });

  test('file problems', () {
    String? check(String name, int size, [int already = 0]) =>
        feedbackFileProblem(name: name, size: size, already: already);
    expect(check('a.png', 1), isNull);
    expect(check('a.png', feedbackImageMaxBytes), isNull);
    expect(check('a.png', feedbackImageMaxBytes + 1), isNotNull);
    expect(check('a.mp4', feedbackImageMaxBytes + 1), isNull);
    expect(check('a.mp4', feedbackVideoMaxBytes + 1), isNotNull);
    expect(check('a.png', 0), isNotNull);
    expect(check('a.pdf', 10), isNotNull);
    expect(check('a.png', 10, feedbackMaxAttachments - 1), isNull);
    expect(check('a.png', 10, feedbackMaxAttachments), isNotNull);
  });

  test('upload name keeps extension', () {
    final name = '${'x' * 150}.mp4';
    final short = feedbackUploadName(name);
    expect(short.length, 100);
    expect(short.endsWith('.mp4'), isTrue);
    expect(feedbackUploadName('crash.png'), 'crash.png');
  });

  test('storage urls', () {
    expect(isFeedbackStorageUrl(_link), isTrue);
    expect(isFeedbackStorageUrl('http://storage.googleapis.com/x'), isFalse);
    expect(isFeedbackStorageUrl('https://storage.googleapis.com.evil.com/x'), isFalse);
    expect(isFeedbackStorageUrl('https://evil.com/storage.googleapis.com'), isFalse);
    expect(isFeedbackStorageUrl(null), isFalse);
  });

  test('attachments drop foreign links', () {
    final list = feedbackAttachmentsOf([
      {
        'id': 'a',
        'name': 'crash.png',
        'contentType': 'image/png',
        'size': 20,
        'at': 1000,
        'url': _link,
        'expiresAt': 5000,
      },
      {'id': 'b', 'name': 'clip.mp4', 'contentType': 'video/mp4', 'size': 30, 'url': 'https://evil.com/x'},
      {'name': 'no id', 'contentType': 'image/png'},
      'junk',
    ]);
    expect(list.map((a) => a.id), ['a', 'b']);
    expect(list[0].isImage, isTrue);
    expect(list[0].url, _link);
    expect(list[0].hasLinkAt(DateTime.fromMillisecondsSinceEpoch(4000)), isTrue);
    expect(list[0].hasLinkAt(DateTime.fromMillisecondsSinceEpoch(5000)), isFalse);
    expect(list[1].isVideo, isTrue);
    expect(list[1].url, isNull);
    expect(feedbackAttachmentsOf(null), isEmpty);
  });

  test('upload ticket validation', () {
    final ticket = FeedbackUploadTicket.fromMap(_ticket());
    expect(ticket?.id, 'att1');
    expect(ticket?.headers['x-goog-content-length-range'], '10,10');
    expect(FeedbackUploadTicket.fromMap(_ticket(url: 'https://evil.com/up')), isNull);
    expect(FeedbackUploadTicket.fromMap(_ticket(method: 'POST')), isNull);
    expect(FeedbackUploadTicket.fromMap(_ticket(headers: {'x-goog-if-generation-match': '0'})), isNull);
    expect(FeedbackUploadTicket.fromMap(_ticket(headers: 'none')), isNull);
    expect(FeedbackUploadTicket.fromMap({'uploadUrl': _link}), isNull);
  });

  test('fresh links replace by id', () {
    final own = feedbackAttachmentsOf([
      {'id': 'a', 'name': 'a.png', 'contentType': 'image/png', 'size': 1},
      {'id': 'b', 'name': 'b.png', 'contentType': 'image/png', 'size': 1},
    ]);
    final links = FeedbackLinks.fromMap({
      'attachments': [
        {'id': 'a', 'name': 'a.png', 'contentType': 'image/png', 'size': 1, 'url': _link, 'expiresAt': 9000},
      ],
      'comments': {
        'c1': [
          {'id': 'x', 'name': 'x.mp4', 'contentType': 'video/mp4', 'size': 1, 'url': _link, 'expiresAt': 9000},
        ],
        'c2': [],
      },
    });
    final item = links.linked(own, null);
    expect(item[0].url, _link);
    expect(item[1].url, isNull);
    final comment = links.linked([
      const FeedbackAttachment(id: 'x', name: 'x.mp4', contentType: 'video/mp4', size: 1),
    ], 'c1');
    expect(comment.single.url, _link);
    expect(links.linked(own, 'missing').every((a) => a.url == null), isTrue);
  });
}
