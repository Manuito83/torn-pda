import 'package:torn_pda/models/chat/chat_alerts.dart';

/// Hide wins over show
class ChatRoomFilter {
  ChatRoomFilter({List<String> show = const [], List<String> hide = const []})
    : show = List.unmodifiable(show),
      hide = List.unmodifiable(hide),
      _show = ChatAlertMatcher(keywords: show),
      _hide = ChatAlertMatcher(keywords: hide);

  static final ChatRoomFilter none = ChatRoomFilter();

  final List<String> show;
  final List<String> hide;
  final ChatAlertMatcher _show;
  final ChatAlertMatcher _hide;

  bool get isActive => show.isNotEmpty || hide.isNotEmpty;

  bool hides(String content) {
    if (_hide.match(content) != null) return true;
    return !_show.isEmpty && _show.match(content) == null;
  }
}
