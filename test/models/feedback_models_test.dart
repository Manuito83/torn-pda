import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';

void main() {
  test('item reads Firestore data and survives missing fields', () {
    final item = FeedbackItem.fromMap('a1', {
      'title': 'Dark mode',
      'status': 'planned',
      'tags': ['ui', 7],
      'votesCount': 12,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000),
      'lastActivityAt': 2000,
      'response': {'text': 'On it', 'authorName': 'Manu', 'at': Timestamp.fromMillisecondsSinceEpoch(3000)},
    });
    expect(item.status, FeedbackStatus.planned);
    expect(item.tags, ['ui', '7']);
    expect(item.createdAt, DateTime.fromMillisecondsSinceEpoch(1000));
    expect(item.lastActivityAt, DateTime.fromMillisecondsSinceEpoch(2000));
    expect(item.response?.authorName, 'Manu');
    expect(item.commentsCount, 0);

    final broken = FeedbackItem.fromMap('b2', {
      'status': 'weird',
      'response': {'authorName': 'x'},
    });
    expect(broken.status, FeedbackStatus.open);
    expect(broken.response, isNull);
    expect(broken.createdAt, isNull);
  });

  test('heading puts the number before the title', () {
    expect(FeedbackItem.fromMap('a', {'title': 'Dark mode', 'number': 129}).heading, '#129 Dark mode');
    expect(FeedbackItem.fromMap('b', {'title': 'Dark mode'}).heading, 'Dark mode');
  });

  test('tags resolve by id and unknown ids stay visible', () {
    const known = [FeedbackTag(id: 'ui', name: 'Interface', color: 0xFF2196F3)];
    final item = FeedbackItem.fromMap('a', {
      'tags': ['ui', 'old'],
    });
    final tags = feedbackTagsOf(item, known);
    expect(tags.map((t) => t.name), ['Interface', 'old']);
    expect(tags.last.color, feedbackColor(null));
  });

  test('colors accept only six digit hex', () {
    expect(feedbackColor('#2196F3'), 0xFF2196F3);
    expect(feedbackColor('2196F3'), 0xFF9E9E9E);
    expect(feedbackColor('#FFF'), 0xFF9E9E9E);
  });

  test('dates are relative for a week and absolute after', () {
    final now = DateTime(2026, 11, 14, 12);
    expect(feedbackDate(now.subtract(const Duration(seconds: 20)), now), 'just now');
    expect(feedbackDate(now.subtract(const Duration(minutes: 5)), now), '5m ago');
    expect(feedbackDate(now.subtract(const Duration(hours: 3)), now), '3h ago');
    expect(feedbackDate(now.subtract(const Duration(days: 2)), now), '2d ago');
    expect(feedbackDate(DateTime(2026, 10, 1), now), '1 Oct 2026');
    expect(feedbackDate(null, now), '');
  });

  test('only our storage folder is loaded as an image', () {
    expect(isFeedbackImageUrl('${feedbackImagePrefix}abc-1.png?alt=media&token=t'), isTrue);
    expect(isFeedbackImageUrl('https://example.com/a.png'), isFalse);
    expect(
      isFeedbackImageUrl(
        'http://firebasestorage.googleapis.com/v0/b/torn-pda-manuito.appspot.com/o/feedback_legacy%2Fa',
      ),
      isFalse,
    );
    expect(
      isFeedbackImageUrl('https://firebasestorage.googleapis.com/v0/b/other.appspot.com/o/feedback_legacy%2Fa'),
      isFalse,
    );
    expect(
      isFeedbackImageUrl('https://firebasestorage.googleapis.com/v0/b/torn-pda-manuito.appspot.com/o/chat%2Fa'),
      isFalse,
    );
  });

  test('only web links are opened', () {
    expect(isFeedbackWebUrl('https://example.com/a.png'), isTrue);
    expect(isFeedbackWebUrl('http://example.com/a.png'), isFalse);
    expect(isFeedbackWebUrl('javascript:alert(1)'), isFalse);
    expect(isFeedbackWebUrl('tornpda://x'), isFalse);
    expect(isFeedbackWebUrl(null), isFalse);
  });

  test('filter changes keep the other choices', () {
    final filter = const FeedbackFilter().withStatus(FeedbackStatus.open).withTag('ui').withSort(FeedbackSort.recent);
    expect((filter.status, filter.tagId, filter.sort), (FeedbackStatus.open, 'ui', FeedbackSort.recent));
    expect(filter.withStatus(null).tagId, 'ui');
    expect(filter.withTag(null).status, FeedbackStatus.open);
  });

  test('state answer replaces the asked ids and keeps the rest', () {
    const before = FeedbackAccount(known: true, votedIds: {'old', 'a'}, subscribedIds: {'old'});
    final after = before.fromState(
      {
        'canWrite': true,
        'playerId': 7,
        'isModerator': true,
        'modUnlockedUntil': 4000000000000,
        'votedIds': ['b'],
        'subscribedIds': <String>[],
        'lockedIds': ['b'],
        'subscribedToAll': true,
      },
      ['a', 'b'],
    );

    expect(after.votedIds, {'old', 'b'});
    expect(after.subscribedIds, {'old'});
    expect(after.lockedIds, {'b'});
    expect(after.isUnlocked(DateTime(2026)), isTrue);
    expect(after.isUnlocked(DateTime.fromMillisecondsSinceEpoch(5000000000000)), isFalse);
    expect(after.subscribedToAll, isTrue);
  });

  test('a player without write access keeps the reason and never unlocks', () {
    final account = const FeedbackAccount().fromState({'canWrite': false, 'reason': 'not_verified'}, []);
    expect(account.canWrite, isFalse);
    expect(account.reason, 'not_verified');
    expect(account.isUnlocked(DateTime(2026)), isFalse);
  });

  test('unknown reason is generic', () {
    expect(feedbackReasonText('whatever'), feedbackReasonText(null));
  });

  test('filter round trip', () {
    final filter = const FeedbackFilter(
      tab: FeedbackTab.mine,
      status: FeedbackStatus.declined,
      tagId: 'ui',
      sort: FeedbackSort.activity,
    );
    final back = FeedbackFilter.decode(filter.encode());
    expect(
      (back.tab, back.status, back.tagId, back.sort),
      (FeedbackTab.mine, FeedbackStatus.declined, 'ui', FeedbackSort.activity),
    );

    for (final bad in ['', 'x', 'a|b|c|d|e', 'active|duplicate|ui|nope']) {
      final decoded = FeedbackFilter.decode(bad);
      expect((decoded.status, decoded.sort), (null, FeedbackSort.top));
    }
    expect(const FeedbackFilter().statuses, feedbackActiveStatuses);
  });
}
