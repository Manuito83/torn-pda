import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/feedback/feedback_input.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';

void main() {
  test('title rules', () {
    expect(isValidFeedbackTitle('Dark mode'), isTrue);
    expect(isValidFeedbackTitle('ab'), isFalse);
    expect(isValidFeedbackTitle('  a  '), isFalse);
    expect(isValidFeedbackTitle('!!!!'), isFalse);
    expect(isValidFeedbackTitle('x' * 121), isFalse);
    expect(isValidFeedbackTitle('two\nlines'), isFalse);
    expect(isValidFeedbackTitle('Mod\u0000e'), isFalse);
    expect(isValidFeedbackTitle('Mod${String.fromCharCode(0x202E)}e'), isFalse);
  });

  test('body and comment accept new lines and respect the limits', () {
    expect(isValidFeedbackBody(''), isTrue);
    expect(isValidFeedbackBody('a\nb\tc'), isTrue);
    expect(isValidFeedbackBody('x' * 4001), isFalse);
    expect(isValidFeedbackComment('   '), isFalse);
    expect(isValidFeedbackComment('test'), isTrue);
    expect(isValidFeedbackComment('x' * 2001), isFalse);
  });

  test('pin forms only pass with six to twelve digits', () {
    expect(isValidFeedbackPin('123456'), isTrue);
    expect(isValidFeedbackPin('12345'), isFalse);
    expect(isValidFeedbackPin('1234567890123'), isFalse);
    expect(isValidFeedbackPin('12345a'), isFalse);
    expect(isFeedbackPinFormValid(FeedbackPinMode.unlock, current: '123456'), isTrue);
    expect(isFeedbackPinFormValid(FeedbackPinMode.remove), isFalse);
    expect(isFeedbackPinFormValid(FeedbackPinMode.change, next: '123456', repeat: '123456'), isTrue);
    expect(isFeedbackPinFormValid(FeedbackPinMode.change, next: '123456', repeat: '654321'), isFalse);
    expect(isFeedbackPinFormValid(FeedbackPinMode.change, current: '12', next: '123456', repeat: '123456'), isFalse);
  });

  test('status request keeps only what changed and checks the duplicate', () {
    final plain = feedbackStatusRequest(feedbackId: 'a', status: FeedbackStatus.planned);
    expect(plain, {'feedbackId': 'a', 'status': 'planned'});

    final answered = feedbackStatusRequest(feedbackId: 'a', status: FeedbackStatus.started, responseText: ' ok ');
    expect(answered?['responseText'], 'ok');

    final duplicate = feedbackStatusRequest(
      feedbackId: 'a',
      status: FeedbackStatus.duplicate,
      duplicateInput: 'tornpda://feedback/b2',
    );
    expect(duplicate?['duplicateOf'], 'b2');
    expect(feedbackStatusRequest(feedbackId: 'a', status: FeedbackStatus.duplicate, duplicateInput: 'a'), isNull);
    expect(feedbackStatusRequest(feedbackId: 'a', status: FeedbackStatus.duplicate, duplicateInput: 'no id'), isNull);
  });

  test('only tornpda feedback links with one id open a suggestion', () {
    expect(feedbackIdFromLink('tornpda://feedback/abc_12-X'), 'abc_12-X');
    expect(feedbackIdFromLink('tornpda://feedback/'), isNull);
    expect(feedbackIdFromLink('tornpda://feedback/a/b'), isNull);
    expect(feedbackIdFromLink('tornpda://settings/abc'), isNull);
    expect(feedbackIdFromLink('https://feedback/abc'), isNull);
  });
}
