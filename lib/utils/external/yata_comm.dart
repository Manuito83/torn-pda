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
  String reason;
}

class YataComm {
  static String _url = YataConfig.url;
  static String _user = YataConfig.user;
  static String _pass = YataConfig.pass;

  static var _authUrl = Uri.parse('$_url/api/v1/auth/');
  static var _awardsUrl = Uri.parse('$_url/awards/');
  static var _awardsTogglePinUrl = Uri.parse('$_url/awards/pin/');

  static CookieJar _cj = CookieJar();
  static HttpClient _client = HttpClient();

  static Future<dynamic> getAwards(String apiKey) async {
    Map<String, String> headers = {
      "referer": _url,
    };

    // 2 cookies, for CSRF and SessionId
    var cookies = await _cj.loadForRequest(_authUrl);
    if (cookies.length < 2) {
      // No valid sessionId, calling auth!
      var result = await _getAuth();
      if (result is YataError) {
        if (result.reason == "user") {
          return result;
        }
      }
      // Get cookies again after the new auth
      cookies = await _cj.loadForRequest(_authUrl);
    }

    try {
      var awardsRequest = await _client.getUrl(_awardsUrl);
      awardsRequest.cookies.addAll(cookies);
      headers.forEach((key, value) => awardsRequest.headers.add(key, value));
      var awardsResponse = await awardsRequest.close();
      var awardsJson = await awardsResponse.transform(utf8.decoder).join();
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
    var cookies = await _cj.loadForRequest(_authUrl);
    if (cookies.length < 2) {
      // No valid sessionId, calling auth!
      await _getAuth();
    }

    try {
      // Modify header on the fly to account for the csrf token
      headers["X-CSRFToken"] = cookies[0].value;

      var awardsRequest = await _client.postUrl(_awardsTogglePinUrl);
      awardsRequest.cookies.addAll(await _cj.loadForRequest(_authUrl));
      headers.forEach((key, value) => awardsRequest.headers.add(key, value));
      var body = "{\"awardId\": \"$awardId\"}";
      awardsRequest.write(body);
      var awardsResponse = await awardsRequest.close();
      var awardsJson = await awardsResponse.transform(utf8.decoder).join();

      return json.decode(awardsJson);
    } catch (e) {
      return YataError();
    }
  }

  static Future _getAuth() async {
    UserController _u = Get.put(UserController());
    Map<String, String> headers = {
      "authorization": 'Basic ' + base64Encode(utf8.encode('$_user:$_pass')),
      "referer": _url,
      "api-key": _u.alternativeYataKey,
    };

    var authRequest = await _client.getUrl(_authUrl);
    headers.forEach((key, value) => authRequest.headers.add(key, value));
    var authResponse = await authRequest.close();

    if (authResponse.statusCode == 400 && authResponse.reasonPhrase == "Bad Request") {
      return YataError()..reason = "user";
    }

    await _cj.saveFromResponse(_authUrl, authResponse.cookies);
    return true;
  }
}
