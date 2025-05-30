import 'dart:async' show Future;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class UserscriptApisProvider {
  static Map<String, String> _apis = {};

  /// Initializes the provider by loading the API scripts from the assets.
  /// Returns a [Future] if someone wants to check for errors.
  static Future<Map<String, String>> initialize() async {
    _apis = await _getApisMap(_getApis());
    return _apis;
  }

  static Map<String, String> get apis {
    return _apis;
  }

  static Future<Map<String, String>> _getApisMap(
      Future<List<String>> apiEntries) async {
    return apiEntries.then((fileList) async {
      return {
        for (var file in fileList)
          _mapFileNameToApiName(file): await rootBundle.loadString(file)
      };
    });
  }

  static String _mapFileNameToApiName(String fileName) {
    return fileName
        .replaceFirst('assets/userscripts/apis/', '')
        .replaceFirst('.js', '');
  }

  static Future<List<String>> _getApis() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    return manifestMap.keys
        .where((String key) => key.startsWith('assets/userscripts/apis/'))
        .where((String key) => key.endsWith('.js'))
        .toList();
  }
}
