import 'dart:convert';

import 'package:torn_pda/models/profile/other_profile_model/other_profile_pda.dart';

class ChatBazaar {
  const ChatBazaar(this.open, this.items, {this.listed = true});

  final bool open;
  final List<BazaarItem> items;

  /// False when only the state is known
  final bool listed;

  /// Null without a bazaar in the profile
  static ChatBazaar? parse(Map<String, dynamic> json) {
    final node = json['bazaar'];
    final exists = json['bazaar_exists'] ?? (node is Map ? node['exists'] : null);
    if (exists == false) return null;
    final open = json['bazaar_is_open'] ?? (node is Map ? node['is_open'] : null);
    if (open == false || open == 0) return const ChatBazaar(false, []);
    final rows = node is Map ? node['items'] : node;
    // Torn never lists another player's items
    if (rows is! List || rows.isEmpty) {
      return open == true || open == 1 ? const ChatBazaar(true, [], listed: false) : null;
    }
    final items = <BazaarItem>[];
    for (final row in rows) {
      if (row is! Map) continue;
      try {
        items.add(BazaarItem.fromJson(Map<String, dynamic>.from(row)));
      } catch (_) {}
    }
    return ChatBazaar(true, items);
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
