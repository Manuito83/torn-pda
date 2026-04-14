import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/html_parser.dart';

/// Tests for [HtmlParser.fix] — strips HTML tags, returns plain text.
///
/// Run with:  flutter test test/utils/html_parser_test.dart

void main() {
  group('HtmlParser.fix', () {
    test('strips paragraph tags', () {
      expect(HtmlParser.fix('<p>Hello world</p>'), 'Hello world');
    });

    test('strips nested tags', () {
      expect(HtmlParser.fix('<p>Hello <b>bold</b> text</p>'), 'Hello bold text');
    });

    test('handles links', () {
      expect(
        HtmlParser.fix('<a href="https://torn.com">click</a>'),
        'click',
      );
    });

    test('returns empty-ish for null input', () {
      // parse(null) produces a minimal document; the text content is empty
      final result = HtmlParser.fix(null);
      expect(result.trim(), isEmpty);
    });

    test('plain text passes through', () {
      expect(HtmlParser.fix('no tags here'), 'no tags here');
    });
  });
}
