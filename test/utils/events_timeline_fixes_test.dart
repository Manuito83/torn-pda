import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/profile/events_timeline_fixes.dart';

/// Tests for the pure string-processing helpers in events_timeline_fixes.dart:
///   - [fixHrefAttributes]
///   - [processEventMessage]
///   - [stripUnsupportedHtmlTags]
///
/// Run with:  flutter test test/utils/events_timeline_fixes_test.dart

void main() {
  // -------------------------------------------------------------------------
  // fixHrefAttributes
  // -------------------------------------------------------------------------
  group('fixHrefAttributes', () {
    test('collapses duplicate www.torn.com prefixes', () {
      const input =
          '<a href = http://www.torn.com/http://www.torn.com/profiles.php?XID=123>User</a>';
      final result = fixHrefAttributes(input);
      expect(result, contains('href="https://www.torn.com/profiles.php?XID=123"'));
    });

    test('normalises a single www.torn.com href', () {
      const input = '<a href = http://www.torn.com/page.php>Page</a>';
      final result = fixHrefAttributes(input);
      expect(result, contains('href="https://www.torn.com/page.php"'));
    });

    test('leaves non-torn hrefs untouched', () {
      const input = '<a href="https://example.com/foo">Link</a>';
      final result = fixHrefAttributes(input);
      expect(result, input);
    });
  });

  // -------------------------------------------------------------------------
  // processEventMessage
  // -------------------------------------------------------------------------
  group('processEventMessage', () {
    test('replaces "View the details here!" with "view"', () {
      expect(processEventMessage('View the details here!'), 'view');
    });

    test('replaces "Please click here to continue." with "view"', () {
      expect(processEventMessage('Please click here to continue.'), 'view');
    });

    test('replaces "Please click here." with "view"', () {
      expect(processEventMessage('Please click here.'), 'view');
    });

    test('replaces "Please click here to collect your funds." with "Collect"', () {
      expect(
        processEventMessage('Please click here to collect your funds.'),
        'Collect',
      );
    });

    test('converts [view] brackets to parentheses', () {
      expect(processEventMessage('[view]'), '(view)');
    });
  });

  // -------------------------------------------------------------------------
  // stripUnsupportedHtmlTags
  // -------------------------------------------------------------------------
  group('stripUnsupportedHtmlTags', () {
    test('keeps <a> and <b> tags', () {
      const input = '<b>bold</b> and <a href="#">link</a>';
      expect(stripUnsupportedHtmlTags(input), input);
    });

    test('strips <span>, <div>, etc.', () {
      const input = '<span>x</span><div>y</div><b>z</b>';
      expect(stripUnsupportedHtmlTags(input), 'xy<b>z</b>');
    });

    test('converts <br> to newlines', () {
      expect(stripUnsupportedHtmlTags('line1<br/>line2'), 'line1\nline2');
      expect(stripUnsupportedHtmlTags('line1<br>line2'), 'line1\nline2');
    });
  });
}
