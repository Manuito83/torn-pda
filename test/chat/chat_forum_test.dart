import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_forum.dart';

const _changelog = '''
<h2>Torn PDA v4.0.0</h2>
<p><span style="color:#888888;">14 November 2026 <a href="https://tornpda.com/changelog/">full notes</a></span></p>
<hr>
<h3><span style="color:#86b9f2;">New</span></h3>
<ul>
<li><strong>Chat: built in</strong> <p>Chat without leaving the game.</p>
<p><img src="https://tornpda.com/img/a.webp" alt="Bubble" width="300"> <img src="https://editor.torn.com/b.jpg" alt="b"><br><span style="color:#888888;">Caption</span></p></li>
<li>Second <strong>item</strong></li>
</ul>
<p>After the list<br>next line</p>
''';

void main() {
  test('a changelog post becomes blocks', () {
    final blocks = ChatForum.blocks(_changelog);
    expect(
      [for (final b in blocks) (b.kind, b.nested)],
      [
        (ChatForumBlockKind.heading, false),
        (ChatForumBlockKind.paragraph, false),
        (ChatForumBlockKind.rule, false),
        (ChatForumBlockKind.subheading, false),
        (ChatForumBlockKind.bullet, false),
        (ChatForumBlockKind.paragraph, true),
        (ChatForumBlockKind.image, true),
        (ChatForumBlockKind.image, true),
        (ChatForumBlockKind.paragraph, true),
        (ChatForumBlockKind.bullet, false),
        (ChatForumBlockKind.paragraph, false),
      ],
    );
    expect(blocks[0].text, 'Torn PDA v4.0.0');
    expect(blocks[1].spans.map((s) => (s.text, s.color, s.link)), [
      ('14 November 2026 ', 0xFF888888, null),
      ('full notes', 0xFF888888, 'https://tornpda.com/changelog/'),
    ]);
    expect(blocks[4].spans.single, (text: 'Chat: built in', bold: true, color: null, link: null));
    expect((blocks[6].image, blocks[6].width, blocks[6].alt), ('https://tornpda.com/img/a.webp', 300, 'Bubble'));
    expect(blocks[7].width, isNull);
    expect(blocks[9].text, 'Second item');
    expect(blocks[10].text, 'After the list\nnext line');
  });

  test('the web link start picks the page', () {
    Uri link(String start) => Uri.parse('https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0$start');
    expect(ChatForum.startOf(link('&start=3520')), 3520);
    expect(ChatForum.startOf(link('&start=3527')), 3520);
    expect(ChatForum.startOf(link('')), 0);
  });

  test('pages of 20', () {
    expect(ChatForum.pages(3548), 178);
    expect(ChatForum.pages(20), 1);
    expect(ChatForum.pages(0), 1);
    expect(ChatForum.pageOf(3520), 177);
    expect(ChatForum.pageOf(0), 1);
    expect(ChatForum.offsetOf(177), 3520);
    expect(ChatForum.offsetOf(0), 0);
  });

  test('web link to a page or to a post', () {
    expect(
      ChatForum.webLink(16163503, forum: 67, start: 3520),
      'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0&start=3520',
    );
    expect(ChatForum.webLink(9, to: 28163100), 'https://www.torn.com/forums.php#/p=threads&t=9&b=0&a=0&to=28163100');
  });

  test('only the text color is read', () {
    expect(ChatForum.colorOf('color:#888888;'), 0xFF888888);
    expect(ChatForum.colorOf('font-weight:bold; color: #ABC'), 0xFFAABBCC);
    expect(ChatForum.colorOf('background-color:#ffffff'), isNull);
    expect(ChatForum.colorOf(null), isNull);
  });

  test('wrapped list text keeps its bullet', () {
    for (final html in [
      '<ul><li><p>Wrapped</p></li></ul>',
      '<ul><li><h3>Wrapped</h3></li></ul>',
      '<ul><li>\n<p>Wrapped</p></li></ul>',
    ]) {
      final blocks = ChatForum.blocks(html);
      expect([for (final b in blocks) (b.kind, b.text)], [(ChatForumBlockKind.bullet, 'Wrapped')], reason: html);
    }
  });

  test('scripts, odd schemes and hidden markup never show', () {
    final blocks = ChatForum.blocks(
      '<p><a href="javascript:alert(1)">bad</a> <img src="data:image/png;base64,AAAA"><script>x()</script>'
      '<style>p{}</style><a href="/profiles.php?XID=4">rel</a></p>',
    );
    expect(blocks, hasLength(1));
    expect(blocks.single.spans.map((s) => (s.text, s.link)), [
      ('bad', null),
      (' ', null),
      ('rel', 'https://www.torn.com/profiles.php?XID=4'),
    ]);
  });

  test('posts page from JSON', () {
    final page = ChatForumPage.fromJson({
      'posts': [
        {
          'id': 28163188,
          'author': {'id': 2225097, 'username': 'Manuito', 'karma': 5312},
          'created_time': 1763200000,
          'content': '<p>hi</p>',
          'is_edited': true,
          'is_pinned': true,
          'likes': 4,
          'dislikes': 1,
          'quoted_post_id': 28163100,
        },
        {'id': 'bad'},
      ],
      '_metadata': {
        'links': {'next': 'https://api.torn.com/v2/forum/1/posts?offset=20', 'prev': null},
      },
    })!;
    expect(page.hasNext, isTrue);
    expect((page.posts.single.author, page.posts.single.karma), ('Manuito', 5312));
    expect(page.posts.single.edited, isTrue);
    final post = page.posts.single;
    expect((post.pinned, post.likes, post.dislikes, post.quotedPostId), (true, 4, 1, 28163100));
    expect(page.posts.single.createdAt, DateTime.fromMillisecondsSinceEpoch(1763200000000));
    expect(
      ChatForumPage.fromJson({
        'posts': [],
        '_metadata': {
          'links': {'next': null},
        },
      })!.hasNext,
      isFalse,
    );
  });
}
