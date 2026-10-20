import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/models/items_model.dart';

enum ChatPriceTone { good, near, off }

class ChatPriceCheck {
  final int id;
  final String? type;
  final String name;
  final int asked;
  final int market;

  const ChatPriceCheck(this.id, this.type, this.name, this.asked, this.market);

  static const Set<String> rooms = {'trade', 'global'};
  static const int pointsId = -1;
  static const int _maxChips = 3;
  static const int _reach = 40;
  static const double _near = 0.03;
  static const double _tooLow = -0.40;
  static const double _tooHigh = 0.30;

  static final RegExp _intent = RegExp(
    r'\b(wts|wtb|wtt|selling|buying|paying|buy|sell|for sale|wanted)\b|(^|\s)[sb]\s?:',
    caseSensitive: false,
  );
  static final RegExp _price = RegExp(
    r'(?<![a-zA-Z0-9.,])(\$\s?)?(\d{1,3}(?:,\d{3})+|\d+(?:\.\d+)?)\s?([kmb])?(?![a-zA-Z0-9])',
    caseSensitive: false,
  );
  static final RegExp _quantity = RegExp(r'\b(\d+)\s?x\b|\bx\s?(\d+)\b', caseSensitive: false);
  static final RegExp _points = RegExp(
    r'(?:(?<![a-zA-Z0-9.,])(\d{1,3}(?:,\d{3})+|\d+(?:\.\d+)?)\s?([km])?\s?)?\b(?:points?|pts?)\b',
    caseSensitive: false,
  );
  static final RegExp _each = RegExp(r'\b(ea|each|per)\b', caseSensitive: false);

  static (ItemsModel, List<(String, int, Item)>)? _names;

  double get ratio => (asked - market) / market;

  ChatPriceTone get tone {
    final r = ratio;
    if (r <= _tooLow || r >= _tooHigh) return ChatPriceTone.off;
    return r <= -_near ? ChatPriceTone.good : ChatPriceTone.near;
  }

  String get label {
    final pct = (ratio.abs() * 100).round();
    final tail = id == pointsId ? ' - lowest \$${short(market)}' : ' (\$${short(market)})';
    return '${pct == 0 ? 'At market' : '$pct% ${ratio < 0 ? 'under' : 'over'} market'}$tail';
  }

  /// Three cheapest, null when none
  static String? lowestListed(List<Object> listings) {
    final cheapest = [
      for (final l in listings)
        if (l is Map && l['price'] is int) (l['price'] as int, l['amount'] is int ? l['amount'] as int : 1),
    ]..sort((a, b) => a.$1 - b.$1);
    if (cheapest.isEmpty) return null;
    final money = NumberFormat.decimalPattern('en_US');
    return cheapest.take(3).map((l) => '\$${money.format(l.$1)} x${l.$2}').join(' - ');
  }

  static String lowestLine(List<Object>? listings) {
    if (listings == null) return "Couldn't load listings";
    final lowest = lowestListed(listings);
    return lowest == null ? 'No listings' : 'Lowest listed: $lowest';
  }

  static String haveLine(int amount, [String unit = '']) {
    final count = NumberFormat.decimalPattern('en_US').format(amount);
    final what = amount == 0 ? (unit.isEmpty ? 'none' : 'no $unit') : '$count $unit'.trim();
    return 'You have $what - only you see this';
  }

  static bool looksLikeOffer(String text) => _intent.hasMatch(text) && _price.hasMatch(text);

