import 'package:torn_pda/models/chaining/war_settings.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/utils/country_check.dart';

/// Members the War page lists, pinned first
List<Member> warMembersShown(
  List<FactionModel> factions, {
  required int offlineSelector,
  required int okayRedFilterActive,
  required bool countryFilterActive,
  required int abroadFilterActive,
  required String playerLocation,
  required WarSettings settings,
  required double Function(Member) fairFightOf,
  required double Function(Member) totalStatsOf,
  required int Function(Member) estimatedStatsIndexOf,
  required int Function(Member, Member) compare,
  DateTime? now,
}) {
  final nowSeconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  final pinned = <Member>[];
  final others = <Member>[];

  for (final faction in factions) {
    if (faction.hidden!) continue;
    faction.members!.forEach((key, member) {
      member!.memberId = int.parse(key);
      member.factionName = faction.name;
      member.factionLeader = faction.leader;
      member.factionColeader = faction.coLeader;

      final shown =
          _passesFilters(
            member,
            offlineSelector: offlineSelector,
            okayRedFilterActive: okayRedFilterActive,
            countryFilterActive: countryFilterActive,
            abroadFilterActive: abroadFilterActive,
            playerLocation: playerLocation,
          ) &&
          (!settings.filtersEnabled ||
              _withinRanges(
                member,
                settings,
                nowSeconds: nowSeconds,
                fairFightOf: fairFightOf,
                totalStatsOf: totalStatsOf,
                estimatedStatsIndexOf: estimatedStatsIndexOf,
              ));
      if (!shown) return;
      (member.pinned ? pinned : others).add(member);
    });
  }

  pinned.sort(compare);
  others.sort(compare);
  return [...pinned, ...others];
}

bool _passesFilters(
  Member member, {
  required int offlineSelector,
  required int okayRedFilterActive,
  required bool countryFilterActive,
  required int abroadFilterActive,
  required String playerLocation,
}) {
  if (member.hidden!) return false;
  if (member.status!.state!.contains("Federal") && member.status!.state!.contains("Fallen")) return false;

  if ((member.lastAction!.status!.contains("Online") || member.lastAction!.status!.contains("Idle")) &&
      offlineSelector == 2) {
    return false;
  }

  if (member.lastAction!.status!.contains("Offline") && offlineSelector == 1) {
    return false;
  }

  if (okayRedFilterActive == 1 && member.status!.color == "red") {
    return false;
  }

  if (okayRedFilterActive == 2 && member.status!.color != "red") {
    return false;
  }

  if (countryFilterActive &&
      countryCheck(state: member.status!.state, description: member.status!.description) != playerLocation) {
    return false;
  }

  // Filter out not traveling
  if (abroadFilterActive == 1) {
    if (countryCheck(state: member.status!.state, description: member.status!.description) == "Torn" &&
        !isTraveling(state: member.status!.state)) {
      return false;
    }
  }

  // Filter out traveling
  if (abroadFilterActive == 2) {
    if (countryCheck(state: member.status!.state, description: member.status!.description) != "Torn" ||
        isTraveling(state: member.status!.state)) {
      return false;
    }
  }

  return true;
}

bool _withinRanges(
  Member member,
  WarSettings settings, {
  required int nowSeconds,
  required double Function(Member) fairFightOf,
  required double Function(Member) totalStatsOf,
  required int Function(Member) estimatedStatsIndexOf,
}) {
  if (settings.levelRange != null) {
    if (member.level == null ||
        member.level! < settings.levelRange!.start ||
        member.level! > settings.levelRange!.end) {
      return false;
    }
  }

  if (settings.lifeRange != null) {
    if (member.lifeCurrent == null ||
        member.lifeCurrent! < settings.lifeRange!.start ||
        member.lifeCurrent! > settings.lifeRange!.end) {
      return false;
    }
  }

  if (settings.respectRange != null) {
    if (member.respectGain == null ||
        member.respectGain! < settings.respectRange!.start ||
        member.respectGain! > settings.respectRange!.end) {
      return false;
    }
  }

  if (settings.fairFightRange != null) {
    double effFF = fairFightOf(member);
    if (effFF == -1 || effFF < settings.fairFightRange!.start || effFF > settings.fairFightRange!.end) {
      return false;
    }
  }

  if (settings.hospitalTimeRange != null) {
    int seconds = 0;
    if (member.status?.state == 'Hospital') {
      seconds = (member.status?.until ?? 0) - nowSeconds;
      if (seconds < 0) seconds = 0;
    }
    double minutes = seconds / 60.0;
    if (minutes < settings.hospitalTimeRange!.start || minutes > settings.hospitalTimeRange!.end) {
      return false;
    }
  }

  // Stats Filters
  if (settings.statsRange != null) {
    double totalStats = totalStatsOf(member);
    if (totalStats < settings.statsRange!.start || totalStats > settings.statsRange!.end) {
      return false;
    }
  }

  if (settings.estimatedStatsRange != null) {
    int estIndex = estimatedStatsIndexOf(member);
    // If member has no estimate (index -1), and we are filtering, exclude them
    // Range is 0-6.
    if (estIndex == -1) {
      return false;
    }

    if (estIndex < settings.estimatedStatsRange!.start.round() ||
        estIndex > settings.estimatedStatsRange!.end.round()) {
      return false;
    }
  }

  if (settings.strengthRange != null) {
    if (member.statsStr == null ||
        member.statsStr == -1 ||
        member.statsStr! < settings.strengthRange!.start ||
        member.statsStr! > settings.strengthRange!.end) {
      return false;
    }
  }
  if (settings.defenseRange != null) {
    if (member.statsDef == null ||
        member.statsDef == -1 ||
        member.statsDef! < settings.defenseRange!.start ||
        member.statsDef! > settings.defenseRange!.end) {
      return false;
    }
  }
  if (settings.speedRange != null) {
    if (member.statsSpd == null ||
        member.statsSpd == -1 ||
        member.statsSpd! < settings.speedRange!.start ||
        member.statsSpd! > settings.speedRange!.end) {
      return false;
    }
  }
  if (settings.dexterityRange != null) {
    if (member.statsDex == null ||
        member.statsDex == -1 ||
        member.statsDex! < settings.dexterityRange!.start ||
        member.statsDex! > settings.dexterityRange!.end) {
      return false;
    }
  }

  return true;
}
