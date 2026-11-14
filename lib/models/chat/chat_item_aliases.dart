import 'dart:convert';

import 'package:torn_pda/models/items_model.dart';

class ChatItemAlias {
  final String alias;
  final String item;

  const ChatItemAlias(this.alias, this.item);

  Map<String, String> toJson() => {'alias': alias, 'item': item};

  @override
  bool operator ==(Object other) => other is ChatItemAlias && other.alias == alias && other.item == item;

  @override
  int get hashCode => Object.hash(alias, item);
}

class ChatItemAliases {
  static const int max = 100;

  static const List<ChatItemAlias> defaults = [
    ChatItemAlias('xan', 'Xanax'),
    ChatItemAlias('xans', 'Xanax'),
    ChatItemAlias('fhc', 'Feathery Hotel Coupon'),
    ChatItemAlias('fhcs', 'Feathery Hotel Coupon'),
    ChatItemAlias('edvd', 'Erotic DVD'),
    ChatItemAlias('edvds', 'Erotic DVD'),
    ChatItemAlias('e-dvd', 'Erotic DVD'),
    ChatItemAlias('e-dvds', 'Erotic DVD'),
    ChatItemAlias('e dvd', 'Erotic DVD'),
    ChatItemAlias('e dvds', 'Erotic DVD'),
    ChatItemAlias('xtc', 'Ecstasy'),
    ChatItemAlias('ecstacy', 'Ecstasy'),
    ChatItemAlias('drugpack', 'Drug Pack'),
    ChatItemAlias('sed', 'Small Explosive Device'),
    ChatItemAlias('seds', 'Small Explosive Device'),
    ChatItemAlias('bct', 'Business Class Ticket'),
    ChatItemAlias('bcts', 'Business Class Ticket'),
    ChatItemAlias('dp', 'Donator Pack'),
    ChatItemAlias('dono pack', 'Donator Pack'),
    ChatItemAlias('ket', 'Ketamine'),
    ChatItemAlias('weed', 'Cannabis'),
    ChatItemAlias('sfak', 'Small First Aid Kit'),
    ChatItemAlias('munster', 'Can of Munster'),
    ChatItemAlias('six pack energy', 'Six-Pack of Energy Drink'),
    ChatItemAlias('six pack energy drink', 'Six-Pack of Energy Drink'),
    ChatItemAlias('6 pack energy', 'Six-Pack of Energy Drink'),
  ];

  static final RegExp _valid = RegExp(r'^[a-z0-9][a-z0-9 \-]{1,23}$');

  /// Lowercase alias, or null
  static String? cleanAlias(String text) {
    final clean = text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return _valid.hasMatch(clean) ? clean : null;
  }

  static ChatItemAlias? _entry(Object? json) {
    if (json is! Map) return null;
    final alias = json['alias'] is String ? cleanAlias(json['alias'] as String) : null;
    final item = json['item'] is String ? (json['item'] as String).trim() : '';
    return alias == null || item.isEmpty || item.length > 80 ? null : ChatItemAlias(alias, item);
  }

  /// Empty storage means the defaults
  static List<ChatItemAlias> decode(String stored) {
    if (stored.isEmpty) return defaults;
    try {
      return [for (final e in jsonDecode(stored) as List) ?_entry(e)];
    } catch (_) {
      return defaults;
    }
  }

  static String encode(List<ChatItemAlias> aliases) => jsonEncode([for (final a in aliases) a.toJson()]);

  static String export(List<ChatItemAlias> aliases) => const JsonEncoder.withIndent('  ').convert({
    'itemNicknames': [for (final a in aliases) a.toJson()],
  });

  /// Entries read and skipped, or null
  static (List<ChatItemAlias>, int)? parse(String text) {
    try {
      var json = jsonDecode(text.trim());
      if (json is Map) json = json['itemNicknames'];
      if (json is! List) return null;
      final found = [for (final e in json) ?_entry(e)];
      return found.isEmpty ? null : (found, json.length - found.length);
    } catch (_) {
      return null;
    }
  }

  /// Existing nicknames win on import
  static List<ChatItemAlias> merge(List<ChatItemAlias> current, List<ChatItemAlias> incoming) {
    final seen = {for (final a in current) a.alias};
    final merged = [...current];
    for (final a in incoming) {
      if (merged.length >= max) break;
      if (seen.add(a.alias)) merged.add(a);
    }
    return merged;
  }

  /// Item name for an exact nickname
  static String? itemFor(String query, List<ChatItemAlias> aliases) {
    final term = query.trim().toLowerCase();
    for (final a in aliases) {
      if (a.alias == term) return a.item;
    }
    return null;
  }

  static int pair(String s, int at) => s.codeUnitAt(at) << 16 | s.codeUnitAt(at + 1);

  /// Lowercase, a hyphen counts as a space
  static String spaced(String text) => text.toLowerCase().replaceAll('-', ' ');

  static (ItemsModel, List<ChatItemAlias>, List<(String, int, Item)>)? _entries;

  /// Longest first
  static List<(String, int, Item)> entries(List<ChatItemAlias> aliases, ItemsModel catalog) {
    if (aliases.isEmpty) return const [];
    final cached = _entries;
    if (cached != null && identical(cached.$1, catalog) && identical(cached.$2, aliases)) return cached.$3;
    final byName = {
      for (final i in catalog.items?.values ?? const <Item>[])
        if ((i.marketValue ?? 0) > 0 && i.name != null) spaced(i.name!): i,
    };
    final found = [
      for (final a in aliases)
        if (byName[spaced(a.item)] case final item?) (spaced(a.alias), pair(spaced(a.alias), 0), item),
    ]..sort((a, b) => b.$1.length - a.$1.length);
    _entries = (catalog, aliases, found);
    return found;
  }
}
