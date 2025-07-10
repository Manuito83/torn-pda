// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'torn_v2.swagger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestLinks _$RequestLinksFromJson(Map<String, dynamic> json) => RequestLinks(
      next: json['next'],
      prev: json['prev'],
    );

Map<String, dynamic> _$RequestLinksToJson(RequestLinks instance) =>
    <String, dynamic>{
      'next': instance.next,
      'prev': instance.prev,
    };

RequestMetadata _$RequestMetadataFromJson(Map<String, dynamic> json) =>
    RequestMetadata(
      links: RequestLinks.fromJson(json['links'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RequestMetadataToJson(RequestMetadata instance) =>
    <String, dynamic>{
      'links': instance.links.toJson(),
    };

RequestMetadataWithLinks _$RequestMetadataWithLinksFromJson(
        Map<String, dynamic> json) =>
    RequestMetadataWithLinks(
      links: RequestLinks.fromJson(json['links'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RequestMetadataWithLinksToJson(
        RequestMetadataWithLinks instance) =>
    <String, dynamic>{
      'links': instance.links.toJson(),
    };

RequestMetadataWithLinksAndTotal _$RequestMetadataWithLinksAndTotalFromJson(
        Map<String, dynamic> json) =>
    RequestMetadataWithLinksAndTotal(
      links: RequestLinks.fromJson(json['links'] as Map<String, dynamic>),
      total: (json['total'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RequestMetadataWithLinksAndTotalToJson(
        RequestMetadataWithLinksAndTotal instance) =>
    <String, dynamic>{
      'links': instance.links.toJson(),
      'total': instance.total,
    };

Parameters _$ParametersFromJson(Map<String, dynamic> json) => Parameters();

Map<String, dynamic> _$ParametersToJson(Parameters instance) =>
    <String, dynamic>{};

AttackPlayerFaction _$AttackPlayerFactionFromJson(Map<String, dynamic> json) =>
    AttackPlayerFaction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$AttackPlayerFactionToJson(
        AttackPlayerFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

AttackPlayer _$AttackPlayerFromJson(Map<String, dynamic> json) => AttackPlayer(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      level: (json['level'] as num).toInt(),
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
      id: (json['id'] as num).toInt(),
      factionId: json['faction_id'],
    );

Map<String, dynamic> _$AttackPlayerSimplifiedToJson(
        AttackPlayerSimplified instance) =>
    <String, dynamic>{
      'id': instance.id,
      'faction_id': instance.factionId,
    };

AttackingFinishingHitEffects _$AttackingFinishingHitEffectsFromJson(
        Map<String, dynamic> json) =>
    AttackingFinishingHitEffects(
      name: attackFinishingHitEffectFromJson(json['name']),
      $value: (json['value'] as num).toInt(),
    );

Map<String, dynamic> _$AttackingFinishingHitEffectsToJson(
        AttackingFinishingHitEffects instance) =>
    <String, dynamic>{
      'name': attackFinishingHitEffectToJson(instance.name),
      'value': instance.$value,
    };

Attack _$AttackFromJson(Map<String, dynamic> json) => Attack(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      started: (json['started'] as num).toInt(),
      ended: (json['ended'] as num).toInt(),
      attacker: json['attacker'],
      defender: AttackPlayer.fromJson(json['defender'] as Map<String, dynamic>),
      result: factionAttackResultFromJson(json['result']),
      respectGain: (json['respect_gain'] as num).toDouble(),
      respectLoss: (json['respect_loss'] as num).toDouble(),
      chain: (json['chain'] as num).toInt(),
      isInterrupted: json['is_interrupted'] as bool,
      isStealthed: json['is_stealthed'] as bool,
      isRaid: json['is_raid'] as bool,
      isRankedWar: json['is_ranked_war'] as bool,
      finishingHitEffects: (json['finishing_hit_effects'] as List<dynamic>?)
              ?.map((e) => AttackingFinishingHitEffects.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      modifiers:
          Attack$Modifiers.fromJson(json['modifiers'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttackToJson(Attack instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'started': instance.started,
      'ended': instance.ended,
      'attacker': instance.attacker,
      'defender': instance.defender.toJson(),
      'result': factionAttackResultToJson(instance.result),
      'respect_gain': instance.respectGain,
      'respect_loss': instance.respectLoss,
      'chain': instance.chain,
      'is_interrupted': instance.isInterrupted,
      'is_stealthed': instance.isStealthed,
      'is_raid': instance.isRaid,
      'is_ranked_war': instance.isRankedWar,
      'finishing_hit_effects':
          instance.finishingHitEffects.map((e) => e.toJson()).toList(),
      'modifiers': instance.modifiers.toJson(),
    };

AttackSimplified _$AttackSimplifiedFromJson(Map<String, dynamic> json) =>
    AttackSimplified(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      started: (json['started'] as num).toInt(),
      ended: (json['ended'] as num).toInt(),
      attacker: json['attacker'],
      defender: AttackPlayerSimplified.fromJson(
          json['defender'] as Map<String, dynamic>),
      result: factionAttackResultFromJson(json['result']),
      respectGain: (json['respect_gain'] as num).toDouble(),
      respectLoss: (json['respect_loss'] as num).toDouble(),
    );

Map<String, dynamic> _$AttackSimplifiedToJson(AttackSimplified instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'started': instance.started,
      'ended': instance.ended,
      'attacker': instance.attacker,
      'defender': instance.defender.toJson(),
      'result': factionAttackResultToJson(instance.result),
      'respect_gain': instance.respectGain,
      'respect_loss': instance.respectLoss,
    };

ReviveSimplified _$ReviveSimplifiedFromJson(Map<String, dynamic> json) =>
    ReviveSimplified(
      id: (json['id'] as num).toInt(),
      reviver: ReviveSimplified$Reviver.fromJson(
          json['reviver'] as Map<String, dynamic>),
      target: ReviveSimplified$Target.fromJson(
          json['target'] as Map<String, dynamic>),
      successChance: (json['success_chance'] as num).toDouble(),
      result: json['result'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$ReviveSimplifiedToJson(ReviveSimplified instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reviver': instance.reviver.toJson(),
      'target': instance.target.toJson(),
      'success_chance': instance.successChance,
      'result': instance.result,
      'timestamp': instance.timestamp,
    };

Revive _$ReviveFromJson(Map<String, dynamic> json) => Revive(
      id: (json['id'] as num).toInt(),
      reviver: Revive$Reviver.fromJson(json['reviver'] as Map<String, dynamic>),
      target: Revive$Target.fromJson(json['target'] as Map<String, dynamic>),
      successChance: (json['success_chance'] as num).toDouble(),
      result: json['result'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$ReviveToJson(Revive instance) => <String, dynamic>{
      'id': instance.id,
      'reviver': instance.reviver.toJson(),
      'target': instance.target.toJson(),
      'success_chance': instance.successChance,
      'result': instance.result,
      'timestamp': instance.timestamp,
    };

RevivesResponse _$RevivesResponseFromJson(Map<String, dynamic> json) =>
    RevivesResponse(
      revives: (json['revives'] as List<dynamic>?)
              ?.map((e) => Revive.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RevivesResponseToJson(RevivesResponse instance) =>
    <String, dynamic>{
      'revives': instance.revives.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

RevivesFullResponse _$RevivesFullResponseFromJson(Map<String, dynamic> json) =>
    RevivesFullResponse(
      revives: (json['revives'] as List<dynamic>?)
              ?.map((e) => ReviveSimplified.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RevivesFullResponseToJson(
        RevivesFullResponse instance) =>
    <String, dynamic>{
      'revives': instance.revives.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

TimestampResponse _$TimestampResponseFromJson(Map<String, dynamic> json) =>
    TimestampResponse(
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$TimestampResponseToJson(TimestampResponse instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
    };

ReportBase _$ReportBaseFromJson(Map<String, dynamic> json) => ReportBase(
      type: reportTypeEnumFromJson(json['type']),
      targetId: json['target_id'],
      reporterId: (json['reporter_id'] as num).toInt(),
      factionId: json['faction_id'],
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$ReportBaseToJson(ReportBase instance) =>
    <String, dynamic>{
      'type': reportTypeEnumToJson(instance.type),
      'target_id': instance.targetId,
      'reporter_id': instance.reporterId,
      'faction_id': instance.factionId,
      'timestamp': instance.timestamp,
    };

ReportWarrantDetails _$ReportWarrantDetailsFromJson(
        Map<String, dynamic> json) =>
    ReportWarrantDetails(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      warrant: (json['warrant'] as num).toInt(),
    );

Map<String, dynamic> _$ReportWarrantDetailsToJson(
        ReportWarrantDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'warrant': instance.warrant,
    };

ReportMostWanted _$ReportMostWantedFromJson(Map<String, dynamic> json) =>
    ReportMostWanted(
      top: (json['top'] as List<dynamic>?)
              ?.map((e) =>
                  ReportWarrantDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notable: (json['notable'] as List<dynamic>?)
              ?.map((e) =>
                  ReportWarrantDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ReportMostWantedToJson(ReportMostWanted instance) =>
    <String, dynamic>{
      'top': instance.top.map((e) => e.toJson()).toList(),
      'notable': instance.notable.map((e) => e.toJson()).toList(),
    };

ReportMoney _$ReportMoneyFromJson(Map<String, dynamic> json) => ReportMoney(
      money: (json['money'] as num).toInt(),
    );

Map<String, dynamic> _$ReportMoneyToJson(ReportMoney instance) =>
    <String, dynamic>{
      'money': instance.money,
    };

ReportInvestment _$ReportInvestmentFromJson(Map<String, dynamic> json) =>
    ReportInvestment(
      amount: (json['amount'] as num).toInt(),
      until: (json['until'] as num).toInt(),
    );

Map<String, dynamic> _$ReportInvestmentToJson(ReportInvestment instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'until': instance.until,
    };

ReportTrueLevel _$ReportTrueLevelFromJson(Map<String, dynamic> json) =>
    ReportTrueLevel(
      level: (json['level'] as num).toInt(),
    );

Map<String, dynamic> _$ReportTrueLevelToJson(ReportTrueLevel instance) =>
    <String, dynamic>{
      'level': instance.level,
    };

ReportStats _$ReportStatsFromJson(Map<String, dynamic> json) => ReportStats(
      strength: json['strength'],
      speed: json['speed'],
      dexterity: json['dexterity'],
      defense: json['defense'],
      total: json['total'],
    );

Map<String, dynamic> _$ReportStatsToJson(ReportStats instance) =>
    <String, dynamic>{
      'strength': instance.strength,
      'speed': instance.speed,
      'dexterity': instance.dexterity,
      'defense': instance.defense,
      'total': instance.total,
    };

ReportHistoryFaction _$ReportHistoryFactionFromJson(
        Map<String, dynamic> json) =>
    ReportHistoryFaction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      joined: DateTime.parse(json['joined'] as String),
      left: json['left'],
    );

Map<String, dynamic> _$ReportHistoryFactionToJson(
        ReportHistoryFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'joined': _dateToJson(instance.joined),
      'left': instance.left,
    };

ReportHistoryCompany _$ReportHistoryCompanyFromJson(
        Map<String, dynamic> json) =>
    ReportHistoryCompany(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      joined: DateTime.parse(json['joined'] as String),
      left: json['left'],
    );

Map<String, dynamic> _$ReportHistoryCompanyToJson(
        ReportHistoryCompany instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'joined': _dateToJson(instance.joined),
      'left': instance.left,
    };

ReportHistory _$ReportHistoryFromJson(Map<String, dynamic> json) =>
    ReportHistory(
      factions: (json['factions'] as List<dynamic>?)
              ?.map((e) =>
                  ReportHistoryFaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      companies: (json['companies'] as List<dynamic>?)
              ?.map((e) =>
                  ReportHistoryCompany.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ReportHistoryToJson(ReportHistory instance) =>
    <String, dynamic>{
      'factions': instance.factions.map((e) => e.toJson()).toList(),
      'companies': instance.companies.map((e) => e.toJson()).toList(),
    };

ReportFriendOrFoeUser _$ReportFriendOrFoeUserFromJson(
        Map<String, dynamic> json) =>
    ReportFriendOrFoeUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$ReportFriendOrFoeUserToJson(
        ReportFriendOrFoeUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

ReportFriendOrFoe _$ReportFriendOrFoeFromJson(Map<String, dynamic> json) =>
    ReportFriendOrFoe(
      friends: (json['friends'] as List<dynamic>?)
              ?.map((e) =>
                  ReportFriendOrFoeUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      enemies: (json['enemies'] as List<dynamic>?)
              ?.map((e) =>
                  ReportFriendOrFoeUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ReportFriendOrFoeToJson(ReportFriendOrFoe instance) =>
    <String, dynamic>{
      'friends': instance.friends.map((e) => e.toJson()).toList(),
      'enemies': instance.enemies.map((e) => e.toJson()).toList(),
    };

ReportCompanyFinancials _$ReportCompanyFinancialsFromJson(
        Map<String, dynamic> json) =>
    ReportCompanyFinancials(
      balance: (json['balance'] as num).toInt(),
      employees: (json['employees'] as num).toInt(),
      wages: ReportCompanyFinancials$Wages.fromJson(
          json['wages'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReportCompanyFinancialsToJson(
        ReportCompanyFinancials instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'employees': instance.employees,
      'wages': instance.wages.toJson(),
    };

ReportStockAnalysis _$ReportStockAnalysisFromJson(Map<String, dynamic> json) =>
    ReportStockAnalysis(
      items: (json['items'] as List<dynamic>)
          .map((e) => ReportStockAnalysis$Items$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReportStockAnalysisToJson(
        ReportStockAnalysis instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

ReportAnonymousBounties _$ReportAnonymousBountiesFromJson(
        Map<String, dynamic> json) =>
    ReportAnonymousBounties(
      bounties: (json['bounties'] as List<dynamic>)
          .map((e) => ReportAnonymousBounties$Bounties$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReportAnonymousBountiesToJson(
        ReportAnonymousBounties instance) =>
    <String, dynamic>{
      'bounties': instance.bounties.map((e) => e.toJson()).toList(),
    };

ReportReport _$ReportReportFromJson(Map<String, dynamic> json) => ReportReport(
      report: json['report'],
    );

Map<String, dynamic> _$ReportReportToJson(ReportReport instance) =>
    <String, dynamic>{
      'report': instance.report,
    };

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
      type: reportTypeEnumFromJson(json['type']),
      targetId: json['target_id'],
      reporterId: (json['reporter_id'] as num).toInt(),
      factionId: json['faction_id'],
      timestamp: (json['timestamp'] as num).toInt(),
      report: json['report'],
    );

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
      'type': reportTypeEnumToJson(instance.type),
      'target_id': instance.targetId,
      'reporter_id': instance.reporterId,
      'faction_id': instance.factionId,
      'timestamp': instance.timestamp,
      'report': instance.report,
    };

ReportsResponse _$ReportsResponseFromJson(Map<String, dynamic> json) =>
    ReportsResponse(
      reports: (json['reports'] as List<dynamic>?)
              ?.map((e) => Report.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReportsResponseToJson(ReportsResponse instance) =>
    <String, dynamic>{
      'reports': instance.reports.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

SelectionCategoryEnum _$SelectionCategoryEnumFromJson(
        Map<String, dynamic> json) =>
    SelectionCategoryEnum();

Map<String, dynamic> _$SelectionCategoryEnumToJson(
        SelectionCategoryEnum instance) =>
    <String, dynamic>{};

BasicUser _$BasicUserFromJson(Map<String, dynamic> json) => BasicUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$BasicUserToJson(BasicUser instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

UserPropertyBasicDetails _$UserPropertyBasicDetailsFromJson(
        Map<String, dynamic> json) =>
    UserPropertyBasicDetails(
      id: (json['id'] as num).toInt(),
      owner: BasicUser.fromJson(json['owner'] as Map<String, dynamic>),
      property:
          BasicProperty.fromJson(json['property'] as Map<String, dynamic>),
      happy: (json['happy'] as num).toInt(),
      upkeep: UserPropertyBasicDetails$Upkeep.fromJson(
          json['upkeep'] as Map<String, dynamic>),
      marketPrice: (json['market_price'] as num).toInt(),
      modifications:
          propertyModificationEnumListFromJson(json['modifications'] as List?),
      staff: (json['staff'] as List<dynamic>)
          .map((e) => UserPropertyBasicDetails$Staff$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserPropertyBasicDetailsToJson(
        UserPropertyBasicDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner': instance.owner.toJson(),
      'property': instance.property.toJson(),
      'happy': instance.happy,
      'upkeep': instance.upkeep.toJson(),
      'market_price': instance.marketPrice,
      'modifications':
          propertyModificationEnumListToJson(instance.modifications),
      'staff': instance.staff.map((e) => e.toJson()).toList(),
    };

UserPropertyDetailsExtended _$UserPropertyDetailsExtendedFromJson(
        Map<String, dynamic> json) =>
    UserPropertyDetailsExtended(
      usedBy: (json['used_by'] as List<dynamic>?)
              ?.map((e) => BasicUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: userPropertyDetailsExtendedStatusFromJson(json['status']),
      id: (json['id'] as num).toInt(),
      owner: BasicUser.fromJson(json['owner'] as Map<String, dynamic>),
      property:
          BasicProperty.fromJson(json['property'] as Map<String, dynamic>),
      happy: (json['happy'] as num).toInt(),
      upkeep: UserPropertyDetailsExtended$Upkeep.fromJson(
          json['upkeep'] as Map<String, dynamic>),
      marketPrice: (json['market_price'] as num).toInt(),
      modifications:
          propertyModificationEnumListFromJson(json['modifications'] as List?),
      staff: (json['staff'] as List<dynamic>)
          .map((e) => UserPropertyDetailsExtended$Staff$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserPropertyDetailsExtendedToJson(
        UserPropertyDetailsExtended instance) =>
    <String, dynamic>{
      'used_by': instance.usedBy.map((e) => e.toJson()).toList(),
      'status': userPropertyDetailsExtendedStatusToJson(instance.status),
      'id': instance.id,
      'owner': instance.owner.toJson(),
      'property': instance.property.toJson(),
      'happy': instance.happy,
      'upkeep': instance.upkeep.toJson(),
      'market_price': instance.marketPrice,
      'modifications':
          propertyModificationEnumListToJson(instance.modifications),
      'staff': instance.staff.map((e) => e.toJson()).toList(),
    };

UserPropertyDetails _$UserPropertyDetailsFromJson(Map<String, dynamic> json) =>
    UserPropertyDetails(
      usedBy: (json['used_by'] as List<dynamic>?)
              ?.map((e) => BasicUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      id: (json['id'] as num).toInt(),
      owner: BasicUser.fromJson(json['owner'] as Map<String, dynamic>),
      property:
          BasicProperty.fromJson(json['property'] as Map<String, dynamic>),
      happy: (json['happy'] as num).toInt(),
      upkeep: UserPropertyDetails$Upkeep.fromJson(
          json['upkeep'] as Map<String, dynamic>),
      marketPrice: (json['market_price'] as num).toInt(),
      modifications:
          propertyModificationEnumListFromJson(json['modifications'] as List?),
      staff: (json['staff'] as List<dynamic>)
          .map((e) => UserPropertyDetails$Staff$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserPropertyDetailsToJson(
        UserPropertyDetails instance) =>
    <String, dynamic>{
      'used_by': instance.usedBy.map((e) => e.toJson()).toList(),
      'id': instance.id,
      'owner': instance.owner.toJson(),
      'property': instance.property.toJson(),
      'happy': instance.happy,
      'upkeep': instance.upkeep.toJson(),
      'market_price': instance.marketPrice,
      'modifications':
          propertyModificationEnumListToJson(instance.modifications),
      'staff': instance.staff.map((e) => e.toJson()).toList(),
    };

UserPropertyDetailsExtendedRented _$UserPropertyDetailsExtendedRentedFromJson(
        Map<String, dynamic> json) =>
    UserPropertyDetailsExtendedRented(
      usedBy: (json['used_by'] as List<dynamic>?)
              ?.map((e) => BasicUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: userPropertyDetailsExtendedRentedStatusFromJson(json['status']),
      cost: (json['cost'] as num).toInt(),
      costPerDay: (json['cost_per_day'] as num).toInt(),
      rentalPeriod: (json['rental_period'] as num).toInt(),
      rentalPeriodRemaining: (json['rental_period_remaining'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      owner: BasicUser.fromJson(json['owner'] as Map<String, dynamic>),
      property:
          BasicProperty.fromJson(json['property'] as Map<String, dynamic>),
      happy: (json['happy'] as num).toInt(),
      upkeep: UserPropertyDetailsExtendedRented$Upkeep.fromJson(
          json['upkeep'] as Map<String, dynamic>),
      marketPrice: (json['market_price'] as num).toInt(),
      modifications:
          propertyModificationEnumListFromJson(json['modifications'] as List?),
      staff: (json['staff'] as List<dynamic>)
          .map((e) => UserPropertyDetailsExtendedRented$Staff$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserPropertyDetailsExtendedRentedToJson(
        UserPropertyDetailsExtendedRented instance) =>
    <String, dynamic>{
      'used_by': instance.usedBy.map((e) => e.toJson()).toList(),
      'status': userPropertyDetailsExtendedRentedStatusToJson(instance.status),
      'cost': instance.cost,
      'cost_per_day': instance.costPerDay,
      'rental_period': instance.rentalPeriod,
      'rental_period_remaining': instance.rentalPeriodRemaining,
      'id': instance.id,
      'owner': instance.owner.toJson(),
      'property': instance.property.toJson(),
      'happy': instance.happy,
      'upkeep': instance.upkeep.toJson(),
      'market_price': instance.marketPrice,
      'modifications':
          propertyModificationEnumListToJson(instance.modifications),
      'staff': instance.staff.map((e) => e.toJson()).toList(),
    };

UserPropertyDetailsExtendedForRent _$UserPropertyDetailsExtendedForRentFromJson(
        Map<String, dynamic> json) =>
    UserPropertyDetailsExtendedForRent(
      usedBy: (json['used_by'] as List<dynamic>?)
              ?.map((e) => BasicUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: userPropertyDetailsExtendedForRentStatusFromJson(json['status']),
      cost: (json['cost'] as num).toInt(),
      costPerDay: (json['cost_per_day'] as num).toInt(),
      rentalPeriod: (json['rental_period'] as num).toInt(),
      renterAsked: json['renter_asked'] == null
          ? null
          : BasicUser.fromJson(json['renter_asked'] as Map<String, dynamic>),
      id: (json['id'] as num).toInt(),
      owner: BasicUser.fromJson(json['owner'] as Map<String, dynamic>),
      property:
          BasicProperty.fromJson(json['property'] as Map<String, dynamic>),
      happy: (json['happy'] as num).toInt(),
      upkeep: UserPropertyDetailsExtendedForRent$Upkeep.fromJson(
          json['upkeep'] as Map<String, dynamic>),
      marketPrice: (json['market_price'] as num).toInt(),
      modifications:
          propertyModificationEnumListFromJson(json['modifications'] as List?),
      staff: (json['staff'] as List<dynamic>)
          .map((e) => UserPropertyDetailsExtendedForRent$Staff$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserPropertyDetailsExtendedForRentToJson(
        UserPropertyDetailsExtendedForRent instance) =>
    <String, dynamic>{
      'used_by': instance.usedBy.map((e) => e.toJson()).toList(),
      'status': userPropertyDetailsExtendedForRentStatusToJson(instance.status),
      'cost': instance.cost,
      'cost_per_day': instance.costPerDay,
      'rental_period': instance.rentalPeriod,
      'renter_asked': instance.renterAsked?.toJson(),
      'id': instance.id,
      'owner': instance.owner.toJson(),
      'property': instance.property.toJson(),
      'happy': instance.happy,
      'upkeep': instance.upkeep.toJson(),
      'market_price': instance.marketPrice,
      'modifications':
          propertyModificationEnumListToJson(instance.modifications),
      'staff': instance.staff.map((e) => e.toJson()).toList(),
    };

UserPropertyDetailsExtendedForSale _$UserPropertyDetailsExtendedForSaleFromJson(
        Map<String, dynamic> json) =>
    UserPropertyDetailsExtendedForSale(
      usedBy: (json['used_by'] as List<dynamic>?)
              ?.map((e) => BasicUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: userPropertyDetailsExtendedForSaleStatusFromJson(json['status']),
      cost: (json['cost'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      owner: BasicUser.fromJson(json['owner'] as Map<String, dynamic>),
      property:
          BasicProperty.fromJson(json['property'] as Map<String, dynamic>),
      happy: (json['happy'] as num).toInt(),
      upkeep: UserPropertyDetailsExtendedForSale$Upkeep.fromJson(
          json['upkeep'] as Map<String, dynamic>),
      marketPrice: (json['market_price'] as num).toInt(),
      modifications:
          propertyModificationEnumListFromJson(json['modifications'] as List?),
      staff: (json['staff'] as List<dynamic>)
          .map((e) => UserPropertyDetailsExtendedForSale$Staff$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserPropertyDetailsExtendedForSaleToJson(
        UserPropertyDetailsExtendedForSale instance) =>
    <String, dynamic>{
      'used_by': instance.usedBy.map((e) => e.toJson()).toList(),
      'status': userPropertyDetailsExtendedForSaleStatusToJson(instance.status),
      'cost': instance.cost,
      'id': instance.id,
      'owner': instance.owner.toJson(),
      'property': instance.property.toJson(),
      'happy': instance.happy,
      'upkeep': instance.upkeep.toJson(),
      'market_price': instance.marketPrice,
      'modifications':
          propertyModificationEnumListToJson(instance.modifications),
      'staff': instance.staff.map((e) => e.toJson()).toList(),
    };

UserPropertiesResponse _$UserPropertiesResponseFromJson(
        Map<String, dynamic> json) =>
    UserPropertiesResponse(
      properties: (json['properties'] as List<dynamic>?)
              ?.map((e) => e as Object)
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserPropertiesResponseToJson(
        UserPropertiesResponse instance) =>
    <String, dynamic>{
      'properties': instance.properties,
      '_metadata': instance.metadata.toJson(),
    };

UserPropertyResponse _$UserPropertyResponseFromJson(
        Map<String, dynamic> json) =>
    UserPropertyResponse(
      property: UserPropertyDetails.fromJson(
          json['property'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserPropertyResponseToJson(
        UserPropertyResponse instance) =>
    <String, dynamic>{
      'property': instance.property.toJson(),
    };

UserCurrentEducation _$UserCurrentEducationFromJson(
        Map<String, dynamic> json) =>
    UserCurrentEducation(
      id: (json['id'] as num).toInt(),
      until: (json['until'] as num).toInt(),
    );

Map<String, dynamic> _$UserCurrentEducationToJson(
        UserCurrentEducation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'until': instance.until,
    };

UserEducation _$UserEducationFromJson(Map<String, dynamic> json) =>
    UserEducation(
      complete: (json['complete'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      current: json['current'],
    );

Map<String, dynamic> _$UserEducationToJson(UserEducation instance) =>
    <String, dynamic>{
      'complete': instance.complete,
      'current': instance.current,
    };

UserEducationResponse _$UserEducationResponseFromJson(
        Map<String, dynamic> json) =>
    UserEducationResponse(
      education:
          UserEducation.fromJson(json['education'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserEducationResponseToJson(
        UserEducationResponse instance) =>
    <String, dynamic>{
      'education': instance.education.toJson(),
    };

UserCrimeDetailsBootlegging _$UserCrimeDetailsBootleggingFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsBootlegging(
      onlineStore: UserCrimeDetailsBootlegging$OnlineStore.fromJson(
          json['online_store'] as Map<String, dynamic>),
      dvdSales: UserCrimeDetailsBootlegging$DvdSales.fromJson(
          json['dvd_sales'] as Map<String, dynamic>),
      dvdsCopied: (json['dvds_copied'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsBootleggingToJson(
        UserCrimeDetailsBootlegging instance) =>
    <String, dynamic>{
      'online_store': instance.onlineStore.toJson(),
      'dvd_sales': instance.dvdSales.toJson(),
      'dvds_copied': instance.dvdsCopied,
    };

UserCrimeDetailsGraffiti _$UserCrimeDetailsGraffitiFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsGraffiti(
      cansUsed: (json['cans_used'] as num).toInt(),
      mostGraffitiInOneArea: (json['most_graffiti_in_one_area'] as num).toInt(),
      mostGraffitiSimultaneously:
          (json['most_graffiti_simultaneously'] as num).toInt(),
      graffitiRemoved: (json['graffiti_removed'] as num).toInt(),
      costToCity: (json['cost_to_city'] as num).toInt(),
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
      averageNotoriety: (json['average_notoriety'] as num).toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsShopliftingToJson(
        UserCrimeDetailsShoplifting instance) =>
    <String, dynamic>{
      'average_notoriety': instance.averageNotoriety,
    };

UserCrimeDetailsCardSkimming _$UserCrimeDetailsCardSkimmingFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsCardSkimming(
      cardDetails: UserCrimeDetailsCardSkimming$CardDetails.fromJson(
          json['card_details'] as Map<String, dynamic>),
      skimmers: UserCrimeDetailsCardSkimming$Skimmers.fromJson(
          json['skimmers'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCrimeDetailsCardSkimmingToJson(
        UserCrimeDetailsCardSkimming instance) =>
    <String, dynamic>{
      'card_details': instance.cardDetails.toJson(),
      'skimmers': instance.skimmers.toJson(),
    };

UserCrimeDetailsHustling _$UserCrimeDetailsHustlingFromJson(
        Map<String, dynamic> json) =>
    UserCrimeDetailsHustling(
      totalAudienceGathered: (json['total_audience_gathered'] as num).toInt(),
      biggestMoneyWon: (json['biggest_money_won'] as num).toInt(),
      shillMoneyCollected: (json['shill_money_collected'] as num).toInt(),
      pickpocketMoneyCollected:
          (json['pickpocket_money_collected'] as num).toInt(),
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
      bruteForceCycles: (json['brute_force_cycles'] as num).toInt(),
      encryptionLayersBroken: (json['encryption_layers_broken'] as num).toInt(),
      highestMips: (json['highest_mips'] as num).toInt(),
      charsGuessed: (json['chars_guessed'] as num).toInt(),
      charsGuessedTotal: (json['chars_guessed_total'] as num).toInt(),
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
      mostResponses: (json['most_responses'] as num).toInt(),
      zones: UserCrimeDetailsScamming$Zones.fromJson(
          json['zones'] as Map<String, dynamic>),
      concerns: UserCrimeDetailsScamming$Concerns.fromJson(
          json['concerns'] as Map<String, dynamic>),
      payouts: UserCrimeDetailsScamming$Payouts.fromJson(
          json['payouts'] as Map<String, dynamic>),
      emails: UserCrimeDetailsScamming$Emails.fromJson(
          json['emails'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCrimeDetailsScammingToJson(
        UserCrimeDetailsScamming instance) =>
    <String, dynamic>{
      'most_responses': instance.mostResponses,
      'zones': instance.zones.toJson(),
      'concerns': instance.concerns.toJson(),
      'payouts': instance.payouts.toJson(),
      'emails': instance.emails.toJson(),
    };

UserSubcrime _$UserSubcrimeFromJson(Map<String, dynamic> json) => UserSubcrime(
      id: (json['id'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      success: (json['success'] as num).toInt(),
      fail: (json['fail'] as num).toInt(),
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
      standard: (json['standard'] as num).toInt(),
      special: (json['special'] as num).toInt(),
    );

Map<String, dynamic> _$UserCrimeRewardAmmoToJson(
        UserCrimeRewardAmmo instance) =>
    <String, dynamic>{
      'standard': instance.standard,
      'special': instance.special,
    };

UserCrimeRewardItem _$UserCrimeRewardItemFromJson(Map<String, dynamic> json) =>
    UserCrimeRewardItem(
      id: (json['id'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
    );

Map<String, dynamic> _$UserCrimeRewardItemToJson(
        UserCrimeRewardItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
    };

UserCrimeRewards _$UserCrimeRewardsFromJson(Map<String, dynamic> json) =>
    UserCrimeRewards(
      money: (json['money'] as num).toInt(),
      ammo: UserCrimeRewardAmmo.fromJson(json['ammo'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  UserCrimeRewardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserCrimeRewardsToJson(UserCrimeRewards instance) =>
    <String, dynamic>{
      'money': instance.money,
      'ammo': instance.ammo.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

UserCrimeAttempts _$UserCrimeAttemptsFromJson(Map<String, dynamic> json) =>
    UserCrimeAttempts(
      total: (json['total'] as num).toInt(),
      success: (json['success'] as num).toInt(),
      fail: (json['fail'] as num).toInt(),
      criticalFail: (json['critical_fail'] as num).toInt(),
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
      'subcrimes': instance.subcrimes.map((e) => e.toJson()).toList(),
    };

UserCrimeUniquesRewardMoney _$UserCrimeUniquesRewardMoneyFromJson(
        Map<String, dynamic> json) =>
    UserCrimeUniquesRewardMoney(
      min: (json['min'] as num).toInt(),
      max: (json['max'] as num).toInt(),
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
      amount: (json['amount'] as num).toInt(),
      type: userCrimeUniquesRewardAmmoEnumFromJson(json['type']),
    );

Map<String, dynamic> _$UserCrimeUniquesRewardAmmoToJson(
        UserCrimeUniquesRewardAmmo instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'type': userCrimeUniquesRewardAmmoEnumToJson(instance.type),
    };

UserCrimeUniquesReward _$UserCrimeUniquesRewardFromJson(
        Map<String, dynamic> json) =>
    UserCrimeUniquesReward(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  UserCrimeRewardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      money: json['money'],
      ammo: json['ammo'],
    );

Map<String, dynamic> _$UserCrimeUniquesRewardToJson(
        UserCrimeUniquesReward instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'money': instance.money,
      'ammo': instance.ammo,
    };

UserCrimeUniques _$UserCrimeUniquesFromJson(Map<String, dynamic> json) =>
    UserCrimeUniques(
      id: (json['id'] as num).toInt(),
      rewards: UserCrimeUniquesReward.fromJson(
          json['rewards'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCrimeUniquesToJson(UserCrimeUniques instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rewards': instance.rewards.toJson(),
    };

UserCrimesResponse _$UserCrimesResponseFromJson(Map<String, dynamic> json) =>
    UserCrimesResponse(
      crimes: UserCrime.fromJson(json['crimes'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCrimesResponseToJson(UserCrimesResponse instance) =>
    <String, dynamic>{
      'crimes': instance.crimes.toJson(),
    };

UserCrime _$UserCrimeFromJson(Map<String, dynamic> json) => UserCrime(
      nerveSpent: (json['nerve_spent'] as num).toInt(),
      skill: (json['skill'] as num).toInt(),
      progressionBonus: (json['progression_bonus'] as num).toInt(),
      rewards:
          UserCrimeRewards.fromJson(json['rewards'] as Map<String, dynamic>),
      attempts:
          UserCrimeAttempts.fromJson(json['attempts'] as Map<String, dynamic>),
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
      'rewards': instance.rewards.toJson(),
      'attempts': instance.attempts.toJson(),
      'uniques': instance.uniques.map((e) => e.toJson()).toList(),
      'miscellaneous': instance.miscellaneous,
    };

UserRacesResponse _$UserRacesResponseFromJson(Map<String, dynamic> json) =>
    UserRacesResponse(
      races: (json['races'] as List<dynamic>?)
              ?.map(
                  (e) => RacingRaceDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserRacesResponseToJson(UserRacesResponse instance) =>
    <String, dynamic>{
      'races': instance.races.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

UserRaceCarDetails _$UserRaceCarDetailsFromJson(Map<String, dynamic> json) =>
    UserRaceCarDetails(
      id: (json['id'] as num).toInt(),
      name: json['name'],
      worth: (json['worth'] as num).toInt(),
      pointsSpent: (json['points_spent'] as num).toInt(),
      racesEntered: (json['races_entered'] as num).toInt(),
      racesWon: (json['races_won'] as num).toInt(),
      isRemoved: json['is_removed'] as bool,
      parts: (json['parts'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      carItemId: (json['car_item_id'] as num).toInt(),
      carItemName: json['car_item_name'] as String,
      topSpeed: (json['top_speed'] as num).toInt(),
      acceleration: (json['acceleration'] as num).toInt(),
      braking: (json['braking'] as num).toInt(),
      dirt: (json['dirt'] as num).toInt(),
      handling: (json['handling'] as num).toInt(),
      safety: (json['safety'] as num).toInt(),
      tarmac: (json['tarmac'] as num).toInt(),
      $class: raceClassEnumFromJson(json['class']),
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
      'class': raceClassEnumToJson(instance.$class),
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
      'enlistedcars': instance.enlistedcars.map((e) => e.toJson()).toList(),
    };

UserForumPostsResponse _$UserForumPostsResponseFromJson(
        Map<String, dynamic> json) =>
    UserForumPostsResponse(
      forumPosts: (json['forumPosts'] as List<dynamic>?)
              ?.map((e) => ForumPost.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserForumPostsResponseToJson(
        UserForumPostsResponse instance) =>
    <String, dynamic>{
      'forumPosts': instance.forumPosts.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

UserForumThreadsResponse _$UserForumThreadsResponseFromJson(
        Map<String, dynamic> json) =>
    UserForumThreadsResponse(
      forumThreads: (json['forumThreads'] as List<dynamic>?)
              ?.map((e) =>
                  ForumThreadUserExtended.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserForumThreadsResponseToJson(
        UserForumThreadsResponse instance) =>
    <String, dynamic>{
      'forumThreads': instance.forumThreads.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
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
      'forumFeed': instance.forumFeed.map((e) => e.toJson()).toList(),
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
      'forumFriends': instance.forumFriends.map((e) => e.toJson()).toList(),
    };

HofValue _$HofValueFromJson(Map<String, dynamic> json) => HofValue(
      $value: (json['value'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
    );

Map<String, dynamic> _$HofValueToJson(HofValue instance) => <String, dynamic>{
      'value': instance.$value,
      'rank': instance.rank,
    };

HofValueFloat _$HofValueFloatFromJson(Map<String, dynamic> json) =>
    HofValueFloat(
      $value: (json['value'] as num).toDouble(),
      rank: (json['rank'] as num).toInt(),
    );

Map<String, dynamic> _$HofValueFloatToJson(HofValueFloat instance) =>
    <String, dynamic>{
      'value': instance.$value,
      'rank': instance.rank,
    };

HofValueString _$HofValueStringFromJson(Map<String, dynamic> json) =>
    HofValueString(
      $value: json['value'] as String,
      rank: json['rank'],
    );

Map<String, dynamic> _$HofValueStringToJson(HofValueString instance) =>
    <String, dynamic>{
      'value': instance.$value,
      'rank': instance.rank,
    };

UserHofStats _$UserHofStatsFromJson(Map<String, dynamic> json) => UserHofStats(
      attacks: HofValue.fromJson(json['attacks'] as Map<String, dynamic>),
      busts: HofValue.fromJson(json['busts'] as Map<String, dynamic>),
      defends: HofValue.fromJson(json['defends'] as Map<String, dynamic>),
      networth: HofValue.fromJson(json['networth'] as Map<String, dynamic>),
      offences: HofValue.fromJson(json['offences'] as Map<String, dynamic>),
      revives: HofValue.fromJson(json['revives'] as Map<String, dynamic>),
      level: HofValue.fromJson(json['level'] as Map<String, dynamic>),
      rank: HofValue.fromJson(json['rank'] as Map<String, dynamic>),
      awards: HofValue.fromJson(json['awards'] as Map<String, dynamic>),
      racingSkill:
          HofValueFloat.fromJson(json['racing_skill'] as Map<String, dynamic>),
      racingPoints:
          HofValue.fromJson(json['racing_points'] as Map<String, dynamic>),
      racingWins:
          HofValue.fromJson(json['racing_wins'] as Map<String, dynamic>),
      travelTime:
          HofValue.fromJson(json['travel_time'] as Map<String, dynamic>),
      workingStats:
          HofValue.fromJson(json['working_stats'] as Map<String, dynamic>),
      battleStats: json['battle_stats'],
    );

Map<String, dynamic> _$UserHofStatsToJson(UserHofStats instance) =>
    <String, dynamic>{
      'attacks': instance.attacks.toJson(),
      'busts': instance.busts.toJson(),
      'defends': instance.defends.toJson(),
      'networth': instance.networth.toJson(),
      'offences': instance.offences.toJson(),
      'revives': instance.revives.toJson(),
      'level': instance.level.toJson(),
      'rank': instance.rank.toJson(),
      'awards': instance.awards.toJson(),
      'racing_skill': instance.racingSkill.toJson(),
      'racing_points': instance.racingPoints.toJson(),
      'racing_wins': instance.racingWins.toJson(),
      'travel_time': instance.travelTime.toJson(),
      'working_stats': instance.workingStats.toJson(),
      'battle_stats': instance.battleStats,
    };

UserHofResponse _$UserHofResponseFromJson(Map<String, dynamic> json) =>
    UserHofResponse(
      hof: UserHofStats.fromJson(json['hof'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserHofResponseToJson(UserHofResponse instance) =>
    <String, dynamic>{
      'hof': instance.hof.toJson(),
    };

UserCalendar _$UserCalendarFromJson(Map<String, dynamic> json) => UserCalendar(
      startTime: json['start_time'] as String,
    );

Map<String, dynamic> _$UserCalendarToJson(UserCalendar instance) =>
    <String, dynamic>{
      'start_time': instance.startTime,
    };

UserCalendarResponse _$UserCalendarResponseFromJson(
        Map<String, dynamic> json) =>
    UserCalendarResponse(
      calendar: UserCalendar.fromJson(json['calendar'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCalendarResponseToJson(
        UserCalendarResponse instance) =>
    <String, dynamic>{
      'calendar': instance.calendar.toJson(),
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
      'bounties': instance.bounties.map((e) => e.toJson()).toList(),
    };

UserJobRanks _$UserJobRanksFromJson(Map<String, dynamic> json) => UserJobRanks(
      army: jobPositionArmyEnumFromJson(json['army']),
      grocer: jobPositionGrocerEnumFromJson(json['grocer']),
      casino: jobPositionCasinoEnumFromJson(json['casino']),
      medical: jobPositionMedicalEnumFromJson(json['medical']),
      law: jobPositionLawEnumFromJson(json['law']),
      education: jobPositionEducationEnumFromJson(json['education']),
    );

Map<String, dynamic> _$UserJobRanksToJson(UserJobRanks instance) =>
    <String, dynamic>{
      'army': jobPositionArmyEnumToJson(instance.army),
      'grocer': jobPositionGrocerEnumToJson(instance.grocer),
      'casino': jobPositionCasinoEnumToJson(instance.casino),
      'medical': jobPositionMedicalEnumToJson(instance.medical),
      'law': jobPositionLawEnumToJson(instance.law),
      'education': jobPositionEducationEnumToJson(instance.education),
    };

UserJobRanksResponse _$UserJobRanksResponseFromJson(
        Map<String, dynamic> json) =>
    UserJobRanksResponse(
      jobranks: UserJobRanks.fromJson(json['jobranks'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserJobRanksResponseToJson(
        UserJobRanksResponse instance) =>
    <String, dynamic>{
      'jobranks': instance.jobranks.toJson(),
    };

UserItemMarkeListingItemDetails _$UserItemMarkeListingItemDetailsFromJson(
        Map<String, dynamic> json) =>
    UserItemMarkeListingItemDetails(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      rarity: json['rarity'],
      uid: json['uid'],
      stats: json['stats'],
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
      'rarity': instance.rarity,
      'uid': instance.uid,
      'stats': instance.stats,
      'bonuses': instance.bonuses.map((e) => e.toJson()).toList(),
    };

UserItemMarketListing _$UserItemMarketListingFromJson(
        Map<String, dynamic> json) =>
    UserItemMarketListing(
      id: (json['id'] as num).toInt(),
      price: (json['price'] as num).toInt(),
      averagePrice: (json['average_price'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
      isAnonymous: json['is_anonymous'] as bool,
      available: (json['available'] as num).toInt(),
      item: UserItemMarkeListingItemDetails.fromJson(
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
      'item': instance.item.toJson(),
    };

UserItemMarketResponse _$UserItemMarketResponseFromJson(
        Map<String, dynamic> json) =>
    UserItemMarketResponse(
      itemmarket: (json['itemmarket'] as List<dynamic>?)
              ?.map((e) =>
                  UserItemMarketListing.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserItemMarketResponseToJson(
        UserItemMarketResponse instance) =>
    <String, dynamic>{
      'itemmarket': instance.itemmarket.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

UserFactionBalance _$UserFactionBalanceFromJson(Map<String, dynamic> json) =>
    UserFactionBalance(
      money: (json['money'] as num).toInt(),
      points: (json['points'] as num).toInt(),
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

UserList _$UserListFromJson(Map<String, dynamic> json) => UserList(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      level: (json['level'] as num).toInt(),
      factionId: json['faction_id'],
      lastAction:
          UserLastAction.fromJson(json['last_action'] as Map<String, dynamic>),
      status: UserStatus.fromJson(json['status'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserListToJson(UserList instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'level': instance.level,
      'faction_id': instance.factionId,
      'last_action': instance.lastAction.toJson(),
      'status': instance.status.toJson(),
    };

UserListResponse _$UserListResponseFromJson(Map<String, dynamic> json) =>
    UserListResponse(
      list: (json['list'] as List<dynamic>?)
              ?.map((e) => UserList.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserListResponseToJson(UserListResponse instance) =>
    <String, dynamic>{
      'list': instance.list.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

UserSelectionName _$UserSelectionNameFromJson(Map<String, dynamic> json) =>
    UserSelectionName();

Map<String, dynamic> _$UserSelectionNameToJson(UserSelectionName instance) =>
    <String, dynamic>{};

UserLookupResponse _$UserLookupResponseFromJson(Map<String, dynamic> json) =>
    UserLookupResponse(
      selections: (json['selections'] as List<dynamic>?)
              ?.map(
                  (e) => UserSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserLookupResponseToJson(UserLookupResponse instance) =>
    <String, dynamic>{
      'selections': instance.selections.map((e) => e.toJson()).toList(),
    };

PersonalStatsOther _$PersonalStatsOtherFromJson(Map<String, dynamic> json) =>
    PersonalStatsOther(
      other: PersonalStatsOther$Other.fromJson(
          json['other'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsOtherToJson(PersonalStatsOther instance) =>
    <String, dynamic>{
      'other': instance.other.toJson(),
    };

PersonalStatsOtherPopular _$PersonalStatsOtherPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOtherPopular(
      other: PersonalStatsOtherPopular$Other.fromJson(
          json['other'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsOtherPopularToJson(
        PersonalStatsOtherPopular instance) =>
    <String, dynamic>{
      'other': instance.other.toJson(),
    };

PersonalStatsNetworthExtended _$PersonalStatsNetworthExtendedFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsNetworthExtended(
      networth: PersonalStatsNetworthExtended$Networth.fromJson(
          json['networth'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsNetworthExtendedToJson(
        PersonalStatsNetworthExtended instance) =>
    <String, dynamic>{
      'networth': instance.networth.toJson(),
    };

PersonalStatsNetworthPublic _$PersonalStatsNetworthPublicFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsNetworthPublic(
      networth: PersonalStatsNetworthPublic$Networth.fromJson(
          json['networth'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsNetworthPublicToJson(
        PersonalStatsNetworthPublic instance) =>
    <String, dynamic>{
      'networth': instance.networth.toJson(),
    };

PersonalStatsRacing _$PersonalStatsRacingFromJson(Map<String, dynamic> json) =>
    PersonalStatsRacing(
      racing: PersonalStatsRacing$Racing.fromJson(
          json['racing'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsRacingToJson(
        PersonalStatsRacing instance) =>
    <String, dynamic>{
      'racing': instance.racing.toJson(),
    };

PersonalStatsMissions _$PersonalStatsMissionsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsMissions(
      missions: PersonalStatsMissions$Missions.fromJson(
          json['missions'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsMissionsToJson(
        PersonalStatsMissions instance) =>
    <String, dynamic>{
      'missions': instance.missions.toJson(),
    };

PersonalStatsDrugs _$PersonalStatsDrugsFromJson(Map<String, dynamic> json) =>
    PersonalStatsDrugs(
      drugs: PersonalStatsDrugs$Drugs.fromJson(
          json['drugs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsDrugsToJson(PersonalStatsDrugs instance) =>
    <String, dynamic>{
      'drugs': instance.drugs.toJson(),
    };

PersonalStatsTravel _$PersonalStatsTravelFromJson(Map<String, dynamic> json) =>
    PersonalStatsTravel(
      travel: PersonalStatsTravel$Travel.fromJson(
          json['travel'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsTravelToJson(
        PersonalStatsTravel instance) =>
    <String, dynamic>{
      'travel': instance.travel.toJson(),
    };

PersonalStatsTravelPopular _$PersonalStatsTravelPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTravelPopular(
      travel: PersonalStatsTravelPopular$Travel.fromJson(
          json['travel'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsTravelPopularToJson(
        PersonalStatsTravelPopular instance) =>
    <String, dynamic>{
      'travel': instance.travel.toJson(),
    };

PersonalStatsItems _$PersonalStatsItemsFromJson(Map<String, dynamic> json) =>
    PersonalStatsItems(
      items: PersonalStatsItems$Items.fromJson(
          json['items'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsItemsToJson(PersonalStatsItems instance) =>
    <String, dynamic>{
      'items': instance.items.toJson(),
    };

PersonalStatsItemsPopular _$PersonalStatsItemsPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsItemsPopular(
      items: PersonalStatsItemsPopular$Items.fromJson(
          json['items'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsItemsPopularToJson(
        PersonalStatsItemsPopular instance) =>
    <String, dynamic>{
      'items': instance.items.toJson(),
    };

PersonalStatsInvestments _$PersonalStatsInvestmentsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsInvestments(
      investments: PersonalStatsInvestments$Investments.fromJson(
          json['investments'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsInvestmentsToJson(
        PersonalStatsInvestments instance) =>
    <String, dynamic>{
      'investments': instance.investments.toJson(),
    };

PersonalStatsBounties _$PersonalStatsBountiesFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsBounties(
      bounties: PersonalStatsBounties$Bounties.fromJson(
          json['bounties'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsBountiesToJson(
        PersonalStatsBounties instance) =>
    <String, dynamic>{
      'bounties': instance.bounties.toJson(),
    };

PersonalStatsCrimesV2 _$PersonalStatsCrimesV2FromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCrimesV2(
      offenses: PersonalStatsCrimesV2$Offenses.fromJson(
          json['offenses'] as Map<String, dynamic>),
      skills: PersonalStatsCrimesV2$Skills.fromJson(
          json['skills'] as Map<String, dynamic>),
      version: json['version'] as String,
    );

Map<String, dynamic> _$PersonalStatsCrimesV2ToJson(
        PersonalStatsCrimesV2 instance) =>
    <String, dynamic>{
      'offenses': instance.offenses.toJson(),
      'skills': instance.skills.toJson(),
      'version': instance.version,
    };

PersonalStatsCrimesV1 _$PersonalStatsCrimesV1FromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCrimesV1(
      total: (json['total'] as num).toInt(),
      sellIllegalGoods: (json['sell_illegal_goods'] as num).toInt(),
      theft: (json['theft'] as num).toInt(),
      autoTheft: (json['auto_theft'] as num).toInt(),
      drugDeals: (json['drug_deals'] as num).toInt(),
      computer: (json['computer'] as num).toInt(),
      fraud: (json['fraud'] as num).toInt(),
      murder: (json['murder'] as num).toInt(),
      other: (json['other'] as num).toInt(),
      organizedCrimes: (json['organized_crimes'] as num).toInt(),
      version: json['version'] as String,
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
      crimes: PersonalStatsCrimesPopular$Crimes.fromJson(
          json['crimes'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsCrimesPopularToJson(
        PersonalStatsCrimesPopular instance) =>
    <String, dynamic>{
      'crimes': instance.crimes.toJson(),
    };

PersonalStatsCommunication _$PersonalStatsCommunicationFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCommunication(
      communication: PersonalStatsCommunication$Communication.fromJson(
          json['communication'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsCommunicationToJson(
        PersonalStatsCommunication instance) =>
    <String, dynamic>{
      'communication': instance.communication.toJson(),
    };

PersonalStatsFinishingHits _$PersonalStatsFinishingHitsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsFinishingHits(
      finishingHits: PersonalStatsFinishingHits$FinishingHits.fromJson(
          json['finishing_hits'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsFinishingHitsToJson(
        PersonalStatsFinishingHits instance) =>
    <String, dynamic>{
      'finishing_hits': instance.finishingHits.toJson(),
    };

PersonalStatsHospital _$PersonalStatsHospitalFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsHospital(
      hospital: PersonalStatsHospital$Hospital.fromJson(
          json['hospital'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsHospitalToJson(
        PersonalStatsHospital instance) =>
    <String, dynamic>{
      'hospital': instance.hospital.toJson(),
    };

PersonalStatsHospitalPopular _$PersonalStatsHospitalPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsHospitalPopular(
      hospital: PersonalStatsHospitalPopular$Hospital.fromJson(
          json['hospital'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsHospitalPopularToJson(
        PersonalStatsHospitalPopular instance) =>
    <String, dynamic>{
      'hospital': instance.hospital.toJson(),
    };

PersonalStatsJail _$PersonalStatsJailFromJson(Map<String, dynamic> json) =>
    PersonalStatsJail(
      jail:
          PersonalStatsJail$Jail.fromJson(json['jail'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJailToJson(PersonalStatsJail instance) =>
    <String, dynamic>{
      'jail': instance.jail.toJson(),
    };

PersonalStatsTrading _$PersonalStatsTradingFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTrading(
      trading: PersonalStatsTrading$Trading.fromJson(
          json['trading'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsTradingToJson(
        PersonalStatsTrading instance) =>
    <String, dynamic>{
      'trading': instance.trading.toJson(),
    };

PersonalStatsJobsPublic _$PersonalStatsJobsPublicFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJobsPublic(
      jobs: PersonalStatsJobsPublic$Jobs.fromJson(
          json['jobs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJobsPublicToJson(
        PersonalStatsJobsPublic instance) =>
    <String, dynamic>{
      'jobs': instance.jobs.toJson(),
    };

PersonalStatsJobsExtended _$PersonalStatsJobsExtendedFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJobsExtended(
      jobs: PersonalStatsJobsExtended$Jobs.fromJson(
          json['jobs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJobsExtendedToJson(
        PersonalStatsJobsExtended instance) =>
    <String, dynamic>{
      'jobs': instance.jobs.toJson(),
    };

PersonalStatsBattleStats _$PersonalStatsBattleStatsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsBattleStats(
      battleStats: PersonalStatsBattleStats$BattleStats.fromJson(
          json['battle_stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsBattleStatsToJson(
        PersonalStatsBattleStats instance) =>
    <String, dynamic>{
      'battle_stats': instance.battleStats.toJson(),
    };

PersonalStatsAttackingPublic _$PersonalStatsAttackingPublicFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsAttackingPublic(
      attacking: PersonalStatsAttackingPublic$Attacking.fromJson(
          json['attacking'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsAttackingPublicToJson(
        PersonalStatsAttackingPublic instance) =>
    <String, dynamic>{
      'attacking': instance.attacking.toJson(),
    };

PersonalStatsAttackingExtended _$PersonalStatsAttackingExtendedFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsAttackingExtended(
      attacking: PersonalStatsAttackingExtended$Attacking.fromJson(
          json['attacking'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsAttackingExtendedToJson(
        PersonalStatsAttackingExtended instance) =>
    <String, dynamic>{
      'attacking': instance.attacking.toJson(),
    };

PersonalStatsAttackingPopular _$PersonalStatsAttackingPopularFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsAttackingPopular(
      attacking: PersonalStatsAttackingPopular$Attacking.fromJson(
          json['attacking'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsAttackingPopularToJson(
        PersonalStatsAttackingPopular instance) =>
    <String, dynamic>{
      'attacking': instance.attacking.toJson(),
    };

PersonalStatsHistoricStat _$PersonalStatsHistoricStatFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsHistoricStat(
      name: json['name'] as String,
      $value: (json['value'] as num).toInt(),
      timestamp: (json['timestamp'] as num).toInt(),
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
      'personalstats': instance.personalstats.map((e) => e.toJson()).toList(),
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

FactionRaidReport _$FactionRaidReportFromJson(Map<String, dynamic> json) =>
    FactionRaidReport(
      id: (json['id'] as num).toInt(),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      aggressor: FactionRaidReportFaction.fromJson(
          json['aggressor'] as Map<String, dynamic>),
      defender: FactionRaidReportFaction.fromJson(
          json['defender'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionRaidReportToJson(FactionRaidReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start': instance.start,
      'end': instance.end,
      'aggressor': instance.aggressor.toJson(),
      'defender': instance.defender.toJson(),
    };

FactionRaidReportFaction _$FactionRaidReportFactionFromJson(
        Map<String, dynamic> json) =>
    FactionRaidReportFaction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num).toDouble(),
      attackers: (json['attackers'] as List<dynamic>?)
              ?.map((e) =>
                  FactionRaidReportAttacker.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nonAttackers: (json['non_attackers'] as List<dynamic>?)
              ?.map((e) =>
                  FactionRaidReportUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionRaidReportFactionToJson(
        FactionRaidReportFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'attackers': instance.attackers.map((e) => e.toJson()).toList(),
      'non_attackers': instance.nonAttackers.map((e) => e.toJson()).toList(),
    };

FactionRaidReportAttacker _$FactionRaidReportAttackerFromJson(
        Map<String, dynamic> json) =>
    FactionRaidReportAttacker(
      user:
          FactionRaidReportUser.fromJson(json['user'] as Map<String, dynamic>),
      attacks: (json['attacks'] as num).toInt(),
      damage: (json['damage'] as num).toDouble(),
    );

Map<String, dynamic> _$FactionRaidReportAttackerToJson(
        FactionRaidReportAttacker instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'attacks': instance.attacks,
      'damage': instance.damage,
    };

FactionRaidReportUser _$FactionRaidReportUserFromJson(
        Map<String, dynamic> json) =>
    FactionRaidReportUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$FactionRaidReportUserToJson(
        FactionRaidReportUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

FactionRaidWarReportResponse _$FactionRaidWarReportResponseFromJson(
        Map<String, dynamic> json) =>
    FactionRaidWarReportResponse(
      raidreport: (json['raidreport'] as List<dynamic>?)
              ?.map(
                  (e) => FactionRaidReport.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionRaidWarReportResponseToJson(
        FactionRaidWarReportResponse instance) =>
    <String, dynamic>{
      'raidreport': instance.raidreport.map((e) => e.toJson()).toList(),
    };

FactionWarfareDirtyBomb _$FactionWarfareDirtyBombFromJson(
        Map<String, dynamic> json) =>
    FactionWarfareDirtyBomb(
      id: (json['id'] as num).toInt(),
      plantedAt: (json['planted_at'] as num).toInt(),
      detonatedAt: (json['detonated_at'] as num).toInt(),
      faction: FactionWarfareDirtyBombTargetFaction.fromJson(
          json['faction'] as Map<String, dynamic>),
      user: json['user'],
    );

Map<String, dynamic> _$FactionWarfareDirtyBombToJson(
        FactionWarfareDirtyBomb instance) =>
    <String, dynamic>{
      'id': instance.id,
      'planted_at': instance.plantedAt,
      'detonated_at': instance.detonatedAt,
      'faction': instance.faction.toJson(),
      'user': instance.user,
    };

FactionWarfareDirtyBombTargetFaction
    _$FactionWarfareDirtyBombTargetFactionFromJson(Map<String, dynamic> json) =>
        FactionWarfareDirtyBombTargetFaction(
          id: (json['id'] as num).toInt(),
          name: json['name'] as String,
          respectLost: (json['respect_lost'] as num).toInt(),
        );

Map<String, dynamic> _$FactionWarfareDirtyBombTargetFactionToJson(
        FactionWarfareDirtyBombTargetFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'respect_lost': instance.respectLost,
    };

FactionWarfareDirtyBombPlanter _$FactionWarfareDirtyBombPlanterFromJson(
        Map<String, dynamic> json) =>
    FactionWarfareDirtyBombPlanter(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$FactionWarfareDirtyBombPlanterToJson(
        FactionWarfareDirtyBombPlanter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

FactionRaidWarfare _$FactionRaidWarfareFromJson(Map<String, dynamic> json) =>
    FactionRaidWarfare(
      id: (json['id'] as num).toInt(),
      start: (json['start'] as num).toInt(),
      end: json['end'],
      aggressor: FactionRaidWarfareFaction.fromJson(
          json['aggressor'] as Map<String, dynamic>),
      defender: FactionRaidWarfareFaction.fromJson(
          json['defender'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionRaidWarfareToJson(FactionRaidWarfare instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start': instance.start,
      'end': instance.end,
      'aggressor': instance.aggressor.toJson(),
      'defender': instance.defender.toJson(),
    };

FactionRaidWarfareFaction _$FactionRaidWarfareFactionFromJson(
        Map<String, dynamic> json) =>
    FactionRaidWarfareFaction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num).toDouble(),
      chain: (json['chain'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionRaidWarfareFactionToJson(
        FactionRaidWarfareFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'chain': instance.chain,
    };

FactionTerritoryWarfare _$FactionTerritoryWarfareFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarfare(
      id: (json['id'] as num).toInt(),
      territory: factionTerritoryEnumFromJson(json['territory']),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      target: (json['target'] as num).toInt(),
      aggressor: FactionTerritoryWarFaction.fromJson(
          json['aggressor'] as Map<String, dynamic>),
      defender: FactionTerritoryWarFaction.fromJson(
          json['defender'] as Map<String, dynamic>),
      result: json['result'] as String,
    );

Map<String, dynamic> _$FactionTerritoryWarfareToJson(
        FactionTerritoryWarfare instance) =>
    <String, dynamic>{
      'id': instance.id,
      'territory': factionTerritoryEnumToJson(instance.territory),
      'start': instance.start,
      'end': instance.end,
      'target': instance.target,
      'aggressor': instance.aggressor.toJson(),
      'defender': instance.defender.toJson(),
      'result': instance.result,
    };

FactionTerritoryWarFactionWallPlayers
    _$FactionTerritoryWarFactionWallPlayersFromJson(
            Map<String, dynamic> json) =>
        FactionTerritoryWarFactionWallPlayers(
          id: (json['id'] as num).toInt(),
          name: json['name'] as String,
        );

Map<String, dynamic> _$FactionTerritoryWarFactionWallPlayersToJson(
        FactionTerritoryWarFactionWallPlayers instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

FactionTerritoryWarFaction _$FactionTerritoryWarFactionFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarFaction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num).toInt(),
      chain: (json['chain'] as num?)?.toInt(),
      playersOnWall: (json['players_on_wall'] as List<dynamic>?)
              ?.map((e) => FactionTerritoryWarFactionWallPlayers.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoryWarFactionToJson(
        FactionTerritoryWarFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'chain': instance.chain,
      'players_on_wall':
          instance.playersOnWall?.map((e) => e.toJson()).toList(),
    };

FactionTerritoryWarFinishedFaction _$FactionTerritoryWarFinishedFactionFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarFinishedFaction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num).toInt(),
      isAggressor: json['is_aggressor'] as bool,
    );

Map<String, dynamic> _$FactionTerritoryWarFinishedFactionToJson(
        FactionTerritoryWarFinishedFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'is_aggressor': instance.isAggressor,
    };

FactionSearchLeader _$FactionSearchLeaderFromJson(Map<String, dynamic> json) =>
    FactionSearchLeader(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$FactionSearchLeaderToJson(
        FactionSearchLeader instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

FactionSearch _$FactionSearchFromJson(Map<String, dynamic> json) =>
    FactionSearch(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      respect: (json['respect'] as num).toInt(),
      members: (json['members'] as num).toInt(),
      leader:
          FactionSearchLeader.fromJson(json['leader'] as Map<String, dynamic>),
      coLeader: json['co_leader'],
      image: json['image'],
      tagImage: json['tag_image'],
      tag: json['tag'],
      isDestroyed: json['is_destroyed'] as bool,
      isRecruiting: json['is_recruiting'] as bool,
    );

Map<String, dynamic> _$FactionSearchToJson(FactionSearch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'respect': instance.respect,
      'members': instance.members,
      'leader': instance.leader.toJson(),
      'co_leader': instance.coLeader,
      'image': instance.image,
      'tag_image': instance.tagImage,
      'tag': instance.tag,
      'is_destroyed': instance.isDestroyed,
      'is_recruiting': instance.isRecruiting,
    };

FactionSearchResponse _$FactionSearchResponseFromJson(
        Map<String, dynamic> json) =>
    FactionSearchResponse(
      search: (json['search'] as List<dynamic>?)
              ?.map((e) => FactionSearch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionSearchResponseToJson(
        FactionSearchResponse instance) =>
    <String, dynamic>{
      'search': instance.search.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

FactionTerritoryWarFinished _$FactionTerritoryWarFinishedFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarFinished(
      id: (json['id'] as num).toInt(),
      territory: factionTerritoryEnumFromJson(json['territory']),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      target: (json['target'] as num).toInt(),
      result: factionTerritoryWarResultEnumFromJson(json['result']),
      factions: (json['factions'] as List<dynamic>?)
              ?.map((e) => FactionTerritoryWarFinishedFaction.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoryWarFinishedToJson(
        FactionTerritoryWarFinished instance) =>
    <String, dynamic>{
      'id': instance.id,
      'territory': factionTerritoryEnumToJson(instance.territory),
      'start': instance.start,
      'end': instance.end,
      'target': instance.target,
      'result': factionTerritoryWarResultEnumToJson(instance.result),
      'factions': instance.factions.map((e) => e.toJson()).toList(),
    };

FactionTerritoryWarOngoingFaction _$FactionTerritoryWarOngoingFactionFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarOngoingFaction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num).toInt(),
      isAggressor: json['is_aggressor'] as bool,
      chain: (json['chain'] as num).toInt(),
      playerIds: (json['playerIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoryWarOngoingFactionToJson(
        FactionTerritoryWarOngoingFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'is_aggressor': instance.isAggressor,
      'chain': instance.chain,
      'playerIds': instance.playerIds,
    };

FactionTerritoryWarOngoing _$FactionTerritoryWarOngoingFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarOngoing(
      id: (json['id'] as num).toInt(),
      territory: factionTerritoryEnumFromJson(json['territory']),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      target: (json['target'] as num).toInt(),
      factions: (json['factions'] as List<dynamic>?)
              ?.map((e) => FactionTerritoryWarOngoingFaction.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoryWarOngoingToJson(
        FactionTerritoryWarOngoing instance) =>
    <String, dynamic>{
      'id': instance.id,
      'territory': factionTerritoryEnumToJson(instance.territory),
      'start': instance.start,
      'end': instance.end,
      'target': instance.target,
      'factions': instance.factions.map((e) => e.toJson()).toList(),
    };

FactionTerritoryWarsResponse _$FactionTerritoryWarsResponseFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarsResponse(
      territorywars: json['territorywars'],
    );

Map<String, dynamic> _$FactionTerritoryWarsResponseToJson(
        FactionTerritoryWarsResponse instance) =>
    <String, dynamic>{
      'territorywars': instance.territorywars,
    };

FactionTerritoryWarsHistoryResponse
    _$FactionTerritoryWarsHistoryResponseFromJson(Map<String, dynamic> json) =>
        FactionTerritoryWarsHistoryResponse(
          territorywars: (json['territorywars'] as List<dynamic>?)
                  ?.map((e) => FactionTerritoryWarFinished.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
        );

Map<String, dynamic> _$FactionTerritoryWarsHistoryResponseToJson(
        FactionTerritoryWarsHistoryResponse instance) =>
    <String, dynamic>{
      'territorywars': instance.territorywars.map((e) => e.toJson()).toList(),
    };

FactionTerritoryWarReportMembers _$FactionTerritoryWarReportMembersFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarReportMembers(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      level: (json['level'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      joins: (json['joins'] as num).toInt(),
      clears: (json['clears'] as num).toInt(),
    );

Map<String, dynamic> _$FactionTerritoryWarReportMembersToJson(
        FactionTerritoryWarReportMembers instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'level': instance.level,
      'score': instance.score,
      'joins': instance.joins,
      'clears': instance.clears,
    };

FactionTerritoryWarReportFaction _$FactionTerritoryWarReportFactionFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarReportFaction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num).toInt(),
      joins: (json['joins'] as num).toInt(),
      clears: (json['clears'] as num).toInt(),
      isAggressor: json['is_aggressor'] as bool,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => FactionTerritoryWarReportMembers.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoryWarReportFactionToJson(
        FactionTerritoryWarReportFaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'joins': instance.joins,
      'clears': instance.clears,
      'is_aggressor': instance.isAggressor,
      'members': instance.members.map((e) => e.toJson()).toList(),
    };

FactionTerritoryWarReport _$FactionTerritoryWarReportFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarReport(
      id: (json['id'] as num).toInt(),
      territory: factionTerritoryEnumFromJson(json['territory']),
      startedAt: (json['started_at'] as num).toInt(),
      endedAt: (json['ended_at'] as num).toInt(),
      winner: (json['winner'] as num).toInt(),
      result: json['result'] as String,
      factions: (json['factions'] as List<dynamic>?)
              ?.map((e) => FactionTerritoryWarReportFaction.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoryWarReportToJson(
        FactionTerritoryWarReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'territory': factionTerritoryEnumToJson(instance.territory),
      'started_at': instance.startedAt,
      'ended_at': instance.endedAt,
      'winner': instance.winner,
      'result': instance.result,
      'factions': instance.factions.map((e) => e.toJson()).toList(),
    };

FactionTerritoryWarReportResponse _$FactionTerritoryWarReportResponseFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarReportResponse(
      territorywarreport: (json['territorywarreport'] as List<dynamic>?)
              ?.map((e) =>
                  FactionTerritoryWarReport.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoryWarReportResponseToJson(
        FactionTerritoryWarReportResponse instance) =>
    <String, dynamic>{
      'territorywarreport':
          instance.territorywarreport.map((e) => e.toJson()).toList(),
    };

FactionTerritoryOwnership _$FactionTerritoryOwnershipFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryOwnership(
      id: json['id'] as String,
      ownedBy: json['owned_by'],
      acquiredAt: json['acquired_at'],
    );

Map<String, dynamic> _$FactionTerritoryOwnershipToJson(
        FactionTerritoryOwnership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owned_by': instance.ownedBy,
      'acquired_at': instance.acquiredAt,
    };

FactionTerritoriesOwnershipResponse
    _$FactionTerritoriesOwnershipResponseFromJson(Map<String, dynamic> json) =>
        FactionTerritoriesOwnershipResponse(
          territoryOwnership: (json['territoryOwnership'] as List<dynamic>?)
                  ?.map((e) => FactionTerritoryOwnership.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
        );

Map<String, dynamic> _$FactionTerritoriesOwnershipResponseToJson(
        FactionTerritoriesOwnershipResponse instance) =>
    <String, dynamic>{
      'territoryOwnership':
          instance.territoryOwnership.map((e) => e.toJson()).toList(),
    };

TornRacketReward _$TornRacketRewardFromJson(Map<String, dynamic> json) =>
    TornRacketReward(
      type: tornRacketTypeFromJson(json['type']),
      quantity: (json['quantity'] as num).toInt(),
      id: json['id'],
    );

Map<String, dynamic> _$TornRacketRewardToJson(TornRacketReward instance) =>
    <String, dynamic>{
      'type': tornRacketTypeToJson(instance.type),
      'quantity': instance.quantity,
      'id': instance.id,
    };

TornRacket _$TornRacketFromJson(Map<String, dynamic> json) => TornRacket(
      name: json['name'] as String,
      level: (json['level'] as num).toInt(),
      description: json['description'] as String,
      reward: TornRacketReward.fromJson(json['reward'] as Map<String, dynamic>),
      createdAt: (json['created_at'] as num).toInt(),
      changedAt: (json['changed_at'] as num).toInt(),
    );

Map<String, dynamic> _$TornRacketToJson(TornRacket instance) =>
    <String, dynamic>{
      'name': instance.name,
      'level': instance.level,
      'description': instance.description,
      'reward': instance.reward.toJson(),
      'created_at': instance.createdAt,
      'changed_at': instance.changedAt,
    };

FactionRacketsResponse _$FactionRacketsResponseFromJson(
        Map<String, dynamic> json) =>
    FactionRacketsResponse(
      rackets: (json['rackets'] as List<dynamic>?)
              ?.map((e) => TornRacket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionRacketsResponseToJson(
        FactionRacketsResponse instance) =>
    <String, dynamic>{
      'rackets': instance.rackets.map((e) => e.toJson()).toList(),
    };

FactionTerritory _$FactionTerritoryFromJson(Map<String, dynamic> json) =>
    FactionTerritory(
      id: factionTerritoryEnumFromJson(json['id']),
      acquiredAt: (json['acquired_at'] as num).toInt(),
      sector: (json['sector'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      density: (json['density'] as num).toInt(),
      slots: (json['slots'] as num).toInt(),
      respect: (json['respect'] as num).toInt(),
      coordinates: TornTerritoryCoordinates.fromJson(
          json['coordinates'] as Map<String, dynamic>),
      racket: json['racket'],
    );

Map<String, dynamic> _$FactionTerritoryToJson(FactionTerritory instance) =>
    <String, dynamic>{
      'id': factionTerritoryEnumToJson(instance.id),
      'acquired_at': instance.acquiredAt,
      'sector': instance.sector,
      'size': instance.size,
      'density': instance.density,
      'slots': instance.slots,
      'respect': instance.respect,
      'coordinates': instance.coordinates.toJson(),
      'racket': instance.racket,
    };

FactionTerritoriesResponse _$FactionTerritoriesResponseFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoriesResponse(
      territory: (json['territory'] as List<dynamic>?)
              ?.map((e) => FactionTerritory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionTerritoriesResponseToJson(
        FactionTerritoriesResponse instance) =>
    <String, dynamic>{
      'territory': instance.territory.map((e) => e.toJson()).toList(),
    };

FactionPosition _$FactionPositionFromJson(Map<String, dynamic> json) =>
    FactionPosition(
      name: json['name'] as String,
      isDefault: json['is_default'] as bool,
      abilities:
          factionPositionAbilityEnumListFromJson(json['abilities'] as List?),
    );

Map<String, dynamic> _$FactionPositionToJson(FactionPosition instance) =>
    <String, dynamic>{
      'name': instance.name,
      'is_default': instance.isDefault,
      'abilities': factionPositionAbilityEnumListToJson(instance.abilities),
    };

FactionPositionsResponse _$FactionPositionsResponseFromJson(
        Map<String, dynamic> json) =>
    FactionPositionsResponse(
      positions: (json['positions'] as List<dynamic>?)
              ?.map((e) => FactionPosition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionPositionsResponseToJson(
        FactionPositionsResponse instance) =>
    <String, dynamic>{
      'positions': instance.positions.map((e) => e.toJson()).toList(),
    };

FactionUpgradeDetails _$FactionUpgradeDetailsFromJson(
        Map<String, dynamic> json) =>
    FactionUpgradeDetails(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      ability: json['ability'] as String,
      level: (json['level'] as num).toInt(),
      cost: (json['cost'] as num).toInt(),
      unlockedAt: (json['unlocked_at'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FactionUpgradeDetailsToJson(
        FactionUpgradeDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'ability': instance.ability,
      'level': instance.level,
      'cost': instance.cost,
      'unlocked_at': instance.unlockedAt,
    };

FactionBranchDetails _$FactionBranchDetailsFromJson(
        Map<String, dynamic> json) =>
    FactionBranchDetails(
      name: json['name'] as String,
      order: (json['order'] as num).toInt(),
      multiplier: (json['multiplier'] as num).toInt(),
      upgrades: (json['upgrades'] as List<dynamic>?)
              ?.map((e) =>
                  FactionUpgradeDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionBranchDetailsToJson(
        FactionBranchDetails instance) =>
    <String, dynamic>{
      'name': instance.name,
      'order': instance.order,
      'multiplier': instance.multiplier,
      'upgrades': instance.upgrades.map((e) => e.toJson()).toList(),
    };

FactionUpgrades _$FactionUpgradesFromJson(Map<String, dynamic> json) =>
    FactionUpgrades(
      core: FactionUpgrades$Core.fromJson(json['core'] as Map<String, dynamic>),
      peace: (json['peace'] as List<dynamic>?)
              ?.map((e) =>
                  FactionBranchDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      war: (json['war'] as List<dynamic>?)
              ?.map((e) =>
                  FactionBranchDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionUpgradesToJson(FactionUpgrades instance) =>
    <String, dynamic>{
      'core': instance.core.toJson(),
      'peace': instance.peace.map((e) => e.toJson()).toList(),
      'war': instance.war.map((e) => e.toJson()).toList(),
    };

FactionUpgradesResponse _$FactionUpgradesResponseFromJson(
        Map<String, dynamic> json) =>
    FactionUpgradesResponse(
      upgrades:
          FactionUpgrades.fromJson(json['upgrades'] as Map<String, dynamic>),
      state: factionBranchStateEnumFromJson(json['state']),
    );

Map<String, dynamic> _$FactionUpgradesResponseToJson(
        FactionUpgradesResponse instance) =>
    <String, dynamic>{
      'upgrades': instance.upgrades.toJson(),
      'state': factionBranchStateEnumToJson(instance.state),
    };

FactionStat _$FactionStatFromJson(Map<String, dynamic> json) => FactionStat(
      name: factionStatEnumFromJson(json['name']),
      $value: (json['value'] as num).toInt(),
    );

Map<String, dynamic> _$FactionStatToJson(FactionStat instance) =>
    <String, dynamic>{
      'name': factionStatEnumToJson(instance.name),
      'value': instance.$value,
    };

FactionStatsResponse _$FactionStatsResponseFromJson(
        Map<String, dynamic> json) =>
    FactionStatsResponse(
      stats: (json['stats'] as List<dynamic>?)
              ?.map((e) => FactionStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionStatsResponseToJson(
        FactionStatsResponse instance) =>
    <String, dynamic>{
      'stats': instance.stats.map((e) => e.toJson()).toList(),
    };

FactionContributor _$FactionContributorFromJson(Map<String, dynamic> json) =>
    FactionContributor(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      $value: (json['value'] as num).toInt(),
      inFaction: json['in_faction'] as bool,
    );

Map<String, dynamic> _$FactionContributorToJson(FactionContributor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'value': instance.$value,
      'in_faction': instance.inFaction,
    };

FactionContributorsResponse _$FactionContributorsResponseFromJson(
        Map<String, dynamic> json) =>
    FactionContributorsResponse(
      contributors: (json['contributors'] as List<dynamic>?)
              ?.map(
                  (e) => FactionContributor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionContributorsResponseToJson(
        FactionContributorsResponse instance) =>
    <String, dynamic>{
      'contributors': instance.contributors.map((e) => e.toJson()).toList(),
    };

FactionHofStats _$FactionHofStatsFromJson(Map<String, dynamic> json) =>
    FactionHofStats(
      rank: HofValueString.fromJson(json['rank'] as Map<String, dynamic>),
      respect: HofValue.fromJson(json['respect'] as Map<String, dynamic>),
      chain: HofValue.fromJson(json['chain'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionHofStatsToJson(FactionHofStats instance) =>
    <String, dynamic>{
      'rank': instance.rank.toJson(),
      'respect': instance.respect.toJson(),
      'chain': instance.chain.toJson(),
    };

FactionHofResponse _$FactionHofResponseFromJson(Map<String, dynamic> json) =>
    FactionHofResponse(
      hof: FactionHofStats.fromJson(json['hof'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionHofResponseToJson(FactionHofResponse instance) =>
    <String, dynamic>{
      'hof': instance.hof.toJson(),
    };

FactionMember _$FactionMemberFromJson(Map<String, dynamic> json) =>
    FactionMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      position: json['position'] as String,
      level: (json['level'] as num).toInt(),
      daysInFaction: (json['days_in_faction'] as num).toInt(),
      isRevivable: json['is_revivable'] as bool,
      isOnWall: json['is_on_wall'] as bool,
      isInOc: json['is_in_oc'] as bool,
      hasEarlyDischarge: json['has_early_discharge'] as bool,
      lastAction:
          UserLastAction.fromJson(json['last_action'] as Map<String, dynamic>),
      status: UserStatus.fromJson(json['status'] as Map<String, dynamic>),
      reviveSetting: reviveSettingFromJson(json['revive_setting']),
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
      'last_action': instance.lastAction.toJson(),
      'status': instance.status.toJson(),
      'revive_setting': reviveSettingToJson(instance.reviveSetting),
    };

UserLastAction _$UserLastActionFromJson(Map<String, dynamic> json) =>
    UserLastAction(
      status: json['status'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      relative: json['relative'] as String,
    );

Map<String, dynamic> _$UserLastActionToJson(UserLastAction instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp,
      'relative': instance.relative,
    };

UserStatus _$UserStatusFromJson(Map<String, dynamic> json) => UserStatus(
      description: json['description'] as String,
      details: json['details'],
      state: json['state'] as String,
      until: json['until'],
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
      'members': instance.members.map((e) => e.toJson()).toList(),
    };

FactionRank _$FactionRankFromJson(Map<String, dynamic> json) => FactionRank(
      level: (json['level'] as num).toInt(),
      name: json['name'] as String,
      division: (json['division'] as num).toInt(),
      position: (json['position'] as num).toInt(),
      wins: (json['wins'] as num).toInt(),
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
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      tag: json['tag'] as String,
      tagImage: json['tag_image'] as String,
      leaderId: (json['leader_id'] as num).toInt(),
      coLeaderId: (json['co_leader_id'] as num).toInt(),
      respect: (json['respect'] as num).toInt(),
      daysOld: (json['days_old'] as num).toInt(),
      capacity: (json['capacity'] as num).toInt(),
      members: (json['members'] as num).toInt(),
      isEnlisted: json['is_enlisted'],
      rank: FactionRank.fromJson(json['rank'] as Map<String, dynamic>),
      bestChain: (json['best_chain'] as num).toInt(),
    );

Map<String, dynamic> _$FactionBasicToJson(FactionBasic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tag': instance.tag,
      'tag_image': instance.tagImage,
      'leader_id': instance.leaderId,
      'co_leader_id': instance.coLeaderId,
      'respect': instance.respect,
      'days_old': instance.daysOld,
      'capacity': instance.capacity,
      'members': instance.members,
      'is_enlisted': instance.isEnlisted,
      'rank': instance.rank.toJson(),
      'best_chain': instance.bestChain,
    };

FactionBasicResponse _$FactionBasicResponseFromJson(
        Map<String, dynamic> json) =>
    FactionBasicResponse(
      basic: FactionBasic.fromJson(json['basic'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionBasicResponseToJson(
        FactionBasicResponse instance) =>
    <String, dynamic>{
      'basic': instance.basic.toJson(),
    };

FactionPact _$FactionPactFromJson(Map<String, dynamic> json) => FactionPact(
      factionId: (json['faction_id'] as num).toInt(),
      factionName: json['faction_name'] as String,
      until: json['until'] as String,
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
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num).toInt(),
      chain: (json['chain'] as num).toInt(),
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
      warId: (json['war_id'] as num).toInt(),
      start: (json['start'] as num).toInt(),
      end: json['end'],
      target: (json['target'] as num).toInt(),
      winner: json['winner'],
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
      'factions': instance.factions.map((e) => e.toJson()).toList(),
    };

FactionRaidWarParticipant _$FactionRaidWarParticipantFromJson(
        Map<String, dynamic> json) =>
    FactionRaidWarParticipant(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num).toInt(),
      chain: (json['chain'] as num).toInt(),
      isAggressor: json['is_aggressor'] as bool,
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
      warId: (json['war_id'] as num).toInt(),
      start: (json['start'] as num).toInt(),
      end: json['end'],
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
      'factions': instance.factions.map((e) => e.toJson()).toList(),
    };

FactionTerritoryWarParticipant _$FactionTerritoryWarParticipantFromJson(
        Map<String, dynamic> json) =>
    FactionTerritoryWarParticipant(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num).toInt(),
      chain: (json['chain'] as num).toInt(),
      isAggressor: json['is_aggressor'] as bool,
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
      warId: (json['war_id'] as num).toInt(),
      territory: json['territory'] as String,
      start: (json['start'] as num).toInt(),
      end: json['end'],
      target: (json['target'] as num).toInt(),
      winner: json['winner'],
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
      'factions': instance.factions.map((e) => e.toJson()).toList(),
    };

FactionWars _$FactionWarsFromJson(Map<String, dynamic> json) => FactionWars(
      ranked: json['ranked'],
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
      'ranked': instance.ranked,
      'raids': instance.raids.map((e) => e.toJson()).toList(),
      'territory': instance.territory.map((e) => e.toJson()).toList(),
    };

FactionWarsResponse _$FactionWarsResponseFromJson(Map<String, dynamic> json) =>
    FactionWarsResponse(
      pacts: (json['pacts'] as List<dynamic>?)
              ?.map((e) => FactionPact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      wars: FactionWars.fromJson(json['wars'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionWarsResponseToJson(
        FactionWarsResponse instance) =>
    <String, dynamic>{
      'pacts': instance.pacts.map((e) => e.toJson()).toList(),
      'wars': instance.wars.toJson(),
    };

FactionNews _$FactionNewsFromJson(Map<String, dynamic> json) => FactionNews(
      id: json['id'] as String,
      text: json['text'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
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
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionNewsResponseToJson(
        FactionNewsResponse instance) =>
    <String, dynamic>{
      'news': instance.news.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

FactionRaidsResponse _$FactionRaidsResponseFromJson(
        Map<String, dynamic> json) =>
    FactionRaidsResponse(
      raids: (json['raids'] as List<dynamic>?)
              ?.map(
                  (e) => FactionRaidWarfare.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionRaidsResponseToJson(
        FactionRaidsResponse instance) =>
    <String, dynamic>{
      'raids': instance.raids.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

FactionAttacksResponse _$FactionAttacksResponseFromJson(
        Map<String, dynamic> json) =>
    FactionAttacksResponse(
      attacks: (json['attacks'] as List<dynamic>?)
              ?.map((e) => Attack.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionAttacksResponseToJson(
        FactionAttacksResponse instance) =>
    <String, dynamic>{
      'attacks': instance.attacks.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

FactionAttacksFullResponse _$FactionAttacksFullResponseFromJson(
        Map<String, dynamic> json) =>
    FactionAttacksFullResponse(
      attacks: (json['attacks'] as List<dynamic>?)
              ?.map((e) => AttackSimplified.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionAttacksFullResponseToJson(
        FactionAttacksFullResponse instance) =>
    <String, dynamic>{
      'attacks': instance.attacks.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

FactionApplication _$FactionApplicationFromJson(Map<String, dynamic> json) =>
    FactionApplication(
      id: (json['id'] as num).toInt(),
      user: FactionApplication$User.fromJson(
          json['user'] as Map<String, dynamic>),
      message: json['message'],
      validUntil: (json['valid_until'] as num).toInt(),
      status: factionApplicationStatusEnumFromJson(json['status']),
    );

Map<String, dynamic> _$FactionApplicationToJson(FactionApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user.toJson(),
      'message': instance.message,
      'valid_until': instance.validUntil,
      'status': factionApplicationStatusEnumToJson(instance.status),
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
      'applications': instance.applications.map((e) => e.toJson()).toList(),
    };

FactionOngoingChain _$FactionOngoingChainFromJson(Map<String, dynamic> json) =>
    FactionOngoingChain(
      id: (json['id'] as num).toInt(),
      current: (json['current'] as num).toInt(),
      max: (json['max'] as num).toInt(),
      timeout: (json['timeout'] as num).toInt(),
      modifier: (json['modifier'] as num).toDouble(),
      cooldown: (json['cooldown'] as num).toInt(),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
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
      chain:
          FactionOngoingChain.fromJson(json['chain'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionOngoingChainResponseToJson(
        FactionOngoingChainResponse instance) =>
    <String, dynamic>{
      'chain': instance.chain.toJson(),
    };

FactionChain _$FactionChainFromJson(Map<String, dynamic> json) => FactionChain(
      id: (json['id'] as num).toInt(),
      chain: (json['chain'] as num).toInt(),
      respect: (json['respect'] as num).toDouble(),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );

Map<String, dynamic> _$FactionChainToJson(FactionChain instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chain': instance.chain,
      'respect': instance.respect,
      'start': instance.start,
      'end': instance.end,
    };

FactionChainWarfare _$FactionChainWarfareFromJson(Map<String, dynamic> json) =>
    FactionChainWarfare(
      faction: FactionChainWarfare$Faction.fromJson(
          json['faction'] as Map<String, dynamic>),
      id: (json['id'] as num).toInt(),
      chain: (json['chain'] as num).toInt(),
      respect: (json['respect'] as num).toDouble(),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );

Map<String, dynamic> _$FactionChainWarfareToJson(
        FactionChainWarfare instance) =>
    <String, dynamic>{
      'faction': instance.faction.toJson(),
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
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionChainsResponseToJson(
        FactionChainsResponse instance) =>
    <String, dynamic>{
      'chains': instance.chains.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

FactionChainReportResponse _$FactionChainReportResponseFromJson(
        Map<String, dynamic> json) =>
    FactionChainReportResponse(
      chainreport: FactionChainReport.fromJson(
          json['chainreport'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionChainReportResponseToJson(
        FactionChainReportResponse instance) =>
    <String, dynamic>{
      'chainreport': instance.chainreport.toJson(),
    };

FactionChainReport _$FactionChainReportFromJson(Map<String, dynamic> json) =>
    FactionChainReport(
      id: (json['id'] as num).toInt(),
      factionId: (json['faction_id'] as num).toInt(),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      details: FactionChainReportDetails.fromJson(
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
      nonAttackers: (json['non_attackers'] as List<dynamic>?)
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
      'details': instance.details.toJson(),
      'bonuses': instance.bonuses.map((e) => e.toJson()).toList(),
      'attackers': instance.attackers.map((e) => e.toJson()).toList(),
      'non_attackers': instance.nonAttackers,
    };

FactionChainReportDetails _$FactionChainReportDetailsFromJson(
        Map<String, dynamic> json) =>
    FactionChainReportDetails(
      chain: (json['chain'] as num).toInt(),
      respect: (json['respect'] as num).toDouble(),
      members: (json['members'] as num).toInt(),
      targets: (json['targets'] as num).toInt(),
      war: (json['war'] as num).toInt(),
      best: (json['best'] as num).toDouble(),
      leave: (json['leave'] as num).toInt(),
      mug: (json['mug'] as num).toInt(),
      hospitalize: (json['hospitalize'] as num).toInt(),
      assists: (json['assists'] as num).toInt(),
      retaliations: (json['retaliations'] as num).toInt(),
      overseas: (json['overseas'] as num).toInt(),
      draws: (json['draws'] as num).toInt(),
      escapes: (json['escapes'] as num).toInt(),
      losses: (json['losses'] as num).toInt(),
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
      attackerId: (json['attacker_id'] as num).toInt(),
      defenderId: (json['defender_id'] as num).toInt(),
      chain: (json['chain'] as num).toInt(),
      respect: (json['respect'] as num).toInt(),
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
      id: (json['id'] as num).toInt(),
      respect: FactionChainReportAttackerRespect.fromJson(
          json['respect'] as Map<String, dynamic>),
      attacks: FactionChainReportAttackerAttacks.fromJson(
          json['attacks'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionChainReportAttackerToJson(
        FactionChainReportAttacker instance) =>
    <String, dynamic>{
      'id': instance.id,
      'respect': instance.respect.toJson(),
      'attacks': instance.attacks.toJson(),
    };

FactionChainReportAttackerRespect _$FactionChainReportAttackerRespectFromJson(
        Map<String, dynamic> json) =>
    FactionChainReportAttackerRespect(
      total: (json['total'] as num).toDouble(),
      average: (json['average'] as num).toDouble(),
      best: (json['best'] as num).toDouble(),
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
      total: (json['total'] as num).toInt(),
      leave: (json['leave'] as num).toInt(),
      mug: (json['mug'] as num).toInt(),
      hospitalize: (json['hospitalize'] as num).toInt(),
      assists: (json['assists'] as num).toInt(),
      retaliations: (json['retaliations'] as num).toInt(),
      overseas: (json['overseas'] as num).toInt(),
      draws: (json['draws'] as num).toInt(),
      escapes: (json['escapes'] as num?)?.toInt(),
      losses: (json['losses'] as num).toInt(),
      war: (json['war'] as num).toInt(),
      bonuses: (json['bonuses'] as num).toInt(),
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
      id: (json['id'] as num).toInt(),
      outcome: json['outcome'],
      joinedAt: (json['joined_at'] as num).toInt(),
      progress: (json['progress'] as num).toDouble(),
    );

Map<String, dynamic> _$FactionCrimeUserToJson(FactionCrimeUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'outcome': instance.outcome,
      'joined_at': instance.joinedAt,
      'progress': instance.progress,
    };

FactionCrimeRewardItem _$FactionCrimeRewardItemFromJson(
        Map<String, dynamic> json) =>
    FactionCrimeRewardItem(
      id: (json['id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$FactionCrimeRewardItemToJson(
        FactionCrimeRewardItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
    };

FactionCrimeRewardPayout _$FactionCrimeRewardPayoutFromJson(
        Map<String, dynamic> json) =>
    FactionCrimeRewardPayout(
      type: factionOrganizedCrimePayoutTypeFromJson(json['type']),
      percentage: (json['percentage'] as num).toInt(),
      paidBy: (json['paid_by'] as num).toInt(),
      paidAt: (json['paid_at'] as num).toInt(),
    );

Map<String, dynamic> _$FactionCrimeRewardPayoutToJson(
        FactionCrimeRewardPayout instance) =>
    <String, dynamic>{
      'type': factionOrganizedCrimePayoutTypeToJson(instance.type),
      'percentage': instance.percentage,
      'paid_by': instance.paidBy,
      'paid_at': instance.paidAt,
    };

FactionCrimeReward _$FactionCrimeRewardFromJson(Map<String, dynamic> json) =>
    FactionCrimeReward(
      money: (json['money'] as num).toInt(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  FactionCrimeRewardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      respect: (json['respect'] as num).toInt(),
      scope: (json['scope'] as num).toInt(),
      payout: json['payout'],
    );

Map<String, dynamic> _$FactionCrimeRewardToJson(FactionCrimeReward instance) =>
    <String, dynamic>{
      'money': instance.money,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'respect': instance.respect,
      'scope': instance.scope,
      'payout': instance.payout,
    };

FactionCrimeSlot _$FactionCrimeSlotFromJson(Map<String, dynamic> json) =>
    FactionCrimeSlot(
      position: json['position'] as String,
      itemRequirement: json['item_requirement'],
      user: json['user'],
      checkpointPassRate: (json['checkpoint_pass_rate'] as num).toInt(),
    );

Map<String, dynamic> _$FactionCrimeSlotToJson(FactionCrimeSlot instance) =>
    <String, dynamic>{
      'position': instance.position,
      'item_requirement': instance.itemRequirement,
      'user': instance.user,
      'checkpoint_pass_rate': instance.checkpointPassRate,
    };

FactionCrime _$FactionCrimeFromJson(Map<String, dynamic> json) => FactionCrime(
      id: (json['id'] as num).toInt(),
      previousCrimeId: json['previous_crime_id'],
      name: json['name'] as String,
      difficulty: (json['difficulty'] as num).toInt(),
      status: factionCrimeStatusEnumFromJson(json['status']),
      createdAt: (json['created_at'] as num).toInt(),
      planningAt: json['planning_at'],
      readyAt: json['ready_at'],
      expiredAt: (json['expired_at'] as num).toInt(),
      executedAt: json['executed_at'],
      slots: (json['slots'] as List<dynamic>?)
              ?.map((e) => FactionCrimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rewards: json['rewards'],
    );

Map<String, dynamic> _$FactionCrimeToJson(FactionCrime instance) =>
    <String, dynamic>{
      'id': instance.id,
      'previous_crime_id': instance.previousCrimeId,
      'name': instance.name,
      'difficulty': instance.difficulty,
      'status': factionCrimeStatusEnumToJson(instance.status),
      'created_at': instance.createdAt,
      'planning_at': instance.planningAt,
      'ready_at': instance.readyAt,
      'expired_at': instance.expiredAt,
      'executed_at': instance.executedAt,
      'slots': instance.slots.map((e) => e.toJson()).toList(),
      'rewards': instance.rewards,
    };

FactionCrimesResponse _$FactionCrimesResponseFromJson(
        Map<String, dynamic> json) =>
    FactionCrimesResponse(
      crimes: (json['crimes'] as List<dynamic>?)
              ?.map((e) => FactionCrime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionCrimesResponseToJson(
        FactionCrimesResponse instance) =>
    <String, dynamic>{
      'crimes': instance.crimes.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

FactionCrimeResponse _$FactionCrimeResponseFromJson(
        Map<String, dynamic> json) =>
    FactionCrimeResponse(
      crime: FactionCrime.fromJson(json['crime'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionCrimeResponseToJson(
        FactionCrimeResponse instance) =>
    <String, dynamic>{
      'crime': instance.crime.toJson(),
    };

FactionBalance _$FactionBalanceFromJson(Map<String, dynamic> json) =>
    FactionBalance(
      faction: FactionBalance$Faction.fromJson(
          json['faction'] as Map<String, dynamic>),
      members: (json['members'] as List<dynamic>)
          .map((e) =>
              FactionBalance$Members$Item.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FactionBalanceToJson(FactionBalance instance) =>
    <String, dynamic>{
      'faction': instance.faction.toJson(),
      'members': instance.members.map((e) => e.toJson()).toList(),
    };

FactionBalanceResponse _$FactionBalanceResponseFromJson(
        Map<String, dynamic> json) =>
    FactionBalanceResponse(
      balance: FactionBalance.fromJson(json['balance'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionBalanceResponseToJson(
        FactionBalanceResponse instance) =>
    <String, dynamic>{
      'balance': instance.balance.toJson(),
    };

FactionSelectionName _$FactionSelectionNameFromJson(
        Map<String, dynamic> json) =>
    FactionSelectionName();

Map<String, dynamic> _$FactionSelectionNameToJson(
        FactionSelectionName instance) =>
    <String, dynamic>{};

FactionLookupResponse _$FactionLookupResponseFromJson(
        Map<String, dynamic> json) =>
    FactionLookupResponse(
      selections: (json['selections'] as List<dynamic>?)
              ?.map((e) =>
                  FactionSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionLookupResponseToJson(
        FactionLookupResponse instance) =>
    <String, dynamic>{
      'selections': instance.selections.map((e) => e.toJson()).toList(),
    };

FactionRankedWarDetails _$FactionRankedWarDetailsFromJson(
        Map<String, dynamic> json) =>
    FactionRankedWarDetails(
      id: (json['id'] as num).toInt(),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      target: (json['target'] as num).toInt(),
      winner: json['winner'],
      factions: (json['factions'] as List<dynamic>)
          .map((e) => FactionRankedWarDetails$Factions$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FactionRankedWarDetailsToJson(
        FactionRankedWarDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start': instance.start,
      'end': instance.end,
      'target': instance.target,
      'winner': instance.winner,
      'factions': instance.factions.map((e) => e.toJson()).toList(),
    };

FactionRankedWarResponse _$FactionRankedWarResponseFromJson(
        Map<String, dynamic> json) =>
    FactionRankedWarResponse(
      rankedwars: (json['rankedwars'] as List<dynamic>?)
              ?.map((e) =>
                  FactionRankedWarDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionRankedWarResponseToJson(
        FactionRankedWarResponse instance) =>
    <String, dynamic>{
      'rankedwars': instance.rankedwars.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

FactionWarfareResponse _$FactionWarfareResponseFromJson(
        Map<String, dynamic> json) =>
    FactionWarfareResponse(
      warfare: json['warfare'],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionWarfareResponseToJson(
        FactionWarfareResponse instance) =>
    <String, dynamic>{
      'warfare': instance.warfare,
      '_metadata': instance.metadata.toJson(),
    };

FactionRankedWarReportResponse _$FactionRankedWarReportResponseFromJson(
        Map<String, dynamic> json) =>
    FactionRankedWarReportResponse(
      rankedwarreport: FactionRankedWarReportResponse$Rankedwarreport.fromJson(
          json['rankedwarreport'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionRankedWarReportResponseToJson(
        FactionRankedWarReportResponse instance) =>
    <String, dynamic>{
      'rankedwarreport': instance.rankedwarreport.toJson(),
    };

ForumCategoriesResponse _$ForumCategoriesResponseFromJson(
        Map<String, dynamic> json) =>
    ForumCategoriesResponse(
      categories: (json['categories'] as List<dynamic>)
          .map((e) => ForumCategoriesResponse$Categories$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ForumCategoriesResponseToJson(
        ForumCategoriesResponse instance) =>
    <String, dynamic>{
      'categories': instance.categories.map((e) => e.toJson()).toList(),
    };

ForumThreadAuthor _$ForumThreadAuthorFromJson(Map<String, dynamic> json) =>
    ForumThreadAuthor(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      karma: (json['karma'] as num).toInt(),
    );

Map<String, dynamic> _$ForumThreadAuthorToJson(ForumThreadAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'karma': instance.karma,
    };

ForumPollVote _$ForumPollVoteFromJson(Map<String, dynamic> json) =>
    ForumPollVote(
      answer: json['answer'] as String,
      votes: (json['votes'] as num).toInt(),
    );

Map<String, dynamic> _$ForumPollVoteToJson(ForumPollVote instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'votes': instance.votes,
    };

ForumPoll _$ForumPollFromJson(Map<String, dynamic> json) => ForumPoll(
      question: json['question'] as String,
      answersCount: (json['answers_count'] as num).toInt(),
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => ForumPollVote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ForumPollToJson(ForumPoll instance) => <String, dynamic>{
      'question': instance.question,
      'answers_count': instance.answersCount,
      'answers': instance.answers.map((e) => e.toJson()).toList(),
    };

ForumThreadBase _$ForumThreadBaseFromJson(Map<String, dynamic> json) =>
    ForumThreadBase(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      forumId: (json['forum_id'] as num).toInt(),
      posts: (json['posts'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      views: (json['views'] as num).toInt(),
      author:
          ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      lastPoster: json['last_poster'],
      firstPostTime: (json['first_post_time'] as num).toInt(),
      lastPostTime: json['last_post_time'],
      hasPoll: json['has_poll'] as bool,
      isLocked: json['is_locked'] as bool,
      isSticky: json['is_sticky'] as bool,
    );

Map<String, dynamic> _$ForumThreadBaseToJson(ForumThreadBase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'forum_id': instance.forumId,
      'posts': instance.posts,
      'rating': instance.rating,
      'views': instance.views,
      'author': instance.author.toJson(),
      'last_poster': instance.lastPoster,
      'first_post_time': instance.firstPostTime,
      'last_post_time': instance.lastPostTime,
      'has_poll': instance.hasPoll,
      'is_locked': instance.isLocked,
      'is_sticky': instance.isSticky,
    };

ForumThreadExtended _$ForumThreadExtendedFromJson(Map<String, dynamic> json) =>
    ForumThreadExtended(
      content: json['content'] as String,
      contentRaw: json['content_raw'] as String,
      poll: json['poll'],
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      forumId: (json['forum_id'] as num).toInt(),
      posts: (json['posts'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      views: (json['views'] as num).toInt(),
      author:
          ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      lastPoster: json['last_poster'],
      firstPostTime: (json['first_post_time'] as num).toInt(),
      lastPostTime: json['last_post_time'],
      hasPoll: json['has_poll'] as bool,
      isLocked: json['is_locked'] as bool,
      isSticky: json['is_sticky'] as bool,
    );

Map<String, dynamic> _$ForumThreadExtendedToJson(
        ForumThreadExtended instance) =>
    <String, dynamic>{
      'content': instance.content,
      'content_raw': instance.contentRaw,
      'poll': instance.poll,
      'id': instance.id,
      'title': instance.title,
      'forum_id': instance.forumId,
      'posts': instance.posts,
      'rating': instance.rating,
      'views': instance.views,
      'author': instance.author.toJson(),
      'last_poster': instance.lastPoster,
      'first_post_time': instance.firstPostTime,
      'last_post_time': instance.lastPostTime,
      'has_poll': instance.hasPoll,
      'is_locked': instance.isLocked,
      'is_sticky': instance.isSticky,
    };

ForumPost _$ForumPostFromJson(Map<String, dynamic> json) => ForumPost(
      id: (json['id'] as num).toInt(),
      threadId: (json['thread_id'] as num).toInt(),
      author:
          ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      isLegacy: json['is_legacy'] as bool,
      isTopic: json['is_topic'] as bool,
      isEdited: json['is_edited'] as bool,
      isPinned: json['is_pinned'] as bool,
      createdTime: (json['created_time'] as num).toInt(),
      editedBy: json['edited_by'],
      hasQuote: json['has_quote'] as bool,
      quotedPostId: json['quoted_post_id'],
      content: json['content'] as String,
      likes: (json['likes'] as num).toInt(),
      dislikes: (json['dislikes'] as num).toInt(),
    );

Map<String, dynamic> _$ForumPostToJson(ForumPost instance) => <String, dynamic>{
      'id': instance.id,
      'thread_id': instance.threadId,
      'author': instance.author.toJson(),
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
      newPosts: json['new_posts'],
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      forumId: (json['forum_id'] as num).toInt(),
      posts: (json['posts'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      views: (json['views'] as num).toInt(),
      author:
          ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      lastPoster: json['last_poster'],
      firstPostTime: (json['first_post_time'] as num).toInt(),
      lastPostTime: json['last_post_time'],
      hasPoll: json['has_poll'] as bool,
      isLocked: json['is_locked'] as bool,
      isSticky: json['is_sticky'] as bool,
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
      'author': instance.author.toJson(),
      'last_poster': instance.lastPoster,
      'first_post_time': instance.firstPostTime,
      'last_post_time': instance.lastPostTime,
      'has_poll': instance.hasPoll,
      'is_locked': instance.isLocked,
      'is_sticky': instance.isSticky,
    };

ForumSubscribedThreadPostsCount _$ForumSubscribedThreadPostsCountFromJson(
        Map<String, dynamic> json) =>
    ForumSubscribedThreadPostsCount(
      $new: (json['new'] as num).toInt(),
      total: (json['total'] as num).toInt(),
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
      id: (json['id'] as num).toInt(),
      forumId: (json['forum_id'] as num).toInt(),
      author:
          ForumThreadAuthor.fromJson(json['author'] as Map<String, dynamic>),
      title: json['title'] as String,
      posts: ForumSubscribedThreadPostsCount.fromJson(
          json['posts'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumSubscribedThreadToJson(
        ForumSubscribedThread instance) =>
    <String, dynamic>{
      'id': instance.id,
      'forum_id': instance.forumId,
      'author': instance.author.toJson(),
      'title': instance.title,
      'posts': instance.posts.toJson(),
    };

ForumFeed _$ForumFeedFromJson(Map<String, dynamic> json) => ForumFeed(
      threadId: (json['thread_id'] as num).toInt(),
      postId: (json['post_id'] as num).toInt(),
      user: ForumThreadAuthor.fromJson(json['user'] as Map<String, dynamic>),
      title: json['title'] as String,
      text: json['text'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      isSeen: json['is_seen'] as bool,
      type: forumFeedTypeEnumFromJson(json['type']),
    );

Map<String, dynamic> _$ForumFeedToJson(ForumFeed instance) => <String, dynamic>{
      'thread_id': instance.threadId,
      'post_id': instance.postId,
      'user': instance.user.toJson(),
      'title': instance.title,
      'text': instance.text,
      'timestamp': instance.timestamp,
      'is_seen': instance.isSeen,
      'type': forumFeedTypeEnumToJson(instance.type),
    };

ForumThreadsResponse _$ForumThreadsResponseFromJson(
        Map<String, dynamic> json) =>
    ForumThreadsResponse(
      threads: (json['threads'] as List<dynamic>?)
              ?.map((e) => ForumThreadBase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumThreadsResponseToJson(
        ForumThreadsResponse instance) =>
    <String, dynamic>{
      'threads': instance.threads.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

ForumThreadResponse _$ForumThreadResponseFromJson(Map<String, dynamic> json) =>
    ForumThreadResponse(
      thread:
          ForumThreadExtended.fromJson(json['thread'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumThreadResponseToJson(
        ForumThreadResponse instance) =>
    <String, dynamic>{
      'thread': instance.thread.toJson(),
    };

ForumPostsResponse _$ForumPostsResponseFromJson(Map<String, dynamic> json) =>
    ForumPostsResponse(
      posts: (json['posts'] as List<dynamic>?)
              ?.map((e) => ForumPost.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumPostsResponseToJson(ForumPostsResponse instance) =>
    <String, dynamic>{
      'posts': instance.posts.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

ForumSelectionName _$ForumSelectionNameFromJson(Map<String, dynamic> json) =>
    ForumSelectionName();

Map<String, dynamic> _$ForumSelectionNameToJson(ForumSelectionName instance) =>
    <String, dynamic>{};

ForumLookupResponse _$ForumLookupResponseFromJson(Map<String, dynamic> json) =>
    ForumLookupResponse(
      selections: (json['selections'] as List<dynamic>?)
              ?.map(
                  (e) => ForumSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ForumLookupResponseToJson(
        ForumLookupResponse instance) =>
    <String, dynamic>{
      'selections': instance.selections.map((e) => e.toJson()).toList(),
    };

KeyLogResponse _$KeyLogResponseFromJson(Map<String, dynamic> json) =>
    KeyLogResponse(
      log: (json['log'] as List<dynamic>)
          .map((e) =>
              KeyLogResponse$Log$Item.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$KeyLogResponseToJson(KeyLogResponse instance) =>
    <String, dynamic>{
      'log': instance.log.map((e) => e.toJson()).toList(),
    };

KeyInfoResponse _$KeyInfoResponseFromJson(Map<String, dynamic> json) =>
    KeyInfoResponse(
      info: KeyInfoResponse$Info.fromJson(json['info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$KeyInfoResponseToJson(KeyInfoResponse instance) =>
    <String, dynamic>{
      'info': instance.info.toJson(),
    };

KeySelectionName _$KeySelectionNameFromJson(Map<String, dynamic> json) =>
    KeySelectionName();

Map<String, dynamic> _$KeySelectionNameToJson(KeySelectionName instance) =>
    <String, dynamic>{};

BasicProperty _$BasicPropertyFromJson(Map<String, dynamic> json) =>
    BasicProperty(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$BasicPropertyToJson(BasicProperty instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

MarketRentalDetails _$MarketRentalDetailsFromJson(Map<String, dynamic> json) =>
    MarketRentalDetails(
      listings: (json['listings'] as List<dynamic>)
          .map((e) => MarketRentalDetails$Listings$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      property:
          BasicProperty.fromJson(json['property'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MarketRentalDetailsToJson(
        MarketRentalDetails instance) =>
    <String, dynamic>{
      'listings': instance.listings.map((e) => e.toJson()).toList(),
      'property': instance.property.toJson(),
    };

MarketRentalsResponse _$MarketRentalsResponseFromJson(
        Map<String, dynamic> json) =>
    MarketRentalsResponse(
      properties: MarketRentalDetails.fromJson(
          json['properties'] as Map<String, dynamic>),
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MarketRentalsResponseToJson(
        MarketRentalsResponse instance) =>
    <String, dynamic>{
      'properties': instance.properties.toJson(),
      '_metadata': instance.metadata.toJson(),
    };

MarketPropertyDetails _$MarketPropertyDetailsFromJson(
        Map<String, dynamic> json) =>
    MarketPropertyDetails(
      listings: (json['listings'] as List<dynamic>)
          .map((e) => MarketPropertyDetails$Listings$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      property:
          BasicProperty.fromJson(json['property'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MarketPropertyDetailsToJson(
        MarketPropertyDetails instance) =>
    <String, dynamic>{
      'listings': instance.listings.map((e) => e.toJson()).toList(),
      'property': instance.property.toJson(),
    };

MarketPropertiesResponse _$MarketPropertiesResponseFromJson(
        Map<String, dynamic> json) =>
    MarketPropertiesResponse(
      properties: MarketPropertyDetails.fromJson(
          json['properties'] as Map<String, dynamic>),
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MarketPropertiesResponseToJson(
        MarketPropertiesResponse instance) =>
    <String, dynamic>{
      'properties': instance.properties.toJson(),
      '_metadata': instance.metadata.toJson(),
    };

BazaarWeekly _$BazaarWeeklyFromJson(Map<String, dynamic> json) => BazaarWeekly(
      busiest: (json['busiest'] as List<dynamic>?)
              ?.map((e) =>
                  BazaarWeeklyCustomers.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mostPopular: (json['most_popular'] as List<dynamic>?)
              ?.map((e) =>
                  BazaarTotalFavorites.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      trending: (json['trending'] as List<dynamic>?)
              ?.map((e) =>
                  BazaarRecentFavorites.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topGrossing: (json['top_grossing'] as List<dynamic>?)
              ?.map(
                  (e) => BazaarWeeklyIncome.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bulk: (json['bulk'] as List<dynamic>?)
              ?.map((e) => BazaarBulkSales.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      advancedItem: (json['advanced_item'] as List<dynamic>?)
              ?.map((e) =>
                  BazaarAdvancedItemSales.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bargain: (json['bargain'] as List<dynamic>?)
              ?.map(
                  (e) => BazaarBargainSales.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dollarSale: (json['dollar_sale'] as List<dynamic>?)
              ?.map(
                  (e) => BazaarDollarSales.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$BazaarWeeklyToJson(BazaarWeekly instance) =>
    <String, dynamic>{
      'busiest': instance.busiest.map((e) => e.toJson()).toList(),
      'most_popular': instance.mostPopular.map((e) => e.toJson()).toList(),
      'trending': instance.trending.map((e) => e.toJson()).toList(),
      'top_grossing': instance.topGrossing.map((e) => e.toJson()).toList(),
      'bulk': instance.bulk.map((e) => e.toJson()).toList(),
      'advanced_item': instance.advancedItem.map((e) => e.toJson()).toList(),
      'bargain': instance.bargain.map((e) => e.toJson()).toList(),
      'dollar_sale': instance.dollarSale.map((e) => e.toJson()).toList(),
    };

BazaarSpecialized _$BazaarSpecializedFromJson(Map<String, dynamic> json) =>
    BazaarSpecialized(
      specialized: (json['specialized'] as List<dynamic>?)
              ?.map((e) =>
                  BazaarWeeklyCustomers.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$BazaarSpecializedToJson(BazaarSpecialized instance) =>
    <String, dynamic>{
      'specialized': instance.specialized.map((e) => e.toJson()).toList(),
    };

BazaarResponse _$BazaarResponseFromJson(Map<String, dynamic> json) =>
    BazaarResponse(
      bazaar: json['bazaar'],
    );

Map<String, dynamic> _$BazaarResponseToJson(BazaarResponse instance) =>
    <String, dynamic>{
      'bazaar': instance.bazaar,
    };

BazaarResponseSpecialized _$BazaarResponseSpecializedFromJson(
        Map<String, dynamic> json) =>
    BazaarResponseSpecialized(
      bazaar:
          BazaarSpecialized.fromJson(json['bazaar'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BazaarResponseSpecializedToJson(
        BazaarResponseSpecialized instance) =>
    <String, dynamic>{
      'bazaar': instance.bazaar.toJson(),
    };

Bazaar _$BazaarFromJson(Map<String, dynamic> json) => Bazaar(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isOpen: json['is_open'] as bool,
    );

Map<String, dynamic> _$BazaarToJson(Bazaar instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_open': instance.isOpen,
    };

BazaarWeeklyCustomers _$BazaarWeeklyCustomersFromJson(
        Map<String, dynamic> json) =>
    BazaarWeeklyCustomers(
      weeklyCustomers: (json['weekly_customers'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isOpen: json['is_open'] as bool,
    );

Map<String, dynamic> _$BazaarWeeklyCustomersToJson(
        BazaarWeeklyCustomers instance) =>
    <String, dynamic>{
      'weekly_customers': instance.weeklyCustomers,
      'id': instance.id,
      'name': instance.name,
      'is_open': instance.isOpen,
    };

BazaarTotalFavorites _$BazaarTotalFavoritesFromJson(
        Map<String, dynamic> json) =>
    BazaarTotalFavorites(
      totalFavorites: (json['total_favorites'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isOpen: json['is_open'] as bool,
    );

Map<String, dynamic> _$BazaarTotalFavoritesToJson(
        BazaarTotalFavorites instance) =>
    <String, dynamic>{
      'total_favorites': instance.totalFavorites,
      'id': instance.id,
      'name': instance.name,
      'is_open': instance.isOpen,
    };

BazaarRecentFavorites _$BazaarRecentFavoritesFromJson(
        Map<String, dynamic> json) =>
    BazaarRecentFavorites(
      recentFavorites: (json['recent_favorites'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isOpen: json['is_open'] as bool,
    );

Map<String, dynamic> _$BazaarRecentFavoritesToJson(
        BazaarRecentFavorites instance) =>
    <String, dynamic>{
      'recent_favorites': instance.recentFavorites,
      'id': instance.id,
      'name': instance.name,
      'is_open': instance.isOpen,
    };

BazaarWeeklyIncome _$BazaarWeeklyIncomeFromJson(Map<String, dynamic> json) =>
    BazaarWeeklyIncome(
      weeklyIncome: (json['weekly_income'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isOpen: json['is_open'] as bool,
    );

Map<String, dynamic> _$BazaarWeeklyIncomeToJson(BazaarWeeklyIncome instance) =>
    <String, dynamic>{
      'weekly_income': instance.weeklyIncome,
      'id': instance.id,
      'name': instance.name,
      'is_open': instance.isOpen,
    };

BazaarBulkSales _$BazaarBulkSalesFromJson(Map<String, dynamic> json) =>
    BazaarBulkSales(
      bulkSales: (json['bulk_sales'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isOpen: json['is_open'] as bool,
    );

Map<String, dynamic> _$BazaarBulkSalesToJson(BazaarBulkSales instance) =>
    <String, dynamic>{
      'bulk_sales': instance.bulkSales,
      'id': instance.id,
      'name': instance.name,
      'is_open': instance.isOpen,
    };

BazaarAdvancedItemSales _$BazaarAdvancedItemSalesFromJson(
        Map<String, dynamic> json) =>
    BazaarAdvancedItemSales(
      advancedItemSales: (json['advanced_item_sales'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isOpen: json['is_open'] as bool,
    );

Map<String, dynamic> _$BazaarAdvancedItemSalesToJson(
        BazaarAdvancedItemSales instance) =>
    <String, dynamic>{
      'advanced_item_sales': instance.advancedItemSales,
      'id': instance.id,
      'name': instance.name,
      'is_open': instance.isOpen,
    };

BazaarBargainSales _$BazaarBargainSalesFromJson(Map<String, dynamic> json) =>
    BazaarBargainSales(
      bargainSales: (json['bargain_sales'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isOpen: json['is_open'] as bool,
    );

Map<String, dynamic> _$BazaarBargainSalesToJson(BazaarBargainSales instance) =>
    <String, dynamic>{
      'bargain_sales': instance.bargainSales,
      'id': instance.id,
      'name': instance.name,
      'is_open': instance.isOpen,
    };

BazaarDollarSales _$BazaarDollarSalesFromJson(Map<String, dynamic> json) =>
    BazaarDollarSales(
      dollarSales: (json['dollar_sales'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isOpen: json['is_open'] as bool,
    );

Map<String, dynamic> _$BazaarDollarSalesToJson(BazaarDollarSales instance) =>
    <String, dynamic>{
      'dollar_sales': instance.dollarSales,
      'id': instance.id,
      'name': instance.name,
      'is_open': instance.isOpen,
    };

ItemMarketListingItemBonus _$ItemMarketListingItemBonusFromJson(
        Map<String, dynamic> json) =>
    ItemMarketListingItemBonus(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      $value: (json['value'] as num).toInt(),
    );

Map<String, dynamic> _$ItemMarketListingItemBonusToJson(
        ItemMarketListingItemBonus instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'value': instance.$value,
    };

ItemMarketListingItemStats _$ItemMarketListingItemStatsFromJson(
        Map<String, dynamic> json) =>
    ItemMarketListingItemStats(
      damage: json['damage'],
      accuracy: json['accuracy'],
      armor: json['armor'],
      quality: (json['quality'] as num).toDouble(),
    );

Map<String, dynamic> _$ItemMarketListingItemStatsToJson(
        ItemMarketListingItemStats instance) =>
    <String, dynamic>{
      'damage': instance.damage,
      'accuracy': instance.accuracy,
      'armor': instance.armor,
      'quality': instance.quality,
    };

ItemMarketItem _$ItemMarketItemFromJson(Map<String, dynamic> json) =>
    ItemMarketItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      averagePrice: (json['average_price'] as num).toInt(),
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
      price: (json['price'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
    );

Map<String, dynamic> _$ItemMarketListingStackableToJson(
        ItemMarketListingStackable instance) =>
    <String, dynamic>{
      'price': instance.price,
      'amount': instance.amount,
    };

ItemMarketListingItemDetails _$ItemMarketListingItemDetailsFromJson(
        Map<String, dynamic> json) =>
    ItemMarketListingItemDetails(
      uid: (json['uid'] as num).toInt(),
      stats: ItemMarketListingItemStats.fromJson(
          json['stats'] as Map<String, dynamic>),
      bonuses: (json['bonuses'] as List<dynamic>?)
              ?.map((e) => ItemMarketListingItemBonus.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      rarity: json['rarity'],
    );

Map<String, dynamic> _$ItemMarketListingItemDetailsToJson(
        ItemMarketListingItemDetails instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'stats': instance.stats.toJson(),
      'bonuses': instance.bonuses.map((e) => e.toJson()).toList(),
      'rarity': instance.rarity,
    };

ItemMarketListingNonstackable _$ItemMarketListingNonstackableFromJson(
        Map<String, dynamic> json) =>
    ItemMarketListingNonstackable(
      price: (json['price'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
      itemDetails: ItemMarketListingItemDetails.fromJson(
          json['item_details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ItemMarketListingNonstackableToJson(
        ItemMarketListingNonstackable instance) =>
    <String, dynamic>{
      'price': instance.price,
      'amount': instance.amount,
      'item_details': instance.itemDetails.toJson(),
    };

ItemMarket _$ItemMarketFromJson(Map<String, dynamic> json) => ItemMarket(
      item: ItemMarketItem.fromJson(json['item'] as Map<String, dynamic>),
      listings: (json['listings'] as List<dynamic>?)
              ?.map((e) => e as Object)
              .toList() ??
          [],
      cacheTimestamp: (json['cache_timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$ItemMarketToJson(ItemMarket instance) =>
    <String, dynamic>{
      'item': instance.item.toJson(),
      'listings': instance.listings,
      'cache_timestamp': instance.cacheTimestamp,
    };

MarketItemMarketResponse _$MarketItemMarketResponseFromJson(
        Map<String, dynamic> json) =>
    MarketItemMarketResponse(
      itemmarket:
          ItemMarket.fromJson(json['itemmarket'] as Map<String, dynamic>),
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MarketItemMarketResponseToJson(
        MarketItemMarketResponse instance) =>
    <String, dynamic>{
      'itemmarket': instance.itemmarket.toJson(),
      '_metadata': instance.metadata.toJson(),
    };

MarketSelectionName _$MarketSelectionNameFromJson(Map<String, dynamic> json) =>
    MarketSelectionName();

Map<String, dynamic> _$MarketSelectionNameToJson(
        MarketSelectionName instance) =>
    <String, dynamic>{};

MarketLookupResponse _$MarketLookupResponseFromJson(
        Map<String, dynamic> json) =>
    MarketLookupResponse(
      selections: (json['selections'] as List<dynamic>?)
              ?.map((e) =>
                  MarketSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$MarketLookupResponseToJson(
        MarketLookupResponse instance) =>
    <String, dynamic>{
      'selections': instance.selections.map((e) => e.toJson()).toList(),
    };

UserRacingRecordsResponse _$UserRacingRecordsResponseFromJson(
        Map<String, dynamic> json) =>
    UserRacingRecordsResponse(
      racingrecords: (json['racingrecords'] as List<dynamic>)
          .map((e) => UserRacingRecordsResponse$Racingrecords$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserRacingRecordsResponseToJson(
        UserRacingRecordsResponse instance) =>
    <String, dynamic>{
      'racingrecords': instance.racingrecords.map((e) => e.toJson()).toList(),
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
      'cars': instance.cars.map((e) => e.toJson()).toList(),
    };

RaceCar _$RaceCarFromJson(Map<String, dynamic> json) => RaceCar(
      carItemId: (json['car_item_id'] as num).toInt(),
      carItemName: json['car_item_name'] as String,
      topSpeed: (json['top_speed'] as num).toInt(),
      acceleration: (json['acceleration'] as num).toInt(),
      braking: (json['braking'] as num).toInt(),
      dirt: (json['dirt'] as num).toInt(),
      handling: (json['handling'] as num).toInt(),
      safety: (json['safety'] as num).toInt(),
      tarmac: (json['tarmac'] as num).toInt(),
      $class: raceClassEnumFromJson(json['class']),
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
      'class': raceClassEnumToJson(instance.$class),
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
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };

RaceTrack _$RaceTrackFromJson(Map<String, dynamic> json) => RaceTrack(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
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
      'carupgrades': instance.carupgrades.map((e) => e.toJson()).toList(),
    };

RaceCarUpgrade _$RaceCarUpgradeFromJson(Map<String, dynamic> json) =>
    RaceCarUpgrade(
      id: (json['id'] as num).toInt(),
      classRequired: raceClassEnumFromJson(json['class_required']),
      name: json['name'] as String,
      description: json['description'] as String,
      category: raceCarUpgradeCategoryFromJson(json['category']),
      subcategory: raceCarUpgradeSubCategoryFromJson(json['subcategory']),
      effects: RaceCarUpgrade$Effects.fromJson(
          json['effects'] as Map<String, dynamic>),
      cost: RaceCarUpgrade$Cost.fromJson(json['cost'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RaceCarUpgradeToJson(RaceCarUpgrade instance) =>
    <String, dynamic>{
      'id': instance.id,
      'class_required': raceClassEnumToJson(instance.classRequired),
      'name': instance.name,
      'description': instance.description,
      'category': raceCarUpgradeCategoryToJson(instance.category),
      'subcategory': raceCarUpgradeSubCategoryToJson(instance.subcategory),
      'effects': instance.effects.toJson(),
      'cost': instance.cost.toJson(),
    };

RacingRacesResponse _$RacingRacesResponseFromJson(Map<String, dynamic> json) =>
    RacingRacesResponse(
      races: (json['races'] as List<dynamic>?)
              ?.map((e) => Race.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RacingRacesResponseToJson(
        RacingRacesResponse instance) =>
    <String, dynamic>{
      'races': instance.races.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

Race _$RaceFromJson(Map<String, dynamic> json) => Race(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      trackId: (json['track_id'] as num).toInt(),
      creatorId: (json['creator_id'] as num).toInt(),
      status: raceStatusEnumFromJson(json['status']),
      laps: (json['laps'] as num).toInt(),
      participants: Race$Participants.fromJson(
          json['participants'] as Map<String, dynamic>),
      schedule:
          Race$Schedule.fromJson(json['schedule'] as Map<String, dynamic>),
      requirements: Race$Requirements.fromJson(
          json['requirements'] as Map<String, dynamic>),
      isOfficial: json['is_official'] as bool,
    );

Map<String, dynamic> _$RaceToJson(Race instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'track_id': instance.trackId,
      'creator_id': instance.creatorId,
      'status': raceStatusEnumToJson(instance.status),
      'laps': instance.laps,
      'participants': instance.participants.toJson(),
      'schedule': instance.schedule.toJson(),
      'requirements': instance.requirements.toJson(),
      'is_official': instance.isOfficial,
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
      'records': instance.records.map((e) => e.toJson()).toList(),
    };

RaceRecord _$RaceRecordFromJson(Map<String, dynamic> json) => RaceRecord(
      driverId: (json['driver_id'] as num).toInt(),
      driverName: json['driver_name'] as String,
      carItemId: (json['car_item_id'] as num).toInt(),
      lapTime: (json['lap_time'] as num).toDouble(),
      carItemName: json['car_item_name'] as String,
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
      driverId: (json['driver_id'] as num).toInt(),
      position: json['position'],
      carId: (json['car_id'] as num).toInt(),
      carItemId: (json['car_item_id'] as num).toInt(),
      carItemName: json['car_item_name'] as String,
      carClass: raceClassEnumFromJson(json['car_class']),
      hasCrashed: json['has_crashed'],
      bestLapTime: json['best_lap_time'],
      raceTime: json['race_time'],
      timeEnded: json['time_ended'],
    );

Map<String, dynamic> _$RacerDetailsToJson(RacerDetails instance) =>
    <String, dynamic>{
      'driver_id': instance.driverId,
      'position': instance.position,
      'car_id': instance.carId,
      'car_item_id': instance.carItemId,
      'car_item_name': instance.carItemName,
      'car_class': raceClassEnumToJson(instance.carClass),
      'has_crashed': instance.hasCrashed,
      'best_lap_time': instance.bestLapTime,
      'race_time': instance.raceTime,
      'time_ended': instance.timeEnded,
    };

RacingRaceDetails _$RacingRaceDetailsFromJson(Map<String, dynamic> json) =>
    RacingRaceDetails(
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => RacerDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isOfficial: json['is_official'] as bool,
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      trackId: (json['track_id'] as num).toInt(),
      creatorId: (json['creator_id'] as num).toInt(),
      status: raceStatusEnumFromJson(json['status']),
      laps: (json['laps'] as num).toInt(),
      participants: RacingRaceDetails$Participants.fromJson(
          json['participants'] as Map<String, dynamic>),
      schedule: RacingRaceDetails$Schedule.fromJson(
          json['schedule'] as Map<String, dynamic>),
      requirements: RacingRaceDetails$Requirements.fromJson(
          json['requirements'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RacingRaceDetailsToJson(RacingRaceDetails instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
      'is_official': instance.isOfficial,
      'id': instance.id,
      'title': instance.title,
      'track_id': instance.trackId,
      'creator_id': instance.creatorId,
      'status': raceStatusEnumToJson(instance.status),
      'laps': instance.laps,
      'participants': instance.participants.toJson(),
      'schedule': instance.schedule.toJson(),
      'requirements': instance.requirements.toJson(),
    };

RacingRaceDetailsResponse _$RacingRaceDetailsResponseFromJson(
        Map<String, dynamic> json) =>
    RacingRaceDetailsResponse(
      race: RacingRaceDetails.fromJson(json['race'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RacingRaceDetailsResponseToJson(
        RacingRaceDetailsResponse instance) =>
    <String, dynamic>{
      'race': instance.race.toJson(),
    };

RacingSelectionName _$RacingSelectionNameFromJson(Map<String, dynamic> json) =>
    RacingSelectionName();

Map<String, dynamic> _$RacingSelectionNameToJson(
        RacingSelectionName instance) =>
    <String, dynamic>{};

RacingLookupResponse _$RacingLookupResponseFromJson(
        Map<String, dynamic> json) =>
    RacingLookupResponse(
      selections: (json['selections'] as List<dynamic>?)
              ?.map((e) =>
                  RacingSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RacingLookupResponseToJson(
        RacingLookupResponse instance) =>
    <String, dynamic>{
      'selections': instance.selections.map((e) => e.toJson()).toList(),
    };

PropertySelectionName _$PropertySelectionNameFromJson(
        Map<String, dynamic> json) =>
    PropertySelectionName();

Map<String, dynamic> _$PropertySelectionNameToJson(
        PropertySelectionName instance) =>
    <String, dynamic>{};

PropertyLookupResponse _$PropertyLookupResponseFromJson(
        Map<String, dynamic> json) =>
    PropertyLookupResponse(
      selections: (json['selections'] as List<dynamic>?)
              ?.map((e) =>
                  PropertySelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$PropertyLookupResponseToJson(
        PropertyLookupResponse instance) =>
    <String, dynamic>{
      'selections': instance.selections.map((e) => e.toJson()).toList(),
    };

TornOrganizedCrimeResponse _$TornOrganizedCrimeResponseFromJson(
        Map<String, dynamic> json) =>
    TornOrganizedCrimeResponse(
      organizedcrimes: (json['organizedcrimes'] as List<dynamic>?)
              ?.map(
                  (e) => TornOrganizedCrime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornOrganizedCrimeResponseToJson(
        TornOrganizedCrimeResponse instance) =>
    <String, dynamic>{
      'organizedcrimes':
          instance.organizedcrimes.map((e) => e.toJson()).toList(),
    };

TornOrganizedCrime _$TornOrganizedCrimeFromJson(Map<String, dynamic> json) =>
    TornOrganizedCrime(
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: (json['difficulty'] as num).toInt(),
      spawn: TornOrganizedCrimeSpawn.fromJson(
          json['spawn'] as Map<String, dynamic>),
      scope: TornOrganizedCrimeScope.fromJson(
          json['scope'] as Map<String, dynamic>),
      prerequisite: json['prerequisite'],
      slots: (json['slots'] as List<dynamic>?)
              ?.map((e) =>
                  TornOrganizedCrimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornOrganizedCrimeToJson(TornOrganizedCrime instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'difficulty': instance.difficulty,
      'spawn': instance.spawn.toJson(),
      'scope': instance.scope.toJson(),
      'prerequisite': instance.prerequisite,
      'slots': instance.slots.map((e) => e.toJson()).toList(),
    };

TornOrganizedCrimeSpawn _$TornOrganizedCrimeSpawnFromJson(
        Map<String, dynamic> json) =>
    TornOrganizedCrimeSpawn(
      level: (json['level'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$TornOrganizedCrimeSpawnToJson(
        TornOrganizedCrimeSpawn instance) =>
    <String, dynamic>{
      'level': instance.level,
      'name': instance.name,
    };

TornOrganizedCrimeScope _$TornOrganizedCrimeScopeFromJson(
        Map<String, dynamic> json) =>
    TornOrganizedCrimeScope(
      cost: (json['cost'] as num).toInt(),
      $return: (json['return'] as num).toInt(),
    );

Map<String, dynamic> _$TornOrganizedCrimeScopeToJson(
        TornOrganizedCrimeScope instance) =>
    <String, dynamic>{
      'cost': instance.cost,
      'return': instance.$return,
    };

TornOrganizedCrimeSlot _$TornOrganizedCrimeSlotFromJson(
        Map<String, dynamic> json) =>
    TornOrganizedCrimeSlot(
      id: json['id'] as String,
      name: json['name'] as String,
      requiredItem: json['required_item'],
    );

Map<String, dynamic> _$TornOrganizedCrimeSlotToJson(
        TornOrganizedCrimeSlot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'required_item': instance.requiredItem,
    };

TornOrganizedCrimeRequiredItem _$TornOrganizedCrimeRequiredItemFromJson(
        Map<String, dynamic> json) =>
    TornOrganizedCrimeRequiredItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isUsed: json['is_used'] as bool,
    );

Map<String, dynamic> _$TornOrganizedCrimeRequiredItemToJson(
        TornOrganizedCrimeRequiredItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_used': instance.isUsed,
    };

TornProperties _$TornPropertiesFromJson(Map<String, dynamic> json) =>
    TornProperties(
      properties: (json['properties'] as List<dynamic>?)
          ?.map((e) => TornProperties$Properties$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TornPropertiesToJson(TornProperties instance) =>
    <String, dynamic>{
      'properties': instance.properties?.map((e) => e.toJson()).toList(),
    };

TornEducationRewards _$TornEducationRewardsFromJson(
        Map<String, dynamic> json) =>
    TornEducationRewards(
      workingStats: TornEducationRewards$WorkingStats.fromJson(
          json['working_stats'] as Map<String, dynamic>),
      effect: json['effect'],
      honor: json['honor'],
    );

Map<String, dynamic> _$TornEducationRewardsToJson(
        TornEducationRewards instance) =>
    <String, dynamic>{
      'working_stats': instance.workingStats.toJson(),
      'effect': instance.effect,
      'honor': instance.honor,
    };

TornEducationPrerequisites _$TornEducationPrerequisitesFromJson(
        Map<String, dynamic> json) =>
    TornEducationPrerequisites(
      cost: (json['cost'] as num).toInt(),
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornEducationPrerequisitesToJson(
        TornEducationPrerequisites instance) =>
    <String, dynamic>{
      'cost': instance.cost,
      'courses': instance.courses,
    };

TornEducationCourses _$TornEducationCoursesFromJson(
        Map<String, dynamic> json) =>
    TornEducationCourses(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      duration: (json['duration'] as num).toInt(),
      rewards: TornEducationRewards.fromJson(
          json['rewards'] as Map<String, dynamic>),
      prerequisites: TornEducationPrerequisites.fromJson(
          json['prerequisites'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornEducationCoursesToJson(
        TornEducationCourses instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'duration': instance.duration,
      'rewards': instance.rewards.toJson(),
      'prerequisites': instance.prerequisites.toJson(),
    };

TornEducation _$TornEducationFromJson(Map<String, dynamic> json) =>
    TornEducation(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) =>
                  TornEducationCourses.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornEducationToJson(TornEducation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'courses': instance.courses.map((e) => e.toJson()).toList(),
    };

TornEducationResponse _$TornEducationResponseFromJson(
        Map<String, dynamic> json) =>
    TornEducationResponse(
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => TornEducation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornEducationResponseToJson(
        TornEducationResponse instance) =>
    <String, dynamic>{
      'education': instance.education.map((e) => e.toJson()).toList(),
    };

TornTerritoryCoordinates _$TornTerritoryCoordinatesFromJson(
        Map<String, dynamic> json) =>
    TornTerritoryCoordinates(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$TornTerritoryCoordinatesToJson(
        TornTerritoryCoordinates instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

TornTerritory _$TornTerritoryFromJson(Map<String, dynamic> json) =>
    TornTerritory(
      id: factionTerritoryEnumFromJson(json['id']),
      sector: (json['sector'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      density: (json['density'] as num).toInt(),
      slots: (json['slots'] as num).toInt(),
      respect: (json['respect'] as num).toInt(),
      coordinates: TornTerritoryCoordinates.fromJson(
          json['coordinates'] as Map<String, dynamic>),
      neighbors: factionTerritoryEnumListFromJson(json['neighbors'] as List?),
    );

Map<String, dynamic> _$TornTerritoryToJson(TornTerritory instance) =>
    <String, dynamic>{
      'id': factionTerritoryEnumToJson(instance.id),
      'sector': instance.sector,
      'size': instance.size,
      'density': instance.density,
      'slots': instance.slots,
      'respect': instance.respect,
      'coordinates': instance.coordinates.toJson(),
      'neighbors': factionTerritoryEnumListToJson(instance.neighbors),
    };

TornTerritoriesResponse _$TornTerritoriesResponseFromJson(
        Map<String, dynamic> json) =>
    TornTerritoriesResponse(
      territory: (json['territory'] as List<dynamic>?)
              ?.map((e) => TornTerritory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornTerritoriesResponseToJson(
        TornTerritoriesResponse instance) =>
    <String, dynamic>{
      'territory': instance.territory.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

TornTerritoriesNoLinksResponse _$TornTerritoriesNoLinksResponseFromJson(
        Map<String, dynamic> json) =>
    TornTerritoriesNoLinksResponse(
      territory: (json['territory'] as List<dynamic>?)
              ?.map((e) => TornTerritory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornTerritoriesNoLinksResponseToJson(
        TornTerritoriesNoLinksResponse instance) =>
    <String, dynamic>{
      'territory': instance.territory.map((e) => e.toJson()).toList(),
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
      'subcrimes': instance.subcrimes.map((e) => e.toJson()).toList(),
    };

TornSubcrime _$TornSubcrimeFromJson(Map<String, dynamic> json) => TornSubcrime(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      nerveCost: (json['nerve_cost'] as num).toInt(),
    );

Map<String, dynamic> _$TornSubcrimeToJson(TornSubcrime instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nerve_cost': instance.nerveCost,
    };

TornCrime _$TornCrimeFromJson(Map<String, dynamic> json) => TornCrime(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: json['category_name'] as String?,
      enhancerId: (json['enhancer_id'] as num).toInt(),
      enhancerName: json['enhancer_name'] as String,
      uniqueOutcomesCount: (json['unique_outcomes_count'] as num).toInt(),
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

TornCrimesResponse _$TornCrimesResponseFromJson(Map<String, dynamic> json) =>
    TornCrimesResponse(
      crimes: (json['crimes'] as List<dynamic>?)
              ?.map((e) => TornCrime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornCrimesResponseToJson(TornCrimesResponse instance) =>
    <String, dynamic>{
      'crimes': instance.crimes.map((e) => e.toJson()).toList(),
    };

TornCalendarActivity _$TornCalendarActivityFromJson(
        Map<String, dynamic> json) =>
    TornCalendarActivity(
      title: json['title'] as String,
      description: json['description'] as String,
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
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
      calendar: TornCalendarResponse$Calendar.fromJson(
          json['calendar'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornCalendarResponseToJson(
        TornCalendarResponse instance) =>
    <String, dynamic>{
      'calendar': instance.calendar.toJson(),
    };

TornHof _$TornHofFromJson(Map<String, dynamic> json) => TornHof(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      factionId: (json['faction_id'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      lastAction: (json['last_action'] as num).toInt(),
      rankName: json['rank_name'] as String,
      rankNumber: (json['rank_number'] as num).toInt(),
      position: (json['position'] as num).toInt(),
      signedUp: (json['signed_up'] as num).toInt(),
      ageInDays: (json['age_in_days'] as num).toInt(),
      $value: json['value'],
      rank: json['rank'] as String,
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
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornHofResponseToJson(TornHofResponse instance) =>
    <String, dynamic>{
      'hof': instance.hof.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

FactionHofValues _$FactionHofValuesFromJson(Map<String, dynamic> json) =>
    FactionHofValues(
      chain: json['chain'],
      chainDuration: json['chain_duration'],
      respect: json['respect'],
    );

Map<String, dynamic> _$FactionHofValuesToJson(FactionHofValues instance) =>
    <String, dynamic>{
      'chain': instance.chain,
      'chain_duration': instance.chainDuration,
      'respect': instance.respect,
    };

TornFactionHof _$TornFactionHofFromJson(Map<String, dynamic> json) =>
    TornFactionHof(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      members: (json['members'] as num).toInt(),
      position: (json['position'] as num).toInt(),
      rank: json['rank'] as String,
      values: FactionHofValues.fromJson(json['values'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornFactionHofToJson(TornFactionHof instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'members': instance.members,
      'position': instance.position,
      'rank': instance.rank,
      'values': instance.values.toJson(),
    };

TornFactionHofResponse _$TornFactionHofResponseFromJson(
        Map<String, dynamic> json) =>
    TornFactionHofResponse(
      factionhof: (json['factionhof'] as List<dynamic>?)
              ?.map((e) => TornFactionHof.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornFactionHofResponseToJson(
        TornFactionHofResponse instance) =>
    <String, dynamic>{
      'factionhof': instance.factionhof.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

TornLog _$TornLogFromJson(Map<String, dynamic> json) => TornLog(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
    );

Map<String, dynamic> _$TornLogToJson(TornLog instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
    };

TornLogCategory _$TornLogCategoryFromJson(Map<String, dynamic> json) =>
    TornLogCategory(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
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
      'logtypes': instance.logtypes.map((e) => e.toJson()).toList(),
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
      'logcategories': instance.logcategories.map((e) => e.toJson()).toList(),
    };

Bounty _$BountyFromJson(Map<String, dynamic> json) => Bounty(
      targetId: (json['target_id'] as num).toInt(),
      targetName: json['target_name'] as String,
      targetLevel: (json['target_level'] as num).toInt(),
      listerId: json['lister_id'],
      listerName: json['lister_name'],
      reward: (json['reward'] as num).toInt(),
      reason: json['reason'],
      quantity: (json['quantity'] as num).toInt(),
      isAnonymous: json['is_anonymous'] as bool,
      validUntil: (json['valid_until'] as num).toInt(),
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

AttackLogSummary _$AttackLogSummaryFromJson(Map<String, dynamic> json) =>
    AttackLogSummary(
      id: json['id'],
      name: json['name'],
      hits: (json['hits'] as num).toInt(),
      misses: (json['misses'] as num).toInt(),
      damage: (json['damage'] as num).toInt(),
    );

Map<String, dynamic> _$AttackLogSummaryToJson(AttackLogSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'hits': instance.hits,
      'misses': instance.misses,
      'damage': instance.damage,
    };

AttackLog _$AttackLogFromJson(Map<String, dynamic> json) => AttackLog(
      text: json['text'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      action: attackActionEnumFromJson(json['action']),
      icon: json['icon'] as String,
      attacker: json['attacker'],
      defender: json['defender'],
      attackerItem: json['attacker_item'] == null
          ? null
          : AttackLog$AttackerItem.fromJson(
              json['attacker_item'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttackLogToJson(AttackLog instance) => <String, dynamic>{
      'text': instance.text,
      'timestamp': instance.timestamp,
      'action': attackActionEnumToJson(instance.action),
      'icon': instance.icon,
      'attacker': instance.attacker,
      'defender': instance.defender,
      'attacker_item': instance.attackerItem?.toJson(),
    };

AttackLogResponse _$AttackLogResponseFromJson(Map<String, dynamic> json) =>
    AttackLogResponse(
      attacklog: AttackLogResponse$Attacklog.fromJson(
          json['attacklog'] as Map<String, dynamic>),
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttackLogResponseToJson(AttackLogResponse instance) =>
    <String, dynamic>{
      'attacklog': instance.attacklog.toJson(),
      '_metadata': instance.metadata.toJson(),
    };

TornBountiesResponse _$TornBountiesResponseFromJson(
        Map<String, dynamic> json) =>
    TornBountiesResponse(
      bounties: (json['bounties'] as List<dynamic>?)
              ?.map((e) => Bounty.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: RequestMetadataWithLinks.fromJson(
          json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornBountiesResponseToJson(
        TornBountiesResponse instance) =>
    <String, dynamic>{
      'bounties': instance.bounties.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata.toJson(),
    };

TornItemAmmo _$TornItemAmmoFromJson(Map<String, dynamic> json) => TornItemAmmo(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
      types: tornItemAmmoTypeEnumListFromJson(json['types'] as List?),
    );

Map<String, dynamic> _$TornItemAmmoToJson(TornItemAmmo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'types': tornItemAmmoTypeEnumListToJson(instance.types),
    };

TornItemAmmoResponse _$TornItemAmmoResponseFromJson(
        Map<String, dynamic> json) =>
    TornItemAmmoResponse(
      itemammo: (json['itemammo'] as List<dynamic>?)
              ?.map((e) => TornItemAmmo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornItemAmmoResponseToJson(
        TornItemAmmoResponse instance) =>
    <String, dynamic>{
      'itemammo': instance.itemammo.map((e) => e.toJson()).toList(),
    };

TornItemMods _$TornItemModsFromJson(Map<String, dynamic> json) => TornItemMods(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      dualFit: json['dual_fit'] as bool,
      weapons: tornItemWeaponTypeEnumListFromJson(json['weapons'] as List?),
    );

Map<String, dynamic> _$TornItemModsToJson(TornItemMods instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'dual_fit': instance.dualFit,
      'weapons': tornItemWeaponTypeEnumListToJson(instance.weapons),
    };

TornItemModsResponse _$TornItemModsResponseFromJson(
        Map<String, dynamic> json) =>
    TornItemModsResponse(
      itemmods: (json['itemmods'] as List<dynamic>?)
              ?.map((e) => TornItemMods.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornItemModsResponseToJson(
        TornItemModsResponse instance) =>
    <String, dynamic>{
      'itemmods': instance.itemmods.map((e) => e.toJson()).toList(),
    };

TornItemBaseStats _$TornItemBaseStatsFromJson(Map<String, dynamic> json) =>
    TornItemBaseStats(
      damage: (json['damage'] as num).toInt(),
      accuracy: (json['accuracy'] as num).toInt(),
      armor: (json['armor'] as num).toInt(),
    );

Map<String, dynamic> _$TornItemBaseStatsToJson(TornItemBaseStats instance) =>
    <String, dynamic>{
      'damage': instance.damage,
      'accuracy': instance.accuracy,
      'armor': instance.armor,
    };

TornItemWeaponDetails _$TornItemWeaponDetailsFromJson(
        Map<String, dynamic> json) =>
    TornItemWeaponDetails(
      stealthLevel: (json['stealth_level'] as num).toDouble(),
      baseStats: TornItemBaseStats.fromJson(
          json['base_stats'] as Map<String, dynamic>),
      category: tornItemWeaponCategoryEnumFromJson(json['category']),
      ammo: json['ammo'],
      mods: (json['mods'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornItemWeaponDetailsToJson(
        TornItemWeaponDetails instance) =>
    <String, dynamic>{
      'stealth_level': instance.stealthLevel,
      'base_stats': instance.baseStats.toJson(),
      'category': tornItemWeaponCategoryEnumToJson(instance.category),
      'ammo': instance.ammo,
      'mods': instance.mods,
    };

TornItemArmorCoverage _$TornItemArmorCoverageFromJson(
        Map<String, dynamic> json) =>
    TornItemArmorCoverage(
      name: tornItemArmorCoveragePartEnumFromJson(json['name']),
      $value: (json['value'] as num).toDouble(),
    );

Map<String, dynamic> _$TornItemArmorCoverageToJson(
        TornItemArmorCoverage instance) =>
    <String, dynamic>{
      'name': tornItemArmorCoveragePartEnumToJson(instance.name),
      'value': instance.$value,
    };

TornItemArmorDetails _$TornItemArmorDetailsFromJson(
        Map<String, dynamic> json) =>
    TornItemArmorDetails(
      coverage: (json['coverage'] as List<dynamic>?)
              ?.map((e) =>
                  TornItemArmorCoverage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      baseStats: TornItemBaseStats.fromJson(
          json['base_stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornItemArmorDetailsToJson(
        TornItemArmorDetails instance) =>
    <String, dynamic>{
      'coverage': instance.coverage.map((e) => e.toJson()).toList(),
      'base_stats': instance.baseStats.toJson(),
    };

TornItem _$TornItemFromJson(Map<String, dynamic> json) => TornItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      effect: json['effect'],
      requirement: json['requirement'],
      image: json['image'] as String,
      type: tornItemTypeEnumFromJson(json['type']),
      subType: json['sub_type'],
      isMasked: json['is_masked'] as bool,
      isTradable: json['is_tradable'] as bool,
      isFoundInCity: json['is_found_in_city'] as bool,
      $value: TornItem$Value.fromJson(json['value'] as Map<String, dynamic>),
      circulation: (json['circulation'] as num).toInt(),
      details: json['details'],
    );

Map<String, dynamic> _$TornItemToJson(TornItem instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'effect': instance.effect,
      'requirement': instance.requirement,
      'image': instance.image,
      'type': tornItemTypeEnumToJson(instance.type),
      'sub_type': instance.subType,
      'is_masked': instance.isMasked,
      'is_tradable': instance.isTradable,
      'is_found_in_city': instance.isFoundInCity,
      'value': instance.$value.toJson(),
      'circulation': instance.circulation,
      'details': instance.details,
    };

TornItemsResponse _$TornItemsResponseFromJson(Map<String, dynamic> json) =>
    TornItemsResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TornItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornItemsResponseToJson(TornItemsResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

TornFactionTreeBranch _$TornFactionTreeBranchFromJson(
        Map<String, dynamic> json) =>
    TornFactionTreeBranch(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      upgrades: (json['upgrades'] as List<dynamic>)
          .map((e) => TornFactionTreeBranch$Upgrades$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TornFactionTreeBranchToJson(
        TornFactionTreeBranch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'upgrades': instance.upgrades.map((e) => e.toJson()).toList(),
    };

TornFactionTree _$TornFactionTreeFromJson(Map<String, dynamic> json) =>
    TornFactionTree(
      name: json['name'] as String,
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) =>
                  TornFactionTreeBranch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornFactionTreeToJson(TornFactionTree instance) =>
    <String, dynamic>{
      'name': instance.name,
      'branches': instance.branches.map((e) => e.toJson()).toList(),
    };

TornFactionTreeResponse _$TornFactionTreeResponseFromJson(
        Map<String, dynamic> json) =>
    TornFactionTreeResponse(
      factionTree: (json['factionTree'] as List<dynamic>?)
              ?.map((e) => TornFactionTree.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornFactionTreeResponseToJson(
        TornFactionTreeResponse instance) =>
    <String, dynamic>{
      'factionTree': instance.factionTree.map((e) => e.toJson()).toList(),
    };

TornSelectionName _$TornSelectionNameFromJson(Map<String, dynamic> json) =>
    TornSelectionName();

Map<String, dynamic> _$TornSelectionNameToJson(TornSelectionName instance) =>
    <String, dynamic>{};

TornLookupResponse _$TornLookupResponseFromJson(Map<String, dynamic> json) =>
    TornLookupResponse(
      selections: (json['selections'] as List<dynamic>?)
              ?.map(
                  (e) => TornSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornLookupResponseToJson(TornLookupResponse instance) =>
    <String, dynamic>{
      'selections': instance.selections.map((e) => e.toJson()).toList(),
    };

Attack$Modifiers _$Attack$ModifiersFromJson(Map<String, dynamic> json) =>
    Attack$Modifiers(
      fairFight: (json['fair_fight'] as num).toDouble(),
      war: (json['war'] as num).toDouble(),
      retaliation: (json['retaliation'] as num).toDouble(),
      group: (json['group'] as num).toDouble(),
      overseas: (json['overseas'] as num).toDouble(),
      chain: (json['chain'] as num).toDouble(),
      warlord: (json['warlord'] as num).toDouble(),
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

ReviveSimplified$Reviver _$ReviveSimplified$ReviverFromJson(
        Map<String, dynamic> json) =>
    ReviveSimplified$Reviver(
      id: (json['id'] as num).toInt(),
      factionId: json['faction_id'],
    );

Map<String, dynamic> _$ReviveSimplified$ReviverToJson(
        ReviveSimplified$Reviver instance) =>
    <String, dynamic>{
      'id': instance.id,
      'faction_id': instance.factionId,
    };

ReviveSimplified$Target _$ReviveSimplified$TargetFromJson(
        Map<String, dynamic> json) =>
    ReviveSimplified$Target(
      id: (json['id'] as num).toInt(),
      factionId: json['faction_id'],
      hospitalReason: json['hospital_reason'] as String,
      earlyDischarge: json['early_discharge'] as bool,
      lastAction: (json['last_action'] as num).toInt(),
      onlineStatus: json['online_status'] as String,
    );

Map<String, dynamic> _$ReviveSimplified$TargetToJson(
        ReviveSimplified$Target instance) =>
    <String, dynamic>{
      'id': instance.id,
      'faction_id': instance.factionId,
      'hospital_reason': instance.hospitalReason,
      'early_discharge': instance.earlyDischarge,
      'last_action': instance.lastAction,
      'online_status': instance.onlineStatus,
    };

Revive$Reviver _$Revive$ReviverFromJson(Map<String, dynamic> json) =>
    Revive$Reviver(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      faction: json['faction'],
      skill: json['skill'],
    );

Map<String, dynamic> _$Revive$ReviverToJson(Revive$Reviver instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'faction': instance.faction,
      'skill': instance.skill,
    };

Revive$Target _$Revive$TargetFromJson(Map<String, dynamic> json) =>
    Revive$Target(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      faction: json['faction'],
      hospitalReason: json['hospital_reason'] as String,
      earlyDischarge: json['early_discharge'] as bool,
      lastAction: (json['last_action'] as num).toInt(),
      onlineStatus: json['online_status'] as String,
    );

Map<String, dynamic> _$Revive$TargetToJson(Revive$Target instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'faction': instance.faction,
      'hospital_reason': instance.hospitalReason,
      'early_discharge': instance.earlyDischarge,
      'last_action': instance.lastAction,
      'online_status': instance.onlineStatus,
    };

ReportCompanyFinancials$Wages _$ReportCompanyFinancials$WagesFromJson(
        Map<String, dynamic> json) =>
    ReportCompanyFinancials$Wages(
      highest: (json['highest'] as num).toInt(),
      lowest: (json['lowest'] as num).toInt(),
      average: (json['average'] as num).toInt(),
    );

Map<String, dynamic> _$ReportCompanyFinancials$WagesToJson(
        ReportCompanyFinancials$Wages instance) =>
    <String, dynamic>{
      'highest': instance.highest,
      'lowest': instance.lowest,
      'average': instance.average,
    };

ReportStockAnalysis$Items$Item _$ReportStockAnalysis$Items$ItemFromJson(
        Map<String, dynamic> json) =>
    ReportStockAnalysis$Items$Item(
      country: countryEnumFromJson(json['country']),
      item: ReportStockAnalysis$Items$Item$Item.fromJson(
          json['item'] as Map<String, dynamic>),
      tripDuration: (json['trip_duration'] as num).toInt(),
      hourlyProfit: (json['hourly_profit'] as num).toInt(),
    );

Map<String, dynamic> _$ReportStockAnalysis$Items$ItemToJson(
        ReportStockAnalysis$Items$Item instance) =>
    <String, dynamic>{
      'country': countryEnumToJson(instance.country),
      'item': instance.item.toJson(),
      'trip_duration': instance.tripDuration,
      'hourly_profit': instance.hourlyProfit,
    };

ReportAnonymousBounties$Bounties$Item
    _$ReportAnonymousBounties$Bounties$ItemFromJson(
            Map<String, dynamic> json) =>
        ReportAnonymousBounties$Bounties$Item(
          text: json['text'] as String,
          bounty: (json['bounty'] as num).toInt(),
          user: json['user'],
        );

Map<String, dynamic> _$ReportAnonymousBounties$Bounties$ItemToJson(
        ReportAnonymousBounties$Bounties$Item instance) =>
    <String, dynamic>{
      'text': instance.text,
      'bounty': instance.bounty,
      'user': instance.user,
    };

UserPropertyBasicDetails$Upkeep _$UserPropertyBasicDetails$UpkeepFromJson(
        Map<String, dynamic> json) =>
    UserPropertyBasicDetails$Upkeep(
      property: (json['property'] as num).toInt(),
      staff: (json['staff'] as num).toInt(),
    );

Map<String, dynamic> _$UserPropertyBasicDetails$UpkeepToJson(
        UserPropertyBasicDetails$Upkeep instance) =>
    <String, dynamic>{
      'property': instance.property,
      'staff': instance.staff,
    };

UserPropertyBasicDetails$Staff$Item
    _$UserPropertyBasicDetails$Staff$ItemFromJson(Map<String, dynamic> json) =>
        UserPropertyBasicDetails$Staff$Item(
          type: propertyStaffEnumFromJson(json['type']),
          amount: (json['amount'] as num).toInt(),
        );

Map<String, dynamic> _$UserPropertyBasicDetails$Staff$ItemToJson(
        UserPropertyBasicDetails$Staff$Item instance) =>
    <String, dynamic>{
      'type': propertyStaffEnumToJson(instance.type),
      'amount': instance.amount,
    };

UserPropertyDetailsExtended$Upkeep _$UserPropertyDetailsExtended$UpkeepFromJson(
        Map<String, dynamic> json) =>
    UserPropertyDetailsExtended$Upkeep(
      property: (json['property'] as num).toInt(),
      staff: (json['staff'] as num).toInt(),
    );

Map<String, dynamic> _$UserPropertyDetailsExtended$UpkeepToJson(
        UserPropertyDetailsExtended$Upkeep instance) =>
    <String, dynamic>{
      'property': instance.property,
      'staff': instance.staff,
    };

UserPropertyDetailsExtended$Staff$Item
    _$UserPropertyDetailsExtended$Staff$ItemFromJson(
            Map<String, dynamic> json) =>
        UserPropertyDetailsExtended$Staff$Item(
          type: propertyStaffEnumFromJson(json['type']),
          amount: (json['amount'] as num).toInt(),
        );

Map<String, dynamic> _$UserPropertyDetailsExtended$Staff$ItemToJson(
        UserPropertyDetailsExtended$Staff$Item instance) =>
    <String, dynamic>{
      'type': propertyStaffEnumToJson(instance.type),
      'amount': instance.amount,
    };

UserPropertyDetails$Upkeep _$UserPropertyDetails$UpkeepFromJson(
        Map<String, dynamic> json) =>
    UserPropertyDetails$Upkeep(
      property: (json['property'] as num).toInt(),
      staff: (json['staff'] as num).toInt(),
    );

Map<String, dynamic> _$UserPropertyDetails$UpkeepToJson(
        UserPropertyDetails$Upkeep instance) =>
    <String, dynamic>{
      'property': instance.property,
      'staff': instance.staff,
    };

UserPropertyDetails$Staff$Item _$UserPropertyDetails$Staff$ItemFromJson(
        Map<String, dynamic> json) =>
    UserPropertyDetails$Staff$Item(
      type: propertyStaffEnumFromJson(json['type']),
      amount: (json['amount'] as num).toInt(),
    );

Map<String, dynamic> _$UserPropertyDetails$Staff$ItemToJson(
        UserPropertyDetails$Staff$Item instance) =>
    <String, dynamic>{
      'type': propertyStaffEnumToJson(instance.type),
      'amount': instance.amount,
    };

UserPropertyDetailsExtendedRented$Upkeep
    _$UserPropertyDetailsExtendedRented$UpkeepFromJson(
            Map<String, dynamic> json) =>
        UserPropertyDetailsExtendedRented$Upkeep(
          property: (json['property'] as num).toInt(),
          staff: (json['staff'] as num).toInt(),
        );

Map<String, dynamic> _$UserPropertyDetailsExtendedRented$UpkeepToJson(
        UserPropertyDetailsExtendedRented$Upkeep instance) =>
    <String, dynamic>{
      'property': instance.property,
      'staff': instance.staff,
    };

UserPropertyDetailsExtendedRented$Staff$Item
    _$UserPropertyDetailsExtendedRented$Staff$ItemFromJson(
            Map<String, dynamic> json) =>
        UserPropertyDetailsExtendedRented$Staff$Item(
          type: propertyStaffEnumFromJson(json['type']),
          amount: (json['amount'] as num).toInt(),
        );

Map<String, dynamic> _$UserPropertyDetailsExtendedRented$Staff$ItemToJson(
        UserPropertyDetailsExtendedRented$Staff$Item instance) =>
    <String, dynamic>{
      'type': propertyStaffEnumToJson(instance.type),
      'amount': instance.amount,
    };

UserPropertyDetailsExtendedForRent$Upkeep
    _$UserPropertyDetailsExtendedForRent$UpkeepFromJson(
            Map<String, dynamic> json) =>
        UserPropertyDetailsExtendedForRent$Upkeep(
          property: (json['property'] as num).toInt(),
          staff: (json['staff'] as num).toInt(),
        );

Map<String, dynamic> _$UserPropertyDetailsExtendedForRent$UpkeepToJson(
        UserPropertyDetailsExtendedForRent$Upkeep instance) =>
    <String, dynamic>{
      'property': instance.property,
      'staff': instance.staff,
    };

UserPropertyDetailsExtendedForRent$Staff$Item
    _$UserPropertyDetailsExtendedForRent$Staff$ItemFromJson(
            Map<String, dynamic> json) =>
        UserPropertyDetailsExtendedForRent$Staff$Item(
          type: propertyStaffEnumFromJson(json['type']),
          amount: (json['amount'] as num).toInt(),
        );

Map<String, dynamic> _$UserPropertyDetailsExtendedForRent$Staff$ItemToJson(
        UserPropertyDetailsExtendedForRent$Staff$Item instance) =>
    <String, dynamic>{
      'type': propertyStaffEnumToJson(instance.type),
      'amount': instance.amount,
    };

UserPropertyDetailsExtendedForSale$Upkeep
    _$UserPropertyDetailsExtendedForSale$UpkeepFromJson(
            Map<String, dynamic> json) =>
        UserPropertyDetailsExtendedForSale$Upkeep(
          property: (json['property'] as num).toInt(),
          staff: (json['staff'] as num).toInt(),
        );

Map<String, dynamic> _$UserPropertyDetailsExtendedForSale$UpkeepToJson(
        UserPropertyDetailsExtendedForSale$Upkeep instance) =>
    <String, dynamic>{
      'property': instance.property,
      'staff': instance.staff,
    };

UserPropertyDetailsExtendedForSale$Staff$Item
    _$UserPropertyDetailsExtendedForSale$Staff$ItemFromJson(
            Map<String, dynamic> json) =>
        UserPropertyDetailsExtendedForSale$Staff$Item(
          type: propertyStaffEnumFromJson(json['type']),
          amount: (json['amount'] as num).toInt(),
        );

Map<String, dynamic> _$UserPropertyDetailsExtendedForSale$Staff$ItemToJson(
        UserPropertyDetailsExtendedForSale$Staff$Item instance) =>
    <String, dynamic>{
      'type': propertyStaffEnumToJson(instance.type),
      'amount': instance.amount,
    };

UserCrimeDetailsBootlegging$OnlineStore
    _$UserCrimeDetailsBootlegging$OnlineStoreFromJson(
            Map<String, dynamic> json) =>
        UserCrimeDetailsBootlegging$OnlineStore(
          earnings: (json['earnings'] as num).toInt(),
          visits: (json['visits'] as num).toInt(),
          customers: (json['customers'] as num).toInt(),
          sales: (json['sales'] as num).toInt(),
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
          action: (json['action'] as num).toInt(),
          comedy: (json['comedy'] as num).toInt(),
          drama: (json['drama'] as num).toInt(),
          fantasy: (json['fantasy'] as num).toInt(),
          horror: (json['horror'] as num).toInt(),
          romance: (json['romance'] as num).toInt(),
          thriller: (json['thriller'] as num).toInt(),
          sciFi: (json['sci_fi'] as num).toInt(),
          total: (json['total'] as num).toInt(),
          earnings: (json['earnings'] as num).toInt(),
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
      'sci_fi': instance.sciFi,
      'total': instance.total,
      'earnings': instance.earnings,
    };

UserCrimeDetailsCardSkimming$CardDetails
    _$UserCrimeDetailsCardSkimming$CardDetailsFromJson(
            Map<String, dynamic> json) =>
        UserCrimeDetailsCardSkimming$CardDetails(
          recoverable: (json['recoverable'] as num).toInt(),
          recovered: (json['recovered'] as num).toInt(),
          sold: (json['sold'] as num).toInt(),
          lost: (json['lost'] as num).toInt(),
          areas: (json['areas'] as List<dynamic>)
              .map((e) =>
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
      'areas': instance.areas.map((e) => e.toJson()).toList(),
    };

UserCrimeDetailsCardSkimming$Skimmers
    _$UserCrimeDetailsCardSkimming$SkimmersFromJson(
            Map<String, dynamic> json) =>
        UserCrimeDetailsCardSkimming$Skimmers(
          active: (json['active'] as num).toInt(),
          mostLucrative: (json['most_lucrative'] as num).toInt(),
          oldestRecovered: (json['oldest_recovered'] as num).toInt(),
          lost: (json['lost'] as num).toInt(),
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
      red: (json['red'] as num).toInt(),
      neutral: (json['neutral'] as num).toInt(),
      concern: (json['concern'] as num).toInt(),
      sensitivity: (json['sensitivity'] as num).toInt(),
      temptation: (json['temptation'] as num).toInt(),
      hesitation: (json['hesitation'] as num).toInt(),
      lowReward: (json['low_reward'] as num).toInt(),
      mediumReward: (json['medium_reward'] as num).toInt(),
      highReward: (json['high_reward'] as num).toInt(),
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
      attempts: (json['attempts'] as num).toInt(),
      resolved: (json['resolved'] as num).toInt(),
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
      low: (json['low'] as num).toInt(),
      medium: (json['medium'] as num).toInt(),
      high: (json['high'] as num).toInt(),
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
      scraper: (json['scraper'] as num).toInt(),
      phisher: (json['phisher'] as num).toInt(),
    );

Map<String, dynamic> _$UserCrimeDetailsScamming$EmailsToJson(
        UserCrimeDetailsScamming$Emails instance) =>
    <String, dynamic>{
      'scraper': instance.scraper,
      'phisher': instance.phisher,
    };

PersonalStatsOther$Other _$PersonalStatsOther$OtherFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOther$Other(
      activity: PersonalStatsOther$Other$Activity.fromJson(
          json['activity'] as Map<String, dynamic>),
      awards: (json['awards'] as num).toInt(),
      meritsBought: (json['merits_bought'] as num).toInt(),
      refills: PersonalStatsOther$Other$Refills.fromJson(
          json['refills'] as Map<String, dynamic>),
      donatorDays: (json['donator_days'] as num).toInt(),
      rankedWarWins: (json['ranked_war_wins'] as num).toInt(),
    );

Map<String, dynamic> _$PersonalStatsOther$OtherToJson(
        PersonalStatsOther$Other instance) =>
    <String, dynamic>{
      'activity': instance.activity.toJson(),
      'awards': instance.awards,
      'merits_bought': instance.meritsBought,
      'refills': instance.refills.toJson(),
      'donator_days': instance.donatorDays,
      'ranked_war_wins': instance.rankedWarWins,
    };

PersonalStatsOtherPopular$Other _$PersonalStatsOtherPopular$OtherFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOtherPopular$Other(
      activity: PersonalStatsOtherPopular$Other$Activity.fromJson(
          json['activity'] as Map<String, dynamic>),
      awards: (json['awards'] as num).toInt(),
      meritsBought: (json['merits_bought'] as num).toInt(),
      refills: PersonalStatsOtherPopular$Other$Refills.fromJson(
          json['refills'] as Map<String, dynamic>),
      donatorDays: (json['donator_days'] as num).toInt(),
      rankedWarWins: (json['ranked_war_wins'] as num).toInt(),
    );

Map<String, dynamic> _$PersonalStatsOtherPopular$OtherToJson(
        PersonalStatsOtherPopular$Other instance) =>
    <String, dynamic>{
      'activity': instance.activity.toJson(),
      'awards': instance.awards,
      'merits_bought': instance.meritsBought,
      'refills': instance.refills.toJson(),
      'donator_days': instance.donatorDays,
      'ranked_war_wins': instance.rankedWarWins,
    };

PersonalStatsNetworthExtended$Networth
    _$PersonalStatsNetworthExtended$NetworthFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsNetworthExtended$Networth(
          total: (json['total'] as num).toInt(),
          wallet: (json['wallet'] as num).toInt(),
          vaults: (json['vaults'] as num).toInt(),
          bank: (json['bank'] as num).toInt(),
          overseasBank: (json['overseas_bank'] as num).toInt(),
          points: (json['points'] as num).toInt(),
          inventory: (json['inventory'] as num).toInt(),
          displayCase: (json['display_case'] as num).toInt(),
          bazaar: (json['bazaar'] as num).toInt(),
          itemMarket: (json['item_market'] as num).toInt(),
          property: (json['property'] as num).toInt(),
          stockMarket: (json['stock_market'] as num).toInt(),
          auctionHouse: (json['auction_house'] as num).toInt(),
          bookie: (json['bookie'] as num).toInt(),
          company: (json['company'] as num).toInt(),
          enlistedCars: (json['enlisted_cars'] as num).toInt(),
          piggyBank: (json['piggy_bank'] as num).toInt(),
          pending: (json['pending'] as num).toInt(),
          loans: (json['loans'] as num).toInt(),
          unpaidFees: (json['unpaid_fees'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
        );

Map<String, dynamic> _$PersonalStatsNetworthPublic$NetworthToJson(
        PersonalStatsNetworthPublic$Networth instance) =>
    <String, dynamic>{
      'total': instance.total,
    };

PersonalStatsRacing$Racing _$PersonalStatsRacing$RacingFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsRacing$Racing(
      skill: (json['skill'] as num).toInt(),
      points: (json['points'] as num).toInt(),
      races: PersonalStatsRacing$Racing$Races.fromJson(
          json['races'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsRacing$RacingToJson(
        PersonalStatsRacing$Racing instance) =>
    <String, dynamic>{
      'skill': instance.skill,
      'points': instance.points,
      'races': instance.races.toJson(),
    };

PersonalStatsMissions$Missions _$PersonalStatsMissions$MissionsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsMissions$Missions(
      missions: (json['missions'] as num).toInt(),
      contracts: PersonalStatsMissions$Missions$Contracts.fromJson(
          json['contracts'] as Map<String, dynamic>),
      credits: (json['credits'] as num).toInt(),
    );

Map<String, dynamic> _$PersonalStatsMissions$MissionsToJson(
        PersonalStatsMissions$Missions instance) =>
    <String, dynamic>{
      'missions': instance.missions,
      'contracts': instance.contracts.toJson(),
      'credits': instance.credits,
    };

PersonalStatsDrugs$Drugs _$PersonalStatsDrugs$DrugsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsDrugs$Drugs(
      cannabis: (json['cannabis'] as num).toInt(),
      ecstasy: (json['ecstasy'] as num).toInt(),
      ketamine: (json['ketamine'] as num).toInt(),
      lsd: (json['lsd'] as num).toInt(),
      opium: (json['opium'] as num).toInt(),
      pcp: (json['pcp'] as num).toInt(),
      shrooms: (json['shrooms'] as num).toInt(),
      speed: (json['speed'] as num).toInt(),
      vicodin: (json['vicodin'] as num).toInt(),
      xanax: (json['xanax'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      overdoses: (json['overdoses'] as num).toInt(),
      rehabilitations: PersonalStatsDrugs$Drugs$Rehabilitations.fromJson(
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
      'rehabilitations': instance.rehabilitations.toJson(),
    };

PersonalStatsTravel$Travel _$PersonalStatsTravel$TravelFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTravel$Travel(
      total: (json['total'] as num).toInt(),
      timeSpent: (json['time_spent'] as num).toInt(),
      itemsBought: (json['items_bought'] as num).toInt(),
      hunting: PersonalStatsTravel$Travel$Hunting.fromJson(
          json['hunting'] as Map<String, dynamic>),
      attacksWon: (json['attacks_won'] as num).toInt(),
      defendsLost: (json['defends_lost'] as num).toInt(),
      argentina: (json['argentina'] as num).toInt(),
      canada: (json['canada'] as num).toInt(),
      caymanIslands: (json['cayman_islands'] as num).toInt(),
      china: (json['china'] as num).toInt(),
      hawaii: (json['hawaii'] as num).toInt(),
      japan: (json['japan'] as num).toInt(),
      mexico: (json['mexico'] as num).toInt(),
      unitedArabEmirates: (json['united_arab_emirates'] as num).toInt(),
      unitedKingdom: (json['united_kingdom'] as num).toInt(),
      southAfrica: (json['south_africa'] as num).toInt(),
      switzerland: (json['switzerland'] as num).toInt(),
    );

Map<String, dynamic> _$PersonalStatsTravel$TravelToJson(
        PersonalStatsTravel$Travel instance) =>
    <String, dynamic>{
      'total': instance.total,
      'time_spent': instance.timeSpent,
      'items_bought': instance.itemsBought,
      'hunting': instance.hunting.toJson(),
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
      total: (json['total'] as num).toInt(),
      timeSpent: (json['time_spent'] as num).toInt(),
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
      found: PersonalStatsItems$Items$Found.fromJson(
          json['found'] as Map<String, dynamic>),
      trashed: (json['trashed'] as num).toInt(),
      used: PersonalStatsItems$Items$Used.fromJson(
          json['used'] as Map<String, dynamic>),
      virusesCoded: (json['viruses_coded'] as num).toInt(),
    );

Map<String, dynamic> _$PersonalStatsItems$ItemsToJson(
        PersonalStatsItems$Items instance) =>
    <String, dynamic>{
      'found': instance.found.toJson(),
      'trashed': instance.trashed,
      'used': instance.used.toJson(),
      'viruses_coded': instance.virusesCoded,
    };

PersonalStatsItemsPopular$Items _$PersonalStatsItemsPopular$ItemsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsItemsPopular$Items(
      found: PersonalStatsItemsPopular$Items$Found.fromJson(
          json['found'] as Map<String, dynamic>),
      used: PersonalStatsItemsPopular$Items$Used.fromJson(
          json['used'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsItemsPopular$ItemsToJson(
        PersonalStatsItemsPopular$Items instance) =>
    <String, dynamic>{
      'found': instance.found.toJson(),
      'used': instance.used.toJson(),
    };

PersonalStatsInvestments$Investments
    _$PersonalStatsInvestments$InvestmentsFromJson(Map<String, dynamic> json) =>
        PersonalStatsInvestments$Investments(
          bank: PersonalStatsInvestments$Investments$Bank.fromJson(
              json['bank'] as Map<String, dynamic>),
          stocks: PersonalStatsInvestments$Investments$Stocks.fromJson(
              json['stocks'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsInvestments$InvestmentsToJson(
        PersonalStatsInvestments$Investments instance) =>
    <String, dynamic>{
      'bank': instance.bank.toJson(),
      'stocks': instance.stocks.toJson(),
    };

PersonalStatsBounties$Bounties _$PersonalStatsBounties$BountiesFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsBounties$Bounties(
      placed: PersonalStatsBounties$Bounties$Placed.fromJson(
          json['placed'] as Map<String, dynamic>),
      collected: PersonalStatsBounties$Bounties$Collected.fromJson(
          json['collected'] as Map<String, dynamic>),
      received: PersonalStatsBounties$Bounties$Received.fromJson(
          json['received'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsBounties$BountiesToJson(
        PersonalStatsBounties$Bounties instance) =>
    <String, dynamic>{
      'placed': instance.placed.toJson(),
      'collected': instance.collected.toJson(),
      'received': instance.received.toJson(),
    };

PersonalStatsCrimesV2$Offenses _$PersonalStatsCrimesV2$OffensesFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsCrimesV2$Offenses(
      vandalism: (json['vandalism'] as num).toInt(),
      fraud: (json['fraud'] as num).toInt(),
      theft: (json['theft'] as num).toInt(),
      counterfeiting: (json['counterfeiting'] as num).toInt(),
      illicitServices: (json['illicit_services'] as num).toInt(),
      cybercrime: (json['cybercrime'] as num).toInt(),
      extortion: (json['extortion'] as num).toInt(),
      illegalProduction: (json['illegal_production'] as num).toInt(),
      organizedCrimes: (json['organized_crimes'] as num).toInt(),
      total: (json['total'] as num).toInt(),
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
      searchForCash: (json['search_for_cash'] as num).toInt(),
      bootlegging: (json['bootlegging'] as num).toInt(),
      graffiti: (json['graffiti'] as num).toInt(),
      shoplifting: (json['shoplifting'] as num).toInt(),
      pickpocketing: (json['pickpocketing'] as num).toInt(),
      cardSkimming: (json['card_skimming'] as num).toInt(),
      burglary: (json['burglary'] as num).toInt(),
      hustling: (json['hustling'] as num).toInt(),
      disposal: (json['disposal'] as num).toInt(),
      cracking: (json['cracking'] as num).toInt(),
      forgery: (json['forgery'] as num).toInt(),
      scamming: (json['scamming'] as num).toInt(),
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
      total: (json['total'] as num).toInt(),
      version: json['version'] as String,
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
          mailsSent:
              PersonalStatsCommunication$Communication$MailsSent.fromJson(
                  json['mails_sent'] as Map<String, dynamic>),
          classifiedAds: (json['classified_ads'] as num).toInt(),
          personals: (json['personals'] as num).toInt(),
        );

Map<String, dynamic> _$PersonalStatsCommunication$CommunicationToJson(
        PersonalStatsCommunication$Communication instance) =>
    <String, dynamic>{
      'mails_sent': instance.mailsSent.toJson(),
      'classified_ads': instance.classifiedAds,
      'personals': instance.personals,
    };

PersonalStatsFinishingHits$FinishingHits
    _$PersonalStatsFinishingHits$FinishingHitsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsFinishingHits$FinishingHits(
          heavyArtillery: (json['heavy_artillery'] as num).toInt(),
          machineGuns: (json['machine_guns'] as num).toInt(),
          rifles: (json['rifles'] as num).toInt(),
          subMachineGuns: (json['sub_machine_guns'] as num).toInt(),
          shotguns: (json['shotguns'] as num).toInt(),
          pistols: (json['pistols'] as num).toInt(),
          temporary: (json['temporary'] as num).toInt(),
          piercing: (json['piercing'] as num).toInt(),
          slashing: (json['slashing'] as num).toInt(),
          clubbing: (json['clubbing'] as num).toInt(),
          mechanical: (json['mechanical'] as num).toInt(),
          handToHand: (json['hand_to_hand'] as num).toInt(),
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
      timesHospitalized: (json['times_hospitalized'] as num).toInt(),
      medicalItemsUsed: (json['medical_items_used'] as num).toInt(),
      bloodWithdrawn: (json['blood_withdrawn'] as num).toInt(),
      reviving: PersonalStatsHospital$Hospital$Reviving.fromJson(
          json['reviving'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsHospital$HospitalToJson(
        PersonalStatsHospital$Hospital instance) =>
    <String, dynamic>{
      'times_hospitalized': instance.timesHospitalized,
      'medical_items_used': instance.medicalItemsUsed,
      'blood_withdrawn': instance.bloodWithdrawn,
      'reviving': instance.reviving.toJson(),
    };

PersonalStatsHospitalPopular$Hospital
    _$PersonalStatsHospitalPopular$HospitalFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsHospitalPopular$Hospital(
          medicalItemsUsed: (json['medical_items_used'] as num).toInt(),
          reviving: PersonalStatsHospitalPopular$Hospital$Reviving.fromJson(
              json['reviving'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsHospitalPopular$HospitalToJson(
        PersonalStatsHospitalPopular$Hospital instance) =>
    <String, dynamic>{
      'medical_items_used': instance.medicalItemsUsed,
      'reviving': instance.reviving.toJson(),
    };

PersonalStatsJail$Jail _$PersonalStatsJail$JailFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJail$Jail(
      timesJailed: (json['times_jailed'] as num).toInt(),
      busts: PersonalStatsJail$Jail$Busts.fromJson(
          json['busts'] as Map<String, dynamic>),
      bails: PersonalStatsJail$Jail$Bails.fromJson(
          json['bails'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJail$JailToJson(
        PersonalStatsJail$Jail instance) =>
    <String, dynamic>{
      'times_jailed': instance.timesJailed,
      'busts': instance.busts.toJson(),
      'bails': instance.bails.toJson(),
    };

PersonalStatsTrading$Trading _$PersonalStatsTrading$TradingFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsTrading$Trading(
      items: PersonalStatsTrading$Trading$Items.fromJson(
          json['items'] as Map<String, dynamic>),
      trades: (json['trades'] as num).toInt(),
      points: PersonalStatsTrading$Trading$Points.fromJson(
          json['points'] as Map<String, dynamic>),
      bazaar: PersonalStatsTrading$Trading$Bazaar.fromJson(
          json['bazaar'] as Map<String, dynamic>),
      itemMarket: json['item_market'] == null
          ? null
          : PersonalStatsTrading$Trading$ItemMarket.fromJson(
              json['item_market'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsTrading$TradingToJson(
        PersonalStatsTrading$Trading instance) =>
    <String, dynamic>{
      'items': instance.items.toJson(),
      'trades': instance.trades,
      'points': instance.points.toJson(),
      'bazaar': instance.bazaar.toJson(),
      'item_market': instance.itemMarket?.toJson(),
    };

PersonalStatsJobsPublic$Jobs _$PersonalStatsJobsPublic$JobsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsJobsPublic$Jobs(
      jobPointsUsed: (json['job_points_used'] as num).toInt(),
      trainsReceived: (json['trains_received'] as num).toInt(),
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
      jobPointsUsed: (json['job_points_used'] as num).toInt(),
      trainsReceived: (json['trains_received'] as num).toInt(),
      stats: PersonalStatsJobsExtended$Jobs$Stats.fromJson(
          json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsJobsExtended$JobsToJson(
        PersonalStatsJobsExtended$Jobs instance) =>
    <String, dynamic>{
      'job_points_used': instance.jobPointsUsed,
      'trains_received': instance.trainsReceived,
      'stats': instance.stats.toJson(),
    };

PersonalStatsBattleStats$BattleStats
    _$PersonalStatsBattleStats$BattleStatsFromJson(Map<String, dynamic> json) =>
        PersonalStatsBattleStats$BattleStats(
          strength: (json['strength'] as num).toInt(),
          defense: (json['defense'] as num).toInt(),
          speed: (json['speed'] as num).toInt(),
          dexterity: (json['dexterity'] as num).toInt(),
          total: (json['total'] as num).toInt(),
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
          attacks: PersonalStatsAttackingPublic$Attacking$Attacks.fromJson(
              json['attacks'] as Map<String, dynamic>),
          defends: PersonalStatsAttackingPublic$Attacking$Defends.fromJson(
              json['defends'] as Map<String, dynamic>),
          elo: (json['elo'] as num).toInt(),
          unarmoredWins: (json['unarmored_wins'] as num).toInt(),
          highestLevelBeaten: (json['highest_level_beaten'] as num).toInt(),
          escapes: json['escapes'] == null
              ? null
              : PersonalStatsAttackingPublic$Attacking$Escapes.fromJson(
                  json['escapes'] as Map<String, dynamic>),
          killstreak:
              PersonalStatsAttackingPublic$Attacking$Killstreak.fromJson(
                  json['killstreak'] as Map<String, dynamic>),
          hits: PersonalStatsAttackingPublic$Attacking$Hits.fromJson(
              json['hits'] as Map<String, dynamic>),
          damage: PersonalStatsAttackingPublic$Attacking$Damage.fromJson(
              json['damage'] as Map<String, dynamic>),
          networth: PersonalStatsAttackingPublic$Attacking$Networth.fromJson(
              json['networth'] as Map<String, dynamic>),
          ammunition:
              PersonalStatsAttackingPublic$Attacking$Ammunition.fromJson(
                  json['ammunition'] as Map<String, dynamic>),
          faction: PersonalStatsAttackingPublic$Attacking$Faction.fromJson(
              json['faction'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$AttackingToJson(
        PersonalStatsAttackingPublic$Attacking instance) =>
    <String, dynamic>{
      'attacks': instance.attacks.toJson(),
      'defends': instance.defends.toJson(),
      'elo': instance.elo,
      'unarmored_wins': instance.unarmoredWins,
      'highest_level_beaten': instance.highestLevelBeaten,
      'escapes': instance.escapes?.toJson(),
      'killstreak': instance.killstreak.toJson(),
      'hits': instance.hits.toJson(),
      'damage': instance.damage.toJson(),
      'networth': instance.networth.toJson(),
      'ammunition': instance.ammunition.toJson(),
      'faction': instance.faction.toJson(),
    };

PersonalStatsAttackingExtended$Attacking
    _$PersonalStatsAttackingExtended$AttackingFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking(
          attacks: PersonalStatsAttackingExtended$Attacking$Attacks.fromJson(
              json['attacks'] as Map<String, dynamic>),
          defends: PersonalStatsAttackingExtended$Attacking$Defends.fromJson(
              json['defends'] as Map<String, dynamic>),
          elo: (json['elo'] as num).toInt(),
          unarmoredWins: (json['unarmored_wins'] as num).toInt(),
          highestLevelBeaten: (json['highest_level_beaten'] as num).toInt(),
          escapes: PersonalStatsAttackingExtended$Attacking$Escapes.fromJson(
              json['escapes'] as Map<String, dynamic>),
          killstreak:
              PersonalStatsAttackingExtended$Attacking$Killstreak.fromJson(
                  json['killstreak'] as Map<String, dynamic>),
          hits: PersonalStatsAttackingExtended$Attacking$Hits.fromJson(
              json['hits'] as Map<String, dynamic>),
          damage: PersonalStatsAttackingExtended$Attacking$Damage.fromJson(
              json['damage'] as Map<String, dynamic>),
          networth: PersonalStatsAttackingExtended$Attacking$Networth.fromJson(
              json['networth'] as Map<String, dynamic>),
          ammunition:
              PersonalStatsAttackingExtended$Attacking$Ammunition.fromJson(
                  json['ammunition'] as Map<String, dynamic>),
          faction: PersonalStatsAttackingExtended$Attacking$Faction.fromJson(
              json['faction'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$AttackingToJson(
        PersonalStatsAttackingExtended$Attacking instance) =>
    <String, dynamic>{
      'attacks': instance.attacks.toJson(),
      'defends': instance.defends.toJson(),
      'elo': instance.elo,
      'unarmored_wins': instance.unarmoredWins,
      'highest_level_beaten': instance.highestLevelBeaten,
      'escapes': instance.escapes.toJson(),
      'killstreak': instance.killstreak.toJson(),
      'hits': instance.hits.toJson(),
      'damage': instance.damage.toJson(),
      'networth': instance.networth.toJson(),
      'ammunition': instance.ammunition.toJson(),
      'faction': instance.faction.toJson(),
    };

PersonalStatsAttackingPopular$Attacking
    _$PersonalStatsAttackingPopular$AttackingFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking(
          attacks: PersonalStatsAttackingPopular$Attacking$Attacks.fromJson(
              json['attacks'] as Map<String, dynamic>),
          defends: PersonalStatsAttackingPopular$Attacking$Defends.fromJson(
              json['defends'] as Map<String, dynamic>),
          elo: (json['elo'] as num).toInt(),
          escapes: PersonalStatsAttackingPopular$Attacking$Escapes.fromJson(
              json['escapes'] as Map<String, dynamic>),
          killstreak:
              PersonalStatsAttackingPopular$Attacking$Killstreak.fromJson(
                  json['killstreak'] as Map<String, dynamic>),
          hits: PersonalStatsAttackingPopular$Attacking$Hits.fromJson(
              json['hits'] as Map<String, dynamic>),
          damage: PersonalStatsAttackingPopular$Attacking$Damage.fromJson(
              json['damage'] as Map<String, dynamic>),
          networth: PersonalStatsAttackingPopular$Attacking$Networth.fromJson(
              json['networth'] as Map<String, dynamic>),
          ammunition:
              PersonalStatsAttackingPopular$Attacking$Ammunition.fromJson(
                  json['ammunition'] as Map<String, dynamic>),
          faction: PersonalStatsAttackingPopular$Attacking$Faction.fromJson(
              json['faction'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$AttackingToJson(
        PersonalStatsAttackingPopular$Attacking instance) =>
    <String, dynamic>{
      'attacks': instance.attacks.toJson(),
      'defends': instance.defends.toJson(),
      'elo': instance.elo,
      'escapes': instance.escapes.toJson(),
      'killstreak': instance.killstreak.toJson(),
      'hits': instance.hits.toJson(),
      'damage': instance.damage.toJson(),
      'networth': instance.networth.toJson(),
      'ammunition': instance.ammunition.toJson(),
      'faction': instance.faction.toJson(),
    };

FactionUpgrades$Core _$FactionUpgrades$CoreFromJson(
        Map<String, dynamic> json) =>
    FactionUpgrades$Core(
      upgrades: (json['upgrades'] as List<dynamic>?)
              ?.map((e) =>
                  FactionUpgradeDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionUpgrades$CoreToJson(
        FactionUpgrades$Core instance) =>
    <String, dynamic>{
      'upgrades': instance.upgrades?.map((e) => e.toJson()).toList(),
    };

FactionApplication$User _$FactionApplication$UserFromJson(
        Map<String, dynamic> json) =>
    FactionApplication$User(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      level: (json['level'] as num).toInt(),
      stats: json['stats'],
    );

Map<String, dynamic> _$FactionApplication$UserToJson(
        FactionApplication$User instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'level': instance.level,
      'stats': instance.stats,
    };

FactionChainWarfare$Faction _$FactionChainWarfare$FactionFromJson(
        Map<String, dynamic> json) =>
    FactionChainWarfare$Faction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$FactionChainWarfare$FactionToJson(
        FactionChainWarfare$Faction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

FactionBalance$Faction _$FactionBalance$FactionFromJson(
        Map<String, dynamic> json) =>
    FactionBalance$Faction(
      money: (json['money'] as num).toInt(),
      points: (json['points'] as num).toInt(),
      scope: (json['scope'] as num).toInt(),
    );

Map<String, dynamic> _$FactionBalance$FactionToJson(
        FactionBalance$Faction instance) =>
    <String, dynamic>{
      'money': instance.money,
      'points': instance.points,
      'scope': instance.scope,
    };

FactionBalance$Members$Item _$FactionBalance$Members$ItemFromJson(
        Map<String, dynamic> json) =>
    FactionBalance$Members$Item(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      money: (json['money'] as num).toInt(),
      points: (json['points'] as num).toInt(),
    );

Map<String, dynamic> _$FactionBalance$Members$ItemToJson(
        FactionBalance$Members$Item instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'money': instance.money,
      'points': instance.points,
    };

FactionRankedWarDetails$Factions$Item
    _$FactionRankedWarDetails$Factions$ItemFromJson(
            Map<String, dynamic> json) =>
        FactionRankedWarDetails$Factions$Item(
          id: (json['id'] as num).toInt(),
          name: json['name'] as String,
          score: (json['score'] as num).toInt(),
          chain: (json['chain'] as num).toInt(),
        );

Map<String, dynamic> _$FactionRankedWarDetails$Factions$ItemToJson(
        FactionRankedWarDetails$Factions$Item instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'chain': instance.chain,
    };

FactionRankedWarReportResponse$Rankedwarreport
    _$FactionRankedWarReportResponse$RankedwarreportFromJson(
            Map<String, dynamic> json) =>
        FactionRankedWarReportResponse$Rankedwarreport(
          id: (json['id'] as num).toInt(),
          start: (json['start'] as num).toInt(),
          end: (json['end'] as num).toInt(),
          winner: (json['winner'] as num).toInt(),
          forfeit: json['forfeit'] as bool,
          factions: (json['factions'] as List<dynamic>)
              .map((e) =>
                  FactionRankedWarReportResponse$Rankedwarreport$Factions$Item
                      .fromJson(e as Map<String, dynamic>))
              .toList(),
        );

Map<String, dynamic> _$FactionRankedWarReportResponse$RankedwarreportToJson(
        FactionRankedWarReportResponse$Rankedwarreport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start': instance.start,
      'end': instance.end,
      'winner': instance.winner,
      'forfeit': instance.forfeit,
      'factions': instance.factions.map((e) => e.toJson()).toList(),
    };

ForumCategoriesResponse$Categories$Item
    _$ForumCategoriesResponse$Categories$ItemFromJson(
            Map<String, dynamic> json) =>
        ForumCategoriesResponse$Categories$Item(
          id: (json['id'] as num).toInt(),
          title: json['title'] as String,
          acronym: json['acronym'] as String,
          threads: (json['threads'] as num).toInt(),
        );

Map<String, dynamic> _$ForumCategoriesResponse$Categories$ItemToJson(
        ForumCategoriesResponse$Categories$Item instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'acronym': instance.acronym,
      'threads': instance.threads,
    };

KeyLogResponse$Log$Item _$KeyLogResponse$Log$ItemFromJson(
        Map<String, dynamic> json) =>
    KeyLogResponse$Log$Item(
      timestamp: (json['timestamp'] as num).toInt(),
      type: json['type'] as String,
      selections: json['selections'] as String,
      id: json['id'],
      comment: json['comment'],
      ip: json['ip'] as String,
    );

Map<String, dynamic> _$KeyLogResponse$Log$ItemToJson(
        KeyLogResponse$Log$Item instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'type': instance.type,
      'selections': instance.selections,
      'id': instance.id,
      'comment': instance.comment,
      'ip': instance.ip,
    };

KeyInfoResponse$Info _$KeyInfoResponse$InfoFromJson(
        Map<String, dynamic> json) =>
    KeyInfoResponse$Info(
      selections: KeyInfoResponse$Info$Selections.fromJson(
          json['selections'] as Map<String, dynamic>),
      access: KeyInfoResponse$Info$Access.fromJson(
          json['access'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$KeyInfoResponse$InfoToJson(
        KeyInfoResponse$Info instance) =>
    <String, dynamic>{
      'selections': instance.selections.toJson(),
      'access': instance.access.toJson(),
    };

MarketRentalDetails$Listings$Item _$MarketRentalDetails$Listings$ItemFromJson(
        Map<String, dynamic> json) =>
    MarketRentalDetails$Listings$Item(
      happy: (json['happy'] as num).toInt(),
      cost: (json['cost'] as num).toInt(),
      costPerDay: (json['cost_per_day'] as num).toInt(),
      rentalPeriod: (json['rental_period'] as num).toInt(),
      marketPrice: (json['market_price'] as num).toInt(),
      upkeep: (json['upkeep'] as num).toInt(),
      modifications: (json['modifications'] as List<dynamic>?)
              ?.map((e) => e as Object)
              .toList() ??
          [],
    );

Map<String, dynamic> _$MarketRentalDetails$Listings$ItemToJson(
        MarketRentalDetails$Listings$Item instance) =>
    <String, dynamic>{
      'happy': instance.happy,
      'cost': instance.cost,
      'cost_per_day': instance.costPerDay,
      'rental_period': instance.rentalPeriod,
      'market_price': instance.marketPrice,
      'upkeep': instance.upkeep,
      'modifications': instance.modifications,
    };

MarketPropertyDetails$Listings$Item
    _$MarketPropertyDetails$Listings$ItemFromJson(Map<String, dynamic> json) =>
        MarketPropertyDetails$Listings$Item(
          happy: (json['happy'] as num).toInt(),
          cost: (json['cost'] as num).toInt(),
          marketPrice: (json['market_price'] as num).toInt(),
          upkeep: (json['upkeep'] as num).toInt(),
          modifications: (json['modifications'] as List<dynamic>?)
                  ?.map((e) => e as Object)
                  .toList() ??
              [],
        );

Map<String, dynamic> _$MarketPropertyDetails$Listings$ItemToJson(
        MarketPropertyDetails$Listings$Item instance) =>
    <String, dynamic>{
      'happy': instance.happy,
      'cost': instance.cost,
      'market_price': instance.marketPrice,
      'upkeep': instance.upkeep,
      'modifications': instance.modifications,
    };

UserRacingRecordsResponse$Racingrecords$Item
    _$UserRacingRecordsResponse$Racingrecords$ItemFromJson(
            Map<String, dynamic> json) =>
        UserRacingRecordsResponse$Racingrecords$Item(
          track: UserRacingRecordsResponse$Racingrecords$Item$Track.fromJson(
              json['track'] as Map<String, dynamic>),
          records: (json['records'] as List<dynamic>)
              .map((e) =>
                  UserRacingRecordsResponse$Racingrecords$Item$Records$Item
                      .fromJson(e as Map<String, dynamic>))
              .toList(),
        );

Map<String, dynamic> _$UserRacingRecordsResponse$Racingrecords$ItemToJson(
        UserRacingRecordsResponse$Racingrecords$Item instance) =>
    <String, dynamic>{
      'track': instance.track.toJson(),
      'records': instance.records.map((e) => e.toJson()).toList(),
    };

RaceCarUpgrade$Effects _$RaceCarUpgrade$EffectsFromJson(
        Map<String, dynamic> json) =>
    RaceCarUpgrade$Effects(
      topSpeed: (json['top_speed'] as num).toInt(),
      acceleration: (json['acceleration'] as num).toInt(),
      braking: (json['braking'] as num).toInt(),
      handling: (json['handling'] as num).toInt(),
      safety: (json['safety'] as num).toInt(),
      dirt: (json['dirt'] as num).toInt(),
      tarmac: (json['tarmac'] as num).toInt(),
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
      points: (json['points'] as num).toInt(),
      cash: (json['cash'] as num).toInt(),
    );

Map<String, dynamic> _$RaceCarUpgrade$CostToJson(
        RaceCarUpgrade$Cost instance) =>
    <String, dynamic>{
      'points': instance.points,
      'cash': instance.cash,
    };

Race$Participants _$Race$ParticipantsFromJson(Map<String, dynamic> json) =>
    Race$Participants(
      minimum: (json['minimum'] as num).toInt(),
      maximum: (json['maximum'] as num).toInt(),
      current: (json['current'] as num).toInt(),
    );

Map<String, dynamic> _$Race$ParticipantsToJson(Race$Participants instance) =>
    <String, dynamic>{
      'minimum': instance.minimum,
      'maximum': instance.maximum,
      'current': instance.current,
    };

Race$Schedule _$Race$ScheduleFromJson(Map<String, dynamic> json) =>
    Race$Schedule(
      joinFrom: (json['join_from'] as num).toInt(),
      joinUntil: (json['join_until'] as num).toInt(),
      start: (json['start'] as num).toInt(),
      end: json['end'],
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
      carClass: json['car_class'],
      driverClass: json['driver_class'],
      carItemId: json['car_item_id'],
      requiresStockCar: json['requires_stock_car'] as bool,
      requiresPassword: json['requires_password'] as bool,
      joinFee: (json['join_fee'] as num).toInt(),
    );

Map<String, dynamic> _$Race$RequirementsToJson(Race$Requirements instance) =>
    <String, dynamic>{
      'car_class': instance.carClass,
      'driver_class': instance.driverClass,
      'car_item_id': instance.carItemId,
      'requires_stock_car': instance.requiresStockCar,
      'requires_password': instance.requiresPassword,
      'join_fee': instance.joinFee,
    };

RacingRaceDetails$Participants _$RacingRaceDetails$ParticipantsFromJson(
        Map<String, dynamic> json) =>
    RacingRaceDetails$Participants(
      minimum: (json['minimum'] as num).toInt(),
      maximum: (json['maximum'] as num).toInt(),
      current: (json['current'] as num).toInt(),
    );

Map<String, dynamic> _$RacingRaceDetails$ParticipantsToJson(
        RacingRaceDetails$Participants instance) =>
    <String, dynamic>{
      'minimum': instance.minimum,
      'maximum': instance.maximum,
      'current': instance.current,
    };

RacingRaceDetails$Schedule _$RacingRaceDetails$ScheduleFromJson(
        Map<String, dynamic> json) =>
    RacingRaceDetails$Schedule(
      joinFrom: (json['join_from'] as num).toInt(),
      joinUntil: (json['join_until'] as num).toInt(),
      start: (json['start'] as num).toInt(),
      end: json['end'],
    );

Map<String, dynamic> _$RacingRaceDetails$ScheduleToJson(
        RacingRaceDetails$Schedule instance) =>
    <String, dynamic>{
      'join_from': instance.joinFrom,
      'join_until': instance.joinUntil,
      'start': instance.start,
      'end': instance.end,
    };

RacingRaceDetails$Requirements _$RacingRaceDetails$RequirementsFromJson(
        Map<String, dynamic> json) =>
    RacingRaceDetails$Requirements(
      carClass: json['car_class'],
      driverClass: json['driver_class'],
      carItemId: json['car_item_id'],
      requiresStockCar: json['requires_stock_car'] as bool,
      requiresPassword: json['requires_password'] as bool,
      joinFee: (json['join_fee'] as num).toInt(),
    );

Map<String, dynamic> _$RacingRaceDetails$RequirementsToJson(
        RacingRaceDetails$Requirements instance) =>
    <String, dynamic>{
      'car_class': instance.carClass,
      'driver_class': instance.driverClass,
      'car_item_id': instance.carItemId,
      'requires_stock_car': instance.requiresStockCar,
      'requires_password': instance.requiresPassword,
      'join_fee': instance.joinFee,
    };

TornProperties$Properties$Item _$TornProperties$Properties$ItemFromJson(
        Map<String, dynamic> json) =>
    TornProperties$Properties$Item(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      cost: (json['cost'] as num).toInt(),
      happy: (json['happy'] as num).toInt(),
      upkeep: (json['upkeep'] as num).toInt(),
      modifications: (json['modifications'] as List<dynamic>?)
              ?.map((e) => e as Object)
              .toList() ??
          [],
      staff:
          (json['staff'] as List<dynamic>?)?.map((e) => e as Object).toList() ??
              [],
    );

Map<String, dynamic> _$TornProperties$Properties$ItemToJson(
        TornProperties$Properties$Item instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'cost': instance.cost,
      'happy': instance.happy,
      'upkeep': instance.upkeep,
      'modifications': instance.modifications,
      'staff': instance.staff,
    };

TornEducationRewards$WorkingStats _$TornEducationRewards$WorkingStatsFromJson(
        Map<String, dynamic> json) =>
    TornEducationRewards$WorkingStats(
      manualLabor: json['manual_labor'],
      intelligence: json['intelligence'],
      endurance: json['endurance'],
    );

Map<String, dynamic> _$TornEducationRewards$WorkingStatsToJson(
        TornEducationRewards$WorkingStats instance) =>
    <String, dynamic>{
      'manual_labor': instance.manualLabor,
      'intelligence': instance.intelligence,
      'endurance': instance.endurance,
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
      'competitions': instance.competitions.map((e) => e.toJson()).toList(),
      'events': instance.events.map((e) => e.toJson()).toList(),
    };

AttackLog$AttackerItem _$AttackLog$AttackerItemFromJson(
        Map<String, dynamic> json) =>
    AttackLog$AttackerItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$AttackLog$AttackerItemToJson(
        AttackLog$AttackerItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

AttackLogResponse$Attacklog _$AttackLogResponse$AttacklogFromJson(
        Map<String, dynamic> json) =>
    AttackLogResponse$Attacklog(
      log: (json['log'] as List<dynamic>?)
              ?.map((e) => AttackLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: (json['summary'] as List<dynamic>?)
              ?.map((e) => AttackLogSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$AttackLogResponse$AttacklogToJson(
        AttackLogResponse$Attacklog instance) =>
    <String, dynamic>{
      'log': instance.log.map((e) => e.toJson()).toList(),
      'summary': instance.summary.map((e) => e.toJson()).toList(),
    };

TornItem$Value _$TornItem$ValueFromJson(Map<String, dynamic> json) =>
    TornItem$Value(
      vendor: json['vendor'],
      buyPrice: json['buy_price'],
      sellPrice: json['sell_price'],
      marketPrice: (json['market_price'] as num).toInt(),
    );

Map<String, dynamic> _$TornItem$ValueToJson(TornItem$Value instance) =>
    <String, dynamic>{
      'vendor': instance.vendor,
      'buy_price': instance.buyPrice,
      'sell_price': instance.sellPrice,
      'market_price': instance.marketPrice,
    };

TornFactionTreeBranch$Upgrades$Item
    _$TornFactionTreeBranch$Upgrades$ItemFromJson(Map<String, dynamic> json) =>
        TornFactionTreeBranch$Upgrades$Item(
          name: json['name'] as String,
          level: (json['level'] as num).toInt(),
          ability: json['ability'] as String,
          cost: (json['cost'] as num).toInt(),
          challenge: json['challenge'],
        );

Map<String, dynamic> _$TornFactionTreeBranch$Upgrades$ItemToJson(
        TornFactionTreeBranch$Upgrades$Item instance) =>
    <String, dynamic>{
      'name': instance.name,
      'level': instance.level,
      'ability': instance.ability,
      'cost': instance.cost,
      'challenge': instance.challenge,
    };

ReportStockAnalysis$Items$Item$Item
    _$ReportStockAnalysis$Items$Item$ItemFromJson(Map<String, dynamic> json) =>
        ReportStockAnalysis$Items$Item$Item(
          id: (json['id'] as num).toInt(),
          name: json['name'] as String,
          price: (json['price'] as num).toInt(),
          $value: (json['value'] as num).toInt(),
          due: json['due'],
        );

Map<String, dynamic> _$ReportStockAnalysis$Items$Item$ItemToJson(
        ReportStockAnalysis$Items$Item$Item instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'value': instance.$value,
      'due': instance.due,
    };

UserCrimeDetailsCardSkimming$CardDetails$Areas$Item
    _$UserCrimeDetailsCardSkimming$CardDetails$Areas$ItemFromJson(
            Map<String, dynamic> json) =>
        UserCrimeDetailsCardSkimming$CardDetails$Areas$Item(
          id: (json['id'] as num).toInt(),
          amount: (json['amount'] as num).toInt(),
        );

Map<String, dynamic>
    _$UserCrimeDetailsCardSkimming$CardDetails$Areas$ItemToJson(
            UserCrimeDetailsCardSkimming$CardDetails$Areas$Item instance) =>
        <String, dynamic>{
          'id': instance.id,
          'amount': instance.amount,
        };

PersonalStatsOther$Other$Activity _$PersonalStatsOther$Other$ActivityFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOther$Other$Activity(
      time: (json['time'] as num).toInt(),
      streak: PersonalStatsOther$Other$Activity$Streak.fromJson(
          json['streak'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PersonalStatsOther$Other$ActivityToJson(
        PersonalStatsOther$Other$Activity instance) =>
    <String, dynamic>{
      'time': instance.time,
      'streak': instance.streak.toJson(),
    };

PersonalStatsOther$Other$Refills _$PersonalStatsOther$Other$RefillsFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsOther$Other$Refills(
      energy: (json['energy'] as num).toInt(),
      nerve: (json['nerve'] as num).toInt(),
      token: (json['token'] as num).toInt(),
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
          time: (json['time'] as num).toInt(),
          streak: PersonalStatsOtherPopular$Other$Activity$Streak.fromJson(
              json['streak'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsOtherPopular$Other$ActivityToJson(
        PersonalStatsOtherPopular$Other$Activity instance) =>
    <String, dynamic>{
      'time': instance.time,
      'streak': instance.streak.toJson(),
    };

PersonalStatsOtherPopular$Other$Refills
    _$PersonalStatsOtherPopular$Other$RefillsFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsOtherPopular$Other$Refills(
          energy: (json['energy'] as num).toInt(),
          nerve: (json['nerve'] as num).toInt(),
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
      entered: (json['entered'] as num).toInt(),
      won: (json['won'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
          duke: (json['duke'] as num).toInt(),
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
          amount: (json['amount'] as num).toInt(),
          fees: (json['fees'] as num).toInt(),
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
      skill: (json['skill'] as num).toInt(),
    );

Map<String, dynamic> _$PersonalStatsTravel$Travel$HuntingToJson(
        PersonalStatsTravel$Travel$Hunting instance) =>
    <String, dynamic>{
      'skill': instance.skill,
    };

PersonalStatsItems$Items$Found _$PersonalStatsItems$Items$FoundFromJson(
        Map<String, dynamic> json) =>
    PersonalStatsItems$Items$Found(
      city: (json['city'] as num).toInt(),
      dump: (json['dump'] as num).toInt(),
      easterEggs: (json['easter_eggs'] as num).toInt(),
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
      books: (json['books'] as num).toInt(),
      boosters: (json['boosters'] as num).toInt(),
      consumables: (json['consumables'] as num).toInt(),
      candy: (json['candy'] as num).toInt(),
      alcohol: (json['alcohol'] as num).toInt(),
      energyDrinks: (json['energy_drinks'] as num).toInt(),
      statEnhancers: (json['stat_enhancers'] as num).toInt(),
      easterEggs: (json['easter_eggs'] as num).toInt(),
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
          dump: (json['dump'] as num).toInt(),
        );

Map<String, dynamic> _$PersonalStatsItemsPopular$Items$FoundToJson(
        PersonalStatsItemsPopular$Items$Found instance) =>
    <String, dynamic>{
      'dump': instance.dump,
    };

PersonalStatsItemsPopular$Items$Used
    _$PersonalStatsItemsPopular$Items$UsedFromJson(Map<String, dynamic> json) =>
        PersonalStatsItemsPopular$Items$Used(
          books: (json['books'] as num).toInt(),
          boosters: (json['boosters'] as num).toInt(),
          consumables: (json['consumables'] as num).toInt(),
          candy: (json['candy'] as num).toInt(),
          alcohol: (json['alcohol'] as num).toInt(),
          energyDrinks: (json['energy_drinks'] as num).toInt(),
          statEnhancers: (json['stat_enhancers'] as num).toInt(),
          easterEggs: (json['easter_eggs'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
          profit: (json['profit'] as num).toInt(),
          current: (json['current'] as num).toInt(),
          timeRemaining: (json['time_remaining'] as num).toInt(),
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
          profits: (json['profits'] as num).toInt(),
          losses: (json['losses'] as num).toInt(),
          fees: (json['fees'] as num).toInt(),
          netProfits: (json['net_profits'] as num).toInt(),
          payouts: (json['payouts'] as num).toInt(),
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
          amount: (json['amount'] as num).toInt(),
          $value: (json['value'] as num).toInt(),
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
          amount: (json['amount'] as num).toInt(),
          $value: (json['value'] as num).toInt(),
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
          amount: (json['amount'] as num).toInt(),
          $value: (json['value'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
          friends: (json['friends'] as num).toInt(),
          faction: (json['faction'] as num).toInt(),
          colleagues: (json['colleagues'] as num).toInt(),
          spouse: (json['spouse'] as num).toInt(),
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
          skill: (json['skill'] as num).toInt(),
          revives: (json['revives'] as num).toInt(),
          revivesReceived: (json['revives_received'] as num).toInt(),
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
          skill: (json['skill'] as num).toInt(),
          revives: (json['revives'] as num).toInt(),
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
      success: (json['success'] as num).toInt(),
      fails: (json['fails'] as num).toInt(),
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
      amount: (json['amount'] as num).toInt(),
      fees: (json['fees'] as num).toInt(),
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
      bought: PersonalStatsTrading$Trading$Items$Bought.fromJson(
          json['bought'] as Map<String, dynamic>),
      auctions: PersonalStatsTrading$Trading$Items$Auctions.fromJson(
          json['auctions'] as Map<String, dynamic>),
      sent: (json['sent'] as num).toInt(),
    );

Map<String, dynamic> _$PersonalStatsTrading$Trading$ItemsToJson(
        PersonalStatsTrading$Trading$Items instance) =>
    <String, dynamic>{
      'bought': instance.bought.toJson(),
      'auctions': instance.auctions.toJson(),
      'sent': instance.sent,
    };

PersonalStatsTrading$Trading$Points
    _$PersonalStatsTrading$Trading$PointsFromJson(Map<String, dynamic> json) =>
        PersonalStatsTrading$Trading$Points(
          bought: (json['bought'] as num).toInt(),
          sold: (json['sold'] as num).toInt(),
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
          customers: (json['customers'] as num).toInt(),
          sales: (json['sales'] as num).toInt(),
          profit: (json['profit'] as num).toInt(),
        );

Map<String, dynamic> _$PersonalStatsTrading$Trading$BazaarToJson(
        PersonalStatsTrading$Trading$Bazaar instance) =>
    <String, dynamic>{
      'customers': instance.customers,
      'sales': instance.sales,
      'profit': instance.profit,
    };

PersonalStatsTrading$Trading$ItemMarket
    _$PersonalStatsTrading$Trading$ItemMarketFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsTrading$Trading$ItemMarket(
          customers: (json['customers'] as num).toInt(),
          sales: (json['sales'] as num).toInt(),
          revenue: (json['revenue'] as num).toInt(),
          fees: (json['fees'] as num).toInt(),
        );

Map<String, dynamic> _$PersonalStatsTrading$Trading$ItemMarketToJson(
        PersonalStatsTrading$Trading$ItemMarket instance) =>
    <String, dynamic>{
      'customers': instance.customers,
      'sales': instance.sales,
      'revenue': instance.revenue,
      'fees': instance.fees,
    };

PersonalStatsJobsExtended$Jobs$Stats
    _$PersonalStatsJobsExtended$Jobs$StatsFromJson(Map<String, dynamic> json) =>
        PersonalStatsJobsExtended$Jobs$Stats(
          manual: (json['manual'] as num).toInt(),
          intelligence: (json['intelligence'] as num).toInt(),
          endurance: (json['endurance'] as num).toInt(),
          total: (json['total'] as num).toInt(),
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
          won: (json['won'] as num).toInt(),
          lost: (json['lost'] as num).toInt(),
          stalemate: (json['stalemate'] as num).toInt(),
          assist: (json['assist'] as num).toInt(),
          stealth: (json['stealth'] as num).toInt(),
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
          won: (json['won'] as num).toInt(),
          lost: (json['lost'] as num).toInt(),
          stalemate: (json['stalemate'] as num).toInt(),
          total: (json['total'] as num).toInt(),
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
          player: (json['player'] as num).toInt(),
          foes: (json['foes'] as num).toInt(),
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
          best: (json['best'] as num).toInt(),
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
          success: (json['success'] as num).toInt(),
          miss: (json['miss'] as num).toInt(),
          critical: (json['critical'] as num).toInt(),
          oneHitKills: (json['one_hit_kills'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
          best: (json['best'] as num).toInt(),
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
          moneyMugged: (json['money_mugged'] as num).toInt(),
          largestMug: (json['largest_mug'] as num).toInt(),
          itemsLooted: (json['items_looted'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
          special: (json['special'] as num).toInt(),
          hollowPoint: (json['hollow_point'] as num).toInt(),
          tracer: (json['tracer'] as num).toInt(),
          piercing: (json['piercing'] as num).toInt(),
          incendiary: (json['incendiary'] as num).toInt(),
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
          respect: (json['respect'] as num).toInt(),
          retaliations: (json['retaliations'] as num).toInt(),
          rankedWarHits: (json['ranked_war_hits'] as num).toInt(),
          raidHits: (json['raid_hits'] as num).toInt(),
          territory:
              PersonalStatsAttackingPublic$Attacking$Faction$Territory.fromJson(
                  json['territory'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingPublic$Attacking$FactionToJson(
        PersonalStatsAttackingPublic$Attacking$Faction instance) =>
    <String, dynamic>{
      'respect': instance.respect,
      'retaliations': instance.retaliations,
      'ranked_war_hits': instance.rankedWarHits,
      'raid_hits': instance.raidHits,
      'territory': instance.territory.toJson(),
    };

PersonalStatsAttackingExtended$Attacking$Attacks
    _$PersonalStatsAttackingExtended$Attacking$AttacksFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingExtended$Attacking$Attacks(
          won: (json['won'] as num).toInt(),
          lost: (json['lost'] as num).toInt(),
          stalemate: (json['stalemate'] as num).toInt(),
          assist: (json['assist'] as num).toInt(),
          stealth: (json['stealth'] as num).toInt(),
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
          won: (json['won'] as num).toInt(),
          lost: (json['lost'] as num).toInt(),
          stalemate: (json['stalemate'] as num).toInt(),
          total: (json['total'] as num).toInt(),
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
          player: (json['player'] as num).toInt(),
          foes: (json['foes'] as num).toInt(),
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
          best: (json['best'] as num).toInt(),
          current: (json['current'] as num).toInt(),
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
          success: (json['success'] as num).toInt(),
          miss: (json['miss'] as num).toInt(),
          critical: (json['critical'] as num).toInt(),
          oneHitKills: (json['one_hit_kills'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
          best: (json['best'] as num).toInt(),
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
          moneyMugged: (json['money_mugged'] as num).toInt(),
          largestMug: (json['largest_mug'] as num).toInt(),
          itemsLooted: (json['items_looted'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
          special: (json['special'] as num).toInt(),
          hollowPoint: (json['hollow_point'] as num).toInt(),
          tracer: (json['tracer'] as num).toInt(),
          piercing: (json['piercing'] as num).toInt(),
          incendiary: (json['incendiary'] as num).toInt(),
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
          respect: (json['respect'] as num).toInt(),
          retaliations: (json['retaliations'] as num).toInt(),
          rankedWarHits: (json['ranked_war_hits'] as num).toInt(),
          raidHits: (json['raid_hits'] as num).toInt(),
          territory: PersonalStatsAttackingExtended$Attacking$Faction$Territory
              .fromJson(json['territory'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$PersonalStatsAttackingExtended$Attacking$FactionToJson(
        PersonalStatsAttackingExtended$Attacking$Faction instance) =>
    <String, dynamic>{
      'respect': instance.respect,
      'retaliations': instance.retaliations,
      'ranked_war_hits': instance.rankedWarHits,
      'raid_hits': instance.raidHits,
      'territory': instance.territory.toJson(),
    };

PersonalStatsAttackingPopular$Attacking$Attacks
    _$PersonalStatsAttackingPopular$Attacking$AttacksFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsAttackingPopular$Attacking$Attacks(
          won: (json['won'] as num).toInt(),
          lost: (json['lost'] as num).toInt(),
          stalemate: (json['stalemate'] as num).toInt(),
          assist: (json['assist'] as num).toInt(),
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
          won: (json['won'] as num).toInt(),
          lost: (json['lost'] as num).toInt(),
          stalemate: (json['stalemate'] as num).toInt(),
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
          player: (json['player'] as num).toInt(),
          foes: (json['foes'] as num).toInt(),
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
          best: (json['best'] as num).toInt(),
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
          success: (json['success'] as num).toInt(),
          miss: (json['miss'] as num).toInt(),
          critical: (json['critical'] as num).toInt(),
          oneHitKills: (json['one_hit_kills'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
          best: (json['best'] as num).toInt(),
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
          moneyMugged: (json['money_mugged'] as num).toInt(),
          largestMug: (json['largest_mug'] as num).toInt(),
          itemsLooted: (json['items_looted'] as num).toInt(),
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
          total: (json['total'] as num).toInt(),
          special: (json['special'] as num).toInt(),
          hollowPoint: (json['hollow_point'] as num).toInt(),
          tracer: (json['tracer'] as num).toInt(),
          piercing: (json['piercing'] as num).toInt(),
          incendiary: (json['incendiary'] as num).toInt(),
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
          respect: (json['respect'] as num).toInt(),
          rankedWarHits: (json['ranked_war_hits'] as num).toInt(),
        );

Map<String, dynamic> _$PersonalStatsAttackingPopular$Attacking$FactionToJson(
        PersonalStatsAttackingPopular$Attacking$Faction instance) =>
    <String, dynamic>{
      'respect': instance.respect,
      'ranked_war_hits': instance.rankedWarHits,
    };

FactionRankedWarReportResponse$Rankedwarreport$Factions$Item
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$ItemFromJson(
            Map<String, dynamic> json) =>
        FactionRankedWarReportResponse$Rankedwarreport$Factions$Item(
          id: (json['id'] as num).toInt(),
          name: json['name'] as String,
          score: (json['score'] as num).toInt(),
          attacks: (json['attacks'] as num).toInt(),
          rank:
              FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rank
                  .fromJson(json['rank'] as Map<String, dynamic>),
          rewards:
              FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards
                  .fromJson(json['rewards'] as Map<String, dynamic>),
          members: (json['members'] as List<dynamic>)
              .map((e) =>
                  FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Members$Item
                      .fromJson(e as Map<String, dynamic>))
              .toList(),
        );

Map<String, dynamic>
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$ItemToJson(
            FactionRankedWarReportResponse$Rankedwarreport$Factions$Item
                instance) =>
        <String, dynamic>{
          'id': instance.id,
          'name': instance.name,
          'score': instance.score,
          'attacks': instance.attacks,
          'rank': instance.rank.toJson(),
          'rewards': instance.rewards.toJson(),
          'members': instance.members.map((e) => e.toJson()).toList(),
        };

KeyInfoResponse$Info$Selections _$KeyInfoResponse$Info$SelectionsFromJson(
        Map<String, dynamic> json) =>
    KeyInfoResponse$Info$Selections(
      company: (json['company'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      faction: (json['faction'] as List<dynamic>?)
              ?.map((e) =>
                  FactionSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      market: (json['market'] as List<dynamic>?)
              ?.map((e) =>
                  MarketSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      property: (json['property'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      torn: (json['torn'] as List<dynamic>?)
              ?.map(
                  (e) => TornSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      user: (json['user'] as List<dynamic>?)
              ?.map(
                  (e) => UserSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      racing: (json['racing'] as List<dynamic>?)
              ?.map((e) =>
                  RacingSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      forum: (json['forum'] as List<dynamic>?)
              ?.map(
                  (e) => ForumSelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      key: (json['key'] as List<dynamic>?)
              ?.map((e) => KeySelectionName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$KeyInfoResponse$Info$SelectionsToJson(
        KeyInfoResponse$Info$Selections instance) =>
    <String, dynamic>{
      'company': instance.company,
      'faction': instance.faction.map((e) => e.toJson()).toList(),
      'market': instance.market.map((e) => e.toJson()).toList(),
      'property': instance.property,
      'torn': instance.torn.map((e) => e.toJson()).toList(),
      'user': instance.user.map((e) => e.toJson()).toList(),
      'racing': instance.racing.map((e) => e.toJson()).toList(),
      'forum': instance.forum.map((e) => e.toJson()).toList(),
      'key': instance.key.map((e) => e.toJson()).toList(),
    };

KeyInfoResponse$Info$Access _$KeyInfoResponse$Info$AccessFromJson(
        Map<String, dynamic> json) =>
    KeyInfoResponse$Info$Access(
      level: (json['level'] as num).toInt(),
      type: apiKeyAccessTypeEnumFromJson(json['type']),
      faction: json['faction'] as bool,
      factionId: json['faction_id'],
      company: json['company'] as bool,
      companyId: json['company_id'],
    );

Map<String, dynamic> _$KeyInfoResponse$Info$AccessToJson(
        KeyInfoResponse$Info$Access instance) =>
    <String, dynamic>{
      'level': instance.level,
      'type': apiKeyAccessTypeEnumToJson(instance.type),
      'faction': instance.faction,
      'faction_id': instance.factionId,
      'company': instance.company,
      'company_id': instance.companyId,
    };

UserRacingRecordsResponse$Racingrecords$Item$Track
    _$UserRacingRecordsResponse$Racingrecords$Item$TrackFromJson(
            Map<String, dynamic> json) =>
        UserRacingRecordsResponse$Racingrecords$Item$Track(
          id: (json['id'] as num).toInt(),
          name: json['name'] as String,
        );

Map<String, dynamic> _$UserRacingRecordsResponse$Racingrecords$Item$TrackToJson(
        UserRacingRecordsResponse$Racingrecords$Item$Track instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

UserRacingRecordsResponse$Racingrecords$Item$Records$Item
    _$UserRacingRecordsResponse$Racingrecords$Item$Records$ItemFromJson(
            Map<String, dynamic> json) =>
        UserRacingRecordsResponse$Racingrecords$Item$Records$Item(
          carId: (json['car_id'] as num).toInt(),
          carName: json['car_name'] as String,
          lapTime: (json['lap_time'] as num).toInt(),
        );

Map<String,
    dynamic> _$UserRacingRecordsResponse$Racingrecords$Item$Records$ItemToJson(
        UserRacingRecordsResponse$Racingrecords$Item$Records$Item instance) =>
    <String, dynamic>{
      'car_id': instance.carId,
      'car_name': instance.carName,
      'lap_time': instance.lapTime,
    };

PersonalStatsOther$Other$Activity$Streak
    _$PersonalStatsOther$Other$Activity$StreakFromJson(
            Map<String, dynamic> json) =>
        PersonalStatsOther$Other$Activity$Streak(
          best: (json['best'] as num).toInt(),
          current: (json['current'] as num).toInt(),
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
          best: (json['best'] as num).toInt(),
          current: (json['current'] as num).toInt(),
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
          market: (json['market'] as num).toInt(),
          shops: (json['shops'] as num).toInt(),
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
          won: (json['won'] as num).toInt(),
          sold: (json['sold'] as num).toInt(),
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
          wallJoins: (json['wall_joins'] as num).toInt(),
          wallClears: (json['wall_clears'] as num).toInt(),
          wallTime: (json['wall_time'] as num).toInt(),
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
          wallJoins: (json['wall_joins'] as num).toInt(),
          wallClears: (json['wall_clears'] as num).toInt(),
          wallTime: (json['wall_time'] as num).toInt(),
        );

Map<String,
    dynamic> _$PersonalStatsAttackingExtended$Attacking$Faction$TerritoryToJson(
        PersonalStatsAttackingExtended$Attacking$Faction$Territory instance) =>
    <String, dynamic>{
      'wall_joins': instance.wallJoins,
      'wall_clears': instance.wallClears,
      'wall_time': instance.wallTime,
    };

FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rank
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$RankFromJson(
            Map<String, dynamic> json) =>
        FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rank(
          before: json['before'] as String,
          after: json['after'] as String,
        );

Map<String, dynamic>
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$RankToJson(
            FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rank
                instance) =>
        <String, dynamic>{
          'before': instance.before,
          'after': instance.after,
        };

FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$RewardsFromJson(
            Map<String, dynamic> json) =>
        FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards(
          respect: (json['respect'] as num).toInt(),
          points: (json['points'] as num).toInt(),
          items: (json['items'] as List<dynamic>)
              .map((e) =>
                  FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards$Items$Item
                      .fromJson(e as Map<String, dynamic>))
              .toList(),
        );

Map<String, dynamic>
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$RewardsToJson(
            FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards
                instance) =>
        <String, dynamic>{
          'respect': instance.respect,
          'points': instance.points,
          'items': instance.items.map((e) => e.toJson()).toList(),
        };

FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Members$Item
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Members$ItemFromJson(
            Map<String, dynamic> json) =>
        FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Members$Item(
          id: (json['id'] as num).toInt(),
          name: json['name'] as String,
          level: (json['level'] as num).toInt(),
          attacks: (json['attacks'] as num).toInt(),
          score: (json['score'] as num).toDouble(),
        );

Map<String, dynamic>
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Members$ItemToJson(
            FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Members$Item
                instance) =>
        <String, dynamic>{
          'id': instance.id,
          'name': instance.name,
          'level': instance.level,
          'attacks': instance.attacks,
          'score': instance.score,
        };

FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards$Items$Item
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards$Items$ItemFromJson(
            Map<String, dynamic> json) =>
        FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards$Items$Item(
          id: (json['id'] as num).toInt(),
          name: json['name'] as String,
          quantity: (json['quantity'] as num).toInt(),
        );

Map<String, dynamic>
    _$FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards$Items$ItemToJson(
            FactionRankedWarReportResponse$Rankedwarreport$Factions$Item$Rewards$Items$Item
                instance) =>
        <String, dynamic>{
          'id': instance.id,
          'name': instance.name,
          'quantity': instance.quantity,
        };
