import 'package:torn_pda/private/yata_config.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cookie_jar/cookie_jar.dart';
import 'dart:io';

class YataError {
  String reason;
}

class YataComm {
  static String _url = YataConfig.url;
  static String _user = YataConfig.user;
  static String _pass = YataConfig.pass;

  static var _authUrl = Uri.parse('$_url/api/v1/auth/');
  static var _awardsUrl = Uri.parse('$_url/awards/');

  static CookieJar _cj = CookieJar();
  static HttpClient _client = HttpClient();

  static Future<dynamic> getAwards(String apiKey) async {
    Map<String, String> headers = {
      "referer": _url,
    };

    // 2 cookies, for CSRF and SessionId
    if (_cj.loadForRequest(_authUrl).length < 2) {
      // No valid sessionId, calling auth!
      var result = await _getAuth(apiKey);
      if (result is YataError) {
        if (result.reason == "user") {
          return result;
        }
      }
    }

    try {
      var awardsRequest = await _client.getUrl(_awardsUrl);
      awardsRequest.cookies.addAll(_cj.loadForRequest(_authUrl));
      headers.forEach((key, value) => awardsRequest.headers.add(key, value));
      headers["referer"] = _authUrl.toString();
      var awardsResponse = await awardsRequest.close();
      var awardsJson = await awardsResponse.transform(utf8.decoder).join();
      return json.decode(awardsJson);
    } catch (e) {
      return YataError();
    }
  }

  static Future _getAuth(String apiKey) async {
    Map<String, String> headers = {
      "authorization": 'Basic ' + base64Encode(utf8.encode('$_user:$_pass')),
      "referer": _url,
      "api-key": apiKey,
    };

    var authRequest = await _client.getUrl(_authUrl);
    headers.forEach((key, value) => authRequest.headers.add(key, value));
    var authResponse = await authRequest.close();

    if (authResponse.statusCode == 400 && authResponse.reasonPhrase == "Bad Request") {
      return YataError()..reason = "user";
    }

    _cj.saveFromResponse(_authUrl, authResponse.cookies);
  }

}
