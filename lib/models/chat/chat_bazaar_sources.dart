enum ChatBazaarState { open, closed, none, unknown }

/// Strict read of the v1 bazaar selection
ChatBazaarState chatBazaarState(Object? json) {
  if (json is! Map || json.containsKey('error')) return ChatBazaarState.unknown;
  final exists = json['bazaar_exists'];
  final open = json['bazaar_is_open'];
  if (exists is! bool || open is! bool) return ChatBazaarState.unknown;
  if (!exists) return ChatBazaarState.none;
  return open ? ChatBazaarState.open : ChatBazaarState.closed;
}

/// False for errors about the key, the limits or the seller id
bool chatBazaarSourceFault(int? code) => !const {1, 2, 5, 6, 8, 10, 13, 14, 16, 18, 999}.contains(code);
