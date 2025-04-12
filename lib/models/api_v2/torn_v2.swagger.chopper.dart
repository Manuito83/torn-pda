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
  Future<Response<FactionHofResponse>> _factionIdHofGet({required int? id}) {
    final Uri $url = Uri.parse('/faction/${id}/hof');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionHofResponse, FactionHofResponse>($request);
  }

  @override
  Future<Response<FactionHofResponse>> _factionHofGet() {
    final Uri $url = Uri.parse('/faction/hof');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionHofResponse, FactionHofResponse>($request);
  }

  @override
  Future<Response<FactionMembersResponse>> _factionIdMembersGet({
    required int? id,
    String? striptags,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/members');
    final Map<String, dynamic> $params = <String, dynamic>{'striptags': striptags};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<FactionMembersResponse, FactionMembersResponse>($request);
  }

  @override
  Future<Response<FactionMembersResponse>> _factionMembersGet({String? striptags}) {
    final Uri $url = Uri.parse('/faction/members');
    final Map<String, dynamic> $params = <String, dynamic>{'striptags': striptags};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<FactionMembersResponse, FactionMembersResponse>($request);
  }

  @override
  Future<Response<FactionBasicResponse>> _factionIdBasicGet({required int? id}) {
    final Uri $url = Uri.parse('/faction/${id}/basic');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionBasicResponse, FactionBasicResponse>($request);
  }

  @override
  Future<Response<FactionBasicResponse>> _factionBasicGet() {
    final Uri $url = Uri.parse('/faction/basic');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionBasicResponse, FactionBasicResponse>($request);
  }

  @override
  Future<Response<FactionWarsResponse>> _factionIdWarsGet({required int? id}) {
    final Uri $url = Uri.parse('/faction/${id}/wars');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionWarsResponse, FactionWarsResponse>($request);
  }

  @override
  Future<Response<FactionWarsResponse>> _factionWarsGet() {
    final Uri $url = Uri.parse('/faction/wars');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionWarsResponse, FactionWarsResponse>($request);
  }

  @override
  Future<Response<FactionNewsResponse>> _factionNewsGet({
    String? striptags,
    int? limit,
    String? sort,
    int? to,
    int? from,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/faction/news');
    final Map<String, dynamic> $params = <String, dynamic>{
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<FactionNewsResponse, FactionNewsResponse>($request);
  }

  @override
  Future<Response<FactionAttacksResponse>> _factionAttacksGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/attacks');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<FactionAttacksResponse, FactionAttacksResponse>($request);
  }

  @override
  Future<Response<FactionAttacksFullResponse>> _factionAttacksfullGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/attacksfull');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<FactionAttacksFullResponse, FactionAttacksFullResponse>($request);
  }

  @override
  Future<Response<FactionApplicationsResponse>> _factionApplicationsGet() {
    final Uri $url = Uri.parse('/faction/applications');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionApplicationsResponse, FactionApplicationsResponse>($request);
  }

  @override
  Future<Response<FactionOngoingChainResponse>> _factionIdChainGet({required int? id}) {
    final Uri $url = Uri.parse('/faction/${id}/chain');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionOngoingChainResponse, FactionOngoingChainResponse>($request);
  }

  @override
  Future<Response<FactionOngoingChainResponse>> _factionChainGet() {
    final Uri $url = Uri.parse('/faction/chain');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionOngoingChainResponse, FactionOngoingChainResponse>($request);
  }

  @override
  Future<Response<FactionChainsResponse>> _factionIdChainsGet({
    required int? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/${id}/chains');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<FactionChainsResponse, FactionChainsResponse>($request);
  }

  @override
  Future<Response<FactionChainsResponse>> _factionChainsGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/chains');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<FactionChainsResponse, FactionChainsResponse>($request);
  }

  @override
  Future<Response<FactionChainReportResponse>> _factionChainIdChainreportGet({required int? chainId}) {
    final Uri $url = Uri.parse('/faction/${chainId}/chainreport');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionChainReportResponse, FactionChainReportResponse>($request);
  }

  @override
  Future<Response<FactionChainReportResponse>> _factionChainreportGet() {
    final Uri $url = Uri.parse('/faction/chainreport');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionChainReportResponse, FactionChainReportResponse>($request);
  }

  @override
  Future<Response<FactionCrimesResponse>> _factionCrimesGet({
    String? cat,
    int? offset,
    int? from,
    int? to,
    String? sort,
  }) {
    final Uri $url = Uri.parse('/faction/crimes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'offset': offset,
      'from': from,
      'to': to,
      'sort': sort,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<FactionCrimesResponse, FactionCrimesResponse>($request);
  }

  @override
  Future<Response<FactionLookupResponse>> _factionLookupGet() {
    final Uri $url = Uri.parse('/faction/lookup');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<FactionLookupResponse, FactionLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _factionTimestampGet() {
    final Uri $url = Uri.parse('/faction/timestamp');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _factionGet({
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<ForumCategoriesResponse>> _forumCategoriesGet() {
    final Uri $url = Uri.parse('/forum/categories');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<ForumCategoriesResponse, ForumCategoriesResponse>($request);
  }

  @override
  Future<Response<ForumThreadsResponse>> _forumCategoryIdsThreadsGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    required String? categoryIds,
  }) {
    final Uri $url = Uri.parse('/forum/${categoryIds}/threads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<ForumThreadsResponse, ForumThreadsResponse>($request);
  }

  @override
  Future<Response<ForumThreadsResponse>> _forumThreadsGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/forum/threads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<ForumThreadsResponse, ForumThreadsResponse>($request);
  }

  @override
  Future<Response<ForumThreadResponse>> _forumThreadIdThreadGet({required int? threadId}) {
    final Uri $url = Uri.parse('/forum/${threadId}/thread');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<ForumThreadResponse, ForumThreadResponse>($request);
  }

  @override
  Future<Response<ForumPostsResponse>> _forumThreadIdPostsGet({
    int? offset,
    String? striptags,
    required int? threadId,
  }) {
    final Uri $url = Uri.parse('/forum/${threadId}/posts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'offset': offset,
      'striptags': striptags,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<ForumPostsResponse, ForumPostsResponse>($request);
  }

  @override
  Future<Response<ForumLookupResponse>> _forumLookupGet() {
    final Uri $url = Uri.parse('/forum/lookup');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<ForumLookupResponse, ForumLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _forumTimestampGet() {
    final Uri $url = Uri.parse('/forum/timestamp');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _forumGet({
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<MarketItemMarketResponse>> _marketIdItemmarketGet({
    required int? id,
    String? bonus,
    int? offset,
    String? comment,
  }) {
    final Uri $url = Uri.parse('/market/${id}/itemmarket');
    final Map<String, dynamic> $params = <String, dynamic>{
      'bonus': bonus,
      'offset': offset,
      'comment': comment,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<MarketItemMarketResponse, MarketItemMarketResponse>($request);
  }

  @override
  Future<Response<MarketLookupResponse>> _marketLookupGet() {
    final Uri $url = Uri.parse('/market/lookup');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<MarketLookupResponse, MarketLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _marketTimestampGet() {
    final Uri $url = Uri.parse('/market/timestamp');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _marketGet({
    List<Object?>? selections,
    String? id,
    String? bonus,
    String? cat,
    String? sort,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/market');
    final Map<String, dynamic> $params = <String, dynamic>{
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<RacingRacesResponse>> _racingRacesGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? cat,
  }) {
    final Uri $url = Uri.parse('/racing/races');
    final Map<String, dynamic> $params = <String, dynamic>{
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<RacingRacesResponse, RacingRacesResponse>($request);
  }

  @override
  Future<Response<RacingTrackRecordsResponse>> _racingTrackIdRecordsGet({
    required int? trackId,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/racing/${trackId}/records');
    final Map<String, dynamic> $params = <String, dynamic>{'cat': cat};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<RacingTrackRecordsResponse, RacingTrackRecordsResponse>($request);
  }

  @override
  Future<Response<RacingRaceDetailsResponse>> _racingRaceIdRaceGet({required int? raceId}) {
    final Uri $url = Uri.parse('/racing/${raceId}/race');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<RacingRaceDetailsResponse, RacingRaceDetailsResponse>($request);
  }

  @override
  Future<Response<RacingCarsResponse>> _racingCarsGet() {
    final Uri $url = Uri.parse('/racing/cars');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<RacingCarsResponse, RacingCarsResponse>($request);
  }

  @override
  Future<Response<RacingTracksResponse>> _racingTracksGet() {
    final Uri $url = Uri.parse('/racing/tracks');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<RacingTracksResponse, RacingTracksResponse>($request);
  }

  @override
  Future<Response<RacingCarUpgradesResponse>> _racingCarupgradesGet() {
    final Uri $url = Uri.parse('/racing/carupgrades');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<RacingCarUpgradesResponse, RacingCarUpgradesResponse>($request);
  }

  @override
  Future<Response<RacingLookupResponse>> _racingLookupGet() {
    final Uri $url = Uri.parse('/racing/lookup');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<RacingLookupResponse, RacingLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _racingTimestampGet() {
    final Uri $url = Uri.parse('/racing/timestamp');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _racingGet({
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<TornSubcrimesResponse>> _tornCrimeIdSubcrimesGet({required String? crimeId}) {
    final Uri $url = Uri.parse('/torn/${crimeId}/subcrimes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TornSubcrimesResponse, TornSubcrimesResponse>($request);
  }

  @override
  Future<Response<TornCrimesResponse>> _tornCrimesGet() {
    final Uri $url = Uri.parse('/torn/crimes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TornCrimesResponse, TornCrimesResponse>($request);
  }

  @override
  Future<Response<TornCalendarResponse>> _tornCalendarGet() {
    final Uri $url = Uri.parse('/torn/calendar');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TornCalendarResponse, TornCalendarResponse>($request);
  }

  @override
  Future<Response<TornHofResponse>> _tornHofGet({
    int? limit,
    int? offset,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/torn/hof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'cat': cat,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<TornHofResponse, TornHofResponse>($request);
  }

  @override
  Future<Response<TornFactionHofResponse>> _tornFactionhofGet({
    int? limit,
    int? offset,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/torn/factionhof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'cat': cat,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<TornFactionHofResponse, TornFactionHofResponse>($request);
  }

  @override
  Future<Response<TornLogTypesResponse>> _tornLogCategoryIdLogtypesGet({required int? logCategoryId}) {
    final Uri $url = Uri.parse('/torn/${logCategoryId}/logtypes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TornLogTypesResponse, TornLogTypesResponse>($request);
  }

  @override
  Future<Response<TornLogTypesResponse>> _tornLogtypesGet() {
    final Uri $url = Uri.parse('/torn/logtypes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TornLogTypesResponse, TornLogTypesResponse>($request);
  }

  @override
  Future<Response<TornLogCategoriesResponse>> _tornLogcategoriesGet() {
    final Uri $url = Uri.parse('/torn/logcategories');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TornLogCategoriesResponse, TornLogCategoriesResponse>($request);
  }

  @override
  Future<Response<TornBountiesResponse>> _tornBountiesGet({
    int? limit,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/torn/bounties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<TornBountiesResponse, TornBountiesResponse>($request);
  }

  @override
  Future<Response<TornLookupResponse>> _tornLookupGet() {
    final Uri $url = Uri.parse('/torn/lookup');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TornLookupResponse, TornLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _tornTimestampGet() {
    final Uri $url = Uri.parse('/torn/timestamp');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _tornGet({
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<UserPersonalStatsResponse>> _userIdPersonalstatsGet({
    required int? id,
    String? cat,
    List<Object?>? stat,
    int? timestamp,
  }) {
    final Uri $url = Uri.parse('/user/${id}/personalstats');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'stat': stat,
      'timestamp': timestamp,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<UserPersonalStatsResponse, UserPersonalStatsResponse>($request);
  }

  @override
  Future<Response<UserPersonalStatsResponse>> _userPersonalstatsGet({
    String? cat,
    List<Object?>? stat,
    int? timestamp,
  }) {
    final Uri $url = Uri.parse('/user/personalstats');
    final Map<String, dynamic> $params = <String, dynamic>{
      'cat': cat,
      'stat': stat,
      'timestamp': timestamp,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<UserPersonalStatsResponse, UserPersonalStatsResponse>($request);
  }

  @override
  Future<Response<UserCrimesResponse>> _userCrimeIdCrimesGet({required String? crimeId}) {
    final Uri $url = Uri.parse('/user/${crimeId}/crimes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserCrimesResponse, UserCrimesResponse>($request);
  }

  @override
  Future<Response<UserRacesResponse>> _userRacesGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? cat,
  }) {
    final Uri $url = Uri.parse('/user/races');
    final Map<String, dynamic> $params = <String, dynamic>{
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<UserRacesResponse, UserRacesResponse>($request);
  }

  @override
  Future<Response<UserEnlistedCarsResponse>> _userEnlistedcarsGet() {
    final Uri $url = Uri.parse('/user/enlistedcars');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserEnlistedCarsResponse, UserEnlistedCarsResponse>($request);
  }

  @override
  Future<Response<UserForumPostsResponse>> _userIdForumpostsGet({
    String? striptags,
    required int? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/${id}/forumposts');
    final Map<String, dynamic> $params = <String, dynamic>{
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<UserForumPostsResponse, UserForumPostsResponse>($request);
  }

  @override
  Future<Response<UserForumPostsResponse>> _userForumpostsGet({
    String? striptags,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/forumposts');
    final Map<String, dynamic> $params = <String, dynamic>{
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<UserForumPostsResponse, UserForumPostsResponse>($request);
  }

  @override
  Future<Response<UserForumThreadsResponse>> _userIdForumthreadsGet({
    required int? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/${id}/forumthreads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<UserForumThreadsResponse, UserForumThreadsResponse>($request);
  }

  @override
  Future<Response<UserForumThreadsResponse>> _userForumthreadsGet({
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/forumthreads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<UserForumThreadsResponse, UserForumThreadsResponse>($request);
  }

  @override
  Future<Response<UserForumSubscribedThreadsResponse>> _userForumsubscribedthreadsGet() {
    final Uri $url = Uri.parse('/user/forumsubscribedthreads');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserForumSubscribedThreadsResponse, UserForumSubscribedThreadsResponse>($request);
  }

  @override
  Future<Response<UserForumFeedResponse>> _userForumfeedGet() {
    final Uri $url = Uri.parse('/user/forumfeed');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserForumFeedResponse, UserForumFeedResponse>($request);
  }

  @override
  Future<Response<UserForumFriendsResponse>> _userForumfriendsGet() {
    final Uri $url = Uri.parse('/user/forumfriends');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserForumFriendsResponse, UserForumFriendsResponse>($request);
  }

  @override
  Future<Response<UserHofResponse>> _userIdHofGet({required int? id}) {
    final Uri $url = Uri.parse('/user/${id}/hof');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserHofResponse, UserHofResponse>($request);
  }

  @override
  Future<Response<UserHofResponse>> _userHofGet() {
    final Uri $url = Uri.parse('/user/hof');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserHofResponse, UserHofResponse>($request);
  }

  @override
  Future<Response<UserCalendarResponse>> _userCalendarGet() {
    final Uri $url = Uri.parse('/user/calendar');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserCalendarResponse, UserCalendarResponse>($request);
  }

  @override
  Future<Response<UserBountiesResponse>> _userIdBountiesGet({required int? id}) {
    final Uri $url = Uri.parse('/user/${id}/bounties');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserBountiesResponse, UserBountiesResponse>($request);
  }

  @override
  Future<Response<UserBountiesResponse>> _userBountiesGet() {
    final Uri $url = Uri.parse('/user/bounties');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserBountiesResponse, UserBountiesResponse>($request);
  }

  @override
  Future<Response<UserJobRanksResponse>> _userJobranksGet() {
    final Uri $url = Uri.parse('/user/jobranks');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserJobRanksResponse, UserJobRanksResponse>($request);
  }

  @override
  Future<Response<UserItemMarketResponse>> _userItemmarketGet({int? offset, String? comment}) {
    final Uri $url = Uri.parse('/user/itemmarket');
    final Map<String, dynamic> $params = <String, dynamic>{
      'offset': offset,
      'comment': comment,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<UserItemMarketResponse, UserItemMarketResponse>($request);
  }

  @override
  Future<Response<UserFactionBalanceResponse>> _userFactionbalanceGet() {
    final Uri $url = Uri.parse('/user/factionbalance');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserFactionBalanceResponse, UserFactionBalanceResponse>($request);
  }

  @override
  Future<Response<UserOrganizedCrimeResponse>> _userOrganizedcrimeGet() {
    final Uri $url = Uri.parse('/user/organizedcrime');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserOrganizedCrimeResponse, UserOrganizedCrimeResponse>($request);
  }

  @override
  Future<Response<UserLookupResponse>> _userLookupGet() {
    final Uri $url = Uri.parse('/user/lookup');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<UserLookupResponse, UserLookupResponse>($request);
  }

  @override
  Future<Response<TimestampResponse>> _userTimestampGet() {
    final Uri $url = Uri.parse('/user/timestamp');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );
    return client.send<TimestampResponse, TimestampResponse>($request);
  }

  @override
  Future<Response<dynamic>> _userGet({
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
      parameters: {...$params, 'comment': 'PDA-App'},
    );
    return client.send<dynamic, dynamic>($request);
  }
}
