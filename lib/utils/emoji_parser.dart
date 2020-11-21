import 'dart:convert';

class EmojiParser {
  static String fix(String text) {
    List<int> bytes = text.toString().codeUnits;
    return utf8.decode(bytes);
  }
}
