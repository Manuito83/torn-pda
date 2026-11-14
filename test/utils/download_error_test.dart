import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/utils/download_error.dart';

DioException _dio(DioExceptionType type, {int? status}) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    type: type,
    response: status == null ? null : Response(requestOptions: request, statusCode: status),
  );
}

void main() {
  group('describeDownloadError', () {
    test('403 and 451 are flagged as blocked', () {
      for (final status in [403, 451]) {
        final failure = describeDownloadError(_dio(DioExceptionType.badResponse, status: status));
        expect(failure.blocked, isTrue);
      }
    });

    test('404 and 410 mean the file is gone, not blocked', () {
      for (final status in [404, 410]) {
        final failure = describeDownloadError(_dio(DioExceptionType.badResponse, status: status));
        expect(failure.blocked, isFalse);
      }
    });

    test('other statuses keep the code, no status drops it', () {
      expect(
        describeDownloadError(_dio(DioExceptionType.badResponse, status: 500)).message,
        'Could not complete the download (error 500)',
      );
      expect(describeDownloadError(StateError('x')).message, 'Could not complete the download');
    });

    test('network problems are not blocks', () {
      for (final failure in [
        describeDownloadError(_dio(DioExceptionType.connectionError)),
        describeDownloadError(const SocketException('x')),
        describeDownloadError(_dio(DioExceptionType.receiveTimeout)),
      ]) {
        expect(failure.blocked, isFalse);
      }
      expect(
        describeDownloadError(_dio(DioExceptionType.connectionError)).message,
        isNot(describeDownloadError(_dio(DioExceptionType.receiveTimeout)).message),
      );
    });
  });

  group('cookieHeaderFor', () {
    const cookies = [
      (name: 'a', value: '1', domain: 'torn.com'),
      (name: 'b', value: '2', domain: '.torn.com'),
      (name: 'c', value: '3', domain: 'www.torn.com'),
      (name: 'd', value: '4', domain: null),
      (name: 'e', value: '5', domain: ''),
    ];

    test('parent domains match, with or without the leading dot', () {
      expect(cookieHeaderFor('www.torn.com', cookies), 'a=1; b=2; c=3; d=4; e=5');
      expect(cookieHeaderFor('torn.com', cookies), 'a=1; b=2; d=4; e=5');
    });

    test('a lookalike host only gets cookies without a domain', () {
      expect(cookieHeaderFor('xtorn.com', cookies), 'd=4; e=5');
      expect(cookieHeaderFor('torn.com.evil.net', cookies), 'd=4; e=5');
      expect(cookieHeaderFor('xtorn.com', cookies.take(3)), isNull);
    });
  });

  group('isUploadBlocked', () {
    test('451 always, 403 only without an API answer', () {
      expect(isUploadBlocked(451, {'error': 'x'}), isTrue);
      expect(isUploadBlocked(403, '<html>denied</html>'), isTrue);
      expect(isUploadBlocked(403, null), isTrue);
      expect(
        isUploadBlocked(403, {
          'data': {'error': 'Invalid client_id'},
        }),
        isFalse,
      );
      expect(isUploadBlocked(403, 'Invalid userhash'), isFalse);
      expect(isUploadBlocked(429, ''), isFalse);
    });
  });

  group('downloadReferer', () {
    test('same host keeps the full page, other host gets the origin only', () {
      expect(
        downloadReferer('https://www.torn.com/page.php?sid=x#top', 'https://www.torn.com/f.png'),
        'https://www.torn.com/page.php?sid=x',
      );
      expect(
        downloadReferer('https://www.torn.com/page.php?sid=x', 'https://i.imgur.com/a.png'),
        'https://www.torn.com/',
      );
    });

    test('no referer without a real page', () {
      expect(downloadReferer('', 'https://a.com/f'), isNull);
      expect(downloadReferer('about:blank', 'https://a.com/f'), isNull);
    });
  });
}
