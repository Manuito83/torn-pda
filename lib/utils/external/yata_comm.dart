import 'package:torn_pda/private/yata_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class YataComm {

  static String url = YataConfig.url;
  static String user = YataConfig.user;
  static String pass = YataConfig.pass;

  static Future<String> getAwards (String apiKey) async {

    var csrf = await _getAuth(apiKey);

    var awardsResponse = await http.post(
      '$url/awards/',
      headers: {
        "referer": url,
        'X-CSRFToken': csrf.split(';')[0].split('=')[1],
        'cookie': csrf,
      },
    );

    return awardsResponse.body;
  }

  static Future<String> _getAuth (String apiKey) async {
    var basicAuth = 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
    var authResponse = await http.get(
      '$url/api/v1/auth/',
      headers: {
        'authorization': basicAuth,
        "referer": url,
        "api-key": apiKey,
      },
    );

    var csrf = authResponse.headers['set-cookie'];
    return csrf;

  }

}