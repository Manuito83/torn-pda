// Dart imports:
import 'dart:convert';

class RemoteAnnouncement {
  final String id;
  final String title;
  final String body;
  final String? url;
  final String? button;
  final Set<String> platforms;
  final int? minBuild;
  final int? maxBuild;
  final DateTime? until;
  final Set<int> players;

  RemoteAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.url,
    this.button,
    this.platforms = const {},
    this.minBuild,
    this.maxBuild,
    this.until,
    this.players = const {},
  });

  /// Null when empty or invalid
  static RemoteAnnouncement? parse(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;

      final id = json['id'];
      final title = json['title'];
      final body = json['body'];
      if (id is! String || id.isEmpty || title is! String || body is! String) return null;

      final url = json['url'];
      final button = json['button'];
      final platforms = json['platforms'];
      final players = json['players'];
      final minBuild = json['minBuild'];
      final maxBuild = json['maxBuild'];
      final until = json['until'];

      if (url != null && (url is! String || !const ['http', 'https'].contains(Uri.tryParse(url)?.scheme))) return null;
      if (button != null && button is! String) return null;
      if (platforms != null && platforms is! List) return null;
      if (players != null && (players is! List || players.any((p) => int.tryParse('$p') == null))) return null;
      if (minBuild != null && minBuild is! int) return null;
      if (maxBuild != null && maxBuild is! int) return null;
      final untilDate = until == null ? null : DateTime.tryParse('$until');
      if (until != null && untilDate == null) return null;

      return RemoteAnnouncement(
        id: id,
        title: title,
        body: body,
        url: url,
        button: button,
        platforms: {for (final p in platforms ?? []) '$p'.toLowerCase()},
        minBuild: minBuild,
        maxBuild: maxBuild,
        until: untilDate,
        players: {for (final p in players ?? []) int.parse('$p')},
      );
    } catch (_) {
      return null;
    }
  }

  /// [platform] is "android" or "ios"
  bool appliesTo({
    required int playerId,
    required String platform,
    required int build,
    required DateTime now,
    required String seenId,
  }) {
    if (id == seenId) return false;
    if (platforms.isNotEmpty && !platforms.contains(platform)) return false;
    if (minBuild != null && build < minBuild!) return false;
    if (maxBuild != null && build > maxBuild!) return false;
    if (until != null && now.isAfter(until!)) return false;
    if (players.isNotEmpty && !players.contains(playerId)) return false;
    return true;
  }
}
