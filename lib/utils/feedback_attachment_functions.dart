import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:torn_pda/models/feedback/feedback_attachment.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

const feedbackUploadTimeout = Duration(minutes: 10);

Future<FeedbackUploadTicket> requestFeedbackUpload({
  required String feedbackId,
  required String name,
  required String contentType,
  required int size,
  String? commentId,
}) async {
  final answer = await callFeedback('attachmentRequest', {
    'feedbackId': feedbackId,
    'commentId': ?commentId,
    'contentType': contentType,
    'size': size,
    'name': name,
  });
  return FeedbackUploadTicket.fromMap(answer) ?? (throw const FeedbackCallError('upload_failed'));
}

Future<FeedbackAttachment> confirmFeedbackUpload(String attachmentId) async {
  final answer = await callFeedback('attachmentConfirm', {'attachmentId': attachmentId});
  return FeedbackAttachment.fromMap(answer['attachment']) ?? (throw const FeedbackCallError('upload_failed'));
}

Future<void> deleteFeedbackAttachment(String feedbackId, String attachmentId, {String? commentId}) {
  return callFeedback('attachmentDelete', {
    'feedbackId': feedbackId,
    'commentId': ?commentId,
    'attachmentId': attachmentId,
  });
}

Future<FeedbackLinks> fetchFeedbackLinks(String feedbackId, List<String> commentIds) async {
  final answer = await callFeedback('attachmentUrls', {'feedbackId': feedbackId, 'commentIds': commentIds});
  return FeedbackLinks.fromMap(answer);
}

// Headers exactly as signed
Future<void> putFeedbackFile(
  FeedbackUploadTicket ticket,
  String path,
  int size, {
  void Function(double progress)? onProgress,
  Dio? dio,
}) async {
  final client =
      dio ??
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          sendTimeout: feedbackUploadTimeout,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
  try {
    await client.put<void>(
      ticket.url,
      data: File(path).openRead(),
      options: Options(
        headers: {...ticket.headers, Headers.contentLengthHeader: size},
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
      onSendProgress: onProgress == null ? null : (sent, total) => onProgress(total > 0 ? sent / total : 0),
    );
  } on DioException catch (e) {
    final timedOut =
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
    throw FeedbackCallError(timedOut ? 'timeout' : 'upload_failed');
  } on FileSystemException {
    throw const FeedbackCallError('upload_failed');
  }
}

// Permission, upload and confirmation of one file
Future<void> uploadFeedbackFile({
  required String feedbackId,
  required String name,
  required String contentType,
  required String path,
  required int size,
  String? commentId,
  void Function(double progress)? onProgress,
}) async {
  final ticket = await requestFeedbackUpload(
    feedbackId: feedbackId,
    commentId: commentId,
    name: name,
    contentType: contentType,
    size: size,
  );
  await putFeedbackFile(ticket, path, size, onProgress: onProgress);
  await confirmFeedbackUpload(ticket.id);
}
