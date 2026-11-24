import 'package:torn_pda/models/feedback/feedback_models.dart';

const feedbackMaxAttachments = 5;
const feedbackImageMaxBytes = 10 * 1024 * 1024;
const feedbackVideoMaxBytes = 50 * 1024 * 1024;
const _storageHost = 'storage.googleapis.com';

const _contentTypes = {
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'gif': 'image/gif',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
};

final feedbackAttachmentExtensions = _contentTypes.keys.toList();

// Null when the extension is not accepted
String? feedbackContentType(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot < 0 ? null : _contentTypes[fileName.substring(dot + 1).toLowerCase()];
}

bool isFeedbackVideoType(String contentType) => contentType.startsWith('video/');

// The server takes up to 100 characters
String feedbackUploadName(String name) {
  const max = 100;
  if (name.length <= max) return name;
  final dot = name.lastIndexOf('.');
  final extension = dot < 0 ? '' : name.substring(dot);
  return name.substring(0, max - extension.length) + extension;
}

String feedbackSizeText(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / 1024).ceil()} KB';
}

String? feedbackFileProblem({required String name, required int size, required int already}) {
  if (already >= feedbackMaxAttachments) return 'Up to $feedbackMaxAttachments files';
  final type = feedbackContentType(name);
  if (type == null) return 'File type not accepted';
  if (size < 1) return 'Empty file';
  final video = isFeedbackVideoType(type);
  if (size > (video ? feedbackVideoMaxBytes : feedbackImageMaxBytes)) {
    return video ? 'Video over 50 MB' : 'Image over 10 MB';
  }
  return null;
}

// Signed links are Google Storage over https
bool isFeedbackStorageUrl(String? url) {
  final uri = url == null ? null : Uri.tryParse(url);
  return uri != null && uri.scheme == 'https' && uri.host == _storageHost;
}

class FeedbackAttachment {
  const FeedbackAttachment({
    required this.id,
    required this.name,
    required this.contentType,
    required this.size,
    this.url,
    this.expiresAt,
  });

  final String id;
  final String name;
  final String contentType;
  final int size;
  final String? url;
  final DateTime? expiresAt;

  bool get isVideo => isFeedbackVideoType(contentType);

  bool get isImage => contentType.startsWith('image/');

  bool hasLinkAt(DateTime now) => url != null && expiresAt != null && expiresAt!.isAfter(now);

  // Links that are not Storage are dropped
  static FeedbackAttachment? fromMap(Object? raw) {
    if (raw is! Map || raw['id'] is! String || raw['contentType'] is! String) return null;
    final url = raw['url'];
    return FeedbackAttachment(
      id: raw['id'] as String,
      name: raw['name']?.toString() ?? '',
      contentType: raw['contentType'] as String,
      size: feedbackCount(raw['size']),
      url: url is String && isFeedbackStorageUrl(url) ? url : null,
      expiresAt: feedbackTime(raw['expiresAt']),
    );
  }
}

List<FeedbackAttachment> feedbackAttachmentsOf(Object? raw) {
  return [
    if (raw is List)
      for (final entry in raw)
        if (FeedbackAttachment.fromMap(entry) case final attachment?) attachment,
  ];
}

// Permission to upload one file
class FeedbackUploadTicket {
  const FeedbackUploadTicket({required this.id, required this.url, required this.headers});

  final String id;
  final String url;
  final Map<String, String> headers;

  // Null unless a Storage PUT with Content-Type
  static FeedbackUploadTicket? fromMap(Map<String, dynamic> map) {
    final id = map['attachmentId'];
    final url = map['uploadUrl'];
    final headers = map['headers'];
    if (id is! String || url is! String || !isFeedbackStorageUrl(url) || headers is! Map) return null;
    if (map['method'] != 'PUT') return null;
    final plain = {for (final entry in headers.entries) entry.key.toString(): entry.value.toString()};
    if (!plain.keys.any((name) => name.toLowerCase() == 'content-type')) return null;
    return FeedbackUploadTicket(id: id, url: url, headers: plain);
  }
}

class FeedbackLinks {
  const FeedbackLinks({this.item = const [], this.comments = const {}});

  final List<FeedbackAttachment> item;
  final Map<String, List<FeedbackAttachment>> comments;

  factory FeedbackLinks.fromMap(Map<String, dynamic> map) {
    final raw = map['comments'];
    return FeedbackLinks(
      item: feedbackAttachmentsOf(map['attachments']),
      comments: {
        if (raw is Map)
          for (final entry in raw.entries) entry.key.toString(): feedbackAttachmentsOf(entry.value),
      },
    );
  }

  // Own attachments with fresh links
  List<FeedbackAttachment> linked(List<FeedbackAttachment> own, String? commentId) {
    final fresh = commentId == null ? item : comments[commentId] ?? const [];
    return [for (final attachment in own) fresh.where((l) => l.id == attachment.id).firstOrNull ?? attachment];
  }
}
