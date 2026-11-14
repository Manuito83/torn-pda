import 'dart:convert';

import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';

/// Empty or corrupt caches read empty
List<FFScouterTarget> decodeFFScouterTargets(String cached) {
  if (cached.isEmpty) return const [];
  try {
    final decoded = jsonDecode(cached);
    if (decoded is! List) return const [];
    return [for (final e in decoded) FFScouterTarget.fromJson(e as Map<String, dynamic>)];
  } catch (_) {
    return const [];
  }
}

String encodeFFScouterTargets(List<FFScouterTarget> targets) => jsonEncode([for (final t in targets) t.toJson()]);
