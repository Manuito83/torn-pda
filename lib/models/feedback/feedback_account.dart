class FeedbackAccount {
  const FeedbackAccount({
    this.known = false,
    this.canWrite = false,
    this.reason,
    this.playerId,
    this.playerName,
    this.isModerator = false,
    this.modUnlockedUntil,
    this.votedIds = const {},
    this.subscribedIds = const {},
    this.lockedIds = const {},
    this.subscribedToAll = false,
  });

  // False until the server answers
  final bool known;
  final bool canWrite;
  final String? reason;
  final int? playerId;
  final String? playerName;
  final bool isModerator;
  final DateTime? modUnlockedUntil;
  final Set<String> votedIds;
  final Set<String> subscribedIds;
  final Set<String> lockedIds;
  final bool subscribedToAll;

  bool isUnlocked(DateTime now) => isModerator && modUnlockedUntil != null && modUnlockedUntil!.isAfter(now);

  FeedbackAccount copyWith({
    Set<String>? votedIds,
    Set<String>? subscribedIds,
    bool? subscribedToAll,
    DateTime? modUnlockedUntil,
    bool clearUnlock = false,
  }) {
    return FeedbackAccount(
      known: known,
      canWrite: canWrite,
      reason: reason,
      playerId: playerId,
      playerName: playerName,
      isModerator: isModerator,
      modUnlockedUntil: clearUnlock ? null : modUnlockedUntil ?? this.modUnlockedUntil,
      votedIds: votedIds ?? this.votedIds,
      subscribedIds: subscribedIds ?? this.subscribedIds,
      lockedIds: lockedIds,
      subscribedToAll: subscribedToAll ?? this.subscribedToAll,
    );
  }

  // Asked ids replaced, others kept
  FeedbackAccount fromState(Map<String, dynamic> map, List<String> asked) {
    Set<String> ids(String key) => {if (map[key] is List) ...(map[key] as List).map((id) => id.toString())};
    Set<String> merged(Set<String> before, Set<String> answer) => {
      ...before.where((id) => !asked.contains(id)),
      ...answer,
    };
    final until = map['modUnlockedUntil'];
    return FeedbackAccount(
      known: true,
      canWrite: map['canWrite'] == true,
      reason: map['reason'] is String ? map['reason'] as String : null,
      playerId: map['playerId'] is num ? (map['playerId'] as num).toInt() : null,
      playerName: map['playerName'] as String?,
      isModerator: map['isModerator'] == true,
      modUnlockedUntil: until is num ? DateTime.fromMillisecondsSinceEpoch(until.toInt()) : null,
      votedIds: merged(votedIds, ids('votedIds')),
      subscribedIds: merged(subscribedIds, ids('subscribedIds')),
      lockedIds: merged(lockedIds, ids('lockedIds')),
      subscribedToAll: map['subscribedToAll'] == true,
    );
  }
}

String feedbackReasonText(String? reason) {
  switch (reason) {
    case 'not_verified':
      return 'Player not verified';
    case 'no_key':
      return 'No API key';
    case 'no_player':
      return 'No player found';
    case 'verify_busy':
      return 'Verification busy';
    case 'rate_limited':
    case 'resource-exhausted':
      return 'Too many requests';
    case 'pin_required':
      return 'PIN required';
    case 'pin_wrong':
      return 'Wrong PIN';
    case 'pin_locked':
      return 'PIN locked';
    case 'has_public_duplicates':
      return 'Has public duplicates';
    case 'invalid-argument':
      return 'Invalid input';
    case 'not-found':
      return 'Not found';
    case 'unauthenticated':
      return 'Not signed in';
    case 'deadline-exceeded':
    case 'timeout':
      return 'Timed out';
    case 'unavailable':
    case 'torn_unavailable':
      return 'Service unavailable';
    case null:
    case '':
      return 'Something went wrong';
    default:
      // Moderator reasons shown as sent
      return reason.startsWith('mod_') ? _spaced(reason) : 'Something went wrong';
  }
}

String _spaced(String reason) {
  final text = reason.replaceAll('_', ' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