  static String short(int value) {
    final (unit, suffix) = value >= 1000000000 ? (1e9, 'b') : (value >= 1000000 ? (1e6, 'm') : (1e3, 'k'));
    final scaled = value / unit;
    final text = scaled >= 100 ? scaled.toStringAsFixed(0) : scaled.toStringAsFixed(1);
    return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}$suffix';
  }

  static List<ChatPriceCheck> find(String text, ItemsModel catalog, [List<ChatItemAlias> aliases = const []]) {
    if (!looksLikeOffer(text)) return const [];
    final quantity = _quantity.allMatches(text).any((m) => (int.tryParse(m[1] ?? m[2] ?? '') ?? 1) > 1);
    if (quantity && !_each.hasMatch(text)) return const [];

    final prices = _prices(text);
    if (prices.isEmpty) return const [];

    final found = _match(text, catalog, aliases, singles: true);

    final used = <int>{};
    final checks = <ChatPriceCheck>[];
    for (final (start, end, item) in found) {
      int? best;
      var bestGap = _reach + 1;
      for (var i = 0; i < prices.length; i++) {
        if (used.contains(i)) continue;
        final gap = prices[i].$1 >= end ? prices[i].$1 - end : start - prices[i].$2;
        if (gap >= 0 && gap < bestGap) {
          best = i;
          bestGap = gap;
        }
      }
      if (best == null) continue;
      used.add(best);
      checks.add(ChatPriceCheck(_idOf(catalog, item), item.type?.name, item.name!, prices[best].$3, item.marketValue!));
      if (checks.length == _maxChips) break;
    }
    return checks;
  }

  static List<(int, int, int)> _prices(String text) {
    final prices = <(int, int, int)>[];
    for (final m in _price.allMatches(text)) {
      final number = double.tryParse(m[2]!.replaceAll(',', ''));
      if (number == null) continue;
      final factor = switch (m[3]?.toLowerCase()) {
        'k' => 1e3,
        'm' => 1e6,
        'b' => 1e9,
        _ => 1.0,
      };
      final value = (number * factor).round();
      if (value > 0 && (m[1] != null || m[3] != null || m[2]!.contains(',') || value >= 1000)) {
        prices.add((m.start, m.end, value));
      }
    }
    return prices;
  }

  static bool mentionsPoints(String text) => looksLikeOffer(text) && _points.hasMatch(text);

  /// Null when the answer is unusable
  static List<Object>? pointsListings(Map<String, dynamic>? json) {
    final raw = json?['pointsmarket'];
    final rows = raw is Map ? raw.values : (raw is List ? raw : null);
    if (rows == null) return null;
    final listings = <Object>[
      for (final l in rows)
        if (l is Map && l['cost'] is int && (l['cost'] as int) > 0)
          {'price': l['cost'], 'amount': l['quantity'] is int ? l['quantity'] : 1},
    ];
    return listings.isEmpty ? null : listings;
  }

  /// Null when the price is unclear
  static ChatPriceCheck? points(String text, List<Object> listings, [List<int> taken = const []]) {
    final mention = _points.firstMatch(text);
    if (mention == null || !looksLikeOffer(text)) return null;
    final prices = _prices(
      text,
    ).where((p) => (p.$2 <= mention.start || p.$1 >= mention.end) && !taken.contains(p.$3)).toList();
    final costs = [
      for (final l in listings)
        if (l is Map && l['price'] is int) l['price'] as int,
    ]..sort();
    if (prices.length != 1 || costs.isEmpty) return null;

    final market = costs.first;
    final price = prices.single.$3;
    var asked = price;
    if (!_each.hasMatch(text) && !text.contains('@')) {
      final factor = switch (mention[2]?.toLowerCase()) {
        'k' => 1e3,
        'm' => 1e6,
        _ => 1.0,
      };
      final amount = double.tryParse((mention[1] ?? '').replaceAll(',', '')) ?? 0;
      final each = amount > 0 ? (price / (amount * factor)).round() : null;
      bool plausible(num v) => v >= market / 2 && v <= market * 2;
      final priceFits = plausible(price);
      if (priceFits == (each != null && plausible(each))) return null;
      if (!priceFits) asked = each!;
    }
    return ChatPriceCheck(pointsId, null, 'Points', asked, market);
  }

  /// One word names only when singles
  static List<(int, int, Item)> _match(
    String text,
    ItemsModel catalog,
    List<ChatItemAlias> aliases, {
    required bool singles,
  }) {
    final lower = ChatItemAliases.spaced(text);
    if (lower.length != text.length) return const [];
    final taken = <(int, int)>[];
    final pairs = {for (var i = 0; i + 1 < lower.length; i++) ChatItemAliases.pair(lower, i)};
    final found = <(int, int, Item)>[];
    final names = _sortedNames(catalog);
    var n = 0;
    for (final (name, pair, item) in names.followedBy(ChatItemAliases.entries(aliases, catalog))) {
      final catalogName = n++ < names.length;
      if (!pairs.contains(pair) || (!singles && catalogName && !name.contains(' '))) continue;
      var at = lower.indexOf(name);
      while (at >= 0) {
        final end = at + name.length;
        final plural =
            end < lower.length &&
            lower.codeUnitAt(end) == 0x73 &&
            (end + 1 == lower.length || !_word(lower.codeUnitAt(end + 1)));
        final clean =
            (at == 0 || !_word(lower.codeUnitAt(at - 1))) &&
            (plural || end == lower.length || !_word(lower.codeUnitAt(end)));
        final stop = plural ? end + 1 : end;
        final hit = clean && !taken.any((t) => at < t.$2 && stop > t.$1);
        if (hit) {
          taken.add((at, stop));
          found.add((at, stop, item));
          if (singles) break;
        }
        at = lower.indexOf(name, hit ? stop : at + 1);
      }
    }
    return found..sort((a, b) => a.$1 - b.$1);
  }

  static int _idOf(ItemsModel catalog, Item item) =>
      int.tryParse(catalog.items!.entries.firstWhere((e) => identical(e.value, item)).key) ?? 0;

  static ItemsModel? get loadedCatalog => _names?.$1;

  /// Longest first, lowercase, once per catalog
  static List<(String, int, Item)> _sortedNames(ItemsModel catalog) {
    final cached = _names;
    if (cached != null && identical(cached.$1, catalog)) return cached.$2;
    final names = [
      for (final i in catalog.items?.values ?? const <Item>[])
        if ((i.name?.length ?? 0) >= 3 && (i.marketValue ?? 0) > 0)
          (ChatItemAliases.spaced(i.name!), ChatItemAliases.pair(ChatItemAliases.spaced(i.name!), 0), i),
    ]..sort((a, b) => b.$1.length - a.$1.length);
    _names = (catalog, names);
    return names;
  }

  static bool _word(int c) => (c >= 0x61 && c <= 0x7a) || (c >= 0x30 && c <= 0x39);
}

class ChatItemRef {
  const ChatItemRef({
    required this.raw,
    required this.id,
    required this.type,
    required this.name,
    required this.market,
  });

  final String raw;
  final int id;
  final String? type;
  final String name;
  final int market;

  /// One word names too
  static Set<int> namedIds(String text, ItemsModel catalog, List<ChatItemAlias> aliases) => {
    for (final (_, _, item) in ChatPriceCheck._match(text, catalog, aliases, singles: true))
      ChatPriceCheck._idOf(catalog, item),
  };

  /// Skips one word catalog names
  static List<Object> split(String text, ItemsModel catalog, List<ChatItemAlias> aliases) {
    final parts = <Object>[];
    var last = 0;
    for (final (start, end, item) in ChatPriceCheck._match(text, catalog, aliases, singles: false)) {
      if (start > last) parts.add(text.substring(last, start));
      parts.add(
        ChatItemRef(
          raw: text.substring(start, end),
          id: ChatPriceCheck._idOf(catalog, item),
          type: item.type?.name,
          name: item.name!,
          market: item.marketValue!,
        ),
      );
      last = end;
    }
    if (last < text.length) parts.add(text.substring(last));
    return parts;
  }
}
