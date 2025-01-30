// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'torn_v2.swagger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestLinks _$RequestLinksFromJson(Map<String, dynamic> json) => RequestLinks(
      next: json['next'] as String?,
      prev: json['prev'] as String?,
    );

Map<String, dynamic> _$RequestLinksToJson(RequestLinks instance) =>
    <String, dynamic>{
      'next': instance.next,
      'prev': instance.prev,
    };

RequestMetadata _$RequestMetadataFromJson(Map<String, dynamic> json) =>
    RequestMetadata(
      links: json['links'] == null
          ? null
          : RequestLinks.fromJson(json['links'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RequestMetadataToJson(RequestMetadata instance) =>
    <String, dynamic>{
      'links': instance.links?.toJson(),
    };

RequestMetadataWithLinks _$RequestMetadataWithLinksFromJson(
        Map<String, dynamic> json) =>
    RequestMetadataWithLinks(
      links: json['links'] == null
          ? null
          : RequestLinks.fromJson(json['links'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RequestMetadataWithLinksToJson(
        RequestMetadataWithLinks instance) =>
    <String, dynamic>{
      'links': instance.links?.toJson(),
    };

AttackPlayerFaction _$AttackPlayerFactionFromJson(Map<String, dynamic> json) =>
    AttackPlayerFaction(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$AttackPlayerFactionToJson(
        AttackPlayerFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

AttackPlayer _$AttackPlayerFromJson(Map<String, dynamic> json) => AttackPlayer(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      level: (json['level'] as num?)?.toInt(),
      faction: json['faction'],
    );

Map<String, dynamic> _$AttackPlayerToJson(AttackPlayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'level': instance.level,
      'faction': instance.faction,
    };

AttackPlayerSimplified _$AttackPlayerSimplifiedFromJson(
        Map<String, dynamic> json) =>
    AttackPlayerSimplified(
      id: (json['id'] as num?)?.toInt(),
      factionId: (json['faction_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AttackPlayerSimplifiedToJson(
        AttackPlayerSimplified instance) =>
    <String, dynamic>{
      'id': instance.id,
      'faction_id': instance.factionId,
    };

Attack _$AttackFromJson(Map<String, dynamic> json) => Attack(
      id: (json['id'] as num?)?.toInt(),
      code: json['code'] as String?,
      started: (json['started'] as num?)?.toInt(),
      ended: (json['ended'] as num?)?.toInt(),
      attacker: json['attacker'],
      defender: json['defender'] == null
          ? null
          : AttackPlayer.fromJson(json['defender'] as Map<String, dynamic>),
      result: factionAttackResultNullableFromJson(json['result']),
      respectGain: (json['respect_gain'] as num?)?.toDouble(),
      respectLoss: (json['respect_loss'] as num?)?.toDouble(),
      chain: (json['chain'] as num?)?.toInt(),
      isInterrupted: json['is_interrupted'] as bool?,
      isStealthed: json['is_stealthed'] as bool?,
      isRaid: json['is_raid'] as bool?,
      isRankedWar: json['is_ranked_war'] as bool?,
      modifiers: json['modifiers'] == null
          ? null
          : Attack$Modifiers.fromJson(
              json['modifiers'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttackToJson(Attack instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'started': instance.started,
      'ended': instance.ended,
      'attacker': instance.attacker,
      'defender': instance.defender?.toJson(),
      'result': factionAttackResultNullableToJson(instance.result),
      'respect_gain': instance.respectGain,
      'respect_loss': instance.respectLoss,
      'chain': instance.chain,
      'is_interrupted': instance.isInterrupted,
      'is_stealthed': instance.isStealthed,
      'is_raid': instance.isRaid,
      'is_ranked_war': instance.isRankedWar,
      'modifiers': instance.modifiers?.toJson(),
    };

AttackSimplified _$AttackSimplifiedFromJson(Map<String, dynamic> json) =>
    AttackSimplified(
      id: (json['id'] as num?)?.toInt(),
      code: json['code'] as String?,
      started: (json['started'] as num?)?.toInt(),
      ended: (json['ended'] as num?)?.toInt(),
      attacker: json['attacker'],
      defender: json['defender'] == null
          ? null
          : AttackPlayerSimplified.fromJson(
              json['defender'] as Map<String, dynamic>),
      result: factionAttackResultNullableFromJson(json['result']),
      respectGain: (json['respect_gain'] as num?)?.toDouble(),
      respectLoss: (json['respect_loss'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AttackSimplifiedToJson(AttackSimplified instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'started': instance.started,
      'ended': instance.ended,
      'attacker': instance.attacker,
      'defender': instance.defender?.toJson(),
      'result': factionAttackResultNullableToJson(instance.result),
      'respect_gain': instance.respectGain,
      'respect_loss': instance.respectLoss,
    };

TimestampResponse _$TimestampResponseFromJson(Map<String, dynamic> json) =>
    TimestampResponse(
      timestamp: (json['timestamp'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TimestampResponseToJson(TimestampResponse instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
    };

FactionHofStats _$FactionHofStatsFromJson(Map<String, dynamic> json) =>
    FactionHofStats(
      rank: json['rank'] == null
          ? null
          : HofValueString.fromJson(json['rank'] as Map<String, dynamic>),
      respect: json['respect'] == null
          ? null
          : HofValue.fromJson(json['respect'] as Map<String, dynamic>),
      chain: json['chain'] == null
          ? null
          : HofValue.fromJson(json['chain'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionHofStatsToJson(FactionHofStats instance) =>
    <String, dynamic>{
      'rank': instance.rank?.toJson(),
      'respect': instance.respect?.toJson(),
      'chain': instance.chain?.toJson(),
    };

FactionHofResponse _$FactionHofResponseFromJson(Map<String, dynamic> json) =>
    FactionHofResponse(
      hof: (json['hof'] as List<dynamic>?)
              ?.map((e) => FactionHofStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionHofResponseToJson(FactionHofResponse instance) =>
    <String, dynamic>{
      'hof': instance.hof?.map((e) => e.toJson()).toList(),
    };

FactionMember _$FactionMemberFromJson(Map<String, dynamic> json) =>
    FactionMember(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      position: json['position'] as String?,
      level: (json['level'] as num?)?.toInt(),
      daysInFaction: (json['days_in_faction'] as num?)?.toInt(),
      isRevivable: json['is_revivable'] as bool?,
      isOnWall: json['is_on_wall'] as bool?,
      isInOc: json['is_in_oc'] as bool?,
      hasEarlyDischarge: json['has_early_discharge'] as bool?,
      lastAction: json['last_action'] == null
          ? null
          : UserLastAction.fromJson(
              json['last_action'] as Map<String, dynamic>),
      status: json['status'] == null
          ? null
          : UserStatus.fromJson(json['status'] as Map<String, dynamic>),
      life: json['life'] == null
          ? null
          : UserLife.fromJson(json['life'] as Map<String, dynamic>),
      reviveSetting: reviveSettingNullableFromJson(json['revive_setting']),
    );

Map<String, dynamic> _$FactionMemberToJson(FactionMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'position': instance.position,
      'level': instance.level,
      'days_in_faction': instance.daysInFaction,
      'is_revivable': instance.isRevivable,
      'is_on_wall': instance.isOnWall,
      'is_in_oc': instance.isInOc,
      'has_early_discharge': instance.hasEarlyDischarge,
      'last_action': instance.lastAction?.toJson(),
      'status': instance.status?.toJson(),
      'life': instance.life?.toJson(),
      'revive_setting': reviveSettingNullableToJson(instance.reviveSetting),
    };

UserLastAction _$UserLastActionFromJson(Map<String, dynamic> json) =>
    UserLastAction(
      status: json['status'] as String?,
      timestamp: (json['timestamp'] as num?)?.toInt(),
      relative: json['relative'] as String?,
    );

Map<String, dynamic> _$UserLastActionToJson(UserLastAction instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp,
      'relative': instance.relative,
    };

UserLife _$UserLifeFromJson(Map<String, dynamic> json) => UserLife(
      current: (json['current'] as num?)?.toInt(),
      maximum: (json['maximum'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserLifeToJson(UserLife instance) => <String, dynamic>{
      'current': instance.current,
      'maximum': instance.maximum,
    };

UserStatus _$UserStatusFromJson(Map<String, dynamic> json) => UserStatus(
      description: json['description'] as String?,
      details: json['details'] as String?,
      state: json['state'] as String?,
      until: (json['until'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserStatusToJson(UserStatus instance) =>
    <String, dynamic>{
      'description': instance.description,
      'details': instance.details,
      'state': instance.state,
      'until': instance.until,
    };

FactionMembersResponse _$FactionMembersResponseFromJson(
        Map<String, dynamic> json) =>
    FactionMembersResponse(
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => FactionMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionMembersResponseToJson(
        FactionMembersResponse instance) =>
    <String, dynamic>{
      'members': instance.members?.map((e) => e.toJson()).toList(),
    };

FactionRank _$FactionRankFromJson(Map<String, dynamic> json) => FactionRank(
      level: (json['level'] as num?)?.toInt(),
      name: json['name'] as String?,
      division: (json['division'] as num?)?.toInt(),
      position: (json['position'] as num?)?.toInt(),
      wins: (json['wins'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionRankToJson(FactionRank instance) =>
    <String, dynamic>{
      'level': instance.level,
      'name': instance.name,
      'division': instance.division,
      'position': instance.position,
      'wins': instance.wins,
    };

FactionBasic _$FactionBasicFromJson(Map<String, dynamic> json) => FactionBasic(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      tag: json['tag'] as String?,
      tagImage: json['tag_image'] as String?,
      leaderId: (json['leader_id'] as num?)?.toInt(),
      coLeaderId: (json['co-leader_id'] as num?)?.toInt(),
      respect: (json['respect'] as num?)?.toInt(),
      daysOld: (json['days_old'] as num?)?.toInt(),
      capacity: (json['capacity'] as num?)?.toInt(),
      members: (json['members'] as num?)?.toInt(),
      isEnlisted: json['is_enlisted'] as bool?,
      rank: json['rank'] == null
          ? null
          : FactionRank.fromJson(json['rank'] as Map<String, dynamic>),
      bestChain: (json['best_chain'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionBasicToJson(FactionBasic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tag': instance.tag,
      'tag_image': instance.tagImage,
      'leader_id': instance.leaderId,
      'co-leader_id': instance.coLeaderId,
      'respect': instance.respect,
      'days_old': instance.daysOld,
      'capacity': instance.capacity,
      'members': instance.members,
      'is_enlisted': instance.isEnlisted,
      'rank': instance.rank?.toJson(),
      'best_chain': instance.bestChain,
    };

FactionBasicResponse _$FactionBasicResponseFromJson(
        Map<String, dynamic> json) =>
    FactionBasicResponse(
      basic: json['basic'] == null
          ? null
          : FactionBasic.fromJson(json['basic'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionBasicResponseToJson(
        FactionBasicResponse instance) =>
    <String, dynamic>{
      'basic': instance.basic?.toJson(),
    };

FactionPact _$FactionPactFromJson(Map<String, dynamic> json) => FactionPact(
      factionId: (json['faction_id'] as num?)?.toInt(),
      factionName: json['faction_name'] as String?,
      until: json['until'] as String?,
    );

Map<String, dynamic> _$FactionPactToJson(FactionPact instance) =>
    <String, dynamic>{
      'faction_id': instance.factionId,
      'faction_name': instance.factionName,
      'until': instance.until,
    };

FactionRankedWarParticipant _$FactionRankedWarParticipantFromJson(
        Map<String, dynamic> json) =>
    FactionRankedWarParticipant(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      score: (json['score'] as num?)?.toInt(),
      chain: (json['chain'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionRankedWarParticipantToJson(
        FactionRankedWarParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'chain': instance.chain,
    };

FactionRankedWar _$FactionRankedWarFromJson(Map<String, dynamic> json) =>
    FactionRankedWar(
      warId: (json['war_id'] as num?)?.toInt(),
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
      target: (json['target'] as num?)?.toInt(),
      winner: (json['winner'] as num?)?.toInt(),
      factions: (json['factions'] as List<dynamic>?)
              ?.map((e) => FactionRankedWarParticipant.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionRankedWarToJson(FactionRankedWar instance) =>
    <String, dynamic>{
      'war_id': instance.warId,
      'start': instance.start,
      'end': instance.end,
      'target': instance.target,
      'winner': instance.winner,
      'factions': instance.factions?.map((e) => e.toJson()).toList(),
    };

FactionRaidWarParticipant _$FactionRaidWarParticipantFromJson(
        Map<String, dynamic> json) =>
    FactionRaidWarParticipant(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      score: (json['score'] as num?)?.toInt(),
      chain: (json['chain'] as num?)?.toInt(),
      isAggressor: json['is_aggressor'] as bool?,
    );

Map<String, dynamic> _$FactionRaidWarParticipantToJson(
        FactionRaidWarParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'chain': instance.chain,
      'is_aggressor': instance.isAggressor,
    };

FactionRaidWar _$FactionRaidWarFromJson(Map<String, dynamic> json) =>
    FactionRaidWar(
      warId: (json['war_id'] as num?)?.toInt(),
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
      factions: (json['factions'] as List<dynamic>?)
              ?.map((e) =>
                  FactionRaidWarParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionRaidWarToJson(FactionRaidWar instance) =>
    <String, dynamic>{
      'war_id': instance.warId,
      'start': instance.start,
      'end': instance.end,
      'factions': instance.factions?.map((e) => e.toJson()).toList(),
    };

FactionTerritoryWarParticipant _$FactionTerritoryWarParticipantFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarParticipant(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      score: (json['score'] as num?)?.toInt(),
      chain: (json['chain'] as num?)?.toInt(),
      isAggressor: json['is_aggressor'] as bool?,
      playerIds: (json['playerIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoryWarParticipantToJson(
        FactionTerritoryWarParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'chain': instance.chain,
      'is_aggressor': instance.isAggressor,
      'playerIds': instance.playerIds,
    };

FactionTerritoryWar _$FactionTerritoryWarFromJson(Map<String, dynamic> json) =>
    FactionTerritoryWar(
      warId: (json['war_id'] as num?)?.toInt(),
      territory: json['territory'] as String?,
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
      target: (json['target'] as num?)?.toInt(),
      winner: (json['winner'] as num?)?.toInt(),
      factions: (json['factions'] as List<dynamic>?)
              ?.map((e) => FactionTerritoryWarParticipant.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoryWarToJson(
        FactionTerritoryWar instance) =>
    <String, dynamic>{
      'war_id': instance.warId,
      'territory': instance.territory,
      'start': instance.start,
      'end': instance.end,
      'target': instance.target,
      'winner': instance.winner,
      'factions': instance.factions?.map((e) => e.toJson()).toList(),
    };

FactionWars _$FactionWarsFromJson(Map<String, dynamic> json) => FactionWars(
      ranked: json['ranked'] == null
          ? null
          : FactionRankedWar.fromJson(json['ranked'] as Map<String, dynamic>),
      raids: (json['raids'] as List<dynamic>?)
              ?.map((e) => FactionRaidWar.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      territory: (json['territory'] as List<dynamic>?)
              ?.map((e) =>
                  FactionTerritoryWar.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionWarsToJson(FactionWars instance) =>
    <String, dynamic>{
      'ranked': instance.ranked?.toJson(),
      'raids': instance.raids?.map((e) => e.toJson()).toList(),
      'territory': instance.territory?.map((e) => e.toJson()).toList(),
    };

FactionWarsResponse _$FactionWarsResponseFromJson(Map<String, dynamic> json) =>
    FactionWarsResponse(
      pacts: (json['pacts'] as List<dynamic>?)
              ?.map((e) => FactionPact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      wars: json['wars'] == null
          ? null
          : FactionWars.fromJson(json['wars'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionWarsResponseToJson(
        FactionWarsResponse instance) =>
    <String, dynamic>{
      'pacts': instance.pacts?.map((e) => e.toJson()).toList(),
      'wars': instance.wars?.toJson(),
    };

FactionNews _$FactionNewsFromJson(Map<String, dynamic> json) => FactionNews(
      id: json['id'] as String?,
      text: json['text'] as String?,
      timestamp: (json['timestamp'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionNewsToJson(FactionNews instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'timestamp': instance.timestamp,
    };

FactionNewsResponse _$FactionNewsResponseFromJson(Map<String, dynamic> json) =>
    FactionNewsResponse(
      news: (json['news'] as List<dynamic>?)
              ?.map((e) => FactionNews.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionNewsResponseToJson(
        FactionNewsResponse instance) =>
    <String, dynamic>{
      'news': instance.news?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

FactionAttacksResponse _$FactionAttacksResponseFromJson(
        Map<String, dynamic> json) =>
    FactionAttacksResponse(
      attacks: (json['attacks'] as List<dynamic>?)
              ?.map((e) => Attack.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionAttacksResponseToJson(
        FactionAttacksResponse instance) =>
    <String, dynamic>{
      'attacks': instance.attacks?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

FactionAttacksFullResponse _$FactionAttacksFullResponseFromJson(
        Map<String, dynamic> json) =>
    FactionAttacksFullResponse(
      attacks: (json['attacks'] as List<dynamic>?)
              ?.map((e) => AttackSimplified.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionAttacksFullResponseToJson(
        FactionAttacksFullResponse instance) =>
    <String, dynamic>{
      'attacks': instance.attacks?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

FactionApplication _$FactionApplicationFromJson(Map<String, dynamic> json) =>
    FactionApplication(
      id: (json['id'] as num?)?.toInt(),
      user: json['user'] == null
          ? null
          : FactionApplication$User.fromJson(
              json['user'] as Map<String, dynamic>),
      message: json['message'] as String?,
      validUntil: (json['valid_until'] as num?)?.toInt(),
      status: factionApplicationStatusEnumNullableFromJson(json['status']),
    );

Map<String, dynamic> _$FactionApplicationToJson(FactionApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user?.toJson(),
      'message': instance.message,
      'valid_until': instance.validUntil,
      'status': factionApplicationStatusEnumNullableToJson(instance.status),
    };

FactionApplicationsResponse _$FactionApplicationsResponseFromJson(
        Map<String, dynamic> json) =>
    FactionApplicationsResponse(
      applications: (json['applications'] as List<dynamic>?)
              ?.map(
                  (e) => FactionApplication.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionApplicationsResponseToJson(
        FactionApplicationsResponse instance) =>
    <String, dynamic>{
      'applications': instance.applications?.map((e) => e.toJson()).toList(),
    };

FactionOngoingChain _$FactionOngoingChainFromJson(Map<String, dynamic> json) =>
    FactionOngoingChain(
      id: (json['id'] as num?)?.toInt(),
      current: (json['current'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
      timeout: (json['timeout'] as num?)?.toInt(),
      modifier: (json['modifier'] as num?)?.toDouble(),
      cooldown: (json['cooldown'] as num?)?.toInt(),
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionOngoingChainToJson(
        FactionOngoingChain instance) =>
    <String, dynamic>{
      'id': instance.id,
      'current': instance.current,
      'max': instance.max,
      'timeout': instance.timeout,
      'modifier': instance.modifier,
      'cooldown': instance.cooldown,
      'start': instance.start,
      'end': instance.end,
    };

FactionOngoingChainResponse _$FactionOngoingChainResponseFromJson(
        Map<String, dynamic> json) =>
    FactionOngoingChainResponse(
      chain: json['chain'] == null
          ? null
          : FactionOngoingChain.fromJson(json['chain'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionOngoingChainResponseToJson(
        FactionOngoingChainResponse instance) =>
    <String, dynamic>{
      'chain': instance.chain?.toJson(),
    };

FactionChain _$FactionChainFromJson(Map<String, dynamic> json) => FactionChain(
      id: (json['id'] as num?)?.toInt(),
      chain: (json['chain'] as num?)?.toInt(),
      respect: (json['respect'] as num?)?.toDouble(),
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionChainToJson(FactionChain instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chain': instance.chain,
      'respect': instance.respect,
      'start': instance.start,
      'end': instance.end,
    };

FactionChainsResponse _$FactionChainsResponseFromJson(
        Map<String, dynamic> json) =>
    FactionChainsResponse(
      chains: (json['chains'] as List<dynamic>?)
              ?.map((e) => FactionChain.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionChainsResponseToJson(
        FactionChainsResponse instance) =>
    <String, dynamic>{
      'chains': instance.chains?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

FactionChainReportResponse _$FactionChainReportResponseFromJson(
        Map<String, dynamic> json) =>
    FactionChainReportResponse(
      chainreport: json['chainreport'] == null
          ? null
          : FactionChainReport.fromJson(
              json['chainreport'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionChainReportResponseToJson(
        FactionChainReportResponse instance) =>
    <String, dynamic>{
      'chainreport': instance.chainreport?.toJson(),
    };

FactionChainReport _$FactionChainReportFromJson(Map<String, dynamic> json) =>
    FactionChainReport(
      id: (json['id'] as num?)?.toInt(),
      factionId: (json['faction_id'] as num?)?.toInt(),
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
      details: json['details'] == null
          ? null
          : FactionChainReportDetails.fromJson(
              json['details'] as Map<String, dynamic>),
      bonuses: (json['bonuses'] as List<dynamic>?)
              ?.map((e) =>
                  FactionChainReportBonus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attackers: (json['attackers'] as List<dynamic>?)
              ?.map((e) => FactionChainReportAttacker.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      nonAttackers: (json['non-attackers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionChainReportToJson(FactionChainReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'faction_id': instance.factionId,
      'start': instance.start,
      'end': instance.end,
      'details': instance.details?.toJson(),
      'bonuses': instance.bonuses?.map((e) => e.toJson()).toList(),
      'attackers': instance.attackers?.map((e) => e.toJson()).toList(),
      'non-attackers': instance.nonAttackers,
    };

FactionChainReportDetails _$FactionChainReportDetailsFromJson(
        Map<String, dynamic> json) =>
    FactionChainReportDetails(
      chain: (json['chain'] as num?)?.toInt(),
      respect: (json['respect'] as num?)?.toDouble(),
      members: (json['members'] as num?)?.toInt(),
      targets: (json['targets'] as num?)?.toInt(),
      war: (json['war'] as num?)?.toInt(),
      best: (json['best'] as num?)?.toDouble(),
      leave: (json['leave'] as num?)?.toInt(),
      mug: (json['mug'] as num?)?.toInt(),
      hospitalize: (json['hospitalize'] as num?)?.toInt(),
      assists: (json['assists'] as num?)?.toInt(),
      retaliations: (json['retaliations'] as num?)?.toInt(),
      overseas: (json['overseas'] as num?)?.toInt(),
      draws: (json['draws'] as num?)?.toInt(),
      escapes: (json['escapes'] as num?)?.toInt(),
      losses: (json['losses'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionChainReportDetailsToJson(
        FactionChainReportDetails instance) =>
    <String, dynamic>{
      'chain': instance.chain,
      'respect': instance.respect,
      'members': instance.members,
      'targets': instance.targets,
      'war': instance.war,
      'best': instance.best,
      'leave': instance.leave,
      'mug': instance.mug,
      'hospitalize': instance.hospitalize,
      'assists': instance.assists,
      'retaliations': instance.retaliations,
      'overseas': instance.overseas,
      'draws': instance.draws,
      'escapes': instance.escapes,
      'losses': instance.losses,
    };

FactionChainReportBonus _$FactionChainReportBonusFromJson(
        Map<String, dynamic> json) =>
    FactionChainReportBonus(
      attackerId: (json['attacker_id'] as num?)?.toInt(),
      defenderId: (json['defender_id'] as num?)?.toInt(),
      chain: (json['chain'] as num?)?.toInt(),
      respect: (json['respect'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionChainReportBonusToJson(
        FactionChainReportBonus instance) =>
    <String, dynamic>{
      'attacker_id': instance.attackerId,
      'defender_id': instance.defenderId,
      'chain': instance.chain,
      'respect': instance.respect,
    };

FactionChainReportAttacker _$FactionChainReportAttackerFromJson(
        Map<String, dynamic> json) =>
    FactionChainReportAttacker(
      id: (json['id'] as num?)?.toInt(),
      respect: json['respect'] == null
          ? null
          : FactionChainReportAttackerRespect.fromJson(
              json['respect'] as Map<String, dynamic>),
      attacks: json['attacks'] == null
          ? null
          : FactionChainReportAttackerAttacks.fromJson(
              json['attacks'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionChainReportAttackerToJson(
        FactionChainReportAttacker instance) =>
    <String, dynamic>{
      'id': instance.id,
      'respect': instance.respect?.toJson(),
      'attacks': instance.attacks?.toJson(),
    };

FactionChainReportAttackerRespect _$FactionChainReportAttackerRespectFromJson(
        Map<String, dynamic> json) =>
    FactionChainReportAttackerRespect(
      total: (json['total'] as num?)?.toDouble(),
      average: (json['average'] as num?)?.toDouble(),
      best: (json['best'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FactionChainReportAttackerRespectToJson(
        FactionChainReportAttackerRespect instance) =>
    <String, dynamic>{
      'total': instance.total,
      'average': instance.average,
      'best': instance.best,
    };

FactionChainReportAttackerAttacks _$FactionChainReportAttackerAttacksFromJson(
        Map<String, dynamic> json) =>
    FactionChainReportAttackerAttacks(
      total: (json['total'] as num?)?.toInt(),
      leave: (json['leave'] as num?)?.toInt(),
      mug: (json['mug'] as num?)?.toInt(),
      hospitalize: (json['hospitalize'] as num?)?.toInt(),
      assists: (json['assists'] as num?)?.toInt(),
      retaliations: (json['retaliations'] as num?)?.toInt(),
      overseas: (json['overseas'] as num?)?.toInt(),
      draws: (json['draws'] as num?)?.toInt(),
      escapes: (json['escapes'] as num?)?.toInt(),
      losses: (json['losses'] as num?)?.toInt(),
      war: (json['war'] as num?)?.toInt(),
      bonuses: (json['bonuses'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionChainReportAttackerAttacksToJson(
        FactionChainReportAttackerAttacks instance) =>
    <String, dynamic>{
      'total': instance.total,
      'leave': instance.leave,
      'mug': instance.mug,
      'hospitalize': instance.hospitalize,
      'assists': instance.assists,
      'retaliations': instance.retaliations,
      'overseas': instance.overseas,
      'draws': instance.draws,
      'escapes': instance.escapes,
      'losses': instance.losses,
      'war': instance.war,
      'bonuses': instance.bonuses,
    };

FactionCrimeUser _$FactionCrimeUserFromJson(Map<String, dynamic> json) =>
    FactionCrimeUser(
      id: (json['id'] as num?)?.toInt(),
      joinedAt: (json['joined_at'] as num?)?.toInt(),
      progress: (json['progress'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FactionCrimeUserToJson(FactionCrimeUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'joined_at': instance.joinedAt,
      'progress': instance.progress,
    };

FactionCrimeRewardItem _$FactionCrimeRewardItemFromJson(
        Map<String, dynamic> json) =>
    FactionCrimeRewardItem(
      id: (json['id'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionCrimeRewardItemToJson(
        FactionCrimeRewardItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
    };

FactionCrimeReward _$FactionCrimeRewardFromJson(Map<String, dynamic> json) =>
    FactionCrimeReward(
      money: (json['money'] as num?)?.toInt(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  FactionCrimeRewardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      respect: (json['respect'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionCrimeRewardToJson(FactionCrimeReward instance) =>
    <String, dynamic>{
      'money': instance.money,
      'items': instance.items?.map((e) => e.toJson()).toList(),
      'respect': instance.respect,
    };

FactionCrimeSlot _$FactionCrimeSlotFromJson(Map<String, dynamic> json) =>
    FactionCrimeSlot(
      position: json['position'] as String?,
      itemRequirement: json['item_requirement'],
      userId: (json['user_id'] as num?)?.toInt(),
      user: json['user'],
      successChance: (json['success_chance'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionCrimeSlotToJson(FactionCrimeSlot instance) =>
    <String, dynamic>{
      'position': instance.position,
      'item_requirement': instance.itemRequirement,
      'user_id': instance.userId,
      'user': instance.user,
      'success_chance': instance.successChance,
    };

FactionCrime _$FactionCrimeFromJson(Map<String, dynamic> json) => FactionCrime(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      difficulty: (json['difficulty'] as num?)?.toInt(),
      status: factionCrimeStatusEnumNullableFromJson(json['status']),
      createdAt: (json['created_at'] as num?)?.toInt(),
      initiatedAt: (json['initiated_at'] as num?)?.toInt(),
      planningAt: (json['planning_at'] as num?)?.toInt(),
      readyAt: (json['ready_at'] as num?)?.toInt(),
      expiredAt: (json['expired_at'] as num?)?.toInt(),
      executedAt: (json['executed_at'] as num?)?.toInt(),
      slots: (json['slots'] as List<dynamic>?)
              ?.map((e) => FactionCrimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rewards: json['rewards'],
    );

Map<String, dynamic> _$FactionCrimeToJson(FactionCrime instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'difficulty': instance.difficulty,
      'status': factionCrimeStatusEnumNullableToJson(instance.status),
      'created_at': instance.createdAt,
      'initiated_at': instance.initiatedAt,
      'planning_at': instance.planningAt,
      'ready_at': instance.readyAt,
      'expired_at': instance.expiredAt,
      'executed_at': instance.executedAt,
      'slots': instance.slots?.map((e) => e.toJson()).toList(),
      'rewards': instance.rewards,
    };

FactionCrimesResponse _$FactionCrimesResponseFromJson(
        Map<String, dynamic> json) =>
    FactionCrimesResponse(
      crimes: (json['crimes'] as List<dynamic>?)
              ?.map((e) => FactionCrime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionCrimesResponseToJson(
        FactionCrimesResponse instance) =>
    <String, dynamic>{
      'crimes': instance.crimes?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

FactionLookupResponse _$FactionLookupResponseFromJson(
        Map<String, dynamic> json) =>
    FactionLookupResponse(
      selections: factionSelectionNameListFromJson(json['selections'] as List?),
    );

Map<String, dynamic> _$FactionLookupResponseToJson(
        FactionLookupResponse instance) =>
    <String, dynamic>{
      'selections': factionSelectionNameListToJson(instance.selections),
    };

ForumCategoriesResponse _$ForumCategoriesResponseFromJson(
        Map<String, dynamic> json) =>
    ForumCategoriesResponse(
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => ForumCategoriesResponse$Categories$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ForumCategoriesResponseToJson(
        ForumCategoriesResponse instance) =>
    <String, dynamic>{
      'categories': instance.categories?.map((e) => e.toJson()).toList(),
    };

ForumThreadAuthor _$ForumThreadAuthorFromJson(Map<String, dynamic> json) =>
    ForumThreadAuthor(
      id: (json['id'] as num?)?.toInt(),
      username: json['username'] as String?,
      karma: (json['karma'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ForumThreadAuthorToJson(ForumThreadAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'karma': instance.karma,
    };

ForumPollVote _$ForumPollVoteFromJson(Map<String, dynamic> json) =>
    ForumPollVote(
      answer: json['answer'] as String?,
      votes: (json['votes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ForumPollVoteToJson(ForumPollVote instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'votes': instance.votes,
    };

ForumPoll _$ForumPollFromJson(Map<String, dynamic> json) => ForumPoll(
      question: json['question'] as String?,
      answersCount: (json['answers_count'] as num?)?.toInt(),
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => ForumPollVote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ForumPollToJson(ForumPoll instance) => <String, dynamic>{
      'question': instance.question,
      'answers_count': instance.answersCount,
      'answers': instance.answers?.map((e) => e.toJson()).toList(),
    };

ForumThreadBase _$ForumThreadBaseFromJson(Map<String, dynamic> json) =>
    ForumThreadBase(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      forumId: (json['forum_id'] as num?)?.toInt(),
      posts: (json['posts'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      views: (json['views'] as num?)?.toInt(),
      author: json['author'] == null
          ? null
          : ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      lastPoster: json['last_poster'] == null
          ? null
          : ForumThreadAuthor.fromJson(
              json['last_poster'] as Map<String, dynamic>),
      firstPostTime: (json['first_post_time'] as num?)?.toInt(),
      lastPostTime: (json['last_post_time'] as num?)?.toInt(),
      hasPoll: json['has_poll'] as bool?,
      isLocked: json['is_locked'] as bool?,
      isSticky: json['is_sticky'] as bool?,
    );

Map<String, dynamic> _$ForumThreadBaseToJson(ForumThreadBase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'forum_id': instance.forumId,
      'posts': instance.posts,
      'rating': instance.rating,
      'views': instance.views,
      'author': instance.author?.toJson(),
      'last_poster': instance.lastPoster?.toJson(),
      'first_post_time': instance.firstPostTime,
      'last_post_time': instance.lastPostTime,
      'has_poll': instance.hasPoll,
      'is_locked': instance.isLocked,
      'is_sticky': instance.isSticky,
    };

ForumThreadExtended _$ForumThreadExtendedFromJson(Map<String, dynamic> json) =>
    ForumThreadExtended(
      content: json['content'] as String?,
      contentRaw: json['content_raw'] as String?,
      poll: json['poll'] == null
          ? null
          : ForumPoll.fromJson(json['poll'] as Map<String, dynamic>),
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      forumId: (json['forum_id'] as num?)?.toInt(),
      posts: (json['posts'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      views: (json['views'] as num?)?.toInt(),
      author: json['author'] == null
          ? null
          : ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      lastPoster: json['last_poster'] == null
          ? null
          : ForumThreadAuthor.fromJson(
              json['last_poster'] as Map<String, dynamic>),
      firstPostTime: (json['first_post_time'] as num?)?.toInt(),
      lastPostTime: (json['last_post_time'] as num?)?.toInt(),
      hasPoll: json['has_poll'] as bool?,
      isLocked: json['is_locked'] as bool?,
      isSticky: json['is_sticky'] as bool?,
    );

Map<String, dynamic> _$ForumThreadExtendedToJson(
        ForumThreadExtended instance) =>
    <String, dynamic>{
      'content': instance.content,
      'content_raw': instance.contentRaw,
      'poll': instance.poll?.toJson(),
      'id': instance.id,
      'title': instance.title,
      'forum_id': instance.forumId,
      'posts': instance.posts,
      'rating': instance.rating,
      'views': instance.views,
      'author': instance.author?.toJson(),
      'last_poster': instance.lastPoster?.toJson(),
      'first_post_time': instance.firstPostTime,
      'last_post_time': instance.lastPostTime,
      'has_poll': instance.hasPoll,
      'is_locked': instance.isLocked,
      'is_sticky': instance.isSticky,
    };

ForumPost _$ForumPostFromJson(Map<String, dynamic> json) => ForumPost(
      id: (json['id'] as num?)?.toInt(),
      threadId: (json['thread_id'] as num?)?.toInt(),
      author: json['author'] == null
          ? null
          : ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      isLegacy: json['is_legacy'] as bool?,
      isTopic: json['is_topic'] as bool?,
      isEdited: json['is_edited'] as bool?,
      isPinned: json['is_pinned'] as bool?,
      createdTime: (json['created_time'] as num?)?.toInt(),
      editedBy: (json['edited_by'] as num?)?.toInt(),
      hasQuote: json['has_quote'] as bool?,
      quotedPostId: (json['quoted_post_id'] as num?)?.toInt(),
      content: json['content'] as String?,
      likes: (json['likes'] as num?)?.toInt(),
      dislikes: (json['dislikes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ForumPostToJson(ForumPost instance) => <String, dynamic>{
      'id': instance.id,
      'thread_id': instance.threadId,
      'author': instance.author?.toJson(),
      'is_legacy': instance.isLegacy,
      'is_topic': instance.isTopic,
      'is_edited': instance.isEdited,
      'is_pinned': instance.isPinned,
      'created_time': instance.createdTime,
      'edited_by': instance.editedBy,
      'has_quote': instance.hasQuote,
      'quoted_post_id': instance.quotedPostId,
      'content': instance.content,
      'likes': instance.likes,
      'dislikes': instance.dislikes,
    };

ForumThreadUserExtended _$ForumThreadUserExtendedFromJson(
        Map<String, dynamic> json) =>
    ForumThreadUserExtended(
      newPosts: (json['new_posts'] as num?)?.toInt(),
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      forumId: (json['forum_id'] as num?)?.toInt(),
      posts: (json['posts'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      views: (json['views'] as num?)?.toInt(),
      author: json['author'] == null
          ? null
          : ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      lastPoster: json['last_poster'] == null
          ? null
          : ForumThreadAuthor.fromJson(
              json['last_poster'] as Map<String, dynamic>),
      firstPostTime: (json['first_post_time'] as num?)?.toInt(),
      lastPostTime: (json['last_post_time'] as num?)?.toInt(),
      hasPoll: json['has_poll'] as bool?,
      isLocked: json['is_locked'] as bool?,
      isSticky: json['is_sticky'] as bool?,
    );

Map<String, dynamic> _$ForumThreadUserExtendedToJson(
        ForumThreadUserExtended instance) =>
    <String, dynamic>{
      'new_posts': instance.newPosts,
      'id': instance.id,
      'title': instance.title,
      'forum_id': instance.forumId,
      'posts': instance.posts,
      'rating': instance.rating,
      'views': instance.views,
      'author': instance.author?.toJson(),
      'last_poster': instance.lastPoster?.toJson(),
      'first_post_time': instance.firstPostTime,
      'last_post_time': instance.lastPostTime,
      'has_poll': instance.hasPoll,
      'is_locked': instance.isLocked,
      'is_sticky': instance.isSticky,
    };

ForumSubscribedThreadPostsCount _$ForumSubscribedThreadPostsCountFromJson(
        Map<String, dynamic> json) =>
    ForumSubscribedThreadPostsCount(
      $new: (json['new'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ForumSubscribedThreadPostsCountToJson(
        ForumSubscribedThreadPostsCount instance) =>
    <String, dynamic>{
      'new': instance.$new,
      'total': instance.total,
    };

ForumSubscribedThread _$ForumSubscribedThreadFromJson(
        Map<String, dynamic> json) =>
    ForumSubscribedThread(
      id: (json['id'] as num?)?.toInt(),
      forumId: (json['forum_id'] as num?)?.toInt(),
      author: json['author'] == null
          ? null
          : ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      title: json['title'] as String?,
      posts: json['posts'] == null
          ? null
          : ForumSubscribedThreadPostsCount.fromJson(
              json['posts'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumSubscribedThreadToJson(
        ForumSubscribedThread instance) =>
    <String, dynamic>{
      'id': instance.id,
      'forum_id': instance.forumId,
      'author': instance.author?.toJson(),
      'title': instance.title,
      'posts': instance.posts?.toJson(),
    };

ForumFeed _$ForumFeedFromJson(Map<String, dynamic> json) => ForumFeed(
      threadId: (json['thread_id'] as num?)?.toInt(),
      postId: (json['post_id'] as num?)?.toInt(),
      user: json['user'] == null
          ? null
          : ForumThreadAuthor.fromJson(json['user'] as Map<String, dynamic>),
      title: json['title'] as String?,
      text: json['text'] as String?,
      timestamp: (json['timestamp'] as num?)?.toInt(),
      isSeen: json['is_seen'] as bool?,
      type: forumFeedTypeEnumNullableFromJson(json['type']),
    );

Map<String, dynamic> _$ForumFeedToJson(ForumFeed instance) => <String, dynamic>{
      'thread_id': instance.threadId,
      'post_id': instance.postId,
      'user': instance.user?.toJson(),
      'title': instance.title,
      'text': instance.text,
      'timestamp': instance.timestamp,
      'is_seen': instance.isSeen,
      'type': forumFeedTypeEnumNullableToJson(instance.type),
    };

ForumThreadsResponse _$ForumThreadsResponseFromJson(
        Map<String, dynamic> json) =>
    ForumThreadsResponse(
      threads: (json['threads'] as List<dynamic>?)
              ?.map((e) => ForumThreadBase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumThreadsResponseToJson(
        ForumThreadsResponse instance) =>
    <String, dynamic>{
      'threads': instance.threads?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

ForumThreadResponse _$ForumThreadResponseFromJson(Map<String, dynamic> json) =>
    ForumThreadResponse(
      thread: json['thread'] == null
          ? null
          : ForumThreadExtended.fromJson(
              json['thread'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumThreadResponseToJson(
        ForumThreadResponse instance) =>
    <String, dynamic>{
      'thread': instance.thread?.toJson(),
    };

ForumPostsResponse _$ForumPostsResponseFromJson(Map<String, dynamic> json) =>
    ForumPostsResponse(
      posts: (json['posts'] as List<dynamic>?)
              ?.map((e) => ForumPost.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumPostsResponseToJson(ForumPostsResponse instance) =>
    <String, dynamic>{
      'posts': instance.posts?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

ForumLookupResponse _$ForumLookupResponseFromJson(Map<String, dynamic> json) =>
    ForumLookupResponse(
      selections: forumSelectionNameListFromJson(json['selections'] as List?),
    );

Map<String, dynamic> _$ForumLookupResponseToJson(
        ForumLookupResponse instance) =>
    <String, dynamic>{
      'selections': forumSelectionNameListToJson(instance.selections),
    };

ItemMarketListingItemBonus _$ItemMarketListingItemBonusFromJson(
        Map<String, dynamic> json) =>
    ItemMarketListingItemBonus(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ItemMarketListingItemBonusToJson(
        ItemMarketListingItemBonus instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
    };

ItemMarketListingItemStats _$ItemMarketListingItemStatsFromJson(
        Map<String, dynamic> json) =>
    ItemMarketListingItemStats(
      damage: (json['damage'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      armor: (json['armor'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ItemMarketListingItemStatsToJson(
        ItemMarketListingItemStats instance) =>
    <String, dynamic>{
      'damage': instance.damage,
      'accuracy': instance.accuracy,
      'armor': instance.armor,
    };

ItemMarketItem _$ItemMarketItemFromJson(Map<String, dynamic> json) =>
    ItemMarketItem(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      type: json['type'] as String?,
      averagePrice: (json['average_price'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ItemMarketItemToJson(ItemMarketItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'average_price': instance.averagePrice,
    };

ItemMarketListingStackable _$ItemMarketListingStackableFromJson(
        Map<String, dynamic> json) =>
    ItemMarketListingStackable(
      id: (json['id'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ItemMarketListingStackableToJson(
        ItemMarketListingStackable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'price': instance.price,
      'amount': instance.amount,
    };

ItemMarketListingItemDetails _$ItemMarketListingItemDetailsFromJson(
        Map<String, dynamic> json) =>
    ItemMarketListingItemDetails(
      uid: (json['uid'] as num?)?.toInt(),
      stats: json['stats'] == null
          ? null
          : ItemMarketListingItemStats.fromJson(
              json['stats'] as Map<String, dynamic>),
      bonuses: (json['bonuses'] as List<dynamic>?)
              ?.map((e) => ItemMarketListingItemBonus.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      rarity:
          itemMarketListingItemDetailsRarityNullableFromJson(json['rarity']),
    );

Map<String, dynamic> _$ItemMarketListingItemDetailsToJson(
        ItemMarketListingItemDetails instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'stats': instance.stats?.toJson(),
      'bonuses': instance.bonuses?.map((e) => e.toJson()).toList(),
      'rarity':
          itemMarketListingItemDetailsRarityNullableToJson(instance.rarity),
    };

ItemMarketListingNonstackable _$ItemMarketListingNonstackableFromJson(
        Map<String, dynamic> json) =>
    ItemMarketListingNonstackable(
      id: (json['id'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toInt(),
      itemDetails: json['itemDetails'] == null
          ? null
          : ItemMarketListingItemDetails.fromJson(
              json['itemDetails'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ItemMarketListingNonstackableToJson(
        ItemMarketListingNonstackable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'price': instance.price,
      'amount': instance.amount,
      'itemDetails': instance.itemDetails?.toJson(),
    };

ItemMarket _$ItemMarketFromJson(Map<String, dynamic> json) => ItemMarket(
      item: json['item'] == null
          ? null
          : ItemMarketItem.fromJson(json['item'] as Map<String, dynamic>),
      listings: (json['listings'] as List<dynamic>?)
              ?.map((e) => e as Object)
              .toList() ??
          [],
    );

Map<String, dynamic> _$ItemMarketToJson(ItemMarket instance) =>
    <String, dynamic>{
      'item': instance.item?.toJson(),
      'listings': instance.listings,
    };

MarketItemMarketResponse _$MarketItemMarketResponseFromJson(
        Map<String, dynamic> json) =>
    MarketItemMarketResponse(
      itemmarket: json['itemmarket'] == null
          ? null
          : ItemMarket.fromJson(json['itemmarket'] as Map<String, dynamic>),
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MarketItemMarketResponseToJson(
        MarketItemMarketResponse instance) =>
    <String, dynamic>{
      'itemmarket': instance.itemmarket?.toJson(),
      '_metadata': instance.metadata?.toJson(),
    };

MarketLookupResponse _$MarketLookupResponseFromJson(
        Map<String, dynamic> json) =>
    MarketLookupResponse(
      selections: marketSelectionNameListFromJson(json['selections'] as List?),
    );

Map<String, dynamic> _$MarketLookupResponseToJson(
        MarketLookupResponse instance) =>
    <String, dynamic>{
      'selections': marketSelectionNameListToJson(instance.selections),
    };

RacingCarsResponse _$RacingCarsResponseFromJson(Map<String, dynamic> json) =>
    RacingCarsResponse(
      cars: (json['cars'] as List<dynamic>?)
              ?.map((e) => RaceCar.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RacingCarsResponseToJson(RacingCarsResponse instance) =>
    <String, dynamic>{
      'cars': instance.cars?.map((e) => e.toJson()).toList(),
    };

RaceCar _$RaceCarFromJson(Map<String, dynamic> json) => RaceCar(
      carItemId: (json['car_item_id'] as num?)?.toInt(),
      carItemName: json['car_item_name'] as String?,
      topSpeed: (json['top_speed'] as num?)?.toInt(),
      acceleration: (json['acceleration'] as num?)?.toInt(),
      braking: (json['braking'] as num?)?.toInt(),
      dirt: (json['dirt'] as num?)?.toInt(),
      handling: (json['handling'] as num?)?.toInt(),
      safety: (json['safety'] as num?)?.toInt(),
      tarmac: (json['tarmac'] as num?)?.toInt(),
      $class: raceClassEnumNullableFromJson(json['class']),
    );

Map<String, dynamic> _$RaceCarToJson(RaceCar instance) => <String, dynamic>{
      'car_item_id': instance.carItemId,
      'car_item_name': instance.carItemName,
      'top_speed': instance.topSpeed,
      'acceleration': instance.acceleration,
      'braking': instance.braking,
      'dirt': instance.dirt,
      'handling': instance.handling,
      'safety': instance.safety,
      'tarmac': instance.tarmac,
      'class': raceClassEnumNullableToJson(instance.$class),
    };

RacingTracksResponse _$RacingTracksResponseFromJson(
        Map<String, dynamic> json) =>
    RacingTracksResponse(
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((e) => RaceTrack.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RacingTracksResponseToJson(
        RacingTracksResponse instance) =>
    <String, dynamic>{
      'tracks': instance.tracks?.map((e) => e.toJson()).toList(),
    };

RaceTrack _$RaceTrackFromJson(Map<String, dynamic> json) => RaceTrack(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$RaceTrackToJson(RaceTrack instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
    };

RacingCarUpgradesResponse _$RacingCarUpgradesResponseFromJson(
        Map<String, dynamic> json) =>
    RacingCarUpgradesResponse(
      carupgrades: (json['carupgrades'] as List<dynamic>?)
              ?.map((e) => RaceCarUpgrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RacingCarUpgradesResponseToJson(
        RacingCarUpgradesResponse instance) =>
    <String, dynamic>{
      'carupgrades': instance.carupgrades?.map((e) => e.toJson()).toList(),
    };

RaceCarUpgrade _$RaceCarUpgradeFromJson(Map<String, dynamic> json) =>
    RaceCarUpgrade(
      id: (json['id'] as num?)?.toInt(),
      classRequired: raceClassEnumNullableFromJson(json['class_required']),
      name: json['name'] as String?,
      description: json['description'] as String?,
      category: raceCarUpgradeCategoryNullableFromJson(json['category']),
      subcategory:
          raceCarUpgradeSubCategoryNullableFromJson(json['subcategory']),
      effects: json['effects'] == null
          ? null
          : RaceCarUpgrade$Effects.fromJson(
              json['effects'] as Map<String, dynamic>),
      cost: json['cost'] == null
          ? null
          : RaceCarUpgrade$Cost.fromJson(json['cost'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RaceCarUpgradeToJson(RaceCarUpgrade instance) =>
    <String, dynamic>{
      'id': instance.id,
      'class_required': raceClassEnumNullableToJson(instance.classRequired),
      'name': instance.name,
      'description': instance.description,
      'category': raceCarUpgradeCategoryNullableToJson(instance.category),
      'subcategory':
          raceCarUpgradeSubCategoryNullableToJson(instance.subcategory),
      'effects': instance.effects?.toJson(),
      'cost': instance.cost?.toJson(),
    };

RacingRacesResponse _$RacingRacesResponseFromJson(Map<String, dynamic> json) =>
    RacingRacesResponse(
      races: (json['races'] as List<dynamic>?)
              ?.map((e) => Race.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RacingRacesResponseToJson(
        RacingRacesResponse instance) =>
    <String, dynamic>{
      'races': instance.races?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

Race _$RaceFromJson(Map<String, dynamic> json) => Race(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      trackId: (json['track_id'] as num?)?.toInt(),
      creatorId: (json['creator_id'] as num?)?.toInt(),
      status: raceStatusEnumNullableFromJson(json['status']),
      laps: (json['laps'] as num?)?.toInt(),
      participants: json['participants'] == null
          ? null
          : Race$Participants.fromJson(
              json['participants'] as Map<String, dynamic>),
      schedule: json['schedule'] == null
          ? null
          : Race$Schedule.fromJson(json['schedule'] as Map<String, dynamic>),
      requirements: json['requirements'] == null
          ? null
          : Race$Requirements.fromJson(
              json['requirements'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RaceToJson(Race instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'track_id': instance.trackId,
      'creator_id': instance.creatorId,
      'status': raceStatusEnumNullableToJson(instance.status),
      'laps': instance.laps,
      'participants': instance.participants?.toJson(),
      'schedule': instance.schedule?.toJson(),
      'requirements': instance.requirements?.toJson(),
    };

RacingTrackRecordsResponse _$RacingTrackRecordsResponseFromJson(
        Map<String, dynamic> json) =>
    RacingTrackRecordsResponse(
      records: (json['records'] as List<dynamic>?)
              ?.map((e) => RaceRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RacingTrackRecordsResponseToJson(
        RacingTrackRecordsResponse instance) =>
    <String, dynamic>{
      'records': instance.records?.map((e) => e.toJson()).toList(),
    };

RaceRecord _$RaceRecordFromJson(Map<String, dynamic> json) => RaceRecord(
      driverId: (json['driver_id'] as num?)?.toInt(),
      driverName: json['driver_name'] as String?,
      carItemId: (json['car_item_id'] as num?)?.toInt(),
      lapTime: (json['lap_time'] as num?)?.toInt(),
      carItemName: json['car_item_name'] as String?,
    );

Map<String, dynamic> _$RaceRecordToJson(RaceRecord instance) =>
    <String, dynamic>{
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'car_item_id': instance.carItemId,
      'lap_time': instance.lapTime,
      'car_item_name': instance.carItemName,
    };

RacerDetails _$RacerDetailsFromJson(Map<String, dynamic> json) => RacerDetails(
      driverId: (json['driver_id'] as num?)?.toInt(),
      position: (json['position'] as num?)?.toInt(),
      carId: (json['car_id'] as num?)?.toInt(),
      carItemId: (json['car_item_id'] as num?)?.toInt(),
      carItemName: json['car_item_name'] as String?,
      carClass: raceClassEnumNullableFromJson(json['car_class']),
      hasCrashed: json['has_crashed'] as bool?,
      bestLapTime: (json['best_lap_time'] as num?)?.toDouble(),
      raceTime: (json['race_time'] as num?)?.toDouble(),
      timeEnded: (json['time_ended'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RacerDetailsToJson(RacerDetails instance) =>
    <String, dynamic>{
      'driver_id': instance.driverId,
      'position': instance.position,
      'car_id': instance.carId,
      'car_item_id': instance.carItemId,
      'car_item_name': instance.carItemName,
      'car_class': raceClassEnumNullableToJson(instance.carClass),
      'has_crashed': instance.hasCrashed,
      'best_lap_time': instance.bestLapTime,
      'race_time': instance.raceTime,
      'time_ended': instance.timeEnded,
    };

RacingRaceDetailsResponse _$RacingRaceDetailsResponseFromJson(
        Map<String, dynamic> json) =>
    RacingRaceDetailsResponse(
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => RacerDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      trackId: (json['track_id'] as num?)?.toInt(),
      creatorId: (json['creator_id'] as num?)?.toInt(),
      status: raceStatusEnumNullableFromJson(json['status']),
      laps: (json['laps'] as num?)?.toInt(),
      participants: json['participants'] == null
          ? null
          : RacingRaceDetailsResponse$Participants.fromJson(
              json['participants'] as Map<String, dynamic>),
      schedule: json['schedule'] == null
          ? null
          : RacingRaceDetailsResponse$Schedule.fromJson(
              json['schedule'] as Map<String, dynamic>),
      requirements: json['requirements'] == null
          ? null
          : RacingRaceDetailsResponse$Requirements.fromJson(
              json['requirements'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RacingRaceDetailsResponseToJson(
        RacingRaceDetailsResponse instance) =>
    <String, dynamic>{
      'results': instance.results?.map((e) => e.toJson()).toList(),
      'id': instance.id,
      'title': instance.title,
      'track_id': instance.trackId,
      'creator_id': instance.creatorId,
      'status': raceStatusEnumNullableToJson(instance.status),
      'laps': instance.laps,
      'participants': instance.participants?.toJson(),
      'schedule': instance.schedule?.toJson(),
      'requirements': instance.requirements?.toJson(),
    };

RacingLookupResponse _$RacingLookupResponseFromJson(
        Map<String, dynamic> json) =>
    RacingLookupResponse(
      selections: racingSelectionNameListFromJson(json['selections'] as List?),
    );

Map<String, dynamic> _$RacingLookupResponseToJson(
        RacingLookupResponse instance) =>
    <String, dynamic>{
      'selections': racingSelectionNameListToJson(instance.selections),
    };

TornSubcrimesResponse _$TornSubcrimesResponseFromJson(
        Map<String, dynamic> json) =>
    TornSubcrimesResponse(
      subcrimes: (json['subcrimes'] as List<dynamic>?)
              ?.map((e) => TornSubcrime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornSubcrimesResponseToJson(
        TornSubcrimesResponse instance) =>
    <String, dynamic>{
      'subcrimes': instance.subcrimes?.map((e) => e.toJson()).toList(),
    };

TornSubcrime _$TornSubcrimeFromJson(Map<String, dynamic> json) => TornSubcrime(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      nerveCost: (json['nerve_cost'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TornSubcrimeToJson(TornSubcrime instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nerve_cost': instance.nerveCost,
    };

TornCrimesResponse _$TornCrimesResponseFromJson(Map<String, dynamic> json) =>
    TornCrimesResponse(
      crimes: (json['crimes'] as List<dynamic>?)
              ?.map((e) => TornCrime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornCrimesResponseToJson(TornCrimesResponse instance) =>
    <String, dynamic>{
      'crimes': instance.crimes?.map((e) => e.toJson()).toList(),
    };

TornCrime _$TornCrimeFromJson(Map<String, dynamic> json) => TornCrime(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      categoryId: (json['category_id'] as num?)?.toInt(),
      categoryName: json['category_name'] as String?,
      enhancerId: (json['enhancer_id'] as num?)?.toInt(),
      enhancerName: json['enhancer_name'] as String?,
      uniqueOutcomesCount: (json['unique_outcomes_count'] as num?)?.toInt(),
      uniqueOutcomesIds: (json['unique_outcomes_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      notes:
          (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );

Map<String, dynamic> _$TornCrimeToJson(TornCrime instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'enhancer_id': instance.enhancerId,
      'enhancer_name': instance.enhancerName,
      'unique_outcomes_count': instance.uniqueOutcomesCount,
      'unique_outcomes_ids': instance.uniqueOutcomesIds,
      'notes': instance.notes,
    };

TornCalendarActivity _$TornCalendarActivityFromJson(
        Map<String, dynamic> json) =>
    TornCalendarActivity(
      title: json['title'] as String?,
      description: json['description'] as String?,
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TornCalendarActivityToJson(
        TornCalendarActivity instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'start': instance.start,
      'end': instance.end,
    };

TornCalendarResponse _$TornCalendarResponseFromJson(
        Map<String, dynamic> json) =>
    TornCalendarResponse(
      calendar: json['calendar'] == null
          ? null
          : TornCalendarResponse$Calendar.fromJson(
              json['calendar'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornCalendarResponseToJson(
        TornCalendarResponse instance) =>
    <String, dynamic>{
      'calendar': instance.calendar?.toJson(),
    };

TornHof _$TornHofFromJson(Map<String, dynamic> json) => TornHof(
      id: (json['id'] as num?)?.toInt(),
      username: json['username'] as String?,
      factionId: (json['faction_id'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt(),
      lastAction: (json['last_action'] as num?)?.toInt(),
      rankName: json['rank_name'] as String?,
      rankNumber: (json['rank_number'] as num?)?.toInt(),
      position: (json['position'] as num?)?.toInt(),
      signedUp: (json['signed_up'] as num?)?.toInt(),
      ageInDays: (json['age_in_days'] as num?)?.toInt(),
      $value: json['value'],
      rank: json['rank'] as String?,
    );

Map<String, dynamic> _$TornHofToJson(TornHof instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'faction_id': instance.factionId,
      'level': instance.level,
      'last_action': instance.lastAction,
      'rank_name': instance.rankName,
      'rank_number': instance.rankNumber,
      'position': instance.position,
      'signed_up': instance.signedUp,
      'age_in_days': instance.ageInDays,
      'value': instance.$value,
      'rank': instance.rank,
    };

TornHofResponse _$TornHofResponseFromJson(Map<String, dynamic> json) =>
    TornHofResponse(
      hof: (json['hof'] as List<dynamic>?)
              ?.map((e) => TornHof.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornHofResponseToJson(TornHofResponse instance) =>
    <String, dynamic>{
      'hof': instance.hof?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

FactionHofValues _$FactionHofValuesFromJson(Map<String, dynamic> json) =>
    FactionHofValues(
      chain: (json['chain'] as num?)?.toInt(),
      chainDuration: (json['chain_duration'] as num?)?.toInt(),
      respect: (json['respect'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionHofValuesToJson(FactionHofValues instance) =>
    <String, dynamic>{
      'chain': instance.chain,
      'chain_duration': instance.chainDuration,
      'respect': instance.respect,
    };

TornFactionHof _$TornFactionHofFromJson(Map<String, dynamic> json) =>
    TornFactionHof(
      factionId: (json['faction_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      members: (json['members'] as num?)?.toInt(),
      position: (json['position'] as num?)?.toInt(),
      rank: json['rank'] as String?,
      values: json['values'] == null
          ? null
          : FactionHofValues.fromJson(json['values'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornFactionHofToJson(TornFactionHof instance) =>
    <String, dynamic>{
      'faction_id': instance.factionId,
      'name': instance.name,
      'members': instance.members,
      'position': instance.position,
      'rank': instance.rank,
      'values': instance.values?.toJson(),
    };

TornFactionHofResponse _$TornFactionHofResponseFromJson(
        Map<String, dynamic> json) =>
    TornFactionHofResponse(
      factionhof: (json['factionhof'] as List<dynamic>?)
              ?.map((e) => TornFactionHof.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornFactionHofResponseToJson(
        TornFactionHofResponse instance) =>
    <String, dynamic>{
      'factionhof': instance.factionhof?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

TornLog _$TornLogFromJson(Map<String, dynamic> json) => TornLog(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
    );

Map<String, dynamic> _$TornLogToJson(TornLog instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
    };

TornLogCategory _$TornLogCategoryFromJson(Map<String, dynamic> json) =>
    TornLogCategory(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
    );

Map<String, dynamic> _$TornLogCategoryToJson(TornLogCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
    };

TornLogTypesResponse _$TornLogTypesResponseFromJson(
        Map<String, dynamic> json) =>
    TornLogTypesResponse(
      logtypes: (json['logtypes'] as List<dynamic>?)
              ?.map((e) => TornLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornLogTypesResponseToJson(
        TornLogTypesResponse instance) =>
    <String, dynamic>{
      'logtypes': instance.logtypes?.map((e) => e.toJson()).toList(),
    };

TornLogCategoriesResponse _$TornLogCategoriesResponseFromJson(
        Map<String, dynamic> json) =>
    TornLogCategoriesResponse(
      logcategories: (json['logcategories'] as List<dynamic>?)
              ?.map((e) => TornLogCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornLogCategoriesResponseToJson(
        TornLogCategoriesResponse instance) =>
    <String, dynamic>{
      'logcategories': instance.logcategories?.map((e) => e.toJson()).toList(),
    };

Bounty _$BountyFromJson(Map<String, dynamic> json) => Bounty(
      targetId: (json['target_id'] as num?)?.toInt(),
      targetName: json['target_name'] as String?,
      targetLevel: (json['target_level'] as num?)?.toInt(),
      listerId: (json['lister_id'] as num?)?.toInt(),
      listerName: json['lister_name'] as String?,
      reward: (json['reward'] as num?)?.toInt(),
      reason: json['reason'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      isAnonymous: json['is_anonymous'] as bool?,
      validUntil: (json['valid_until'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BountyToJson(Bounty instance) => <String, dynamic>{
      'target_id': instance.targetId,
      'target_name': instance.targetName,
      'target_level': instance.targetLevel,
      'lister_id': instance.listerId,
      'lister_name': instance.listerName,
      'reward': instance.reward,
      'reason': instance.reason,
      'quantity': instance.quantity,
      'is_anonymous': instance.isAnonymous,
      'valid_until': instance.validUntil,
    };

TornBountiesResponse _$TornBountiesResponseFromJson(
        Map<String, dynamic> json) =>
    TornBountiesResponse(
      bounties: (json['bounties'] as List<dynamic>?)
              ?.map((e) => Bounty.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornBountiesResponseToJson(
        TornBountiesResponse instance) =>
    <String, dynamic>{
      'bounties': instance.bounties?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

TornLookupResponse _$TornLookupResponseFromJson(Map<String, dynamic> json) =>
    TornLookupResponse(
      selections: tornSelectionNameListFromJson(json['selections'] as List?),
    );

Map<String, dynamic> _$TornLookupResponseToJson(TornLookupResponse instance) =>
    <String, dynamic>{
      'selections': tornSelectionNameListToJson(instance.selections),
    };

PersonalStatsOther _$PersonalStatsOtherFromJson(Map<String, dynamic> json) =>
    PersonalStatsOther(
      other: json['other'] == null
          ? null
          : PersonalStatsOther$Other.fromJson(
              json['other'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsOtherToJson(PersonalStatsOther instance) =>
    <String, dynamic>{
      'other': instance.other?.toJson(),
    };

PersonalStatsOtherPopular _$PersonalStatsOtherPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOtherPopular(
      other: json['other'] == null
          ? null
          : PersonalStatsOtherPopular$Other.fromJson(
              json['other'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsOtherPopularToJson(
        PersonalStatsOtherPopular instance) =>
    <String, dynamic>{
      'other': instance.other?.toJson(),
    };

PersonalStatsNetworthExtended _$PersonalStatsNetworthExtendedFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsNetworthExtended(
      networth: json['networth'] == null
          ? null
          : PersonalStatsNetworthExtended$Networth.fromJson(
              json['networth'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsNetworthExtendedToJson(
        PersonalStatsNetworthExtended instance) =>
    <String, dynamic>{
      'networth': instance.networth?.toJson(),
    };

PersonalStatsNetworthPublic _$PersonalStatsNetworthPublicFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsNetworthPublic(
      networth: json['networth'] == null
          ? null
          : PersonalStatsNetworthPublic$Networth.fromJson(
              json['networth'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsNetworthPublicToJson(
        PersonalStatsNetworthPublic instance) =>
    <String, dynamic>{
      'networth': instance.networth?.toJson(),
    };

PersonalStatsRacing _$PersonalStatsRacingFromJson(Map<String, dynamic> json) =>
    PersonalStatsRacing(
      racing: json['racing'] == null
          ? null
          : PersonalStatsRacing$Racing.fromJson(
              json['racing'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsRacingToJson(
        PersonalStatsRacing instance) =>
    <String, dynamic>{
      'racing': instance.racing?.toJson(),
    };

PersonalStatsMissions _$PersonalStatsMissionsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsMissions(
      missions: json['missions'] == null
          ? null
          : PersonalStatsMissions$Missions.fromJson(
              json['missions'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsMissionsToJson(
        PersonalStatsMissions instance) =>
    <String, dynamic>{
      'missions': instance.missions?.toJson(),
    };

PersonalStatsDrugs _$PersonalStatsDrugsFromJson(Map<String, dynamic> json) =>
    PersonalStatsDrugs(
      drugs: json['drugs'] == null
          ? null
          : PersonalStatsDrugs$Drugs.fromJson(
              json['drugs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsDrugsToJson(PersonalStatsDrugs instance) =>
    <String, dynamic>{
      'drugs': instance.drugs?.toJson(),
    };

PersonalStatsTravel _$PersonalStatsTravelFromJson(Map<String, dynamic> json) =>
    PersonalStatsTravel(
      travel: json['travel'] == null
          ? null
          : PersonalStatsTravel$Travel.fromJson(
              json['travel'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsTravelToJson(
        PersonalStatsTravel instance) =>
    <String, dynamic>{
      'travel': instance.travel?.toJson(),
    };

PersonalStatsTravelPopular _$PersonalStatsTravelPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTravelPopular(
      travel: json['travel'] == null
          ? null
          : PersonalStatsTravelPopular$Travel.fromJson(
              json['travel'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsTravelPopularToJson(
        PersonalStatsTravelPopular instance) =>
    <String, dynamic>{
      'travel': instance.travel?.toJson(),
    };

PersonalStatsItems _$PersonalStatsItemsFromJson(Map<String, dynamic> json) =>
    PersonalStatsItems(
      items: json['items'] == null
          ? null
          : PersonalStatsItems$Items.fromJson(
              json['items'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsItemsToJson(PersonalStatsItems instance) =>
    <String, dynamic>{
      'items': instance.items?.toJson(),
    };

PersonalStatsItemsPopular _$PersonalStatsItemsPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsItemsPopular(
      items: json['items'] == null
          ? null
          : PersonalStatsItemsPopular$Items.fromJson(
              json['items'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsItemsPopularToJson(
        PersonalStatsItemsPopular instance) =>
    <String, dynamic>{
      'items': instance.items?.toJson(),
    };

PersonalStatsInvestments _$PersonalStatsInvestmentsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsInvestments(
      investments: json['investments'] == null
          ? null
          : PersonalStatsInvestments$Investments.fromJson(
              json['investments'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsInvestmentsToJson(
        PersonalStatsInvestments instance) =>
    <String, dynamic>{
      'investments': instance.investments?.toJson(),
    };

PersonalStatsBounties _$PersonalStatsBountiesFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsBounties(
      bounties: json['bounties'] == null
          ? null
          : PersonalStatsBounties$Bounties.fromJson(
              json['bounties'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsBountiesToJson(
        PersonalStatsBounties instance) =>
    <String, dynamic>{
      'bounties': instance.bounties?.toJson(),
    };

PersonalStatsCrimesV2 _$PersonalStatsCrimesV2FromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCrimesV2(
      offenses: json['offenses'] == null
          ? null
          : PersonalStatsCrimesV2$Offenses.fromJson(
              json['offenses'] as Map<String, dynamic>),
      skills: json['skills'] == null
          ? null
          : PersonalStatsCrimesV2$Skills.fromJson(
              json['skills'] as Map<String, dynamic>),
      version: json['version'] as String?,
    );

Map<String, dynamic> _$PersonalStatsCrimesV2ToJson(
        PersonalStatsCrimesV2 instance) =>
    <String, dynamic>{
      'offenses': instance.offenses?.toJson(),
      'skills': instance.skills?.toJson(),
      'version': instance.version,
    };

PersonalStatsCrimesV1 _$PersonalStatsCrimesV1FromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCrimesV1(
      total: (json['total'] as num?)?.toInt(),
      sellIllegalGoods: (json['sell_illegal_goods'] as num?)?.toInt(),
      theft: (json['theft'] as num?)?.toInt(),
      autoTheft: (json['auto_theft'] as num?)?.toInt(),
      drugDeals: (json['drug_deals'] as num?)?.toInt(),
      computer: (json['computer'] as num?)?.toInt(),
      fraud: (json['fraud'] as num?)?.toInt(),
      murder: (json['murder'] as num?)?.toInt(),
      other: (json['other'] as num?)?.toInt(),
      organizedCrimes: (json['organized_crimes'] as num?)?.toInt(),
      version: json['version'] as String?,
    );

Map<String, dynamic> _$PersonalStatsCrimesV1ToJson(
        PersonalStatsCrimesV1 instance) =>
    <String, dynamic>{
      'total': instance.total,
      'sell_illegal_goods': instance.sellIllegalGoods,
      'theft': instance.theft,
      'auto_theft': instance.autoTheft,
      'drug_deals': instance.drugDeals,
      'computer': instance.computer,
      'fraud': instance.fraud,
      'murder': instance.murder,
      'other': instance.other,
      'organized_crimes': instance.organizedCrimes,
      'version': instance.version,
    };

PersonalStatsCrimesPopular _$PersonalStatsCrimesPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCrimesPopular(
      crimes: json['crimes'] == null
          ? null
          : PersonalStatsCrimesPopular$Crimes.fromJson(
              json['crimes'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsCrimesPopularToJson(
        PersonalStatsCrimesPopular instance) =>
    <String, dynamic>{
      'crimes': instance.crimes?.toJson(),
    };

PersonalStatsCommunication _$PersonalStatsCommunicationFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCommunication(
      communication: json['communication'] == null
          ? null
          : PersonalStatsCommunication$Communication.fromJson(
              json['communication'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsCommunicationToJson(
        PersonalStatsCommunication instance) =>
    <String, dynamic>{
      'communication': instance.communication?.toJson(),
    };

PersonalStatsFinishingHits _$PersonalStatsFinishingHitsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsFinishingHits(
      finishingHits: json['finishing_hits'] == null
          ? null
          : PersonalStatsFinishingHits$FinishingHits.fromJson(
              json['finishing_hits'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsFinishingHitsToJson(
        PersonalStatsFinishingHits instance) =>
    <String, dynamic>{
      'finishing_hits': instance.finishingHits?.toJson(),
    };

PersonalStatsHospital _$PersonalStatsHospitalFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsHospital(
      hospital: json['hospital'] == null
          ? null
          : PersonalStatsHospital$Hospital.fromJson(
              json['hospital'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsHospitalToJson(
        PersonalStatsHospital instance) =>
    <String, dynamic>{
      'hospital': instance.hospital?.toJson(),
    };

PersonalStatsHospitalPopular _$PersonalStatsHospitalPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsHospitalPopular(
      hospital: json['hospital'] == null
          ? null
          : PersonalStatsHospitalPopular$Hospital.fromJson(
              json['hospital'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsHospitalPopularToJson(
        PersonalStatsHospitalPopular instance) =>
    <String, dynamic>{
      'hospital': instance.hospital?.toJson(),
    };

PersonalStatsJail _$PersonalStatsJailFromJson(Map<String, dynamic> json) =>
    PersonalStatsJail(
      jail: json['jail'] == null
          ? null
          : PersonalStatsJail$Jail.fromJson(
              json['jail'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJailToJson(PersonalStatsJail instance) =>
    <String, dynamic>{
      'jail': instance.jail?.toJson(),
    };

PersonalStatsTrading _$PersonalStatsTradingFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTrading(
      trading: json['trading'] == null
          ? null
          : PersonalStatsTrading$Trading.fromJson(
              json['trading'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsTradingToJson(
        PersonalStatsTrading instance) =>
    <String, dynamic>{
      'trading': instance.trading?.toJson(),
    };

PersonalStatsJobsPublic _$PersonalStatsJobsPublicFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJobsPublic(
      jobs: json['jobs'] == null
          ? null
          : PersonalStatsJobsPublic$Jobs.fromJson(
              json['jobs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJobsPublicToJson(
        PersonalStatsJobsPublic instance) =>
    <String, dynamic>{
      'jobs': instance.jobs?.toJson(),
    };

PersonalStatsJobsExtended _$PersonalStatsJobsExtendedFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJobsExtended(
      jobs: json['jobs'] == null
          ? null
          : PersonalStatsJobsExtended$Jobs.fromJson(
              json['jobs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJobsExtendedToJson(
        PersonalStatsJobsExtended instance) =>
    <String, dynamic>{
      'jobs': instance.jobs?.toJson(),
    };

PersonalStatsBattleStats _$PersonalStatsBattleStatsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsBattleStats(
      battleStats: json['battle_stats'] == null
          ? null
          : PersonalStatsBattleStats$BattleStats.fromJson(
              json['battle_stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsBattleStatsToJson(
        PersonalStatsBattleStats instance) =>
    <String, dynamic>{
      'battle_stats': instance.battleStats?.toJson(),
    };

PersonalStatsAttackingPublic _$PersonalStatsAttackingPublicFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsAttackingPublic(
      attacking: json['attacking'] == null
          ? null
          : PersonalStatsAttackingPublic$Attacking.fromJson(
              json['attacking'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsAttackingPublicToJson(
        PersonalStatsAttackingPublic instance) =>
    <String, dynamic>{
      'attacking': instance.attacking?.toJson(),
    };

PersonalStatsAttackingExtended _$PersonalStatsAttackingExtendedFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsAttackingExtended(
      attacking: json['attacking'] == null
          ? null
          : PersonalStatsAttackingExtended$Attacking.fromJson(
              json['attacking'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsAttackingExtendedToJson(
        PersonalStatsAttackingExtended instance) =>
    <String, dynamic>{
      'attacking': instance.attacking?.toJson(),
    };

PersonalStatsAttackingPopular _$PersonalStatsAttackingPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsAttackingPopular(
      attacking: json['attacking'] == null
          ? null
          : PersonalStatsAttackingPopular$Attacking.fromJson(
              json['attacking'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsAttackingPopularToJson(
        PersonalStatsAttackingPopular instance) =>
    <String, dynamic>{
      'attacking': instance.attacking?.toJson(),
    };

PersonalStatsHistoricStat _$PersonalStatsHistoricStatFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsHistoricStat(
      name: json['name'] as String?,
      $value: (json['value'] as num?)?.toInt(),
      timestamp: (json['timestamp'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsHistoricStatToJson(
        PersonalStatsHistoricStat instance) =>
    <String, dynamic>{
      'name': instance.name,
      'value': instance.$value,
      'timestamp': instance.timestamp,
    };

UserPersonalStatsHistoric _$UserPersonalStatsHistoricFromJson(
        Map<String, dynamic> json) =>
    UserPersonalStatsHistoric(
      personalstats: (json['personalstats'] as List<dynamic>?)
              ?.map((e) =>
                  PersonalStatsHistoricStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserPersonalStatsHistoricToJson(
        UserPersonalStatsHistoric instance) =>
    <String, dynamic>{
      'personalstats': instance.personalstats?.map((e) => e.toJson()).toList(),
    };

PersonalStatsCrimes _$PersonalStatsCrimesFromJson(Map<String, dynamic> json) =>
    PersonalStatsCrimes(
      crimes: json['crimes'],
    );

Map<String, dynamic> _$PersonalStatsCrimesToJson(
        PersonalStatsCrimes instance) =>
    <String, dynamic>{
      'crimes': instance.crimes,
    };

UserPersonalStatsPopular _$UserPersonalStatsPopularFromJson(
        Map<String, dynamic> json) =>
    UserPersonalStatsPopular(
      personalstats: json['personalstats'],
    );

Map<String, dynamic> _$UserPersonalStatsPopularToJson(
        UserPersonalStatsPopular instance) =>
    <String, dynamic>{
      'personalstats': instance.personalstats,
    };

UserPersonalStatsCategory _$UserPersonalStatsCategoryFromJson(
        Map<String, dynamic> json) =>
    UserPersonalStatsCategory(
      personalstats: json['personalstats'],
    );

Map<String, dynamic> _$UserPersonalStatsCategoryToJson(
        UserPersonalStatsCategory instance) =>
    <String, dynamic>{
      'personalstats': instance.personalstats,
    };

UserPersonalStatsFull _$UserPersonalStatsFullFromJson(
        Map<String, dynamic> json) =>
    UserPersonalStatsFull(
      personalstats: json['personalstats'],
    );

Map<String, dynamic> _$UserPersonalStatsFullToJson(
        UserPersonalStatsFull instance) =>
    <String, dynamic>{
      'personalstats': instance.personalstats,
    };

UserPersonalStatsFullPublic _$UserPersonalStatsFullPublicFromJson(
        Map<String, dynamic> json) =>
    UserPersonalStatsFullPublic(
      personalstats: json['personalstats'],
    );

Map<String, dynamic> _$UserPersonalStatsFullPublicToJson(
        UserPersonalStatsFullPublic instance) =>
    <String, dynamic>{
      'personalstats': instance.personalstats,
    };

UserPersonalStatsResponse _$UserPersonalStatsResponseFromJson(
        Map<String, dynamic> json) =>
    UserPersonalStatsResponse();

Map<String, dynamic> _$UserPersonalStatsResponseToJson(
        UserPersonalStatsResponse instance) =>
    <String, dynamic>{};

UserCrimeDetailsBootlegging _$UserCrimeDetailsBootleggingFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsBootlegging(
      onlineStore: json['online_store'] == null
          ? null
          : UserCrimeDetailsBootlegging$OnlineStore.fromJson(
              json['online_store'] as Map<String, dynamic>),
      dvdSales: json['dvd_sales'] == null
          ? null
          : UserCrimeDetailsBootlegging$DvdSales.fromJson(
              json['dvd_sales'] as Map<String, dynamic>),
      dvdsCopied: (json['dvds_copied'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsBootleggingToJson(
        UserCrimeDetailsBootlegging instance) =>
    <String, dynamic>{
      'online_store': instance.onlineStore?.toJson(),
      'dvd_sales': instance.dvdSales?.toJson(),
      'dvds_copied': instance.dvdsCopied,
    };

UserCrimeDetailsGraffiti _$UserCrimeDetailsGraffitiFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsGraffiti(
      cansUsed: (json['cans_used'] as num?)?.toInt(),
      mostGraffitiInOneArea:
          (json['most_graffiti_in_one_area'] as num?)?.toInt(),
      mostGraffitiSimultaneously:
          (json['most_graffiti_simultaneously'] as num?)?.toInt(),
      graffitiRemoved: (json['graffiti_removed'] as num?)?.toInt(),
      costToCity: (json['cost_to_city'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsGraffitiToJson(
        UserCrimeDetailsGraffiti instance) =>
    <String, dynamic>{
      'cans_used': instance.cansUsed,
      'most_graffiti_in_one_area': instance.mostGraffitiInOneArea,
      'most_graffiti_simultaneously': instance.mostGraffitiSimultaneously,
      'graffiti_removed': instance.graffitiRemoved,
      'cost_to_city': instance.costToCity,
    };

UserCrimeDetailsShoplifting _$UserCrimeDetailsShopliftingFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsShoplifting(
      averageNotoriety: (json['average_notoriety'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsShopliftingToJson(
        UserCrimeDetailsShoplifting instance) =>
    <String, dynamic>{
      'average_notoriety': instance.averageNotoriety,
    };

UserCrimeDetailsCardSkimming _$UserCrimeDetailsCardSkimmingFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsCardSkimming(
      cardDetails: json['card_details'] == null
          ? null
          : UserCrimeDetailsCardSkimming$CardDetails.fromJson(
              json['card_details'] as Map<String, dynamic>),
      skimmers: json['skimmers'] == null
          ? null
          : UserCrimeDetailsCardSkimming$Skimmers.fromJson(
              json['skimmers'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCrimeDetailsCardSkimmingToJson(
        UserCrimeDetailsCardSkimming instance) =>
    <String, dynamic>{
      'card_details': instance.cardDetails?.toJson(),
      'skimmers': instance.skimmers?.toJson(),
    };

UserCrimeDetailsHustling _$UserCrimeDetailsHustlingFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsHustling(
      totalAudienceGathered: (json['total_audience_gathered'] as num?)?.toInt(),
      biggestMoneyWon: (json['biggest_money_won'] as num?)?.toInt(),
      shillMoneyCollected: (json['shill_money_collected'] as num?)?.toInt(),
      pickpocketMoneyCollected:
          (json['pickpocket_money_collected'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsHustlingToJson(
        UserCrimeDetailsHustling instance) =>
    <String, dynamic>{
      'total_audience_gathered': instance.totalAudienceGathered,
      'biggest_money_won': instance.biggestMoneyWon,
      'shill_money_collected': instance.shillMoneyCollected,
      'pickpocket_money_collected': instance.pickpocketMoneyCollected,
    };

UserCrimeDetailsCracking _$UserCrimeDetailsCrackingFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsCracking(
      bruteForceCycles: (json['brute_force_cycles'] as num?)?.toInt(),
      encryptionLayersBroken:
          (json['encryption_layers_broken'] as num?)?.toInt(),
      highestMips: (json['highest_mips'] as num?)?.toInt(),
      charsGuessed: (json['chars_guessed'] as num?)?.toInt(),
      charsGuessedTotal: (json['chars_guessed_total'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsCrackingToJson(
        UserCrimeDetailsCracking instance) =>
    <String, dynamic>{
      'brute_force_cycles': instance.bruteForceCycles,
      'encryption_layers_broken': instance.encryptionLayersBroken,
      'highest_mips': instance.highestMips,
      'chars_guessed': instance.charsGuessed,
      'chars_guessed_total': instance.charsGuessedTotal,
    };

UserCrimeDetailsScamming _$UserCrimeDetailsScammingFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsScamming(
      mostResponses: (json['most_responses'] as num?)?.toInt(),
      zones: json['zones'] == null
          ? null
          : UserCrimeDetailsScamming$Zones.fromJson(
              json['zones'] as Map<String, dynamic>),
      concerns: json['concerns'] == null
          ? null
          : UserCrimeDetailsScamming$Concerns.fromJson(
              json['concerns'] as Map<String, dynamic>),
      payouts: json['payouts'] == null
          ? null
          : UserCrimeDetailsScamming$Payouts.fromJson(
              json['payouts'] as Map<String, dynamic>),
      emails: json['emails'] == null
          ? null
          : UserCrimeDetailsScamming$Emails.fromJson(
              json['emails'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCrimeDetailsScammingToJson(
        UserCrimeDetailsScamming instance) =>
    <String, dynamic>{
      'most_responses': instance.mostResponses,
      'zones': instance.zones?.toJson(),
      'concerns': instance.concerns?.toJson(),
      'payouts': instance.payouts?.toJson(),
      'emails': instance.emails?.toJson(),
    };

UserSubcrime _$UserSubcrimeFromJson(Map<String, dynamic> json) => UserSubcrime(
      id: (json['id'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      success: (json['success'] as num?)?.toInt(),
      fail: (json['fail'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserSubcrimeToJson(UserSubcrime instance) =>
    <String, dynamic>{
      'id': instance.id,
      'total': instance.total,
      'success': instance.success,
      'fail': instance.fail,
    };

UserCrimeRewardAmmo _$UserCrimeRewardAmmoFromJson(Map<String, dynamic> json) =>
    UserCrimeRewardAmmo(
      standard: (json['standard'] as num?)?.toInt(),
      special: (json['special'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeRewardAmmoToJson(
        UserCrimeRewardAmmo instance) =>
    <String, dynamic>{
      'standard': instance.standard,
      'special': instance.special,
    };

UserCrimeRewardItem _$UserCrimeRewardItemFromJson(Map<String, dynamic> json) =>
    UserCrimeRewardItem(
      id: (json['id'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeRewardItemToJson(
        UserCrimeRewardItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
    };

UserCrimeRewards _$UserCrimeRewardsFromJson(Map<String, dynamic> json) =>
    UserCrimeRewards(
      money: (json['money'] as num?)?.toInt(),
      ammo: json['ammo'] == null
          ? null
          : UserCrimeRewardAmmo.fromJson(json['ammo'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  UserCrimeRewardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserCrimeRewardsToJson(UserCrimeRewards instance) =>
    <String, dynamic>{
      'money': instance.money,
      'ammo': instance.ammo?.toJson(),
      'items': instance.items?.map((e) => e.toJson()).toList(),
    };

UserCrimeAttempts _$UserCrimeAttemptsFromJson(Map<String, dynamic> json) =>
    UserCrimeAttempts(
      total: (json['total'] as num?)?.toInt(),
      success: (json['success'] as num?)?.toInt(),
      fail: (json['fail'] as num?)?.toInt(),
      criticalFail: (json['critical_fail'] as num?)?.toInt(),
      subcrimes: (json['subcrimes'] as List<dynamic>?)
              ?.map((e) => UserSubcrime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserCrimeAttemptsToJson(UserCrimeAttempts instance) =>
    <String, dynamic>{
      'total': instance.total,
      'success': instance.success,
      'fail': instance.fail,
      'critical_fail': instance.criticalFail,
      'subcrimes': instance.subcrimes?.map((e) => e.toJson()).toList(),
    };

UserCrimeUniquesRewardMoney _$UserCrimeUniquesRewardMoneyFromJson(
        Map<String, dynamic> json) =>
    UserCrimeUniquesRewardMoney(
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeUniquesRewardMoneyToJson(
        UserCrimeUniquesRewardMoney instance) =>
    <String, dynamic>{
      'min': instance.min,
      'max': instance.max,
    };

UserCrimeUniquesRewardAmmo _$UserCrimeUniquesRewardAmmoFromJson(
        Map<String, dynamic> json) =>
    UserCrimeUniquesRewardAmmo(
      amount: (json['amount'] as num?)?.toInt(),
      type: userCrimeUniquesRewardAmmoEnumNullableFromJson(json['type']),
    );

Map<String, dynamic> _$UserCrimeUniquesRewardAmmoToJson(
        UserCrimeUniquesRewardAmmo instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'type': userCrimeUniquesRewardAmmoEnumNullableToJson(instance.type),
    };

UserCrimeUniquesReward _$UserCrimeUniquesRewardFromJson(
        Map<String, dynamic> json) =>
    UserCrimeUniquesReward(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  UserCrimeRewardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      money: json['money'] == null
          ? null
          : UserCrimeUniquesRewardMoney.fromJson(
              json['money'] as Map<String, dynamic>),
      ammo: json['ammo'] == null
          ? null
          : UserCrimeUniquesRewardAmmo.fromJson(
              json['ammo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCrimeUniquesRewardToJson(
        UserCrimeUniquesReward instance) =>
    <String, dynamic>{
      'items': instance.items?.map((e) => e.toJson()).toList(),
      'money': instance.money?.toJson(),
      'ammo': instance.ammo?.toJson(),
    };

UserCrimeUniques _$UserCrimeUniquesFromJson(Map<String, dynamic> json) =>
    UserCrimeUniques(
      id: (json['id'] as num?)?.toInt(),
      rewards: (json['rewards'] as List<dynamic>?)
              ?.map((e) =>
                  UserCrimeUniquesReward.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserCrimeUniquesToJson(UserCrimeUniques instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rewards': instance.rewards?.map((e) => e.toJson()).toList(),
    };

UserCrimesResponse _$UserCrimesResponseFromJson(Map<String, dynamic> json) =>
    UserCrimesResponse(
      crimes: json['crimes'] == null
          ? null
          : UserCrime.fromJson(json['crimes'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCrimesResponseToJson(UserCrimesResponse instance) =>
    <String, dynamic>{
      'crimes': instance.crimes?.toJson(),
    };

UserCrime _$UserCrimeFromJson(Map<String, dynamic> json) => UserCrime(
      nerveSpent: (json['nerve_spent'] as num?)?.toInt(),
      skill: (json['skill'] as num?)?.toInt(),
      progressionBonus: (json['progression_bonus'] as num?)?.toInt(),
      rewards: json['rewards'] == null
          ? null
          : UserCrimeRewards.fromJson(json['rewards'] as Map<String, dynamic>),
      attempts: json['attempts'] == null
          ? null
          : UserCrimeAttempts.fromJson(
              json['attempts'] as Map<String, dynamic>),
      uniques: (json['uniques'] as List<dynamic>?)
              ?.map((e) => UserCrimeUniques.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      miscellaneous: json['miscellaneous'],
    );

Map<String, dynamic> _$UserCrimeToJson(UserCrime instance) => <String, dynamic>{
      'nerve_spent': instance.nerveSpent,
      'skill': instance.skill,
      'progression_bonus': instance.progressionBonus,
      'rewards': instance.rewards?.toJson(),
      'attempts': instance.attempts?.toJson(),
      'uniques': instance.uniques?.map((e) => e.toJson()).toList(),
      'miscellaneous': instance.miscellaneous,
    };

UserRacesResponse _$UserRacesResponseFromJson(Map<String, dynamic> json) =>
    UserRacesResponse(
      races: (json['races'] as List<dynamic>?)
              ?.map((e) =>
                  RacingRaceDetailsResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserRacesResponseToJson(UserRacesResponse instance) =>
    <String, dynamic>{
      'races': instance.races?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

UserRaceCarDetails _$UserRaceCarDetailsFromJson(Map<String, dynamic> json) =>
    UserRaceCarDetails(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      worth: (json['worth'] as num?)?.toInt(),
      pointsSpent: (json['points_spent'] as num?)?.toInt(),
      racesEntered: (json['races_entered'] as num?)?.toInt(),
      racesWon: (json['races_won'] as num?)?.toInt(),
      isRemoved: json['is_removed'] as bool?,
      parts: (json['parts'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      carItemId: (json['car_item_id'] as num?)?.toInt(),
      carItemName: json['car_item_name'] as String?,
      topSpeed: (json['top_speed'] as num?)?.toInt(),
      acceleration: (json['acceleration'] as num?)?.toInt(),
      braking: (json['braking'] as num?)?.toInt(),
      dirt: (json['dirt'] as num?)?.toInt(),
      handling: (json['handling'] as num?)?.toInt(),
      safety: (json['safety'] as num?)?.toInt(),
      tarmac: (json['tarmac'] as num?)?.toInt(),
      $class: raceClassEnumNullableFromJson(json['class']),
    );

Map<String, dynamic> _$UserRaceCarDetailsToJson(UserRaceCarDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'worth': instance.worth,
      'points_spent': instance.pointsSpent,
      'races_entered': instance.racesEntered,
      'races_won': instance.racesWon,
      'is_removed': instance.isRemoved,
      'parts': instance.parts,
      'car_item_id': instance.carItemId,
      'car_item_name': instance.carItemName,
      'top_speed': instance.topSpeed,
      'acceleration': instance.acceleration,
      'braking': instance.braking,
      'dirt': instance.dirt,
      'handling': instance.handling,
      'safety': instance.safety,
      'tarmac': instance.tarmac,
      'class': raceClassEnumNullableToJson(instance.$class),
    };

UserEnlistedCarsResponse _$UserEnlistedCarsResponseFromJson(
        Map<String, dynamic> json) =>
    UserEnlistedCarsResponse(
      enlistedcars: (json['enlistedcars'] as List<dynamic>?)
              ?.map(
                  (e) => UserRaceCarDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserEnlistedCarsResponseToJson(
        UserEnlistedCarsResponse instance) =>
    <String, dynamic>{
      'enlistedcars': instance.enlistedcars?.map((e) => e.toJson()).toList(),
    };

UserForumPostsResponse _$UserForumPostsResponseFromJson(
        Map<String, dynamic> json) =>
    UserForumPostsResponse(
      forumPosts: (json['forumPosts'] as List<dynamic>?)
              ?.map((e) => ForumPost.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserForumPostsResponseToJson(
        UserForumPostsResponse instance) =>
    <String, dynamic>{
      'forumPosts': instance.forumPosts?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

UserForumThreadsResponse _$UserForumThreadsResponseFromJson(
        Map<String, dynamic> json) =>
    UserForumThreadsResponse(
      forumThreads: (json['forumThreads'] as List<dynamic>?)
              ?.map((e) =>
                  ForumThreadUserExtended.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserForumThreadsResponseToJson(
        UserForumThreadsResponse instance) =>
    <String, dynamic>{
      'forumThreads': instance.forumThreads?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

UserForumSubscribedThreadsResponse _$UserForumSubscribedThreadsResponseFromJson(
        Map<String, dynamic> json) =>
    UserForumSubscribedThreadsResponse(
      forumSubscribedThreads: (json['forumSubscribedThreads'] as List<dynamic>?)
              ?.map((e) =>
                  ForumSubscribedThread.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserForumSubscribedThreadsResponseToJson(
        UserForumSubscribedThreadsResponse instance) =>
    <String, dynamic>{
      'forumSubscribedThreads':
          instance.forumSubscribedThreads?.map((e) => e.toJson()).toList(),
    };

UserForumFeedResponse _$UserForumFeedResponseFromJson(
        Map<String, dynamic> json) =>
    UserForumFeedResponse(
      forumFeed: (json['forumFeed'] as List<dynamic>?)
              ?.map((e) => ForumFeed.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserForumFeedResponseToJson(
        UserForumFeedResponse instance) =>
    <String, dynamic>{
      'forumFeed': instance.forumFeed?.map((e) => e.toJson()).toList(),
    };

UserForumFriendsResponse _$UserForumFriendsResponseFromJson(
        Map<String, dynamic> json) =>
    UserForumFriendsResponse(
      forumFriends: (json['forumFriends'] as List<dynamic>?)
              ?.map((e) => ForumFeed.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserForumFriendsResponseToJson(
        UserForumFriendsResponse instance) =>
    <String, dynamic>{
      'forumFriends': instance.forumFriends?.map((e) => e.toJson()).toList(),
    };

HofValue _$HofValueFromJson(Map<String, dynamic> json) => HofValue(
      $value: (json['value'] as num?)?.toInt(),
      rank: (json['rank'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HofValueToJson(HofValue instance) => <String, dynamic>{
      'value': instance.$value,
      'rank': instance.rank,
    };

HofValueString _$HofValueStringFromJson(Map<String, dynamic> json) =>
    HofValueString(
      $value: json['value'] as String?,
      rank: (json['rank'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HofValueStringToJson(HofValueString instance) =>
    <String, dynamic>{
      'value': instance.$value,
      'rank': instance.rank,
    };

UserHofStats _$UserHofStatsFromJson(Map<String, dynamic> json) => UserHofStats(
      attacks: json['attacks'] == null
          ? null
          : HofValue.fromJson(json['attacks'] as Map<String, dynamic>),
      busts: json['busts'] == null
          ? null
          : HofValue.fromJson(json['busts'] as Map<String, dynamic>),
      defends: json['defends'] == null
          ? null
          : HofValue.fromJson(json['defends'] as Map<String, dynamic>),
      networth: json['networth'] == null
          ? null
          : HofValue.fromJson(json['networth'] as Map<String, dynamic>),
      offences: json['offences'] == null
          ? null
          : HofValue.fromJson(json['offences'] as Map<String, dynamic>),
      revives: json['revives'] == null
          ? null
          : HofValue.fromJson(json['revives'] as Map<String, dynamic>),
      level: json['level'] == null
          ? null
          : HofValue.fromJson(json['level'] as Map<String, dynamic>),
      rank: json['rank'] == null
          ? null
          : HofValue.fromJson(json['rank'] as Map<String, dynamic>),
      awards: json['awards'] == null
          ? null
          : HofValue.fromJson(json['awards'] as Map<String, dynamic>),
      racingSkill: json['racing_skill'] == null
          ? null
          : HofValue.fromJson(json['racing_skill'] as Map<String, dynamic>),
      racingPoints: json['racing_points'] == null
          ? null
          : HofValue.fromJson(json['racing_points'] as Map<String, dynamic>),
      racingWins: json['racing_wins'] == null
          ? null
          : HofValue.fromJson(json['racing_wins'] as Map<String, dynamic>),
      travelTime: json['travel_time'] == null
          ? null
          : HofValue.fromJson(json['travel_time'] as Map<String, dynamic>),
      workingStats: json['working_stats'] == null
          ? null
          : HofValue.fromJson(json['working_stats'] as Map<String, dynamic>),
      battleStats: json['battle_stats'] == null
          ? null
          : HofValue.fromJson(json['battle_stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserHofStatsToJson(UserHofStats instance) =>
    <String, dynamic>{
      'attacks': instance.attacks?.toJson(),
      'busts': instance.busts?.toJson(),
      'defends': instance.defends?.toJson(),
      'networth': instance.networth?.toJson(),
      'offences': instance.offences?.toJson(),
      'revives': instance.revives?.toJson(),
      'level': instance.level?.toJson(),
      'rank': instance.rank?.toJson(),
      'awards': instance.awards?.toJson(),
      'racing_skill': instance.racingSkill?.toJson(),
      'racing_points': instance.racingPoints?.toJson(),
      'racing_wins': instance.racingWins?.toJson(),
      'travel_time': instance.travelTime?.toJson(),
      'working_stats': instance.workingStats?.toJson(),
      'battle_stats': instance.battleStats?.toJson(),
    };

UserHofResponse _$UserHofResponseFromJson(Map<String, dynamic> json) =>
    UserHofResponse(
      hof: (json['hof'] as List<dynamic>?)
              ?.map((e) => UserHofStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserHofResponseToJson(UserHofResponse instance) =>
    <String, dynamic>{
      'hof': instance.hof?.map((e) => e.toJson()).toList(),
    };

UserCalendar _$UserCalendarFromJson(Map<String, dynamic> json) => UserCalendar(
      startTime: json['start_time'] as String?,
    );

Map<String, dynamic> _$UserCalendarToJson(UserCalendar instance) =>
    <String, dynamic>{
      'start_time': instance.startTime,
    };

UserCalendarResponse _$UserCalendarResponseFromJson(
        Map<String, dynamic> json) =>
    UserCalendarResponse(
      calendar: json['calendar'] == null
          ? null
          : UserCalendar.fromJson(json['calendar'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCalendarResponseToJson(
        UserCalendarResponse instance) =>
    <String, dynamic>{
      'calendar': instance.calendar?.toJson(),
    };

UserBountiesResponse _$UserBountiesResponseFromJson(
        Map<String, dynamic> json) =>
    UserBountiesResponse(
      bounties: (json['bounties'] as List<dynamic>?)
              ?.map((e) => Bounty.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserBountiesResponseToJson(
        UserBountiesResponse instance) =>
    <String, dynamic>{
      'bounties': instance.bounties?.map((e) => e.toJson()).toList(),
    };

UserJobRanks _$UserJobRanksFromJson(Map<String, dynamic> json) => UserJobRanks(
      army: jobPositionArmyEnumNullableFromJson(json['army']),
      grocer: jobPositionGrocerEnumNullableFromJson(json['grocer']),
      casino: jobPositionCasinoEnumNullableFromJson(json['casino']),
      medical: jobPositionMedicalEnumNullableFromJson(json['medical']),
      law: jobPositionLawEnumNullableFromJson(json['law']),
      education: jobPositionEducationEnumNullableFromJson(json['education']),
    );

Map<String, dynamic> _$UserJobRanksToJson(UserJobRanks instance) =>
    <String, dynamic>{
      'army': jobPositionArmyEnumNullableToJson(instance.army),
      'grocer': jobPositionGrocerEnumNullableToJson(instance.grocer),
      'casino': jobPositionCasinoEnumNullableToJson(instance.casino),
      'medical': jobPositionMedicalEnumNullableToJson(instance.medical),
      'law': jobPositionLawEnumNullableToJson(instance.law),
      'education': jobPositionEducationEnumNullableToJson(instance.education),
    };

UserJobRanksResponse _$UserJobRanksResponseFromJson(
        Map<String, dynamic> json) =>
    UserJobRanksResponse(
      jobranks: json['jobranks'] == null
          ? null
          : UserJobRanks.fromJson(json['jobranks'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserJobRanksResponseToJson(
        UserJobRanksResponse instance) =>
    <String, dynamic>{
      'jobranks': instance.jobranks?.toJson(),
    };

UserItemMarkeListingItemDetails _$UserItemMarkeListingItemDetailsFromJson(
        Map<String, dynamic> json) =>
    UserItemMarkeListingItemDetails(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      type: json['type'] as String?,
      rarity:
          userItemMarkeListingItemDetailsRarityNullableFromJson(json['rarity']),
      uid: (json['uid'] as num?)?.toInt(),
      stats: json['stats'] == null
          ? null
          : ItemMarketListingItemStats.fromJson(
              json['stats'] as Map<String, dynamic>),
      bonuses: (json['bonuses'] as List<dynamic>?)
              ?.map((e) => ItemMarketListingItemBonus.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserItemMarkeListingItemDetailsToJson(
        UserItemMarkeListingItemDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'rarity':
          userItemMarkeListingItemDetailsRarityNullableToJson(instance.rarity),
      'uid': instance.uid,
      'stats': instance.stats?.toJson(),
      'bonuses': instance.bonuses?.map((e) => e.toJson()).toList(),
    };

UserItemMarketListing _$UserItemMarketListingFromJson(
        Map<String, dynamic> json) =>
    UserItemMarketListing(
      id: (json['id'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toInt(),
      averagePrice: (json['average_price'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toInt(),
      isAnonymous: json['is_anonymous'] as bool?,
      available: (json['available'] as num?)?.toInt(),
      item: json['item'] == null
          ? null
          : UserItemMarkeListingItemDetails.fromJson(
              json['item'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserItemMarketListingToJson(
        UserItemMarketListing instance) =>
    <String, dynamic>{
      'id': instance.id,
      'price': instance.price,
      'average_price': instance.averagePrice,
      'amount': instance.amount,
      'is_anonymous': instance.isAnonymous,
      'available': instance.available,
      'item': instance.item?.toJson(),
    };

UserItemMarketResponse _$UserItemMarketResponseFromJson(
        Map<String, dynamic> json) =>
    UserItemMarketResponse(
      itemmarket: (json['itemmarket'] as List<dynamic>?)
              ?.map((e) =>
                  UserItemMarketListing.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserItemMarketResponseToJson(
        UserItemMarketResponse instance) =>
    <String, dynamic>{
      'itemmarket': instance.itemmarket?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

UserFactionBalance _$UserFactionBalanceFromJson(Map<String, dynamic> json) =>
    UserFactionBalance(
      money: (json['money'] as num?)?.toInt(),
      points: (json['points'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserFactionBalanceToJson(UserFactionBalance instance) =>
    <String, dynamic>{
      'money': instance.money,
      'points': instance.points,
    };

UserFactionBalanceResponse _$UserFactionBalanceResponseFromJson(
        Map<String, dynamic> json) =>
    UserFactionBalanceResponse(
      factionBalance: json['factionBalance'],
    );

Map<String, dynamic> _$UserFactionBalanceResponseToJson(
        UserFactionBalanceResponse instance) =>
    <String, dynamic>{
      'factionBalance': instance.factionBalance,
    };

UserOrganizedCrimeResponse _$UserOrganizedCrimeResponseFromJson(
        Map<String, dynamic> json) =>
    UserOrganizedCrimeResponse(
      organizedCrime: json['organizedCrime'],
    );

Map<String, dynamic> _$UserOrganizedCrimeResponseToJson(
        UserOrganizedCrimeResponse instance) =>
    <String, dynamic>{
      'organizedCrime': instance.organizedCrime,
    };

UserLookupResponse _$UserLookupResponseFromJson(Map<String, dynamic> json) =>
    UserLookupResponse(
      selections: userSelectionNameListFromJson(json['selections'] as List?),
    );

Map<String, dynamic> _$UserLookupResponseToJson(UserLookupResponse instance) =>
    <String, dynamic>{
      'selections': userSelectionNameListToJson(instance.selections),
    };

Attack$Modifiers _$Attack$ModifiersFromJson(Map<String, dynamic> json) =>
    Attack$Modifiers(
      fairFight: (json['fair_fight'] as num?)?.toDouble(),
      war: (json['war'] as num?)?.toDouble(),
      retaliation: (json['retaliation'] as num?)?.toDouble(),
      group: (json['group'] as num?)?.toDouble(),
      overseas: (json['overseas'] as num?)?.toDouble(),
      chain: (json['chain'] as num?)?.toDouble(),
      warlord: (json['warlord'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$Attack$ModifiersToJson(Attack$Modifiers instance) =>
    <String, dynamic>{
      'fair_fight': instance.fairFight,
      'war': instance.war,
      'retaliation': instance.retaliation,
      'group': instance.group,
      'overseas': instance.overseas,
      'chain': instance.chain,
      'warlord': instance.warlord,
    };

FactionApplication$User _$FactionApplication$UserFromJson(
        Map<String, dynamic> json) =>
    FactionApplication$User(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      level: json['level'] as String?,
      stats: json['stats'] == null
          ? null
          : FactionApplication$User$Stats.fromJson(
              json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionApplication$UserToJson(
        FactionApplication$User instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'level': instance.level,
      'stats': instance.stats?.toJson(),
    };

ForumCategoriesResponse$Categories$Item
    _$ForumCategoriesResponse$Categories$ItemFromJson(
            Map<String, dynamic> json) =>
        ForumCategoriesResponse$Categories$Item(
          id: (json['id'] as num?)?.toInt(),
          title: json['title'] as String?,
          acronym: json['acronym'] as String?,
          threads: (json['threads'] as num?)?.toInt(),
        );

Map<String, dynamic> _$ForumCategoriesResponse$Categories$ItemToJson(
        ForumCategoriesResponse$Categories$Item instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'acronym': instance.acronym,
      'threads': instance.threads,
    };

RaceCarUpgrade$Effects _$RaceCarUpgrade$EffectsFromJson(
        Map<String, dynamic> json) =>
    RaceCarUpgrade$Effects(
      topSpeed: (json['top_speed'] as num?)?.toInt(),
      acceleration: (json['acceleration'] as num?)?.toInt(),
      braking: (json['braking'] as num?)?.toInt(),
      handling: (json['handling'] as num?)?.toInt(),
      safety: (json['safety'] as num?)?.toInt(),
      dirt: (json['dirt'] as num?)?.toInt(),
      tarmac: (json['tarmac'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RaceCarUpgrade$EffectsToJson(
        RaceCarUpgrade$Effects instance) =>
    <String, dynamic>{
      'top_speed': instance.topSpeed,
      'acceleration': instance.acceleration,
      'braking': instance.braking,
      'handling': instance.handling,
      'safety': instance.safety,
      'dirt': instance.dirt,
      'tarmac': instance.tarmac,
    };

RaceCarUpgrade$Cost _$RaceCarUpgrade$CostFromJson(Map<String, dynamic> json) =>
    RaceCarUpgrade$Cost(
      points: (json['points'] as num?)?.toInt(),
      cash: (json['cash'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RaceCarUpgrade$CostToJson(
        RaceCarUpgrade$Cost instance) =>
    <String, dynamic>{
      'points': instance.points,
      'cash': instance.cash,
    };

Race$Participants _$Race$ParticipantsFromJson(Map<String, dynamic> json) =>
    Race$Participants(
      minimum: (json['minimum'] as num?)?.toInt(),
      maximum: (json['maximum'] as num?)?.toInt(),
      current: (json['current'] as num?)?.toInt(),
    );

Map<String, dynamic> _$Race$ParticipantsToJson(Race$Participants instance) =>
    <String, dynamic>{
      'minimum': instance.minimum,
      'maximum': instance.maximum,
      'current': instance.current,
    };

Race$Schedule _$Race$ScheduleFromJson(Map<String, dynamic> json) =>
    Race$Schedule(
      joinFrom: (json['join_from'] as num?)?.toInt(),
      joinUntil: (json['join_until'] as num?)?.toInt(),
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );

Map<String, dynamic> _$Race$ScheduleToJson(Race$Schedule instance) =>
    <String, dynamic>{
      'join_from': instance.joinFrom,
      'join_until': instance.joinUntil,
      'start': instance.start,
      'end': instance.end,
    };

Race$Requirements _$Race$RequirementsFromJson(Map<String, dynamic> json) =>
    Race$Requirements(
      carClass: raceClassEnumNullableFromJson(json['car_class']),
      driverClass: raceClassEnumNullableFromJson(json['driver_class']),
      carItemId: (json['car_item_id'] as num?)?.toInt(),
      requiresStockCar: json['requires_stock_car'] as bool?,
      requiresPassword: json['requires_password'] as bool?,
      joinFee: (json['join_fee'] as num?)?.toInt(),
    );

Map<String, dynamic> _$Race$RequirementsToJson(Race$Requirements instance) =>
    <String, dynamic>{
      'car_class': raceClassEnumNullableToJson(instance.carClass),
      'driver_class': raceClassEnumNullableToJson(instance.driverClass),
      'car_item_id': instance.carItemId,
      'requires_stock_car': instance.requiresStockCar,
      'requires_password': instance.requiresPassword,
      'join_fee': instance.joinFee,
    };

RacingRaceDetailsResponse$Participants
    _$RacingRaceDetailsResponse$ParticipantsFromJson(
            Map<String, dynamic> json) =>
        RacingRaceDetailsResponse$Participants(
          minimum: (json['minimum'] as num?)?.toInt(),
          maximum: (json['maximum'] as num?)?.toInt(),
          current: (json['current'] as num?)?.toInt(),
        );

Map<String, dynamic> _$RacingRaceDetailsResponse$ParticipantsToJson(
        RacingRaceDetailsResponse$Participants instance) =>
    <String, dynamic>{
      'minimum': instance.minimum,
      'maximum': instance.maximum,
      'current': instance.current,
    };

RacingRaceDetailsResponse$Schedule _$RacingRaceDetailsResponse$ScheduleFromJson(
        Map<String, dynamic> json) =>
    RacingRaceDetailsResponse$Schedule(
      joinFrom: (json['join_from'] as num?)?.toInt(),
      joinUntil: (json['join_until'] as num?)?.toInt(),
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RacingRaceDetailsResponse$ScheduleToJson(
        RacingRaceDetailsResponse$Schedule instance) =>
    <String, dynamic>{
      'join_from': instance.joinFrom,
      'join_until': instance.joinUntil,
      'start': instance.start,
      'end': instance.end,
    };

RacingRaceDetailsResponse$Requirements
    _$RacingRaceDetailsResponse$RequirementsFromJson(
            Map<String, dynamic> json) =>
        RacingRaceDetailsResponse$Requirements(
          carClass: raceClassEnumNullableFromJson(json['car_class']),
          driverClass: raceClassEnumNullableFromJson(json['driver_class']),
          carItemId: (json['car_item_id'] as num?)?.toInt(),
          requiresStockCar: json['requires_stock_car'] as bool?,
          requiresPassword: json['requires_password'] as bool?,
          joinFee: (json['join_fee'] as num?)?.toInt(),
        );

Map<String, dynamic> _$RacingRaceDetailsResponse$RequirementsToJson(
        RacingRaceDetailsResponse$Requirements instance) =>
    <String, dynamic>{
      'car_class': raceClassEnumNullableToJson(instance.carClass),
      'driver_class': raceClassEnumNullableToJson(instance.driverClass),
      'car_item_id': instance.carItemId,
      'requires_stock_car': instance.requiresStockCar,
      'requires_password': instance.requiresPassword,
      'join_fee': instance.joinFee,
    };

TornCalendarResponse$Calendar _$TornCalendarResponse$CalendarFromJson(
        Map<String, dynamic> json) =>
    TornCalendarResponse$Calendar(
      competitions: (json['competitions'] as List<dynamic>?)
              ?.map((e) =>
                  TornCalendarActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      events: (json['events'] as List<dynamic>?)
              ?.map((e) =>
                  TornCalendarActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornCalendarResponse$CalendarToJson(
        TornCalendarResponse$Calendar instance) =>
    <String, dynamic>{
      'competitions': instance.competitions?.map((e) => e.toJson()).toList(),
      'events': instance.events?.map((e) => e.toJson()).toList(),
    };

PersonalStatsOther$Other _$PersonalStatsOther$OtherFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOther$Other(
      activity: json['activity'] == null
          ? null
          : PersonalStatsOther$Other$Activity.fromJson(
              json['activity'] as Map<String, dynamic>),
      awards: (json['awards'] as num?)?.toInt(),
      meritsBought: (json['merits_bought'] as num?)?.toInt(),
      refills: json['refills'] == null
          ? null
          : PersonalStatsOther$Other$Refills.fromJson(
              json['refills'] as Map<String, dynamic>),
      donatorDays: (json['donator_days'] as num?)?.toInt(),
      rankedWarWins: (json['ranked_war_wins'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsOther$OtherToJson(
        PersonalStatsOther$Other instance) =>
    <String, dynamic>{
      'activity': instance.activity?.toJson(),
      'awards': instance.awards,
      'merits_bought': instance.meritsBought,
      'refills': instance.refills?.toJson(),
      'donator_days': instance.donatorDays,
      'ranked_war_wins': instance.rankedWarWins,
    };

PersonalStatsOtherPopular$Other _$PersonalStatsOtherPopular$OtherFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOtherPopular$Other(
      activity: json['activity'] == null
          ? null
          : PersonalStatsOtherPopular$Other$Activity.fromJson(
              json['activity'] as Map<String, dynamic>),
      awards: (json['awards'] as num?)?.toInt(),
      meritsBought: (json['merits_bought'] as num?)?.toInt(),
      refills: json['refills'] == null
          ? null
          : PersonalStatsOtherPopular$Other$Refills.fromJson(
              json['refills'] as Map<String, dynamic>),
      donatorDays: (json['donator_days'] as num?)?.toInt(),
      rankedWarWins: (json['ranked_war_wins'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsOtherPopular$OtherToJson(
        PersonalStatsOtherPopular$Other instance) =>
    <String, dynamic>{
      'activity': instance.activity?.toJson(),
      'awards': instance.awards,
      'merits_bought': instance.meritsBought,
      'refills': instance.refills?.toJson(),
      'donator_days': instance.donatorDays,
      'ranked_war_wins': instance.rankedWarWins,
    };

PersonalStatsNetworthExtended$Networth
    _$PersonalStatsNetworthExtended$NetworthFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsNetworthExtended$Networth(
          total: (json['total'] as num?)?.toInt(),
          wallet: (json['wallet'] as num?)?.toInt(),
          vaults: (json['vaults'] as num?)?.toInt(),
          bank: (json['bank'] as num?)?.toInt(),
          overseasBank: (json['overseas_bank'] as num?)?.toInt(),
          points: (json['points'] as num?)?.toInt(),
          inventory: (json['inventory'] as num?)?.toInt(),
          displayCase: (json['display_case'] as num?)?.toInt(),
          bazaar: (json['bazaar'] as num?)?.toInt(),
          itemMarket: (json['item_market'] as num?)?.toInt(),
          property: (json['property'] as num?)?.toInt(),
          stockMarket: (json['stock_market'] as num?)?.toInt(),
          auctionHouse: (json['auction_house'] as num?)?.toInt(),
          bookie: (json['bookie'] as num?)?.toInt(),
          company: (json['company'] as num?)?.toInt(),
          enlistedCars: (json['enlisted_cars'] as num?)?.toInt(),
          piggyBank: (json['piggy_bank'] as num?)?.toInt(),
          pending: (json['pending'] as num?)?.toInt(),
          loans: (json['loans'] as num?)?.toInt(),
          unpaidFees: (json['unpaid_fees'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsNetworthExtended$NetworthToJson(
        PersonalStatsNetworthExtended$Networth instance) =>
    <String, dynamic>{
      'total': instance.total,
      'wallet': instance.wallet,
      'vaults': instance.vaults,
      'bank': instance.bank,
      'overseas_bank': instance.overseasBank,
      'points': instance.points,
      'inventory': instance.inventory,
      'display_case': instance.displayCase,
      'bazaar': instance.bazaar,
      'item_market': instance.itemMarket,
      'property': instance.property,
      'stock_market': instance.stockMarket,
      'auction_house': instance.auctionHouse,
      'bookie': instance.bookie,
      'company': instance.company,
      'enlisted_cars': instance.enlistedCars,
      'piggy_bank': instance.piggyBank,
      'pending': instance.pending,
      'loans': instance.loans,
      'unpaid_fees': instance.unpaidFees,
    };

PersonalStatsNetworthPublic$Networth
    _$PersonalStatsNetworthPublic$NetworthFromJson(Map<String, dynamic> json) =>
        PersonalStatsNetworthPublic$Networth(
          total: (json['total'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsNetworthPublic$NetworthToJson(
        PersonalStatsNetworthPublic$Networth instance) =>
    <String, dynamic>{
      'total': instance.total,
    };

PersonalStatsRacing$Racing _$PersonalStatsRacing$RacingFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsRacing$Racing(
      skill: (json['skill'] as num?)?.toInt(),
      points: (json['points'] as num?)?.toInt(),
      races: json['races'] == null
          ? null
          : PersonalStatsRacing$Racing$Races.fromJson(
              json['races'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsRacing$RacingToJson(
        PersonalStatsRacing$Racing instance) =>
    <String, dynamic>{
      'skill': instance.skill,
      'points': instance.points,
      'races': instance.races?.toJson(),
    };

PersonalStatsMissions$Missions _$PersonalStatsMissions$MissionsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsMissions$Missions(
      missions: (json['missions'] as num?)?.toInt(),
      contracts: json['contracts'] == null
          ? null
          : PersonalStatsMissions$Missions$Contracts.fromJson(
              json['contracts'] as Map<String, dynamic>),
      credits: (json['credits'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsMissions$MissionsToJson(
        PersonalStatsMissions$Missions instance) =>
    <String, dynamic>{
      'missions': instance.missions,
      'contracts': instance.contracts?.toJson(),
      'credits': instance.credits,
    };

PersonalStatsDrugs$Drugs _$PersonalStatsDrugs$DrugsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsDrugs$Drugs(
      cannabis: (json['cannabis'] as num?)?.toInt(),
      ecstasy: (json['ecstasy'] as num?)?.toInt(),
      ketamine: (json['ketamine'] as num?)?.toInt(),
      lsd: (json['lsd'] as num?)?.toInt(),
      opium: (json['opium'] as num?)?.toInt(),
      pcp: (json['pcp'] as num?)?.toInt(),
      shrooms: (json['shrooms'] as num?)?.toInt(),
      speed: (json['speed'] as num?)?.toInt(),
      vicodin: (json['vicodin'] as num?)?.toInt(),
      xanax: (json['xanax'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      overdoses: (json['overdoses'] as num?)?.toInt(),
      rehabilitations: json['rehabilitations'] == null
          ? null
          : PersonalStatsDrugs$Drugs$Rehabilitations.fromJson(
              json['rehabilitations'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsDrugs$DrugsToJson(
        PersonalStatsDrugs$Drugs instance) =>
    <String, dynamic>{
      'cannabis': instance.cannabis,
      'ecstasy': instance.ecstasy,
      'ketamine': instance.ketamine,
      'lsd': instance.lsd,
      'opium': instance.opium,
      'pcp': instance.pcp,
      'shrooms': instance.shrooms,
      'speed': instance.speed,
      'vicodin': instance.vicodin,
      'xanax': instance.xanax,
      'total': instance.total,
      'overdoses': instance.overdoses,
      'rehabilitations': instance.rehabilitations?.toJson(),
    };

PersonalStatsTravel$Travel _$PersonalStatsTravel$TravelFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTravel$Travel(
      total: (json['total'] as num?)?.toInt(),
      timeSpent: (json['time_spent'] as num?)?.toInt(),
      itemsBought: (json['items_bought'] as num?)?.toInt(),
      hunting: json['hunting'] == null
          ? null
          : PersonalStatsTravel$Travel$Hunting.fromJson(
              json['hunting'] as Map<String, dynamic>),
      attacksWon: (json['attacks_won'] as num?)?.toInt(),
      defendsLost: (json['defends_lost'] as num?)?.toInt(),
      argentina: (json['argentina'] as num?)?.toInt(),
      canada: (json['canada'] as num?)?.toInt(),
      caymanIslands: (json['cayman_islands'] as num?)?.toInt(),
      china: (json['china'] as num?)?.toInt(),
      hawaii: (json['hawaii'] as num?)?.toInt(),
      japan: (json['japan'] as num?)?.toInt(),
      mexico: (json['mexico'] as num?)?.toInt(),
      unitedArabEmirates: (json['united_arab_emirates'] as num?)?.toInt(),
      unitedKingdom: (json['united_kingdom'] as num?)?.toInt(),
      southAfrica: (json['south_africa'] as num?)?.toInt(),
      switzerland: (json['switzerland'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsTravel$TravelToJson(
        PersonalStatsTravel$Travel instance) =>
    <String, dynamic>{
      'total': instance.total,
      'time_spent': instance.timeSpent,
      'items_bought': instance.itemsBought,
      'hunting': instance.hunting?.toJson(),
      'attacks_won': instance.attacksWon,
      'defends_lost': instance.defendsLost,
      'argentina': instance.argentina,
      'canada': instance.canada,
      'cayman_islands': instance.caymanIslands,
      'china': instance.china,
      'hawaii': instance.hawaii,
      'japan': instance.japan,
      'mexico': instance.mexico,
      'united_arab_emirates': instance.unitedArabEmirates,
      'united_kingdom': instance.unitedKingdom,
      'south_africa': instance.southAfrica,
      'switzerland': instance.switzerland,
    };

PersonalStatsTravelPopular$Travel _$PersonalStatsTravelPopular$TravelFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTravelPopular$Travel(
      total: (json['total'] as num?)?.toInt(),
      timeSpent: (json['time_spent'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsTravelPopular$TravelToJson(
        PersonalStatsTravelPopular$Travel instance) =>
    <String, dynamic>{
      'total': instance.total,
      'time_spent': instance.timeSpent,
    };

PersonalStatsItems$Items _$PersonalStatsItems$ItemsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsItems$Items(
      found: json['found'] == null
          ? null
          : PersonalStatsItems$Items$Found.fromJson(
              json['found'] as Map<String, dynamic>),
      trashed: (json['trashed'] as num?)?.toInt(),
      used: json['used'] == null
          ? null
          : PersonalStatsItems$Items$Used.fromJson(
              json['used'] as Map<String, dynamic>),
      virusesCoded: (json['viruses_coded'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsItems$ItemsToJson(
        PersonalStatsItems$Items instance) =>
    <String, dynamic>{
      'found': instance.found?.toJson(),
      'trashed': instance.trashed,
      'used': instance.used?.toJson(),
      'viruses_coded': instance.virusesCoded,
    };

PersonalStatsItemsPopular$Items _$PersonalStatsItemsPopular$ItemsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsItemsPopular$Items(
      found: json['found'] == null
          ? null
          : PersonalStatsItemsPopular$Items$Found.fromJson(
              json['found'] as Map<String, dynamic>),
      used: json['used'] == null
          ? null
          : PersonalStatsItemsPopular$Items$Used.fromJson(
              json['used'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsItemsPopular$ItemsToJson(
        PersonalStatsItemsPopular$Items instance) =>
    <String, dynamic>{
      'found': instance.found?.toJson(),
      'used': instance.used?.toJson(),
    };

PersonalStatsInvestments$Investments
    _$PersonalStatsInvestments$InvestmentsFromJson(Map<String, dynamic> json) =>
        PersonalStatsInvestments$Investments(
          bank: json['bank'] == null
              ? null
              : PersonalStatsInvestments$Investments$Bank.fromJson(
                  json['bank'] as Map<String, dynamic>),
          stocks: json['stocks'] == null
              ? null
              : PersonalStatsInvestments$Investments$Stocks.fromJson(
                  json['stocks'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsInvestments$InvestmentsToJson(
        PersonalStatsInvestments$Investments instance) =>
    <String, dynamic>{
      'bank': instance.bank?.toJson(),
      'stocks': instance.stocks?.toJson(),
    };

PersonalStatsBounties$Bounties _$PersonalStatsBounties$BountiesFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsBounties$Bounties(
      placed: json['placed'] == null
          ? null
          : PersonalStatsBounties$Bounties$Placed.fromJson(
              json['placed'] as Map<String, dynamic>),
      collected: json['collected'] == null
          ? null
          : PersonalStatsBounties$Bounties$Collected.fromJson(
              json['collected'] as Map<String, dynamic>),
      received: json['received'] == null
          ? null
          : PersonalStatsBounties$Bounties$Received.fromJson(
              json['received'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsBounties$BountiesToJson(
        PersonalStatsBounties$Bounties instance) =>
    <String, dynamic>{
      'placed': instance.placed?.toJson(),
      'collected': instance.collected?.toJson(),
      'received': instance.received?.toJson(),
    };

PersonalStatsCrimesV2$Offenses _$PersonalStatsCrimesV2$OffensesFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCrimesV2$Offenses(
      vandalism: (json['vandalism'] as num?)?.toInt(),
      fraud: (json['fraud'] as num?)?.toInt(),
      theft: (json['theft'] as num?)?.toInt(),
      counterfeiting: (json['counterfeiting'] as num?)?.toInt(),
      illicitServices: (json['illicit_services'] as num?)?.toInt(),
      cybercrime: (json['cybercrime'] as num?)?.toInt(),
      extortion: (json['extortion'] as num?)?.toInt(),
      illegalProduction: (json['illegal_production'] as num?)?.toInt(),
      organizedCrimes: (json['organized_crimes'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsCrimesV2$OffensesToJson(
        PersonalStatsCrimesV2$Offenses instance) =>
    <String, dynamic>{
      'vandalism': instance.vandalism,
      'fraud': instance.fraud,
      'theft': instance.theft,
      'counterfeiting': instance.counterfeiting,
      'illicit_services': instance.illicitServices,
      'cybercrime': instance.cybercrime,
      'extortion': instance.extortion,
      'illegal_production': instance.illegalProduction,
      'organized_crimes': instance.organizedCrimes,
      'total': instance.total,
    };

PersonalStatsCrimesV2$Skills _$PersonalStatsCrimesV2$SkillsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCrimesV2$Skills(
      searchForCash: (json['search_for_cash'] as num?)?.toInt(),
      bootlegging: (json['bootlegging'] as num?)?.toInt(),
      graffiti: (json['graffiti'] as num?)?.toInt(),
      shoplifting: (json['shoplifting'] as num?)?.toInt(),
      pickpocketing: (json['pickpocketing'] as num?)?.toInt(),
      cardSkimming: (json['card_skimming'] as num?)?.toInt(),
      burglary: (json['burglary'] as num?)?.toInt(),
      hustling: (json['hustling'] as num?)?.toInt(),
      disposal: (json['disposal'] as num?)?.toInt(),
      cracking: (json['cracking'] as num?)?.toInt(),
      forgery: (json['forgery'] as num?)?.toInt(),
      scamming: (json['scamming'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsCrimesV2$SkillsToJson(
        PersonalStatsCrimesV2$Skills instance) =>
    <String, dynamic>{
      'search_for_cash': instance.searchForCash,
      'bootlegging': instance.bootlegging,
      'graffiti': instance.graffiti,
      'shoplifting': instance.shoplifting,
      'pickpocketing': instance.pickpocketing,
      'card_skimming': instance.cardSkimming,
      'burglary': instance.burglary,
      'hustling': instance.hustling,
      'disposal': instance.disposal,
      'cracking': instance.cracking,
      'forgery': instance.forgery,
      'scamming': instance.scamming,
    };

PersonalStatsCrimesPopular$Crimes _$PersonalStatsCrimesPopular$CrimesFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCrimesPopular$Crimes(
      total: (json['total'] as num?)?.toInt(),
      version: json['version'] as String?,
    );

Map<String, dynamic> _$PersonalStatsCrimesPopular$CrimesToJson(
        PersonalStatsCrimesPopular$Crimes instance) =>
    <String, dynamic>{
      'total': instance.total,
      'version': instance.version,
    };

PersonalStatsCommunication$Communication
    _$PersonalStatsCommunication$CommunicationFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsCommunication$Communication(
          mailsSent: json['mails_sent'] == null
              ? null
              : PersonalStatsCommunication$Communication$MailsSent.fromJson(
                  json['mails_sent'] as Map<String, dynamic>),
          classifiedAds: (json['classified_ads'] as num?)?.toInt(),
          personals: (json['personals'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsCommunication$CommunicationToJson(
        PersonalStatsCommunication$Communication instance) =>
    <String, dynamic>{
      'mails_sent': instance.mailsSent?.toJson(),
      'classified_ads': instance.classifiedAds,
      'personals': instance.personals,
    };

PersonalStatsFinishingHits$FinishingHits
    _$PersonalStatsFinishingHits$FinishingHitsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsFinishingHits$FinishingHits(
          heavyArtillery: (json['heavy_artillery'] as num?)?.toInt(),
          machineGuns: (json['machine_guns'] as num?)?.toInt(),
          rifles: (json['rifles'] as num?)?.toInt(),
          subMachineGuns: (json['sub_machine_guns'] as num?)?.toInt(),
          shotguns: (json['shotguns'] as num?)?.toInt(),
          pistols: (json['pistols'] as num?)?.toInt(),
          temporary: (json['temporary'] as num?)?.toInt(),
          piercing: (json['piercing'] as num?)?.toInt(),
          slashing: (json['slashing'] as num?)?.toInt(),
          clubbing: (json['clubbing'] as num?)?.toInt(),
          mechanical: (json['mechanical'] as num?)?.toInt(),
          handToHand: (json['hand_to_hand'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsFinishingHits$FinishingHitsToJson(
        PersonalStatsFinishingHits$FinishingHits instance) =>
    <String, dynamic>{
      'heavy_artillery': instance.heavyArtillery,
      'machine_guns': instance.machineGuns,
      'rifles': instance.rifles,
      'sub_machine_guns': instance.subMachineGuns,
      'shotguns': instance.shotguns,
      'pistols': instance.pistols,
      'temporary': instance.temporary,
      'piercing': instance.piercing,
      'slashing': instance.slashing,
      'clubbing': instance.clubbing,
      'mechanical': instance.mechanical,
      'hand_to_hand': instance.handToHand,
    };

PersonalStatsHospital$Hospital _$PersonalStatsHospital$HospitalFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsHospital$Hospital(
      timesHospitalized: (json['times_hospitalized'] as num?)?.toInt(),
      medicalItemsUsed: (json['medical_items_used'] as num?)?.toInt(),
      bloodWithdrawn: (json['blood_withdrawn'] as num?)?.toInt(),
      reviving: json['reviving'] == null
          ? null
          : PersonalStatsHospital$Hospital$Reviving.fromJson(
              json['reviving'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsHospital$HospitalToJson(
        PersonalStatsHospital$Hospital instance) =>
    <String, dynamic>{
      'times_hospitalized': instance.timesHospitalized,
      'medical_items_used': instance.medicalItemsUsed,
      'blood_withdrawn': instance.bloodWithdrawn,
      'reviving': instance.reviving?.toJson(),
    };

PersonalStatsHospitalPopular$Hospital
    _$PersonalStatsHospitalPopular$HospitalFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsHospitalPopular$Hospital(
          medicalItemsUsed: (json['medical_items_used'] as num?)?.toInt(),
          reviving: json['reviving'] == null
              ? null
              : PersonalStatsHospitalPopular$Hospital$Reviving.fromJson(
                  json['reviving'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsHospitalPopular$HospitalToJson(
        PersonalStatsHospitalPopular$Hospital instance) =>
    <String, dynamic>{
      'medical_items_used': instance.medicalItemsUsed,
      'reviving': instance.reviving?.toJson(),
    };

PersonalStatsJail$Jail _$PersonalStatsJail$JailFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJail$Jail(
      timesJailed: (json['times_jailed'] as num?)?.toInt(),
      busts: json['busts'] == null
          ? null
          : PersonalStatsJail$Jail$Busts.fromJson(
              json['busts'] as Map<String, dynamic>),
      bails: json['bails'] == null
          ? null
          : PersonalStatsJail$Jail$Bails.fromJson(
              json['bails'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJail$JailToJson(
        PersonalStatsJail$Jail instance) =>
    <String, dynamic>{
      'times_jailed': instance.timesJailed,
      'busts': instance.busts?.toJson(),
      'bails': instance.bails?.toJson(),
    };

PersonalStatsTrading$Trading _$PersonalStatsTrading$TradingFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTrading$Trading(
      items: json['items'] == null
          ? null
          : PersonalStatsTrading$Trading$Items.fromJson(
              json['items'] as Map<String, dynamic>),
      trades: (json['trades'] as num?)?.toInt(),
      points: json['points'] == null
          ? null
          : PersonalStatsTrading$Trading$Points.fromJson(
              json['points'] as Map<String, dynamic>),
      bazaar: json['bazaar'] == null
          ? null
          : PersonalStatsTrading$Trading$Bazaar.fromJson(
              json['bazaar'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsTrading$TradingToJson(
        PersonalStatsTrading$Trading instance) =>
    <String, dynamic>{
      'items': instance.items?.toJson(),
      'trades': instance.trades,
      'points': instance.points?.toJson(),
      'bazaar': instance.bazaar?.toJson(),
    };

PersonalStatsJobsPublic$Jobs _$PersonalStatsJobsPublic$JobsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJobsPublic$Jobs(
      jobPointsUsed: (json['job_points_used'] as num?)?.toInt(),
      trainsReceived: (json['trains_received'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsJobsPublic$JobsToJson(
        PersonalStatsJobsPublic$Jobs instance) =>
    <String, dynamic>{
      'job_points_used': instance.jobPointsUsed,
      'trains_received': instance.trainsReceived,
    };

PersonalStatsJobsExtended$Jobs _$PersonalStatsJobsExtended$JobsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJobsExtended$Jobs(
      jobPointsUsed: (json['job_points_used'] as num?)?.toInt(),
      trainsReceived: (json['trains_received'] as num?)?.toInt(),
      stats: json['stats'] == null
          ? null
          : PersonalStatsJobsExtended$Jobs$Stats.fromJson(
              json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJobsExtended$JobsToJson(
        PersonalStatsJobsExtended$Jobs instance) =>
    <String, dynamic>{
      'job_points_used': instance.jobPointsUsed,
      'trains_received': instance.trainsReceived,
      'stats': instance.stats?.toJson(),
    };

PersonalStatsBattleStats$BattleStats
    _$PersonalStatsBattleStats$BattleStatsFromJson(Map<String, dynamic> json) =>
        PersonalStatsBattleStats$BattleStats(
          strength: (json['strength'] as num?)?.toInt(),
          defense: (json['defense'] as num?)?.toInt(),
          speed: (json['speed'] as num?)?.toInt(),
          dexterity: (json['dexterity'] as num?)?.toInt(),
          total: (json['total'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsBattleStats$BattleStatsToJson(
        PersonalStatsBattleStats$BattleStats instance) =>
    <String, dynamic>{
      'strength': instance.strength,
      'defense': instance.defense,
      'speed': instance.speed,
      'dexterity': instance.dexterity,
      'total': instance.total,
    };

PersonalStatsAttackingPublic$Attacking
    _$PersonalStatsAttackingPublic$AttackingFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking(
          attacks: json['attacks'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Attacks.fromJson(
                  json['attacks'] as Map<String, dynamic>),
          defends: json['defends'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Defends.fromJson(
                  json['defends'] as Map<String, dynamic>),
          elo: (json['elo'] as num?)?.toInt(),
          unarmoredWins: (json['unarmored_wins'] as num?)?.toInt(),
          highestLevelBeaten: (json['highest_level_beaten'] as num?)?.toInt(),
          escapes: json['escapes'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Escapes.fromJson(
                  json['escapes'] as Map<String, dynamic>),
          killstreak: json['killstreak'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Killstreak.fromJson(
                  json['killstreak'] as Map<String, dynamic>),
          hits: json['hits'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Hits.fromJson(
                  json['hits'] as Map<String, dynamic>),
          damage: json['damage'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Damage.fromJson(
                  json['damage'] as Map<String, dynamic>),
          networth: json['networth'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Networth.fromJson(
                  json['networth'] as Map<String, dynamic>),
          ammunition: json['ammunition'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Ammunition.fromJson(
                  json['ammunition'] as Map<String, dynamic>),
          faction: json['faction'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Faction.fromJson(
                  json['faction'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$AttackingToJson(
        PersonalStatsAttackingPublic$Attacking instance) =>
    <String, dynamic>{
      'attacks': instance.attacks?.toJson(),
      'defends': instance.defends?.toJson(),
      'elo': instance.elo,
      'unarmored_wins': instance.unarmoredWins,
      'highest_level_beaten': instance.highestLevelBeaten,
      'escapes': instance.escapes?.toJson(),
      'killstreak': instance.killstreak?.toJson(),
      'hits': instance.hits?.toJson(),
      'damage': instance.damage?.toJson(),
      'networth': instance.networth?.toJson(),
      'ammunition': instance.ammunition?.toJson(),
      'faction': instance.faction?.toJson(),
    };

PersonalStatsAttackingExtended$Attacking
    _$PersonalStatsAttackingExtended$AttackingFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking(
          attacks: json['attacks'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Attacks.fromJson(
                  json['attacks'] as Map<String, dynamic>),
          defends: json['defends'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Defends.fromJson(
                  json['defends'] as Map<String, dynamic>),
          elo: (json['elo'] as num?)?.toInt(),
          unarmoredWins: (json['unarmored_wins'] as num?)?.toInt(),
          highestLevelBeaten: (json['highest_level_beaten'] as num?)?.toInt(),
          escapes: json['escapes'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Escapes.fromJson(
                  json['escapes'] as Map<String, dynamic>),
          killstreak: json['killstreak'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Killstreak.fromJson(
                  json['killstreak'] as Map<String, dynamic>),
          hits: json['hits'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Hits.fromJson(
                  json['hits'] as Map<String, dynamic>),
          damage: json['damage'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Damage.fromJson(
                  json['damage'] as Map<String, dynamic>),
          networth: json['networth'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Networth.fromJson(
                  json['networth'] as Map<String, dynamic>),
          ammunition: json['ammunition'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Ammunition.fromJson(
                  json['ammunition'] as Map<String, dynamic>),
          faction: json['faction'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Faction.fromJson(
                  json['faction'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$AttackingToJson(
        PersonalStatsAttackingExtended$Attacking instance) =>
    <String, dynamic>{
      'attacks': instance.attacks?.toJson(),
      'defends': instance.defends?.toJson(),
      'elo': instance.elo,
      'unarmored_wins': instance.unarmoredWins,
      'highest_level_beaten': instance.highestLevelBeaten,
      'escapes': instance.escapes?.toJson(),
      'killstreak': instance.killstreak?.toJson(),
      'hits': instance.hits?.toJson(),
      'damage': instance.damage?.toJson(),
      'networth': instance.networth?.toJson(),
      'ammunition': instance.ammunition?.toJson(),
      'faction': instance.faction?.toJson(),
    };

PersonalStatsAttackingPopular$Attacking
    _$PersonalStatsAttackingPopular$AttackingFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking(
          attacks: json['attacks'] == null
              ? null
              : PersonalStatsAttackingPopular$Attacking$Attacks.fromJson(
                  json['attacks'] as Map<String, dynamic>),
          defends: json['defends'] == null
              ? null
              : PersonalStatsAttackingPopular$Attacking$Defends.fromJson(
                  json['defends'] as Map<String, dynamic>),
          elo: (json['elo'] as num?)?.toInt(),
          escapes: json['escapes'] == null
              ? null
              : PersonalStatsAttackingPopular$Attacking$Escapes.fromJson(
                  json['escapes'] as Map<String, dynamic>),
          killstreak: json['killstreak'] == null
              ? null
              : PersonalStatsAttackingPopular$Attacking$Killstreak.fromJson(
                  json['killstreak'] as Map<String, dynamic>),
          hits: json['hits'] == null
              ? null
              : PersonalStatsAttackingPopular$Attacking$Hits.fromJson(
                  json['hits'] as Map<String, dynamic>),
          damage: json['damage'] == null
              ? null
              : PersonalStatsAttackingPopular$Attacking$Damage.fromJson(
                  json['damage'] as Map<String, dynamic>),
          networth: json['networth'] == null
              ? null
              : PersonalStatsAttackingPopular$Attacking$Networth.fromJson(
                  json['networth'] as Map<String, dynamic>),
          ammunition: json['ammunition'] == null
              ? null
              : PersonalStatsAttackingPopular$Attacking$Ammunition.fromJson(
                  json['ammunition'] as Map<String, dynamic>),
          faction: json['faction'] == null
              ? null
              : PersonalStatsAttackingPopular$Attacking$Faction.fromJson(
                  json['faction'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$AttackingToJson(
        PersonalStatsAttackingPopular$Attacking instance) =>
    <String, dynamic>{
      'attacks': instance.attacks?.toJson(),
      'defends': instance.defends?.toJson(),
      'elo': instance.elo,
      'escapes': instance.escapes?.toJson(),
      'killstreak': instance.killstreak?.toJson(),
      'hits': instance.hits?.toJson(),
      'damage': instance.damage?.toJson(),
      'networth': instance.networth?.toJson(),
      'ammunition': instance.ammunition?.toJson(),
      'faction': instance.faction?.toJson(),
    };

UserCrimeDetailsBootlegging$OnlineStore
    _$UserCrimeDetailsBootlegging$OnlineStoreFromJson(
            Map<String, dynamic> json) =>
        UserCrimeDetailsBootlegging$OnlineStore(
          earnings: (json['earnings'] as num?)?.toInt(),
          visits: (json['visits'] as num?)?.toInt(),
          customers: (json['customers'] as num?)?.toInt(),
          sales: (json['sales'] as num?)?.toInt(),
        );

Map<String, dynamic> _$UserCrimeDetailsBootlegging$OnlineStoreToJson(
        UserCrimeDetailsBootlegging$OnlineStore instance) =>
    <String, dynamic>{
      'earnings': instance.earnings,
      'visits': instance.visits,
      'customers': instance.customers,
      'sales': instance.sales,
    };

UserCrimeDetailsBootlegging$DvdSales
    _$UserCrimeDetailsBootlegging$DvdSalesFromJson(Map<String, dynamic> json) =>
        UserCrimeDetailsBootlegging$DvdSales(
          action: (json['action'] as num?)?.toInt(),
          comedy: (json['comedy'] as num?)?.toInt(),
          drama: (json['drama'] as num?)?.toInt(),
          fantasy: (json['fantasy'] as num?)?.toInt(),
          horror: (json['horror'] as num?)?.toInt(),
          romance: (json['romance'] as num?)?.toInt(),
          thriller: (json['thriller'] as num?)?.toInt(),
          sciFi: (json['sci-fi'] as num?)?.toInt(),
          total: (json['total'] as num?)?.toInt(),
          earnings: (json['earnings'] as num?)?.toInt(),
        );

Map<String, dynamic> _$UserCrimeDetailsBootlegging$DvdSalesToJson(
        UserCrimeDetailsBootlegging$DvdSales instance) =>
    <String, dynamic>{
      'action': instance.action,
      'comedy': instance.comedy,
      'drama': instance.drama,
      'fantasy': instance.fantasy,
      'horror': instance.horror,
      'romance': instance.romance,
      'thriller': instance.thriller,
      'sci-fi': instance.sciFi,
      'total': instance.total,
      'earnings': instance.earnings,
    };

UserCrimeDetailsCardSkimming$CardDetails
    _$UserCrimeDetailsCardSkimming$CardDetailsFromJson(
            Map<String, dynamic> json) =>
        UserCrimeDetailsCardSkimming$CardDetails(
          recoverable: (json['recoverable'] as num?)?.toInt(),
          recovered: (json['recovered'] as num?)?.toInt(),
          sold: (json['sold'] as num?)?.toInt(),
          lost: (json['lost'] as num?)?.toInt(),
          areas: (json['areas'] as List<dynamic>?)
              ?.map((e) =>
                  UserCrimeDetailsCardSkimming$CardDetails$Areas$Item.fromJson(
                      e as Map<String, dynamic>))
              .toList(),
        );

Map<String, dynamic> _$UserCrimeDetailsCardSkimming$CardDetailsToJson(
        UserCrimeDetailsCardSkimming$CardDetails instance) =>
    <String, dynamic>{
      'recoverable': instance.recoverable,
      'recovered': instance.recovered,
      'sold': instance.sold,
      'lost': instance.lost,
      'areas': instance.areas?.map((e) => e.toJson()).toList(),
    };

UserCrimeDetailsCardSkimming$Skimmers
    _$UserCrimeDetailsCardSkimming$SkimmersFromJson(
            Map<String, dynamic> json) =>
        UserCrimeDetailsCardSkimming$Skimmers(
          active: (json['active'] as num?)?.toInt(),
          mostLucrative: (json['most_lucrative'] as num?)?.toInt(),
          oldestRecovered: (json['oldest_recovered'] as num?)?.toInt(),
          lost: (json['lost'] as num?)?.toInt(),
        );

Map<String, dynamic> _$UserCrimeDetailsCardSkimming$SkimmersToJson(
        UserCrimeDetailsCardSkimming$Skimmers instance) =>
    <String, dynamic>{
      'active': instance.active,
      'most_lucrative': instance.mostLucrative,
      'oldest_recovered': instance.oldestRecovered,
      'lost': instance.lost,
    };

UserCrimeDetailsScamming$Zones _$UserCrimeDetailsScamming$ZonesFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsScamming$Zones(
      red: (json['red'] as num?)?.toInt(),
      neutral: (json['neutral'] as num?)?.toInt(),
      concern: (json['concern'] as num?)?.toInt(),
      sensitivity: (json['sensitivity'] as num?)?.toInt(),
      temptation: (json['temptation'] as num?)?.toInt(),
      hesitation: (json['hesitation'] as num?)?.toInt(),
      lowReward: (json['low_reward'] as num?)?.toInt(),
      mediumReward: (json['medium_reward'] as num?)?.toInt(),
      highReward: (json['high_reward'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsScamming$ZonesToJson(
        UserCrimeDetailsScamming$Zones instance) =>
    <String, dynamic>{
      'red': instance.red,
      'neutral': instance.neutral,
      'concern': instance.concern,
      'sensitivity': instance.sensitivity,
      'temptation': instance.temptation,
      'hesitation': instance.hesitation,
      'low_reward': instance.lowReward,
      'medium_reward': instance.mediumReward,
      'high_reward': instance.highReward,
    };

UserCrimeDetailsScamming$Concerns _$UserCrimeDetailsScamming$ConcernsFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsScamming$Concerns(
      attempts: (json['attempts'] as num?)?.toInt(),
      resolved: (json['resolved'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsScamming$ConcernsToJson(
        UserCrimeDetailsScamming$Concerns instance) =>
    <String, dynamic>{
      'attempts': instance.attempts,
      'resolved': instance.resolved,
    };

UserCrimeDetailsScamming$Payouts _$UserCrimeDetailsScamming$PayoutsFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsScamming$Payouts(
      low: (json['low'] as num?)?.toInt(),
      medium: (json['medium'] as num?)?.toInt(),
      high: (json['high'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsScamming$PayoutsToJson(
        UserCrimeDetailsScamming$Payouts instance) =>
    <String, dynamic>{
      'low': instance.low,
      'medium': instance.medium,
      'high': instance.high,
    };

UserCrimeDetailsScamming$Emails _$UserCrimeDetailsScamming$EmailsFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsScamming$Emails(
      scraper: (json['scraper'] as num?)?.toInt(),
      phisher: (json['phisher'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsScamming$EmailsToJson(
        UserCrimeDetailsScamming$Emails instance) =>
    <String, dynamic>{
      'scraper': instance.scraper,
      'phisher': instance.phisher,
    };

FactionApplication$User$Stats _$FactionApplication$User$StatsFromJson(
        Map<String, dynamic> json) =>
    FactionApplication$User$Stats(
      strength: (json['strength'] as num?)?.toInt(),
      speed: (json['speed'] as num?)?.toInt(),
      dexterity: (json['dexterity'] as num?)?.toInt(),
      defense: (json['defense'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionApplication$User$StatsToJson(
        FactionApplication$User$Stats instance) =>
    <String, dynamic>{
      'strength': instance.strength,
      'speed': instance.speed,
      'dexterity': instance.dexterity,
      'defense': instance.defense,
    };

PersonalStatsOther$Other$Activity _$PersonalStatsOther$Other$ActivityFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOther$Other$Activity(
      time: (json['time'] as num?)?.toInt(),
      streak: json['streak'] == null
          ? null
          : PersonalStatsOther$Other$Activity$Streak.fromJson(
              json['streak'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsOther$Other$ActivityToJson(
        PersonalStatsOther$Other$Activity instance) =>
    <String, dynamic>{
      'time': instance.time,
      'streak': instance.streak?.toJson(),
    };

PersonalStatsOther$Other$Refills _$PersonalStatsOther$Other$RefillsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOther$Other$Refills(
      energy: (json['energy'] as num?)?.toInt(),
      nerve: (json['nerve'] as num?)?.toInt(),
      token: (json['token'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsOther$Other$RefillsToJson(
        PersonalStatsOther$Other$Refills instance) =>
    <String, dynamic>{
      'energy': instance.energy,
      'nerve': instance.nerve,
      'token': instance.token,
    };

PersonalStatsOtherPopular$Other$Activity
    _$PersonalStatsOtherPopular$Other$ActivityFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsOtherPopular$Other$Activity(
          time: (json['time'] as num?)?.toInt(),
          streak: json['streak'] == null
              ? null
              : PersonalStatsOtherPopular$Other$Activity$Streak.fromJson(
                  json['streak'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsOtherPopular$Other$ActivityToJson(
        PersonalStatsOtherPopular$Other$Activity instance) =>
    <String, dynamic>{
      'time': instance.time,
      'streak': instance.streak?.toJson(),
    };

PersonalStatsOtherPopular$Other$Refills
    _$PersonalStatsOtherPopular$Other$RefillsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsOtherPopular$Other$Refills(
          energy: (json['energy'] as num?)?.toInt(),
          nerve: (json['nerve'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsOtherPopular$Other$RefillsToJson(
        PersonalStatsOtherPopular$Other$Refills instance) =>
    <String, dynamic>{
      'energy': instance.energy,
      'nerve': instance.nerve,
    };

PersonalStatsRacing$Racing$Races _$PersonalStatsRacing$Racing$RacesFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsRacing$Racing$Races(
      entered: (json['entered'] as num?)?.toInt(),
      won: (json['won'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsRacing$Racing$RacesToJson(
        PersonalStatsRacing$Racing$Races instance) =>
    <String, dynamic>{
      'entered': instance.entered,
      'won': instance.won,
    };

PersonalStatsMissions$Missions$Contracts
    _$PersonalStatsMissions$Missions$ContractsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsMissions$Missions$Contracts(
          total: (json['total'] as num?)?.toInt(),
          duke: (json['duke'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsMissions$Missions$ContractsToJson(
        PersonalStatsMissions$Missions$Contracts instance) =>
    <String, dynamic>{
      'total': instance.total,
      'duke': instance.duke,
    };

PersonalStatsDrugs$Drugs$Rehabilitations
    _$PersonalStatsDrugs$Drugs$RehabilitationsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsDrugs$Drugs$Rehabilitations(
          amount: (json['amount'] as num?)?.toInt(),
          fees: (json['fees'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsDrugs$Drugs$RehabilitationsToJson(
        PersonalStatsDrugs$Drugs$Rehabilitations instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'fees': instance.fees,
    };

PersonalStatsTravel$Travel$Hunting _$PersonalStatsTravel$Travel$HuntingFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTravel$Travel$Hunting(
      skill: (json['skill'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsTravel$Travel$HuntingToJson(
        PersonalStatsTravel$Travel$Hunting instance) =>
    <String, dynamic>{
      'skill': instance.skill,
    };

PersonalStatsItems$Items$Found _$PersonalStatsItems$Items$FoundFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsItems$Items$Found(
      city: (json['city'] as num?)?.toInt(),
      dump: (json['dump'] as num?)?.toInt(),
      easterEggs: (json['easter_eggs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsItems$Items$FoundToJson(
        PersonalStatsItems$Items$Found instance) =>
    <String, dynamic>{
      'city': instance.city,
      'dump': instance.dump,
      'easter_eggs': instance.easterEggs,
    };

PersonalStatsItems$Items$Used _$PersonalStatsItems$Items$UsedFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsItems$Items$Used(
      books: (json['books'] as num?)?.toInt(),
      boosters: (json['boosters'] as num?)?.toInt(),
      consumables: (json['consumables'] as num?)?.toInt(),
      candy: (json['candy'] as num?)?.toInt(),
      alcohol: (json['alcohol'] as num?)?.toInt(),
      energyDrinks: (json['energy_drinks'] as num?)?.toInt(),
      statEnhancers: (json['stat_enhancers'] as num?)?.toInt(),
      easterEggs: (json['easter_eggs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsItems$Items$UsedToJson(
        PersonalStatsItems$Items$Used instance) =>
    <String, dynamic>{
      'books': instance.books,
      'boosters': instance.boosters,
      'consumables': instance.consumables,
      'candy': instance.candy,
      'alcohol': instance.alcohol,
      'energy_drinks': instance.energyDrinks,
      'stat_enhancers': instance.statEnhancers,
      'easter_eggs': instance.easterEggs,
    };

PersonalStatsItemsPopular$Items$Found
    _$PersonalStatsItemsPopular$Items$FoundFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsItemsPopular$Items$Found(
          dump: (json['dump'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsItemsPopular$Items$FoundToJson(
        PersonalStatsItemsPopular$Items$Found instance) =>
    <String, dynamic>{
      'dump': instance.dump,
    };

PersonalStatsItemsPopular$Items$Used
    _$PersonalStatsItemsPopular$Items$UsedFromJson(Map<String, dynamic> json) =>
        PersonalStatsItemsPopular$Items$Used(
          books: (json['books'] as num?)?.toInt(),
          boosters: (json['boosters'] as num?)?.toInt(),
          consumables: (json['consumables'] as num?)?.toInt(),
          candy: (json['candy'] as num?)?.toInt(),
          alcohol: (json['alcohol'] as num?)?.toInt(),
          energyDrinks: (json['energy_drinks'] as num?)?.toInt(),
          statEnhancers: (json['stat_enhancers'] as num?)?.toInt(),
          easterEggs: (json['easter_eggs'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsItemsPopular$Items$UsedToJson(
        PersonalStatsItemsPopular$Items$Used instance) =>
    <String, dynamic>{
      'books': instance.books,
      'boosters': instance.boosters,
      'consumables': instance.consumables,
      'candy': instance.candy,
      'alcohol': instance.alcohol,
      'energy_drinks': instance.energyDrinks,
      'stat_enhancers': instance.statEnhancers,
      'easter_eggs': instance.easterEggs,
    };

PersonalStatsInvestments$Investments$Bank
    _$PersonalStatsInvestments$Investments$BankFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsInvestments$Investments$Bank(
          total: (json['total'] as num?)?.toInt(),
          profit: (json['profit'] as num?)?.toInt(),
          current: (json['current'] as num?)?.toInt(),
          timeRemaining: (json['time_remaining'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsInvestments$Investments$BankToJson(
        PersonalStatsInvestments$Investments$Bank instance) =>
    <String, dynamic>{
      'total': instance.total,
      'profit': instance.profit,
      'current': instance.current,
      'time_remaining': instance.timeRemaining,
    };

PersonalStatsInvestments$Investments$Stocks
    _$PersonalStatsInvestments$Investments$StocksFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsInvestments$Investments$Stocks(
          profits: (json['profits'] as num?)?.toInt(),
          losses: (json['losses'] as num?)?.toInt(),
          fees: (json['fees'] as num?)?.toInt(),
          netProfits: (json['net_profits'] as num?)?.toInt(),
          payouts: (json['payouts'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsInvestments$Investments$StocksToJson(
        PersonalStatsInvestments$Investments$Stocks instance) =>
    <String, dynamic>{
      'profits': instance.profits,
      'losses': instance.losses,
      'fees': instance.fees,
      'net_profits': instance.netProfits,
      'payouts': instance.payouts,
    };

PersonalStatsBounties$Bounties$Placed
    _$PersonalStatsBounties$Bounties$PlacedFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsBounties$Bounties$Placed(
          amount: (json['amount'] as num?)?.toInt(),
          $value: (json['value'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsBounties$Bounties$PlacedToJson(
        PersonalStatsBounties$Bounties$Placed instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'value': instance.$value,
    };

PersonalStatsBounties$Bounties$Collected
    _$PersonalStatsBounties$Bounties$CollectedFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsBounties$Bounties$Collected(
          amount: (json['amount'] as num?)?.toInt(),
          $value: (json['value'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsBounties$Bounties$CollectedToJson(
        PersonalStatsBounties$Bounties$Collected instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'value': instance.$value,
    };

PersonalStatsBounties$Bounties$Received
    _$PersonalStatsBounties$Bounties$ReceivedFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsBounties$Bounties$Received(
          amount: (json['amount'] as num?)?.toInt(),
          $value: (json['value'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsBounties$Bounties$ReceivedToJson(
        PersonalStatsBounties$Bounties$Received instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'value': instance.$value,
    };

PersonalStatsCommunication$Communication$MailsSent
    _$PersonalStatsCommunication$Communication$MailsSentFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsCommunication$Communication$MailsSent(
          total: (json['total'] as num?)?.toInt(),
          friends: (json['friends'] as num?)?.toInt(),
          faction: (json['faction'] as num?)?.toInt(),
          colleagues: (json['colleagues'] as num?)?.toInt(),
          spouse: (json['spouse'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsCommunication$Communication$MailsSentToJson(
        PersonalStatsCommunication$Communication$MailsSent instance) =>
    <String, dynamic>{
      'total': instance.total,
      'friends': instance.friends,
      'faction': instance.faction,
      'colleagues': instance.colleagues,
      'spouse': instance.spouse,
    };

PersonalStatsHospital$Hospital$Reviving
    _$PersonalStatsHospital$Hospital$RevivingFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsHospital$Hospital$Reviving(
          skill: (json['skill'] as num?)?.toInt(),
          revives: (json['revives'] as num?)?.toInt(),
          revivesReceived: (json['revives_received'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsHospital$Hospital$RevivingToJson(
        PersonalStatsHospital$Hospital$Reviving instance) =>
    <String, dynamic>{
      'skill': instance.skill,
      'revives': instance.revives,
      'revives_received': instance.revivesReceived,
    };

PersonalStatsHospitalPopular$Hospital$Reviving
    _$PersonalStatsHospitalPopular$Hospital$RevivingFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsHospitalPopular$Hospital$Reviving(
          skill: (json['skill'] as num?)?.toInt(),
          revives: (json['revives'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsHospitalPopular$Hospital$RevivingToJson(
        PersonalStatsHospitalPopular$Hospital$Reviving instance) =>
    <String, dynamic>{
      'skill': instance.skill,
      'revives': instance.revives,
    };

PersonalStatsJail$Jail$Busts _$PersonalStatsJail$Jail$BustsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJail$Jail$Busts(
      success: (json['success'] as num?)?.toInt(),
      fails: (json['fails'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsJail$Jail$BustsToJson(
        PersonalStatsJail$Jail$Busts instance) =>
    <String, dynamic>{
      'success': instance.success,
      'fails': instance.fails,
    };

PersonalStatsJail$Jail$Bails _$PersonalStatsJail$Jail$BailsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJail$Jail$Bails(
      amount: (json['amount'] as num?)?.toInt(),
      fees: (json['fees'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsJail$Jail$BailsToJson(
        PersonalStatsJail$Jail$Bails instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'fees': instance.fees,
    };

PersonalStatsTrading$Trading$Items _$PersonalStatsTrading$Trading$ItemsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTrading$Trading$Items(
      bought: json['bought'] == null
          ? null
          : PersonalStatsTrading$Trading$Items$Bought.fromJson(
              json['bought'] as Map<String, dynamic>),
      auctions: json['auctions'] == null
          ? null
          : PersonalStatsTrading$Trading$Items$Auctions.fromJson(
              json['auctions'] as Map<String, dynamic>),
      sent: (json['sent'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PersonalStatsTrading$Trading$ItemsToJson(
        PersonalStatsTrading$Trading$Items instance) =>
    <String, dynamic>{
      'bought': instance.bought?.toJson(),
      'auctions': instance.auctions?.toJson(),
      'sent': instance.sent,
    };

PersonalStatsTrading$Trading$Points
    _$PersonalStatsTrading$Trading$PointsFromJson(Map<String, dynamic> json) =>
        PersonalStatsTrading$Trading$Points(
          bought: (json['bought'] as num?)?.toInt(),
          sold: (json['sold'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsTrading$Trading$PointsToJson(
        PersonalStatsTrading$Trading$Points instance) =>
    <String, dynamic>{
      'bought': instance.bought,
      'sold': instance.sold,
    };

PersonalStatsTrading$Trading$Bazaar
    _$PersonalStatsTrading$Trading$BazaarFromJson(Map<String, dynamic> json) =>
        PersonalStatsTrading$Trading$Bazaar(
          customers: (json['customers'] as num?)?.toInt(),
          sales: (json['sales'] as num?)?.toInt(),
          profit: (json['profit'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsTrading$Trading$BazaarToJson(
        PersonalStatsTrading$Trading$Bazaar instance) =>
    <String, dynamic>{
      'customers': instance.customers,
      'sales': instance.sales,
      'profit': instance.profit,
    };

PersonalStatsJobsExtended$Jobs$Stats
    _$PersonalStatsJobsExtended$Jobs$StatsFromJson(Map<String, dynamic> json) =>
        PersonalStatsJobsExtended$Jobs$Stats(
          manual: (json['manual'] as num?)?.toInt(),
          intelligence: (json['intelligence'] as num?)?.toInt(),
          endurance: (json['endurance'] as num?)?.toInt(),
          total: (json['total'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsJobsExtended$Jobs$StatsToJson(
        PersonalStatsJobsExtended$Jobs$Stats instance) =>
    <String, dynamic>{
      'manual': instance.manual,
      'intelligence': instance.intelligence,
      'endurance': instance.endurance,
      'total': instance.total,
    };

PersonalStatsAttackingPublic$Attacking$Attacks
    _$PersonalStatsAttackingPublic$Attacking$AttacksFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Attacks(
          won: (json['won'] as num?)?.toInt(),
          lost: (json['lost'] as num?)?.toInt(),
          stalemate: (json['stalemate'] as num?)?.toInt(),
          assist: (json['assist'] as num?)?.toInt(),
          stealth: (json['stealth'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$AttacksToJson(
        PersonalStatsAttackingPublic$Attacking$Attacks instance) =>
    <String, dynamic>{
      'won': instance.won,
      'lost': instance.lost,
      'stalemate': instance.stalemate,
      'assist': instance.assist,
      'stealth': instance.stealth,
    };

PersonalStatsAttackingPublic$Attacking$Defends
    _$PersonalStatsAttackingPublic$Attacking$DefendsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Defends(
          won: (json['won'] as num?)?.toInt(),
          lost: (json['lost'] as num?)?.toInt(),
          stalemate: (json['stalemate'] as num?)?.toInt(),
          total: (json['total'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$DefendsToJson(
        PersonalStatsAttackingPublic$Attacking$Defends instance) =>
    <String, dynamic>{
      'won': instance.won,
      'lost': instance.lost,
      'stalemate': instance.stalemate,
      'total': instance.total,
    };

PersonalStatsAttackingPublic$Attacking$Escapes
    _$PersonalStatsAttackingPublic$Attacking$EscapesFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Escapes(
          player: (json['player'] as num?)?.toInt(),
          foes: (json['foes'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$EscapesToJson(
        PersonalStatsAttackingPublic$Attacking$Escapes instance) =>
    <String, dynamic>{
      'player': instance.player,
      'foes': instance.foes,
    };

PersonalStatsAttackingPublic$Attacking$Killstreak
    _$PersonalStatsAttackingPublic$Attacking$KillstreakFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Killstreak(
          best: (json['best'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$KillstreakToJson(
        PersonalStatsAttackingPublic$Attacking$Killstreak instance) =>
    <String, dynamic>{
      'best': instance.best,
    };

PersonalStatsAttackingPublic$Attacking$Hits
    _$PersonalStatsAttackingPublic$Attacking$HitsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Hits(
          success: (json['success'] as num?)?.toInt(),
          miss: (json['miss'] as num?)?.toInt(),
          critical: (json['critical'] as num?)?.toInt(),
          oneHitKills: (json['one_hit_kills'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$HitsToJson(
        PersonalStatsAttackingPublic$Attacking$Hits instance) =>
    <String, dynamic>{
      'success': instance.success,
      'miss': instance.miss,
      'critical': instance.critical,
      'one_hit_kills': instance.oneHitKills,
    };

PersonalStatsAttackingPublic$Attacking$Damage
    _$PersonalStatsAttackingPublic$Attacking$DamageFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Damage(
          total: (json['total'] as num?)?.toInt(),
          best: (json['best'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$DamageToJson(
        PersonalStatsAttackingPublic$Attacking$Damage instance) =>
    <String, dynamic>{
      'total': instance.total,
      'best': instance.best,
    };

PersonalStatsAttackingPublic$Attacking$Networth
    _$PersonalStatsAttackingPublic$Attacking$NetworthFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Networth(
          moneyMugged: (json['money_mugged'] as num?)?.toInt(),
          largestMug: (json['largest_mug'] as num?)?.toInt(),
          itemsLooted: (json['items_looted'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$NetworthToJson(
        PersonalStatsAttackingPublic$Attacking$Networth instance) =>
    <String, dynamic>{
      'money_mugged': instance.moneyMugged,
      'largest_mug': instance.largestMug,
      'items_looted': instance.itemsLooted,
    };

PersonalStatsAttackingPublic$Attacking$Ammunition
    _$PersonalStatsAttackingPublic$Attacking$AmmunitionFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Ammunition(
          total: (json['total'] as num?)?.toInt(),
          special: (json['special'] as num?)?.toInt(),
          hollowPoint: (json['hollow_point'] as num?)?.toInt(),
          tracer: (json['tracer'] as num?)?.toInt(),
          piercing: (json['piercing'] as num?)?.toInt(),
          incendiary: (json['incendiary'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$AmmunitionToJson(
        PersonalStatsAttackingPublic$Attacking$Ammunition instance) =>
    <String, dynamic>{
      'total': instance.total,
      'special': instance.special,
      'hollow_point': instance.hollowPoint,
      'tracer': instance.tracer,
      'piercing': instance.piercing,
      'incendiary': instance.incendiary,
    };

PersonalStatsAttackingPublic$Attacking$Faction
    _$PersonalStatsAttackingPublic$Attacking$FactionFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Faction(
          respect: (json['respect'] as num?)?.toInt(),
          retaliations: (json['retaliations'] as num?)?.toInt(),
          rankedWarHits: (json['ranked_war_hits'] as num?)?.toInt(),
          raidHits: (json['raid_hits'] as num?)?.toInt(),
          territory: json['territory'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Faction$Territory
                  .fromJson(json['territory'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$FactionToJson(
        PersonalStatsAttackingPublic$Attacking$Faction instance) =>
    <String, dynamic>{
      'respect': instance.respect,
      'retaliations': instance.retaliations,
      'ranked_war_hits': instance.rankedWarHits,
      'raid_hits': instance.raidHits,
      'territory': instance.territory?.toJson(),
    };

PersonalStatsAttackingExtended$Attacking$Attacks
    _$PersonalStatsAttackingExtended$Attacking$AttacksFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Attacks(
          won: (json['won'] as num?)?.toInt(),
          lost: (json['lost'] as num?)?.toInt(),
          stalemate: (json['stalemate'] as num?)?.toInt(),
          assist: (json['assist'] as num?)?.toInt(),
          stealth: (json['stealth'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$Attacking$AttacksToJson(
        PersonalStatsAttackingExtended$Attacking$Attacks instance) =>
    <String, dynamic>{
      'won': instance.won,
      'lost': instance.lost,
      'stalemate': instance.stalemate,
      'assist': instance.assist,
      'stealth': instance.stealth,
    };

PersonalStatsAttackingExtended$Attacking$Defends
    _$PersonalStatsAttackingExtended$Attacking$DefendsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Defends(
          won: (json['won'] as num?)?.toInt(),
          lost: (json['lost'] as num?)?.toInt(),
          stalemate: (json['stalemate'] as num?)?.toInt(),
          total: (json['total'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$Attacking$DefendsToJson(
        PersonalStatsAttackingExtended$Attacking$Defends instance) =>
    <String, dynamic>{
      'won': instance.won,
      'lost': instance.lost,
      'stalemate': instance.stalemate,
      'total': instance.total,
    };

PersonalStatsAttackingExtended$Attacking$Escapes
    _$PersonalStatsAttackingExtended$Attacking$EscapesFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Escapes(
          player: (json['player'] as num?)?.toInt(),
          foes: (json['foes'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$Attacking$EscapesToJson(
        PersonalStatsAttackingExtended$Attacking$Escapes instance) =>
    <String, dynamic>{
      'player': instance.player,
      'foes': instance.foes,
    };

PersonalStatsAttackingExtended$Attacking$Killstreak
    _$PersonalStatsAttackingExtended$Attacking$KillstreakFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Killstreak(
          best: (json['best'] as num?)?.toInt(),
          current: (json['current'] as num?)?.toInt(),
        );

Map<String, dynamic>
    _$PersonalStatsAttackingExtended$Attacking$KillstreakToJson(
            PersonalStatsAttackingExtended$Attacking$Killstreak instance) =>
        <String, dynamic>{
          'best': instance.best,
          'current': instance.current,
        };

PersonalStatsAttackingExtended$Attacking$Hits
    _$PersonalStatsAttackingExtended$Attacking$HitsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Hits(
          success: (json['success'] as num?)?.toInt(),
          miss: (json['miss'] as num?)?.toInt(),
          critical: (json['critical'] as num?)?.toInt(),
          oneHitKills: (json['one_hit_kills'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$Attacking$HitsToJson(
        PersonalStatsAttackingExtended$Attacking$Hits instance) =>
    <String, dynamic>{
      'success': instance.success,
      'miss': instance.miss,
      'critical': instance.critical,
      'one_hit_kills': instance.oneHitKills,
    };

PersonalStatsAttackingExtended$Attacking$Damage
    _$PersonalStatsAttackingExtended$Attacking$DamageFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Damage(
          total: (json['total'] as num?)?.toInt(),
          best: (json['best'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$Attacking$DamageToJson(
        PersonalStatsAttackingExtended$Attacking$Damage instance) =>
    <String, dynamic>{
      'total': instance.total,
      'best': instance.best,
    };

PersonalStatsAttackingExtended$Attacking$Networth
    _$PersonalStatsAttackingExtended$Attacking$NetworthFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Networth(
          moneyMugged: (json['money_mugged'] as num?)?.toInt(),
          largestMug: (json['largest_mug'] as num?)?.toInt(),
          itemsLooted: (json['items_looted'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$Attacking$NetworthToJson(
        PersonalStatsAttackingExtended$Attacking$Networth instance) =>
    <String, dynamic>{
      'money_mugged': instance.moneyMugged,
      'largest_mug': instance.largestMug,
      'items_looted': instance.itemsLooted,
    };

PersonalStatsAttackingExtended$Attacking$Ammunition
    _$PersonalStatsAttackingExtended$Attacking$AmmunitionFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Ammunition(
          total: (json['total'] as num?)?.toInt(),
          special: (json['special'] as num?)?.toInt(),
          hollowPoint: (json['hollow_point'] as num?)?.toInt(),
          tracer: (json['tracer'] as num?)?.toInt(),
          piercing: (json['piercing'] as num?)?.toInt(),
          incendiary: (json['incendiary'] as num?)?.toInt(),
        );

Map<String, dynamic>
    _$PersonalStatsAttackingExtended$Attacking$AmmunitionToJson(
            PersonalStatsAttackingExtended$Attacking$Ammunition instance) =>
        <String, dynamic>{
          'total': instance.total,
          'special': instance.special,
          'hollow_point': instance.hollowPoint,
          'tracer': instance.tracer,
          'piercing': instance.piercing,
          'incendiary': instance.incendiary,
        };

PersonalStatsAttackingExtended$Attacking$Faction
    _$PersonalStatsAttackingExtended$Attacking$FactionFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Faction(
          respect: (json['respect'] as num?)?.toInt(),
          retaliations: (json['retaliations'] as num?)?.toInt(),
          rankedWarHits: (json['ranked_war_hits'] as num?)?.toInt(),
          raidHits: (json['raid_hits'] as num?)?.toInt(),
          territory: json['territory'] == null
              ? null
              : PersonalStatsAttackingExtended$Attacking$Faction$Territory
                  .fromJson(json['territory'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$Attacking$FactionToJson(
        PersonalStatsAttackingExtended$Attacking$Faction instance) =>
    <String, dynamic>{
      'respect': instance.respect,
      'retaliations': instance.retaliations,
      'ranked_war_hits': instance.rankedWarHits,
      'raid_hits': instance.raidHits,
      'territory': instance.territory?.toJson(),
    };

PersonalStatsAttackingPopular$Attacking$Attacks
    _$PersonalStatsAttackingPopular$Attacking$AttacksFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Attacks(
          won: (json['won'] as num?)?.toInt(),
          lost: (json['lost'] as num?)?.toInt(),
          stalemate: (json['stalemate'] as num?)?.toInt(),
          assist: (json['assist'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$AttacksToJson(
        PersonalStatsAttackingPopular$Attacking$Attacks instance) =>
    <String, dynamic>{
      'won': instance.won,
      'lost': instance.lost,
      'stalemate': instance.stalemate,
      'assist': instance.assist,
    };

PersonalStatsAttackingPopular$Attacking$Defends
    _$PersonalStatsAttackingPopular$Attacking$DefendsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Defends(
          won: (json['won'] as num?)?.toInt(),
          lost: (json['lost'] as num?)?.toInt(),
          stalemate: (json['stalemate'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$DefendsToJson(
        PersonalStatsAttackingPopular$Attacking$Defends instance) =>
    <String, dynamic>{
      'won': instance.won,
      'lost': instance.lost,
      'stalemate': instance.stalemate,
    };

PersonalStatsAttackingPopular$Attacking$Escapes
    _$PersonalStatsAttackingPopular$Attacking$EscapesFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Escapes(
          player: (json['player'] as num?)?.toInt(),
          foes: (json['foes'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$EscapesToJson(
        PersonalStatsAttackingPopular$Attacking$Escapes instance) =>
    <String, dynamic>{
      'player': instance.player,
      'foes': instance.foes,
    };

PersonalStatsAttackingPopular$Attacking$Killstreak
    _$PersonalStatsAttackingPopular$Attacking$KillstreakFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Killstreak(
          best: (json['best'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$KillstreakToJson(
        PersonalStatsAttackingPopular$Attacking$Killstreak instance) =>
    <String, dynamic>{
      'best': instance.best,
    };

PersonalStatsAttackingPopular$Attacking$Hits
    _$PersonalStatsAttackingPopular$Attacking$HitsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Hits(
          success: (json['success'] as num?)?.toInt(),
          miss: (json['miss'] as num?)?.toInt(),
          critical: (json['critical'] as num?)?.toInt(),
          oneHitKills: (json['one_hit_kills'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$HitsToJson(
        PersonalStatsAttackingPopular$Attacking$Hits instance) =>
    <String, dynamic>{
      'success': instance.success,
      'miss': instance.miss,
      'critical': instance.critical,
      'one_hit_kills': instance.oneHitKills,
    };

PersonalStatsAttackingPopular$Attacking$Damage
    _$PersonalStatsAttackingPopular$Attacking$DamageFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Damage(
          total: (json['total'] as num?)?.toInt(),
          best: (json['best'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$DamageToJson(
        PersonalStatsAttackingPopular$Attacking$Damage instance) =>
    <String, dynamic>{
      'total': instance.total,
      'best': instance.best,
    };

PersonalStatsAttackingPopular$Attacking$Networth
    _$PersonalStatsAttackingPopular$Attacking$NetworthFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Networth(
          moneyMugged: (json['money_mugged'] as num?)?.toInt(),
          largestMug: (json['largest_mug'] as num?)?.toInt(),
          itemsLooted: (json['items_looted'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$NetworthToJson(
        PersonalStatsAttackingPopular$Attacking$Networth instance) =>
    <String, dynamic>{
      'money_mugged': instance.moneyMugged,
      'largest_mug': instance.largestMug,
      'items_looted': instance.itemsLooted,
    };

PersonalStatsAttackingPopular$Attacking$Ammunition
    _$PersonalStatsAttackingPopular$Attacking$AmmunitionFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Ammunition(
          total: (json['total'] as num?)?.toInt(),
          special: (json['special'] as num?)?.toInt(),
          hollowPoint: (json['hollow_point'] as num?)?.toInt(),
          tracer: (json['tracer'] as num?)?.toInt(),
          piercing: (json['piercing'] as num?)?.toInt(),
          incendiary: (json['incendiary'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$AmmunitionToJson(
        PersonalStatsAttackingPopular$Attacking$Ammunition instance) =>
    <String, dynamic>{
      'total': instance.total,
      'special': instance.special,
      'hollow_point': instance.hollowPoint,
      'tracer': instance.tracer,
      'piercing': instance.piercing,
      'incendiary': instance.incendiary,
    };

PersonalStatsAttackingPopular$Attacking$Faction
    _$PersonalStatsAttackingPopular$Attacking$FactionFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Faction(
          respect: (json['respect'] as num?)?.toInt(),
          rankedWarHits: (json['ranked_war_hits'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$FactionToJson(
        PersonalStatsAttackingPopular$Attacking$Faction instance) =>
    <String, dynamic>{
      'respect': instance.respect,
      'ranked_war_hits': instance.rankedWarHits,
    };

UserCrimeDetailsCardSkimming$CardDetails$Areas$Item
    _$UserCrimeDetailsCardSkimming$CardDetails$Areas$ItemFromJson(
            Map<String, dynamic> json) =>
        UserCrimeDetailsCardSkimming$CardDetails$Areas$Item(
          id: (json['id'] as num?)?.toInt(),
          amount: (json['amount'] as num?)?.toInt(),
        );

Map<String, dynamic>
    _$UserCrimeDetailsCardSkimming$CardDetails$Areas$ItemToJson(
            UserCrimeDetailsCardSkimming$CardDetails$Areas$Item instance) =>
        <String, dynamic>{
          'id': instance.id,
          'amount': instance.amount,
        };

PersonalStatsOther$Other$Activity$Streak
    _$PersonalStatsOther$Other$Activity$StreakFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsOther$Other$Activity$Streak(
          best: (json['best'] as num?)?.toInt(),
          current: (json['current'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsOther$Other$Activity$StreakToJson(
        PersonalStatsOther$Other$Activity$Streak instance) =>
    <String, dynamic>{
      'best': instance.best,
      'current': instance.current,
    };

PersonalStatsOtherPopular$Other$Activity$Streak
    _$PersonalStatsOtherPopular$Other$Activity$StreakFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsOtherPopular$Other$Activity$Streak(
          best: (json['best'] as num?)?.toInt(),
          current: (json['current'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsOtherPopular$Other$Activity$StreakToJson(
        PersonalStatsOtherPopular$Other$Activity$Streak instance) =>
    <String, dynamic>{
      'best': instance.best,
      'current': instance.current,
    };

PersonalStatsTrading$Trading$Items$Bought
    _$PersonalStatsTrading$Trading$Items$BoughtFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsTrading$Trading$Items$Bought(
          market: (json['market'] as num?)?.toInt(),
          shops: (json['shops'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsTrading$Trading$Items$BoughtToJson(
        PersonalStatsTrading$Trading$Items$Bought instance) =>
    <String, dynamic>{
      'market': instance.market,
      'shops': instance.shops,
    };

PersonalStatsTrading$Trading$Items$Auctions
    _$PersonalStatsTrading$Trading$Items$AuctionsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsTrading$Trading$Items$Auctions(
          won: (json['won'] as num?)?.toInt(),
          sold: (json['sold'] as num?)?.toInt(),
        );

Map<String, dynamic> _$PersonalStatsTrading$Trading$Items$AuctionsToJson(
        PersonalStatsTrading$Trading$Items$Auctions instance) =>
    <String, dynamic>{
      'won': instance.won,
      'sold': instance.sold,
    };

PersonalStatsAttackingPublic$Attacking$Faction$Territory
    _$PersonalStatsAttackingPublic$Attacking$Faction$TerritoryFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPublic$Attacking$Faction$Territory(
          wallJoins: (json['wall_joins'] as num?)?.toInt(),
          wallClears: (json['wall_clears'] as num?)?.toInt(),
          wallTime: (json['wall_time'] as num?)?.toInt(),
        );

Map<String,
    dynamic> _$PersonalStatsAttackingPublic$Attacking$Faction$TerritoryToJson(
        PersonalStatsAttackingPublic$Attacking$Faction$Territory instance) =>
    <String, dynamic>{
      'wall_joins': instance.wallJoins,
      'wall_clears': instance.wallClears,
      'wall_time': instance.wallTime,
    };

PersonalStatsAttackingExtended$Attacking$Faction$Territory
    _$PersonalStatsAttackingExtended$Attacking$Faction$TerritoryFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Faction$Territory(
          wallJoins: (json['wall_joins'] as num?)?.toInt(),
          wallClears: (json['wall_clears'] as num?)?.toInt(),
          wallTime: (json['wall_time'] as num?)?.toInt(),
        );

Map<String,
    dynamic> _$PersonalStatsAttackingExtended$Attacking$Faction$TerritoryToJson(
        PersonalStatsAttackingExtended$Attacking$Faction$Territory instance) =>
    <String, dynamic>{
      'wall_joins': instance.wallJoins,
      'wall_clears': instance.wallClears,
      'wall_time': instance.wallTime,
    };
