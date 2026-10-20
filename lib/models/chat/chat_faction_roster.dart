import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';

class ChatEnemyChain {
  const ChatEnemyChain({required this.hits, required this.breaksAt});

  final int hits;
  final DateTime breaksAt;
}

ChatEnemyChain? chatEnemyChain(FactionOngoingChain chain, DateTime now) {
  if (chain.current <= 0 || chain.timeout <= 0) return null;
  return ChatEnemyChain(
    hits: chain.current,
    breaksAt: now.add(Duration(seconds: chain.timeout)),
  );
}

String? chatEnemyChainLine(ChatEnemyChain? chain, DateTime now) {
  final left = chain?.breaksAt.difference(now);
  if (left == null || left.inSeconds <= 0) return null;
  return 'Enemy chain ${chain!.hits} - ${chatClock(left)} left';
}

String? chatRosterLine(List<FactionMember> members) {
  if (members.isEmpty) return null;
  final online = members.where((m) => m.lastAction.status == 'Online').length;
  final hospital = members.where((m) => m.status.state == 'Hospital').length;
  final abroad = members.where((m) => m.status.state == 'Abroad' || m.status.state == 'Traveling').length;
  return ['$online online', if (hospital > 0) '$hospital in hospital', if (abroad > 0) '$abroad abroad'].join(' - ');
}

List<FactionMember> chatRosterByAction(List<FactionMember> members) =>
    [...members]..sort((a, b) => b.lastAction.timestamp.compareTo(a.lastAction.timestamp));
