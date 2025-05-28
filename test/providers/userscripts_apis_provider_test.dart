import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/userscripts_apis_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserscriptApisProvider.initialize();
  var result = UserscriptApisProvider.apis;
  test('Returns a Map', () async {
    expect(result, isA<Map<String, String>>());
  });

  test('Is not empty', () async {
    expect(result, isNotEmpty);
  });

  test('Contains GM_getValue.js', () async {
    expect(result.keys, contains('GM_getValue'));
  });

  test('Contains default.js', () async {
    expect(result.keys, contains('default'));
  });
}
