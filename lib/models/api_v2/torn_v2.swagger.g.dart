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

FactionMember _$FactionMemberFromJson(Map<String, dynamic> json) =>
    FactionMember(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      position: json['position'] as String?,
      level: (json['level'] as num?)?.toDouble(),
      daysInFaction: (json['days_in_faction'] as num?)?.toDouble(),
      isRevivable: json['is_revivable'] as bool?,
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
      'last_action': instance.lastAction?.toJson(),
      'status': instance.status?.toJson(),
      'life': instance.life?.toJson(),
      'revive_setting': reviveSettingNullableToJson(instance.reviveSetting),
    };

UserLastAction _$UserLastActionFromJson(Map<String, dynamic> json) =>
    UserLastAction(
      status: json['status'] as String?,
      timestamp: (json['timestamp'] as num?)?.toDouble(),
      relative: json['relative'] as String?,
    );

Map<String, dynamic> _$UserLastActionToJson(UserLastAction instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp,
      'relative': instance.relative,
    };

UserLife _$UserLifeFromJson(Map<String, dynamic> json) => UserLife(
      current: (json['current'] as num?)?.toDouble(),
      maximum: (json['maximum'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$UserLifeToJson(UserLife instance) => <String, dynamic>{
      'current': instance.current,
      'maximum': instance.maximum,
    };

UserStatus _$UserStatusFromJson(Map<String, dynamic> json) => UserStatus(
      description: json['description'] as String?,
      details: json['details'] as String?,
      state: json['state'] as String?,
      until: json['until'] as String?,
    );

Map<String, dynamic> _$UserStatusToJson(UserStatus instance) =>
    <String, dynamic>{
      'description': instance.description,
      'details': instance.details,
      'state': instance.state,
      'until': instance.until,
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

ForumCategories _$ForumCategoriesFromJson(Map<String, dynamic> json) =>
    ForumCategories(
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => ForumCategories$Categories$Item.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ForumCategoriesToJson(ForumCategories instance) =>
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
    );

Map<String, dynamic> _$ItemMarketListingItemDetailsToJson(
        ItemMarketListingItemDetails instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'stats': instance.stats?.toJson(),
      'bonuses': instance.bonuses?.map((e) => e.toJson()).toList(),
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

RaceCars _$RaceCarsFromJson(Map<String, dynamic> json) => RaceCars(
      cars: (json['cars'] as List<dynamic>?)
              ?.map((e) => RaceCar.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RaceCarsToJson(RaceCars instance) => <String, dynamic>{
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

RaceTracks _$RaceTracksFromJson(Map<String, dynamic> json) => RaceTracks(
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((e) => RaceTrack.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RaceTracksToJson(RaceTracks instance) =>
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

RaceCarUpgrades _$RaceCarUpgradesFromJson(Map<String, dynamic> json) =>
    RaceCarUpgrades(
      carupgrades: (json['carupgrades'] as List<dynamic>?)
              ?.map((e) => RaceCarUpgrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RaceCarUpgradesToJson(RaceCarUpgrades instance) =>
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

Races _$RacesFromJson(Map<String, dynamic> json) => Races(
      races: (json['races'] as List<dynamic>?)
              ?.map((e) => Race.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RacesToJson(Races instance) => <String, dynamic>{
      'races': instance.races?.map((e) => e.toJson()).toList(),
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

RaceRecords _$RaceRecordsFromJson(Map<String, dynamic> json) => RaceRecords(
      records: (json['records'] as List<dynamic>?)
              ?.map((e) => RaceRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RaceRecordsToJson(RaceRecords instance) =>
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
      timeEnded: (json['time_ended'] as num?)?.toDouble(),
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

RaceDetails _$RaceDetailsFromJson(Map<String, dynamic> json) => RaceDetails(
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
          : RaceDetails$Participants.fromJson(
              json['participants'] as Map<String, dynamic>),
      schedule: json['schedule'] == null
          ? null
          : RaceDetails$Schedule.fromJson(
              json['schedule'] as Map<String, dynamic>),
      requirements: json['requirements'] == null
          ? null
          : RaceDetails$Requirements.fromJson(
              json['requirements'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RaceDetailsToJson(RaceDetails instance) =>
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

TornSubcrimes _$TornSubcrimesFromJson(Map<String, dynamic> json) =>
    TornSubcrimes(
      subcrimes: (json['subcrimes'] as List<dynamic>?)
              ?.map((e) => TornSubcrime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornSubcrimesToJson(TornSubcrimes instance) =>
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

TornCrimes _$TornCrimesFromJson(Map<String, dynamic> json) => TornCrimes(
      crimes: (json['crimes'] as List<dynamic>?)
              ?.map((e) => TornCrime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornCrimesToJson(TornCrimes instance) =>
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

UserCrimeDetails _$UserCrimeDetailsFromJson(Map<String, dynamic> json) =>
    UserCrimeDetails(
      crimes: json['crimes'] == null
          ? null
          : UserCrime.fromJson(json['crimes'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCrimeDetailsToJson(UserCrimeDetails instance) =>
    <String, dynamic>{
      'crimes': instance.crimes?.toJson(),
    };

UserCrime _$UserCrimeFromJson(Map<String, dynamic> json) => UserCrime(
      nerveSpent: (json['nerve_spent'] as num?)?.toInt(),
      skill: (json['skill'] as num?)?.toInt(),
      progressionBonus: (json['progression_bonus'] as num?)?.toInt(),
      achievedUniques: (json['achieved_uniques'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
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
      'achieved_uniques': instance.achievedUniques,
      'rewards': instance.rewards?.toJson(),
      'attempts': instance.attempts?.toJson(),
      'uniques': instance.uniques?.map((e) => e.toJson()).toList(),
      'miscellaneous': instance.miscellaneous,
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

UserCalendar _$UserCalendarFromJson(Map<String, dynamic> json) => UserCalendar(
      startTime: json['start_time'] as String?,
    );

Map<String, dynamic> _$UserCalendarToJson(UserCalendar instance) =>
    <String, dynamic>{
      'start_time': instance.startTime,
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

UserItemMarkeListingItemDetails _$UserItemMarkeListingItemDetailsFromJson(
        Map<String, dynamic> json) =>
    UserItemMarkeListingItemDetails(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      type: json['type'] as String?,
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

FactionSelectionsHofGet$Response _$FactionSelectionsHofGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    FactionSelectionsHofGet$Response(
      hof: (json['hof'] as List<dynamic>?)
              ?.map((e) => FactionHofStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$FactionSelectionsHofGet$ResponseToJson(
        FactionSelectionsHofGet$Response instance) =>
    <String, dynamic>{
      'hof': instance.hof?.map((e) => e.toJson()).toList(),
    };

FactionSelectionsMembersGet$Response
    _$FactionSelectionsMembersGet$ResponseFromJson(Map<String, dynamic> json) =>
        FactionSelectionsMembersGet$Response(
          members: (json['members'] as List<dynamic>?)
                  ?.map(
                      (e) => FactionMember.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        );

Map<String, dynamic> _$FactionSelectionsMembersGet$ResponseToJson(
        FactionSelectionsMembersGet$Response instance) =>
    <String, dynamic>{
      'members': instance.members?.map((e) => e.toJson()).toList(),
    };

FactionSelectionsBasicGet$Response _$FactionSelectionsBasicGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    FactionSelectionsBasicGet$Response(
      basic: json['basic'] == null
          ? null
          : FactionBasic.fromJson(json['basic'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionSelectionsBasicGet$ResponseToJson(
        FactionSelectionsBasicGet$Response instance) =>
    <String, dynamic>{
      'basic': instance.basic?.toJson(),
    };

FactionSelectionsWarsGet$Response _$FactionSelectionsWarsGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    FactionSelectionsWarsGet$Response(
      pacts: (json['pacts'] as List<dynamic>?)
              ?.map((e) => FactionPact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      wars: json['wars'] == null
          ? null
          : FactionWars.fromJson(json['wars'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionSelectionsWarsGet$ResponseToJson(
        FactionSelectionsWarsGet$Response instance) =>
    <String, dynamic>{
      'pacts': instance.pacts?.map((e) => e.toJson()).toList(),
      'wars': instance.wars?.toJson(),
    };

FactionSelectionsNewsGet$Response _$FactionSelectionsNewsGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    FactionSelectionsNewsGet$Response(
      news: (json['news'] as List<dynamic>?)
              ?.map((e) => FactionNews.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['_metadata'] == null
          ? null
          : RequestMetadataWithLinks.fromJson(
              json['_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FactionSelectionsNewsGet$ResponseToJson(
        FactionSelectionsNewsGet$Response instance) =>
    <String, dynamic>{
      'news': instance.news?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

FactionSelectionsAttacksGet$Response
    _$FactionSelectionsAttacksGet$ResponseFromJson(Map<String, dynamic> json) =>
        FactionSelectionsAttacksGet$Response(
          attacks: (json['attacks'] as List<dynamic>?)
                  ?.map((e) => Attack.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
          metadata: json['_metadata'] == null
              ? null
              : RequestMetadataWithLinks.fromJson(
                  json['_metadata'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$FactionSelectionsAttacksGet$ResponseToJson(
        FactionSelectionsAttacksGet$Response instance) =>
    <String, dynamic>{
      'attacks': instance.attacks?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

FactionSelectionsAttacksfullGet$Response
    _$FactionSelectionsAttacksfullGet$ResponseFromJson(
            Map<String, dynamic> json) =>
        FactionSelectionsAttacksfullGet$Response(
          attacks: (json['attacks'] as List<dynamic>?)
                  ?.map((e) =>
                      AttackSimplified.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
          metadata: json['_metadata'] == null
              ? null
              : RequestMetadataWithLinks.fromJson(
                  json['_metadata'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$FactionSelectionsAttacksfullGet$ResponseToJson(
        FactionSelectionsAttacksfullGet$Response instance) =>
    <String, dynamic>{
      'attacks': instance.attacks?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
    };

ForumSelectionsThreadsGet$Response _$ForumSelectionsThreadsGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    ForumSelectionsThreadsGet$Response(
      threads: (json['threads'] as List<dynamic>?)
              ?.map((e) => ForumThreadBase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      links: json['_links'] == null
          ? null
          : RequestLinks.fromJson(json['_links'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumSelectionsThreadsGet$ResponseToJson(
        ForumSelectionsThreadsGet$Response instance) =>
    <String, dynamic>{
      'threads': instance.threads?.map((e) => e.toJson()).toList(),
      '_links': instance.links?.toJson(),
    };

ForumSelectionsThreadGet$Response _$ForumSelectionsThreadGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    ForumSelectionsThreadGet$Response(
      thread: json['thread'] == null
          ? null
          : ForumThreadExtended.fromJson(
              json['thread'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumSelectionsThreadGet$ResponseToJson(
        ForumSelectionsThreadGet$Response instance) =>
    <String, dynamic>{
      'thread': instance.thread?.toJson(),
    };

ForumSelectionsPostsGet$Response _$ForumSelectionsPostsGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    ForumSelectionsPostsGet$Response(
      posts: (json['posts'] as List<dynamic>?)
              ?.map((e) => ForumPost.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      links: json['_links'] == null
          ? null
          : RequestLinks.fromJson(json['_links'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ForumSelectionsPostsGet$ResponseToJson(
        ForumSelectionsPostsGet$Response instance) =>
    <String, dynamic>{
      'posts': instance.posts?.map((e) => e.toJson()).toList(),
      '_links': instance.links?.toJson(),
    };

MarketSelectionsItemmarketGet$Response
    _$MarketSelectionsItemmarketGet$ResponseFromJson(
            Map<String, dynamic> json) =>
        MarketSelectionsItemmarketGet$Response(
          itemmarket: json['itemmarket'] == null
              ? null
              : ItemMarket.fromJson(json['itemmarket'] as Map<String, dynamic>),
          metadata: json['_metadata'] == null
              ? null
              : RequestMetadataWithLinks.fromJson(
                  json['_metadata'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$MarketSelectionsItemmarketGet$ResponseToJson(
        MarketSelectionsItemmarketGet$Response instance) =>
    <String, dynamic>{
      'itemmarket': instance.itemmarket?.toJson(),
      '_metadata': instance.metadata?.toJson(),
    };

TornSelectionsCalendarGet$Response _$TornSelectionsCalendarGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    TornSelectionsCalendarGet$Response(
      calendar: json['calendar'] == null
          ? null
          : TornSelectionsCalendarGet$Response$Calendar.fromJson(
              json['calendar'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornSelectionsCalendarGet$ResponseToJson(
        TornSelectionsCalendarGet$Response instance) =>
    <String, dynamic>{
      'calendar': instance.calendar?.toJson(),
    };

TornSelectionsHofGet$Response _$TornSelectionsHofGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    TornSelectionsHofGet$Response(
      hof: (json['hof'] as List<dynamic>?)
              ?.map((e) => TornHof.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      links: json['_links'] == null
          ? null
          : RequestLinks.fromJson(json['_links'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornSelectionsHofGet$ResponseToJson(
        TornSelectionsHofGet$Response instance) =>
    <String, dynamic>{
      'hof': instance.hof?.map((e) => e.toJson()).toList(),
      '_links': instance.links?.toJson(),
    };

TornSelectionsFactionhofGet$Response
    _$TornSelectionsFactionhofGet$ResponseFromJson(Map<String, dynamic> json) =>
        TornSelectionsFactionhofGet$Response(
          factionhof: (json['factionhof'] as List<dynamic>?)
                  ?.map(
                      (e) => TornFactionHof.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
          links: json['_links'] == null
              ? null
              : RequestLinks.fromJson(json['_links'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$TornSelectionsFactionhofGet$ResponseToJson(
        TornSelectionsFactionhofGet$Response instance) =>
    <String, dynamic>{
      'factionhof': instance.factionhof?.map((e) => e.toJson()).toList(),
      '_links': instance.links?.toJson(),
    };

TornSelectionsLogtypesGet$Response _$TornSelectionsLogtypesGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    TornSelectionsLogtypesGet$Response(
      logtypes: (json['logtypes'] as List<dynamic>?)
              ?.map((e) => TornLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TornSelectionsLogtypesGet$ResponseToJson(
        TornSelectionsLogtypesGet$Response instance) =>
    <String, dynamic>{
      'logtypes': instance.logtypes?.map((e) => e.toJson()).toList(),
    };

TornSelectionsLogcategoriesGet$Response
    _$TornSelectionsLogcategoriesGet$ResponseFromJson(
            Map<String, dynamic> json) =>
        TornSelectionsLogcategoriesGet$Response(
          logcategories: (json['logcategories'] as List<dynamic>?)
                  ?.map((e) =>
                      TornLogCategory.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        );

Map<String, dynamic> _$TornSelectionsLogcategoriesGet$ResponseToJson(
        TornSelectionsLogcategoriesGet$Response instance) =>
    <String, dynamic>{
      'logcategories': instance.logcategories?.map((e) => e.toJson()).toList(),
    };

TornSelectionsBountiesGet$Response _$TornSelectionsBountiesGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    TornSelectionsBountiesGet$Response(
      bounties: (json['bounties'] as List<dynamic>?)
              ?.map((e) => Bounty.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      links: json['_links'] == null
          ? null
          : RequestLinks.fromJson(json['_links'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TornSelectionsBountiesGet$ResponseToJson(
        TornSelectionsBountiesGet$Response instance) =>
    <String, dynamic>{
      'bounties': instance.bounties?.map((e) => e.toJson()).toList(),
      '_links': instance.links?.toJson(),
    };

UserSelectionsForumpostsGet$Response
    _$UserSelectionsForumpostsGet$ResponseFromJson(Map<String, dynamic> json) =>
        UserSelectionsForumpostsGet$Response(
          forumPosts: (json['forumPosts'] as List<dynamic>?)
                  ?.map((e) => ForumPost.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
          links: json['_links'] == null
              ? null
              : RequestLinks.fromJson(json['_links'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$UserSelectionsForumpostsGet$ResponseToJson(
        UserSelectionsForumpostsGet$Response instance) =>
    <String, dynamic>{
      'forumPosts': instance.forumPosts?.map((e) => e.toJson()).toList(),
      '_links': instance.links?.toJson(),
    };

UserSelectionsForumthreadsGet$Response
    _$UserSelectionsForumthreadsGet$ResponseFromJson(
            Map<String, dynamic> json) =>
        UserSelectionsForumthreadsGet$Response(
          forumThreads: (json['forumThreads'] as List<dynamic>?)
                  ?.map((e) => ForumThreadUserExtended.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
          links: json['_links'] == null
              ? null
              : RequestLinks.fromJson(json['_links'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$UserSelectionsForumthreadsGet$ResponseToJson(
        UserSelectionsForumthreadsGet$Response instance) =>
    <String, dynamic>{
      'forumThreads': instance.forumThreads?.map((e) => e.toJson()).toList(),
      '_links': instance.links?.toJson(),
    };

UserSelectionsForumsubscribedthreadsGet$Response
    _$UserSelectionsForumsubscribedthreadsGet$ResponseFromJson(
            Map<String, dynamic> json) =>
        UserSelectionsForumsubscribedthreadsGet$Response(
          forumSubscribedThreads: (json['forumSubscribedThreads']
                      as List<dynamic>?)
                  ?.map((e) =>
                      ForumSubscribedThread.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        );

Map<String, dynamic> _$UserSelectionsForumsubscribedthreadsGet$ResponseToJson(
        UserSelectionsForumsubscribedthreadsGet$Response instance) =>
    <String, dynamic>{
      'forumSubscribedThreads':
          instance.forumSubscribedThreads?.map((e) => e.toJson()).toList(),
    };

UserSelectionsForumfeedGet$Response
    _$UserSelectionsForumfeedGet$ResponseFromJson(Map<String, dynamic> json) =>
        UserSelectionsForumfeedGet$Response(
          forumFeed: (json['forumFeed'] as List<dynamic>?)
                  ?.map((e) => ForumFeed.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        );

Map<String, dynamic> _$UserSelectionsForumfeedGet$ResponseToJson(
        UserSelectionsForumfeedGet$Response instance) =>
    <String, dynamic>{
      'forumFeed': instance.forumFeed?.map((e) => e.toJson()).toList(),
    };

UserSelectionsForumfriendsGet$Response
    _$UserSelectionsForumfriendsGet$ResponseFromJson(
            Map<String, dynamic> json) =>
        UserSelectionsForumfriendsGet$Response(
          forumFriends: (json['forumFriends'] as List<dynamic>?)
                  ?.map((e) => ForumFeed.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        );

Map<String, dynamic> _$UserSelectionsForumfriendsGet$ResponseToJson(
        UserSelectionsForumfriendsGet$Response instance) =>
    <String, dynamic>{
      'forumFriends': instance.forumFriends?.map((e) => e.toJson()).toList(),
    };

UserSelectionsHofGet$Response _$UserSelectionsHofGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    UserSelectionsHofGet$Response(
      hof: (json['hof'] as List<dynamic>?)
              ?.map((e) => UserHofStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserSelectionsHofGet$ResponseToJson(
        UserSelectionsHofGet$Response instance) =>
    <String, dynamic>{
      'hof': instance.hof?.map((e) => e.toJson()).toList(),
    };

UserSelectionsCalendarGet$Response _$UserSelectionsCalendarGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    UserSelectionsCalendarGet$Response(
      calendar: json['calendar'] == null
          ? null
          : UserCalendar.fromJson(json['calendar'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserSelectionsCalendarGet$ResponseToJson(
        UserSelectionsCalendarGet$Response instance) =>
    <String, dynamic>{
      'calendar': instance.calendar?.toJson(),
    };

UserSelectionsBountiesGet$Response _$UserSelectionsBountiesGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    UserSelectionsBountiesGet$Response(
      bounties: (json['bounties'] as List<dynamic>?)
              ?.map((e) => Bounty.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserSelectionsBountiesGet$ResponseToJson(
        UserSelectionsBountiesGet$Response instance) =>
    <String, dynamic>{
      'bounties': instance.bounties?.map((e) => e.toJson()).toList(),
    };

UserSelectionsJobranksGet$Response _$UserSelectionsJobranksGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    UserSelectionsJobranksGet$Response(
      jobranks: json['jobranks'] == null
          ? null
          : UserJobRanks.fromJson(json['jobranks'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserSelectionsJobranksGet$ResponseToJson(
        UserSelectionsJobranksGet$Response instance) =>
    <String, dynamic>{
      'jobranks': instance.jobranks?.toJson(),
    };

UserSelectionsItemmarketGet$Response
    _$UserSelectionsItemmarketGet$ResponseFromJson(Map<String, dynamic> json) =>
        UserSelectionsItemmarketGet$Response(
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

Map<String, dynamic> _$UserSelectionsItemmarketGet$ResponseToJson(
        UserSelectionsItemmarketGet$Response instance) =>
    <String, dynamic>{
      'itemmarket': instance.itemmarket?.map((e) => e.toJson()).toList(),
      '_metadata': instance.metadata?.toJson(),
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

ForumCategories$Categories$Item _$ForumCategories$Categories$ItemFromJson(
        Map<String, dynamic> json) =>
    ForumCategories$Categories$Item(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      acronym: json['acronym'] as String?,
      threads: (json['threads'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ForumCategories$Categories$ItemToJson(
        ForumCategories$Categories$Item instance) =>
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

RaceDetails$Participants _$RaceDetails$ParticipantsFromJson(
        Map<String, dynamic> json) =>
    RaceDetails$Participants(
      minimum: (json['minimum'] as num?)?.toInt(),
      maximum: (json['maximum'] as num?)?.toInt(),
      current: (json['current'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RaceDetails$ParticipantsToJson(
        RaceDetails$Participants instance) =>
    <String, dynamic>{
      'minimum': instance.minimum,
      'maximum': instance.maximum,
      'current': instance.current,
    };

RaceDetails$Schedule _$RaceDetails$ScheduleFromJson(
        Map<String, dynamic> json) =>
    RaceDetails$Schedule(
      joinFrom: (json['join_from'] as num?)?.toInt(),
      joinUntil: (json['join_until'] as num?)?.toInt(),
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RaceDetails$ScheduleToJson(
        RaceDetails$Schedule instance) =>
    <String, dynamic>{
      'join_from': instance.joinFrom,
      'join_until': instance.joinUntil,
      'start': instance.start,
      'end': instance.end,
    };

RaceDetails$Requirements _$RaceDetails$RequirementsFromJson(
        Map<String, dynamic> json) =>
    RaceDetails$Requirements(
      carClass: raceClassEnumNullableFromJson(json['car_class']),
      driverClass: raceClassEnumNullableFromJson(json['driver_class']),
      carItemId: (json['car_item_id'] as num?)?.toInt(),
      requiresStockCar: json['requires_stock_car'] as bool?,
      requiresPassword: json['requires_password'] as bool?,
      joinFee: (json['join_fee'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RaceDetails$RequirementsToJson(
        RaceDetails$Requirements instance) =>
    <String, dynamic>{
      'car_class': raceClassEnumNullableToJson(instance.carClass),
      'driver_class': raceClassEnumNullableToJson(instance.driverClass),
      'car_item_id': instance.carItemId,
      'requires_stock_car': instance.requiresStockCar,
      'requires_password': instance.requiresPassword,
      'join_fee': instance.joinFee,
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

TornSelectionsCalendarGet$Response$Calendar
    _$TornSelectionsCalendarGet$Response$CalendarFromJson(
            Map<String, dynamic> json) =>
        TornSelectionsCalendarGet$Response$Calendar(
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

Map<String, dynamic> _$TornSelectionsCalendarGet$Response$CalendarToJson(
        TornSelectionsCalendarGet$Response$Calendar instance) =>
    <String, dynamic>{
      'competitions': instance.competitions?.map((e) => e.toJson()).toList(),
      'events': instance.events?.map((e) => e.toJson()).toList(),
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
