import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_script_link.dart';

void main() {
  ChatLink only(String text) => ChatLink.split(text).whereType<ChatLink>().single;

  group('links', () {
    test('reads players, bazaars, attacks and trades', () {
      final xid = only('https://www.torn.com/profiles.php?XID=123');
      expect(xid.kind, ChatLinkKind.player);
      expect(xid.id, 123);
      final userId = only('www.torn.com/profiles.php?userId=456');
      expect((userId.kind, userId.id), (ChatLinkKind.player, 456));
      expect(userId.url, 'https://www.torn.com/profiles.php?userId=456');
      final bazaar = only('https://www.torn.com/bazaar.php?userId=7#/');
      expect((bazaar.kind, bazaar.id), (ChatLinkKind.bazaar, 7));
      expect(only('https://www.torn.com/loader.php?sid=attack&user2ID=8').kind, ChatLinkKind.attack);
      expect(only('https://www.torn.com/trade.php#step=view&ID=9').kind, ChatLinkKind.trade);
    });

    test('reads forums, factions, companies and the item market', () {
      final thread = only('https://www.torn.com/forums.php#/p=threads&f=2&t=16000000&b=0&a=0');
      expect((thread.kind, thread.id), (ChatLinkKind.forum, 16000000));
      final section = only('https://www.torn.com/forums.php#/p=forums&f=2');
      expect((section.kind, section.id), (ChatLinkKind.forum, null));
      final faction = only('https://www.torn.com/factions.php?step=profile&ID=11');
      expect((faction.kind, faction.id), (ChatLinkKind.faction, 11));
      final company = only('https://www.torn.com/joblist.php#/p=corpinfo&ID=12');
      expect((company.kind, company.id), (ChatLinkKind.company, 12));
      expect(only('https://www.torn.com/joblist.php#/p=corpinfo&userID=13').kind, ChatLinkKind.company);
      final item = only(
        'https://www.torn.com/page.php?sid=ItemMarket#/market/view=search&itemID=1&itemName=Some%20Item',
      );
      expect(item.kind, ChatLinkKind.item);
      expect(item.title, 'Some Item');
      expect(item.id, 1);
      final gym = only('https://www.torn.com/gym.php');
      expect(gym.kind, ChatLinkKind.torn);
      expect(gym.title, 'gym.php');
    });

    test('external links show host and path only', () {
      final link = only('see https://example.org/a/b?c=1');
      expect(link.kind, ChatLinkKind.external);
      expect(link.title, 'example.org');
      expect(link.detail, '/a/b?c=1');
    });

    test('hosts that only look like Torn are external', () {
      expect(only('https://torn.com.example.org/profiles.php?XID=1').kind, ChatLinkKind.external);
      expect(only('https://eviltorn.com/profiles.php?XID=1').kind, ChatLinkKind.external);
      final userInfo = only('https://www.torn.com@example.org/profiles.php?XID=1');
      expect(userInfo.kind, ChatLinkKind.external);
      expect(userInfo.title, 'example.org');
    });

    test('plain text, emails and other schemes are not links', () {
      expect(ChatLink.split('no links here'), ['no links here']);
      expect(ChatLink.split('mail me at someone@torn.com/x').whereType<ChatLink>(), isEmpty);
      expect(ChatLink.split('javascript:alert(1)').whereType<ChatLink>(), isEmpty);
      expect(ChatLink.parse('ftp://example.org'), isNull);
    });

    test('keeps the text around a link without punctuation or emojis', () {
      final parts = ChatLink.split('look (https://www.torn.com/bazaar.php?userId=7), cheap!');
      expect(parts.length, 3);
      expect(parts.first, 'look (');
      expect((parts[1] as ChatLink).raw, 'https://www.torn.com/bazaar.php?userId=7');
      expect(parts.last, '), cheap!');
      expect(only('https://en.example.org/wiki/A_(b)').raw, 'https://en.example.org/wiki/A_(b)');
      expect(only('open https://example.org/abc\u{1F448}').raw, 'https://example.org/abc');
    });

    test('markdown link label', () {
      final parts = ChatLink.split('rates [**CLICK HERE**](https://www.torn.com/forums.php#/p=threads&f=1&t=5) now');
      expect(parts.length, 3);
      final link = parts[1] as ChatLink;
      expect(link.label, 'CLICK HERE');
      expect(link.title, 'Forum thread #5');
      expect(parts.last, ' now');
      final fake = only('[www.torn.com](https://example.org/x)');
      expect(fake.kind, ChatLinkKind.external);
      expect(fake.title, 'example.org');
    });

    test('images are detected by extension', () {
      for (final url in [
        'https://i.example.org/a/cat.PNG',
        'https://cdn.example.org/x/y.jpeg?ex=1&hm=2',
        'look www.example.org/z.webp!',
        'https://www.torn.com/images/v2/a.gif',
      ]) {
        expect(only(url).isImage, isTrue, reason: url);
      }
      for (final url in [
        'https://example.org/gallery',
        'https://example.org/x.png.html',
        'https://example.org/?f=a.png',
        'https://www.torn.com/profiles.php?XID=1',
      ]) {
        expect(only(url).isImage, isFalse, reason: url);
      }
      expect(only('https://awardimages.torn.com/123.png').isTorn, isTrue);
      expect(only('https://torn.com.example.org/a.png').isTorn, isFalse);
    });

    test('reads YouTube video ids', () {
      for (final url in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42',
        'https://m.youtube.com/watch?feature=share&v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ?si=abc',
        'https://youtube.com/shorts/dQw4w9WgXcQ',
        'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
      ]) {
        expect(only(url).videoId, 'dQw4w9WgXcQ', reason: url);
      }
      for (final url in [
        'https://www.youtube.com/@channel',
        'https://www.youtube.com/watch?v=short',
        'https://notyoutube.com/watch?v=dQw4w9WgXcQ',
        'https://www.torn.com/watch?v=dQw4w9WgXcQ',
        'https://torn@youtu.be/dQw4w9WgXcQ',
      ]) {
        expect(only(url).videoId, isNull, reason: url);
      }
    });

    test('previews only fetch public addresses', () {
      bool public(String url) => ChatLink.isPublic(Uri.parse(url));
      for (final url in [
        'https://example.com/a.png',
        'http://8.8.8.8/x',
        'https://cafe.de',
        'https://www.torn.com/profiles.php',
        'http://172.32.0.1',
      ]) {
        expect(public(url), isTrue, reason: url);
      }
      for (final url in [
        'http://192.168.1.1/',
        'http://10.0.0.5/admin',
        'http://172.16.0.1',
        'http://172.31.255.1',
        'http://127.0.0.1',
        'http://localhost/',
        'http://printer.local/',
        'http://router.lan',
        'http://169.254.169.254/latest',
        'http://100.64.0.1',
        'http://0.0.0.0',
        'http://[::1]/',
        'http://[fe80::1]/',
        'http://[fd00::1]/',
        'http://[::ffff:192.168.1.1]/',
        'http://0x7f.0.0.1/',
        'https://example.com:8080/',
        'ftp://example.com/',
      ]) {
        expect(public(url), isFalse, reason: url);
      }
    });
  });

  group('warnings', () {
    String? warning(String text) => only(text).warning;

    test('lookalike hosts are flagged', () {
      for (final url in [
        'https://torn.com.example.org/x',
        'https://t0rn.com/profiles.php?XID=1',
        'https://torn-com.example.org',
        'https://www-torn.net/login',
        'https://torn.co/x',
        'https://tornlogin.example.org',
        'https://www.torn.com@example.org/x',
        'https://example.org/torn/login',
        '[torn.com/bazaar](https://example.org/x)',
      ]) {
        expect(warning(url), ChatLink.lookalikeWarning, reason: url);
      }
      expect(warning('https://user@example.org/x'), 'Hidden address');
    });

    test('Torn and community sites are not flagged', () {
      for (final url in [
        'https://www.torn.com/profiles.php?XID=1',
        'https://tornstats.com/spy',
        'https://www.tornexchange.com/prices',
        'https://example.org/login',
        '[my bazaar](https://example.org/x)',
      ]) {
        expect(warning(url), isNull, reason: url);
      }
    });
  });

  test('Name [id] becomes a player reference', () {
    final parts = ChatPlayerRef.split('ask Some_Name [1234] or Other-1[56]');
    final refs = parts.whereType<ChatPlayerRef>().toList();
    expect(refs.map((r) => (r.name, r.id)), [('Some_Name', 1234), ('Other-1', 56)]);
    expect(parts.first, 'ask ');
    expect(refs.first.raw, 'Some_Name [1234]');
    expect(ChatPlayerRef.split('x [12] 100 [5] [9]').whereType<ChatPlayerRef>().map((r) => r.name), ['x']);
    expect(ChatPlayerRef.split('price [0]').whereType<ChatPlayerRef>(), isEmpty);
    expect(ChatPlayerRef.split('a-b_c[abc]'), ['a-b_c[abc]']);
  });

  group('scripts', () {
    ChatScriptLink? script(String url) => ChatScriptLink.of(ChatLink.parse(url)!);

    test('user.js links are trusted only on known hosts', () {
      final github = script('https://raw.githubusercontent.com/someone/repo/main/war-helper.user.js')!;
      expect(github.name, 'war helper');
      expect(github.host, 'raw.githubusercontent.com');
      expect(github.trusted, isTrue);
      final other = script('https://example.org/a/tool.user.js')!;
      expect(other.host, 'example.org');
      expect(other.trusted, isFalse);
      expect(script('https://evilgreasyfork.org/x.user.js')!.trusted, isFalse);
    });

    test('Greasy Fork pages give the install URL', () {
      final s = script('https://greasyfork.org/en/scripts/12345-torn-tools')!;
      expect(s.installUrl, 'https://greasyfork.org/scripts/12345/code/torn-tools.user.js');
      expect(s.name, 'torn tools');
      expect(s.trusted, isTrue);
    });

    test('plain pages and http links are not scripts', () {
      expect(script('https://greasyfork.org/en/scripts'), isNull);
      expect(script('https://example.org/page'), isNull);
      expect(script('http://example.org/a.user.js'), isNull);
      expect(script('https://www.torn.com/index.php'), isNull);
    });

    test('an installed script matches by URL or Greasy Fork id', () {
      final s = script('https://greasyfork.org/en/scripts/12345-torn-tools')!;
      expect(s.installedIn(['https://greasyfork.org/scripts/12345/code/other.user.js']), isTrue);
      expect(s.installedIn([null, 'https://example.org/a.user.js']), isFalse);
    });
  });
}
