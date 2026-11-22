import 'package:torn_pda/models/feedback/feedback_models.dart';

const feedbackTitleMax = 120;
const feedbackBodyMax = 4000;
const feedbackCommentMax = 2000;
const feedbackResponseMax = 2000;

final _forbiddenChars = RegExp(r'[\p{Cc}\p{Zl}\p{Zp}\p{Bidi_Control}]', unicode: true);
final _visibleChar = RegExp(r'[\p{L}\p{N}]', unicode: true);
final _pinFormat = RegExp(r'^\d{6,12}$');
final _docIdFormat = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

bool _cleanText(String value, int min, int max, {required bool multiline}) {
  final text = value.replaceAll('\r\n', '\n').trim();
  if (text.length < min || text.length > max) return false;
  return !_forbiddenChars.hasMatch(multiline ? text.replaceAll(RegExp(r'[\n\t]'), '') : text);
}

bool isValidFeedbackTitle(String value) {
  return _cleanText(value, 3, feedbackTitleMax, multiline: false) && _visibleChar.hasMatch(value);
}

bool isValidFeedbackBody(String value) => _cleanText(value, 0, feedbackBodyMax, multiline: true);

bool isValidFeedbackComment(String value) => _cleanText(value, 1, feedbackCommentMax, multiline: true);

// Empty clears the response
bool isValidFeedbackResponse(String value) => _cleanText(value, 0, feedbackResponseMax, multiline: true);

bool isValidFeedbackPin(String value) => _pinFormat.hasMatch(value);

bool isFeedbackDocId(String value) => _docIdFormat.hasMatch(value);

enum FeedbackPinMode { unlock, change, remove }

// Server counts every wrong PIN
bool isFeedbackPinFormValid(FeedbackPinMode mode, {String current = '', String next = '', String repeat = ''}) {
  switch (mode) {
    case FeedbackPinMode.unlock:
    case FeedbackPinMode.remove:
      return isValidFeedbackPin(current);
    case FeedbackPinMode.change:
      return (current.isEmpty || isValidFeedbackPin(current)) && isValidFeedbackPin(next) && next == repeat;
  }
}

// Null when input is invalid
Map<String, dynamic>? feedbackStatusRequest({
  required String feedbackId,
  required FeedbackStatus status,
  String? responseText,
  String duplicateInput = '',
}) {
  final duplicateOf = status == FeedbackStatus.duplicate ? feedbackDuplicateId(duplicateInput) : null;
  if (status == FeedbackStatus.duplicate && (duplicateOf == null || duplicateOf == feedbackId)) return null;
  if (responseText != null && !isValidFeedbackResponse(responseText)) return null;
  return {
    'feedbackId': feedbackId,
    'status': status.name,
    'responseText': ?responseText?.trim(),
    'duplicateOf': ?duplicateOf,
  };
}

String? feedbackDuplicateId(String value) {
  final text = value.trim();
  final id = text.startsWith('tornpda://feedback/') ? text.substring('tornpda://feedback/'.length) : text;
  return isFeedbackDocId(id) ? id : null;
}

// Only tornpda://feedback/<id> opens a suggestion
String? feedbackIdFromLink(String link) {
  final uri = Uri.tryParse(link);
  if (uri == null || uri.scheme != 'tornpda' || uri.host != 'feedback' || uri.pathSegments.length != 1) return null;
  final id = uri.pathSegments.first;
  return isFeedbackDocId(id) ? id : null;
}
