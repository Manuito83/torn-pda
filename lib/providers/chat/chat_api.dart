import 'package:torn_pda/models/chat/chat_faction_roster.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/models/company/employees_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

abstract class ChatApi {
  Future<ChatLastAction?> lastAction(int userId);

  Future<List<(ChatUser, ChatLastAction)>?> roster(String roomId);

  Future<List<(ChatUser, ChatLastAction)>?> friends();
}

class TornChatApi implements ChatApi {
  TornChatApi(this._prefs);

  final ChatPrefs _prefs;

  @override
  Future<ChatLastAction?> lastAction(int userId) async {
    // Under the 30 s poll
    final card = await ChatPlayerCards.load(userId, maxAge: const Duration(seconds: 25));
    final presence = card?.presence;
    return presence == null ? null : ChatLastAction(presence, card!.lastAction);
  }

  @override
  Future<List<(ChatUser, ChatLastAction)>?> roster(String roomId) async {
    if (_prefs.isFactionRoom(roomId)) {
      final roster = ChatFactionRoster.shared;
      final members = roster.recentMembers() ?? await roster.loadMembers();
      if (members == null) return null;
      return [
        for (final m in members)
          if (_parse(m.lastAction.status, m.lastAction.timestamp) case final action?)
            (ChatUser(id: m.id, name: m.name, leader: chatIsLead(m.position)), action),
      ];
    }
    if (roomId == 'company') {
      final company = await ApiCallsV1.getCompanyEmployees();
      if (company is! CompanyEmployees) return null;
      return [
        for (final e in company.companyEmployees?.entries ?? const <MapEntry<String, CompanyEmployee>>[])
          if ((int.tryParse(e.key), e.value.name, _parse(e.value.lastAction?.status, e.value.lastAction?.timestamp))
              case (final int id, final String name, final ChatLastAction action))
            (
              ChatUser(
                id: id,
                name: name,
                leader: chatIsLead(e.value.position),
                playerStatus: ChatPlayerStatus.from(
                  e.value.status?.state,
                  e.value.status?.description,
                  e.value.status?.until,
                ),
              ),
              action,
            ),
      ];
    }
    return null;
  }

  static const int _maxFriendPages = 3;

  @override
  Future<List<(ChatUser, ChatLastAction)>?> friends() async {
    final friends = <(ChatUser, ChatLastAction)>[];
    for (var page = 0; page < _maxFriendPages; page++) {
      final response = await ApiCallsV2.getUserFriendsList_v2(offset: page * 50);
      if (response == null) return page == 0 ? null : friends;
      for (final f in response.list) {
        final action = _parse(f.lastAction.status, f.lastAction.timestamp);
        if (action != null) friends.add((ChatUser(id: f.id, name: f.name), action));
      }
      if (response.list.length < 50 || response.metadata.links.next == null) break;
    }
    return friends;
  }

  static ChatLastAction? _parse(String? status, int? timestamp) {
    final presence = ChatPresence.parse(status);
    if (presence == null) return null;
    return ChatLastAction(
      presence,
      timestamp == null || timestamp <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    );
  }
}
