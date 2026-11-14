import 'package:torn_pda/utils/wiki_pages.dart';

class ChatSlang {
  const ChatSlang({required this.raw, required this.term, required this.meaning, required this.article});

  final String raw;
  final String term;
  final String meaning;
  final String article;

  String get url => ChatWiki.article(article).toString();
}

class ChatWiki {
  static const String host = 'wiki.torn.com';
  static const Set<String> _slangRooms = {'newplayers'};

  static Uri article(String title) => Uri.parse(wikiPages[title] ?? 'https://$host/wiki/${title.replaceAll(' ', '_')}');

  /// Opens the article on an exact title
  static Uri searchLink(String query) =>
      Uri.https(host, '/index.php', {'search': query.trim(), 'title': 'Special:Search'});

  /// Known articles, no network
  static List<String> articles(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    return {
      for (final t in _terms)
        if (t.$1.toLowerCase() == q || t.$4.toLowerCase().contains(q)) t.$4,
    }.toList();
  }

  static bool slangIn(String? roomId, bool everywhere) => everywhere || _slangRooms.contains(roomId);

  // Upper case terms only match as written
  static const List<(String, bool, String, String)> _terms = [
    ('OC', true, 'Organized crime: a faction crew job that pays cash and items', 'Organized Crimes'),
    ('RW', true, 'Ranked war, or in trades a ranked weapon: a weapon from a ranked war reward', 'Ranked War'),
    (
      'FHC',
      true,
      'Feathery Hotel Coupon: refills energy and gives 500 happy, 6 h booster cooldown',
      'Feathery Hotel Coupon',
    ),
    ('MV', true, 'Market value: the usual price of an item', 'Items'),
    ('DM', true, 'Direct message: a private chat with one player', 'Messages'),
    ('EOD', true, 'EOD Armor: a top defensive armor set from armor caches', 'EOD Armor'),
    ('PSF', true, 'Private Security Firm: a player owned company', 'Private Security Firm'),
    ('LS', true, 'Lingerie Store: a player owned company', 'Lingerie Store'),
    ('AN', true, 'Adult Novelties: a player owned company', 'Adult Novelties'),
    ('EE', true, 'Employee effectiveness: how well someone works in a company', 'Company'),
    (
      'SED',
      true,
      'Small Explosive Device: used on yourself to go to hospital and dodge attacks',
      'Small Explosive Device',
    ),
    ('BCT', true, 'Business Class Ticket: a return flight 70% shorter', 'Business Class Ticket'),
    ('BB', true, "Bunker Bucks: traded for ranked war weapons at Big Al's Bunker", 'Bunker Bucks'),
    ('B/O', true, 'Buyout: the price to buy it right now', 'Trade'),
    ('NW', true, 'Net worth: cash, items, points and properties together', 'Special:Search/Networth'),
    ('OBO', false, 'Or best offer: the price can be negotiated', 'Trade'),
    ('PI', true, 'Private island: the top property', 'Properties'),
    ('NNB', true, 'Natural nerve bar: your nerve without boosts', 'Nerve'),
    ('SE', true, 'Stat enhancer: an item that boosts stats permanently', 'Stat Enhancer'),
    ('FF', true, 'Fair fight: respect multiplier (1x to 3x) from the stat gap', 'Fair Fight'),
    ('BS', true, 'Battle stats: strength, defense, speed and dexterity', 'Battle Stats'),
    ('OD', true, 'Overdose: taking too many drugs too fast', 'Drugs'),
    ('EDU', true, 'Education: courses that give permanent perks', 'Education'),
    ('HOF', true, 'Hall of Fame: the all time rankings', 'Hall of Fame'),
    ('API', true, 'The key based service that scripts and apps use to read your data', 'API'),
    ('xanax', false, 'A drug you buy abroad; it restores energy and uses your drug cooldown', 'Xanax'),
    ('xan', false, 'Short for xanax, a drug you buy abroad', 'Xanax'),
    ('bazaar', false, 'Your personal shop, where others buy items from you', 'Bazaar'),
    ('refill', false, 'Energy, nerve or happy refill, bought with points', 'Points'),
    ('chain bonus', false, 'Respect bonus when a faction chain hits a milestone', 'Chain'),
    (
      'happy jump',
      false,
      'Raising happy above max with candy, E-DVDs or ecstasy, then training for bigger gains',
      'Special:Search/Happy jump',
    ),
    ('e can', false, 'Energy drink can: an item that gives energy', 'Energy Drink'),
    ('e-can', false, 'Energy drink can: an item that gives energy', 'Energy Drink'),
    ('ecan', false, 'Energy drink can: an item that gives energy', 'Energy Drink'),
    ('hosp', false, 'Short for hospital, or to put someone there', 'Hospital'),
    ('stacking', false, 'Saving up energy to spend it all in one go', 'Energy'),
    ('bbucks', false, "Bunker Bucks: traded for ranked war weapons at Big Al's Bunker", 'Bunker Bucks'),
    ('cache', false, 'A ranked war reward box that opens into weapons or armor', 'Armor Cache'),
    ('roi', false, 'Return on investment: what you earn back on what you spend', 'Stock Market'),
    ('retal', false, 'Retaliation: hitting back someone who attacked your faction', 'Chain'),
    ('merc', false, 'Mercenary: a player paid to attack or hospitalize someone for you', 'Attacking'),
    ('bounty', false, 'Money offered to whoever hospitalizes a target', 'Bounties'),
    ('mugging', false, 'An attack option that steals cash from the loser', 'Mug'),
    ('mug', false, 'After winning an attack, steal part of their cash on hand', 'Mug'),
    ('bump', false, 'Posting again to push a sale or thread back to the top', 'Forums'),
    ('plushie', false, 'A soft toy found overseas, collected in sets for the Museum', 'Plushie'),
    ('rehab', false, 'Swiss clinic that lowers your drug addiction for a fee', 'Travel - Switzerland'),
    ('revive', false, 'Gets a player out of hospital, whatever the time left', 'Revive'),
  ];

  static final Map<String, (String, bool, String, String)> _byTerm = {for (final t in _terms) t.$1.toLowerCase(): t};

  static final RegExp _pattern = RegExp(
    '(?<![A-Za-z0-9])(${([for (final t in _terms) t.$1]..sort((a, b) => b.length.compareTo(a.length))).join('|')})s?(?![A-Za-z0-9])',
    caseSensitive: false,
  );

  static List<Object> split(String text) {
    final parts = <Object>[];
    var last = 0;
    for (final m in _pattern.allMatches(text)) {
      final word = m.group(1)!;
      final entry = _byTerm[word.toLowerCase()]!;
      if (entry.$2 && word != entry.$1) continue;
      if (m.start > last) parts.add(text.substring(last, m.start));
      parts.add(ChatSlang(raw: m.group(0)!, term: entry.$1, meaning: entry.$3, article: entry.$4));
      last = m.end;
    }
    if (last < text.length) parts.add(text.substring(last));
    return parts;
  }
}
