import 'package:html/parser.dart' as html;
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_bazaar.dart';
import 'package:torn_pda/models/chat/chat_chain_report.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_html_text.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_player_card.dart';
import 'package:torn_pda/models/chat/chat_price_check.dart';
import 'package:torn_pda/models/items_model.dart';

class ChatBounty {
  final int total;
  final int count;

  const ChatBounty(this.total, this.count);

  static ChatBounty? parse(Map<String, dynamic> json) {
    final list = json['bounties'];
    if (list is! List) return null;
    var total = 0;
    var count = 0;
    for (final bounty in list) {
      final reward = bounty is Map ? bounty['reward'] : null;
      if (reward is! num || reward <= 0) continue;
      total += reward.toInt();
      count++;
    }
    return count == 0 ? null : ChatBounty(total, count);
  }

  String get text => 'Bounty ${ChatMoneyRef.format(total)}${count > 1 ? ' ($count listed)' : ''}';
}

class ChatLinkInfo {
  final String title;
  final String? detail;
  final ChatPresence? presence;
  final String? imageUrl;
  final List<String> extra;

  final ChatStatusClock? clock;
  final String? lead;

  const ChatLinkInfo(
    this.title, {
    this.detail,
    this.presence,
    this.imageUrl,
    this.extra = const [],
    this.clock,
    this.lead,
    this.settled = false,
    this.bazaar,
    this.kicker,
  });

  /// Overrides the label above the title
  final String? kicker;

  final ChatBazaar? bazaar;

  /// Won't change any more
  final bool settled;

  String? detailAt(DateTime now) {
    if (clock == null) return detail;
    final text = [?lead, ?clock!.at(now)].join(' - ');
    return text.isEmpty ? null : text;
  }

  static ChatLinkInfo? player(ChatLinkKind kind, Map<String, dynamic> json, [ChatBounty? bounty]) {
    // v1 sends it flat
    final profile = json['profile'] is Map ? json['profile'] as Map : json;
    final name = profile['name'];
    if (name is! String || name.isEmpty) return null;
    final id = profile['id'] ?? profile['player_id'];
    final level = profile['level'];
    final status = profile['status'] is Map ? profile['status']['description'] : null;
    final presence = ChatPresence.parse(profile['last_action'] is Map ? profile['last_action']['status'] : null);
    final title = id == null ? name : '$name [$id]';
    if (kind == ChatLinkKind.bazaar) {
      final parsed = ChatBazaar.parse(json);
      final count = parsed?.items.length;
      final detail = switch (count) {
        null => null,
        0 => parsed!.open ? 'Empty' : 'Closed',
        1 => '1 item',
        _ => '$count items',
      };
      return ChatLinkInfo('Bazaar of $title', detail: detail, presence: presence, bazaar: parsed);
    }
    final parts = [if (level != null) 'Lvl $level', if (status is String && status.isNotEmpty) status];
    return ChatLinkInfo(
      kind == ChatLinkKind.attack ? 'Attack $title' : title,
      detail: parts.isEmpty ? null : parts.join(' - '),
      presence: presence,
      extra: [if (bounty != null) bounty.text],
      clock: ChatStatusClock.parse(profile['status'] is Map ? profile['status'] as Map : null),
      lead: level == null ? null : 'Lvl $level',
    );
  }

  static ChatLinkInfo? faction(Map<String, dynamic> json, [DateTime? now]) {
    final basic = json['basic'];
    if (basic is! Map) return null;
    final name = basic['name'];
    if (name is! String || name.isEmpty) return null;
    final tag = basic['tag'];
    final members = basic['members'];
    final capacity = basic['capacity'];
    final respect = basic['respect'];
    final rank = basic['rank'] is Map ? basic['rank']['name'] : null;
    final detail = [
      if (members is int) capacity is int && capacity > 0 ? '$members/$capacity members' : '$members members',
      if (respect is int) 'Respect ${respect >= 1000 ? ChatPriceCheck.short(respect) : respect}',
      if (rank is String && rank.isNotEmpty) rank,
    ];

    final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final ranked = json['wars'] is Map ? json['wars']['ranked'] : null;
    final List<Map> sides = ranked is Map && ranked['factions'] is List
        ? (ranked['factions'] as List).whereType<Map>().toList()
        : [];
    final start = ranked is Map ? ranked['start'] : null;
    final end = ranked is Map ? ranked['end'] : null;
    final live = start is int && start <= seconds && (end is! int || end == 0 || end > seconds);
    String? war;
    if (live && sides.length == 2) {
      final mine = sides.firstWhere((f) => f['id'] == basic['id'], orElse: () => sides.first);
      final other = sides.firstWhere((f) => f != mine);
      if (other['name'] is String) {
        String score(Map side) => chatCount(side['score'] is num ? (side['score'] as num).toInt() : 0);
        war = 'War vs ${other['name']}: ${score(mine)} - ${score(other)}';
      }
    }
    final chain = json['chain'] is Map ? json['chain']['current'] : null;
    return ChatLinkInfo(
      tag is String && tag.isNotEmpty ? '$name [$tag]' : name,
      detail: detail.isEmpty ? null : detail.join(' - '),
      extra: [?war, if (chain is int && chain > 0) 'Chain $chain'],
    );
  }

