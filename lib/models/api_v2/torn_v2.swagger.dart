// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';
import 'dart:convert';

import 'package:chopper/chopper.dart';

import 'client_mapping.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:chopper/chopper.dart' as chopper;
import 'torn_v2.enums.swagger.dart' as enums;
export 'torn_v2.enums.swagger.dart';

part 'torn_v2.swagger.chopper.dart';
part 'torn_v2.swagger.g.dart';

// **************************************************************************
// SwaggerChopperGenerator
// **************************************************************************

@ChopperApi()
abstract class TornV2 extends ChopperService {
  static TornV2 create({
    ChopperClient? client,
    http.Client? httpClient,
    Authenticator? authenticator,
    ErrorConverter? errorConverter,
    Converter? converter,
    Uri? baseUrl,
    List<Interceptor>? interceptors,
  }) {
    if (client != null) {
      return _$TornV2(client);
    }

    final newClient = ChopperClient(
        services: [_$TornV2()],
        converter: converter ?? $JsonSerializableConverter(),
        interceptors: interceptors ?? [],
        client: httpClient,
        authenticator: authenticator,
        errorConverter: errorConverter,
        baseUrl: baseUrl ?? Uri.parse('http://'));
    return _$TornV2(newClient);
  }

  ///Get a faction's hall of fame rankings.
  ///@param id Faction id
  Future<chopper.Response<FactionHofResponse>> factionIdHofGet({required int? id}) {
    generatedMapping.putIfAbsent(FactionHofResponse, () => FactionHofResponse.fromJsonFactory);

    return _factionIdHofGet(id: id);
  }

  ///Get a faction's hall of fame rankings.
  ///@param id Faction id
  @GET(path: '/faction/{id}/hof')
  Future<chopper.Response<FactionHofResponse>> _factionIdHofGet({@Path('id') required int? id});

  ///Get your faction's hall of fame rankings.
  Future<chopper.Response<FactionHofResponse>> factionHofGet() {
    generatedMapping.putIfAbsent(FactionHofResponse, () => FactionHofResponse.fromJsonFactory);

    return _factionHofGet();
  }

  ///Get your faction's hall of fame rankings.
  @GET(path: '/faction/hof')
  Future<chopper.Response<FactionHofResponse>> _factionHofGet();

  ///Get a list of a faction's members
  ///@param id Faction id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  Future<chopper.Response<FactionMembersResponse>> factionIdMembersGet({
    required int? id,
    enums.ApiStripTagsTrue? striptags,
  }) {
    generatedMapping.putIfAbsent(FactionMembersResponse, () => FactionMembersResponse.fromJsonFactory);

    return _factionIdMembersGet(id: id, striptags: striptags?.value?.toString());
  }

  ///Get a list of a faction's members
  ///@param id Faction id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  @GET(path: '/faction/{id}/members')
  Future<chopper.Response<FactionMembersResponse>> _factionIdMembersGet({
    @Path('id') required int? id,
    @Query('striptags') String? striptags,
  });

  ///Get a list of your faction's members
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  Future<chopper.Response<FactionMembersResponse>> factionMembersGet({enums.ApiStripTagsTrue? striptags}) {
    generatedMapping.putIfAbsent(FactionMembersResponse, () => FactionMembersResponse.fromJsonFactory);

    return _factionMembersGet(striptags: striptags?.value?.toString());
  }

  ///Get a list of your faction's members
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  @GET(path: '/faction/members')
  Future<chopper.Response<FactionMembersResponse>> _factionMembersGet({@Query('striptags') String? striptags});

  ///Get a faction's basic details
  ///@param id Faction id
  Future<chopper.Response<FactionBasicResponse>> factionIdBasicGet({required int? id}) {
    generatedMapping.putIfAbsent(FactionBasicResponse, () => FactionBasicResponse.fromJsonFactory);

    return _factionIdBasicGet(id: id);
  }

  ///Get a faction's basic details
  ///@param id Faction id
  @GET(path: '/faction/{id}/basic')
  Future<chopper.Response<FactionBasicResponse>> _factionIdBasicGet({@Path('id') required int? id});

  ///Get your faction's basic details
  Future<chopper.Response<FactionBasicResponse>> factionBasicGet() {
    generatedMapping.putIfAbsent(FactionBasicResponse, () => FactionBasicResponse.fromJsonFactory);

    return _factionBasicGet();
  }

  ///Get your faction's basic details
  @GET(path: '/faction/basic')
  Future<chopper.Response<FactionBasicResponse>> _factionBasicGet();

  ///Get a faction's wars & pacts details
  ///@param id Faction id
  Future<chopper.Response<FactionWarsResponse>> factionIdWarsGet({required int? id}) {
    generatedMapping.putIfAbsent(FactionWarsResponse, () => FactionWarsResponse.fromJsonFactory);

    return _factionIdWarsGet(id: id);
  }

  ///Get a faction's wars & pacts details
  ///@param id Faction id
  @GET(path: '/faction/{id}/wars')
  Future<chopper.Response<FactionWarsResponse>> _factionIdWarsGet({@Path('id') required int? id});

  ///Get your faction's wars & pacts details
  Future<chopper.Response<FactionWarsResponse>> factionWarsGet() {
    generatedMapping.putIfAbsent(FactionWarsResponse, () => FactionWarsResponse.fromJsonFactory);

    return _factionWarsGet();
  }

  ///Get your faction's wars & pacts details
  @GET(path: '/faction/wars')
  Future<chopper.Response<FactionWarsResponse>> _factionWarsGet();

  ///Get your faction's news details
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  ///@param cat News category type
  Future<chopper.Response<FactionNewsResponse>> factionNewsGet({
    enums.ApiStripTagsFalse? striptags,
    int? limit,
    enums.ApiSort? sort,
    int? to,
    int? from,
    required enums.FactionNewsCategory? cat,
  }) {
    generatedMapping.putIfAbsent(FactionNewsResponse, () => FactionNewsResponse.fromJsonFactory);

    return _factionNewsGet(
        striptags: striptags?.value?.toString(),
        limit: limit,
        sort: sort?.value?.toString(),
        to: to,
        from: from,
        cat: cat?.value?.toString());
  }

  ///Get your faction's news details
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  ///@param cat News category type
  @GET(path: '/faction/news')
  Future<chopper.Response<FactionNewsResponse>> _factionNewsGet({
    @Query('striptags') String? striptags,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') required String? cat,
  });

  ///Get your faction's detailed attacks
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  Future<chopper.Response<FactionAttacksResponse>> factionAttacksGet({
    int? limit,
    enums.ApiSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(FactionAttacksResponse, () => FactionAttacksResponse.fromJsonFactory);

    return _factionAttacksGet(limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get your faction's detailed attacks
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  @GET(path: '/faction/attacks')
  Future<chopper.Response<FactionAttacksResponse>> _factionAttacksGet({
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get your faction's attacks
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  Future<chopper.Response<FactionAttacksFullResponse>> factionAttacksfullGet({
    int? limit,
    enums.ApiSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(FactionAttacksFullResponse, () => FactionAttacksFullResponse.fromJsonFactory);

    return _factionAttacksfullGet(limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get your faction's attacks
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  @GET(path: '/faction/attacksfull')
  Future<chopper.Response<FactionAttacksFullResponse>> _factionAttacksfullGet({
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get your faction's applications
  Future<chopper.Response<FactionApplicationsResponse>> factionApplicationsGet() {
    generatedMapping.putIfAbsent(FactionApplicationsResponse, () => FactionApplicationsResponse.fromJsonFactory);

    return _factionApplicationsGet();
  }

  ///Get your faction's applications
  @GET(path: '/faction/applications')
  Future<chopper.Response<FactionApplicationsResponse>> _factionApplicationsGet();

  ///Get a faction's current chain
  ///@param id Faction id
  Future<chopper.Response<FactionOngoingChainResponse>> factionIdChainGet({required int? id}) {
    generatedMapping.putIfAbsent(FactionOngoingChainResponse, () => FactionOngoingChainResponse.fromJsonFactory);

    return _factionIdChainGet(id: id);
  }

  ///Get a faction's current chain
  ///@param id Faction id
  @GET(path: '/faction/{id}/chain')
  Future<chopper.Response<FactionOngoingChainResponse>> _factionIdChainGet({@Path('id') required int? id});

  ///Get your faction's current chain
  Future<chopper.Response<FactionOngoingChainResponse>> factionChainGet() {
    generatedMapping.putIfAbsent(FactionOngoingChainResponse, () => FactionOngoingChainResponse.fromJsonFactory);

    return _factionChainGet();
  }

  ///Get your faction's current chain
  @GET(path: '/faction/chain')
  Future<chopper.Response<FactionOngoingChainResponse>> _factionChainGet();

  ///Get a list of a faction's completed chains
  ///@param id Faction id
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  Future<chopper.Response<FactionChainsResponse>> factionIdChainsGet({
    required int? id,
    int? limit,
    enums.ApiSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(FactionChainsResponse, () => FactionChainsResponse.fromJsonFactory);

    return _factionIdChainsGet(id: id, limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get a list of a faction's completed chains
  ///@param id Faction id
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  @GET(path: '/faction/{id}/chains')
  Future<chopper.Response<FactionChainsResponse>> _factionIdChainsGet({
    @Path('id') required int? id,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get a list of your faction's completed chains
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  Future<chopper.Response<FactionChainsResponse>> factionChainsGet({
    int? limit,
    enums.ApiSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(FactionChainsResponse, () => FactionChainsResponse.fromJsonFactory);

    return _factionChainsGet(limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get a list of your faction's completed chains
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  @GET(path: '/faction/chains')
  Future<chopper.Response<FactionChainsResponse>> _factionChainsGet({
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get a chain report
  ///@param chainId Chain id
  Future<chopper.Response<FactionChainReportResponse>> factionChainIdChainreportGet({required int? chainId}) {
    generatedMapping.putIfAbsent(FactionChainReportResponse, () => FactionChainReportResponse.fromJsonFactory);

    return _factionChainIdChainreportGet(chainId: chainId);
  }

  ///Get a chain report
  ///@param chainId Chain id
  @GET(path: '/faction/{chainId}/chainreport')
  Future<chopper.Response<FactionChainReportResponse>> _factionChainIdChainreportGet(
      {@Path('chainId') required int? chainId});

  ///Get your faction's latest chain report
  Future<chopper.Response<FactionChainReportResponse>> factionChainreportGet() {
    generatedMapping.putIfAbsent(FactionChainReportResponse, () => FactionChainReportResponse.fromJsonFactory);

    return _factionChainreportGet();
  }

  ///Get your faction's latest chain report
  @GET(path: '/faction/chainreport')
  Future<chopper.Response<FactionChainReportResponse>> _factionChainreportGet();

  ///Get your faction's organized crimes
  ///@param cat Category of organized crimes returned. Category 'available' includes both 'recruiting' & 'planning', and category 'completed' includes both 'successful' & 'failure'<br>Default category is 'all'
  ///@param offset
  ///@param from Returns crimes created after this timestamp
  ///@param to Returns crimes created before this timestamp
  ///@param sort Direction to sort rows in
  Future<chopper.Response<FactionCrimesResponse>> factionCrimesGet({
    enums.FactionCrimesGetCat? cat,
    int? offset,
    int? from,
    int? to,
    enums.FactionCrimesGetSort? sort,
  }) {
    generatedMapping.putIfAbsent(FactionCrimesResponse, () => FactionCrimesResponse.fromJsonFactory);

    return _factionCrimesGet(
        cat: cat?.value?.toString(), offset: offset, from: from, to: to, sort: sort?.value?.toString());
  }

  ///Get your faction's organized crimes
  ///@param cat Category of organized crimes returned. Category 'available' includes both 'recruiting' & 'planning', and category 'completed' includes both 'successful' & 'failure'<br>Default category is 'all'
  ///@param offset
  ///@param from Returns crimes created after this timestamp
  ///@param to Returns crimes created before this timestamp
  ///@param sort Direction to sort rows in
  @GET(path: '/faction/crimes')
  Future<chopper.Response<FactionCrimesResponse>> _factionCrimesGet({
    @Query('cat') String? cat,
    @Query('offset') int? offset,
    @Query('from') int? from,
    @Query('to') int? to,
    @Query('sort') String? sort,
  });

  ///
  Future<chopper.Response<FactionLookupResponse>> factionLookupGet() {
    generatedMapping.putIfAbsent(FactionLookupResponse, () => FactionLookupResponse.fromJsonFactory);

    return _factionLookupGet();
  }

  ///
  @GET(path: '/faction/lookup')
  Future<chopper.Response<FactionLookupResponse>> _factionLookupGet();

  ///Get current server time
  Future<chopper.Response<TimestampResponse>> factionTimestampGet() {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _factionTimestampGet();
  }

  ///Get current server time
  @GET(path: '/faction/timestamp')
  Future<chopper.Response<TimestampResponse>> _factionTimestampGet();

  ///Get any Faction selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param sort Direction to sort rows in
  ///@param offset
  Future<chopper.Response> factionGet({
    List<enums.FactionSelectionName>? selections,
    String? id,
    int? limit,
    int? to,
    int? from,
    String? cat,
    enums.ApiStripTags? striptags,
    enums.FactionGetSort? sort,
    int? offset,
  }) {
    return _factionGet(
        selections: factionSelectionNameListToJson(selections),
        id: id,
        limit: limit,
        to: to,
        from: from,
        cat: cat,
        striptags: striptags?.value?.toString(),
        sort: sort?.value?.toString(),
        offset: offset);
  }

  ///Get any Faction selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param sort Direction to sort rows in
  ///@param offset
  @GET(path: '/faction')
  Future<chopper.Response> _factionGet({
    @Query('selections') List<Object?>? selections,
    @Query('id') String? id,
    @Query('limit') int? limit,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') String? cat,
    @Query('striptags') String? striptags,
    @Query('sort') String? sort,
    @Query('offset') int? offset,
  });

  ///Get publicly available forum categories
  Future<chopper.Response<ForumCategoriesResponse>> forumCategoriesGet() {
    generatedMapping.putIfAbsent(ForumCategoriesResponse, () => ForumCategoriesResponse.fromJsonFactory);

    return _forumCategoriesGet();
  }

  ///Get publicly available forum categories
  @GET(path: '/forum/categories')
  Future<chopper.Response<ForumCategoriesResponse>> _forumCategoriesGet();

  ///Get threads for specific public forum category or categories
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  ///@param categoryIds Category id or a list of category ids (comma separated)
  Future<chopper.Response<ForumThreadsResponse>> forumCategoryIdsThreadsGet({
    int? limit,
    enums.ForumCategoryIdsThreadsGetSort? sort,
    int? to,
    int? from,
    required String? categoryIds,
  }) {
    generatedMapping.putIfAbsent(ForumThreadsResponse, () => ForumThreadsResponse.fromJsonFactory);

    return _forumCategoryIdsThreadsGet(
        limit: limit, sort: sort?.value?.toString(), to: to, from: from, categoryIds: categoryIds);
  }

  ///Get threads for specific public forum category or categories
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  ///@param categoryIds Category id or a list of category ids (comma separated)
  @GET(path: '/forum/{categoryIds}/threads')
  Future<chopper.Response<ForumThreadsResponse>> _forumCategoryIdsThreadsGet({
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
    @Path('categoryIds') required String? categoryIds,
  });

  ///Get threads across all forum categories
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  Future<chopper.Response<ForumThreadsResponse>> forumThreadsGet({
    int? limit,
    enums.ForumThreadsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(ForumThreadsResponse, () => ForumThreadsResponse.fromJsonFactory);

    return _forumThreadsGet(limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get threads across all forum categories
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  @GET(path: '/forum/threads')
  Future<chopper.Response<ForumThreadsResponse>> _forumThreadsGet({
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get specific thread details
  ///@param threadId Thread id
  Future<chopper.Response<ForumThreadResponse>> forumThreadIdThreadGet({required int? threadId}) {
    generatedMapping.putIfAbsent(ForumThreadResponse, () => ForumThreadResponse.fromJsonFactory);

    return _forumThreadIdThreadGet(threadId: threadId);
  }

  ///Get specific thread details
  ///@param threadId Thread id
  @GET(path: '/forum/{threadId}/thread')
  Future<chopper.Response<ForumThreadResponse>> _forumThreadIdThreadGet({@Path('threadId') required int? threadId});

  ///Get specific forum thread posts
  ///@param offset
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param threadId Thread id
  Future<chopper.Response<ForumPostsResponse>> forumThreadIdPostsGet({
    int? offset,
    enums.ApiStripTagsTrue? striptags,
    required int? threadId,
  }) {
    generatedMapping.putIfAbsent(ForumPostsResponse, () => ForumPostsResponse.fromJsonFactory);

    return _forumThreadIdPostsGet(offset: offset, striptags: striptags?.value?.toString(), threadId: threadId);
  }

  ///Get specific forum thread posts
  ///@param offset
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param threadId Thread id
  @GET(path: '/forum/{threadId}/posts')
  Future<chopper.Response<ForumPostsResponse>> _forumThreadIdPostsGet({
    @Query('offset') int? offset,
    @Query('striptags') String? striptags,
    @Path('threadId') required int? threadId,
  });

  ///Get all available forum selections
  Future<chopper.Response<ForumLookupResponse>> forumLookupGet() {
    generatedMapping.putIfAbsent(ForumLookupResponse, () => ForumLookupResponse.fromJsonFactory);

    return _forumLookupGet();
  }

  ///Get all available forum selections
  @GET(path: '/forum/lookup')
  Future<chopper.Response<ForumLookupResponse>> _forumLookupGet();

  ///Get current server time
  Future<chopper.Response<TimestampResponse>> forumTimestampGet() {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _forumTimestampGet();
  }

  ///Get current server time
  @GET(path: '/forum/timestamp')
  Future<chopper.Response<TimestampResponse>> _forumTimestampGet();

  ///Get any Forum selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  Future<chopper.Response> forumGet({
    List<enums.ForumSelectionName>? selections,
    String? id,
    enums.ApiStripTags? striptags,
    int? limit,
    int? to,
    int? from,
    String? cat,
    enums.ForumGetSort? sort,
    int? offset,
  }) {
    return _forumGet(
        selections: forumSelectionNameListToJson(selections),
        id: id,
        striptags: striptags?.value?.toString(),
        limit: limit,
        to: to,
        from: from,
        cat: cat,
        sort: sort?.value?.toString(),
        offset: offset);
  }

  ///Get any Forum selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  @GET(path: '/forum')
  Future<chopper.Response> _forumGet({
    @Query('selections') List<Object?>? selections,
    @Query('id') String? id,
    @Query('striptags') String? striptags,
    @Query('limit') int? limit,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') String? cat,
    @Query('sort') String? sort,
    @Query('offset') int? offset,
  });

  ///Get item market listings
  ///@param id Item id
  ///@param bonus Used to filter weapons with a specific bonus.
  ///@param offset
  Future<chopper.Response<MarketItemMarketResponse>> marketIdItemmarketGet({
    required int? id,
    enums.WeaponBonusEnum? bonus,
    int? offset,
  }) {
    generatedMapping.putIfAbsent(MarketItemMarketResponse, () => MarketItemMarketResponse.fromJsonFactory);

    return _marketIdItemmarketGet(id: id, bonus: bonus?.value?.toString(), offset: offset);
  }

  ///Get item market listings
  ///@param id Item id
  ///@param bonus Used to filter weapons with a specific bonus.
  ///@param offset
  @GET(path: '/market/{id}/itemmarket')
  Future<chopper.Response<MarketItemMarketResponse>> _marketIdItemmarketGet({
    @Path('id') required int? id,
    @Query('bonus') String? bonus,
    @Query('offset') int? offset,
  });

  ///Get all available market selections
  Future<chopper.Response<MarketLookupResponse>> marketLookupGet() {
    generatedMapping.putIfAbsent(MarketLookupResponse, () => MarketLookupResponse.fromJsonFactory);

    return _marketLookupGet();
  }

  ///Get all available market selections
  @GET(path: '/market/lookup')
  Future<chopper.Response<MarketLookupResponse>> _marketLookupGet();

  ///Get current server time
  Future<chopper.Response<TimestampResponse>> marketTimestampGet() {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _marketTimestampGet();
  }

  ///Get current server time
  @GET(path: '/market/timestamp')
  Future<chopper.Response<TimestampResponse>> _marketTimestampGet();

  ///Get any Market selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param bonus Used to filter weapons with a specific bonus
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  Future<chopper.Response> marketGet({
    List<enums.MarketSelectionName>? selections,
    String? id,
    enums.WeaponBonusEnum? bonus,
    String? cat,
    enums.MarketGetSort? sort,
    int? offset,
  }) {
    return _marketGet(
        selections: marketSelectionNameListToJson(selections),
        id: id,
        bonus: bonus?.value?.toString(),
        cat: cat,
        sort: sort?.value?.toString(),
        offset: offset);
  }

  ///Get any Market selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param bonus Used to filter weapons with a specific bonus
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  @GET(path: '/market')
  Future<chopper.Response> _marketGet({
    @Query('selections') List<Object?>? selections,
    @Query('id') String? id,
    @Query('bonus') String? bonus,
    @Query('cat') String? cat,
    @Query('sort') String? sort,
    @Query('offset') int? offset,
  });

  ///Get races
  ///@param limit
  ///@param sort Sorted by schedule.start field
  ///@param to Timestamp until when started races are returned (schedule.start)
  ///@param from Timestamp after when started races are returned (scheduled.start)
  ///@param cat Category of races returned
  Future<chopper.Response<RacingRacesResponse>> racingRacesGet({
    int? limit,
    enums.RacingRacesGetSort? sort,
    int? to,
    int? from,
    enums.RacingRacesGetCat? cat,
  }) {
    generatedMapping.putIfAbsent(RacingRacesResponse, () => RacingRacesResponse.fromJsonFactory);

    return _racingRacesGet(
        limit: limit, sort: sort?.value?.toString(), to: to, from: from, cat: cat?.value?.toString());
  }

  ///Get races
  ///@param limit
  ///@param sort Sorted by schedule.start field
  ///@param to Timestamp until when started races are returned (schedule.start)
  ///@param from Timestamp after when started races are returned (scheduled.start)
  ///@param cat Category of races returned
  @GET(path: '/racing/races')
  Future<chopper.Response<RacingRacesResponse>> _racingRacesGet({
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') String? cat,
  });

  ///Get track records
  ///@param trackId Track id
  ///@param cat Car class
  Future<chopper.Response<RacingTrackRecordsResponse>> racingTrackIdRecordsGet({
    required int? trackId,
    required enums.RaceClassEnum? cat,
  }) {
    generatedMapping.putIfAbsent(RacingTrackRecordsResponse, () => RacingTrackRecordsResponse.fromJsonFactory);

    return _racingTrackIdRecordsGet(trackId: trackId, cat: cat?.value?.toString());
  }

  ///Get track records
  ///@param trackId Track id
  ///@param cat Car class
  @GET(path: '/racing/{trackId}/records')
  Future<chopper.Response<RacingTrackRecordsResponse>> _racingTrackIdRecordsGet({
    @Path('trackId') required int? trackId,
    @Query('cat') required String? cat,
  });

  ///Get specific race details
  ///@param raceId Race id
  Future<chopper.Response<RacingRaceDetailsResponse>> racingRaceIdRaceGet({required int? raceId}) {
    generatedMapping.putIfAbsent(RacingRaceDetailsResponse, () => RacingRaceDetailsResponse.fromJsonFactory);

    return _racingRaceIdRaceGet(raceId: raceId);
  }

  ///Get specific race details
  ///@param raceId Race id
  @GET(path: '/racing/{raceId}/race')
  Future<chopper.Response<RacingRaceDetailsResponse>> _racingRaceIdRaceGet({@Path('raceId') required int? raceId});

  ///Get cars and their racing stats
  Future<chopper.Response<RacingCarsResponse>> racingCarsGet() {
    generatedMapping.putIfAbsent(RacingCarsResponse, () => RacingCarsResponse.fromJsonFactory);

    return _racingCarsGet();
  }

  ///Get cars and their racing stats
  @GET(path: '/racing/cars')
  Future<chopper.Response<RacingCarsResponse>> _racingCarsGet();

  ///Get race tracks and descriptions
  Future<chopper.Response<RacingTracksResponse>> racingTracksGet() {
    generatedMapping.putIfAbsent(RacingTracksResponse, () => RacingTracksResponse.fromJsonFactory);

    return _racingTracksGet();
  }

  ///Get race tracks and descriptions
  @GET(path: '/racing/tracks')
  Future<chopper.Response<RacingTracksResponse>> _racingTracksGet();

  ///Get all possible car upgrades
  Future<chopper.Response<RacingCarUpgradesResponse>> racingCarupgradesGet() {
    generatedMapping.putIfAbsent(RacingCarUpgradesResponse, () => RacingCarUpgradesResponse.fromJsonFactory);

    return _racingCarupgradesGet();
  }

  ///Get all possible car upgrades
  @GET(path: '/racing/carupgrades')
  Future<chopper.Response<RacingCarUpgradesResponse>> _racingCarupgradesGet();

  ///Get all available racing selections
  Future<chopper.Response<RacingLookupResponse>> racingLookupGet() {
    generatedMapping.putIfAbsent(RacingLookupResponse, () => RacingLookupResponse.fromJsonFactory);

    return _racingLookupGet();
  }

  ///Get all available racing selections
  @GET(path: '/racing/lookup')
  Future<chopper.Response<RacingLookupResponse>> _racingLookupGet();

  ///Get current server time
  Future<chopper.Response<TimestampResponse>> racingTimestampGet() {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _racingTimestampGet();
  }

  ///Get current server time
  @GET(path: '/racing/timestamp')
  Future<chopper.Response<TimestampResponse>> _racingTimestampGet();

  ///Get any Racing selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  Future<chopper.Response> racingGet({
    List<enums.RacingSelectionName>? selections,
    String? id,
    int? limit,
    int? to,
    int? from,
    String? cat,
    enums.RacingGetSort? sort,
    int? offset,
  }) {
    return _racingGet(
        selections: racingSelectionNameListToJson(selections),
        id: id,
        limit: limit,
        to: to,
        from: from,
        cat: cat,
        sort: sort?.value?.toString(),
        offset: offset);
  }

  ///Get any Racing selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  @GET(path: '/racing')
  Future<chopper.Response> _racingGet({
    @Query('selections') List<Object?>? selections,
    @Query('id') String? id,
    @Query('limit') int? limit,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') String? cat,
    @Query('sort') String? sort,
    @Query('offset') int? offset,
  });

  ///Get Subcrimes information
  ///@param crimeId Crime id
  Future<chopper.Response<TornSubcrimesResponse>> tornCrimeIdSubcrimesGet({required String? crimeId}) {
    generatedMapping.putIfAbsent(TornSubcrimesResponse, () => TornSubcrimesResponse.fromJsonFactory);

    return _tornCrimeIdSubcrimesGet(crimeId: crimeId);
  }

  ///Get Subcrimes information
  ///@param crimeId Crime id
  @GET(path: '/torn/{crimeId}/subcrimes')
  Future<chopper.Response<TornSubcrimesResponse>> _tornCrimeIdSubcrimesGet({@Path('crimeId') required String? crimeId});

  ///Get crimes information
  Future<chopper.Response<TornCrimesResponse>> tornCrimesGet() {
    generatedMapping.putIfAbsent(TornCrimesResponse, () => TornCrimesResponse.fromJsonFactory);

    return _tornCrimesGet();
  }

  ///Get crimes information
  @GET(path: '/torn/crimes')
  Future<chopper.Response<TornCrimesResponse>> _tornCrimesGet();

  ///Get calendar information
  Future<chopper.Response<TornCalendarResponse>> tornCalendarGet() {
    generatedMapping.putIfAbsent(TornCalendarResponse, () => TornCalendarResponse.fromJsonFactory);

    return _tornCalendarGet();
  }

  ///Get calendar information
  @GET(path: '/torn/calendar')
  Future<chopper.Response<TornCalendarResponse>> _tornCalendarGet();

  ///Get player hall of fame positions for a specific category
  ///@param limit
  ///@param offset
  ///@param cat Leaderboards category
  Future<chopper.Response<TornHofResponse>> tornHofGet({
    int? limit,
    int? offset,
    required enums.TornHofCategory? cat,
  }) {
    generatedMapping.putIfAbsent(TornHofResponse, () => TornHofResponse.fromJsonFactory);

    return _tornHofGet(limit: limit, offset: offset, cat: cat?.value?.toString());
  }

  ///Get player hall of fame positions for a specific category
  ///@param limit
  ///@param offset
  ///@param cat Leaderboards category
  @GET(path: '/torn/hof')
  Future<chopper.Response<TornHofResponse>> _tornHofGet({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('cat') required String? cat,
  });

  ///Get faction hall of fame positions for a specific category
  ///@param limit
  ///@param offset
  ///@param cat Leaderboards category
  Future<chopper.Response<TornFactionHofResponse>> tornFactionhofGet({
    int? limit,
    int? offset,
    required enums.TornFactionHofCategory? cat,
  }) {
    generatedMapping.putIfAbsent(TornFactionHofResponse, () => TornFactionHofResponse.fromJsonFactory);

    return _tornFactionhofGet(limit: limit, offset: offset, cat: cat?.value?.toString());
  }

  ///Get faction hall of fame positions for a specific category
  ///@param limit
  ///@param offset
  ///@param cat Leaderboards category
  @GET(path: '/torn/factionhof')
  Future<chopper.Response<TornFactionHofResponse>> _tornFactionhofGet({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('cat') required String? cat,
  });

  ///Get available log ids for a specific log category
  ///@param logCategoryId Log category id
  Future<chopper.Response<TornLogTypesResponse>> tornLogCategoryIdLogtypesGet({required int? logCategoryId}) {
    generatedMapping.putIfAbsent(TornLogTypesResponse, () => TornLogTypesResponse.fromJsonFactory);

    return _tornLogCategoryIdLogtypesGet(logCategoryId: logCategoryId);
  }

  ///Get available log ids for a specific log category
  ///@param logCategoryId Log category id
  @GET(path: '/torn/{logCategoryId}/logtypes')
  Future<chopper.Response<TornLogTypesResponse>> _tornLogCategoryIdLogtypesGet(
      {@Path('logCategoryId') required int? logCategoryId});

  ///Get all available log ids
  Future<chopper.Response<TornLogTypesResponse>> tornLogtypesGet() {
    generatedMapping.putIfAbsent(TornLogTypesResponse, () => TornLogTypesResponse.fromJsonFactory);

    return _tornLogtypesGet();
  }

  ///Get all available log ids
  @GET(path: '/torn/logtypes')
  Future<chopper.Response<TornLogTypesResponse>> _tornLogtypesGet();

  ///Get available log categories
  Future<chopper.Response<TornLogCategoriesResponse>> tornLogcategoriesGet() {
    generatedMapping.putIfAbsent(TornLogCategoriesResponse, () => TornLogCategoriesResponse.fromJsonFactory);

    return _tornLogcategoriesGet();
  }

  ///Get available log categories
  @GET(path: '/torn/logcategories')
  Future<chopper.Response<TornLogCategoriesResponse>> _tornLogcategoriesGet();

  ///Get bounties
  ///@param limit
  ///@param offset
  Future<chopper.Response<TornBountiesResponse>> tornBountiesGet({
    int? limit,
    int? offset,
  }) {
    generatedMapping.putIfAbsent(TornBountiesResponse, () => TornBountiesResponse.fromJsonFactory);

    return _tornBountiesGet(limit: limit, offset: offset);
  }

  ///Get bounties
  ///@param limit
  ///@param offset
  @GET(path: '/torn/bounties')
  Future<chopper.Response<TornBountiesResponse>> _tornBountiesGet({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  ///Get all available torn selections
  Future<chopper.Response<TornLookupResponse>> tornLookupGet() {
    generatedMapping.putIfAbsent(TornLookupResponse, () => TornLookupResponse.fromJsonFactory);

    return _tornLookupGet();
  }

  ///Get all available torn selections
  @GET(path: '/torn/lookup')
  Future<chopper.Response<TornLookupResponse>> _tornLookupGet();

  ///Get current server time
  Future<chopper.Response<TimestampResponse>> tornTimestampGet() {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _tornTimestampGet();
  }

  ///Get current server time
  @GET(path: '/torn/timestamp')
  Future<chopper.Response<TimestampResponse>> _tornTimestampGet();

  ///Get any Torn selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  Future<chopper.Response> tornGet({
    List<enums.TornSelectionName>? selections,
    String? id,
    enums.ApiStripTags? striptags,
    int? limit,
    int? to,
    int? from,
    String? cat,
    enums.TornGetSort? sort,
    int? offset,
  }) {
    return _tornGet(
        selections: tornSelectionNameListToJson(selections),
        id: id,
        striptags: striptags?.value?.toString(),
        limit: limit,
        to: to,
        from: from,
        cat: cat,
        sort: sort?.value?.toString(),
        offset: offset);
  }

  ///Get any Torn selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  @GET(path: '/torn')
  Future<chopper.Response> _tornGet({
    @Query('selections') List<Object?>? selections,
    @Query('id') String? id,
    @Query('striptags') String? striptags,
    @Query('limit') int? limit,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') String? cat,
    @Query('sort') String? sort,
    @Query('offset') int? offset,
  });

  ///Get a player's personal stats
  ///@param id User id
  ///@param cat
  ///@param stat Stat names (10 maximum). Used to fetch historical stat values
  ///@param timestamp Returns stats until this timestamp (converted to nearest date).
  Future<chopper.Response<UserPersonalStatsResponse>> userIdPersonalstatsGet({
    required int? id,
    enums.PersonalStatsCategoryEnum? cat,
    List<enums.PersonalStatsStatName>? stat,
    int? timestamp,
  }) {
    generatedMapping.putIfAbsent(UserPersonalStatsResponse, () => UserPersonalStatsResponse.fromJsonFactory);

    return _userIdPersonalstatsGet(
        id: id, cat: cat?.value?.toString(), stat: personalStatsStatNameListToJson(stat), timestamp: timestamp);
  }

  ///Get a player's personal stats
  ///@param id User id
  ///@param cat
  ///@param stat Stat names (10 maximum). Used to fetch historical stat values
  ///@param timestamp Returns stats until this timestamp (converted to nearest date).
  @GET(path: '/user/{id}/personalstats')
  Future<chopper.Response<UserPersonalStatsResponse>> _userIdPersonalstatsGet({
    @Path('id') required int? id,
    @Query('cat') String? cat,
    @Query('stat') List<Object?>? stat,
    @Query('timestamp') int? timestamp,
  });

  ///Get your personal stats
  ///@param cat Stats category. Required unless requesting specific stats via 'stat' query parameter
  ///@param stat Stat names (10 maximum). Used to fetch historical stat values
  ///@param timestamp Returns stats until this timestamp (converted to nearest date).
  Future<chopper.Response<UserPersonalStatsResponse>> userPersonalstatsGet({
    enums.PersonalStatsCategoryEnum? cat,
    List<enums.PersonalStatsStatName>? stat,
    int? timestamp,
  }) {
    generatedMapping.putIfAbsent(UserPersonalStatsResponse, () => UserPersonalStatsResponse.fromJsonFactory);

    return _userPersonalstatsGet(
        cat: cat?.value?.toString(), stat: personalStatsStatNameListToJson(stat), timestamp: timestamp);
  }

  ///Get your personal stats
  ///@param cat Stats category. Required unless requesting specific stats via 'stat' query parameter
  ///@param stat Stat names (10 maximum). Used to fetch historical stat values
  ///@param timestamp Returns stats until this timestamp (converted to nearest date).
  @GET(path: '/user/personalstats')
  Future<chopper.Response<UserPersonalStatsResponse>> _userPersonalstatsGet({
    @Query('cat') String? cat,
    @Query('stat') List<Object?>? stat,
    @Query('timestamp') int? timestamp,
  });

  ///Get your crime statistics
  ///@param crimeId Crime id
  Future<chopper.Response<UserCrimesResponse>> userCrimeIdCrimesGet({required String? crimeId}) {
    generatedMapping.putIfAbsent(UserCrimesResponse, () => UserCrimesResponse.fromJsonFactory);

    return _userCrimeIdCrimesGet(crimeId: crimeId);
  }

  ///Get your crime statistics
  ///@param crimeId Crime id
  @GET(path: '/user/{crimeId}/crimes')
  Future<chopper.Response<UserCrimesResponse>> _userCrimeIdCrimesGet({@Path('crimeId') required String? crimeId});

  ///Get user races
  ///@param limit
  ///@param sort Sorted by schedule.start field
  ///@param to Timestamp until when started races are returned (schedule.start)
  ///@param from Timestamp after when started races are returned (scheduled.start)
  ///@param cat Category of races returned
  Future<chopper.Response<UserRacesResponse>> userRacesGet({
    int? limit,
    enums.UserRacesGetSort? sort,
    int? to,
    int? from,
    enums.UserRacesGetCat? cat,
  }) {
    generatedMapping.putIfAbsent(UserRacesResponse, () => UserRacesResponse.fromJsonFactory);

    return _userRacesGet(limit: limit, sort: sort?.value?.toString(), to: to, from: from, cat: cat?.value?.toString());
  }

  ///Get user races
  ///@param limit
  ///@param sort Sorted by schedule.start field
  ///@param to Timestamp until when started races are returned (schedule.start)
  ///@param from Timestamp after when started races are returned (scheduled.start)
  ///@param cat Category of races returned
  @GET(path: '/user/races')
  Future<chopper.Response<UserRacesResponse>> _userRacesGet({
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') String? cat,
  });

  ///Get user enlisted cars
  Future<chopper.Response<UserEnlistedCarsResponse>> userEnlistedcarsGet() {
    generatedMapping.putIfAbsent(UserEnlistedCarsResponse, () => UserEnlistedCarsResponse.fromJsonFactory);

    return _userEnlistedcarsGet();
  }

  ///Get user enlisted cars
  @GET(path: '/user/enlistedcars')
  Future<chopper.Response<UserEnlistedCarsResponse>> _userEnlistedcarsGet();

  ///Get posts for a specific player
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param id User id
  ///@param limit
  ///@param sort Sorted by post created timestamp
  ///@param to Returns posts created before this timestamp
  ///@param from Returns posts created after this timestamp
  Future<chopper.Response<UserForumPostsResponse>> userIdForumpostsGet({
    enums.ApiStripTagsTrue? striptags,
    required int? id,
    int? limit,
    enums.UserIdForumpostsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(UserForumPostsResponse, () => UserForumPostsResponse.fromJsonFactory);

    return _userIdForumpostsGet(
        striptags: striptags?.value?.toString(),
        id: id,
        limit: limit,
        sort: sort?.value?.toString(),
        to: to,
        from: from);
  }

  ///Get posts for a specific player
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param id User id
  ///@param limit
  ///@param sort Sorted by post created timestamp
  ///@param to Returns posts created before this timestamp
  ///@param from Returns posts created after this timestamp
  @GET(path: '/user/{id}/forumposts')
  Future<chopper.Response<UserForumPostsResponse>> _userIdForumpostsGet({
    @Query('striptags') String? striptags,
    @Path('id') required int? id,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get your posts
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param sort Sorted by post created timestamp
  ///@param to Returns posts created before this timestamp
  ///@param from Returns posts created after this timestamp
  Future<chopper.Response<UserForumPostsResponse>> userForumpostsGet({
    enums.ApiStripTagsTrue? striptags,
    int? limit,
    enums.UserForumpostsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(UserForumPostsResponse, () => UserForumPostsResponse.fromJsonFactory);

    return _userForumpostsGet(
        striptags: striptags?.value?.toString(), limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get your posts
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param sort Sorted by post created timestamp
  ///@param to Returns posts created before this timestamp
  ///@param from Returns posts created after this timestamp
  @GET(path: '/user/forumposts')
  Future<chopper.Response<UserForumPostsResponse>> _userForumpostsGet({
    @Query('striptags') String? striptags,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get threads for a specific player
  ///@param id User id
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  Future<chopper.Response<UserForumThreadsResponse>> userIdForumthreadsGet({
    required int? id,
    int? limit,
    enums.UserIdForumthreadsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(UserForumThreadsResponse, () => UserForumThreadsResponse.fromJsonFactory);

    return _userIdForumthreadsGet(id: id, limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get threads for a specific player
  ///@param id User id
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  @GET(path: '/user/{id}/forumthreads')
  Future<chopper.Response<UserForumThreadsResponse>> _userIdForumthreadsGet({
    @Path('id') required int? id,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get your threads
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  Future<chopper.Response<UserForumThreadsResponse>> userForumthreadsGet({
    int? limit,
    enums.UserForumthreadsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(UserForumThreadsResponse, () => UserForumThreadsResponse.fromJsonFactory);

    return _userForumthreadsGet(limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get your threads
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  @GET(path: '/user/forumthreads')
  Future<chopper.Response<UserForumThreadsResponse>> _userForumthreadsGet({
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get updates on threads you subscribed to
  Future<chopper.Response<UserForumSubscribedThreadsResponse>> userForumsubscribedthreadsGet() {
    generatedMapping.putIfAbsent(
        UserForumSubscribedThreadsResponse, () => UserForumSubscribedThreadsResponse.fromJsonFactory);

    return _userForumsubscribedthreadsGet();
  }

  ///Get updates on threads you subscribed to
  @GET(path: '/user/forumsubscribedthreads')
  Future<chopper.Response<UserForumSubscribedThreadsResponse>> _userForumsubscribedthreadsGet();

  ///Get updates on your threads and posts
  Future<chopper.Response<UserForumFeedResponse>> userForumfeedGet() {
    generatedMapping.putIfAbsent(UserForumFeedResponse, () => UserForumFeedResponse.fromJsonFactory);

    return _userForumfeedGet();
  }

  ///Get updates on your threads and posts
  @GET(path: '/user/forumfeed')
  Future<chopper.Response<UserForumFeedResponse>> _userForumfeedGet();

  ///Get updates on your friends' activity
  Future<chopper.Response<UserForumFriendsResponse>> userForumfriendsGet() {
    generatedMapping.putIfAbsent(UserForumFriendsResponse, () => UserForumFriendsResponse.fromJsonFactory);

    return _userForumfriendsGet();
  }

  ///Get updates on your friends' activity
  @GET(path: '/user/forumfriends')
  Future<chopper.Response<UserForumFriendsResponse>> _userForumfriendsGet();

  ///Get hall of fame rankings for a specific player
  ///@param id User id
  Future<chopper.Response<UserHofResponse>> userIdHofGet({required int? id}) {
    generatedMapping.putIfAbsent(UserHofResponse, () => UserHofResponse.fromJsonFactory);

    return _userIdHofGet(id: id);
  }

  ///Get hall of fame rankings for a specific player
  ///@param id User id
  @GET(path: '/user/{id}/hof')
  Future<chopper.Response<UserHofResponse>> _userIdHofGet({@Path('id') required int? id});

  ///Get your hall of fame rankings
  Future<chopper.Response<UserHofResponse>> userHofGet() {
    generatedMapping.putIfAbsent(UserHofResponse, () => UserHofResponse.fromJsonFactory);

    return _userHofGet();
  }

  ///Get your hall of fame rankings
  @GET(path: '/user/hof')
  Future<chopper.Response<UserHofResponse>> _userHofGet();

  ///Get your competition's event start time
  Future<chopper.Response<UserCalendarResponse>> userCalendarGet() {
    generatedMapping.putIfAbsent(UserCalendarResponse, () => UserCalendarResponse.fromJsonFactory);

    return _userCalendarGet();
  }

  ///Get your competition's event start time
  @GET(path: '/user/calendar')
  Future<chopper.Response<UserCalendarResponse>> _userCalendarGet();

  ///Get bounties placed on a specific user
  ///@param id User id
  Future<chopper.Response<UserBountiesResponse>> userIdBountiesGet({required int? id}) {
    generatedMapping.putIfAbsent(UserBountiesResponse, () => UserBountiesResponse.fromJsonFactory);

    return _userIdBountiesGet(id: id);
  }

  ///Get bounties placed on a specific user
  ///@param id User id
  @GET(path: '/user/{id}/bounties')
  Future<chopper.Response<UserBountiesResponse>> _userIdBountiesGet({@Path('id') required int? id});

  ///Get bounties placed on you
  Future<chopper.Response<UserBountiesResponse>> userBountiesGet() {
    generatedMapping.putIfAbsent(UserBountiesResponse, () => UserBountiesResponse.fromJsonFactory);

    return _userBountiesGet();
  }

  ///Get bounties placed on you
  @GET(path: '/user/bounties')
  Future<chopper.Response<UserBountiesResponse>> _userBountiesGet();

  ///Get your starter job positions
  Future<chopper.Response<UserJobRanksResponse>> userJobranksGet() {
    generatedMapping.putIfAbsent(UserJobRanksResponse, () => UserJobRanksResponse.fromJsonFactory);

    return _userJobranksGet();
  }

  ///Get your starter job positions
  @GET(path: '/user/jobranks')
  Future<chopper.Response<UserJobRanksResponse>> _userJobranksGet();

  ///Get your item market listings for a specific item
  ///@param offset
  Future<chopper.Response<UserItemMarketResponse>> userItemmarketGet({int? offset}) {
    generatedMapping.putIfAbsent(UserItemMarketResponse, () => UserItemMarketResponse.fromJsonFactory);

    return _userItemmarketGet(offset: offset);
  }

  ///Get your item market listings for a specific item
  ///@param offset
  @GET(path: '/user/itemmarket')
  Future<chopper.Response<UserItemMarketResponse>> _userItemmarketGet({@Query('offset') int? offset});

  ///Get your current faction balance
  Future<chopper.Response<UserFactionBalanceResponse>> userFactionbalanceGet() {
    generatedMapping.putIfAbsent(UserFactionBalanceResponse, () => UserFactionBalanceResponse.fromJsonFactory);

    return _userFactionbalanceGet();
  }

  ///Get your current faction balance
  @GET(path: '/user/factionbalance')
  Future<chopper.Response<UserFactionBalanceResponse>> _userFactionbalanceGet();

  ///Get your current ongoing organized crime
  Future<chopper.Response<UserOrganizedCrimeResponse>> userOrganizedcrimeGet() {
    generatedMapping.putIfAbsent(UserOrganizedCrimeResponse, () => UserOrganizedCrimeResponse.fromJsonFactory);

    return _userOrganizedcrimeGet();
  }

  ///Get your current ongoing organized crime
  @GET(path: '/user/organizedcrime')
  Future<chopper.Response<UserOrganizedCrimeResponse>> _userOrganizedcrimeGet();

  ///Get all available user selections
  Future<chopper.Response<UserLookupResponse>> userLookupGet() {
    generatedMapping.putIfAbsent(UserLookupResponse, () => UserLookupResponse.fromJsonFactory);

    return _userLookupGet();
  }

  ///Get all available user selections
  @GET(path: '/user/lookup')
  Future<chopper.Response<UserLookupResponse>> _userLookupGet();

  ///Get current server time
  Future<chopper.Response<TimestampResponse>> userTimestampGet() {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _userTimestampGet();
  }

  ///Get current server time
  @GET(path: '/user/timestamp')
  Future<chopper.Response<TimestampResponse>> _userTimestampGet();

  ///Get any User selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param stat Selection stat
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param sort Direction to sort rows in
  ///@param offset
  Future<chopper.Response> userGet({
    String? selections,
    String? id,
    int? limit,
    int? to,
    int? from,
    String? cat,
    String? stat,
    enums.ApiStripTags? striptags,
    enums.UserGetSort? sort,
    int? offset,
  }) {
    return _userGet(
        selections: selections,
        id: id,
        limit: limit,
        to: to,
        from: from,
        cat: cat,
        stat: stat,
        striptags: striptags?.value?.toString(),
        sort: sort?.value?.toString(),
        offset: offset);
  }

  ///Get any User selection
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param stat Selection stat
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param sort Direction to sort rows in
  ///@param offset
  @GET(path: '/user')
  Future<chopper.Response> _userGet({
    @Query('selections') String? selections,
    @Query('id') String? id,
    @Query('limit') int? limit,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') String? cat,
    @Query('stat') String? stat,
    @Query('striptags') String? striptags,
    @Query('sort') String? sort,
    @Query('offset') int? offset,
  });
}

@JsonSerializable(explicitToJson: true)
class RequestLinks {
  const RequestLinks({
    this.next,
    this.prev,
  });

  factory RequestLinks.fromJson(Map<String, dynamic> json) => _$RequestLinksFromJson(json);

  static const toJsonFactory = _$RequestLinksToJson;
  Map<String, dynamic> toJson() => _$RequestLinksToJson(this);

  @JsonKey(name: 'next')
  final String? next;
  @JsonKey(name: 'prev')
  final String? prev;
  static const fromJsonFactory = _$RequestLinksFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RequestLinks &&
            (identical(other.next, next) || const DeepCollectionEquality().equals(other.next, next)) &&
            (identical(other.prev, prev) || const DeepCollectionEquality().equals(other.prev, prev)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(next) ^ const DeepCollectionEquality().hash(prev) ^ runtimeType.hashCode;
}

extension $RequestLinksExtension on RequestLinks {
  RequestLinks copyWith({String? next, String? prev}) {
    return RequestLinks(next: next ?? this.next, prev: prev ?? this.prev);
  }

  RequestLinks copyWithWrapped({Wrapped<String?>? next, Wrapped<String?>? prev}) {
    return RequestLinks(next: (next != null ? next.value : this.next), prev: (prev != null ? prev.value : this.prev));
  }
}

@JsonSerializable(explicitToJson: true)
class RequestMetadata {
  const RequestMetadata({
    this.links,
  });

  factory RequestMetadata.fromJson(Map<String, dynamic> json) => _$RequestMetadataFromJson(json);

  static const toJsonFactory = _$RequestMetadataToJson;
  Map<String, dynamic> toJson() => _$RequestMetadataToJson(this);

  @JsonKey(name: 'links')
  final RequestLinks? links;
  static const fromJsonFactory = _$RequestMetadataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RequestMetadata &&
            (identical(other.links, links) || const DeepCollectionEquality().equals(other.links, links)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(links) ^ runtimeType.hashCode;
}

extension $RequestMetadataExtension on RequestMetadata {
  RequestMetadata copyWith({RequestLinks? links}) {
    return RequestMetadata(links: links ?? this.links);
  }

  RequestMetadata copyWithWrapped({Wrapped<RequestLinks?>? links}) {
    return RequestMetadata(links: (links != null ? links.value : this.links));
  }
}

@JsonSerializable(explicitToJson: true)
class RequestMetadataWithLinks {
  const RequestMetadataWithLinks({
    this.links,
  });

  factory RequestMetadataWithLinks.fromJson(Map<String, dynamic> json) => _$RequestMetadataWithLinksFromJson(json);

  static const toJsonFactory = _$RequestMetadataWithLinksToJson;
  Map<String, dynamic> toJson() => _$RequestMetadataWithLinksToJson(this);

  @JsonKey(name: 'links')
  final RequestLinks? links;
  static const fromJsonFactory = _$RequestMetadataWithLinksFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RequestMetadataWithLinks &&
            (identical(other.links, links) || const DeepCollectionEquality().equals(other.links, links)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(links) ^ runtimeType.hashCode;
}

extension $RequestMetadataWithLinksExtension on RequestMetadataWithLinks {
  RequestMetadataWithLinks copyWith({RequestLinks? links}) {
    return RequestMetadataWithLinks(links: links ?? this.links);
  }

  RequestMetadataWithLinks copyWithWrapped({Wrapped<RequestLinks?>? links}) {
    return RequestMetadataWithLinks(links: (links != null ? links.value : this.links));
  }
}

@JsonSerializable(explicitToJson: true)
class AttackPlayerFaction {
  const AttackPlayerFaction({
    this.id,
    this.name,
  });

  factory AttackPlayerFaction.fromJson(Map<String, dynamic> json) => _$AttackPlayerFactionFromJson(json);

  static const toJsonFactory = _$AttackPlayerFactionToJson;
  Map<String, dynamic> toJson() => _$AttackPlayerFactionToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  static const fromJsonFactory = _$AttackPlayerFactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AttackPlayerFaction &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ const DeepCollectionEquality().hash(name) ^ runtimeType.hashCode;
}

extension $AttackPlayerFactionExtension on AttackPlayerFaction {
  AttackPlayerFaction copyWith({int? id, String? name}) {
    return AttackPlayerFaction(id: id ?? this.id, name: name ?? this.name);
  }

  AttackPlayerFaction copyWithWrapped({Wrapped<int?>? id, Wrapped<String?>? name}) {
    return AttackPlayerFaction(id: (id != null ? id.value : this.id), name: (name != null ? name.value : this.name));
  }
}

@JsonSerializable(explicitToJson: true)
class AttackPlayer {
  const AttackPlayer({
    this.id,
    this.name,
    this.level,
    this.faction,
  });

  factory AttackPlayer.fromJson(Map<String, dynamic> json) => _$AttackPlayerFromJson(json);

  static const toJsonFactory = _$AttackPlayerToJson;
  Map<String, dynamic> toJson() => _$AttackPlayerToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'level')
  final int? level;
  @JsonKey(name: 'faction')
  final Object? faction;
  static const fromJsonFactory = _$AttackPlayerFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AttackPlayer &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.level, level) || const DeepCollectionEquality().equals(other.level, level)) &&
            (identical(other.faction, faction) || const DeepCollectionEquality().equals(other.faction, faction)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(level) ^
      const DeepCollectionEquality().hash(faction) ^
      runtimeType.hashCode;
}

extension $AttackPlayerExtension on AttackPlayer {
  AttackPlayer copyWith({int? id, String? name, int? level, Object? faction}) {
    return AttackPlayer(
        id: id ?? this.id, name: name ?? this.name, level: level ?? this.level, faction: faction ?? this.faction);
  }

  AttackPlayer copyWithWrapped(
      {Wrapped<int?>? id, Wrapped<String?>? name, Wrapped<int?>? level, Wrapped<Object?>? faction}) {
    return AttackPlayer(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        level: (level != null ? level.value : this.level),
        faction: (faction != null ? faction.value : this.faction));
  }
}

@JsonSerializable(explicitToJson: true)
class AttackPlayerSimplified {
  const AttackPlayerSimplified({
    this.id,
    this.factionId,
  });

  factory AttackPlayerSimplified.fromJson(Map<String, dynamic> json) => _$AttackPlayerSimplifiedFromJson(json);

  static const toJsonFactory = _$AttackPlayerSimplifiedToJson;
  Map<String, dynamic> toJson() => _$AttackPlayerSimplifiedToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'faction_id')
  final int? factionId;
  static const fromJsonFactory = _$AttackPlayerSimplifiedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AttackPlayerSimplified &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.factionId, factionId) ||
                const DeepCollectionEquality().equals(other.factionId, factionId)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ const DeepCollectionEquality().hash(factionId) ^ runtimeType.hashCode;
}

extension $AttackPlayerSimplifiedExtension on AttackPlayerSimplified {
  AttackPlayerSimplified copyWith({int? id, int? factionId}) {
    return AttackPlayerSimplified(id: id ?? this.id, factionId: factionId ?? this.factionId);
  }

  AttackPlayerSimplified copyWithWrapped({Wrapped<int?>? id, Wrapped<int?>? factionId}) {
    return AttackPlayerSimplified(
        id: (id != null ? id.value : this.id), factionId: (factionId != null ? factionId.value : this.factionId));
  }
}

@JsonSerializable(explicitToJson: true)
class Attack {
  const Attack({
    this.id,
    this.code,
    this.started,
    this.ended,
    this.attacker,
    this.defender,
    this.result,
    this.respectGain,
    this.respectLoss,
    this.chain,
    this.isInterrupted,
    this.isStealthed,
    this.isRaid,
    this.isRankedWar,
    this.modifiers,
  });

  factory Attack.fromJson(Map<String, dynamic> json) => _$AttackFromJson(json);

  static const toJsonFactory = _$AttackToJson;
  Map<String, dynamic> toJson() => _$AttackToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'code')
  final String? code;
  @JsonKey(name: 'started')
  final int? started;
  @JsonKey(name: 'ended')
  final int? ended;
  @JsonKey(name: 'attacker')
  final Object? attacker;
  @JsonKey(name: 'defender')
  final AttackPlayer? defender;
  @JsonKey(
    name: 'result',
    toJson: factionAttackResultNullableToJson,
    fromJson: factionAttackResultNullableFromJson,
  )
  final enums.FactionAttackResult? result;
  @JsonKey(name: 'respect_gain')
  final double? respectGain;
  @JsonKey(name: 'respect_loss')
  final double? respectLoss;
  @JsonKey(name: 'chain')
  final int? chain;
  @JsonKey(name: 'is_interrupted')
  final bool? isInterrupted;
  @JsonKey(name: 'is_stealthed')
  final bool? isStealthed;
  @JsonKey(name: 'is_raid')
  final bool? isRaid;
  @JsonKey(name: 'is_ranked_war')
  final bool? isRankedWar;
  @JsonKey(name: 'modifiers')
  final Attack$Modifiers? modifiers;
  static const fromJsonFactory = _$AttackFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Attack &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.code, code) || const DeepCollectionEquality().equals(other.code, code)) &&
            (identical(other.started, started) || const DeepCollectionEquality().equals(other.started, started)) &&
            (identical(other.ended, ended) || const DeepCollectionEquality().equals(other.ended, ended)) &&
            (identical(other.attacker, attacker) || const DeepCollectionEquality().equals(other.attacker, attacker)) &&
            (identical(other.defender, defender) || const DeepCollectionEquality().equals(other.defender, defender)) &&
            (identical(other.result, result) || const DeepCollectionEquality().equals(other.result, result)) &&
            (identical(other.respectGain, respectGain) ||
                const DeepCollectionEquality().equals(other.respectGain, respectGain)) &&
            (identical(other.respectLoss, respectLoss) ||
                const DeepCollectionEquality().equals(other.respectLoss, respectLoss)) &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)) &&
            (identical(other.isInterrupted, isInterrupted) ||
                const DeepCollectionEquality().equals(other.isInterrupted, isInterrupted)) &&
            (identical(other.isStealthed, isStealthed) ||
                const DeepCollectionEquality().equals(other.isStealthed, isStealthed)) &&
            (identical(other.isRaid, isRaid) || const DeepCollectionEquality().equals(other.isRaid, isRaid)) &&
            (identical(other.isRankedWar, isRankedWar) ||
                const DeepCollectionEquality().equals(other.isRankedWar, isRankedWar)) &&
            (identical(other.modifiers, modifiers) ||
                const DeepCollectionEquality().equals(other.modifiers, modifiers)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(code) ^
      const DeepCollectionEquality().hash(started) ^
      const DeepCollectionEquality().hash(ended) ^
      const DeepCollectionEquality().hash(attacker) ^
      const DeepCollectionEquality().hash(defender) ^
      const DeepCollectionEquality().hash(result) ^
      const DeepCollectionEquality().hash(respectGain) ^
      const DeepCollectionEquality().hash(respectLoss) ^
      const DeepCollectionEquality().hash(chain) ^
      const DeepCollectionEquality().hash(isInterrupted) ^
      const DeepCollectionEquality().hash(isStealthed) ^
      const DeepCollectionEquality().hash(isRaid) ^
      const DeepCollectionEquality().hash(isRankedWar) ^
      const DeepCollectionEquality().hash(modifiers) ^
      runtimeType.hashCode;
}

extension $AttackExtension on Attack {
  Attack copyWith(
      {int? id,
      String? code,
      int? started,
      int? ended,
      Object? attacker,
      AttackPlayer? defender,
      enums.FactionAttackResult? result,
      double? respectGain,
      double? respectLoss,
      int? chain,
      bool? isInterrupted,
      bool? isStealthed,
      bool? isRaid,
      bool? isRankedWar,
      Attack$Modifiers? modifiers}) {
    return Attack(
        id: id ?? this.id,
        code: code ?? this.code,
        started: started ?? this.started,
        ended: ended ?? this.ended,
        attacker: attacker ?? this.attacker,
        defender: defender ?? this.defender,
        result: result ?? this.result,
        respectGain: respectGain ?? this.respectGain,
        respectLoss: respectLoss ?? this.respectLoss,
        chain: chain ?? this.chain,
        isInterrupted: isInterrupted ?? this.isInterrupted,
        isStealthed: isStealthed ?? this.isStealthed,
        isRaid: isRaid ?? this.isRaid,
        isRankedWar: isRankedWar ?? this.isRankedWar,
        modifiers: modifiers ?? this.modifiers);
  }

  Attack copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? code,
      Wrapped<int?>? started,
      Wrapped<int?>? ended,
      Wrapped<Object?>? attacker,
      Wrapped<AttackPlayer?>? defender,
      Wrapped<enums.FactionAttackResult?>? result,
      Wrapped<double?>? respectGain,
      Wrapped<double?>? respectLoss,
      Wrapped<int?>? chain,
      Wrapped<bool?>? isInterrupted,
      Wrapped<bool?>? isStealthed,
      Wrapped<bool?>? isRaid,
      Wrapped<bool?>? isRankedWar,
      Wrapped<Attack$Modifiers?>? modifiers}) {
    return Attack(
        id: (id != null ? id.value : this.id),
        code: (code != null ? code.value : this.code),
        started: (started != null ? started.value : this.started),
        ended: (ended != null ? ended.value : this.ended),
        attacker: (attacker != null ? attacker.value : this.attacker),
        defender: (defender != null ? defender.value : this.defender),
        result: (result != null ? result.value : this.result),
        respectGain: (respectGain != null ? respectGain.value : this.respectGain),
        respectLoss: (respectLoss != null ? respectLoss.value : this.respectLoss),
        chain: (chain != null ? chain.value : this.chain),
        isInterrupted: (isInterrupted != null ? isInterrupted.value : this.isInterrupted),
        isStealthed: (isStealthed != null ? isStealthed.value : this.isStealthed),
        isRaid: (isRaid != null ? isRaid.value : this.isRaid),
        isRankedWar: (isRankedWar != null ? isRankedWar.value : this.isRankedWar),
        modifiers: (modifiers != null ? modifiers.value : this.modifiers));
  }
}

@JsonSerializable(explicitToJson: true)
class AttackSimplified {
  const AttackSimplified({
    this.id,
    this.code,
    this.started,
    this.ended,
    this.attacker,
    this.defender,
    this.result,
    this.respectGain,
    this.respectLoss,
  });

  factory AttackSimplified.fromJson(Map<String, dynamic> json) => _$AttackSimplifiedFromJson(json);

  static const toJsonFactory = _$AttackSimplifiedToJson;
  Map<String, dynamic> toJson() => _$AttackSimplifiedToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'code')
  final String? code;
  @JsonKey(name: 'started')
  final int? started;
  @JsonKey(name: 'ended')
  final int? ended;
  @JsonKey(name: 'attacker')
  final Object? attacker;
  @JsonKey(name: 'defender')
  final AttackPlayerSimplified? defender;
  @JsonKey(
    name: 'result',
    toJson: factionAttackResultNullableToJson,
    fromJson: factionAttackResultNullableFromJson,
  )
  final enums.FactionAttackResult? result;
  @JsonKey(name: 'respect_gain')
  final double? respectGain;
  @JsonKey(name: 'respect_loss')
  final double? respectLoss;
  static const fromJsonFactory = _$AttackSimplifiedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AttackSimplified &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.code, code) || const DeepCollectionEquality().equals(other.code, code)) &&
            (identical(other.started, started) || const DeepCollectionEquality().equals(other.started, started)) &&
            (identical(other.ended, ended) || const DeepCollectionEquality().equals(other.ended, ended)) &&
            (identical(other.attacker, attacker) || const DeepCollectionEquality().equals(other.attacker, attacker)) &&
            (identical(other.defender, defender) || const DeepCollectionEquality().equals(other.defender, defender)) &&
            (identical(other.result, result) || const DeepCollectionEquality().equals(other.result, result)) &&
            (identical(other.respectGain, respectGain) ||
                const DeepCollectionEquality().equals(other.respectGain, respectGain)) &&
            (identical(other.respectLoss, respectLoss) ||
                const DeepCollectionEquality().equals(other.respectLoss, respectLoss)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(code) ^
      const DeepCollectionEquality().hash(started) ^
      const DeepCollectionEquality().hash(ended) ^
      const DeepCollectionEquality().hash(attacker) ^
      const DeepCollectionEquality().hash(defender) ^
      const DeepCollectionEquality().hash(result) ^
      const DeepCollectionEquality().hash(respectGain) ^
      const DeepCollectionEquality().hash(respectLoss) ^
      runtimeType.hashCode;
}

extension $AttackSimplifiedExtension on AttackSimplified {
  AttackSimplified copyWith(
      {int? id,
      String? code,
      int? started,
      int? ended,
      Object? attacker,
      AttackPlayerSimplified? defender,
      enums.FactionAttackResult? result,
      double? respectGain,
      double? respectLoss}) {
    return AttackSimplified(
        id: id ?? this.id,
        code: code ?? this.code,
        started: started ?? this.started,
        ended: ended ?? this.ended,
        attacker: attacker ?? this.attacker,
        defender: defender ?? this.defender,
        result: result ?? this.result,
        respectGain: respectGain ?? this.respectGain,
        respectLoss: respectLoss ?? this.respectLoss);
  }

  AttackSimplified copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? code,
      Wrapped<int?>? started,
      Wrapped<int?>? ended,
      Wrapped<Object?>? attacker,
      Wrapped<AttackPlayerSimplified?>? defender,
      Wrapped<enums.FactionAttackResult?>? result,
      Wrapped<double?>? respectGain,
      Wrapped<double?>? respectLoss}) {
    return AttackSimplified(
        id: (id != null ? id.value : this.id),
        code: (code != null ? code.value : this.code),
        started: (started != null ? started.value : this.started),
        ended: (ended != null ? ended.value : this.ended),
        attacker: (attacker != null ? attacker.value : this.attacker),
        defender: (defender != null ? defender.value : this.defender),
        result: (result != null ? result.value : this.result),
        respectGain: (respectGain != null ? respectGain.value : this.respectGain),
        respectLoss: (respectLoss != null ? respectLoss.value : this.respectLoss));
  }
}

@JsonSerializable(explicitToJson: true)
class TimestampResponse {
  const TimestampResponse({
    this.timestamp,
  });

  factory TimestampResponse.fromJson(Map<String, dynamic> json) => _$TimestampResponseFromJson(json);

  static const toJsonFactory = _$TimestampResponseToJson;
  Map<String, dynamic> toJson() => _$TimestampResponseToJson(this);

  @JsonKey(name: 'timestamp')
  final int? timestamp;
  static const fromJsonFactory = _$TimestampResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TimestampResponse &&
            (identical(other.timestamp, timestamp) ||
                const DeepCollectionEquality().equals(other.timestamp, timestamp)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(timestamp) ^ runtimeType.hashCode;
}

extension $TimestampResponseExtension on TimestampResponse {
  TimestampResponse copyWith({int? timestamp}) {
    return TimestampResponse(timestamp: timestamp ?? this.timestamp);
  }

  TimestampResponse copyWithWrapped({Wrapped<int?>? timestamp}) {
    return TimestampResponse(timestamp: (timestamp != null ? timestamp.value : this.timestamp));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionHofStats {
  const FactionHofStats({
    this.rank,
    this.respect,
    this.chain,
  });

  factory FactionHofStats.fromJson(Map<String, dynamic> json) => _$FactionHofStatsFromJson(json);

  static const toJsonFactory = _$FactionHofStatsToJson;
  Map<String, dynamic> toJson() => _$FactionHofStatsToJson(this);

  @JsonKey(name: 'rank')
  final HofValueString? rank;
  @JsonKey(name: 'respect')
  final HofValue? respect;
  @JsonKey(name: 'chain')
  final HofValue? chain;
  static const fromJsonFactory = _$FactionHofStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionHofStats &&
            (identical(other.rank, rank) || const DeepCollectionEquality().equals(other.rank, rank)) &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)) &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(rank) ^
      const DeepCollectionEquality().hash(respect) ^
      const DeepCollectionEquality().hash(chain) ^
      runtimeType.hashCode;
}

extension $FactionHofStatsExtension on FactionHofStats {
  FactionHofStats copyWith({HofValueString? rank, HofValue? respect, HofValue? chain}) {
    return FactionHofStats(rank: rank ?? this.rank, respect: respect ?? this.respect, chain: chain ?? this.chain);
  }

  FactionHofStats copyWithWrapped(
      {Wrapped<HofValueString?>? rank, Wrapped<HofValue?>? respect, Wrapped<HofValue?>? chain}) {
    return FactionHofStats(
        rank: (rank != null ? rank.value : this.rank),
        respect: (respect != null ? respect.value : this.respect),
        chain: (chain != null ? chain.value : this.chain));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionHofResponse {
  const FactionHofResponse({
    this.hof,
  });

  factory FactionHofResponse.fromJson(Map<String, dynamic> json) => _$FactionHofResponseFromJson(json);

  static const toJsonFactory = _$FactionHofResponseToJson;
  Map<String, dynamic> toJson() => _$FactionHofResponseToJson(this);

  @JsonKey(name: 'hof', defaultValue: <FactionHofStats>[])
  final List<FactionHofStats>? hof;
  static const fromJsonFactory = _$FactionHofResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionHofResponse &&
            (identical(other.hof, hof) || const DeepCollectionEquality().equals(other.hof, hof)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(hof) ^ runtimeType.hashCode;
}

extension $FactionHofResponseExtension on FactionHofResponse {
  FactionHofResponse copyWith({List<FactionHofStats>? hof}) {
    return FactionHofResponse(hof: hof ?? this.hof);
  }

  FactionHofResponse copyWithWrapped({Wrapped<List<FactionHofStats>?>? hof}) {
    return FactionHofResponse(hof: (hof != null ? hof.value : this.hof));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionMember {
  const FactionMember({
    this.id,
    this.name,
    this.position,
    this.level,
    this.daysInFaction,
    this.isRevivable,
    this.isOnWall,
    this.isInOc,
    this.hasEarlyDischarge,
    this.lastAction,
    this.status,
    this.life,
    this.reviveSetting,
  });

  factory FactionMember.fromJson(Map<String, dynamic> json) => _$FactionMemberFromJson(json);

  static const toJsonFactory = _$FactionMemberToJson;
  Map<String, dynamic> toJson() => _$FactionMemberToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'position')
  final String? position;
  @JsonKey(name: 'level')
  final int? level;
  @JsonKey(name: 'days_in_faction')
  final int? daysInFaction;
  @JsonKey(name: 'is_revivable')
  final bool? isRevivable;
  @JsonKey(name: 'is_on_wall')
  final bool? isOnWall;
  @JsonKey(name: 'is_in_oc')
  final bool? isInOc;
  @JsonKey(name: 'has_early_discharge')
  final bool? hasEarlyDischarge;
  @JsonKey(name: 'last_action')
  final UserLastAction? lastAction;
  @JsonKey(name: 'status')
  final UserStatus? status;
  @JsonKey(name: 'life')
  final UserLife? life;
  @JsonKey(
    name: 'revive_setting',
    toJson: reviveSettingNullableToJson,
    fromJson: reviveSettingNullableFromJson,
  )
  final enums.ReviveSetting? reviveSetting;
  static const fromJsonFactory = _$FactionMemberFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionMember &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.position, position) || const DeepCollectionEquality().equals(other.position, position)) &&
            (identical(other.level, level) || const DeepCollectionEquality().equals(other.level, level)) &&
            (identical(other.daysInFaction, daysInFaction) ||
                const DeepCollectionEquality().equals(other.daysInFaction, daysInFaction)) &&
            (identical(other.isRevivable, isRevivable) ||
                const DeepCollectionEquality().equals(other.isRevivable, isRevivable)) &&
            (identical(other.isOnWall, isOnWall) || const DeepCollectionEquality().equals(other.isOnWall, isOnWall)) &&
            (identical(other.isInOc, isInOc) || const DeepCollectionEquality().equals(other.isInOc, isInOc)) &&
            (identical(other.hasEarlyDischarge, hasEarlyDischarge) ||
                const DeepCollectionEquality().equals(other.hasEarlyDischarge, hasEarlyDischarge)) &&
            (identical(other.lastAction, lastAction) ||
                const DeepCollectionEquality().equals(other.lastAction, lastAction)) &&
            (identical(other.status, status) || const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.life, life) || const DeepCollectionEquality().equals(other.life, life)) &&
            (identical(other.reviveSetting, reviveSetting) ||
                const DeepCollectionEquality().equals(other.reviveSetting, reviveSetting)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(position) ^
      const DeepCollectionEquality().hash(level) ^
      const DeepCollectionEquality().hash(daysInFaction) ^
      const DeepCollectionEquality().hash(isRevivable) ^
      const DeepCollectionEquality().hash(isOnWall) ^
      const DeepCollectionEquality().hash(isInOc) ^
      const DeepCollectionEquality().hash(hasEarlyDischarge) ^
      const DeepCollectionEquality().hash(lastAction) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(life) ^
      const DeepCollectionEquality().hash(reviveSetting) ^
      runtimeType.hashCode;
}

extension $FactionMemberExtension on FactionMember {
  FactionMember copyWith(
      {int? id,
      String? name,
      String? position,
      int? level,
      int? daysInFaction,
      bool? isRevivable,
      bool? isOnWall,
      bool? isInOc,
      bool? hasEarlyDischarge,
      UserLastAction? lastAction,
      UserStatus? status,
      UserLife? life,
      enums.ReviveSetting? reviveSetting}) {
    return FactionMember(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
        level: level ?? this.level,
        daysInFaction: daysInFaction ?? this.daysInFaction,
        isRevivable: isRevivable ?? this.isRevivable,
        isOnWall: isOnWall ?? this.isOnWall,
        isInOc: isInOc ?? this.isInOc,
        hasEarlyDischarge: hasEarlyDischarge ?? this.hasEarlyDischarge,
        lastAction: lastAction ?? this.lastAction,
        status: status ?? this.status,
        life: life ?? this.life,
        reviveSetting: reviveSetting ?? this.reviveSetting);
  }

  FactionMember copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<String?>? position,
      Wrapped<int?>? level,
      Wrapped<int?>? daysInFaction,
      Wrapped<bool?>? isRevivable,
      Wrapped<bool?>? isOnWall,
      Wrapped<bool?>? isInOc,
      Wrapped<bool?>? hasEarlyDischarge,
      Wrapped<UserLastAction?>? lastAction,
      Wrapped<UserStatus?>? status,
      Wrapped<UserLife?>? life,
      Wrapped<enums.ReviveSetting?>? reviveSetting}) {
    return FactionMember(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        position: (position != null ? position.value : this.position),
        level: (level != null ? level.value : this.level),
        daysInFaction: (daysInFaction != null ? daysInFaction.value : this.daysInFaction),
        isRevivable: (isRevivable != null ? isRevivable.value : this.isRevivable),
        isOnWall: (isOnWall != null ? isOnWall.value : this.isOnWall),
        isInOc: (isInOc != null ? isInOc.value : this.isInOc),
        hasEarlyDischarge: (hasEarlyDischarge != null ? hasEarlyDischarge.value : this.hasEarlyDischarge),
        lastAction: (lastAction != null ? lastAction.value : this.lastAction),
        status: (status != null ? status.value : this.status),
        life: (life != null ? life.value : this.life),
        reviveSetting: (reviveSetting != null ? reviveSetting.value : this.reviveSetting));
  }
}

@JsonSerializable(explicitToJson: true)
class UserLastAction {
  const UserLastAction({
    this.status,
    this.timestamp,
    this.relative,
  });

  factory UserLastAction.fromJson(Map<String, dynamic> json) => _$UserLastActionFromJson(json);

  static const toJsonFactory = _$UserLastActionToJson;
  Map<String, dynamic> toJson() => _$UserLastActionToJson(this);

  @JsonKey(name: 'status')
  final String? status;
  @JsonKey(name: 'timestamp')
  final int? timestamp;
  @JsonKey(name: 'relative')
  final String? relative;
  static const fromJsonFactory = _$UserLastActionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserLastAction &&
            (identical(other.status, status) || const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.timestamp, timestamp) ||
                const DeepCollectionEquality().equals(other.timestamp, timestamp)) &&
            (identical(other.relative, relative) || const DeepCollectionEquality().equals(other.relative, relative)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(timestamp) ^
      const DeepCollectionEquality().hash(relative) ^
      runtimeType.hashCode;
}

extension $UserLastActionExtension on UserLastAction {
  UserLastAction copyWith({String? status, int? timestamp, String? relative}) {
    return UserLastAction(
        status: status ?? this.status, timestamp: timestamp ?? this.timestamp, relative: relative ?? this.relative);
  }

  UserLastAction copyWithWrapped({Wrapped<String?>? status, Wrapped<int?>? timestamp, Wrapped<String?>? relative}) {
    return UserLastAction(
        status: (status != null ? status.value : this.status),
        timestamp: (timestamp != null ? timestamp.value : this.timestamp),
        relative: (relative != null ? relative.value : this.relative));
  }
}

@JsonSerializable(explicitToJson: true)
class UserLife {
  const UserLife({
    this.current,
    this.maximum,
  });

  factory UserLife.fromJson(Map<String, dynamic> json) => _$UserLifeFromJson(json);

  static const toJsonFactory = _$UserLifeToJson;
  Map<String, dynamic> toJson() => _$UserLifeToJson(this);

  @JsonKey(name: 'current')
  final int? current;
  @JsonKey(name: 'maximum')
  final int? maximum;
  static const fromJsonFactory = _$UserLifeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserLife &&
            (identical(other.current, current) || const DeepCollectionEquality().equals(other.current, current)) &&
            (identical(other.maximum, maximum) || const DeepCollectionEquality().equals(other.maximum, maximum)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(current) ^
      const DeepCollectionEquality().hash(maximum) ^
      runtimeType.hashCode;
}

extension $UserLifeExtension on UserLife {
  UserLife copyWith({int? current, int? maximum}) {
    return UserLife(current: current ?? this.current, maximum: maximum ?? this.maximum);
  }

  UserLife copyWithWrapped({Wrapped<int?>? current, Wrapped<int?>? maximum}) {
    return UserLife(
        current: (current != null ? current.value : this.current),
        maximum: (maximum != null ? maximum.value : this.maximum));
  }
}

@JsonSerializable(explicitToJson: true)
class UserStatus {
  const UserStatus({
    this.description,
    this.details,
    this.state,
    this.until,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) => _$UserStatusFromJson(json);

  static const toJsonFactory = _$UserStatusToJson;
  Map<String, dynamic> toJson() => _$UserStatusToJson(this);

  @JsonKey(name: 'description')
  final String? description;
  @JsonKey(name: 'details')
  final String? details;
  @JsonKey(name: 'state')
  final String? state;
  @JsonKey(name: 'until')
  final int? until;
  static const fromJsonFactory = _$UserStatusFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserStatus &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(other.description, description)) &&
            (identical(other.details, details) || const DeepCollectionEquality().equals(other.details, details)) &&
            (identical(other.state, state) || const DeepCollectionEquality().equals(other.state, state)) &&
            (identical(other.until, until) || const DeepCollectionEquality().equals(other.until, until)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(description) ^
      const DeepCollectionEquality().hash(details) ^
      const DeepCollectionEquality().hash(state) ^
      const DeepCollectionEquality().hash(until) ^
      runtimeType.hashCode;
}

extension $UserStatusExtension on UserStatus {
  UserStatus copyWith({String? description, String? details, String? state, int? until}) {
    return UserStatus(
        description: description ?? this.description,
        details: details ?? this.details,
        state: state ?? this.state,
        until: until ?? this.until);
  }

  UserStatus copyWithWrapped(
      {Wrapped<String?>? description, Wrapped<String?>? details, Wrapped<String?>? state, Wrapped<int?>? until}) {
    return UserStatus(
        description: (description != null ? description.value : this.description),
        details: (details != null ? details.value : this.details),
        state: (state != null ? state.value : this.state),
        until: (until != null ? until.value : this.until));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionMembersResponse {
  const FactionMembersResponse({
    this.members,
  });

  factory FactionMembersResponse.fromJson(Map<String, dynamic> json) => _$FactionMembersResponseFromJson(json);

  static const toJsonFactory = _$FactionMembersResponseToJson;
  Map<String, dynamic> toJson() => _$FactionMembersResponseToJson(this);

  @JsonKey(name: 'members', defaultValue: <FactionMember>[])
  final List<FactionMember>? members;
  static const fromJsonFactory = _$FactionMembersResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionMembersResponse &&
            (identical(other.members, members) || const DeepCollectionEquality().equals(other.members, members)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(members) ^ runtimeType.hashCode;
}

extension $FactionMembersResponseExtension on FactionMembersResponse {
  FactionMembersResponse copyWith({List<FactionMember>? members}) {
    return FactionMembersResponse(members: members ?? this.members);
  }

  FactionMembersResponse copyWithWrapped({Wrapped<List<FactionMember>?>? members}) {
    return FactionMembersResponse(members: (members != null ? members.value : this.members));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionRank {
  const FactionRank({
    this.level,
    this.name,
    this.division,
    this.position,
    this.wins,
  });

  factory FactionRank.fromJson(Map<String, dynamic> json) => _$FactionRankFromJson(json);

  static const toJsonFactory = _$FactionRankToJson;
  Map<String, dynamic> toJson() => _$FactionRankToJson(this);

  @JsonKey(name: 'level')
  final int? level;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'division')
  final int? division;
  @JsonKey(name: 'position')
  final int? position;
  @JsonKey(name: 'wins')
  final int? wins;
  static const fromJsonFactory = _$FactionRankFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionRank &&
            (identical(other.level, level) || const DeepCollectionEquality().equals(other.level, level)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.division, division) || const DeepCollectionEquality().equals(other.division, division)) &&
            (identical(other.position, position) || const DeepCollectionEquality().equals(other.position, position)) &&
            (identical(other.wins, wins) || const DeepCollectionEquality().equals(other.wins, wins)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(level) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(division) ^
      const DeepCollectionEquality().hash(position) ^
      const DeepCollectionEquality().hash(wins) ^
      runtimeType.hashCode;
}

extension $FactionRankExtension on FactionRank {
  FactionRank copyWith({int? level, String? name, int? division, int? position, int? wins}) {
    return FactionRank(
        level: level ?? this.level,
        name: name ?? this.name,
        division: division ?? this.division,
        position: position ?? this.position,
        wins: wins ?? this.wins);
  }

  FactionRank copyWithWrapped(
      {Wrapped<int?>? level,
      Wrapped<String?>? name,
      Wrapped<int?>? division,
      Wrapped<int?>? position,
      Wrapped<int?>? wins}) {
    return FactionRank(
        level: (level != null ? level.value : this.level),
        name: (name != null ? name.value : this.name),
        division: (division != null ? division.value : this.division),
        position: (position != null ? position.value : this.position),
        wins: (wins != null ? wins.value : this.wins));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionBasic {
  const FactionBasic({
    this.id,
    this.name,
    this.tag,
    this.tagImage,
    this.leaderId,
    this.coLeaderId,
    this.respect,
    this.daysOld,
    this.capacity,
    this.members,
    this.isEnlisted,
    this.rank,
    this.bestChain,
  });

  factory FactionBasic.fromJson(Map<String, dynamic> json) => _$FactionBasicFromJson(json);

  static const toJsonFactory = _$FactionBasicToJson;
  Map<String, dynamic> toJson() => _$FactionBasicToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'tag')
  final String? tag;
  @JsonKey(name: 'tag_image')
  final String? tagImage;
  @JsonKey(name: 'leader_id')
  final int? leaderId;
  @JsonKey(name: 'co-leader_id')
  final int? coLeaderId;
  @JsonKey(name: 'respect')
  final int? respect;
  @JsonKey(name: 'days_old')
  final int? daysOld;
  @JsonKey(name: 'capacity')
  final int? capacity;
  @JsonKey(name: 'members')
  final int? members;
  @JsonKey(name: 'is_enlisted')
  final bool? isEnlisted;
  @JsonKey(name: 'rank')
  final FactionRank? rank;
  @JsonKey(name: 'best_chain')
  final int? bestChain;
  static const fromJsonFactory = _$FactionBasicFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionBasic &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.tag, tag) || const DeepCollectionEquality().equals(other.tag, tag)) &&
            (identical(other.tagImage, tagImage) || const DeepCollectionEquality().equals(other.tagImage, tagImage)) &&
            (identical(other.leaderId, leaderId) || const DeepCollectionEquality().equals(other.leaderId, leaderId)) &&
            (identical(other.coLeaderId, coLeaderId) ||
                const DeepCollectionEquality().equals(other.coLeaderId, coLeaderId)) &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)) &&
            (identical(other.daysOld, daysOld) || const DeepCollectionEquality().equals(other.daysOld, daysOld)) &&
            (identical(other.capacity, capacity) || const DeepCollectionEquality().equals(other.capacity, capacity)) &&
            (identical(other.members, members) || const DeepCollectionEquality().equals(other.members, members)) &&
            (identical(other.isEnlisted, isEnlisted) ||
                const DeepCollectionEquality().equals(other.isEnlisted, isEnlisted)) &&
            (identical(other.rank, rank) || const DeepCollectionEquality().equals(other.rank, rank)) &&
            (identical(other.bestChain, bestChain) ||
                const DeepCollectionEquality().equals(other.bestChain, bestChain)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(tag) ^
      const DeepCollectionEquality().hash(tagImage) ^
      const DeepCollectionEquality().hash(leaderId) ^
      const DeepCollectionEquality().hash(coLeaderId) ^
      const DeepCollectionEquality().hash(respect) ^
      const DeepCollectionEquality().hash(daysOld) ^
      const DeepCollectionEquality().hash(capacity) ^
      const DeepCollectionEquality().hash(members) ^
      const DeepCollectionEquality().hash(isEnlisted) ^
      const DeepCollectionEquality().hash(rank) ^
      const DeepCollectionEquality().hash(bestChain) ^
      runtimeType.hashCode;
}

extension $FactionBasicExtension on FactionBasic {
  FactionBasic copyWith(
      {int? id,
      String? name,
      String? tag,
      String? tagImage,
      int? leaderId,
      int? coLeaderId,
      int? respect,
      int? daysOld,
      int? capacity,
      int? members,
      bool? isEnlisted,
      FactionRank? rank,
      int? bestChain}) {
    return FactionBasic(
        id: id ?? this.id,
        name: name ?? this.name,
        tag: tag ?? this.tag,
        tagImage: tagImage ?? this.tagImage,
        leaderId: leaderId ?? this.leaderId,
        coLeaderId: coLeaderId ?? this.coLeaderId,
        respect: respect ?? this.respect,
        daysOld: daysOld ?? this.daysOld,
        capacity: capacity ?? this.capacity,
        members: members ?? this.members,
        isEnlisted: isEnlisted ?? this.isEnlisted,
        rank: rank ?? this.rank,
        bestChain: bestChain ?? this.bestChain);
  }

  FactionBasic copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<String?>? tag,
      Wrapped<String?>? tagImage,
      Wrapped<int?>? leaderId,
      Wrapped<int?>? coLeaderId,
      Wrapped<int?>? respect,
      Wrapped<int?>? daysOld,
      Wrapped<int?>? capacity,
      Wrapped<int?>? members,
      Wrapped<bool?>? isEnlisted,
      Wrapped<FactionRank?>? rank,
      Wrapped<int?>? bestChain}) {
    return FactionBasic(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        tag: (tag != null ? tag.value : this.tag),
        tagImage: (tagImage != null ? tagImage.value : this.tagImage),
        leaderId: (leaderId != null ? leaderId.value : this.leaderId),
        coLeaderId: (coLeaderId != null ? coLeaderId.value : this.coLeaderId),
        respect: (respect != null ? respect.value : this.respect),
        daysOld: (daysOld != null ? daysOld.value : this.daysOld),
        capacity: (capacity != null ? capacity.value : this.capacity),
        members: (members != null ? members.value : this.members),
        isEnlisted: (isEnlisted != null ? isEnlisted.value : this.isEnlisted),
        rank: (rank != null ? rank.value : this.rank),
        bestChain: (bestChain != null ? bestChain.value : this.bestChain));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionBasicResponse {
  const FactionBasicResponse({
    this.basic,
  });

  factory FactionBasicResponse.fromJson(Map<String, dynamic> json) => _$FactionBasicResponseFromJson(json);

  static const toJsonFactory = _$FactionBasicResponseToJson;
  Map<String, dynamic> toJson() => _$FactionBasicResponseToJson(this);

  @JsonKey(name: 'basic')
  final FactionBasic? basic;
  static const fromJsonFactory = _$FactionBasicResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionBasicResponse &&
            (identical(other.basic, basic) || const DeepCollectionEquality().equals(other.basic, basic)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(basic) ^ runtimeType.hashCode;
}

extension $FactionBasicResponseExtension on FactionBasicResponse {
  FactionBasicResponse copyWith({FactionBasic? basic}) {
    return FactionBasicResponse(basic: basic ?? this.basic);
  }

  FactionBasicResponse copyWithWrapped({Wrapped<FactionBasic?>? basic}) {
    return FactionBasicResponse(basic: (basic != null ? basic.value : this.basic));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionPact {
  const FactionPact({
    this.factionId,
    this.factionName,
    this.until,
  });

  factory FactionPact.fromJson(Map<String, dynamic> json) => _$FactionPactFromJson(json);

  static const toJsonFactory = _$FactionPactToJson;
  Map<String, dynamic> toJson() => _$FactionPactToJson(this);

  @JsonKey(name: 'faction_id')
  final int? factionId;
  @JsonKey(name: 'faction_name')
  final String? factionName;
  @JsonKey(name: 'until')
  final String? until;
  static const fromJsonFactory = _$FactionPactFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionPact &&
            (identical(other.factionId, factionId) ||
                const DeepCollectionEquality().equals(other.factionId, factionId)) &&
            (identical(other.factionName, factionName) ||
                const DeepCollectionEquality().equals(other.factionName, factionName)) &&
            (identical(other.until, until) || const DeepCollectionEquality().equals(other.until, until)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(factionId) ^
      const DeepCollectionEquality().hash(factionName) ^
      const DeepCollectionEquality().hash(until) ^
      runtimeType.hashCode;
}

extension $FactionPactExtension on FactionPact {
  FactionPact copyWith({int? factionId, String? factionName, String? until}) {
    return FactionPact(
        factionId: factionId ?? this.factionId,
        factionName: factionName ?? this.factionName,
        until: until ?? this.until);
  }

  FactionPact copyWithWrapped({Wrapped<int?>? factionId, Wrapped<String?>? factionName, Wrapped<String?>? until}) {
    return FactionPact(
        factionId: (factionId != null ? factionId.value : this.factionId),
        factionName: (factionName != null ? factionName.value : this.factionName),
        until: (until != null ? until.value : this.until));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionRankedWarParticipant {
  const FactionRankedWarParticipant({
    this.id,
    this.name,
    this.score,
    this.chain,
  });

  factory FactionRankedWarParticipant.fromJson(Map<String, dynamic> json) =>
      _$FactionRankedWarParticipantFromJson(json);

  static const toJsonFactory = _$FactionRankedWarParticipantToJson;
  Map<String, dynamic> toJson() => _$FactionRankedWarParticipantToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'score')
  final int? score;
  @JsonKey(name: 'chain')
  final int? chain;
  static const fromJsonFactory = _$FactionRankedWarParticipantFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionRankedWarParticipant &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.score, score) || const DeepCollectionEquality().equals(other.score, score)) &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(score) ^
      const DeepCollectionEquality().hash(chain) ^
      runtimeType.hashCode;
}

extension $FactionRankedWarParticipantExtension on FactionRankedWarParticipant {
  FactionRankedWarParticipant copyWith({int? id, String? name, int? score, int? chain}) {
    return FactionRankedWarParticipant(
        id: id ?? this.id, name: name ?? this.name, score: score ?? this.score, chain: chain ?? this.chain);
  }

  FactionRankedWarParticipant copyWithWrapped(
      {Wrapped<int?>? id, Wrapped<String?>? name, Wrapped<int?>? score, Wrapped<int?>? chain}) {
    return FactionRankedWarParticipant(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        score: (score != null ? score.value : this.score),
        chain: (chain != null ? chain.value : this.chain));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionRankedWar {
  const FactionRankedWar({
    this.warId,
    this.start,
    this.end,
    this.target,
    this.winner,
    this.factions,
  });

  factory FactionRankedWar.fromJson(Map<String, dynamic> json) => _$FactionRankedWarFromJson(json);

  static const toJsonFactory = _$FactionRankedWarToJson;
  Map<String, dynamic> toJson() => _$FactionRankedWarToJson(this);

  @JsonKey(name: 'war_id')
  final int? warId;
  @JsonKey(name: 'start')
  final int? start;
  @JsonKey(name: 'end')
  final int? end;
  @JsonKey(name: 'target')
  final int? target;
  @JsonKey(name: 'winner')
  final int? winner;
  @JsonKey(name: 'factions', defaultValue: <FactionRankedWarParticipant>[])
  final List<FactionRankedWarParticipant>? factions;
  static const fromJsonFactory = _$FactionRankedWarFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionRankedWar &&
            (identical(other.warId, warId) || const DeepCollectionEquality().equals(other.warId, warId)) &&
            (identical(other.start, start) || const DeepCollectionEquality().equals(other.start, start)) &&
            (identical(other.end, end) || const DeepCollectionEquality().equals(other.end, end)) &&
            (identical(other.target, target) || const DeepCollectionEquality().equals(other.target, target)) &&
            (identical(other.winner, winner) || const DeepCollectionEquality().equals(other.winner, winner)) &&
            (identical(other.factions, factions) || const DeepCollectionEquality().equals(other.factions, factions)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(warId) ^
      const DeepCollectionEquality().hash(start) ^
      const DeepCollectionEquality().hash(end) ^
      const DeepCollectionEquality().hash(target) ^
      const DeepCollectionEquality().hash(winner) ^
      const DeepCollectionEquality().hash(factions) ^
      runtimeType.hashCode;
}

extension $FactionRankedWarExtension on FactionRankedWar {
  FactionRankedWar copyWith(
      {int? warId, int? start, int? end, int? target, int? winner, List<FactionRankedWarParticipant>? factions}) {
    return FactionRankedWar(
        warId: warId ?? this.warId,
        start: start ?? this.start,
        end: end ?? this.end,
        target: target ?? this.target,
        winner: winner ?? this.winner,
        factions: factions ?? this.factions);
  }

  FactionRankedWar copyWithWrapped(
      {Wrapped<int?>? warId,
      Wrapped<int?>? start,
      Wrapped<int?>? end,
      Wrapped<int?>? target,
      Wrapped<int?>? winner,
      Wrapped<List<FactionRankedWarParticipant>?>? factions}) {
    return FactionRankedWar(
        warId: (warId != null ? warId.value : this.warId),
        start: (start != null ? start.value : this.start),
        end: (end != null ? end.value : this.end),
        target: (target != null ? target.value : this.target),
        winner: (winner != null ? winner.value : this.winner),
        factions: (factions != null ? factions.value : this.factions));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionRaidWarParticipant {
  const FactionRaidWarParticipant({
    this.id,
    this.name,
    this.score,
    this.chain,
    this.isAggressor,
  });

  factory FactionRaidWarParticipant.fromJson(Map<String, dynamic> json) => _$FactionRaidWarParticipantFromJson(json);

  static const toJsonFactory = _$FactionRaidWarParticipantToJson;
  Map<String, dynamic> toJson() => _$FactionRaidWarParticipantToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'score')
  final int? score;
  @JsonKey(name: 'chain')
  final int? chain;
  @JsonKey(name: 'is_aggressor')
  final bool? isAggressor;
  static const fromJsonFactory = _$FactionRaidWarParticipantFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionRaidWarParticipant &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.score, score) || const DeepCollectionEquality().equals(other.score, score)) &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)) &&
            (identical(other.isAggressor, isAggressor) ||
                const DeepCollectionEquality().equals(other.isAggressor, isAggressor)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(score) ^
      const DeepCollectionEquality().hash(chain) ^
      const DeepCollectionEquality().hash(isAggressor) ^
      runtimeType.hashCode;
}

extension $FactionRaidWarParticipantExtension on FactionRaidWarParticipant {
  FactionRaidWarParticipant copyWith({int? id, String? name, int? score, int? chain, bool? isAggressor}) {
    return FactionRaidWarParticipant(
        id: id ?? this.id,
        name: name ?? this.name,
        score: score ?? this.score,
        chain: chain ?? this.chain,
        isAggressor: isAggressor ?? this.isAggressor);
  }

  FactionRaidWarParticipant copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<int?>? score,
      Wrapped<int?>? chain,
      Wrapped<bool?>? isAggressor}) {
    return FactionRaidWarParticipant(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        score: (score != null ? score.value : this.score),
        chain: (chain != null ? chain.value : this.chain),
        isAggressor: (isAggressor != null ? isAggressor.value : this.isAggressor));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionRaidWar {
  const FactionRaidWar({
    this.warId,
    this.start,
    this.end,
    this.factions,
  });

  factory FactionRaidWar.fromJson(Map<String, dynamic> json) => _$FactionRaidWarFromJson(json);

  static const toJsonFactory = _$FactionRaidWarToJson;
  Map<String, dynamic> toJson() => _$FactionRaidWarToJson(this);

  @JsonKey(name: 'war_id')
  final int? warId;
  @JsonKey(name: 'start')
  final int? start;
  @JsonKey(name: 'end')
  final int? end;
  @JsonKey(name: 'factions', defaultValue: <FactionRaidWarParticipant>[])
  final List<FactionRaidWarParticipant>? factions;
  static const fromJsonFactory = _$FactionRaidWarFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionRaidWar &&
            (identical(other.warId, warId) || const DeepCollectionEquality().equals(other.warId, warId)) &&
            (identical(other.start, start) || const DeepCollectionEquality().equals(other.start, start)) &&
            (identical(other.end, end) || const DeepCollectionEquality().equals(other.end, end)) &&
            (identical(other.factions, factions) || const DeepCollectionEquality().equals(other.factions, factions)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(warId) ^
      const DeepCollectionEquality().hash(start) ^
      const DeepCollectionEquality().hash(end) ^
      const DeepCollectionEquality().hash(factions) ^
      runtimeType.hashCode;
}

extension $FactionRaidWarExtension on FactionRaidWar {
  FactionRaidWar copyWith({int? warId, int? start, int? end, List<FactionRaidWarParticipant>? factions}) {
    return FactionRaidWar(
        warId: warId ?? this.warId,
        start: start ?? this.start,
        end: end ?? this.end,
        factions: factions ?? this.factions);
  }

  FactionRaidWar copyWithWrapped(
      {Wrapped<int?>? warId,
      Wrapped<int?>? start,
      Wrapped<int?>? end,
      Wrapped<List<FactionRaidWarParticipant>?>? factions}) {
    return FactionRaidWar(
        warId: (warId != null ? warId.value : this.warId),
        start: (start != null ? start.value : this.start),
        end: (end != null ? end.value : this.end),
        factions: (factions != null ? factions.value : this.factions));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionTerritoryWarParticipant {
  const FactionTerritoryWarParticipant({
    this.id,
    this.name,
    this.score,
    this.chain,
    this.isAggressor,
    this.playerIds,
  });

  factory FactionTerritoryWarParticipant.fromJson(Map<String, dynamic> json) =>
      _$FactionTerritoryWarParticipantFromJson(json);

  static const toJsonFactory = _$FactionTerritoryWarParticipantToJson;
  Map<String, dynamic> toJson() => _$FactionTerritoryWarParticipantToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'score')
  final int? score;
  @JsonKey(name: 'chain')
  final int? chain;
  @JsonKey(name: 'is_aggressor')
  final bool? isAggressor;
  @JsonKey(name: 'playerIds', defaultValue: <int>[])
  final List<int>? playerIds;
  static const fromJsonFactory = _$FactionTerritoryWarParticipantFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionTerritoryWarParticipant &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.score, score) || const DeepCollectionEquality().equals(other.score, score)) &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)) &&
            (identical(other.isAggressor, isAggressor) ||
                const DeepCollectionEquality().equals(other.isAggressor, isAggressor)) &&
            (identical(other.playerIds, playerIds) ||
                const DeepCollectionEquality().equals(other.playerIds, playerIds)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(score) ^
      const DeepCollectionEquality().hash(chain) ^
      const DeepCollectionEquality().hash(isAggressor) ^
      const DeepCollectionEquality().hash(playerIds) ^
      runtimeType.hashCode;
}

extension $FactionTerritoryWarParticipantExtension on FactionTerritoryWarParticipant {
  FactionTerritoryWarParticipant copyWith(
      {int? id, String? name, int? score, int? chain, bool? isAggressor, List<int>? playerIds}) {
    return FactionTerritoryWarParticipant(
        id: id ?? this.id,
        name: name ?? this.name,
        score: score ?? this.score,
        chain: chain ?? this.chain,
        isAggressor: isAggressor ?? this.isAggressor,
        playerIds: playerIds ?? this.playerIds);
  }

  FactionTerritoryWarParticipant copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<int?>? score,
      Wrapped<int?>? chain,
      Wrapped<bool?>? isAggressor,
      Wrapped<List<int>?>? playerIds}) {
    return FactionTerritoryWarParticipant(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        score: (score != null ? score.value : this.score),
        chain: (chain != null ? chain.value : this.chain),
        isAggressor: (isAggressor != null ? isAggressor.value : this.isAggressor),
        playerIds: (playerIds != null ? playerIds.value : this.playerIds));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionTerritoryWar {
  const FactionTerritoryWar({
    this.warId,
    this.territory,
    this.start,
    this.end,
    this.target,
    this.winner,
    this.factions,
  });

  factory FactionTerritoryWar.fromJson(Map<String, dynamic> json) => _$FactionTerritoryWarFromJson(json);

  static const toJsonFactory = _$FactionTerritoryWarToJson;
  Map<String, dynamic> toJson() => _$FactionTerritoryWarToJson(this);

  @JsonKey(name: 'war_id')
  final int? warId;
  @JsonKey(name: 'territory')
  final String? territory;
  @JsonKey(name: 'start')
  final int? start;
  @JsonKey(name: 'end')
  final int? end;
  @JsonKey(name: 'target')
  final int? target;
  @JsonKey(name: 'winner')
  final int? winner;
  @JsonKey(name: 'factions', defaultValue: <FactionTerritoryWarParticipant>[])
  final List<FactionTerritoryWarParticipant>? factions;
  static const fromJsonFactory = _$FactionTerritoryWarFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionTerritoryWar &&
            (identical(other.warId, warId) || const DeepCollectionEquality().equals(other.warId, warId)) &&
            (identical(other.territory, territory) ||
                const DeepCollectionEquality().equals(other.territory, territory)) &&
            (identical(other.start, start) || const DeepCollectionEquality().equals(other.start, start)) &&
            (identical(other.end, end) || const DeepCollectionEquality().equals(other.end, end)) &&
            (identical(other.target, target) || const DeepCollectionEquality().equals(other.target, target)) &&
            (identical(other.winner, winner) || const DeepCollectionEquality().equals(other.winner, winner)) &&
            (identical(other.factions, factions) || const DeepCollectionEquality().equals(other.factions, factions)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(warId) ^
      const DeepCollectionEquality().hash(territory) ^
      const DeepCollectionEquality().hash(start) ^
      const DeepCollectionEquality().hash(end) ^
      const DeepCollectionEquality().hash(target) ^
      const DeepCollectionEquality().hash(winner) ^
      const DeepCollectionEquality().hash(factions) ^
      runtimeType.hashCode;
}

extension $FactionTerritoryWarExtension on FactionTerritoryWar {
  FactionTerritoryWar copyWith(
      {int? warId,
      String? territory,
      int? start,
      int? end,
      int? target,
      int? winner,
      List<FactionTerritoryWarParticipant>? factions}) {
    return FactionTerritoryWar(
        warId: warId ?? this.warId,
        territory: territory ?? this.territory,
        start: start ?? this.start,
        end: end ?? this.end,
        target: target ?? this.target,
        winner: winner ?? this.winner,
        factions: factions ?? this.factions);
  }

  FactionTerritoryWar copyWithWrapped(
      {Wrapped<int?>? warId,
      Wrapped<String?>? territory,
      Wrapped<int?>? start,
      Wrapped<int?>? end,
      Wrapped<int?>? target,
      Wrapped<int?>? winner,
      Wrapped<List<FactionTerritoryWarParticipant>?>? factions}) {
    return FactionTerritoryWar(
        warId: (warId != null ? warId.value : this.warId),
        territory: (territory != null ? territory.value : this.territory),
        start: (start != null ? start.value : this.start),
        end: (end != null ? end.value : this.end),
        target: (target != null ? target.value : this.target),
        winner: (winner != null ? winner.value : this.winner),
        factions: (factions != null ? factions.value : this.factions));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionWars {
  const FactionWars({
    this.ranked,
    this.raids,
    this.territory,
  });

  factory FactionWars.fromJson(Map<String, dynamic> json) => _$FactionWarsFromJson(json);

  static const toJsonFactory = _$FactionWarsToJson;
  Map<String, dynamic> toJson() => _$FactionWarsToJson(this);

  @JsonKey(name: 'ranked')
  final FactionRankedWar? ranked;
  @JsonKey(name: 'raids', defaultValue: <FactionRaidWar>[])
  final List<FactionRaidWar>? raids;
  @JsonKey(name: 'territory', defaultValue: <FactionTerritoryWar>[])
  final List<FactionTerritoryWar>? territory;
  static const fromJsonFactory = _$FactionWarsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionWars &&
            (identical(other.ranked, ranked) || const DeepCollectionEquality().equals(other.ranked, ranked)) &&
            (identical(other.raids, raids) || const DeepCollectionEquality().equals(other.raids, raids)) &&
            (identical(other.territory, territory) ||
                const DeepCollectionEquality().equals(other.territory, territory)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(ranked) ^
      const DeepCollectionEquality().hash(raids) ^
      const DeepCollectionEquality().hash(territory) ^
      runtimeType.hashCode;
}

extension $FactionWarsExtension on FactionWars {
  FactionWars copyWith({FactionRankedWar? ranked, List<FactionRaidWar>? raids, List<FactionTerritoryWar>? territory}) {
    return FactionWars(
        ranked: ranked ?? this.ranked, raids: raids ?? this.raids, territory: territory ?? this.territory);
  }

  FactionWars copyWithWrapped(
      {Wrapped<FactionRankedWar?>? ranked,
      Wrapped<List<FactionRaidWar>?>? raids,
      Wrapped<List<FactionTerritoryWar>?>? territory}) {
    return FactionWars(
        ranked: (ranked != null ? ranked.value : this.ranked),
        raids: (raids != null ? raids.value : this.raids),
        territory: (territory != null ? territory.value : this.territory));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionWarsResponse {
  const FactionWarsResponse({
    this.pacts,
    this.wars,
  });

  factory FactionWarsResponse.fromJson(Map<String, dynamic> json) => _$FactionWarsResponseFromJson(json);

  static const toJsonFactory = _$FactionWarsResponseToJson;
  Map<String, dynamic> toJson() => _$FactionWarsResponseToJson(this);

  @JsonKey(name: 'pacts', defaultValue: <FactionPact>[])
  final List<FactionPact>? pacts;
  @JsonKey(name: 'wars')
  final FactionWars? wars;
  static const fromJsonFactory = _$FactionWarsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionWarsResponse &&
            (identical(other.pacts, pacts) || const DeepCollectionEquality().equals(other.pacts, pacts)) &&
            (identical(other.wars, wars) || const DeepCollectionEquality().equals(other.wars, wars)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(pacts) ^ const DeepCollectionEquality().hash(wars) ^ runtimeType.hashCode;
}

extension $FactionWarsResponseExtension on FactionWarsResponse {
  FactionWarsResponse copyWith({List<FactionPact>? pacts, FactionWars? wars}) {
    return FactionWarsResponse(pacts: pacts ?? this.pacts, wars: wars ?? this.wars);
  }

  FactionWarsResponse copyWithWrapped({Wrapped<List<FactionPact>?>? pacts, Wrapped<FactionWars?>? wars}) {
    return FactionWarsResponse(
        pacts: (pacts != null ? pacts.value : this.pacts), wars: (wars != null ? wars.value : this.wars));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionNews {
  const FactionNews({
    this.id,
    this.text,
    this.timestamp,
  });

  factory FactionNews.fromJson(Map<String, dynamic> json) => _$FactionNewsFromJson(json);

  static const toJsonFactory = _$FactionNewsToJson;
  Map<String, dynamic> toJson() => _$FactionNewsToJson(this);

  @JsonKey(name: 'id')
  final String? id;
  @JsonKey(name: 'text')
  final String? text;
  @JsonKey(name: 'timestamp')
  final int? timestamp;
  static const fromJsonFactory = _$FactionNewsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionNews &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.text, text) || const DeepCollectionEquality().equals(other.text, text)) &&
            (identical(other.timestamp, timestamp) ||
                const DeepCollectionEquality().equals(other.timestamp, timestamp)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(text) ^
      const DeepCollectionEquality().hash(timestamp) ^
      runtimeType.hashCode;
}

extension $FactionNewsExtension on FactionNews {
  FactionNews copyWith({String? id, String? text, int? timestamp}) {
    return FactionNews(id: id ?? this.id, text: text ?? this.text, timestamp: timestamp ?? this.timestamp);
  }

  FactionNews copyWithWrapped({Wrapped<String?>? id, Wrapped<String?>? text, Wrapped<int?>? timestamp}) {
    return FactionNews(
        id: (id != null ? id.value : this.id),
        text: (text != null ? text.value : this.text),
        timestamp: (timestamp != null ? timestamp.value : this.timestamp));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionNewsResponse {
  const FactionNewsResponse({
    this.news,
    this.metadata,
  });

  factory FactionNewsResponse.fromJson(Map<String, dynamic> json) => _$FactionNewsResponseFromJson(json);

  static const toJsonFactory = _$FactionNewsResponseToJson;
  Map<String, dynamic> toJson() => _$FactionNewsResponseToJson(this);

  @JsonKey(name: 'news', defaultValue: <FactionNews>[])
  final List<FactionNews>? news;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$FactionNewsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionNewsResponse &&
            (identical(other.news, news) || const DeepCollectionEquality().equals(other.news, news)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(news) ^ const DeepCollectionEquality().hash(metadata) ^ runtimeType.hashCode;
}

extension $FactionNewsResponseExtension on FactionNewsResponse {
  FactionNewsResponse copyWith({List<FactionNews>? news, RequestMetadataWithLinks? metadata}) {
    return FactionNewsResponse(news: news ?? this.news, metadata: metadata ?? this.metadata);
  }

  FactionNewsResponse copyWithWrapped(
      {Wrapped<List<FactionNews>?>? news, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return FactionNewsResponse(
        news: (news != null ? news.value : this.news), metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionAttacksResponse {
  const FactionAttacksResponse({
    this.attacks,
    this.metadata,
  });

  factory FactionAttacksResponse.fromJson(Map<String, dynamic> json) => _$FactionAttacksResponseFromJson(json);

  static const toJsonFactory = _$FactionAttacksResponseToJson;
  Map<String, dynamic> toJson() => _$FactionAttacksResponseToJson(this);

  @JsonKey(name: 'attacks', defaultValue: <Attack>[])
  final List<Attack>? attacks;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$FactionAttacksResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionAttacksResponse &&
            (identical(other.attacks, attacks) || const DeepCollectionEquality().equals(other.attacks, attacks)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(attacks) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $FactionAttacksResponseExtension on FactionAttacksResponse {
  FactionAttacksResponse copyWith({List<Attack>? attacks, RequestMetadataWithLinks? metadata}) {
    return FactionAttacksResponse(attacks: attacks ?? this.attacks, metadata: metadata ?? this.metadata);
  }

  FactionAttacksResponse copyWithWrapped(
      {Wrapped<List<Attack>?>? attacks, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return FactionAttacksResponse(
        attacks: (attacks != null ? attacks.value : this.attacks),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionAttacksFullResponse {
  const FactionAttacksFullResponse({
    this.attacks,
    this.metadata,
  });

  factory FactionAttacksFullResponse.fromJson(Map<String, dynamic> json) => _$FactionAttacksFullResponseFromJson(json);

  static const toJsonFactory = _$FactionAttacksFullResponseToJson;
  Map<String, dynamic> toJson() => _$FactionAttacksFullResponseToJson(this);

  @JsonKey(name: 'attacks', defaultValue: <AttackSimplified>[])
  final List<AttackSimplified>? attacks;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$FactionAttacksFullResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionAttacksFullResponse &&
            (identical(other.attacks, attacks) || const DeepCollectionEquality().equals(other.attacks, attacks)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(attacks) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $FactionAttacksFullResponseExtension on FactionAttacksFullResponse {
  FactionAttacksFullResponse copyWith({List<AttackSimplified>? attacks, RequestMetadataWithLinks? metadata}) {
    return FactionAttacksFullResponse(attacks: attacks ?? this.attacks, metadata: metadata ?? this.metadata);
  }

  FactionAttacksFullResponse copyWithWrapped(
      {Wrapped<List<AttackSimplified>?>? attacks, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return FactionAttacksFullResponse(
        attacks: (attacks != null ? attacks.value : this.attacks),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionApplication {
  const FactionApplication({
    this.id,
    this.user,
    this.message,
    this.validUntil,
    this.status,
  });

  factory FactionApplication.fromJson(Map<String, dynamic> json) => _$FactionApplicationFromJson(json);

  static const toJsonFactory = _$FactionApplicationToJson;
  Map<String, dynamic> toJson() => _$FactionApplicationToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'user')
  final FactionApplication$User? user;
  @JsonKey(name: 'message')
  final String? message;
  @JsonKey(name: 'valid_until')
  final int? validUntil;
  @JsonKey(
    name: 'status',
    toJson: factionApplicationStatusEnumNullableToJson,
    fromJson: factionApplicationStatusEnumNullableFromJson,
  )
  final enums.FactionApplicationStatusEnum? status;
  static const fromJsonFactory = _$FactionApplicationFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionApplication &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.user, user) || const DeepCollectionEquality().equals(other.user, user)) &&
            (identical(other.message, message) || const DeepCollectionEquality().equals(other.message, message)) &&
            (identical(other.validUntil, validUntil) ||
                const DeepCollectionEquality().equals(other.validUntil, validUntil)) &&
            (identical(other.status, status) || const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(user) ^
      const DeepCollectionEquality().hash(message) ^
      const DeepCollectionEquality().hash(validUntil) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $FactionApplicationExtension on FactionApplication {
  FactionApplication copyWith(
      {int? id,
      FactionApplication$User? user,
      String? message,
      int? validUntil,
      enums.FactionApplicationStatusEnum? status}) {
    return FactionApplication(
        id: id ?? this.id,
        user: user ?? this.user,
        message: message ?? this.message,
        validUntil: validUntil ?? this.validUntil,
        status: status ?? this.status);
  }

  FactionApplication copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<FactionApplication$User?>? user,
      Wrapped<String?>? message,
      Wrapped<int?>? validUntil,
      Wrapped<enums.FactionApplicationStatusEnum?>? status}) {
    return FactionApplication(
        id: (id != null ? id.value : this.id),
        user: (user != null ? user.value : this.user),
        message: (message != null ? message.value : this.message),
        validUntil: (validUntil != null ? validUntil.value : this.validUntil),
        status: (status != null ? status.value : this.status));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionApplicationsResponse {
  const FactionApplicationsResponse({
    this.applications,
  });

  factory FactionApplicationsResponse.fromJson(Map<String, dynamic> json) =>
      _$FactionApplicationsResponseFromJson(json);

  static const toJsonFactory = _$FactionApplicationsResponseToJson;
  Map<String, dynamic> toJson() => _$FactionApplicationsResponseToJson(this);

  @JsonKey(name: 'applications', defaultValue: <FactionApplication>[])
  final List<FactionApplication>? applications;
  static const fromJsonFactory = _$FactionApplicationsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionApplicationsResponse &&
            (identical(other.applications, applications) ||
                const DeepCollectionEquality().equals(other.applications, applications)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(applications) ^ runtimeType.hashCode;
}

extension $FactionApplicationsResponseExtension on FactionApplicationsResponse {
  FactionApplicationsResponse copyWith({List<FactionApplication>? applications}) {
    return FactionApplicationsResponse(applications: applications ?? this.applications);
  }

  FactionApplicationsResponse copyWithWrapped({Wrapped<List<FactionApplication>?>? applications}) {
    return FactionApplicationsResponse(applications: (applications != null ? applications.value : this.applications));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionOngoingChain {
  const FactionOngoingChain({
    this.id,
    this.current,
    this.max,
    this.timeout,
    this.modifier,
    this.cooldown,
    this.start,
    this.end,
  });

  factory FactionOngoingChain.fromJson(Map<String, dynamic> json) => _$FactionOngoingChainFromJson(json);

  static const toJsonFactory = _$FactionOngoingChainToJson;
  Map<String, dynamic> toJson() => _$FactionOngoingChainToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'current')
  final int? current;
  @JsonKey(name: 'max')
  final int? max;
  @JsonKey(name: 'timeout')
  final int? timeout;
  @JsonKey(name: 'modifier')
  final double? modifier;
  @JsonKey(name: 'cooldown')
  final int? cooldown;
  @JsonKey(name: 'start')
  final int? start;
  @JsonKey(name: 'end')
  final int? end;
  static const fromJsonFactory = _$FactionOngoingChainFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionOngoingChain &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.current, current) || const DeepCollectionEquality().equals(other.current, current)) &&
            (identical(other.max, max) || const DeepCollectionEquality().equals(other.max, max)) &&
            (identical(other.timeout, timeout) || const DeepCollectionEquality().equals(other.timeout, timeout)) &&
            (identical(other.modifier, modifier) || const DeepCollectionEquality().equals(other.modifier, modifier)) &&
            (identical(other.cooldown, cooldown) || const DeepCollectionEquality().equals(other.cooldown, cooldown)) &&
            (identical(other.start, start) || const DeepCollectionEquality().equals(other.start, start)) &&
            (identical(other.end, end) || const DeepCollectionEquality().equals(other.end, end)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(current) ^
      const DeepCollectionEquality().hash(max) ^
      const DeepCollectionEquality().hash(timeout) ^
      const DeepCollectionEquality().hash(modifier) ^
      const DeepCollectionEquality().hash(cooldown) ^
      const DeepCollectionEquality().hash(start) ^
      const DeepCollectionEquality().hash(end) ^
      runtimeType.hashCode;
}

extension $FactionOngoingChainExtension on FactionOngoingChain {
  FactionOngoingChain copyWith(
      {int? id, int? current, int? max, int? timeout, double? modifier, int? cooldown, int? start, int? end}) {
    return FactionOngoingChain(
        id: id ?? this.id,
        current: current ?? this.current,
        max: max ?? this.max,
        timeout: timeout ?? this.timeout,
        modifier: modifier ?? this.modifier,
        cooldown: cooldown ?? this.cooldown,
        start: start ?? this.start,
        end: end ?? this.end);
  }

  FactionOngoingChain copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<int?>? current,
      Wrapped<int?>? max,
      Wrapped<int?>? timeout,
      Wrapped<double?>? modifier,
      Wrapped<int?>? cooldown,
      Wrapped<int?>? start,
      Wrapped<int?>? end}) {
    return FactionOngoingChain(
        id: (id != null ? id.value : this.id),
        current: (current != null ? current.value : this.current),
        max: (max != null ? max.value : this.max),
        timeout: (timeout != null ? timeout.value : this.timeout),
        modifier: (modifier != null ? modifier.value : this.modifier),
        cooldown: (cooldown != null ? cooldown.value : this.cooldown),
        start: (start != null ? start.value : this.start),
        end: (end != null ? end.value : this.end));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionOngoingChainResponse {
  const FactionOngoingChainResponse({
    this.chain,
  });

  factory FactionOngoingChainResponse.fromJson(Map<String, dynamic> json) =>
      _$FactionOngoingChainResponseFromJson(json);

  static const toJsonFactory = _$FactionOngoingChainResponseToJson;
  Map<String, dynamic> toJson() => _$FactionOngoingChainResponseToJson(this);

  @JsonKey(name: 'chain')
  final FactionOngoingChain? chain;
  static const fromJsonFactory = _$FactionOngoingChainResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionOngoingChainResponse &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(chain) ^ runtimeType.hashCode;
}

extension $FactionOngoingChainResponseExtension on FactionOngoingChainResponse {
  FactionOngoingChainResponse copyWith({FactionOngoingChain? chain}) {
    return FactionOngoingChainResponse(chain: chain ?? this.chain);
  }

  FactionOngoingChainResponse copyWithWrapped({Wrapped<FactionOngoingChain?>? chain}) {
    return FactionOngoingChainResponse(chain: (chain != null ? chain.value : this.chain));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionChain {
  const FactionChain({
    this.id,
    this.chain,
    this.respect,
    this.start,
    this.end,
  });

  factory FactionChain.fromJson(Map<String, dynamic> json) => _$FactionChainFromJson(json);

  static const toJsonFactory = _$FactionChainToJson;
  Map<String, dynamic> toJson() => _$FactionChainToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'chain')
  final int? chain;
  @JsonKey(name: 'respect')
  final double? respect;
  @JsonKey(name: 'start')
  final int? start;
  @JsonKey(name: 'end')
  final int? end;
  static const fromJsonFactory = _$FactionChainFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionChain &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)) &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)) &&
            (identical(other.start, start) || const DeepCollectionEquality().equals(other.start, start)) &&
            (identical(other.end, end) || const DeepCollectionEquality().equals(other.end, end)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(chain) ^
      const DeepCollectionEquality().hash(respect) ^
      const DeepCollectionEquality().hash(start) ^
      const DeepCollectionEquality().hash(end) ^
      runtimeType.hashCode;
}

extension $FactionChainExtension on FactionChain {
  FactionChain copyWith({int? id, int? chain, double? respect, int? start, int? end}) {
    return FactionChain(
        id: id ?? this.id,
        chain: chain ?? this.chain,
        respect: respect ?? this.respect,
        start: start ?? this.start,
        end: end ?? this.end);
  }

  FactionChain copyWithWrapped(
      {Wrapped<int?>? id, Wrapped<int?>? chain, Wrapped<double?>? respect, Wrapped<int?>? start, Wrapped<int?>? end}) {
    return FactionChain(
        id: (id != null ? id.value : this.id),
        chain: (chain != null ? chain.value : this.chain),
        respect: (respect != null ? respect.value : this.respect),
        start: (start != null ? start.value : this.start),
        end: (end != null ? end.value : this.end));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionChainsResponse {
  const FactionChainsResponse({
    this.chains,
    this.metadata,
  });

  factory FactionChainsResponse.fromJson(Map<String, dynamic> json) => _$FactionChainsResponseFromJson(json);

  static const toJsonFactory = _$FactionChainsResponseToJson;
  Map<String, dynamic> toJson() => _$FactionChainsResponseToJson(this);

  @JsonKey(name: 'chains', defaultValue: <FactionChain>[])
  final List<FactionChain>? chains;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$FactionChainsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionChainsResponse &&
            (identical(other.chains, chains) || const DeepCollectionEquality().equals(other.chains, chains)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(chains) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $FactionChainsResponseExtension on FactionChainsResponse {
  FactionChainsResponse copyWith({List<FactionChain>? chains, RequestMetadataWithLinks? metadata}) {
    return FactionChainsResponse(chains: chains ?? this.chains, metadata: metadata ?? this.metadata);
  }

  FactionChainsResponse copyWithWrapped(
      {Wrapped<List<FactionChain>?>? chains, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return FactionChainsResponse(
        chains: (chains != null ? chains.value : this.chains),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionChainReportResponse {
  const FactionChainReportResponse({
    this.chainreport,
  });

  factory FactionChainReportResponse.fromJson(Map<String, dynamic> json) => _$FactionChainReportResponseFromJson(json);

  static const toJsonFactory = _$FactionChainReportResponseToJson;
  Map<String, dynamic> toJson() => _$FactionChainReportResponseToJson(this);

  @JsonKey(name: 'chainreport')
  final FactionChainReport? chainreport;
  static const fromJsonFactory = _$FactionChainReportResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionChainReportResponse &&
            (identical(other.chainreport, chainreport) ||
                const DeepCollectionEquality().equals(other.chainreport, chainreport)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(chainreport) ^ runtimeType.hashCode;
}

extension $FactionChainReportResponseExtension on FactionChainReportResponse {
  FactionChainReportResponse copyWith({FactionChainReport? chainreport}) {
    return FactionChainReportResponse(chainreport: chainreport ?? this.chainreport);
  }

  FactionChainReportResponse copyWithWrapped({Wrapped<FactionChainReport?>? chainreport}) {
    return FactionChainReportResponse(chainreport: (chainreport != null ? chainreport.value : this.chainreport));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionChainReport {
  const FactionChainReport({
    this.id,
    this.factionId,
    this.start,
    this.end,
    this.details,
    this.bonuses,
    this.attackers,
    this.nonAttackers,
  });

  factory FactionChainReport.fromJson(Map<String, dynamic> json) => _$FactionChainReportFromJson(json);

  static const toJsonFactory = _$FactionChainReportToJson;
  Map<String, dynamic> toJson() => _$FactionChainReportToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'faction_id')
  final int? factionId;
  @JsonKey(name: 'start')
  final int? start;
  @JsonKey(name: 'end')
  final int? end;
  @JsonKey(name: 'details')
  final FactionChainReportDetails? details;
  @JsonKey(name: 'bonuses', defaultValue: <FactionChainReportBonus>[])
  final List<FactionChainReportBonus>? bonuses;
  @JsonKey(name: 'attackers', defaultValue: <FactionChainReportAttacker>[])
  final List<FactionChainReportAttacker>? attackers;
  @JsonKey(name: 'non-attackers', defaultValue: <int>[])
  final List<int>? nonAttackers;
  static const fromJsonFactory = _$FactionChainReportFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionChainReport &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.factionId, factionId) ||
                const DeepCollectionEquality().equals(other.factionId, factionId)) &&
            (identical(other.start, start) || const DeepCollectionEquality().equals(other.start, start)) &&
            (identical(other.end, end) || const DeepCollectionEquality().equals(other.end, end)) &&
            (identical(other.details, details) || const DeepCollectionEquality().equals(other.details, details)) &&
            (identical(other.bonuses, bonuses) || const DeepCollectionEquality().equals(other.bonuses, bonuses)) &&
            (identical(other.attackers, attackers) ||
                const DeepCollectionEquality().equals(other.attackers, attackers)) &&
            (identical(other.nonAttackers, nonAttackers) ||
                const DeepCollectionEquality().equals(other.nonAttackers, nonAttackers)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(factionId) ^
      const DeepCollectionEquality().hash(start) ^
      const DeepCollectionEquality().hash(end) ^
      const DeepCollectionEquality().hash(details) ^
      const DeepCollectionEquality().hash(bonuses) ^
      const DeepCollectionEquality().hash(attackers) ^
      const DeepCollectionEquality().hash(nonAttackers) ^
      runtimeType.hashCode;
}

extension $FactionChainReportExtension on FactionChainReport {
  FactionChainReport copyWith(
      {int? id,
      int? factionId,
      int? start,
      int? end,
      FactionChainReportDetails? details,
      List<FactionChainReportBonus>? bonuses,
      List<FactionChainReportAttacker>? attackers,
      List<int>? nonAttackers}) {
    return FactionChainReport(
        id: id ?? this.id,
        factionId: factionId ?? this.factionId,
        start: start ?? this.start,
        end: end ?? this.end,
        details: details ?? this.details,
        bonuses: bonuses ?? this.bonuses,
        attackers: attackers ?? this.attackers,
        nonAttackers: nonAttackers ?? this.nonAttackers);
  }

  FactionChainReport copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<int?>? factionId,
      Wrapped<int?>? start,
      Wrapped<int?>? end,
      Wrapped<FactionChainReportDetails?>? details,
      Wrapped<List<FactionChainReportBonus>?>? bonuses,
      Wrapped<List<FactionChainReportAttacker>?>? attackers,
      Wrapped<List<int>?>? nonAttackers}) {
    return FactionChainReport(
        id: (id != null ? id.value : this.id),
        factionId: (factionId != null ? factionId.value : this.factionId),
        start: (start != null ? start.value : this.start),
        end: (end != null ? end.value : this.end),
        details: (details != null ? details.value : this.details),
        bonuses: (bonuses != null ? bonuses.value : this.bonuses),
        attackers: (attackers != null ? attackers.value : this.attackers),
        nonAttackers: (nonAttackers != null ? nonAttackers.value : this.nonAttackers));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionChainReportDetails {
  const FactionChainReportDetails({
    this.chain,
    this.respect,
    this.members,
    this.targets,
    this.war,
    this.best,
    this.leave,
    this.mug,
    this.hospitalize,
    this.assists,
    this.retaliations,
    this.overseas,
    this.draws,
    this.escapes,
    this.losses,
  });

  factory FactionChainReportDetails.fromJson(Map<String, dynamic> json) => _$FactionChainReportDetailsFromJson(json);

  static const toJsonFactory = _$FactionChainReportDetailsToJson;
  Map<String, dynamic> toJson() => _$FactionChainReportDetailsToJson(this);

  @JsonKey(name: 'chain')
  final int? chain;
  @JsonKey(name: 'respect')
  final double? respect;
  @JsonKey(name: 'members')
  final int? members;
  @JsonKey(name: 'targets')
  final int? targets;
  @JsonKey(name: 'war')
  final int? war;
  @JsonKey(name: 'best')
  final double? best;
  @JsonKey(name: 'leave')
  final int? leave;
  @JsonKey(name: 'mug')
  final int? mug;
  @JsonKey(name: 'hospitalize')
  final int? hospitalize;
  @JsonKey(name: 'assists')
  final int? assists;
  @JsonKey(name: 'retaliations')
  final int? retaliations;
  @JsonKey(name: 'overseas')
  final int? overseas;
  @JsonKey(name: 'draws')
  final int? draws;
  @JsonKey(name: 'escapes')
  final int? escapes;
  @JsonKey(name: 'losses')
  final int? losses;
  static const fromJsonFactory = _$FactionChainReportDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionChainReportDetails &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)) &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)) &&
            (identical(other.members, members) || const DeepCollectionEquality().equals(other.members, members)) &&
            (identical(other.targets, targets) || const DeepCollectionEquality().equals(other.targets, targets)) &&
            (identical(other.war, war) || const DeepCollectionEquality().equals(other.war, war)) &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)) &&
            (identical(other.leave, leave) || const DeepCollectionEquality().equals(other.leave, leave)) &&
            (identical(other.mug, mug) || const DeepCollectionEquality().equals(other.mug, mug)) &&
            (identical(other.hospitalize, hospitalize) ||
                const DeepCollectionEquality().equals(other.hospitalize, hospitalize)) &&
            (identical(other.assists, assists) || const DeepCollectionEquality().equals(other.assists, assists)) &&
            (identical(other.retaliations, retaliations) ||
                const DeepCollectionEquality().equals(other.retaliations, retaliations)) &&
            (identical(other.overseas, overseas) || const DeepCollectionEquality().equals(other.overseas, overseas)) &&
            (identical(other.draws, draws) || const DeepCollectionEquality().equals(other.draws, draws)) &&
            (identical(other.escapes, escapes) || const DeepCollectionEquality().equals(other.escapes, escapes)) &&
            (identical(other.losses, losses) || const DeepCollectionEquality().equals(other.losses, losses)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(chain) ^
      const DeepCollectionEquality().hash(respect) ^
      const DeepCollectionEquality().hash(members) ^
      const DeepCollectionEquality().hash(targets) ^
      const DeepCollectionEquality().hash(war) ^
      const DeepCollectionEquality().hash(best) ^
      const DeepCollectionEquality().hash(leave) ^
      const DeepCollectionEquality().hash(mug) ^
      const DeepCollectionEquality().hash(hospitalize) ^
      const DeepCollectionEquality().hash(assists) ^
      const DeepCollectionEquality().hash(retaliations) ^
      const DeepCollectionEquality().hash(overseas) ^
      const DeepCollectionEquality().hash(draws) ^
      const DeepCollectionEquality().hash(escapes) ^
      const DeepCollectionEquality().hash(losses) ^
      runtimeType.hashCode;
}

extension $FactionChainReportDetailsExtension on FactionChainReportDetails {
  FactionChainReportDetails copyWith(
      {int? chain,
      double? respect,
      int? members,
      int? targets,
      int? war,
      double? best,
      int? leave,
      int? mug,
      int? hospitalize,
      int? assists,
      int? retaliations,
      int? overseas,
      int? draws,
      int? escapes,
      int? losses}) {
    return FactionChainReportDetails(
        chain: chain ?? this.chain,
        respect: respect ?? this.respect,
        members: members ?? this.members,
        targets: targets ?? this.targets,
        war: war ?? this.war,
        best: best ?? this.best,
        leave: leave ?? this.leave,
        mug: mug ?? this.mug,
        hospitalize: hospitalize ?? this.hospitalize,
        assists: assists ?? this.assists,
        retaliations: retaliations ?? this.retaliations,
        overseas: overseas ?? this.overseas,
        draws: draws ?? this.draws,
        escapes: escapes ?? this.escapes,
        losses: losses ?? this.losses);
  }

  FactionChainReportDetails copyWithWrapped(
      {Wrapped<int?>? chain,
      Wrapped<double?>? respect,
      Wrapped<int?>? members,
      Wrapped<int?>? targets,
      Wrapped<int?>? war,
      Wrapped<double?>? best,
      Wrapped<int?>? leave,
      Wrapped<int?>? mug,
      Wrapped<int?>? hospitalize,
      Wrapped<int?>? assists,
      Wrapped<int?>? retaliations,
      Wrapped<int?>? overseas,
      Wrapped<int?>? draws,
      Wrapped<int?>? escapes,
      Wrapped<int?>? losses}) {
    return FactionChainReportDetails(
        chain: (chain != null ? chain.value : this.chain),
        respect: (respect != null ? respect.value : this.respect),
        members: (members != null ? members.value : this.members),
        targets: (targets != null ? targets.value : this.targets),
        war: (war != null ? war.value : this.war),
        best: (best != null ? best.value : this.best),
        leave: (leave != null ? leave.value : this.leave),
        mug: (mug != null ? mug.value : this.mug),
        hospitalize: (hospitalize != null ? hospitalize.value : this.hospitalize),
        assists: (assists != null ? assists.value : this.assists),
        retaliations: (retaliations != null ? retaliations.value : this.retaliations),
        overseas: (overseas != null ? overseas.value : this.overseas),
        draws: (draws != null ? draws.value : this.draws),
        escapes: (escapes != null ? escapes.value : this.escapes),
        losses: (losses != null ? losses.value : this.losses));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionChainReportBonus {
  const FactionChainReportBonus({
    this.attackerId,
    this.defenderId,
    this.chain,
    this.respect,
  });

  factory FactionChainReportBonus.fromJson(Map<String, dynamic> json) => _$FactionChainReportBonusFromJson(json);

  static const toJsonFactory = _$FactionChainReportBonusToJson;
  Map<String, dynamic> toJson() => _$FactionChainReportBonusToJson(this);

  @JsonKey(name: 'attacker_id')
  final int? attackerId;
  @JsonKey(name: 'defender_id')
  final int? defenderId;
  @JsonKey(name: 'chain')
  final int? chain;
  @JsonKey(name: 'respect')
  final int? respect;
  static const fromJsonFactory = _$FactionChainReportBonusFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionChainReportBonus &&
            (identical(other.attackerId, attackerId) ||
                const DeepCollectionEquality().equals(other.attackerId, attackerId)) &&
            (identical(other.defenderId, defenderId) ||
                const DeepCollectionEquality().equals(other.defenderId, defenderId)) &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)) &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(attackerId) ^
      const DeepCollectionEquality().hash(defenderId) ^
      const DeepCollectionEquality().hash(chain) ^
      const DeepCollectionEquality().hash(respect) ^
      runtimeType.hashCode;
}

extension $FactionChainReportBonusExtension on FactionChainReportBonus {
  FactionChainReportBonus copyWith({int? attackerId, int? defenderId, int? chain, int? respect}) {
    return FactionChainReportBonus(
        attackerId: attackerId ?? this.attackerId,
        defenderId: defenderId ?? this.defenderId,
        chain: chain ?? this.chain,
        respect: respect ?? this.respect);
  }

  FactionChainReportBonus copyWithWrapped(
      {Wrapped<int?>? attackerId, Wrapped<int?>? defenderId, Wrapped<int?>? chain, Wrapped<int?>? respect}) {
    return FactionChainReportBonus(
        attackerId: (attackerId != null ? attackerId.value : this.attackerId),
        defenderId: (defenderId != null ? defenderId.value : this.defenderId),
        chain: (chain != null ? chain.value : this.chain),
        respect: (respect != null ? respect.value : this.respect));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionChainReportAttacker {
  const FactionChainReportAttacker({
    this.id,
    this.respect,
    this.attacks,
  });

  factory FactionChainReportAttacker.fromJson(Map<String, dynamic> json) => _$FactionChainReportAttackerFromJson(json);

  static const toJsonFactory = _$FactionChainReportAttackerToJson;
  Map<String, dynamic> toJson() => _$FactionChainReportAttackerToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'respect')
  final FactionChainReportAttackerRespect? respect;
  @JsonKey(name: 'attacks')
  final FactionChainReportAttackerAttacks? attacks;
  static const fromJsonFactory = _$FactionChainReportAttackerFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionChainReportAttacker &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)) &&
            (identical(other.attacks, attacks) || const DeepCollectionEquality().equals(other.attacks, attacks)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(respect) ^
      const DeepCollectionEquality().hash(attacks) ^
      runtimeType.hashCode;
}

extension $FactionChainReportAttackerExtension on FactionChainReportAttacker {
  FactionChainReportAttacker copyWith(
      {int? id, FactionChainReportAttackerRespect? respect, FactionChainReportAttackerAttacks? attacks}) {
    return FactionChainReportAttacker(
        id: id ?? this.id, respect: respect ?? this.respect, attacks: attacks ?? this.attacks);
  }

  FactionChainReportAttacker copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<FactionChainReportAttackerRespect?>? respect,
      Wrapped<FactionChainReportAttackerAttacks?>? attacks}) {
    return FactionChainReportAttacker(
        id: (id != null ? id.value : this.id),
        respect: (respect != null ? respect.value : this.respect),
        attacks: (attacks != null ? attacks.value : this.attacks));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionChainReportAttackerRespect {
  const FactionChainReportAttackerRespect({
    this.total,
    this.average,
    this.best,
  });

  factory FactionChainReportAttackerRespect.fromJson(Map<String, dynamic> json) =>
      _$FactionChainReportAttackerRespectFromJson(json);

  static const toJsonFactory = _$FactionChainReportAttackerRespectToJson;
  Map<String, dynamic> toJson() => _$FactionChainReportAttackerRespectToJson(this);

  @JsonKey(name: 'total')
  final double? total;
  @JsonKey(name: 'average')
  final double? average;
  @JsonKey(name: 'best')
  final double? best;
  static const fromJsonFactory = _$FactionChainReportAttackerRespectFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionChainReportAttackerRespect &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.average, average) || const DeepCollectionEquality().equals(other.average, average)) &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(average) ^
      const DeepCollectionEquality().hash(best) ^
      runtimeType.hashCode;
}

extension $FactionChainReportAttackerRespectExtension on FactionChainReportAttackerRespect {
  FactionChainReportAttackerRespect copyWith({double? total, double? average, double? best}) {
    return FactionChainReportAttackerRespect(
        total: total ?? this.total, average: average ?? this.average, best: best ?? this.best);
  }

  FactionChainReportAttackerRespect copyWithWrapped(
      {Wrapped<double?>? total, Wrapped<double?>? average, Wrapped<double?>? best}) {
    return FactionChainReportAttackerRespect(
        total: (total != null ? total.value : this.total),
        average: (average != null ? average.value : this.average),
        best: (best != null ? best.value : this.best));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionChainReportAttackerAttacks {
  const FactionChainReportAttackerAttacks({
    this.total,
    this.leave,
    this.mug,
    this.hospitalize,
    this.assists,
    this.retaliations,
    this.overseas,
    this.draws,
    this.escapes,
    this.losses,
    this.war,
    this.bonuses,
  });

  factory FactionChainReportAttackerAttacks.fromJson(Map<String, dynamic> json) =>
      _$FactionChainReportAttackerAttacksFromJson(json);

  static const toJsonFactory = _$FactionChainReportAttackerAttacksToJson;
  Map<String, dynamic> toJson() => _$FactionChainReportAttackerAttacksToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'leave')
  final int? leave;
  @JsonKey(name: 'mug')
  final int? mug;
  @JsonKey(name: 'hospitalize')
  final int? hospitalize;
  @JsonKey(name: 'assists')
  final int? assists;
  @JsonKey(name: 'retaliations')
  final int? retaliations;
  @JsonKey(name: 'overseas')
  final int? overseas;
  @JsonKey(name: 'draws')
  final int? draws;
  @JsonKey(name: 'escapes')
  final int? escapes;
  @JsonKey(name: 'losses')
  final int? losses;
  @JsonKey(name: 'war')
  final int? war;
  @JsonKey(name: 'bonuses')
  final int? bonuses;
  static const fromJsonFactory = _$FactionChainReportAttackerAttacksFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionChainReportAttackerAttacks &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.leave, leave) || const DeepCollectionEquality().equals(other.leave, leave)) &&
            (identical(other.mug, mug) || const DeepCollectionEquality().equals(other.mug, mug)) &&
            (identical(other.hospitalize, hospitalize) ||
                const DeepCollectionEquality().equals(other.hospitalize, hospitalize)) &&
            (identical(other.assists, assists) || const DeepCollectionEquality().equals(other.assists, assists)) &&
            (identical(other.retaliations, retaliations) ||
                const DeepCollectionEquality().equals(other.retaliations, retaliations)) &&
            (identical(other.overseas, overseas) || const DeepCollectionEquality().equals(other.overseas, overseas)) &&
            (identical(other.draws, draws) || const DeepCollectionEquality().equals(other.draws, draws)) &&
            (identical(other.escapes, escapes) || const DeepCollectionEquality().equals(other.escapes, escapes)) &&
            (identical(other.losses, losses) || const DeepCollectionEquality().equals(other.losses, losses)) &&
            (identical(other.war, war) || const DeepCollectionEquality().equals(other.war, war)) &&
            (identical(other.bonuses, bonuses) || const DeepCollectionEquality().equals(other.bonuses, bonuses)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(leave) ^
      const DeepCollectionEquality().hash(mug) ^
      const DeepCollectionEquality().hash(hospitalize) ^
      const DeepCollectionEquality().hash(assists) ^
      const DeepCollectionEquality().hash(retaliations) ^
      const DeepCollectionEquality().hash(overseas) ^
      const DeepCollectionEquality().hash(draws) ^
      const DeepCollectionEquality().hash(escapes) ^
      const DeepCollectionEquality().hash(losses) ^
      const DeepCollectionEquality().hash(war) ^
      const DeepCollectionEquality().hash(bonuses) ^
      runtimeType.hashCode;
}

extension $FactionChainReportAttackerAttacksExtension on FactionChainReportAttackerAttacks {
  FactionChainReportAttackerAttacks copyWith(
      {int? total,
      int? leave,
      int? mug,
      int? hospitalize,
      int? assists,
      int? retaliations,
      int? overseas,
      int? draws,
      int? escapes,
      int? losses,
      int? war,
      int? bonuses}) {
    return FactionChainReportAttackerAttacks(
        total: total ?? this.total,
        leave: leave ?? this.leave,
        mug: mug ?? this.mug,
        hospitalize: hospitalize ?? this.hospitalize,
        assists: assists ?? this.assists,
        retaliations: retaliations ?? this.retaliations,
        overseas: overseas ?? this.overseas,
        draws: draws ?? this.draws,
        escapes: escapes ?? this.escapes,
        losses: losses ?? this.losses,
        war: war ?? this.war,
        bonuses: bonuses ?? this.bonuses);
  }

  FactionChainReportAttackerAttacks copyWithWrapped(
      {Wrapped<int?>? total,
      Wrapped<int?>? leave,
      Wrapped<int?>? mug,
      Wrapped<int?>? hospitalize,
      Wrapped<int?>? assists,
      Wrapped<int?>? retaliations,
      Wrapped<int?>? overseas,
      Wrapped<int?>? draws,
      Wrapped<int?>? escapes,
      Wrapped<int?>? losses,
      Wrapped<int?>? war,
      Wrapped<int?>? bonuses}) {
    return FactionChainReportAttackerAttacks(
        total: (total != null ? total.value : this.total),
        leave: (leave != null ? leave.value : this.leave),
        mug: (mug != null ? mug.value : this.mug),
        hospitalize: (hospitalize != null ? hospitalize.value : this.hospitalize),
        assists: (assists != null ? assists.value : this.assists),
        retaliations: (retaliations != null ? retaliations.value : this.retaliations),
        overseas: (overseas != null ? overseas.value : this.overseas),
        draws: (draws != null ? draws.value : this.draws),
        escapes: (escapes != null ? escapes.value : this.escapes),
        losses: (losses != null ? losses.value : this.losses),
        war: (war != null ? war.value : this.war),
        bonuses: (bonuses != null ? bonuses.value : this.bonuses));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionCrimeUser {
  const FactionCrimeUser({
    this.id,
    this.joinedAt,
    this.progress,
  });

  factory FactionCrimeUser.fromJson(Map<String, dynamic> json) => _$FactionCrimeUserFromJson(json);

  static const toJsonFactory = _$FactionCrimeUserToJson;
  Map<String, dynamic> toJson() => _$FactionCrimeUserToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'joined_at')
  final int? joinedAt;
  @JsonKey(name: 'progress')
  final double? progress;
  static const fromJsonFactory = _$FactionCrimeUserFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionCrimeUser &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.joinedAt, joinedAt) || const DeepCollectionEquality().equals(other.joinedAt, joinedAt)) &&
            (identical(other.progress, progress) || const DeepCollectionEquality().equals(other.progress, progress)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(joinedAt) ^
      const DeepCollectionEquality().hash(progress) ^
      runtimeType.hashCode;
}

extension $FactionCrimeUserExtension on FactionCrimeUser {
  FactionCrimeUser copyWith({int? id, int? joinedAt, double? progress}) {
    return FactionCrimeUser(
        id: id ?? this.id, joinedAt: joinedAt ?? this.joinedAt, progress: progress ?? this.progress);
  }

  FactionCrimeUser copyWithWrapped({Wrapped<int?>? id, Wrapped<int?>? joinedAt, Wrapped<double?>? progress}) {
    return FactionCrimeUser(
        id: (id != null ? id.value : this.id),
        joinedAt: (joinedAt != null ? joinedAt.value : this.joinedAt),
        progress: (progress != null ? progress.value : this.progress));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionCrimeRewardItem {
  const FactionCrimeRewardItem({
    this.id,
    this.quantity,
  });

  factory FactionCrimeRewardItem.fromJson(Map<String, dynamic> json) => _$FactionCrimeRewardItemFromJson(json);

  static const toJsonFactory = _$FactionCrimeRewardItemToJson;
  Map<String, dynamic> toJson() => _$FactionCrimeRewardItemToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'quantity')
  final int? quantity;
  static const fromJsonFactory = _$FactionCrimeRewardItemFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionCrimeRewardItem &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.quantity, quantity) || const DeepCollectionEquality().equals(other.quantity, quantity)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ const DeepCollectionEquality().hash(quantity) ^ runtimeType.hashCode;
}

extension $FactionCrimeRewardItemExtension on FactionCrimeRewardItem {
  FactionCrimeRewardItem copyWith({int? id, int? quantity}) {
    return FactionCrimeRewardItem(id: id ?? this.id, quantity: quantity ?? this.quantity);
  }

  FactionCrimeRewardItem copyWithWrapped({Wrapped<int?>? id, Wrapped<int?>? quantity}) {
    return FactionCrimeRewardItem(
        id: (id != null ? id.value : this.id), quantity: (quantity != null ? quantity.value : this.quantity));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionCrimeReward {
  const FactionCrimeReward({
    this.money,
    this.items,
    this.respect,
  });

  factory FactionCrimeReward.fromJson(Map<String, dynamic> json) => _$FactionCrimeRewardFromJson(json);

  static const toJsonFactory = _$FactionCrimeRewardToJson;
  Map<String, dynamic> toJson() => _$FactionCrimeRewardToJson(this);

  @JsonKey(name: 'money')
  final int? money;
  @JsonKey(name: 'items', defaultValue: <FactionCrimeRewardItem>[])
  final List<FactionCrimeRewardItem>? items;
  @JsonKey(name: 'respect')
  final int? respect;
  static const fromJsonFactory = _$FactionCrimeRewardFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionCrimeReward &&
            (identical(other.money, money) || const DeepCollectionEquality().equals(other.money, money)) &&
            (identical(other.items, items) || const DeepCollectionEquality().equals(other.items, items)) &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(money) ^
      const DeepCollectionEquality().hash(items) ^
      const DeepCollectionEquality().hash(respect) ^
      runtimeType.hashCode;
}

extension $FactionCrimeRewardExtension on FactionCrimeReward {
  FactionCrimeReward copyWith({int? money, List<FactionCrimeRewardItem>? items, int? respect}) {
    return FactionCrimeReward(money: money ?? this.money, items: items ?? this.items, respect: respect ?? this.respect);
  }

  FactionCrimeReward copyWithWrapped(
      {Wrapped<int?>? money, Wrapped<List<FactionCrimeRewardItem>?>? items, Wrapped<int?>? respect}) {
    return FactionCrimeReward(
        money: (money != null ? money.value : this.money),
        items: (items != null ? items.value : this.items),
        respect: (respect != null ? respect.value : this.respect));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionCrimeSlot {
  const FactionCrimeSlot({
    this.position,
    this.itemRequirement,
    this.userId,
    this.user,
    this.successChance,
  });

  factory FactionCrimeSlot.fromJson(Map<String, dynamic> json) => _$FactionCrimeSlotFromJson(json);

  static const toJsonFactory = _$FactionCrimeSlotToJson;
  Map<String, dynamic> toJson() => _$FactionCrimeSlotToJson(this);

  @JsonKey(name: 'position')
  final String? position;
  @JsonKey(name: 'item_requirement')
  final Object? itemRequirement;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'user')
  final Object? user;
  @JsonKey(name: 'success_chance')
  final int? successChance;
  static const fromJsonFactory = _$FactionCrimeSlotFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionCrimeSlot &&
            (identical(other.position, position) || const DeepCollectionEquality().equals(other.position, position)) &&
            (identical(other.itemRequirement, itemRequirement) ||
                const DeepCollectionEquality().equals(other.itemRequirement, itemRequirement)) &&
            (identical(other.userId, userId) || const DeepCollectionEquality().equals(other.userId, userId)) &&
            (identical(other.user, user) || const DeepCollectionEquality().equals(other.user, user)) &&
            (identical(other.successChance, successChance) ||
                const DeepCollectionEquality().equals(other.successChance, successChance)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(position) ^
      const DeepCollectionEquality().hash(itemRequirement) ^
      const DeepCollectionEquality().hash(userId) ^
      const DeepCollectionEquality().hash(user) ^
      const DeepCollectionEquality().hash(successChance) ^
      runtimeType.hashCode;
}

extension $FactionCrimeSlotExtension on FactionCrimeSlot {
  FactionCrimeSlot copyWith(
      {String? position, Object? itemRequirement, int? userId, Object? user, int? successChance}) {
    return FactionCrimeSlot(
        position: position ?? this.position,
        itemRequirement: itemRequirement ?? this.itemRequirement,
        userId: userId ?? this.userId,
        user: user ?? this.user,
        successChance: successChance ?? this.successChance);
  }

  FactionCrimeSlot copyWithWrapped(
      {Wrapped<String?>? position,
      Wrapped<Object?>? itemRequirement,
      Wrapped<int?>? userId,
      Wrapped<Object?>? user,
      Wrapped<int?>? successChance}) {
    return FactionCrimeSlot(
        position: (position != null ? position.value : this.position),
        itemRequirement: (itemRequirement != null ? itemRequirement.value : this.itemRequirement),
        userId: (userId != null ? userId.value : this.userId),
        user: (user != null ? user.value : this.user),
        successChance: (successChance != null ? successChance.value : this.successChance));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionCrime {
  const FactionCrime({
    this.id,
    this.name,
    this.difficulty,
    this.status,
    this.createdAt,
    this.initiatedAt,
    this.planningAt,
    this.readyAt,
    this.expiredAt,
    this.executedAt,
    this.slots,
    this.rewards,
  });

  factory FactionCrime.fromJson(Map<String, dynamic> json) => _$FactionCrimeFromJson(json);

  static const toJsonFactory = _$FactionCrimeToJson;
  Map<String, dynamic> toJson() => _$FactionCrimeToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'difficulty')
  final int? difficulty;
  @JsonKey(
    name: 'status',
    toJson: factionCrimeStatusEnumNullableToJson,
    fromJson: factionCrimeStatusEnumNullableFromJson,
  )
  final enums.FactionCrimeStatusEnum? status;
  @JsonKey(name: 'created_at')
  final int? createdAt;
  @JsonKey(name: 'initiated_at')
  @deprecated
  final int? initiatedAt;
  @JsonKey(name: 'planning_at')
  final int? planningAt;
  @JsonKey(name: 'ready_at')
  final int? readyAt;
  @JsonKey(name: 'expired_at')
  final int? expiredAt;
  @JsonKey(name: 'executed_at')
  final int? executedAt;
  @JsonKey(name: 'slots', defaultValue: <FactionCrimeSlot>[])
  final List<FactionCrimeSlot>? slots;
  @JsonKey(name: 'rewards')
  final Object? rewards;
  static const fromJsonFactory = _$FactionCrimeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionCrime &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.difficulty, difficulty) ||
                const DeepCollectionEquality().equals(other.difficulty, difficulty)) &&
            (identical(other.status, status) || const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(other.createdAt, createdAt)) &&
            (identical(other.initiatedAt, initiatedAt) ||
                const DeepCollectionEquality().equals(other.initiatedAt, initiatedAt)) &&
            (identical(other.planningAt, planningAt) ||
                const DeepCollectionEquality().equals(other.planningAt, planningAt)) &&
            (identical(other.readyAt, readyAt) || const DeepCollectionEquality().equals(other.readyAt, readyAt)) &&
            (identical(other.expiredAt, expiredAt) ||
                const DeepCollectionEquality().equals(other.expiredAt, expiredAt)) &&
            (identical(other.executedAt, executedAt) ||
                const DeepCollectionEquality().equals(other.executedAt, executedAt)) &&
            (identical(other.slots, slots) || const DeepCollectionEquality().equals(other.slots, slots)) &&
            (identical(other.rewards, rewards) || const DeepCollectionEquality().equals(other.rewards, rewards)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(difficulty) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(initiatedAt) ^
      const DeepCollectionEquality().hash(planningAt) ^
      const DeepCollectionEquality().hash(readyAt) ^
      const DeepCollectionEquality().hash(expiredAt) ^
      const DeepCollectionEquality().hash(executedAt) ^
      const DeepCollectionEquality().hash(slots) ^
      const DeepCollectionEquality().hash(rewards) ^
      runtimeType.hashCode;
}

extension $FactionCrimeExtension on FactionCrime {
  FactionCrime copyWith(
      {int? id,
      String? name,
      int? difficulty,
      enums.FactionCrimeStatusEnum? status,
      int? createdAt,
      int? initiatedAt,
      int? planningAt,
      int? readyAt,
      int? expiredAt,
      int? executedAt,
      List<FactionCrimeSlot>? slots,
      Object? rewards}) {
    return FactionCrime(
        id: id ?? this.id,
        name: name ?? this.name,
        difficulty: difficulty ?? this.difficulty,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        initiatedAt: initiatedAt ?? this.initiatedAt,
        planningAt: planningAt ?? this.planningAt,
        readyAt: readyAt ?? this.readyAt,
        expiredAt: expiredAt ?? this.expiredAt,
        executedAt: executedAt ?? this.executedAt,
        slots: slots ?? this.slots,
        rewards: rewards ?? this.rewards);
  }

  FactionCrime copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<int?>? difficulty,
      Wrapped<enums.FactionCrimeStatusEnum?>? status,
      Wrapped<int?>? createdAt,
      Wrapped<int?>? initiatedAt,
      Wrapped<int?>? planningAt,
      Wrapped<int?>? readyAt,
      Wrapped<int?>? expiredAt,
      Wrapped<int?>? executedAt,
      Wrapped<List<FactionCrimeSlot>?>? slots,
      Wrapped<Object?>? rewards}) {
    return FactionCrime(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        difficulty: (difficulty != null ? difficulty.value : this.difficulty),
        status: (status != null ? status.value : this.status),
        createdAt: (createdAt != null ? createdAt.value : this.createdAt),
        initiatedAt: (initiatedAt != null ? initiatedAt.value : this.initiatedAt),
        planningAt: (planningAt != null ? planningAt.value : this.planningAt),
        readyAt: (readyAt != null ? readyAt.value : this.readyAt),
        expiredAt: (expiredAt != null ? expiredAt.value : this.expiredAt),
        executedAt: (executedAt != null ? executedAt.value : this.executedAt),
        slots: (slots != null ? slots.value : this.slots),
        rewards: (rewards != null ? rewards.value : this.rewards));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionCrimesResponse {
  const FactionCrimesResponse({
    this.crimes,
    this.metadata,
  });

  factory FactionCrimesResponse.fromJson(Map<String, dynamic> json) => _$FactionCrimesResponseFromJson(json);

  static const toJsonFactory = _$FactionCrimesResponseToJson;
  Map<String, dynamic> toJson() => _$FactionCrimesResponseToJson(this);

  @JsonKey(name: 'crimes', defaultValue: <FactionCrime>[])
  final List<FactionCrime>? crimes;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$FactionCrimesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionCrimesResponse &&
            (identical(other.crimes, crimes) || const DeepCollectionEquality().equals(other.crimes, crimes)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(crimes) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $FactionCrimesResponseExtension on FactionCrimesResponse {
  FactionCrimesResponse copyWith({List<FactionCrime>? crimes, RequestMetadataWithLinks? metadata}) {
    return FactionCrimesResponse(crimes: crimes ?? this.crimes, metadata: metadata ?? this.metadata);
  }

  FactionCrimesResponse copyWithWrapped(
      {Wrapped<List<FactionCrime>?>? crimes, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return FactionCrimesResponse(
        crimes: (crimes != null ? crimes.value : this.crimes),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionLookupResponse {
  const FactionLookupResponse({
    this.selections,
  });

  factory FactionLookupResponse.fromJson(Map<String, dynamic> json) => _$FactionLookupResponseFromJson(json);

  static const toJsonFactory = _$FactionLookupResponseToJson;
  Map<String, dynamic> toJson() => _$FactionLookupResponseToJson(this);

  @JsonKey(
    name: 'selections',
    toJson: factionSelectionNameListToJson,
    fromJson: factionSelectionNameListFromJson,
  )
  final List<enums.FactionSelectionName>? selections;
  static const fromJsonFactory = _$FactionLookupResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionLookupResponse &&
            (identical(other.selections, selections) ||
                const DeepCollectionEquality().equals(other.selections, selections)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(selections) ^ runtimeType.hashCode;
}

extension $FactionLookupResponseExtension on FactionLookupResponse {
  FactionLookupResponse copyWith({List<enums.FactionSelectionName>? selections}) {
    return FactionLookupResponse(selections: selections ?? this.selections);
  }

  FactionLookupResponse copyWithWrapped({Wrapped<List<enums.FactionSelectionName>?>? selections}) {
    return FactionLookupResponse(selections: (selections != null ? selections.value : this.selections));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumCategoriesResponse {
  const ForumCategoriesResponse({
    this.categories,
  });

  factory ForumCategoriesResponse.fromJson(Map<String, dynamic> json) => _$ForumCategoriesResponseFromJson(json);

  static const toJsonFactory = _$ForumCategoriesResponseToJson;
  Map<String, dynamic> toJson() => _$ForumCategoriesResponseToJson(this);

  @JsonKey(name: 'categories')
  final List<ForumCategoriesResponse$Categories$Item>? categories;
  static const fromJsonFactory = _$ForumCategoriesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumCategoriesResponse &&
            (identical(other.categories, categories) ||
                const DeepCollectionEquality().equals(other.categories, categories)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(categories) ^ runtimeType.hashCode;
}

extension $ForumCategoriesResponseExtension on ForumCategoriesResponse {
  ForumCategoriesResponse copyWith({List<ForumCategoriesResponse$Categories$Item>? categories}) {
    return ForumCategoriesResponse(categories: categories ?? this.categories);
  }

  ForumCategoriesResponse copyWithWrapped({Wrapped<List<ForumCategoriesResponse$Categories$Item>?>? categories}) {
    return ForumCategoriesResponse(categories: (categories != null ? categories.value : this.categories));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumThreadAuthor {
  const ForumThreadAuthor({
    this.id,
    this.username,
    this.karma,
  });

  factory ForumThreadAuthor.fromJson(Map<String, dynamic> json) => _$ForumThreadAuthorFromJson(json);

  static const toJsonFactory = _$ForumThreadAuthorToJson;
  Map<String, dynamic> toJson() => _$ForumThreadAuthorToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'username')
  final String? username;
  @JsonKey(name: 'karma')
  final int? karma;
  static const fromJsonFactory = _$ForumThreadAuthorFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumThreadAuthor &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.username, username) || const DeepCollectionEquality().equals(other.username, username)) &&
            (identical(other.karma, karma) || const DeepCollectionEquality().equals(other.karma, karma)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(username) ^
      const DeepCollectionEquality().hash(karma) ^
      runtimeType.hashCode;
}

extension $ForumThreadAuthorExtension on ForumThreadAuthor {
  ForumThreadAuthor copyWith({int? id, String? username, int? karma}) {
    return ForumThreadAuthor(id: id ?? this.id, username: username ?? this.username, karma: karma ?? this.karma);
  }

  ForumThreadAuthor copyWithWrapped({Wrapped<int?>? id, Wrapped<String?>? username, Wrapped<int?>? karma}) {
    return ForumThreadAuthor(
        id: (id != null ? id.value : this.id),
        username: (username != null ? username.value : this.username),
        karma: (karma != null ? karma.value : this.karma));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumPollVote {
  const ForumPollVote({
    this.answer,
    this.votes,
  });

  factory ForumPollVote.fromJson(Map<String, dynamic> json) => _$ForumPollVoteFromJson(json);

  static const toJsonFactory = _$ForumPollVoteToJson;
  Map<String, dynamic> toJson() => _$ForumPollVoteToJson(this);

  @JsonKey(name: 'answer')
  final String? answer;
  @JsonKey(name: 'votes')
  final int? votes;
  static const fromJsonFactory = _$ForumPollVoteFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumPollVote &&
            (identical(other.answer, answer) || const DeepCollectionEquality().equals(other.answer, answer)) &&
            (identical(other.votes, votes) || const DeepCollectionEquality().equals(other.votes, votes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(answer) ^ const DeepCollectionEquality().hash(votes) ^ runtimeType.hashCode;
}

extension $ForumPollVoteExtension on ForumPollVote {
  ForumPollVote copyWith({String? answer, int? votes}) {
    return ForumPollVote(answer: answer ?? this.answer, votes: votes ?? this.votes);
  }

  ForumPollVote copyWithWrapped({Wrapped<String?>? answer, Wrapped<int?>? votes}) {
    return ForumPollVote(
        answer: (answer != null ? answer.value : this.answer), votes: (votes != null ? votes.value : this.votes));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumPoll {
  const ForumPoll({
    this.question,
    this.answersCount,
    this.answers,
  });

  factory ForumPoll.fromJson(Map<String, dynamic> json) => _$ForumPollFromJson(json);

  static const toJsonFactory = _$ForumPollToJson;
  Map<String, dynamic> toJson() => _$ForumPollToJson(this);

  @JsonKey(name: 'question')
  final String? question;
  @JsonKey(name: 'answers_count')
  final int? answersCount;
  @JsonKey(name: 'answers', defaultValue: <ForumPollVote>[])
  final List<ForumPollVote>? answers;
  static const fromJsonFactory = _$ForumPollFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumPoll &&
            (identical(other.question, question) || const DeepCollectionEquality().equals(other.question, question)) &&
            (identical(other.answersCount, answersCount) ||
                const DeepCollectionEquality().equals(other.answersCount, answersCount)) &&
            (identical(other.answers, answers) || const DeepCollectionEquality().equals(other.answers, answers)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(question) ^
      const DeepCollectionEquality().hash(answersCount) ^
      const DeepCollectionEquality().hash(answers) ^
      runtimeType.hashCode;
}

extension $ForumPollExtension on ForumPoll {
  ForumPoll copyWith({String? question, int? answersCount, List<ForumPollVote>? answers}) {
    return ForumPoll(
        question: question ?? this.question,
        answersCount: answersCount ?? this.answersCount,
        answers: answers ?? this.answers);
  }

  ForumPoll copyWithWrapped(
      {Wrapped<String?>? question, Wrapped<int?>? answersCount, Wrapped<List<ForumPollVote>?>? answers}) {
    return ForumPoll(
        question: (question != null ? question.value : this.question),
        answersCount: (answersCount != null ? answersCount.value : this.answersCount),
        answers: (answers != null ? answers.value : this.answers));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumThreadBase {
  const ForumThreadBase({
    this.id,
    this.title,
    this.forumId,
    this.posts,
    this.rating,
    this.views,
    this.author,
    this.lastPoster,
    this.firstPostTime,
    this.lastPostTime,
    this.hasPoll,
    this.isLocked,
    this.isSticky,
  });

  factory ForumThreadBase.fromJson(Map<String, dynamic> json) => _$ForumThreadBaseFromJson(json);

  static const toJsonFactory = _$ForumThreadBaseToJson;
  Map<String, dynamic> toJson() => _$ForumThreadBaseToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'forum_id')
  final int? forumId;
  @JsonKey(name: 'posts')
  final int? posts;
  @JsonKey(name: 'rating')
  final int? rating;
  @JsonKey(name: 'views')
  final int? views;
  @JsonKey(name: 'author')
  final ForumThreadAuthor? author;
  @JsonKey(name: 'last_poster')
  final ForumThreadAuthor? lastPoster;
  @JsonKey(name: 'first_post_time')
  final int? firstPostTime;
  @JsonKey(name: 'last_post_time')
  final int? lastPostTime;
  @JsonKey(name: 'has_poll')
  final bool? hasPoll;
  @JsonKey(name: 'is_locked')
  final bool? isLocked;
  @JsonKey(name: 'is_sticky')
  final bool? isSticky;
  static const fromJsonFactory = _$ForumThreadBaseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumThreadBase &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.forumId, forumId) || const DeepCollectionEquality().equals(other.forumId, forumId)) &&
            (identical(other.posts, posts) || const DeepCollectionEquality().equals(other.posts, posts)) &&
            (identical(other.rating, rating) || const DeepCollectionEquality().equals(other.rating, rating)) &&
            (identical(other.views, views) || const DeepCollectionEquality().equals(other.views, views)) &&
            (identical(other.author, author) || const DeepCollectionEquality().equals(other.author, author)) &&
            (identical(other.lastPoster, lastPoster) ||
                const DeepCollectionEquality().equals(other.lastPoster, lastPoster)) &&
            (identical(other.firstPostTime, firstPostTime) ||
                const DeepCollectionEquality().equals(other.firstPostTime, firstPostTime)) &&
            (identical(other.lastPostTime, lastPostTime) ||
                const DeepCollectionEquality().equals(other.lastPostTime, lastPostTime)) &&
            (identical(other.hasPoll, hasPoll) || const DeepCollectionEquality().equals(other.hasPoll, hasPoll)) &&
            (identical(other.isLocked, isLocked) || const DeepCollectionEquality().equals(other.isLocked, isLocked)) &&
            (identical(other.isSticky, isSticky) || const DeepCollectionEquality().equals(other.isSticky, isSticky)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(forumId) ^
      const DeepCollectionEquality().hash(posts) ^
      const DeepCollectionEquality().hash(rating) ^
      const DeepCollectionEquality().hash(views) ^
      const DeepCollectionEquality().hash(author) ^
      const DeepCollectionEquality().hash(lastPoster) ^
      const DeepCollectionEquality().hash(firstPostTime) ^
      const DeepCollectionEquality().hash(lastPostTime) ^
      const DeepCollectionEquality().hash(hasPoll) ^
      const DeepCollectionEquality().hash(isLocked) ^
      const DeepCollectionEquality().hash(isSticky) ^
      runtimeType.hashCode;
}

extension $ForumThreadBaseExtension on ForumThreadBase {
  ForumThreadBase copyWith(
      {int? id,
      String? title,
      int? forumId,
      int? posts,
      int? rating,
      int? views,
      ForumThreadAuthor? author,
      ForumThreadAuthor? lastPoster,
      int? firstPostTime,
      int? lastPostTime,
      bool? hasPoll,
      bool? isLocked,
      bool? isSticky}) {
    return ForumThreadBase(
        id: id ?? this.id,
        title: title ?? this.title,
        forumId: forumId ?? this.forumId,
        posts: posts ?? this.posts,
        rating: rating ?? this.rating,
        views: views ?? this.views,
        author: author ?? this.author,
        lastPoster: lastPoster ?? this.lastPoster,
        firstPostTime: firstPostTime ?? this.firstPostTime,
        lastPostTime: lastPostTime ?? this.lastPostTime,
        hasPoll: hasPoll ?? this.hasPoll,
        isLocked: isLocked ?? this.isLocked,
        isSticky: isSticky ?? this.isSticky);
  }

  ForumThreadBase copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? title,
      Wrapped<int?>? forumId,
      Wrapped<int?>? posts,
      Wrapped<int?>? rating,
      Wrapped<int?>? views,
      Wrapped<ForumThreadAuthor?>? author,
      Wrapped<ForumThreadAuthor?>? lastPoster,
      Wrapped<int?>? firstPostTime,
      Wrapped<int?>? lastPostTime,
      Wrapped<bool?>? hasPoll,
      Wrapped<bool?>? isLocked,
      Wrapped<bool?>? isSticky}) {
    return ForumThreadBase(
        id: (id != null ? id.value : this.id),
        title: (title != null ? title.value : this.title),
        forumId: (forumId != null ? forumId.value : this.forumId),
        posts: (posts != null ? posts.value : this.posts),
        rating: (rating != null ? rating.value : this.rating),
        views: (views != null ? views.value : this.views),
        author: (author != null ? author.value : this.author),
        lastPoster: (lastPoster != null ? lastPoster.value : this.lastPoster),
        firstPostTime: (firstPostTime != null ? firstPostTime.value : this.firstPostTime),
        lastPostTime: (lastPostTime != null ? lastPostTime.value : this.lastPostTime),
        hasPoll: (hasPoll != null ? hasPoll.value : this.hasPoll),
        isLocked: (isLocked != null ? isLocked.value : this.isLocked),
        isSticky: (isSticky != null ? isSticky.value : this.isSticky));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumThreadExtended {
  const ForumThreadExtended({
    this.content,
    this.contentRaw,
    this.poll,
    this.id,
    this.title,
    this.forumId,
    this.posts,
    this.rating,
    this.views,
    this.author,
    this.lastPoster,
    this.firstPostTime,
    this.lastPostTime,
    this.hasPoll,
    this.isLocked,
    this.isSticky,
  });

  factory ForumThreadExtended.fromJson(Map<String, dynamic> json) => _$ForumThreadExtendedFromJson(json);

  static const toJsonFactory = _$ForumThreadExtendedToJson;
  Map<String, dynamic> toJson() => _$ForumThreadExtendedToJson(this);

  @JsonKey(name: 'content')
  final String? content;
  @JsonKey(name: 'content_raw')
  final String? contentRaw;
  @JsonKey(name: 'poll')
  final ForumPoll? poll;
  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'forum_id')
  final int? forumId;
  @JsonKey(name: 'posts')
  final int? posts;
  @JsonKey(name: 'rating')
  final int? rating;
  @JsonKey(name: 'views')
  final int? views;
  @JsonKey(name: 'author')
  final ForumThreadAuthor? author;
  @JsonKey(name: 'last_poster')
  final ForumThreadAuthor? lastPoster;
  @JsonKey(name: 'first_post_time')
  final int? firstPostTime;
  @JsonKey(name: 'last_post_time')
  final int? lastPostTime;
  @JsonKey(name: 'has_poll')
  final bool? hasPoll;
  @JsonKey(name: 'is_locked')
  final bool? isLocked;
  @JsonKey(name: 'is_sticky')
  final bool? isSticky;
  static const fromJsonFactory = _$ForumThreadExtendedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumThreadExtended &&
            (identical(other.content, content) || const DeepCollectionEquality().equals(other.content, content)) &&
            (identical(other.contentRaw, contentRaw) ||
                const DeepCollectionEquality().equals(other.contentRaw, contentRaw)) &&
            (identical(other.poll, poll) || const DeepCollectionEquality().equals(other.poll, poll)) &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.forumId, forumId) || const DeepCollectionEquality().equals(other.forumId, forumId)) &&
            (identical(other.posts, posts) || const DeepCollectionEquality().equals(other.posts, posts)) &&
            (identical(other.rating, rating) || const DeepCollectionEquality().equals(other.rating, rating)) &&
            (identical(other.views, views) || const DeepCollectionEquality().equals(other.views, views)) &&
            (identical(other.author, author) || const DeepCollectionEquality().equals(other.author, author)) &&
            (identical(other.lastPoster, lastPoster) ||
                const DeepCollectionEquality().equals(other.lastPoster, lastPoster)) &&
            (identical(other.firstPostTime, firstPostTime) ||
                const DeepCollectionEquality().equals(other.firstPostTime, firstPostTime)) &&
            (identical(other.lastPostTime, lastPostTime) ||
                const DeepCollectionEquality().equals(other.lastPostTime, lastPostTime)) &&
            (identical(other.hasPoll, hasPoll) || const DeepCollectionEquality().equals(other.hasPoll, hasPoll)) &&
            (identical(other.isLocked, isLocked) || const DeepCollectionEquality().equals(other.isLocked, isLocked)) &&
            (identical(other.isSticky, isSticky) || const DeepCollectionEquality().equals(other.isSticky, isSticky)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(content) ^
      const DeepCollectionEquality().hash(contentRaw) ^
      const DeepCollectionEquality().hash(poll) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(forumId) ^
      const DeepCollectionEquality().hash(posts) ^
      const DeepCollectionEquality().hash(rating) ^
      const DeepCollectionEquality().hash(views) ^
      const DeepCollectionEquality().hash(author) ^
      const DeepCollectionEquality().hash(lastPoster) ^
      const DeepCollectionEquality().hash(firstPostTime) ^
      const DeepCollectionEquality().hash(lastPostTime) ^
      const DeepCollectionEquality().hash(hasPoll) ^
      const DeepCollectionEquality().hash(isLocked) ^
      const DeepCollectionEquality().hash(isSticky) ^
      runtimeType.hashCode;
}

extension $ForumThreadExtendedExtension on ForumThreadExtended {
  ForumThreadExtended copyWith(
      {String? content,
      String? contentRaw,
      ForumPoll? poll,
      int? id,
      String? title,
      int? forumId,
      int? posts,
      int? rating,
      int? views,
      ForumThreadAuthor? author,
      ForumThreadAuthor? lastPoster,
      int? firstPostTime,
      int? lastPostTime,
      bool? hasPoll,
      bool? isLocked,
      bool? isSticky}) {
    return ForumThreadExtended(
        content: content ?? this.content,
        contentRaw: contentRaw ?? this.contentRaw,
        poll: poll ?? this.poll,
        id: id ?? this.id,
        title: title ?? this.title,
        forumId: forumId ?? this.forumId,
        posts: posts ?? this.posts,
        rating: rating ?? this.rating,
        views: views ?? this.views,
        author: author ?? this.author,
        lastPoster: lastPoster ?? this.lastPoster,
        firstPostTime: firstPostTime ?? this.firstPostTime,
        lastPostTime: lastPostTime ?? this.lastPostTime,
        hasPoll: hasPoll ?? this.hasPoll,
        isLocked: isLocked ?? this.isLocked,
        isSticky: isSticky ?? this.isSticky);
  }

  ForumThreadExtended copyWithWrapped(
      {Wrapped<String?>? content,
      Wrapped<String?>? contentRaw,
      Wrapped<ForumPoll?>? poll,
      Wrapped<int?>? id,
      Wrapped<String?>? title,
      Wrapped<int?>? forumId,
      Wrapped<int?>? posts,
      Wrapped<int?>? rating,
      Wrapped<int?>? views,
      Wrapped<ForumThreadAuthor?>? author,
      Wrapped<ForumThreadAuthor?>? lastPoster,
      Wrapped<int?>? firstPostTime,
      Wrapped<int?>? lastPostTime,
      Wrapped<bool?>? hasPoll,
      Wrapped<bool?>? isLocked,
      Wrapped<bool?>? isSticky}) {
    return ForumThreadExtended(
        content: (content != null ? content.value : this.content),
        contentRaw: (contentRaw != null ? contentRaw.value : this.contentRaw),
        poll: (poll != null ? poll.value : this.poll),
        id: (id != null ? id.value : this.id),
        title: (title != null ? title.value : this.title),
        forumId: (forumId != null ? forumId.value : this.forumId),
        posts: (posts != null ? posts.value : this.posts),
        rating: (rating != null ? rating.value : this.rating),
        views: (views != null ? views.value : this.views),
        author: (author != null ? author.value : this.author),
        lastPoster: (lastPoster != null ? lastPoster.value : this.lastPoster),
        firstPostTime: (firstPostTime != null ? firstPostTime.value : this.firstPostTime),
        lastPostTime: (lastPostTime != null ? lastPostTime.value : this.lastPostTime),
        hasPoll: (hasPoll != null ? hasPoll.value : this.hasPoll),
        isLocked: (isLocked != null ? isLocked.value : this.isLocked),
        isSticky: (isSticky != null ? isSticky.value : this.isSticky));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumPost {
  const ForumPost({
    this.id,
    this.threadId,
    this.author,
    this.isLegacy,
    this.isTopic,
    this.isEdited,
    this.isPinned,
    this.createdTime,
    this.editedBy,
    this.hasQuote,
    this.quotedPostId,
    this.content,
    this.likes,
    this.dislikes,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) => _$ForumPostFromJson(json);

  static const toJsonFactory = _$ForumPostToJson;
  Map<String, dynamic> toJson() => _$ForumPostToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'thread_id')
  final int? threadId;
  @JsonKey(name: 'author')
  final ForumThreadAuthor? author;
  @JsonKey(name: 'is_legacy')
  final bool? isLegacy;
  @JsonKey(name: 'is_topic')
  final bool? isTopic;
  @JsonKey(name: 'is_edited')
  final bool? isEdited;
  @JsonKey(name: 'is_pinned')
  final bool? isPinned;
  @JsonKey(name: 'created_time')
  final int? createdTime;
  @JsonKey(name: 'edited_by')
  final int? editedBy;
  @JsonKey(name: 'has_quote')
  final bool? hasQuote;
  @JsonKey(name: 'quoted_post_id')
  final int? quotedPostId;
  @JsonKey(name: 'content')
  final String? content;
  @JsonKey(name: 'likes')
  final int? likes;
  @JsonKey(name: 'dislikes')
  final int? dislikes;
  static const fromJsonFactory = _$ForumPostFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumPost &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.threadId, threadId) || const DeepCollectionEquality().equals(other.threadId, threadId)) &&
            (identical(other.author, author) || const DeepCollectionEquality().equals(other.author, author)) &&
            (identical(other.isLegacy, isLegacy) || const DeepCollectionEquality().equals(other.isLegacy, isLegacy)) &&
            (identical(other.isTopic, isTopic) || const DeepCollectionEquality().equals(other.isTopic, isTopic)) &&
            (identical(other.isEdited, isEdited) || const DeepCollectionEquality().equals(other.isEdited, isEdited)) &&
            (identical(other.isPinned, isPinned) || const DeepCollectionEquality().equals(other.isPinned, isPinned)) &&
            (identical(other.createdTime, createdTime) ||
                const DeepCollectionEquality().equals(other.createdTime, createdTime)) &&
            (identical(other.editedBy, editedBy) || const DeepCollectionEquality().equals(other.editedBy, editedBy)) &&
            (identical(other.hasQuote, hasQuote) || const DeepCollectionEquality().equals(other.hasQuote, hasQuote)) &&
            (identical(other.quotedPostId, quotedPostId) ||
                const DeepCollectionEquality().equals(other.quotedPostId, quotedPostId)) &&
            (identical(other.content, content) || const DeepCollectionEquality().equals(other.content, content)) &&
            (identical(other.likes, likes) || const DeepCollectionEquality().equals(other.likes, likes)) &&
            (identical(other.dislikes, dislikes) || const DeepCollectionEquality().equals(other.dislikes, dislikes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(threadId) ^
      const DeepCollectionEquality().hash(author) ^
      const DeepCollectionEquality().hash(isLegacy) ^
      const DeepCollectionEquality().hash(isTopic) ^
      const DeepCollectionEquality().hash(isEdited) ^
      const DeepCollectionEquality().hash(isPinned) ^
      const DeepCollectionEquality().hash(createdTime) ^
      const DeepCollectionEquality().hash(editedBy) ^
      const DeepCollectionEquality().hash(hasQuote) ^
      const DeepCollectionEquality().hash(quotedPostId) ^
      const DeepCollectionEquality().hash(content) ^
      const DeepCollectionEquality().hash(likes) ^
      const DeepCollectionEquality().hash(dislikes) ^
      runtimeType.hashCode;
}

extension $ForumPostExtension on ForumPost {
  ForumPost copyWith(
      {int? id,
      int? threadId,
      ForumThreadAuthor? author,
      bool? isLegacy,
      bool? isTopic,
      bool? isEdited,
      bool? isPinned,
      int? createdTime,
      int? editedBy,
      bool? hasQuote,
      int? quotedPostId,
      String? content,
      int? likes,
      int? dislikes}) {
    return ForumPost(
        id: id ?? this.id,
        threadId: threadId ?? this.threadId,
        author: author ?? this.author,
        isLegacy: isLegacy ?? this.isLegacy,
        isTopic: isTopic ?? this.isTopic,
        isEdited: isEdited ?? this.isEdited,
        isPinned: isPinned ?? this.isPinned,
        createdTime: createdTime ?? this.createdTime,
        editedBy: editedBy ?? this.editedBy,
        hasQuote: hasQuote ?? this.hasQuote,
        quotedPostId: quotedPostId ?? this.quotedPostId,
        content: content ?? this.content,
        likes: likes ?? this.likes,
        dislikes: dislikes ?? this.dislikes);
  }

  ForumPost copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<int?>? threadId,
      Wrapped<ForumThreadAuthor?>? author,
      Wrapped<bool?>? isLegacy,
      Wrapped<bool?>? isTopic,
      Wrapped<bool?>? isEdited,
      Wrapped<bool?>? isPinned,
      Wrapped<int?>? createdTime,
      Wrapped<int?>? editedBy,
      Wrapped<bool?>? hasQuote,
      Wrapped<int?>? quotedPostId,
      Wrapped<String?>? content,
      Wrapped<int?>? likes,
      Wrapped<int?>? dislikes}) {
    return ForumPost(
        id: (id != null ? id.value : this.id),
        threadId: (threadId != null ? threadId.value : this.threadId),
        author: (author != null ? author.value : this.author),
        isLegacy: (isLegacy != null ? isLegacy.value : this.isLegacy),
        isTopic: (isTopic != null ? isTopic.value : this.isTopic),
        isEdited: (isEdited != null ? isEdited.value : this.isEdited),
        isPinned: (isPinned != null ? isPinned.value : this.isPinned),
        createdTime: (createdTime != null ? createdTime.value : this.createdTime),
        editedBy: (editedBy != null ? editedBy.value : this.editedBy),
        hasQuote: (hasQuote != null ? hasQuote.value : this.hasQuote),
        quotedPostId: (quotedPostId != null ? quotedPostId.value : this.quotedPostId),
        content: (content != null ? content.value : this.content),
        likes: (likes != null ? likes.value : this.likes),
        dislikes: (dislikes != null ? dislikes.value : this.dislikes));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumThreadUserExtended {
  const ForumThreadUserExtended({
    this.newPosts,
    this.id,
    this.title,
    this.forumId,
    this.posts,
    this.rating,
    this.views,
    this.author,
    this.lastPoster,
    this.firstPostTime,
    this.lastPostTime,
    this.hasPoll,
    this.isLocked,
    this.isSticky,
  });

  factory ForumThreadUserExtended.fromJson(Map<String, dynamic> json) => _$ForumThreadUserExtendedFromJson(json);

  static const toJsonFactory = _$ForumThreadUserExtendedToJson;
  Map<String, dynamic> toJson() => _$ForumThreadUserExtendedToJson(this);

  @JsonKey(name: 'new_posts')
  final int? newPosts;
  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'forum_id')
  final int? forumId;
  @JsonKey(name: 'posts')
  final int? posts;
  @JsonKey(name: 'rating')
  final int? rating;
  @JsonKey(name: 'views')
  final int? views;
  @JsonKey(name: 'author')
  final ForumThreadAuthor? author;
  @JsonKey(name: 'last_poster')
  final ForumThreadAuthor? lastPoster;
  @JsonKey(name: 'first_post_time')
  final int? firstPostTime;
  @JsonKey(name: 'last_post_time')
  final int? lastPostTime;
  @JsonKey(name: 'has_poll')
  final bool? hasPoll;
  @JsonKey(name: 'is_locked')
  final bool? isLocked;
  @JsonKey(name: 'is_sticky')
  final bool? isSticky;
  static const fromJsonFactory = _$ForumThreadUserExtendedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumThreadUserExtended &&
            (identical(other.newPosts, newPosts) || const DeepCollectionEquality().equals(other.newPosts, newPosts)) &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.forumId, forumId) || const DeepCollectionEquality().equals(other.forumId, forumId)) &&
            (identical(other.posts, posts) || const DeepCollectionEquality().equals(other.posts, posts)) &&
            (identical(other.rating, rating) || const DeepCollectionEquality().equals(other.rating, rating)) &&
            (identical(other.views, views) || const DeepCollectionEquality().equals(other.views, views)) &&
            (identical(other.author, author) || const DeepCollectionEquality().equals(other.author, author)) &&
            (identical(other.lastPoster, lastPoster) ||
                const DeepCollectionEquality().equals(other.lastPoster, lastPoster)) &&
            (identical(other.firstPostTime, firstPostTime) ||
                const DeepCollectionEquality().equals(other.firstPostTime, firstPostTime)) &&
            (identical(other.lastPostTime, lastPostTime) ||
                const DeepCollectionEquality().equals(other.lastPostTime, lastPostTime)) &&
            (identical(other.hasPoll, hasPoll) || const DeepCollectionEquality().equals(other.hasPoll, hasPoll)) &&
            (identical(other.isLocked, isLocked) || const DeepCollectionEquality().equals(other.isLocked, isLocked)) &&
            (identical(other.isSticky, isSticky) || const DeepCollectionEquality().equals(other.isSticky, isSticky)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(newPosts) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(forumId) ^
      const DeepCollectionEquality().hash(posts) ^
      const DeepCollectionEquality().hash(rating) ^
      const DeepCollectionEquality().hash(views) ^
      const DeepCollectionEquality().hash(author) ^
      const DeepCollectionEquality().hash(lastPoster) ^
      const DeepCollectionEquality().hash(firstPostTime) ^
      const DeepCollectionEquality().hash(lastPostTime) ^
      const DeepCollectionEquality().hash(hasPoll) ^
      const DeepCollectionEquality().hash(isLocked) ^
      const DeepCollectionEquality().hash(isSticky) ^
      runtimeType.hashCode;
}

extension $ForumThreadUserExtendedExtension on ForumThreadUserExtended {
  ForumThreadUserExtended copyWith(
      {int? newPosts,
      int? id,
      String? title,
      int? forumId,
      int? posts,
      int? rating,
      int? views,
      ForumThreadAuthor? author,
      ForumThreadAuthor? lastPoster,
      int? firstPostTime,
      int? lastPostTime,
      bool? hasPoll,
      bool? isLocked,
      bool? isSticky}) {
    return ForumThreadUserExtended(
        newPosts: newPosts ?? this.newPosts,
        id: id ?? this.id,
        title: title ?? this.title,
        forumId: forumId ?? this.forumId,
        posts: posts ?? this.posts,
        rating: rating ?? this.rating,
        views: views ?? this.views,
        author: author ?? this.author,
        lastPoster: lastPoster ?? this.lastPoster,
        firstPostTime: firstPostTime ?? this.firstPostTime,
        lastPostTime: lastPostTime ?? this.lastPostTime,
        hasPoll: hasPoll ?? this.hasPoll,
        isLocked: isLocked ?? this.isLocked,
        isSticky: isSticky ?? this.isSticky);
  }

  ForumThreadUserExtended copyWithWrapped(
      {Wrapped<int?>? newPosts,
      Wrapped<int?>? id,
      Wrapped<String?>? title,
      Wrapped<int?>? forumId,
      Wrapped<int?>? posts,
      Wrapped<int?>? rating,
      Wrapped<int?>? views,
      Wrapped<ForumThreadAuthor?>? author,
      Wrapped<ForumThreadAuthor?>? lastPoster,
      Wrapped<int?>? firstPostTime,
      Wrapped<int?>? lastPostTime,
      Wrapped<bool?>? hasPoll,
      Wrapped<bool?>? isLocked,
      Wrapped<bool?>? isSticky}) {
    return ForumThreadUserExtended(
        newPosts: (newPosts != null ? newPosts.value : this.newPosts),
        id: (id != null ? id.value : this.id),
        title: (title != null ? title.value : this.title),
        forumId: (forumId != null ? forumId.value : this.forumId),
        posts: (posts != null ? posts.value : this.posts),
        rating: (rating != null ? rating.value : this.rating),
        views: (views != null ? views.value : this.views),
        author: (author != null ? author.value : this.author),
        lastPoster: (lastPoster != null ? lastPoster.value : this.lastPoster),
        firstPostTime: (firstPostTime != null ? firstPostTime.value : this.firstPostTime),
        lastPostTime: (lastPostTime != null ? lastPostTime.value : this.lastPostTime),
        hasPoll: (hasPoll != null ? hasPoll.value : this.hasPoll),
        isLocked: (isLocked != null ? isLocked.value : this.isLocked),
        isSticky: (isSticky != null ? isSticky.value : this.isSticky));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumSubscribedThreadPostsCount {
  const ForumSubscribedThreadPostsCount({
    this.$new,
    this.total,
  });

  factory ForumSubscribedThreadPostsCount.fromJson(Map<String, dynamic> json) =>
      _$ForumSubscribedThreadPostsCountFromJson(json);

  static const toJsonFactory = _$ForumSubscribedThreadPostsCountToJson;
  Map<String, dynamic> toJson() => _$ForumSubscribedThreadPostsCountToJson(this);

  @JsonKey(name: 'new')
  final int? $new;
  @JsonKey(name: 'total')
  final int? total;
  static const fromJsonFactory = _$ForumSubscribedThreadPostsCountFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumSubscribedThreadPostsCount &&
            (identical(other.$new, $new) || const DeepCollectionEquality().equals(other.$new, $new)) &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash($new) ^ const DeepCollectionEquality().hash(total) ^ runtimeType.hashCode;
}

extension $ForumSubscribedThreadPostsCountExtension on ForumSubscribedThreadPostsCount {
  ForumSubscribedThreadPostsCount copyWith({int? $new, int? total}) {
    return ForumSubscribedThreadPostsCount($new: $new ?? this.$new, total: total ?? this.total);
  }

  ForumSubscribedThreadPostsCount copyWithWrapped({Wrapped<int?>? $new, Wrapped<int?>? total}) {
    return ForumSubscribedThreadPostsCount(
        $new: ($new != null ? $new.value : this.$new), total: (total != null ? total.value : this.total));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumSubscribedThread {
  const ForumSubscribedThread({
    this.id,
    this.forumId,
    this.author,
    this.title,
    this.posts,
  });

  factory ForumSubscribedThread.fromJson(Map<String, dynamic> json) => _$ForumSubscribedThreadFromJson(json);

  static const toJsonFactory = _$ForumSubscribedThreadToJson;
  Map<String, dynamic> toJson() => _$ForumSubscribedThreadToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'forum_id')
  final int? forumId;
  @JsonKey(name: 'author')
  final ForumThreadAuthor? author;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'posts')
  final ForumSubscribedThreadPostsCount? posts;
  static const fromJsonFactory = _$ForumSubscribedThreadFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumSubscribedThread &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.forumId, forumId) || const DeepCollectionEquality().equals(other.forumId, forumId)) &&
            (identical(other.author, author) || const DeepCollectionEquality().equals(other.author, author)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.posts, posts) || const DeepCollectionEquality().equals(other.posts, posts)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(forumId) ^
      const DeepCollectionEquality().hash(author) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(posts) ^
      runtimeType.hashCode;
}

extension $ForumSubscribedThreadExtension on ForumSubscribedThread {
  ForumSubscribedThread copyWith(
      {int? id, int? forumId, ForumThreadAuthor? author, String? title, ForumSubscribedThreadPostsCount? posts}) {
    return ForumSubscribedThread(
        id: id ?? this.id,
        forumId: forumId ?? this.forumId,
        author: author ?? this.author,
        title: title ?? this.title,
        posts: posts ?? this.posts);
  }

  ForumSubscribedThread copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<int?>? forumId,
      Wrapped<ForumThreadAuthor?>? author,
      Wrapped<String?>? title,
      Wrapped<ForumSubscribedThreadPostsCount?>? posts}) {
    return ForumSubscribedThread(
        id: (id != null ? id.value : this.id),
        forumId: (forumId != null ? forumId.value : this.forumId),
        author: (author != null ? author.value : this.author),
        title: (title != null ? title.value : this.title),
        posts: (posts != null ? posts.value : this.posts));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumFeed {
  const ForumFeed({
    this.threadId,
    this.postId,
    this.user,
    this.title,
    this.text,
    this.timestamp,
    this.isSeen,
    this.type,
  });

  factory ForumFeed.fromJson(Map<String, dynamic> json) => _$ForumFeedFromJson(json);

  static const toJsonFactory = _$ForumFeedToJson;
  Map<String, dynamic> toJson() => _$ForumFeedToJson(this);

  @JsonKey(name: 'thread_id')
  final int? threadId;
  @JsonKey(name: 'post_id')
  final int? postId;
  @JsonKey(name: 'user')
  final ForumThreadAuthor? user;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'text')
  final String? text;
  @JsonKey(name: 'timestamp')
  final int? timestamp;
  @JsonKey(name: 'is_seen')
  final bool? isSeen;
  @JsonKey(
    name: 'type',
    toJson: forumFeedTypeEnumNullableToJson,
    fromJson: forumFeedTypeEnumNullableFromJson,
  )
  final enums.ForumFeedTypeEnum? type;
  static const fromJsonFactory = _$ForumFeedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumFeed &&
            (identical(other.threadId, threadId) || const DeepCollectionEquality().equals(other.threadId, threadId)) &&
            (identical(other.postId, postId) || const DeepCollectionEquality().equals(other.postId, postId)) &&
            (identical(other.user, user) || const DeepCollectionEquality().equals(other.user, user)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.text, text) || const DeepCollectionEquality().equals(other.text, text)) &&
            (identical(other.timestamp, timestamp) ||
                const DeepCollectionEquality().equals(other.timestamp, timestamp)) &&
            (identical(other.isSeen, isSeen) || const DeepCollectionEquality().equals(other.isSeen, isSeen)) &&
            (identical(other.type, type) || const DeepCollectionEquality().equals(other.type, type)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(threadId) ^
      const DeepCollectionEquality().hash(postId) ^
      const DeepCollectionEquality().hash(user) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(text) ^
      const DeepCollectionEquality().hash(timestamp) ^
      const DeepCollectionEquality().hash(isSeen) ^
      const DeepCollectionEquality().hash(type) ^
      runtimeType.hashCode;
}

extension $ForumFeedExtension on ForumFeed {
  ForumFeed copyWith(
      {int? threadId,
      int? postId,
      ForumThreadAuthor? user,
      String? title,
      String? text,
      int? timestamp,
      bool? isSeen,
      enums.ForumFeedTypeEnum? type}) {
    return ForumFeed(
        threadId: threadId ?? this.threadId,
        postId: postId ?? this.postId,
        user: user ?? this.user,
        title: title ?? this.title,
        text: text ?? this.text,
        timestamp: timestamp ?? this.timestamp,
        isSeen: isSeen ?? this.isSeen,
        type: type ?? this.type);
  }

  ForumFeed copyWithWrapped(
      {Wrapped<int?>? threadId,
      Wrapped<int?>? postId,
      Wrapped<ForumThreadAuthor?>? user,
      Wrapped<String?>? title,
      Wrapped<String?>? text,
      Wrapped<int?>? timestamp,
      Wrapped<bool?>? isSeen,
      Wrapped<enums.ForumFeedTypeEnum?>? type}) {
    return ForumFeed(
        threadId: (threadId != null ? threadId.value : this.threadId),
        postId: (postId != null ? postId.value : this.postId),
        user: (user != null ? user.value : this.user),
        title: (title != null ? title.value : this.title),
        text: (text != null ? text.value : this.text),
        timestamp: (timestamp != null ? timestamp.value : this.timestamp),
        isSeen: (isSeen != null ? isSeen.value : this.isSeen),
        type: (type != null ? type.value : this.type));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumThreadsResponse {
  const ForumThreadsResponse({
    this.threads,
    this.metadata,
  });

  factory ForumThreadsResponse.fromJson(Map<String, dynamic> json) => _$ForumThreadsResponseFromJson(json);

  static const toJsonFactory = _$ForumThreadsResponseToJson;
  Map<String, dynamic> toJson() => _$ForumThreadsResponseToJson(this);

  @JsonKey(name: 'threads', defaultValue: <ForumThreadBase>[])
  final List<ForumThreadBase>? threads;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$ForumThreadsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumThreadsResponse &&
            (identical(other.threads, threads) || const DeepCollectionEquality().equals(other.threads, threads)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(threads) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $ForumThreadsResponseExtension on ForumThreadsResponse {
  ForumThreadsResponse copyWith({List<ForumThreadBase>? threads, RequestMetadataWithLinks? metadata}) {
    return ForumThreadsResponse(threads: threads ?? this.threads, metadata: metadata ?? this.metadata);
  }

  ForumThreadsResponse copyWithWrapped(
      {Wrapped<List<ForumThreadBase>?>? threads, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return ForumThreadsResponse(
        threads: (threads != null ? threads.value : this.threads),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumThreadResponse {
  const ForumThreadResponse({
    this.thread,
  });

  factory ForumThreadResponse.fromJson(Map<String, dynamic> json) => _$ForumThreadResponseFromJson(json);

  static const toJsonFactory = _$ForumThreadResponseToJson;
  Map<String, dynamic> toJson() => _$ForumThreadResponseToJson(this);

  @JsonKey(name: 'thread')
  final ForumThreadExtended? thread;
  static const fromJsonFactory = _$ForumThreadResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumThreadResponse &&
            (identical(other.thread, thread) || const DeepCollectionEquality().equals(other.thread, thread)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(thread) ^ runtimeType.hashCode;
}

extension $ForumThreadResponseExtension on ForumThreadResponse {
  ForumThreadResponse copyWith({ForumThreadExtended? thread}) {
    return ForumThreadResponse(thread: thread ?? this.thread);
  }

  ForumThreadResponse copyWithWrapped({Wrapped<ForumThreadExtended?>? thread}) {
    return ForumThreadResponse(thread: (thread != null ? thread.value : this.thread));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumPostsResponse {
  const ForumPostsResponse({
    this.posts,
    this.metadata,
  });

  factory ForumPostsResponse.fromJson(Map<String, dynamic> json) => _$ForumPostsResponseFromJson(json);

  static const toJsonFactory = _$ForumPostsResponseToJson;
  Map<String, dynamic> toJson() => _$ForumPostsResponseToJson(this);

  @JsonKey(name: 'posts', defaultValue: <ForumPost>[])
  final List<ForumPost>? posts;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$ForumPostsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumPostsResponse &&
            (identical(other.posts, posts) || const DeepCollectionEquality().equals(other.posts, posts)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(posts) ^ const DeepCollectionEquality().hash(metadata) ^ runtimeType.hashCode;
}

extension $ForumPostsResponseExtension on ForumPostsResponse {
  ForumPostsResponse copyWith({List<ForumPost>? posts, RequestMetadataWithLinks? metadata}) {
    return ForumPostsResponse(posts: posts ?? this.posts, metadata: metadata ?? this.metadata);
  }

  ForumPostsResponse copyWithWrapped({Wrapped<List<ForumPost>?>? posts, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return ForumPostsResponse(
        posts: (posts != null ? posts.value : this.posts),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumLookupResponse {
  const ForumLookupResponse({
    this.selections,
  });

  factory ForumLookupResponse.fromJson(Map<String, dynamic> json) => _$ForumLookupResponseFromJson(json);

  static const toJsonFactory = _$ForumLookupResponseToJson;
  Map<String, dynamic> toJson() => _$ForumLookupResponseToJson(this);

  @JsonKey(
    name: 'selections',
    toJson: forumSelectionNameListToJson,
    fromJson: forumSelectionNameListFromJson,
  )
  final List<enums.ForumSelectionName>? selections;
  static const fromJsonFactory = _$ForumLookupResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumLookupResponse &&
            (identical(other.selections, selections) ||
                const DeepCollectionEquality().equals(other.selections, selections)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(selections) ^ runtimeType.hashCode;
}

extension $ForumLookupResponseExtension on ForumLookupResponse {
  ForumLookupResponse copyWith({List<enums.ForumSelectionName>? selections}) {
    return ForumLookupResponse(selections: selections ?? this.selections);
  }

  ForumLookupResponse copyWithWrapped({Wrapped<List<enums.ForumSelectionName>?>? selections}) {
    return ForumLookupResponse(selections: (selections != null ? selections.value : this.selections));
  }
}

@JsonSerializable(explicitToJson: true)
class ItemMarketListingItemBonus {
  const ItemMarketListingItemBonus({
    this.id,
    this.title,
    this.description,
  });

  factory ItemMarketListingItemBonus.fromJson(Map<String, dynamic> json) => _$ItemMarketListingItemBonusFromJson(json);

  static const toJsonFactory = _$ItemMarketListingItemBonusToJson;
  Map<String, dynamic> toJson() => _$ItemMarketListingItemBonusToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'description')
  final String? description;
  static const fromJsonFactory = _$ItemMarketListingItemBonusFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ItemMarketListingItemBonus &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(other.description, description)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(description) ^
      runtimeType.hashCode;
}

extension $ItemMarketListingItemBonusExtension on ItemMarketListingItemBonus {
  ItemMarketListingItemBonus copyWith({int? id, String? title, String? description}) {
    return ItemMarketListingItemBonus(
        id: id ?? this.id, title: title ?? this.title, description: description ?? this.description);
  }

  ItemMarketListingItemBonus copyWithWrapped(
      {Wrapped<int?>? id, Wrapped<String?>? title, Wrapped<String?>? description}) {
    return ItemMarketListingItemBonus(
        id: (id != null ? id.value : this.id),
        title: (title != null ? title.value : this.title),
        description: (description != null ? description.value : this.description));
  }
}

@JsonSerializable(explicitToJson: true)
class ItemMarketListingItemStats {
  const ItemMarketListingItemStats({
    this.damage,
    this.accuracy,
    this.armor,
  });

  factory ItemMarketListingItemStats.fromJson(Map<String, dynamic> json) => _$ItemMarketListingItemStatsFromJson(json);

  static const toJsonFactory = _$ItemMarketListingItemStatsToJson;
  Map<String, dynamic> toJson() => _$ItemMarketListingItemStatsToJson(this);

  @JsonKey(name: 'damage')
  final double? damage;
  @JsonKey(name: 'accuracy')
  final double? accuracy;
  @JsonKey(name: 'armor')
  final double? armor;
  static const fromJsonFactory = _$ItemMarketListingItemStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ItemMarketListingItemStats &&
            (identical(other.damage, damage) || const DeepCollectionEquality().equals(other.damage, damage)) &&
            (identical(other.accuracy, accuracy) || const DeepCollectionEquality().equals(other.accuracy, accuracy)) &&
            (identical(other.armor, armor) || const DeepCollectionEquality().equals(other.armor, armor)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(damage) ^
      const DeepCollectionEquality().hash(accuracy) ^
      const DeepCollectionEquality().hash(armor) ^
      runtimeType.hashCode;
}

extension $ItemMarketListingItemStatsExtension on ItemMarketListingItemStats {
  ItemMarketListingItemStats copyWith({double? damage, double? accuracy, double? armor}) {
    return ItemMarketListingItemStats(
        damage: damage ?? this.damage, accuracy: accuracy ?? this.accuracy, armor: armor ?? this.armor);
  }

  ItemMarketListingItemStats copyWithWrapped(
      {Wrapped<double?>? damage, Wrapped<double?>? accuracy, Wrapped<double?>? armor}) {
    return ItemMarketListingItemStats(
        damage: (damage != null ? damage.value : this.damage),
        accuracy: (accuracy != null ? accuracy.value : this.accuracy),
        armor: (armor != null ? armor.value : this.armor));
  }
}

@JsonSerializable(explicitToJson: true)
class ItemMarketItem {
  const ItemMarketItem({
    this.id,
    this.name,
    this.type,
    this.averagePrice,
  });

  factory ItemMarketItem.fromJson(Map<String, dynamic> json) => _$ItemMarketItemFromJson(json);

  static const toJsonFactory = _$ItemMarketItemToJson;
  Map<String, dynamic> toJson() => _$ItemMarketItemToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'type')
  final String? type;
  @JsonKey(name: 'average_price')
  final int? averagePrice;
  static const fromJsonFactory = _$ItemMarketItemFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ItemMarketItem &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.type, type) || const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.averagePrice, averagePrice) ||
                const DeepCollectionEquality().equals(other.averagePrice, averagePrice)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(averagePrice) ^
      runtimeType.hashCode;
}

extension $ItemMarketItemExtension on ItemMarketItem {
  ItemMarketItem copyWith({int? id, String? name, String? type, int? averagePrice}) {
    return ItemMarketItem(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        averagePrice: averagePrice ?? this.averagePrice);
  }

  ItemMarketItem copyWithWrapped(
      {Wrapped<int?>? id, Wrapped<String?>? name, Wrapped<String?>? type, Wrapped<int?>? averagePrice}) {
    return ItemMarketItem(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        type: (type != null ? type.value : this.type),
        averagePrice: (averagePrice != null ? averagePrice.value : this.averagePrice));
  }
}

@JsonSerializable(explicitToJson: true)
class ItemMarketListingStackable {
  const ItemMarketListingStackable({
    this.id,
    this.price,
    this.amount,
  });

  factory ItemMarketListingStackable.fromJson(Map<String, dynamic> json) => _$ItemMarketListingStackableFromJson(json);

  static const toJsonFactory = _$ItemMarketListingStackableToJson;
  Map<String, dynamic> toJson() => _$ItemMarketListingStackableToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'price')
  final int? price;
  @JsonKey(name: 'amount')
  final int? amount;
  static const fromJsonFactory = _$ItemMarketListingStackableFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ItemMarketListingStackable &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.price, price) || const DeepCollectionEquality().equals(other.price, price)) &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(price) ^
      const DeepCollectionEquality().hash(amount) ^
      runtimeType.hashCode;
}

extension $ItemMarketListingStackableExtension on ItemMarketListingStackable {
  ItemMarketListingStackable copyWith({int? id, int? price, int? amount}) {
    return ItemMarketListingStackable(id: id ?? this.id, price: price ?? this.price, amount: amount ?? this.amount);
  }

  ItemMarketListingStackable copyWithWrapped({Wrapped<int?>? id, Wrapped<int?>? price, Wrapped<int?>? amount}) {
    return ItemMarketListingStackable(
        id: (id != null ? id.value : this.id),
        price: (price != null ? price.value : this.price),
        amount: (amount != null ? amount.value : this.amount));
  }
}

@JsonSerializable(explicitToJson: true)
class ItemMarketListingItemDetails {
  const ItemMarketListingItemDetails({
    this.uid,
    this.stats,
    this.bonuses,
    this.rarity,
  });

  factory ItemMarketListingItemDetails.fromJson(Map<String, dynamic> json) =>
      _$ItemMarketListingItemDetailsFromJson(json);

  static const toJsonFactory = _$ItemMarketListingItemDetailsToJson;
  Map<String, dynamic> toJson() => _$ItemMarketListingItemDetailsToJson(this);

  @JsonKey(name: 'uid')
  final int? uid;
  @JsonKey(name: 'stats')
  final ItemMarketListingItemStats? stats;
  @JsonKey(name: 'bonuses', defaultValue: <ItemMarketListingItemBonus>[])
  final List<ItemMarketListingItemBonus>? bonuses;
  @JsonKey(
    name: 'rarity',
    toJson: itemMarketListingItemDetailsRarityNullableToJson,
    fromJson: itemMarketListingItemDetailsRarityNullableFromJson,
  )
  final enums.ItemMarketListingItemDetailsRarity? rarity;
  static const fromJsonFactory = _$ItemMarketListingItemDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ItemMarketListingItemDetails &&
            (identical(other.uid, uid) || const DeepCollectionEquality().equals(other.uid, uid)) &&
            (identical(other.stats, stats) || const DeepCollectionEquality().equals(other.stats, stats)) &&
            (identical(other.bonuses, bonuses) || const DeepCollectionEquality().equals(other.bonuses, bonuses)) &&
            (identical(other.rarity, rarity) || const DeepCollectionEquality().equals(other.rarity, rarity)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(uid) ^
      const DeepCollectionEquality().hash(stats) ^
      const DeepCollectionEquality().hash(bonuses) ^
      const DeepCollectionEquality().hash(rarity) ^
      runtimeType.hashCode;
}

extension $ItemMarketListingItemDetailsExtension on ItemMarketListingItemDetails {
  ItemMarketListingItemDetails copyWith(
      {int? uid,
      ItemMarketListingItemStats? stats,
      List<ItemMarketListingItemBonus>? bonuses,
      enums.ItemMarketListingItemDetailsRarity? rarity}) {
    return ItemMarketListingItemDetails(
        uid: uid ?? this.uid,
        stats: stats ?? this.stats,
        bonuses: bonuses ?? this.bonuses,
        rarity: rarity ?? this.rarity);
  }

  ItemMarketListingItemDetails copyWithWrapped(
      {Wrapped<int?>? uid,
      Wrapped<ItemMarketListingItemStats?>? stats,
      Wrapped<List<ItemMarketListingItemBonus>?>? bonuses,
      Wrapped<enums.ItemMarketListingItemDetailsRarity?>? rarity}) {
    return ItemMarketListingItemDetails(
        uid: (uid != null ? uid.value : this.uid),
        stats: (stats != null ? stats.value : this.stats),
        bonuses: (bonuses != null ? bonuses.value : this.bonuses),
        rarity: (rarity != null ? rarity.value : this.rarity));
  }
}

@JsonSerializable(explicitToJson: true)
class ItemMarketListingNonstackable {
  const ItemMarketListingNonstackable({
    this.id,
    this.price,
    this.amount,
    this.itemDetails,
  });

  factory ItemMarketListingNonstackable.fromJson(Map<String, dynamic> json) =>
      _$ItemMarketListingNonstackableFromJson(json);

  static const toJsonFactory = _$ItemMarketListingNonstackableToJson;
  Map<String, dynamic> toJson() => _$ItemMarketListingNonstackableToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'price')
  final int? price;
  @JsonKey(name: 'amount')
  final int? amount;
  @JsonKey(name: 'itemDetails')
  final ItemMarketListingItemDetails? itemDetails;
  static const fromJsonFactory = _$ItemMarketListingNonstackableFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ItemMarketListingNonstackable &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.price, price) || const DeepCollectionEquality().equals(other.price, price)) &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.itemDetails, itemDetails) ||
                const DeepCollectionEquality().equals(other.itemDetails, itemDetails)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(price) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(itemDetails) ^
      runtimeType.hashCode;
}

extension $ItemMarketListingNonstackableExtension on ItemMarketListingNonstackable {
  ItemMarketListingNonstackable copyWith(
      {int? id, int? price, int? amount, ItemMarketListingItemDetails? itemDetails}) {
    return ItemMarketListingNonstackable(
        id: id ?? this.id,
        price: price ?? this.price,
        amount: amount ?? this.amount,
        itemDetails: itemDetails ?? this.itemDetails);
  }

  ItemMarketListingNonstackable copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<int?>? price,
      Wrapped<int?>? amount,
      Wrapped<ItemMarketListingItemDetails?>? itemDetails}) {
    return ItemMarketListingNonstackable(
        id: (id != null ? id.value : this.id),
        price: (price != null ? price.value : this.price),
        amount: (amount != null ? amount.value : this.amount),
        itemDetails: (itemDetails != null ? itemDetails.value : this.itemDetails));
  }
}

@JsonSerializable(explicitToJson: true)
class ItemMarket {
  const ItemMarket({
    this.item,
    this.listings,
  });

  factory ItemMarket.fromJson(Map<String, dynamic> json) => _$ItemMarketFromJson(json);

  static const toJsonFactory = _$ItemMarketToJson;
  Map<String, dynamic> toJson() => _$ItemMarketToJson(this);

  @JsonKey(name: 'item')
  final ItemMarketItem? item;
  @JsonKey(name: 'listings', defaultValue: <Object>[])
  final List<Object>? listings;
  static const fromJsonFactory = _$ItemMarketFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ItemMarket &&
            (identical(other.item, item) || const DeepCollectionEquality().equals(other.item, item)) &&
            (identical(other.listings, listings) || const DeepCollectionEquality().equals(other.listings, listings)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(item) ^ const DeepCollectionEquality().hash(listings) ^ runtimeType.hashCode;
}

extension $ItemMarketExtension on ItemMarket {
  ItemMarket copyWith({ItemMarketItem? item, List<Object>? listings}) {
    return ItemMarket(item: item ?? this.item, listings: listings ?? this.listings);
  }

  ItemMarket copyWithWrapped({Wrapped<ItemMarketItem?>? item, Wrapped<List<Object>?>? listings}) {
    return ItemMarket(
        item: (item != null ? item.value : this.item), listings: (listings != null ? listings.value : this.listings));
  }
}

@JsonSerializable(explicitToJson: true)
class MarketItemMarketResponse {
  const MarketItemMarketResponse({
    this.itemmarket,
    this.metadata,
  });

  factory MarketItemMarketResponse.fromJson(Map<String, dynamic> json) => _$MarketItemMarketResponseFromJson(json);

  static const toJsonFactory = _$MarketItemMarketResponseToJson;
  Map<String, dynamic> toJson() => _$MarketItemMarketResponseToJson(this);

  @JsonKey(name: 'itemmarket')
  final ItemMarket? itemmarket;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$MarketItemMarketResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MarketItemMarketResponse &&
            (identical(other.itemmarket, itemmarket) ||
                const DeepCollectionEquality().equals(other.itemmarket, itemmarket)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(itemmarket) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $MarketItemMarketResponseExtension on MarketItemMarketResponse {
  MarketItemMarketResponse copyWith({ItemMarket? itemmarket, RequestMetadataWithLinks? metadata}) {
    return MarketItemMarketResponse(itemmarket: itemmarket ?? this.itemmarket, metadata: metadata ?? this.metadata);
  }

  MarketItemMarketResponse copyWithWrapped(
      {Wrapped<ItemMarket?>? itemmarket, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return MarketItemMarketResponse(
        itemmarket: (itemmarket != null ? itemmarket.value : this.itemmarket),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class MarketLookupResponse {
  const MarketLookupResponse({
    this.selections,
  });

  factory MarketLookupResponse.fromJson(Map<String, dynamic> json) => _$MarketLookupResponseFromJson(json);

  static const toJsonFactory = _$MarketLookupResponseToJson;
  Map<String, dynamic> toJson() => _$MarketLookupResponseToJson(this);

  @JsonKey(
    name: 'selections',
    toJson: marketSelectionNameListToJson,
    fromJson: marketSelectionNameListFromJson,
  )
  final List<enums.MarketSelectionName>? selections;
  static const fromJsonFactory = _$MarketLookupResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MarketLookupResponse &&
            (identical(other.selections, selections) ||
                const DeepCollectionEquality().equals(other.selections, selections)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(selections) ^ runtimeType.hashCode;
}

extension $MarketLookupResponseExtension on MarketLookupResponse {
  MarketLookupResponse copyWith({List<enums.MarketSelectionName>? selections}) {
    return MarketLookupResponse(selections: selections ?? this.selections);
  }

  MarketLookupResponse copyWithWrapped({Wrapped<List<enums.MarketSelectionName>?>? selections}) {
    return MarketLookupResponse(selections: (selections != null ? selections.value : this.selections));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingCarsResponse {
  const RacingCarsResponse({
    this.cars,
  });

  factory RacingCarsResponse.fromJson(Map<String, dynamic> json) => _$RacingCarsResponseFromJson(json);

  static const toJsonFactory = _$RacingCarsResponseToJson;
  Map<String, dynamic> toJson() => _$RacingCarsResponseToJson(this);

  @JsonKey(name: 'cars', defaultValue: <RaceCar>[])
  final List<RaceCar>? cars;
  static const fromJsonFactory = _$RacingCarsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingCarsResponse &&
            (identical(other.cars, cars) || const DeepCollectionEquality().equals(other.cars, cars)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(cars) ^ runtimeType.hashCode;
}

extension $RacingCarsResponseExtension on RacingCarsResponse {
  RacingCarsResponse copyWith({List<RaceCar>? cars}) {
    return RacingCarsResponse(cars: cars ?? this.cars);
  }

  RacingCarsResponse copyWithWrapped({Wrapped<List<RaceCar>?>? cars}) {
    return RacingCarsResponse(cars: (cars != null ? cars.value : this.cars));
  }
}

@JsonSerializable(explicitToJson: true)
class RaceCar {
  const RaceCar({
    this.carItemId,
    this.carItemName,
    this.topSpeed,
    this.acceleration,
    this.braking,
    this.dirt,
    this.handling,
    this.safety,
    this.tarmac,
    this.$class,
  });

  factory RaceCar.fromJson(Map<String, dynamic> json) => _$RaceCarFromJson(json);

  static const toJsonFactory = _$RaceCarToJson;
  Map<String, dynamic> toJson() => _$RaceCarToJson(this);

  @JsonKey(name: 'car_item_id')
  final int? carItemId;
  @JsonKey(name: 'car_item_name')
  final String? carItemName;
  @JsonKey(name: 'top_speed')
  final int? topSpeed;
  @JsonKey(name: 'acceleration')
  final int? acceleration;
  @JsonKey(name: 'braking')
  final int? braking;
  @JsonKey(name: 'dirt')
  final int? dirt;
  @JsonKey(name: 'handling')
  final int? handling;
  @JsonKey(name: 'safety')
  final int? safety;
  @JsonKey(name: 'tarmac')
  final int? tarmac;
  @JsonKey(
    name: 'class',
    toJson: raceClassEnumNullableToJson,
    fromJson: raceClassEnumNullableFromJson,
  )
  final enums.RaceClassEnum? $class;
  static const fromJsonFactory = _$RaceCarFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RaceCar &&
            (identical(other.carItemId, carItemId) ||
                const DeepCollectionEquality().equals(other.carItemId, carItemId)) &&
            (identical(other.carItemName, carItemName) ||
                const DeepCollectionEquality().equals(other.carItemName, carItemName)) &&
            (identical(other.topSpeed, topSpeed) || const DeepCollectionEquality().equals(other.topSpeed, topSpeed)) &&
            (identical(other.acceleration, acceleration) ||
                const DeepCollectionEquality().equals(other.acceleration, acceleration)) &&
            (identical(other.braking, braking) || const DeepCollectionEquality().equals(other.braking, braking)) &&
            (identical(other.dirt, dirt) || const DeepCollectionEquality().equals(other.dirt, dirt)) &&
            (identical(other.handling, handling) || const DeepCollectionEquality().equals(other.handling, handling)) &&
            (identical(other.safety, safety) || const DeepCollectionEquality().equals(other.safety, safety)) &&
            (identical(other.tarmac, tarmac) || const DeepCollectionEquality().equals(other.tarmac, tarmac)) &&
            (identical(other.$class, $class) || const DeepCollectionEquality().equals(other.$class, $class)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(carItemId) ^
      const DeepCollectionEquality().hash(carItemName) ^
      const DeepCollectionEquality().hash(topSpeed) ^
      const DeepCollectionEquality().hash(acceleration) ^
      const DeepCollectionEquality().hash(braking) ^
      const DeepCollectionEquality().hash(dirt) ^
      const DeepCollectionEquality().hash(handling) ^
      const DeepCollectionEquality().hash(safety) ^
      const DeepCollectionEquality().hash(tarmac) ^
      const DeepCollectionEquality().hash($class) ^
      runtimeType.hashCode;
}

extension $RaceCarExtension on RaceCar {
  RaceCar copyWith(
      {int? carItemId,
      String? carItemName,
      int? topSpeed,
      int? acceleration,
      int? braking,
      int? dirt,
      int? handling,
      int? safety,
      int? tarmac,
      enums.RaceClassEnum? $class}) {
    return RaceCar(
        carItemId: carItemId ?? this.carItemId,
        carItemName: carItemName ?? this.carItemName,
        topSpeed: topSpeed ?? this.topSpeed,
        acceleration: acceleration ?? this.acceleration,
        braking: braking ?? this.braking,
        dirt: dirt ?? this.dirt,
        handling: handling ?? this.handling,
        safety: safety ?? this.safety,
        tarmac: tarmac ?? this.tarmac,
        $class: $class ?? this.$class);
  }

  RaceCar copyWithWrapped(
      {Wrapped<int?>? carItemId,
      Wrapped<String?>? carItemName,
      Wrapped<int?>? topSpeed,
      Wrapped<int?>? acceleration,
      Wrapped<int?>? braking,
      Wrapped<int?>? dirt,
      Wrapped<int?>? handling,
      Wrapped<int?>? safety,
      Wrapped<int?>? tarmac,
      Wrapped<enums.RaceClassEnum?>? $class}) {
    return RaceCar(
        carItemId: (carItemId != null ? carItemId.value : this.carItemId),
        carItemName: (carItemName != null ? carItemName.value : this.carItemName),
        topSpeed: (topSpeed != null ? topSpeed.value : this.topSpeed),
        acceleration: (acceleration != null ? acceleration.value : this.acceleration),
        braking: (braking != null ? braking.value : this.braking),
        dirt: (dirt != null ? dirt.value : this.dirt),
        handling: (handling != null ? handling.value : this.handling),
        safety: (safety != null ? safety.value : this.safety),
        tarmac: (tarmac != null ? tarmac.value : this.tarmac),
        $class: ($class != null ? $class.value : this.$class));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingTracksResponse {
  const RacingTracksResponse({
    this.tracks,
  });

  factory RacingTracksResponse.fromJson(Map<String, dynamic> json) => _$RacingTracksResponseFromJson(json);

  static const toJsonFactory = _$RacingTracksResponseToJson;
  Map<String, dynamic> toJson() => _$RacingTracksResponseToJson(this);

  @JsonKey(name: 'tracks', defaultValue: <RaceTrack>[])
  final List<RaceTrack>? tracks;
  static const fromJsonFactory = _$RacingTracksResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingTracksResponse &&
            (identical(other.tracks, tracks) || const DeepCollectionEquality().equals(other.tracks, tracks)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(tracks) ^ runtimeType.hashCode;
}

extension $RacingTracksResponseExtension on RacingTracksResponse {
  RacingTracksResponse copyWith({List<RaceTrack>? tracks}) {
    return RacingTracksResponse(tracks: tracks ?? this.tracks);
  }

  RacingTracksResponse copyWithWrapped({Wrapped<List<RaceTrack>?>? tracks}) {
    return RacingTracksResponse(tracks: (tracks != null ? tracks.value : this.tracks));
  }
}

@JsonSerializable(explicitToJson: true)
class RaceTrack {
  const RaceTrack({
    this.id,
    this.title,
    this.description,
  });

  factory RaceTrack.fromJson(Map<String, dynamic> json) => _$RaceTrackFromJson(json);

  static const toJsonFactory = _$RaceTrackToJson;
  Map<String, dynamic> toJson() => _$RaceTrackToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'description')
  final String? description;
  static const fromJsonFactory = _$RaceTrackFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RaceTrack &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(other.description, description)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(description) ^
      runtimeType.hashCode;
}

extension $RaceTrackExtension on RaceTrack {
  RaceTrack copyWith({int? id, String? title, String? description}) {
    return RaceTrack(id: id ?? this.id, title: title ?? this.title, description: description ?? this.description);
  }

  RaceTrack copyWithWrapped({Wrapped<int?>? id, Wrapped<String?>? title, Wrapped<String?>? description}) {
    return RaceTrack(
        id: (id != null ? id.value : this.id),
        title: (title != null ? title.value : this.title),
        description: (description != null ? description.value : this.description));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingCarUpgradesResponse {
  const RacingCarUpgradesResponse({
    this.carupgrades,
  });

  factory RacingCarUpgradesResponse.fromJson(Map<String, dynamic> json) => _$RacingCarUpgradesResponseFromJson(json);

  static const toJsonFactory = _$RacingCarUpgradesResponseToJson;
  Map<String, dynamic> toJson() => _$RacingCarUpgradesResponseToJson(this);

  @JsonKey(name: 'carupgrades', defaultValue: <RaceCarUpgrade>[])
  final List<RaceCarUpgrade>? carupgrades;
  static const fromJsonFactory = _$RacingCarUpgradesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingCarUpgradesResponse &&
            (identical(other.carupgrades, carupgrades) ||
                const DeepCollectionEquality().equals(other.carupgrades, carupgrades)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(carupgrades) ^ runtimeType.hashCode;
}

extension $RacingCarUpgradesResponseExtension on RacingCarUpgradesResponse {
  RacingCarUpgradesResponse copyWith({List<RaceCarUpgrade>? carupgrades}) {
    return RacingCarUpgradesResponse(carupgrades: carupgrades ?? this.carupgrades);
  }

  RacingCarUpgradesResponse copyWithWrapped({Wrapped<List<RaceCarUpgrade>?>? carupgrades}) {
    return RacingCarUpgradesResponse(carupgrades: (carupgrades != null ? carupgrades.value : this.carupgrades));
  }
}

@JsonSerializable(explicitToJson: true)
class RaceCarUpgrade {
  const RaceCarUpgrade({
    this.id,
    this.classRequired,
    this.name,
    this.description,
    this.category,
    this.subcategory,
    this.effects,
    this.cost,
  });

  factory RaceCarUpgrade.fromJson(Map<String, dynamic> json) => _$RaceCarUpgradeFromJson(json);

  static const toJsonFactory = _$RaceCarUpgradeToJson;
  Map<String, dynamic> toJson() => _$RaceCarUpgradeToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(
    name: 'class_required',
    toJson: raceClassEnumNullableToJson,
    fromJson: raceClassEnumNullableFromJson,
  )
  final enums.RaceClassEnum? classRequired;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'description')
  final String? description;
  @JsonKey(
    name: 'category',
    toJson: raceCarUpgradeCategoryNullableToJson,
    fromJson: raceCarUpgradeCategoryNullableFromJson,
  )
  final enums.RaceCarUpgradeCategory? category;
  @JsonKey(
    name: 'subcategory',
    toJson: raceCarUpgradeSubCategoryNullableToJson,
    fromJson: raceCarUpgradeSubCategoryNullableFromJson,
  )
  final enums.RaceCarUpgradeSubCategory? subcategory;
  @JsonKey(name: 'effects')
  final RaceCarUpgrade$Effects? effects;
  @JsonKey(name: 'cost')
  final RaceCarUpgrade$Cost? cost;
  static const fromJsonFactory = _$RaceCarUpgradeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RaceCarUpgrade &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.classRequired, classRequired) ||
                const DeepCollectionEquality().equals(other.classRequired, classRequired)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(other.description, description)) &&
            (identical(other.category, category) || const DeepCollectionEquality().equals(other.category, category)) &&
            (identical(other.subcategory, subcategory) ||
                const DeepCollectionEquality().equals(other.subcategory, subcategory)) &&
            (identical(other.effects, effects) || const DeepCollectionEquality().equals(other.effects, effects)) &&
            (identical(other.cost, cost) || const DeepCollectionEquality().equals(other.cost, cost)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(classRequired) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(description) ^
      const DeepCollectionEquality().hash(category) ^
      const DeepCollectionEquality().hash(subcategory) ^
      const DeepCollectionEquality().hash(effects) ^
      const DeepCollectionEquality().hash(cost) ^
      runtimeType.hashCode;
}

extension $RaceCarUpgradeExtension on RaceCarUpgrade {
  RaceCarUpgrade copyWith(
      {int? id,
      enums.RaceClassEnum? classRequired,
      String? name,
      String? description,
      enums.RaceCarUpgradeCategory? category,
      enums.RaceCarUpgradeSubCategory? subcategory,
      RaceCarUpgrade$Effects? effects,
      RaceCarUpgrade$Cost? cost}) {
    return RaceCarUpgrade(
        id: id ?? this.id,
        classRequired: classRequired ?? this.classRequired,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        subcategory: subcategory ?? this.subcategory,
        effects: effects ?? this.effects,
        cost: cost ?? this.cost);
  }

  RaceCarUpgrade copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<enums.RaceClassEnum?>? classRequired,
      Wrapped<String?>? name,
      Wrapped<String?>? description,
      Wrapped<enums.RaceCarUpgradeCategory?>? category,
      Wrapped<enums.RaceCarUpgradeSubCategory?>? subcategory,
      Wrapped<RaceCarUpgrade$Effects?>? effects,
      Wrapped<RaceCarUpgrade$Cost?>? cost}) {
    return RaceCarUpgrade(
        id: (id != null ? id.value : this.id),
        classRequired: (classRequired != null ? classRequired.value : this.classRequired),
        name: (name != null ? name.value : this.name),
        description: (description != null ? description.value : this.description),
        category: (category != null ? category.value : this.category),
        subcategory: (subcategory != null ? subcategory.value : this.subcategory),
        effects: (effects != null ? effects.value : this.effects),
        cost: (cost != null ? cost.value : this.cost));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingRacesResponse {
  const RacingRacesResponse({
    this.races,
    this.metadata,
  });

  factory RacingRacesResponse.fromJson(Map<String, dynamic> json) => _$RacingRacesResponseFromJson(json);

  static const toJsonFactory = _$RacingRacesResponseToJson;
  Map<String, dynamic> toJson() => _$RacingRacesResponseToJson(this);

  @JsonKey(name: 'races', defaultValue: <Race>[])
  final List<Race>? races;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$RacingRacesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingRacesResponse &&
            (identical(other.races, races) || const DeepCollectionEquality().equals(other.races, races)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(races) ^ const DeepCollectionEquality().hash(metadata) ^ runtimeType.hashCode;
}

extension $RacingRacesResponseExtension on RacingRacesResponse {
  RacingRacesResponse copyWith({List<Race>? races, RequestMetadataWithLinks? metadata}) {
    return RacingRacesResponse(races: races ?? this.races, metadata: metadata ?? this.metadata);
  }

  RacingRacesResponse copyWithWrapped({Wrapped<List<Race>?>? races, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return RacingRacesResponse(
        races: (races != null ? races.value : this.races),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class Race {
  const Race({
    this.id,
    this.title,
    this.trackId,
    this.creatorId,
    this.status,
    this.laps,
    this.participants,
    this.schedule,
    this.requirements,
  });

  factory Race.fromJson(Map<String, dynamic> json) => _$RaceFromJson(json);

  static const toJsonFactory = _$RaceToJson;
  Map<String, dynamic> toJson() => _$RaceToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'track_id')
  final int? trackId;
  @JsonKey(name: 'creator_id')
  final int? creatorId;
  @JsonKey(
    name: 'status',
    toJson: raceStatusEnumNullableToJson,
    fromJson: raceStatusEnumNullableFromJson,
  )
  final enums.RaceStatusEnum? status;
  @JsonKey(name: 'laps')
  final int? laps;
  @JsonKey(name: 'participants')
  final Race$Participants? participants;
  @JsonKey(name: 'schedule')
  final Race$Schedule? schedule;
  @JsonKey(name: 'requirements')
  final Race$Requirements? requirements;
  static const fromJsonFactory = _$RaceFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Race &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.trackId, trackId) || const DeepCollectionEquality().equals(other.trackId, trackId)) &&
            (identical(other.creatorId, creatorId) ||
                const DeepCollectionEquality().equals(other.creatorId, creatorId)) &&
            (identical(other.status, status) || const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.laps, laps) || const DeepCollectionEquality().equals(other.laps, laps)) &&
            (identical(other.participants, participants) ||
                const DeepCollectionEquality().equals(other.participants, participants)) &&
            (identical(other.schedule, schedule) || const DeepCollectionEquality().equals(other.schedule, schedule)) &&
            (identical(other.requirements, requirements) ||
                const DeepCollectionEquality().equals(other.requirements, requirements)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(trackId) ^
      const DeepCollectionEquality().hash(creatorId) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(laps) ^
      const DeepCollectionEquality().hash(participants) ^
      const DeepCollectionEquality().hash(schedule) ^
      const DeepCollectionEquality().hash(requirements) ^
      runtimeType.hashCode;
}

extension $RaceExtension on Race {
  Race copyWith(
      {int? id,
      String? title,
      int? trackId,
      int? creatorId,
      enums.RaceStatusEnum? status,
      int? laps,
      Race$Participants? participants,
      Race$Schedule? schedule,
      Race$Requirements? requirements}) {
    return Race(
        id: id ?? this.id,
        title: title ?? this.title,
        trackId: trackId ?? this.trackId,
        creatorId: creatorId ?? this.creatorId,
        status: status ?? this.status,
        laps: laps ?? this.laps,
        participants: participants ?? this.participants,
        schedule: schedule ?? this.schedule,
        requirements: requirements ?? this.requirements);
  }

  Race copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? title,
      Wrapped<int?>? trackId,
      Wrapped<int?>? creatorId,
      Wrapped<enums.RaceStatusEnum?>? status,
      Wrapped<int?>? laps,
      Wrapped<Race$Participants?>? participants,
      Wrapped<Race$Schedule?>? schedule,
      Wrapped<Race$Requirements?>? requirements}) {
    return Race(
        id: (id != null ? id.value : this.id),
        title: (title != null ? title.value : this.title),
        trackId: (trackId != null ? trackId.value : this.trackId),
        creatorId: (creatorId != null ? creatorId.value : this.creatorId),
        status: (status != null ? status.value : this.status),
        laps: (laps != null ? laps.value : this.laps),
        participants: (participants != null ? participants.value : this.participants),
        schedule: (schedule != null ? schedule.value : this.schedule),
        requirements: (requirements != null ? requirements.value : this.requirements));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingTrackRecordsResponse {
  const RacingTrackRecordsResponse({
    this.records,
  });

  factory RacingTrackRecordsResponse.fromJson(Map<String, dynamic> json) => _$RacingTrackRecordsResponseFromJson(json);

  static const toJsonFactory = _$RacingTrackRecordsResponseToJson;
  Map<String, dynamic> toJson() => _$RacingTrackRecordsResponseToJson(this);

  @JsonKey(name: 'records', defaultValue: <RaceRecord>[])
  final List<RaceRecord>? records;
  static const fromJsonFactory = _$RacingTrackRecordsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingTrackRecordsResponse &&
            (identical(other.records, records) || const DeepCollectionEquality().equals(other.records, records)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(records) ^ runtimeType.hashCode;
}

extension $RacingTrackRecordsResponseExtension on RacingTrackRecordsResponse {
  RacingTrackRecordsResponse copyWith({List<RaceRecord>? records}) {
    return RacingTrackRecordsResponse(records: records ?? this.records);
  }

  RacingTrackRecordsResponse copyWithWrapped({Wrapped<List<RaceRecord>?>? records}) {
    return RacingTrackRecordsResponse(records: (records != null ? records.value : this.records));
  }
}

@JsonSerializable(explicitToJson: true)
class RaceRecord {
  const RaceRecord({
    this.driverId,
    this.driverName,
    this.carItemId,
    this.lapTime,
    this.carItemName,
  });

  factory RaceRecord.fromJson(Map<String, dynamic> json) => _$RaceRecordFromJson(json);

  static const toJsonFactory = _$RaceRecordToJson;
  Map<String, dynamic> toJson() => _$RaceRecordToJson(this);

  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'driver_name')
  final String? driverName;
  @JsonKey(name: 'car_item_id')
  final int? carItemId;
  @JsonKey(name: 'lap_time')
  final int? lapTime;
  @JsonKey(name: 'car_item_name')
  final String? carItemName;
  static const fromJsonFactory = _$RaceRecordFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RaceRecord &&
            (identical(other.driverId, driverId) || const DeepCollectionEquality().equals(other.driverId, driverId)) &&
            (identical(other.driverName, driverName) ||
                const DeepCollectionEquality().equals(other.driverName, driverName)) &&
            (identical(other.carItemId, carItemId) ||
                const DeepCollectionEquality().equals(other.carItemId, carItemId)) &&
            (identical(other.lapTime, lapTime) || const DeepCollectionEquality().equals(other.lapTime, lapTime)) &&
            (identical(other.carItemName, carItemName) ||
                const DeepCollectionEquality().equals(other.carItemName, carItemName)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(driverId) ^
      const DeepCollectionEquality().hash(driverName) ^
      const DeepCollectionEquality().hash(carItemId) ^
      const DeepCollectionEquality().hash(lapTime) ^
      const DeepCollectionEquality().hash(carItemName) ^
      runtimeType.hashCode;
}

extension $RaceRecordExtension on RaceRecord {
  RaceRecord copyWith({int? driverId, String? driverName, int? carItemId, int? lapTime, String? carItemName}) {
    return RaceRecord(
        driverId: driverId ?? this.driverId,
        driverName: driverName ?? this.driverName,
        carItemId: carItemId ?? this.carItemId,
        lapTime: lapTime ?? this.lapTime,
        carItemName: carItemName ?? this.carItemName);
  }

  RaceRecord copyWithWrapped(
      {Wrapped<int?>? driverId,
      Wrapped<String?>? driverName,
      Wrapped<int?>? carItemId,
      Wrapped<int?>? lapTime,
      Wrapped<String?>? carItemName}) {
    return RaceRecord(
        driverId: (driverId != null ? driverId.value : this.driverId),
        driverName: (driverName != null ? driverName.value : this.driverName),
        carItemId: (carItemId != null ? carItemId.value : this.carItemId),
        lapTime: (lapTime != null ? lapTime.value : this.lapTime),
        carItemName: (carItemName != null ? carItemName.value : this.carItemName));
  }
}

@JsonSerializable(explicitToJson: true)
class RacerDetails {
  const RacerDetails({
    this.driverId,
    this.position,
    this.carId,
    this.carItemId,
    this.carItemName,
    this.carClass,
    this.hasCrashed,
    this.bestLapTime,
    this.raceTime,
    this.timeEnded,
  });

  factory RacerDetails.fromJson(Map<String, dynamic> json) => _$RacerDetailsFromJson(json);

  static const toJsonFactory = _$RacerDetailsToJson;
  Map<String, dynamic> toJson() => _$RacerDetailsToJson(this);

  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'position')
  final int? position;
  @JsonKey(name: 'car_id')
  final int? carId;
  @JsonKey(name: 'car_item_id')
  final int? carItemId;
  @JsonKey(name: 'car_item_name')
  final String? carItemName;
  @JsonKey(
    name: 'car_class',
    toJson: raceClassEnumNullableToJson,
    fromJson: raceClassEnumNullableFromJson,
  )
  final enums.RaceClassEnum? carClass;
  @JsonKey(name: 'has_crashed')
  final bool? hasCrashed;
  @JsonKey(name: 'best_lap_time')
  final double? bestLapTime;
  @JsonKey(name: 'race_time')
  final double? raceTime;
  @JsonKey(name: 'time_ended')
  final int? timeEnded;
  static const fromJsonFactory = _$RacerDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacerDetails &&
            (identical(other.driverId, driverId) || const DeepCollectionEquality().equals(other.driverId, driverId)) &&
            (identical(other.position, position) || const DeepCollectionEquality().equals(other.position, position)) &&
            (identical(other.carId, carId) || const DeepCollectionEquality().equals(other.carId, carId)) &&
            (identical(other.carItemId, carItemId) ||
                const DeepCollectionEquality().equals(other.carItemId, carItemId)) &&
            (identical(other.carItemName, carItemName) ||
                const DeepCollectionEquality().equals(other.carItemName, carItemName)) &&
            (identical(other.carClass, carClass) || const DeepCollectionEquality().equals(other.carClass, carClass)) &&
            (identical(other.hasCrashed, hasCrashed) ||
                const DeepCollectionEquality().equals(other.hasCrashed, hasCrashed)) &&
            (identical(other.bestLapTime, bestLapTime) ||
                const DeepCollectionEquality().equals(other.bestLapTime, bestLapTime)) &&
            (identical(other.raceTime, raceTime) || const DeepCollectionEquality().equals(other.raceTime, raceTime)) &&
            (identical(other.timeEnded, timeEnded) ||
                const DeepCollectionEquality().equals(other.timeEnded, timeEnded)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(driverId) ^
      const DeepCollectionEquality().hash(position) ^
      const DeepCollectionEquality().hash(carId) ^
      const DeepCollectionEquality().hash(carItemId) ^
      const DeepCollectionEquality().hash(carItemName) ^
      const DeepCollectionEquality().hash(carClass) ^
      const DeepCollectionEquality().hash(hasCrashed) ^
      const DeepCollectionEquality().hash(bestLapTime) ^
      const DeepCollectionEquality().hash(raceTime) ^
      const DeepCollectionEquality().hash(timeEnded) ^
      runtimeType.hashCode;
}

extension $RacerDetailsExtension on RacerDetails {
  RacerDetails copyWith(
      {int? driverId,
      int? position,
      int? carId,
      int? carItemId,
      String? carItemName,
      enums.RaceClassEnum? carClass,
      bool? hasCrashed,
      double? bestLapTime,
      double? raceTime,
      int? timeEnded}) {
    return RacerDetails(
        driverId: driverId ?? this.driverId,
        position: position ?? this.position,
        carId: carId ?? this.carId,
        carItemId: carItemId ?? this.carItemId,
        carItemName: carItemName ?? this.carItemName,
        carClass: carClass ?? this.carClass,
        hasCrashed: hasCrashed ?? this.hasCrashed,
        bestLapTime: bestLapTime ?? this.bestLapTime,
        raceTime: raceTime ?? this.raceTime,
        timeEnded: timeEnded ?? this.timeEnded);
  }

  RacerDetails copyWithWrapped(
      {Wrapped<int?>? driverId,
      Wrapped<int?>? position,
      Wrapped<int?>? carId,
      Wrapped<int?>? carItemId,
      Wrapped<String?>? carItemName,
      Wrapped<enums.RaceClassEnum?>? carClass,
      Wrapped<bool?>? hasCrashed,
      Wrapped<double?>? bestLapTime,
      Wrapped<double?>? raceTime,
      Wrapped<int?>? timeEnded}) {
    return RacerDetails(
        driverId: (driverId != null ? driverId.value : this.driverId),
        position: (position != null ? position.value : this.position),
        carId: (carId != null ? carId.value : this.carId),
        carItemId: (carItemId != null ? carItemId.value : this.carItemId),
        carItemName: (carItemName != null ? carItemName.value : this.carItemName),
        carClass: (carClass != null ? carClass.value : this.carClass),
        hasCrashed: (hasCrashed != null ? hasCrashed.value : this.hasCrashed),
        bestLapTime: (bestLapTime != null ? bestLapTime.value : this.bestLapTime),
        raceTime: (raceTime != null ? raceTime.value : this.raceTime),
        timeEnded: (timeEnded != null ? timeEnded.value : this.timeEnded));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingRaceDetailsResponse {
  const RacingRaceDetailsResponse({
    this.results,
    this.id,
    this.title,
    this.trackId,
    this.creatorId,
    this.status,
    this.laps,
    this.participants,
    this.schedule,
    this.requirements,
  });

  factory RacingRaceDetailsResponse.fromJson(Map<String, dynamic> json) => _$RacingRaceDetailsResponseFromJson(json);

  static const toJsonFactory = _$RacingRaceDetailsResponseToJson;
  Map<String, dynamic> toJson() => _$RacingRaceDetailsResponseToJson(this);

  @JsonKey(name: 'results', defaultValue: <RacerDetails>[])
  final List<RacerDetails>? results;
  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'track_id')
  final int? trackId;
  @JsonKey(name: 'creator_id')
  final int? creatorId;
  @JsonKey(
    name: 'status',
    toJson: raceStatusEnumNullableToJson,
    fromJson: raceStatusEnumNullableFromJson,
  )
  final enums.RaceStatusEnum? status;
  @JsonKey(name: 'laps')
  final int? laps;
  @JsonKey(name: 'participants')
  final RacingRaceDetailsResponse$Participants? participants;
  @JsonKey(name: 'schedule')
  final RacingRaceDetailsResponse$Schedule? schedule;
  @JsonKey(name: 'requirements')
  final RacingRaceDetailsResponse$Requirements? requirements;
  static const fromJsonFactory = _$RacingRaceDetailsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingRaceDetailsResponse &&
            (identical(other.results, results) || const DeepCollectionEquality().equals(other.results, results)) &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.trackId, trackId) || const DeepCollectionEquality().equals(other.trackId, trackId)) &&
            (identical(other.creatorId, creatorId) ||
                const DeepCollectionEquality().equals(other.creatorId, creatorId)) &&
            (identical(other.status, status) || const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.laps, laps) || const DeepCollectionEquality().equals(other.laps, laps)) &&
            (identical(other.participants, participants) ||
                const DeepCollectionEquality().equals(other.participants, participants)) &&
            (identical(other.schedule, schedule) || const DeepCollectionEquality().equals(other.schedule, schedule)) &&
            (identical(other.requirements, requirements) ||
                const DeepCollectionEquality().equals(other.requirements, requirements)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(results) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(trackId) ^
      const DeepCollectionEquality().hash(creatorId) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(laps) ^
      const DeepCollectionEquality().hash(participants) ^
      const DeepCollectionEquality().hash(schedule) ^
      const DeepCollectionEquality().hash(requirements) ^
      runtimeType.hashCode;
}

extension $RacingRaceDetailsResponseExtension on RacingRaceDetailsResponse {
  RacingRaceDetailsResponse copyWith(
      {List<RacerDetails>? results,
      int? id,
      String? title,
      int? trackId,
      int? creatorId,
      enums.RaceStatusEnum? status,
      int? laps,
      RacingRaceDetailsResponse$Participants? participants,
      RacingRaceDetailsResponse$Schedule? schedule,
      RacingRaceDetailsResponse$Requirements? requirements}) {
    return RacingRaceDetailsResponse(
        results: results ?? this.results,
        id: id ?? this.id,
        title: title ?? this.title,
        trackId: trackId ?? this.trackId,
        creatorId: creatorId ?? this.creatorId,
        status: status ?? this.status,
        laps: laps ?? this.laps,
        participants: participants ?? this.participants,
        schedule: schedule ?? this.schedule,
        requirements: requirements ?? this.requirements);
  }

  RacingRaceDetailsResponse copyWithWrapped(
      {Wrapped<List<RacerDetails>?>? results,
      Wrapped<int?>? id,
      Wrapped<String?>? title,
      Wrapped<int?>? trackId,
      Wrapped<int?>? creatorId,
      Wrapped<enums.RaceStatusEnum?>? status,
      Wrapped<int?>? laps,
      Wrapped<RacingRaceDetailsResponse$Participants?>? participants,
      Wrapped<RacingRaceDetailsResponse$Schedule?>? schedule,
      Wrapped<RacingRaceDetailsResponse$Requirements?>? requirements}) {
    return RacingRaceDetailsResponse(
        results: (results != null ? results.value : this.results),
        id: (id != null ? id.value : this.id),
        title: (title != null ? title.value : this.title),
        trackId: (trackId != null ? trackId.value : this.trackId),
        creatorId: (creatorId != null ? creatorId.value : this.creatorId),
        status: (status != null ? status.value : this.status),
        laps: (laps != null ? laps.value : this.laps),
        participants: (participants != null ? participants.value : this.participants),
        schedule: (schedule != null ? schedule.value : this.schedule),
        requirements: (requirements != null ? requirements.value : this.requirements));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingLookupResponse {
  const RacingLookupResponse({
    this.selections,
  });

  factory RacingLookupResponse.fromJson(Map<String, dynamic> json) => _$RacingLookupResponseFromJson(json);

  static const toJsonFactory = _$RacingLookupResponseToJson;
  Map<String, dynamic> toJson() => _$RacingLookupResponseToJson(this);

  @JsonKey(
    name: 'selections',
    toJson: racingSelectionNameListToJson,
    fromJson: racingSelectionNameListFromJson,
  )
  final List<enums.RacingSelectionName>? selections;
  static const fromJsonFactory = _$RacingLookupResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingLookupResponse &&
            (identical(other.selections, selections) ||
                const DeepCollectionEquality().equals(other.selections, selections)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(selections) ^ runtimeType.hashCode;
}

extension $RacingLookupResponseExtension on RacingLookupResponse {
  RacingLookupResponse copyWith({List<enums.RacingSelectionName>? selections}) {
    return RacingLookupResponse(selections: selections ?? this.selections);
  }

  RacingLookupResponse copyWithWrapped({Wrapped<List<enums.RacingSelectionName>?>? selections}) {
    return RacingLookupResponse(selections: (selections != null ? selections.value : this.selections));
  }
}

@JsonSerializable(explicitToJson: true)
class TornSubcrimesResponse {
  const TornSubcrimesResponse({
    this.subcrimes,
  });

  factory TornSubcrimesResponse.fromJson(Map<String, dynamic> json) => _$TornSubcrimesResponseFromJson(json);

  static const toJsonFactory = _$TornSubcrimesResponseToJson;
  Map<String, dynamic> toJson() => _$TornSubcrimesResponseToJson(this);

  @JsonKey(name: 'subcrimes', defaultValue: <TornSubcrime>[])
  final List<TornSubcrime>? subcrimes;
  static const fromJsonFactory = _$TornSubcrimesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornSubcrimesResponse &&
            (identical(other.subcrimes, subcrimes) ||
                const DeepCollectionEquality().equals(other.subcrimes, subcrimes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(subcrimes) ^ runtimeType.hashCode;
}

extension $TornSubcrimesResponseExtension on TornSubcrimesResponse {
  TornSubcrimesResponse copyWith({List<TornSubcrime>? subcrimes}) {
    return TornSubcrimesResponse(subcrimes: subcrimes ?? this.subcrimes);
  }

  TornSubcrimesResponse copyWithWrapped({Wrapped<List<TornSubcrime>?>? subcrimes}) {
    return TornSubcrimesResponse(subcrimes: (subcrimes != null ? subcrimes.value : this.subcrimes));
  }
}

@JsonSerializable(explicitToJson: true)
class TornSubcrime {
  const TornSubcrime({
    this.id,
    this.name,
    this.nerveCost,
  });

  factory TornSubcrime.fromJson(Map<String, dynamic> json) => _$TornSubcrimeFromJson(json);

  static const toJsonFactory = _$TornSubcrimeToJson;
  Map<String, dynamic> toJson() => _$TornSubcrimeToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'nerve_cost')
  final int? nerveCost;
  static const fromJsonFactory = _$TornSubcrimeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornSubcrime &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.nerveCost, nerveCost) ||
                const DeepCollectionEquality().equals(other.nerveCost, nerveCost)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(nerveCost) ^
      runtimeType.hashCode;
}

extension $TornSubcrimeExtension on TornSubcrime {
  TornSubcrime copyWith({int? id, String? name, int? nerveCost}) {
    return TornSubcrime(id: id ?? this.id, name: name ?? this.name, nerveCost: nerveCost ?? this.nerveCost);
  }

  TornSubcrime copyWithWrapped({Wrapped<int?>? id, Wrapped<String?>? name, Wrapped<int?>? nerveCost}) {
    return TornSubcrime(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        nerveCost: (nerveCost != null ? nerveCost.value : this.nerveCost));
  }
}

@JsonSerializable(explicitToJson: true)
class TornCrimesResponse {
  const TornCrimesResponse({
    this.crimes,
  });

  factory TornCrimesResponse.fromJson(Map<String, dynamic> json) => _$TornCrimesResponseFromJson(json);

  static const toJsonFactory = _$TornCrimesResponseToJson;
  Map<String, dynamic> toJson() => _$TornCrimesResponseToJson(this);

  @JsonKey(name: 'crimes', defaultValue: <TornCrime>[])
  final List<TornCrime>? crimes;
  static const fromJsonFactory = _$TornCrimesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornCrimesResponse &&
            (identical(other.crimes, crimes) || const DeepCollectionEquality().equals(other.crimes, crimes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(crimes) ^ runtimeType.hashCode;
}

extension $TornCrimesResponseExtension on TornCrimesResponse {
  TornCrimesResponse copyWith({List<TornCrime>? crimes}) {
    return TornCrimesResponse(crimes: crimes ?? this.crimes);
  }

  TornCrimesResponse copyWithWrapped({Wrapped<List<TornCrime>?>? crimes}) {
    return TornCrimesResponse(crimes: (crimes != null ? crimes.value : this.crimes));
  }
}

@JsonSerializable(explicitToJson: true)
class TornCrime {
  const TornCrime({
    this.id,
    this.name,
    this.categoryId,
    this.categoryName,
    this.enhancerId,
    this.enhancerName,
    this.uniqueOutcomesCount,
    this.uniqueOutcomesIds,
    this.notes,
  });

  factory TornCrime.fromJson(Map<String, dynamic> json) => _$TornCrimeFromJson(json);

  static const toJsonFactory = _$TornCrimeToJson;
  Map<String, dynamic> toJson() => _$TornCrimeToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'category_id')
  final int? categoryId;
  @JsonKey(name: 'category_name')
  final String? categoryName;
  @JsonKey(name: 'enhancer_id')
  final int? enhancerId;
  @JsonKey(name: 'enhancer_name')
  final String? enhancerName;
  @JsonKey(name: 'unique_outcomes_count')
  final int? uniqueOutcomesCount;
  @JsonKey(name: 'unique_outcomes_ids', defaultValue: <int>[])
  final List<int>? uniqueOutcomesIds;
  @JsonKey(name: 'notes', defaultValue: <String>[])
  final List<String>? notes;
  static const fromJsonFactory = _$TornCrimeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornCrime &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.categoryId, categoryId) ||
                const DeepCollectionEquality().equals(other.categoryId, categoryId)) &&
            (identical(other.categoryName, categoryName) ||
                const DeepCollectionEquality().equals(other.categoryName, categoryName)) &&
            (identical(other.enhancerId, enhancerId) ||
                const DeepCollectionEquality().equals(other.enhancerId, enhancerId)) &&
            (identical(other.enhancerName, enhancerName) ||
                const DeepCollectionEquality().equals(other.enhancerName, enhancerName)) &&
            (identical(other.uniqueOutcomesCount, uniqueOutcomesCount) ||
                const DeepCollectionEquality().equals(other.uniqueOutcomesCount, uniqueOutcomesCount)) &&
            (identical(other.uniqueOutcomesIds, uniqueOutcomesIds) ||
                const DeepCollectionEquality().equals(other.uniqueOutcomesIds, uniqueOutcomesIds)) &&
            (identical(other.notes, notes) || const DeepCollectionEquality().equals(other.notes, notes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(categoryId) ^
      const DeepCollectionEquality().hash(categoryName) ^
      const DeepCollectionEquality().hash(enhancerId) ^
      const DeepCollectionEquality().hash(enhancerName) ^
      const DeepCollectionEquality().hash(uniqueOutcomesCount) ^
      const DeepCollectionEquality().hash(uniqueOutcomesIds) ^
      const DeepCollectionEquality().hash(notes) ^
      runtimeType.hashCode;
}

extension $TornCrimeExtension on TornCrime {
  TornCrime copyWith(
      {int? id,
      String? name,
      int? categoryId,
      String? categoryName,
      int? enhancerId,
      String? enhancerName,
      int? uniqueOutcomesCount,
      List<int>? uniqueOutcomesIds,
      List<String>? notes}) {
    return TornCrime(
        id: id ?? this.id,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        enhancerId: enhancerId ?? this.enhancerId,
        enhancerName: enhancerName ?? this.enhancerName,
        uniqueOutcomesCount: uniqueOutcomesCount ?? this.uniqueOutcomesCount,
        uniqueOutcomesIds: uniqueOutcomesIds ?? this.uniqueOutcomesIds,
        notes: notes ?? this.notes);
  }

  TornCrime copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<int?>? categoryId,
      Wrapped<String?>? categoryName,
      Wrapped<int?>? enhancerId,
      Wrapped<String?>? enhancerName,
      Wrapped<int?>? uniqueOutcomesCount,
      Wrapped<List<int>?>? uniqueOutcomesIds,
      Wrapped<List<String>?>? notes}) {
    return TornCrime(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        categoryId: (categoryId != null ? categoryId.value : this.categoryId),
        categoryName: (categoryName != null ? categoryName.value : this.categoryName),
        enhancerId: (enhancerId != null ? enhancerId.value : this.enhancerId),
        enhancerName: (enhancerName != null ? enhancerName.value : this.enhancerName),
        uniqueOutcomesCount: (uniqueOutcomesCount != null ? uniqueOutcomesCount.value : this.uniqueOutcomesCount),
        uniqueOutcomesIds: (uniqueOutcomesIds != null ? uniqueOutcomesIds.value : this.uniqueOutcomesIds),
        notes: (notes != null ? notes.value : this.notes));
  }
}

@JsonSerializable(explicitToJson: true)
class TornCalendarActivity {
  const TornCalendarActivity({
    this.title,
    this.description,
    this.start,
    this.end,
  });

  factory TornCalendarActivity.fromJson(Map<String, dynamic> json) => _$TornCalendarActivityFromJson(json);

  static const toJsonFactory = _$TornCalendarActivityToJson;
  Map<String, dynamic> toJson() => _$TornCalendarActivityToJson(this);

  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'description')
  final String? description;
  @JsonKey(name: 'start')
  final int? start;
  @JsonKey(name: 'end')
  final int? end;
  static const fromJsonFactory = _$TornCalendarActivityFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornCalendarActivity &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(other.description, description)) &&
            (identical(other.start, start) || const DeepCollectionEquality().equals(other.start, start)) &&
            (identical(other.end, end) || const DeepCollectionEquality().equals(other.end, end)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(description) ^
      const DeepCollectionEquality().hash(start) ^
      const DeepCollectionEquality().hash(end) ^
      runtimeType.hashCode;
}

extension $TornCalendarActivityExtension on TornCalendarActivity {
  TornCalendarActivity copyWith({String? title, String? description, int? start, int? end}) {
    return TornCalendarActivity(
        title: title ?? this.title,
        description: description ?? this.description,
        start: start ?? this.start,
        end: end ?? this.end);
  }

  TornCalendarActivity copyWithWrapped(
      {Wrapped<String?>? title, Wrapped<String?>? description, Wrapped<int?>? start, Wrapped<int?>? end}) {
    return TornCalendarActivity(
        title: (title != null ? title.value : this.title),
        description: (description != null ? description.value : this.description),
        start: (start != null ? start.value : this.start),
        end: (end != null ? end.value : this.end));
  }
}

@JsonSerializable(explicitToJson: true)
class TornCalendarResponse {
  const TornCalendarResponse({
    this.calendar,
  });

  factory TornCalendarResponse.fromJson(Map<String, dynamic> json) => _$TornCalendarResponseFromJson(json);

  static const toJsonFactory = _$TornCalendarResponseToJson;
  Map<String, dynamic> toJson() => _$TornCalendarResponseToJson(this);

  @JsonKey(name: 'calendar')
  final TornCalendarResponse$Calendar? calendar;
  static const fromJsonFactory = _$TornCalendarResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornCalendarResponse &&
            (identical(other.calendar, calendar) || const DeepCollectionEquality().equals(other.calendar, calendar)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(calendar) ^ runtimeType.hashCode;
}

extension $TornCalendarResponseExtension on TornCalendarResponse {
  TornCalendarResponse copyWith({TornCalendarResponse$Calendar? calendar}) {
    return TornCalendarResponse(calendar: calendar ?? this.calendar);
  }

  TornCalendarResponse copyWithWrapped({Wrapped<TornCalendarResponse$Calendar?>? calendar}) {
    return TornCalendarResponse(calendar: (calendar != null ? calendar.value : this.calendar));
  }
}

@JsonSerializable(explicitToJson: true)
class TornHof {
  const TornHof({
    this.id,
    this.username,
    this.factionId,
    this.level,
    this.lastAction,
    this.rankName,
    this.rankNumber,
    this.position,
    this.signedUp,
    this.ageInDays,
    this.$value,
    this.rank,
  });

  factory TornHof.fromJson(Map<String, dynamic> json) => _$TornHofFromJson(json);

  static const toJsonFactory = _$TornHofToJson;
  Map<String, dynamic> toJson() => _$TornHofToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'username')
  final String? username;
  @JsonKey(name: 'faction_id')
  final int? factionId;
  @JsonKey(name: 'level')
  final int? level;
  @JsonKey(name: 'last_action')
  final int? lastAction;
  @JsonKey(name: 'rank_name')
  final String? rankName;
  @JsonKey(name: 'rank_number')
  final int? rankNumber;
  @JsonKey(name: 'position')
  final int? position;
  @JsonKey(name: 'signed_up')
  final int? signedUp;
  @JsonKey(name: 'age_in_days')
  final int? ageInDays;
  @JsonKey(name: 'value')
  final dynamic $value;
  @JsonKey(name: 'rank')
  final String? rank;
  static const fromJsonFactory = _$TornHofFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornHof &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.username, username) || const DeepCollectionEquality().equals(other.username, username)) &&
            (identical(other.factionId, factionId) ||
                const DeepCollectionEquality().equals(other.factionId, factionId)) &&
            (identical(other.level, level) || const DeepCollectionEquality().equals(other.level, level)) &&
            (identical(other.lastAction, lastAction) ||
                const DeepCollectionEquality().equals(other.lastAction, lastAction)) &&
            (identical(other.rankName, rankName) || const DeepCollectionEquality().equals(other.rankName, rankName)) &&
            (identical(other.rankNumber, rankNumber) ||
                const DeepCollectionEquality().equals(other.rankNumber, rankNumber)) &&
            (identical(other.position, position) || const DeepCollectionEquality().equals(other.position, position)) &&
            (identical(other.signedUp, signedUp) || const DeepCollectionEquality().equals(other.signedUp, signedUp)) &&
            (identical(other.ageInDays, ageInDays) ||
                const DeepCollectionEquality().equals(other.ageInDays, ageInDays)) &&
            (identical(other.$value, $value) || const DeepCollectionEquality().equals(other.$value, $value)) &&
            (identical(other.rank, rank) || const DeepCollectionEquality().equals(other.rank, rank)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(username) ^
      const DeepCollectionEquality().hash(factionId) ^
      const DeepCollectionEquality().hash(level) ^
      const DeepCollectionEquality().hash(lastAction) ^
      const DeepCollectionEquality().hash(rankName) ^
      const DeepCollectionEquality().hash(rankNumber) ^
      const DeepCollectionEquality().hash(position) ^
      const DeepCollectionEquality().hash(signedUp) ^
      const DeepCollectionEquality().hash(ageInDays) ^
      const DeepCollectionEquality().hash($value) ^
      const DeepCollectionEquality().hash(rank) ^
      runtimeType.hashCode;
}

extension $TornHofExtension on TornHof {
  TornHof copyWith(
      {int? id,
      String? username,
      int? factionId,
      int? level,
      int? lastAction,
      String? rankName,
      int? rankNumber,
      int? position,
      int? signedUp,
      int? ageInDays,
      dynamic $value,
      String? rank}) {
    return TornHof(
        id: id ?? this.id,
        username: username ?? this.username,
        factionId: factionId ?? this.factionId,
        level: level ?? this.level,
        lastAction: lastAction ?? this.lastAction,
        rankName: rankName ?? this.rankName,
        rankNumber: rankNumber ?? this.rankNumber,
        position: position ?? this.position,
        signedUp: signedUp ?? this.signedUp,
        ageInDays: ageInDays ?? this.ageInDays,
        $value: $value ?? this.$value,
        rank: rank ?? this.rank);
  }

  TornHof copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? username,
      Wrapped<int?>? factionId,
      Wrapped<int?>? level,
      Wrapped<int?>? lastAction,
      Wrapped<String?>? rankName,
      Wrapped<int?>? rankNumber,
      Wrapped<int?>? position,
      Wrapped<int?>? signedUp,
      Wrapped<int?>? ageInDays,
      Wrapped<dynamic>? $value,
      Wrapped<String?>? rank}) {
    return TornHof(
        id: (id != null ? id.value : this.id),
        username: (username != null ? username.value : this.username),
        factionId: (factionId != null ? factionId.value : this.factionId),
        level: (level != null ? level.value : this.level),
        lastAction: (lastAction != null ? lastAction.value : this.lastAction),
        rankName: (rankName != null ? rankName.value : this.rankName),
        rankNumber: (rankNumber != null ? rankNumber.value : this.rankNumber),
        position: (position != null ? position.value : this.position),
        signedUp: (signedUp != null ? signedUp.value : this.signedUp),
        ageInDays: (ageInDays != null ? ageInDays.value : this.ageInDays),
        $value: ($value != null ? $value.value : this.$value),
        rank: (rank != null ? rank.value : this.rank));
  }
}

@JsonSerializable(explicitToJson: true)
class TornHofResponse {
  const TornHofResponse({
    this.hof,
    this.metadata,
  });

  factory TornHofResponse.fromJson(Map<String, dynamic> json) => _$TornHofResponseFromJson(json);

  static const toJsonFactory = _$TornHofResponseToJson;
  Map<String, dynamic> toJson() => _$TornHofResponseToJson(this);

  @JsonKey(name: 'hof', defaultValue: <TornHof>[])
  final List<TornHof>? hof;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$TornHofResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornHofResponse &&
            (identical(other.hof, hof) || const DeepCollectionEquality().equals(other.hof, hof)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(hof) ^ const DeepCollectionEquality().hash(metadata) ^ runtimeType.hashCode;
}

extension $TornHofResponseExtension on TornHofResponse {
  TornHofResponse copyWith({List<TornHof>? hof, RequestMetadataWithLinks? metadata}) {
    return TornHofResponse(hof: hof ?? this.hof, metadata: metadata ?? this.metadata);
  }

  TornHofResponse copyWithWrapped({Wrapped<List<TornHof>?>? hof, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return TornHofResponse(
        hof: (hof != null ? hof.value : this.hof), metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionHofValues {
  const FactionHofValues({
    this.chain,
    this.chainDuration,
    this.respect,
  });

  factory FactionHofValues.fromJson(Map<String, dynamic> json) => _$FactionHofValuesFromJson(json);

  static const toJsonFactory = _$FactionHofValuesToJson;
  Map<String, dynamic> toJson() => _$FactionHofValuesToJson(this);

  @JsonKey(name: 'chain')
  final int? chain;
  @JsonKey(name: 'chain_duration')
  final int? chainDuration;
  @JsonKey(name: 'respect')
  final int? respect;
  static const fromJsonFactory = _$FactionHofValuesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionHofValues &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)) &&
            (identical(other.chainDuration, chainDuration) ||
                const DeepCollectionEquality().equals(other.chainDuration, chainDuration)) &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(chain) ^
      const DeepCollectionEquality().hash(chainDuration) ^
      const DeepCollectionEquality().hash(respect) ^
      runtimeType.hashCode;
}

extension $FactionHofValuesExtension on FactionHofValues {
  FactionHofValues copyWith({int? chain, int? chainDuration, int? respect}) {
    return FactionHofValues(
        chain: chain ?? this.chain,
        chainDuration: chainDuration ?? this.chainDuration,
        respect: respect ?? this.respect);
  }

  FactionHofValues copyWithWrapped({Wrapped<int?>? chain, Wrapped<int?>? chainDuration, Wrapped<int?>? respect}) {
    return FactionHofValues(
        chain: (chain != null ? chain.value : this.chain),
        chainDuration: (chainDuration != null ? chainDuration.value : this.chainDuration),
        respect: (respect != null ? respect.value : this.respect));
  }
}

@JsonSerializable(explicitToJson: true)
class TornFactionHof {
  const TornFactionHof({
    this.factionId,
    this.name,
    this.members,
    this.position,
    this.rank,
    this.values,
  });

  factory TornFactionHof.fromJson(Map<String, dynamic> json) => _$TornFactionHofFromJson(json);

  static const toJsonFactory = _$TornFactionHofToJson;
  Map<String, dynamic> toJson() => _$TornFactionHofToJson(this);

  @JsonKey(name: 'faction_id')
  final int? factionId;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'members')
  final int? members;
  @JsonKey(name: 'position')
  final int? position;
  @JsonKey(name: 'rank')
  final String? rank;
  @JsonKey(name: 'values')
  final FactionHofValues? values;
  static const fromJsonFactory = _$TornFactionHofFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornFactionHof &&
            (identical(other.factionId, factionId) ||
                const DeepCollectionEquality().equals(other.factionId, factionId)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.members, members) || const DeepCollectionEquality().equals(other.members, members)) &&
            (identical(other.position, position) || const DeepCollectionEquality().equals(other.position, position)) &&
            (identical(other.rank, rank) || const DeepCollectionEquality().equals(other.rank, rank)) &&
            (identical(other.values, values) || const DeepCollectionEquality().equals(other.values, values)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(factionId) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(members) ^
      const DeepCollectionEquality().hash(position) ^
      const DeepCollectionEquality().hash(rank) ^
      const DeepCollectionEquality().hash(values) ^
      runtimeType.hashCode;
}

extension $TornFactionHofExtension on TornFactionHof {
  TornFactionHof copyWith(
      {int? factionId, String? name, int? members, int? position, String? rank, FactionHofValues? values}) {
    return TornFactionHof(
        factionId: factionId ?? this.factionId,
        name: name ?? this.name,
        members: members ?? this.members,
        position: position ?? this.position,
        rank: rank ?? this.rank,
        values: values ?? this.values);
  }

  TornFactionHof copyWithWrapped(
      {Wrapped<int?>? factionId,
      Wrapped<String?>? name,
      Wrapped<int?>? members,
      Wrapped<int?>? position,
      Wrapped<String?>? rank,
      Wrapped<FactionHofValues?>? values}) {
    return TornFactionHof(
        factionId: (factionId != null ? factionId.value : this.factionId),
        name: (name != null ? name.value : this.name),
        members: (members != null ? members.value : this.members),
        position: (position != null ? position.value : this.position),
        rank: (rank != null ? rank.value : this.rank),
        values: (values != null ? values.value : this.values));
  }
}

@JsonSerializable(explicitToJson: true)
class TornFactionHofResponse {
  const TornFactionHofResponse({
    this.factionhof,
    this.metadata,
  });

  factory TornFactionHofResponse.fromJson(Map<String, dynamic> json) => _$TornFactionHofResponseFromJson(json);

  static const toJsonFactory = _$TornFactionHofResponseToJson;
  Map<String, dynamic> toJson() => _$TornFactionHofResponseToJson(this);

  @JsonKey(name: 'factionhof', defaultValue: <TornFactionHof>[])
  final List<TornFactionHof>? factionhof;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$TornFactionHofResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornFactionHofResponse &&
            (identical(other.factionhof, factionhof) ||
                const DeepCollectionEquality().equals(other.factionhof, factionhof)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(factionhof) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $TornFactionHofResponseExtension on TornFactionHofResponse {
  TornFactionHofResponse copyWith({List<TornFactionHof>? factionhof, RequestMetadataWithLinks? metadata}) {
    return TornFactionHofResponse(factionhof: factionhof ?? this.factionhof, metadata: metadata ?? this.metadata);
  }

  TornFactionHofResponse copyWithWrapped(
      {Wrapped<List<TornFactionHof>?>? factionhof, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return TornFactionHofResponse(
        factionhof: (factionhof != null ? factionhof.value : this.factionhof),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class TornLog {
  const TornLog({
    this.id,
    this.title,
  });

  factory TornLog.fromJson(Map<String, dynamic> json) => _$TornLogFromJson(json);

  static const toJsonFactory = _$TornLogToJson;
  Map<String, dynamic> toJson() => _$TornLogToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  static const fromJsonFactory = _$TornLogFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornLog &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ const DeepCollectionEquality().hash(title) ^ runtimeType.hashCode;
}

extension $TornLogExtension on TornLog {
  TornLog copyWith({int? id, String? title}) {
    return TornLog(id: id ?? this.id, title: title ?? this.title);
  }

  TornLog copyWithWrapped({Wrapped<int?>? id, Wrapped<String?>? title}) {
    return TornLog(id: (id != null ? id.value : this.id), title: (title != null ? title.value : this.title));
  }
}

@JsonSerializable(explicitToJson: true)
class TornLogCategory {
  const TornLogCategory({
    this.id,
    this.title,
  });

  factory TornLogCategory.fromJson(Map<String, dynamic> json) => _$TornLogCategoryFromJson(json);

  static const toJsonFactory = _$TornLogCategoryToJson;
  Map<String, dynamic> toJson() => _$TornLogCategoryToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  static const fromJsonFactory = _$TornLogCategoryFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornLogCategory &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ const DeepCollectionEquality().hash(title) ^ runtimeType.hashCode;
}

extension $TornLogCategoryExtension on TornLogCategory {
  TornLogCategory copyWith({int? id, String? title}) {
    return TornLogCategory(id: id ?? this.id, title: title ?? this.title);
  }

  TornLogCategory copyWithWrapped({Wrapped<int?>? id, Wrapped<String?>? title}) {
    return TornLogCategory(id: (id != null ? id.value : this.id), title: (title != null ? title.value : this.title));
  }
}

@JsonSerializable(explicitToJson: true)
class TornLogTypesResponse {
  const TornLogTypesResponse({
    this.logtypes,
  });

  factory TornLogTypesResponse.fromJson(Map<String, dynamic> json) => _$TornLogTypesResponseFromJson(json);

  static const toJsonFactory = _$TornLogTypesResponseToJson;
  Map<String, dynamic> toJson() => _$TornLogTypesResponseToJson(this);

  @JsonKey(name: 'logtypes', defaultValue: <TornLog>[])
  final List<TornLog>? logtypes;
  static const fromJsonFactory = _$TornLogTypesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornLogTypesResponse &&
            (identical(other.logtypes, logtypes) || const DeepCollectionEquality().equals(other.logtypes, logtypes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(logtypes) ^ runtimeType.hashCode;
}

extension $TornLogTypesResponseExtension on TornLogTypesResponse {
  TornLogTypesResponse copyWith({List<TornLog>? logtypes}) {
    return TornLogTypesResponse(logtypes: logtypes ?? this.logtypes);
  }

  TornLogTypesResponse copyWithWrapped({Wrapped<List<TornLog>?>? logtypes}) {
    return TornLogTypesResponse(logtypes: (logtypes != null ? logtypes.value : this.logtypes));
  }
}

@JsonSerializable(explicitToJson: true)
class TornLogCategoriesResponse {
  const TornLogCategoriesResponse({
    this.logcategories,
  });

  factory TornLogCategoriesResponse.fromJson(Map<String, dynamic> json) => _$TornLogCategoriesResponseFromJson(json);

  static const toJsonFactory = _$TornLogCategoriesResponseToJson;
  Map<String, dynamic> toJson() => _$TornLogCategoriesResponseToJson(this);

  @JsonKey(name: 'logcategories', defaultValue: <TornLogCategory>[])
  final List<TornLogCategory>? logcategories;
  static const fromJsonFactory = _$TornLogCategoriesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornLogCategoriesResponse &&
            (identical(other.logcategories, logcategories) ||
                const DeepCollectionEquality().equals(other.logcategories, logcategories)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(logcategories) ^ runtimeType.hashCode;
}

extension $TornLogCategoriesResponseExtension on TornLogCategoriesResponse {
  TornLogCategoriesResponse copyWith({List<TornLogCategory>? logcategories}) {
    return TornLogCategoriesResponse(logcategories: logcategories ?? this.logcategories);
  }

  TornLogCategoriesResponse copyWithWrapped({Wrapped<List<TornLogCategory>?>? logcategories}) {
    return TornLogCategoriesResponse(logcategories: (logcategories != null ? logcategories.value : this.logcategories));
  }
}

@JsonSerializable(explicitToJson: true)
class Bounty {
  const Bounty({
    this.targetId,
    this.targetName,
    this.targetLevel,
    this.listerId,
    this.listerName,
    this.reward,
    this.reason,
    this.quantity,
    this.isAnonymous,
    this.validUntil,
  });

  factory Bounty.fromJson(Map<String, dynamic> json) => _$BountyFromJson(json);

  static const toJsonFactory = _$BountyToJson;
  Map<String, dynamic> toJson() => _$BountyToJson(this);

  @JsonKey(name: 'target_id')
  final int? targetId;
  @JsonKey(name: 'target_name')
  final String? targetName;
  @JsonKey(name: 'target_level')
  final int? targetLevel;
  @JsonKey(name: 'lister_id')
  final int? listerId;
  @JsonKey(name: 'lister_name')
  final String? listerName;
  @JsonKey(name: 'reward')
  final int? reward;
  @JsonKey(name: 'reason')
  final String? reason;
  @JsonKey(name: 'quantity')
  final int? quantity;
  @JsonKey(name: 'is_anonymous')
  final bool? isAnonymous;
  @JsonKey(name: 'valid_until')
  final int? validUntil;
  static const fromJsonFactory = _$BountyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Bounty &&
            (identical(other.targetId, targetId) || const DeepCollectionEquality().equals(other.targetId, targetId)) &&
            (identical(other.targetName, targetName) ||
                const DeepCollectionEquality().equals(other.targetName, targetName)) &&
            (identical(other.targetLevel, targetLevel) ||
                const DeepCollectionEquality().equals(other.targetLevel, targetLevel)) &&
            (identical(other.listerId, listerId) || const DeepCollectionEquality().equals(other.listerId, listerId)) &&
            (identical(other.listerName, listerName) ||
                const DeepCollectionEquality().equals(other.listerName, listerName)) &&
            (identical(other.reward, reward) || const DeepCollectionEquality().equals(other.reward, reward)) &&
            (identical(other.reason, reason) || const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.quantity, quantity) || const DeepCollectionEquality().equals(other.quantity, quantity)) &&
            (identical(other.isAnonymous, isAnonymous) ||
                const DeepCollectionEquality().equals(other.isAnonymous, isAnonymous)) &&
            (identical(other.validUntil, validUntil) ||
                const DeepCollectionEquality().equals(other.validUntil, validUntil)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(targetId) ^
      const DeepCollectionEquality().hash(targetName) ^
      const DeepCollectionEquality().hash(targetLevel) ^
      const DeepCollectionEquality().hash(listerId) ^
      const DeepCollectionEquality().hash(listerName) ^
      const DeepCollectionEquality().hash(reward) ^
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(quantity) ^
      const DeepCollectionEquality().hash(isAnonymous) ^
      const DeepCollectionEquality().hash(validUntil) ^
      runtimeType.hashCode;
}

extension $BountyExtension on Bounty {
  Bounty copyWith(
      {int? targetId,
      String? targetName,
      int? targetLevel,
      int? listerId,
      String? listerName,
      int? reward,
      String? reason,
      int? quantity,
      bool? isAnonymous,
      int? validUntil}) {
    return Bounty(
        targetId: targetId ?? this.targetId,
        targetName: targetName ?? this.targetName,
        targetLevel: targetLevel ?? this.targetLevel,
        listerId: listerId ?? this.listerId,
        listerName: listerName ?? this.listerName,
        reward: reward ?? this.reward,
        reason: reason ?? this.reason,
        quantity: quantity ?? this.quantity,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        validUntil: validUntil ?? this.validUntil);
  }

  Bounty copyWithWrapped(
      {Wrapped<int?>? targetId,
      Wrapped<String?>? targetName,
      Wrapped<int?>? targetLevel,
      Wrapped<int?>? listerId,
      Wrapped<String?>? listerName,
      Wrapped<int?>? reward,
      Wrapped<String?>? reason,
      Wrapped<int?>? quantity,
      Wrapped<bool?>? isAnonymous,
      Wrapped<int?>? validUntil}) {
    return Bounty(
        targetId: (targetId != null ? targetId.value : this.targetId),
        targetName: (targetName != null ? targetName.value : this.targetName),
        targetLevel: (targetLevel != null ? targetLevel.value : this.targetLevel),
        listerId: (listerId != null ? listerId.value : this.listerId),
        listerName: (listerName != null ? listerName.value : this.listerName),
        reward: (reward != null ? reward.value : this.reward),
        reason: (reason != null ? reason.value : this.reason),
        quantity: (quantity != null ? quantity.value : this.quantity),
        isAnonymous: (isAnonymous != null ? isAnonymous.value : this.isAnonymous),
        validUntil: (validUntil != null ? validUntil.value : this.validUntil));
  }
}

@JsonSerializable(explicitToJson: true)
class TornBountiesResponse {
  const TornBountiesResponse({
    this.bounties,
    this.metadata,
  });

  factory TornBountiesResponse.fromJson(Map<String, dynamic> json) => _$TornBountiesResponseFromJson(json);

  static const toJsonFactory = _$TornBountiesResponseToJson;
  Map<String, dynamic> toJson() => _$TornBountiesResponseToJson(this);

  @JsonKey(name: 'bounties', defaultValue: <Bounty>[])
  final List<Bounty>? bounties;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$TornBountiesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornBountiesResponse &&
            (identical(other.bounties, bounties) || const DeepCollectionEquality().equals(other.bounties, bounties)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bounties) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $TornBountiesResponseExtension on TornBountiesResponse {
  TornBountiesResponse copyWith({List<Bounty>? bounties, RequestMetadataWithLinks? metadata}) {
    return TornBountiesResponse(bounties: bounties ?? this.bounties, metadata: metadata ?? this.metadata);
  }

  TornBountiesResponse copyWithWrapped(
      {Wrapped<List<Bounty>?>? bounties, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return TornBountiesResponse(
        bounties: (bounties != null ? bounties.value : this.bounties),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class TornLookupResponse {
  const TornLookupResponse({
    this.selections,
  });

  factory TornLookupResponse.fromJson(Map<String, dynamic> json) => _$TornLookupResponseFromJson(json);

  static const toJsonFactory = _$TornLookupResponseToJson;
  Map<String, dynamic> toJson() => _$TornLookupResponseToJson(this);

  @JsonKey(
    name: 'selections',
    toJson: tornSelectionNameListToJson,
    fromJson: tornSelectionNameListFromJson,
  )
  final List<enums.TornSelectionName>? selections;
  static const fromJsonFactory = _$TornLookupResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornLookupResponse &&
            (identical(other.selections, selections) ||
                const DeepCollectionEquality().equals(other.selections, selections)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(selections) ^ runtimeType.hashCode;
}

extension $TornLookupResponseExtension on TornLookupResponse {
  TornLookupResponse copyWith({List<enums.TornSelectionName>? selections}) {
    return TornLookupResponse(selections: selections ?? this.selections);
  }

  TornLookupResponse copyWithWrapped({Wrapped<List<enums.TornSelectionName>?>? selections}) {
    return TornLookupResponse(selections: (selections != null ? selections.value : this.selections));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOther {
  const PersonalStatsOther({
    this.other,
  });

  factory PersonalStatsOther.fromJson(Map<String, dynamic> json) => _$PersonalStatsOtherFromJson(json);

  static const toJsonFactory = _$PersonalStatsOtherToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOtherToJson(this);

  @JsonKey(name: 'other')
  final PersonalStatsOther$Other? other;
  static const fromJsonFactory = _$PersonalStatsOtherFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOther &&
            (identical(other.other, other) || const DeepCollectionEquality().equals(other.other, other)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(other) ^ runtimeType.hashCode;
}

extension $PersonalStatsOtherExtension on PersonalStatsOther {
  PersonalStatsOther copyWith({PersonalStatsOther$Other? other}) {
    return PersonalStatsOther(other: other ?? this.other);
  }

  PersonalStatsOther copyWithWrapped({Wrapped<PersonalStatsOther$Other?>? other}) {
    return PersonalStatsOther(other: (other != null ? other.value : this.other));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOtherPopular {
  const PersonalStatsOtherPopular({
    this.other,
  });

  factory PersonalStatsOtherPopular.fromJson(Map<String, dynamic> json) => _$PersonalStatsOtherPopularFromJson(json);

  static const toJsonFactory = _$PersonalStatsOtherPopularToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOtherPopularToJson(this);

  @JsonKey(name: 'other')
  final PersonalStatsOtherPopular$Other? other;
  static const fromJsonFactory = _$PersonalStatsOtherPopularFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOtherPopular &&
            (identical(other.other, other) || const DeepCollectionEquality().equals(other.other, other)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(other) ^ runtimeType.hashCode;
}

extension $PersonalStatsOtherPopularExtension on PersonalStatsOtherPopular {
  PersonalStatsOtherPopular copyWith({PersonalStatsOtherPopular$Other? other}) {
    return PersonalStatsOtherPopular(other: other ?? this.other);
  }

  PersonalStatsOtherPopular copyWithWrapped({Wrapped<PersonalStatsOtherPopular$Other?>? other}) {
    return PersonalStatsOtherPopular(other: (other != null ? other.value : this.other));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsNetworthExtended {
  const PersonalStatsNetworthExtended({
    this.networth,
  });

  factory PersonalStatsNetworthExtended.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsNetworthExtendedFromJson(json);

  static const toJsonFactory = _$PersonalStatsNetworthExtendedToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsNetworthExtendedToJson(this);

  @JsonKey(name: 'networth')
  final PersonalStatsNetworthExtended$Networth? networth;
  static const fromJsonFactory = _$PersonalStatsNetworthExtendedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsNetworthExtended &&
            (identical(other.networth, networth) || const DeepCollectionEquality().equals(other.networth, networth)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(networth) ^ runtimeType.hashCode;
}

extension $PersonalStatsNetworthExtendedExtension on PersonalStatsNetworthExtended {
  PersonalStatsNetworthExtended copyWith({PersonalStatsNetworthExtended$Networth? networth}) {
    return PersonalStatsNetworthExtended(networth: networth ?? this.networth);
  }

  PersonalStatsNetworthExtended copyWithWrapped({Wrapped<PersonalStatsNetworthExtended$Networth?>? networth}) {
    return PersonalStatsNetworthExtended(networth: (networth != null ? networth.value : this.networth));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsNetworthPublic {
  const PersonalStatsNetworthPublic({
    this.networth,
  });

  factory PersonalStatsNetworthPublic.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsNetworthPublicFromJson(json);

  static const toJsonFactory = _$PersonalStatsNetworthPublicToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsNetworthPublicToJson(this);

  @JsonKey(name: 'networth')
  final PersonalStatsNetworthPublic$Networth? networth;
  static const fromJsonFactory = _$PersonalStatsNetworthPublicFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsNetworthPublic &&
            (identical(other.networth, networth) || const DeepCollectionEquality().equals(other.networth, networth)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(networth) ^ runtimeType.hashCode;
}

extension $PersonalStatsNetworthPublicExtension on PersonalStatsNetworthPublic {
  PersonalStatsNetworthPublic copyWith({PersonalStatsNetworthPublic$Networth? networth}) {
    return PersonalStatsNetworthPublic(networth: networth ?? this.networth);
  }

  PersonalStatsNetworthPublic copyWithWrapped({Wrapped<PersonalStatsNetworthPublic$Networth?>? networth}) {
    return PersonalStatsNetworthPublic(networth: (networth != null ? networth.value : this.networth));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsRacing {
  const PersonalStatsRacing({
    this.racing,
  });

  factory PersonalStatsRacing.fromJson(Map<String, dynamic> json) => _$PersonalStatsRacingFromJson(json);

  static const toJsonFactory = _$PersonalStatsRacingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsRacingToJson(this);

  @JsonKey(name: 'racing')
  final PersonalStatsRacing$Racing? racing;
  static const fromJsonFactory = _$PersonalStatsRacingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsRacing &&
            (identical(other.racing, racing) || const DeepCollectionEquality().equals(other.racing, racing)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(racing) ^ runtimeType.hashCode;
}

extension $PersonalStatsRacingExtension on PersonalStatsRacing {
  PersonalStatsRacing copyWith({PersonalStatsRacing$Racing? racing}) {
    return PersonalStatsRacing(racing: racing ?? this.racing);
  }

  PersonalStatsRacing copyWithWrapped({Wrapped<PersonalStatsRacing$Racing?>? racing}) {
    return PersonalStatsRacing(racing: (racing != null ? racing.value : this.racing));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsMissions {
  const PersonalStatsMissions({
    this.missions,
  });

  factory PersonalStatsMissions.fromJson(Map<String, dynamic> json) => _$PersonalStatsMissionsFromJson(json);

  static const toJsonFactory = _$PersonalStatsMissionsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsMissionsToJson(this);

  @JsonKey(name: 'missions')
  final PersonalStatsMissions$Missions? missions;
  static const fromJsonFactory = _$PersonalStatsMissionsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsMissions &&
            (identical(other.missions, missions) || const DeepCollectionEquality().equals(other.missions, missions)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(missions) ^ runtimeType.hashCode;
}

extension $PersonalStatsMissionsExtension on PersonalStatsMissions {
  PersonalStatsMissions copyWith({PersonalStatsMissions$Missions? missions}) {
    return PersonalStatsMissions(missions: missions ?? this.missions);
  }

  PersonalStatsMissions copyWithWrapped({Wrapped<PersonalStatsMissions$Missions?>? missions}) {
    return PersonalStatsMissions(missions: (missions != null ? missions.value : this.missions));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsDrugs {
  const PersonalStatsDrugs({
    this.drugs,
  });

  factory PersonalStatsDrugs.fromJson(Map<String, dynamic> json) => _$PersonalStatsDrugsFromJson(json);

  static const toJsonFactory = _$PersonalStatsDrugsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsDrugsToJson(this);

  @JsonKey(name: 'drugs')
  final PersonalStatsDrugs$Drugs? drugs;
  static const fromJsonFactory = _$PersonalStatsDrugsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsDrugs &&
            (identical(other.drugs, drugs) || const DeepCollectionEquality().equals(other.drugs, drugs)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(drugs) ^ runtimeType.hashCode;
}

extension $PersonalStatsDrugsExtension on PersonalStatsDrugs {
  PersonalStatsDrugs copyWith({PersonalStatsDrugs$Drugs? drugs}) {
    return PersonalStatsDrugs(drugs: drugs ?? this.drugs);
  }

  PersonalStatsDrugs copyWithWrapped({Wrapped<PersonalStatsDrugs$Drugs?>? drugs}) {
    return PersonalStatsDrugs(drugs: (drugs != null ? drugs.value : this.drugs));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTravel {
  const PersonalStatsTravel({
    this.travel,
  });

  factory PersonalStatsTravel.fromJson(Map<String, dynamic> json) => _$PersonalStatsTravelFromJson(json);

  static const toJsonFactory = _$PersonalStatsTravelToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTravelToJson(this);

  @JsonKey(name: 'travel')
  final PersonalStatsTravel$Travel? travel;
  static const fromJsonFactory = _$PersonalStatsTravelFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTravel &&
            (identical(other.travel, travel) || const DeepCollectionEquality().equals(other.travel, travel)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(travel) ^ runtimeType.hashCode;
}

extension $PersonalStatsTravelExtension on PersonalStatsTravel {
  PersonalStatsTravel copyWith({PersonalStatsTravel$Travel? travel}) {
    return PersonalStatsTravel(travel: travel ?? this.travel);
  }

  PersonalStatsTravel copyWithWrapped({Wrapped<PersonalStatsTravel$Travel?>? travel}) {
    return PersonalStatsTravel(travel: (travel != null ? travel.value : this.travel));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTravelPopular {
  const PersonalStatsTravelPopular({
    this.travel,
  });

  factory PersonalStatsTravelPopular.fromJson(Map<String, dynamic> json) => _$PersonalStatsTravelPopularFromJson(json);

  static const toJsonFactory = _$PersonalStatsTravelPopularToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTravelPopularToJson(this);

  @JsonKey(name: 'travel')
  final PersonalStatsTravelPopular$Travel? travel;
  static const fromJsonFactory = _$PersonalStatsTravelPopularFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTravelPopular &&
            (identical(other.travel, travel) || const DeepCollectionEquality().equals(other.travel, travel)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(travel) ^ runtimeType.hashCode;
}

extension $PersonalStatsTravelPopularExtension on PersonalStatsTravelPopular {
  PersonalStatsTravelPopular copyWith({PersonalStatsTravelPopular$Travel? travel}) {
    return PersonalStatsTravelPopular(travel: travel ?? this.travel);
  }

  PersonalStatsTravelPopular copyWithWrapped({Wrapped<PersonalStatsTravelPopular$Travel?>? travel}) {
    return PersonalStatsTravelPopular(travel: (travel != null ? travel.value : this.travel));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsItems {
  const PersonalStatsItems({
    this.items,
  });

  factory PersonalStatsItems.fromJson(Map<String, dynamic> json) => _$PersonalStatsItemsFromJson(json);

  static const toJsonFactory = _$PersonalStatsItemsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsItemsToJson(this);

  @JsonKey(name: 'items')
  final PersonalStatsItems$Items? items;
  static const fromJsonFactory = _$PersonalStatsItemsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsItems &&
            (identical(other.items, items) || const DeepCollectionEquality().equals(other.items, items)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(items) ^ runtimeType.hashCode;
}

extension $PersonalStatsItemsExtension on PersonalStatsItems {
  PersonalStatsItems copyWith({PersonalStatsItems$Items? items}) {
    return PersonalStatsItems(items: items ?? this.items);
  }

  PersonalStatsItems copyWithWrapped({Wrapped<PersonalStatsItems$Items?>? items}) {
    return PersonalStatsItems(items: (items != null ? items.value : this.items));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsItemsPopular {
  const PersonalStatsItemsPopular({
    this.items,
  });

  factory PersonalStatsItemsPopular.fromJson(Map<String, dynamic> json) => _$PersonalStatsItemsPopularFromJson(json);

  static const toJsonFactory = _$PersonalStatsItemsPopularToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsItemsPopularToJson(this);

  @JsonKey(name: 'items')
  final PersonalStatsItemsPopular$Items? items;
  static const fromJsonFactory = _$PersonalStatsItemsPopularFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsItemsPopular &&
            (identical(other.items, items) || const DeepCollectionEquality().equals(other.items, items)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(items) ^ runtimeType.hashCode;
}

extension $PersonalStatsItemsPopularExtension on PersonalStatsItemsPopular {
  PersonalStatsItemsPopular copyWith({PersonalStatsItemsPopular$Items? items}) {
    return PersonalStatsItemsPopular(items: items ?? this.items);
  }

  PersonalStatsItemsPopular copyWithWrapped({Wrapped<PersonalStatsItemsPopular$Items?>? items}) {
    return PersonalStatsItemsPopular(items: (items != null ? items.value : this.items));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsInvestments {
  const PersonalStatsInvestments({
    this.investments,
  });

  factory PersonalStatsInvestments.fromJson(Map<String, dynamic> json) => _$PersonalStatsInvestmentsFromJson(json);

  static const toJsonFactory = _$PersonalStatsInvestmentsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsInvestmentsToJson(this);

  @JsonKey(name: 'investments')
  final PersonalStatsInvestments$Investments? investments;
  static const fromJsonFactory = _$PersonalStatsInvestmentsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsInvestments &&
            (identical(other.investments, investments) ||
                const DeepCollectionEquality().equals(other.investments, investments)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(investments) ^ runtimeType.hashCode;
}

extension $PersonalStatsInvestmentsExtension on PersonalStatsInvestments {
  PersonalStatsInvestments copyWith({PersonalStatsInvestments$Investments? investments}) {
    return PersonalStatsInvestments(investments: investments ?? this.investments);
  }

  PersonalStatsInvestments copyWithWrapped({Wrapped<PersonalStatsInvestments$Investments?>? investments}) {
    return PersonalStatsInvestments(investments: (investments != null ? investments.value : this.investments));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsBounties {
  const PersonalStatsBounties({
    this.bounties,
  });

  factory PersonalStatsBounties.fromJson(Map<String, dynamic> json) => _$PersonalStatsBountiesFromJson(json);

  static const toJsonFactory = _$PersonalStatsBountiesToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsBountiesToJson(this);

  @JsonKey(name: 'bounties')
  final PersonalStatsBounties$Bounties? bounties;
  static const fromJsonFactory = _$PersonalStatsBountiesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsBounties &&
            (identical(other.bounties, bounties) || const DeepCollectionEquality().equals(other.bounties, bounties)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(bounties) ^ runtimeType.hashCode;
}

extension $PersonalStatsBountiesExtension on PersonalStatsBounties {
  PersonalStatsBounties copyWith({PersonalStatsBounties$Bounties? bounties}) {
    return PersonalStatsBounties(bounties: bounties ?? this.bounties);
  }

  PersonalStatsBounties copyWithWrapped({Wrapped<PersonalStatsBounties$Bounties?>? bounties}) {
    return PersonalStatsBounties(bounties: (bounties != null ? bounties.value : this.bounties));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCrimesV2 {
  const PersonalStatsCrimesV2({
    this.offenses,
    this.skills,
    this.version,
  });

  factory PersonalStatsCrimesV2.fromJson(Map<String, dynamic> json) => _$PersonalStatsCrimesV2FromJson(json);

  static const toJsonFactory = _$PersonalStatsCrimesV2ToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCrimesV2ToJson(this);

  @JsonKey(name: 'offenses')
  final PersonalStatsCrimesV2$Offenses? offenses;
  @JsonKey(name: 'skills')
  final PersonalStatsCrimesV2$Skills? skills;
  @JsonKey(name: 'version')
  final String? version;
  static const fromJsonFactory = _$PersonalStatsCrimesV2FromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCrimesV2 &&
            (identical(other.offenses, offenses) || const DeepCollectionEquality().equals(other.offenses, offenses)) &&
            (identical(other.skills, skills) || const DeepCollectionEquality().equals(other.skills, skills)) &&
            (identical(other.version, version) || const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(offenses) ^
      const DeepCollectionEquality().hash(skills) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $PersonalStatsCrimesV2Extension on PersonalStatsCrimesV2 {
  PersonalStatsCrimesV2 copyWith(
      {PersonalStatsCrimesV2$Offenses? offenses, PersonalStatsCrimesV2$Skills? skills, String? version}) {
    return PersonalStatsCrimesV2(
        offenses: offenses ?? this.offenses, skills: skills ?? this.skills, version: version ?? this.version);
  }

  PersonalStatsCrimesV2 copyWithWrapped(
      {Wrapped<PersonalStatsCrimesV2$Offenses?>? offenses,
      Wrapped<PersonalStatsCrimesV2$Skills?>? skills,
      Wrapped<String?>? version}) {
    return PersonalStatsCrimesV2(
        offenses: (offenses != null ? offenses.value : this.offenses),
        skills: (skills != null ? skills.value : this.skills),
        version: (version != null ? version.value : this.version));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCrimesV1 {
  const PersonalStatsCrimesV1({
    this.total,
    this.sellIllegalGoods,
    this.theft,
    this.autoTheft,
    this.drugDeals,
    this.computer,
    this.fraud,
    this.murder,
    this.other,
    this.organizedCrimes,
    this.version,
  });

  factory PersonalStatsCrimesV1.fromJson(Map<String, dynamic> json) => _$PersonalStatsCrimesV1FromJson(json);

  static const toJsonFactory = _$PersonalStatsCrimesV1ToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCrimesV1ToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'sell_illegal_goods')
  final int? sellIllegalGoods;
  @JsonKey(name: 'theft')
  final int? theft;
  @JsonKey(name: 'auto_theft')
  final int? autoTheft;
  @JsonKey(name: 'drug_deals')
  final int? drugDeals;
  @JsonKey(name: 'computer')
  final int? computer;
  @JsonKey(name: 'fraud')
  final int? fraud;
  @JsonKey(name: 'murder')
  final int? murder;
  @JsonKey(name: 'other')
  final int? other;
  @JsonKey(name: 'organized_crimes')
  final int? organizedCrimes;
  @JsonKey(name: 'version')
  final String? version;
  static const fromJsonFactory = _$PersonalStatsCrimesV1FromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCrimesV1 &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.sellIllegalGoods, sellIllegalGoods) ||
                const DeepCollectionEquality().equals(other.sellIllegalGoods, sellIllegalGoods)) &&
            (identical(other.theft, theft) || const DeepCollectionEquality().equals(other.theft, theft)) &&
            (identical(other.autoTheft, autoTheft) ||
                const DeepCollectionEquality().equals(other.autoTheft, autoTheft)) &&
            (identical(other.drugDeals, drugDeals) ||
                const DeepCollectionEquality().equals(other.drugDeals, drugDeals)) &&
            (identical(other.computer, computer) || const DeepCollectionEquality().equals(other.computer, computer)) &&
            (identical(other.fraud, fraud) || const DeepCollectionEquality().equals(other.fraud, fraud)) &&
            (identical(other.murder, murder) || const DeepCollectionEquality().equals(other.murder, murder)) &&
            (identical(other.other, other) || const DeepCollectionEquality().equals(other.other, other)) &&
            (identical(other.organizedCrimes, organizedCrimes) ||
                const DeepCollectionEquality().equals(other.organizedCrimes, organizedCrimes)) &&
            (identical(other.version, version) || const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(sellIllegalGoods) ^
      const DeepCollectionEquality().hash(theft) ^
      const DeepCollectionEquality().hash(autoTheft) ^
      const DeepCollectionEquality().hash(drugDeals) ^
      const DeepCollectionEquality().hash(computer) ^
      const DeepCollectionEquality().hash(fraud) ^
      const DeepCollectionEquality().hash(murder) ^
      const DeepCollectionEquality().hash(other) ^
      const DeepCollectionEquality().hash(organizedCrimes) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $PersonalStatsCrimesV1Extension on PersonalStatsCrimesV1 {
  PersonalStatsCrimesV1 copyWith(
      {int? total,
      int? sellIllegalGoods,
      int? theft,
      int? autoTheft,
      int? drugDeals,
      int? computer,
      int? fraud,
      int? murder,
      int? other,
      int? organizedCrimes,
      String? version}) {
    return PersonalStatsCrimesV1(
        total: total ?? this.total,
        sellIllegalGoods: sellIllegalGoods ?? this.sellIllegalGoods,
        theft: theft ?? this.theft,
        autoTheft: autoTheft ?? this.autoTheft,
        drugDeals: drugDeals ?? this.drugDeals,
        computer: computer ?? this.computer,
        fraud: fraud ?? this.fraud,
        murder: murder ?? this.murder,
        other: other ?? this.other,
        organizedCrimes: organizedCrimes ?? this.organizedCrimes,
        version: version ?? this.version);
  }

  PersonalStatsCrimesV1 copyWithWrapped(
      {Wrapped<int?>? total,
      Wrapped<int?>? sellIllegalGoods,
      Wrapped<int?>? theft,
      Wrapped<int?>? autoTheft,
      Wrapped<int?>? drugDeals,
      Wrapped<int?>? computer,
      Wrapped<int?>? fraud,
      Wrapped<int?>? murder,
      Wrapped<int?>? other,
      Wrapped<int?>? organizedCrimes,
      Wrapped<String?>? version}) {
    return PersonalStatsCrimesV1(
        total: (total != null ? total.value : this.total),
        sellIllegalGoods: (sellIllegalGoods != null ? sellIllegalGoods.value : this.sellIllegalGoods),
        theft: (theft != null ? theft.value : this.theft),
        autoTheft: (autoTheft != null ? autoTheft.value : this.autoTheft),
        drugDeals: (drugDeals != null ? drugDeals.value : this.drugDeals),
        computer: (computer != null ? computer.value : this.computer),
        fraud: (fraud != null ? fraud.value : this.fraud),
        murder: (murder != null ? murder.value : this.murder),
        other: (other != null ? other.value : this.other),
        organizedCrimes: (organizedCrimes != null ? organizedCrimes.value : this.organizedCrimes),
        version: (version != null ? version.value : this.version));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCrimesPopular {
  const PersonalStatsCrimesPopular({
    this.crimes,
  });

  factory PersonalStatsCrimesPopular.fromJson(Map<String, dynamic> json) => _$PersonalStatsCrimesPopularFromJson(json);

  static const toJsonFactory = _$PersonalStatsCrimesPopularToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCrimesPopularToJson(this);

  @JsonKey(name: 'crimes')
  final PersonalStatsCrimesPopular$Crimes? crimes;
  static const fromJsonFactory = _$PersonalStatsCrimesPopularFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCrimesPopular &&
            (identical(other.crimes, crimes) || const DeepCollectionEquality().equals(other.crimes, crimes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(crimes) ^ runtimeType.hashCode;
}

extension $PersonalStatsCrimesPopularExtension on PersonalStatsCrimesPopular {
  PersonalStatsCrimesPopular copyWith({PersonalStatsCrimesPopular$Crimes? crimes}) {
    return PersonalStatsCrimesPopular(crimes: crimes ?? this.crimes);
  }

  PersonalStatsCrimesPopular copyWithWrapped({Wrapped<PersonalStatsCrimesPopular$Crimes?>? crimes}) {
    return PersonalStatsCrimesPopular(crimes: (crimes != null ? crimes.value : this.crimes));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCommunication {
  const PersonalStatsCommunication({
    this.communication,
  });

  factory PersonalStatsCommunication.fromJson(Map<String, dynamic> json) => _$PersonalStatsCommunicationFromJson(json);

  static const toJsonFactory = _$PersonalStatsCommunicationToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCommunicationToJson(this);

  @JsonKey(name: 'communication')
  final PersonalStatsCommunication$Communication? communication;
  static const fromJsonFactory = _$PersonalStatsCommunicationFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCommunication &&
            (identical(other.communication, communication) ||
                const DeepCollectionEquality().equals(other.communication, communication)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(communication) ^ runtimeType.hashCode;
}

extension $PersonalStatsCommunicationExtension on PersonalStatsCommunication {
  PersonalStatsCommunication copyWith({PersonalStatsCommunication$Communication? communication}) {
    return PersonalStatsCommunication(communication: communication ?? this.communication);
  }

  PersonalStatsCommunication copyWithWrapped({Wrapped<PersonalStatsCommunication$Communication?>? communication}) {
    return PersonalStatsCommunication(
        communication: (communication != null ? communication.value : this.communication));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsFinishingHits {
  const PersonalStatsFinishingHits({
    this.finishingHits,
  });

  factory PersonalStatsFinishingHits.fromJson(Map<String, dynamic> json) => _$PersonalStatsFinishingHitsFromJson(json);

  static const toJsonFactory = _$PersonalStatsFinishingHitsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsFinishingHitsToJson(this);

  @JsonKey(name: 'finishing_hits')
  final PersonalStatsFinishingHits$FinishingHits? finishingHits;
  static const fromJsonFactory = _$PersonalStatsFinishingHitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsFinishingHits &&
            (identical(other.finishingHits, finishingHits) ||
                const DeepCollectionEquality().equals(other.finishingHits, finishingHits)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(finishingHits) ^ runtimeType.hashCode;
}

extension $PersonalStatsFinishingHitsExtension on PersonalStatsFinishingHits {
  PersonalStatsFinishingHits copyWith({PersonalStatsFinishingHits$FinishingHits? finishingHits}) {
    return PersonalStatsFinishingHits(finishingHits: finishingHits ?? this.finishingHits);
  }

  PersonalStatsFinishingHits copyWithWrapped({Wrapped<PersonalStatsFinishingHits$FinishingHits?>? finishingHits}) {
    return PersonalStatsFinishingHits(
        finishingHits: (finishingHits != null ? finishingHits.value : this.finishingHits));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsHospital {
  const PersonalStatsHospital({
    this.hospital,
  });

  factory PersonalStatsHospital.fromJson(Map<String, dynamic> json) => _$PersonalStatsHospitalFromJson(json);

  static const toJsonFactory = _$PersonalStatsHospitalToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsHospitalToJson(this);

  @JsonKey(name: 'hospital')
  final PersonalStatsHospital$Hospital? hospital;
  static const fromJsonFactory = _$PersonalStatsHospitalFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsHospital &&
            (identical(other.hospital, hospital) || const DeepCollectionEquality().equals(other.hospital, hospital)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(hospital) ^ runtimeType.hashCode;
}

extension $PersonalStatsHospitalExtension on PersonalStatsHospital {
  PersonalStatsHospital copyWith({PersonalStatsHospital$Hospital? hospital}) {
    return PersonalStatsHospital(hospital: hospital ?? this.hospital);
  }

  PersonalStatsHospital copyWithWrapped({Wrapped<PersonalStatsHospital$Hospital?>? hospital}) {
    return PersonalStatsHospital(hospital: (hospital != null ? hospital.value : this.hospital));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsHospitalPopular {
  const PersonalStatsHospitalPopular({
    this.hospital,
  });

  factory PersonalStatsHospitalPopular.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsHospitalPopularFromJson(json);

  static const toJsonFactory = _$PersonalStatsHospitalPopularToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsHospitalPopularToJson(this);

  @JsonKey(name: 'hospital')
  final PersonalStatsHospitalPopular$Hospital? hospital;
  static const fromJsonFactory = _$PersonalStatsHospitalPopularFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsHospitalPopular &&
            (identical(other.hospital, hospital) || const DeepCollectionEquality().equals(other.hospital, hospital)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(hospital) ^ runtimeType.hashCode;
}

extension $PersonalStatsHospitalPopularExtension on PersonalStatsHospitalPopular {
  PersonalStatsHospitalPopular copyWith({PersonalStatsHospitalPopular$Hospital? hospital}) {
    return PersonalStatsHospitalPopular(hospital: hospital ?? this.hospital);
  }

  PersonalStatsHospitalPopular copyWithWrapped({Wrapped<PersonalStatsHospitalPopular$Hospital?>? hospital}) {
    return PersonalStatsHospitalPopular(hospital: (hospital != null ? hospital.value : this.hospital));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsJail {
  const PersonalStatsJail({
    this.jail,
  });

  factory PersonalStatsJail.fromJson(Map<String, dynamic> json) => _$PersonalStatsJailFromJson(json);

  static const toJsonFactory = _$PersonalStatsJailToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsJailToJson(this);

  @JsonKey(name: 'jail')
  final PersonalStatsJail$Jail? jail;
  static const fromJsonFactory = _$PersonalStatsJailFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsJail &&
            (identical(other.jail, jail) || const DeepCollectionEquality().equals(other.jail, jail)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(jail) ^ runtimeType.hashCode;
}

extension $PersonalStatsJailExtension on PersonalStatsJail {
  PersonalStatsJail copyWith({PersonalStatsJail$Jail? jail}) {
    return PersonalStatsJail(jail: jail ?? this.jail);
  }

  PersonalStatsJail copyWithWrapped({Wrapped<PersonalStatsJail$Jail?>? jail}) {
    return PersonalStatsJail(jail: (jail != null ? jail.value : this.jail));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTrading {
  const PersonalStatsTrading({
    this.trading,
  });

  factory PersonalStatsTrading.fromJson(Map<String, dynamic> json) => _$PersonalStatsTradingFromJson(json);

  static const toJsonFactory = _$PersonalStatsTradingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTradingToJson(this);

  @JsonKey(name: 'trading')
  final PersonalStatsTrading$Trading? trading;
  static const fromJsonFactory = _$PersonalStatsTradingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTrading &&
            (identical(other.trading, trading) || const DeepCollectionEquality().equals(other.trading, trading)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(trading) ^ runtimeType.hashCode;
}

extension $PersonalStatsTradingExtension on PersonalStatsTrading {
  PersonalStatsTrading copyWith({PersonalStatsTrading$Trading? trading}) {
    return PersonalStatsTrading(trading: trading ?? this.trading);
  }

  PersonalStatsTrading copyWithWrapped({Wrapped<PersonalStatsTrading$Trading?>? trading}) {
    return PersonalStatsTrading(trading: (trading != null ? trading.value : this.trading));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsJobsPublic {
  const PersonalStatsJobsPublic({
    this.jobs,
  });

  factory PersonalStatsJobsPublic.fromJson(Map<String, dynamic> json) => _$PersonalStatsJobsPublicFromJson(json);

  static const toJsonFactory = _$PersonalStatsJobsPublicToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsJobsPublicToJson(this);

  @JsonKey(name: 'jobs')
  final PersonalStatsJobsPublic$Jobs? jobs;
  static const fromJsonFactory = _$PersonalStatsJobsPublicFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsJobsPublic &&
            (identical(other.jobs, jobs) || const DeepCollectionEquality().equals(other.jobs, jobs)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(jobs) ^ runtimeType.hashCode;
}

extension $PersonalStatsJobsPublicExtension on PersonalStatsJobsPublic {
  PersonalStatsJobsPublic copyWith({PersonalStatsJobsPublic$Jobs? jobs}) {
    return PersonalStatsJobsPublic(jobs: jobs ?? this.jobs);
  }

  PersonalStatsJobsPublic copyWithWrapped({Wrapped<PersonalStatsJobsPublic$Jobs?>? jobs}) {
    return PersonalStatsJobsPublic(jobs: (jobs != null ? jobs.value : this.jobs));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsJobsExtended {
  const PersonalStatsJobsExtended({
    this.jobs,
  });

  factory PersonalStatsJobsExtended.fromJson(Map<String, dynamic> json) => _$PersonalStatsJobsExtendedFromJson(json);

  static const toJsonFactory = _$PersonalStatsJobsExtendedToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsJobsExtendedToJson(this);

  @JsonKey(name: 'jobs')
  final PersonalStatsJobsExtended$Jobs? jobs;
  static const fromJsonFactory = _$PersonalStatsJobsExtendedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsJobsExtended &&
            (identical(other.jobs, jobs) || const DeepCollectionEquality().equals(other.jobs, jobs)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(jobs) ^ runtimeType.hashCode;
}

extension $PersonalStatsJobsExtendedExtension on PersonalStatsJobsExtended {
  PersonalStatsJobsExtended copyWith({PersonalStatsJobsExtended$Jobs? jobs}) {
    return PersonalStatsJobsExtended(jobs: jobs ?? this.jobs);
  }

  PersonalStatsJobsExtended copyWithWrapped({Wrapped<PersonalStatsJobsExtended$Jobs?>? jobs}) {
    return PersonalStatsJobsExtended(jobs: (jobs != null ? jobs.value : this.jobs));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsBattleStats {
  const PersonalStatsBattleStats({
    this.battleStats,
  });

  factory PersonalStatsBattleStats.fromJson(Map<String, dynamic> json) => _$PersonalStatsBattleStatsFromJson(json);

  static const toJsonFactory = _$PersonalStatsBattleStatsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsBattleStatsToJson(this);

  @JsonKey(name: 'battle_stats')
  final PersonalStatsBattleStats$BattleStats? battleStats;
  static const fromJsonFactory = _$PersonalStatsBattleStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsBattleStats &&
            (identical(other.battleStats, battleStats) ||
                const DeepCollectionEquality().equals(other.battleStats, battleStats)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(battleStats) ^ runtimeType.hashCode;
}

extension $PersonalStatsBattleStatsExtension on PersonalStatsBattleStats {
  PersonalStatsBattleStats copyWith({PersonalStatsBattleStats$BattleStats? battleStats}) {
    return PersonalStatsBattleStats(battleStats: battleStats ?? this.battleStats);
  }

  PersonalStatsBattleStats copyWithWrapped({Wrapped<PersonalStatsBattleStats$BattleStats?>? battleStats}) {
    return PersonalStatsBattleStats(battleStats: (battleStats != null ? battleStats.value : this.battleStats));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic {
  const PersonalStatsAttackingPublic({
    this.attacking,
  });

  factory PersonalStatsAttackingPublic.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublicFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublicToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublicToJson(this);

  @JsonKey(name: 'attacking')
  final PersonalStatsAttackingPublic$Attacking? attacking;
  static const fromJsonFactory = _$PersonalStatsAttackingPublicFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic &&
            (identical(other.attacking, attacking) ||
                const DeepCollectionEquality().equals(other.attacking, attacking)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(attacking) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublicExtension on PersonalStatsAttackingPublic {
  PersonalStatsAttackingPublic copyWith({PersonalStatsAttackingPublic$Attacking? attacking}) {
    return PersonalStatsAttackingPublic(attacking: attacking ?? this.attacking);
  }

  PersonalStatsAttackingPublic copyWithWrapped({Wrapped<PersonalStatsAttackingPublic$Attacking?>? attacking}) {
    return PersonalStatsAttackingPublic(attacking: (attacking != null ? attacking.value : this.attacking));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended {
  const PersonalStatsAttackingExtended({
    this.attacking,
  });

  factory PersonalStatsAttackingExtended.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtendedFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtendedToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtendedToJson(this);

  @JsonKey(name: 'attacking')
  final PersonalStatsAttackingExtended$Attacking? attacking;
  static const fromJsonFactory = _$PersonalStatsAttackingExtendedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended &&
            (identical(other.attacking, attacking) ||
                const DeepCollectionEquality().equals(other.attacking, attacking)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(attacking) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtendedExtension on PersonalStatsAttackingExtended {
  PersonalStatsAttackingExtended copyWith({PersonalStatsAttackingExtended$Attacking? attacking}) {
    return PersonalStatsAttackingExtended(attacking: attacking ?? this.attacking);
  }

  PersonalStatsAttackingExtended copyWithWrapped({Wrapped<PersonalStatsAttackingExtended$Attacking?>? attacking}) {
    return PersonalStatsAttackingExtended(attacking: (attacking != null ? attacking.value : this.attacking));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular {
  const PersonalStatsAttackingPopular({
    this.attacking,
  });

  factory PersonalStatsAttackingPopular.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopularFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopularToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopularToJson(this);

  @JsonKey(name: 'attacking')
  final PersonalStatsAttackingPopular$Attacking? attacking;
  static const fromJsonFactory = _$PersonalStatsAttackingPopularFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular &&
            (identical(other.attacking, attacking) ||
                const DeepCollectionEquality().equals(other.attacking, attacking)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(attacking) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopularExtension on PersonalStatsAttackingPopular {
  PersonalStatsAttackingPopular copyWith({PersonalStatsAttackingPopular$Attacking? attacking}) {
    return PersonalStatsAttackingPopular(attacking: attacking ?? this.attacking);
  }

  PersonalStatsAttackingPopular copyWithWrapped({Wrapped<PersonalStatsAttackingPopular$Attacking?>? attacking}) {
    return PersonalStatsAttackingPopular(attacking: (attacking != null ? attacking.value : this.attacking));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsHistoricStat {
  const PersonalStatsHistoricStat({
    this.name,
    this.$value,
    this.timestamp,
  });

  factory PersonalStatsHistoricStat.fromJson(Map<String, dynamic> json) => _$PersonalStatsHistoricStatFromJson(json);

  static const toJsonFactory = _$PersonalStatsHistoricStatToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsHistoricStatToJson(this);

  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'value')
  final int? $value;
  @JsonKey(name: 'timestamp')
  final int? timestamp;
  static const fromJsonFactory = _$PersonalStatsHistoricStatFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsHistoricStat &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.$value, $value) || const DeepCollectionEquality().equals(other.$value, $value)) &&
            (identical(other.timestamp, timestamp) ||
                const DeepCollectionEquality().equals(other.timestamp, timestamp)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash($value) ^
      const DeepCollectionEquality().hash(timestamp) ^
      runtimeType.hashCode;
}

extension $PersonalStatsHistoricStatExtension on PersonalStatsHistoricStat {
  PersonalStatsHistoricStat copyWith({String? name, int? $value, int? timestamp}) {
    return PersonalStatsHistoricStat(
        name: name ?? this.name, $value: $value ?? this.$value, timestamp: timestamp ?? this.timestamp);
  }

  PersonalStatsHistoricStat copyWithWrapped({Wrapped<String?>? name, Wrapped<int?>? $value, Wrapped<int?>? timestamp}) {
    return PersonalStatsHistoricStat(
        name: (name != null ? name.value : this.name),
        $value: ($value != null ? $value.value : this.$value),
        timestamp: (timestamp != null ? timestamp.value : this.timestamp));
  }
}

@JsonSerializable(explicitToJson: true)
class UserPersonalStatsHistoric {
  const UserPersonalStatsHistoric({
    this.personalstats,
  });

  factory UserPersonalStatsHistoric.fromJson(Map<String, dynamic> json) => _$UserPersonalStatsHistoricFromJson(json);

  static const toJsonFactory = _$UserPersonalStatsHistoricToJson;
  Map<String, dynamic> toJson() => _$UserPersonalStatsHistoricToJson(this);

  @JsonKey(name: 'personalstats', defaultValue: <PersonalStatsHistoricStat>[])
  final List<PersonalStatsHistoricStat>? personalstats;
  static const fromJsonFactory = _$UserPersonalStatsHistoricFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserPersonalStatsHistoric &&
            (identical(other.personalstats, personalstats) ||
                const DeepCollectionEquality().equals(other.personalstats, personalstats)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(personalstats) ^ runtimeType.hashCode;
}

extension $UserPersonalStatsHistoricExtension on UserPersonalStatsHistoric {
  UserPersonalStatsHistoric copyWith({List<PersonalStatsHistoricStat>? personalstats}) {
    return UserPersonalStatsHistoric(personalstats: personalstats ?? this.personalstats);
  }

  UserPersonalStatsHistoric copyWithWrapped({Wrapped<List<PersonalStatsHistoricStat>?>? personalstats}) {
    return UserPersonalStatsHistoric(personalstats: (personalstats != null ? personalstats.value : this.personalstats));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCrimes {
  const PersonalStatsCrimes({
    this.crimes,
  });

  factory PersonalStatsCrimes.fromJson(Map<String, dynamic> json) => _$PersonalStatsCrimesFromJson(json);

  static const toJsonFactory = _$PersonalStatsCrimesToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCrimesToJson(this);

  @JsonKey(name: 'crimes')
  final Object? crimes;
  static const fromJsonFactory = _$PersonalStatsCrimesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCrimes &&
            (identical(other.crimes, crimes) || const DeepCollectionEquality().equals(other.crimes, crimes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(crimes) ^ runtimeType.hashCode;
}

extension $PersonalStatsCrimesExtension on PersonalStatsCrimes {
  PersonalStatsCrimes copyWith({Object? crimes}) {
    return PersonalStatsCrimes(crimes: crimes ?? this.crimes);
  }

  PersonalStatsCrimes copyWithWrapped({Wrapped<Object?>? crimes}) {
    return PersonalStatsCrimes(crimes: (crimes != null ? crimes.value : this.crimes));
  }
}

@JsonSerializable(explicitToJson: true)
class UserPersonalStatsPopular {
  const UserPersonalStatsPopular({
    this.personalstats,
  });

  factory UserPersonalStatsPopular.fromJson(Map<String, dynamic> json) => _$UserPersonalStatsPopularFromJson(json);

  static const toJsonFactory = _$UserPersonalStatsPopularToJson;
  Map<String, dynamic> toJson() => _$UserPersonalStatsPopularToJson(this);

  @JsonKey(name: 'personalstats')
  final dynamic personalstats;
  static const fromJsonFactory = _$UserPersonalStatsPopularFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserPersonalStatsPopular &&
            (identical(other.personalstats, personalstats) ||
                const DeepCollectionEquality().equals(other.personalstats, personalstats)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(personalstats) ^ runtimeType.hashCode;
}

extension $UserPersonalStatsPopularExtension on UserPersonalStatsPopular {
  UserPersonalStatsPopular copyWith({dynamic personalstats}) {
    return UserPersonalStatsPopular(personalstats: personalstats ?? this.personalstats);
  }

  UserPersonalStatsPopular copyWithWrapped({Wrapped<dynamic>? personalstats}) {
    return UserPersonalStatsPopular(personalstats: (personalstats != null ? personalstats.value : this.personalstats));
  }
}

@JsonSerializable(explicitToJson: true)
class UserPersonalStatsCategory {
  const UserPersonalStatsCategory({
    this.personalstats,
  });

  factory UserPersonalStatsCategory.fromJson(Map<String, dynamic> json) => _$UserPersonalStatsCategoryFromJson(json);

  static const toJsonFactory = _$UserPersonalStatsCategoryToJson;
  Map<String, dynamic> toJson() => _$UserPersonalStatsCategoryToJson(this);

  @JsonKey(name: 'personalstats')
  final dynamic personalstats;
  static const fromJsonFactory = _$UserPersonalStatsCategoryFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserPersonalStatsCategory &&
            (identical(other.personalstats, personalstats) ||
                const DeepCollectionEquality().equals(other.personalstats, personalstats)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(personalstats) ^ runtimeType.hashCode;
}

extension $UserPersonalStatsCategoryExtension on UserPersonalStatsCategory {
  UserPersonalStatsCategory copyWith({dynamic personalstats}) {
    return UserPersonalStatsCategory(personalstats: personalstats ?? this.personalstats);
  }

  UserPersonalStatsCategory copyWithWrapped({Wrapped<dynamic>? personalstats}) {
    return UserPersonalStatsCategory(personalstats: (personalstats != null ? personalstats.value : this.personalstats));
  }
}

@JsonSerializable(explicitToJson: true)
class UserPersonalStatsFull {
  const UserPersonalStatsFull({
    this.personalstats,
  });

  factory UserPersonalStatsFull.fromJson(Map<String, dynamic> json) => _$UserPersonalStatsFullFromJson(json);

  static const toJsonFactory = _$UserPersonalStatsFullToJson;
  Map<String, dynamic> toJson() => _$UserPersonalStatsFullToJson(this);

  @JsonKey(name: 'personalstats')
  final dynamic personalstats;
  static const fromJsonFactory = _$UserPersonalStatsFullFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserPersonalStatsFull &&
            (identical(other.personalstats, personalstats) ||
                const DeepCollectionEquality().equals(other.personalstats, personalstats)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(personalstats) ^ runtimeType.hashCode;
}

extension $UserPersonalStatsFullExtension on UserPersonalStatsFull {
  UserPersonalStatsFull copyWith({dynamic personalstats}) {
    return UserPersonalStatsFull(personalstats: personalstats ?? this.personalstats);
  }

  UserPersonalStatsFull copyWithWrapped({Wrapped<dynamic>? personalstats}) {
    return UserPersonalStatsFull(personalstats: (personalstats != null ? personalstats.value : this.personalstats));
  }
}

@JsonSerializable(explicitToJson: true)
class UserPersonalStatsFullPublic {
  const UserPersonalStatsFullPublic({
    this.personalstats,
  });

  factory UserPersonalStatsFullPublic.fromJson(Map<String, dynamic> json) =>
      _$UserPersonalStatsFullPublicFromJson(json);

  static const toJsonFactory = _$UserPersonalStatsFullPublicToJson;
  Map<String, dynamic> toJson() => _$UserPersonalStatsFullPublicToJson(this);

  @JsonKey(name: 'personalstats')
  final dynamic personalstats;
  static const fromJsonFactory = _$UserPersonalStatsFullPublicFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserPersonalStatsFullPublic &&
            (identical(other.personalstats, personalstats) ||
                const DeepCollectionEquality().equals(other.personalstats, personalstats)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(personalstats) ^ runtimeType.hashCode;
}

extension $UserPersonalStatsFullPublicExtension on UserPersonalStatsFullPublic {
  UserPersonalStatsFullPublic copyWith({dynamic personalstats}) {
    return UserPersonalStatsFullPublic(personalstats: personalstats ?? this.personalstats);
  }

  UserPersonalStatsFullPublic copyWithWrapped({Wrapped<dynamic>? personalstats}) {
    return UserPersonalStatsFullPublic(
        personalstats: (personalstats != null ? personalstats.value : this.personalstats));
  }
}

@JsonSerializable(explicitToJson: true)
class UserPersonalStatsResponse {
  const UserPersonalStatsResponse();

  factory UserPersonalStatsResponse.fromJson(Map<String, dynamic> json) => _$UserPersonalStatsResponseFromJson(json);

  static const toJsonFactory = _$UserPersonalStatsResponseToJson;
  Map<String, dynamic> toJson() => _$UserPersonalStatsResponseToJson(this);

  static const fromJsonFactory = _$UserPersonalStatsResponseFromJson;

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => runtimeType.hashCode;
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsBootlegging {
  const UserCrimeDetailsBootlegging({
    this.onlineStore,
    this.dvdSales,
    this.dvdsCopied,
  });

  factory UserCrimeDetailsBootlegging.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsBootleggingFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsBootleggingToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsBootleggingToJson(this);

  @JsonKey(name: 'online_store')
  final UserCrimeDetailsBootlegging$OnlineStore? onlineStore;
  @JsonKey(name: 'dvd_sales')
  final UserCrimeDetailsBootlegging$DvdSales? dvdSales;
  @JsonKey(name: 'dvds_copied')
  final int? dvdsCopied;
  static const fromJsonFactory = _$UserCrimeDetailsBootleggingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsBootlegging &&
            (identical(other.onlineStore, onlineStore) ||
                const DeepCollectionEquality().equals(other.onlineStore, onlineStore)) &&
            (identical(other.dvdSales, dvdSales) || const DeepCollectionEquality().equals(other.dvdSales, dvdSales)) &&
            (identical(other.dvdsCopied, dvdsCopied) ||
                const DeepCollectionEquality().equals(other.dvdsCopied, dvdsCopied)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(onlineStore) ^
      const DeepCollectionEquality().hash(dvdSales) ^
      const DeepCollectionEquality().hash(dvdsCopied) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsBootleggingExtension on UserCrimeDetailsBootlegging {
  UserCrimeDetailsBootlegging copyWith(
      {UserCrimeDetailsBootlegging$OnlineStore? onlineStore,
      UserCrimeDetailsBootlegging$DvdSales? dvdSales,
      int? dvdsCopied}) {
    return UserCrimeDetailsBootlegging(
        onlineStore: onlineStore ?? this.onlineStore,
        dvdSales: dvdSales ?? this.dvdSales,
        dvdsCopied: dvdsCopied ?? this.dvdsCopied);
  }

  UserCrimeDetailsBootlegging copyWithWrapped(
      {Wrapped<UserCrimeDetailsBootlegging$OnlineStore?>? onlineStore,
      Wrapped<UserCrimeDetailsBootlegging$DvdSales?>? dvdSales,
      Wrapped<int?>? dvdsCopied}) {
    return UserCrimeDetailsBootlegging(
        onlineStore: (onlineStore != null ? onlineStore.value : this.onlineStore),
        dvdSales: (dvdSales != null ? dvdSales.value : this.dvdSales),
        dvdsCopied: (dvdsCopied != null ? dvdsCopied.value : this.dvdsCopied));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsGraffiti {
  const UserCrimeDetailsGraffiti({
    this.cansUsed,
    this.mostGraffitiInOneArea,
    this.mostGraffitiSimultaneously,
    this.graffitiRemoved,
    this.costToCity,
  });

  factory UserCrimeDetailsGraffiti.fromJson(Map<String, dynamic> json) => _$UserCrimeDetailsGraffitiFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsGraffitiToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsGraffitiToJson(this);

  @JsonKey(name: 'cans_used')
  final int? cansUsed;
  @JsonKey(name: 'most_graffiti_in_one_area')
  final int? mostGraffitiInOneArea;
  @JsonKey(name: 'most_graffiti_simultaneously')
  final int? mostGraffitiSimultaneously;
  @JsonKey(name: 'graffiti_removed')
  final int? graffitiRemoved;
  @JsonKey(name: 'cost_to_city')
  final int? costToCity;
  static const fromJsonFactory = _$UserCrimeDetailsGraffitiFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsGraffiti &&
            (identical(other.cansUsed, cansUsed) || const DeepCollectionEquality().equals(other.cansUsed, cansUsed)) &&
            (identical(other.mostGraffitiInOneArea, mostGraffitiInOneArea) ||
                const DeepCollectionEquality().equals(other.mostGraffitiInOneArea, mostGraffitiInOneArea)) &&
            (identical(other.mostGraffitiSimultaneously, mostGraffitiSimultaneously) ||
                const DeepCollectionEquality().equals(other.mostGraffitiSimultaneously, mostGraffitiSimultaneously)) &&
            (identical(other.graffitiRemoved, graffitiRemoved) ||
                const DeepCollectionEquality().equals(other.graffitiRemoved, graffitiRemoved)) &&
            (identical(other.costToCity, costToCity) ||
                const DeepCollectionEquality().equals(other.costToCity, costToCity)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(cansUsed) ^
      const DeepCollectionEquality().hash(mostGraffitiInOneArea) ^
      const DeepCollectionEquality().hash(mostGraffitiSimultaneously) ^
      const DeepCollectionEquality().hash(graffitiRemoved) ^
      const DeepCollectionEquality().hash(costToCity) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsGraffitiExtension on UserCrimeDetailsGraffiti {
  UserCrimeDetailsGraffiti copyWith(
      {int? cansUsed,
      int? mostGraffitiInOneArea,
      int? mostGraffitiSimultaneously,
      int? graffitiRemoved,
      int? costToCity}) {
    return UserCrimeDetailsGraffiti(
        cansUsed: cansUsed ?? this.cansUsed,
        mostGraffitiInOneArea: mostGraffitiInOneArea ?? this.mostGraffitiInOneArea,
        mostGraffitiSimultaneously: mostGraffitiSimultaneously ?? this.mostGraffitiSimultaneously,
        graffitiRemoved: graffitiRemoved ?? this.graffitiRemoved,
        costToCity: costToCity ?? this.costToCity);
  }

  UserCrimeDetailsGraffiti copyWithWrapped(
      {Wrapped<int?>? cansUsed,
      Wrapped<int?>? mostGraffitiInOneArea,
      Wrapped<int?>? mostGraffitiSimultaneously,
      Wrapped<int?>? graffitiRemoved,
      Wrapped<int?>? costToCity}) {
    return UserCrimeDetailsGraffiti(
        cansUsed: (cansUsed != null ? cansUsed.value : this.cansUsed),
        mostGraffitiInOneArea:
            (mostGraffitiInOneArea != null ? mostGraffitiInOneArea.value : this.mostGraffitiInOneArea),
        mostGraffitiSimultaneously:
            (mostGraffitiSimultaneously != null ? mostGraffitiSimultaneously.value : this.mostGraffitiSimultaneously),
        graffitiRemoved: (graffitiRemoved != null ? graffitiRemoved.value : this.graffitiRemoved),
        costToCity: (costToCity != null ? costToCity.value : this.costToCity));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsShoplifting {
  const UserCrimeDetailsShoplifting({
    this.averageNotoriety,
  });

  factory UserCrimeDetailsShoplifting.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsShopliftingFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsShopliftingToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsShopliftingToJson(this);

  @JsonKey(name: 'average_notoriety')
  final int? averageNotoriety;
  static const fromJsonFactory = _$UserCrimeDetailsShopliftingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsShoplifting &&
            (identical(other.averageNotoriety, averageNotoriety) ||
                const DeepCollectionEquality().equals(other.averageNotoriety, averageNotoriety)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(averageNotoriety) ^ runtimeType.hashCode;
}

extension $UserCrimeDetailsShopliftingExtension on UserCrimeDetailsShoplifting {
  UserCrimeDetailsShoplifting copyWith({int? averageNotoriety}) {
    return UserCrimeDetailsShoplifting(averageNotoriety: averageNotoriety ?? this.averageNotoriety);
  }

  UserCrimeDetailsShoplifting copyWithWrapped({Wrapped<int?>? averageNotoriety}) {
    return UserCrimeDetailsShoplifting(
        averageNotoriety: (averageNotoriety != null ? averageNotoriety.value : this.averageNotoriety));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsCardSkimming {
  const UserCrimeDetailsCardSkimming({
    this.cardDetails,
    this.skimmers,
  });

  factory UserCrimeDetailsCardSkimming.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsCardSkimmingFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsCardSkimmingToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsCardSkimmingToJson(this);

  @JsonKey(name: 'card_details')
  final UserCrimeDetailsCardSkimming$CardDetails? cardDetails;
  @JsonKey(name: 'skimmers')
  final UserCrimeDetailsCardSkimming$Skimmers? skimmers;
  static const fromJsonFactory = _$UserCrimeDetailsCardSkimmingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsCardSkimming &&
            (identical(other.cardDetails, cardDetails) ||
                const DeepCollectionEquality().equals(other.cardDetails, cardDetails)) &&
            (identical(other.skimmers, skimmers) || const DeepCollectionEquality().equals(other.skimmers, skimmers)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(cardDetails) ^
      const DeepCollectionEquality().hash(skimmers) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsCardSkimmingExtension on UserCrimeDetailsCardSkimming {
  UserCrimeDetailsCardSkimming copyWith(
      {UserCrimeDetailsCardSkimming$CardDetails? cardDetails, UserCrimeDetailsCardSkimming$Skimmers? skimmers}) {
    return UserCrimeDetailsCardSkimming(
        cardDetails: cardDetails ?? this.cardDetails, skimmers: skimmers ?? this.skimmers);
  }

  UserCrimeDetailsCardSkimming copyWithWrapped(
      {Wrapped<UserCrimeDetailsCardSkimming$CardDetails?>? cardDetails,
      Wrapped<UserCrimeDetailsCardSkimming$Skimmers?>? skimmers}) {
    return UserCrimeDetailsCardSkimming(
        cardDetails: (cardDetails != null ? cardDetails.value : this.cardDetails),
        skimmers: (skimmers != null ? skimmers.value : this.skimmers));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsHustling {
  const UserCrimeDetailsHustling({
    this.totalAudienceGathered,
    this.biggestMoneyWon,
    this.shillMoneyCollected,
    this.pickpocketMoneyCollected,
  });

  factory UserCrimeDetailsHustling.fromJson(Map<String, dynamic> json) => _$UserCrimeDetailsHustlingFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsHustlingToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsHustlingToJson(this);

  @JsonKey(name: 'total_audience_gathered')
  final int? totalAudienceGathered;
  @JsonKey(name: 'biggest_money_won')
  final int? biggestMoneyWon;
  @JsonKey(name: 'shill_money_collected')
  final int? shillMoneyCollected;
  @JsonKey(name: 'pickpocket_money_collected')
  final int? pickpocketMoneyCollected;
  static const fromJsonFactory = _$UserCrimeDetailsHustlingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsHustling &&
            (identical(other.totalAudienceGathered, totalAudienceGathered) ||
                const DeepCollectionEquality().equals(other.totalAudienceGathered, totalAudienceGathered)) &&
            (identical(other.biggestMoneyWon, biggestMoneyWon) ||
                const DeepCollectionEquality().equals(other.biggestMoneyWon, biggestMoneyWon)) &&
            (identical(other.shillMoneyCollected, shillMoneyCollected) ||
                const DeepCollectionEquality().equals(other.shillMoneyCollected, shillMoneyCollected)) &&
            (identical(other.pickpocketMoneyCollected, pickpocketMoneyCollected) ||
                const DeepCollectionEquality().equals(other.pickpocketMoneyCollected, pickpocketMoneyCollected)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(totalAudienceGathered) ^
      const DeepCollectionEquality().hash(biggestMoneyWon) ^
      const DeepCollectionEquality().hash(shillMoneyCollected) ^
      const DeepCollectionEquality().hash(pickpocketMoneyCollected) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsHustlingExtension on UserCrimeDetailsHustling {
  UserCrimeDetailsHustling copyWith(
      {int? totalAudienceGathered, int? biggestMoneyWon, int? shillMoneyCollected, int? pickpocketMoneyCollected}) {
    return UserCrimeDetailsHustling(
        totalAudienceGathered: totalAudienceGathered ?? this.totalAudienceGathered,
        biggestMoneyWon: biggestMoneyWon ?? this.biggestMoneyWon,
        shillMoneyCollected: shillMoneyCollected ?? this.shillMoneyCollected,
        pickpocketMoneyCollected: pickpocketMoneyCollected ?? this.pickpocketMoneyCollected);
  }

  UserCrimeDetailsHustling copyWithWrapped(
      {Wrapped<int?>? totalAudienceGathered,
      Wrapped<int?>? biggestMoneyWon,
      Wrapped<int?>? shillMoneyCollected,
      Wrapped<int?>? pickpocketMoneyCollected}) {
    return UserCrimeDetailsHustling(
        totalAudienceGathered:
            (totalAudienceGathered != null ? totalAudienceGathered.value : this.totalAudienceGathered),
        biggestMoneyWon: (biggestMoneyWon != null ? biggestMoneyWon.value : this.biggestMoneyWon),
        shillMoneyCollected: (shillMoneyCollected != null ? shillMoneyCollected.value : this.shillMoneyCollected),
        pickpocketMoneyCollected:
            (pickpocketMoneyCollected != null ? pickpocketMoneyCollected.value : this.pickpocketMoneyCollected));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsCracking {
  const UserCrimeDetailsCracking({
    this.bruteForceCycles,
    this.encryptionLayersBroken,
    this.highestMips,
    this.charsGuessed,
    this.charsGuessedTotal,
  });

  factory UserCrimeDetailsCracking.fromJson(Map<String, dynamic> json) => _$UserCrimeDetailsCrackingFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsCrackingToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsCrackingToJson(this);

  @JsonKey(name: 'brute_force_cycles')
  final int? bruteForceCycles;
  @JsonKey(name: 'encryption_layers_broken')
  final int? encryptionLayersBroken;
  @JsonKey(name: 'highest_mips')
  final int? highestMips;
  @JsonKey(name: 'chars_guessed')
  final int? charsGuessed;
  @JsonKey(name: 'chars_guessed_total')
  final int? charsGuessedTotal;
  static const fromJsonFactory = _$UserCrimeDetailsCrackingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsCracking &&
            (identical(other.bruteForceCycles, bruteForceCycles) ||
                const DeepCollectionEquality().equals(other.bruteForceCycles, bruteForceCycles)) &&
            (identical(other.encryptionLayersBroken, encryptionLayersBroken) ||
                const DeepCollectionEquality().equals(other.encryptionLayersBroken, encryptionLayersBroken)) &&
            (identical(other.highestMips, highestMips) ||
                const DeepCollectionEquality().equals(other.highestMips, highestMips)) &&
            (identical(other.charsGuessed, charsGuessed) ||
                const DeepCollectionEquality().equals(other.charsGuessed, charsGuessed)) &&
            (identical(other.charsGuessedTotal, charsGuessedTotal) ||
                const DeepCollectionEquality().equals(other.charsGuessedTotal, charsGuessedTotal)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bruteForceCycles) ^
      const DeepCollectionEquality().hash(encryptionLayersBroken) ^
      const DeepCollectionEquality().hash(highestMips) ^
      const DeepCollectionEquality().hash(charsGuessed) ^
      const DeepCollectionEquality().hash(charsGuessedTotal) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsCrackingExtension on UserCrimeDetailsCracking {
  UserCrimeDetailsCracking copyWith(
      {int? bruteForceCycles,
      int? encryptionLayersBroken,
      int? highestMips,
      int? charsGuessed,
      int? charsGuessedTotal}) {
    return UserCrimeDetailsCracking(
        bruteForceCycles: bruteForceCycles ?? this.bruteForceCycles,
        encryptionLayersBroken: encryptionLayersBroken ?? this.encryptionLayersBroken,
        highestMips: highestMips ?? this.highestMips,
        charsGuessed: charsGuessed ?? this.charsGuessed,
        charsGuessedTotal: charsGuessedTotal ?? this.charsGuessedTotal);
  }

  UserCrimeDetailsCracking copyWithWrapped(
      {Wrapped<int?>? bruteForceCycles,
      Wrapped<int?>? encryptionLayersBroken,
      Wrapped<int?>? highestMips,
      Wrapped<int?>? charsGuessed,
      Wrapped<int?>? charsGuessedTotal}) {
    return UserCrimeDetailsCracking(
        bruteForceCycles: (bruteForceCycles != null ? bruteForceCycles.value : this.bruteForceCycles),
        encryptionLayersBroken:
            (encryptionLayersBroken != null ? encryptionLayersBroken.value : this.encryptionLayersBroken),
        highestMips: (highestMips != null ? highestMips.value : this.highestMips),
        charsGuessed: (charsGuessed != null ? charsGuessed.value : this.charsGuessed),
        charsGuessedTotal: (charsGuessedTotal != null ? charsGuessedTotal.value : this.charsGuessedTotal));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsScamming {
  const UserCrimeDetailsScamming({
    this.mostResponses,
    this.zones,
    this.concerns,
    this.payouts,
    this.emails,
  });

  factory UserCrimeDetailsScamming.fromJson(Map<String, dynamic> json) => _$UserCrimeDetailsScammingFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsScammingToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsScammingToJson(this);

  @JsonKey(name: 'most_responses')
  final int? mostResponses;
  @JsonKey(name: 'zones')
  final UserCrimeDetailsScamming$Zones? zones;
  @JsonKey(name: 'concerns')
  final UserCrimeDetailsScamming$Concerns? concerns;
  @JsonKey(name: 'payouts')
  final UserCrimeDetailsScamming$Payouts? payouts;
  @JsonKey(name: 'emails')
  final UserCrimeDetailsScamming$Emails? emails;
  static const fromJsonFactory = _$UserCrimeDetailsScammingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsScamming &&
            (identical(other.mostResponses, mostResponses) ||
                const DeepCollectionEquality().equals(other.mostResponses, mostResponses)) &&
            (identical(other.zones, zones) || const DeepCollectionEquality().equals(other.zones, zones)) &&
            (identical(other.concerns, concerns) || const DeepCollectionEquality().equals(other.concerns, concerns)) &&
            (identical(other.payouts, payouts) || const DeepCollectionEquality().equals(other.payouts, payouts)) &&
            (identical(other.emails, emails) || const DeepCollectionEquality().equals(other.emails, emails)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(mostResponses) ^
      const DeepCollectionEquality().hash(zones) ^
      const DeepCollectionEquality().hash(concerns) ^
      const DeepCollectionEquality().hash(payouts) ^
      const DeepCollectionEquality().hash(emails) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsScammingExtension on UserCrimeDetailsScamming {
  UserCrimeDetailsScamming copyWith(
      {int? mostResponses,
      UserCrimeDetailsScamming$Zones? zones,
      UserCrimeDetailsScamming$Concerns? concerns,
      UserCrimeDetailsScamming$Payouts? payouts,
      UserCrimeDetailsScamming$Emails? emails}) {
    return UserCrimeDetailsScamming(
        mostResponses: mostResponses ?? this.mostResponses,
        zones: zones ?? this.zones,
        concerns: concerns ?? this.concerns,
        payouts: payouts ?? this.payouts,
        emails: emails ?? this.emails);
  }

  UserCrimeDetailsScamming copyWithWrapped(
      {Wrapped<int?>? mostResponses,
      Wrapped<UserCrimeDetailsScamming$Zones?>? zones,
      Wrapped<UserCrimeDetailsScamming$Concerns?>? concerns,
      Wrapped<UserCrimeDetailsScamming$Payouts?>? payouts,
      Wrapped<UserCrimeDetailsScamming$Emails?>? emails}) {
    return UserCrimeDetailsScamming(
        mostResponses: (mostResponses != null ? mostResponses.value : this.mostResponses),
        zones: (zones != null ? zones.value : this.zones),
        concerns: (concerns != null ? concerns.value : this.concerns),
        payouts: (payouts != null ? payouts.value : this.payouts),
        emails: (emails != null ? emails.value : this.emails));
  }
}

@JsonSerializable(explicitToJson: true)
class UserSubcrime {
  const UserSubcrime({
    this.id,
    this.total,
    this.success,
    this.fail,
  });

  factory UserSubcrime.fromJson(Map<String, dynamic> json) => _$UserSubcrimeFromJson(json);

  static const toJsonFactory = _$UserSubcrimeToJson;
  Map<String, dynamic> toJson() => _$UserSubcrimeToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'success')
  final int? success;
  @JsonKey(name: 'fail')
  final int? fail;
  static const fromJsonFactory = _$UserSubcrimeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserSubcrime &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.success, success) || const DeepCollectionEquality().equals(other.success, success)) &&
            (identical(other.fail, fail) || const DeepCollectionEquality().equals(other.fail, fail)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(success) ^
      const DeepCollectionEquality().hash(fail) ^
      runtimeType.hashCode;
}

extension $UserSubcrimeExtension on UserSubcrime {
  UserSubcrime copyWith({int? id, int? total, int? success, int? fail}) {
    return UserSubcrime(
        id: id ?? this.id, total: total ?? this.total, success: success ?? this.success, fail: fail ?? this.fail);
  }

  UserSubcrime copyWithWrapped({Wrapped<int?>? id, Wrapped<int?>? total, Wrapped<int?>? success, Wrapped<int?>? fail}) {
    return UserSubcrime(
        id: (id != null ? id.value : this.id),
        total: (total != null ? total.value : this.total),
        success: (success != null ? success.value : this.success),
        fail: (fail != null ? fail.value : this.fail));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeRewardAmmo {
  const UserCrimeRewardAmmo({
    this.standard,
    this.special,
  });

  factory UserCrimeRewardAmmo.fromJson(Map<String, dynamic> json) => _$UserCrimeRewardAmmoFromJson(json);

  static const toJsonFactory = _$UserCrimeRewardAmmoToJson;
  Map<String, dynamic> toJson() => _$UserCrimeRewardAmmoToJson(this);

  @JsonKey(name: 'standard')
  final int? standard;
  @JsonKey(name: 'special')
  final int? special;
  static const fromJsonFactory = _$UserCrimeRewardAmmoFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeRewardAmmo &&
            (identical(other.standard, standard) || const DeepCollectionEquality().equals(other.standard, standard)) &&
            (identical(other.special, special) || const DeepCollectionEquality().equals(other.special, special)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(standard) ^
      const DeepCollectionEquality().hash(special) ^
      runtimeType.hashCode;
}

extension $UserCrimeRewardAmmoExtension on UserCrimeRewardAmmo {
  UserCrimeRewardAmmo copyWith({int? standard, int? special}) {
    return UserCrimeRewardAmmo(standard: standard ?? this.standard, special: special ?? this.special);
  }

  UserCrimeRewardAmmo copyWithWrapped({Wrapped<int?>? standard, Wrapped<int?>? special}) {
    return UserCrimeRewardAmmo(
        standard: (standard != null ? standard.value : this.standard),
        special: (special != null ? special.value : this.special));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeRewardItem {
  const UserCrimeRewardItem({
    this.id,
    this.amount,
  });

  factory UserCrimeRewardItem.fromJson(Map<String, dynamic> json) => _$UserCrimeRewardItemFromJson(json);

  static const toJsonFactory = _$UserCrimeRewardItemToJson;
  Map<String, dynamic> toJson() => _$UserCrimeRewardItemToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'amount')
  final int? amount;
  static const fromJsonFactory = _$UserCrimeRewardItemFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeRewardItem &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ const DeepCollectionEquality().hash(amount) ^ runtimeType.hashCode;
}

extension $UserCrimeRewardItemExtension on UserCrimeRewardItem {
  UserCrimeRewardItem copyWith({int? id, int? amount}) {
    return UserCrimeRewardItem(id: id ?? this.id, amount: amount ?? this.amount);
  }

  UserCrimeRewardItem copyWithWrapped({Wrapped<int?>? id, Wrapped<int?>? amount}) {
    return UserCrimeRewardItem(
        id: (id != null ? id.value : this.id), amount: (amount != null ? amount.value : this.amount));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeRewards {
  const UserCrimeRewards({
    this.money,
    this.ammo,
    this.items,
  });

  factory UserCrimeRewards.fromJson(Map<String, dynamic> json) => _$UserCrimeRewardsFromJson(json);

  static const toJsonFactory = _$UserCrimeRewardsToJson;
  Map<String, dynamic> toJson() => _$UserCrimeRewardsToJson(this);

  @JsonKey(name: 'money')
  final int? money;
  @JsonKey(name: 'ammo')
  final UserCrimeRewardAmmo? ammo;
  @JsonKey(name: 'items', defaultValue: <UserCrimeRewardItem>[])
  final List<UserCrimeRewardItem>? items;
  static const fromJsonFactory = _$UserCrimeRewardsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeRewards &&
            (identical(other.money, money) || const DeepCollectionEquality().equals(other.money, money)) &&
            (identical(other.ammo, ammo) || const DeepCollectionEquality().equals(other.ammo, ammo)) &&
            (identical(other.items, items) || const DeepCollectionEquality().equals(other.items, items)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(money) ^
      const DeepCollectionEquality().hash(ammo) ^
      const DeepCollectionEquality().hash(items) ^
      runtimeType.hashCode;
}

extension $UserCrimeRewardsExtension on UserCrimeRewards {
  UserCrimeRewards copyWith({int? money, UserCrimeRewardAmmo? ammo, List<UserCrimeRewardItem>? items}) {
    return UserCrimeRewards(money: money ?? this.money, ammo: ammo ?? this.ammo, items: items ?? this.items);
  }

  UserCrimeRewards copyWithWrapped(
      {Wrapped<int?>? money, Wrapped<UserCrimeRewardAmmo?>? ammo, Wrapped<List<UserCrimeRewardItem>?>? items}) {
    return UserCrimeRewards(
        money: (money != null ? money.value : this.money),
        ammo: (ammo != null ? ammo.value : this.ammo),
        items: (items != null ? items.value : this.items));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeAttempts {
  const UserCrimeAttempts({
    this.total,
    this.success,
    this.fail,
    this.criticalFail,
    this.subcrimes,
  });

  factory UserCrimeAttempts.fromJson(Map<String, dynamic> json) => _$UserCrimeAttemptsFromJson(json);

  static const toJsonFactory = _$UserCrimeAttemptsToJson;
  Map<String, dynamic> toJson() => _$UserCrimeAttemptsToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'success')
  final int? success;
  @JsonKey(name: 'fail')
  final int? fail;
  @JsonKey(name: 'critical_fail')
  final int? criticalFail;
  @JsonKey(name: 'subcrimes', defaultValue: <UserSubcrime>[])
  final List<UserSubcrime>? subcrimes;
  static const fromJsonFactory = _$UserCrimeAttemptsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeAttempts &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.success, success) || const DeepCollectionEquality().equals(other.success, success)) &&
            (identical(other.fail, fail) || const DeepCollectionEquality().equals(other.fail, fail)) &&
            (identical(other.criticalFail, criticalFail) ||
                const DeepCollectionEquality().equals(other.criticalFail, criticalFail)) &&
            (identical(other.subcrimes, subcrimes) ||
                const DeepCollectionEquality().equals(other.subcrimes, subcrimes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(success) ^
      const DeepCollectionEquality().hash(fail) ^
      const DeepCollectionEquality().hash(criticalFail) ^
      const DeepCollectionEquality().hash(subcrimes) ^
      runtimeType.hashCode;
}

extension $UserCrimeAttemptsExtension on UserCrimeAttempts {
  UserCrimeAttempts copyWith({int? total, int? success, int? fail, int? criticalFail, List<UserSubcrime>? subcrimes}) {
    return UserCrimeAttempts(
        total: total ?? this.total,
        success: success ?? this.success,
        fail: fail ?? this.fail,
        criticalFail: criticalFail ?? this.criticalFail,
        subcrimes: subcrimes ?? this.subcrimes);
  }

  UserCrimeAttempts copyWithWrapped(
      {Wrapped<int?>? total,
      Wrapped<int?>? success,
      Wrapped<int?>? fail,
      Wrapped<int?>? criticalFail,
      Wrapped<List<UserSubcrime>?>? subcrimes}) {
    return UserCrimeAttempts(
        total: (total != null ? total.value : this.total),
        success: (success != null ? success.value : this.success),
        fail: (fail != null ? fail.value : this.fail),
        criticalFail: (criticalFail != null ? criticalFail.value : this.criticalFail),
        subcrimes: (subcrimes != null ? subcrimes.value : this.subcrimes));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeUniquesRewardMoney {
  const UserCrimeUniquesRewardMoney({
    this.min,
    this.max,
  });

  factory UserCrimeUniquesRewardMoney.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeUniquesRewardMoneyFromJson(json);

  static const toJsonFactory = _$UserCrimeUniquesRewardMoneyToJson;
  Map<String, dynamic> toJson() => _$UserCrimeUniquesRewardMoneyToJson(this);

  @JsonKey(name: 'min')
  final int? min;
  @JsonKey(name: 'max')
  final int? max;
  static const fromJsonFactory = _$UserCrimeUniquesRewardMoneyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeUniquesRewardMoney &&
            (identical(other.min, min) || const DeepCollectionEquality().equals(other.min, min)) &&
            (identical(other.max, max) || const DeepCollectionEquality().equals(other.max, max)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(min) ^ const DeepCollectionEquality().hash(max) ^ runtimeType.hashCode;
}

extension $UserCrimeUniquesRewardMoneyExtension on UserCrimeUniquesRewardMoney {
  UserCrimeUniquesRewardMoney copyWith({int? min, int? max}) {
    return UserCrimeUniquesRewardMoney(min: min ?? this.min, max: max ?? this.max);
  }

  UserCrimeUniquesRewardMoney copyWithWrapped({Wrapped<int?>? min, Wrapped<int?>? max}) {
    return UserCrimeUniquesRewardMoney(
        min: (min != null ? min.value : this.min), max: (max != null ? max.value : this.max));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeUniquesRewardAmmo {
  const UserCrimeUniquesRewardAmmo({
    this.amount,
    this.type,
  });

  factory UserCrimeUniquesRewardAmmo.fromJson(Map<String, dynamic> json) => _$UserCrimeUniquesRewardAmmoFromJson(json);

  static const toJsonFactory = _$UserCrimeUniquesRewardAmmoToJson;
  Map<String, dynamic> toJson() => _$UserCrimeUniquesRewardAmmoToJson(this);

  @JsonKey(name: 'amount')
  final int? amount;
  @JsonKey(
    name: 'type',
    toJson: userCrimeUniquesRewardAmmoEnumNullableToJson,
    fromJson: userCrimeUniquesRewardAmmoEnumNullableFromJson,
  )
  final enums.UserCrimeUniquesRewardAmmoEnum? type;
  static const fromJsonFactory = _$UserCrimeUniquesRewardAmmoFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeUniquesRewardAmmo &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.type, type) || const DeepCollectionEquality().equals(other.type, type)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(amount) ^ const DeepCollectionEquality().hash(type) ^ runtimeType.hashCode;
}

extension $UserCrimeUniquesRewardAmmoExtension on UserCrimeUniquesRewardAmmo {
  UserCrimeUniquesRewardAmmo copyWith({int? amount, enums.UserCrimeUniquesRewardAmmoEnum? type}) {
    return UserCrimeUniquesRewardAmmo(amount: amount ?? this.amount, type: type ?? this.type);
  }

  UserCrimeUniquesRewardAmmo copyWithWrapped(
      {Wrapped<int?>? amount, Wrapped<enums.UserCrimeUniquesRewardAmmoEnum?>? type}) {
    return UserCrimeUniquesRewardAmmo(
        amount: (amount != null ? amount.value : this.amount), type: (type != null ? type.value : this.type));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeUniquesReward {
  const UserCrimeUniquesReward({
    this.items,
    this.money,
    this.ammo,
  });

  factory UserCrimeUniquesReward.fromJson(Map<String, dynamic> json) => _$UserCrimeUniquesRewardFromJson(json);

  static const toJsonFactory = _$UserCrimeUniquesRewardToJson;
  Map<String, dynamic> toJson() => _$UserCrimeUniquesRewardToJson(this);

  @JsonKey(name: 'items', defaultValue: <UserCrimeRewardItem>[])
  final List<UserCrimeRewardItem>? items;
  @JsonKey(name: 'money')
  final UserCrimeUniquesRewardMoney? money;
  @JsonKey(name: 'ammo')
  final UserCrimeUniquesRewardAmmo? ammo;
  static const fromJsonFactory = _$UserCrimeUniquesRewardFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeUniquesReward &&
            (identical(other.items, items) || const DeepCollectionEquality().equals(other.items, items)) &&
            (identical(other.money, money) || const DeepCollectionEquality().equals(other.money, money)) &&
            (identical(other.ammo, ammo) || const DeepCollectionEquality().equals(other.ammo, ammo)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(items) ^
      const DeepCollectionEquality().hash(money) ^
      const DeepCollectionEquality().hash(ammo) ^
      runtimeType.hashCode;
}

extension $UserCrimeUniquesRewardExtension on UserCrimeUniquesReward {
  UserCrimeUniquesReward copyWith(
      {List<UserCrimeRewardItem>? items, UserCrimeUniquesRewardMoney? money, UserCrimeUniquesRewardAmmo? ammo}) {
    return UserCrimeUniquesReward(items: items ?? this.items, money: money ?? this.money, ammo: ammo ?? this.ammo);
  }

  UserCrimeUniquesReward copyWithWrapped(
      {Wrapped<List<UserCrimeRewardItem>?>? items,
      Wrapped<UserCrimeUniquesRewardMoney?>? money,
      Wrapped<UserCrimeUniquesRewardAmmo?>? ammo}) {
    return UserCrimeUniquesReward(
        items: (items != null ? items.value : this.items),
        money: (money != null ? money.value : this.money),
        ammo: (ammo != null ? ammo.value : this.ammo));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeUniques {
  const UserCrimeUniques({
    this.id,
    this.rewards,
  });

  factory UserCrimeUniques.fromJson(Map<String, dynamic> json) => _$UserCrimeUniquesFromJson(json);

  static const toJsonFactory = _$UserCrimeUniquesToJson;
  Map<String, dynamic> toJson() => _$UserCrimeUniquesToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'rewards', defaultValue: <UserCrimeUniquesReward>[])
  final List<UserCrimeUniquesReward>? rewards;
  static const fromJsonFactory = _$UserCrimeUniquesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeUniques &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.rewards, rewards) || const DeepCollectionEquality().equals(other.rewards, rewards)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ const DeepCollectionEquality().hash(rewards) ^ runtimeType.hashCode;
}

extension $UserCrimeUniquesExtension on UserCrimeUniques {
  UserCrimeUniques copyWith({int? id, List<UserCrimeUniquesReward>? rewards}) {
    return UserCrimeUniques(id: id ?? this.id, rewards: rewards ?? this.rewards);
  }

  UserCrimeUniques copyWithWrapped({Wrapped<int?>? id, Wrapped<List<UserCrimeUniquesReward>?>? rewards}) {
    return UserCrimeUniques(
        id: (id != null ? id.value : this.id), rewards: (rewards != null ? rewards.value : this.rewards));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimesResponse {
  const UserCrimesResponse({
    this.crimes,
  });

  factory UserCrimesResponse.fromJson(Map<String, dynamic> json) => _$UserCrimesResponseFromJson(json);

  static const toJsonFactory = _$UserCrimesResponseToJson;
  Map<String, dynamic> toJson() => _$UserCrimesResponseToJson(this);

  @JsonKey(name: 'crimes')
  final UserCrime? crimes;
  static const fromJsonFactory = _$UserCrimesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimesResponse &&
            (identical(other.crimes, crimes) || const DeepCollectionEquality().equals(other.crimes, crimes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(crimes) ^ runtimeType.hashCode;
}

extension $UserCrimesResponseExtension on UserCrimesResponse {
  UserCrimesResponse copyWith({UserCrime? crimes}) {
    return UserCrimesResponse(crimes: crimes ?? this.crimes);
  }

  UserCrimesResponse copyWithWrapped({Wrapped<UserCrime?>? crimes}) {
    return UserCrimesResponse(crimes: (crimes != null ? crimes.value : this.crimes));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrime {
  const UserCrime({
    this.nerveSpent,
    this.skill,
    this.progressionBonus,
    this.rewards,
    this.attempts,
    this.uniques,
    this.miscellaneous,
  });

  factory UserCrime.fromJson(Map<String, dynamic> json) => _$UserCrimeFromJson(json);

  static const toJsonFactory = _$UserCrimeToJson;
  Map<String, dynamic> toJson() => _$UserCrimeToJson(this);

  @JsonKey(name: 'nerve_spent')
  final int? nerveSpent;
  @JsonKey(name: 'skill')
  final int? skill;
  @JsonKey(name: 'progression_bonus')
  final int? progressionBonus;
  @JsonKey(name: 'rewards')
  final UserCrimeRewards? rewards;
  @JsonKey(name: 'attempts')
  final UserCrimeAttempts? attempts;
  @JsonKey(name: 'uniques', defaultValue: <UserCrimeUniques>[])
  final List<UserCrimeUniques>? uniques;
  @JsonKey(name: 'miscellaneous')
  final Object? miscellaneous;
  static const fromJsonFactory = _$UserCrimeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrime &&
            (identical(other.nerveSpent, nerveSpent) ||
                const DeepCollectionEquality().equals(other.nerveSpent, nerveSpent)) &&
            (identical(other.skill, skill) || const DeepCollectionEquality().equals(other.skill, skill)) &&
            (identical(other.progressionBonus, progressionBonus) ||
                const DeepCollectionEquality().equals(other.progressionBonus, progressionBonus)) &&
            (identical(other.rewards, rewards) || const DeepCollectionEquality().equals(other.rewards, rewards)) &&
            (identical(other.attempts, attempts) || const DeepCollectionEquality().equals(other.attempts, attempts)) &&
            (identical(other.uniques, uniques) || const DeepCollectionEquality().equals(other.uniques, uniques)) &&
            (identical(other.miscellaneous, miscellaneous) ||
                const DeepCollectionEquality().equals(other.miscellaneous, miscellaneous)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(nerveSpent) ^
      const DeepCollectionEquality().hash(skill) ^
      const DeepCollectionEquality().hash(progressionBonus) ^
      const DeepCollectionEquality().hash(rewards) ^
      const DeepCollectionEquality().hash(attempts) ^
      const DeepCollectionEquality().hash(uniques) ^
      const DeepCollectionEquality().hash(miscellaneous) ^
      runtimeType.hashCode;
}

extension $UserCrimeExtension on UserCrime {
  UserCrime copyWith(
      {int? nerveSpent,
      int? skill,
      int? progressionBonus,
      UserCrimeRewards? rewards,
      UserCrimeAttempts? attempts,
      List<UserCrimeUniques>? uniques,
      Object? miscellaneous}) {
    return UserCrime(
        nerveSpent: nerveSpent ?? this.nerveSpent,
        skill: skill ?? this.skill,
        progressionBonus: progressionBonus ?? this.progressionBonus,
        rewards: rewards ?? this.rewards,
        attempts: attempts ?? this.attempts,
        uniques: uniques ?? this.uniques,
        miscellaneous: miscellaneous ?? this.miscellaneous);
  }

  UserCrime copyWithWrapped(
      {Wrapped<int?>? nerveSpent,
      Wrapped<int?>? skill,
      Wrapped<int?>? progressionBonus,
      Wrapped<UserCrimeRewards?>? rewards,
      Wrapped<UserCrimeAttempts?>? attempts,
      Wrapped<List<UserCrimeUniques>?>? uniques,
      Wrapped<Object?>? miscellaneous}) {
    return UserCrime(
        nerveSpent: (nerveSpent != null ? nerveSpent.value : this.nerveSpent),
        skill: (skill != null ? skill.value : this.skill),
        progressionBonus: (progressionBonus != null ? progressionBonus.value : this.progressionBonus),
        rewards: (rewards != null ? rewards.value : this.rewards),
        attempts: (attempts != null ? attempts.value : this.attempts),
        uniques: (uniques != null ? uniques.value : this.uniques),
        miscellaneous: (miscellaneous != null ? miscellaneous.value : this.miscellaneous));
  }
}

@JsonSerializable(explicitToJson: true)
class UserRacesResponse {
  const UserRacesResponse({
    this.races,
    this.metadata,
  });

  factory UserRacesResponse.fromJson(Map<String, dynamic> json) => _$UserRacesResponseFromJson(json);

  static const toJsonFactory = _$UserRacesResponseToJson;
  Map<String, dynamic> toJson() => _$UserRacesResponseToJson(this);

  @JsonKey(name: 'races', defaultValue: <RacingRaceDetailsResponse>[])
  final List<RacingRaceDetailsResponse>? races;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$UserRacesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserRacesResponse &&
            (identical(other.races, races) || const DeepCollectionEquality().equals(other.races, races)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(races) ^ const DeepCollectionEquality().hash(metadata) ^ runtimeType.hashCode;
}

extension $UserRacesResponseExtension on UserRacesResponse {
  UserRacesResponse copyWith({List<RacingRaceDetailsResponse>? races, RequestMetadataWithLinks? metadata}) {
    return UserRacesResponse(races: races ?? this.races, metadata: metadata ?? this.metadata);
  }

  UserRacesResponse copyWithWrapped(
      {Wrapped<List<RacingRaceDetailsResponse>?>? races, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return UserRacesResponse(
        races: (races != null ? races.value : this.races),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class UserRaceCarDetails {
  const UserRaceCarDetails({
    this.id,
    this.name,
    this.worth,
    this.pointsSpent,
    this.racesEntered,
    this.racesWon,
    this.isRemoved,
    this.parts,
    this.carItemId,
    this.carItemName,
    this.topSpeed,
    this.acceleration,
    this.braking,
    this.dirt,
    this.handling,
    this.safety,
    this.tarmac,
    this.$class,
  });

  factory UserRaceCarDetails.fromJson(Map<String, dynamic> json) => _$UserRaceCarDetailsFromJson(json);

  static const toJsonFactory = _$UserRaceCarDetailsToJson;
  Map<String, dynamic> toJson() => _$UserRaceCarDetailsToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'worth')
  final int? worth;
  @JsonKey(name: 'points_spent')
  final int? pointsSpent;
  @JsonKey(name: 'races_entered')
  final int? racesEntered;
  @JsonKey(name: 'races_won')
  final int? racesWon;
  @JsonKey(name: 'is_removed')
  final bool? isRemoved;
  @JsonKey(name: 'parts', defaultValue: <int>[])
  final List<int>? parts;
  @JsonKey(name: 'car_item_id')
  final int? carItemId;
  @JsonKey(name: 'car_item_name')
  final String? carItemName;
  @JsonKey(name: 'top_speed')
  final int? topSpeed;
  @JsonKey(name: 'acceleration')
  final int? acceleration;
  @JsonKey(name: 'braking')
  final int? braking;
  @JsonKey(name: 'dirt')
  final int? dirt;
  @JsonKey(name: 'handling')
  final int? handling;
  @JsonKey(name: 'safety')
  final int? safety;
  @JsonKey(name: 'tarmac')
  final int? tarmac;
  @JsonKey(
    name: 'class',
    toJson: raceClassEnumNullableToJson,
    fromJson: raceClassEnumNullableFromJson,
  )
  final enums.RaceClassEnum? $class;
  static const fromJsonFactory = _$UserRaceCarDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserRaceCarDetails &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.worth, worth) || const DeepCollectionEquality().equals(other.worth, worth)) &&
            (identical(other.pointsSpent, pointsSpent) ||
                const DeepCollectionEquality().equals(other.pointsSpent, pointsSpent)) &&
            (identical(other.racesEntered, racesEntered) ||
                const DeepCollectionEquality().equals(other.racesEntered, racesEntered)) &&
            (identical(other.racesWon, racesWon) || const DeepCollectionEquality().equals(other.racesWon, racesWon)) &&
            (identical(other.isRemoved, isRemoved) ||
                const DeepCollectionEquality().equals(other.isRemoved, isRemoved)) &&
            (identical(other.parts, parts) || const DeepCollectionEquality().equals(other.parts, parts)) &&
            (identical(other.carItemId, carItemId) ||
                const DeepCollectionEquality().equals(other.carItemId, carItemId)) &&
            (identical(other.carItemName, carItemName) ||
                const DeepCollectionEquality().equals(other.carItemName, carItemName)) &&
            (identical(other.topSpeed, topSpeed) || const DeepCollectionEquality().equals(other.topSpeed, topSpeed)) &&
            (identical(other.acceleration, acceleration) ||
                const DeepCollectionEquality().equals(other.acceleration, acceleration)) &&
            (identical(other.braking, braking) || const DeepCollectionEquality().equals(other.braking, braking)) &&
            (identical(other.dirt, dirt) || const DeepCollectionEquality().equals(other.dirt, dirt)) &&
            (identical(other.handling, handling) || const DeepCollectionEquality().equals(other.handling, handling)) &&
            (identical(other.safety, safety) || const DeepCollectionEquality().equals(other.safety, safety)) &&
            (identical(other.tarmac, tarmac) || const DeepCollectionEquality().equals(other.tarmac, tarmac)) &&
            (identical(other.$class, $class) || const DeepCollectionEquality().equals(other.$class, $class)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(worth) ^
      const DeepCollectionEquality().hash(pointsSpent) ^
      const DeepCollectionEquality().hash(racesEntered) ^
      const DeepCollectionEquality().hash(racesWon) ^
      const DeepCollectionEquality().hash(isRemoved) ^
      const DeepCollectionEquality().hash(parts) ^
      const DeepCollectionEquality().hash(carItemId) ^
      const DeepCollectionEquality().hash(carItemName) ^
      const DeepCollectionEquality().hash(topSpeed) ^
      const DeepCollectionEquality().hash(acceleration) ^
      const DeepCollectionEquality().hash(braking) ^
      const DeepCollectionEquality().hash(dirt) ^
      const DeepCollectionEquality().hash(handling) ^
      const DeepCollectionEquality().hash(safety) ^
      const DeepCollectionEquality().hash(tarmac) ^
      const DeepCollectionEquality().hash($class) ^
      runtimeType.hashCode;
}

extension $UserRaceCarDetailsExtension on UserRaceCarDetails {
  UserRaceCarDetails copyWith(
      {int? id,
      String? name,
      int? worth,
      int? pointsSpent,
      int? racesEntered,
      int? racesWon,
      bool? isRemoved,
      List<int>? parts,
      int? carItemId,
      String? carItemName,
      int? topSpeed,
      int? acceleration,
      int? braking,
      int? dirt,
      int? handling,
      int? safety,
      int? tarmac,
      enums.RaceClassEnum? $class}) {
    return UserRaceCarDetails(
        id: id ?? this.id,
        name: name ?? this.name,
        worth: worth ?? this.worth,
        pointsSpent: pointsSpent ?? this.pointsSpent,
        racesEntered: racesEntered ?? this.racesEntered,
        racesWon: racesWon ?? this.racesWon,
        isRemoved: isRemoved ?? this.isRemoved,
        parts: parts ?? this.parts,
        carItemId: carItemId ?? this.carItemId,
        carItemName: carItemName ?? this.carItemName,
        topSpeed: topSpeed ?? this.topSpeed,
        acceleration: acceleration ?? this.acceleration,
        braking: braking ?? this.braking,
        dirt: dirt ?? this.dirt,
        handling: handling ?? this.handling,
        safety: safety ?? this.safety,
        tarmac: tarmac ?? this.tarmac,
        $class: $class ?? this.$class);
  }

  UserRaceCarDetails copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<int?>? worth,
      Wrapped<int?>? pointsSpent,
      Wrapped<int?>? racesEntered,
      Wrapped<int?>? racesWon,
      Wrapped<bool?>? isRemoved,
      Wrapped<List<int>?>? parts,
      Wrapped<int?>? carItemId,
      Wrapped<String?>? carItemName,
      Wrapped<int?>? topSpeed,
      Wrapped<int?>? acceleration,
      Wrapped<int?>? braking,
      Wrapped<int?>? dirt,
      Wrapped<int?>? handling,
      Wrapped<int?>? safety,
      Wrapped<int?>? tarmac,
      Wrapped<enums.RaceClassEnum?>? $class}) {
    return UserRaceCarDetails(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        worth: (worth != null ? worth.value : this.worth),
        pointsSpent: (pointsSpent != null ? pointsSpent.value : this.pointsSpent),
        racesEntered: (racesEntered != null ? racesEntered.value : this.racesEntered),
        racesWon: (racesWon != null ? racesWon.value : this.racesWon),
        isRemoved: (isRemoved != null ? isRemoved.value : this.isRemoved),
        parts: (parts != null ? parts.value : this.parts),
        carItemId: (carItemId != null ? carItemId.value : this.carItemId),
        carItemName: (carItemName != null ? carItemName.value : this.carItemName),
        topSpeed: (topSpeed != null ? topSpeed.value : this.topSpeed),
        acceleration: (acceleration != null ? acceleration.value : this.acceleration),
        braking: (braking != null ? braking.value : this.braking),
        dirt: (dirt != null ? dirt.value : this.dirt),
        handling: (handling != null ? handling.value : this.handling),
        safety: (safety != null ? safety.value : this.safety),
        tarmac: (tarmac != null ? tarmac.value : this.tarmac),
        $class: ($class != null ? $class.value : this.$class));
  }
}

@JsonSerializable(explicitToJson: true)
class UserEnlistedCarsResponse {
  const UserEnlistedCarsResponse({
    this.enlistedcars,
  });

  factory UserEnlistedCarsResponse.fromJson(Map<String, dynamic> json) => _$UserEnlistedCarsResponseFromJson(json);

  static const toJsonFactory = _$UserEnlistedCarsResponseToJson;
  Map<String, dynamic> toJson() => _$UserEnlistedCarsResponseToJson(this);

  @JsonKey(name: 'enlistedcars', defaultValue: <UserRaceCarDetails>[])
  final List<UserRaceCarDetails>? enlistedcars;
  static const fromJsonFactory = _$UserEnlistedCarsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserEnlistedCarsResponse &&
            (identical(other.enlistedcars, enlistedcars) ||
                const DeepCollectionEquality().equals(other.enlistedcars, enlistedcars)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(enlistedcars) ^ runtimeType.hashCode;
}

extension $UserEnlistedCarsResponseExtension on UserEnlistedCarsResponse {
  UserEnlistedCarsResponse copyWith({List<UserRaceCarDetails>? enlistedcars}) {
    return UserEnlistedCarsResponse(enlistedcars: enlistedcars ?? this.enlistedcars);
  }

  UserEnlistedCarsResponse copyWithWrapped({Wrapped<List<UserRaceCarDetails>?>? enlistedcars}) {
    return UserEnlistedCarsResponse(enlistedcars: (enlistedcars != null ? enlistedcars.value : this.enlistedcars));
  }
}

@JsonSerializable(explicitToJson: true)
class UserForumPostsResponse {
  const UserForumPostsResponse({
    this.forumPosts,
    this.metadata,
  });

  factory UserForumPostsResponse.fromJson(Map<String, dynamic> json) => _$UserForumPostsResponseFromJson(json);

  static const toJsonFactory = _$UserForumPostsResponseToJson;
  Map<String, dynamic> toJson() => _$UserForumPostsResponseToJson(this);

  @JsonKey(name: 'forumPosts', defaultValue: <ForumPost>[])
  final List<ForumPost>? forumPosts;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$UserForumPostsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserForumPostsResponse &&
            (identical(other.forumPosts, forumPosts) ||
                const DeepCollectionEquality().equals(other.forumPosts, forumPosts)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(forumPosts) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $UserForumPostsResponseExtension on UserForumPostsResponse {
  UserForumPostsResponse copyWith({List<ForumPost>? forumPosts, RequestMetadataWithLinks? metadata}) {
    return UserForumPostsResponse(forumPosts: forumPosts ?? this.forumPosts, metadata: metadata ?? this.metadata);
  }

  UserForumPostsResponse copyWithWrapped(
      {Wrapped<List<ForumPost>?>? forumPosts, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return UserForumPostsResponse(
        forumPosts: (forumPosts != null ? forumPosts.value : this.forumPosts),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class UserForumThreadsResponse {
  const UserForumThreadsResponse({
    this.forumThreads,
    this.metadata,
  });

  factory UserForumThreadsResponse.fromJson(Map<String, dynamic> json) => _$UserForumThreadsResponseFromJson(json);

  static const toJsonFactory = _$UserForumThreadsResponseToJson;
  Map<String, dynamic> toJson() => _$UserForumThreadsResponseToJson(this);

  @JsonKey(name: 'forumThreads', defaultValue: <ForumThreadUserExtended>[])
  final List<ForumThreadUserExtended>? forumThreads;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$UserForumThreadsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserForumThreadsResponse &&
            (identical(other.forumThreads, forumThreads) ||
                const DeepCollectionEquality().equals(other.forumThreads, forumThreads)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(forumThreads) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $UserForumThreadsResponseExtension on UserForumThreadsResponse {
  UserForumThreadsResponse copyWith({List<ForumThreadUserExtended>? forumThreads, RequestMetadataWithLinks? metadata}) {
    return UserForumThreadsResponse(
        forumThreads: forumThreads ?? this.forumThreads, metadata: metadata ?? this.metadata);
  }

  UserForumThreadsResponse copyWithWrapped(
      {Wrapped<List<ForumThreadUserExtended>?>? forumThreads, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return UserForumThreadsResponse(
        forumThreads: (forumThreads != null ? forumThreads.value : this.forumThreads),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class UserForumSubscribedThreadsResponse {
  const UserForumSubscribedThreadsResponse({
    this.forumSubscribedThreads,
  });

  factory UserForumSubscribedThreadsResponse.fromJson(Map<String, dynamic> json) =>
      _$UserForumSubscribedThreadsResponseFromJson(json);

  static const toJsonFactory = _$UserForumSubscribedThreadsResponseToJson;
  Map<String, dynamic> toJson() => _$UserForumSubscribedThreadsResponseToJson(this);

  @JsonKey(name: 'forumSubscribedThreads', defaultValue: <ForumSubscribedThread>[])
  final List<ForumSubscribedThread>? forumSubscribedThreads;
  static const fromJsonFactory = _$UserForumSubscribedThreadsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserForumSubscribedThreadsResponse &&
            (identical(other.forumSubscribedThreads, forumSubscribedThreads) ||
                const DeepCollectionEquality().equals(other.forumSubscribedThreads, forumSubscribedThreads)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(forumSubscribedThreads) ^ runtimeType.hashCode;
}

extension $UserForumSubscribedThreadsResponseExtension on UserForumSubscribedThreadsResponse {
  UserForumSubscribedThreadsResponse copyWith({List<ForumSubscribedThread>? forumSubscribedThreads}) {
    return UserForumSubscribedThreadsResponse(
        forumSubscribedThreads: forumSubscribedThreads ?? this.forumSubscribedThreads);
  }

  UserForumSubscribedThreadsResponse copyWithWrapped({Wrapped<List<ForumSubscribedThread>?>? forumSubscribedThreads}) {
    return UserForumSubscribedThreadsResponse(
        forumSubscribedThreads:
            (forumSubscribedThreads != null ? forumSubscribedThreads.value : this.forumSubscribedThreads));
  }
}

@JsonSerializable(explicitToJson: true)
class UserForumFeedResponse {
  const UserForumFeedResponse({
    this.forumFeed,
  });

  factory UserForumFeedResponse.fromJson(Map<String, dynamic> json) => _$UserForumFeedResponseFromJson(json);

  static const toJsonFactory = _$UserForumFeedResponseToJson;
  Map<String, dynamic> toJson() => _$UserForumFeedResponseToJson(this);

  @JsonKey(name: 'forumFeed', defaultValue: <ForumFeed>[])
  final List<ForumFeed>? forumFeed;
  static const fromJsonFactory = _$UserForumFeedResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserForumFeedResponse &&
            (identical(other.forumFeed, forumFeed) ||
                const DeepCollectionEquality().equals(other.forumFeed, forumFeed)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(forumFeed) ^ runtimeType.hashCode;
}

extension $UserForumFeedResponseExtension on UserForumFeedResponse {
  UserForumFeedResponse copyWith({List<ForumFeed>? forumFeed}) {
    return UserForumFeedResponse(forumFeed: forumFeed ?? this.forumFeed);
  }

  UserForumFeedResponse copyWithWrapped({Wrapped<List<ForumFeed>?>? forumFeed}) {
    return UserForumFeedResponse(forumFeed: (forumFeed != null ? forumFeed.value : this.forumFeed));
  }
}

@JsonSerializable(explicitToJson: true)
class UserForumFriendsResponse {
  const UserForumFriendsResponse({
    this.forumFriends,
  });

  factory UserForumFriendsResponse.fromJson(Map<String, dynamic> json) => _$UserForumFriendsResponseFromJson(json);

  static const toJsonFactory = _$UserForumFriendsResponseToJson;
  Map<String, dynamic> toJson() => _$UserForumFriendsResponseToJson(this);

  @JsonKey(name: 'forumFriends', defaultValue: <ForumFeed>[])
  final List<ForumFeed>? forumFriends;
  static const fromJsonFactory = _$UserForumFriendsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserForumFriendsResponse &&
            (identical(other.forumFriends, forumFriends) ||
                const DeepCollectionEquality().equals(other.forumFriends, forumFriends)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(forumFriends) ^ runtimeType.hashCode;
}

extension $UserForumFriendsResponseExtension on UserForumFriendsResponse {
  UserForumFriendsResponse copyWith({List<ForumFeed>? forumFriends}) {
    return UserForumFriendsResponse(forumFriends: forumFriends ?? this.forumFriends);
  }

  UserForumFriendsResponse copyWithWrapped({Wrapped<List<ForumFeed>?>? forumFriends}) {
    return UserForumFriendsResponse(forumFriends: (forumFriends != null ? forumFriends.value : this.forumFriends));
  }
}

@JsonSerializable(explicitToJson: true)
class HofValue {
  const HofValue({
    this.$value,
    this.rank,
  });

  factory HofValue.fromJson(Map<String, dynamic> json) => _$HofValueFromJson(json);

  static const toJsonFactory = _$HofValueToJson;
  Map<String, dynamic> toJson() => _$HofValueToJson(this);

  @JsonKey(name: 'value')
  final int? $value;
  @JsonKey(name: 'rank')
  final int? rank;
  static const fromJsonFactory = _$HofValueFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is HofValue &&
            (identical(other.$value, $value) || const DeepCollectionEquality().equals(other.$value, $value)) &&
            (identical(other.rank, rank) || const DeepCollectionEquality().equals(other.rank, rank)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash($value) ^ const DeepCollectionEquality().hash(rank) ^ runtimeType.hashCode;
}

extension $HofValueExtension on HofValue {
  HofValue copyWith({int? $value, int? rank}) {
    return HofValue($value: $value ?? this.$value, rank: rank ?? this.rank);
  }

  HofValue copyWithWrapped({Wrapped<int?>? $value, Wrapped<int?>? rank}) {
    return HofValue(
        $value: ($value != null ? $value.value : this.$value), rank: (rank != null ? rank.value : this.rank));
  }
}

@JsonSerializable(explicitToJson: true)
class HofValueString {
  const HofValueString({
    this.$value,
    this.rank,
  });

  factory HofValueString.fromJson(Map<String, dynamic> json) => _$HofValueStringFromJson(json);

  static const toJsonFactory = _$HofValueStringToJson;
  Map<String, dynamic> toJson() => _$HofValueStringToJson(this);

  @JsonKey(name: 'value')
  final String? $value;
  @JsonKey(name: 'rank')
  final int? rank;
  static const fromJsonFactory = _$HofValueStringFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is HofValueString &&
            (identical(other.$value, $value) || const DeepCollectionEquality().equals(other.$value, $value)) &&
            (identical(other.rank, rank) || const DeepCollectionEquality().equals(other.rank, rank)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash($value) ^ const DeepCollectionEquality().hash(rank) ^ runtimeType.hashCode;
}

extension $HofValueStringExtension on HofValueString {
  HofValueString copyWith({String? $value, int? rank}) {
    return HofValueString($value: $value ?? this.$value, rank: rank ?? this.rank);
  }

  HofValueString copyWithWrapped({Wrapped<String?>? $value, Wrapped<int?>? rank}) {
    return HofValueString(
        $value: ($value != null ? $value.value : this.$value), rank: (rank != null ? rank.value : this.rank));
  }
}

@JsonSerializable(explicitToJson: true)
class UserHofStats {
  const UserHofStats({
    this.attacks,
    this.busts,
    this.defends,
    this.networth,
    this.offences,
    this.revives,
    this.level,
    this.rank,
    this.awards,
    this.racingSkill,
    this.racingPoints,
    this.racingWins,
    this.travelTime,
    this.workingStats,
    this.battleStats,
  });

  factory UserHofStats.fromJson(Map<String, dynamic> json) => _$UserHofStatsFromJson(json);

  static const toJsonFactory = _$UserHofStatsToJson;
  Map<String, dynamic> toJson() => _$UserHofStatsToJson(this);

  @JsonKey(name: 'attacks')
  final HofValue? attacks;
  @JsonKey(name: 'busts')
  final HofValue? busts;
  @JsonKey(name: 'defends')
  final HofValue? defends;
  @JsonKey(name: 'networth')
  final HofValue? networth;
  @JsonKey(name: 'offences')
  final HofValue? offences;
  @JsonKey(name: 'revives')
  final HofValue? revives;
  @JsonKey(name: 'level')
  final HofValue? level;
  @JsonKey(name: 'rank')
  final HofValue? rank;
  @JsonKey(name: 'awards')
  final HofValue? awards;
  @JsonKey(name: 'racing_skill')
  final HofValue? racingSkill;
  @JsonKey(name: 'racing_points')
  final HofValue? racingPoints;
  @JsonKey(name: 'racing_wins')
  final HofValue? racingWins;
  @JsonKey(name: 'travel_time')
  final HofValue? travelTime;
  @JsonKey(name: 'working_stats')
  final HofValue? workingStats;
  @JsonKey(name: 'battle_stats')
  final HofValue? battleStats;
  static const fromJsonFactory = _$UserHofStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserHofStats &&
            (identical(other.attacks, attacks) || const DeepCollectionEquality().equals(other.attacks, attacks)) &&
            (identical(other.busts, busts) || const DeepCollectionEquality().equals(other.busts, busts)) &&
            (identical(other.defends, defends) || const DeepCollectionEquality().equals(other.defends, defends)) &&
            (identical(other.networth, networth) || const DeepCollectionEquality().equals(other.networth, networth)) &&
            (identical(other.offences, offences) || const DeepCollectionEquality().equals(other.offences, offences)) &&
            (identical(other.revives, revives) || const DeepCollectionEquality().equals(other.revives, revives)) &&
            (identical(other.level, level) || const DeepCollectionEquality().equals(other.level, level)) &&
            (identical(other.rank, rank) || const DeepCollectionEquality().equals(other.rank, rank)) &&
            (identical(other.awards, awards) || const DeepCollectionEquality().equals(other.awards, awards)) &&
            (identical(other.racingSkill, racingSkill) ||
                const DeepCollectionEquality().equals(other.racingSkill, racingSkill)) &&
            (identical(other.racingPoints, racingPoints) ||
                const DeepCollectionEquality().equals(other.racingPoints, racingPoints)) &&
            (identical(other.racingWins, racingWins) ||
                const DeepCollectionEquality().equals(other.racingWins, racingWins)) &&
            (identical(other.travelTime, travelTime) ||
                const DeepCollectionEquality().equals(other.travelTime, travelTime)) &&
            (identical(other.workingStats, workingStats) ||
                const DeepCollectionEquality().equals(other.workingStats, workingStats)) &&
            (identical(other.battleStats, battleStats) ||
                const DeepCollectionEquality().equals(other.battleStats, battleStats)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(attacks) ^
      const DeepCollectionEquality().hash(busts) ^
      const DeepCollectionEquality().hash(defends) ^
      const DeepCollectionEquality().hash(networth) ^
      const DeepCollectionEquality().hash(offences) ^
      const DeepCollectionEquality().hash(revives) ^
      const DeepCollectionEquality().hash(level) ^
      const DeepCollectionEquality().hash(rank) ^
      const DeepCollectionEquality().hash(awards) ^
      const DeepCollectionEquality().hash(racingSkill) ^
      const DeepCollectionEquality().hash(racingPoints) ^
      const DeepCollectionEquality().hash(racingWins) ^
      const DeepCollectionEquality().hash(travelTime) ^
      const DeepCollectionEquality().hash(workingStats) ^
      const DeepCollectionEquality().hash(battleStats) ^
      runtimeType.hashCode;
}

extension $UserHofStatsExtension on UserHofStats {
  UserHofStats copyWith(
      {HofValue? attacks,
      HofValue? busts,
      HofValue? defends,
      HofValue? networth,
      HofValue? offences,
      HofValue? revives,
      HofValue? level,
      HofValue? rank,
      HofValue? awards,
      HofValue? racingSkill,
      HofValue? racingPoints,
      HofValue? racingWins,
      HofValue? travelTime,
      HofValue? workingStats,
      HofValue? battleStats}) {
    return UserHofStats(
        attacks: attacks ?? this.attacks,
        busts: busts ?? this.busts,
        defends: defends ?? this.defends,
        networth: networth ?? this.networth,
        offences: offences ?? this.offences,
        revives: revives ?? this.revives,
        level: level ?? this.level,
        rank: rank ?? this.rank,
        awards: awards ?? this.awards,
        racingSkill: racingSkill ?? this.racingSkill,
        racingPoints: racingPoints ?? this.racingPoints,
        racingWins: racingWins ?? this.racingWins,
        travelTime: travelTime ?? this.travelTime,
        workingStats: workingStats ?? this.workingStats,
        battleStats: battleStats ?? this.battleStats);
  }

  UserHofStats copyWithWrapped(
      {Wrapped<HofValue?>? attacks,
      Wrapped<HofValue?>? busts,
      Wrapped<HofValue?>? defends,
      Wrapped<HofValue?>? networth,
      Wrapped<HofValue?>? offences,
      Wrapped<HofValue?>? revives,
      Wrapped<HofValue?>? level,
      Wrapped<HofValue?>? rank,
      Wrapped<HofValue?>? awards,
      Wrapped<HofValue?>? racingSkill,
      Wrapped<HofValue?>? racingPoints,
      Wrapped<HofValue?>? racingWins,
      Wrapped<HofValue?>? travelTime,
      Wrapped<HofValue?>? workingStats,
      Wrapped<HofValue?>? battleStats}) {
    return UserHofStats(
        attacks: (attacks != null ? attacks.value : this.attacks),
        busts: (busts != null ? busts.value : this.busts),
        defends: (defends != null ? defends.value : this.defends),
        networth: (networth != null ? networth.value : this.networth),
        offences: (offences != null ? offences.value : this.offences),
        revives: (revives != null ? revives.value : this.revives),
        level: (level != null ? level.value : this.level),
        rank: (rank != null ? rank.value : this.rank),
        awards: (awards != null ? awards.value : this.awards),
        racingSkill: (racingSkill != null ? racingSkill.value : this.racingSkill),
        racingPoints: (racingPoints != null ? racingPoints.value : this.racingPoints),
        racingWins: (racingWins != null ? racingWins.value : this.racingWins),
        travelTime: (travelTime != null ? travelTime.value : this.travelTime),
        workingStats: (workingStats != null ? workingStats.value : this.workingStats),
        battleStats: (battleStats != null ? battleStats.value : this.battleStats));
  }
}

@JsonSerializable(explicitToJson: true)
class UserHofResponse {
  const UserHofResponse({
    this.hof,
  });

  factory UserHofResponse.fromJson(Map<String, dynamic> json) => _$UserHofResponseFromJson(json);

  static const toJsonFactory = _$UserHofResponseToJson;
  Map<String, dynamic> toJson() => _$UserHofResponseToJson(this);

  @JsonKey(name: 'hof', defaultValue: <UserHofStats>[])
  final List<UserHofStats>? hof;
  static const fromJsonFactory = _$UserHofResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserHofResponse &&
            (identical(other.hof, hof) || const DeepCollectionEquality().equals(other.hof, hof)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(hof) ^ runtimeType.hashCode;
}

extension $UserHofResponseExtension on UserHofResponse {
  UserHofResponse copyWith({List<UserHofStats>? hof}) {
    return UserHofResponse(hof: hof ?? this.hof);
  }

  UserHofResponse copyWithWrapped({Wrapped<List<UserHofStats>?>? hof}) {
    return UserHofResponse(hof: (hof != null ? hof.value : this.hof));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCalendar {
  const UserCalendar({
    this.startTime,
  });

  factory UserCalendar.fromJson(Map<String, dynamic> json) => _$UserCalendarFromJson(json);

  static const toJsonFactory = _$UserCalendarToJson;
  Map<String, dynamic> toJson() => _$UserCalendarToJson(this);

  @JsonKey(name: 'start_time')
  final String? startTime;
  static const fromJsonFactory = _$UserCalendarFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCalendar &&
            (identical(other.startTime, startTime) ||
                const DeepCollectionEquality().equals(other.startTime, startTime)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(startTime) ^ runtimeType.hashCode;
}

extension $UserCalendarExtension on UserCalendar {
  UserCalendar copyWith({String? startTime}) {
    return UserCalendar(startTime: startTime ?? this.startTime);
  }

  UserCalendar copyWithWrapped({Wrapped<String?>? startTime}) {
    return UserCalendar(startTime: (startTime != null ? startTime.value : this.startTime));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCalendarResponse {
  const UserCalendarResponse({
    this.calendar,
  });

  factory UserCalendarResponse.fromJson(Map<String, dynamic> json) => _$UserCalendarResponseFromJson(json);

  static const toJsonFactory = _$UserCalendarResponseToJson;
  Map<String, dynamic> toJson() => _$UserCalendarResponseToJson(this);

  @JsonKey(name: 'calendar')
  final UserCalendar? calendar;
  static const fromJsonFactory = _$UserCalendarResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCalendarResponse &&
            (identical(other.calendar, calendar) || const DeepCollectionEquality().equals(other.calendar, calendar)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(calendar) ^ runtimeType.hashCode;
}

extension $UserCalendarResponseExtension on UserCalendarResponse {
  UserCalendarResponse copyWith({UserCalendar? calendar}) {
    return UserCalendarResponse(calendar: calendar ?? this.calendar);
  }

  UserCalendarResponse copyWithWrapped({Wrapped<UserCalendar?>? calendar}) {
    return UserCalendarResponse(calendar: (calendar != null ? calendar.value : this.calendar));
  }
}

@JsonSerializable(explicitToJson: true)
class UserBountiesResponse {
  const UserBountiesResponse({
    this.bounties,
  });

  factory UserBountiesResponse.fromJson(Map<String, dynamic> json) => _$UserBountiesResponseFromJson(json);

  static const toJsonFactory = _$UserBountiesResponseToJson;
  Map<String, dynamic> toJson() => _$UserBountiesResponseToJson(this);

  @JsonKey(name: 'bounties', defaultValue: <Bounty>[])
  final List<Bounty>? bounties;
  static const fromJsonFactory = _$UserBountiesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserBountiesResponse &&
            (identical(other.bounties, bounties) || const DeepCollectionEquality().equals(other.bounties, bounties)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(bounties) ^ runtimeType.hashCode;
}

extension $UserBountiesResponseExtension on UserBountiesResponse {
  UserBountiesResponse copyWith({List<Bounty>? bounties}) {
    return UserBountiesResponse(bounties: bounties ?? this.bounties);
  }

  UserBountiesResponse copyWithWrapped({Wrapped<List<Bounty>?>? bounties}) {
    return UserBountiesResponse(bounties: (bounties != null ? bounties.value : this.bounties));
  }
}

@JsonSerializable(explicitToJson: true)
class UserJobRanks {
  const UserJobRanks({
    this.army,
    this.grocer,
    this.casino,
    this.medical,
    this.law,
    this.education,
  });

  factory UserJobRanks.fromJson(Map<String, dynamic> json) => _$UserJobRanksFromJson(json);

  static const toJsonFactory = _$UserJobRanksToJson;
  Map<String, dynamic> toJson() => _$UserJobRanksToJson(this);

  @JsonKey(
    name: 'army',
    toJson: jobPositionArmyEnumNullableToJson,
    fromJson: jobPositionArmyEnumNullableFromJson,
  )
  final enums.JobPositionArmyEnum? army;
  @JsonKey(
    name: 'grocer',
    toJson: jobPositionGrocerEnumNullableToJson,
    fromJson: jobPositionGrocerEnumNullableFromJson,
  )
  final enums.JobPositionGrocerEnum? grocer;
  @JsonKey(
    name: 'casino',
    toJson: jobPositionCasinoEnumNullableToJson,
    fromJson: jobPositionCasinoEnumNullableFromJson,
  )
  final enums.JobPositionCasinoEnum? casino;
  @JsonKey(
    name: 'medical',
    toJson: jobPositionMedicalEnumNullableToJson,
    fromJson: jobPositionMedicalEnumNullableFromJson,
  )
  final enums.JobPositionMedicalEnum? medical;
  @JsonKey(
    name: 'law',
    toJson: jobPositionLawEnumNullableToJson,
    fromJson: jobPositionLawEnumNullableFromJson,
  )
  final enums.JobPositionLawEnum? law;
  @JsonKey(
    name: 'education',
    toJson: jobPositionEducationEnumNullableToJson,
    fromJson: jobPositionEducationEnumNullableFromJson,
  )
  final enums.JobPositionEducationEnum? education;
  static const fromJsonFactory = _$UserJobRanksFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserJobRanks &&
            (identical(other.army, army) || const DeepCollectionEquality().equals(other.army, army)) &&
            (identical(other.grocer, grocer) || const DeepCollectionEquality().equals(other.grocer, grocer)) &&
            (identical(other.casino, casino) || const DeepCollectionEquality().equals(other.casino, casino)) &&
            (identical(other.medical, medical) || const DeepCollectionEquality().equals(other.medical, medical)) &&
            (identical(other.law, law) || const DeepCollectionEquality().equals(other.law, law)) &&
            (identical(other.education, education) ||
                const DeepCollectionEquality().equals(other.education, education)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(army) ^
      const DeepCollectionEquality().hash(grocer) ^
      const DeepCollectionEquality().hash(casino) ^
      const DeepCollectionEquality().hash(medical) ^
      const DeepCollectionEquality().hash(law) ^
      const DeepCollectionEquality().hash(education) ^
      runtimeType.hashCode;
}

extension $UserJobRanksExtension on UserJobRanks {
  UserJobRanks copyWith(
      {enums.JobPositionArmyEnum? army,
      enums.JobPositionGrocerEnum? grocer,
      enums.JobPositionCasinoEnum? casino,
      enums.JobPositionMedicalEnum? medical,
      enums.JobPositionLawEnum? law,
      enums.JobPositionEducationEnum? education}) {
    return UserJobRanks(
        army: army ?? this.army,
        grocer: grocer ?? this.grocer,
        casino: casino ?? this.casino,
        medical: medical ?? this.medical,
        law: law ?? this.law,
        education: education ?? this.education);
  }

  UserJobRanks copyWithWrapped(
      {Wrapped<enums.JobPositionArmyEnum?>? army,
      Wrapped<enums.JobPositionGrocerEnum?>? grocer,
      Wrapped<enums.JobPositionCasinoEnum?>? casino,
      Wrapped<enums.JobPositionMedicalEnum?>? medical,
      Wrapped<enums.JobPositionLawEnum?>? law,
      Wrapped<enums.JobPositionEducationEnum?>? education}) {
    return UserJobRanks(
        army: (army != null ? army.value : this.army),
        grocer: (grocer != null ? grocer.value : this.grocer),
        casino: (casino != null ? casino.value : this.casino),
        medical: (medical != null ? medical.value : this.medical),
        law: (law != null ? law.value : this.law),
        education: (education != null ? education.value : this.education));
  }
}

@JsonSerializable(explicitToJson: true)
class UserJobRanksResponse {
  const UserJobRanksResponse({
    this.jobranks,
  });

  factory UserJobRanksResponse.fromJson(Map<String, dynamic> json) => _$UserJobRanksResponseFromJson(json);

  static const toJsonFactory = _$UserJobRanksResponseToJson;
  Map<String, dynamic> toJson() => _$UserJobRanksResponseToJson(this);

  @JsonKey(name: 'jobranks')
  final UserJobRanks? jobranks;
  static const fromJsonFactory = _$UserJobRanksResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserJobRanksResponse &&
            (identical(other.jobranks, jobranks) || const DeepCollectionEquality().equals(other.jobranks, jobranks)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(jobranks) ^ runtimeType.hashCode;
}

extension $UserJobRanksResponseExtension on UserJobRanksResponse {
  UserJobRanksResponse copyWith({UserJobRanks? jobranks}) {
    return UserJobRanksResponse(jobranks: jobranks ?? this.jobranks);
  }

  UserJobRanksResponse copyWithWrapped({Wrapped<UserJobRanks?>? jobranks}) {
    return UserJobRanksResponse(jobranks: (jobranks != null ? jobranks.value : this.jobranks));
  }
}

@JsonSerializable(explicitToJson: true)
class UserItemMarkeListingItemDetails {
  const UserItemMarkeListingItemDetails({
    this.id,
    this.name,
    this.type,
    this.rarity,
    this.uid,
    this.stats,
    this.bonuses,
  });

  factory UserItemMarkeListingItemDetails.fromJson(Map<String, dynamic> json) =>
      _$UserItemMarkeListingItemDetailsFromJson(json);

  static const toJsonFactory = _$UserItemMarkeListingItemDetailsToJson;
  Map<String, dynamic> toJson() => _$UserItemMarkeListingItemDetailsToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'type')
  final String? type;
  @JsonKey(
    name: 'rarity',
    toJson: userItemMarkeListingItemDetailsRarityNullableToJson,
    fromJson: userItemMarkeListingItemDetailsRarityNullableFromJson,
  )
  final enums.UserItemMarkeListingItemDetailsRarity? rarity;
  @JsonKey(name: 'uid')
  final int? uid;
  @JsonKey(name: 'stats')
  final ItemMarketListingItemStats? stats;
  @JsonKey(name: 'bonuses', defaultValue: <ItemMarketListingItemBonus>[])
  final List<ItemMarketListingItemBonus>? bonuses;
  static const fromJsonFactory = _$UserItemMarkeListingItemDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserItemMarkeListingItemDetails &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.type, type) || const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.rarity, rarity) || const DeepCollectionEquality().equals(other.rarity, rarity)) &&
            (identical(other.uid, uid) || const DeepCollectionEquality().equals(other.uid, uid)) &&
            (identical(other.stats, stats) || const DeepCollectionEquality().equals(other.stats, stats)) &&
            (identical(other.bonuses, bonuses) || const DeepCollectionEquality().equals(other.bonuses, bonuses)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(rarity) ^
      const DeepCollectionEquality().hash(uid) ^
      const DeepCollectionEquality().hash(stats) ^
      const DeepCollectionEquality().hash(bonuses) ^
      runtimeType.hashCode;
}

extension $UserItemMarkeListingItemDetailsExtension on UserItemMarkeListingItemDetails {
  UserItemMarkeListingItemDetails copyWith(
      {int? id,
      String? name,
      String? type,
      enums.UserItemMarkeListingItemDetailsRarity? rarity,
      int? uid,
      ItemMarketListingItemStats? stats,
      List<ItemMarketListingItemBonus>? bonuses}) {
    return UserItemMarkeListingItemDetails(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        rarity: rarity ?? this.rarity,
        uid: uid ?? this.uid,
        stats: stats ?? this.stats,
        bonuses: bonuses ?? this.bonuses);
  }

  UserItemMarkeListingItemDetails copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<String?>? type,
      Wrapped<enums.UserItemMarkeListingItemDetailsRarity?>? rarity,
      Wrapped<int?>? uid,
      Wrapped<ItemMarketListingItemStats?>? stats,
      Wrapped<List<ItemMarketListingItemBonus>?>? bonuses}) {
    return UserItemMarkeListingItemDetails(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        type: (type != null ? type.value : this.type),
        rarity: (rarity != null ? rarity.value : this.rarity),
        uid: (uid != null ? uid.value : this.uid),
        stats: (stats != null ? stats.value : this.stats),
        bonuses: (bonuses != null ? bonuses.value : this.bonuses));
  }
}

@JsonSerializable(explicitToJson: true)
class UserItemMarketListing {
  const UserItemMarketListing({
    this.id,
    this.price,
    this.averagePrice,
    this.amount,
    this.isAnonymous,
    this.available,
    this.item,
  });

  factory UserItemMarketListing.fromJson(Map<String, dynamic> json) => _$UserItemMarketListingFromJson(json);

  static const toJsonFactory = _$UserItemMarketListingToJson;
  Map<String, dynamic> toJson() => _$UserItemMarketListingToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'price')
  final int? price;
  @JsonKey(name: 'average_price')
  final int? averagePrice;
  @JsonKey(name: 'amount')
  final int? amount;
  @JsonKey(name: 'is_anonymous')
  final bool? isAnonymous;
  @JsonKey(name: 'available')
  final int? available;
  @JsonKey(name: 'item')
  final UserItemMarkeListingItemDetails? item;
  static const fromJsonFactory = _$UserItemMarketListingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserItemMarketListing &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.price, price) || const DeepCollectionEquality().equals(other.price, price)) &&
            (identical(other.averagePrice, averagePrice) ||
                const DeepCollectionEquality().equals(other.averagePrice, averagePrice)) &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.isAnonymous, isAnonymous) ||
                const DeepCollectionEquality().equals(other.isAnonymous, isAnonymous)) &&
            (identical(other.available, available) ||
                const DeepCollectionEquality().equals(other.available, available)) &&
            (identical(other.item, item) || const DeepCollectionEquality().equals(other.item, item)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(price) ^
      const DeepCollectionEquality().hash(averagePrice) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(isAnonymous) ^
      const DeepCollectionEquality().hash(available) ^
      const DeepCollectionEquality().hash(item) ^
      runtimeType.hashCode;
}

extension $UserItemMarketListingExtension on UserItemMarketListing {
  UserItemMarketListing copyWith(
      {int? id,
      int? price,
      int? averagePrice,
      int? amount,
      bool? isAnonymous,
      int? available,
      UserItemMarkeListingItemDetails? item}) {
    return UserItemMarketListing(
        id: id ?? this.id,
        price: price ?? this.price,
        averagePrice: averagePrice ?? this.averagePrice,
        amount: amount ?? this.amount,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        available: available ?? this.available,
        item: item ?? this.item);
  }

  UserItemMarketListing copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<int?>? price,
      Wrapped<int?>? averagePrice,
      Wrapped<int?>? amount,
      Wrapped<bool?>? isAnonymous,
      Wrapped<int?>? available,
      Wrapped<UserItemMarkeListingItemDetails?>? item}) {
    return UserItemMarketListing(
        id: (id != null ? id.value : this.id),
        price: (price != null ? price.value : this.price),
        averagePrice: (averagePrice != null ? averagePrice.value : this.averagePrice),
        amount: (amount != null ? amount.value : this.amount),
        isAnonymous: (isAnonymous != null ? isAnonymous.value : this.isAnonymous),
        available: (available != null ? available.value : this.available),
        item: (item != null ? item.value : this.item));
  }
}

@JsonSerializable(explicitToJson: true)
class UserItemMarketResponse {
  const UserItemMarketResponse({
    this.itemmarket,
    this.metadata,
  });

  factory UserItemMarketResponse.fromJson(Map<String, dynamic> json) => _$UserItemMarketResponseFromJson(json);

  static const toJsonFactory = _$UserItemMarketResponseToJson;
  Map<String, dynamic> toJson() => _$UserItemMarketResponseToJson(this);

  @JsonKey(name: 'itemmarket', defaultValue: <UserItemMarketListing>[])
  final List<UserItemMarketListing>? itemmarket;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$UserItemMarketResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserItemMarketResponse &&
            (identical(other.itemmarket, itemmarket) ||
                const DeepCollectionEquality().equals(other.itemmarket, itemmarket)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(itemmarket) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $UserItemMarketResponseExtension on UserItemMarketResponse {
  UserItemMarketResponse copyWith({List<UserItemMarketListing>? itemmarket, RequestMetadataWithLinks? metadata}) {
    return UserItemMarketResponse(itemmarket: itemmarket ?? this.itemmarket, metadata: metadata ?? this.metadata);
  }

  UserItemMarketResponse copyWithWrapped(
      {Wrapped<List<UserItemMarketListing>?>? itemmarket, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return UserItemMarketResponse(
        itemmarket: (itemmarket != null ? itemmarket.value : this.itemmarket),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class UserFactionBalance {
  const UserFactionBalance({
    this.money,
    this.points,
  });

  factory UserFactionBalance.fromJson(Map<String, dynamic> json) => _$UserFactionBalanceFromJson(json);

  static const toJsonFactory = _$UserFactionBalanceToJson;
  Map<String, dynamic> toJson() => _$UserFactionBalanceToJson(this);

  @JsonKey(name: 'money')
  final int? money;
  @JsonKey(name: 'points')
  final int? points;
  static const fromJsonFactory = _$UserFactionBalanceFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserFactionBalance &&
            (identical(other.money, money) || const DeepCollectionEquality().equals(other.money, money)) &&
            (identical(other.points, points) || const DeepCollectionEquality().equals(other.points, points)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(money) ^ const DeepCollectionEquality().hash(points) ^ runtimeType.hashCode;
}

extension $UserFactionBalanceExtension on UserFactionBalance {
  UserFactionBalance copyWith({int? money, int? points}) {
    return UserFactionBalance(money: money ?? this.money, points: points ?? this.points);
  }

  UserFactionBalance copyWithWrapped({Wrapped<int?>? money, Wrapped<int?>? points}) {
    return UserFactionBalance(
        money: (money != null ? money.value : this.money), points: (points != null ? points.value : this.points));
  }
}

@JsonSerializable(explicitToJson: true)
class UserFactionBalanceResponse {
  const UserFactionBalanceResponse({
    this.factionBalance,
  });

  factory UserFactionBalanceResponse.fromJson(Map<String, dynamic> json) => _$UserFactionBalanceResponseFromJson(json);

  static const toJsonFactory = _$UserFactionBalanceResponseToJson;
  Map<String, dynamic> toJson() => _$UserFactionBalanceResponseToJson(this);

  @JsonKey(name: 'factionBalance')
  final Object? factionBalance;
  static const fromJsonFactory = _$UserFactionBalanceResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserFactionBalanceResponse &&
            (identical(other.factionBalance, factionBalance) ||
                const DeepCollectionEquality().equals(other.factionBalance, factionBalance)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(factionBalance) ^ runtimeType.hashCode;
}

extension $UserFactionBalanceResponseExtension on UserFactionBalanceResponse {
  UserFactionBalanceResponse copyWith({Object? factionBalance}) {
    return UserFactionBalanceResponse(factionBalance: factionBalance ?? this.factionBalance);
  }

  UserFactionBalanceResponse copyWithWrapped({Wrapped<Object?>? factionBalance}) {
    return UserFactionBalanceResponse(
        factionBalance: (factionBalance != null ? factionBalance.value : this.factionBalance));
  }
}

@JsonSerializable(explicitToJson: true)
class UserOrganizedCrimeResponse {
  const UserOrganizedCrimeResponse({
    this.organizedCrime,
  });

  factory UserOrganizedCrimeResponse.fromJson(Map<String, dynamic> json) => _$UserOrganizedCrimeResponseFromJson(json);

  static const toJsonFactory = _$UserOrganizedCrimeResponseToJson;
  Map<String, dynamic> toJson() => _$UserOrganizedCrimeResponseToJson(this);

  @JsonKey(name: 'organizedCrime')
  final Object? organizedCrime;
  static const fromJsonFactory = _$UserOrganizedCrimeResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserOrganizedCrimeResponse &&
            (identical(other.organizedCrime, organizedCrime) ||
                const DeepCollectionEquality().equals(other.organizedCrime, organizedCrime)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(organizedCrime) ^ runtimeType.hashCode;
}

extension $UserOrganizedCrimeResponseExtension on UserOrganizedCrimeResponse {
  UserOrganizedCrimeResponse copyWith({Object? organizedCrime}) {
    return UserOrganizedCrimeResponse(organizedCrime: organizedCrime ?? this.organizedCrime);
  }

  UserOrganizedCrimeResponse copyWithWrapped({Wrapped<Object?>? organizedCrime}) {
    return UserOrganizedCrimeResponse(
        organizedCrime: (organizedCrime != null ? organizedCrime.value : this.organizedCrime));
  }
}

@JsonSerializable(explicitToJson: true)
class UserLookupResponse {
  const UserLookupResponse({
    this.selections,
  });

  factory UserLookupResponse.fromJson(Map<String, dynamic> json) => _$UserLookupResponseFromJson(json);

  static const toJsonFactory = _$UserLookupResponseToJson;
  Map<String, dynamic> toJson() => _$UserLookupResponseToJson(this);

  @JsonKey(
    name: 'selections',
    toJson: userSelectionNameListToJson,
    fromJson: userSelectionNameListFromJson,
  )
  final List<enums.UserSelectionName>? selections;
  static const fromJsonFactory = _$UserLookupResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserLookupResponse &&
            (identical(other.selections, selections) ||
                const DeepCollectionEquality().equals(other.selections, selections)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(selections) ^ runtimeType.hashCode;
}

extension $UserLookupResponseExtension on UserLookupResponse {
  UserLookupResponse copyWith({List<enums.UserSelectionName>? selections}) {
    return UserLookupResponse(selections: selections ?? this.selections);
  }

  UserLookupResponse copyWithWrapped({Wrapped<List<enums.UserSelectionName>?>? selections}) {
    return UserLookupResponse(selections: (selections != null ? selections.value : this.selections));
  }
}

@JsonSerializable(explicitToJson: true)
class Attack$Modifiers {
  const Attack$Modifiers({
    this.fairFight,
    this.war,
    this.retaliation,
    this.group,
    this.overseas,
    this.chain,
    this.warlord,
  });

  factory Attack$Modifiers.fromJson(Map<String, dynamic> json) => _$Attack$ModifiersFromJson(json);

  static const toJsonFactory = _$Attack$ModifiersToJson;
  Map<String, dynamic> toJson() => _$Attack$ModifiersToJson(this);

  @JsonKey(name: 'fair_fight')
  final double? fairFight;
  @JsonKey(name: 'war')
  final double? war;
  @JsonKey(name: 'retaliation')
  final double? retaliation;
  @JsonKey(name: 'group')
  final double? group;
  @JsonKey(name: 'overseas')
  final double? overseas;
  @JsonKey(name: 'chain')
  final double? chain;
  @JsonKey(name: 'warlord')
  final double? warlord;
  static const fromJsonFactory = _$Attack$ModifiersFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Attack$Modifiers &&
            (identical(other.fairFight, fairFight) ||
                const DeepCollectionEquality().equals(other.fairFight, fairFight)) &&
            (identical(other.war, war) || const DeepCollectionEquality().equals(other.war, war)) &&
            (identical(other.retaliation, retaliation) ||
                const DeepCollectionEquality().equals(other.retaliation, retaliation)) &&
            (identical(other.group, group) || const DeepCollectionEquality().equals(other.group, group)) &&
            (identical(other.overseas, overseas) || const DeepCollectionEquality().equals(other.overseas, overseas)) &&
            (identical(other.chain, chain) || const DeepCollectionEquality().equals(other.chain, chain)) &&
            (identical(other.warlord, warlord) || const DeepCollectionEquality().equals(other.warlord, warlord)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(fairFight) ^
      const DeepCollectionEquality().hash(war) ^
      const DeepCollectionEquality().hash(retaliation) ^
      const DeepCollectionEquality().hash(group) ^
      const DeepCollectionEquality().hash(overseas) ^
      const DeepCollectionEquality().hash(chain) ^
      const DeepCollectionEquality().hash(warlord) ^
      runtimeType.hashCode;
}

extension $Attack$ModifiersExtension on Attack$Modifiers {
  Attack$Modifiers copyWith(
      {double? fairFight,
      double? war,
      double? retaliation,
      double? group,
      double? overseas,
      double? chain,
      double? warlord}) {
    return Attack$Modifiers(
        fairFight: fairFight ?? this.fairFight,
        war: war ?? this.war,
        retaliation: retaliation ?? this.retaliation,
        group: group ?? this.group,
        overseas: overseas ?? this.overseas,
        chain: chain ?? this.chain,
        warlord: warlord ?? this.warlord);
  }

  Attack$Modifiers copyWithWrapped(
      {Wrapped<double?>? fairFight,
      Wrapped<double?>? war,
      Wrapped<double?>? retaliation,
      Wrapped<double?>? group,
      Wrapped<double?>? overseas,
      Wrapped<double?>? chain,
      Wrapped<double?>? warlord}) {
    return Attack$Modifiers(
        fairFight: (fairFight != null ? fairFight.value : this.fairFight),
        war: (war != null ? war.value : this.war),
        retaliation: (retaliation != null ? retaliation.value : this.retaliation),
        group: (group != null ? group.value : this.group),
        overseas: (overseas != null ? overseas.value : this.overseas),
        chain: (chain != null ? chain.value : this.chain),
        warlord: (warlord != null ? warlord.value : this.warlord));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionApplication$User {
  const FactionApplication$User({
    this.id,
    this.name,
    this.level,
    this.stats,
  });

  factory FactionApplication$User.fromJson(Map<String, dynamic> json) => _$FactionApplication$UserFromJson(json);

  static const toJsonFactory = _$FactionApplication$UserToJson;
  Map<String, dynamic> toJson() => _$FactionApplication$UserToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'level')
  final String? level;
  @JsonKey(name: 'stats')
  final FactionApplication$User$Stats? stats;
  static const fromJsonFactory = _$FactionApplication$UserFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionApplication$User &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) || const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.level, level) || const DeepCollectionEquality().equals(other.level, level)) &&
            (identical(other.stats, stats) || const DeepCollectionEquality().equals(other.stats, stats)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(level) ^
      const DeepCollectionEquality().hash(stats) ^
      runtimeType.hashCode;
}

extension $FactionApplication$UserExtension on FactionApplication$User {
  FactionApplication$User copyWith({int? id, String? name, String? level, FactionApplication$User$Stats? stats}) {
    return FactionApplication$User(
        id: id ?? this.id, name: name ?? this.name, level: level ?? this.level, stats: stats ?? this.stats);
  }

  FactionApplication$User copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<String?>? level,
      Wrapped<FactionApplication$User$Stats?>? stats}) {
    return FactionApplication$User(
        id: (id != null ? id.value : this.id),
        name: (name != null ? name.value : this.name),
        level: (level != null ? level.value : this.level),
        stats: (stats != null ? stats.value : this.stats));
  }
}

@JsonSerializable(explicitToJson: true)
class ForumCategoriesResponse$Categories$Item {
  const ForumCategoriesResponse$Categories$Item({
    this.id,
    this.title,
    this.acronym,
    this.threads,
  });

  factory ForumCategoriesResponse$Categories$Item.fromJson(Map<String, dynamic> json) =>
      _$ForumCategoriesResponse$Categories$ItemFromJson(json);

  static const toJsonFactory = _$ForumCategoriesResponse$Categories$ItemToJson;
  Map<String, dynamic> toJson() => _$ForumCategoriesResponse$Categories$ItemToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'acronym')
  final String? acronym;
  @JsonKey(name: 'threads')
  final int? threads;
  static const fromJsonFactory = _$ForumCategoriesResponse$Categories$ItemFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumCategoriesResponse$Categories$Item &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) || const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.acronym, acronym) || const DeepCollectionEquality().equals(other.acronym, acronym)) &&
            (identical(other.threads, threads) || const DeepCollectionEquality().equals(other.threads, threads)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(acronym) ^
      const DeepCollectionEquality().hash(threads) ^
      runtimeType.hashCode;
}

extension $ForumCategoriesResponse$Categories$ItemExtension on ForumCategoriesResponse$Categories$Item {
  ForumCategoriesResponse$Categories$Item copyWith({int? id, String? title, String? acronym, int? threads}) {
    return ForumCategoriesResponse$Categories$Item(
        id: id ?? this.id,
        title: title ?? this.title,
        acronym: acronym ?? this.acronym,
        threads: threads ?? this.threads);
  }

  ForumCategoriesResponse$Categories$Item copyWithWrapped(
      {Wrapped<int?>? id, Wrapped<String?>? title, Wrapped<String?>? acronym, Wrapped<int?>? threads}) {
    return ForumCategoriesResponse$Categories$Item(
        id: (id != null ? id.value : this.id),
        title: (title != null ? title.value : this.title),
        acronym: (acronym != null ? acronym.value : this.acronym),
        threads: (threads != null ? threads.value : this.threads));
  }
}

@JsonSerializable(explicitToJson: true)
class RaceCarUpgrade$Effects {
  const RaceCarUpgrade$Effects({
    this.topSpeed,
    this.acceleration,
    this.braking,
    this.handling,
    this.safety,
    this.dirt,
    this.tarmac,
  });

  factory RaceCarUpgrade$Effects.fromJson(Map<String, dynamic> json) => _$RaceCarUpgrade$EffectsFromJson(json);

  static const toJsonFactory = _$RaceCarUpgrade$EffectsToJson;
  Map<String, dynamic> toJson() => _$RaceCarUpgrade$EffectsToJson(this);

  @JsonKey(name: 'top_speed')
  final int? topSpeed;
  @JsonKey(name: 'acceleration')
  final int? acceleration;
  @JsonKey(name: 'braking')
  final int? braking;
  @JsonKey(name: 'handling')
  final int? handling;
  @JsonKey(name: 'safety')
  final int? safety;
  @JsonKey(name: 'dirt')
  final int? dirt;
  @JsonKey(name: 'tarmac')
  final int? tarmac;
  static const fromJsonFactory = _$RaceCarUpgrade$EffectsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RaceCarUpgrade$Effects &&
            (identical(other.topSpeed, topSpeed) || const DeepCollectionEquality().equals(other.topSpeed, topSpeed)) &&
            (identical(other.acceleration, acceleration) ||
                const DeepCollectionEquality().equals(other.acceleration, acceleration)) &&
            (identical(other.braking, braking) || const DeepCollectionEquality().equals(other.braking, braking)) &&
            (identical(other.handling, handling) || const DeepCollectionEquality().equals(other.handling, handling)) &&
            (identical(other.safety, safety) || const DeepCollectionEquality().equals(other.safety, safety)) &&
            (identical(other.dirt, dirt) || const DeepCollectionEquality().equals(other.dirt, dirt)) &&
            (identical(other.tarmac, tarmac) || const DeepCollectionEquality().equals(other.tarmac, tarmac)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(topSpeed) ^
      const DeepCollectionEquality().hash(acceleration) ^
      const DeepCollectionEquality().hash(braking) ^
      const DeepCollectionEquality().hash(handling) ^
      const DeepCollectionEquality().hash(safety) ^
      const DeepCollectionEquality().hash(dirt) ^
      const DeepCollectionEquality().hash(tarmac) ^
      runtimeType.hashCode;
}

extension $RaceCarUpgrade$EffectsExtension on RaceCarUpgrade$Effects {
  RaceCarUpgrade$Effects copyWith(
      {int? topSpeed, int? acceleration, int? braking, int? handling, int? safety, int? dirt, int? tarmac}) {
    return RaceCarUpgrade$Effects(
        topSpeed: topSpeed ?? this.topSpeed,
        acceleration: acceleration ?? this.acceleration,
        braking: braking ?? this.braking,
        handling: handling ?? this.handling,
        safety: safety ?? this.safety,
        dirt: dirt ?? this.dirt,
        tarmac: tarmac ?? this.tarmac);
  }

  RaceCarUpgrade$Effects copyWithWrapped(
      {Wrapped<int?>? topSpeed,
      Wrapped<int?>? acceleration,
      Wrapped<int?>? braking,
      Wrapped<int?>? handling,
      Wrapped<int?>? safety,
      Wrapped<int?>? dirt,
      Wrapped<int?>? tarmac}) {
    return RaceCarUpgrade$Effects(
        topSpeed: (topSpeed != null ? topSpeed.value : this.topSpeed),
        acceleration: (acceleration != null ? acceleration.value : this.acceleration),
        braking: (braking != null ? braking.value : this.braking),
        handling: (handling != null ? handling.value : this.handling),
        safety: (safety != null ? safety.value : this.safety),
        dirt: (dirt != null ? dirt.value : this.dirt),
        tarmac: (tarmac != null ? tarmac.value : this.tarmac));
  }
}

@JsonSerializable(explicitToJson: true)
class RaceCarUpgrade$Cost {
  const RaceCarUpgrade$Cost({
    this.points,
    this.cash,
  });

  factory RaceCarUpgrade$Cost.fromJson(Map<String, dynamic> json) => _$RaceCarUpgrade$CostFromJson(json);

  static const toJsonFactory = _$RaceCarUpgrade$CostToJson;
  Map<String, dynamic> toJson() => _$RaceCarUpgrade$CostToJson(this);

  @JsonKey(name: 'points')
  final int? points;
  @JsonKey(name: 'cash')
  final int? cash;
  static const fromJsonFactory = _$RaceCarUpgrade$CostFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RaceCarUpgrade$Cost &&
            (identical(other.points, points) || const DeepCollectionEquality().equals(other.points, points)) &&
            (identical(other.cash, cash) || const DeepCollectionEquality().equals(other.cash, cash)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(points) ^ const DeepCollectionEquality().hash(cash) ^ runtimeType.hashCode;
}

extension $RaceCarUpgrade$CostExtension on RaceCarUpgrade$Cost {
  RaceCarUpgrade$Cost copyWith({int? points, int? cash}) {
    return RaceCarUpgrade$Cost(points: points ?? this.points, cash: cash ?? this.cash);
  }

  RaceCarUpgrade$Cost copyWithWrapped({Wrapped<int?>? points, Wrapped<int?>? cash}) {
    return RaceCarUpgrade$Cost(
        points: (points != null ? points.value : this.points), cash: (cash != null ? cash.value : this.cash));
  }
}

@JsonSerializable(explicitToJson: true)
class Race$Participants {
  const Race$Participants({
    this.minimum,
    this.maximum,
    this.current,
  });

  factory Race$Participants.fromJson(Map<String, dynamic> json) => _$Race$ParticipantsFromJson(json);

  static const toJsonFactory = _$Race$ParticipantsToJson;
  Map<String, dynamic> toJson() => _$Race$ParticipantsToJson(this);

  @JsonKey(name: 'minimum')
  final int? minimum;
  @JsonKey(name: 'maximum')
  final int? maximum;
  @JsonKey(name: 'current')
  final int? current;
  static const fromJsonFactory = _$Race$ParticipantsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Race$Participants &&
            (identical(other.minimum, minimum) || const DeepCollectionEquality().equals(other.minimum, minimum)) &&
            (identical(other.maximum, maximum) || const DeepCollectionEquality().equals(other.maximum, maximum)) &&
            (identical(other.current, current) || const DeepCollectionEquality().equals(other.current, current)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(minimum) ^
      const DeepCollectionEquality().hash(maximum) ^
      const DeepCollectionEquality().hash(current) ^
      runtimeType.hashCode;
}

extension $Race$ParticipantsExtension on Race$Participants {
  Race$Participants copyWith({int? minimum, int? maximum, int? current}) {
    return Race$Participants(
        minimum: minimum ?? this.minimum, maximum: maximum ?? this.maximum, current: current ?? this.current);
  }

  Race$Participants copyWithWrapped({Wrapped<int?>? minimum, Wrapped<int?>? maximum, Wrapped<int?>? current}) {
    return Race$Participants(
        minimum: (minimum != null ? minimum.value : this.minimum),
        maximum: (maximum != null ? maximum.value : this.maximum),
        current: (current != null ? current.value : this.current));
  }
}

@JsonSerializable(explicitToJson: true)
class Race$Schedule {
  const Race$Schedule({
    this.joinFrom,
    this.joinUntil,
    this.start,
    this.end,
  });

  factory Race$Schedule.fromJson(Map<String, dynamic> json) => _$Race$ScheduleFromJson(json);

  static const toJsonFactory = _$Race$ScheduleToJson;
  Map<String, dynamic> toJson() => _$Race$ScheduleToJson(this);

  @JsonKey(name: 'join_from')
  final int? joinFrom;
  @JsonKey(name: 'join_until')
  final int? joinUntil;
  @JsonKey(name: 'start')
  final int? start;
  @JsonKey(name: 'end')
  final int? end;
  static const fromJsonFactory = _$Race$ScheduleFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Race$Schedule &&
            (identical(other.joinFrom, joinFrom) || const DeepCollectionEquality().equals(other.joinFrom, joinFrom)) &&
            (identical(other.joinUntil, joinUntil) ||
                const DeepCollectionEquality().equals(other.joinUntil, joinUntil)) &&
            (identical(other.start, start) || const DeepCollectionEquality().equals(other.start, start)) &&
            (identical(other.end, end) || const DeepCollectionEquality().equals(other.end, end)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(joinFrom) ^
      const DeepCollectionEquality().hash(joinUntil) ^
      const DeepCollectionEquality().hash(start) ^
      const DeepCollectionEquality().hash(end) ^
      runtimeType.hashCode;
}

extension $Race$ScheduleExtension on Race$Schedule {
  Race$Schedule copyWith({int? joinFrom, int? joinUntil, int? start, int? end}) {
    return Race$Schedule(
        joinFrom: joinFrom ?? this.joinFrom,
        joinUntil: joinUntil ?? this.joinUntil,
        start: start ?? this.start,
        end: end ?? this.end);
  }

  Race$Schedule copyWithWrapped(
      {Wrapped<int?>? joinFrom, Wrapped<int?>? joinUntil, Wrapped<int?>? start, Wrapped<int?>? end}) {
    return Race$Schedule(
        joinFrom: (joinFrom != null ? joinFrom.value : this.joinFrom),
        joinUntil: (joinUntil != null ? joinUntil.value : this.joinUntil),
        start: (start != null ? start.value : this.start),
        end: (end != null ? end.value : this.end));
  }
}

@JsonSerializable(explicitToJson: true)
class Race$Requirements {
  const Race$Requirements({
    this.carClass,
    this.driverClass,
    this.carItemId,
    this.requiresStockCar,
    this.requiresPassword,
    this.joinFee,
  });

  factory Race$Requirements.fromJson(Map<String, dynamic> json) => _$Race$RequirementsFromJson(json);

  static const toJsonFactory = _$Race$RequirementsToJson;
  Map<String, dynamic> toJson() => _$Race$RequirementsToJson(this);

  @JsonKey(
    name: 'car_class',
    toJson: raceClassEnumNullableToJson,
    fromJson: raceClassEnumNullableFromJson,
  )
  final enums.RaceClassEnum? carClass;
  @JsonKey(
    name: 'driver_class',
    toJson: raceClassEnumNullableToJson,
    fromJson: raceClassEnumNullableFromJson,
  )
  final enums.RaceClassEnum? driverClass;
  @JsonKey(name: 'car_item_id')
  final int? carItemId;
  @JsonKey(name: 'requires_stock_car')
  final bool? requiresStockCar;
  @JsonKey(name: 'requires_password')
  final bool? requiresPassword;
  @JsonKey(name: 'join_fee')
  final int? joinFee;
  static const fromJsonFactory = _$Race$RequirementsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Race$Requirements &&
            (identical(other.carClass, carClass) || const DeepCollectionEquality().equals(other.carClass, carClass)) &&
            (identical(other.driverClass, driverClass) ||
                const DeepCollectionEquality().equals(other.driverClass, driverClass)) &&
            (identical(other.carItemId, carItemId) ||
                const DeepCollectionEquality().equals(other.carItemId, carItemId)) &&
            (identical(other.requiresStockCar, requiresStockCar) ||
                const DeepCollectionEquality().equals(other.requiresStockCar, requiresStockCar)) &&
            (identical(other.requiresPassword, requiresPassword) ||
                const DeepCollectionEquality().equals(other.requiresPassword, requiresPassword)) &&
            (identical(other.joinFee, joinFee) || const DeepCollectionEquality().equals(other.joinFee, joinFee)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(carClass) ^
      const DeepCollectionEquality().hash(driverClass) ^
      const DeepCollectionEquality().hash(carItemId) ^
      const DeepCollectionEquality().hash(requiresStockCar) ^
      const DeepCollectionEquality().hash(requiresPassword) ^
      const DeepCollectionEquality().hash(joinFee) ^
      runtimeType.hashCode;
}

extension $Race$RequirementsExtension on Race$Requirements {
  Race$Requirements copyWith(
      {enums.RaceClassEnum? carClass,
      enums.RaceClassEnum? driverClass,
      int? carItemId,
      bool? requiresStockCar,
      bool? requiresPassword,
      int? joinFee}) {
    return Race$Requirements(
        carClass: carClass ?? this.carClass,
        driverClass: driverClass ?? this.driverClass,
        carItemId: carItemId ?? this.carItemId,
        requiresStockCar: requiresStockCar ?? this.requiresStockCar,
        requiresPassword: requiresPassword ?? this.requiresPassword,
        joinFee: joinFee ?? this.joinFee);
  }

  Race$Requirements copyWithWrapped(
      {Wrapped<enums.RaceClassEnum?>? carClass,
      Wrapped<enums.RaceClassEnum?>? driverClass,
      Wrapped<int?>? carItemId,
      Wrapped<bool?>? requiresStockCar,
      Wrapped<bool?>? requiresPassword,
      Wrapped<int?>? joinFee}) {
    return Race$Requirements(
        carClass: (carClass != null ? carClass.value : this.carClass),
        driverClass: (driverClass != null ? driverClass.value : this.driverClass),
        carItemId: (carItemId != null ? carItemId.value : this.carItemId),
        requiresStockCar: (requiresStockCar != null ? requiresStockCar.value : this.requiresStockCar),
        requiresPassword: (requiresPassword != null ? requiresPassword.value : this.requiresPassword),
        joinFee: (joinFee != null ? joinFee.value : this.joinFee));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingRaceDetailsResponse$Participants {
  const RacingRaceDetailsResponse$Participants({
    this.minimum,
    this.maximum,
    this.current,
  });

  factory RacingRaceDetailsResponse$Participants.fromJson(Map<String, dynamic> json) =>
      _$RacingRaceDetailsResponse$ParticipantsFromJson(json);

  static const toJsonFactory = _$RacingRaceDetailsResponse$ParticipantsToJson;
  Map<String, dynamic> toJson() => _$RacingRaceDetailsResponse$ParticipantsToJson(this);

  @JsonKey(name: 'minimum')
  final int? minimum;
  @JsonKey(name: 'maximum')
  final int? maximum;
  @JsonKey(name: 'current')
  final int? current;
  static const fromJsonFactory = _$RacingRaceDetailsResponse$ParticipantsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingRaceDetailsResponse$Participants &&
            (identical(other.minimum, minimum) || const DeepCollectionEquality().equals(other.minimum, minimum)) &&
            (identical(other.maximum, maximum) || const DeepCollectionEquality().equals(other.maximum, maximum)) &&
            (identical(other.current, current) || const DeepCollectionEquality().equals(other.current, current)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(minimum) ^
      const DeepCollectionEquality().hash(maximum) ^
      const DeepCollectionEquality().hash(current) ^
      runtimeType.hashCode;
}

extension $RacingRaceDetailsResponse$ParticipantsExtension on RacingRaceDetailsResponse$Participants {
  RacingRaceDetailsResponse$Participants copyWith({int? minimum, int? maximum, int? current}) {
    return RacingRaceDetailsResponse$Participants(
        minimum: minimum ?? this.minimum, maximum: maximum ?? this.maximum, current: current ?? this.current);
  }

  RacingRaceDetailsResponse$Participants copyWithWrapped(
      {Wrapped<int?>? minimum, Wrapped<int?>? maximum, Wrapped<int?>? current}) {
    return RacingRaceDetailsResponse$Participants(
        minimum: (minimum != null ? minimum.value : this.minimum),
        maximum: (maximum != null ? maximum.value : this.maximum),
        current: (current != null ? current.value : this.current));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingRaceDetailsResponse$Schedule {
  const RacingRaceDetailsResponse$Schedule({
    this.joinFrom,
    this.joinUntil,
    this.start,
    this.end,
  });

  factory RacingRaceDetailsResponse$Schedule.fromJson(Map<String, dynamic> json) =>
      _$RacingRaceDetailsResponse$ScheduleFromJson(json);

  static const toJsonFactory = _$RacingRaceDetailsResponse$ScheduleToJson;
  Map<String, dynamic> toJson() => _$RacingRaceDetailsResponse$ScheduleToJson(this);

  @JsonKey(name: 'join_from')
  final int? joinFrom;
  @JsonKey(name: 'join_until')
  final int? joinUntil;
  @JsonKey(name: 'start')
  final int? start;
  @JsonKey(name: 'end')
  final int? end;
  static const fromJsonFactory = _$RacingRaceDetailsResponse$ScheduleFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingRaceDetailsResponse$Schedule &&
            (identical(other.joinFrom, joinFrom) || const DeepCollectionEquality().equals(other.joinFrom, joinFrom)) &&
            (identical(other.joinUntil, joinUntil) ||
                const DeepCollectionEquality().equals(other.joinUntil, joinUntil)) &&
            (identical(other.start, start) || const DeepCollectionEquality().equals(other.start, start)) &&
            (identical(other.end, end) || const DeepCollectionEquality().equals(other.end, end)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(joinFrom) ^
      const DeepCollectionEquality().hash(joinUntil) ^
      const DeepCollectionEquality().hash(start) ^
      const DeepCollectionEquality().hash(end) ^
      runtimeType.hashCode;
}

extension $RacingRaceDetailsResponse$ScheduleExtension on RacingRaceDetailsResponse$Schedule {
  RacingRaceDetailsResponse$Schedule copyWith({int? joinFrom, int? joinUntil, int? start, int? end}) {
    return RacingRaceDetailsResponse$Schedule(
        joinFrom: joinFrom ?? this.joinFrom,
        joinUntil: joinUntil ?? this.joinUntil,
        start: start ?? this.start,
        end: end ?? this.end);
  }

  RacingRaceDetailsResponse$Schedule copyWithWrapped(
      {Wrapped<int?>? joinFrom, Wrapped<int?>? joinUntil, Wrapped<int?>? start, Wrapped<int?>? end}) {
    return RacingRaceDetailsResponse$Schedule(
        joinFrom: (joinFrom != null ? joinFrom.value : this.joinFrom),
        joinUntil: (joinUntil != null ? joinUntil.value : this.joinUntil),
        start: (start != null ? start.value : this.start),
        end: (end != null ? end.value : this.end));
  }
}

@JsonSerializable(explicitToJson: true)
class RacingRaceDetailsResponse$Requirements {
  const RacingRaceDetailsResponse$Requirements({
    this.carClass,
    this.driverClass,
    this.carItemId,
    this.requiresStockCar,
    this.requiresPassword,
    this.joinFee,
  });

  factory RacingRaceDetailsResponse$Requirements.fromJson(Map<String, dynamic> json) =>
      _$RacingRaceDetailsResponse$RequirementsFromJson(json);

  static const toJsonFactory = _$RacingRaceDetailsResponse$RequirementsToJson;
  Map<String, dynamic> toJson() => _$RacingRaceDetailsResponse$RequirementsToJson(this);

  @JsonKey(
    name: 'car_class',
    toJson: raceClassEnumNullableToJson,
    fromJson: raceClassEnumNullableFromJson,
  )
  final enums.RaceClassEnum? carClass;
  @JsonKey(
    name: 'driver_class',
    toJson: raceClassEnumNullableToJson,
    fromJson: raceClassEnumNullableFromJson,
  )
  final enums.RaceClassEnum? driverClass;
  @JsonKey(name: 'car_item_id')
  final int? carItemId;
  @JsonKey(name: 'requires_stock_car')
  final bool? requiresStockCar;
  @JsonKey(name: 'requires_password')
  final bool? requiresPassword;
  @JsonKey(name: 'join_fee')
  final int? joinFee;
  static const fromJsonFactory = _$RacingRaceDetailsResponse$RequirementsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RacingRaceDetailsResponse$Requirements &&
            (identical(other.carClass, carClass) || const DeepCollectionEquality().equals(other.carClass, carClass)) &&
            (identical(other.driverClass, driverClass) ||
                const DeepCollectionEquality().equals(other.driverClass, driverClass)) &&
            (identical(other.carItemId, carItemId) ||
                const DeepCollectionEquality().equals(other.carItemId, carItemId)) &&
            (identical(other.requiresStockCar, requiresStockCar) ||
                const DeepCollectionEquality().equals(other.requiresStockCar, requiresStockCar)) &&
            (identical(other.requiresPassword, requiresPassword) ||
                const DeepCollectionEquality().equals(other.requiresPassword, requiresPassword)) &&
            (identical(other.joinFee, joinFee) || const DeepCollectionEquality().equals(other.joinFee, joinFee)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(carClass) ^
      const DeepCollectionEquality().hash(driverClass) ^
      const DeepCollectionEquality().hash(carItemId) ^
      const DeepCollectionEquality().hash(requiresStockCar) ^
      const DeepCollectionEquality().hash(requiresPassword) ^
      const DeepCollectionEquality().hash(joinFee) ^
      runtimeType.hashCode;
}

extension $RacingRaceDetailsResponse$RequirementsExtension on RacingRaceDetailsResponse$Requirements {
  RacingRaceDetailsResponse$Requirements copyWith(
      {enums.RaceClassEnum? carClass,
      enums.RaceClassEnum? driverClass,
      int? carItemId,
      bool? requiresStockCar,
      bool? requiresPassword,
      int? joinFee}) {
    return RacingRaceDetailsResponse$Requirements(
        carClass: carClass ?? this.carClass,
        driverClass: driverClass ?? this.driverClass,
        carItemId: carItemId ?? this.carItemId,
        requiresStockCar: requiresStockCar ?? this.requiresStockCar,
        requiresPassword: requiresPassword ?? this.requiresPassword,
        joinFee: joinFee ?? this.joinFee);
  }

  RacingRaceDetailsResponse$Requirements copyWithWrapped(
      {Wrapped<enums.RaceClassEnum?>? carClass,
      Wrapped<enums.RaceClassEnum?>? driverClass,
      Wrapped<int?>? carItemId,
      Wrapped<bool?>? requiresStockCar,
      Wrapped<bool?>? requiresPassword,
      Wrapped<int?>? joinFee}) {
    return RacingRaceDetailsResponse$Requirements(
        carClass: (carClass != null ? carClass.value : this.carClass),
        driverClass: (driverClass != null ? driverClass.value : this.driverClass),
        carItemId: (carItemId != null ? carItemId.value : this.carItemId),
        requiresStockCar: (requiresStockCar != null ? requiresStockCar.value : this.requiresStockCar),
        requiresPassword: (requiresPassword != null ? requiresPassword.value : this.requiresPassword),
        joinFee: (joinFee != null ? joinFee.value : this.joinFee));
  }
}

@JsonSerializable(explicitToJson: true)
class TornCalendarResponse$Calendar {
  const TornCalendarResponse$Calendar({
    this.competitions,
    this.events,
  });

  factory TornCalendarResponse$Calendar.fromJson(Map<String, dynamic> json) =>
      _$TornCalendarResponse$CalendarFromJson(json);

  static const toJsonFactory = _$TornCalendarResponse$CalendarToJson;
  Map<String, dynamic> toJson() => _$TornCalendarResponse$CalendarToJson(this);

  @JsonKey(name: 'competitions', defaultValue: <TornCalendarActivity>[])
  final List<TornCalendarActivity>? competitions;
  @JsonKey(name: 'events', defaultValue: <TornCalendarActivity>[])
  final List<TornCalendarActivity>? events;
  static const fromJsonFactory = _$TornCalendarResponse$CalendarFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornCalendarResponse$Calendar &&
            (identical(other.competitions, competitions) ||
                const DeepCollectionEquality().equals(other.competitions, competitions)) &&
            (identical(other.events, events) || const DeepCollectionEquality().equals(other.events, events)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(competitions) ^
      const DeepCollectionEquality().hash(events) ^
      runtimeType.hashCode;
}

extension $TornCalendarResponse$CalendarExtension on TornCalendarResponse$Calendar {
  TornCalendarResponse$Calendar copyWith(
      {List<TornCalendarActivity>? competitions, List<TornCalendarActivity>? events}) {
    return TornCalendarResponse$Calendar(
        competitions: competitions ?? this.competitions, events: events ?? this.events);
  }

  TornCalendarResponse$Calendar copyWithWrapped(
      {Wrapped<List<TornCalendarActivity>?>? competitions, Wrapped<List<TornCalendarActivity>?>? events}) {
    return TornCalendarResponse$Calendar(
        competitions: (competitions != null ? competitions.value : this.competitions),
        events: (events != null ? events.value : this.events));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOther$Other {
  const PersonalStatsOther$Other({
    this.activity,
    this.awards,
    this.meritsBought,
    this.refills,
    this.donatorDays,
    this.rankedWarWins,
  });

  factory PersonalStatsOther$Other.fromJson(Map<String, dynamic> json) => _$PersonalStatsOther$OtherFromJson(json);

  static const toJsonFactory = _$PersonalStatsOther$OtherToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOther$OtherToJson(this);

  @JsonKey(name: 'activity')
  final PersonalStatsOther$Other$Activity? activity;
  @JsonKey(name: 'awards')
  final int? awards;
  @JsonKey(name: 'merits_bought')
  final int? meritsBought;
  @JsonKey(name: 'refills')
  final PersonalStatsOther$Other$Refills? refills;
  @JsonKey(name: 'donator_days')
  final int? donatorDays;
  @JsonKey(name: 'ranked_war_wins')
  final int? rankedWarWins;
  static const fromJsonFactory = _$PersonalStatsOther$OtherFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOther$Other &&
            (identical(other.activity, activity) || const DeepCollectionEquality().equals(other.activity, activity)) &&
            (identical(other.awards, awards) || const DeepCollectionEquality().equals(other.awards, awards)) &&
            (identical(other.meritsBought, meritsBought) ||
                const DeepCollectionEquality().equals(other.meritsBought, meritsBought)) &&
            (identical(other.refills, refills) || const DeepCollectionEquality().equals(other.refills, refills)) &&
            (identical(other.donatorDays, donatorDays) ||
                const DeepCollectionEquality().equals(other.donatorDays, donatorDays)) &&
            (identical(other.rankedWarWins, rankedWarWins) ||
                const DeepCollectionEquality().equals(other.rankedWarWins, rankedWarWins)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(activity) ^
      const DeepCollectionEquality().hash(awards) ^
      const DeepCollectionEquality().hash(meritsBought) ^
      const DeepCollectionEquality().hash(refills) ^
      const DeepCollectionEquality().hash(donatorDays) ^
      const DeepCollectionEquality().hash(rankedWarWins) ^
      runtimeType.hashCode;
}

extension $PersonalStatsOther$OtherExtension on PersonalStatsOther$Other {
  PersonalStatsOther$Other copyWith(
      {PersonalStatsOther$Other$Activity? activity,
      int? awards,
      int? meritsBought,
      PersonalStatsOther$Other$Refills? refills,
      int? donatorDays,
      int? rankedWarWins}) {
    return PersonalStatsOther$Other(
        activity: activity ?? this.activity,
        awards: awards ?? this.awards,
        meritsBought: meritsBought ?? this.meritsBought,
        refills: refills ?? this.refills,
        donatorDays: donatorDays ?? this.donatorDays,
        rankedWarWins: rankedWarWins ?? this.rankedWarWins);
  }

  PersonalStatsOther$Other copyWithWrapped(
      {Wrapped<PersonalStatsOther$Other$Activity?>? activity,
      Wrapped<int?>? awards,
      Wrapped<int?>? meritsBought,
      Wrapped<PersonalStatsOther$Other$Refills?>? refills,
      Wrapped<int?>? donatorDays,
      Wrapped<int?>? rankedWarWins}) {
    return PersonalStatsOther$Other(
        activity: (activity != null ? activity.value : this.activity),
        awards: (awards != null ? awards.value : this.awards),
        meritsBought: (meritsBought != null ? meritsBought.value : this.meritsBought),
        refills: (refills != null ? refills.value : this.refills),
        donatorDays: (donatorDays != null ? donatorDays.value : this.donatorDays),
        rankedWarWins: (rankedWarWins != null ? rankedWarWins.value : this.rankedWarWins));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOtherPopular$Other {
  const PersonalStatsOtherPopular$Other({
    this.activity,
    this.awards,
    this.meritsBought,
    this.refills,
    this.donatorDays,
    this.rankedWarWins,
  });

  factory PersonalStatsOtherPopular$Other.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsOtherPopular$OtherFromJson(json);

  static const toJsonFactory = _$PersonalStatsOtherPopular$OtherToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOtherPopular$OtherToJson(this);

  @JsonKey(name: 'activity')
  final PersonalStatsOtherPopular$Other$Activity? activity;
  @JsonKey(name: 'awards')
  final int? awards;
  @JsonKey(name: 'merits_bought')
  final int? meritsBought;
  @JsonKey(name: 'refills')
  final PersonalStatsOtherPopular$Other$Refills? refills;
  @JsonKey(name: 'donator_days')
  final int? donatorDays;
  @JsonKey(name: 'ranked_war_wins')
  final int? rankedWarWins;
  static const fromJsonFactory = _$PersonalStatsOtherPopular$OtherFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOtherPopular$Other &&
            (identical(other.activity, activity) || const DeepCollectionEquality().equals(other.activity, activity)) &&
            (identical(other.awards, awards) || const DeepCollectionEquality().equals(other.awards, awards)) &&
            (identical(other.meritsBought, meritsBought) ||
                const DeepCollectionEquality().equals(other.meritsBought, meritsBought)) &&
            (identical(other.refills, refills) || const DeepCollectionEquality().equals(other.refills, refills)) &&
            (identical(other.donatorDays, donatorDays) ||
                const DeepCollectionEquality().equals(other.donatorDays, donatorDays)) &&
            (identical(other.rankedWarWins, rankedWarWins) ||
                const DeepCollectionEquality().equals(other.rankedWarWins, rankedWarWins)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(activity) ^
      const DeepCollectionEquality().hash(awards) ^
      const DeepCollectionEquality().hash(meritsBought) ^
      const DeepCollectionEquality().hash(refills) ^
      const DeepCollectionEquality().hash(donatorDays) ^
      const DeepCollectionEquality().hash(rankedWarWins) ^
      runtimeType.hashCode;
}

extension $PersonalStatsOtherPopular$OtherExtension on PersonalStatsOtherPopular$Other {
  PersonalStatsOtherPopular$Other copyWith(
      {PersonalStatsOtherPopular$Other$Activity? activity,
      int? awards,
      int? meritsBought,
      PersonalStatsOtherPopular$Other$Refills? refills,
      int? donatorDays,
      int? rankedWarWins}) {
    return PersonalStatsOtherPopular$Other(
        activity: activity ?? this.activity,
        awards: awards ?? this.awards,
        meritsBought: meritsBought ?? this.meritsBought,
        refills: refills ?? this.refills,
        donatorDays: donatorDays ?? this.donatorDays,
        rankedWarWins: rankedWarWins ?? this.rankedWarWins);
  }

  PersonalStatsOtherPopular$Other copyWithWrapped(
      {Wrapped<PersonalStatsOtherPopular$Other$Activity?>? activity,
      Wrapped<int?>? awards,
      Wrapped<int?>? meritsBought,
      Wrapped<PersonalStatsOtherPopular$Other$Refills?>? refills,
      Wrapped<int?>? donatorDays,
      Wrapped<int?>? rankedWarWins}) {
    return PersonalStatsOtherPopular$Other(
        activity: (activity != null ? activity.value : this.activity),
        awards: (awards != null ? awards.value : this.awards),
        meritsBought: (meritsBought != null ? meritsBought.value : this.meritsBought),
        refills: (refills != null ? refills.value : this.refills),
        donatorDays: (donatorDays != null ? donatorDays.value : this.donatorDays),
        rankedWarWins: (rankedWarWins != null ? rankedWarWins.value : this.rankedWarWins));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsNetworthExtended$Networth {
  const PersonalStatsNetworthExtended$Networth({
    this.total,
    this.wallet,
    this.vaults,
    this.bank,
    this.overseasBank,
    this.points,
    this.inventory,
    this.displayCase,
    this.bazaar,
    this.itemMarket,
    this.property,
    this.stockMarket,
    this.auctionHouse,
    this.bookie,
    this.company,
    this.enlistedCars,
    this.piggyBank,
    this.pending,
    this.loans,
    this.unpaidFees,
  });

  factory PersonalStatsNetworthExtended$Networth.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsNetworthExtended$NetworthFromJson(json);

  static const toJsonFactory = _$PersonalStatsNetworthExtended$NetworthToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsNetworthExtended$NetworthToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'wallet')
  final int? wallet;
  @JsonKey(name: 'vaults')
  final int? vaults;
  @JsonKey(name: 'bank')
  final int? bank;
  @JsonKey(name: 'overseas_bank')
  final int? overseasBank;
  @JsonKey(name: 'points')
  final int? points;
  @JsonKey(name: 'inventory')
  final int? inventory;
  @JsonKey(name: 'display_case')
  final int? displayCase;
  @JsonKey(name: 'bazaar')
  final int? bazaar;
  @JsonKey(name: 'item_market')
  final int? itemMarket;
  @JsonKey(name: 'property')
  final int? property;
  @JsonKey(name: 'stock_market')
  final int? stockMarket;
  @JsonKey(name: 'auction_house')
  final int? auctionHouse;
  @JsonKey(name: 'bookie')
  final int? bookie;
  @JsonKey(name: 'company')
  final int? company;
  @JsonKey(name: 'enlisted_cars')
  final int? enlistedCars;
  @JsonKey(name: 'piggy_bank')
  final int? piggyBank;
  @JsonKey(name: 'pending')
  final int? pending;
  @JsonKey(name: 'loans')
  final int? loans;
  @JsonKey(name: 'unpaid_fees')
  final int? unpaidFees;
  static const fromJsonFactory = _$PersonalStatsNetworthExtended$NetworthFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsNetworthExtended$Networth &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.wallet, wallet) || const DeepCollectionEquality().equals(other.wallet, wallet)) &&
            (identical(other.vaults, vaults) || const DeepCollectionEquality().equals(other.vaults, vaults)) &&
            (identical(other.bank, bank) || const DeepCollectionEquality().equals(other.bank, bank)) &&
            (identical(other.overseasBank, overseasBank) ||
                const DeepCollectionEquality().equals(other.overseasBank, overseasBank)) &&
            (identical(other.points, points) || const DeepCollectionEquality().equals(other.points, points)) &&
            (identical(other.inventory, inventory) ||
                const DeepCollectionEquality().equals(other.inventory, inventory)) &&
            (identical(other.displayCase, displayCase) ||
                const DeepCollectionEquality().equals(other.displayCase, displayCase)) &&
            (identical(other.bazaar, bazaar) || const DeepCollectionEquality().equals(other.bazaar, bazaar)) &&
            (identical(other.itemMarket, itemMarket) ||
                const DeepCollectionEquality().equals(other.itemMarket, itemMarket)) &&
            (identical(other.property, property) || const DeepCollectionEquality().equals(other.property, property)) &&
            (identical(other.stockMarket, stockMarket) ||
                const DeepCollectionEquality().equals(other.stockMarket, stockMarket)) &&
            (identical(other.auctionHouse, auctionHouse) ||
                const DeepCollectionEquality().equals(other.auctionHouse, auctionHouse)) &&
            (identical(other.bookie, bookie) || const DeepCollectionEquality().equals(other.bookie, bookie)) &&
            (identical(other.company, company) || const DeepCollectionEquality().equals(other.company, company)) &&
            (identical(other.enlistedCars, enlistedCars) ||
                const DeepCollectionEquality().equals(other.enlistedCars, enlistedCars)) &&
            (identical(other.piggyBank, piggyBank) ||
                const DeepCollectionEquality().equals(other.piggyBank, piggyBank)) &&
            (identical(other.pending, pending) || const DeepCollectionEquality().equals(other.pending, pending)) &&
            (identical(other.loans, loans) || const DeepCollectionEquality().equals(other.loans, loans)) &&
            (identical(other.unpaidFees, unpaidFees) ||
                const DeepCollectionEquality().equals(other.unpaidFees, unpaidFees)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(wallet) ^
      const DeepCollectionEquality().hash(vaults) ^
      const DeepCollectionEquality().hash(bank) ^
      const DeepCollectionEquality().hash(overseasBank) ^
      const DeepCollectionEquality().hash(points) ^
      const DeepCollectionEquality().hash(inventory) ^
      const DeepCollectionEquality().hash(displayCase) ^
      const DeepCollectionEquality().hash(bazaar) ^
      const DeepCollectionEquality().hash(itemMarket) ^
      const DeepCollectionEquality().hash(property) ^
      const DeepCollectionEquality().hash(stockMarket) ^
      const DeepCollectionEquality().hash(auctionHouse) ^
      const DeepCollectionEquality().hash(bookie) ^
      const DeepCollectionEquality().hash(company) ^
      const DeepCollectionEquality().hash(enlistedCars) ^
      const DeepCollectionEquality().hash(piggyBank) ^
      const DeepCollectionEquality().hash(pending) ^
      const DeepCollectionEquality().hash(loans) ^
      const DeepCollectionEquality().hash(unpaidFees) ^
      runtimeType.hashCode;
}

extension $PersonalStatsNetworthExtended$NetworthExtension on PersonalStatsNetworthExtended$Networth {
  PersonalStatsNetworthExtended$Networth copyWith(
      {int? total,
      int? wallet,
      int? vaults,
      int? bank,
      int? overseasBank,
      int? points,
      int? inventory,
      int? displayCase,
      int? bazaar,
      int? itemMarket,
      int? property,
      int? stockMarket,
      int? auctionHouse,
      int? bookie,
      int? company,
      int? enlistedCars,
      int? piggyBank,
      int? pending,
      int? loans,
      int? unpaidFees}) {
    return PersonalStatsNetworthExtended$Networth(
        total: total ?? this.total,
        wallet: wallet ?? this.wallet,
        vaults: vaults ?? this.vaults,
        bank: bank ?? this.bank,
        overseasBank: overseasBank ?? this.overseasBank,
        points: points ?? this.points,
        inventory: inventory ?? this.inventory,
        displayCase: displayCase ?? this.displayCase,
        bazaar: bazaar ?? this.bazaar,
        itemMarket: itemMarket ?? this.itemMarket,
        property: property ?? this.property,
        stockMarket: stockMarket ?? this.stockMarket,
        auctionHouse: auctionHouse ?? this.auctionHouse,
        bookie: bookie ?? this.bookie,
        company: company ?? this.company,
        enlistedCars: enlistedCars ?? this.enlistedCars,
        piggyBank: piggyBank ?? this.piggyBank,
        pending: pending ?? this.pending,
        loans: loans ?? this.loans,
        unpaidFees: unpaidFees ?? this.unpaidFees);
  }

  PersonalStatsNetworthExtended$Networth copyWithWrapped(
      {Wrapped<int?>? total,
      Wrapped<int?>? wallet,
      Wrapped<int?>? vaults,
      Wrapped<int?>? bank,
      Wrapped<int?>? overseasBank,
      Wrapped<int?>? points,
      Wrapped<int?>? inventory,
      Wrapped<int?>? displayCase,
      Wrapped<int?>? bazaar,
      Wrapped<int?>? itemMarket,
      Wrapped<int?>? property,
      Wrapped<int?>? stockMarket,
      Wrapped<int?>? auctionHouse,
      Wrapped<int?>? bookie,
      Wrapped<int?>? company,
      Wrapped<int?>? enlistedCars,
      Wrapped<int?>? piggyBank,
      Wrapped<int?>? pending,
      Wrapped<int?>? loans,
      Wrapped<int?>? unpaidFees}) {
    return PersonalStatsNetworthExtended$Networth(
        total: (total != null ? total.value : this.total),
        wallet: (wallet != null ? wallet.value : this.wallet),
        vaults: (vaults != null ? vaults.value : this.vaults),
        bank: (bank != null ? bank.value : this.bank),
        overseasBank: (overseasBank != null ? overseasBank.value : this.overseasBank),
        points: (points != null ? points.value : this.points),
        inventory: (inventory != null ? inventory.value : this.inventory),
        displayCase: (displayCase != null ? displayCase.value : this.displayCase),
        bazaar: (bazaar != null ? bazaar.value : this.bazaar),
        itemMarket: (itemMarket != null ? itemMarket.value : this.itemMarket),
        property: (property != null ? property.value : this.property),
        stockMarket: (stockMarket != null ? stockMarket.value : this.stockMarket),
        auctionHouse: (auctionHouse != null ? auctionHouse.value : this.auctionHouse),
        bookie: (bookie != null ? bookie.value : this.bookie),
        company: (company != null ? company.value : this.company),
        enlistedCars: (enlistedCars != null ? enlistedCars.value : this.enlistedCars),
        piggyBank: (piggyBank != null ? piggyBank.value : this.piggyBank),
        pending: (pending != null ? pending.value : this.pending),
        loans: (loans != null ? loans.value : this.loans),
        unpaidFees: (unpaidFees != null ? unpaidFees.value : this.unpaidFees));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsNetworthPublic$Networth {
  const PersonalStatsNetworthPublic$Networth({
    this.total,
  });

  factory PersonalStatsNetworthPublic$Networth.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsNetworthPublic$NetworthFromJson(json);

  static const toJsonFactory = _$PersonalStatsNetworthPublic$NetworthToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsNetworthPublic$NetworthToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  static const fromJsonFactory = _$PersonalStatsNetworthPublic$NetworthFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsNetworthPublic$Networth &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(total) ^ runtimeType.hashCode;
}

extension $PersonalStatsNetworthPublic$NetworthExtension on PersonalStatsNetworthPublic$Networth {
  PersonalStatsNetworthPublic$Networth copyWith({int? total}) {
    return PersonalStatsNetworthPublic$Networth(total: total ?? this.total);
  }

  PersonalStatsNetworthPublic$Networth copyWithWrapped({Wrapped<int?>? total}) {
    return PersonalStatsNetworthPublic$Networth(total: (total != null ? total.value : this.total));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsRacing$Racing {
  const PersonalStatsRacing$Racing({
    this.skill,
    this.points,
    this.races,
  });

  factory PersonalStatsRacing$Racing.fromJson(Map<String, dynamic> json) => _$PersonalStatsRacing$RacingFromJson(json);

  static const toJsonFactory = _$PersonalStatsRacing$RacingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsRacing$RacingToJson(this);

  @JsonKey(name: 'skill')
  final int? skill;
  @JsonKey(name: 'points')
  final int? points;
  @JsonKey(name: 'races')
  final PersonalStatsRacing$Racing$Races? races;
  static const fromJsonFactory = _$PersonalStatsRacing$RacingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsRacing$Racing &&
            (identical(other.skill, skill) || const DeepCollectionEquality().equals(other.skill, skill)) &&
            (identical(other.points, points) || const DeepCollectionEquality().equals(other.points, points)) &&
            (identical(other.races, races) || const DeepCollectionEquality().equals(other.races, races)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(skill) ^
      const DeepCollectionEquality().hash(points) ^
      const DeepCollectionEquality().hash(races) ^
      runtimeType.hashCode;
}

extension $PersonalStatsRacing$RacingExtension on PersonalStatsRacing$Racing {
  PersonalStatsRacing$Racing copyWith({int? skill, int? points, PersonalStatsRacing$Racing$Races? races}) {
    return PersonalStatsRacing$Racing(
        skill: skill ?? this.skill, points: points ?? this.points, races: races ?? this.races);
  }

  PersonalStatsRacing$Racing copyWithWrapped(
      {Wrapped<int?>? skill, Wrapped<int?>? points, Wrapped<PersonalStatsRacing$Racing$Races?>? races}) {
    return PersonalStatsRacing$Racing(
        skill: (skill != null ? skill.value : this.skill),
        points: (points != null ? points.value : this.points),
        races: (races != null ? races.value : this.races));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsMissions$Missions {
  const PersonalStatsMissions$Missions({
    this.missions,
    this.contracts,
    this.credits,
  });

  factory PersonalStatsMissions$Missions.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsMissions$MissionsFromJson(json);

  static const toJsonFactory = _$PersonalStatsMissions$MissionsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsMissions$MissionsToJson(this);

  @JsonKey(name: 'missions')
  final int? missions;
  @JsonKey(name: 'contracts')
  final PersonalStatsMissions$Missions$Contracts? contracts;
  @JsonKey(name: 'credits')
  final int? credits;
  static const fromJsonFactory = _$PersonalStatsMissions$MissionsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsMissions$Missions &&
            (identical(other.missions, missions) || const DeepCollectionEquality().equals(other.missions, missions)) &&
            (identical(other.contracts, contracts) ||
                const DeepCollectionEquality().equals(other.contracts, contracts)) &&
            (identical(other.credits, credits) || const DeepCollectionEquality().equals(other.credits, credits)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(missions) ^
      const DeepCollectionEquality().hash(contracts) ^
      const DeepCollectionEquality().hash(credits) ^
      runtimeType.hashCode;
}

extension $PersonalStatsMissions$MissionsExtension on PersonalStatsMissions$Missions {
  PersonalStatsMissions$Missions copyWith(
      {int? missions, PersonalStatsMissions$Missions$Contracts? contracts, int? credits}) {
    return PersonalStatsMissions$Missions(
        missions: missions ?? this.missions, contracts: contracts ?? this.contracts, credits: credits ?? this.credits);
  }

  PersonalStatsMissions$Missions copyWithWrapped(
      {Wrapped<int?>? missions,
      Wrapped<PersonalStatsMissions$Missions$Contracts?>? contracts,
      Wrapped<int?>? credits}) {
    return PersonalStatsMissions$Missions(
        missions: (missions != null ? missions.value : this.missions),
        contracts: (contracts != null ? contracts.value : this.contracts),
        credits: (credits != null ? credits.value : this.credits));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsDrugs$Drugs {
  const PersonalStatsDrugs$Drugs({
    this.cannabis,
    this.ecstasy,
    this.ketamine,
    this.lsd,
    this.opium,
    this.pcp,
    this.shrooms,
    this.speed,
    this.vicodin,
    this.xanax,
    this.total,
    this.overdoses,
    this.rehabilitations,
  });

  factory PersonalStatsDrugs$Drugs.fromJson(Map<String, dynamic> json) => _$PersonalStatsDrugs$DrugsFromJson(json);

  static const toJsonFactory = _$PersonalStatsDrugs$DrugsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsDrugs$DrugsToJson(this);

  @JsonKey(name: 'cannabis')
  final int? cannabis;
  @JsonKey(name: 'ecstasy')
  final int? ecstasy;
  @JsonKey(name: 'ketamine')
  final int? ketamine;
  @JsonKey(name: 'lsd')
  final int? lsd;
  @JsonKey(name: 'opium')
  final int? opium;
  @JsonKey(name: 'pcp')
  final int? pcp;
  @JsonKey(name: 'shrooms')
  final int? shrooms;
  @JsonKey(name: 'speed')
  final int? speed;
  @JsonKey(name: 'vicodin')
  final int? vicodin;
  @JsonKey(name: 'xanax')
  final int? xanax;
  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'overdoses')
  final int? overdoses;
  @JsonKey(name: 'rehabilitations')
  final PersonalStatsDrugs$Drugs$Rehabilitations? rehabilitations;
  static const fromJsonFactory = _$PersonalStatsDrugs$DrugsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsDrugs$Drugs &&
            (identical(other.cannabis, cannabis) || const DeepCollectionEquality().equals(other.cannabis, cannabis)) &&
            (identical(other.ecstasy, ecstasy) || const DeepCollectionEquality().equals(other.ecstasy, ecstasy)) &&
            (identical(other.ketamine, ketamine) || const DeepCollectionEquality().equals(other.ketamine, ketamine)) &&
            (identical(other.lsd, lsd) || const DeepCollectionEquality().equals(other.lsd, lsd)) &&
            (identical(other.opium, opium) || const DeepCollectionEquality().equals(other.opium, opium)) &&
            (identical(other.pcp, pcp) || const DeepCollectionEquality().equals(other.pcp, pcp)) &&
            (identical(other.shrooms, shrooms) || const DeepCollectionEquality().equals(other.shrooms, shrooms)) &&
            (identical(other.speed, speed) || const DeepCollectionEquality().equals(other.speed, speed)) &&
            (identical(other.vicodin, vicodin) || const DeepCollectionEquality().equals(other.vicodin, vicodin)) &&
            (identical(other.xanax, xanax) || const DeepCollectionEquality().equals(other.xanax, xanax)) &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.overdoses, overdoses) ||
                const DeepCollectionEquality().equals(other.overdoses, overdoses)) &&
            (identical(other.rehabilitations, rehabilitations) ||
                const DeepCollectionEquality().equals(other.rehabilitations, rehabilitations)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(cannabis) ^
      const DeepCollectionEquality().hash(ecstasy) ^
      const DeepCollectionEquality().hash(ketamine) ^
      const DeepCollectionEquality().hash(lsd) ^
      const DeepCollectionEquality().hash(opium) ^
      const DeepCollectionEquality().hash(pcp) ^
      const DeepCollectionEquality().hash(shrooms) ^
      const DeepCollectionEquality().hash(speed) ^
      const DeepCollectionEquality().hash(vicodin) ^
      const DeepCollectionEquality().hash(xanax) ^
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(overdoses) ^
      const DeepCollectionEquality().hash(rehabilitations) ^
      runtimeType.hashCode;
}

extension $PersonalStatsDrugs$DrugsExtension on PersonalStatsDrugs$Drugs {
  PersonalStatsDrugs$Drugs copyWith(
      {int? cannabis,
      int? ecstasy,
      int? ketamine,
      int? lsd,
      int? opium,
      int? pcp,
      int? shrooms,
      int? speed,
      int? vicodin,
      int? xanax,
      int? total,
      int? overdoses,
      PersonalStatsDrugs$Drugs$Rehabilitations? rehabilitations}) {
    return PersonalStatsDrugs$Drugs(
        cannabis: cannabis ?? this.cannabis,
        ecstasy: ecstasy ?? this.ecstasy,
        ketamine: ketamine ?? this.ketamine,
        lsd: lsd ?? this.lsd,
        opium: opium ?? this.opium,
        pcp: pcp ?? this.pcp,
        shrooms: shrooms ?? this.shrooms,
        speed: speed ?? this.speed,
        vicodin: vicodin ?? this.vicodin,
        xanax: xanax ?? this.xanax,
        total: total ?? this.total,
        overdoses: overdoses ?? this.overdoses,
        rehabilitations: rehabilitations ?? this.rehabilitations);
  }

  PersonalStatsDrugs$Drugs copyWithWrapped(
      {Wrapped<int?>? cannabis,
      Wrapped<int?>? ecstasy,
      Wrapped<int?>? ketamine,
      Wrapped<int?>? lsd,
      Wrapped<int?>? opium,
      Wrapped<int?>? pcp,
      Wrapped<int?>? shrooms,
      Wrapped<int?>? speed,
      Wrapped<int?>? vicodin,
      Wrapped<int?>? xanax,
      Wrapped<int?>? total,
      Wrapped<int?>? overdoses,
      Wrapped<PersonalStatsDrugs$Drugs$Rehabilitations?>? rehabilitations}) {
    return PersonalStatsDrugs$Drugs(
        cannabis: (cannabis != null ? cannabis.value : this.cannabis),
        ecstasy: (ecstasy != null ? ecstasy.value : this.ecstasy),
        ketamine: (ketamine != null ? ketamine.value : this.ketamine),
        lsd: (lsd != null ? lsd.value : this.lsd),
        opium: (opium != null ? opium.value : this.opium),
        pcp: (pcp != null ? pcp.value : this.pcp),
        shrooms: (shrooms != null ? shrooms.value : this.shrooms),
        speed: (speed != null ? speed.value : this.speed),
        vicodin: (vicodin != null ? vicodin.value : this.vicodin),
        xanax: (xanax != null ? xanax.value : this.xanax),
        total: (total != null ? total.value : this.total),
        overdoses: (overdoses != null ? overdoses.value : this.overdoses),
        rehabilitations: (rehabilitations != null ? rehabilitations.value : this.rehabilitations));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTravel$Travel {
  const PersonalStatsTravel$Travel({
    this.total,
    this.timeSpent,
    this.itemsBought,
    this.hunting,
    this.attacksWon,
    this.defendsLost,
    this.argentina,
    this.canada,
    this.caymanIslands,
    this.china,
    this.hawaii,
    this.japan,
    this.mexico,
    this.unitedArabEmirates,
    this.unitedKingdom,
    this.southAfrica,
    this.switzerland,
  });

  factory PersonalStatsTravel$Travel.fromJson(Map<String, dynamic> json) => _$PersonalStatsTravel$TravelFromJson(json);

  static const toJsonFactory = _$PersonalStatsTravel$TravelToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTravel$TravelToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'time_spent')
  final int? timeSpent;
  @JsonKey(name: 'items_bought')
  final int? itemsBought;
  @JsonKey(name: 'hunting')
  final PersonalStatsTravel$Travel$Hunting? hunting;
  @JsonKey(name: 'attacks_won')
  final int? attacksWon;
  @JsonKey(name: 'defends_lost')
  final int? defendsLost;
  @JsonKey(name: 'argentina')
  final int? argentina;
  @JsonKey(name: 'canada')
  final int? canada;
  @JsonKey(name: 'cayman_islands')
  final int? caymanIslands;
  @JsonKey(name: 'china')
  final int? china;
  @JsonKey(name: 'hawaii')
  final int? hawaii;
  @JsonKey(name: 'japan')
  final int? japan;
  @JsonKey(name: 'mexico')
  final int? mexico;
  @JsonKey(name: 'united_arab_emirates')
  final int? unitedArabEmirates;
  @JsonKey(name: 'united_kingdom')
  final int? unitedKingdom;
  @JsonKey(name: 'south_africa')
  final int? southAfrica;
  @JsonKey(name: 'switzerland')
  final int? switzerland;
  static const fromJsonFactory = _$PersonalStatsTravel$TravelFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTravel$Travel &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.timeSpent, timeSpent) ||
                const DeepCollectionEquality().equals(other.timeSpent, timeSpent)) &&
            (identical(other.itemsBought, itemsBought) ||
                const DeepCollectionEquality().equals(other.itemsBought, itemsBought)) &&
            (identical(other.hunting, hunting) || const DeepCollectionEquality().equals(other.hunting, hunting)) &&
            (identical(other.attacksWon, attacksWon) ||
                const DeepCollectionEquality().equals(other.attacksWon, attacksWon)) &&
            (identical(other.defendsLost, defendsLost) ||
                const DeepCollectionEquality().equals(other.defendsLost, defendsLost)) &&
            (identical(other.argentina, argentina) ||
                const DeepCollectionEquality().equals(other.argentina, argentina)) &&
            (identical(other.canada, canada) || const DeepCollectionEquality().equals(other.canada, canada)) &&
            (identical(other.caymanIslands, caymanIslands) ||
                const DeepCollectionEquality().equals(other.caymanIslands, caymanIslands)) &&
            (identical(other.china, china) || const DeepCollectionEquality().equals(other.china, china)) &&
            (identical(other.hawaii, hawaii) || const DeepCollectionEquality().equals(other.hawaii, hawaii)) &&
            (identical(other.japan, japan) || const DeepCollectionEquality().equals(other.japan, japan)) &&
            (identical(other.mexico, mexico) || const DeepCollectionEquality().equals(other.mexico, mexico)) &&
            (identical(other.unitedArabEmirates, unitedArabEmirates) ||
                const DeepCollectionEquality().equals(other.unitedArabEmirates, unitedArabEmirates)) &&
            (identical(other.unitedKingdom, unitedKingdom) ||
                const DeepCollectionEquality().equals(other.unitedKingdom, unitedKingdom)) &&
            (identical(other.southAfrica, southAfrica) ||
                const DeepCollectionEquality().equals(other.southAfrica, southAfrica)) &&
            (identical(other.switzerland, switzerland) ||
                const DeepCollectionEquality().equals(other.switzerland, switzerland)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(timeSpent) ^
      const DeepCollectionEquality().hash(itemsBought) ^
      const DeepCollectionEquality().hash(hunting) ^
      const DeepCollectionEquality().hash(attacksWon) ^
      const DeepCollectionEquality().hash(defendsLost) ^
      const DeepCollectionEquality().hash(argentina) ^
      const DeepCollectionEquality().hash(canada) ^
      const DeepCollectionEquality().hash(caymanIslands) ^
      const DeepCollectionEquality().hash(china) ^
      const DeepCollectionEquality().hash(hawaii) ^
      const DeepCollectionEquality().hash(japan) ^
      const DeepCollectionEquality().hash(mexico) ^
      const DeepCollectionEquality().hash(unitedArabEmirates) ^
      const DeepCollectionEquality().hash(unitedKingdom) ^
      const DeepCollectionEquality().hash(southAfrica) ^
      const DeepCollectionEquality().hash(switzerland) ^
      runtimeType.hashCode;
}

extension $PersonalStatsTravel$TravelExtension on PersonalStatsTravel$Travel {
  PersonalStatsTravel$Travel copyWith(
      {int? total,
      int? timeSpent,
      int? itemsBought,
      PersonalStatsTravel$Travel$Hunting? hunting,
      int? attacksWon,
      int? defendsLost,
      int? argentina,
      int? canada,
      int? caymanIslands,
      int? china,
      int? hawaii,
      int? japan,
      int? mexico,
      int? unitedArabEmirates,
      int? unitedKingdom,
      int? southAfrica,
      int? switzerland}) {
    return PersonalStatsTravel$Travel(
        total: total ?? this.total,
        timeSpent: timeSpent ?? this.timeSpent,
        itemsBought: itemsBought ?? this.itemsBought,
        hunting: hunting ?? this.hunting,
        attacksWon: attacksWon ?? this.attacksWon,
        defendsLost: defendsLost ?? this.defendsLost,
        argentina: argentina ?? this.argentina,
        canada: canada ?? this.canada,
        caymanIslands: caymanIslands ?? this.caymanIslands,
        china: china ?? this.china,
        hawaii: hawaii ?? this.hawaii,
        japan: japan ?? this.japan,
        mexico: mexico ?? this.mexico,
        unitedArabEmirates: unitedArabEmirates ?? this.unitedArabEmirates,
        unitedKingdom: unitedKingdom ?? this.unitedKingdom,
        southAfrica: southAfrica ?? this.southAfrica,
        switzerland: switzerland ?? this.switzerland);
  }

  PersonalStatsTravel$Travel copyWithWrapped(
      {Wrapped<int?>? total,
      Wrapped<int?>? timeSpent,
      Wrapped<int?>? itemsBought,
      Wrapped<PersonalStatsTravel$Travel$Hunting?>? hunting,
      Wrapped<int?>? attacksWon,
      Wrapped<int?>? defendsLost,
      Wrapped<int?>? argentina,
      Wrapped<int?>? canada,
      Wrapped<int?>? caymanIslands,
      Wrapped<int?>? china,
      Wrapped<int?>? hawaii,
      Wrapped<int?>? japan,
      Wrapped<int?>? mexico,
      Wrapped<int?>? unitedArabEmirates,
      Wrapped<int?>? unitedKingdom,
      Wrapped<int?>? southAfrica,
      Wrapped<int?>? switzerland}) {
    return PersonalStatsTravel$Travel(
        total: (total != null ? total.value : this.total),
        timeSpent: (timeSpent != null ? timeSpent.value : this.timeSpent),
        itemsBought: (itemsBought != null ? itemsBought.value : this.itemsBought),
        hunting: (hunting != null ? hunting.value : this.hunting),
        attacksWon: (attacksWon != null ? attacksWon.value : this.attacksWon),
        defendsLost: (defendsLost != null ? defendsLost.value : this.defendsLost),
        argentina: (argentina != null ? argentina.value : this.argentina),
        canada: (canada != null ? canada.value : this.canada),
        caymanIslands: (caymanIslands != null ? caymanIslands.value : this.caymanIslands),
        china: (china != null ? china.value : this.china),
        hawaii: (hawaii != null ? hawaii.value : this.hawaii),
        japan: (japan != null ? japan.value : this.japan),
        mexico: (mexico != null ? mexico.value : this.mexico),
        unitedArabEmirates: (unitedArabEmirates != null ? unitedArabEmirates.value : this.unitedArabEmirates),
        unitedKingdom: (unitedKingdom != null ? unitedKingdom.value : this.unitedKingdom),
        southAfrica: (southAfrica != null ? southAfrica.value : this.southAfrica),
        switzerland: (switzerland != null ? switzerland.value : this.switzerland));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTravelPopular$Travel {
  const PersonalStatsTravelPopular$Travel({
    this.total,
    this.timeSpent,
  });

  factory PersonalStatsTravelPopular$Travel.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsTravelPopular$TravelFromJson(json);

  static const toJsonFactory = _$PersonalStatsTravelPopular$TravelToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTravelPopular$TravelToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'time_spent')
  final int? timeSpent;
  static const fromJsonFactory = _$PersonalStatsTravelPopular$TravelFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTravelPopular$Travel &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.timeSpent, timeSpent) ||
                const DeepCollectionEquality().equals(other.timeSpent, timeSpent)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(timeSpent) ^
      runtimeType.hashCode;
}

extension $PersonalStatsTravelPopular$TravelExtension on PersonalStatsTravelPopular$Travel {
  PersonalStatsTravelPopular$Travel copyWith({int? total, int? timeSpent}) {
    return PersonalStatsTravelPopular$Travel(total: total ?? this.total, timeSpent: timeSpent ?? this.timeSpent);
  }

  PersonalStatsTravelPopular$Travel copyWithWrapped({Wrapped<int?>? total, Wrapped<int?>? timeSpent}) {
    return PersonalStatsTravelPopular$Travel(
        total: (total != null ? total.value : this.total),
        timeSpent: (timeSpent != null ? timeSpent.value : this.timeSpent));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsItems$Items {
  const PersonalStatsItems$Items({
    this.found,
    this.trashed,
    this.used,
    this.virusesCoded,
  });

  factory PersonalStatsItems$Items.fromJson(Map<String, dynamic> json) => _$PersonalStatsItems$ItemsFromJson(json);

  static const toJsonFactory = _$PersonalStatsItems$ItemsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsItems$ItemsToJson(this);

  @JsonKey(name: 'found')
  final PersonalStatsItems$Items$Found? found;
  @JsonKey(name: 'trashed')
  final int? trashed;
  @JsonKey(name: 'used')
  final PersonalStatsItems$Items$Used? used;
  @JsonKey(name: 'viruses_coded')
  final int? virusesCoded;
  static const fromJsonFactory = _$PersonalStatsItems$ItemsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsItems$Items &&
            (identical(other.found, found) || const DeepCollectionEquality().equals(other.found, found)) &&
            (identical(other.trashed, trashed) || const DeepCollectionEquality().equals(other.trashed, trashed)) &&
            (identical(other.used, used) || const DeepCollectionEquality().equals(other.used, used)) &&
            (identical(other.virusesCoded, virusesCoded) ||
                const DeepCollectionEquality().equals(other.virusesCoded, virusesCoded)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(found) ^
      const DeepCollectionEquality().hash(trashed) ^
      const DeepCollectionEquality().hash(used) ^
      const DeepCollectionEquality().hash(virusesCoded) ^
      runtimeType.hashCode;
}

extension $PersonalStatsItems$ItemsExtension on PersonalStatsItems$Items {
  PersonalStatsItems$Items copyWith(
      {PersonalStatsItems$Items$Found? found, int? trashed, PersonalStatsItems$Items$Used? used, int? virusesCoded}) {
    return PersonalStatsItems$Items(
        found: found ?? this.found,
        trashed: trashed ?? this.trashed,
        used: used ?? this.used,
        virusesCoded: virusesCoded ?? this.virusesCoded);
  }

  PersonalStatsItems$Items copyWithWrapped(
      {Wrapped<PersonalStatsItems$Items$Found?>? found,
      Wrapped<int?>? trashed,
      Wrapped<PersonalStatsItems$Items$Used?>? used,
      Wrapped<int?>? virusesCoded}) {
    return PersonalStatsItems$Items(
        found: (found != null ? found.value : this.found),
        trashed: (trashed != null ? trashed.value : this.trashed),
        used: (used != null ? used.value : this.used),
        virusesCoded: (virusesCoded != null ? virusesCoded.value : this.virusesCoded));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsItemsPopular$Items {
  const PersonalStatsItemsPopular$Items({
    this.found,
    this.used,
  });

  factory PersonalStatsItemsPopular$Items.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsItemsPopular$ItemsFromJson(json);

  static const toJsonFactory = _$PersonalStatsItemsPopular$ItemsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsItemsPopular$ItemsToJson(this);

  @JsonKey(name: 'found')
  final PersonalStatsItemsPopular$Items$Found? found;
  @JsonKey(name: 'used')
  final PersonalStatsItemsPopular$Items$Used? used;
  static const fromJsonFactory = _$PersonalStatsItemsPopular$ItemsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsItemsPopular$Items &&
            (identical(other.found, found) || const DeepCollectionEquality().equals(other.found, found)) &&
            (identical(other.used, used) || const DeepCollectionEquality().equals(other.used, used)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(found) ^ const DeepCollectionEquality().hash(used) ^ runtimeType.hashCode;
}

extension $PersonalStatsItemsPopular$ItemsExtension on PersonalStatsItemsPopular$Items {
  PersonalStatsItemsPopular$Items copyWith(
      {PersonalStatsItemsPopular$Items$Found? found, PersonalStatsItemsPopular$Items$Used? used}) {
    return PersonalStatsItemsPopular$Items(found: found ?? this.found, used: used ?? this.used);
  }

  PersonalStatsItemsPopular$Items copyWithWrapped(
      {Wrapped<PersonalStatsItemsPopular$Items$Found?>? found, Wrapped<PersonalStatsItemsPopular$Items$Used?>? used}) {
    return PersonalStatsItemsPopular$Items(
        found: (found != null ? found.value : this.found), used: (used != null ? used.value : this.used));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsInvestments$Investments {
  const PersonalStatsInvestments$Investments({
    this.bank,
    this.stocks,
  });

  factory PersonalStatsInvestments$Investments.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsInvestments$InvestmentsFromJson(json);

  static const toJsonFactory = _$PersonalStatsInvestments$InvestmentsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsInvestments$InvestmentsToJson(this);

  @JsonKey(name: 'bank')
  final PersonalStatsInvestments$Investments$Bank? bank;
  @JsonKey(name: 'stocks')
  final PersonalStatsInvestments$Investments$Stocks? stocks;
  static const fromJsonFactory = _$PersonalStatsInvestments$InvestmentsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsInvestments$Investments &&
            (identical(other.bank, bank) || const DeepCollectionEquality().equals(other.bank, bank)) &&
            (identical(other.stocks, stocks) || const DeepCollectionEquality().equals(other.stocks, stocks)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bank) ^ const DeepCollectionEquality().hash(stocks) ^ runtimeType.hashCode;
}

extension $PersonalStatsInvestments$InvestmentsExtension on PersonalStatsInvestments$Investments {
  PersonalStatsInvestments$Investments copyWith(
      {PersonalStatsInvestments$Investments$Bank? bank, PersonalStatsInvestments$Investments$Stocks? stocks}) {
    return PersonalStatsInvestments$Investments(bank: bank ?? this.bank, stocks: stocks ?? this.stocks);
  }

  PersonalStatsInvestments$Investments copyWithWrapped(
      {Wrapped<PersonalStatsInvestments$Investments$Bank?>? bank,
      Wrapped<PersonalStatsInvestments$Investments$Stocks?>? stocks}) {
    return PersonalStatsInvestments$Investments(
        bank: (bank != null ? bank.value : this.bank), stocks: (stocks != null ? stocks.value : this.stocks));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsBounties$Bounties {
  const PersonalStatsBounties$Bounties({
    this.placed,
    this.collected,
    this.received,
  });

  factory PersonalStatsBounties$Bounties.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsBounties$BountiesFromJson(json);

  static const toJsonFactory = _$PersonalStatsBounties$BountiesToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsBounties$BountiesToJson(this);

  @JsonKey(name: 'placed')
  final PersonalStatsBounties$Bounties$Placed? placed;
  @JsonKey(name: 'collected')
  final PersonalStatsBounties$Bounties$Collected? collected;
  @JsonKey(name: 'received')
  final PersonalStatsBounties$Bounties$Received? received;
  static const fromJsonFactory = _$PersonalStatsBounties$BountiesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsBounties$Bounties &&
            (identical(other.placed, placed) || const DeepCollectionEquality().equals(other.placed, placed)) &&
            (identical(other.collected, collected) ||
                const DeepCollectionEquality().equals(other.collected, collected)) &&
            (identical(other.received, received) || const DeepCollectionEquality().equals(other.received, received)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(placed) ^
      const DeepCollectionEquality().hash(collected) ^
      const DeepCollectionEquality().hash(received) ^
      runtimeType.hashCode;
}

extension $PersonalStatsBounties$BountiesExtension on PersonalStatsBounties$Bounties {
  PersonalStatsBounties$Bounties copyWith(
      {PersonalStatsBounties$Bounties$Placed? placed,
      PersonalStatsBounties$Bounties$Collected? collected,
      PersonalStatsBounties$Bounties$Received? received}) {
    return PersonalStatsBounties$Bounties(
        placed: placed ?? this.placed, collected: collected ?? this.collected, received: received ?? this.received);
  }

  PersonalStatsBounties$Bounties copyWithWrapped(
      {Wrapped<PersonalStatsBounties$Bounties$Placed?>? placed,
      Wrapped<PersonalStatsBounties$Bounties$Collected?>? collected,
      Wrapped<PersonalStatsBounties$Bounties$Received?>? received}) {
    return PersonalStatsBounties$Bounties(
        placed: (placed != null ? placed.value : this.placed),
        collected: (collected != null ? collected.value : this.collected),
        received: (received != null ? received.value : this.received));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCrimesV2$Offenses {
  const PersonalStatsCrimesV2$Offenses({
    this.vandalism,
    this.fraud,
    this.theft,
    this.counterfeiting,
    this.illicitServices,
    this.cybercrime,
    this.extortion,
    this.illegalProduction,
    this.organizedCrimes,
    this.total,
  });

  factory PersonalStatsCrimesV2$Offenses.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsCrimesV2$OffensesFromJson(json);

  static const toJsonFactory = _$PersonalStatsCrimesV2$OffensesToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCrimesV2$OffensesToJson(this);

  @JsonKey(name: 'vandalism')
  final int? vandalism;
  @JsonKey(name: 'fraud')
  final int? fraud;
  @JsonKey(name: 'theft')
  final int? theft;
  @JsonKey(name: 'counterfeiting')
  final int? counterfeiting;
  @JsonKey(name: 'illicit_services')
  final int? illicitServices;
  @JsonKey(name: 'cybercrime')
  final int? cybercrime;
  @JsonKey(name: 'extortion')
  final int? extortion;
  @JsonKey(name: 'illegal_production')
  final int? illegalProduction;
  @JsonKey(name: 'organized_crimes')
  final int? organizedCrimes;
  @JsonKey(name: 'total')
  final int? total;
  static const fromJsonFactory = _$PersonalStatsCrimesV2$OffensesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCrimesV2$Offenses &&
            (identical(other.vandalism, vandalism) ||
                const DeepCollectionEquality().equals(other.vandalism, vandalism)) &&
            (identical(other.fraud, fraud) || const DeepCollectionEquality().equals(other.fraud, fraud)) &&
            (identical(other.theft, theft) || const DeepCollectionEquality().equals(other.theft, theft)) &&
            (identical(other.counterfeiting, counterfeiting) ||
                const DeepCollectionEquality().equals(other.counterfeiting, counterfeiting)) &&
            (identical(other.illicitServices, illicitServices) ||
                const DeepCollectionEquality().equals(other.illicitServices, illicitServices)) &&
            (identical(other.cybercrime, cybercrime) ||
                const DeepCollectionEquality().equals(other.cybercrime, cybercrime)) &&
            (identical(other.extortion, extortion) ||
                const DeepCollectionEquality().equals(other.extortion, extortion)) &&
            (identical(other.illegalProduction, illegalProduction) ||
                const DeepCollectionEquality().equals(other.illegalProduction, illegalProduction)) &&
            (identical(other.organizedCrimes, organizedCrimes) ||
                const DeepCollectionEquality().equals(other.organizedCrimes, organizedCrimes)) &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(vandalism) ^
      const DeepCollectionEquality().hash(fraud) ^
      const DeepCollectionEquality().hash(theft) ^
      const DeepCollectionEquality().hash(counterfeiting) ^
      const DeepCollectionEquality().hash(illicitServices) ^
      const DeepCollectionEquality().hash(cybercrime) ^
      const DeepCollectionEquality().hash(extortion) ^
      const DeepCollectionEquality().hash(illegalProduction) ^
      const DeepCollectionEquality().hash(organizedCrimes) ^
      const DeepCollectionEquality().hash(total) ^
      runtimeType.hashCode;
}

extension $PersonalStatsCrimesV2$OffensesExtension on PersonalStatsCrimesV2$Offenses {
  PersonalStatsCrimesV2$Offenses copyWith(
      {int? vandalism,
      int? fraud,
      int? theft,
      int? counterfeiting,
      int? illicitServices,
      int? cybercrime,
      int? extortion,
      int? illegalProduction,
      int? organizedCrimes,
      int? total}) {
    return PersonalStatsCrimesV2$Offenses(
        vandalism: vandalism ?? this.vandalism,
        fraud: fraud ?? this.fraud,
        theft: theft ?? this.theft,
        counterfeiting: counterfeiting ?? this.counterfeiting,
        illicitServices: illicitServices ?? this.illicitServices,
        cybercrime: cybercrime ?? this.cybercrime,
        extortion: extortion ?? this.extortion,
        illegalProduction: illegalProduction ?? this.illegalProduction,
        organizedCrimes: organizedCrimes ?? this.organizedCrimes,
        total: total ?? this.total);
  }

  PersonalStatsCrimesV2$Offenses copyWithWrapped(
      {Wrapped<int?>? vandalism,
      Wrapped<int?>? fraud,
      Wrapped<int?>? theft,
      Wrapped<int?>? counterfeiting,
      Wrapped<int?>? illicitServices,
      Wrapped<int?>? cybercrime,
      Wrapped<int?>? extortion,
      Wrapped<int?>? illegalProduction,
      Wrapped<int?>? organizedCrimes,
      Wrapped<int?>? total}) {
    return PersonalStatsCrimesV2$Offenses(
        vandalism: (vandalism != null ? vandalism.value : this.vandalism),
        fraud: (fraud != null ? fraud.value : this.fraud),
        theft: (theft != null ? theft.value : this.theft),
        counterfeiting: (counterfeiting != null ? counterfeiting.value : this.counterfeiting),
        illicitServices: (illicitServices != null ? illicitServices.value : this.illicitServices),
        cybercrime: (cybercrime != null ? cybercrime.value : this.cybercrime),
        extortion: (extortion != null ? extortion.value : this.extortion),
        illegalProduction: (illegalProduction != null ? illegalProduction.value : this.illegalProduction),
        organizedCrimes: (organizedCrimes != null ? organizedCrimes.value : this.organizedCrimes),
        total: (total != null ? total.value : this.total));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCrimesV2$Skills {
  const PersonalStatsCrimesV2$Skills({
    this.searchForCash,
    this.bootlegging,
    this.graffiti,
    this.shoplifting,
    this.pickpocketing,
    this.cardSkimming,
    this.burglary,
    this.hustling,
    this.disposal,
    this.cracking,
    this.forgery,
    this.scamming,
  });

  factory PersonalStatsCrimesV2$Skills.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsCrimesV2$SkillsFromJson(json);

  static const toJsonFactory = _$PersonalStatsCrimesV2$SkillsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCrimesV2$SkillsToJson(this);

  @JsonKey(name: 'search_for_cash')
  final int? searchForCash;
  @JsonKey(name: 'bootlegging')
  final int? bootlegging;
  @JsonKey(name: 'graffiti')
  final int? graffiti;
  @JsonKey(name: 'shoplifting')
  final int? shoplifting;
  @JsonKey(name: 'pickpocketing')
  final int? pickpocketing;
  @JsonKey(name: 'card_skimming')
  final int? cardSkimming;
  @JsonKey(name: 'burglary')
  final int? burglary;
  @JsonKey(name: 'hustling')
  final int? hustling;
  @JsonKey(name: 'disposal')
  final int? disposal;
  @JsonKey(name: 'cracking')
  final int? cracking;
  @JsonKey(name: 'forgery')
  final int? forgery;
  @JsonKey(name: 'scamming')
  final int? scamming;
  static const fromJsonFactory = _$PersonalStatsCrimesV2$SkillsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCrimesV2$Skills &&
            (identical(other.searchForCash, searchForCash) ||
                const DeepCollectionEquality().equals(other.searchForCash, searchForCash)) &&
            (identical(other.bootlegging, bootlegging) ||
                const DeepCollectionEquality().equals(other.bootlegging, bootlegging)) &&
            (identical(other.graffiti, graffiti) || const DeepCollectionEquality().equals(other.graffiti, graffiti)) &&
            (identical(other.shoplifting, shoplifting) ||
                const DeepCollectionEquality().equals(other.shoplifting, shoplifting)) &&
            (identical(other.pickpocketing, pickpocketing) ||
                const DeepCollectionEquality().equals(other.pickpocketing, pickpocketing)) &&
            (identical(other.cardSkimming, cardSkimming) ||
                const DeepCollectionEquality().equals(other.cardSkimming, cardSkimming)) &&
            (identical(other.burglary, burglary) || const DeepCollectionEquality().equals(other.burglary, burglary)) &&
            (identical(other.hustling, hustling) || const DeepCollectionEquality().equals(other.hustling, hustling)) &&
            (identical(other.disposal, disposal) || const DeepCollectionEquality().equals(other.disposal, disposal)) &&
            (identical(other.cracking, cracking) || const DeepCollectionEquality().equals(other.cracking, cracking)) &&
            (identical(other.forgery, forgery) || const DeepCollectionEquality().equals(other.forgery, forgery)) &&
            (identical(other.scamming, scamming) || const DeepCollectionEquality().equals(other.scamming, scamming)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(searchForCash) ^
      const DeepCollectionEquality().hash(bootlegging) ^
      const DeepCollectionEquality().hash(graffiti) ^
      const DeepCollectionEquality().hash(shoplifting) ^
      const DeepCollectionEquality().hash(pickpocketing) ^
      const DeepCollectionEquality().hash(cardSkimming) ^
      const DeepCollectionEquality().hash(burglary) ^
      const DeepCollectionEquality().hash(hustling) ^
      const DeepCollectionEquality().hash(disposal) ^
      const DeepCollectionEquality().hash(cracking) ^
      const DeepCollectionEquality().hash(forgery) ^
      const DeepCollectionEquality().hash(scamming) ^
      runtimeType.hashCode;
}

extension $PersonalStatsCrimesV2$SkillsExtension on PersonalStatsCrimesV2$Skills {
  PersonalStatsCrimesV2$Skills copyWith(
      {int? searchForCash,
      int? bootlegging,
      int? graffiti,
      int? shoplifting,
      int? pickpocketing,
      int? cardSkimming,
      int? burglary,
      int? hustling,
      int? disposal,
      int? cracking,
      int? forgery,
      int? scamming}) {
    return PersonalStatsCrimesV2$Skills(
        searchForCash: searchForCash ?? this.searchForCash,
        bootlegging: bootlegging ?? this.bootlegging,
        graffiti: graffiti ?? this.graffiti,
        shoplifting: shoplifting ?? this.shoplifting,
        pickpocketing: pickpocketing ?? this.pickpocketing,
        cardSkimming: cardSkimming ?? this.cardSkimming,
        burglary: burglary ?? this.burglary,
        hustling: hustling ?? this.hustling,
        disposal: disposal ?? this.disposal,
        cracking: cracking ?? this.cracking,
        forgery: forgery ?? this.forgery,
        scamming: scamming ?? this.scamming);
  }

  PersonalStatsCrimesV2$Skills copyWithWrapped(
      {Wrapped<int?>? searchForCash,
      Wrapped<int?>? bootlegging,
      Wrapped<int?>? graffiti,
      Wrapped<int?>? shoplifting,
      Wrapped<int?>? pickpocketing,
      Wrapped<int?>? cardSkimming,
      Wrapped<int?>? burglary,
      Wrapped<int?>? hustling,
      Wrapped<int?>? disposal,
      Wrapped<int?>? cracking,
      Wrapped<int?>? forgery,
      Wrapped<int?>? scamming}) {
    return PersonalStatsCrimesV2$Skills(
        searchForCash: (searchForCash != null ? searchForCash.value : this.searchForCash),
        bootlegging: (bootlegging != null ? bootlegging.value : this.bootlegging),
        graffiti: (graffiti != null ? graffiti.value : this.graffiti),
        shoplifting: (shoplifting != null ? shoplifting.value : this.shoplifting),
        pickpocketing: (pickpocketing != null ? pickpocketing.value : this.pickpocketing),
        cardSkimming: (cardSkimming != null ? cardSkimming.value : this.cardSkimming),
        burglary: (burglary != null ? burglary.value : this.burglary),
        hustling: (hustling != null ? hustling.value : this.hustling),
        disposal: (disposal != null ? disposal.value : this.disposal),
        cracking: (cracking != null ? cracking.value : this.cracking),
        forgery: (forgery != null ? forgery.value : this.forgery),
        scamming: (scamming != null ? scamming.value : this.scamming));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCrimesPopular$Crimes {
  const PersonalStatsCrimesPopular$Crimes({
    this.total,
    this.version,
  });

  factory PersonalStatsCrimesPopular$Crimes.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsCrimesPopular$CrimesFromJson(json);

  static const toJsonFactory = _$PersonalStatsCrimesPopular$CrimesToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCrimesPopular$CrimesToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'version')
  final String? version;
  static const fromJsonFactory = _$PersonalStatsCrimesPopular$CrimesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCrimesPopular$Crimes &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.version, version) || const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^ const DeepCollectionEquality().hash(version) ^ runtimeType.hashCode;
}

extension $PersonalStatsCrimesPopular$CrimesExtension on PersonalStatsCrimesPopular$Crimes {
  PersonalStatsCrimesPopular$Crimes copyWith({int? total, String? version}) {
    return PersonalStatsCrimesPopular$Crimes(total: total ?? this.total, version: version ?? this.version);
  }

  PersonalStatsCrimesPopular$Crimes copyWithWrapped({Wrapped<int?>? total, Wrapped<String?>? version}) {
    return PersonalStatsCrimesPopular$Crimes(
        total: (total != null ? total.value : this.total), version: (version != null ? version.value : this.version));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCommunication$Communication {
  const PersonalStatsCommunication$Communication({
    this.mailsSent,
    this.classifiedAds,
    this.personals,
  });

  factory PersonalStatsCommunication$Communication.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsCommunication$CommunicationFromJson(json);

  static const toJsonFactory = _$PersonalStatsCommunication$CommunicationToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCommunication$CommunicationToJson(this);

  @JsonKey(name: 'mails_sent')
  final PersonalStatsCommunication$Communication$MailsSent? mailsSent;
  @JsonKey(name: 'classified_ads')
  final int? classifiedAds;
  @JsonKey(name: 'personals')
  final int? personals;
  static const fromJsonFactory = _$PersonalStatsCommunication$CommunicationFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCommunication$Communication &&
            (identical(other.mailsSent, mailsSent) ||
                const DeepCollectionEquality().equals(other.mailsSent, mailsSent)) &&
            (identical(other.classifiedAds, classifiedAds) ||
                const DeepCollectionEquality().equals(other.classifiedAds, classifiedAds)) &&
            (identical(other.personals, personals) ||
                const DeepCollectionEquality().equals(other.personals, personals)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(mailsSent) ^
      const DeepCollectionEquality().hash(classifiedAds) ^
      const DeepCollectionEquality().hash(personals) ^
      runtimeType.hashCode;
}

extension $PersonalStatsCommunication$CommunicationExtension on PersonalStatsCommunication$Communication {
  PersonalStatsCommunication$Communication copyWith(
      {PersonalStatsCommunication$Communication$MailsSent? mailsSent, int? classifiedAds, int? personals}) {
    return PersonalStatsCommunication$Communication(
        mailsSent: mailsSent ?? this.mailsSent,
        classifiedAds: classifiedAds ?? this.classifiedAds,
        personals: personals ?? this.personals);
  }

  PersonalStatsCommunication$Communication copyWithWrapped(
      {Wrapped<PersonalStatsCommunication$Communication$MailsSent?>? mailsSent,
      Wrapped<int?>? classifiedAds,
      Wrapped<int?>? personals}) {
    return PersonalStatsCommunication$Communication(
        mailsSent: (mailsSent != null ? mailsSent.value : this.mailsSent),
        classifiedAds: (classifiedAds != null ? classifiedAds.value : this.classifiedAds),
        personals: (personals != null ? personals.value : this.personals));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsFinishingHits$FinishingHits {
  const PersonalStatsFinishingHits$FinishingHits({
    this.heavyArtillery,
    this.machineGuns,
    this.rifles,
    this.subMachineGuns,
    this.shotguns,
    this.pistols,
    this.temporary,
    this.piercing,
    this.slashing,
    this.clubbing,
    this.mechanical,
    this.handToHand,
  });

  factory PersonalStatsFinishingHits$FinishingHits.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsFinishingHits$FinishingHitsFromJson(json);

  static const toJsonFactory = _$PersonalStatsFinishingHits$FinishingHitsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsFinishingHits$FinishingHitsToJson(this);

  @JsonKey(name: 'heavy_artillery')
  final int? heavyArtillery;
  @JsonKey(name: 'machine_guns')
  final int? machineGuns;
  @JsonKey(name: 'rifles')
  final int? rifles;
  @JsonKey(name: 'sub_machine_guns')
  final int? subMachineGuns;
  @JsonKey(name: 'shotguns')
  final int? shotguns;
  @JsonKey(name: 'pistols')
  final int? pistols;
  @JsonKey(name: 'temporary')
  final int? temporary;
  @JsonKey(name: 'piercing')
  final int? piercing;
  @JsonKey(name: 'slashing')
  final int? slashing;
  @JsonKey(name: 'clubbing')
  final int? clubbing;
  @JsonKey(name: 'mechanical')
  final int? mechanical;
  @JsonKey(name: 'hand_to_hand')
  final int? handToHand;
  static const fromJsonFactory = _$PersonalStatsFinishingHits$FinishingHitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsFinishingHits$FinishingHits &&
            (identical(other.heavyArtillery, heavyArtillery) ||
                const DeepCollectionEquality().equals(other.heavyArtillery, heavyArtillery)) &&
            (identical(other.machineGuns, machineGuns) ||
                const DeepCollectionEquality().equals(other.machineGuns, machineGuns)) &&
            (identical(other.rifles, rifles) || const DeepCollectionEquality().equals(other.rifles, rifles)) &&
            (identical(other.subMachineGuns, subMachineGuns) ||
                const DeepCollectionEquality().equals(other.subMachineGuns, subMachineGuns)) &&
            (identical(other.shotguns, shotguns) || const DeepCollectionEquality().equals(other.shotguns, shotguns)) &&
            (identical(other.pistols, pistols) || const DeepCollectionEquality().equals(other.pistols, pistols)) &&
            (identical(other.temporary, temporary) ||
                const DeepCollectionEquality().equals(other.temporary, temporary)) &&
            (identical(other.piercing, piercing) || const DeepCollectionEquality().equals(other.piercing, piercing)) &&
            (identical(other.slashing, slashing) || const DeepCollectionEquality().equals(other.slashing, slashing)) &&
            (identical(other.clubbing, clubbing) || const DeepCollectionEquality().equals(other.clubbing, clubbing)) &&
            (identical(other.mechanical, mechanical) ||
                const DeepCollectionEquality().equals(other.mechanical, mechanical)) &&
            (identical(other.handToHand, handToHand) ||
                const DeepCollectionEquality().equals(other.handToHand, handToHand)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(heavyArtillery) ^
      const DeepCollectionEquality().hash(machineGuns) ^
      const DeepCollectionEquality().hash(rifles) ^
      const DeepCollectionEquality().hash(subMachineGuns) ^
      const DeepCollectionEquality().hash(shotguns) ^
      const DeepCollectionEquality().hash(pistols) ^
      const DeepCollectionEquality().hash(temporary) ^
      const DeepCollectionEquality().hash(piercing) ^
      const DeepCollectionEquality().hash(slashing) ^
      const DeepCollectionEquality().hash(clubbing) ^
      const DeepCollectionEquality().hash(mechanical) ^
      const DeepCollectionEquality().hash(handToHand) ^
      runtimeType.hashCode;
}

extension $PersonalStatsFinishingHits$FinishingHitsExtension on PersonalStatsFinishingHits$FinishingHits {
  PersonalStatsFinishingHits$FinishingHits copyWith(
      {int? heavyArtillery,
      int? machineGuns,
      int? rifles,
      int? subMachineGuns,
      int? shotguns,
      int? pistols,
      int? temporary,
      int? piercing,
      int? slashing,
      int? clubbing,
      int? mechanical,
      int? handToHand}) {
    return PersonalStatsFinishingHits$FinishingHits(
        heavyArtillery: heavyArtillery ?? this.heavyArtillery,
        machineGuns: machineGuns ?? this.machineGuns,
        rifles: rifles ?? this.rifles,
        subMachineGuns: subMachineGuns ?? this.subMachineGuns,
        shotguns: shotguns ?? this.shotguns,
        pistols: pistols ?? this.pistols,
        temporary: temporary ?? this.temporary,
        piercing: piercing ?? this.piercing,
        slashing: slashing ?? this.slashing,
        clubbing: clubbing ?? this.clubbing,
        mechanical: mechanical ?? this.mechanical,
        handToHand: handToHand ?? this.handToHand);
  }

  PersonalStatsFinishingHits$FinishingHits copyWithWrapped(
      {Wrapped<int?>? heavyArtillery,
      Wrapped<int?>? machineGuns,
      Wrapped<int?>? rifles,
      Wrapped<int?>? subMachineGuns,
      Wrapped<int?>? shotguns,
      Wrapped<int?>? pistols,
      Wrapped<int?>? temporary,
      Wrapped<int?>? piercing,
      Wrapped<int?>? slashing,
      Wrapped<int?>? clubbing,
      Wrapped<int?>? mechanical,
      Wrapped<int?>? handToHand}) {
    return PersonalStatsFinishingHits$FinishingHits(
        heavyArtillery: (heavyArtillery != null ? heavyArtillery.value : this.heavyArtillery),
        machineGuns: (machineGuns != null ? machineGuns.value : this.machineGuns),
        rifles: (rifles != null ? rifles.value : this.rifles),
        subMachineGuns: (subMachineGuns != null ? subMachineGuns.value : this.subMachineGuns),
        shotguns: (shotguns != null ? shotguns.value : this.shotguns),
        pistols: (pistols != null ? pistols.value : this.pistols),
        temporary: (temporary != null ? temporary.value : this.temporary),
        piercing: (piercing != null ? piercing.value : this.piercing),
        slashing: (slashing != null ? slashing.value : this.slashing),
        clubbing: (clubbing != null ? clubbing.value : this.clubbing),
        mechanical: (mechanical != null ? mechanical.value : this.mechanical),
        handToHand: (handToHand != null ? handToHand.value : this.handToHand));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsHospital$Hospital {
  const PersonalStatsHospital$Hospital({
    this.timesHospitalized,
    this.medicalItemsUsed,
    this.bloodWithdrawn,
    this.reviving,
  });

  factory PersonalStatsHospital$Hospital.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsHospital$HospitalFromJson(json);

  static const toJsonFactory = _$PersonalStatsHospital$HospitalToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsHospital$HospitalToJson(this);

  @JsonKey(name: 'times_hospitalized')
  final int? timesHospitalized;
  @JsonKey(name: 'medical_items_used')
  final int? medicalItemsUsed;
  @JsonKey(name: 'blood_withdrawn')
  final int? bloodWithdrawn;
  @JsonKey(name: 'reviving')
  final PersonalStatsHospital$Hospital$Reviving? reviving;
  static const fromJsonFactory = _$PersonalStatsHospital$HospitalFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsHospital$Hospital &&
            (identical(other.timesHospitalized, timesHospitalized) ||
                const DeepCollectionEquality().equals(other.timesHospitalized, timesHospitalized)) &&
            (identical(other.medicalItemsUsed, medicalItemsUsed) ||
                const DeepCollectionEquality().equals(other.medicalItemsUsed, medicalItemsUsed)) &&
            (identical(other.bloodWithdrawn, bloodWithdrawn) ||
                const DeepCollectionEquality().equals(other.bloodWithdrawn, bloodWithdrawn)) &&
            (identical(other.reviving, reviving) || const DeepCollectionEquality().equals(other.reviving, reviving)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(timesHospitalized) ^
      const DeepCollectionEquality().hash(medicalItemsUsed) ^
      const DeepCollectionEquality().hash(bloodWithdrawn) ^
      const DeepCollectionEquality().hash(reviving) ^
      runtimeType.hashCode;
}

extension $PersonalStatsHospital$HospitalExtension on PersonalStatsHospital$Hospital {
  PersonalStatsHospital$Hospital copyWith(
      {int? timesHospitalized,
      int? medicalItemsUsed,
      int? bloodWithdrawn,
      PersonalStatsHospital$Hospital$Reviving? reviving}) {
    return PersonalStatsHospital$Hospital(
        timesHospitalized: timesHospitalized ?? this.timesHospitalized,
        medicalItemsUsed: medicalItemsUsed ?? this.medicalItemsUsed,
        bloodWithdrawn: bloodWithdrawn ?? this.bloodWithdrawn,
        reviving: reviving ?? this.reviving);
  }

  PersonalStatsHospital$Hospital copyWithWrapped(
      {Wrapped<int?>? timesHospitalized,
      Wrapped<int?>? medicalItemsUsed,
      Wrapped<int?>? bloodWithdrawn,
      Wrapped<PersonalStatsHospital$Hospital$Reviving?>? reviving}) {
    return PersonalStatsHospital$Hospital(
        timesHospitalized: (timesHospitalized != null ? timesHospitalized.value : this.timesHospitalized),
        medicalItemsUsed: (medicalItemsUsed != null ? medicalItemsUsed.value : this.medicalItemsUsed),
        bloodWithdrawn: (bloodWithdrawn != null ? bloodWithdrawn.value : this.bloodWithdrawn),
        reviving: (reviving != null ? reviving.value : this.reviving));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsHospitalPopular$Hospital {
  const PersonalStatsHospitalPopular$Hospital({
    this.medicalItemsUsed,
    this.reviving,
  });

  factory PersonalStatsHospitalPopular$Hospital.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsHospitalPopular$HospitalFromJson(json);

  static const toJsonFactory = _$PersonalStatsHospitalPopular$HospitalToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsHospitalPopular$HospitalToJson(this);

  @JsonKey(name: 'medical_items_used')
  final int? medicalItemsUsed;
  @JsonKey(name: 'reviving')
  final PersonalStatsHospitalPopular$Hospital$Reviving? reviving;
  static const fromJsonFactory = _$PersonalStatsHospitalPopular$HospitalFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsHospitalPopular$Hospital &&
            (identical(other.medicalItemsUsed, medicalItemsUsed) ||
                const DeepCollectionEquality().equals(other.medicalItemsUsed, medicalItemsUsed)) &&
            (identical(other.reviving, reviving) || const DeepCollectionEquality().equals(other.reviving, reviving)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(medicalItemsUsed) ^
      const DeepCollectionEquality().hash(reviving) ^
      runtimeType.hashCode;
}

extension $PersonalStatsHospitalPopular$HospitalExtension on PersonalStatsHospitalPopular$Hospital {
  PersonalStatsHospitalPopular$Hospital copyWith(
      {int? medicalItemsUsed, PersonalStatsHospitalPopular$Hospital$Reviving? reviving}) {
    return PersonalStatsHospitalPopular$Hospital(
        medicalItemsUsed: medicalItemsUsed ?? this.medicalItemsUsed, reviving: reviving ?? this.reviving);
  }

  PersonalStatsHospitalPopular$Hospital copyWithWrapped(
      {Wrapped<int?>? medicalItemsUsed, Wrapped<PersonalStatsHospitalPopular$Hospital$Reviving?>? reviving}) {
    return PersonalStatsHospitalPopular$Hospital(
        medicalItemsUsed: (medicalItemsUsed != null ? medicalItemsUsed.value : this.medicalItemsUsed),
        reviving: (reviving != null ? reviving.value : this.reviving));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsJail$Jail {
  const PersonalStatsJail$Jail({
    this.timesJailed,
    this.busts,
    this.bails,
  });

  factory PersonalStatsJail$Jail.fromJson(Map<String, dynamic> json) => _$PersonalStatsJail$JailFromJson(json);

  static const toJsonFactory = _$PersonalStatsJail$JailToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsJail$JailToJson(this);

  @JsonKey(name: 'times_jailed')
  final int? timesJailed;
  @JsonKey(name: 'busts')
  final PersonalStatsJail$Jail$Busts? busts;
  @JsonKey(name: 'bails')
  final PersonalStatsJail$Jail$Bails? bails;
  static const fromJsonFactory = _$PersonalStatsJail$JailFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsJail$Jail &&
            (identical(other.timesJailed, timesJailed) ||
                const DeepCollectionEquality().equals(other.timesJailed, timesJailed)) &&
            (identical(other.busts, busts) || const DeepCollectionEquality().equals(other.busts, busts)) &&
            (identical(other.bails, bails) || const DeepCollectionEquality().equals(other.bails, bails)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(timesJailed) ^
      const DeepCollectionEquality().hash(busts) ^
      const DeepCollectionEquality().hash(bails) ^
      runtimeType.hashCode;
}

extension $PersonalStatsJail$JailExtension on PersonalStatsJail$Jail {
  PersonalStatsJail$Jail copyWith(
      {int? timesJailed, PersonalStatsJail$Jail$Busts? busts, PersonalStatsJail$Jail$Bails? bails}) {
    return PersonalStatsJail$Jail(
        timesJailed: timesJailed ?? this.timesJailed, busts: busts ?? this.busts, bails: bails ?? this.bails);
  }

  PersonalStatsJail$Jail copyWithWrapped(
      {Wrapped<int?>? timesJailed,
      Wrapped<PersonalStatsJail$Jail$Busts?>? busts,
      Wrapped<PersonalStatsJail$Jail$Bails?>? bails}) {
    return PersonalStatsJail$Jail(
        timesJailed: (timesJailed != null ? timesJailed.value : this.timesJailed),
        busts: (busts != null ? busts.value : this.busts),
        bails: (bails != null ? bails.value : this.bails));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTrading$Trading {
  const PersonalStatsTrading$Trading({
    this.items,
    this.trades,
    this.points,
    this.bazaar,
  });

  factory PersonalStatsTrading$Trading.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsTrading$TradingFromJson(json);

  static const toJsonFactory = _$PersonalStatsTrading$TradingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTrading$TradingToJson(this);

  @JsonKey(name: 'items')
  final PersonalStatsTrading$Trading$Items? items;
  @JsonKey(name: 'trades')
  final int? trades;
  @JsonKey(name: 'points')
  final PersonalStatsTrading$Trading$Points? points;
  @JsonKey(name: 'bazaar')
  final PersonalStatsTrading$Trading$Bazaar? bazaar;
  static const fromJsonFactory = _$PersonalStatsTrading$TradingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTrading$Trading &&
            (identical(other.items, items) || const DeepCollectionEquality().equals(other.items, items)) &&
            (identical(other.trades, trades) || const DeepCollectionEquality().equals(other.trades, trades)) &&
            (identical(other.points, points) || const DeepCollectionEquality().equals(other.points, points)) &&
            (identical(other.bazaar, bazaar) || const DeepCollectionEquality().equals(other.bazaar, bazaar)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(items) ^
      const DeepCollectionEquality().hash(trades) ^
      const DeepCollectionEquality().hash(points) ^
      const DeepCollectionEquality().hash(bazaar) ^
      runtimeType.hashCode;
}

extension $PersonalStatsTrading$TradingExtension on PersonalStatsTrading$Trading {
  PersonalStatsTrading$Trading copyWith(
      {PersonalStatsTrading$Trading$Items? items,
      int? trades,
      PersonalStatsTrading$Trading$Points? points,
      PersonalStatsTrading$Trading$Bazaar? bazaar}) {
    return PersonalStatsTrading$Trading(
        items: items ?? this.items,
        trades: trades ?? this.trades,
        points: points ?? this.points,
        bazaar: bazaar ?? this.bazaar);
  }

  PersonalStatsTrading$Trading copyWithWrapped(
      {Wrapped<PersonalStatsTrading$Trading$Items?>? items,
      Wrapped<int?>? trades,
      Wrapped<PersonalStatsTrading$Trading$Points?>? points,
      Wrapped<PersonalStatsTrading$Trading$Bazaar?>? bazaar}) {
    return PersonalStatsTrading$Trading(
        items: (items != null ? items.value : this.items),
        trades: (trades != null ? trades.value : this.trades),
        points: (points != null ? points.value : this.points),
        bazaar: (bazaar != null ? bazaar.value : this.bazaar));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsJobsPublic$Jobs {
  const PersonalStatsJobsPublic$Jobs({
    this.jobPointsUsed,
    this.trainsReceived,
  });

  factory PersonalStatsJobsPublic$Jobs.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsJobsPublic$JobsFromJson(json);

  static const toJsonFactory = _$PersonalStatsJobsPublic$JobsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsJobsPublic$JobsToJson(this);

  @JsonKey(name: 'job_points_used')
  final int? jobPointsUsed;
  @JsonKey(name: 'trains_received')
  final int? trainsReceived;
  static const fromJsonFactory = _$PersonalStatsJobsPublic$JobsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsJobsPublic$Jobs &&
            (identical(other.jobPointsUsed, jobPointsUsed) ||
                const DeepCollectionEquality().equals(other.jobPointsUsed, jobPointsUsed)) &&
            (identical(other.trainsReceived, trainsReceived) ||
                const DeepCollectionEquality().equals(other.trainsReceived, trainsReceived)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(jobPointsUsed) ^
      const DeepCollectionEquality().hash(trainsReceived) ^
      runtimeType.hashCode;
}

extension $PersonalStatsJobsPublic$JobsExtension on PersonalStatsJobsPublic$Jobs {
  PersonalStatsJobsPublic$Jobs copyWith({int? jobPointsUsed, int? trainsReceived}) {
    return PersonalStatsJobsPublic$Jobs(
        jobPointsUsed: jobPointsUsed ?? this.jobPointsUsed, trainsReceived: trainsReceived ?? this.trainsReceived);
  }

  PersonalStatsJobsPublic$Jobs copyWithWrapped({Wrapped<int?>? jobPointsUsed, Wrapped<int?>? trainsReceived}) {
    return PersonalStatsJobsPublic$Jobs(
        jobPointsUsed: (jobPointsUsed != null ? jobPointsUsed.value : this.jobPointsUsed),
        trainsReceived: (trainsReceived != null ? trainsReceived.value : this.trainsReceived));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsJobsExtended$Jobs {
  const PersonalStatsJobsExtended$Jobs({
    this.jobPointsUsed,
    this.trainsReceived,
    this.stats,
  });

  factory PersonalStatsJobsExtended$Jobs.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsJobsExtended$JobsFromJson(json);

  static const toJsonFactory = _$PersonalStatsJobsExtended$JobsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsJobsExtended$JobsToJson(this);

  @JsonKey(name: 'job_points_used')
  final int? jobPointsUsed;
  @JsonKey(name: 'trains_received')
  final int? trainsReceived;
  @JsonKey(name: 'stats')
  final PersonalStatsJobsExtended$Jobs$Stats? stats;
  static const fromJsonFactory = _$PersonalStatsJobsExtended$JobsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsJobsExtended$Jobs &&
            (identical(other.jobPointsUsed, jobPointsUsed) ||
                const DeepCollectionEquality().equals(other.jobPointsUsed, jobPointsUsed)) &&
            (identical(other.trainsReceived, trainsReceived) ||
                const DeepCollectionEquality().equals(other.trainsReceived, trainsReceived)) &&
            (identical(other.stats, stats) || const DeepCollectionEquality().equals(other.stats, stats)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(jobPointsUsed) ^
      const DeepCollectionEquality().hash(trainsReceived) ^
      const DeepCollectionEquality().hash(stats) ^
      runtimeType.hashCode;
}

extension $PersonalStatsJobsExtended$JobsExtension on PersonalStatsJobsExtended$Jobs {
  PersonalStatsJobsExtended$Jobs copyWith(
      {int? jobPointsUsed, int? trainsReceived, PersonalStatsJobsExtended$Jobs$Stats? stats}) {
    return PersonalStatsJobsExtended$Jobs(
        jobPointsUsed: jobPointsUsed ?? this.jobPointsUsed,
        trainsReceived: trainsReceived ?? this.trainsReceived,
        stats: stats ?? this.stats);
  }

  PersonalStatsJobsExtended$Jobs copyWithWrapped(
      {Wrapped<int?>? jobPointsUsed,
      Wrapped<int?>? trainsReceived,
      Wrapped<PersonalStatsJobsExtended$Jobs$Stats?>? stats}) {
    return PersonalStatsJobsExtended$Jobs(
        jobPointsUsed: (jobPointsUsed != null ? jobPointsUsed.value : this.jobPointsUsed),
        trainsReceived: (trainsReceived != null ? trainsReceived.value : this.trainsReceived),
        stats: (stats != null ? stats.value : this.stats));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsBattleStats$BattleStats {
  const PersonalStatsBattleStats$BattleStats({
    this.strength,
    this.defense,
    this.speed,
    this.dexterity,
    this.total,
  });

  factory PersonalStatsBattleStats$BattleStats.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsBattleStats$BattleStatsFromJson(json);

  static const toJsonFactory = _$PersonalStatsBattleStats$BattleStatsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsBattleStats$BattleStatsToJson(this);

  @JsonKey(name: 'strength')
  final int? strength;
  @JsonKey(name: 'defense')
  final int? defense;
  @JsonKey(name: 'speed')
  final int? speed;
  @JsonKey(name: 'dexterity')
  final int? dexterity;
  @JsonKey(name: 'total')
  final int? total;
  static const fromJsonFactory = _$PersonalStatsBattleStats$BattleStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsBattleStats$BattleStats &&
            (identical(other.strength, strength) || const DeepCollectionEquality().equals(other.strength, strength)) &&
            (identical(other.defense, defense) || const DeepCollectionEquality().equals(other.defense, defense)) &&
            (identical(other.speed, speed) || const DeepCollectionEquality().equals(other.speed, speed)) &&
            (identical(other.dexterity, dexterity) ||
                const DeepCollectionEquality().equals(other.dexterity, dexterity)) &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(strength) ^
      const DeepCollectionEquality().hash(defense) ^
      const DeepCollectionEquality().hash(speed) ^
      const DeepCollectionEquality().hash(dexterity) ^
      const DeepCollectionEquality().hash(total) ^
      runtimeType.hashCode;
}

extension $PersonalStatsBattleStats$BattleStatsExtension on PersonalStatsBattleStats$BattleStats {
  PersonalStatsBattleStats$BattleStats copyWith({int? strength, int? defense, int? speed, int? dexterity, int? total}) {
    return PersonalStatsBattleStats$BattleStats(
        strength: strength ?? this.strength,
        defense: defense ?? this.defense,
        speed: speed ?? this.speed,
        dexterity: dexterity ?? this.dexterity,
        total: total ?? this.total);
  }

  PersonalStatsBattleStats$BattleStats copyWithWrapped(
      {Wrapped<int?>? strength,
      Wrapped<int?>? defense,
      Wrapped<int?>? speed,
      Wrapped<int?>? dexterity,
      Wrapped<int?>? total}) {
    return PersonalStatsBattleStats$BattleStats(
        strength: (strength != null ? strength.value : this.strength),
        defense: (defense != null ? defense.value : this.defense),
        speed: (speed != null ? speed.value : this.speed),
        dexterity: (dexterity != null ? dexterity.value : this.dexterity),
        total: (total != null ? total.value : this.total));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking {
  const PersonalStatsAttackingPublic$Attacking({
    this.attacks,
    this.defends,
    this.elo,
    this.unarmoredWins,
    this.highestLevelBeaten,
    this.escapes,
    this.killstreak,
    this.hits,
    this.damage,
    this.networth,
    this.ammunition,
    this.faction,
  });

  factory PersonalStatsAttackingPublic$Attacking.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$AttackingFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$AttackingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$AttackingToJson(this);

  @JsonKey(name: 'attacks')
  final PersonalStatsAttackingPublic$Attacking$Attacks? attacks;
  @JsonKey(name: 'defends')
  final PersonalStatsAttackingPublic$Attacking$Defends? defends;
  @JsonKey(name: 'elo')
  final int? elo;
  @JsonKey(name: 'unarmored_wins')
  final int? unarmoredWins;
  @JsonKey(name: 'highest_level_beaten')
  final int? highestLevelBeaten;
  @JsonKey(name: 'escapes')
  final PersonalStatsAttackingPublic$Attacking$Escapes? escapes;
  @JsonKey(name: 'killstreak')
  final PersonalStatsAttackingPublic$Attacking$Killstreak? killstreak;
  @JsonKey(name: 'hits')
  final PersonalStatsAttackingPublic$Attacking$Hits? hits;
  @JsonKey(name: 'damage')
  final PersonalStatsAttackingPublic$Attacking$Damage? damage;
  @JsonKey(name: 'networth')
  final PersonalStatsAttackingPublic$Attacking$Networth? networth;
  @JsonKey(name: 'ammunition')
  final PersonalStatsAttackingPublic$Attacking$Ammunition? ammunition;
  @JsonKey(name: 'faction')
  final PersonalStatsAttackingPublic$Attacking$Faction? faction;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$AttackingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking &&
            (identical(other.attacks, attacks) || const DeepCollectionEquality().equals(other.attacks, attacks)) &&
            (identical(other.defends, defends) || const DeepCollectionEquality().equals(other.defends, defends)) &&
            (identical(other.elo, elo) || const DeepCollectionEquality().equals(other.elo, elo)) &&
            (identical(other.unarmoredWins, unarmoredWins) ||
                const DeepCollectionEquality().equals(other.unarmoredWins, unarmoredWins)) &&
            (identical(other.highestLevelBeaten, highestLevelBeaten) ||
                const DeepCollectionEquality().equals(other.highestLevelBeaten, highestLevelBeaten)) &&
            (identical(other.escapes, escapes) || const DeepCollectionEquality().equals(other.escapes, escapes)) &&
            (identical(other.killstreak, killstreak) ||
                const DeepCollectionEquality().equals(other.killstreak, killstreak)) &&
            (identical(other.hits, hits) || const DeepCollectionEquality().equals(other.hits, hits)) &&
            (identical(other.damage, damage) || const DeepCollectionEquality().equals(other.damage, damage)) &&
            (identical(other.networth, networth) || const DeepCollectionEquality().equals(other.networth, networth)) &&
            (identical(other.ammunition, ammunition) ||
                const DeepCollectionEquality().equals(other.ammunition, ammunition)) &&
            (identical(other.faction, faction) || const DeepCollectionEquality().equals(other.faction, faction)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(attacks) ^
      const DeepCollectionEquality().hash(defends) ^
      const DeepCollectionEquality().hash(elo) ^
      const DeepCollectionEquality().hash(unarmoredWins) ^
      const DeepCollectionEquality().hash(highestLevelBeaten) ^
      const DeepCollectionEquality().hash(escapes) ^
      const DeepCollectionEquality().hash(killstreak) ^
      const DeepCollectionEquality().hash(hits) ^
      const DeepCollectionEquality().hash(damage) ^
      const DeepCollectionEquality().hash(networth) ^
      const DeepCollectionEquality().hash(ammunition) ^
      const DeepCollectionEquality().hash(faction) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$AttackingExtension on PersonalStatsAttackingPublic$Attacking {
  PersonalStatsAttackingPublic$Attacking copyWith(
      {PersonalStatsAttackingPublic$Attacking$Attacks? attacks,
      PersonalStatsAttackingPublic$Attacking$Defends? defends,
      int? elo,
      int? unarmoredWins,
      int? highestLevelBeaten,
      PersonalStatsAttackingPublic$Attacking$Escapes? escapes,
      PersonalStatsAttackingPublic$Attacking$Killstreak? killstreak,
      PersonalStatsAttackingPublic$Attacking$Hits? hits,
      PersonalStatsAttackingPublic$Attacking$Damage? damage,
      PersonalStatsAttackingPublic$Attacking$Networth? networth,
      PersonalStatsAttackingPublic$Attacking$Ammunition? ammunition,
      PersonalStatsAttackingPublic$Attacking$Faction? faction}) {
    return PersonalStatsAttackingPublic$Attacking(
        attacks: attacks ?? this.attacks,
        defends: defends ?? this.defends,
        elo: elo ?? this.elo,
        unarmoredWins: unarmoredWins ?? this.unarmoredWins,
        highestLevelBeaten: highestLevelBeaten ?? this.highestLevelBeaten,
        escapes: escapes ?? this.escapes,
        killstreak: killstreak ?? this.killstreak,
        hits: hits ?? this.hits,
        damage: damage ?? this.damage,
        networth: networth ?? this.networth,
        ammunition: ammunition ?? this.ammunition,
        faction: faction ?? this.faction);
  }

  PersonalStatsAttackingPublic$Attacking copyWithWrapped(
      {Wrapped<PersonalStatsAttackingPublic$Attacking$Attacks?>? attacks,
      Wrapped<PersonalStatsAttackingPublic$Attacking$Defends?>? defends,
      Wrapped<int?>? elo,
      Wrapped<int?>? unarmoredWins,
      Wrapped<int?>? highestLevelBeaten,
      Wrapped<PersonalStatsAttackingPublic$Attacking$Escapes?>? escapes,
      Wrapped<PersonalStatsAttackingPublic$Attacking$Killstreak?>? killstreak,
      Wrapped<PersonalStatsAttackingPublic$Attacking$Hits?>? hits,
      Wrapped<PersonalStatsAttackingPublic$Attacking$Damage?>? damage,
      Wrapped<PersonalStatsAttackingPublic$Attacking$Networth?>? networth,
      Wrapped<PersonalStatsAttackingPublic$Attacking$Ammunition?>? ammunition,
      Wrapped<PersonalStatsAttackingPublic$Attacking$Faction?>? faction}) {
    return PersonalStatsAttackingPublic$Attacking(
        attacks: (attacks != null ? attacks.value : this.attacks),
        defends: (defends != null ? defends.value : this.defends),
        elo: (elo != null ? elo.value : this.elo),
        unarmoredWins: (unarmoredWins != null ? unarmoredWins.value : this.unarmoredWins),
        highestLevelBeaten: (highestLevelBeaten != null ? highestLevelBeaten.value : this.highestLevelBeaten),
        escapes: (escapes != null ? escapes.value : this.escapes),
        killstreak: (killstreak != null ? killstreak.value : this.killstreak),
        hits: (hits != null ? hits.value : this.hits),
        damage: (damage != null ? damage.value : this.damage),
        networth: (networth != null ? networth.value : this.networth),
        ammunition: (ammunition != null ? ammunition.value : this.ammunition),
        faction: (faction != null ? faction.value : this.faction));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking {
  const PersonalStatsAttackingExtended$Attacking({
    this.attacks,
    this.defends,
    this.elo,
    this.unarmoredWins,
    this.highestLevelBeaten,
    this.escapes,
    this.killstreak,
    this.hits,
    this.damage,
    this.networth,
    this.ammunition,
    this.faction,
  });

  factory PersonalStatsAttackingExtended$Attacking.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$AttackingFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$AttackingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$AttackingToJson(this);

  @JsonKey(name: 'attacks')
  final PersonalStatsAttackingExtended$Attacking$Attacks? attacks;
  @JsonKey(name: 'defends')
  final PersonalStatsAttackingExtended$Attacking$Defends? defends;
  @JsonKey(name: 'elo')
  final int? elo;
  @JsonKey(name: 'unarmored_wins')
  final int? unarmoredWins;
  @JsonKey(name: 'highest_level_beaten')
  final int? highestLevelBeaten;
  @JsonKey(name: 'escapes')
  final PersonalStatsAttackingExtended$Attacking$Escapes? escapes;
  @JsonKey(name: 'killstreak')
  final PersonalStatsAttackingExtended$Attacking$Killstreak? killstreak;
  @JsonKey(name: 'hits')
  final PersonalStatsAttackingExtended$Attacking$Hits? hits;
  @JsonKey(name: 'damage')
  final PersonalStatsAttackingExtended$Attacking$Damage? damage;
  @JsonKey(name: 'networth')
  final PersonalStatsAttackingExtended$Attacking$Networth? networth;
  @JsonKey(name: 'ammunition')
  final PersonalStatsAttackingExtended$Attacking$Ammunition? ammunition;
  @JsonKey(name: 'faction')
  final PersonalStatsAttackingExtended$Attacking$Faction? faction;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$AttackingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking &&
            (identical(other.attacks, attacks) || const DeepCollectionEquality().equals(other.attacks, attacks)) &&
            (identical(other.defends, defends) || const DeepCollectionEquality().equals(other.defends, defends)) &&
            (identical(other.elo, elo) || const DeepCollectionEquality().equals(other.elo, elo)) &&
            (identical(other.unarmoredWins, unarmoredWins) ||
                const DeepCollectionEquality().equals(other.unarmoredWins, unarmoredWins)) &&
            (identical(other.highestLevelBeaten, highestLevelBeaten) ||
                const DeepCollectionEquality().equals(other.highestLevelBeaten, highestLevelBeaten)) &&
            (identical(other.escapes, escapes) || const DeepCollectionEquality().equals(other.escapes, escapes)) &&
            (identical(other.killstreak, killstreak) ||
                const DeepCollectionEquality().equals(other.killstreak, killstreak)) &&
            (identical(other.hits, hits) || const DeepCollectionEquality().equals(other.hits, hits)) &&
            (identical(other.damage, damage) || const DeepCollectionEquality().equals(other.damage, damage)) &&
            (identical(other.networth, networth) || const DeepCollectionEquality().equals(other.networth, networth)) &&
            (identical(other.ammunition, ammunition) ||
                const DeepCollectionEquality().equals(other.ammunition, ammunition)) &&
            (identical(other.faction, faction) || const DeepCollectionEquality().equals(other.faction, faction)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(attacks) ^
      const DeepCollectionEquality().hash(defends) ^
      const DeepCollectionEquality().hash(elo) ^
      const DeepCollectionEquality().hash(unarmoredWins) ^
      const DeepCollectionEquality().hash(highestLevelBeaten) ^
      const DeepCollectionEquality().hash(escapes) ^
      const DeepCollectionEquality().hash(killstreak) ^
      const DeepCollectionEquality().hash(hits) ^
      const DeepCollectionEquality().hash(damage) ^
      const DeepCollectionEquality().hash(networth) ^
      const DeepCollectionEquality().hash(ammunition) ^
      const DeepCollectionEquality().hash(faction) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$AttackingExtension on PersonalStatsAttackingExtended$Attacking {
  PersonalStatsAttackingExtended$Attacking copyWith(
      {PersonalStatsAttackingExtended$Attacking$Attacks? attacks,
      PersonalStatsAttackingExtended$Attacking$Defends? defends,
      int? elo,
      int? unarmoredWins,
      int? highestLevelBeaten,
      PersonalStatsAttackingExtended$Attacking$Escapes? escapes,
      PersonalStatsAttackingExtended$Attacking$Killstreak? killstreak,
      PersonalStatsAttackingExtended$Attacking$Hits? hits,
      PersonalStatsAttackingExtended$Attacking$Damage? damage,
      PersonalStatsAttackingExtended$Attacking$Networth? networth,
      PersonalStatsAttackingExtended$Attacking$Ammunition? ammunition,
      PersonalStatsAttackingExtended$Attacking$Faction? faction}) {
    return PersonalStatsAttackingExtended$Attacking(
        attacks: attacks ?? this.attacks,
        defends: defends ?? this.defends,
        elo: elo ?? this.elo,
        unarmoredWins: unarmoredWins ?? this.unarmoredWins,
        highestLevelBeaten: highestLevelBeaten ?? this.highestLevelBeaten,
        escapes: escapes ?? this.escapes,
        killstreak: killstreak ?? this.killstreak,
        hits: hits ?? this.hits,
        damage: damage ?? this.damage,
        networth: networth ?? this.networth,
        ammunition: ammunition ?? this.ammunition,
        faction: faction ?? this.faction);
  }

  PersonalStatsAttackingExtended$Attacking copyWithWrapped(
      {Wrapped<PersonalStatsAttackingExtended$Attacking$Attacks?>? attacks,
      Wrapped<PersonalStatsAttackingExtended$Attacking$Defends?>? defends,
      Wrapped<int?>? elo,
      Wrapped<int?>? unarmoredWins,
      Wrapped<int?>? highestLevelBeaten,
      Wrapped<PersonalStatsAttackingExtended$Attacking$Escapes?>? escapes,
      Wrapped<PersonalStatsAttackingExtended$Attacking$Killstreak?>? killstreak,
      Wrapped<PersonalStatsAttackingExtended$Attacking$Hits?>? hits,
      Wrapped<PersonalStatsAttackingExtended$Attacking$Damage?>? damage,
      Wrapped<PersonalStatsAttackingExtended$Attacking$Networth?>? networth,
      Wrapped<PersonalStatsAttackingExtended$Attacking$Ammunition?>? ammunition,
      Wrapped<PersonalStatsAttackingExtended$Attacking$Faction?>? faction}) {
    return PersonalStatsAttackingExtended$Attacking(
        attacks: (attacks != null ? attacks.value : this.attacks),
        defends: (defends != null ? defends.value : this.defends),
        elo: (elo != null ? elo.value : this.elo),
        unarmoredWins: (unarmoredWins != null ? unarmoredWins.value : this.unarmoredWins),
        highestLevelBeaten: (highestLevelBeaten != null ? highestLevelBeaten.value : this.highestLevelBeaten),
        escapes: (escapes != null ? escapes.value : this.escapes),
        killstreak: (killstreak != null ? killstreak.value : this.killstreak),
        hits: (hits != null ? hits.value : this.hits),
        damage: (damage != null ? damage.value : this.damage),
        networth: (networth != null ? networth.value : this.networth),
        ammunition: (ammunition != null ? ammunition.value : this.ammunition),
        faction: (faction != null ? faction.value : this.faction));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking {
  const PersonalStatsAttackingPopular$Attacking({
    this.attacks,
    this.defends,
    this.elo,
    this.escapes,
    this.killstreak,
    this.hits,
    this.damage,
    this.networth,
    this.ammunition,
    this.faction,
  });

  factory PersonalStatsAttackingPopular$Attacking.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$AttackingFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$AttackingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$AttackingToJson(this);

  @JsonKey(name: 'attacks')
  final PersonalStatsAttackingPopular$Attacking$Attacks? attacks;
  @JsonKey(name: 'defends')
  final PersonalStatsAttackingPopular$Attacking$Defends? defends;
  @JsonKey(name: 'elo')
  final int? elo;
  @JsonKey(name: 'escapes')
  final PersonalStatsAttackingPopular$Attacking$Escapes? escapes;
  @JsonKey(name: 'killstreak')
  final PersonalStatsAttackingPopular$Attacking$Killstreak? killstreak;
  @JsonKey(name: 'hits')
  final PersonalStatsAttackingPopular$Attacking$Hits? hits;
  @JsonKey(name: 'damage')
  final PersonalStatsAttackingPopular$Attacking$Damage? damage;
  @JsonKey(name: 'networth')
  final PersonalStatsAttackingPopular$Attacking$Networth? networth;
  @JsonKey(name: 'ammunition')
  final PersonalStatsAttackingPopular$Attacking$Ammunition? ammunition;
  @JsonKey(name: 'faction')
  final PersonalStatsAttackingPopular$Attacking$Faction? faction;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$AttackingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking &&
            (identical(other.attacks, attacks) || const DeepCollectionEquality().equals(other.attacks, attacks)) &&
            (identical(other.defends, defends) || const DeepCollectionEquality().equals(other.defends, defends)) &&
            (identical(other.elo, elo) || const DeepCollectionEquality().equals(other.elo, elo)) &&
            (identical(other.escapes, escapes) || const DeepCollectionEquality().equals(other.escapes, escapes)) &&
            (identical(other.killstreak, killstreak) ||
                const DeepCollectionEquality().equals(other.killstreak, killstreak)) &&
            (identical(other.hits, hits) || const DeepCollectionEquality().equals(other.hits, hits)) &&
            (identical(other.damage, damage) || const DeepCollectionEquality().equals(other.damage, damage)) &&
            (identical(other.networth, networth) || const DeepCollectionEquality().equals(other.networth, networth)) &&
            (identical(other.ammunition, ammunition) ||
                const DeepCollectionEquality().equals(other.ammunition, ammunition)) &&
            (identical(other.faction, faction) || const DeepCollectionEquality().equals(other.faction, faction)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(attacks) ^
      const DeepCollectionEquality().hash(defends) ^
      const DeepCollectionEquality().hash(elo) ^
      const DeepCollectionEquality().hash(escapes) ^
      const DeepCollectionEquality().hash(killstreak) ^
      const DeepCollectionEquality().hash(hits) ^
      const DeepCollectionEquality().hash(damage) ^
      const DeepCollectionEquality().hash(networth) ^
      const DeepCollectionEquality().hash(ammunition) ^
      const DeepCollectionEquality().hash(faction) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$AttackingExtension on PersonalStatsAttackingPopular$Attacking {
  PersonalStatsAttackingPopular$Attacking copyWith(
      {PersonalStatsAttackingPopular$Attacking$Attacks? attacks,
      PersonalStatsAttackingPopular$Attacking$Defends? defends,
      int? elo,
      PersonalStatsAttackingPopular$Attacking$Escapes? escapes,
      PersonalStatsAttackingPopular$Attacking$Killstreak? killstreak,
      PersonalStatsAttackingPopular$Attacking$Hits? hits,
      PersonalStatsAttackingPopular$Attacking$Damage? damage,
      PersonalStatsAttackingPopular$Attacking$Networth? networth,
      PersonalStatsAttackingPopular$Attacking$Ammunition? ammunition,
      PersonalStatsAttackingPopular$Attacking$Faction? faction}) {
    return PersonalStatsAttackingPopular$Attacking(
        attacks: attacks ?? this.attacks,
        defends: defends ?? this.defends,
        elo: elo ?? this.elo,
        escapes: escapes ?? this.escapes,
        killstreak: killstreak ?? this.killstreak,
        hits: hits ?? this.hits,
        damage: damage ?? this.damage,
        networth: networth ?? this.networth,
        ammunition: ammunition ?? this.ammunition,
        faction: faction ?? this.faction);
  }

  PersonalStatsAttackingPopular$Attacking copyWithWrapped(
      {Wrapped<PersonalStatsAttackingPopular$Attacking$Attacks?>? attacks,
      Wrapped<PersonalStatsAttackingPopular$Attacking$Defends?>? defends,
      Wrapped<int?>? elo,
      Wrapped<PersonalStatsAttackingPopular$Attacking$Escapes?>? escapes,
      Wrapped<PersonalStatsAttackingPopular$Attacking$Killstreak?>? killstreak,
      Wrapped<PersonalStatsAttackingPopular$Attacking$Hits?>? hits,
      Wrapped<PersonalStatsAttackingPopular$Attacking$Damage?>? damage,
      Wrapped<PersonalStatsAttackingPopular$Attacking$Networth?>? networth,
      Wrapped<PersonalStatsAttackingPopular$Attacking$Ammunition?>? ammunition,
      Wrapped<PersonalStatsAttackingPopular$Attacking$Faction?>? faction}) {
    return PersonalStatsAttackingPopular$Attacking(
        attacks: (attacks != null ? attacks.value : this.attacks),
        defends: (defends != null ? defends.value : this.defends),
        elo: (elo != null ? elo.value : this.elo),
        escapes: (escapes != null ? escapes.value : this.escapes),
        killstreak: (killstreak != null ? killstreak.value : this.killstreak),
        hits: (hits != null ? hits.value : this.hits),
        damage: (damage != null ? damage.value : this.damage),
        networth: (networth != null ? networth.value : this.networth),
        ammunition: (ammunition != null ? ammunition.value : this.ammunition),
        faction: (faction != null ? faction.value : this.faction));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsBootlegging$OnlineStore {
  const UserCrimeDetailsBootlegging$OnlineStore({
    this.earnings,
    this.visits,
    this.customers,
    this.sales,
  });

  factory UserCrimeDetailsBootlegging$OnlineStore.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsBootlegging$OnlineStoreFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsBootlegging$OnlineStoreToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsBootlegging$OnlineStoreToJson(this);

  @JsonKey(name: 'earnings')
  final int? earnings;
  @JsonKey(name: 'visits')
  final int? visits;
  @JsonKey(name: 'customers')
  final int? customers;
  @JsonKey(name: 'sales')
  final int? sales;
  static const fromJsonFactory = _$UserCrimeDetailsBootlegging$OnlineStoreFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsBootlegging$OnlineStore &&
            (identical(other.earnings, earnings) || const DeepCollectionEquality().equals(other.earnings, earnings)) &&
            (identical(other.visits, visits) || const DeepCollectionEquality().equals(other.visits, visits)) &&
            (identical(other.customers, customers) ||
                const DeepCollectionEquality().equals(other.customers, customers)) &&
            (identical(other.sales, sales) || const DeepCollectionEquality().equals(other.sales, sales)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(earnings) ^
      const DeepCollectionEquality().hash(visits) ^
      const DeepCollectionEquality().hash(customers) ^
      const DeepCollectionEquality().hash(sales) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsBootlegging$OnlineStoreExtension on UserCrimeDetailsBootlegging$OnlineStore {
  UserCrimeDetailsBootlegging$OnlineStore copyWith({int? earnings, int? visits, int? customers, int? sales}) {
    return UserCrimeDetailsBootlegging$OnlineStore(
        earnings: earnings ?? this.earnings,
        visits: visits ?? this.visits,
        customers: customers ?? this.customers,
        sales: sales ?? this.sales);
  }

  UserCrimeDetailsBootlegging$OnlineStore copyWithWrapped(
      {Wrapped<int?>? earnings, Wrapped<int?>? visits, Wrapped<int?>? customers, Wrapped<int?>? sales}) {
    return UserCrimeDetailsBootlegging$OnlineStore(
        earnings: (earnings != null ? earnings.value : this.earnings),
        visits: (visits != null ? visits.value : this.visits),
        customers: (customers != null ? customers.value : this.customers),
        sales: (sales != null ? sales.value : this.sales));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsBootlegging$DvdSales {
  const UserCrimeDetailsBootlegging$DvdSales({
    this.action,
    this.comedy,
    this.drama,
    this.fantasy,
    this.horror,
    this.romance,
    this.thriller,
    this.sciFi,
    this.total,
    this.earnings,
  });

  factory UserCrimeDetailsBootlegging$DvdSales.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsBootlegging$DvdSalesFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsBootlegging$DvdSalesToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsBootlegging$DvdSalesToJson(this);

  @JsonKey(name: 'action')
  final int? action;
  @JsonKey(name: 'comedy')
  final int? comedy;
  @JsonKey(name: 'drama')
  final int? drama;
  @JsonKey(name: 'fantasy')
  final int? fantasy;
  @JsonKey(name: 'horror')
  final int? horror;
  @JsonKey(name: 'romance')
  final int? romance;
  @JsonKey(name: 'thriller')
  final int? thriller;
  @JsonKey(name: 'sci-fi')
  final int? sciFi;
  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'earnings')
  final int? earnings;
  static const fromJsonFactory = _$UserCrimeDetailsBootlegging$DvdSalesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsBootlegging$DvdSales &&
            (identical(other.action, action) || const DeepCollectionEquality().equals(other.action, action)) &&
            (identical(other.comedy, comedy) || const DeepCollectionEquality().equals(other.comedy, comedy)) &&
            (identical(other.drama, drama) || const DeepCollectionEquality().equals(other.drama, drama)) &&
            (identical(other.fantasy, fantasy) || const DeepCollectionEquality().equals(other.fantasy, fantasy)) &&
            (identical(other.horror, horror) || const DeepCollectionEquality().equals(other.horror, horror)) &&
            (identical(other.romance, romance) || const DeepCollectionEquality().equals(other.romance, romance)) &&
            (identical(other.thriller, thriller) || const DeepCollectionEquality().equals(other.thriller, thriller)) &&
            (identical(other.sciFi, sciFi) || const DeepCollectionEquality().equals(other.sciFi, sciFi)) &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.earnings, earnings) || const DeepCollectionEquality().equals(other.earnings, earnings)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(action) ^
      const DeepCollectionEquality().hash(comedy) ^
      const DeepCollectionEquality().hash(drama) ^
      const DeepCollectionEquality().hash(fantasy) ^
      const DeepCollectionEquality().hash(horror) ^
      const DeepCollectionEquality().hash(romance) ^
      const DeepCollectionEquality().hash(thriller) ^
      const DeepCollectionEquality().hash(sciFi) ^
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(earnings) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsBootlegging$DvdSalesExtension on UserCrimeDetailsBootlegging$DvdSales {
  UserCrimeDetailsBootlegging$DvdSales copyWith(
      {int? action,
      int? comedy,
      int? drama,
      int? fantasy,
      int? horror,
      int? romance,
      int? thriller,
      int? sciFi,
      int? total,
      int? earnings}) {
    return UserCrimeDetailsBootlegging$DvdSales(
        action: action ?? this.action,
        comedy: comedy ?? this.comedy,
        drama: drama ?? this.drama,
        fantasy: fantasy ?? this.fantasy,
        horror: horror ?? this.horror,
        romance: romance ?? this.romance,
        thriller: thriller ?? this.thriller,
        sciFi: sciFi ?? this.sciFi,
        total: total ?? this.total,
        earnings: earnings ?? this.earnings);
  }

  UserCrimeDetailsBootlegging$DvdSales copyWithWrapped(
      {Wrapped<int?>? action,
      Wrapped<int?>? comedy,
      Wrapped<int?>? drama,
      Wrapped<int?>? fantasy,
      Wrapped<int?>? horror,
      Wrapped<int?>? romance,
      Wrapped<int?>? thriller,
      Wrapped<int?>? sciFi,
      Wrapped<int?>? total,
      Wrapped<int?>? earnings}) {
    return UserCrimeDetailsBootlegging$DvdSales(
        action: (action != null ? action.value : this.action),
        comedy: (comedy != null ? comedy.value : this.comedy),
        drama: (drama != null ? drama.value : this.drama),
        fantasy: (fantasy != null ? fantasy.value : this.fantasy),
        horror: (horror != null ? horror.value : this.horror),
        romance: (romance != null ? romance.value : this.romance),
        thriller: (thriller != null ? thriller.value : this.thriller),
        sciFi: (sciFi != null ? sciFi.value : this.sciFi),
        total: (total != null ? total.value : this.total),
        earnings: (earnings != null ? earnings.value : this.earnings));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsCardSkimming$CardDetails {
  const UserCrimeDetailsCardSkimming$CardDetails({
    this.recoverable,
    this.recovered,
    this.sold,
    this.lost,
    this.areas,
  });

  factory UserCrimeDetailsCardSkimming$CardDetails.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsCardSkimming$CardDetailsFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsCardSkimming$CardDetailsToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsCardSkimming$CardDetailsToJson(this);

  @JsonKey(name: 'recoverable')
  final int? recoverable;
  @JsonKey(name: 'recovered')
  final int? recovered;
  @JsonKey(name: 'sold')
  final int? sold;
  @JsonKey(name: 'lost')
  final int? lost;
  @JsonKey(name: 'areas')
  final List<UserCrimeDetailsCardSkimming$CardDetails$Areas$Item>? areas;
  static const fromJsonFactory = _$UserCrimeDetailsCardSkimming$CardDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsCardSkimming$CardDetails &&
            (identical(other.recoverable, recoverable) ||
                const DeepCollectionEquality().equals(other.recoverable, recoverable)) &&
            (identical(other.recovered, recovered) ||
                const DeepCollectionEquality().equals(other.recovered, recovered)) &&
            (identical(other.sold, sold) || const DeepCollectionEquality().equals(other.sold, sold)) &&
            (identical(other.lost, lost) || const DeepCollectionEquality().equals(other.lost, lost)) &&
            (identical(other.areas, areas) || const DeepCollectionEquality().equals(other.areas, areas)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(recoverable) ^
      const DeepCollectionEquality().hash(recovered) ^
      const DeepCollectionEquality().hash(sold) ^
      const DeepCollectionEquality().hash(lost) ^
      const DeepCollectionEquality().hash(areas) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsCardSkimming$CardDetailsExtension on UserCrimeDetailsCardSkimming$CardDetails {
  UserCrimeDetailsCardSkimming$CardDetails copyWith(
      {int? recoverable,
      int? recovered,
      int? sold,
      int? lost,
      List<UserCrimeDetailsCardSkimming$CardDetails$Areas$Item>? areas}) {
    return UserCrimeDetailsCardSkimming$CardDetails(
        recoverable: recoverable ?? this.recoverable,
        recovered: recovered ?? this.recovered,
        sold: sold ?? this.sold,
        lost: lost ?? this.lost,
        areas: areas ?? this.areas);
  }

  UserCrimeDetailsCardSkimming$CardDetails copyWithWrapped(
      {Wrapped<int?>? recoverable,
      Wrapped<int?>? recovered,
      Wrapped<int?>? sold,
      Wrapped<int?>? lost,
      Wrapped<List<UserCrimeDetailsCardSkimming$CardDetails$Areas$Item>?>? areas}) {
    return UserCrimeDetailsCardSkimming$CardDetails(
        recoverable: (recoverable != null ? recoverable.value : this.recoverable),
        recovered: (recovered != null ? recovered.value : this.recovered),
        sold: (sold != null ? sold.value : this.sold),
        lost: (lost != null ? lost.value : this.lost),
        areas: (areas != null ? areas.value : this.areas));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsCardSkimming$Skimmers {
  const UserCrimeDetailsCardSkimming$Skimmers({
    this.active,
    this.mostLucrative,
    this.oldestRecovered,
    this.lost,
  });

  factory UserCrimeDetailsCardSkimming$Skimmers.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsCardSkimming$SkimmersFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsCardSkimming$SkimmersToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsCardSkimming$SkimmersToJson(this);

  @JsonKey(name: 'active')
  final int? active;
  @JsonKey(name: 'most_lucrative')
  final int? mostLucrative;
  @JsonKey(name: 'oldest_recovered')
  final int? oldestRecovered;
  @JsonKey(name: 'lost')
  final int? lost;
  static const fromJsonFactory = _$UserCrimeDetailsCardSkimming$SkimmersFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsCardSkimming$Skimmers &&
            (identical(other.active, active) || const DeepCollectionEquality().equals(other.active, active)) &&
            (identical(other.mostLucrative, mostLucrative) ||
                const DeepCollectionEquality().equals(other.mostLucrative, mostLucrative)) &&
            (identical(other.oldestRecovered, oldestRecovered) ||
                const DeepCollectionEquality().equals(other.oldestRecovered, oldestRecovered)) &&
            (identical(other.lost, lost) || const DeepCollectionEquality().equals(other.lost, lost)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(active) ^
      const DeepCollectionEquality().hash(mostLucrative) ^
      const DeepCollectionEquality().hash(oldestRecovered) ^
      const DeepCollectionEquality().hash(lost) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsCardSkimming$SkimmersExtension on UserCrimeDetailsCardSkimming$Skimmers {
  UserCrimeDetailsCardSkimming$Skimmers copyWith({int? active, int? mostLucrative, int? oldestRecovered, int? lost}) {
    return UserCrimeDetailsCardSkimming$Skimmers(
        active: active ?? this.active,
        mostLucrative: mostLucrative ?? this.mostLucrative,
        oldestRecovered: oldestRecovered ?? this.oldestRecovered,
        lost: lost ?? this.lost);
  }

  UserCrimeDetailsCardSkimming$Skimmers copyWithWrapped(
      {Wrapped<int?>? active, Wrapped<int?>? mostLucrative, Wrapped<int?>? oldestRecovered, Wrapped<int?>? lost}) {
    return UserCrimeDetailsCardSkimming$Skimmers(
        active: (active != null ? active.value : this.active),
        mostLucrative: (mostLucrative != null ? mostLucrative.value : this.mostLucrative),
        oldestRecovered: (oldestRecovered != null ? oldestRecovered.value : this.oldestRecovered),
        lost: (lost != null ? lost.value : this.lost));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsScamming$Zones {
  const UserCrimeDetailsScamming$Zones({
    this.red,
    this.neutral,
    this.concern,
    this.sensitivity,
    this.temptation,
    this.hesitation,
    this.lowReward,
    this.mediumReward,
    this.highReward,
  });

  factory UserCrimeDetailsScamming$Zones.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsScamming$ZonesFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsScamming$ZonesToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsScamming$ZonesToJson(this);

  @JsonKey(name: 'red')
  final int? red;
  @JsonKey(name: 'neutral')
  final int? neutral;
  @JsonKey(name: 'concern')
  final int? concern;
  @JsonKey(name: 'sensitivity')
  final int? sensitivity;
  @JsonKey(name: 'temptation')
  final int? temptation;
  @JsonKey(name: 'hesitation')
  final int? hesitation;
  @JsonKey(name: 'low_reward')
  final int? lowReward;
  @JsonKey(name: 'medium_reward')
  final int? mediumReward;
  @JsonKey(name: 'high_reward')
  final int? highReward;
  static const fromJsonFactory = _$UserCrimeDetailsScamming$ZonesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsScamming$Zones &&
            (identical(other.red, red) || const DeepCollectionEquality().equals(other.red, red)) &&
            (identical(other.neutral, neutral) || const DeepCollectionEquality().equals(other.neutral, neutral)) &&
            (identical(other.concern, concern) || const DeepCollectionEquality().equals(other.concern, concern)) &&
            (identical(other.sensitivity, sensitivity) ||
                const DeepCollectionEquality().equals(other.sensitivity, sensitivity)) &&
            (identical(other.temptation, temptation) ||
                const DeepCollectionEquality().equals(other.temptation, temptation)) &&
            (identical(other.hesitation, hesitation) ||
                const DeepCollectionEquality().equals(other.hesitation, hesitation)) &&
            (identical(other.lowReward, lowReward) ||
                const DeepCollectionEquality().equals(other.lowReward, lowReward)) &&
            (identical(other.mediumReward, mediumReward) ||
                const DeepCollectionEquality().equals(other.mediumReward, mediumReward)) &&
            (identical(other.highReward, highReward) ||
                const DeepCollectionEquality().equals(other.highReward, highReward)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(red) ^
      const DeepCollectionEquality().hash(neutral) ^
      const DeepCollectionEquality().hash(concern) ^
      const DeepCollectionEquality().hash(sensitivity) ^
      const DeepCollectionEquality().hash(temptation) ^
      const DeepCollectionEquality().hash(hesitation) ^
      const DeepCollectionEquality().hash(lowReward) ^
      const DeepCollectionEquality().hash(mediumReward) ^
      const DeepCollectionEquality().hash(highReward) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsScamming$ZonesExtension on UserCrimeDetailsScamming$Zones {
  UserCrimeDetailsScamming$Zones copyWith(
      {int? red,
      int? neutral,
      int? concern,
      int? sensitivity,
      int? temptation,
      int? hesitation,
      int? lowReward,
      int? mediumReward,
      int? highReward}) {
    return UserCrimeDetailsScamming$Zones(
        red: red ?? this.red,
        neutral: neutral ?? this.neutral,
        concern: concern ?? this.concern,
        sensitivity: sensitivity ?? this.sensitivity,
        temptation: temptation ?? this.temptation,
        hesitation: hesitation ?? this.hesitation,
        lowReward: lowReward ?? this.lowReward,
        mediumReward: mediumReward ?? this.mediumReward,
        highReward: highReward ?? this.highReward);
  }

  UserCrimeDetailsScamming$Zones copyWithWrapped(
      {Wrapped<int?>? red,
      Wrapped<int?>? neutral,
      Wrapped<int?>? concern,
      Wrapped<int?>? sensitivity,
      Wrapped<int?>? temptation,
      Wrapped<int?>? hesitation,
      Wrapped<int?>? lowReward,
      Wrapped<int?>? mediumReward,
      Wrapped<int?>? highReward}) {
    return UserCrimeDetailsScamming$Zones(
        red: (red != null ? red.value : this.red),
        neutral: (neutral != null ? neutral.value : this.neutral),
        concern: (concern != null ? concern.value : this.concern),
        sensitivity: (sensitivity != null ? sensitivity.value : this.sensitivity),
        temptation: (temptation != null ? temptation.value : this.temptation),
        hesitation: (hesitation != null ? hesitation.value : this.hesitation),
        lowReward: (lowReward != null ? lowReward.value : this.lowReward),
        mediumReward: (mediumReward != null ? mediumReward.value : this.mediumReward),
        highReward: (highReward != null ? highReward.value : this.highReward));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsScamming$Concerns {
  const UserCrimeDetailsScamming$Concerns({
    this.attempts,
    this.resolved,
  });

  factory UserCrimeDetailsScamming$Concerns.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsScamming$ConcernsFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsScamming$ConcernsToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsScamming$ConcernsToJson(this);

  @JsonKey(name: 'attempts')
  final int? attempts;
  @JsonKey(name: 'resolved')
  final int? resolved;
  static const fromJsonFactory = _$UserCrimeDetailsScamming$ConcernsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsScamming$Concerns &&
            (identical(other.attempts, attempts) || const DeepCollectionEquality().equals(other.attempts, attempts)) &&
            (identical(other.resolved, resolved) || const DeepCollectionEquality().equals(other.resolved, resolved)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(attempts) ^
      const DeepCollectionEquality().hash(resolved) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsScamming$ConcernsExtension on UserCrimeDetailsScamming$Concerns {
  UserCrimeDetailsScamming$Concerns copyWith({int? attempts, int? resolved}) {
    return UserCrimeDetailsScamming$Concerns(attempts: attempts ?? this.attempts, resolved: resolved ?? this.resolved);
  }

  UserCrimeDetailsScamming$Concerns copyWithWrapped({Wrapped<int?>? attempts, Wrapped<int?>? resolved}) {
    return UserCrimeDetailsScamming$Concerns(
        attempts: (attempts != null ? attempts.value : this.attempts),
        resolved: (resolved != null ? resolved.value : this.resolved));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsScamming$Payouts {
  const UserCrimeDetailsScamming$Payouts({
    this.low,
    this.medium,
    this.high,
  });

  factory UserCrimeDetailsScamming$Payouts.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsScamming$PayoutsFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsScamming$PayoutsToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsScamming$PayoutsToJson(this);

  @JsonKey(name: 'low')
  final int? low;
  @JsonKey(name: 'medium')
  final int? medium;
  @JsonKey(name: 'high')
  final int? high;
  static const fromJsonFactory = _$UserCrimeDetailsScamming$PayoutsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsScamming$Payouts &&
            (identical(other.low, low) || const DeepCollectionEquality().equals(other.low, low)) &&
            (identical(other.medium, medium) || const DeepCollectionEquality().equals(other.medium, medium)) &&
            (identical(other.high, high) || const DeepCollectionEquality().equals(other.high, high)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(low) ^
      const DeepCollectionEquality().hash(medium) ^
      const DeepCollectionEquality().hash(high) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsScamming$PayoutsExtension on UserCrimeDetailsScamming$Payouts {
  UserCrimeDetailsScamming$Payouts copyWith({int? low, int? medium, int? high}) {
    return UserCrimeDetailsScamming$Payouts(
        low: low ?? this.low, medium: medium ?? this.medium, high: high ?? this.high);
  }

  UserCrimeDetailsScamming$Payouts copyWithWrapped({Wrapped<int?>? low, Wrapped<int?>? medium, Wrapped<int?>? high}) {
    return UserCrimeDetailsScamming$Payouts(
        low: (low != null ? low.value : this.low),
        medium: (medium != null ? medium.value : this.medium),
        high: (high != null ? high.value : this.high));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsScamming$Emails {
  const UserCrimeDetailsScamming$Emails({
    this.scraper,
    this.phisher,
  });

  factory UserCrimeDetailsScamming$Emails.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsScamming$EmailsFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsScamming$EmailsToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsScamming$EmailsToJson(this);

  @JsonKey(name: 'scraper')
  final int? scraper;
  @JsonKey(name: 'phisher')
  final int? phisher;
  static const fromJsonFactory = _$UserCrimeDetailsScamming$EmailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsScamming$Emails &&
            (identical(other.scraper, scraper) || const DeepCollectionEquality().equals(other.scraper, scraper)) &&
            (identical(other.phisher, phisher) || const DeepCollectionEquality().equals(other.phisher, phisher)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(scraper) ^
      const DeepCollectionEquality().hash(phisher) ^
      runtimeType.hashCode;
}

extension $UserCrimeDetailsScamming$EmailsExtension on UserCrimeDetailsScamming$Emails {
  UserCrimeDetailsScamming$Emails copyWith({int? scraper, int? phisher}) {
    return UserCrimeDetailsScamming$Emails(scraper: scraper ?? this.scraper, phisher: phisher ?? this.phisher);
  }

  UserCrimeDetailsScamming$Emails copyWithWrapped({Wrapped<int?>? scraper, Wrapped<int?>? phisher}) {
    return UserCrimeDetailsScamming$Emails(
        scraper: (scraper != null ? scraper.value : this.scraper),
        phisher: (phisher != null ? phisher.value : this.phisher));
  }
}

@JsonSerializable(explicitToJson: true)
class FactionApplication$User$Stats {
  const FactionApplication$User$Stats({
    this.strength,
    this.speed,
    this.dexterity,
    this.defense,
  });

  factory FactionApplication$User$Stats.fromJson(Map<String, dynamic> json) =>
      _$FactionApplication$User$StatsFromJson(json);

  static const toJsonFactory = _$FactionApplication$User$StatsToJson;
  Map<String, dynamic> toJson() => _$FactionApplication$User$StatsToJson(this);

  @JsonKey(name: 'strength')
  final int? strength;
  @JsonKey(name: 'speed')
  final int? speed;
  @JsonKey(name: 'dexterity')
  final int? dexterity;
  @JsonKey(name: 'defense')
  final int? defense;
  static const fromJsonFactory = _$FactionApplication$User$StatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FactionApplication$User$Stats &&
            (identical(other.strength, strength) || const DeepCollectionEquality().equals(other.strength, strength)) &&
            (identical(other.speed, speed) || const DeepCollectionEquality().equals(other.speed, speed)) &&
            (identical(other.dexterity, dexterity) ||
                const DeepCollectionEquality().equals(other.dexterity, dexterity)) &&
            (identical(other.defense, defense) || const DeepCollectionEquality().equals(other.defense, defense)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(strength) ^
      const DeepCollectionEquality().hash(speed) ^
      const DeepCollectionEquality().hash(dexterity) ^
      const DeepCollectionEquality().hash(defense) ^
      runtimeType.hashCode;
}

extension $FactionApplication$User$StatsExtension on FactionApplication$User$Stats {
  FactionApplication$User$Stats copyWith({int? strength, int? speed, int? dexterity, int? defense}) {
    return FactionApplication$User$Stats(
        strength: strength ?? this.strength,
        speed: speed ?? this.speed,
        dexterity: dexterity ?? this.dexterity,
        defense: defense ?? this.defense);
  }

  FactionApplication$User$Stats copyWithWrapped(
      {Wrapped<int?>? strength, Wrapped<int?>? speed, Wrapped<int?>? dexterity, Wrapped<int?>? defense}) {
    return FactionApplication$User$Stats(
        strength: (strength != null ? strength.value : this.strength),
        speed: (speed != null ? speed.value : this.speed),
        dexterity: (dexterity != null ? dexterity.value : this.dexterity),
        defense: (defense != null ? defense.value : this.defense));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOther$Other$Activity {
  const PersonalStatsOther$Other$Activity({
    this.time,
    this.streak,
  });

  factory PersonalStatsOther$Other$Activity.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsOther$Other$ActivityFromJson(json);

  static const toJsonFactory = _$PersonalStatsOther$Other$ActivityToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOther$Other$ActivityToJson(this);

  @JsonKey(name: 'time')
  final int? time;
  @JsonKey(name: 'streak')
  final PersonalStatsOther$Other$Activity$Streak? streak;
  static const fromJsonFactory = _$PersonalStatsOther$Other$ActivityFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOther$Other$Activity &&
            (identical(other.time, time) || const DeepCollectionEquality().equals(other.time, time)) &&
            (identical(other.streak, streak) || const DeepCollectionEquality().equals(other.streak, streak)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(time) ^ const DeepCollectionEquality().hash(streak) ^ runtimeType.hashCode;
}

extension $PersonalStatsOther$Other$ActivityExtension on PersonalStatsOther$Other$Activity {
  PersonalStatsOther$Other$Activity copyWith({int? time, PersonalStatsOther$Other$Activity$Streak? streak}) {
    return PersonalStatsOther$Other$Activity(time: time ?? this.time, streak: streak ?? this.streak);
  }

  PersonalStatsOther$Other$Activity copyWithWrapped(
      {Wrapped<int?>? time, Wrapped<PersonalStatsOther$Other$Activity$Streak?>? streak}) {
    return PersonalStatsOther$Other$Activity(
        time: (time != null ? time.value : this.time), streak: (streak != null ? streak.value : this.streak));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOther$Other$Refills {
  const PersonalStatsOther$Other$Refills({
    this.energy,
    this.nerve,
    this.token,
  });

  factory PersonalStatsOther$Other$Refills.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsOther$Other$RefillsFromJson(json);

  static const toJsonFactory = _$PersonalStatsOther$Other$RefillsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOther$Other$RefillsToJson(this);

  @JsonKey(name: 'energy')
  final int? energy;
  @JsonKey(name: 'nerve')
  final int? nerve;
  @JsonKey(name: 'token')
  final int? token;
  static const fromJsonFactory = _$PersonalStatsOther$Other$RefillsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOther$Other$Refills &&
            (identical(other.energy, energy) || const DeepCollectionEquality().equals(other.energy, energy)) &&
            (identical(other.nerve, nerve) || const DeepCollectionEquality().equals(other.nerve, nerve)) &&
            (identical(other.token, token) || const DeepCollectionEquality().equals(other.token, token)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(energy) ^
      const DeepCollectionEquality().hash(nerve) ^
      const DeepCollectionEquality().hash(token) ^
      runtimeType.hashCode;
}

extension $PersonalStatsOther$Other$RefillsExtension on PersonalStatsOther$Other$Refills {
  PersonalStatsOther$Other$Refills copyWith({int? energy, int? nerve, int? token}) {
    return PersonalStatsOther$Other$Refills(
        energy: energy ?? this.energy, nerve: nerve ?? this.nerve, token: token ?? this.token);
  }

  PersonalStatsOther$Other$Refills copyWithWrapped(
      {Wrapped<int?>? energy, Wrapped<int?>? nerve, Wrapped<int?>? token}) {
    return PersonalStatsOther$Other$Refills(
        energy: (energy != null ? energy.value : this.energy),
        nerve: (nerve != null ? nerve.value : this.nerve),
        token: (token != null ? token.value : this.token));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOtherPopular$Other$Activity {
  const PersonalStatsOtherPopular$Other$Activity({
    this.time,
    this.streak,
  });

  factory PersonalStatsOtherPopular$Other$Activity.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsOtherPopular$Other$ActivityFromJson(json);

  static const toJsonFactory = _$PersonalStatsOtherPopular$Other$ActivityToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOtherPopular$Other$ActivityToJson(this);

  @JsonKey(name: 'time')
  final int? time;
  @JsonKey(name: 'streak')
  final PersonalStatsOtherPopular$Other$Activity$Streak? streak;
  static const fromJsonFactory = _$PersonalStatsOtherPopular$Other$ActivityFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOtherPopular$Other$Activity &&
            (identical(other.time, time) || const DeepCollectionEquality().equals(other.time, time)) &&
            (identical(other.streak, streak) || const DeepCollectionEquality().equals(other.streak, streak)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(time) ^ const DeepCollectionEquality().hash(streak) ^ runtimeType.hashCode;
}

extension $PersonalStatsOtherPopular$Other$ActivityExtension on PersonalStatsOtherPopular$Other$Activity {
  PersonalStatsOtherPopular$Other$Activity copyWith(
      {int? time, PersonalStatsOtherPopular$Other$Activity$Streak? streak}) {
    return PersonalStatsOtherPopular$Other$Activity(time: time ?? this.time, streak: streak ?? this.streak);
  }

  PersonalStatsOtherPopular$Other$Activity copyWithWrapped(
      {Wrapped<int?>? time, Wrapped<PersonalStatsOtherPopular$Other$Activity$Streak?>? streak}) {
    return PersonalStatsOtherPopular$Other$Activity(
        time: (time != null ? time.value : this.time), streak: (streak != null ? streak.value : this.streak));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOtherPopular$Other$Refills {
  const PersonalStatsOtherPopular$Other$Refills({
    this.energy,
    this.nerve,
  });

  factory PersonalStatsOtherPopular$Other$Refills.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsOtherPopular$Other$RefillsFromJson(json);

  static const toJsonFactory = _$PersonalStatsOtherPopular$Other$RefillsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOtherPopular$Other$RefillsToJson(this);

  @JsonKey(name: 'energy')
  final int? energy;
  @JsonKey(name: 'nerve')
  final int? nerve;
  static const fromJsonFactory = _$PersonalStatsOtherPopular$Other$RefillsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOtherPopular$Other$Refills &&
            (identical(other.energy, energy) || const DeepCollectionEquality().equals(other.energy, energy)) &&
            (identical(other.nerve, nerve) || const DeepCollectionEquality().equals(other.nerve, nerve)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(energy) ^ const DeepCollectionEquality().hash(nerve) ^ runtimeType.hashCode;
}

extension $PersonalStatsOtherPopular$Other$RefillsExtension on PersonalStatsOtherPopular$Other$Refills {
  PersonalStatsOtherPopular$Other$Refills copyWith({int? energy, int? nerve}) {
    return PersonalStatsOtherPopular$Other$Refills(energy: energy ?? this.energy, nerve: nerve ?? this.nerve);
  }

  PersonalStatsOtherPopular$Other$Refills copyWithWrapped({Wrapped<int?>? energy, Wrapped<int?>? nerve}) {
    return PersonalStatsOtherPopular$Other$Refills(
        energy: (energy != null ? energy.value : this.energy), nerve: (nerve != null ? nerve.value : this.nerve));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsRacing$Racing$Races {
  const PersonalStatsRacing$Racing$Races({
    this.entered,
    this.won,
  });

  factory PersonalStatsRacing$Racing$Races.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsRacing$Racing$RacesFromJson(json);

  static const toJsonFactory = _$PersonalStatsRacing$Racing$RacesToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsRacing$Racing$RacesToJson(this);

  @JsonKey(name: 'entered')
  final int? entered;
  @JsonKey(name: 'won')
  final int? won;
  static const fromJsonFactory = _$PersonalStatsRacing$Racing$RacesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsRacing$Racing$Races &&
            (identical(other.entered, entered) || const DeepCollectionEquality().equals(other.entered, entered)) &&
            (identical(other.won, won) || const DeepCollectionEquality().equals(other.won, won)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(entered) ^ const DeepCollectionEquality().hash(won) ^ runtimeType.hashCode;
}

extension $PersonalStatsRacing$Racing$RacesExtension on PersonalStatsRacing$Racing$Races {
  PersonalStatsRacing$Racing$Races copyWith({int? entered, int? won}) {
    return PersonalStatsRacing$Racing$Races(entered: entered ?? this.entered, won: won ?? this.won);
  }

  PersonalStatsRacing$Racing$Races copyWithWrapped({Wrapped<int?>? entered, Wrapped<int?>? won}) {
    return PersonalStatsRacing$Racing$Races(
        entered: (entered != null ? entered.value : this.entered), won: (won != null ? won.value : this.won));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsMissions$Missions$Contracts {
  const PersonalStatsMissions$Missions$Contracts({
    this.total,
    this.duke,
  });

  factory PersonalStatsMissions$Missions$Contracts.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsMissions$Missions$ContractsFromJson(json);

  static const toJsonFactory = _$PersonalStatsMissions$Missions$ContractsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsMissions$Missions$ContractsToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'duke')
  final int? duke;
  static const fromJsonFactory = _$PersonalStatsMissions$Missions$ContractsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsMissions$Missions$Contracts &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.duke, duke) || const DeepCollectionEquality().equals(other.duke, duke)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^ const DeepCollectionEquality().hash(duke) ^ runtimeType.hashCode;
}

extension $PersonalStatsMissions$Missions$ContractsExtension on PersonalStatsMissions$Missions$Contracts {
  PersonalStatsMissions$Missions$Contracts copyWith({int? total, int? duke}) {
    return PersonalStatsMissions$Missions$Contracts(total: total ?? this.total, duke: duke ?? this.duke);
  }

  PersonalStatsMissions$Missions$Contracts copyWithWrapped({Wrapped<int?>? total, Wrapped<int?>? duke}) {
    return PersonalStatsMissions$Missions$Contracts(
        total: (total != null ? total.value : this.total), duke: (duke != null ? duke.value : this.duke));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsDrugs$Drugs$Rehabilitations {
  const PersonalStatsDrugs$Drugs$Rehabilitations({
    this.amount,
    this.fees,
  });

  factory PersonalStatsDrugs$Drugs$Rehabilitations.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsDrugs$Drugs$RehabilitationsFromJson(json);

  static const toJsonFactory = _$PersonalStatsDrugs$Drugs$RehabilitationsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsDrugs$Drugs$RehabilitationsToJson(this);

  @JsonKey(name: 'amount')
  final int? amount;
  @JsonKey(name: 'fees')
  final int? fees;
  static const fromJsonFactory = _$PersonalStatsDrugs$Drugs$RehabilitationsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsDrugs$Drugs$Rehabilitations &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.fees, fees) || const DeepCollectionEquality().equals(other.fees, fees)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(amount) ^ const DeepCollectionEquality().hash(fees) ^ runtimeType.hashCode;
}

extension $PersonalStatsDrugs$Drugs$RehabilitationsExtension on PersonalStatsDrugs$Drugs$Rehabilitations {
  PersonalStatsDrugs$Drugs$Rehabilitations copyWith({int? amount, int? fees}) {
    return PersonalStatsDrugs$Drugs$Rehabilitations(amount: amount ?? this.amount, fees: fees ?? this.fees);
  }

  PersonalStatsDrugs$Drugs$Rehabilitations copyWithWrapped({Wrapped<int?>? amount, Wrapped<int?>? fees}) {
    return PersonalStatsDrugs$Drugs$Rehabilitations(
        amount: (amount != null ? amount.value : this.amount), fees: (fees != null ? fees.value : this.fees));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTravel$Travel$Hunting {
  const PersonalStatsTravel$Travel$Hunting({
    this.skill,
  });

  factory PersonalStatsTravel$Travel$Hunting.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsTravel$Travel$HuntingFromJson(json);

  static const toJsonFactory = _$PersonalStatsTravel$Travel$HuntingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTravel$Travel$HuntingToJson(this);

  @JsonKey(name: 'skill')
  final int? skill;
  static const fromJsonFactory = _$PersonalStatsTravel$Travel$HuntingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTravel$Travel$Hunting &&
            (identical(other.skill, skill) || const DeepCollectionEquality().equals(other.skill, skill)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(skill) ^ runtimeType.hashCode;
}

extension $PersonalStatsTravel$Travel$HuntingExtension on PersonalStatsTravel$Travel$Hunting {
  PersonalStatsTravel$Travel$Hunting copyWith({int? skill}) {
    return PersonalStatsTravel$Travel$Hunting(skill: skill ?? this.skill);
  }

  PersonalStatsTravel$Travel$Hunting copyWithWrapped({Wrapped<int?>? skill}) {
    return PersonalStatsTravel$Travel$Hunting(skill: (skill != null ? skill.value : this.skill));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsItems$Items$Found {
  const PersonalStatsItems$Items$Found({
    this.city,
    this.dump,
    this.easterEggs,
  });

  factory PersonalStatsItems$Items$Found.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsItems$Items$FoundFromJson(json);

  static const toJsonFactory = _$PersonalStatsItems$Items$FoundToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsItems$Items$FoundToJson(this);

  @JsonKey(name: 'city')
  final int? city;
  @JsonKey(name: 'dump')
  final int? dump;
  @JsonKey(name: 'easter_eggs')
  final int? easterEggs;
  static const fromJsonFactory = _$PersonalStatsItems$Items$FoundFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsItems$Items$Found &&
            (identical(other.city, city) || const DeepCollectionEquality().equals(other.city, city)) &&
            (identical(other.dump, dump) || const DeepCollectionEquality().equals(other.dump, dump)) &&
            (identical(other.easterEggs, easterEggs) ||
                const DeepCollectionEquality().equals(other.easterEggs, easterEggs)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(city) ^
      const DeepCollectionEquality().hash(dump) ^
      const DeepCollectionEquality().hash(easterEggs) ^
      runtimeType.hashCode;
}

extension $PersonalStatsItems$Items$FoundExtension on PersonalStatsItems$Items$Found {
  PersonalStatsItems$Items$Found copyWith({int? city, int? dump, int? easterEggs}) {
    return PersonalStatsItems$Items$Found(
        city: city ?? this.city, dump: dump ?? this.dump, easterEggs: easterEggs ?? this.easterEggs);
  }

  PersonalStatsItems$Items$Found copyWithWrapped(
      {Wrapped<int?>? city, Wrapped<int?>? dump, Wrapped<int?>? easterEggs}) {
    return PersonalStatsItems$Items$Found(
        city: (city != null ? city.value : this.city),
        dump: (dump != null ? dump.value : this.dump),
        easterEggs: (easterEggs != null ? easterEggs.value : this.easterEggs));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsItems$Items$Used {
  const PersonalStatsItems$Items$Used({
    this.books,
    this.boosters,
    this.consumables,
    this.candy,
    this.alcohol,
    this.energyDrinks,
    this.statEnhancers,
    this.easterEggs,
  });

  factory PersonalStatsItems$Items$Used.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsItems$Items$UsedFromJson(json);

  static const toJsonFactory = _$PersonalStatsItems$Items$UsedToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsItems$Items$UsedToJson(this);

  @JsonKey(name: 'books')
  final int? books;
  @JsonKey(name: 'boosters')
  final int? boosters;
  @JsonKey(name: 'consumables')
  final int? consumables;
  @JsonKey(name: 'candy')
  final int? candy;
  @JsonKey(name: 'alcohol')
  final int? alcohol;
  @JsonKey(name: 'energy_drinks')
  final int? energyDrinks;
  @JsonKey(name: 'stat_enhancers')
  final int? statEnhancers;
  @JsonKey(name: 'easter_eggs')
  final int? easterEggs;
  static const fromJsonFactory = _$PersonalStatsItems$Items$UsedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsItems$Items$Used &&
            (identical(other.books, books) || const DeepCollectionEquality().equals(other.books, books)) &&
            (identical(other.boosters, boosters) || const DeepCollectionEquality().equals(other.boosters, boosters)) &&
            (identical(other.consumables, consumables) ||
                const DeepCollectionEquality().equals(other.consumables, consumables)) &&
            (identical(other.candy, candy) || const DeepCollectionEquality().equals(other.candy, candy)) &&
            (identical(other.alcohol, alcohol) || const DeepCollectionEquality().equals(other.alcohol, alcohol)) &&
            (identical(other.energyDrinks, energyDrinks) ||
                const DeepCollectionEquality().equals(other.energyDrinks, energyDrinks)) &&
            (identical(other.statEnhancers, statEnhancers) ||
                const DeepCollectionEquality().equals(other.statEnhancers, statEnhancers)) &&
            (identical(other.easterEggs, easterEggs) ||
                const DeepCollectionEquality().equals(other.easterEggs, easterEggs)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(books) ^
      const DeepCollectionEquality().hash(boosters) ^
      const DeepCollectionEquality().hash(consumables) ^
      const DeepCollectionEquality().hash(candy) ^
      const DeepCollectionEquality().hash(alcohol) ^
      const DeepCollectionEquality().hash(energyDrinks) ^
      const DeepCollectionEquality().hash(statEnhancers) ^
      const DeepCollectionEquality().hash(easterEggs) ^
      runtimeType.hashCode;
}

extension $PersonalStatsItems$Items$UsedExtension on PersonalStatsItems$Items$Used {
  PersonalStatsItems$Items$Used copyWith(
      {int? books,
      int? boosters,
      int? consumables,
      int? candy,
      int? alcohol,
      int? energyDrinks,
      int? statEnhancers,
      int? easterEggs}) {
    return PersonalStatsItems$Items$Used(
        books: books ?? this.books,
        boosters: boosters ?? this.boosters,
        consumables: consumables ?? this.consumables,
        candy: candy ?? this.candy,
        alcohol: alcohol ?? this.alcohol,
        energyDrinks: energyDrinks ?? this.energyDrinks,
        statEnhancers: statEnhancers ?? this.statEnhancers,
        easterEggs: easterEggs ?? this.easterEggs);
  }

  PersonalStatsItems$Items$Used copyWithWrapped(
      {Wrapped<int?>? books,
      Wrapped<int?>? boosters,
      Wrapped<int?>? consumables,
      Wrapped<int?>? candy,
      Wrapped<int?>? alcohol,
      Wrapped<int?>? energyDrinks,
      Wrapped<int?>? statEnhancers,
      Wrapped<int?>? easterEggs}) {
    return PersonalStatsItems$Items$Used(
        books: (books != null ? books.value : this.books),
        boosters: (boosters != null ? boosters.value : this.boosters),
        consumables: (consumables != null ? consumables.value : this.consumables),
        candy: (candy != null ? candy.value : this.candy),
        alcohol: (alcohol != null ? alcohol.value : this.alcohol),
        energyDrinks: (energyDrinks != null ? energyDrinks.value : this.energyDrinks),
        statEnhancers: (statEnhancers != null ? statEnhancers.value : this.statEnhancers),
        easterEggs: (easterEggs != null ? easterEggs.value : this.easterEggs));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsItemsPopular$Items$Found {
  const PersonalStatsItemsPopular$Items$Found({
    this.dump,
  });

  factory PersonalStatsItemsPopular$Items$Found.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsItemsPopular$Items$FoundFromJson(json);

  static const toJsonFactory = _$PersonalStatsItemsPopular$Items$FoundToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsItemsPopular$Items$FoundToJson(this);

  @JsonKey(name: 'dump')
  final int? dump;
  static const fromJsonFactory = _$PersonalStatsItemsPopular$Items$FoundFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsItemsPopular$Items$Found &&
            (identical(other.dump, dump) || const DeepCollectionEquality().equals(other.dump, dump)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(dump) ^ runtimeType.hashCode;
}

extension $PersonalStatsItemsPopular$Items$FoundExtension on PersonalStatsItemsPopular$Items$Found {
  PersonalStatsItemsPopular$Items$Found copyWith({int? dump}) {
    return PersonalStatsItemsPopular$Items$Found(dump: dump ?? this.dump);
  }

  PersonalStatsItemsPopular$Items$Found copyWithWrapped({Wrapped<int?>? dump}) {
    return PersonalStatsItemsPopular$Items$Found(dump: (dump != null ? dump.value : this.dump));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsItemsPopular$Items$Used {
  const PersonalStatsItemsPopular$Items$Used({
    this.books,
    this.boosters,
    this.consumables,
    this.candy,
    this.alcohol,
    this.energyDrinks,
    this.statEnhancers,
    this.easterEggs,
  });

  factory PersonalStatsItemsPopular$Items$Used.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsItemsPopular$Items$UsedFromJson(json);

  static const toJsonFactory = _$PersonalStatsItemsPopular$Items$UsedToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsItemsPopular$Items$UsedToJson(this);

  @JsonKey(name: 'books')
  final int? books;
  @JsonKey(name: 'boosters')
  final int? boosters;
  @JsonKey(name: 'consumables')
  final int? consumables;
  @JsonKey(name: 'candy')
  final int? candy;
  @JsonKey(name: 'alcohol')
  final int? alcohol;
  @JsonKey(name: 'energy_drinks')
  final int? energyDrinks;
  @JsonKey(name: 'stat_enhancers')
  final int? statEnhancers;
  @JsonKey(name: 'easter_eggs')
  final int? easterEggs;
  static const fromJsonFactory = _$PersonalStatsItemsPopular$Items$UsedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsItemsPopular$Items$Used &&
            (identical(other.books, books) || const DeepCollectionEquality().equals(other.books, books)) &&
            (identical(other.boosters, boosters) || const DeepCollectionEquality().equals(other.boosters, boosters)) &&
            (identical(other.consumables, consumables) ||
                const DeepCollectionEquality().equals(other.consumables, consumables)) &&
            (identical(other.candy, candy) || const DeepCollectionEquality().equals(other.candy, candy)) &&
            (identical(other.alcohol, alcohol) || const DeepCollectionEquality().equals(other.alcohol, alcohol)) &&
            (identical(other.energyDrinks, energyDrinks) ||
                const DeepCollectionEquality().equals(other.energyDrinks, energyDrinks)) &&
            (identical(other.statEnhancers, statEnhancers) ||
                const DeepCollectionEquality().equals(other.statEnhancers, statEnhancers)) &&
            (identical(other.easterEggs, easterEggs) ||
                const DeepCollectionEquality().equals(other.easterEggs, easterEggs)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(books) ^
      const DeepCollectionEquality().hash(boosters) ^
      const DeepCollectionEquality().hash(consumables) ^
      const DeepCollectionEquality().hash(candy) ^
      const DeepCollectionEquality().hash(alcohol) ^
      const DeepCollectionEquality().hash(energyDrinks) ^
      const DeepCollectionEquality().hash(statEnhancers) ^
      const DeepCollectionEquality().hash(easterEggs) ^
      runtimeType.hashCode;
}

extension $PersonalStatsItemsPopular$Items$UsedExtension on PersonalStatsItemsPopular$Items$Used {
  PersonalStatsItemsPopular$Items$Used copyWith(
      {int? books,
      int? boosters,
      int? consumables,
      int? candy,
      int? alcohol,
      int? energyDrinks,
      int? statEnhancers,
      int? easterEggs}) {
    return PersonalStatsItemsPopular$Items$Used(
        books: books ?? this.books,
        boosters: boosters ?? this.boosters,
        consumables: consumables ?? this.consumables,
        candy: candy ?? this.candy,
        alcohol: alcohol ?? this.alcohol,
        energyDrinks: energyDrinks ?? this.energyDrinks,
        statEnhancers: statEnhancers ?? this.statEnhancers,
        easterEggs: easterEggs ?? this.easterEggs);
  }

  PersonalStatsItemsPopular$Items$Used copyWithWrapped(
      {Wrapped<int?>? books,
      Wrapped<int?>? boosters,
      Wrapped<int?>? consumables,
      Wrapped<int?>? candy,
      Wrapped<int?>? alcohol,
      Wrapped<int?>? energyDrinks,
      Wrapped<int?>? statEnhancers,
      Wrapped<int?>? easterEggs}) {
    return PersonalStatsItemsPopular$Items$Used(
        books: (books != null ? books.value : this.books),
        boosters: (boosters != null ? boosters.value : this.boosters),
        consumables: (consumables != null ? consumables.value : this.consumables),
        candy: (candy != null ? candy.value : this.candy),
        alcohol: (alcohol != null ? alcohol.value : this.alcohol),
        energyDrinks: (energyDrinks != null ? energyDrinks.value : this.energyDrinks),
        statEnhancers: (statEnhancers != null ? statEnhancers.value : this.statEnhancers),
        easterEggs: (easterEggs != null ? easterEggs.value : this.easterEggs));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsInvestments$Investments$Bank {
  const PersonalStatsInvestments$Investments$Bank({
    this.total,
    this.profit,
    this.current,
    this.timeRemaining,
  });

  factory PersonalStatsInvestments$Investments$Bank.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsInvestments$Investments$BankFromJson(json);

  static const toJsonFactory = _$PersonalStatsInvestments$Investments$BankToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsInvestments$Investments$BankToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'profit')
  final int? profit;
  @JsonKey(name: 'current')
  final int? current;
  @JsonKey(name: 'time_remaining')
  final int? timeRemaining;
  static const fromJsonFactory = _$PersonalStatsInvestments$Investments$BankFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsInvestments$Investments$Bank &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.profit, profit) || const DeepCollectionEquality().equals(other.profit, profit)) &&
            (identical(other.current, current) || const DeepCollectionEquality().equals(other.current, current)) &&
            (identical(other.timeRemaining, timeRemaining) ||
                const DeepCollectionEquality().equals(other.timeRemaining, timeRemaining)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(profit) ^
      const DeepCollectionEquality().hash(current) ^
      const DeepCollectionEquality().hash(timeRemaining) ^
      runtimeType.hashCode;
}

extension $PersonalStatsInvestments$Investments$BankExtension on PersonalStatsInvestments$Investments$Bank {
  PersonalStatsInvestments$Investments$Bank copyWith({int? total, int? profit, int? current, int? timeRemaining}) {
    return PersonalStatsInvestments$Investments$Bank(
        total: total ?? this.total,
        profit: profit ?? this.profit,
        current: current ?? this.current,
        timeRemaining: timeRemaining ?? this.timeRemaining);
  }

  PersonalStatsInvestments$Investments$Bank copyWithWrapped(
      {Wrapped<int?>? total, Wrapped<int?>? profit, Wrapped<int?>? current, Wrapped<int?>? timeRemaining}) {
    return PersonalStatsInvestments$Investments$Bank(
        total: (total != null ? total.value : this.total),
        profit: (profit != null ? profit.value : this.profit),
        current: (current != null ? current.value : this.current),
        timeRemaining: (timeRemaining != null ? timeRemaining.value : this.timeRemaining));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsInvestments$Investments$Stocks {
  const PersonalStatsInvestments$Investments$Stocks({
    this.profits,
    this.losses,
    this.fees,
    this.netProfits,
    this.payouts,
  });

  factory PersonalStatsInvestments$Investments$Stocks.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsInvestments$Investments$StocksFromJson(json);

  static const toJsonFactory = _$PersonalStatsInvestments$Investments$StocksToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsInvestments$Investments$StocksToJson(this);

  @JsonKey(name: 'profits')
  final int? profits;
  @JsonKey(name: 'losses')
  final int? losses;
  @JsonKey(name: 'fees')
  final int? fees;
  @JsonKey(name: 'net_profits')
  final int? netProfits;
  @JsonKey(name: 'payouts')
  final int? payouts;
  static const fromJsonFactory = _$PersonalStatsInvestments$Investments$StocksFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsInvestments$Investments$Stocks &&
            (identical(other.profits, profits) || const DeepCollectionEquality().equals(other.profits, profits)) &&
            (identical(other.losses, losses) || const DeepCollectionEquality().equals(other.losses, losses)) &&
            (identical(other.fees, fees) || const DeepCollectionEquality().equals(other.fees, fees)) &&
            (identical(other.netProfits, netProfits) ||
                const DeepCollectionEquality().equals(other.netProfits, netProfits)) &&
            (identical(other.payouts, payouts) || const DeepCollectionEquality().equals(other.payouts, payouts)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(profits) ^
      const DeepCollectionEquality().hash(losses) ^
      const DeepCollectionEquality().hash(fees) ^
      const DeepCollectionEquality().hash(netProfits) ^
      const DeepCollectionEquality().hash(payouts) ^
      runtimeType.hashCode;
}

extension $PersonalStatsInvestments$Investments$StocksExtension on PersonalStatsInvestments$Investments$Stocks {
  PersonalStatsInvestments$Investments$Stocks copyWith(
      {int? profits, int? losses, int? fees, int? netProfits, int? payouts}) {
    return PersonalStatsInvestments$Investments$Stocks(
        profits: profits ?? this.profits,
        losses: losses ?? this.losses,
        fees: fees ?? this.fees,
        netProfits: netProfits ?? this.netProfits,
        payouts: payouts ?? this.payouts);
  }

  PersonalStatsInvestments$Investments$Stocks copyWithWrapped(
      {Wrapped<int?>? profits,
      Wrapped<int?>? losses,
      Wrapped<int?>? fees,
      Wrapped<int?>? netProfits,
      Wrapped<int?>? payouts}) {
    return PersonalStatsInvestments$Investments$Stocks(
        profits: (profits != null ? profits.value : this.profits),
        losses: (losses != null ? losses.value : this.losses),
        fees: (fees != null ? fees.value : this.fees),
        netProfits: (netProfits != null ? netProfits.value : this.netProfits),
        payouts: (payouts != null ? payouts.value : this.payouts));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsBounties$Bounties$Placed {
  const PersonalStatsBounties$Bounties$Placed({
    this.amount,
    this.$value,
  });

  factory PersonalStatsBounties$Bounties$Placed.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsBounties$Bounties$PlacedFromJson(json);

  static const toJsonFactory = _$PersonalStatsBounties$Bounties$PlacedToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsBounties$Bounties$PlacedToJson(this);

  @JsonKey(name: 'amount')
  final int? amount;
  @JsonKey(name: 'value')
  final int? $value;
  static const fromJsonFactory = _$PersonalStatsBounties$Bounties$PlacedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsBounties$Bounties$Placed &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.$value, $value) || const DeepCollectionEquality().equals(other.$value, $value)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(amount) ^ const DeepCollectionEquality().hash($value) ^ runtimeType.hashCode;
}

extension $PersonalStatsBounties$Bounties$PlacedExtension on PersonalStatsBounties$Bounties$Placed {
  PersonalStatsBounties$Bounties$Placed copyWith({int? amount, int? $value}) {
    return PersonalStatsBounties$Bounties$Placed(amount: amount ?? this.amount, $value: $value ?? this.$value);
  }

  PersonalStatsBounties$Bounties$Placed copyWithWrapped({Wrapped<int?>? amount, Wrapped<int?>? $value}) {
    return PersonalStatsBounties$Bounties$Placed(
        amount: (amount != null ? amount.value : this.amount), $value: ($value != null ? $value.value : this.$value));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsBounties$Bounties$Collected {
  const PersonalStatsBounties$Bounties$Collected({
    this.amount,
    this.$value,
  });

  factory PersonalStatsBounties$Bounties$Collected.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsBounties$Bounties$CollectedFromJson(json);

  static const toJsonFactory = _$PersonalStatsBounties$Bounties$CollectedToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsBounties$Bounties$CollectedToJson(this);

  @JsonKey(name: 'amount')
  final int? amount;
  @JsonKey(name: 'value')
  final int? $value;
  static const fromJsonFactory = _$PersonalStatsBounties$Bounties$CollectedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsBounties$Bounties$Collected &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.$value, $value) || const DeepCollectionEquality().equals(other.$value, $value)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(amount) ^ const DeepCollectionEquality().hash($value) ^ runtimeType.hashCode;
}

extension $PersonalStatsBounties$Bounties$CollectedExtension on PersonalStatsBounties$Bounties$Collected {
  PersonalStatsBounties$Bounties$Collected copyWith({int? amount, int? $value}) {
    return PersonalStatsBounties$Bounties$Collected(amount: amount ?? this.amount, $value: $value ?? this.$value);
  }

  PersonalStatsBounties$Bounties$Collected copyWithWrapped({Wrapped<int?>? amount, Wrapped<int?>? $value}) {
    return PersonalStatsBounties$Bounties$Collected(
        amount: (amount != null ? amount.value : this.amount), $value: ($value != null ? $value.value : this.$value));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsBounties$Bounties$Received {
  const PersonalStatsBounties$Bounties$Received({
    this.amount,
    this.$value,
  });

  factory PersonalStatsBounties$Bounties$Received.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsBounties$Bounties$ReceivedFromJson(json);

  static const toJsonFactory = _$PersonalStatsBounties$Bounties$ReceivedToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsBounties$Bounties$ReceivedToJson(this);

  @JsonKey(name: 'amount')
  final int? amount;
  @JsonKey(name: 'value')
  final int? $value;
  static const fromJsonFactory = _$PersonalStatsBounties$Bounties$ReceivedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsBounties$Bounties$Received &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.$value, $value) || const DeepCollectionEquality().equals(other.$value, $value)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(amount) ^ const DeepCollectionEquality().hash($value) ^ runtimeType.hashCode;
}

extension $PersonalStatsBounties$Bounties$ReceivedExtension on PersonalStatsBounties$Bounties$Received {
  PersonalStatsBounties$Bounties$Received copyWith({int? amount, int? $value}) {
    return PersonalStatsBounties$Bounties$Received(amount: amount ?? this.amount, $value: $value ?? this.$value);
  }

  PersonalStatsBounties$Bounties$Received copyWithWrapped({Wrapped<int?>? amount, Wrapped<int?>? $value}) {
    return PersonalStatsBounties$Bounties$Received(
        amount: (amount != null ? amount.value : this.amount), $value: ($value != null ? $value.value : this.$value));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsCommunication$Communication$MailsSent {
  const PersonalStatsCommunication$Communication$MailsSent({
    this.total,
    this.friends,
    this.faction,
    this.colleagues,
    this.spouse,
  });

  factory PersonalStatsCommunication$Communication$MailsSent.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsCommunication$Communication$MailsSentFromJson(json);

  static const toJsonFactory = _$PersonalStatsCommunication$Communication$MailsSentToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsCommunication$Communication$MailsSentToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'friends')
  final int? friends;
  @JsonKey(name: 'faction')
  final int? faction;
  @JsonKey(name: 'colleagues')
  final int? colleagues;
  @JsonKey(name: 'spouse')
  final int? spouse;
  static const fromJsonFactory = _$PersonalStatsCommunication$Communication$MailsSentFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsCommunication$Communication$MailsSent &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.friends, friends) || const DeepCollectionEquality().equals(other.friends, friends)) &&
            (identical(other.faction, faction) || const DeepCollectionEquality().equals(other.faction, faction)) &&
            (identical(other.colleagues, colleagues) ||
                const DeepCollectionEquality().equals(other.colleagues, colleagues)) &&
            (identical(other.spouse, spouse) || const DeepCollectionEquality().equals(other.spouse, spouse)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(friends) ^
      const DeepCollectionEquality().hash(faction) ^
      const DeepCollectionEquality().hash(colleagues) ^
      const DeepCollectionEquality().hash(spouse) ^
      runtimeType.hashCode;
}

extension $PersonalStatsCommunication$Communication$MailsSentExtension
    on PersonalStatsCommunication$Communication$MailsSent {
  PersonalStatsCommunication$Communication$MailsSent copyWith(
      {int? total, int? friends, int? faction, int? colleagues, int? spouse}) {
    return PersonalStatsCommunication$Communication$MailsSent(
        total: total ?? this.total,
        friends: friends ?? this.friends,
        faction: faction ?? this.faction,
        colleagues: colleagues ?? this.colleagues,
        spouse: spouse ?? this.spouse);
  }

  PersonalStatsCommunication$Communication$MailsSent copyWithWrapped(
      {Wrapped<int?>? total,
      Wrapped<int?>? friends,
      Wrapped<int?>? faction,
      Wrapped<int?>? colleagues,
      Wrapped<int?>? spouse}) {
    return PersonalStatsCommunication$Communication$MailsSent(
        total: (total != null ? total.value : this.total),
        friends: (friends != null ? friends.value : this.friends),
        faction: (faction != null ? faction.value : this.faction),
        colleagues: (colleagues != null ? colleagues.value : this.colleagues),
        spouse: (spouse != null ? spouse.value : this.spouse));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsHospital$Hospital$Reviving {
  const PersonalStatsHospital$Hospital$Reviving({
    this.skill,
    this.revives,
    this.revivesReceived,
  });

  factory PersonalStatsHospital$Hospital$Reviving.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsHospital$Hospital$RevivingFromJson(json);

  static const toJsonFactory = _$PersonalStatsHospital$Hospital$RevivingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsHospital$Hospital$RevivingToJson(this);

  @JsonKey(name: 'skill')
  final int? skill;
  @JsonKey(name: 'revives')
  final int? revives;
  @JsonKey(name: 'revives_received')
  final int? revivesReceived;
  static const fromJsonFactory = _$PersonalStatsHospital$Hospital$RevivingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsHospital$Hospital$Reviving &&
            (identical(other.skill, skill) || const DeepCollectionEquality().equals(other.skill, skill)) &&
            (identical(other.revives, revives) || const DeepCollectionEquality().equals(other.revives, revives)) &&
            (identical(other.revivesReceived, revivesReceived) ||
                const DeepCollectionEquality().equals(other.revivesReceived, revivesReceived)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(skill) ^
      const DeepCollectionEquality().hash(revives) ^
      const DeepCollectionEquality().hash(revivesReceived) ^
      runtimeType.hashCode;
}

extension $PersonalStatsHospital$Hospital$RevivingExtension on PersonalStatsHospital$Hospital$Reviving {
  PersonalStatsHospital$Hospital$Reviving copyWith({int? skill, int? revives, int? revivesReceived}) {
    return PersonalStatsHospital$Hospital$Reviving(
        skill: skill ?? this.skill,
        revives: revives ?? this.revives,
        revivesReceived: revivesReceived ?? this.revivesReceived);
  }

  PersonalStatsHospital$Hospital$Reviving copyWithWrapped(
      {Wrapped<int?>? skill, Wrapped<int?>? revives, Wrapped<int?>? revivesReceived}) {
    return PersonalStatsHospital$Hospital$Reviving(
        skill: (skill != null ? skill.value : this.skill),
        revives: (revives != null ? revives.value : this.revives),
        revivesReceived: (revivesReceived != null ? revivesReceived.value : this.revivesReceived));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsHospitalPopular$Hospital$Reviving {
  const PersonalStatsHospitalPopular$Hospital$Reviving({
    this.skill,
    this.revives,
  });

  factory PersonalStatsHospitalPopular$Hospital$Reviving.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsHospitalPopular$Hospital$RevivingFromJson(json);

  static const toJsonFactory = _$PersonalStatsHospitalPopular$Hospital$RevivingToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsHospitalPopular$Hospital$RevivingToJson(this);

  @JsonKey(name: 'skill')
  final int? skill;
  @JsonKey(name: 'revives')
  final int? revives;
  static const fromJsonFactory = _$PersonalStatsHospitalPopular$Hospital$RevivingFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsHospitalPopular$Hospital$Reviving &&
            (identical(other.skill, skill) || const DeepCollectionEquality().equals(other.skill, skill)) &&
            (identical(other.revives, revives) || const DeepCollectionEquality().equals(other.revives, revives)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(skill) ^ const DeepCollectionEquality().hash(revives) ^ runtimeType.hashCode;
}

extension $PersonalStatsHospitalPopular$Hospital$RevivingExtension on PersonalStatsHospitalPopular$Hospital$Reviving {
  PersonalStatsHospitalPopular$Hospital$Reviving copyWith({int? skill, int? revives}) {
    return PersonalStatsHospitalPopular$Hospital$Reviving(skill: skill ?? this.skill, revives: revives ?? this.revives);
  }

  PersonalStatsHospitalPopular$Hospital$Reviving copyWithWrapped({Wrapped<int?>? skill, Wrapped<int?>? revives}) {
    return PersonalStatsHospitalPopular$Hospital$Reviving(
        skill: (skill != null ? skill.value : this.skill), revives: (revives != null ? revives.value : this.revives));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsJail$Jail$Busts {
  const PersonalStatsJail$Jail$Busts({
    this.success,
    this.fails,
  });

  factory PersonalStatsJail$Jail$Busts.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsJail$Jail$BustsFromJson(json);

  static const toJsonFactory = _$PersonalStatsJail$Jail$BustsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsJail$Jail$BustsToJson(this);

  @JsonKey(name: 'success')
  final int? success;
  @JsonKey(name: 'fails')
  final int? fails;
  static const fromJsonFactory = _$PersonalStatsJail$Jail$BustsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsJail$Jail$Busts &&
            (identical(other.success, success) || const DeepCollectionEquality().equals(other.success, success)) &&
            (identical(other.fails, fails) || const DeepCollectionEquality().equals(other.fails, fails)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(success) ^ const DeepCollectionEquality().hash(fails) ^ runtimeType.hashCode;
}

extension $PersonalStatsJail$Jail$BustsExtension on PersonalStatsJail$Jail$Busts {
  PersonalStatsJail$Jail$Busts copyWith({int? success, int? fails}) {
    return PersonalStatsJail$Jail$Busts(success: success ?? this.success, fails: fails ?? this.fails);
  }

  PersonalStatsJail$Jail$Busts copyWithWrapped({Wrapped<int?>? success, Wrapped<int?>? fails}) {
    return PersonalStatsJail$Jail$Busts(
        success: (success != null ? success.value : this.success), fails: (fails != null ? fails.value : this.fails));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsJail$Jail$Bails {
  const PersonalStatsJail$Jail$Bails({
    this.amount,
    this.fees,
  });

  factory PersonalStatsJail$Jail$Bails.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsJail$Jail$BailsFromJson(json);

  static const toJsonFactory = _$PersonalStatsJail$Jail$BailsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsJail$Jail$BailsToJson(this);

  @JsonKey(name: 'amount')
  final int? amount;
  @JsonKey(name: 'fees')
  final int? fees;
  static const fromJsonFactory = _$PersonalStatsJail$Jail$BailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsJail$Jail$Bails &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.fees, fees) || const DeepCollectionEquality().equals(other.fees, fees)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(amount) ^ const DeepCollectionEquality().hash(fees) ^ runtimeType.hashCode;
}

extension $PersonalStatsJail$Jail$BailsExtension on PersonalStatsJail$Jail$Bails {
  PersonalStatsJail$Jail$Bails copyWith({int? amount, int? fees}) {
    return PersonalStatsJail$Jail$Bails(amount: amount ?? this.amount, fees: fees ?? this.fees);
  }

  PersonalStatsJail$Jail$Bails copyWithWrapped({Wrapped<int?>? amount, Wrapped<int?>? fees}) {
    return PersonalStatsJail$Jail$Bails(
        amount: (amount != null ? amount.value : this.amount), fees: (fees != null ? fees.value : this.fees));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTrading$Trading$Items {
  const PersonalStatsTrading$Trading$Items({
    this.bought,
    this.auctions,
    this.sent,
  });

  factory PersonalStatsTrading$Trading$Items.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsTrading$Trading$ItemsFromJson(json);

  static const toJsonFactory = _$PersonalStatsTrading$Trading$ItemsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTrading$Trading$ItemsToJson(this);

  @JsonKey(name: 'bought')
  final PersonalStatsTrading$Trading$Items$Bought? bought;
  @JsonKey(name: 'auctions')
  final PersonalStatsTrading$Trading$Items$Auctions? auctions;
  @JsonKey(name: 'sent')
  final int? sent;
  static const fromJsonFactory = _$PersonalStatsTrading$Trading$ItemsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTrading$Trading$Items &&
            (identical(other.bought, bought) || const DeepCollectionEquality().equals(other.bought, bought)) &&
            (identical(other.auctions, auctions) || const DeepCollectionEquality().equals(other.auctions, auctions)) &&
            (identical(other.sent, sent) || const DeepCollectionEquality().equals(other.sent, sent)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bought) ^
      const DeepCollectionEquality().hash(auctions) ^
      const DeepCollectionEquality().hash(sent) ^
      runtimeType.hashCode;
}

extension $PersonalStatsTrading$Trading$ItemsExtension on PersonalStatsTrading$Trading$Items {
  PersonalStatsTrading$Trading$Items copyWith(
      {PersonalStatsTrading$Trading$Items$Bought? bought,
      PersonalStatsTrading$Trading$Items$Auctions? auctions,
      int? sent}) {
    return PersonalStatsTrading$Trading$Items(
        bought: bought ?? this.bought, auctions: auctions ?? this.auctions, sent: sent ?? this.sent);
  }

  PersonalStatsTrading$Trading$Items copyWithWrapped(
      {Wrapped<PersonalStatsTrading$Trading$Items$Bought?>? bought,
      Wrapped<PersonalStatsTrading$Trading$Items$Auctions?>? auctions,
      Wrapped<int?>? sent}) {
    return PersonalStatsTrading$Trading$Items(
        bought: (bought != null ? bought.value : this.bought),
        auctions: (auctions != null ? auctions.value : this.auctions),
        sent: (sent != null ? sent.value : this.sent));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTrading$Trading$Points {
  const PersonalStatsTrading$Trading$Points({
    this.bought,
    this.sold,
  });

  factory PersonalStatsTrading$Trading$Points.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsTrading$Trading$PointsFromJson(json);

  static const toJsonFactory = _$PersonalStatsTrading$Trading$PointsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTrading$Trading$PointsToJson(this);

  @JsonKey(name: 'bought')
  final int? bought;
  @JsonKey(name: 'sold')
  final int? sold;
  static const fromJsonFactory = _$PersonalStatsTrading$Trading$PointsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTrading$Trading$Points &&
            (identical(other.bought, bought) || const DeepCollectionEquality().equals(other.bought, bought)) &&
            (identical(other.sold, sold) || const DeepCollectionEquality().equals(other.sold, sold)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bought) ^ const DeepCollectionEquality().hash(sold) ^ runtimeType.hashCode;
}

extension $PersonalStatsTrading$Trading$PointsExtension on PersonalStatsTrading$Trading$Points {
  PersonalStatsTrading$Trading$Points copyWith({int? bought, int? sold}) {
    return PersonalStatsTrading$Trading$Points(bought: bought ?? this.bought, sold: sold ?? this.sold);
  }

  PersonalStatsTrading$Trading$Points copyWithWrapped({Wrapped<int?>? bought, Wrapped<int?>? sold}) {
    return PersonalStatsTrading$Trading$Points(
        bought: (bought != null ? bought.value : this.bought), sold: (sold != null ? sold.value : this.sold));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTrading$Trading$Bazaar {
  const PersonalStatsTrading$Trading$Bazaar({
    this.customers,
    this.sales,
    this.profit,
  });

  factory PersonalStatsTrading$Trading$Bazaar.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsTrading$Trading$BazaarFromJson(json);

  static const toJsonFactory = _$PersonalStatsTrading$Trading$BazaarToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTrading$Trading$BazaarToJson(this);

  @JsonKey(name: 'customers')
  final int? customers;
  @JsonKey(name: 'sales')
  final int? sales;
  @JsonKey(name: 'profit')
  final int? profit;
  static const fromJsonFactory = _$PersonalStatsTrading$Trading$BazaarFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTrading$Trading$Bazaar &&
            (identical(other.customers, customers) ||
                const DeepCollectionEquality().equals(other.customers, customers)) &&
            (identical(other.sales, sales) || const DeepCollectionEquality().equals(other.sales, sales)) &&
            (identical(other.profit, profit) || const DeepCollectionEquality().equals(other.profit, profit)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(customers) ^
      const DeepCollectionEquality().hash(sales) ^
      const DeepCollectionEquality().hash(profit) ^
      runtimeType.hashCode;
}

extension $PersonalStatsTrading$Trading$BazaarExtension on PersonalStatsTrading$Trading$Bazaar {
  PersonalStatsTrading$Trading$Bazaar copyWith({int? customers, int? sales, int? profit}) {
    return PersonalStatsTrading$Trading$Bazaar(
        customers: customers ?? this.customers, sales: sales ?? this.sales, profit: profit ?? this.profit);
  }

  PersonalStatsTrading$Trading$Bazaar copyWithWrapped(
      {Wrapped<int?>? customers, Wrapped<int?>? sales, Wrapped<int?>? profit}) {
    return PersonalStatsTrading$Trading$Bazaar(
        customers: (customers != null ? customers.value : this.customers),
        sales: (sales != null ? sales.value : this.sales),
        profit: (profit != null ? profit.value : this.profit));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsJobsExtended$Jobs$Stats {
  const PersonalStatsJobsExtended$Jobs$Stats({
    this.manual,
    this.intelligence,
    this.endurance,
    this.total,
  });

  factory PersonalStatsJobsExtended$Jobs$Stats.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsJobsExtended$Jobs$StatsFromJson(json);

  static const toJsonFactory = _$PersonalStatsJobsExtended$Jobs$StatsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsJobsExtended$Jobs$StatsToJson(this);

  @JsonKey(name: 'manual')
  final int? manual;
  @JsonKey(name: 'intelligence')
  final int? intelligence;
  @JsonKey(name: 'endurance')
  final int? endurance;
  @JsonKey(name: 'total')
  final int? total;
  static const fromJsonFactory = _$PersonalStatsJobsExtended$Jobs$StatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsJobsExtended$Jobs$Stats &&
            (identical(other.manual, manual) || const DeepCollectionEquality().equals(other.manual, manual)) &&
            (identical(other.intelligence, intelligence) ||
                const DeepCollectionEquality().equals(other.intelligence, intelligence)) &&
            (identical(other.endurance, endurance) ||
                const DeepCollectionEquality().equals(other.endurance, endurance)) &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(manual) ^
      const DeepCollectionEquality().hash(intelligence) ^
      const DeepCollectionEquality().hash(endurance) ^
      const DeepCollectionEquality().hash(total) ^
      runtimeType.hashCode;
}

extension $PersonalStatsJobsExtended$Jobs$StatsExtension on PersonalStatsJobsExtended$Jobs$Stats {
  PersonalStatsJobsExtended$Jobs$Stats copyWith({int? manual, int? intelligence, int? endurance, int? total}) {
    return PersonalStatsJobsExtended$Jobs$Stats(
        manual: manual ?? this.manual,
        intelligence: intelligence ?? this.intelligence,
        endurance: endurance ?? this.endurance,
        total: total ?? this.total);
  }

  PersonalStatsJobsExtended$Jobs$Stats copyWithWrapped(
      {Wrapped<int?>? manual, Wrapped<int?>? intelligence, Wrapped<int?>? endurance, Wrapped<int?>? total}) {
    return PersonalStatsJobsExtended$Jobs$Stats(
        manual: (manual != null ? manual.value : this.manual),
        intelligence: (intelligence != null ? intelligence.value : this.intelligence),
        endurance: (endurance != null ? endurance.value : this.endurance),
        total: (total != null ? total.value : this.total));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Attacks {
  const PersonalStatsAttackingPublic$Attacking$Attacks({
    this.won,
    this.lost,
    this.stalemate,
    this.assist,
    this.stealth,
  });

  factory PersonalStatsAttackingPublic$Attacking$Attacks.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$AttacksFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$AttacksToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$AttacksToJson(this);

  @JsonKey(name: 'won')
  final int? won;
  @JsonKey(name: 'lost')
  final int? lost;
  @JsonKey(name: 'stalemate')
  final int? stalemate;
  @JsonKey(name: 'assist')
  final int? assist;
  @JsonKey(name: 'stealth')
  final int? stealth;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$AttacksFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Attacks &&
            (identical(other.won, won) || const DeepCollectionEquality().equals(other.won, won)) &&
            (identical(other.lost, lost) || const DeepCollectionEquality().equals(other.lost, lost)) &&
            (identical(other.stalemate, stalemate) ||
                const DeepCollectionEquality().equals(other.stalemate, stalemate)) &&
            (identical(other.assist, assist) || const DeepCollectionEquality().equals(other.assist, assist)) &&
            (identical(other.stealth, stealth) || const DeepCollectionEquality().equals(other.stealth, stealth)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(won) ^
      const DeepCollectionEquality().hash(lost) ^
      const DeepCollectionEquality().hash(stalemate) ^
      const DeepCollectionEquality().hash(assist) ^
      const DeepCollectionEquality().hash(stealth) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$AttacksExtension on PersonalStatsAttackingPublic$Attacking$Attacks {
  PersonalStatsAttackingPublic$Attacking$Attacks copyWith(
      {int? won, int? lost, int? stalemate, int? assist, int? stealth}) {
    return PersonalStatsAttackingPublic$Attacking$Attacks(
        won: won ?? this.won,
        lost: lost ?? this.lost,
        stalemate: stalemate ?? this.stalemate,
        assist: assist ?? this.assist,
        stealth: stealth ?? this.stealth);
  }

  PersonalStatsAttackingPublic$Attacking$Attacks copyWithWrapped(
      {Wrapped<int?>? won,
      Wrapped<int?>? lost,
      Wrapped<int?>? stalemate,
      Wrapped<int?>? assist,
      Wrapped<int?>? stealth}) {
    return PersonalStatsAttackingPublic$Attacking$Attacks(
        won: (won != null ? won.value : this.won),
        lost: (lost != null ? lost.value : this.lost),
        stalemate: (stalemate != null ? stalemate.value : this.stalemate),
        assist: (assist != null ? assist.value : this.assist),
        stealth: (stealth != null ? stealth.value : this.stealth));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Defends {
  const PersonalStatsAttackingPublic$Attacking$Defends({
    this.won,
    this.lost,
    this.stalemate,
    this.total,
  });

  factory PersonalStatsAttackingPublic$Attacking$Defends.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$DefendsFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$DefendsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$DefendsToJson(this);

  @JsonKey(name: 'won')
  final int? won;
  @JsonKey(name: 'lost')
  final int? lost;
  @JsonKey(name: 'stalemate')
  final int? stalemate;
  @JsonKey(name: 'total')
  final int? total;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$DefendsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Defends &&
            (identical(other.won, won) || const DeepCollectionEquality().equals(other.won, won)) &&
            (identical(other.lost, lost) || const DeepCollectionEquality().equals(other.lost, lost)) &&
            (identical(other.stalemate, stalemate) ||
                const DeepCollectionEquality().equals(other.stalemate, stalemate)) &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(won) ^
      const DeepCollectionEquality().hash(lost) ^
      const DeepCollectionEquality().hash(stalemate) ^
      const DeepCollectionEquality().hash(total) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$DefendsExtension on PersonalStatsAttackingPublic$Attacking$Defends {
  PersonalStatsAttackingPublic$Attacking$Defends copyWith({int? won, int? lost, int? stalemate, int? total}) {
    return PersonalStatsAttackingPublic$Attacking$Defends(
        won: won ?? this.won,
        lost: lost ?? this.lost,
        stalemate: stalemate ?? this.stalemate,
        total: total ?? this.total);
  }

  PersonalStatsAttackingPublic$Attacking$Defends copyWithWrapped(
      {Wrapped<int?>? won, Wrapped<int?>? lost, Wrapped<int?>? stalemate, Wrapped<int?>? total}) {
    return PersonalStatsAttackingPublic$Attacking$Defends(
        won: (won != null ? won.value : this.won),
        lost: (lost != null ? lost.value : this.lost),
        stalemate: (stalemate != null ? stalemate.value : this.stalemate),
        total: (total != null ? total.value : this.total));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Escapes {
  const PersonalStatsAttackingPublic$Attacking$Escapes({
    this.player,
    this.foes,
  });

  factory PersonalStatsAttackingPublic$Attacking$Escapes.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$EscapesFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$EscapesToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$EscapesToJson(this);

  @JsonKey(name: 'player')
  final int? player;
  @JsonKey(name: 'foes')
  final int? foes;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$EscapesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Escapes &&
            (identical(other.player, player) || const DeepCollectionEquality().equals(other.player, player)) &&
            (identical(other.foes, foes) || const DeepCollectionEquality().equals(other.foes, foes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(player) ^ const DeepCollectionEquality().hash(foes) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$EscapesExtension on PersonalStatsAttackingPublic$Attacking$Escapes {
  PersonalStatsAttackingPublic$Attacking$Escapes copyWith({int? player, int? foes}) {
    return PersonalStatsAttackingPublic$Attacking$Escapes(player: player ?? this.player, foes: foes ?? this.foes);
  }

  PersonalStatsAttackingPublic$Attacking$Escapes copyWithWrapped({Wrapped<int?>? player, Wrapped<int?>? foes}) {
    return PersonalStatsAttackingPublic$Attacking$Escapes(
        player: (player != null ? player.value : this.player), foes: (foes != null ? foes.value : this.foes));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Killstreak {
  const PersonalStatsAttackingPublic$Attacking$Killstreak({
    this.best,
  });

  factory PersonalStatsAttackingPublic$Attacking$Killstreak.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$KillstreakFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$KillstreakToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$KillstreakToJson(this);

  @JsonKey(name: 'best')
  final int? best;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$KillstreakFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Killstreak &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(best) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$KillstreakExtension
    on PersonalStatsAttackingPublic$Attacking$Killstreak {
  PersonalStatsAttackingPublic$Attacking$Killstreak copyWith({int? best}) {
    return PersonalStatsAttackingPublic$Attacking$Killstreak(best: best ?? this.best);
  }

  PersonalStatsAttackingPublic$Attacking$Killstreak copyWithWrapped({Wrapped<int?>? best}) {
    return PersonalStatsAttackingPublic$Attacking$Killstreak(best: (best != null ? best.value : this.best));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Hits {
  const PersonalStatsAttackingPublic$Attacking$Hits({
    this.success,
    this.miss,
    this.critical,
    this.oneHitKills,
  });

  factory PersonalStatsAttackingPublic$Attacking$Hits.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$HitsFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$HitsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$HitsToJson(this);

  @JsonKey(name: 'success')
  final int? success;
  @JsonKey(name: 'miss')
  final int? miss;
  @JsonKey(name: 'critical')
  final int? critical;
  @JsonKey(name: 'one_hit_kills')
  final int? oneHitKills;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$HitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Hits &&
            (identical(other.success, success) || const DeepCollectionEquality().equals(other.success, success)) &&
            (identical(other.miss, miss) || const DeepCollectionEquality().equals(other.miss, miss)) &&
            (identical(other.critical, critical) || const DeepCollectionEquality().equals(other.critical, critical)) &&
            (identical(other.oneHitKills, oneHitKills) ||
                const DeepCollectionEquality().equals(other.oneHitKills, oneHitKills)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(success) ^
      const DeepCollectionEquality().hash(miss) ^
      const DeepCollectionEquality().hash(critical) ^
      const DeepCollectionEquality().hash(oneHitKills) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$HitsExtension on PersonalStatsAttackingPublic$Attacking$Hits {
  PersonalStatsAttackingPublic$Attacking$Hits copyWith({int? success, int? miss, int? critical, int? oneHitKills}) {
    return PersonalStatsAttackingPublic$Attacking$Hits(
        success: success ?? this.success,
        miss: miss ?? this.miss,
        critical: critical ?? this.critical,
        oneHitKills: oneHitKills ?? this.oneHitKills);
  }

  PersonalStatsAttackingPublic$Attacking$Hits copyWithWrapped(
      {Wrapped<int?>? success, Wrapped<int?>? miss, Wrapped<int?>? critical, Wrapped<int?>? oneHitKills}) {
    return PersonalStatsAttackingPublic$Attacking$Hits(
        success: (success != null ? success.value : this.success),
        miss: (miss != null ? miss.value : this.miss),
        critical: (critical != null ? critical.value : this.critical),
        oneHitKills: (oneHitKills != null ? oneHitKills.value : this.oneHitKills));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Damage {
  const PersonalStatsAttackingPublic$Attacking$Damage({
    this.total,
    this.best,
  });

  factory PersonalStatsAttackingPublic$Attacking$Damage.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$DamageFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$DamageToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$DamageToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'best')
  final int? best;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$DamageFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Damage &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^ const DeepCollectionEquality().hash(best) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$DamageExtension on PersonalStatsAttackingPublic$Attacking$Damage {
  PersonalStatsAttackingPublic$Attacking$Damage copyWith({int? total, int? best}) {
    return PersonalStatsAttackingPublic$Attacking$Damage(total: total ?? this.total, best: best ?? this.best);
  }

  PersonalStatsAttackingPublic$Attacking$Damage copyWithWrapped({Wrapped<int?>? total, Wrapped<int?>? best}) {
    return PersonalStatsAttackingPublic$Attacking$Damage(
        total: (total != null ? total.value : this.total), best: (best != null ? best.value : this.best));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Networth {
  const PersonalStatsAttackingPublic$Attacking$Networth({
    this.moneyMugged,
    this.largestMug,
    this.itemsLooted,
  });

  factory PersonalStatsAttackingPublic$Attacking$Networth.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$NetworthFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$NetworthToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$NetworthToJson(this);

  @JsonKey(name: 'money_mugged')
  final int? moneyMugged;
  @JsonKey(name: 'largest_mug')
  final int? largestMug;
  @JsonKey(name: 'items_looted')
  final int? itemsLooted;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$NetworthFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Networth &&
            (identical(other.moneyMugged, moneyMugged) ||
                const DeepCollectionEquality().equals(other.moneyMugged, moneyMugged)) &&
            (identical(other.largestMug, largestMug) ||
                const DeepCollectionEquality().equals(other.largestMug, largestMug)) &&
            (identical(other.itemsLooted, itemsLooted) ||
                const DeepCollectionEquality().equals(other.itemsLooted, itemsLooted)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(moneyMugged) ^
      const DeepCollectionEquality().hash(largestMug) ^
      const DeepCollectionEquality().hash(itemsLooted) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$NetworthExtension on PersonalStatsAttackingPublic$Attacking$Networth {
  PersonalStatsAttackingPublic$Attacking$Networth copyWith({int? moneyMugged, int? largestMug, int? itemsLooted}) {
    return PersonalStatsAttackingPublic$Attacking$Networth(
        moneyMugged: moneyMugged ?? this.moneyMugged,
        largestMug: largestMug ?? this.largestMug,
        itemsLooted: itemsLooted ?? this.itemsLooted);
  }

  PersonalStatsAttackingPublic$Attacking$Networth copyWithWrapped(
      {Wrapped<int?>? moneyMugged, Wrapped<int?>? largestMug, Wrapped<int?>? itemsLooted}) {
    return PersonalStatsAttackingPublic$Attacking$Networth(
        moneyMugged: (moneyMugged != null ? moneyMugged.value : this.moneyMugged),
        largestMug: (largestMug != null ? largestMug.value : this.largestMug),
        itemsLooted: (itemsLooted != null ? itemsLooted.value : this.itemsLooted));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Ammunition {
  const PersonalStatsAttackingPublic$Attacking$Ammunition({
    this.total,
    this.special,
    this.hollowPoint,
    this.tracer,
    this.piercing,
    this.incendiary,
  });

  factory PersonalStatsAttackingPublic$Attacking$Ammunition.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$AmmunitionFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$AmmunitionToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$AmmunitionToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'special')
  final int? special;
  @JsonKey(name: 'hollow_point')
  final int? hollowPoint;
  @JsonKey(name: 'tracer')
  final int? tracer;
  @JsonKey(name: 'piercing')
  final int? piercing;
  @JsonKey(name: 'incendiary')
  final int? incendiary;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$AmmunitionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Ammunition &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.special, special) || const DeepCollectionEquality().equals(other.special, special)) &&
            (identical(other.hollowPoint, hollowPoint) ||
                const DeepCollectionEquality().equals(other.hollowPoint, hollowPoint)) &&
            (identical(other.tracer, tracer) || const DeepCollectionEquality().equals(other.tracer, tracer)) &&
            (identical(other.piercing, piercing) || const DeepCollectionEquality().equals(other.piercing, piercing)) &&
            (identical(other.incendiary, incendiary) ||
                const DeepCollectionEquality().equals(other.incendiary, incendiary)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(special) ^
      const DeepCollectionEquality().hash(hollowPoint) ^
      const DeepCollectionEquality().hash(tracer) ^
      const DeepCollectionEquality().hash(piercing) ^
      const DeepCollectionEquality().hash(incendiary) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$AmmunitionExtension
    on PersonalStatsAttackingPublic$Attacking$Ammunition {
  PersonalStatsAttackingPublic$Attacking$Ammunition copyWith(
      {int? total, int? special, int? hollowPoint, int? tracer, int? piercing, int? incendiary}) {
    return PersonalStatsAttackingPublic$Attacking$Ammunition(
        total: total ?? this.total,
        special: special ?? this.special,
        hollowPoint: hollowPoint ?? this.hollowPoint,
        tracer: tracer ?? this.tracer,
        piercing: piercing ?? this.piercing,
        incendiary: incendiary ?? this.incendiary);
  }

  PersonalStatsAttackingPublic$Attacking$Ammunition copyWithWrapped(
      {Wrapped<int?>? total,
      Wrapped<int?>? special,
      Wrapped<int?>? hollowPoint,
      Wrapped<int?>? tracer,
      Wrapped<int?>? piercing,
      Wrapped<int?>? incendiary}) {
    return PersonalStatsAttackingPublic$Attacking$Ammunition(
        total: (total != null ? total.value : this.total),
        special: (special != null ? special.value : this.special),
        hollowPoint: (hollowPoint != null ? hollowPoint.value : this.hollowPoint),
        tracer: (tracer != null ? tracer.value : this.tracer),
        piercing: (piercing != null ? piercing.value : this.piercing),
        incendiary: (incendiary != null ? incendiary.value : this.incendiary));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Faction {
  const PersonalStatsAttackingPublic$Attacking$Faction({
    this.respect,
    this.retaliations,
    this.rankedWarHits,
    this.raidHits,
    this.territory,
  });

  factory PersonalStatsAttackingPublic$Attacking$Faction.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$FactionFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$FactionToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$FactionToJson(this);

  @JsonKey(name: 'respect')
  final int? respect;
  @JsonKey(name: 'retaliations')
  final int? retaliations;
  @JsonKey(name: 'ranked_war_hits')
  final int? rankedWarHits;
  @JsonKey(name: 'raid_hits')
  final int? raidHits;
  @JsonKey(name: 'territory')
  final PersonalStatsAttackingPublic$Attacking$Faction$Territory? territory;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$FactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Faction &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)) &&
            (identical(other.retaliations, retaliations) ||
                const DeepCollectionEquality().equals(other.retaliations, retaliations)) &&
            (identical(other.rankedWarHits, rankedWarHits) ||
                const DeepCollectionEquality().equals(other.rankedWarHits, rankedWarHits)) &&
            (identical(other.raidHits, raidHits) || const DeepCollectionEquality().equals(other.raidHits, raidHits)) &&
            (identical(other.territory, territory) ||
                const DeepCollectionEquality().equals(other.territory, territory)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(respect) ^
      const DeepCollectionEquality().hash(retaliations) ^
      const DeepCollectionEquality().hash(rankedWarHits) ^
      const DeepCollectionEquality().hash(raidHits) ^
      const DeepCollectionEquality().hash(territory) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$FactionExtension on PersonalStatsAttackingPublic$Attacking$Faction {
  PersonalStatsAttackingPublic$Attacking$Faction copyWith(
      {int? respect,
      int? retaliations,
      int? rankedWarHits,
      int? raidHits,
      PersonalStatsAttackingPublic$Attacking$Faction$Territory? territory}) {
    return PersonalStatsAttackingPublic$Attacking$Faction(
        respect: respect ?? this.respect,
        retaliations: retaliations ?? this.retaliations,
        rankedWarHits: rankedWarHits ?? this.rankedWarHits,
        raidHits: raidHits ?? this.raidHits,
        territory: territory ?? this.territory);
  }

  PersonalStatsAttackingPublic$Attacking$Faction copyWithWrapped(
      {Wrapped<int?>? respect,
      Wrapped<int?>? retaliations,
      Wrapped<int?>? rankedWarHits,
      Wrapped<int?>? raidHits,
      Wrapped<PersonalStatsAttackingPublic$Attacking$Faction$Territory?>? territory}) {
    return PersonalStatsAttackingPublic$Attacking$Faction(
        respect: (respect != null ? respect.value : this.respect),
        retaliations: (retaliations != null ? retaliations.value : this.retaliations),
        rankedWarHits: (rankedWarHits != null ? rankedWarHits.value : this.rankedWarHits),
        raidHits: (raidHits != null ? raidHits.value : this.raidHits),
        territory: (territory != null ? territory.value : this.territory));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Attacks {
  const PersonalStatsAttackingExtended$Attacking$Attacks({
    this.won,
    this.lost,
    this.stalemate,
    this.assist,
    this.stealth,
  });

  factory PersonalStatsAttackingExtended$Attacking$Attacks.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$AttacksFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$AttacksToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$AttacksToJson(this);

  @JsonKey(name: 'won')
  final int? won;
  @JsonKey(name: 'lost')
  final int? lost;
  @JsonKey(name: 'stalemate')
  final int? stalemate;
  @JsonKey(name: 'assist')
  final int? assist;
  @JsonKey(name: 'stealth')
  final int? stealth;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$AttacksFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Attacks &&
            (identical(other.won, won) || const DeepCollectionEquality().equals(other.won, won)) &&
            (identical(other.lost, lost) || const DeepCollectionEquality().equals(other.lost, lost)) &&
            (identical(other.stalemate, stalemate) ||
                const DeepCollectionEquality().equals(other.stalemate, stalemate)) &&
            (identical(other.assist, assist) || const DeepCollectionEquality().equals(other.assist, assist)) &&
            (identical(other.stealth, stealth) || const DeepCollectionEquality().equals(other.stealth, stealth)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(won) ^
      const DeepCollectionEquality().hash(lost) ^
      const DeepCollectionEquality().hash(stalemate) ^
      const DeepCollectionEquality().hash(assist) ^
      const DeepCollectionEquality().hash(stealth) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$AttacksExtension
    on PersonalStatsAttackingExtended$Attacking$Attacks {
  PersonalStatsAttackingExtended$Attacking$Attacks copyWith(
      {int? won, int? lost, int? stalemate, int? assist, int? stealth}) {
    return PersonalStatsAttackingExtended$Attacking$Attacks(
        won: won ?? this.won,
        lost: lost ?? this.lost,
        stalemate: stalemate ?? this.stalemate,
        assist: assist ?? this.assist,
        stealth: stealth ?? this.stealth);
  }

  PersonalStatsAttackingExtended$Attacking$Attacks copyWithWrapped(
      {Wrapped<int?>? won,
      Wrapped<int?>? lost,
      Wrapped<int?>? stalemate,
      Wrapped<int?>? assist,
      Wrapped<int?>? stealth}) {
    return PersonalStatsAttackingExtended$Attacking$Attacks(
        won: (won != null ? won.value : this.won),
        lost: (lost != null ? lost.value : this.lost),
        stalemate: (stalemate != null ? stalemate.value : this.stalemate),
        assist: (assist != null ? assist.value : this.assist),
        stealth: (stealth != null ? stealth.value : this.stealth));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Defends {
  const PersonalStatsAttackingExtended$Attacking$Defends({
    this.won,
    this.lost,
    this.stalemate,
    this.total,
  });

  factory PersonalStatsAttackingExtended$Attacking$Defends.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$DefendsFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$DefendsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$DefendsToJson(this);

  @JsonKey(name: 'won')
  final int? won;
  @JsonKey(name: 'lost')
  final int? lost;
  @JsonKey(name: 'stalemate')
  final int? stalemate;
  @JsonKey(name: 'total')
  final int? total;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$DefendsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Defends &&
            (identical(other.won, won) || const DeepCollectionEquality().equals(other.won, won)) &&
            (identical(other.lost, lost) || const DeepCollectionEquality().equals(other.lost, lost)) &&
            (identical(other.stalemate, stalemate) ||
                const DeepCollectionEquality().equals(other.stalemate, stalemate)) &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(won) ^
      const DeepCollectionEquality().hash(lost) ^
      const DeepCollectionEquality().hash(stalemate) ^
      const DeepCollectionEquality().hash(total) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$DefendsExtension
    on PersonalStatsAttackingExtended$Attacking$Defends {
  PersonalStatsAttackingExtended$Attacking$Defends copyWith({int? won, int? lost, int? stalemate, int? total}) {
    return PersonalStatsAttackingExtended$Attacking$Defends(
        won: won ?? this.won,
        lost: lost ?? this.lost,
        stalemate: stalemate ?? this.stalemate,
        total: total ?? this.total);
  }

  PersonalStatsAttackingExtended$Attacking$Defends copyWithWrapped(
      {Wrapped<int?>? won, Wrapped<int?>? lost, Wrapped<int?>? stalemate, Wrapped<int?>? total}) {
    return PersonalStatsAttackingExtended$Attacking$Defends(
        won: (won != null ? won.value : this.won),
        lost: (lost != null ? lost.value : this.lost),
        stalemate: (stalemate != null ? stalemate.value : this.stalemate),
        total: (total != null ? total.value : this.total));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Escapes {
  const PersonalStatsAttackingExtended$Attacking$Escapes({
    this.player,
    this.foes,
  });

  factory PersonalStatsAttackingExtended$Attacking$Escapes.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$EscapesFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$EscapesToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$EscapesToJson(this);

  @JsonKey(name: 'player')
  final int? player;
  @JsonKey(name: 'foes')
  final int? foes;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$EscapesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Escapes &&
            (identical(other.player, player) || const DeepCollectionEquality().equals(other.player, player)) &&
            (identical(other.foes, foes) || const DeepCollectionEquality().equals(other.foes, foes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(player) ^ const DeepCollectionEquality().hash(foes) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$EscapesExtension
    on PersonalStatsAttackingExtended$Attacking$Escapes {
  PersonalStatsAttackingExtended$Attacking$Escapes copyWith({int? player, int? foes}) {
    return PersonalStatsAttackingExtended$Attacking$Escapes(player: player ?? this.player, foes: foes ?? this.foes);
  }

  PersonalStatsAttackingExtended$Attacking$Escapes copyWithWrapped({Wrapped<int?>? player, Wrapped<int?>? foes}) {
    return PersonalStatsAttackingExtended$Attacking$Escapes(
        player: (player != null ? player.value : this.player), foes: (foes != null ? foes.value : this.foes));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Killstreak {
  const PersonalStatsAttackingExtended$Attacking$Killstreak({
    this.best,
    this.current,
  });

  factory PersonalStatsAttackingExtended$Attacking$Killstreak.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$KillstreakFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$KillstreakToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$KillstreakToJson(this);

  @JsonKey(name: 'best')
  final int? best;
  @JsonKey(name: 'current')
  final int? current;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$KillstreakFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Killstreak &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)) &&
            (identical(other.current, current) || const DeepCollectionEquality().equals(other.current, current)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(best) ^ const DeepCollectionEquality().hash(current) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$KillstreakExtension
    on PersonalStatsAttackingExtended$Attacking$Killstreak {
  PersonalStatsAttackingExtended$Attacking$Killstreak copyWith({int? best, int? current}) {
    return PersonalStatsAttackingExtended$Attacking$Killstreak(
        best: best ?? this.best, current: current ?? this.current);
  }

  PersonalStatsAttackingExtended$Attacking$Killstreak copyWithWrapped({Wrapped<int?>? best, Wrapped<int?>? current}) {
    return PersonalStatsAttackingExtended$Attacking$Killstreak(
        best: (best != null ? best.value : this.best), current: (current != null ? current.value : this.current));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Hits {
  const PersonalStatsAttackingExtended$Attacking$Hits({
    this.success,
    this.miss,
    this.critical,
    this.oneHitKills,
  });

  factory PersonalStatsAttackingExtended$Attacking$Hits.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$HitsFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$HitsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$HitsToJson(this);

  @JsonKey(name: 'success')
  final int? success;
  @JsonKey(name: 'miss')
  final int? miss;
  @JsonKey(name: 'critical')
  final int? critical;
  @JsonKey(name: 'one_hit_kills')
  final int? oneHitKills;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$HitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Hits &&
            (identical(other.success, success) || const DeepCollectionEquality().equals(other.success, success)) &&
            (identical(other.miss, miss) || const DeepCollectionEquality().equals(other.miss, miss)) &&
            (identical(other.critical, critical) || const DeepCollectionEquality().equals(other.critical, critical)) &&
            (identical(other.oneHitKills, oneHitKills) ||
                const DeepCollectionEquality().equals(other.oneHitKills, oneHitKills)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(success) ^
      const DeepCollectionEquality().hash(miss) ^
      const DeepCollectionEquality().hash(critical) ^
      const DeepCollectionEquality().hash(oneHitKills) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$HitsExtension on PersonalStatsAttackingExtended$Attacking$Hits {
  PersonalStatsAttackingExtended$Attacking$Hits copyWith({int? success, int? miss, int? critical, int? oneHitKills}) {
    return PersonalStatsAttackingExtended$Attacking$Hits(
        success: success ?? this.success,
        miss: miss ?? this.miss,
        critical: critical ?? this.critical,
        oneHitKills: oneHitKills ?? this.oneHitKills);
  }

  PersonalStatsAttackingExtended$Attacking$Hits copyWithWrapped(
      {Wrapped<int?>? success, Wrapped<int?>? miss, Wrapped<int?>? critical, Wrapped<int?>? oneHitKills}) {
    return PersonalStatsAttackingExtended$Attacking$Hits(
        success: (success != null ? success.value : this.success),
        miss: (miss != null ? miss.value : this.miss),
        critical: (critical != null ? critical.value : this.critical),
        oneHitKills: (oneHitKills != null ? oneHitKills.value : this.oneHitKills));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Damage {
  const PersonalStatsAttackingExtended$Attacking$Damage({
    this.total,
    this.best,
  });

  factory PersonalStatsAttackingExtended$Attacking$Damage.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$DamageFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$DamageToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$DamageToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'best')
  final int? best;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$DamageFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Damage &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^ const DeepCollectionEquality().hash(best) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$DamageExtension on PersonalStatsAttackingExtended$Attacking$Damage {
  PersonalStatsAttackingExtended$Attacking$Damage copyWith({int? total, int? best}) {
    return PersonalStatsAttackingExtended$Attacking$Damage(total: total ?? this.total, best: best ?? this.best);
  }

  PersonalStatsAttackingExtended$Attacking$Damage copyWithWrapped({Wrapped<int?>? total, Wrapped<int?>? best}) {
    return PersonalStatsAttackingExtended$Attacking$Damage(
        total: (total != null ? total.value : this.total), best: (best != null ? best.value : this.best));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Networth {
  const PersonalStatsAttackingExtended$Attacking$Networth({
    this.moneyMugged,
    this.largestMug,
    this.itemsLooted,
  });

  factory PersonalStatsAttackingExtended$Attacking$Networth.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$NetworthFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$NetworthToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$NetworthToJson(this);

  @JsonKey(name: 'money_mugged')
  final int? moneyMugged;
  @JsonKey(name: 'largest_mug')
  final int? largestMug;
  @JsonKey(name: 'items_looted')
  final int? itemsLooted;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$NetworthFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Networth &&
            (identical(other.moneyMugged, moneyMugged) ||
                const DeepCollectionEquality().equals(other.moneyMugged, moneyMugged)) &&
            (identical(other.largestMug, largestMug) ||
                const DeepCollectionEquality().equals(other.largestMug, largestMug)) &&
            (identical(other.itemsLooted, itemsLooted) ||
                const DeepCollectionEquality().equals(other.itemsLooted, itemsLooted)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(moneyMugged) ^
      const DeepCollectionEquality().hash(largestMug) ^
      const DeepCollectionEquality().hash(itemsLooted) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$NetworthExtension
    on PersonalStatsAttackingExtended$Attacking$Networth {
  PersonalStatsAttackingExtended$Attacking$Networth copyWith({int? moneyMugged, int? largestMug, int? itemsLooted}) {
    return PersonalStatsAttackingExtended$Attacking$Networth(
        moneyMugged: moneyMugged ?? this.moneyMugged,
        largestMug: largestMug ?? this.largestMug,
        itemsLooted: itemsLooted ?? this.itemsLooted);
  }

  PersonalStatsAttackingExtended$Attacking$Networth copyWithWrapped(
      {Wrapped<int?>? moneyMugged, Wrapped<int?>? largestMug, Wrapped<int?>? itemsLooted}) {
    return PersonalStatsAttackingExtended$Attacking$Networth(
        moneyMugged: (moneyMugged != null ? moneyMugged.value : this.moneyMugged),
        largestMug: (largestMug != null ? largestMug.value : this.largestMug),
        itemsLooted: (itemsLooted != null ? itemsLooted.value : this.itemsLooted));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Ammunition {
  const PersonalStatsAttackingExtended$Attacking$Ammunition({
    this.total,
    this.special,
    this.hollowPoint,
    this.tracer,
    this.piercing,
    this.incendiary,
  });

  factory PersonalStatsAttackingExtended$Attacking$Ammunition.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$AmmunitionFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$AmmunitionToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$AmmunitionToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'special')
  final int? special;
  @JsonKey(name: 'hollow_point')
  final int? hollowPoint;
  @JsonKey(name: 'tracer')
  final int? tracer;
  @JsonKey(name: 'piercing')
  final int? piercing;
  @JsonKey(name: 'incendiary')
  final int? incendiary;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$AmmunitionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Ammunition &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.special, special) || const DeepCollectionEquality().equals(other.special, special)) &&
            (identical(other.hollowPoint, hollowPoint) ||
                const DeepCollectionEquality().equals(other.hollowPoint, hollowPoint)) &&
            (identical(other.tracer, tracer) || const DeepCollectionEquality().equals(other.tracer, tracer)) &&
            (identical(other.piercing, piercing) || const DeepCollectionEquality().equals(other.piercing, piercing)) &&
            (identical(other.incendiary, incendiary) ||
                const DeepCollectionEquality().equals(other.incendiary, incendiary)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(special) ^
      const DeepCollectionEquality().hash(hollowPoint) ^
      const DeepCollectionEquality().hash(tracer) ^
      const DeepCollectionEquality().hash(piercing) ^
      const DeepCollectionEquality().hash(incendiary) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$AmmunitionExtension
    on PersonalStatsAttackingExtended$Attacking$Ammunition {
  PersonalStatsAttackingExtended$Attacking$Ammunition copyWith(
      {int? total, int? special, int? hollowPoint, int? tracer, int? piercing, int? incendiary}) {
    return PersonalStatsAttackingExtended$Attacking$Ammunition(
        total: total ?? this.total,
        special: special ?? this.special,
        hollowPoint: hollowPoint ?? this.hollowPoint,
        tracer: tracer ?? this.tracer,
        piercing: piercing ?? this.piercing,
        incendiary: incendiary ?? this.incendiary);
  }

  PersonalStatsAttackingExtended$Attacking$Ammunition copyWithWrapped(
      {Wrapped<int?>? total,
      Wrapped<int?>? special,
      Wrapped<int?>? hollowPoint,
      Wrapped<int?>? tracer,
      Wrapped<int?>? piercing,
      Wrapped<int?>? incendiary}) {
    return PersonalStatsAttackingExtended$Attacking$Ammunition(
        total: (total != null ? total.value : this.total),
        special: (special != null ? special.value : this.special),
        hollowPoint: (hollowPoint != null ? hollowPoint.value : this.hollowPoint),
        tracer: (tracer != null ? tracer.value : this.tracer),
        piercing: (piercing != null ? piercing.value : this.piercing),
        incendiary: (incendiary != null ? incendiary.value : this.incendiary));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Faction {
  const PersonalStatsAttackingExtended$Attacking$Faction({
    this.respect,
    this.retaliations,
    this.rankedWarHits,
    this.raidHits,
    this.territory,
  });

  factory PersonalStatsAttackingExtended$Attacking$Faction.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$FactionFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$FactionToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$FactionToJson(this);

  @JsonKey(name: 'respect')
  final int? respect;
  @JsonKey(name: 'retaliations')
  final int? retaliations;
  @JsonKey(name: 'ranked_war_hits')
  final int? rankedWarHits;
  @JsonKey(name: 'raid_hits')
  final int? raidHits;
  @JsonKey(name: 'territory')
  final PersonalStatsAttackingExtended$Attacking$Faction$Territory? territory;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$FactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Faction &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)) &&
            (identical(other.retaliations, retaliations) ||
                const DeepCollectionEquality().equals(other.retaliations, retaliations)) &&
            (identical(other.rankedWarHits, rankedWarHits) ||
                const DeepCollectionEquality().equals(other.rankedWarHits, rankedWarHits)) &&
            (identical(other.raidHits, raidHits) || const DeepCollectionEquality().equals(other.raidHits, raidHits)) &&
            (identical(other.territory, territory) ||
                const DeepCollectionEquality().equals(other.territory, territory)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(respect) ^
      const DeepCollectionEquality().hash(retaliations) ^
      const DeepCollectionEquality().hash(rankedWarHits) ^
      const DeepCollectionEquality().hash(raidHits) ^
      const DeepCollectionEquality().hash(territory) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$FactionExtension
    on PersonalStatsAttackingExtended$Attacking$Faction {
  PersonalStatsAttackingExtended$Attacking$Faction copyWith(
      {int? respect,
      int? retaliations,
      int? rankedWarHits,
      int? raidHits,
      PersonalStatsAttackingExtended$Attacking$Faction$Territory? territory}) {
    return PersonalStatsAttackingExtended$Attacking$Faction(
        respect: respect ?? this.respect,
        retaliations: retaliations ?? this.retaliations,
        rankedWarHits: rankedWarHits ?? this.rankedWarHits,
        raidHits: raidHits ?? this.raidHits,
        territory: territory ?? this.territory);
  }

  PersonalStatsAttackingExtended$Attacking$Faction copyWithWrapped(
      {Wrapped<int?>? respect,
      Wrapped<int?>? retaliations,
      Wrapped<int?>? rankedWarHits,
      Wrapped<int?>? raidHits,
      Wrapped<PersonalStatsAttackingExtended$Attacking$Faction$Territory?>? territory}) {
    return PersonalStatsAttackingExtended$Attacking$Faction(
        respect: (respect != null ? respect.value : this.respect),
        retaliations: (retaliations != null ? retaliations.value : this.retaliations),
        rankedWarHits: (rankedWarHits != null ? rankedWarHits.value : this.rankedWarHits),
        raidHits: (raidHits != null ? raidHits.value : this.raidHits),
        territory: (territory != null ? territory.value : this.territory));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking$Attacks {
  const PersonalStatsAttackingPopular$Attacking$Attacks({
    this.won,
    this.lost,
    this.stalemate,
    this.assist,
  });

  factory PersonalStatsAttackingPopular$Attacking$Attacks.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$Attacking$AttacksFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$Attacking$AttacksToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$Attacking$AttacksToJson(this);

  @JsonKey(name: 'won')
  final int? won;
  @JsonKey(name: 'lost')
  final int? lost;
  @JsonKey(name: 'stalemate')
  final int? stalemate;
  @JsonKey(name: 'assist')
  final int? assist;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$Attacking$AttacksFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking$Attacks &&
            (identical(other.won, won) || const DeepCollectionEquality().equals(other.won, won)) &&
            (identical(other.lost, lost) || const DeepCollectionEquality().equals(other.lost, lost)) &&
            (identical(other.stalemate, stalemate) ||
                const DeepCollectionEquality().equals(other.stalemate, stalemate)) &&
            (identical(other.assist, assist) || const DeepCollectionEquality().equals(other.assist, assist)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(won) ^
      const DeepCollectionEquality().hash(lost) ^
      const DeepCollectionEquality().hash(stalemate) ^
      const DeepCollectionEquality().hash(assist) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$Attacking$AttacksExtension on PersonalStatsAttackingPopular$Attacking$Attacks {
  PersonalStatsAttackingPopular$Attacking$Attacks copyWith({int? won, int? lost, int? stalemate, int? assist}) {
    return PersonalStatsAttackingPopular$Attacking$Attacks(
        won: won ?? this.won,
        lost: lost ?? this.lost,
        stalemate: stalemate ?? this.stalemate,
        assist: assist ?? this.assist);
  }

  PersonalStatsAttackingPopular$Attacking$Attacks copyWithWrapped(
      {Wrapped<int?>? won, Wrapped<int?>? lost, Wrapped<int?>? stalemate, Wrapped<int?>? assist}) {
    return PersonalStatsAttackingPopular$Attacking$Attacks(
        won: (won != null ? won.value : this.won),
        lost: (lost != null ? lost.value : this.lost),
        stalemate: (stalemate != null ? stalemate.value : this.stalemate),
        assist: (assist != null ? assist.value : this.assist));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking$Defends {
  const PersonalStatsAttackingPopular$Attacking$Defends({
    this.won,
    this.lost,
    this.stalemate,
  });

  factory PersonalStatsAttackingPopular$Attacking$Defends.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$Attacking$DefendsFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$Attacking$DefendsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$Attacking$DefendsToJson(this);

  @JsonKey(name: 'won')
  final int? won;
  @JsonKey(name: 'lost')
  final int? lost;
  @JsonKey(name: 'stalemate')
  final int? stalemate;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$Attacking$DefendsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking$Defends &&
            (identical(other.won, won) || const DeepCollectionEquality().equals(other.won, won)) &&
            (identical(other.lost, lost) || const DeepCollectionEquality().equals(other.lost, lost)) &&
            (identical(other.stalemate, stalemate) ||
                const DeepCollectionEquality().equals(other.stalemate, stalemate)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(won) ^
      const DeepCollectionEquality().hash(lost) ^
      const DeepCollectionEquality().hash(stalemate) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$Attacking$DefendsExtension on PersonalStatsAttackingPopular$Attacking$Defends {
  PersonalStatsAttackingPopular$Attacking$Defends copyWith({int? won, int? lost, int? stalemate}) {
    return PersonalStatsAttackingPopular$Attacking$Defends(
        won: won ?? this.won, lost: lost ?? this.lost, stalemate: stalemate ?? this.stalemate);
  }

  PersonalStatsAttackingPopular$Attacking$Defends copyWithWrapped(
      {Wrapped<int?>? won, Wrapped<int?>? lost, Wrapped<int?>? stalemate}) {
    return PersonalStatsAttackingPopular$Attacking$Defends(
        won: (won != null ? won.value : this.won),
        lost: (lost != null ? lost.value : this.lost),
        stalemate: (stalemate != null ? stalemate.value : this.stalemate));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking$Escapes {
  const PersonalStatsAttackingPopular$Attacking$Escapes({
    this.player,
    this.foes,
  });

  factory PersonalStatsAttackingPopular$Attacking$Escapes.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$Attacking$EscapesFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$Attacking$EscapesToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$Attacking$EscapesToJson(this);

  @JsonKey(name: 'player')
  final int? player;
  @JsonKey(name: 'foes')
  final int? foes;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$Attacking$EscapesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking$Escapes &&
            (identical(other.player, player) || const DeepCollectionEquality().equals(other.player, player)) &&
            (identical(other.foes, foes) || const DeepCollectionEquality().equals(other.foes, foes)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(player) ^ const DeepCollectionEquality().hash(foes) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$Attacking$EscapesExtension on PersonalStatsAttackingPopular$Attacking$Escapes {
  PersonalStatsAttackingPopular$Attacking$Escapes copyWith({int? player, int? foes}) {
    return PersonalStatsAttackingPopular$Attacking$Escapes(player: player ?? this.player, foes: foes ?? this.foes);
  }

  PersonalStatsAttackingPopular$Attacking$Escapes copyWithWrapped({Wrapped<int?>? player, Wrapped<int?>? foes}) {
    return PersonalStatsAttackingPopular$Attacking$Escapes(
        player: (player != null ? player.value : this.player), foes: (foes != null ? foes.value : this.foes));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking$Killstreak {
  const PersonalStatsAttackingPopular$Attacking$Killstreak({
    this.best,
  });

  factory PersonalStatsAttackingPopular$Attacking$Killstreak.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$Attacking$KillstreakFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$Attacking$KillstreakToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$Attacking$KillstreakToJson(this);

  @JsonKey(name: 'best')
  final int? best;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$Attacking$KillstreakFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking$Killstreak &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => const DeepCollectionEquality().hash(best) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$Attacking$KillstreakExtension
    on PersonalStatsAttackingPopular$Attacking$Killstreak {
  PersonalStatsAttackingPopular$Attacking$Killstreak copyWith({int? best}) {
    return PersonalStatsAttackingPopular$Attacking$Killstreak(best: best ?? this.best);
  }

  PersonalStatsAttackingPopular$Attacking$Killstreak copyWithWrapped({Wrapped<int?>? best}) {
    return PersonalStatsAttackingPopular$Attacking$Killstreak(best: (best != null ? best.value : this.best));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking$Hits {
  const PersonalStatsAttackingPopular$Attacking$Hits({
    this.success,
    this.miss,
    this.critical,
    this.oneHitKills,
  });

  factory PersonalStatsAttackingPopular$Attacking$Hits.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$Attacking$HitsFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$Attacking$HitsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$Attacking$HitsToJson(this);

  @JsonKey(name: 'success')
  final int? success;
  @JsonKey(name: 'miss')
  final int? miss;
  @JsonKey(name: 'critical')
  final int? critical;
  @JsonKey(name: 'one_hit_kills')
  final int? oneHitKills;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$Attacking$HitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking$Hits &&
            (identical(other.success, success) || const DeepCollectionEquality().equals(other.success, success)) &&
            (identical(other.miss, miss) || const DeepCollectionEquality().equals(other.miss, miss)) &&
            (identical(other.critical, critical) || const DeepCollectionEquality().equals(other.critical, critical)) &&
            (identical(other.oneHitKills, oneHitKills) ||
                const DeepCollectionEquality().equals(other.oneHitKills, oneHitKills)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(success) ^
      const DeepCollectionEquality().hash(miss) ^
      const DeepCollectionEquality().hash(critical) ^
      const DeepCollectionEquality().hash(oneHitKills) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$Attacking$HitsExtension on PersonalStatsAttackingPopular$Attacking$Hits {
  PersonalStatsAttackingPopular$Attacking$Hits copyWith({int? success, int? miss, int? critical, int? oneHitKills}) {
    return PersonalStatsAttackingPopular$Attacking$Hits(
        success: success ?? this.success,
        miss: miss ?? this.miss,
        critical: critical ?? this.critical,
        oneHitKills: oneHitKills ?? this.oneHitKills);
  }

  PersonalStatsAttackingPopular$Attacking$Hits copyWithWrapped(
      {Wrapped<int?>? success, Wrapped<int?>? miss, Wrapped<int?>? critical, Wrapped<int?>? oneHitKills}) {
    return PersonalStatsAttackingPopular$Attacking$Hits(
        success: (success != null ? success.value : this.success),
        miss: (miss != null ? miss.value : this.miss),
        critical: (critical != null ? critical.value : this.critical),
        oneHitKills: (oneHitKills != null ? oneHitKills.value : this.oneHitKills));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking$Damage {
  const PersonalStatsAttackingPopular$Attacking$Damage({
    this.total,
    this.best,
  });

  factory PersonalStatsAttackingPopular$Attacking$Damage.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$Attacking$DamageFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$Attacking$DamageToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$Attacking$DamageToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'best')
  final int? best;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$Attacking$DamageFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking$Damage &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^ const DeepCollectionEquality().hash(best) ^ runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$Attacking$DamageExtension on PersonalStatsAttackingPopular$Attacking$Damage {
  PersonalStatsAttackingPopular$Attacking$Damage copyWith({int? total, int? best}) {
    return PersonalStatsAttackingPopular$Attacking$Damage(total: total ?? this.total, best: best ?? this.best);
  }

  PersonalStatsAttackingPopular$Attacking$Damage copyWithWrapped({Wrapped<int?>? total, Wrapped<int?>? best}) {
    return PersonalStatsAttackingPopular$Attacking$Damage(
        total: (total != null ? total.value : this.total), best: (best != null ? best.value : this.best));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking$Networth {
  const PersonalStatsAttackingPopular$Attacking$Networth({
    this.moneyMugged,
    this.largestMug,
    this.itemsLooted,
  });

  factory PersonalStatsAttackingPopular$Attacking$Networth.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$Attacking$NetworthFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$Attacking$NetworthToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$Attacking$NetworthToJson(this);

  @JsonKey(name: 'money_mugged')
  final int? moneyMugged;
  @JsonKey(name: 'largest_mug')
  final int? largestMug;
  @JsonKey(name: 'items_looted')
  final int? itemsLooted;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$Attacking$NetworthFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking$Networth &&
            (identical(other.moneyMugged, moneyMugged) ||
                const DeepCollectionEquality().equals(other.moneyMugged, moneyMugged)) &&
            (identical(other.largestMug, largestMug) ||
                const DeepCollectionEquality().equals(other.largestMug, largestMug)) &&
            (identical(other.itemsLooted, itemsLooted) ||
                const DeepCollectionEquality().equals(other.itemsLooted, itemsLooted)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(moneyMugged) ^
      const DeepCollectionEquality().hash(largestMug) ^
      const DeepCollectionEquality().hash(itemsLooted) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$Attacking$NetworthExtension
    on PersonalStatsAttackingPopular$Attacking$Networth {
  PersonalStatsAttackingPopular$Attacking$Networth copyWith({int? moneyMugged, int? largestMug, int? itemsLooted}) {
    return PersonalStatsAttackingPopular$Attacking$Networth(
        moneyMugged: moneyMugged ?? this.moneyMugged,
        largestMug: largestMug ?? this.largestMug,
        itemsLooted: itemsLooted ?? this.itemsLooted);
  }

  PersonalStatsAttackingPopular$Attacking$Networth copyWithWrapped(
      {Wrapped<int?>? moneyMugged, Wrapped<int?>? largestMug, Wrapped<int?>? itemsLooted}) {
    return PersonalStatsAttackingPopular$Attacking$Networth(
        moneyMugged: (moneyMugged != null ? moneyMugged.value : this.moneyMugged),
        largestMug: (largestMug != null ? largestMug.value : this.largestMug),
        itemsLooted: (itemsLooted != null ? itemsLooted.value : this.itemsLooted));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking$Ammunition {
  const PersonalStatsAttackingPopular$Attacking$Ammunition({
    this.total,
    this.special,
    this.hollowPoint,
    this.tracer,
    this.piercing,
    this.incendiary,
  });

  factory PersonalStatsAttackingPopular$Attacking$Ammunition.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$Attacking$AmmunitionFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$Attacking$AmmunitionToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$Attacking$AmmunitionToJson(this);

  @JsonKey(name: 'total')
  final int? total;
  @JsonKey(name: 'special')
  final int? special;
  @JsonKey(name: 'hollow_point')
  final int? hollowPoint;
  @JsonKey(name: 'tracer')
  final int? tracer;
  @JsonKey(name: 'piercing')
  final int? piercing;
  @JsonKey(name: 'incendiary')
  final int? incendiary;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$Attacking$AmmunitionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking$Ammunition &&
            (identical(other.total, total) || const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.special, special) || const DeepCollectionEquality().equals(other.special, special)) &&
            (identical(other.hollowPoint, hollowPoint) ||
                const DeepCollectionEquality().equals(other.hollowPoint, hollowPoint)) &&
            (identical(other.tracer, tracer) || const DeepCollectionEquality().equals(other.tracer, tracer)) &&
            (identical(other.piercing, piercing) || const DeepCollectionEquality().equals(other.piercing, piercing)) &&
            (identical(other.incendiary, incendiary) ||
                const DeepCollectionEquality().equals(other.incendiary, incendiary)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(special) ^
      const DeepCollectionEquality().hash(hollowPoint) ^
      const DeepCollectionEquality().hash(tracer) ^
      const DeepCollectionEquality().hash(piercing) ^
      const DeepCollectionEquality().hash(incendiary) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$Attacking$AmmunitionExtension
    on PersonalStatsAttackingPopular$Attacking$Ammunition {
  PersonalStatsAttackingPopular$Attacking$Ammunition copyWith(
      {int? total, int? special, int? hollowPoint, int? tracer, int? piercing, int? incendiary}) {
    return PersonalStatsAttackingPopular$Attacking$Ammunition(
        total: total ?? this.total,
        special: special ?? this.special,
        hollowPoint: hollowPoint ?? this.hollowPoint,
        tracer: tracer ?? this.tracer,
        piercing: piercing ?? this.piercing,
        incendiary: incendiary ?? this.incendiary);
  }

  PersonalStatsAttackingPopular$Attacking$Ammunition copyWithWrapped(
      {Wrapped<int?>? total,
      Wrapped<int?>? special,
      Wrapped<int?>? hollowPoint,
      Wrapped<int?>? tracer,
      Wrapped<int?>? piercing,
      Wrapped<int?>? incendiary}) {
    return PersonalStatsAttackingPopular$Attacking$Ammunition(
        total: (total != null ? total.value : this.total),
        special: (special != null ? special.value : this.special),
        hollowPoint: (hollowPoint != null ? hollowPoint.value : this.hollowPoint),
        tracer: (tracer != null ? tracer.value : this.tracer),
        piercing: (piercing != null ? piercing.value : this.piercing),
        incendiary: (incendiary != null ? incendiary.value : this.incendiary));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPopular$Attacking$Faction {
  const PersonalStatsAttackingPopular$Attacking$Faction({
    this.respect,
    this.rankedWarHits,
  });

  factory PersonalStatsAttackingPopular$Attacking$Faction.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPopular$Attacking$FactionFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPopular$Attacking$FactionToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPopular$Attacking$FactionToJson(this);

  @JsonKey(name: 'respect')
  final int? respect;
  @JsonKey(name: 'ranked_war_hits')
  final int? rankedWarHits;
  static const fromJsonFactory = _$PersonalStatsAttackingPopular$Attacking$FactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPopular$Attacking$Faction &&
            (identical(other.respect, respect) || const DeepCollectionEquality().equals(other.respect, respect)) &&
            (identical(other.rankedWarHits, rankedWarHits) ||
                const DeepCollectionEquality().equals(other.rankedWarHits, rankedWarHits)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(respect) ^
      const DeepCollectionEquality().hash(rankedWarHits) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPopular$Attacking$FactionExtension on PersonalStatsAttackingPopular$Attacking$Faction {
  PersonalStatsAttackingPopular$Attacking$Faction copyWith({int? respect, int? rankedWarHits}) {
    return PersonalStatsAttackingPopular$Attacking$Faction(
        respect: respect ?? this.respect, rankedWarHits: rankedWarHits ?? this.rankedWarHits);
  }

  PersonalStatsAttackingPopular$Attacking$Faction copyWithWrapped(
      {Wrapped<int?>? respect, Wrapped<int?>? rankedWarHits}) {
    return PersonalStatsAttackingPopular$Attacking$Faction(
        respect: (respect != null ? respect.value : this.respect),
        rankedWarHits: (rankedWarHits != null ? rankedWarHits.value : this.rankedWarHits));
  }
}

@JsonSerializable(explicitToJson: true)
class UserCrimeDetailsCardSkimming$CardDetails$Areas$Item {
  const UserCrimeDetailsCardSkimming$CardDetails$Areas$Item({
    this.id,
    this.amount,
  });

  factory UserCrimeDetailsCardSkimming$CardDetails$Areas$Item.fromJson(Map<String, dynamic> json) =>
      _$UserCrimeDetailsCardSkimming$CardDetails$Areas$ItemFromJson(json);

  static const toJsonFactory = _$UserCrimeDetailsCardSkimming$CardDetails$Areas$ItemToJson;
  Map<String, dynamic> toJson() => _$UserCrimeDetailsCardSkimming$CardDetails$Areas$ItemToJson(this);

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'amount')
  final int? amount;
  static const fromJsonFactory = _$UserCrimeDetailsCardSkimming$CardDetails$Areas$ItemFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserCrimeDetailsCardSkimming$CardDetails$Areas$Item &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.amount, amount) || const DeepCollectionEquality().equals(other.amount, amount)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ const DeepCollectionEquality().hash(amount) ^ runtimeType.hashCode;
}

extension $UserCrimeDetailsCardSkimming$CardDetails$Areas$ItemExtension
    on UserCrimeDetailsCardSkimming$CardDetails$Areas$Item {
  UserCrimeDetailsCardSkimming$CardDetails$Areas$Item copyWith({int? id, int? amount}) {
    return UserCrimeDetailsCardSkimming$CardDetails$Areas$Item(id: id ?? this.id, amount: amount ?? this.amount);
  }

  UserCrimeDetailsCardSkimming$CardDetails$Areas$Item copyWithWrapped({Wrapped<int?>? id, Wrapped<int?>? amount}) {
    return UserCrimeDetailsCardSkimming$CardDetails$Areas$Item(
        id: (id != null ? id.value : this.id), amount: (amount != null ? amount.value : this.amount));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOther$Other$Activity$Streak {
  const PersonalStatsOther$Other$Activity$Streak({
    this.best,
    this.current,
  });

  factory PersonalStatsOther$Other$Activity$Streak.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsOther$Other$Activity$StreakFromJson(json);

  static const toJsonFactory = _$PersonalStatsOther$Other$Activity$StreakToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOther$Other$Activity$StreakToJson(this);

  @JsonKey(name: 'best')
  final int? best;
  @JsonKey(name: 'current')
  final int? current;
  static const fromJsonFactory = _$PersonalStatsOther$Other$Activity$StreakFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOther$Other$Activity$Streak &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)) &&
            (identical(other.current, current) || const DeepCollectionEquality().equals(other.current, current)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(best) ^ const DeepCollectionEquality().hash(current) ^ runtimeType.hashCode;
}

extension $PersonalStatsOther$Other$Activity$StreakExtension on PersonalStatsOther$Other$Activity$Streak {
  PersonalStatsOther$Other$Activity$Streak copyWith({int? best, int? current}) {
    return PersonalStatsOther$Other$Activity$Streak(best: best ?? this.best, current: current ?? this.current);
  }

  PersonalStatsOther$Other$Activity$Streak copyWithWrapped({Wrapped<int?>? best, Wrapped<int?>? current}) {
    return PersonalStatsOther$Other$Activity$Streak(
        best: (best != null ? best.value : this.best), current: (current != null ? current.value : this.current));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsOtherPopular$Other$Activity$Streak {
  const PersonalStatsOtherPopular$Other$Activity$Streak({
    this.best,
    this.current,
  });

  factory PersonalStatsOtherPopular$Other$Activity$Streak.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsOtherPopular$Other$Activity$StreakFromJson(json);

  static const toJsonFactory = _$PersonalStatsOtherPopular$Other$Activity$StreakToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsOtherPopular$Other$Activity$StreakToJson(this);

  @JsonKey(name: 'best')
  final int? best;
  @JsonKey(name: 'current')
  final int? current;
  static const fromJsonFactory = _$PersonalStatsOtherPopular$Other$Activity$StreakFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsOtherPopular$Other$Activity$Streak &&
            (identical(other.best, best) || const DeepCollectionEquality().equals(other.best, best)) &&
            (identical(other.current, current) || const DeepCollectionEquality().equals(other.current, current)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(best) ^ const DeepCollectionEquality().hash(current) ^ runtimeType.hashCode;
}

extension $PersonalStatsOtherPopular$Other$Activity$StreakExtension on PersonalStatsOtherPopular$Other$Activity$Streak {
  PersonalStatsOtherPopular$Other$Activity$Streak copyWith({int? best, int? current}) {
    return PersonalStatsOtherPopular$Other$Activity$Streak(best: best ?? this.best, current: current ?? this.current);
  }

  PersonalStatsOtherPopular$Other$Activity$Streak copyWithWrapped({Wrapped<int?>? best, Wrapped<int?>? current}) {
    return PersonalStatsOtherPopular$Other$Activity$Streak(
        best: (best != null ? best.value : this.best), current: (current != null ? current.value : this.current));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTrading$Trading$Items$Bought {
  const PersonalStatsTrading$Trading$Items$Bought({
    this.market,
    this.shops,
  });

  factory PersonalStatsTrading$Trading$Items$Bought.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsTrading$Trading$Items$BoughtFromJson(json);

  static const toJsonFactory = _$PersonalStatsTrading$Trading$Items$BoughtToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTrading$Trading$Items$BoughtToJson(this);

  @JsonKey(name: 'market')
  final int? market;
  @JsonKey(name: 'shops')
  final int? shops;
  static const fromJsonFactory = _$PersonalStatsTrading$Trading$Items$BoughtFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTrading$Trading$Items$Bought &&
            (identical(other.market, market) || const DeepCollectionEquality().equals(other.market, market)) &&
            (identical(other.shops, shops) || const DeepCollectionEquality().equals(other.shops, shops)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(market) ^ const DeepCollectionEquality().hash(shops) ^ runtimeType.hashCode;
}

extension $PersonalStatsTrading$Trading$Items$BoughtExtension on PersonalStatsTrading$Trading$Items$Bought {
  PersonalStatsTrading$Trading$Items$Bought copyWith({int? market, int? shops}) {
    return PersonalStatsTrading$Trading$Items$Bought(market: market ?? this.market, shops: shops ?? this.shops);
  }

  PersonalStatsTrading$Trading$Items$Bought copyWithWrapped({Wrapped<int?>? market, Wrapped<int?>? shops}) {
    return PersonalStatsTrading$Trading$Items$Bought(
        market: (market != null ? market.value : this.market), shops: (shops != null ? shops.value : this.shops));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsTrading$Trading$Items$Auctions {
  const PersonalStatsTrading$Trading$Items$Auctions({
    this.won,
    this.sold,
  });

  factory PersonalStatsTrading$Trading$Items$Auctions.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsTrading$Trading$Items$AuctionsFromJson(json);

  static const toJsonFactory = _$PersonalStatsTrading$Trading$Items$AuctionsToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsTrading$Trading$Items$AuctionsToJson(this);

  @JsonKey(name: 'won')
  final int? won;
  @JsonKey(name: 'sold')
  final int? sold;
  static const fromJsonFactory = _$PersonalStatsTrading$Trading$Items$AuctionsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsTrading$Trading$Items$Auctions &&
            (identical(other.won, won) || const DeepCollectionEquality().equals(other.won, won)) &&
            (identical(other.sold, sold) || const DeepCollectionEquality().equals(other.sold, sold)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(won) ^ const DeepCollectionEquality().hash(sold) ^ runtimeType.hashCode;
}

extension $PersonalStatsTrading$Trading$Items$AuctionsExtension on PersonalStatsTrading$Trading$Items$Auctions {
  PersonalStatsTrading$Trading$Items$Auctions copyWith({int? won, int? sold}) {
    return PersonalStatsTrading$Trading$Items$Auctions(won: won ?? this.won, sold: sold ?? this.sold);
  }

  PersonalStatsTrading$Trading$Items$Auctions copyWithWrapped({Wrapped<int?>? won, Wrapped<int?>? sold}) {
    return PersonalStatsTrading$Trading$Items$Auctions(
        won: (won != null ? won.value : this.won), sold: (sold != null ? sold.value : this.sold));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingPublic$Attacking$Faction$Territory {
  const PersonalStatsAttackingPublic$Attacking$Faction$Territory({
    this.wallJoins,
    this.wallClears,
    this.wallTime,
  });

  factory PersonalStatsAttackingPublic$Attacking$Faction$Territory.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingPublic$Attacking$Faction$TerritoryFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingPublic$Attacking$Faction$TerritoryToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingPublic$Attacking$Faction$TerritoryToJson(this);

  @JsonKey(name: 'wall_joins')
  final int? wallJoins;
  @JsonKey(name: 'wall_clears')
  final int? wallClears;
  @JsonKey(name: 'wall_time')
  final int? wallTime;
  static const fromJsonFactory = _$PersonalStatsAttackingPublic$Attacking$Faction$TerritoryFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingPublic$Attacking$Faction$Territory &&
            (identical(other.wallJoins, wallJoins) ||
                const DeepCollectionEquality().equals(other.wallJoins, wallJoins)) &&
            (identical(other.wallClears, wallClears) ||
                const DeepCollectionEquality().equals(other.wallClears, wallClears)) &&
            (identical(other.wallTime, wallTime) || const DeepCollectionEquality().equals(other.wallTime, wallTime)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(wallJoins) ^
      const DeepCollectionEquality().hash(wallClears) ^
      const DeepCollectionEquality().hash(wallTime) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingPublic$Attacking$Faction$TerritoryExtension
    on PersonalStatsAttackingPublic$Attacking$Faction$Territory {
  PersonalStatsAttackingPublic$Attacking$Faction$Territory copyWith({int? wallJoins, int? wallClears, int? wallTime}) {
    return PersonalStatsAttackingPublic$Attacking$Faction$Territory(
        wallJoins: wallJoins ?? this.wallJoins,
        wallClears: wallClears ?? this.wallClears,
        wallTime: wallTime ?? this.wallTime);
  }

  PersonalStatsAttackingPublic$Attacking$Faction$Territory copyWithWrapped(
      {Wrapped<int?>? wallJoins, Wrapped<int?>? wallClears, Wrapped<int?>? wallTime}) {
    return PersonalStatsAttackingPublic$Attacking$Faction$Territory(
        wallJoins: (wallJoins != null ? wallJoins.value : this.wallJoins),
        wallClears: (wallClears != null ? wallClears.value : this.wallClears),
        wallTime: (wallTime != null ? wallTime.value : this.wallTime));
  }
}

@JsonSerializable(explicitToJson: true)
class PersonalStatsAttackingExtended$Attacking$Faction$Territory {
  const PersonalStatsAttackingExtended$Attacking$Faction$Territory({
    this.wallJoins,
    this.wallClears,
    this.wallTime,
  });

  factory PersonalStatsAttackingExtended$Attacking$Faction$Territory.fromJson(Map<String, dynamic> json) =>
      _$PersonalStatsAttackingExtended$Attacking$Faction$TerritoryFromJson(json);

  static const toJsonFactory = _$PersonalStatsAttackingExtended$Attacking$Faction$TerritoryToJson;
  Map<String, dynamic> toJson() => _$PersonalStatsAttackingExtended$Attacking$Faction$TerritoryToJson(this);

  @JsonKey(name: 'wall_joins')
  final int? wallJoins;
  @JsonKey(name: 'wall_clears')
  final int? wallClears;
  @JsonKey(name: 'wall_time')
  final int? wallTime;
  static const fromJsonFactory = _$PersonalStatsAttackingExtended$Attacking$Faction$TerritoryFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PersonalStatsAttackingExtended$Attacking$Faction$Territory &&
            (identical(other.wallJoins, wallJoins) ||
                const DeepCollectionEquality().equals(other.wallJoins, wallJoins)) &&
            (identical(other.wallClears, wallClears) ||
                const DeepCollectionEquality().equals(other.wallClears, wallClears)) &&
            (identical(other.wallTime, wallTime) || const DeepCollectionEquality().equals(other.wallTime, wallTime)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(wallJoins) ^
      const DeepCollectionEquality().hash(wallClears) ^
      const DeepCollectionEquality().hash(wallTime) ^
      runtimeType.hashCode;
}

extension $PersonalStatsAttackingExtended$Attacking$Faction$TerritoryExtension
    on PersonalStatsAttackingExtended$Attacking$Faction$Territory {
  PersonalStatsAttackingExtended$Attacking$Faction$Territory copyWith(
      {int? wallJoins, int? wallClears, int? wallTime}) {
    return PersonalStatsAttackingExtended$Attacking$Faction$Territory(
        wallJoins: wallJoins ?? this.wallJoins,
        wallClears: wallClears ?? this.wallClears,
        wallTime: wallTime ?? this.wallTime);
  }

  PersonalStatsAttackingExtended$Attacking$Faction$Territory copyWithWrapped(
      {Wrapped<int?>? wallJoins, Wrapped<int?>? wallClears, Wrapped<int?>? wallTime}) {
    return PersonalStatsAttackingExtended$Attacking$Faction$Territory(
        wallJoins: (wallJoins != null ? wallJoins.value : this.wallJoins),
        wallClears: (wallClears != null ? wallClears.value : this.wallClears),
        wallTime: (wallTime != null ? wallTime.value : this.wallTime));
  }
}

String? raceClassEnumNullableToJson(enums.RaceClassEnum? raceClassEnum) {
  return raceClassEnum?.value;
}

String? raceClassEnumToJson(enums.RaceClassEnum raceClassEnum) {
  return raceClassEnum.value;
}

enums.RaceClassEnum raceClassEnumFromJson(
  Object? raceClassEnum, [
  enums.RaceClassEnum? defaultValue,
]) {
  return enums.RaceClassEnum.values.firstWhereOrNull((e) => e.value == raceClassEnum) ??
      defaultValue ??
      enums.RaceClassEnum.swaggerGeneratedUnknown;
}

enums.RaceClassEnum? raceClassEnumNullableFromJson(
  Object? raceClassEnum, [
  enums.RaceClassEnum? defaultValue,
]) {
  if (raceClassEnum == null) {
    return null;
  }
  return enums.RaceClassEnum.values.firstWhereOrNull((e) => e.value == raceClassEnum) ?? defaultValue;
}

String raceClassEnumExplodedListToJson(List<enums.RaceClassEnum>? raceClassEnum) {
  return raceClassEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> raceClassEnumListToJson(List<enums.RaceClassEnum>? raceClassEnum) {
  if (raceClassEnum == null) {
    return [];
  }

  return raceClassEnum.map((e) => e.value!).toList();
}

List<enums.RaceClassEnum> raceClassEnumListFromJson(
  List? raceClassEnum, [
  List<enums.RaceClassEnum>? defaultValue,
]) {
  if (raceClassEnum == null) {
    return defaultValue ?? [];
  }

  return raceClassEnum.map((e) => raceClassEnumFromJson(e.toString())).toList();
}

List<enums.RaceClassEnum>? raceClassEnumNullableListFromJson(
  List? raceClassEnum, [
  List<enums.RaceClassEnum>? defaultValue,
]) {
  if (raceClassEnum == null) {
    return defaultValue;
  }

  return raceClassEnum.map((e) => raceClassEnumFromJson(e.toString())).toList();
}

String? factionNewsCategoryNullableToJson(enums.FactionNewsCategory? factionNewsCategory) {
  return factionNewsCategory?.value;
}

String? factionNewsCategoryToJson(enums.FactionNewsCategory factionNewsCategory) {
  return factionNewsCategory.value;
}

enums.FactionNewsCategory factionNewsCategoryFromJson(
  Object? factionNewsCategory, [
  enums.FactionNewsCategory? defaultValue,
]) {
  return enums.FactionNewsCategory.values.firstWhereOrNull((e) => e.value == factionNewsCategory) ??
      defaultValue ??
      enums.FactionNewsCategory.swaggerGeneratedUnknown;
}

enums.FactionNewsCategory? factionNewsCategoryNullableFromJson(
  Object? factionNewsCategory, [
  enums.FactionNewsCategory? defaultValue,
]) {
  if (factionNewsCategory == null) {
    return null;
  }
  return enums.FactionNewsCategory.values.firstWhereOrNull((e) => e.value == factionNewsCategory) ?? defaultValue;
}

String factionNewsCategoryExplodedListToJson(List<enums.FactionNewsCategory>? factionNewsCategory) {
  return factionNewsCategory?.map((e) => e.value!).join(',') ?? '';
}

List<String> factionNewsCategoryListToJson(List<enums.FactionNewsCategory>? factionNewsCategory) {
  if (factionNewsCategory == null) {
    return [];
  }

  return factionNewsCategory.map((e) => e.value!).toList();
}

List<enums.FactionNewsCategory> factionNewsCategoryListFromJson(
  List? factionNewsCategory, [
  List<enums.FactionNewsCategory>? defaultValue,
]) {
  if (factionNewsCategory == null) {
    return defaultValue ?? [];
  }

  return factionNewsCategory.map((e) => factionNewsCategoryFromJson(e.toString())).toList();
}

List<enums.FactionNewsCategory>? factionNewsCategoryNullableListFromJson(
  List? factionNewsCategory, [
  List<enums.FactionNewsCategory>? defaultValue,
]) {
  if (factionNewsCategory == null) {
    return defaultValue;
  }

  return factionNewsCategory.map((e) => factionNewsCategoryFromJson(e.toString())).toList();
}

String? factionRankEnumNullableToJson(enums.FactionRankEnum? factionRankEnum) {
  return factionRankEnum?.value;
}

String? factionRankEnumToJson(enums.FactionRankEnum factionRankEnum) {
  return factionRankEnum.value;
}

enums.FactionRankEnum factionRankEnumFromJson(
  Object? factionRankEnum, [
  enums.FactionRankEnum? defaultValue,
]) {
  return enums.FactionRankEnum.values.firstWhereOrNull((e) => e.value == factionRankEnum) ??
      defaultValue ??
      enums.FactionRankEnum.swaggerGeneratedUnknown;
}

enums.FactionRankEnum? factionRankEnumNullableFromJson(
  Object? factionRankEnum, [
  enums.FactionRankEnum? defaultValue,
]) {
  if (factionRankEnum == null) {
    return null;
  }
  return enums.FactionRankEnum.values.firstWhereOrNull((e) => e.value == factionRankEnum) ?? defaultValue;
}

String factionRankEnumExplodedListToJson(List<enums.FactionRankEnum>? factionRankEnum) {
  return factionRankEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> factionRankEnumListToJson(List<enums.FactionRankEnum>? factionRankEnum) {
  if (factionRankEnum == null) {
    return [];
  }

  return factionRankEnum.map((e) => e.value!).toList();
}

List<enums.FactionRankEnum> factionRankEnumListFromJson(
  List? factionRankEnum, [
  List<enums.FactionRankEnum>? defaultValue,
]) {
  if (factionRankEnum == null) {
    return defaultValue ?? [];
  }

  return factionRankEnum.map((e) => factionRankEnumFromJson(e.toString())).toList();
}

List<enums.FactionRankEnum>? factionRankEnumNullableListFromJson(
  List? factionRankEnum, [
  List<enums.FactionRankEnum>? defaultValue,
]) {
  if (factionRankEnum == null) {
    return defaultValue;
  }

  return factionRankEnum.map((e) => factionRankEnumFromJson(e.toString())).toList();
}

String? userCrimeUniquesRewardAmmoEnumNullableToJson(
    enums.UserCrimeUniquesRewardAmmoEnum? userCrimeUniquesRewardAmmoEnum) {
  return userCrimeUniquesRewardAmmoEnum?.value;
}

String? userCrimeUniquesRewardAmmoEnumToJson(enums.UserCrimeUniquesRewardAmmoEnum userCrimeUniquesRewardAmmoEnum) {
  return userCrimeUniquesRewardAmmoEnum.value;
}

enums.UserCrimeUniquesRewardAmmoEnum userCrimeUniquesRewardAmmoEnumFromJson(
  Object? userCrimeUniquesRewardAmmoEnum, [
  enums.UserCrimeUniquesRewardAmmoEnum? defaultValue,
]) {
  return enums.UserCrimeUniquesRewardAmmoEnum.values
          .firstWhereOrNull((e) => e.value == userCrimeUniquesRewardAmmoEnum) ??
      defaultValue ??
      enums.UserCrimeUniquesRewardAmmoEnum.swaggerGeneratedUnknown;
}

enums.UserCrimeUniquesRewardAmmoEnum? userCrimeUniquesRewardAmmoEnumNullableFromJson(
  Object? userCrimeUniquesRewardAmmoEnum, [
  enums.UserCrimeUniquesRewardAmmoEnum? defaultValue,
]) {
  if (userCrimeUniquesRewardAmmoEnum == null) {
    return null;
  }
  return enums.UserCrimeUniquesRewardAmmoEnum.values
          .firstWhereOrNull((e) => e.value == userCrimeUniquesRewardAmmoEnum) ??
      defaultValue;
}

String userCrimeUniquesRewardAmmoEnumExplodedListToJson(
    List<enums.UserCrimeUniquesRewardAmmoEnum>? userCrimeUniquesRewardAmmoEnum) {
  return userCrimeUniquesRewardAmmoEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> userCrimeUniquesRewardAmmoEnumListToJson(
    List<enums.UserCrimeUniquesRewardAmmoEnum>? userCrimeUniquesRewardAmmoEnum) {
  if (userCrimeUniquesRewardAmmoEnum == null) {
    return [];
  }

  return userCrimeUniquesRewardAmmoEnum.map((e) => e.value!).toList();
}

List<enums.UserCrimeUniquesRewardAmmoEnum> userCrimeUniquesRewardAmmoEnumListFromJson(
  List? userCrimeUniquesRewardAmmoEnum, [
  List<enums.UserCrimeUniquesRewardAmmoEnum>? defaultValue,
]) {
  if (userCrimeUniquesRewardAmmoEnum == null) {
    return defaultValue ?? [];
  }

  return userCrimeUniquesRewardAmmoEnum.map((e) => userCrimeUniquesRewardAmmoEnumFromJson(e.toString())).toList();
}

List<enums.UserCrimeUniquesRewardAmmoEnum>? userCrimeUniquesRewardAmmoEnumNullableListFromJson(
  List? userCrimeUniquesRewardAmmoEnum, [
  List<enums.UserCrimeUniquesRewardAmmoEnum>? defaultValue,
]) {
  if (userCrimeUniquesRewardAmmoEnum == null) {
    return defaultValue;
  }

  return userCrimeUniquesRewardAmmoEnum.map((e) => userCrimeUniquesRewardAmmoEnumFromJson(e.toString())).toList();
}

String? raceStatusEnumNullableToJson(enums.RaceStatusEnum? raceStatusEnum) {
  return raceStatusEnum?.value;
}

String? raceStatusEnumToJson(enums.RaceStatusEnum raceStatusEnum) {
  return raceStatusEnum.value;
}

enums.RaceStatusEnum raceStatusEnumFromJson(
  Object? raceStatusEnum, [
  enums.RaceStatusEnum? defaultValue,
]) {
  return enums.RaceStatusEnum.values.firstWhereOrNull((e) => e.value == raceStatusEnum) ??
      defaultValue ??
      enums.RaceStatusEnum.swaggerGeneratedUnknown;
}

enums.RaceStatusEnum? raceStatusEnumNullableFromJson(
  Object? raceStatusEnum, [
  enums.RaceStatusEnum? defaultValue,
]) {
  if (raceStatusEnum == null) {
    return null;
  }
  return enums.RaceStatusEnum.values.firstWhereOrNull((e) => e.value == raceStatusEnum) ?? defaultValue;
}

String raceStatusEnumExplodedListToJson(List<enums.RaceStatusEnum>? raceStatusEnum) {
  return raceStatusEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> raceStatusEnumListToJson(List<enums.RaceStatusEnum>? raceStatusEnum) {
  if (raceStatusEnum == null) {
    return [];
  }

  return raceStatusEnum.map((e) => e.value!).toList();
}

List<enums.RaceStatusEnum> raceStatusEnumListFromJson(
  List? raceStatusEnum, [
  List<enums.RaceStatusEnum>? defaultValue,
]) {
  if (raceStatusEnum == null) {
    return defaultValue ?? [];
  }

  return raceStatusEnum.map((e) => raceStatusEnumFromJson(e.toString())).toList();
}

List<enums.RaceStatusEnum>? raceStatusEnumNullableListFromJson(
  List? raceStatusEnum, [
  List<enums.RaceStatusEnum>? defaultValue,
]) {
  if (raceStatusEnum == null) {
    return defaultValue;
  }

  return raceStatusEnum.map((e) => raceStatusEnumFromJson(e.toString())).toList();
}

String? tornHofCategoryNullableToJson(enums.TornHofCategory? tornHofCategory) {
  return tornHofCategory?.value;
}

String? tornHofCategoryToJson(enums.TornHofCategory tornHofCategory) {
  return tornHofCategory.value;
}

enums.TornHofCategory tornHofCategoryFromJson(
  Object? tornHofCategory, [
  enums.TornHofCategory? defaultValue,
]) {
  return enums.TornHofCategory.values.firstWhereOrNull((e) => e.value == tornHofCategory) ??
      defaultValue ??
      enums.TornHofCategory.swaggerGeneratedUnknown;
}

enums.TornHofCategory? tornHofCategoryNullableFromJson(
  Object? tornHofCategory, [
  enums.TornHofCategory? defaultValue,
]) {
  if (tornHofCategory == null) {
    return null;
  }
  return enums.TornHofCategory.values.firstWhereOrNull((e) => e.value == tornHofCategory) ?? defaultValue;
}

String tornHofCategoryExplodedListToJson(List<enums.TornHofCategory>? tornHofCategory) {
  return tornHofCategory?.map((e) => e.value!).join(',') ?? '';
}

List<String> tornHofCategoryListToJson(List<enums.TornHofCategory>? tornHofCategory) {
  if (tornHofCategory == null) {
    return [];
  }

  return tornHofCategory.map((e) => e.value!).toList();
}

List<enums.TornHofCategory> tornHofCategoryListFromJson(
  List? tornHofCategory, [
  List<enums.TornHofCategory>? defaultValue,
]) {
  if (tornHofCategory == null) {
    return defaultValue ?? [];
  }

  return tornHofCategory.map((e) => tornHofCategoryFromJson(e.toString())).toList();
}

List<enums.TornHofCategory>? tornHofCategoryNullableListFromJson(
  List? tornHofCategory, [
  List<enums.TornHofCategory>? defaultValue,
]) {
  if (tornHofCategory == null) {
    return defaultValue;
  }

  return tornHofCategory.map((e) => tornHofCategoryFromJson(e.toString())).toList();
}

String? tornFactionHofCategoryNullableToJson(enums.TornFactionHofCategory? tornFactionHofCategory) {
  return tornFactionHofCategory?.value;
}

String? tornFactionHofCategoryToJson(enums.TornFactionHofCategory tornFactionHofCategory) {
  return tornFactionHofCategory.value;
}

enums.TornFactionHofCategory tornFactionHofCategoryFromJson(
  Object? tornFactionHofCategory, [
  enums.TornFactionHofCategory? defaultValue,
]) {
  return enums.TornFactionHofCategory.values.firstWhereOrNull((e) => e.value == tornFactionHofCategory) ??
      defaultValue ??
      enums.TornFactionHofCategory.swaggerGeneratedUnknown;
}

enums.TornFactionHofCategory? tornFactionHofCategoryNullableFromJson(
  Object? tornFactionHofCategory, [
  enums.TornFactionHofCategory? defaultValue,
]) {
  if (tornFactionHofCategory == null) {
    return null;
  }
  return enums.TornFactionHofCategory.values.firstWhereOrNull((e) => e.value == tornFactionHofCategory) ?? defaultValue;
}

String tornFactionHofCategoryExplodedListToJson(List<enums.TornFactionHofCategory>? tornFactionHofCategory) {
  return tornFactionHofCategory?.map((e) => e.value!).join(',') ?? '';
}

List<String> tornFactionHofCategoryListToJson(List<enums.TornFactionHofCategory>? tornFactionHofCategory) {
  if (tornFactionHofCategory == null) {
    return [];
  }

  return tornFactionHofCategory.map((e) => e.value!).toList();
}

List<enums.TornFactionHofCategory> tornFactionHofCategoryListFromJson(
  List? tornFactionHofCategory, [
  List<enums.TornFactionHofCategory>? defaultValue,
]) {
  if (tornFactionHofCategory == null) {
    return defaultValue ?? [];
  }

  return tornFactionHofCategory.map((e) => tornFactionHofCategoryFromJson(e.toString())).toList();
}

List<enums.TornFactionHofCategory>? tornFactionHofCategoryNullableListFromJson(
  List? tornFactionHofCategory, [
  List<enums.TornFactionHofCategory>? defaultValue,
]) {
  if (tornFactionHofCategory == null) {
    return defaultValue;
  }

  return tornFactionHofCategory.map((e) => tornFactionHofCategoryFromJson(e.toString())).toList();
}

String? factionAttackResultNullableToJson(enums.FactionAttackResult? factionAttackResult) {
  return factionAttackResult?.value;
}

String? factionAttackResultToJson(enums.FactionAttackResult factionAttackResult) {
  return factionAttackResult.value;
}

enums.FactionAttackResult factionAttackResultFromJson(
  Object? factionAttackResult, [
  enums.FactionAttackResult? defaultValue,
]) {
  return enums.FactionAttackResult.values.firstWhereOrNull((e) => e.value == factionAttackResult) ??
      defaultValue ??
      enums.FactionAttackResult.swaggerGeneratedUnknown;
}

enums.FactionAttackResult? factionAttackResultNullableFromJson(
  Object? factionAttackResult, [
  enums.FactionAttackResult? defaultValue,
]) {
  if (factionAttackResult == null) {
    return null;
  }
  return enums.FactionAttackResult.values.firstWhereOrNull((e) => e.value == factionAttackResult) ?? defaultValue;
}

String factionAttackResultExplodedListToJson(List<enums.FactionAttackResult>? factionAttackResult) {
  return factionAttackResult?.map((e) => e.value!).join(',') ?? '';
}

List<String> factionAttackResultListToJson(List<enums.FactionAttackResult>? factionAttackResult) {
  if (factionAttackResult == null) {
    return [];
  }

  return factionAttackResult.map((e) => e.value!).toList();
}

List<enums.FactionAttackResult> factionAttackResultListFromJson(
  List? factionAttackResult, [
  List<enums.FactionAttackResult>? defaultValue,
]) {
  if (factionAttackResult == null) {
    return defaultValue ?? [];
  }

  return factionAttackResult.map((e) => factionAttackResultFromJson(e.toString())).toList();
}

List<enums.FactionAttackResult>? factionAttackResultNullableListFromJson(
  List? factionAttackResult, [
  List<enums.FactionAttackResult>? defaultValue,
]) {
  if (factionAttackResult == null) {
    return defaultValue;
  }

  return factionAttackResult.map((e) => factionAttackResultFromJson(e.toString())).toList();
}

String? raceCarUpgradeCategoryNullableToJson(enums.RaceCarUpgradeCategory? raceCarUpgradeCategory) {
  return raceCarUpgradeCategory?.value;
}

String? raceCarUpgradeCategoryToJson(enums.RaceCarUpgradeCategory raceCarUpgradeCategory) {
  return raceCarUpgradeCategory.value;
}

enums.RaceCarUpgradeCategory raceCarUpgradeCategoryFromJson(
  Object? raceCarUpgradeCategory, [
  enums.RaceCarUpgradeCategory? defaultValue,
]) {
  return enums.RaceCarUpgradeCategory.values.firstWhereOrNull((e) => e.value == raceCarUpgradeCategory) ??
      defaultValue ??
      enums.RaceCarUpgradeCategory.swaggerGeneratedUnknown;
}

enums.RaceCarUpgradeCategory? raceCarUpgradeCategoryNullableFromJson(
  Object? raceCarUpgradeCategory, [
  enums.RaceCarUpgradeCategory? defaultValue,
]) {
  if (raceCarUpgradeCategory == null) {
    return null;
  }
  return enums.RaceCarUpgradeCategory.values.firstWhereOrNull((e) => e.value == raceCarUpgradeCategory) ?? defaultValue;
}

String raceCarUpgradeCategoryExplodedListToJson(List<enums.RaceCarUpgradeCategory>? raceCarUpgradeCategory) {
  return raceCarUpgradeCategory?.map((e) => e.value!).join(',') ?? '';
}

List<String> raceCarUpgradeCategoryListToJson(List<enums.RaceCarUpgradeCategory>? raceCarUpgradeCategory) {
  if (raceCarUpgradeCategory == null) {
    return [];
  }

  return raceCarUpgradeCategory.map((e) => e.value!).toList();
}

List<enums.RaceCarUpgradeCategory> raceCarUpgradeCategoryListFromJson(
  List? raceCarUpgradeCategory, [
  List<enums.RaceCarUpgradeCategory>? defaultValue,
]) {
  if (raceCarUpgradeCategory == null) {
    return defaultValue ?? [];
  }

  return raceCarUpgradeCategory.map((e) => raceCarUpgradeCategoryFromJson(e.toString())).toList();
}

List<enums.RaceCarUpgradeCategory>? raceCarUpgradeCategoryNullableListFromJson(
  List? raceCarUpgradeCategory, [
  List<enums.RaceCarUpgradeCategory>? defaultValue,
]) {
  if (raceCarUpgradeCategory == null) {
    return defaultValue;
  }

  return raceCarUpgradeCategory.map((e) => raceCarUpgradeCategoryFromJson(e.toString())).toList();
}

String? jobPositionArmyEnumNullableToJson(enums.JobPositionArmyEnum? jobPositionArmyEnum) {
  return jobPositionArmyEnum?.value;
}

String? jobPositionArmyEnumToJson(enums.JobPositionArmyEnum jobPositionArmyEnum) {
  return jobPositionArmyEnum.value;
}

enums.JobPositionArmyEnum jobPositionArmyEnumFromJson(
  Object? jobPositionArmyEnum, [
  enums.JobPositionArmyEnum? defaultValue,
]) {
  return enums.JobPositionArmyEnum.values.firstWhereOrNull((e) => e.value == jobPositionArmyEnum) ??
      defaultValue ??
      enums.JobPositionArmyEnum.swaggerGeneratedUnknown;
}

enums.JobPositionArmyEnum? jobPositionArmyEnumNullableFromJson(
  Object? jobPositionArmyEnum, [
  enums.JobPositionArmyEnum? defaultValue,
]) {
  if (jobPositionArmyEnum == null) {
    return null;
  }
  return enums.JobPositionArmyEnum.values.firstWhereOrNull((e) => e.value == jobPositionArmyEnum) ?? defaultValue;
}

String jobPositionArmyEnumExplodedListToJson(List<enums.JobPositionArmyEnum>? jobPositionArmyEnum) {
  return jobPositionArmyEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> jobPositionArmyEnumListToJson(List<enums.JobPositionArmyEnum>? jobPositionArmyEnum) {
  if (jobPositionArmyEnum == null) {
    return [];
  }

  return jobPositionArmyEnum.map((e) => e.value!).toList();
}

List<enums.JobPositionArmyEnum> jobPositionArmyEnumListFromJson(
  List? jobPositionArmyEnum, [
  List<enums.JobPositionArmyEnum>? defaultValue,
]) {
  if (jobPositionArmyEnum == null) {
    return defaultValue ?? [];
  }

  return jobPositionArmyEnum.map((e) => jobPositionArmyEnumFromJson(e.toString())).toList();
}

List<enums.JobPositionArmyEnum>? jobPositionArmyEnumNullableListFromJson(
  List? jobPositionArmyEnum, [
  List<enums.JobPositionArmyEnum>? defaultValue,
]) {
  if (jobPositionArmyEnum == null) {
    return defaultValue;
  }

  return jobPositionArmyEnum.map((e) => jobPositionArmyEnumFromJson(e.toString())).toList();
}

String? jobPositionGrocerEnumNullableToJson(enums.JobPositionGrocerEnum? jobPositionGrocerEnum) {
  return jobPositionGrocerEnum?.value;
}

String? jobPositionGrocerEnumToJson(enums.JobPositionGrocerEnum jobPositionGrocerEnum) {
  return jobPositionGrocerEnum.value;
}

enums.JobPositionGrocerEnum jobPositionGrocerEnumFromJson(
  Object? jobPositionGrocerEnum, [
  enums.JobPositionGrocerEnum? defaultValue,
]) {
  return enums.JobPositionGrocerEnum.values.firstWhereOrNull((e) => e.value == jobPositionGrocerEnum) ??
      defaultValue ??
      enums.JobPositionGrocerEnum.swaggerGeneratedUnknown;
}

enums.JobPositionGrocerEnum? jobPositionGrocerEnumNullableFromJson(
  Object? jobPositionGrocerEnum, [
  enums.JobPositionGrocerEnum? defaultValue,
]) {
  if (jobPositionGrocerEnum == null) {
    return null;
  }
  return enums.JobPositionGrocerEnum.values.firstWhereOrNull((e) => e.value == jobPositionGrocerEnum) ?? defaultValue;
}

String jobPositionGrocerEnumExplodedListToJson(List<enums.JobPositionGrocerEnum>? jobPositionGrocerEnum) {
  return jobPositionGrocerEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> jobPositionGrocerEnumListToJson(List<enums.JobPositionGrocerEnum>? jobPositionGrocerEnum) {
  if (jobPositionGrocerEnum == null) {
    return [];
  }

  return jobPositionGrocerEnum.map((e) => e.value!).toList();
}

List<enums.JobPositionGrocerEnum> jobPositionGrocerEnumListFromJson(
  List? jobPositionGrocerEnum, [
  List<enums.JobPositionGrocerEnum>? defaultValue,
]) {
  if (jobPositionGrocerEnum == null) {
    return defaultValue ?? [];
  }

  return jobPositionGrocerEnum.map((e) => jobPositionGrocerEnumFromJson(e.toString())).toList();
}

List<enums.JobPositionGrocerEnum>? jobPositionGrocerEnumNullableListFromJson(
  List? jobPositionGrocerEnum, [
  List<enums.JobPositionGrocerEnum>? defaultValue,
]) {
  if (jobPositionGrocerEnum == null) {
    return defaultValue;
  }

  return jobPositionGrocerEnum.map((e) => jobPositionGrocerEnumFromJson(e.toString())).toList();
}

String? weaponBonusEnumNullableToJson(enums.WeaponBonusEnum? weaponBonusEnum) {
  return weaponBonusEnum?.value;
}

String? weaponBonusEnumToJson(enums.WeaponBonusEnum weaponBonusEnum) {
  return weaponBonusEnum.value;
}

enums.WeaponBonusEnum weaponBonusEnumFromJson(
  Object? weaponBonusEnum, [
  enums.WeaponBonusEnum? defaultValue,
]) {
  return enums.WeaponBonusEnum.values.firstWhereOrNull((e) => e.value == weaponBonusEnum) ??
      defaultValue ??
      enums.WeaponBonusEnum.swaggerGeneratedUnknown;
}

enums.WeaponBonusEnum? weaponBonusEnumNullableFromJson(
  Object? weaponBonusEnum, [
  enums.WeaponBonusEnum? defaultValue,
]) {
  if (weaponBonusEnum == null) {
    return null;
  }
  return enums.WeaponBonusEnum.values.firstWhereOrNull((e) => e.value == weaponBonusEnum) ?? defaultValue;
}

String weaponBonusEnumExplodedListToJson(List<enums.WeaponBonusEnum>? weaponBonusEnum) {
  return weaponBonusEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> weaponBonusEnumListToJson(List<enums.WeaponBonusEnum>? weaponBonusEnum) {
  if (weaponBonusEnum == null) {
    return [];
  }

  return weaponBonusEnum.map((e) => e.value!).toList();
}

List<enums.WeaponBonusEnum> weaponBonusEnumListFromJson(
  List? weaponBonusEnum, [
  List<enums.WeaponBonusEnum>? defaultValue,
]) {
  if (weaponBonusEnum == null) {
    return defaultValue ?? [];
  }

  return weaponBonusEnum.map((e) => weaponBonusEnumFromJson(e.toString())).toList();
}

List<enums.WeaponBonusEnum>? weaponBonusEnumNullableListFromJson(
  List? weaponBonusEnum, [
  List<enums.WeaponBonusEnum>? defaultValue,
]) {
  if (weaponBonusEnum == null) {
    return defaultValue;
  }

  return weaponBonusEnum.map((e) => weaponBonusEnumFromJson(e.toString())).toList();
}

String? jobPositionCasinoEnumNullableToJson(enums.JobPositionCasinoEnum? jobPositionCasinoEnum) {
  return jobPositionCasinoEnum?.value;
}

String? jobPositionCasinoEnumToJson(enums.JobPositionCasinoEnum jobPositionCasinoEnum) {
  return jobPositionCasinoEnum.value;
}

enums.JobPositionCasinoEnum jobPositionCasinoEnumFromJson(
  Object? jobPositionCasinoEnum, [
  enums.JobPositionCasinoEnum? defaultValue,
]) {
  return enums.JobPositionCasinoEnum.values.firstWhereOrNull((e) => e.value == jobPositionCasinoEnum) ??
      defaultValue ??
      enums.JobPositionCasinoEnum.swaggerGeneratedUnknown;
}

enums.JobPositionCasinoEnum? jobPositionCasinoEnumNullableFromJson(
  Object? jobPositionCasinoEnum, [
  enums.JobPositionCasinoEnum? defaultValue,
]) {
  if (jobPositionCasinoEnum == null) {
    return null;
  }
  return enums.JobPositionCasinoEnum.values.firstWhereOrNull((e) => e.value == jobPositionCasinoEnum) ?? defaultValue;
}

String jobPositionCasinoEnumExplodedListToJson(List<enums.JobPositionCasinoEnum>? jobPositionCasinoEnum) {
  return jobPositionCasinoEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> jobPositionCasinoEnumListToJson(List<enums.JobPositionCasinoEnum>? jobPositionCasinoEnum) {
  if (jobPositionCasinoEnum == null) {
    return [];
  }

  return jobPositionCasinoEnum.map((e) => e.value!).toList();
}

List<enums.JobPositionCasinoEnum> jobPositionCasinoEnumListFromJson(
  List? jobPositionCasinoEnum, [
  List<enums.JobPositionCasinoEnum>? defaultValue,
]) {
  if (jobPositionCasinoEnum == null) {
    return defaultValue ?? [];
  }

  return jobPositionCasinoEnum.map((e) => jobPositionCasinoEnumFromJson(e.toString())).toList();
}

List<enums.JobPositionCasinoEnum>? jobPositionCasinoEnumNullableListFromJson(
  List? jobPositionCasinoEnum, [
  List<enums.JobPositionCasinoEnum>? defaultValue,
]) {
  if (jobPositionCasinoEnum == null) {
    return defaultValue;
  }

  return jobPositionCasinoEnum.map((e) => jobPositionCasinoEnumFromJson(e.toString())).toList();
}

String? jobPositionMedicalEnumNullableToJson(enums.JobPositionMedicalEnum? jobPositionMedicalEnum) {
  return jobPositionMedicalEnum?.value;
}

String? jobPositionMedicalEnumToJson(enums.JobPositionMedicalEnum jobPositionMedicalEnum) {
  return jobPositionMedicalEnum.value;
}

enums.JobPositionMedicalEnum jobPositionMedicalEnumFromJson(
  Object? jobPositionMedicalEnum, [
  enums.JobPositionMedicalEnum? defaultValue,
]) {
  return enums.JobPositionMedicalEnum.values.firstWhereOrNull((e) => e.value == jobPositionMedicalEnum) ??
      defaultValue ??
      enums.JobPositionMedicalEnum.swaggerGeneratedUnknown;
}

enums.JobPositionMedicalEnum? jobPositionMedicalEnumNullableFromJson(
  Object? jobPositionMedicalEnum, [
  enums.JobPositionMedicalEnum? defaultValue,
]) {
  if (jobPositionMedicalEnum == null) {
    return null;
  }
  return enums.JobPositionMedicalEnum.values.firstWhereOrNull((e) => e.value == jobPositionMedicalEnum) ?? defaultValue;
}

String jobPositionMedicalEnumExplodedListToJson(List<enums.JobPositionMedicalEnum>? jobPositionMedicalEnum) {
  return jobPositionMedicalEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> jobPositionMedicalEnumListToJson(List<enums.JobPositionMedicalEnum>? jobPositionMedicalEnum) {
  if (jobPositionMedicalEnum == null) {
    return [];
  }

  return jobPositionMedicalEnum.map((e) => e.value!).toList();
}

List<enums.JobPositionMedicalEnum> jobPositionMedicalEnumListFromJson(
  List? jobPositionMedicalEnum, [
  List<enums.JobPositionMedicalEnum>? defaultValue,
]) {
  if (jobPositionMedicalEnum == null) {
    return defaultValue ?? [];
  }

  return jobPositionMedicalEnum.map((e) => jobPositionMedicalEnumFromJson(e.toString())).toList();
}

List<enums.JobPositionMedicalEnum>? jobPositionMedicalEnumNullableListFromJson(
  List? jobPositionMedicalEnum, [
  List<enums.JobPositionMedicalEnum>? defaultValue,
]) {
  if (jobPositionMedicalEnum == null) {
    return defaultValue;
  }

  return jobPositionMedicalEnum.map((e) => jobPositionMedicalEnumFromJson(e.toString())).toList();
}

String? jobPositionLawEnumNullableToJson(enums.JobPositionLawEnum? jobPositionLawEnum) {
  return jobPositionLawEnum?.value;
}

String? jobPositionLawEnumToJson(enums.JobPositionLawEnum jobPositionLawEnum) {
  return jobPositionLawEnum.value;
}

enums.JobPositionLawEnum jobPositionLawEnumFromJson(
  Object? jobPositionLawEnum, [
  enums.JobPositionLawEnum? defaultValue,
]) {
  return enums.JobPositionLawEnum.values.firstWhereOrNull((e) => e.value == jobPositionLawEnum) ??
      defaultValue ??
      enums.JobPositionLawEnum.swaggerGeneratedUnknown;
}

enums.JobPositionLawEnum? jobPositionLawEnumNullableFromJson(
  Object? jobPositionLawEnum, [
  enums.JobPositionLawEnum? defaultValue,
]) {
  if (jobPositionLawEnum == null) {
    return null;
  }
  return enums.JobPositionLawEnum.values.firstWhereOrNull((e) => e.value == jobPositionLawEnum) ?? defaultValue;
}

String jobPositionLawEnumExplodedListToJson(List<enums.JobPositionLawEnum>? jobPositionLawEnum) {
  return jobPositionLawEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> jobPositionLawEnumListToJson(List<enums.JobPositionLawEnum>? jobPositionLawEnum) {
  if (jobPositionLawEnum == null) {
    return [];
  }

  return jobPositionLawEnum.map((e) => e.value!).toList();
}

List<enums.JobPositionLawEnum> jobPositionLawEnumListFromJson(
  List? jobPositionLawEnum, [
  List<enums.JobPositionLawEnum>? defaultValue,
]) {
  if (jobPositionLawEnum == null) {
    return defaultValue ?? [];
  }

  return jobPositionLawEnum.map((e) => jobPositionLawEnumFromJson(e.toString())).toList();
}

List<enums.JobPositionLawEnum>? jobPositionLawEnumNullableListFromJson(
  List? jobPositionLawEnum, [
  List<enums.JobPositionLawEnum>? defaultValue,
]) {
  if (jobPositionLawEnum == null) {
    return defaultValue;
  }

  return jobPositionLawEnum.map((e) => jobPositionLawEnumFromJson(e.toString())).toList();
}

String? jobPositionEducationEnumNullableToJson(enums.JobPositionEducationEnum? jobPositionEducationEnum) {
  return jobPositionEducationEnum?.value;
}

String? jobPositionEducationEnumToJson(enums.JobPositionEducationEnum jobPositionEducationEnum) {
  return jobPositionEducationEnum.value;
}

enums.JobPositionEducationEnum jobPositionEducationEnumFromJson(
  Object? jobPositionEducationEnum, [
  enums.JobPositionEducationEnum? defaultValue,
]) {
  return enums.JobPositionEducationEnum.values.firstWhereOrNull((e) => e.value == jobPositionEducationEnum) ??
      defaultValue ??
      enums.JobPositionEducationEnum.swaggerGeneratedUnknown;
}

enums.JobPositionEducationEnum? jobPositionEducationEnumNullableFromJson(
  Object? jobPositionEducationEnum, [
  enums.JobPositionEducationEnum? defaultValue,
]) {
  if (jobPositionEducationEnum == null) {
    return null;
  }
  return enums.JobPositionEducationEnum.values.firstWhereOrNull((e) => e.value == jobPositionEducationEnum) ??
      defaultValue;
}

String jobPositionEducationEnumExplodedListToJson(List<enums.JobPositionEducationEnum>? jobPositionEducationEnum) {
  return jobPositionEducationEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> jobPositionEducationEnumListToJson(List<enums.JobPositionEducationEnum>? jobPositionEducationEnum) {
  if (jobPositionEducationEnum == null) {
    return [];
  }

  return jobPositionEducationEnum.map((e) => e.value!).toList();
}

List<enums.JobPositionEducationEnum> jobPositionEducationEnumListFromJson(
  List? jobPositionEducationEnum, [
  List<enums.JobPositionEducationEnum>? defaultValue,
]) {
  if (jobPositionEducationEnum == null) {
    return defaultValue ?? [];
  }

  return jobPositionEducationEnum.map((e) => jobPositionEducationEnumFromJson(e.toString())).toList();
}

List<enums.JobPositionEducationEnum>? jobPositionEducationEnumNullableListFromJson(
  List? jobPositionEducationEnum, [
  List<enums.JobPositionEducationEnum>? defaultValue,
]) {
  if (jobPositionEducationEnum == null) {
    return defaultValue;
  }

  return jobPositionEducationEnum.map((e) => jobPositionEducationEnumFromJson(e.toString())).toList();
}

String? raceCarUpgradeSubCategoryNullableToJson(enums.RaceCarUpgradeSubCategory? raceCarUpgradeSubCategory) {
  return raceCarUpgradeSubCategory?.value;
}

String? raceCarUpgradeSubCategoryToJson(enums.RaceCarUpgradeSubCategory raceCarUpgradeSubCategory) {
  return raceCarUpgradeSubCategory.value;
}

enums.RaceCarUpgradeSubCategory raceCarUpgradeSubCategoryFromJson(
  Object? raceCarUpgradeSubCategory, [
  enums.RaceCarUpgradeSubCategory? defaultValue,
]) {
  return enums.RaceCarUpgradeSubCategory.values.firstWhereOrNull((e) => e.value == raceCarUpgradeSubCategory) ??
      defaultValue ??
      enums.RaceCarUpgradeSubCategory.swaggerGeneratedUnknown;
}

enums.RaceCarUpgradeSubCategory? raceCarUpgradeSubCategoryNullableFromJson(
  Object? raceCarUpgradeSubCategory, [
  enums.RaceCarUpgradeSubCategory? defaultValue,
]) {
  if (raceCarUpgradeSubCategory == null) {
    return null;
  }
  return enums.RaceCarUpgradeSubCategory.values.firstWhereOrNull((e) => e.value == raceCarUpgradeSubCategory) ??
      defaultValue;
}

String raceCarUpgradeSubCategoryExplodedListToJson(List<enums.RaceCarUpgradeSubCategory>? raceCarUpgradeSubCategory) {
  return raceCarUpgradeSubCategory?.map((e) => e.value!).join(',') ?? '';
}

List<String> raceCarUpgradeSubCategoryListToJson(List<enums.RaceCarUpgradeSubCategory>? raceCarUpgradeSubCategory) {
  if (raceCarUpgradeSubCategory == null) {
    return [];
  }

  return raceCarUpgradeSubCategory.map((e) => e.value!).toList();
}

List<enums.RaceCarUpgradeSubCategory> raceCarUpgradeSubCategoryListFromJson(
  List? raceCarUpgradeSubCategory, [
  List<enums.RaceCarUpgradeSubCategory>? defaultValue,
]) {
  if (raceCarUpgradeSubCategory == null) {
    return defaultValue ?? [];
  }

  return raceCarUpgradeSubCategory.map((e) => raceCarUpgradeSubCategoryFromJson(e.toString())).toList();
}

List<enums.RaceCarUpgradeSubCategory>? raceCarUpgradeSubCategoryNullableListFromJson(
  List? raceCarUpgradeSubCategory, [
  List<enums.RaceCarUpgradeSubCategory>? defaultValue,
]) {
  if (raceCarUpgradeSubCategory == null) {
    return defaultValue;
  }

  return raceCarUpgradeSubCategory.map((e) => raceCarUpgradeSubCategoryFromJson(e.toString())).toList();
}

String? factionApplicationStatusEnumNullableToJson(enums.FactionApplicationStatusEnum? factionApplicationStatusEnum) {
  return factionApplicationStatusEnum?.value;
}

String? factionApplicationStatusEnumToJson(enums.FactionApplicationStatusEnum factionApplicationStatusEnum) {
  return factionApplicationStatusEnum.value;
}

enums.FactionApplicationStatusEnum factionApplicationStatusEnumFromJson(
  Object? factionApplicationStatusEnum, [
  enums.FactionApplicationStatusEnum? defaultValue,
]) {
  return enums.FactionApplicationStatusEnum.values.firstWhereOrNull((e) => e.value == factionApplicationStatusEnum) ??
      defaultValue ??
      enums.FactionApplicationStatusEnum.swaggerGeneratedUnknown;
}

enums.FactionApplicationStatusEnum? factionApplicationStatusEnumNullableFromJson(
  Object? factionApplicationStatusEnum, [
  enums.FactionApplicationStatusEnum? defaultValue,
]) {
  if (factionApplicationStatusEnum == null) {
    return null;
  }
  return enums.FactionApplicationStatusEnum.values.firstWhereOrNull((e) => e.value == factionApplicationStatusEnum) ??
      defaultValue;
}

String factionApplicationStatusEnumExplodedListToJson(
    List<enums.FactionApplicationStatusEnum>? factionApplicationStatusEnum) {
  return factionApplicationStatusEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> factionApplicationStatusEnumListToJson(
    List<enums.FactionApplicationStatusEnum>? factionApplicationStatusEnum) {
  if (factionApplicationStatusEnum == null) {
    return [];
  }

  return factionApplicationStatusEnum.map((e) => e.value!).toList();
}

List<enums.FactionApplicationStatusEnum> factionApplicationStatusEnumListFromJson(
  List? factionApplicationStatusEnum, [
  List<enums.FactionApplicationStatusEnum>? defaultValue,
]) {
  if (factionApplicationStatusEnum == null) {
    return defaultValue ?? [];
  }

  return factionApplicationStatusEnum.map((e) => factionApplicationStatusEnumFromJson(e.toString())).toList();
}

List<enums.FactionApplicationStatusEnum>? factionApplicationStatusEnumNullableListFromJson(
  List? factionApplicationStatusEnum, [
  List<enums.FactionApplicationStatusEnum>? defaultValue,
]) {
  if (factionApplicationStatusEnum == null) {
    return defaultValue;
  }

  return factionApplicationStatusEnum.map((e) => factionApplicationStatusEnumFromJson(e.toString())).toList();
}

int? forumFeedTypeEnumNullableToJson(enums.ForumFeedTypeEnum? forumFeedTypeEnum) {
  return forumFeedTypeEnum?.value;
}

int? forumFeedTypeEnumToJson(enums.ForumFeedTypeEnum forumFeedTypeEnum) {
  return forumFeedTypeEnum.value;
}

enums.ForumFeedTypeEnum forumFeedTypeEnumFromJson(
  Object? forumFeedTypeEnum, [
  enums.ForumFeedTypeEnum? defaultValue,
]) {
  return enums.ForumFeedTypeEnum.values.firstWhereOrNull((e) => e.value == forumFeedTypeEnum) ??
      defaultValue ??
      enums.ForumFeedTypeEnum.swaggerGeneratedUnknown;
}

enums.ForumFeedTypeEnum? forumFeedTypeEnumNullableFromJson(
  Object? forumFeedTypeEnum, [
  enums.ForumFeedTypeEnum? defaultValue,
]) {
  if (forumFeedTypeEnum == null) {
    return null;
  }
  return enums.ForumFeedTypeEnum.values.firstWhereOrNull((e) => e.value == forumFeedTypeEnum) ?? defaultValue;
}

String forumFeedTypeEnumExplodedListToJson(List<enums.ForumFeedTypeEnum>? forumFeedTypeEnum) {
  return forumFeedTypeEnum?.map((e) => e.value!).join(',') ?? '';
}

List<int> forumFeedTypeEnumListToJson(List<enums.ForumFeedTypeEnum>? forumFeedTypeEnum) {
  if (forumFeedTypeEnum == null) {
    return [];
  }

  return forumFeedTypeEnum.map((e) => e.value!).toList();
}

List<enums.ForumFeedTypeEnum> forumFeedTypeEnumListFromJson(
  List? forumFeedTypeEnum, [
  List<enums.ForumFeedTypeEnum>? defaultValue,
]) {
  if (forumFeedTypeEnum == null) {
    return defaultValue ?? [];
  }

  return forumFeedTypeEnum.map((e) => forumFeedTypeEnumFromJson(e.toString())).toList();
}

List<enums.ForumFeedTypeEnum>? forumFeedTypeEnumNullableListFromJson(
  List? forumFeedTypeEnum, [
  List<enums.ForumFeedTypeEnum>? defaultValue,
]) {
  if (forumFeedTypeEnum == null) {
    return defaultValue;
  }

  return forumFeedTypeEnum.map((e) => forumFeedTypeEnumFromJson(e.toString())).toList();
}

String? reviveSettingNullableToJson(enums.ReviveSetting? reviveSetting) {
  return reviveSetting?.value;
}

String? reviveSettingToJson(enums.ReviveSetting reviveSetting) {
  return reviveSetting.value;
}

enums.ReviveSetting reviveSettingFromJson(
  Object? reviveSetting, [
  enums.ReviveSetting? defaultValue,
]) {
  return enums.ReviveSetting.values.firstWhereOrNull((e) => e.value == reviveSetting) ??
      defaultValue ??
      enums.ReviveSetting.swaggerGeneratedUnknown;
}

enums.ReviveSetting? reviveSettingNullableFromJson(
  Object? reviveSetting, [
  enums.ReviveSetting? defaultValue,
]) {
  if (reviveSetting == null) {
    return null;
  }
  return enums.ReviveSetting.values.firstWhereOrNull((e) => e.value == reviveSetting) ?? defaultValue;
}

String reviveSettingExplodedListToJson(List<enums.ReviveSetting>? reviveSetting) {
  return reviveSetting?.map((e) => e.value!).join(',') ?? '';
}

List<String> reviveSettingListToJson(List<enums.ReviveSetting>? reviveSetting) {
  if (reviveSetting == null) {
    return [];
  }

  return reviveSetting.map((e) => e.value!).toList();
}

List<enums.ReviveSetting> reviveSettingListFromJson(
  List? reviveSetting, [
  List<enums.ReviveSetting>? defaultValue,
]) {
  if (reviveSetting == null) {
    return defaultValue ?? [];
  }

  return reviveSetting.map((e) => reviveSettingFromJson(e.toString())).toList();
}

List<enums.ReviveSetting>? reviveSettingNullableListFromJson(
  List? reviveSetting, [
  List<enums.ReviveSetting>? defaultValue,
]) {
  if (reviveSetting == null) {
    return defaultValue;
  }

  return reviveSetting.map((e) => reviveSettingFromJson(e.toString())).toList();
}

String? factionCrimeStatusEnumNullableToJson(enums.FactionCrimeStatusEnum? factionCrimeStatusEnum) {
  return factionCrimeStatusEnum?.value;
}

String? factionCrimeStatusEnumToJson(enums.FactionCrimeStatusEnum factionCrimeStatusEnum) {
  return factionCrimeStatusEnum.value;
}

enums.FactionCrimeStatusEnum factionCrimeStatusEnumFromJson(
  Object? factionCrimeStatusEnum, [
  enums.FactionCrimeStatusEnum? defaultValue,
]) {
  return enums.FactionCrimeStatusEnum.values.firstWhereOrNull((e) => e.value == factionCrimeStatusEnum) ??
      defaultValue ??
      enums.FactionCrimeStatusEnum.swaggerGeneratedUnknown;
}

enums.FactionCrimeStatusEnum? factionCrimeStatusEnumNullableFromJson(
  Object? factionCrimeStatusEnum, [
  enums.FactionCrimeStatusEnum? defaultValue,
]) {
  if (factionCrimeStatusEnum == null) {
    return null;
  }
  return enums.FactionCrimeStatusEnum.values.firstWhereOrNull((e) => e.value == factionCrimeStatusEnum) ?? defaultValue;
}

String factionCrimeStatusEnumExplodedListToJson(List<enums.FactionCrimeStatusEnum>? factionCrimeStatusEnum) {
  return factionCrimeStatusEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> factionCrimeStatusEnumListToJson(List<enums.FactionCrimeStatusEnum>? factionCrimeStatusEnum) {
  if (factionCrimeStatusEnum == null) {
    return [];
  }

  return factionCrimeStatusEnum.map((e) => e.value!).toList();
}

List<enums.FactionCrimeStatusEnum> factionCrimeStatusEnumListFromJson(
  List? factionCrimeStatusEnum, [
  List<enums.FactionCrimeStatusEnum>? defaultValue,
]) {
  if (factionCrimeStatusEnum == null) {
    return defaultValue ?? [];
  }

  return factionCrimeStatusEnum.map((e) => factionCrimeStatusEnumFromJson(e.toString())).toList();
}

List<enums.FactionCrimeStatusEnum>? factionCrimeStatusEnumNullableListFromJson(
  List? factionCrimeStatusEnum, [
  List<enums.FactionCrimeStatusEnum>? defaultValue,
]) {
  if (factionCrimeStatusEnum == null) {
    return defaultValue;
  }

  return factionCrimeStatusEnum.map((e) => factionCrimeStatusEnumFromJson(e.toString())).toList();
}

String? factionSelectionNameNullableToJson(enums.FactionSelectionName? factionSelectionName) {
  return factionSelectionName?.value;
}

String? factionSelectionNameToJson(enums.FactionSelectionName factionSelectionName) {
  return factionSelectionName.value;
}

enums.FactionSelectionName factionSelectionNameFromJson(
  Object? factionSelectionName, [
  enums.FactionSelectionName? defaultValue,
]) {
  return enums.FactionSelectionName.values.firstWhereOrNull((e) => e.value == factionSelectionName) ??
      defaultValue ??
      enums.FactionSelectionName.swaggerGeneratedUnknown;
}

enums.FactionSelectionName? factionSelectionNameNullableFromJson(
  Object? factionSelectionName, [
  enums.FactionSelectionName? defaultValue,
]) {
  if (factionSelectionName == null) {
    return null;
  }
  return enums.FactionSelectionName.values.firstWhereOrNull((e) => e.value == factionSelectionName) ?? defaultValue;
}

String factionSelectionNameExplodedListToJson(List<enums.FactionSelectionName>? factionSelectionName) {
  return factionSelectionName?.map((e) => e.value!).join(',') ?? '';
}

List<String> factionSelectionNameListToJson(List<enums.FactionSelectionName>? factionSelectionName) {
  if (factionSelectionName == null) {
    return [];
  }

  return factionSelectionName.map((e) => e.value!).toList();
}

List<enums.FactionSelectionName> factionSelectionNameListFromJson(
  List? factionSelectionName, [
  List<enums.FactionSelectionName>? defaultValue,
]) {
  if (factionSelectionName == null) {
    return defaultValue ?? [];
  }

  return factionSelectionName.map((e) => factionSelectionNameFromJson(e.toString())).toList();
}

List<enums.FactionSelectionName>? factionSelectionNameNullableListFromJson(
  List? factionSelectionName, [
  List<enums.FactionSelectionName>? defaultValue,
]) {
  if (factionSelectionName == null) {
    return defaultValue;
  }

  return factionSelectionName.map((e) => factionSelectionNameFromJson(e.toString())).toList();
}

String? forumSelectionNameNullableToJson(enums.ForumSelectionName? forumSelectionName) {
  return forumSelectionName?.value;
}

String? forumSelectionNameToJson(enums.ForumSelectionName forumSelectionName) {
  return forumSelectionName.value;
}

enums.ForumSelectionName forumSelectionNameFromJson(
  Object? forumSelectionName, [
  enums.ForumSelectionName? defaultValue,
]) {
  return enums.ForumSelectionName.values.firstWhereOrNull((e) => e.value == forumSelectionName) ??
      defaultValue ??
      enums.ForumSelectionName.swaggerGeneratedUnknown;
}

enums.ForumSelectionName? forumSelectionNameNullableFromJson(
  Object? forumSelectionName, [
  enums.ForumSelectionName? defaultValue,
]) {
  if (forumSelectionName == null) {
    return null;
  }
  return enums.ForumSelectionName.values.firstWhereOrNull((e) => e.value == forumSelectionName) ?? defaultValue;
}

String forumSelectionNameExplodedListToJson(List<enums.ForumSelectionName>? forumSelectionName) {
  return forumSelectionName?.map((e) => e.value!).join(',') ?? '';
}

List<String> forumSelectionNameListToJson(List<enums.ForumSelectionName>? forumSelectionName) {
  if (forumSelectionName == null) {
    return [];
  }

  return forumSelectionName.map((e) => e.value!).toList();
}

List<enums.ForumSelectionName> forumSelectionNameListFromJson(
  List? forumSelectionName, [
  List<enums.ForumSelectionName>? defaultValue,
]) {
  if (forumSelectionName == null) {
    return defaultValue ?? [];
  }

  return forumSelectionName.map((e) => forumSelectionNameFromJson(e.toString())).toList();
}

List<enums.ForumSelectionName>? forumSelectionNameNullableListFromJson(
  List? forumSelectionName, [
  List<enums.ForumSelectionName>? defaultValue,
]) {
  if (forumSelectionName == null) {
    return defaultValue;
  }

  return forumSelectionName.map((e) => forumSelectionNameFromJson(e.toString())).toList();
}

String? itemMarketListingItemDetailsRarityNullableToJson(
    enums.ItemMarketListingItemDetailsRarity? itemMarketListingItemDetailsRarity) {
  return itemMarketListingItemDetailsRarity?.value;
}

String? itemMarketListingItemDetailsRarityToJson(
    enums.ItemMarketListingItemDetailsRarity itemMarketListingItemDetailsRarity) {
  return itemMarketListingItemDetailsRarity.value;
}

enums.ItemMarketListingItemDetailsRarity itemMarketListingItemDetailsRarityFromJson(
  Object? itemMarketListingItemDetailsRarity, [
  enums.ItemMarketListingItemDetailsRarity? defaultValue,
]) {
  return enums.ItemMarketListingItemDetailsRarity.values
          .firstWhereOrNull((e) => e.value == itemMarketListingItemDetailsRarity) ??
      defaultValue ??
      enums.ItemMarketListingItemDetailsRarity.swaggerGeneratedUnknown;
}

enums.ItemMarketListingItemDetailsRarity? itemMarketListingItemDetailsRarityNullableFromJson(
  Object? itemMarketListingItemDetailsRarity, [
  enums.ItemMarketListingItemDetailsRarity? defaultValue,
]) {
  if (itemMarketListingItemDetailsRarity == null) {
    return null;
  }
  return enums.ItemMarketListingItemDetailsRarity.values
          .firstWhereOrNull((e) => e.value == itemMarketListingItemDetailsRarity) ??
      defaultValue;
}

String itemMarketListingItemDetailsRarityExplodedListToJson(
    List<enums.ItemMarketListingItemDetailsRarity>? itemMarketListingItemDetailsRarity) {
  return itemMarketListingItemDetailsRarity?.map((e) => e.value!).join(',') ?? '';
}

List<String> itemMarketListingItemDetailsRarityListToJson(
    List<enums.ItemMarketListingItemDetailsRarity>? itemMarketListingItemDetailsRarity) {
  if (itemMarketListingItemDetailsRarity == null) {
    return [];
  }

  return itemMarketListingItemDetailsRarity.map((e) => e.value!).toList();
}

List<enums.ItemMarketListingItemDetailsRarity> itemMarketListingItemDetailsRarityListFromJson(
  List? itemMarketListingItemDetailsRarity, [
  List<enums.ItemMarketListingItemDetailsRarity>? defaultValue,
]) {
  if (itemMarketListingItemDetailsRarity == null) {
    return defaultValue ?? [];
  }

  return itemMarketListingItemDetailsRarity
      .map((e) => itemMarketListingItemDetailsRarityFromJson(e.toString()))
      .toList();
}

List<enums.ItemMarketListingItemDetailsRarity>? itemMarketListingItemDetailsRarityNullableListFromJson(
  List? itemMarketListingItemDetailsRarity, [
  List<enums.ItemMarketListingItemDetailsRarity>? defaultValue,
]) {
  if (itemMarketListingItemDetailsRarity == null) {
    return defaultValue;
  }

  return itemMarketListingItemDetailsRarity
      .map((e) => itemMarketListingItemDetailsRarityFromJson(e.toString()))
      .toList();
}

String? marketSelectionNameNullableToJson(enums.MarketSelectionName? marketSelectionName) {
  return marketSelectionName?.value;
}

String? marketSelectionNameToJson(enums.MarketSelectionName marketSelectionName) {
  return marketSelectionName.value;
}

enums.MarketSelectionName marketSelectionNameFromJson(
  Object? marketSelectionName, [
  enums.MarketSelectionName? defaultValue,
]) {
  return enums.MarketSelectionName.values.firstWhereOrNull((e) => e.value == marketSelectionName) ??
      defaultValue ??
      enums.MarketSelectionName.swaggerGeneratedUnknown;
}

enums.MarketSelectionName? marketSelectionNameNullableFromJson(
  Object? marketSelectionName, [
  enums.MarketSelectionName? defaultValue,
]) {
  if (marketSelectionName == null) {
    return null;
  }
  return enums.MarketSelectionName.values.firstWhereOrNull((e) => e.value == marketSelectionName) ?? defaultValue;
}

String marketSelectionNameExplodedListToJson(List<enums.MarketSelectionName>? marketSelectionName) {
  return marketSelectionName?.map((e) => e.value!).join(',') ?? '';
}

List<String> marketSelectionNameListToJson(List<enums.MarketSelectionName>? marketSelectionName) {
  if (marketSelectionName == null) {
    return [];
  }

  return marketSelectionName.map((e) => e.value!).toList();
}

List<enums.MarketSelectionName> marketSelectionNameListFromJson(
  List? marketSelectionName, [
  List<enums.MarketSelectionName>? defaultValue,
]) {
  if (marketSelectionName == null) {
    return defaultValue ?? [];
  }

  return marketSelectionName.map((e) => marketSelectionNameFromJson(e.toString())).toList();
}

List<enums.MarketSelectionName>? marketSelectionNameNullableListFromJson(
  List? marketSelectionName, [
  List<enums.MarketSelectionName>? defaultValue,
]) {
  if (marketSelectionName == null) {
    return defaultValue;
  }

  return marketSelectionName.map((e) => marketSelectionNameFromJson(e.toString())).toList();
}

String? racingSelectionNameNullableToJson(enums.RacingSelectionName? racingSelectionName) {
  return racingSelectionName?.value;
}

String? racingSelectionNameToJson(enums.RacingSelectionName racingSelectionName) {
  return racingSelectionName.value;
}

enums.RacingSelectionName racingSelectionNameFromJson(
  Object? racingSelectionName, [
  enums.RacingSelectionName? defaultValue,
]) {
  return enums.RacingSelectionName.values.firstWhereOrNull((e) => e.value == racingSelectionName) ??
      defaultValue ??
      enums.RacingSelectionName.swaggerGeneratedUnknown;
}

enums.RacingSelectionName? racingSelectionNameNullableFromJson(
  Object? racingSelectionName, [
  enums.RacingSelectionName? defaultValue,
]) {
  if (racingSelectionName == null) {
    return null;
  }
  return enums.RacingSelectionName.values.firstWhereOrNull((e) => e.value == racingSelectionName) ?? defaultValue;
}

String racingSelectionNameExplodedListToJson(List<enums.RacingSelectionName>? racingSelectionName) {
  return racingSelectionName?.map((e) => e.value!).join(',') ?? '';
}

List<String> racingSelectionNameListToJson(List<enums.RacingSelectionName>? racingSelectionName) {
  if (racingSelectionName == null) {
    return [];
  }

  return racingSelectionName.map((e) => e.value!).toList();
}

List<enums.RacingSelectionName> racingSelectionNameListFromJson(
  List? racingSelectionName, [
  List<enums.RacingSelectionName>? defaultValue,
]) {
  if (racingSelectionName == null) {
    return defaultValue ?? [];
  }

  return racingSelectionName.map((e) => racingSelectionNameFromJson(e.toString())).toList();
}

List<enums.RacingSelectionName>? racingSelectionNameNullableListFromJson(
  List? racingSelectionName, [
  List<enums.RacingSelectionName>? defaultValue,
]) {
  if (racingSelectionName == null) {
    return defaultValue;
  }

  return racingSelectionName.map((e) => racingSelectionNameFromJson(e.toString())).toList();
}

String? tornSelectionNameNullableToJson(enums.TornSelectionName? tornSelectionName) {
  return tornSelectionName?.value;
}

String? tornSelectionNameToJson(enums.TornSelectionName tornSelectionName) {
  return tornSelectionName.value;
}

enums.TornSelectionName tornSelectionNameFromJson(
  Object? tornSelectionName, [
  enums.TornSelectionName? defaultValue,
]) {
  return enums.TornSelectionName.values.firstWhereOrNull((e) => e.value == tornSelectionName) ??
      defaultValue ??
      enums.TornSelectionName.swaggerGeneratedUnknown;
}

enums.TornSelectionName? tornSelectionNameNullableFromJson(
  Object? tornSelectionName, [
  enums.TornSelectionName? defaultValue,
]) {
  if (tornSelectionName == null) {
    return null;
  }
  return enums.TornSelectionName.values.firstWhereOrNull((e) => e.value == tornSelectionName) ?? defaultValue;
}

String tornSelectionNameExplodedListToJson(List<enums.TornSelectionName>? tornSelectionName) {
  return tornSelectionName?.map((e) => e.value!).join(',') ?? '';
}

List<String> tornSelectionNameListToJson(List<enums.TornSelectionName>? tornSelectionName) {
  if (tornSelectionName == null) {
    return [];
  }

  return tornSelectionName.map((e) => e.value!).toList();
}

List<enums.TornSelectionName> tornSelectionNameListFromJson(
  List? tornSelectionName, [
  List<enums.TornSelectionName>? defaultValue,
]) {
  if (tornSelectionName == null) {
    return defaultValue ?? [];
  }

  return tornSelectionName.map((e) => tornSelectionNameFromJson(e.toString())).toList();
}

List<enums.TornSelectionName>? tornSelectionNameNullableListFromJson(
  List? tornSelectionName, [
  List<enums.TornSelectionName>? defaultValue,
]) {
  if (tornSelectionName == null) {
    return defaultValue;
  }

  return tornSelectionName.map((e) => tornSelectionNameFromJson(e.toString())).toList();
}

String? personalStatsCategoryEnumNullableToJson(enums.PersonalStatsCategoryEnum? personalStatsCategoryEnum) {
  return personalStatsCategoryEnum?.value;
}

String? personalStatsCategoryEnumToJson(enums.PersonalStatsCategoryEnum personalStatsCategoryEnum) {
  return personalStatsCategoryEnum.value;
}

enums.PersonalStatsCategoryEnum personalStatsCategoryEnumFromJson(
  Object? personalStatsCategoryEnum, [
  enums.PersonalStatsCategoryEnum? defaultValue,
]) {
  return enums.PersonalStatsCategoryEnum.values.firstWhereOrNull((e) => e.value == personalStatsCategoryEnum) ??
      defaultValue ??
      enums.PersonalStatsCategoryEnum.swaggerGeneratedUnknown;
}

enums.PersonalStatsCategoryEnum? personalStatsCategoryEnumNullableFromJson(
  Object? personalStatsCategoryEnum, [
  enums.PersonalStatsCategoryEnum? defaultValue,
]) {
  if (personalStatsCategoryEnum == null) {
    return null;
  }
  return enums.PersonalStatsCategoryEnum.values.firstWhereOrNull((e) => e.value == personalStatsCategoryEnum) ??
      defaultValue;
}

String personalStatsCategoryEnumExplodedListToJson(List<enums.PersonalStatsCategoryEnum>? personalStatsCategoryEnum) {
  return personalStatsCategoryEnum?.map((e) => e.value!).join(',') ?? '';
}

List<String> personalStatsCategoryEnumListToJson(List<enums.PersonalStatsCategoryEnum>? personalStatsCategoryEnum) {
  if (personalStatsCategoryEnum == null) {
    return [];
  }

  return personalStatsCategoryEnum.map((e) => e.value!).toList();
}

List<enums.PersonalStatsCategoryEnum> personalStatsCategoryEnumListFromJson(
  List? personalStatsCategoryEnum, [
  List<enums.PersonalStatsCategoryEnum>? defaultValue,
]) {
  if (personalStatsCategoryEnum == null) {
    return defaultValue ?? [];
  }

  return personalStatsCategoryEnum.map((e) => personalStatsCategoryEnumFromJson(e.toString())).toList();
}

List<enums.PersonalStatsCategoryEnum>? personalStatsCategoryEnumNullableListFromJson(
  List? personalStatsCategoryEnum, [
  List<enums.PersonalStatsCategoryEnum>? defaultValue,
]) {
  if (personalStatsCategoryEnum == null) {
    return defaultValue;
  }

  return personalStatsCategoryEnum.map((e) => personalStatsCategoryEnumFromJson(e.toString())).toList();
}

String? personalStatsStatNameNullableToJson(enums.PersonalStatsStatName? personalStatsStatName) {
  return personalStatsStatName?.value;
}

String? personalStatsStatNameToJson(enums.PersonalStatsStatName personalStatsStatName) {
  return personalStatsStatName.value;
}

enums.PersonalStatsStatName personalStatsStatNameFromJson(
  Object? personalStatsStatName, [
  enums.PersonalStatsStatName? defaultValue,
]) {
  return enums.PersonalStatsStatName.values.firstWhereOrNull((e) => e.value == personalStatsStatName) ??
      defaultValue ??
      enums.PersonalStatsStatName.swaggerGeneratedUnknown;
}

enums.PersonalStatsStatName? personalStatsStatNameNullableFromJson(
  Object? personalStatsStatName, [
  enums.PersonalStatsStatName? defaultValue,
]) {
  if (personalStatsStatName == null) {
    return null;
  }
  return enums.PersonalStatsStatName.values.firstWhereOrNull((e) => e.value == personalStatsStatName) ?? defaultValue;
}

String personalStatsStatNameExplodedListToJson(List<enums.PersonalStatsStatName>? personalStatsStatName) {
  return personalStatsStatName?.map((e) => e.value!).join(',') ?? '';
}

List<String> personalStatsStatNameListToJson(List<enums.PersonalStatsStatName>? personalStatsStatName) {
  if (personalStatsStatName == null) {
    return [];
  }

  return personalStatsStatName.map((e) => e.value!).toList();
}

List<enums.PersonalStatsStatName> personalStatsStatNameListFromJson(
  List? personalStatsStatName, [
  List<enums.PersonalStatsStatName>? defaultValue,
]) {
  if (personalStatsStatName == null) {
    return defaultValue ?? [];
  }

  return personalStatsStatName.map((e) => personalStatsStatNameFromJson(e.toString())).toList();
}

List<enums.PersonalStatsStatName>? personalStatsStatNameNullableListFromJson(
  List? personalStatsStatName, [
  List<enums.PersonalStatsStatName>? defaultValue,
]) {
  if (personalStatsStatName == null) {
    return defaultValue;
  }

  return personalStatsStatName.map((e) => personalStatsStatNameFromJson(e.toString())).toList();
}

String? userItemMarkeListingItemDetailsRarityNullableToJson(
    enums.UserItemMarkeListingItemDetailsRarity? userItemMarkeListingItemDetailsRarity) {
  return userItemMarkeListingItemDetailsRarity?.value;
}

String? userItemMarkeListingItemDetailsRarityToJson(
    enums.UserItemMarkeListingItemDetailsRarity userItemMarkeListingItemDetailsRarity) {
  return userItemMarkeListingItemDetailsRarity.value;
}

enums.UserItemMarkeListingItemDetailsRarity userItemMarkeListingItemDetailsRarityFromJson(
  Object? userItemMarkeListingItemDetailsRarity, [
  enums.UserItemMarkeListingItemDetailsRarity? defaultValue,
]) {
  return enums.UserItemMarkeListingItemDetailsRarity.values
          .firstWhereOrNull((e) => e.value == userItemMarkeListingItemDetailsRarity) ??
      defaultValue ??
      enums.UserItemMarkeListingItemDetailsRarity.swaggerGeneratedUnknown;
}

enums.UserItemMarkeListingItemDetailsRarity? userItemMarkeListingItemDetailsRarityNullableFromJson(
  Object? userItemMarkeListingItemDetailsRarity, [
  enums.UserItemMarkeListingItemDetailsRarity? defaultValue,
]) {
  if (userItemMarkeListingItemDetailsRarity == null) {
    return null;
  }
  return enums.UserItemMarkeListingItemDetailsRarity.values
          .firstWhereOrNull((e) => e.value == userItemMarkeListingItemDetailsRarity) ??
      defaultValue;
}

String userItemMarkeListingItemDetailsRarityExplodedListToJson(
    List<enums.UserItemMarkeListingItemDetailsRarity>? userItemMarkeListingItemDetailsRarity) {
  return userItemMarkeListingItemDetailsRarity?.map((e) => e.value!).join(',') ?? '';
}

List<String> userItemMarkeListingItemDetailsRarityListToJson(
    List<enums.UserItemMarkeListingItemDetailsRarity>? userItemMarkeListingItemDetailsRarity) {
  if (userItemMarkeListingItemDetailsRarity == null) {
    return [];
  }

  return userItemMarkeListingItemDetailsRarity.map((e) => e.value!).toList();
}

List<enums.UserItemMarkeListingItemDetailsRarity> userItemMarkeListingItemDetailsRarityListFromJson(
  List? userItemMarkeListingItemDetailsRarity, [
  List<enums.UserItemMarkeListingItemDetailsRarity>? defaultValue,
]) {
  if (userItemMarkeListingItemDetailsRarity == null) {
    return defaultValue ?? [];
  }

  return userItemMarkeListingItemDetailsRarity
      .map((e) => userItemMarkeListingItemDetailsRarityFromJson(e.toString()))
      .toList();
}

List<enums.UserItemMarkeListingItemDetailsRarity>? userItemMarkeListingItemDetailsRarityNullableListFromJson(
  List? userItemMarkeListingItemDetailsRarity, [
  List<enums.UserItemMarkeListingItemDetailsRarity>? defaultValue,
]) {
  if (userItemMarkeListingItemDetailsRarity == null) {
    return defaultValue;
  }

  return userItemMarkeListingItemDetailsRarity
      .map((e) => userItemMarkeListingItemDetailsRarityFromJson(e.toString()))
      .toList();
}

String? userSelectionNameNullableToJson(enums.UserSelectionName? userSelectionName) {
  return userSelectionName?.value;
}

String? userSelectionNameToJson(enums.UserSelectionName userSelectionName) {
  return userSelectionName.value;
}

enums.UserSelectionName userSelectionNameFromJson(
  Object? userSelectionName, [
  enums.UserSelectionName? defaultValue,
]) {
  return enums.UserSelectionName.values.firstWhereOrNull((e) => e.value == userSelectionName) ??
      defaultValue ??
      enums.UserSelectionName.swaggerGeneratedUnknown;
}

enums.UserSelectionName? userSelectionNameNullableFromJson(
  Object? userSelectionName, [
  enums.UserSelectionName? defaultValue,
]) {
  if (userSelectionName == null) {
    return null;
  }
  return enums.UserSelectionName.values.firstWhereOrNull((e) => e.value == userSelectionName) ?? defaultValue;
}

String userSelectionNameExplodedListToJson(List<enums.UserSelectionName>? userSelectionName) {
  return userSelectionName?.map((e) => e.value!).join(',') ?? '';
}

List<String> userSelectionNameListToJson(List<enums.UserSelectionName>? userSelectionName) {
  if (userSelectionName == null) {
    return [];
  }

  return userSelectionName.map((e) => e.value!).toList();
}

List<enums.UserSelectionName> userSelectionNameListFromJson(
  List? userSelectionName, [
  List<enums.UserSelectionName>? defaultValue,
]) {
  if (userSelectionName == null) {
    return defaultValue ?? [];
  }

  return userSelectionName.map((e) => userSelectionNameFromJson(e.toString())).toList();
}

List<enums.UserSelectionName>? userSelectionNameNullableListFromJson(
  List? userSelectionName, [
  List<enums.UserSelectionName>? defaultValue,
]) {
  if (userSelectionName == null) {
    return defaultValue;
  }

  return userSelectionName.map((e) => userSelectionNameFromJson(e.toString())).toList();
}

String? apiSortNullableToJson(enums.ApiSort? apiSort) {
  return apiSort?.value;
}

String? apiSortToJson(enums.ApiSort apiSort) {
  return apiSort.value;
}

enums.ApiSort apiSortFromJson(
  Object? apiSort, [
  enums.ApiSort? defaultValue,
]) {
  return enums.ApiSort.values.firstWhereOrNull((e) => e.value == apiSort) ??
      defaultValue ??
      enums.ApiSort.swaggerGeneratedUnknown;
}

enums.ApiSort? apiSortNullableFromJson(
  Object? apiSort, [
  enums.ApiSort? defaultValue,
]) {
  if (apiSort == null) {
    return null;
  }
  return enums.ApiSort.values.firstWhereOrNull((e) => e.value == apiSort) ?? defaultValue;
}

String apiSortExplodedListToJson(List<enums.ApiSort>? apiSort) {
  return apiSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> apiSortListToJson(List<enums.ApiSort>? apiSort) {
  if (apiSort == null) {
    return [];
  }

  return apiSort.map((e) => e.value!).toList();
}

List<enums.ApiSort> apiSortListFromJson(
  List? apiSort, [
  List<enums.ApiSort>? defaultValue,
]) {
  if (apiSort == null) {
    return defaultValue ?? [];
  }

  return apiSort.map((e) => apiSortFromJson(e.toString())).toList();
}

List<enums.ApiSort>? apiSortNullableListFromJson(
  List? apiSort, [
  List<enums.ApiSort>? defaultValue,
]) {
  if (apiSort == null) {
    return defaultValue;
  }

  return apiSort.map((e) => apiSortFromJson(e.toString())).toList();
}

String? apiStripTagsTrueNullableToJson(enums.ApiStripTagsTrue? apiStripTagsTrue) {
  return apiStripTagsTrue?.value;
}

String? apiStripTagsTrueToJson(enums.ApiStripTagsTrue apiStripTagsTrue) {
  return apiStripTagsTrue.value;
}

enums.ApiStripTagsTrue apiStripTagsTrueFromJson(
  Object? apiStripTagsTrue, [
  enums.ApiStripTagsTrue? defaultValue,
]) {
  return enums.ApiStripTagsTrue.values.firstWhereOrNull((e) => e.value == apiStripTagsTrue) ??
      defaultValue ??
      enums.ApiStripTagsTrue.swaggerGeneratedUnknown;
}

enums.ApiStripTagsTrue? apiStripTagsTrueNullableFromJson(
  Object? apiStripTagsTrue, [
  enums.ApiStripTagsTrue? defaultValue,
]) {
  if (apiStripTagsTrue == null) {
    return null;
  }
  return enums.ApiStripTagsTrue.values.firstWhereOrNull((e) => e.value == apiStripTagsTrue) ?? defaultValue;
}

String apiStripTagsTrueExplodedListToJson(List<enums.ApiStripTagsTrue>? apiStripTagsTrue) {
  return apiStripTagsTrue?.map((e) => e.value!).join(',') ?? '';
}

List<String> apiStripTagsTrueListToJson(List<enums.ApiStripTagsTrue>? apiStripTagsTrue) {
  if (apiStripTagsTrue == null) {
    return [];
  }

  return apiStripTagsTrue.map((e) => e.value!).toList();
}

List<enums.ApiStripTagsTrue> apiStripTagsTrueListFromJson(
  List? apiStripTagsTrue, [
  List<enums.ApiStripTagsTrue>? defaultValue,
]) {
  if (apiStripTagsTrue == null) {
    return defaultValue ?? [];
  }

  return apiStripTagsTrue.map((e) => apiStripTagsTrueFromJson(e.toString())).toList();
}

List<enums.ApiStripTagsTrue>? apiStripTagsTrueNullableListFromJson(
  List? apiStripTagsTrue, [
  List<enums.ApiStripTagsTrue>? defaultValue,
]) {
  if (apiStripTagsTrue == null) {
    return defaultValue;
  }

  return apiStripTagsTrue.map((e) => apiStripTagsTrueFromJson(e.toString())).toList();
}

String? apiStripTagsFalseNullableToJson(enums.ApiStripTagsFalse? apiStripTagsFalse) {
  return apiStripTagsFalse?.value;
}

String? apiStripTagsFalseToJson(enums.ApiStripTagsFalse apiStripTagsFalse) {
  return apiStripTagsFalse.value;
}

enums.ApiStripTagsFalse apiStripTagsFalseFromJson(
  Object? apiStripTagsFalse, [
  enums.ApiStripTagsFalse? defaultValue,
]) {
  return enums.ApiStripTagsFalse.values.firstWhereOrNull((e) => e.value == apiStripTagsFalse) ??
      defaultValue ??
      enums.ApiStripTagsFalse.swaggerGeneratedUnknown;
}

enums.ApiStripTagsFalse? apiStripTagsFalseNullableFromJson(
  Object? apiStripTagsFalse, [
  enums.ApiStripTagsFalse? defaultValue,
]) {
  if (apiStripTagsFalse == null) {
    return null;
  }
  return enums.ApiStripTagsFalse.values.firstWhereOrNull((e) => e.value == apiStripTagsFalse) ?? defaultValue;
}

String apiStripTagsFalseExplodedListToJson(List<enums.ApiStripTagsFalse>? apiStripTagsFalse) {
  return apiStripTagsFalse?.map((e) => e.value!).join(',') ?? '';
}

List<String> apiStripTagsFalseListToJson(List<enums.ApiStripTagsFalse>? apiStripTagsFalse) {
  if (apiStripTagsFalse == null) {
    return [];
  }

  return apiStripTagsFalse.map((e) => e.value!).toList();
}

List<enums.ApiStripTagsFalse> apiStripTagsFalseListFromJson(
  List? apiStripTagsFalse, [
  List<enums.ApiStripTagsFalse>? defaultValue,
]) {
  if (apiStripTagsFalse == null) {
    return defaultValue ?? [];
  }

  return apiStripTagsFalse.map((e) => apiStripTagsFalseFromJson(e.toString())).toList();
}

List<enums.ApiStripTagsFalse>? apiStripTagsFalseNullableListFromJson(
  List? apiStripTagsFalse, [
  List<enums.ApiStripTagsFalse>? defaultValue,
]) {
  if (apiStripTagsFalse == null) {
    return defaultValue;
  }

  return apiStripTagsFalse.map((e) => apiStripTagsFalseFromJson(e.toString())).toList();
}

String? apiStripTagsNullableToJson(enums.ApiStripTags? apiStripTags) {
  return apiStripTags?.value;
}

String? apiStripTagsToJson(enums.ApiStripTags apiStripTags) {
  return apiStripTags.value;
}

enums.ApiStripTags apiStripTagsFromJson(
  Object? apiStripTags, [
  enums.ApiStripTags? defaultValue,
]) {
  return enums.ApiStripTags.values.firstWhereOrNull((e) => e.value == apiStripTags) ??
      defaultValue ??
      enums.ApiStripTags.swaggerGeneratedUnknown;
}

enums.ApiStripTags? apiStripTagsNullableFromJson(
  Object? apiStripTags, [
  enums.ApiStripTags? defaultValue,
]) {
  if (apiStripTags == null) {
    return null;
  }
  return enums.ApiStripTags.values.firstWhereOrNull((e) => e.value == apiStripTags) ?? defaultValue;
}

String apiStripTagsExplodedListToJson(List<enums.ApiStripTags>? apiStripTags) {
  return apiStripTags?.map((e) => e.value!).join(',') ?? '';
}

List<String> apiStripTagsListToJson(List<enums.ApiStripTags>? apiStripTags) {
  if (apiStripTags == null) {
    return [];
  }

  return apiStripTags.map((e) => e.value!).toList();
}

List<enums.ApiStripTags> apiStripTagsListFromJson(
  List? apiStripTags, [
  List<enums.ApiStripTags>? defaultValue,
]) {
  if (apiStripTags == null) {
    return defaultValue ?? [];
  }

  return apiStripTags.map((e) => apiStripTagsFromJson(e.toString())).toList();
}

List<enums.ApiStripTags>? apiStripTagsNullableListFromJson(
  List? apiStripTags, [
  List<enums.ApiStripTags>? defaultValue,
]) {
  if (apiStripTags == null) {
    return defaultValue;
  }

  return apiStripTags.map((e) => apiStripTagsFromJson(e.toString())).toList();
}

String? factionCrimesGetCatNullableToJson(enums.FactionCrimesGetCat? factionCrimesGetCat) {
  return factionCrimesGetCat?.value;
}

String? factionCrimesGetCatToJson(enums.FactionCrimesGetCat factionCrimesGetCat) {
  return factionCrimesGetCat.value;
}

enums.FactionCrimesGetCat factionCrimesGetCatFromJson(
  Object? factionCrimesGetCat, [
  enums.FactionCrimesGetCat? defaultValue,
]) {
  return enums.FactionCrimesGetCat.values.firstWhereOrNull((e) => e.value == factionCrimesGetCat) ??
      defaultValue ??
      enums.FactionCrimesGetCat.swaggerGeneratedUnknown;
}

enums.FactionCrimesGetCat? factionCrimesGetCatNullableFromJson(
  Object? factionCrimesGetCat, [
  enums.FactionCrimesGetCat? defaultValue,
]) {
  if (factionCrimesGetCat == null) {
    return null;
  }
  return enums.FactionCrimesGetCat.values.firstWhereOrNull((e) => e.value == factionCrimesGetCat) ?? defaultValue;
}

String factionCrimesGetCatExplodedListToJson(List<enums.FactionCrimesGetCat>? factionCrimesGetCat) {
  return factionCrimesGetCat?.map((e) => e.value!).join(',') ?? '';
}

List<String> factionCrimesGetCatListToJson(List<enums.FactionCrimesGetCat>? factionCrimesGetCat) {
  if (factionCrimesGetCat == null) {
    return [];
  }

  return factionCrimesGetCat.map((e) => e.value!).toList();
}

List<enums.FactionCrimesGetCat> factionCrimesGetCatListFromJson(
  List? factionCrimesGetCat, [
  List<enums.FactionCrimesGetCat>? defaultValue,
]) {
  if (factionCrimesGetCat == null) {
    return defaultValue ?? [];
  }

  return factionCrimesGetCat.map((e) => factionCrimesGetCatFromJson(e.toString())).toList();
}

List<enums.FactionCrimesGetCat>? factionCrimesGetCatNullableListFromJson(
  List? factionCrimesGetCat, [
  List<enums.FactionCrimesGetCat>? defaultValue,
]) {
  if (factionCrimesGetCat == null) {
    return defaultValue;
  }

  return factionCrimesGetCat.map((e) => factionCrimesGetCatFromJson(e.toString())).toList();
}

String? factionCrimesGetSortNullableToJson(enums.FactionCrimesGetSort? factionCrimesGetSort) {
  return factionCrimesGetSort?.value;
}

String? factionCrimesGetSortToJson(enums.FactionCrimesGetSort factionCrimesGetSort) {
  return factionCrimesGetSort.value;
}

enums.FactionCrimesGetSort factionCrimesGetSortFromJson(
  Object? factionCrimesGetSort, [
  enums.FactionCrimesGetSort? defaultValue,
]) {
  return enums.FactionCrimesGetSort.values.firstWhereOrNull((e) => e.value == factionCrimesGetSort) ??
      defaultValue ??
      enums.FactionCrimesGetSort.swaggerGeneratedUnknown;
}

enums.FactionCrimesGetSort? factionCrimesGetSortNullableFromJson(
  Object? factionCrimesGetSort, [
  enums.FactionCrimesGetSort? defaultValue,
]) {
  if (factionCrimesGetSort == null) {
    return null;
  }
  return enums.FactionCrimesGetSort.values.firstWhereOrNull((e) => e.value == factionCrimesGetSort) ?? defaultValue;
}

String factionCrimesGetSortExplodedListToJson(List<enums.FactionCrimesGetSort>? factionCrimesGetSort) {
  return factionCrimesGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> factionCrimesGetSortListToJson(List<enums.FactionCrimesGetSort>? factionCrimesGetSort) {
  if (factionCrimesGetSort == null) {
    return [];
  }

  return factionCrimesGetSort.map((e) => e.value!).toList();
}

List<enums.FactionCrimesGetSort> factionCrimesGetSortListFromJson(
  List? factionCrimesGetSort, [
  List<enums.FactionCrimesGetSort>? defaultValue,
]) {
  if (factionCrimesGetSort == null) {
    return defaultValue ?? [];
  }

  return factionCrimesGetSort.map((e) => factionCrimesGetSortFromJson(e.toString())).toList();
}

List<enums.FactionCrimesGetSort>? factionCrimesGetSortNullableListFromJson(
  List? factionCrimesGetSort, [
  List<enums.FactionCrimesGetSort>? defaultValue,
]) {
  if (factionCrimesGetSort == null) {
    return defaultValue;
  }

  return factionCrimesGetSort.map((e) => factionCrimesGetSortFromJson(e.toString())).toList();
}

String? factionGetSortNullableToJson(enums.FactionGetSort? factionGetSort) {
  return factionGetSort?.value;
}

String? factionGetSortToJson(enums.FactionGetSort factionGetSort) {
  return factionGetSort.value;
}

enums.FactionGetSort factionGetSortFromJson(
  Object? factionGetSort, [
  enums.FactionGetSort? defaultValue,
]) {
  return enums.FactionGetSort.values.firstWhereOrNull((e) => e.value == factionGetSort) ??
      defaultValue ??
      enums.FactionGetSort.swaggerGeneratedUnknown;
}

enums.FactionGetSort? factionGetSortNullableFromJson(
  Object? factionGetSort, [
  enums.FactionGetSort? defaultValue,
]) {
  if (factionGetSort == null) {
    return null;
  }
  return enums.FactionGetSort.values.firstWhereOrNull((e) => e.value == factionGetSort) ?? defaultValue;
}

String factionGetSortExplodedListToJson(List<enums.FactionGetSort>? factionGetSort) {
  return factionGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> factionGetSortListToJson(List<enums.FactionGetSort>? factionGetSort) {
  if (factionGetSort == null) {
    return [];
  }

  return factionGetSort.map((e) => e.value!).toList();
}

List<enums.FactionGetSort> factionGetSortListFromJson(
  List? factionGetSort, [
  List<enums.FactionGetSort>? defaultValue,
]) {
  if (factionGetSort == null) {
    return defaultValue ?? [];
  }

  return factionGetSort.map((e) => factionGetSortFromJson(e.toString())).toList();
}

List<enums.FactionGetSort>? factionGetSortNullableListFromJson(
  List? factionGetSort, [
  List<enums.FactionGetSort>? defaultValue,
]) {
  if (factionGetSort == null) {
    return defaultValue;
  }

  return factionGetSort.map((e) => factionGetSortFromJson(e.toString())).toList();
}

String? forumCategoryIdsThreadsGetSortNullableToJson(
    enums.ForumCategoryIdsThreadsGetSort? forumCategoryIdsThreadsGetSort) {
  return forumCategoryIdsThreadsGetSort?.value;
}

String? forumCategoryIdsThreadsGetSortToJson(enums.ForumCategoryIdsThreadsGetSort forumCategoryIdsThreadsGetSort) {
  return forumCategoryIdsThreadsGetSort.value;
}

enums.ForumCategoryIdsThreadsGetSort forumCategoryIdsThreadsGetSortFromJson(
  Object? forumCategoryIdsThreadsGetSort, [
  enums.ForumCategoryIdsThreadsGetSort? defaultValue,
]) {
  return enums.ForumCategoryIdsThreadsGetSort.values
          .firstWhereOrNull((e) => e.value == forumCategoryIdsThreadsGetSort) ??
      defaultValue ??
      enums.ForumCategoryIdsThreadsGetSort.swaggerGeneratedUnknown;
}

enums.ForumCategoryIdsThreadsGetSort? forumCategoryIdsThreadsGetSortNullableFromJson(
  Object? forumCategoryIdsThreadsGetSort, [
  enums.ForumCategoryIdsThreadsGetSort? defaultValue,
]) {
  if (forumCategoryIdsThreadsGetSort == null) {
    return null;
  }
  return enums.ForumCategoryIdsThreadsGetSort.values
          .firstWhereOrNull((e) => e.value == forumCategoryIdsThreadsGetSort) ??
      defaultValue;
}

String forumCategoryIdsThreadsGetSortExplodedListToJson(
    List<enums.ForumCategoryIdsThreadsGetSort>? forumCategoryIdsThreadsGetSort) {
  return forumCategoryIdsThreadsGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> forumCategoryIdsThreadsGetSortListToJson(
    List<enums.ForumCategoryIdsThreadsGetSort>? forumCategoryIdsThreadsGetSort) {
  if (forumCategoryIdsThreadsGetSort == null) {
    return [];
  }

  return forumCategoryIdsThreadsGetSort.map((e) => e.value!).toList();
}

List<enums.ForumCategoryIdsThreadsGetSort> forumCategoryIdsThreadsGetSortListFromJson(
  List? forumCategoryIdsThreadsGetSort, [
  List<enums.ForumCategoryIdsThreadsGetSort>? defaultValue,
]) {
  if (forumCategoryIdsThreadsGetSort == null) {
    return defaultValue ?? [];
  }

  return forumCategoryIdsThreadsGetSort.map((e) => forumCategoryIdsThreadsGetSortFromJson(e.toString())).toList();
}

List<enums.ForumCategoryIdsThreadsGetSort>? forumCategoryIdsThreadsGetSortNullableListFromJson(
  List? forumCategoryIdsThreadsGetSort, [
  List<enums.ForumCategoryIdsThreadsGetSort>? defaultValue,
]) {
  if (forumCategoryIdsThreadsGetSort == null) {
    return defaultValue;
  }

  return forumCategoryIdsThreadsGetSort.map((e) => forumCategoryIdsThreadsGetSortFromJson(e.toString())).toList();
}

String? forumThreadsGetSortNullableToJson(enums.ForumThreadsGetSort? forumThreadsGetSort) {
  return forumThreadsGetSort?.value;
}

String? forumThreadsGetSortToJson(enums.ForumThreadsGetSort forumThreadsGetSort) {
  return forumThreadsGetSort.value;
}

enums.ForumThreadsGetSort forumThreadsGetSortFromJson(
  Object? forumThreadsGetSort, [
  enums.ForumThreadsGetSort? defaultValue,
]) {
  return enums.ForumThreadsGetSort.values.firstWhereOrNull((e) => e.value == forumThreadsGetSort) ??
      defaultValue ??
      enums.ForumThreadsGetSort.swaggerGeneratedUnknown;
}

enums.ForumThreadsGetSort? forumThreadsGetSortNullableFromJson(
  Object? forumThreadsGetSort, [
  enums.ForumThreadsGetSort? defaultValue,
]) {
  if (forumThreadsGetSort == null) {
    return null;
  }
  return enums.ForumThreadsGetSort.values.firstWhereOrNull((e) => e.value == forumThreadsGetSort) ?? defaultValue;
}

String forumThreadsGetSortExplodedListToJson(List<enums.ForumThreadsGetSort>? forumThreadsGetSort) {
  return forumThreadsGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> forumThreadsGetSortListToJson(List<enums.ForumThreadsGetSort>? forumThreadsGetSort) {
  if (forumThreadsGetSort == null) {
    return [];
  }

  return forumThreadsGetSort.map((e) => e.value!).toList();
}

List<enums.ForumThreadsGetSort> forumThreadsGetSortListFromJson(
  List? forumThreadsGetSort, [
  List<enums.ForumThreadsGetSort>? defaultValue,
]) {
  if (forumThreadsGetSort == null) {
    return defaultValue ?? [];
  }

  return forumThreadsGetSort.map((e) => forumThreadsGetSortFromJson(e.toString())).toList();
}

List<enums.ForumThreadsGetSort>? forumThreadsGetSortNullableListFromJson(
  List? forumThreadsGetSort, [
  List<enums.ForumThreadsGetSort>? defaultValue,
]) {
  if (forumThreadsGetSort == null) {
    return defaultValue;
  }

  return forumThreadsGetSort.map((e) => forumThreadsGetSortFromJson(e.toString())).toList();
}

String? forumGetSortNullableToJson(enums.ForumGetSort? forumGetSort) {
  return forumGetSort?.value;
}

String? forumGetSortToJson(enums.ForumGetSort forumGetSort) {
  return forumGetSort.value;
}

enums.ForumGetSort forumGetSortFromJson(
  Object? forumGetSort, [
  enums.ForumGetSort? defaultValue,
]) {
  return enums.ForumGetSort.values.firstWhereOrNull((e) => e.value == forumGetSort) ??
      defaultValue ??
      enums.ForumGetSort.swaggerGeneratedUnknown;
}

enums.ForumGetSort? forumGetSortNullableFromJson(
  Object? forumGetSort, [
  enums.ForumGetSort? defaultValue,
]) {
  if (forumGetSort == null) {
    return null;
  }
  return enums.ForumGetSort.values.firstWhereOrNull((e) => e.value == forumGetSort) ?? defaultValue;
}

String forumGetSortExplodedListToJson(List<enums.ForumGetSort>? forumGetSort) {
  return forumGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> forumGetSortListToJson(List<enums.ForumGetSort>? forumGetSort) {
  if (forumGetSort == null) {
    return [];
  }

  return forumGetSort.map((e) => e.value!).toList();
}

List<enums.ForumGetSort> forumGetSortListFromJson(
  List? forumGetSort, [
  List<enums.ForumGetSort>? defaultValue,
]) {
  if (forumGetSort == null) {
    return defaultValue ?? [];
  }

  return forumGetSort.map((e) => forumGetSortFromJson(e.toString())).toList();
}

List<enums.ForumGetSort>? forumGetSortNullableListFromJson(
  List? forumGetSort, [
  List<enums.ForumGetSort>? defaultValue,
]) {
  if (forumGetSort == null) {
    return defaultValue;
  }

  return forumGetSort.map((e) => forumGetSortFromJson(e.toString())).toList();
}

String? marketGetSortNullableToJson(enums.MarketGetSort? marketGetSort) {
  return marketGetSort?.value;
}

String? marketGetSortToJson(enums.MarketGetSort marketGetSort) {
  return marketGetSort.value;
}

enums.MarketGetSort marketGetSortFromJson(
  Object? marketGetSort, [
  enums.MarketGetSort? defaultValue,
]) {
  return enums.MarketGetSort.values.firstWhereOrNull((e) => e.value == marketGetSort) ??
      defaultValue ??
      enums.MarketGetSort.swaggerGeneratedUnknown;
}

enums.MarketGetSort? marketGetSortNullableFromJson(
  Object? marketGetSort, [
  enums.MarketGetSort? defaultValue,
]) {
  if (marketGetSort == null) {
    return null;
  }
  return enums.MarketGetSort.values.firstWhereOrNull((e) => e.value == marketGetSort) ?? defaultValue;
}

String marketGetSortExplodedListToJson(List<enums.MarketGetSort>? marketGetSort) {
  return marketGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> marketGetSortListToJson(List<enums.MarketGetSort>? marketGetSort) {
  if (marketGetSort == null) {
    return [];
  }

  return marketGetSort.map((e) => e.value!).toList();
}

List<enums.MarketGetSort> marketGetSortListFromJson(
  List? marketGetSort, [
  List<enums.MarketGetSort>? defaultValue,
]) {
  if (marketGetSort == null) {
    return defaultValue ?? [];
  }

  return marketGetSort.map((e) => marketGetSortFromJson(e.toString())).toList();
}

List<enums.MarketGetSort>? marketGetSortNullableListFromJson(
  List? marketGetSort, [
  List<enums.MarketGetSort>? defaultValue,
]) {
  if (marketGetSort == null) {
    return defaultValue;
  }

  return marketGetSort.map((e) => marketGetSortFromJson(e.toString())).toList();
}

String? racingRacesGetSortNullableToJson(enums.RacingRacesGetSort? racingRacesGetSort) {
  return racingRacesGetSort?.value;
}

String? racingRacesGetSortToJson(enums.RacingRacesGetSort racingRacesGetSort) {
  return racingRacesGetSort.value;
}

enums.RacingRacesGetSort racingRacesGetSortFromJson(
  Object? racingRacesGetSort, [
  enums.RacingRacesGetSort? defaultValue,
]) {
  return enums.RacingRacesGetSort.values.firstWhereOrNull((e) => e.value == racingRacesGetSort) ??
      defaultValue ??
      enums.RacingRacesGetSort.swaggerGeneratedUnknown;
}

enums.RacingRacesGetSort? racingRacesGetSortNullableFromJson(
  Object? racingRacesGetSort, [
  enums.RacingRacesGetSort? defaultValue,
]) {
  if (racingRacesGetSort == null) {
    return null;
  }
  return enums.RacingRacesGetSort.values.firstWhereOrNull((e) => e.value == racingRacesGetSort) ?? defaultValue;
}

String racingRacesGetSortExplodedListToJson(List<enums.RacingRacesGetSort>? racingRacesGetSort) {
  return racingRacesGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> racingRacesGetSortListToJson(List<enums.RacingRacesGetSort>? racingRacesGetSort) {
  if (racingRacesGetSort == null) {
    return [];
  }

  return racingRacesGetSort.map((e) => e.value!).toList();
}

List<enums.RacingRacesGetSort> racingRacesGetSortListFromJson(
  List? racingRacesGetSort, [
  List<enums.RacingRacesGetSort>? defaultValue,
]) {
  if (racingRacesGetSort == null) {
    return defaultValue ?? [];
  }

  return racingRacesGetSort.map((e) => racingRacesGetSortFromJson(e.toString())).toList();
}

List<enums.RacingRacesGetSort>? racingRacesGetSortNullableListFromJson(
  List? racingRacesGetSort, [
  List<enums.RacingRacesGetSort>? defaultValue,
]) {
  if (racingRacesGetSort == null) {
    return defaultValue;
  }

  return racingRacesGetSort.map((e) => racingRacesGetSortFromJson(e.toString())).toList();
}

String? racingRacesGetCatNullableToJson(enums.RacingRacesGetCat? racingRacesGetCat) {
  return racingRacesGetCat?.value;
}

String? racingRacesGetCatToJson(enums.RacingRacesGetCat racingRacesGetCat) {
  return racingRacesGetCat.value;
}

enums.RacingRacesGetCat racingRacesGetCatFromJson(
  Object? racingRacesGetCat, [
  enums.RacingRacesGetCat? defaultValue,
]) {
  return enums.RacingRacesGetCat.values.firstWhereOrNull((e) => e.value == racingRacesGetCat) ??
      defaultValue ??
      enums.RacingRacesGetCat.swaggerGeneratedUnknown;
}

enums.RacingRacesGetCat? racingRacesGetCatNullableFromJson(
  Object? racingRacesGetCat, [
  enums.RacingRacesGetCat? defaultValue,
]) {
  if (racingRacesGetCat == null) {
    return null;
  }
  return enums.RacingRacesGetCat.values.firstWhereOrNull((e) => e.value == racingRacesGetCat) ?? defaultValue;
}

String racingRacesGetCatExplodedListToJson(List<enums.RacingRacesGetCat>? racingRacesGetCat) {
  return racingRacesGetCat?.map((e) => e.value!).join(',') ?? '';
}

List<String> racingRacesGetCatListToJson(List<enums.RacingRacesGetCat>? racingRacesGetCat) {
  if (racingRacesGetCat == null) {
    return [];
  }

  return racingRacesGetCat.map((e) => e.value!).toList();
}

List<enums.RacingRacesGetCat> racingRacesGetCatListFromJson(
  List? racingRacesGetCat, [
  List<enums.RacingRacesGetCat>? defaultValue,
]) {
  if (racingRacesGetCat == null) {
    return defaultValue ?? [];
  }

  return racingRacesGetCat.map((e) => racingRacesGetCatFromJson(e.toString())).toList();
}

List<enums.RacingRacesGetCat>? racingRacesGetCatNullableListFromJson(
  List? racingRacesGetCat, [
  List<enums.RacingRacesGetCat>? defaultValue,
]) {
  if (racingRacesGetCat == null) {
    return defaultValue;
  }

  return racingRacesGetCat.map((e) => racingRacesGetCatFromJson(e.toString())).toList();
}

String? racingGetSortNullableToJson(enums.RacingGetSort? racingGetSort) {
  return racingGetSort?.value;
}

String? racingGetSortToJson(enums.RacingGetSort racingGetSort) {
  return racingGetSort.value;
}

enums.RacingGetSort racingGetSortFromJson(
  Object? racingGetSort, [
  enums.RacingGetSort? defaultValue,
]) {
  return enums.RacingGetSort.values.firstWhereOrNull((e) => e.value == racingGetSort) ??
      defaultValue ??
      enums.RacingGetSort.swaggerGeneratedUnknown;
}

enums.RacingGetSort? racingGetSortNullableFromJson(
  Object? racingGetSort, [
  enums.RacingGetSort? defaultValue,
]) {
  if (racingGetSort == null) {
    return null;
  }
  return enums.RacingGetSort.values.firstWhereOrNull((e) => e.value == racingGetSort) ?? defaultValue;
}

String racingGetSortExplodedListToJson(List<enums.RacingGetSort>? racingGetSort) {
  return racingGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> racingGetSortListToJson(List<enums.RacingGetSort>? racingGetSort) {
  if (racingGetSort == null) {
    return [];
  }

  return racingGetSort.map((e) => e.value!).toList();
}

List<enums.RacingGetSort> racingGetSortListFromJson(
  List? racingGetSort, [
  List<enums.RacingGetSort>? defaultValue,
]) {
  if (racingGetSort == null) {
    return defaultValue ?? [];
  }

  return racingGetSort.map((e) => racingGetSortFromJson(e.toString())).toList();
}

List<enums.RacingGetSort>? racingGetSortNullableListFromJson(
  List? racingGetSort, [
  List<enums.RacingGetSort>? defaultValue,
]) {
  if (racingGetSort == null) {
    return defaultValue;
  }

  return racingGetSort.map((e) => racingGetSortFromJson(e.toString())).toList();
}

String? tornGetSortNullableToJson(enums.TornGetSort? tornGetSort) {
  return tornGetSort?.value;
}

String? tornGetSortToJson(enums.TornGetSort tornGetSort) {
  return tornGetSort.value;
}

enums.TornGetSort tornGetSortFromJson(
  Object? tornGetSort, [
  enums.TornGetSort? defaultValue,
]) {
  return enums.TornGetSort.values.firstWhereOrNull((e) => e.value == tornGetSort) ??
      defaultValue ??
      enums.TornGetSort.swaggerGeneratedUnknown;
}

enums.TornGetSort? tornGetSortNullableFromJson(
  Object? tornGetSort, [
  enums.TornGetSort? defaultValue,
]) {
  if (tornGetSort == null) {
    return null;
  }
  return enums.TornGetSort.values.firstWhereOrNull((e) => e.value == tornGetSort) ?? defaultValue;
}

String tornGetSortExplodedListToJson(List<enums.TornGetSort>? tornGetSort) {
  return tornGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> tornGetSortListToJson(List<enums.TornGetSort>? tornGetSort) {
  if (tornGetSort == null) {
    return [];
  }

  return tornGetSort.map((e) => e.value!).toList();
}

List<enums.TornGetSort> tornGetSortListFromJson(
  List? tornGetSort, [
  List<enums.TornGetSort>? defaultValue,
]) {
  if (tornGetSort == null) {
    return defaultValue ?? [];
  }

  return tornGetSort.map((e) => tornGetSortFromJson(e.toString())).toList();
}

List<enums.TornGetSort>? tornGetSortNullableListFromJson(
  List? tornGetSort, [
  List<enums.TornGetSort>? defaultValue,
]) {
  if (tornGetSort == null) {
    return defaultValue;
  }

  return tornGetSort.map((e) => tornGetSortFromJson(e.toString())).toList();
}

String? userRacesGetSortNullableToJson(enums.UserRacesGetSort? userRacesGetSort) {
  return userRacesGetSort?.value;
}

String? userRacesGetSortToJson(enums.UserRacesGetSort userRacesGetSort) {
  return userRacesGetSort.value;
}

enums.UserRacesGetSort userRacesGetSortFromJson(
  Object? userRacesGetSort, [
  enums.UserRacesGetSort? defaultValue,
]) {
  return enums.UserRacesGetSort.values.firstWhereOrNull((e) => e.value == userRacesGetSort) ??
      defaultValue ??
      enums.UserRacesGetSort.swaggerGeneratedUnknown;
}

enums.UserRacesGetSort? userRacesGetSortNullableFromJson(
  Object? userRacesGetSort, [
  enums.UserRacesGetSort? defaultValue,
]) {
  if (userRacesGetSort == null) {
    return null;
  }
  return enums.UserRacesGetSort.values.firstWhereOrNull((e) => e.value == userRacesGetSort) ?? defaultValue;
}

String userRacesGetSortExplodedListToJson(List<enums.UserRacesGetSort>? userRacesGetSort) {
  return userRacesGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> userRacesGetSortListToJson(List<enums.UserRacesGetSort>? userRacesGetSort) {
  if (userRacesGetSort == null) {
    return [];
  }

  return userRacesGetSort.map((e) => e.value!).toList();
}

List<enums.UserRacesGetSort> userRacesGetSortListFromJson(
  List? userRacesGetSort, [
  List<enums.UserRacesGetSort>? defaultValue,
]) {
  if (userRacesGetSort == null) {
    return defaultValue ?? [];
  }

  return userRacesGetSort.map((e) => userRacesGetSortFromJson(e.toString())).toList();
}

List<enums.UserRacesGetSort>? userRacesGetSortNullableListFromJson(
  List? userRacesGetSort, [
  List<enums.UserRacesGetSort>? defaultValue,
]) {
  if (userRacesGetSort == null) {
    return defaultValue;
  }

  return userRacesGetSort.map((e) => userRacesGetSortFromJson(e.toString())).toList();
}

String? userRacesGetCatNullableToJson(enums.UserRacesGetCat? userRacesGetCat) {
  return userRacesGetCat?.value;
}

String? userRacesGetCatToJson(enums.UserRacesGetCat userRacesGetCat) {
  return userRacesGetCat.value;
}

enums.UserRacesGetCat userRacesGetCatFromJson(
  Object? userRacesGetCat, [
  enums.UserRacesGetCat? defaultValue,
]) {
  return enums.UserRacesGetCat.values.firstWhereOrNull((e) => e.value == userRacesGetCat) ??
      defaultValue ??
      enums.UserRacesGetCat.swaggerGeneratedUnknown;
}

enums.UserRacesGetCat? userRacesGetCatNullableFromJson(
  Object? userRacesGetCat, [
  enums.UserRacesGetCat? defaultValue,
]) {
  if (userRacesGetCat == null) {
    return null;
  }
  return enums.UserRacesGetCat.values.firstWhereOrNull((e) => e.value == userRacesGetCat) ?? defaultValue;
}

String userRacesGetCatExplodedListToJson(List<enums.UserRacesGetCat>? userRacesGetCat) {
  return userRacesGetCat?.map((e) => e.value!).join(',') ?? '';
}

List<String> userRacesGetCatListToJson(List<enums.UserRacesGetCat>? userRacesGetCat) {
  if (userRacesGetCat == null) {
    return [];
  }

  return userRacesGetCat.map((e) => e.value!).toList();
}

List<enums.UserRacesGetCat> userRacesGetCatListFromJson(
  List? userRacesGetCat, [
  List<enums.UserRacesGetCat>? defaultValue,
]) {
  if (userRacesGetCat == null) {
    return defaultValue ?? [];
  }

  return userRacesGetCat.map((e) => userRacesGetCatFromJson(e.toString())).toList();
}

List<enums.UserRacesGetCat>? userRacesGetCatNullableListFromJson(
  List? userRacesGetCat, [
  List<enums.UserRacesGetCat>? defaultValue,
]) {
  if (userRacesGetCat == null) {
    return defaultValue;
  }

  return userRacesGetCat.map((e) => userRacesGetCatFromJson(e.toString())).toList();
}

String? userIdForumpostsGetSortNullableToJson(enums.UserIdForumpostsGetSort? userIdForumpostsGetSort) {
  return userIdForumpostsGetSort?.value;
}

String? userIdForumpostsGetSortToJson(enums.UserIdForumpostsGetSort userIdForumpostsGetSort) {
  return userIdForumpostsGetSort.value;
}

enums.UserIdForumpostsGetSort userIdForumpostsGetSortFromJson(
  Object? userIdForumpostsGetSort, [
  enums.UserIdForumpostsGetSort? defaultValue,
]) {
  return enums.UserIdForumpostsGetSort.values.firstWhereOrNull((e) => e.value == userIdForumpostsGetSort) ??
      defaultValue ??
      enums.UserIdForumpostsGetSort.swaggerGeneratedUnknown;
}

enums.UserIdForumpostsGetSort? userIdForumpostsGetSortNullableFromJson(
  Object? userIdForumpostsGetSort, [
  enums.UserIdForumpostsGetSort? defaultValue,
]) {
  if (userIdForumpostsGetSort == null) {
    return null;
  }
  return enums.UserIdForumpostsGetSort.values.firstWhereOrNull((e) => e.value == userIdForumpostsGetSort) ??
      defaultValue;
}

String userIdForumpostsGetSortExplodedListToJson(List<enums.UserIdForumpostsGetSort>? userIdForumpostsGetSort) {
  return userIdForumpostsGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> userIdForumpostsGetSortListToJson(List<enums.UserIdForumpostsGetSort>? userIdForumpostsGetSort) {
  if (userIdForumpostsGetSort == null) {
    return [];
  }

  return userIdForumpostsGetSort.map((e) => e.value!).toList();
}

List<enums.UserIdForumpostsGetSort> userIdForumpostsGetSortListFromJson(
  List? userIdForumpostsGetSort, [
  List<enums.UserIdForumpostsGetSort>? defaultValue,
]) {
  if (userIdForumpostsGetSort == null) {
    return defaultValue ?? [];
  }

  return userIdForumpostsGetSort.map((e) => userIdForumpostsGetSortFromJson(e.toString())).toList();
}

List<enums.UserIdForumpostsGetSort>? userIdForumpostsGetSortNullableListFromJson(
  List? userIdForumpostsGetSort, [
  List<enums.UserIdForumpostsGetSort>? defaultValue,
]) {
  if (userIdForumpostsGetSort == null) {
    return defaultValue;
  }

  return userIdForumpostsGetSort.map((e) => userIdForumpostsGetSortFromJson(e.toString())).toList();
}

String? userForumpostsGetSortNullableToJson(enums.UserForumpostsGetSort? userForumpostsGetSort) {
  return userForumpostsGetSort?.value;
}

String? userForumpostsGetSortToJson(enums.UserForumpostsGetSort userForumpostsGetSort) {
  return userForumpostsGetSort.value;
}

enums.UserForumpostsGetSort userForumpostsGetSortFromJson(
  Object? userForumpostsGetSort, [
  enums.UserForumpostsGetSort? defaultValue,
]) {
  return enums.UserForumpostsGetSort.values.firstWhereOrNull((e) => e.value == userForumpostsGetSort) ??
      defaultValue ??
      enums.UserForumpostsGetSort.swaggerGeneratedUnknown;
}

enums.UserForumpostsGetSort? userForumpostsGetSortNullableFromJson(
  Object? userForumpostsGetSort, [
  enums.UserForumpostsGetSort? defaultValue,
]) {
  if (userForumpostsGetSort == null) {
    return null;
  }
  return enums.UserForumpostsGetSort.values.firstWhereOrNull((e) => e.value == userForumpostsGetSort) ?? defaultValue;
}

String userForumpostsGetSortExplodedListToJson(List<enums.UserForumpostsGetSort>? userForumpostsGetSort) {
  return userForumpostsGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> userForumpostsGetSortListToJson(List<enums.UserForumpostsGetSort>? userForumpostsGetSort) {
  if (userForumpostsGetSort == null) {
    return [];
  }

  return userForumpostsGetSort.map((e) => e.value!).toList();
}

List<enums.UserForumpostsGetSort> userForumpostsGetSortListFromJson(
  List? userForumpostsGetSort, [
  List<enums.UserForumpostsGetSort>? defaultValue,
]) {
  if (userForumpostsGetSort == null) {
    return defaultValue ?? [];
  }

  return userForumpostsGetSort.map((e) => userForumpostsGetSortFromJson(e.toString())).toList();
}

List<enums.UserForumpostsGetSort>? userForumpostsGetSortNullableListFromJson(
  List? userForumpostsGetSort, [
  List<enums.UserForumpostsGetSort>? defaultValue,
]) {
  if (userForumpostsGetSort == null) {
    return defaultValue;
  }

  return userForumpostsGetSort.map((e) => userForumpostsGetSortFromJson(e.toString())).toList();
}

String? userIdForumthreadsGetSortNullableToJson(enums.UserIdForumthreadsGetSort? userIdForumthreadsGetSort) {
  return userIdForumthreadsGetSort?.value;
}

String? userIdForumthreadsGetSortToJson(enums.UserIdForumthreadsGetSort userIdForumthreadsGetSort) {
  return userIdForumthreadsGetSort.value;
}

enums.UserIdForumthreadsGetSort userIdForumthreadsGetSortFromJson(
  Object? userIdForumthreadsGetSort, [
  enums.UserIdForumthreadsGetSort? defaultValue,
]) {
  return enums.UserIdForumthreadsGetSort.values.firstWhereOrNull((e) => e.value == userIdForumthreadsGetSort) ??
      defaultValue ??
      enums.UserIdForumthreadsGetSort.swaggerGeneratedUnknown;
}

enums.UserIdForumthreadsGetSort? userIdForumthreadsGetSortNullableFromJson(
  Object? userIdForumthreadsGetSort, [
  enums.UserIdForumthreadsGetSort? defaultValue,
]) {
  if (userIdForumthreadsGetSort == null) {
    return null;
  }
  return enums.UserIdForumthreadsGetSort.values.firstWhereOrNull((e) => e.value == userIdForumthreadsGetSort) ??
      defaultValue;
}

String userIdForumthreadsGetSortExplodedListToJson(List<enums.UserIdForumthreadsGetSort>? userIdForumthreadsGetSort) {
  return userIdForumthreadsGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> userIdForumthreadsGetSortListToJson(List<enums.UserIdForumthreadsGetSort>? userIdForumthreadsGetSort) {
  if (userIdForumthreadsGetSort == null) {
    return [];
  }

  return userIdForumthreadsGetSort.map((e) => e.value!).toList();
}

List<enums.UserIdForumthreadsGetSort> userIdForumthreadsGetSortListFromJson(
  List? userIdForumthreadsGetSort, [
  List<enums.UserIdForumthreadsGetSort>? defaultValue,
]) {
  if (userIdForumthreadsGetSort == null) {
    return defaultValue ?? [];
  }

  return userIdForumthreadsGetSort.map((e) => userIdForumthreadsGetSortFromJson(e.toString())).toList();
}

List<enums.UserIdForumthreadsGetSort>? userIdForumthreadsGetSortNullableListFromJson(
  List? userIdForumthreadsGetSort, [
  List<enums.UserIdForumthreadsGetSort>? defaultValue,
]) {
  if (userIdForumthreadsGetSort == null) {
    return defaultValue;
  }

  return userIdForumthreadsGetSort.map((e) => userIdForumthreadsGetSortFromJson(e.toString())).toList();
}

String? userForumthreadsGetSortNullableToJson(enums.UserForumthreadsGetSort? userForumthreadsGetSort) {
  return userForumthreadsGetSort?.value;
}

String? userForumthreadsGetSortToJson(enums.UserForumthreadsGetSort userForumthreadsGetSort) {
  return userForumthreadsGetSort.value;
}

enums.UserForumthreadsGetSort userForumthreadsGetSortFromJson(
  Object? userForumthreadsGetSort, [
  enums.UserForumthreadsGetSort? defaultValue,
]) {
  return enums.UserForumthreadsGetSort.values.firstWhereOrNull((e) => e.value == userForumthreadsGetSort) ??
      defaultValue ??
      enums.UserForumthreadsGetSort.swaggerGeneratedUnknown;
}

enums.UserForumthreadsGetSort? userForumthreadsGetSortNullableFromJson(
  Object? userForumthreadsGetSort, [
  enums.UserForumthreadsGetSort? defaultValue,
]) {
  if (userForumthreadsGetSort == null) {
    return null;
  }
  return enums.UserForumthreadsGetSort.values.firstWhereOrNull((e) => e.value == userForumthreadsGetSort) ??
      defaultValue;
}

String userForumthreadsGetSortExplodedListToJson(List<enums.UserForumthreadsGetSort>? userForumthreadsGetSort) {
  return userForumthreadsGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> userForumthreadsGetSortListToJson(List<enums.UserForumthreadsGetSort>? userForumthreadsGetSort) {
  if (userForumthreadsGetSort == null) {
    return [];
  }

  return userForumthreadsGetSort.map((e) => e.value!).toList();
}

List<enums.UserForumthreadsGetSort> userForumthreadsGetSortListFromJson(
  List? userForumthreadsGetSort, [
  List<enums.UserForumthreadsGetSort>? defaultValue,
]) {
  if (userForumthreadsGetSort == null) {
    return defaultValue ?? [];
  }

  return userForumthreadsGetSort.map((e) => userForumthreadsGetSortFromJson(e.toString())).toList();
}

List<enums.UserForumthreadsGetSort>? userForumthreadsGetSortNullableListFromJson(
  List? userForumthreadsGetSort, [
  List<enums.UserForumthreadsGetSort>? defaultValue,
]) {
  if (userForumthreadsGetSort == null) {
    return defaultValue;
  }

  return userForumthreadsGetSort.map((e) => userForumthreadsGetSortFromJson(e.toString())).toList();
}

String? userGetSortNullableToJson(enums.UserGetSort? userGetSort) {
  return userGetSort?.value;
}

String? userGetSortToJson(enums.UserGetSort userGetSort) {
  return userGetSort.value;
}

enums.UserGetSort userGetSortFromJson(
  Object? userGetSort, [
  enums.UserGetSort? defaultValue,
]) {
  return enums.UserGetSort.values.firstWhereOrNull((e) => e.value == userGetSort) ??
      defaultValue ??
      enums.UserGetSort.swaggerGeneratedUnknown;
}

enums.UserGetSort? userGetSortNullableFromJson(
  Object? userGetSort, [
  enums.UserGetSort? defaultValue,
]) {
  if (userGetSort == null) {
    return null;
  }
  return enums.UserGetSort.values.firstWhereOrNull((e) => e.value == userGetSort) ?? defaultValue;
}

String userGetSortExplodedListToJson(List<enums.UserGetSort>? userGetSort) {
  return userGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> userGetSortListToJson(List<enums.UserGetSort>? userGetSort) {
  if (userGetSort == null) {
    return [];
  }

  return userGetSort.map((e) => e.value!).toList();
}

List<enums.UserGetSort> userGetSortListFromJson(
  List? userGetSort, [
  List<enums.UserGetSort>? defaultValue,
]) {
  if (userGetSort == null) {
    return defaultValue ?? [];
  }

  return userGetSort.map((e) => userGetSortFromJson(e.toString())).toList();
}

List<enums.UserGetSort>? userGetSortNullableListFromJson(
  List? userGetSort, [
  List<enums.UserGetSort>? defaultValue,
]) {
  if (userGetSort == null) {
    return defaultValue;
  }

  return userGetSort.map((e) => userGetSortFromJson(e.toString())).toList();
}

typedef $JsonFactory<T> = T Function(Map<String, dynamic> json);

class $CustomJsonDecoder {
  $CustomJsonDecoder(this.factories);

  final Map<Type, $JsonFactory> factories;

  dynamic decode<T>(dynamic entity) {
    if (entity is Iterable) {
      return _decodeList<T>(entity);
    }

    if (entity is T) {
      return entity;
    }

    if (isTypeOf<T, Map>()) {
      return entity;
    }

    if (isTypeOf<T, Iterable>()) {
      return entity;
    }

    if (entity is Map<String, dynamic>) {
      return _decodeMap<T>(entity);
    }

    return entity;
  }

  T _decodeMap<T>(Map<String, dynamic> values) {
    final jsonFactory = factories[T];
    if (jsonFactory == null || jsonFactory is! $JsonFactory<T>) {
      return throw "Could not find factory for type $T. Is '$T: $T.fromJsonFactory' included in the CustomJsonDecoder instance creation in bootstrapper.dart?";
    }

    return jsonFactory(values);
  }

  List<T> _decodeList<T>(Iterable values) => values.where((v) => v != null).map<T>((v) => decode<T>(v) as T).toList();
}

class $JsonSerializableConverter extends chopper.JsonConverter {
  @override
  FutureOr<chopper.Response<ResultType>> convertResponse<ResultType, Item>(chopper.Response response) async {
    if (response.bodyString.isEmpty) {
      // In rare cases, when let's say 204 (no content) is returned -
      // we cannot decode the missing json with the result type specified
      return chopper.Response(response.base, null, error: response.error);
    }

    if (ResultType == String) {
      return response.copyWith();
    }

    if (ResultType == DateTime) {
      return response.copyWith(body: DateTime.parse((response.body as String).replaceAll('"', '')) as ResultType);
    }

    final jsonRes = await super.convertResponse(response);
    return jsonRes.copyWith<ResultType>(body: $jsonDecoder.decode<Item>(jsonRes.body) as ResultType);
  }
}

final $jsonDecoder = $CustomJsonDecoder(generatedMapping);

// ignore: unused_element
String? _dateToJson(DateTime? date) {
  if (date == null) {
    return null;
  }

  final year = date.year.toString();
  final month = date.month < 10 ? '0${date.month}' : date.month.toString();
  final day = date.day < 10 ? '0${date.day}' : date.day.toString();

  return '$year-$month-$day';
}

class Wrapped<T> {
  final T value;
  const Wrapped.value(this.value);
}
