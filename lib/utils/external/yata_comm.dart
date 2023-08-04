// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:cookie_jar/cookie_jar.dart';
import 'package:get/get.dart';

// Project imports:
import 'package:torn_pda/private/yata_config.dart';
import 'package:torn_pda/providers/user_controller.dart';

class YataError {
  String? reason;
}

class YataComm {
  static final String _url = YataConfig.url;
  static final String _user = YataConfig.user;
  static final String _pass = YataConfig.pass;

  static final _authUrl = Uri.parse('$_url/api/v1/auth/');
  static final _awardsUrl = Uri.parse('$_url/awards/');
  static final _awardsTogglePinUrl = Uri.parse('$_url/awards/pin/');

  static final CookieJar _cj = CookieJar();
  static final HttpClient _client = HttpClient();

  static Future<dynamic> getAwards(String? apiKey) async {
    Map<String, String> headers = {
      "referer": _url,
    };

    // 2 cookies, for CSRF and SessionId
    var cookies = await _cj.loadForRequest(_authUrl);
    if (cookies.length < 2) {
      // No valid sessionId, calling auth!
      final result = await _getAuth();
      if (result is YataError) {
        if (result.reason == "user") {
          return result;
        }
      }
      // Get cookies again after the new auth
      cookies = await _cj.loadForRequest(_authUrl);
    }

    try {
      final awardsRequest = await _client.getUrl(_awardsUrl).timeout(const Duration(seconds: 25));
      awardsRequest.cookies.addAll(cookies);
      headers.forEach((key, value) => awardsRequest.headers.add(key, value));
      final awardsResponse = await awardsRequest.close();
      final awardsJson = await awardsResponse.transform(utf8.decoder).join();
      return json.decode(awardsJson);
    } catch (e) {
      return YataError();
    }
  }

  static Future<dynamic> getPin(String awardId) async {
    Map<String, String> headers = {
      "referer": _url,
    };

    // 2 cookies, for CSRF and SessionId
    final cookies = await _cj.loadForRequest(_authUrl);
    if (cookies.length < 2) {
      // No valid sessionId, calling auth!
      await _getAuth();
    }

    try {
      // Modify header on the fly to account for the csrf token
      headers["X-CSRFToken"] = cookies[0].value;

      final awardsRequest = await _client.postUrl(_awardsTogglePinUrl).timeout(const Duration(seconds: 15));
      awardsRequest.cookies.addAll(await _cj.loadForRequest(_authUrl));
      headers.forEach((key, value) => awardsRequest.headers.add(key, value));
      final body = '{"awardId": "$awardId"}';
      awardsRequest.write(body);
      final awardsResponse = await awardsRequest.close();
      final awardsJson = await awardsResponse.transform(utf8.decoder).join();

      return json.decode(awardsJson);
    } catch (e) {
      return YataError();
    }
  }

  static Future _getAuth() async {
    final UserController u = Get.put(UserController());
    Map<String, String> headers = {
      "authorization": 'Basic ${base64Encode(utf8.encode('$_user:$_pass'))}',
      "referer": _url,
      "api-key": u.alternativeYataKey,
    };

    final authRequest = await _client.getUrl(_authUrl).timeout(const Duration(seconds: 15));
    headers.forEach((key, value) => authRequest.headers.add(key, value));
    final authResponse = await authRequest.close();

    if (authResponse.statusCode == 400 && authResponse.reasonPhrase == "Bad Request") {
      return YataError()..reason = "user";
    }

    await _cj.saveFromResponse(_authUrl, authResponse.cookies);
    return true;
  }
}
