import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_attachment.dart';

const feedbackPageSize = 20;

enum FeedbackStatus {
  open('Open'),
  planned('Planned'),
  started('Started'),
  completed('Completed'),
  declined('Declined'),
  duplicate('Duplicate');

  const FeedbackStatus(this.label);
  final String label;
}

// Used when no status is chosen
const feedbackActiveStatuses = [FeedbackStatus.open, FeedbackStatus.planned, FeedbackStatus.started];

// Duplicates stay out of the list
const feedbackListedStatuses = [
  FeedbackStatus.open,
  FeedbackStatus.planned,
  FeedbackStatus.started,
  FeedbackStatus.completed,
  FeedbackStatus.declined,
];

enum FeedbackSort {
  top('Most voted', 'votesCount'),
  recent('Recent', 'createdAt'),
  activity('Last activity', 'lastActivityAt');

  const FeedbackSort(this.label, this.field);
  final String label;
  final String field;
}

enum FeedbackTab { active, mine }

class FeedbackFilter {
  const FeedbackFilter({this.tab = FeedbackTab.active, this.status, this.tagId, this.sort = FeedbackSort.top});

  final FeedbackTab tab;
  final FeedbackStatus? status;
  final String? tagId;
  final FeedbackSort sort;

  List<FeedbackStatus> get statuses => status == null ? feedbackActiveStatuses : [status!];

  FeedbackFilter withTab(FeedbackTab value) => FeedbackFilter(tab: value, status: status, tagId: tagId, sort: sort);

  FeedbackFilter withStatus(FeedbackStatus? value) => FeedbackFilter(tab: tab, status: value, tagId: tagId, sort: sort);

  FeedbackFilter withTag(String? value) => FeedbackFilter(tab: tab, status: status, tagId: value, sort: sort);

  FeedbackFilter withSort(FeedbackSort value) => FeedbackFilter(tab: tab, status: status, tagId: tagId, sort: value);

  String encode() => [tab.name, status?.name ?? '', tagId ?? '', sort.name].join('|');

  // Anything unreadable gives the defaults
  factory FeedbackFilter.decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 4) return const FeedbackFilter();
    T? named<T extends Enum>(List<T> values, String name) => values.where((v) => v.name == name).firstOrNull;
    return FeedbackFilter(
      tab: named(FeedbackTab.values, parts[0]) ?? FeedbackTab.active,
      status: named(feedbackListedStatuses, parts[1]),
      tagId: parts[2].isEmpty ? null : parts[2],
      sort: named(FeedbackSort.values, parts[3]) ?? FeedbackSort.top,
    );
  }
}

class FeedbackPage<T> {
  const FeedbackPage({required this.items, required this.cursor, required this.hasMore});

  final List<T> items;
  final Object? cursor;
  final bool hasMore;
}

