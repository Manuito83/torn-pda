import 'dart:convert';

import 'package:torn_pda/models/chat/chat_price_check.dart';
import 'package:torn_pda/models/chat/chat_share_out.dart';
import 'package:torn_pda/models/profile/other_profile_model/other_profile_pda.dart';

class ChatBazaar {
  const ChatBazaar(this.open, this.items);

  final bool open;
  final List<BazaarItem> items;

  static const int _maxNamed = 3;

  /// Null without a bazaar in the profile
  static ChatBazaar? parse(Map<String, dynamic> json) {
    final open = json['bazaar_is_open'];
    if (open == false || open == 0) return const ChatBazaar(false, []);
    final rows = json['bazaar'];
    if (rows is! List) return null;
    final items = <BazaarItem>[];
    for (final row in rows) {
      if (row is! Map) continue;
      try {
        items.add(BazaarItem.fromJson(Map<String, dynamic>.from(row)));
      } catch (_) {}
    }
    return ChatBazaar(true, items);
  }

  /// Null without a market value
  static double? ratio(BazaarItem item) {
    final market = item.marketPrice ?? 0;
    final price = item.price ?? 0;
    return market > 0 && price > 0 ? (price - market) / market : null;
  }

  static ChatPriceTone? tone(BazaarItem item) {
    final r = ratio(item);
    if (r == null) return null;
    final tone = ChatPriceCheck(item.id ?? 0, item.type, item.name ?? '', item.price!, item.marketPrice!).tone;
    // Cheap is never suspect here
    return r < 0 && tone == ChatPriceTone.off ? ChatPriceTone.good : tone;
  }

  static String vs(double ratio) {
    final pct = (ratio.abs() * 100).round();
    return pct == 0 ? 'at market' : '$pct% ${ratio < 0 ? 'under' : 'over'}';
  }

  double? get median {
    final ratios = [for (final item in items) ?ratio(item)]..sort();
    if (ratios.isEmpty) return null;
    final mid = ratios.length ~/ 2;
    return ratios.length.isOdd ? ratios[mid] : (ratios[mid - 1] + ratios[mid]) / 2;
  }

  String get summary {
    if (!open) return 'Closed';
    if (items.isEmpty) return 'Empty';
    final count = items.length == 1 ? '1 item' : '${items.length} items';
    final typical = median;
    if (typical == null) return count;
    final text = vs(typical);
    return '$count - typically ${text == 'at market' ? text : '$text market'}';
  }

  /// Items the message names, at most three
  List<BazaarItem> named(Set<int> ids) => items.where((i) => ids.contains(i.id)).take(_maxNamed).toList();

  /// Named first, then bazaar order
  List<BazaarItem> ordered(Set<int> ids) => [
    ...items.where((i) => ids.contains(i.id)),
    ...items.where((i) => !ids.contains(i.id)),
  ];

  static String line(BazaarItem item) {
    final r = ratio(item);
    return '${item.name} x${item.quantity} ${ChatShareOut.money(item.price ?? 0)}${r == null ? '' : ' - ${vs(r)}'}';
  }

  /// Fills the bazaar page search box
  static String fillScript(String name) =>
      '(function(){var n=${jsonEncode(name)},t=0;(function go(){'
      'if(document.querySelector(\'img[src*="/images/items/"]\')){'
      'var b=[...document.querySelectorAll(\'input[placeholder="search..."]\')].pop();'
      'if(b){Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,"value").set.call(b,n);'
      'b.dispatchEvent(new Event("input",{bubbles:true}));return}}'
      'if(++t<40)setTimeout(go,500)})()})()';
}
