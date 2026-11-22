import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';

const feedbackFetchTimeout = Duration(seconds: 10);

const _fromServer = GetOptions(source: Source.server);

FeedbackPage<T> _pageOf<T>(
  QuerySnapshot<Map<String, dynamic>> snapshot,
  Object? cursor,
  T Function(String id, Map<String, dynamic> map) read,
) {
  return FeedbackPage(
    items: [for (final doc in snapshot.docs) read(doc.id, doc.data())],
    cursor: snapshot.docs.isEmpty ? cursor : snapshot.docs.last,
    hasMore: snapshot.docs.length == feedbackPageSize,
  );
}

Future<FeedbackItem?> fetchFeedbackItem(String id) async {
  final doc = await FirebaseFirestore.instance
      .collection('feedback')
      .doc(id)
      .get(_fromServer)
      .timeout(feedbackFetchTimeout);
  final data = doc.data();
  return data == null ? null : FeedbackItem.fromMap(doc.id, data);
}

Future<FeedbackPage<FeedbackItem>> fetchFeedbackPage(FeedbackFilter filter, Object? cursor) async {
  var query = FirebaseFirestore.instance
      .collection('feedback')
      .where('visibility', isEqualTo: 'public')
      .where('status', whereIn: filter.statuses.map((s) => s.name).toList());
  if (filter.tagId != null) query = query.where('tags', arrayContains: filter.tagId);
  query = query.orderBy(filter.sort.field, descending: true).limit(feedbackPageSize);
  if (cursor is DocumentSnapshot) query = query.startAfterDocument(cursor);

  final snapshot = await query.get(_fromServer).timeout(feedbackFetchTimeout);
  return _pageOf(snapshot, cursor, FeedbackItem.fromMap);
}

Future<FeedbackPage<FeedbackComment>> fetchFeedbackComments(String feedbackId, Object? cursor) async {
  var query = FirebaseFirestore.instance
      .collection('feedback')
      .doc(feedbackId)
      .collection('comments')
      .orderBy('createdAt')
      .limit(feedbackPageSize);
  if (cursor is DocumentSnapshot) query = query.startAfterDocument(cursor);

  final snapshot = await query.get(_fromServer).timeout(feedbackFetchTimeout);
  return _pageOf(snapshot, cursor, FeedbackComment.fromMap);
}

Future<List<FeedbackTag>> fetchFeedbackTags() async {
  final doc = await FirebaseFirestore.instance
      .collection('feedback_meta')
      .doc('config')
      .get(_fromServer)
      .timeout(feedbackFetchTimeout);
  final raw = doc.data()?['tags'];
  return [
    if (raw is List)
      for (final tag in raw)
        if (tag is Map) FeedbackTag.fromMap(Map<String, dynamic>.from(tag)),
  ];
}
