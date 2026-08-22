import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/webview_provider.dart';

/// Tests for [WebViewProvider.areUrlsEquivalent]
void main() {
  late WebViewProvider provider;

  setUp(() {
    provider = WebViewProvider();
  });

  group('same page', () {
    test('root and index.php are the same Torn page', () {
      expect(provider.areUrlsEquivalent('https://www.torn.com/', 'https://www.torn.com/index.php'), isTrue);
    });

    test('www and bare host are the same site', () {
      expect(provider.areUrlsEquivalent('https://www.torn.com/index.php', 'https://torn.com/'), isTrue);
    });

    test('identical urls', () {
      expect(provider.areUrlsEquivalent('https://www.torn.com/gym.php', 'https://www.torn.com/gym.php'), isTrue);
    });

    test('attack loader variants for the same target', () {
      expect(
        provider.areUrlsEquivalent(
          'https://www.torn.com/loader.php?sid=attack&user2ID=225',
          'https://www.torn.com/loader2.php?sid=getInAttack&user2ID=225',
        ),
        isTrue,
      );
    });

    test('page.php attack matches the loader for the same target', () {
      expect(
        provider.areUrlsEquivalent(
          'https://www.torn.com/page.php?sid=attack&user2ID=567589',
          'https://www.torn.com/loader2.php?sid=getInAttack&user2ID=567589',
        ),
        isTrue,
      );
    });
  });

  group('different page', () {
    test('root urls of different hosts are not the same page', () {
      expect(provider.areUrlsEquivalent('https://www.torn.com/', 'https://wtfight.com/'), isFalse);
      expect(provider.areUrlsEquivalent('https://www.torn.com/index.php', 'https://www.wikipedia.org/'), isFalse);
      expect(provider.areUrlsEquivalent('https://www.torn.com/', 'https://yata.yt/'), isFalse);
    });

    test('a malformed host does not match a real one', () {
      expect(provider.areUrlsEquivalent('https://https/', 'https://example.com/'), isFalse);
    });

    test('about:blank is not the Torn home', () {
      expect(provider.areUrlsEquivalent('about:blank', 'https://www.torn.com/'), isFalse);
    });

    test('attack loaders on different hosts do not match', () {
      expect(
        provider.areUrlsEquivalent(
          'https://www.torn.com/loader.php?sid=attack&user2ID=225',
          'https://other.com/loader.php?sid=attack&user2ID=225',
        ),
        isFalse,
      );
    });

    test('different targets do not match', () {
      expect(
        provider.areUrlsEquivalent(
          'https://www.torn.com/loader.php?sid=attack&user2ID=225',
          'https://www.torn.com/loader2.php?sid=getInAttack&user2ID=226',
        ),
        isFalse,
      );
    });

    test('a real Torn page is not the root', () {
      expect(provider.areUrlsEquivalent('https://www.torn.com/gym.php', 'https://www.torn.com/'), isFalse);
    });
  });
}
