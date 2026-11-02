import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_html_text.dart';

void main() {
  test('entities decode and tags drop', () {
    const cases = {
      'a &amp; b': 'a & b',
      '&lt;x&gt;': '<x>',
      'say &quot;hi&quot;': 'say "hi"',
      'it&#39;s': "it's",
      'it&#039;s': "it's",
      'it&#x27;s': "it's",
      'a&nbsp;b': 'a\u00A0b',
      'wait&hellip; caf&eacute;': 'wait\u2026 caf\u00E9',
      '&amp;lt;': '&lt;',
      'Hospitalized by <a href="profiles.php?XID=1">Bob</a>': 'Hospitalized by Bob',
      'I <3 you': 'I <3 you',
    };
    cases.forEach((raw, plain) => expect(chatHtmlText(raw), plain, reason: raw));
  });

  test('text without entities or tags comes back as is', () {
    expect(chatHtmlText('line one\r\nline two'), 'line one\r\nline two');
  });

  test('unescape keeps tags as typed', () {
    expect(chatHtmlUnescape('<b>bold</b> &amp; it&#x27;s'), "<b>bold</b> & it's");
  });
}
