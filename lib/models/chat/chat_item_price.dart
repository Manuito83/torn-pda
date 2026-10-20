import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/models/items_model.dart';

class ChatItemPrice {
  final String id;
  final String name;
  final int? marketValue;

  const ChatItemPrice(this.id, this.name, this.marketValue);

  static const int _limit = 12;
  static final NumberFormat _money = NumberFormat.decimalPattern('en_US');

  static List<ChatItemPrice> search(ItemsModel catalog, String query, [List<ChatItemAlias> aliases = const []]) {
    final term = (ChatItemAliases.itemFor(query, aliases) ?? query).trim().toLowerCase();
    if (term.length < 2) return const [];
    final found = <(int, ChatItemPrice)>[];
    for (final e in catalog.items?.entries ?? const <MapEntry<String, Item>>[]) {
      final name = e.value.name;
      if (name == null || name.isEmpty) continue;
      final lower = name.toLowerCase();
      final at = lower.indexOf(term);
      if (at < 0) continue;
      final rank = lower == term ? 0 : (at == 0 ? 1 : (lower.contains(' $term') ? 2 : 3));
      found.add((rank, ChatItemPrice(e.key, name, e.value.marketValue)));
    }
    found.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2.name.compareTo(b.$2.name));
    return [for (final f in found.take(_limit)) f.$2];
  }

  String get price {
    final value = marketValue;
    return value == null || value <= 0 ? '' : '\$${_money.format(value)}';
  }

  String get marketUrl => 'https://www.torn.com/page.php?sid=ItemMarket#/market/view=search&itemID=$id';

  String text({bool link = false}) => [name, if (price.isNotEmpty) price, if (link) marketUrl].join(' ');
}