  static ChatLinkInfo? company(Map<String, dynamic> json) {
    final profile = json['profile'];
    if (profile is! Map) return null;
    final name = profile['name'];
    if (name is! String || name.isEmpty) return null;
    final stars = profile['rating'];
    final type = profile['type'] is Map ? profile['type']['name'] : null;
    final staff = profile['employees'] is Map ? profile['employees'] : const {};
    final director = profile['director'] is Map ? profile['director'] : const {};
    final typeText = [if (stars is int && stars > 0) '$stars*', if (type is String && type.isNotEmpty) type].join(' ');
    final detail = [
      if (typeText.isNotEmpty) typeText,
      if (staff['hired'] is int && staff['capacity'] is int) '${staff['hired']}/${staff['capacity']} staff',
    ];
    final boss = director['name'];
    return ChatLinkInfo(
      name,
      detail: detail.isEmpty ? null : detail.join(' - '),
      extra: [
        if (boss is String && boss.isNotEmpty) 'Director $boss${director['id'] is int ? ' [${director['id']}]' : ''}',
      ],
    );
  }

  static ChatLinkInfo? item(ChatLink link, ItemsModel catalog) {
    final items = catalog.items;
    if (items == null) return null;
    Item? found = link.id == null ? null : items['${link.id}'];
    if (found == null && link.id == null) {
      final name = link.title.toLowerCase();
      found = items.values.where((i) => i.name?.toLowerCase() == name).firstOrNull;
    }
    final name = found?.name;
    if (found == null || name == null || name.isEmpty) return null;
    final value = found.marketValue;
    return ChatLinkInfo(
      name,
      detail: value == null || value <= 0 ? 'Item market' : 'Market \$${chatCount(value)}',
    );
  }

  static ChatLinkInfo? forum(ForumThreadExtended thread, [String? section]) {
    final title = chatHtmlText(thread.title).trim();
    if (title.isEmpty) return null;
    final author = thread.author.username;
    final posts = thread.posts == 1 ? '1 post' : '${chatCount(thread.posts)} posts';
    return ChatLinkInfo(title, detail: author.isEmpty ? posts : 'by $author - $posts', kicker: _forumKicker(section));
  }

  static ChatLinkInfo? forumSection(ForumCategoriesResponse$Categories$Item section) {
    final name = chatHtmlText(section.title).trim();
    if (name.isEmpty) return null;
    return ChatLinkInfo(name, detail: section.threads == 1 ? '1 thread' : '${chatCount(section.threads)} threads');
  }

  static ChatLinkInfo? forumPlaced(ChatLink link, String? section) =>
      section == null ? null : ChatLinkInfo(link.title, kicker: _forumKicker(section));

  static String? _forumKicker(String? section) {
    final name = section == null ? '' : chatHtmlText(section).trim();
    return name.isEmpty ? null : 'Torn forum - $name';
  }

