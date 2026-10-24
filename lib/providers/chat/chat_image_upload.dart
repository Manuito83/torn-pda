import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class ChatUploadError implements Exception {
  const ChatUploadError(this.message, {this.blocked = false});

  final String message;
  final bool blocked;

  @override
  String toString() => message;
}

// Listed in this order, best first
enum ChatImageHost {
  imgbb('ImgBB', 'API key', 32, 'https://api.imgbb.com/', 'Recommended - free account'),
  catbox(
    'Catbox',
    'Userhash',
    200,
    'https://catbox.moe/',
    'No account - blocked in some countries or by some providers',
  ),
  imgur(
    'imgur',
    'Client-ID',
    20,
    'https://api.imgur.com/oauth2/addclient',
    'Blocked in some countries - needs a Client-ID',
  );

  const ChatImageHost(this.label, this.credentialName, this.maxMegabytes, this.registerUrl, this.note);

  final String label;
  final String credentialName;
  final int maxMegabytes;
  final String registerUrl;
  final String note;

  int get maxBytes => maxMegabytes * 1024 * 1024;

  bool get needsCredential => this != catbox;
}

class ChatImageUpload {
  static const List<String> _extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'];

  static Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  static Future<PlatformFile?> Function({required bool fromFiles}) pick = _pick;

  static Future<PlatformFile?> _pick({required bool fromFiles}) async {
    final result = await FilePicker.platform.pickFiles(
      type: fromFiles ? FileType.custom : FileType.image,
      allowedExtensions: fromFiles ? _extensions : null,
      withData: true,
    );
    return result?.files.firstOrNull;
  }

  static Future<String> upload(
    ChatImageHost host,
    Uint8List bytes,
    String name,
    String credential, {
    int expiration = 0,
    void Function(double progress)? onProgress,
  }) async {
    final label = host.label;
    final key = credential.trim();
    if (host.needsCredential && key.isEmpty) {
      throw ChatUploadError('Add the $label ${host.credentialName} in the chat settings first');
    }
    if (bytes.isEmpty) throw const ChatUploadError('Could not read the image');
    if (bytes.length > host.maxBytes) {
      throw ChatUploadError('The image is too big, $label takes up to ${host.maxMegabytes} MB');
    }
    final file = MultipartFile.fromBytes(bytes, filename: name);
    final Response response;
    try {
      response = await dio.post(
        switch (host) {
          ChatImageHost.imgur => 'https://api.imgur.com/3/image',
          ChatImageHost.imgbb => 'https://api.imgbb.com/1/upload',
          ChatImageHost.catbox => 'https://catbox.moe/user/api.php',
        },
        queryParameters: host == ChatImageHost.imgbb
            ? {'key': key, if (expiration > 0) 'expiration': expiration}
            : null,
        data: FormData.fromMap(switch (host) {
          ChatImageHost.imgur => {'image': file, 'type': 'file'},
          ChatImageHost.imgbb => {'image': file, 'name': name},
          ChatImageHost.catbox => {'reqtype': 'fileupload', if (key.isNotEmpty) 'userhash': key, 'fileToUpload': file},
        }),
        options: Options(
          headers: host == ChatImageHost.imgur ? {'Authorization': 'Client-ID $key'} : null,
          validateStatus: (_) => true,
          responseType: host == ChatImageHost.catbox ? ResponseType.plain : ResponseType.json,
        ),
        onSendProgress: onProgress == null ? null : (sent, total) => onProgress(total > 0 ? sent / total : 0),
      );
    } on DioException {
      throw ChatUploadError(
        'Could not reach $label, check the connection. If it is fine, $label may be blocked in your country',
        blocked: true,
      );
    }
    final status = response.statusCode;
    final body = response.data;
    final link = switch (host) {
      ChatImageHost.catbox => body is String ? body.trim() : null,
      _ => body is Map && body['data'] is Map ? body['data'][host == ChatImageHost.imgbb ? 'url' : 'link'] : null,
    };
    if (status == 200 && link is String && link.startsWith('https://') && !link.contains(' ')) return link;
    if (isUploadBlocked(status, body)) {
      throw ChatUploadError(
        '$label may be blocked in your country',
        blocked: true,
      );
    }
    final said = '${body is Map && body['error'] is Map ? body['error']['message'] : body}'.toLowerCase();
    throw ChatUploadError(switch (status) {
      401 || 403 => '$label refused the ${host.credentialName}, check it in the chat settings',
      413 => 'The image is too big for $label',
      429 => '$label is limiting uploads right now, try again later',
      400 when said.contains('key') || said.contains('userhash') =>
        '$label refused the ${host.credentialName}, check it in the chat settings',
      400 => '$label could not read that image',
      _ => '$label could not take the image${status == 200 ? '' : ' (error $status)'}',
    });
  }
}

/// Blocked: 451, or a 403 page
bool isUploadBlocked(int? status, Object? body) {
  if (status == 451) return true;
  if (status != 403 || body is Map) return false;
  final text = body is String ? body.trim().toLowerCase() : '';
  return text.isEmpty || text.contains('<html') || text.contains('<!doctype');
}
