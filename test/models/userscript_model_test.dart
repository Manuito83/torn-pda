import 'package:test/test.dart';
import 'package:torn_pda/models/userscript_model.dart';

void main() {
  group('Userscript header parsing', () {
    test('@grant none', () {
      final headers = UserScriptModel.parseHeader('''
// ==UserScript==
// @name         Test Script
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  Test description
// @author       You
// @match        http://example.com/*
// @grant        none
// ==/UserScript==
''');

      expect(headers['grant'], []);
    });

    test('@grant GM.setValue/GM.getValue', () {
      final headers = UserScriptModel.parseHeader('''
// ==UserScript==
// @name         Test Script
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  Test description
// @author       You
// @match        http://example.com/*
// @grant        GM.setValue
// @grant        GM.getValue
// ==/UserScript==
''');

      expect(headers['grant'], ["GM.setValue", "GM.getValue"]);
    });

test('@grant not included', () {
      final headers = UserScriptModel.parseHeader('''
// ==UserScript==
// @name         Test Script
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  Test description
// @author       You
// @match        http://example.com/*
// ==/UserScript==
''');

      expect(headers['grant'], []);
    });
  });
}