class FeedbackTag {
  const FeedbackTag({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final int color;

  factory FeedbackTag.fromMap(Map<String, dynamic> map) {
    return FeedbackTag(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      color: feedbackColor(map['color']),
    );
  }
}

class FeedbackResponse {
  const FeedbackResponse({required this.text, required this.authorName, required this.at});

  final String text;
  final String authorName;
  final DateTime? at;

  static FeedbackResponse? fromMap(Object? raw) {
    if (raw is! Map || raw['text'] is! String) return null;
    return FeedbackResponse(
      text: raw['text'] as String,
      authorName: raw['authorName']?.toString() ?? '',
      at: feedbackTime(raw['at']),
    );
  }
}

class FeedbackItem {
  const FeedbackItem({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.tags,
    required this.authorName,
    required this.votesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.lastActivityAt,
    required this.response,
    this.number,
    this.type = 'suggestion',
    this.isPrivate = false,
    this.isReport = false,
    this.fromReport = false,
    this.authorPlayerId,
    this.attachments = const [],
    this.duplicateOf,
    this.role,
  });

  final String id;
  final String title;
  final String body;
  final FeedbackStatus status;
  final List<String> tags;
  final String authorName;
  final int votesCount;
  final int commentsCount;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;
  final FeedbackResponse? response;
  final int? number;
  final String type;
  final bool isPrivate;

  final bool isReport;
  final bool fromReport;
  final int? authorPlayerId;
  final List<FeedbackAttachment> attachments;
  final String? duplicateOf;
  final String? role;

  bool get isBug => type == 'bug';

  bool get isHidden => isPrivate || isReport;

  // Value that hides it again
  String get hiddenVisibility => fromReport ? 'report' : 'private';

  String get heading => number == null ? title : '#$number $title';

  FeedbackItem copyWith({
    FeedbackStatus? status,
    List<String>? tags,
    int? votesCount,
    int? commentsCount,
    bool? isPrivate,
    bool? isReport,
    List<FeedbackAttachment>? attachments,
    FeedbackResponse? response,
    bool clearResponse = false,
  }) {
    return FeedbackItem(
      id: id,
      title: title,
      body: body,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      authorName: authorName,
      votesCount: votesCount ?? this.votesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
      response: clearResponse ? null : response ?? this.response,
      number: number,
      type: type,
      isPrivate: isPrivate ?? this.isPrivate,
      isReport: isReport ?? this.isReport,
      fromReport: fromReport,
      authorPlayerId: authorPlayerId,
      attachments: attachments ?? this.attachments,
      duplicateOf: duplicateOf,
      role: role,
    );
  }

  factory FeedbackItem.fromMap(String id, Map<String, dynamic> map) {
    return FeedbackItem(
      id: id,
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      status: FeedbackStatus.values.firstWhere((s) => s.name == map['status'], orElse: () => FeedbackStatus.open),
      tags: [if (map['tags'] is List) ...(map['tags'] as List).map((tag) => tag.toString())],
      authorName: map['authorName']?.toString() ?? '',
      votesCount: feedbackCount(map['votesCount']),
      commentsCount: feedbackCount(map['commentsCount']),
      createdAt: feedbackTime(map['createdAt']),
      lastActivityAt: feedbackTime(map['lastActivityAt']),
      response: FeedbackResponse.fromMap(map['response']),
      number: map['number'] is num ? (map['number'] as num).toInt() : null,
      type: map['type']?.toString() ?? 'suggestion',
      isPrivate: map['visibility'] == 'private',
      isReport: map['visibility'] == 'report',
      fromReport: map['report'] == true,
      authorPlayerId: map['authorPlayerId'] is num ? (map['authorPlayerId'] as num).toInt() : null,
      attachments: feedbackAttachmentsOf(map['attachments']),
      duplicateOf: map['duplicateOf'] is String ? map['duplicateOf'] as String : null,
      role: map['role'] is String ? map['role'] as String : null,
    );
  }
}

class FeedbackComment {
  const FeedbackComment({
    required this.id,
    required this.body,
    required this.authorName,
    required this.createdAt,
    required this.isModerator,
    this.authorPlayerId,
    this.attachments = const [],
  });

  final String id;
  final String body;
  final String authorName;
  final DateTime? createdAt;
  final bool isModerator;
  final int? authorPlayerId;
  final List<FeedbackAttachment> attachments;

  FeedbackComment copyWith({List<FeedbackAttachment>? attachments}) {
    return FeedbackComment(
      id: id,
      body: body,
      authorName: authorName,
      createdAt: createdAt,
      isModerator: isModerator,
      authorPlayerId: authorPlayerId,
      attachments: attachments ?? this.attachments,
    );
  }

  factory FeedbackComment.fromMap(String id, Map<String, dynamic> map) {
    return FeedbackComment(
      id: id,
      body: map['body']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? '',
      createdAt: feedbackTime(map['createdAt']),
      isModerator: map['isModerator'] == true,
      authorPlayerId: map['authorPlayerId'] is num ? (map['authorPlayerId'] as num).toInt() : null,
      attachments: feedbackAttachmentsOf(map['attachments']),
    );
  }
}

// Unknown tag ids stay visible
List<FeedbackTag> feedbackTagsOf(FeedbackItem item, List<FeedbackTag> known) {
  return [
    for (final id in item.tags)
      known.where((tag) => tag.id == id).firstOrNull ?? FeedbackTag(id: id, name: id, color: feedbackColor(null)),
  ];
}

int feedbackCount(Object? raw) => raw is num ? raw.toInt() : 0;

// Timestamp or milliseconds, null otherwise
DateTime? feedbackTime(Object? raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  return null;
}

// Hex to ARGB, grey if invalid
int feedbackColor(Object? raw) {
  final match = raw is String ? RegExp(r'^#([0-9A-Fa-f]{6})$').firstMatch(raw) : null;
  return match == null ? 0xFF9E9E9E : 0xFF000000 | int.parse(match.group(1)!, radix: 16);
}

String feedbackDate(DateTime? date, DateTime now) {
  if (date == null) return '';
  final ago = now.difference(date);
  if (ago.isNegative || ago.inMinutes < 1) return 'just now';
  if (ago.inHours < 1) return '${ago.inMinutes}m ago';
  if (ago.inDays < 1) return '${ago.inHours}h ago';
  if (ago.inDays < 7) return '${ago.inDays}d ago';
  return DateFormat('d MMM yyyy').format(date);
}

String feedbackErrorText(String? code) {
  switch (code) {
    case 'permission-denied':
    case 'unauthenticated':
      return 'Feedback is not available right now';
    case 'timeout':
      return 'Feedback took too long to load';
    case 'not_verified':
    case 'no_key':
    case 'no_player':
    case 'verify_busy':
    case 'resource-exhausted':
      return feedbackReasonText(code);
    default:
      return code != null && code.startsWith('mod_') ? feedbackReasonText(code) : 'Could not load feedback';
  }
}

const feedbackImagePrefix =
    'https://firebasestorage.googleapis.com/v0/b/torn-pda-manuito.appspot.com/o/feedback_legacy%2F';

// Only https links are opened
bool isFeedbackWebUrl(String? url) {
  final uri = url == null ? null : Uri.tryParse(url);
  return uri != null && uri.hasAuthority && uri.scheme == 'https';
}

// Only our storage folder loads
bool isFeedbackImageUrl(String url) => url.startsWith(feedbackImagePrefix);
