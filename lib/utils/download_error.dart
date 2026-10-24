import 'dart:io';

import 'package:dio/dio.dart';

class DownloadFailure {
  const DownloadFailure({required this.message, this.blocked = false});

  final String message;
  final bool blocked;
}

DownloadFailure describeDownloadError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    return switch (error.type) {
      DioExceptionType.cancel => const DownloadFailure(message: 'Could not complete download: cancelled'),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const DownloadFailure(message: 'The download timed out, try again'),
      DioExceptionType.connectionError => const DownloadFailure(message: 'No connection, check your network'),
      _ => _fromStatus(status),
    };
  }
  if (error is SocketException) return const DownloadFailure(message: 'No connection, check your network');
  return _fromStatus(null);
}

DownloadFailure _fromStatus(int? status) {
  if (status == 403 || status == 451) {
    return const DownloadFailure(
      message: 'The site refused the download. It may be blocked in your country',
      blocked: true,
    );
  }
  if (status == 404 || status == 410) return const DownloadFailure(message: 'The file no longer exists');
  return DownloadFailure(
    message: status == null ? 'Could not complete the download' : 'Could not complete the download (error $status)',
  );
}

/// Origin only across hosts
String? downloadReferer(String page, String target) {
  final from = Uri.tryParse(page);
  final to = Uri.tryParse(target);
  if (from == null || to == null || !from.hasScheme || from.host.isEmpty) return null;
  if (from.scheme != 'http' && from.scheme != 'https') return null;
  if (from.host == to.host) return from.removeFragment().toString();
  return '${from.origin}/';
}

String? cookieHeaderFor(String host, Iterable<({String name, String value, String? domain})> cookies) {
  final matching = cookies.where((c) {
    final domain = c.domain?.replaceFirst(RegExp(r'^\.'), '').toLowerCase() ?? '';
    final lower = host.toLowerCase();
    return domain.isEmpty || lower == domain || lower.endsWith('.$domain');
  });
  return matching.isEmpty ? null : matching.map((c) => '${c.name}=${c.value}').join('; ');
}
