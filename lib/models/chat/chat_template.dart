import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chat/chat_item_price.dart';
import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/models/chat/chat_time.dart';

class ChatSlot {
  const ChatSlot(this.key, this.label, this.help);

  final String key;
  final String label;
  final String help;

  String get tag => '{$key}';
}

/// Quick replies with {slots} filled in
class ChatTemplate {
  ChatTemplate._();

  static const slots = [
    ChatSlot('name', 'Name', 'Name of the player in this private chat'),
    ChatSlot('me', 'Me', 'Your name'),
    ChatSlot('item', 'Item', 'Item from the last price check'),
    ChatSlot('price', 'Price', 'Market value of that item'),
    ChatSlot('landing', 'Landing', 'Time left until you land'),
    ChatSlot('destination', 'Destination', 'Where you are flying to or staying'),
    ChatSlot('hospital', 'Hospital', 'Time left in hospital'),
    ChatSlot('jail', 'Jail', 'Time left in jail'),
    ChatSlot('energy', 'Energy', 'Your energy, like 95/150'),
    ChatSlot('nerve', 'Nerve', 'Your nerve, like 40/55'),
    ChatSlot('life', 'Life', 'Your life, like 900/1200'),
    ChatSlot('chain', 'Chain', 'Your chain hits and time left'),
    ChatSlot('time', 'Time', 'The time now, in TCT'),
    ChatSlot('bazaar', 'Bazaar', 'Link to your bazaar'),
    ChatSlot('trade', 'Trade', 'Link to start a trade with you'),
    ChatSlot('profile', 'Profile', 'Link to your profile'),
    ChatSlot('faction', 'Faction', 'Name of your faction'),
  ];

  static const _needBars = {'landing', 'destination', 'hospital', 'jail', 'energy', 'nerve', 'life'};

  static final RegExp _slot = RegExp(r'\{(\w+)\}');

  /// Last item from the price tool
  static ChatItemPrice? lastItem;

  static int percent(int base, int total) => (base * (100 + total) + 50) ~/ 100;

  static List<String> used(String text) => [
    for (final m in _slot.allMatches(text))
      if (slots.any((s) => s.key == m.group(1))) m.group(1)!,
  ];

  static bool needsBars(String text) => used(text).any(_needBars.contains);

  static Map<String, String> values({
    required int now,
    BarsStatusCooldownsModel? bars,
    int chainCurrent = 0,
    int chainSeconds = 0,
    String? name,
    String? me,
    ChatItemPrice? item,
    String? faction,
    String? bazaar,
    String? trade,
    String? profile,
  }) {
    final age = now - (bars?.serverTime ?? now);
    final fresh = bars != null && age <= ChatStatus.barsMaxAge.inSeconds;
    final status = bars?.status;
    final travel = bars?.travel;
    final destination = travel?.destination ?? '';
    final landsIn = (travel?.timestamp ?? 0) - now;
    final until = status?.until ?? 0;

    String? bar(PersonalBars? b) =>
        fresh && b?.current != null && b?.maximum != null ? '${b!.current}/${b.maximum}' : null;

    final found = <String, String?>{
      'name': name,
      'me': me,
      'item': item?.name,
      'price': item?.price,
      'landing': status?.state == 'Traveling' && landsIn > 0 ? ChatStatus.duration(landsIn) : null,
      'destination': status?.state == 'Traveling' || status?.state == 'Abroad' ? destination : null,
      'hospital': status?.state == 'Hospital' && until > now ? ChatStatus.duration(until - now) : null,
      'jail': status?.state == 'Jail' && until > now ? ChatStatus.duration(until - now) : null,
      'energy': bar(bars?.energy),
      'nerve': bar(bars?.nerve),
      'life': bar(bars?.life),
      'chain': chainCurrent > 0 && chainSeconds > 0 ? '$chainCurrent hits, ${ChatStatus.duration(chainSeconds)}' : null,
      'time': ChatTimeRef.insertText(DateTime.fromMillisecondsSinceEpoch(now * 1000)),
      'bazaar': bazaar,
      'trade': trade,
      'profile': profile,
      'faction': faction ?? bars?.faction?.factionName,
    };
    return {
      for (final e in found.entries)
        if (e.value != null && e.value!.trim().isNotEmpty) e.key: e.value!.trim(),
    };
  }

  /// Missing price asks for the item too
  static List<String> toAsk(String text, Map<String, String> values) {
    final missing = fill(text, values).missing;
    final keys = used(text);
    return [
      for (final slot in slots)
        if (missing.contains(slot.key) ||
            (slot.key == 'item' && missing.contains('price') && keys.contains('item')))
          slot.key,
    ];
  }

  /// Unfilled slots stay and go in missing
  static ({String text, List<String> missing}) fill(String text, Map<String, String> values) {
    final missing = <String>[];
    final filled = text.replaceAllMapped(_slot, (m) {
      final key = m.group(1)!;
      if (!slots.any((s) => s.key == key)) return m.group(0)!;
      final value = values[key];
      if (value != null) return value;
      if (!missing.contains(key)) missing.add(key);
      return m.group(0)!;
    });
    return (text: filled, missing: missing);
  }
}
