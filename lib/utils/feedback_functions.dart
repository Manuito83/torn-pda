import 'package:cloud_functions/cloud_functions.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';

const feedbackCallTimeout = Duration(seconds: 15);

class FeedbackCallError implements Exception {
  const FeedbackCallError(this.reason);

  final String reason;

  String get text => feedbackReasonText(reason);
}

Future<Map<String, dynamic>> callFeedback(String name, [Map<String, dynamic> data = const {}]) async {
  try {
    final callable = FirebaseFunctions.instanceFor(
      region: 'us-east4',
    ).httpsCallable('feedback-$name', options: HttpsCallableOptions(timeout: feedbackCallTimeout));
    final result = await callable.call<Object?>(data);
    final raw = result.data;
    return raw is Map ? Map<String, dynamic>.from(raw) : {};
  } on FirebaseFunctionsException catch (e) {
    final details = e.details;
    final reason = details is Map && details['reason'] is String ? details['reason'] as String : e.code;
    throw FeedbackCallError(reason);
  }
}

Future<Map<String, dynamic>> fetchFeedbackState(List<String> ids) => callFeedback('myState', {'feedbackIds': ids});

Future<String> createFeedback(String title, String body) async {
  final answer = await callFeedback('create', {'title': title, 'body': body});
  return answer['feedbackId'] as String;
}

Future<int> voteFeedback(String id, bool on) async {
  final answer = await callFeedback('vote', {'feedbackId': id, 'vote': on});
  return feedbackCount(answer['votesCount']);
}

Future<void> commentFeedback(String id, String body) => callFeedback('comment', {'feedbackId': id, 'body': body});

Future<void> deleteOwnFeedbackComment(String id, String commentId) {
  return callFeedback('deleteOwnComment', {'feedbackId': id, 'commentId': commentId});
}

Future<void> subscribeFeedback(String id, bool on) => callFeedback('subscribe', {'feedbackId': id, 'on': on});

Future<void> subscribeAllFeedback(bool on) => callFeedback('subscribeAll', {'on': on});

FeedbackPage<T> _pageOf<T>(Map<String, dynamic> answer, T Function(String id, Map<String, dynamic> map) build) {
  final raw = answer['items'];
  final cursor = answer['cursor'] ?? answer['nextCursor'];
  return FeedbackPage(
    items: [
      if (raw is List)
        for (final map in raw)
          if (map is Map) build(map['id'].toString(), Map<String, dynamic>.from(map)),
    ],
    cursor: cursor,
    hasMore: cursor != null,
  );
}

Future<FeedbackPage<FeedbackItem>> fetchMineFeedback(Object? cursor) async {
  final answer = await callFeedback('mine', {'limit': feedbackPageSize, 'cursor': ?cursor});
  return _pageOf(answer, FeedbackItem.fromMap);
}

Future<FeedbackPage<FeedbackItem>> fetchPrivateFeedback(Object? cursor) async {
  final answer = await callFeedback('listPrivate', {'limit': feedbackPageSize, 'startAfter': ?cursor});
  return _pageOf(answer, FeedbackItem.fromMap);
}

// Private comments only come through the callable
Future<FeedbackPage<FeedbackComment>> fetchPrivateComments(String id, Object? cursor) async {
  final answer = await callFeedback('listPrivate', {
    'commentsOf': id,
    'limit': feedbackPageSize,
    'startAfter': ?cursor,
  });
  return _pageOf(answer, FeedbackComment.fromMap);
}

Future<void> setFeedbackPin(String newPin, {String? current}) {
  return callFeedback('setPin', {'newPin': newPin, 'currentPin': ?current});
}

Future<void> removeFeedbackPin(String? current) => callFeedback('removePin', {'currentPin': ?current});

Future<DateTime> unlockFeedbackModeration(String pin) async {
  final answer = await callFeedback('modUnlock', {'pin': pin});
  return DateTime.fromMillisecondsSinceEpoch((answer['unlockedUntil'] as num).toInt());
}

Future<void> moderateFeedback(String action, Map<String, dynamic> data) {
  return callFeedback('moderate', {'action': action, ...data});
}