  static ChatLinkInfo? attackLog(Map<String, dynamic> json) {
    final log = json['attacklog'];
    if (log is! Map) return null;
    final actions = log['log'] is List ? (log['log'] as List).whereType<Map>().toList() : <Map>[];
    final summary = log['summary'] is List ? (log['summary'] as List).whereType<Map>().toList() : <Map>[];
    if (actions.isEmpty && summary.isEmpty) return null;
    int total(String key) => summary.fold(0, (sum, s) => sum + (s[key] is int ? s[key] as int : 0));
    num at(Map a) => a['timestamp'] is num ? a['timestamp'] as num : 0;
    final last = actions.isEmpty ? null : actions.reduce((a, b) => at(b) > at(a) ? b : a);
    String who(Object? p) =>
        p is Map && p['name'] is String ? '${p['name']}${p['id'] is int ? ' [${p['id']}]' : ''}' : 'Someone';
    const verbs = {'hosp': 'hospitalized', 'mug': 'mugged', 'leave': 'left', 'lost': 'lost to'};
    final verb = verbs[last?['action']];
    final text = last?['text'];
    final hits = total('hits');
    return ChatLinkInfo(
      verb != null
          ? '${who(last!['attacker'])} $verb ${who(last['defender'])}'
          : text is String && text.isNotEmpty
          ? text
          : 'Attack log',
      detail: summary.isEmpty
          ? null
          : '${hits == 1 ? '1 hit' : '$hits hits'}, ${total('misses')} missed - ${chatCount(total('damage'))} dmg',
      settled: true,
    );
  }

  static ChatLinkInfo chainReport(ChatChainReport report, [DateTime? now]) {
    final attackers = report.attackers.length;
    final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final detail = [
      if (attackers > 0) attackers == 1 ? '1 attacker' : '$attackers attackers',
      if (report.best > 0) 'best hit ${report.best.toStringAsFixed(1)}',
    ];
    return ChatLinkInfo(
      [
        'Chain ${report.chain}',
        '${chatCount(report.respect.round())} respect',
        if (report.end > report.start) chatSpan(report.length),
      ].join(' - '),
      detail: detail.isEmpty ? null : detail.join(' - '),
      settled: report.end > 0 && seconds - report.end > 600,
    );
  }

  static ChatLinkInfo? warReport(Map<String, dynamic> json) {
    final report = json['rankedwarreport'];
    if (report is! Map) return null;
    final sides = report['factions'] is List ? (report['factions'] as List).whereType<Map>().toList() : <Map>[];
    if (sides.length != 2 || sides.any((f) => f['name'] is! String)) return null;
    String score(Map f) => chatCount(f['score'] is num ? (f['score'] as num).toInt() : 0);
    final winner = sides.where((f) => f['id'] == report['winner']).firstOrNull;
    final rank = winner?['rank'];
    final (before, after) = rank is Map ? (rank['before'], rank['after']) : (null, null);
    final detail = [
      if (winner != null) '${winner['name']} won${report['forfeit'] == true ? ' by forfeit' : ''}',
      if (before is String && after is String && before != after) '$before to $after',
    ];
    return ChatLinkInfo(
      '${sides[0]['name']} ${score(sides[0])} : ${score(sides[1])} ${sides[1]['name']}',
      detail: detail.isEmpty ? null : detail.join(' - '),
      settled: report['end'] is int && (report['end'] as int) > 0,
    );
  }

  static ChatLinkInfo? page(String source, Uri base) {
    final doc = html.parse(source);
    String? meta(String key) {
      final tag = doc.querySelector('meta[property="$key"]') ?? doc.querySelector('meta[name="$key"]');
      final content = tag?.attributes['content']?.trim();
      return content == null || content.isEmpty ? null : content;
    }

    final title = meta('og:title') ?? meta('twitter:title') ?? doc.querySelector('title')?.text.trim();
    if (title == null || title.isEmpty) return null;
    final image = meta('og:image') ?? meta('twitter:image');
    final imageUri = image == null ? null : Uri.tryParse(image);
    final resolved = imageUri == null ? null : base.resolveUri(imageUri);
    return ChatLinkInfo(
      title.length > 150 ? '${title.substring(0, 147)}…' : title,
      detail: base.host,
      imageUrl: resolved != null && (resolved.scheme == 'https' || resolved.scheme == 'http') ? '$resolved' : null,
    );
  }

  static ChatLinkInfo video(String id, Map<String, dynamic>? json) {
    final title = json?['title'] is String ? (json!['title'] as String).trim() : '';
    final author = json?['author_name'] is String ? (json!['author_name'] as String).trim() : '';
    return ChatLinkInfo(
      title.isEmpty ? 'YouTube video' : (title.length > 150 ? '${title.substring(0, 147)}…' : title),
      detail: author.isEmpty ? null : author,
      imageUrl: 'https://img.youtube.com/vi/$id/hqdefault.jpg',
    );
  }
}
