// dart format width=80
//Generated code

part of 'torn_v2.swagger.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$TornV2 extends TornV2 {
  _$TornV2([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = TornV2;

  @override
  Future<Response<FactionAttacksResponse>> _userAttacksGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/attacks');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionAttacksResponse, FactionAttacksResponse>($request);
  }

  @override
  Future<Response<FactionAttacksFullResponse>> _userAttacksfullGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/attacksfull');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionAttacksFullResponse, FactionAttacksFullResponse>($request);
  }

  @override
  Future<Response<UserBountiesResponse>> _userBountiesGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/bounties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserBountiesResponse, UserBountiesResponse>($request);
  }

  @override
  Future<Response<UserBountiesResponse>> _userIdBountiesGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/${id}/bounties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserBountiesResponse, UserBountiesResponse>($request);
  }

  @override
  Future<Response<UserCalendarResponse>> _userCalendarGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/calendar');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserCalendarResponse, UserCalendarResponse>($request);
  }

  @override
  Future<Response<UserCrimesResponse>> _userCrimeIdCrimesGet({
    required int? crimeId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/${crimeId}/crimes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserCrimesResponse, UserCrimesResponse>($request);
  }

  @override
  Future<Response<UserEducationResponse>> _userEducationGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/education');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserEducationResponse, UserEducationResponse>($request);
  }

  @override
  Future<Response<UserEnlistedCarsResponse>> _userEnlistedcarsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/enlistedcars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserEnlistedCarsResponse, UserEnlistedCarsResponse>($request);
  }

  @override
  Future<Response<UserFactionBalanceResponse>> _userFactionbalanceGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/factionbalance');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserFactionBalanceResponse, UserFactionBalanceResponse>($request);
  }

  @override
  Future<Response<UserForumFeedResponse>> _userForumfeedGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/forumfeed');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserForumFeedResponse, UserForumFeedResponse>($request);
  }

  @override
  Future<Response<UserForumFriendsResponse>> _userForumfriendsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/forumfriends');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserForumFriendsResponse, UserForumFriendsResponse>($request);
  }

  @override
  Future<Response<UserForumPostsResponse>> _userForumpostsGet({
    String? striptags,
    int? limit,
    String? sort,
    int? from,
    int? to,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/forumposts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'striptags': striptags,
      'limit': limit,
      'sort': sort,
      'from': from,
      'to': to,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserForumPostsResponse, UserForumPostsResponse>($request);
  }

  @override
  Future<Response<UserForumPostsResponse>> _userIdForumpostsGet({
    String? striptags,
    required int? id,
    int? limit,
    String? sort,
    int? from,
    int? to,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/${id}/forumposts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'striptags': striptags,
      'limit': limit,
      'sort': sort,
      'from': from,
      'to': to,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserForumPostsResponse, UserForumPostsResponse>($request);
  }

  @override
  Future<Response<UserForumSubscribedThreadsResponse>> _userForumsubscribedthreadsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/forumsubscribedthreads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserForumSubscribedThreadsResponse, UserForumSubscribedThreadsResponse>($request);
  }

  @override
  Future<Response<UserForumThreadsResponse>> _userForumthreadsGet({
    int? limit,
    String? sort,
    int? from,
    int? to,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/forumthreads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'from': from,
      'to': to,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserForumThreadsResponse, UserForumThreadsResponse>($request);
  }

  @override
  Future<Response<UserForumThreadsResponse>> _userIdForumthreadsGet({
    required int? id,
    int? limit,
    String? sort,
    int? from,
    int? to,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/${id}/forumthreads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'from': from,
      'to': to,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserForumThreadsResponse, UserForumThreadsResponse>($request);
  }

  @override
  Future<Response<UserHofResponse>> _userHofGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/hof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserHofResponse, UserHofResponse>($request);
  }

  @override
  Future<Response<UserHofResponse>> _userIdHofGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/${id}/hof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserHofResponse, UserHofResponse>($request);
  }

  @override
  Future<Response<UserItemMarketResponse>> _userItemmarketGet({
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/itemmarket');
    final Map<String, dynamic> $params = <String, dynamic>{
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserItemMarketResponse, UserItemMarketResponse>($request);
  }

  @override
  Future<Response<UserJobRanksResponse>> _userJobranksGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/jobranks');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserJobRanksResponse, UserJobRanksResponse>($request);
  }

  @override
  Future<Response<UserListResponse>> _userListGet({
    required String? cat,
    int? limit,
    int? offset,
    String? sort,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/list');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'limit': limit,
      'offset': offset,
      'sort': sort,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserListResponse, UserListResponse>($request);
  }

  @override
  Future<Response<UserOrganizedCrimeResponse>> _userOrganizedcrimeGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/organizedcrime');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserOrganizedCrimeResponse, UserOrganizedCrimeResponse>($request);
  }

  @override
  Future<Response<UserPersonalStatsResponse>> _userPersonalstatsGet({
    String? cat,
    List<Object?>? stat,
    int? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/personalstats');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'stat': stat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserPersonalStatsResponse, UserPersonalStatsResponse>($request);
  }

  @override
  Future<Response<UserPersonalStatsResponse>> _userIdPersonalstatsGet({
    required int? id,
    String? cat,
    List<Object?>? stat,
    int? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/${id}/personalstats');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'stat': stat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserPersonalStatsResponse, UserPersonalStatsResponse>($request);
  }

  @override
  Future<Response<UserPropertiesResponse>> _userPropertiesGet({
    int? offset,
    int? limit,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/properties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserPropertiesResponse, UserPropertiesResponse>($request);
  }

  @override
  Future<Response<UserPropertiesResponse>> _userIdPropertiesGet({
    required int? id,
    int? offset,
    int? limit,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/${id}/properties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserPropertiesResponse, UserPropertiesResponse>($request);
  }

  @override
  Future<Response<UserPropertyResponse>> _userPropertyGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/property');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserPropertyResponse, UserPropertyResponse>($request);
  }

  @override
  Future<Response<UserPropertyResponse>> _userIdPropertyGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/${id}/property');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserPropertyResponse, UserPropertyResponse>($request);
  }

  @override
  Future<Response<UserRacesResponse>> _userRacesGet({
    int? limit,
    String? sort,
    int? from,
    int? to,
    String? cat,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/races');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'from': from,
      'to': to,
      'cat': cat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserRacesResponse, UserRacesResponse>($request);
  }

  @override
  Future<Response<UserRacingRecordsResponse>> _userRacingrecordsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/racingrecords');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserRacingRecordsResponse, UserRacingRecordsResponse>($request);
  }

  @override
  Future<Response<ReportsResponse>> _userReportsGet({
    String? cat,
    int? target,
    int? limit,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/reports');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'target': target,
      'limit': limit,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<ReportsResponse, ReportsResponse>($request);
  }

  @override
  Future<Response<RevivesResponse>> _userRevivesGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? striptags,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/revives');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'striptags': striptags,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RevivesResponse, RevivesResponse>($request);
  }

  @override
  Future<Response<RevivesFullResponse>> _userRevivesFullGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? striptags,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/revivesFull');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'striptags': striptags,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RevivesFullResponse, RevivesFullResponse>($request);
  }

  @override
  Future<Response<UserLookupResponse>> _userLookupGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserLookupResponse, UserLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _userTimestampGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _userGet({
    String? selections,
    Object? id,
    int? limit,
    int? from,
    int? to,
    String? sort,
    Object? cat,
    List<Object?>? stat,
    String? striptags,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/user');
    final Map<String, dynamic> $params = <String, dynamic>{
      'selections': selections,
      'id': id,
      'limit': limit,
      'from': from,
      'to': to,
      'sort': sort,
      'cat': cat,
      'stat': stat,
      'striptags': striptags,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<FactionApplicationsResponse>> _factionApplicationsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/applications');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionApplicationsResponse, FactionApplicationsResponse>($request);
  }

  @override
  Future<Response<FactionAttacksResponse>> _factionAttacksGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/attacks');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionAttacksResponse, FactionAttacksResponse>($request);
  }

  @override
  Future<Response<FactionAttacksFullResponse>> _factionAttacksfullGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/attacksfull');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionAttacksFullResponse, FactionAttacksFullResponse>($request);
  }

  @override
  Future<Response<FactionBalanceResponse>> _factionBalanceGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/balance');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionBalanceResponse, FactionBalanceResponse>($request);
  }

  @override
  Future<Response<FactionBasicResponse>> _factionBasicGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/basic');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionBasicResponse, FactionBasicResponse>($request);
  }

  @override
  Future<Response<FactionBasicResponse>> _factionIdBasicGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/basic');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionBasicResponse, FactionBasicResponse>($request);
  }

  @override
  Future<Response<FactionOngoingChainResponse>> _factionChainGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/chain');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionOngoingChainResponse, FactionOngoingChainResponse>($request);
  }

  @override
  Future<Response<FactionOngoingChainResponse>> _factionIdChainGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/chain');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionOngoingChainResponse, FactionOngoingChainResponse>($request);
  }

  @override
  Future<Response<FactionChainsResponse>> _factionChainsGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/chains');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionChainsResponse, FactionChainsResponse>($request);
  }

  @override
  Future<Response<FactionChainsResponse>> _factionIdChainsGet({
    required int? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/chains');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionChainsResponse, FactionChainsResponse>($request);
  }

  @override
  Future<Response<FactionChainReportResponse>> _factionChainreportGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/chainreport');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionChainReportResponse, FactionChainReportResponse>($request);
  }

  @override
  Future<Response<FactionChainReportResponse>> _factionChainIdChainreportGet({
    required int? chainId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${chainId}/chainreport');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionChainReportResponse, FactionChainReportResponse>($request);
  }

  @override
  Future<Response<FactionContributorsResponse>> _factionContributorsGet({
    required String? stat,
    String? cat,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/contributors');
    final Map<String, dynamic> $params = <String, dynamic>{
      'stat': stat,
      'cat': cat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionContributorsResponse, FactionContributorsResponse>($request);
  }

  @override
  Future<Response<FactionCrimesResponse>> _factionCrimesGet({
    String? cat,
    String? filters,
    int? offset,
    int? from,
    int? to,
    String? sort,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/crimes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'filters': filters,
      'offset': offset,
      'from': from,
      'to': to,
      'sort': sort,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionCrimesResponse, FactionCrimesResponse>($request);
  }

  @override
  Future<Response<FactionCrimeResponse>> _factionCrimeIdCrimeGet({
    required int? crimeId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${crimeId}/crime');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionCrimeResponse, FactionCrimeResponse>($request);
  }

  @override
  Future<Response<FactionHofResponse>> _factionHofGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/hof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionHofResponse, FactionHofResponse>($request);
  }

  @override
  Future<Response<FactionHofResponse>> _factionIdHofGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/hof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionHofResponse, FactionHofResponse>($request);
  }

  @override
  Future<Response<FactionMembersResponse>> _factionMembersGet({
    String? striptags,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/members');
    final Map<String, dynamic> $params = <String, dynamic>{
      'striptags': striptags,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionMembersResponse, FactionMembersResponse>($request);
  }

  @override
  Future<Response<FactionMembersResponse>> _factionIdMembersGet({
    required int? id,
    String? striptags,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/members');
    final Map<String, dynamic> $params = <String, dynamic>{
      'striptags': striptags,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionMembersResponse, FactionMembersResponse>($request);
  }

  @override
  Future<Response<FactionNewsResponse>> _factionNewsGet({
    String? striptags,
    int? limit,
    String? sort,
    int? to,
    int? from,
    required String? cat,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/news');
    final Map<String, dynamic> $params = <String, dynamic>{
      'striptags': striptags,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'cat': cat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionNewsResponse, FactionNewsResponse>($request);
  }

  @override
  Future<Response<FactionPositionsResponse>> _factionPositionsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/positions');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionPositionsResponse, FactionPositionsResponse>($request);
  }

  @override
  Future<Response<FactionRacketsResponse>> _factionRacketsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/rackets');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionRacketsResponse, FactionRacketsResponse>($request);
  }

  @override
  Future<Response<FactionRaidWarReportResponse>> _factionRaidWarIdRaidreportGet({
    required int? raidWarId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${raidWarId}/raidreport');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionRaidWarReportResponse, FactionRaidWarReportResponse>($request);
  }

  @override
  Future<Response<FactionRaidsResponse>> _factionRaidsGet({
    int? from,
    int? to,
    String? sort,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/raids');
    final Map<String, dynamic> $params = <String, dynamic>{
      'from': from,
      'to': to,
      'sort': sort,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionRaidsResponse, FactionRaidsResponse>($request);
  }

  @override
  Future<Response<FactionRaidsResponse>> _factionIdRaidsGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/raids');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionRaidsResponse, FactionRaidsResponse>($request);
  }

  @override
  Future<Response<FactionRankedWarResponse>> _factionRankedwarsGet({
    String? cat,
    int? from,
    int? to,
    String? sort,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/rankedwars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'from': from,
      'to': to,
      'sort': sort,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionRankedWarResponse, FactionRankedWarResponse>($request);
  }

  @override
  Future<Response<FactionRankedWarResponse>> _factionIdRankedwarsGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/rankedwars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionRankedWarResponse, FactionRankedWarResponse>($request);
  }

  @override
  Future<Response<FactionRankedWarReportResponse>> _factionRankedWarIdRankedwarreportGet({
    required int? rankedWarId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${rankedWarId}/rankedwarreport');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionRankedWarReportResponse, FactionRankedWarReportResponse>($request);
  }

  @override
  Future<Response<ReportsResponse>> _factionReportsGet({
    String? cat,
    int? target,
    int? limit,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/reports');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'target': target,
      'limit': limit,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<ReportsResponse, ReportsResponse>($request);
  }

  @override
  Future<Response<RevivesResponse>> _factionRevivesGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? striptags,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/revives');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'striptags': striptags,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RevivesResponse, RevivesResponse>($request);
  }

  @override
  Future<Response<RevivesFullResponse>> _factionRevivesFullGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? striptags,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/revivesFull');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'striptags': striptags,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RevivesFullResponse, RevivesFullResponse>($request);
  }

  @override
  Future<Response<FactionSearchResponse>> _factionSearchGet({
    String? name,
    List<dynamic>? filters,
    int? limit,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/search');
    final Map<String, dynamic> $params = <String, dynamic>{
      'name': name,
      'filters': filters,
      'limit': limit,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionSearchResponse, FactionSearchResponse>($request);
  }

  @override
  Future<Response<FactionStatsResponse>> _factionStatsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/stats');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionStatsResponse, FactionStatsResponse>($request);
  }

  @override
  Future<Response<FactionTerritoriesResponse>> _factionTerritoryGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/territory');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionTerritoriesResponse, FactionTerritoriesResponse>($request);
  }

  @override
  Future<Response<FactionTerritoriesResponse>> _factionIdTerritoryGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/territory');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionTerritoriesResponse, FactionTerritoriesResponse>($request);
  }

  @override
  Future<Response<FactionTerritoriesOwnershipResponse>> _factionTerritoryownershipGet({
    int? offset,
    int? limit,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/territoryownership');
    final Map<String, dynamic> $params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionTerritoriesOwnershipResponse, FactionTerritoriesOwnershipResponse>($request);
  }

  @override
  Future<Response<FactionTerritoryWarsResponse>> _factionTerritorywarsGet({
    String? cat,
    int? from,
    int? to,
    String? sort,
    int? limit,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/territorywars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'from': from,
      'to': to,
      'sort': sort,
      'limit': limit,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionTerritoryWarsResponse, FactionTerritoryWarsResponse>($request);
  }

  @override
  Future<Response<FactionTerritoryWarsHistoryResponse>> _factionIdTerritorywarsGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/territorywars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionTerritoryWarsHistoryResponse, FactionTerritoryWarsHistoryResponse>($request);
  }

  @override
  Future<Response<FactionTerritoryWarReportResponse>> _factionTerritoryWarIdTerritorywarreportGet({
    required int? territoryWarId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${territoryWarId}/territorywarreport');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionTerritoryWarReportResponse, FactionTerritoryWarReportResponse>($request);
  }

  @override
  Future<Response<FactionUpgradesResponse>> _factionUpgradesGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/upgrades');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionUpgradesResponse, FactionUpgradesResponse>($request);
  }

  @override
  Future<Response<FactionWarfareResponse>> _factionWarfareGet({
    required String? cat,
    int? limit,
    String? sort,
    int? from,
    int? to,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/warfare');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'limit': limit,
      'sort': sort,
      'from': from,
      'to': to,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionWarfareResponse, FactionWarfareResponse>($request);
  }

  @override
  Future<Response<FactionWarsResponse>> _factionWarsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/wars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionWarsResponse, FactionWarsResponse>($request);
  }

  @override
  Future<Response<FactionWarsResponse>> _factionIdWarsGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/wars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionWarsResponse, FactionWarsResponse>($request);
  }

  @override
  Future<Response<FactionLookupResponse>> _factionLookupGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<FactionLookupResponse, FactionLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _factionTimestampGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _factionGet({
    List<FactionSelectionName>? selections,
    Object? id,
    int? limit,
    int? from,
    int? to,
    Object? cat,
    String? stat,
    String? filters,
    String? striptags,
    String? sort,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/faction');
    final Map<String, dynamic> $params = <String, dynamic>{
      'selections': selections,
      'id': id,
      'limit': limit,
      'from': from,
      'to': to,
      'cat': cat,
      'stat': stat,
      'filters': filters,
      'striptags': striptags,
      'sort': sort,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<ForumCategoriesResponse>> _forumCategoriesGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/forum/categories');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<ForumCategoriesResponse, ForumCategoriesResponse>($request);
  }

  @override
  Future<Response<ForumPostsResponse>> _forumThreadIdPostsGet({
    int? offset,
    String? striptags,
    required int? threadId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/forum/${threadId}/posts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'offset': offset,
      'striptags': striptags,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<ForumPostsResponse, ForumPostsResponse>($request);
  }

  @override
  Future<Response<ForumThreadResponse>> _forumThreadIdThreadGet({
    required int? threadId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/forum/${threadId}/thread');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<ForumThreadResponse, ForumThreadResponse>($request);
  }

  @override
  Future<Response<ForumThreadsResponse>> _forumThreadsGet({
    int? limit,
    String? sort,
    int? from,
    int? to,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/forum/threads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'from': from,
      'to': to,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<ForumThreadsResponse, ForumThreadsResponse>($request);
  }

  @override
  Future<Response<ForumThreadsResponse>> _forumCategoryIdsThreadsGet({
    int? limit,
    String? sort,
    int? from,
    int? to,
    required List<int>? categoryIds,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/forum/${categoryIds}/threads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'from': from,
      'to': to,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<ForumThreadsResponse, ForumThreadsResponse>($request);
  }

  @override
  Future<Response<ForumLookupResponse>> _forumLookupGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/forum/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<ForumLookupResponse, ForumLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _forumTimestampGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/forum/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _forumGet({
    List<ForumSelectionName>? selections,
    Object? id,
    String? striptags,
    int? limit,
    String? sort,
    int? from,
    int? to,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/forum');
    final Map<String, dynamic> $params = <String, dynamic>{
      'selections': selections,
      'id': id,
      'striptags': striptags,
      'limit': limit,
      'sort': sort,
      'from': from,
      'to': to,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<KeyLogResponse>> _keyLogGet({
    int? limit,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/key/log');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<KeyLogResponse, KeyLogResponse>($request);
  }

  @override
  Future<Response<KeyInfoResponse>> _keyInfoGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/key/info');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<KeyInfoResponse, KeyInfoResponse>($request);
  }

  @override
  Future<Response<dynamic>> _keyGet({
    List<KeySelectionName>? selections,
    int? limit,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/key');
    final Map<String, dynamic> $params = <String, dynamic>{
      'selections': selections,
      'limit': limit,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<BazaarResponse>> _marketBazaarGet({
    String? cat,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/market/bazaar');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<BazaarResponse, BazaarResponse>($request);
  }

  @override
  Future<Response<BazaarResponseSpecialized>> _marketIdBazaarGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/market/${id}/bazaar');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<BazaarResponseSpecialized, BazaarResponseSpecialized>($request);
  }

  @override
  Future<Response<MarketItemMarketResponse>> _marketIdItemmarketGet({
    required int? id,
    String? bonus,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/market/${id}/itemmarket');
    final Map<String, dynamic> $params = <String, dynamic>{
      'bonus': bonus,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<MarketItemMarketResponse, MarketItemMarketResponse>($request);
  }

  @override
  Future<Response<MarketPropertiesResponse>> _marketPropertyTypeIdPropertiesGet({
    required int? propertyTypeId,
    int? offset,
    int? limit,
    String? sort,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/market/${propertyTypeId}/properties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
      'sort': sort,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<MarketPropertiesResponse, MarketPropertiesResponse>($request);
  }

  @override
  Future<Response<MarketRentalsResponse>> _marketPropertyTypeIdRentalsGet({
    required int? propertyTypeId,
    int? offset,
    int? limit,
    String? sort,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/market/${propertyTypeId}/rentals');
    final Map<String, dynamic> $params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
      'sort': sort,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<MarketRentalsResponse, MarketRentalsResponse>($request);
  }

  @override
  Future<Response<MarketLookupResponse>> _marketLookupGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/market/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<MarketLookupResponse, MarketLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _marketTimestampGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/market/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _marketGet({
    List<MarketSelectionName>? selections,
    Object? id,
    String? cat,
    String? bonus,
    String? sort,
    int? offset,
    int? limit,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/market');
    final Map<String, dynamic> $params = <String, dynamic>{
      'selections': selections,
      'id': id,
      'cat': cat,
      'bonus': bonus,
      'sort': sort,
      'offset': offset,
      'limit': limit,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<RacingCarsResponse>> _racingCarsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/racing/cars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RacingCarsResponse, RacingCarsResponse>($request);
  }

  @override
  Future<Response<RacingCarUpgradesResponse>> _racingCarupgradesGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/racing/carupgrades');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RacingCarUpgradesResponse, RacingCarUpgradesResponse>($request);
  }

  @override
  Future<Response<RacingRacesResponse>> _racingRacesGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? cat,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/racing/races');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'cat': cat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RacingRacesResponse, RacingRacesResponse>($request);
  }

  @override
  Future<Response<RacingRaceDetailsResponse>> _racingRaceIdRaceGet({
    required int? raceId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/racing/${raceId}/race');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RacingRaceDetailsResponse, RacingRaceDetailsResponse>($request);
  }

  @override
  Future<Response<RacingTrackRecordsResponse>> _racingTrackIdRecordsGet({
    required int? trackId,
    required String? cat,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/racing/${trackId}/records');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RacingTrackRecordsResponse, RacingTrackRecordsResponse>($request);
  }

  @override
  Future<Response<RacingTracksResponse>> _racingTracksGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/racing/tracks');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RacingTracksResponse, RacingTracksResponse>($request);
  }

  @override
  Future<Response<RacingLookupResponse>> _racingLookupGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/racing/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<RacingLookupResponse, RacingLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _racingTimestampGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/racing/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _racingGet({
    List<RacingSelectionName>? selections,
    Object? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
    Object? cat,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/racing');
    final Map<String, dynamic> $params = <String, dynamic>{
      'selections': selections,
      'id': id,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'cat': cat,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<UserPropertyResponse>> _propertyIdPropertyGet({
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/property/${id}/property');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<UserPropertyResponse, UserPropertyResponse>($request);
  }

  @override
  Future<Response<PropertyLookupResponse>> _propertyLookupGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/property/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<PropertyLookupResponse, PropertyLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _propertyTimestampGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/property/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _propertyGet({
    List<PropertySelectionName>? selections,
    required int? id,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/property');
    final Map<String, dynamic> $params = <String, dynamic>{
      'selections': selections,
      'id': id,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<AttackLogResponse>> _tornAttacklogGet({
    required String? log,
    int? offset,
    String? sort,
    String? striptags,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/attacklog');
    final Map<String, dynamic> $params = <String, dynamic>{
      'log': log,
      'offset': offset,
      'sort': sort,
      'striptags': striptags,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<AttackLogResponse, AttackLogResponse>($request);
  }

  @override
  Future<Response<TornBountiesResponse>> _tornBountiesGet({
    int? limit,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/bounties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornBountiesResponse, TornBountiesResponse>($request);
  }

  @override
  Future<Response<TornCalendarResponse>> _tornCalendarGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/calendar');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornCalendarResponse, TornCalendarResponse>($request);
  }

  @override
  Future<Response<TornCrimesResponse>> _tornCrimesGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/crimes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornCrimesResponse, TornCrimesResponse>($request);
  }

  @override
  Future<Response<TornEducationResponse>> _tornEducationGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/education');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornEducationResponse, TornEducationResponse>($request);
  }

  @override
  Future<Response<TornFactionHofResponse>> _tornFactionhofGet({
    int? limit,
    int? offset,
    required String? cat,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/factionhof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'cat': cat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornFactionHofResponse, TornFactionHofResponse>($request);
  }

  @override
  Future<Response<TornFactionTreeResponse>> _tornFactiontreeGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/factiontree');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornFactionTreeResponse, TornFactionTreeResponse>($request);
  }

  @override
  Future<Response<TornHofResponse>> _tornHofGet({
    int? limit,
    int? offset,
    required String? cat,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/hof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'cat': cat,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornHofResponse, TornHofResponse>($request);
  }

  @override
  Future<Response<TornItemAmmoResponse>> _tornItemammoGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/itemammo');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornItemAmmoResponse, TornItemAmmoResponse>($request);
  }

  @override
  Future<Response<TornItemModsResponse>> _tornItemmodsGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/itemmods');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornItemModsResponse, TornItemModsResponse>($request);
  }

  @override
  Future<Response<TornItemsResponse>> _tornItemsGet({
    String? cat,
    String? sort,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/items');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'sort': sort,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornItemsResponse, TornItemsResponse>($request);
  }

  @override
  Future<Response<TornItemsResponse>> _tornIdsItemsGet({
    required List<int>? ids,
    String? sort,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/${ids}/items');
    final Map<String, dynamic> $params = <String, dynamic>{
      'sort': sort,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornItemsResponse, TornItemsResponse>($request);
  }

  @override
  Future<Response<TornLogCategoriesResponse>> _tornLogcategoriesGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/logcategories');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornLogCategoriesResponse, TornLogCategoriesResponse>($request);
  }

  @override
  Future<Response<TornLogTypesResponse>> _tornLogtypesGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/logtypes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornLogTypesResponse, TornLogTypesResponse>($request);
  }

  @override
  Future<Response<TornLogTypesResponse>> _tornLogCategoryIdLogtypesGet({
    required int? logCategoryId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/${logCategoryId}/logtypes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornLogTypesResponse, TornLogTypesResponse>($request);
  }

  @override
  Future<Response<TornOrganizedCrimeResponse>> _tornOrganizedcrimesGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/organizedcrimes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornOrganizedCrimeResponse, TornOrganizedCrimeResponse>($request);
  }

  @override
  Future<Response<TornProperties>> _tornPropertiesGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/properties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornProperties, TornProperties>($request);
  }

  @override
  Future<Response<TornSubcrimesResponse>> _tornCrimeIdSubcrimesGet({
    required int? crimeId,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/${crimeId}/subcrimes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornSubcrimesResponse, TornSubcrimesResponse>($request);
  }

  @override
  Future<Response<TornTerritoriesResponse>> _tornTerritoryGet({
    List<Object?>? ids,
    int? offset,
    int? limit,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/territory');
    final Map<String, dynamic> $params = <String, dynamic>{
      'ids': ids,
      'offset': offset,
      'limit': limit,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornTerritoriesResponse, TornTerritoriesResponse>($request);
  }

  @override
  Future<Response<TornLookupResponse>> _tornLookupGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TornLookupResponse, TornLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _tornTimestampGet({
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _tornGet({
    List<TornSelectionName>? selections,
    Object? id,
    String? striptags,
    int? limit,
    int? to,
    int? from,
    String? sort,
    Object? cat,
    int? offset,
    String? timestamp,
    String? comment,
    String? key,
  }) {
    final Uri $url = Uri.parse('/torn');
    final Map<String, dynamic> $params = <String, dynamic>{
      'selections': selections,
      'id': id,
      'striptags': striptags,
      'limit': limit,
      'to': to,
      'from': from,
      'sort': sort,
      'cat': cat,
      'offset': offset,
      'timestamp': timestamp,
      'comment': comment,
      'key': key,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App', 'legacy': apiV2LegacyRequests},
    );
    return client.send<dynamic, dynamic>($request);
  }
}
