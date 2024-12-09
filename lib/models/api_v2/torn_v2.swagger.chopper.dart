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
  Future<Response<FactionHofResponse>> _factionIdHofGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/hof');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionHofResponse, FactionHofResponse>($request);
  }

  @override
  Future<Response<FactionHofResponse>> _factionHofGet({required String? key}) {
    final Uri $url = Uri.parse('/faction/hof');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionHofResponse, FactionHofResponse>($request);
  }

  @override
  Future<Response<FactionMembersResponse>> _factionIdMembersGet({
    required String? key,
    required int? id,
    String? striptags,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/members');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'striptags': striptags,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionMembersResponse, FactionMembersResponse>($request);
  }

  @override
  Future<Response<FactionMembersResponse>> _factionMembersGet({
    required String? key,
    String? striptags,
  }) {
    final Uri $url = Uri.parse('/faction/members');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'striptags': striptags,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionMembersResponse, FactionMembersResponse>($request);
  }

  @override
  Future<Response<FactionBasicResponse>> _factionIdBasicGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/basic');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionBasicResponse, FactionBasicResponse>($request);
  }

  @override
  Future<Response<FactionBasicResponse>> _factionBasicGet({required String? key}) {
    final Uri $url = Uri.parse('/faction/basic');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionBasicResponse, FactionBasicResponse>($request);
  }

  @override
  Future<Response<FactionWarsResponse>> _factionIdWarsGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/wars');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionWarsResponse, FactionWarsResponse>($request);
  }

  @override
  Future<Response<FactionWarsResponse>> _factionWarsGet({required String? key}) {
    final Uri $url = Uri.parse('/faction/wars');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionWarsResponse, FactionWarsResponse>($request);
  }

  @override
  Future<Response<FactionNewsResponse>> _factionNewsGet({
    required String? key,
    String? striptags,
    int? limit,
    String? sort,
    int? to,
    int? from,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/faction/news');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'striptags': striptags,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'cat': cat,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionNewsResponse, FactionNewsResponse>($request);
  }

  @override
  Future<Response<FactionAttacksResponse>> _factionAttacksGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/attacks');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionAttacksResponse, FactionAttacksResponse>($request);
  }

  @override
  Future<Response<FactionAttacksFullResponse>> _factionAttacksfullGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/attacksfull');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionAttacksFullResponse, FactionAttacksFullResponse>($request);
  }

  @override
  Future<Response<FactionApplicationsResponse>> _factionApplicationsGet({required String? key}) {
    final Uri $url = Uri.parse('/faction/applications');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionApplicationsResponse, FactionApplicationsResponse>($request);
  }

  @override
  Future<Response<FactionOngoingChainResponse>> _factionIdChainGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/chain');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionOngoingChainResponse, FactionOngoingChainResponse>($request);
  }

  @override
  Future<Response<FactionOngoingChainResponse>> _factionChainGet({required String? key}) {
    final Uri $url = Uri.parse('/faction/chain');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionOngoingChainResponse, FactionOngoingChainResponse>($request);
  }

  @override
  Future<Response<FactionChainsResponse>> _factionIdChainsGet({
    required String? key,
    required int? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/chains');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionChainsResponse, FactionChainsResponse>($request);
  }

  @override
  Future<Response<FactionChainsResponse>> _factionChainsGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/chains');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionChainsResponse, FactionChainsResponse>($request);
  }

  @override
  Future<Response<FactionChainReportResponse>> _factionChainIdChainreportGet({
    required String? key,
    required int? chainId,
  }) {
    final Uri $url = Uri.parse('/faction/${chainId}/chainreport');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionChainReportResponse, FactionChainReportResponse>($request);
  }

  @override
  Future<Response<FactionChainReportResponse>> _factionChainreportGet({required String? key}) {
    final Uri $url = Uri.parse('/faction/chainreport');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionChainReportResponse, FactionChainReportResponse>($request);
  }

  @override
  Future<Response<FactionLookupResponse>> _factionLookupGet({required String? key}) {
    final Uri $url = Uri.parse('/faction/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionLookupResponse, FactionLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _factionTimestampGet({required String? key}) {
    final Uri $url = Uri.parse('/faction/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _factionGet({
    required String? key,
    List<Object?>? selections,
    String? id,
    int? limit,
    int? to,
    int? from,
    String? cat,
    String? striptags,
    String? sort,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/faction');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'selections': selections,
      'id': id,
      'limit': limit,
      'to': to,
      'from': from,
      'cat': cat,
      'striptags': striptags,
      'sort': sort,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<ForumCategoriesResponse>> _forumCategoriesGet({required String? key}) {
    final Uri $url = Uri.parse('/forum/categories');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumCategoriesResponse, ForumCategoriesResponse>($request);
  }

  @override
  Future<Response<ForumThreadsResponse>> _forumCategoryIdsThreadsGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
    required List<int>? categoryIds,
  }) {
    final Uri $url = Uri.parse('/forum/${categoryIds}/threads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumThreadsResponse, ForumThreadsResponse>($request);
  }

  @override
  Future<Response<ForumThreadsResponse>> _forumThreadsGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/forum/threads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumThreadsResponse, ForumThreadsResponse>($request);
  }

  @override
  Future<Response<ForumThreadResponse>> _forumThreadIdThreadGet({
    required String? key,
    required int? threadId,
  }) {
    final Uri $url = Uri.parse('/forum/${threadId}/thread');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumThreadResponse, ForumThreadResponse>($request);
  }

  @override
  Future<Response<ForumPostsResponse>> _forumThreadIdPostsGet({
    required String? key,
    int? offset,
    String? striptags,
    required int? threadId,
  }) {
    final Uri $url = Uri.parse('/forum/${threadId}/posts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'offset': offset,
      'striptags': striptags,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumPostsResponse, ForumPostsResponse>($request);
  }

  @override
  Future<Response<ForumLookupResponse>> _forumLookupGet({required String? key}) {
    final Uri $url = Uri.parse('/forum/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumLookupResponse, ForumLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _forumTimestampGet({required String? key}) {
    final Uri $url = Uri.parse('/forum/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _forumGet({
    required String? key,
    List<Object?>? selections,
    String? id,
    String? striptags,
    int? limit,
    int? to,
    int? from,
    String? cat,
    String? sort,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/forum');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'selections': selections,
      'id': id,
      'striptags': striptags,
      'limit': limit,
      'to': to,
      'from': from,
      'cat': cat,
      'sort': sort,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<MarketItemMarketResponse>> _marketIdItemmarketGet({
    required String? key,
    required int? id,
    String? bonus,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/market/${id}/itemmarket');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'bonus': bonus,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<MarketItemMarketResponse, MarketItemMarketResponse>($request);
  }

  @override
  Future<Response<MarketLookupResponse>> _marketLookupGet({required String? key}) {
    final Uri $url = Uri.parse('/market/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<MarketLookupResponse, MarketLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _marketTimestampGet({required String? key}) {
    final Uri $url = Uri.parse('/market/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _marketGet({
    required String? key,
    List<Object?>? selections,
    String? id,
    String? bonus,
    String? cat,
    String? sort,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/market');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'selections': selections,
      'id': id,
      'bonus': bonus,
      'cat': cat,
      'sort': sort,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<RacingRacesResponse>> _racingRacesGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? cat,
  }) {
    final Uri $url = Uri.parse('/racing/races');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'cat': cat,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RacingRacesResponse, RacingRacesResponse>($request);
  }

  @override
  Future<Response<RacingTrackRecordsResponse>> _racingTrackIdRecordsGet({
    required String? key,
    required int? trackId,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/racing/${trackId}/records');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'cat': cat,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RacingTrackRecordsResponse, RacingTrackRecordsResponse>($request);
  }

  @override
  Future<Response<RacingRaceDetailsResponse>> _racingRaceIdRaceGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/racing/{raceId}/race');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RacingRaceDetailsResponse, RacingRaceDetailsResponse>($request);
  }

  @override
  Future<Response<RacingCarsResponse>> _racingCarsGet({required String? key}) {
    final Uri $url = Uri.parse('/racing/cars');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RacingCarsResponse, RacingCarsResponse>($request);
  }

  @override
  Future<Response<RacingTracksResponse>> _racingTracksGet({required String? key}) {
    final Uri $url = Uri.parse('/racing/tracks');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RacingTracksResponse, RacingTracksResponse>($request);
  }

  @override
  Future<Response<RacingCarUpgradesResponse>> _racingCarupgradesGet({required String? key}) {
    final Uri $url = Uri.parse('/racing/carupgrades');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RacingCarUpgradesResponse, RacingCarUpgradesResponse>($request);
  }

  @override
  Future<Response<RacingLookupResponse>> _racingLookupGet({required String? key}) {
    final Uri $url = Uri.parse('/racing/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RacingLookupResponse, RacingLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _racingTimestampGet({required String? key}) {
    final Uri $url = Uri.parse('/racing/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _racingGet({
    required String? key,
    List<Object?>? selections,
    String? id,
    int? limit,
    int? to,
    int? from,
    String? cat,
    String? sort,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/racing');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'selections': selections,
      'id': id,
      'limit': limit,
      'to': to,
      'from': from,
      'cat': cat,
      'sort': sort,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<TornSubcrimesResponse>> _tornCrimeIdSubcrimesGet({
    required String? key,
    required String? crimeId,
  }) {
    final Uri $url = Uri.parse('/torn/${crimeId}/subcrimes');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornSubcrimesResponse, TornSubcrimesResponse>($request);
  }

  @override
  Future<Response<TornCrimesResponse>> _tornCrimesGet({required String? key}) {
    final Uri $url = Uri.parse('/torn/crimes');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornCrimesResponse, TornCrimesResponse>($request);
  }

  @override
  Future<Response<TornCalendarResponse>> _tornCalendarGet({required String? key}) {
    final Uri $url = Uri.parse('/torn/calendar');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornCalendarResponse, TornCalendarResponse>($request);
  }

  @override
  Future<Response<TornHofResponse>> _tornHofGet({
    required String? key,
    int? limit,
    int? offset,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/torn/hof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'offset': offset,
      'cat': cat,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornHofResponse, TornHofResponse>($request);
  }

  @override
  Future<Response<TornFactionHofResponse>> _tornFactionhofGet({
    required String? key,
    int? limit,
    int? offset,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/torn/factionhof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'offset': offset,
      'cat': cat,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornFactionHofResponse, TornFactionHofResponse>($request);
  }

  @override
  Future<Response<TornLogTypesResponse>> _tornLogCategoryIdLogtypesGet({
    required String? key,
    required int? logCategoryId,
  }) {
    final Uri $url = Uri.parse('/torn/${logCategoryId}/logtypes');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornLogTypesResponse, TornLogTypesResponse>($request);
  }

  @override
  Future<Response<TornLogTypesResponse>> _tornLogtypesGet({required String? key}) {
    final Uri $url = Uri.parse('/torn/logtypes');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornLogTypesResponse, TornLogTypesResponse>($request);
  }

  @override
  Future<Response<TornLogCategoriesResponse>> _tornLogcategoriesGet({required String? key}) {
    final Uri $url = Uri.parse('/torn/logcategories');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornLogCategoriesResponse, TornLogCategoriesResponse>($request);
  }

  @override
  Future<Response<TornBountiesResponse>> _tornBountiesGet({
    required String? key,
    int? limit,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/torn/bounties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornBountiesResponse, TornBountiesResponse>($request);
  }

  @override
  Future<Response<TornLookupResponse>> _tornLookupGet({required String? key}) {
    final Uri $url = Uri.parse('/torn/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornLookupResponse, TornLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _tornTimestampGet({required String? key}) {
    final Uri $url = Uri.parse('/torn/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _tornGet({
    required String? key,
    List<Object?>? selections,
    String? id,
    String? striptags,
    int? limit,
    int? to,
    int? from,
    String? cat,
    String? sort,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/torn');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'selections': selections,
      'id': id,
      'striptags': striptags,
      'limit': limit,
      'to': to,
      'from': from,
      'cat': cat,
      'sort': sort,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<UserPersonalStatsResponse>> _userIdPersonalstatsGet({
    required String? key,
    required int? id,
    String? cat,
    List<Object?>? stat,
    int? timestamp,
  }) {
    final Uri $url = Uri.parse('/user/${id}/personalstats');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'cat': cat,
      'stat': stat,
      'timestamp': timestamp,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserPersonalStatsResponse, UserPersonalStatsResponse>($request);
  }

  @override
  Future<Response<UserPersonalStatsResponse>> _userPersonalstatsGet({
    required String? key,
    String? cat,
    List<Object?>? stat,
    int? timestamp,
  }) {
    final Uri $url = Uri.parse('/user/personalstats');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'cat': cat,
      'stat': stat,
      'timestamp': timestamp,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserPersonalStatsResponse, UserPersonalStatsResponse>($request);
  }

  @override
  Future<Response<UserCrimesResponse>> _userCrimeIdCrimesGet({
    required String? key,
    required String? crimeId,
  }) {
    final Uri $url = Uri.parse('/user/${crimeId}/crimes');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserCrimesResponse, UserCrimesResponse>($request);
  }

  @override
  Future<Response<UserRacesResponse>> _userRacesGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? cat,
  }) {
    final Uri $url = Uri.parse('/user/races');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'cat': cat,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserRacesResponse, UserRacesResponse>($request);
  }

  @override
  Future<Response<UserEnlistedCarsResponse>> _userEnlistedcarsGet({required String? key}) {
    final Uri $url = Uri.parse('/user/enlistedcars');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserEnlistedCarsResponse, UserEnlistedCarsResponse>($request);
  }

  @override
  Future<Response<UserForumPostsResponse>> _userIdForumpostsGet({
    required String? key,
    String? cat,
    String? striptags,
    required int? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/${id}/forumposts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'cat': cat,
      'striptags': striptags,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserForumPostsResponse, UserForumPostsResponse>($request);
  }

  @override
  Future<Response<UserForumPostsResponse>> _userForumpostsGet({
    required String? key,
    String? striptags,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/forumposts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'striptags': striptags,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserForumPostsResponse, UserForumPostsResponse>($request);
  }

  @override
  Future<Response<UserForumThreadsResponse>> _userIdForumthreadsGet({
    required String? key,
    required int? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/${id}/forumthreads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserForumThreadsResponse, UserForumThreadsResponse>($request);
  }

  @override
  Future<Response<UserForumThreadsResponse>> _userForumthreadsGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/forumthreads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserForumThreadsResponse, UserForumThreadsResponse>($request);
  }

  @override
  Future<Response<UserForumSubscribedThreadsResponse>> _userForumsubscribedthreadsGet({required String? key}) {
    final Uri $url = Uri.parse('/user/forumsubscribedthreads');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserForumSubscribedThreadsResponse, UserForumSubscribedThreadsResponse>($request);
  }

  @override
  Future<Response<UserForumFeedResponse>> _userForumfeedGet({required String? key}) {
    final Uri $url = Uri.parse('/user/forumfeed');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserForumFeedResponse, UserForumFeedResponse>($request);
  }

  @override
  Future<Response<UserForumFriendsResponse>> _userForumfriendsGet({required String? key}) {
    final Uri $url = Uri.parse('/user/forumfriends');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserForumFriendsResponse, UserForumFriendsResponse>($request);
  }

  @override
  Future<Response<UserHofResponse>> _userIdHofGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/user/${id}/hof');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserHofResponse, UserHofResponse>($request);
  }

  @override
  Future<Response<UserHofResponse>> _userHofGet({required String? key}) {
    final Uri $url = Uri.parse('/user/hof');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserHofResponse, UserHofResponse>($request);
  }

  @override
  Future<Response<UserCalendarResponse>> _userCalendarGet({required String? key}) {
    final Uri $url = Uri.parse('/user/calendar');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserCalendarResponse, UserCalendarResponse>($request);
  }

  @override
  Future<Response<UserBountiesResponse>> _userIdBountiesGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/user/${id}/bounties');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserBountiesResponse, UserBountiesResponse>($request);
  }

  @override
  Future<Response<UserBountiesResponse>> _userBountiesGet({required String? key}) {
    final Uri $url = Uri.parse('/user/bounties');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserBountiesResponse, UserBountiesResponse>($request);
  }

  @override
  Future<Response<UserJobRanksResponse>> _userJobranksGet({required String? key}) {
    final Uri $url = Uri.parse('/user/jobranks');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserJobRanksResponse, UserJobRanksResponse>($request);
  }

  @override
  Future<Response<UserItemMarketResponse>> _userItemmarketGet({
    required String? key,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/user/itemmarket');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserItemMarketResponse, UserItemMarketResponse>($request);
  }

  @override
  Future<Response<UserLookupResponse>> _userLookupGet({required String? key}) {
    final Uri $url = Uri.parse('/user/lookup');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserLookupResponse, UserLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _userTimestampGet({required String? key}) {
    final Uri $url = Uri.parse('/user/timestamp');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _userGet({
    required String? key,
    String? selections,
    String? id,
    int? limit,
    int? to,
    int? from,
    String? cat,
    String? stat,
    String? striptags,
    String? sort,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/user');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'selections': selections,
      'id': id,
      'limit': limit,
      'to': to,
      'from': from,
      'cat': cat,
      'stat': stat,
      'striptags': striptags,
      'sort': sort,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
