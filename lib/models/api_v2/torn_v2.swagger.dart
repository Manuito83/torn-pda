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
  ///@param key API key (Public)
  ///@param id Faction id
  Future<chopper.Response<FactionHofResponse>> factionIdHofGet({
    required String? key,
    required int? id,
  }) {
    generatedMapping.putIfAbsent(FactionHofResponse, () => FactionHofResponse.fromJsonFactory);

    return _factionIdHofGet(key: key, id: id);
  }

  ///Get a faction's hall of fame rankings.
  ///@param key API key (Public)
  ///@param id Faction id
  @Get(path: '/faction/{id}/hof')
  Future<chopper.Response<FactionHofResponse>> _factionIdHofGet({
    @Query('key') required String? key,
    @Path('id') required int? id,
  });

  ///Get your faction's hall of fame rankings.
  ///@param key API key (Public)
  Future<chopper.Response<FactionHofResponse>> factionHofGet({required String? key}) {
    generatedMapping.putIfAbsent(FactionHofResponse, () => FactionHofResponse.fromJsonFactory);

    return _factionHofGet(key: key);
  }

  ///Get your faction's hall of fame rankings.
  ///@param key API key (Public)
  @Get(path: '/faction/hof')
  Future<chopper.Response<FactionHofResponse>> _factionHofGet({@Query('key') required String? key});

  ///Get a list of a faction's members
  ///@param key API key (Public)
  ///@param id Faction id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  Future<chopper.Response<FactionMembersResponse>> factionIdMembersGet({
    required String? key,
    required int? id,
    enums.ApiStripTagsTrue? striptags,
  }) {
    generatedMapping.putIfAbsent(FactionMembersResponse, () => FactionMembersResponse.fromJsonFactory);

    return _factionIdMembersGet(key: key, id: id, striptags: striptags?.value?.toString());
  }

  ///Get a list of a faction's members
  ///@param key API key (Public)
  ///@param id Faction id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  @Get(path: '/faction/{id}/members')
  Future<chopper.Response<FactionMembersResponse>> _factionIdMembersGet({
    @Query('key') required String? key,
    @Path('id') required int? id,
    @Query('striptags') String? striptags,
  });

  ///Get a list of your faction's members
  ///@param key API key (Public)
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  Future<chopper.Response<FactionMembersResponse>> factionMembersGet({
    required String? key,
    enums.ApiStripTagsTrue? striptags,
  }) {
    generatedMapping.putIfAbsent(FactionMembersResponse, () => FactionMembersResponse.fromJsonFactory);

    return _factionMembersGet(key: key, striptags: striptags?.value?.toString());
  }

  ///Get a list of your faction's members
  ///@param key API key (Public)
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  @Get(path: '/faction/members')
  Future<chopper.Response<FactionMembersResponse>> _factionMembersGet({
    @Query('key') required String? key,
    @Query('striptags') String? striptags,
  });

  ///Get a faction's basic details
  ///@param key API key (Public)
  ///@param id Faction id
  Future<chopper.Response<FactionBasicResponse>> factionIdBasicGet({
    required String? key,
    required int? id,
  }) {
    generatedMapping.putIfAbsent(FactionBasicResponse, () => FactionBasicResponse.fromJsonFactory);

    return _factionIdBasicGet(key: key, id: id);
  }

  ///Get a faction's basic details
  ///@param key API key (Public)
  ///@param id Faction id
  @Get(path: '/faction/{id}/basic')
  Future<chopper.Response<FactionBasicResponse>> _factionIdBasicGet({
    @Query('key') required String? key,
    @Path('id') required int? id,
  });

  ///Get your faction's basic details
  ///@param key API key (Public)
  Future<chopper.Response<FactionBasicResponse>> factionBasicGet({required String? key}) {
    generatedMapping.putIfAbsent(FactionBasicResponse, () => FactionBasicResponse.fromJsonFactory);

    return _factionBasicGet(key: key);
  }

  ///Get your faction's basic details
  ///@param key API key (Public)
  @Get(path: '/faction/basic')
  Future<chopper.Response<FactionBasicResponse>> _factionBasicGet({@Query('key') required String? key});

  ///Get a faction's wars & pacts details
  ///@param key API key (Public)
  ///@param id Faction id
  Future<chopper.Response<FactionWarsResponse>> factionIdWarsGet({
    required String? key,
    required int? id,
  }) {
    generatedMapping.putIfAbsent(FactionWarsResponse, () => FactionWarsResponse.fromJsonFactory);

    return _factionIdWarsGet(key: key, id: id);
  }

  ///Get a faction's wars & pacts details
  ///@param key API key (Public)
  ///@param id Faction id
  @Get(path: '/faction/{id}/wars')
  Future<chopper.Response<FactionWarsResponse>> _factionIdWarsGet({
    @Query('key') required String? key,
    @Path('id') required int? id,
  });

  ///Get your faction's wars & pacts details
  ///@param key API key (Public)
  Future<chopper.Response<FactionWarsResponse>> factionWarsGet({required String? key}) {
    generatedMapping.putIfAbsent(FactionWarsResponse, () => FactionWarsResponse.fromJsonFactory);

    return _factionWarsGet(key: key);
  }

  ///Get your faction's wars & pacts details
  ///@param key API key (Public)
  @Get(path: '/faction/wars')
  Future<chopper.Response<FactionWarsResponse>> _factionWarsGet({@Query('key') required String? key});

  ///Get your faction's news details
  ///@param key API key (Minimal)
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  ///@param cat News category type
  Future<chopper.Response<FactionNewsResponse>> factionNewsGet({
    required String? key,
    enums.ApiStripTagsFalse? striptags,
    int? limit,
    enums.ApiSort? sort,
    int? to,
    int? from,
    required enums.FactionNewsCategory? cat,
  }) {
    generatedMapping.putIfAbsent(FactionNewsResponse, () => FactionNewsResponse.fromJsonFactory);

    return _factionNewsGet(
        key: key,
        striptags: striptags?.value?.toString(),
        limit: limit,
        sort: sort?.value?.toString(),
        to: to,
        from: from,
        cat: cat?.value?.toString());
  }

  ///Get your faction's news details
  ///@param key API key (Minimal)
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  ///@param cat News category type
  @Get(path: '/faction/news')
  Future<chopper.Response<FactionNewsResponse>> _factionNewsGet({
    @Query('key') required String? key,
    @Query('striptags') String? striptags,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') required String? cat,
  });

  ///Get your faction's detailed attacks
  ///@param key API key (Limited)
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  Future<chopper.Response<FactionAttacksResponse>> factionAttacksGet({
    required String? key,
    int? limit,
    enums.ApiSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(FactionAttacksResponse, () => FactionAttacksResponse.fromJsonFactory);

    return _factionAttacksGet(key: key, limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get your faction's detailed attacks
  ///@param key API key (Limited)
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  @Get(path: '/faction/attacks')
  Future<chopper.Response<FactionAttacksResponse>> _factionAttacksGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get your faction's attacks
  ///@param key API key (Limited)
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  Future<chopper.Response<FactionAttacksFullResponse>> factionAttacksfullGet({
    required String? key,
    int? limit,
    enums.ApiSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(FactionAttacksFullResponse, () => FactionAttacksFullResponse.fromJsonFactory);

    return _factionAttacksfullGet(key: key, limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get your faction's attacks
  ///@param key API key (Limited)
  ///@param limit
  ///@param sort Sorted by the greatest timestamps
  ///@param to Timestamp that sets the upper limit for the data returned. Data returned will be up to and including this time
  ///@param from Timestamp that sets the lower limit for the data returned. Data returned will be after this time
  @Get(path: '/faction/attacksfull')
  Future<chopper.Response<FactionAttacksFullResponse>> _factionAttacksfullGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get your faction's applications
  ///@param key API key (Minimal)
  Future<chopper.Response<FactionApplicationsResponse>> factionApplicationsGet({required String? key}) {
    generatedMapping.putIfAbsent(FactionApplicationsResponse, () => FactionApplicationsResponse.fromJsonFactory);

    return _factionApplicationsGet(key: key);
  }

  ///Get your faction's applications
  ///@param key API key (Minimal)
  @Get(path: '/faction/applications')
  Future<chopper.Response<FactionApplicationsResponse>> _factionApplicationsGet({@Query('key') required String? key});

  ///Get all available faction selections
  ///@param key API key (Public)
  Future<chopper.Response<FactionLookupResponse>> factionLookupGet({required String? key}) {
    generatedMapping.putIfAbsent(FactionLookupResponse, () => FactionLookupResponse.fromJsonFactory);

    return _factionLookupGet(key: key);
  }

  ///Get all available faction selections
  ///@param key API key (Public)
  @Get(path: '/faction/lookup')
  Future<chopper.Response<FactionLookupResponse>> _factionLookupGet({@Query('key') required String? key});

  ///Get current server time
  ///@param key API key (Public)
  Future<chopper.Response<TimestampResponse>> factionTimestampGet({required String? key}) {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _factionTimestampGet(key: key);
  }

  ///Get current server time
  ///@param key API key (Public)
  @Get(path: '/faction/timestamp')
  Future<chopper.Response<TimestampResponse>> _factionTimestampGet({@Query('key') required String? key});

  ///Get any Faction selection
  ///@param key API key (Public)
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
    required String? key,
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
        key: key,
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
  ///@param key API key (Public)
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param sort Direction to sort rows in
  ///@param offset
  @Get(path: '/faction')
  Future<chopper.Response> _factionGet({
    @Query('key') required String? key,
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
  ///@param key API key (Public)
  Future<chopper.Response<ForumCategoriesResponse>> forumCategoriesGet({required String? key}) {
    generatedMapping.putIfAbsent(ForumCategoriesResponse, () => ForumCategoriesResponse.fromJsonFactory);

    return _forumCategoriesGet(key: key);
  }

  ///Get publicly available forum categories
  ///@param key API key (Public)
  @Get(path: '/forum/categories')
  Future<chopper.Response<ForumCategoriesResponse>> _forumCategoriesGet({@Query('key') required String? key});

  ///Get threads for specific public forum category or categories
  ///@param key API key (Public)
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  ///@param categoryIds Category id or a list of category ids (comma separated)
  Future<chopper.Response<ForumThreadsResponse>> forumCategoryIdsThreadsGet({
    required String? key,
    int? limit,
    enums.ForumCategoryIdsThreadsGetSort? sort,
    int? to,
    int? from,
    required List<int>? categoryIds,
  }) {
    generatedMapping.putIfAbsent(ForumThreadsResponse, () => ForumThreadsResponse.fromJsonFactory);

    return _forumCategoryIdsThreadsGet(
        key: key, limit: limit, sort: sort?.value?.toString(), to: to, from: from, categoryIds: categoryIds);
  }

  ///Get threads for specific public forum category or categories
  ///@param key API key (Public)
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  ///@param categoryIds Category id or a list of category ids (comma separated)
  @Get(path: '/forum/{categoryIds}/threads')
  Future<chopper.Response<ForumThreadsResponse>> _forumCategoryIdsThreadsGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
    @Path('categoryIds') required List<int>? categoryIds,
  });

  ///Get threads across all forum categories
  ///@param key API key (Public)
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  Future<chopper.Response<ForumThreadsResponse>> forumThreadsGet({
    required String? key,
    int? limit,
    enums.ForumThreadsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(ForumThreadsResponse, () => ForumThreadsResponse.fromJsonFactory);

    return _forumThreadsGet(key: key, limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get threads across all forum categories
  ///@param key API key (Public)
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  @Get(path: '/forum/threads')
  Future<chopper.Response<ForumThreadsResponse>> _forumThreadsGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get specific thread details
  ///@param key API key (Public)
  ///@param threadId Thread id
  Future<chopper.Response<ForumThreadResponse>> forumThreadIdThreadGet({
    required String? key,
    required int? threadId,
  }) {
    generatedMapping.putIfAbsent(ForumThreadResponse, () => ForumThreadResponse.fromJsonFactory);

    return _forumThreadIdThreadGet(key: key, threadId: threadId);
  }

  ///Get specific thread details
  ///@param key API key (Public)
  ///@param threadId Thread id
  @Get(path: '/forum/{threadId}/thread')
  Future<chopper.Response<ForumThreadResponse>> _forumThreadIdThreadGet({
    @Query('key') required String? key,
    @Path('threadId') required int? threadId,
  });

  ///Get specific forum thread posts
  ///@param key API key (Public)
  ///@param offset
  ///@param cat This parameter is being replaced with 'stripTags' parameter and will be removed on 1st December 2024. Determines if the 'content' field returns raw HTML or plain text
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param threadId Thread id
  Future<chopper.Response<ForumPostsResponse>> forumThreadIdPostsGet({
    required String? key,
    int? offset,
    enums.ForumThreadIdPostsGetCat? cat,
    enums.ApiStripTagsTrue? striptags,
    required int? threadId,
  }) {
    generatedMapping.putIfAbsent(ForumPostsResponse, () => ForumPostsResponse.fromJsonFactory);

    return _forumThreadIdPostsGet(
        key: key,
        offset: offset,
        cat: cat?.value?.toString(),
        striptags: striptags?.value?.toString(),
        threadId: threadId);
  }

  ///Get specific forum thread posts
  ///@param key API key (Public)
  ///@param offset
  ///@param cat This parameter is being replaced with 'stripTags' parameter and will be removed on 1st December 2024. Determines if the 'content' field returns raw HTML or plain text
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param threadId Thread id
  @Get(path: '/forum/{threadId}/posts')
  Future<chopper.Response<ForumPostsResponse>> _forumThreadIdPostsGet({
    @Query('key') required String? key,
    @Query('offset') int? offset,
    @Query('cat') String? cat,
    @Query('striptags') String? striptags,
    @Path('threadId') required int? threadId,
  });

  ///Get all available forum selections
  ///@param key API key (Public)
  Future<chopper.Response<ForumLookupResponse>> forumLookupGet({required String? key}) {
    generatedMapping.putIfAbsent(ForumLookupResponse, () => ForumLookupResponse.fromJsonFactory);

    return _forumLookupGet(key: key);
  }

  ///Get all available forum selections
  ///@param key API key (Public)
  @Get(path: '/forum/lookup')
  Future<chopper.Response<ForumLookupResponse>> _forumLookupGet({@Query('key') required String? key});

  ///Get current server time
  ///@param key API key (Public)
  Future<chopper.Response<TimestampResponse>> forumTimestampGet({required String? key}) {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _forumTimestampGet(key: key);
  }

  ///Get current server time
  ///@param key API key (Public)
  @Get(path: '/forum/timestamp')
  Future<chopper.Response<TimestampResponse>> _forumTimestampGet({@Query('key') required String? key});

  ///Get any Forum selection
  ///@param key API key (Public)
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
    required String? key,
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
        key: key,
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
  ///@param key API key (Public)
  ///@param selections Selection names
  ///@param id selection id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  @Get(path: '/forum')
  Future<chopper.Response> _forumGet({
    @Query('key') required String? key,
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
  ///@param key API key (Public)
  ///@param id Item id
  ///@param cat This parameter is being replaced with 'bonus' parameter and will be removed on 1st December 2024.
  ///@param bonus Used to filter weapons with a specific bonus.
  ///@param offset
  Future<chopper.Response<MarketItemMarketResponse>> marketIdItemmarketGet({
    required String? key,
    required int? id,
    enums.WeaponBonusEnum? cat,
    enums.WeaponBonusEnum? bonus,
    int? offset,
  }) {
    generatedMapping.putIfAbsent(MarketItemMarketResponse, () => MarketItemMarketResponse.fromJsonFactory);

    return _marketIdItemmarketGet(
        key: key, id: id, cat: cat?.value?.toString(), bonus: bonus?.value?.toString(), offset: offset);
  }

  ///Get item market listings
  ///@param key API key (Public)
  ///@param id Item id
  ///@param cat This parameter is being replaced with 'bonus' parameter and will be removed on 1st December 2024.
  ///@param bonus Used to filter weapons with a specific bonus.
  ///@param offset
  @Get(path: '/market/{id}/itemmarket')
  Future<chopper.Response<MarketItemMarketResponse>> _marketIdItemmarketGet({
    @Query('key') required String? key,
    @Path('id') required int? id,
    @Query('cat') String? cat,
    @Query('bonus') String? bonus,
    @Query('offset') int? offset,
  });

  ///Get all available market selections
  ///@param key API key (Public)
  Future<chopper.Response<MarketLookupResponse>> marketLookupGet({required String? key}) {
    generatedMapping.putIfAbsent(MarketLookupResponse, () => MarketLookupResponse.fromJsonFactory);

    return _marketLookupGet(key: key);
  }

  ///Get all available market selections
  ///@param key API key (Public)
  @Get(path: '/market/lookup')
  Future<chopper.Response<MarketLookupResponse>> _marketLookupGet({@Query('key') required String? key});

  ///Get current server time
  ///@param key API key (Public)
  Future<chopper.Response<TimestampResponse>> marketTimestampGet({required String? key}) {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _marketTimestampGet(key: key);
  }

  ///Get current server time
  ///@param key API key (Public)
  @Get(path: '/market/timestamp')
  Future<chopper.Response<TimestampResponse>> _marketTimestampGet({@Query('key') required String? key});

  ///Get any Market selection
  ///@param key API key (Public)
  ///@param selections Selection names
  ///@param id selection id
  ///@param bonus Used to filter weapons with a specific bonus
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  Future<chopper.Response> marketGet({
    required String? key,
    List<enums.MarketSelectionName>? selections,
    String? id,
    enums.WeaponBonusEnum? bonus,
    String? cat,
    enums.MarketGetSort? sort,
    int? offset,
  }) {
    return _marketGet(
        key: key,
        selections: marketSelectionNameListToJson(selections),
        id: id,
        bonus: bonus?.value?.toString(),
        cat: cat,
        sort: sort?.value?.toString(),
        offset: offset);
  }

  ///Get any Market selection
  ///@param key API key (Public)
  ///@param selections Selection names
  ///@param id selection id
  ///@param bonus Used to filter weapons with a specific bonus
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  @Get(path: '/market')
  Future<chopper.Response> _marketGet({
    @Query('key') required String? key,
    @Query('selections') List<Object?>? selections,
    @Query('id') String? id,
    @Query('bonus') String? bonus,
    @Query('cat') String? cat,
    @Query('sort') String? sort,
    @Query('offset') int? offset,
  });

  ///Get races
  ///@param key API key (Public)
  ///@param limit
  ///@param sort Sorted by schedule.start field
  ///@param to Timestamp until when started races are returned (schedule.start)
  ///@param from Timestamp after when started races are returned (scheduled.start)
  ///@param cat Category of races returned
  Future<chopper.Response<RacingRacesResponse>> racingRacesGet({
    required String? key,
    int? limit,
    enums.RacingRacesGetSort? sort,
    int? to,
    int? from,
    enums.RacingRacesGetCat? cat,
  }) {
    generatedMapping.putIfAbsent(RacingRacesResponse, () => RacingRacesResponse.fromJsonFactory);

    return _racingRacesGet(
        key: key, limit: limit, sort: sort?.value?.toString(), to: to, from: from, cat: cat?.value?.toString());
  }

  ///Get races
  ///@param key API key (Public)
  ///@param limit
  ///@param sort Sorted by schedule.start field
  ///@param to Timestamp until when started races are returned (schedule.start)
  ///@param from Timestamp after when started races are returned (scheduled.start)
  ///@param cat Category of races returned
  @Get(path: '/racing/races')
  Future<chopper.Response<RacingRacesResponse>> _racingRacesGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') String? cat,
  });

  ///Get track records
  ///@param key API key (Public)
  ///@param trackId Track id
  ///@param cat Car class
  Future<chopper.Response<RacingTrackRecordsResponse>> racingTrackIdRecordsGet({
    required String? key,
    required int? trackId,
    required enums.RaceClassEnum? cat,
  }) {
    generatedMapping.putIfAbsent(RacingTrackRecordsResponse, () => RacingTrackRecordsResponse.fromJsonFactory);

    return _racingTrackIdRecordsGet(key: key, trackId: trackId, cat: cat?.value?.toString());
  }

  ///Get track records
  ///@param key API key (Public)
  ///@param trackId Track id
  ///@param cat Car class
  @Get(path: '/racing/{trackId}/records')
  Future<chopper.Response<RacingTrackRecordsResponse>> _racingTrackIdRecordsGet({
    @Query('key') required String? key,
    @Path('trackId') required int? trackId,
    @Query('cat') required String? cat,
  });

  ///Get specific race details
  ///@param key API key (Public)
  ///@param id Race id
  Future<chopper.Response<RacingRaceDetailsResponse>> racingRaceIdRaceGet({
    required String? key,
    required int? id,
  }) {
    generatedMapping.putIfAbsent(RacingRaceDetailsResponse, () => RacingRaceDetailsResponse.fromJsonFactory);

    return _racingRaceIdRaceGet(key: key, id: id);
  }

  ///Get specific race details
  ///@param key API key (Public)
  ///@param id Race id
  @Get(path: '/racing/{raceId}/race')
  Future<chopper.Response<RacingRaceDetailsResponse>> _racingRaceIdRaceGet({
    @Query('key') required String? key,
    @Path('id') required int? id,
  });

  ///Get cars and their racing stats
  ///@param key API key (Public)
  Future<chopper.Response<RacingCarsResponse>> racingCarsGet({required String? key}) {
    generatedMapping.putIfAbsent(RacingCarsResponse, () => RacingCarsResponse.fromJsonFactory);

    return _racingCarsGet(key: key);
  }

  ///Get cars and their racing stats
  ///@param key API key (Public)
  @Get(path: '/racing/cars')
  Future<chopper.Response<RacingCarsResponse>> _racingCarsGet({@Query('key') required String? key});

  ///Get race tracks and descriptions
  ///@param key API key (Public)
  Future<chopper.Response<RacingTracksResponse>> racingTracksGet({required String? key}) {
    generatedMapping.putIfAbsent(RacingTracksResponse, () => RacingTracksResponse.fromJsonFactory);

    return _racingTracksGet(key: key);
  }

  ///Get race tracks and descriptions
  ///@param key API key (Public)
  @Get(path: '/racing/tracks')
  Future<chopper.Response<RacingTracksResponse>> _racingTracksGet({@Query('key') required String? key});

  ///Get all possible car upgrades
  ///@param key API key (Public)
  Future<chopper.Response<RacingCarUpgradesResponse>> racingCarupgradesGet({required String? key}) {
    generatedMapping.putIfAbsent(RacingCarUpgradesResponse, () => RacingCarUpgradesResponse.fromJsonFactory);

    return _racingCarupgradesGet(key: key);
  }

  ///Get all possible car upgrades
  ///@param key API key (Public)
  @Get(path: '/racing/carupgrades')
  Future<chopper.Response<RacingCarUpgradesResponse>> _racingCarupgradesGet({@Query('key') required String? key});

  ///Get all available racing selections
  ///@param key API key (Public)
  Future<chopper.Response<RacingLookupResponse>> racingLookupGet({required String? key}) {
    generatedMapping.putIfAbsent(RacingLookupResponse, () => RacingLookupResponse.fromJsonFactory);

    return _racingLookupGet(key: key);
  }

  ///Get all available racing selections
  ///@param key API key (Public)
  @Get(path: '/racing/lookup')
  Future<chopper.Response<RacingLookupResponse>> _racingLookupGet({@Query('key') required String? key});

  ///Get current server time
  ///@param key API key (Public)
  Future<chopper.Response<TimestampResponse>> racingTimestampGet({required String? key}) {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _racingTimestampGet(key: key);
  }

  ///Get current server time
  ///@param key API key (Public)
  @Get(path: '/racing/timestamp')
  Future<chopper.Response<TimestampResponse>> _racingTimestampGet({@Query('key') required String? key});

  ///Get any Racing selection
  ///@param key API key (Public)
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  Future<chopper.Response> racingGet({
    required String? key,
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
        key: key,
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
  ///@param key API key (Public)
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  @Get(path: '/racing')
  Future<chopper.Response> _racingGet({
    @Query('key') required String? key,
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
  ///@param key API key (Public)
  ///@param crimeId Crime id
  Future<chopper.Response<TornSubcrimesResponse>> tornCrimeIdSubcrimesGet({
    required String? key,
    required String? crimeId,
  }) {
    generatedMapping.putIfAbsent(TornSubcrimesResponse, () => TornSubcrimesResponse.fromJsonFactory);

    return _tornCrimeIdSubcrimesGet(key: key, crimeId: crimeId);
  }

  ///Get Subcrimes information
  ///@param key API key (Public)
  ///@param crimeId Crime id
  @Get(path: '/torn/{crimeId}/subcrimes')
  Future<chopper.Response<TornSubcrimesResponse>> _tornCrimeIdSubcrimesGet({
    @Query('key') required String? key,
    @Path('crimeId') required String? crimeId,
  });

  ///Get crimes information
  ///@param key API key (Public)
  Future<chopper.Response<TornCrimesResponse>> tornCrimesGet({required String? key}) {
    generatedMapping.putIfAbsent(TornCrimesResponse, () => TornCrimesResponse.fromJsonFactory);

    return _tornCrimesGet(key: key);
  }

  ///Get crimes information
  ///@param key API key (Public)
  @Get(path: '/torn/crimes')
  Future<chopper.Response<TornCrimesResponse>> _tornCrimesGet({@Query('key') required String? key});

  ///Get calendar information
  ///@param key API key (Public)
  Future<chopper.Response<TornCalendarResponse>> tornCalendarGet({required String? key}) {
    generatedMapping.putIfAbsent(TornCalendarResponse, () => TornCalendarResponse.fromJsonFactory);

    return _tornCalendarGet(key: key);
  }

  ///Get calendar information
  ///@param key API key (Public)
  @Get(path: '/torn/calendar')
  Future<chopper.Response<TornCalendarResponse>> _tornCalendarGet({@Query('key') required String? key});

  ///Get player hall of fame positions for a specific category
  ///@param key API key (Public)
  ///@param limit
  ///@param offset
  ///@param cat Leaderboards category
  Future<chopper.Response<TornHofResponse>> tornHofGet({
    required String? key,
    int? limit,
    int? offset,
    required enums.TornHofCategory? cat,
  }) {
    generatedMapping.putIfAbsent(TornHofResponse, () => TornHofResponse.fromJsonFactory);

    return _tornHofGet(key: key, limit: limit, offset: offset, cat: cat?.value?.toString());
  }

  ///Get player hall of fame positions for a specific category
  ///@param key API key (Public)
  ///@param limit
  ///@param offset
  ///@param cat Leaderboards category
  @Get(path: '/torn/hof')
  Future<chopper.Response<TornHofResponse>> _tornHofGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('cat') required String? cat,
  });

  ///Get faction hall of fame positions for a specific category
  ///@param key API key (Public)
  ///@param limit
  ///@param offset
  ///@param cat Leaderboards category
  Future<chopper.Response<TornFactionHofResponse>> tornFactionhofGet({
    required String? key,
    int? limit,
    int? offset,
    required enums.TornFactionHofCategory? cat,
  }) {
    generatedMapping.putIfAbsent(TornFactionHofResponse, () => TornFactionHofResponse.fromJsonFactory);

    return _tornFactionhofGet(key: key, limit: limit, offset: offset, cat: cat?.value?.toString());
  }

  ///Get faction hall of fame positions for a specific category
  ///@param key API key (Public)
  ///@param limit
  ///@param offset
  ///@param cat Leaderboards category
  @Get(path: '/torn/factionhof')
  Future<chopper.Response<TornFactionHofResponse>> _tornFactionhofGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('cat') required String? cat,
  });

  ///Get available log ids for a specific log category
  ///@param key API key (Public)
  ///@param logCategoryId Log category id
  Future<chopper.Response<TornLogTypesResponse>> tornLogCategoryIdLogtypesGet({
    required String? key,
    required int? logCategoryId,
  }) {
    generatedMapping.putIfAbsent(TornLogTypesResponse, () => TornLogTypesResponse.fromJsonFactory);

    return _tornLogCategoryIdLogtypesGet(key: key, logCategoryId: logCategoryId);
  }

  ///Get available log ids for a specific log category
  ///@param key API key (Public)
  ///@param logCategoryId Log category id
  @Get(path: '/torn/{logCategoryId}/logtypes')
  Future<chopper.Response<TornLogTypesResponse>> _tornLogCategoryIdLogtypesGet({
    @Query('key') required String? key,
    @Path('logCategoryId') required int? logCategoryId,
  });

  ///Get all available log ids
  ///@param key API key (Public)
  Future<chopper.Response<TornLogTypesResponse>> tornLogtypesGet({required String? key}) {
    generatedMapping.putIfAbsent(TornLogTypesResponse, () => TornLogTypesResponse.fromJsonFactory);

    return _tornLogtypesGet(key: key);
  }

  ///Get all available log ids
  ///@param key API key (Public)
  @Get(path: '/torn/logtypes')
  Future<chopper.Response<TornLogTypesResponse>> _tornLogtypesGet({@Query('key') required String? key});

  ///Get available log categories
  ///@param key API key (Public)
  Future<chopper.Response<TornLogCategoriesResponse>> tornLogcategoriesGet({required String? key}) {
    generatedMapping.putIfAbsent(TornLogCategoriesResponse, () => TornLogCategoriesResponse.fromJsonFactory);

    return _tornLogcategoriesGet(key: key);
  }

  ///Get available log categories
  ///@param key API key (Public)
  @Get(path: '/torn/logcategories')
  Future<chopper.Response<TornLogCategoriesResponse>> _tornLogcategoriesGet({@Query('key') required String? key});

  ///Get bounties
  ///@param key API key (Public)
  ///@param limit
  ///@param offset
  Future<chopper.Response<TornBountiesResponse>> tornBountiesGet({
    required String? key,
    int? limit,
    int? offset,
  }) {
    generatedMapping.putIfAbsent(TornBountiesResponse, () => TornBountiesResponse.fromJsonFactory);

    return _tornBountiesGet(key: key, limit: limit, offset: offset);
  }

  ///Get bounties
  ///@param key API key (Public)
  ///@param limit
  ///@param offset
  @Get(path: '/torn/bounties')
  Future<chopper.Response<TornBountiesResponse>> _tornBountiesGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  ///Get all available torn selections
  ///@param key API key (Public)
  Future<chopper.Response<TornLookupResponse>> tornLookupGet({required String? key}) {
    generatedMapping.putIfAbsent(TornLookupResponse, () => TornLookupResponse.fromJsonFactory);

    return _tornLookupGet(key: key);
  }

  ///Get all available torn selections
  ///@param key API key (Public)
  @Get(path: '/torn/lookup')
  Future<chopper.Response<TornLookupResponse>> _tornLookupGet({@Query('key') required String? key});

  ///Get current server time
  ///@param key API key (Public)
  Future<chopper.Response<TimestampResponse>> tornTimestampGet({required String? key}) {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _tornTimestampGet(key: key);
  }

  ///Get current server time
  ///@param key API key (Public)
  @Get(path: '/torn/timestamp')
  Future<chopper.Response<TimestampResponse>> _tornTimestampGet({@Query('key') required String? key});

  ///Get any Torn selection
  ///@param key API key (Public)
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
    required String? key,
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
        key: key,
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
  ///@param key API key (Public)
  ///@param selections Selection names
  ///@param id selection id
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param sort Direction to sort rows in
  ///@param offset
  @Get(path: '/torn')
  Future<chopper.Response> _tornGet({
    @Query('key') required String? key,
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

  ///Get user's crime statistics
  ///@param key API key (Minimal)
  ///@param crimeId Crime id
  Future<chopper.Response<UserCrimesResponse>> userCrimeIdCrimesGet({
    required String? key,
    required String? crimeId,
  }) {
    generatedMapping.putIfAbsent(UserCrimesResponse, () => UserCrimesResponse.fromJsonFactory);

    return _userCrimeIdCrimesGet(key: key, crimeId: crimeId);
  }

  ///Get user's crime statistics
  ///@param key API key (Minimal)
  ///@param crimeId Crime id
  @Get(path: '/user/{crimeId}/crimes')
  Future<chopper.Response<UserCrimesResponse>> _userCrimeIdCrimesGet({
    @Query('key') required String? key,
    @Path('crimeId') required String? crimeId,
  });

  ///Get user races
  ///@param key API key (Minimal)
  ///@param limit
  ///@param sort Sorted by schedule.start field
  ///@param to Timestamp until when started races are returned (schedule.start)
  ///@param from Timestamp after when started races are returned (scheduled.start)
  ///@param cat Category of races returned
  Future<chopper.Response<UserRacesResponse>> userRacesGet({
    required String? key,
    int? limit,
    enums.UserRacesGetSort? sort,
    int? to,
    int? from,
    enums.UserRacesGetCat? cat,
  }) {
    generatedMapping.putIfAbsent(UserRacesResponse, () => UserRacesResponse.fromJsonFactory);

    return _userRacesGet(
        key: key, limit: limit, sort: sort?.value?.toString(), to: to, from: from, cat: cat?.value?.toString());
  }

  ///Get user races
  ///@param key API key (Minimal)
  ///@param limit
  ///@param sort Sorted by schedule.start field
  ///@param to Timestamp until when started races are returned (schedule.start)
  ///@param from Timestamp after when started races are returned (scheduled.start)
  ///@param cat Category of races returned
  @Get(path: '/user/races')
  Future<chopper.Response<UserRacesResponse>> _userRacesGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
    @Query('cat') String? cat,
  });

  ///Get user enlisted cars
  ///@param key API key (Minimal)
  Future<chopper.Response<UserEnlistedCarsResponse>> userEnlistedcarsGet({required String? key}) {
    generatedMapping.putIfAbsent(UserEnlistedCarsResponse, () => UserEnlistedCarsResponse.fromJsonFactory);

    return _userEnlistedcarsGet(key: key);
  }

  ///Get user enlisted cars
  ///@param key API key (Minimal)
  @Get(path: '/user/enlistedcars')
  Future<chopper.Response<UserEnlistedCarsResponse>> _userEnlistedcarsGet({@Query('key') required String? key});

  ///Get posts for a specific player
  ///@param key API key (Public)
  ///@param cat This parameter is being replaced with 'stripTags' parameter and will be removed on 1st December 2024. Determines if the 'content' field returns raw HTML or plain text
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param id User id
  ///@param limit
  ///@param sort Sorted by post created timestamp
  ///@param to Returns posts created before this timestamp
  ///@param from Returns posts created after this timestamp
  Future<chopper.Response<UserForumPostsResponse>> userIdForumpostsGet({
    required String? key,
    enums.UserIdForumpostsGetCat? cat,
    enums.ApiStripTagsTrue? striptags,
    required int? id,
    int? limit,
    enums.UserIdForumpostsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(UserForumPostsResponse, () => UserForumPostsResponse.fromJsonFactory);

    return _userIdForumpostsGet(
        key: key,
        cat: cat?.value?.toString(),
        striptags: striptags?.value?.toString(),
        id: id,
        limit: limit,
        sort: sort?.value?.toString(),
        to: to,
        from: from);
  }

  ///Get posts for a specific player
  ///@param key API key (Public)
  ///@param cat This parameter is being replaced with 'stripTags' parameter and will be removed on 1st December 2024. Determines if the 'content' field returns raw HTML or plain text
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param id User id
  ///@param limit
  ///@param sort Sorted by post created timestamp
  ///@param to Returns posts created before this timestamp
  ///@param from Returns posts created after this timestamp
  @Get(path: '/user/{id}/forumposts')
  Future<chopper.Response<UserForumPostsResponse>> _userIdForumpostsGet({
    @Query('key') required String? key,
    @Query('cat') String? cat,
    @Query('striptags') String? striptags,
    @Path('id') required int? id,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get your posts
  ///@param key API key (Public)
  ///@param cat This parameter is being replaced with 'stripTags' parameter and will be removed on 1st December 2024. Determines if the 'content' field returns raw HTML or plain text
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param sort Sorted by post created timestamp
  ///@param to Returns posts created before this timestamp
  ///@param from Returns posts created after this timestamp
  Future<chopper.Response<UserForumPostsResponse>> userForumpostsGet({
    required String? key,
    enums.UserForumpostsGetCat? cat,
    enums.ApiStripTagsTrue? striptags,
    int? limit,
    enums.UserForumpostsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(UserForumPostsResponse, () => UserForumPostsResponse.fromJsonFactory);

    return _userForumpostsGet(
        key: key,
        cat: cat?.value?.toString(),
        striptags: striptags?.value?.toString(),
        limit: limit,
        sort: sort?.value?.toString(),
        to: to,
        from: from);
  }

  ///Get your posts
  ///@param key API key (Public)
  ///@param cat This parameter is being replaced with 'stripTags' parameter and will be removed on 1st December 2024. Determines if the 'content' field returns raw HTML or plain text
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param limit
  ///@param sort Sorted by post created timestamp
  ///@param to Returns posts created before this timestamp
  ///@param from Returns posts created after this timestamp
  @Get(path: '/user/forumposts')
  Future<chopper.Response<UserForumPostsResponse>> _userForumpostsGet({
    @Query('key') required String? key,
    @Query('cat') String? cat,
    @Query('striptags') String? striptags,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get threads for a specific player
  ///@param key API key (Public)
  ///@param id User id
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  Future<chopper.Response<UserForumThreadsResponse>> userIdForumthreadsGet({
    required String? key,
    required int? id,
    int? limit,
    enums.UserIdForumthreadsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(UserForumThreadsResponse, () => UserForumThreadsResponse.fromJsonFactory);

    return _userIdForumthreadsGet(key: key, id: id, limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get threads for a specific player
  ///@param key API key (Public)
  ///@param id User id
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  @Get(path: '/user/{id}/forumthreads')
  Future<chopper.Response<UserForumThreadsResponse>> _userIdForumthreadsGet({
    @Query('key') required String? key,
    @Path('id') required int? id,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get your threads
  ///@param key API key (Public)
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  Future<chopper.Response<UserForumThreadsResponse>> userForumthreadsGet({
    required String? key,
    int? limit,
    enums.UserForumthreadsGetSort? sort,
    int? to,
    int? from,
  }) {
    generatedMapping.putIfAbsent(UserForumThreadsResponse, () => UserForumThreadsResponse.fromJsonFactory);

    return _userForumthreadsGet(key: key, limit: limit, sort: sort?.value?.toString(), to: to, from: from);
  }

  ///Get your threads
  ///@param key API key (Public)
  ///@param limit
  ///@param sort Sorted by the greatest of first_post_time and last_post_time timestamps
  ///@param to Returns threads created before this timestamp
  ///@param from Returns threads created after this timestamp
  @Get(path: '/user/forumthreads')
  Future<chopper.Response<UserForumThreadsResponse>> _userForumthreadsGet({
    @Query('key') required String? key,
    @Query('limit') int? limit,
    @Query('sort') String? sort,
    @Query('to') int? to,
    @Query('from') int? from,
  });

  ///Get updates on threads you subscribed to
  ///@param key API key (Minimal)
  Future<chopper.Response<UserForumSubscribedThreadsResponse>> userForumsubscribedthreadsGet({required String? key}) {
    generatedMapping.putIfAbsent(
        UserForumSubscribedThreadsResponse, () => UserForumSubscribedThreadsResponse.fromJsonFactory);

    return _userForumsubscribedthreadsGet(key: key);
  }

  ///Get updates on threads you subscribed to
  ///@param key API key (Minimal)
  @Get(path: '/user/forumsubscribedthreads')
  Future<chopper.Response<UserForumSubscribedThreadsResponse>> _userForumsubscribedthreadsGet(
      {@Query('key') required String? key});

  ///Get updates on your threads and posts
  ///@param key API key (Minimal)
  Future<chopper.Response<UserForumFeedResponse>> userForumfeedGet({required String? key}) {
    generatedMapping.putIfAbsent(UserForumFeedResponse, () => UserForumFeedResponse.fromJsonFactory);

    return _userForumfeedGet(key: key);
  }

  ///Get updates on your threads and posts
  ///@param key API key (Minimal)
  @Get(path: '/user/forumfeed')
  Future<chopper.Response<UserForumFeedResponse>> _userForumfeedGet({@Query('key') required String? key});

  ///Get updates on your friends' activity
  ///@param key API key (Minimal)
  Future<chopper.Response<UserForumFriendsResponse>> userForumfriendsGet({required String? key}) {
    generatedMapping.putIfAbsent(UserForumFriendsResponse, () => UserForumFriendsResponse.fromJsonFactory);

    return _userForumfriendsGet(key: key);
  }

  ///Get updates on your friends' activity
  ///@param key API key (Minimal)
  @Get(path: '/user/forumfriends')
  Future<chopper.Response<UserForumFriendsResponse>> _userForumfriendsGet({@Query('key') required String? key});

  ///Get hall of fame rankings for a specific player
  ///@param key API key (Public)
  ///@param id User id
  Future<chopper.Response<UserHofResponse>> userIdHofGet({
    required String? key,
    required int? id,
  }) {
    generatedMapping.putIfAbsent(UserHofResponse, () => UserHofResponse.fromJsonFactory);

    return _userIdHofGet(key: key, id: id);
  }

  ///Get hall of fame rankings for a specific player
  ///@param key API key (Public)
  ///@param id User id
  @Get(path: '/user/{id}/hof')
  Future<chopper.Response<UserHofResponse>> _userIdHofGet({
    @Query('key') required String? key,
    @Path('id') required int? id,
  });

  ///Get your hall of fame rankings
  ///@param key API key (Public)
  Future<chopper.Response<UserHofResponse>> userHofGet({required String? key}) {
    generatedMapping.putIfAbsent(UserHofResponse, () => UserHofResponse.fromJsonFactory);

    return _userHofGet(key: key);
  }

  ///Get your hall of fame rankings
  ///@param key API key (Public)
  @Get(path: '/user/hof')
  Future<chopper.Response<UserHofResponse>> _userHofGet({@Query('key') required String? key});

  ///Get your competition's event start time
  ///@param key API key (Minimal)
  Future<chopper.Response<UserCalendarResponse>> userCalendarGet({required String? key}) {
    generatedMapping.putIfAbsent(UserCalendarResponse, () => UserCalendarResponse.fromJsonFactory);

    return _userCalendarGet(key: key);
  }

  ///Get your competition's event start time
  ///@param key API key (Minimal)
  @Get(path: '/user/calendar')
  Future<chopper.Response<UserCalendarResponse>> _userCalendarGet({@Query('key') required String? key});

  ///Get bounties placed on a specific user
  ///@param key API key (Public)
  ///@param id User id
  Future<chopper.Response<UserBountiesResponse>> userIdBountiesGet({
    required String? key,
    required int? id,
  }) {
    generatedMapping.putIfAbsent(UserBountiesResponse, () => UserBountiesResponse.fromJsonFactory);

    return _userIdBountiesGet(key: key, id: id);
  }

  ///Get bounties placed on a specific user
  ///@param key API key (Public)
  ///@param id User id
  @Get(path: '/user/{id}/bounties')
  Future<chopper.Response<UserBountiesResponse>> _userIdBountiesGet({
    @Query('key') required String? key,
    @Path('id') required int? id,
  });

  ///Get bounties placed on you
  ///@param key API key (Public)
  Future<chopper.Response<UserBountiesResponse>> userBountiesGet({required String? key}) {
    generatedMapping.putIfAbsent(UserBountiesResponse, () => UserBountiesResponse.fromJsonFactory);

    return _userBountiesGet(key: key);
  }

  ///Get bounties placed on you
  ///@param key API key (Public)
  @Get(path: '/user/bounties')
  Future<chopper.Response<UserBountiesResponse>> _userBountiesGet({@Query('key') required String? key});

  ///Get your starter job positions
  ///@param key API key (Minimal)
  Future<chopper.Response<UserJobRanksResponse>> userJobranksGet({required String? key}) {
    generatedMapping.putIfAbsent(UserJobRanksResponse, () => UserJobRanksResponse.fromJsonFactory);

    return _userJobranksGet(key: key);
  }

  ///Get your starter job positions
  ///@param key API key (Minimal)
  @Get(path: '/user/jobranks')
  Future<chopper.Response<UserJobRanksResponse>> _userJobranksGet({@Query('key') required String? key});

  ///Get your item market listings for a specific item
  ///@param key API key (Limited)
  ///@param offset
  Future<chopper.Response<UserItemMarketResponse>> userItemmarketGet({
    required String? key,
    int? offset,
  }) {
    generatedMapping.putIfAbsent(UserItemMarketResponse, () => UserItemMarketResponse.fromJsonFactory);

    return _userItemmarketGet(key: key, offset: offset);
  }

  ///Get your item market listings for a specific item
  ///@param key API key (Limited)
  ///@param offset
  @Get(path: '/user/itemmarket')
  Future<chopper.Response<UserItemMarketResponse>> _userItemmarketGet({
    @Query('key') required String? key,
    @Query('offset') int? offset,
  });

  ///Get all available user selections
  ///@param key API key (Public)
  Future<chopper.Response<UserLookupResponse>> userLookupGet({required String? key}) {
    generatedMapping.putIfAbsent(UserLookupResponse, () => UserLookupResponse.fromJsonFactory);

    return _userLookupGet(key: key);
  }

  ///Get all available user selections
  ///@param key API key (Public)
  @Get(path: '/user/lookup')
  Future<chopper.Response<UserLookupResponse>> _userLookupGet({@Query('key') required String? key});

  ///Get current server time
  ///@param key API key (Public)
  Future<chopper.Response<TimestampResponse>> userTimestampGet({required String? key}) {
    generatedMapping.putIfAbsent(TimestampResponse, () => TimestampResponse.fromJsonFactory);

    return _userTimestampGet(key: key);
  }

  ///Get current server time
  ///@param key API key (Public)
  @Get(path: '/user/timestamp')
  Future<chopper.Response<TimestampResponse>> _userTimestampGet({@Query('key') required String? key});

  ///Get any User selection
  ///@param key API key (Public)
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param sort Direction to sort rows in
  ///@param offset
  Future<chopper.Response> userGet({
    required String? key,
    List<enums.UserSelectionName>? selections,
    String? id,
    int? limit,
    int? to,
    int? from,
    String? cat,
    enums.ApiStripTags? striptags,
    enums.UserGetSort? sort,
    int? offset,
  }) {
    return _userGet(
        key: key,
        selections: userSelectionNameListToJson(selections),
        id: id,
        limit: limit,
        to: to,
        from: from,
        cat: cat,
        striptags: striptags?.value?.toString(),
        sort: sort?.value?.toString(),
        offset: offset);
  }

  ///Get any User selection
  ///@param key API key (Public)
  ///@param selections Selection names
  ///@param id selection id
  ///@param limit
  ///@param to Timestamp until when rows are returned
  ///@param from Timestamp after when rows are returned
  ///@param cat Selection category
  ///@param striptags Determines if fields include HTML or not ('Hospitalized by <a href=...>user</a>' vs 'Hospitalized by user').
  ///@param sort Direction to sort rows in
  ///@param offset
  @Get(path: '/user')
  Future<chopper.Response> _userGet({
    @Query('key') required String? key,
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
  final double? level;
  @JsonKey(name: 'days_in_faction')
  final double? daysInFaction;
  @JsonKey(name: 'is_revivable')
  final bool? isRevivable;
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
      double? level,
      double? daysInFaction,
      bool? isRevivable,
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
        lastAction: lastAction ?? this.lastAction,
        status: status ?? this.status,
        life: life ?? this.life,
        reviveSetting: reviveSetting ?? this.reviveSetting);
  }

  FactionMember copyWithWrapped(
      {Wrapped<int?>? id,
      Wrapped<String?>? name,
      Wrapped<String?>? position,
      Wrapped<double?>? level,
      Wrapped<double?>? daysInFaction,
      Wrapped<bool?>? isRevivable,
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
  final double? timestamp;
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
  UserLastAction copyWith({String? status, double? timestamp, String? relative}) {
    return UserLastAction(
        status: status ?? this.status, timestamp: timestamp ?? this.timestamp, relative: relative ?? this.relative);
  }

  UserLastAction copyWithWrapped({Wrapped<String?>? status, Wrapped<double?>? timestamp, Wrapped<String?>? relative}) {
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
  final double? current;
  @JsonKey(name: 'maximum')
  final double? maximum;
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
  UserLife copyWith({double? current, double? maximum}) {
    return UserLife(current: current ?? this.current, maximum: maximum ?? this.maximum);
  }

  UserLife copyWithWrapped({Wrapped<double?>? current, Wrapped<double?>? maximum}) {
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
  final String? until;
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
  UserStatus copyWith({String? description, String? details, String? state, String? until}) {
    return UserStatus(
        description: description ?? this.description,
        details: details ?? this.details,
        state: state ?? this.state,
        until: until ?? this.until);
  }

  UserStatus copyWithWrapped(
      {Wrapped<String?>? description, Wrapped<String?>? details, Wrapped<String?>? state, Wrapped<String?>? until}) {
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
    this.links,
    this.metadata,
  });

  factory ForumThreadsResponse.fromJson(Map<String, dynamic> json) => _$ForumThreadsResponseFromJson(json);

  static const toJsonFactory = _$ForumThreadsResponseToJson;
  Map<String, dynamic> toJson() => _$ForumThreadsResponseToJson(this);

  @JsonKey(name: 'threads', defaultValue: <ForumThreadBase>[])
  final List<ForumThreadBase>? threads;
  @JsonKey(name: '_links')
  final RequestLinks? links;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$ForumThreadsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumThreadsResponse &&
            (identical(other.threads, threads) || const DeepCollectionEquality().equals(other.threads, threads)) &&
            (identical(other.links, links) || const DeepCollectionEquality().equals(other.links, links)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(threads) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $ForumThreadsResponseExtension on ForumThreadsResponse {
  ForumThreadsResponse copyWith(
      {List<ForumThreadBase>? threads, RequestLinks? links, RequestMetadataWithLinks? metadata}) {
    return ForumThreadsResponse(
        threads: threads ?? this.threads, links: links ?? this.links, metadata: metadata ?? this.metadata);
  }

  ForumThreadsResponse copyWithWrapped(
      {Wrapped<List<ForumThreadBase>?>? threads,
      Wrapped<RequestLinks?>? links,
      Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return ForumThreadsResponse(
        threads: (threads != null ? threads.value : this.threads),
        links: (links != null ? links.value : this.links),
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
    this.links,
    this.metadata,
  });

  factory ForumPostsResponse.fromJson(Map<String, dynamic> json) => _$ForumPostsResponseFromJson(json);

  static const toJsonFactory = _$ForumPostsResponseToJson;
  Map<String, dynamic> toJson() => _$ForumPostsResponseToJson(this);

  @JsonKey(name: 'posts', defaultValue: <ForumPost>[])
  final List<ForumPost>? posts;
  @JsonKey(name: '_links')
  final RequestLinks? links;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$ForumPostsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForumPostsResponse &&
            (identical(other.posts, posts) || const DeepCollectionEquality().equals(other.posts, posts)) &&
            (identical(other.links, links) || const DeepCollectionEquality().equals(other.links, links)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(posts) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $ForumPostsResponseExtension on ForumPostsResponse {
  ForumPostsResponse copyWith({List<ForumPost>? posts, RequestLinks? links, RequestMetadataWithLinks? metadata}) {
    return ForumPostsResponse(
        posts: posts ?? this.posts, links: links ?? this.links, metadata: metadata ?? this.metadata);
  }

  ForumPostsResponse copyWithWrapped(
      {Wrapped<List<ForumPost>?>? posts, Wrapped<RequestLinks?>? links, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return ForumPostsResponse(
        posts: (posts != null ? posts.value : this.posts),
        links: (links != null ? links.value : this.links),
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
  final double? timeEnded;
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
      double? timeEnded}) {
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
      Wrapped<double?>? timeEnded}) {
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
    this.links,
    this.metadata,
  });

  factory TornHofResponse.fromJson(Map<String, dynamic> json) => _$TornHofResponseFromJson(json);

  static const toJsonFactory = _$TornHofResponseToJson;
  Map<String, dynamic> toJson() => _$TornHofResponseToJson(this);

  @JsonKey(name: 'hof', defaultValue: <TornHof>[])
  final List<TornHof>? hof;
  @JsonKey(name: '_links')
  final RequestLinks? links;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$TornHofResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornHofResponse &&
            (identical(other.hof, hof) || const DeepCollectionEquality().equals(other.hof, hof)) &&
            (identical(other.links, links) || const DeepCollectionEquality().equals(other.links, links)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(hof) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $TornHofResponseExtension on TornHofResponse {
  TornHofResponse copyWith({List<TornHof>? hof, RequestLinks? links, RequestMetadataWithLinks? metadata}) {
    return TornHofResponse(hof: hof ?? this.hof, links: links ?? this.links, metadata: metadata ?? this.metadata);
  }

  TornHofResponse copyWithWrapped(
      {Wrapped<List<TornHof>?>? hof, Wrapped<RequestLinks?>? links, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return TornHofResponse(
        hof: (hof != null ? hof.value : this.hof),
        links: (links != null ? links.value : this.links),
        metadata: (metadata != null ? metadata.value : this.metadata));
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
    this.links,
    this.metadata,
  });

  factory TornFactionHofResponse.fromJson(Map<String, dynamic> json) => _$TornFactionHofResponseFromJson(json);

  static const toJsonFactory = _$TornFactionHofResponseToJson;
  Map<String, dynamic> toJson() => _$TornFactionHofResponseToJson(this);

  @JsonKey(name: 'factionhof', defaultValue: <TornFactionHof>[])
  final List<TornFactionHof>? factionhof;
  @JsonKey(name: '_links')
  final RequestLinks? links;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$TornFactionHofResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornFactionHofResponse &&
            (identical(other.factionhof, factionhof) ||
                const DeepCollectionEquality().equals(other.factionhof, factionhof)) &&
            (identical(other.links, links) || const DeepCollectionEquality().equals(other.links, links)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(factionhof) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $TornFactionHofResponseExtension on TornFactionHofResponse {
  TornFactionHofResponse copyWith(
      {List<TornFactionHof>? factionhof, RequestLinks? links, RequestMetadataWithLinks? metadata}) {
    return TornFactionHofResponse(
        factionhof: factionhof ?? this.factionhof, links: links ?? this.links, metadata: metadata ?? this.metadata);
  }

  TornFactionHofResponse copyWithWrapped(
      {Wrapped<List<TornFactionHof>?>? factionhof,
      Wrapped<RequestLinks?>? links,
      Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return TornFactionHofResponse(
        factionhof: (factionhof != null ? factionhof.value : this.factionhof),
        links: (links != null ? links.value : this.links),
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
    this.links,
    this.metadata,
  });

  factory TornBountiesResponse.fromJson(Map<String, dynamic> json) => _$TornBountiesResponseFromJson(json);

  static const toJsonFactory = _$TornBountiesResponseToJson;
  Map<String, dynamic> toJson() => _$TornBountiesResponseToJson(this);

  @JsonKey(name: 'bounties', defaultValue: <Bounty>[])
  final List<Bounty>? bounties;
  @JsonKey(name: '_links')
  final RequestLinks? links;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$TornBountiesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TornBountiesResponse &&
            (identical(other.bounties, bounties) || const DeepCollectionEquality().equals(other.bounties, bounties)) &&
            (identical(other.links, links) || const DeepCollectionEquality().equals(other.links, links)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bounties) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $TornBountiesResponseExtension on TornBountiesResponse {
  TornBountiesResponse copyWith({List<Bounty>? bounties, RequestLinks? links, RequestMetadataWithLinks? metadata}) {
    return TornBountiesResponse(
        bounties: bounties ?? this.bounties, links: links ?? this.links, metadata: metadata ?? this.metadata);
  }

  TornBountiesResponse copyWithWrapped(
      {Wrapped<List<Bounty>?>? bounties, Wrapped<RequestLinks?>? links, Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return TornBountiesResponse(
        bounties: (bounties != null ? bounties.value : this.bounties),
        links: (links != null ? links.value : this.links),
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
    this.achievedUniques,
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
  @JsonKey(name: 'achieved_uniques', defaultValue: <int>[])
  @deprecated
  final List<int>? achievedUniques;
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
            (identical(other.achievedUniques, achievedUniques) ||
                const DeepCollectionEquality().equals(other.achievedUniques, achievedUniques)) &&
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
      const DeepCollectionEquality().hash(achievedUniques) ^
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
      List<int>? achievedUniques,
      UserCrimeRewards? rewards,
      UserCrimeAttempts? attempts,
      List<UserCrimeUniques>? uniques,
      Object? miscellaneous}) {
    return UserCrime(
        nerveSpent: nerveSpent ?? this.nerveSpent,
        skill: skill ?? this.skill,
        progressionBonus: progressionBonus ?? this.progressionBonus,
        achievedUniques: achievedUniques ?? this.achievedUniques,
        rewards: rewards ?? this.rewards,
        attempts: attempts ?? this.attempts,
        uniques: uniques ?? this.uniques,
        miscellaneous: miscellaneous ?? this.miscellaneous);
  }

  UserCrime copyWithWrapped(
      {Wrapped<int?>? nerveSpent,
      Wrapped<int?>? skill,
      Wrapped<int?>? progressionBonus,
      Wrapped<List<int>?>? achievedUniques,
      Wrapped<UserCrimeRewards?>? rewards,
      Wrapped<UserCrimeAttempts?>? attempts,
      Wrapped<List<UserCrimeUniques>?>? uniques,
      Wrapped<Object?>? miscellaneous}) {
    return UserCrime(
        nerveSpent: (nerveSpent != null ? nerveSpent.value : this.nerveSpent),
        skill: (skill != null ? skill.value : this.skill),
        progressionBonus: (progressionBonus != null ? progressionBonus.value : this.progressionBonus),
        achievedUniques: (achievedUniques != null ? achievedUniques.value : this.achievedUniques),
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
    this.links,
    this.metadata,
  });

  factory UserForumPostsResponse.fromJson(Map<String, dynamic> json) => _$UserForumPostsResponseFromJson(json);

  static const toJsonFactory = _$UserForumPostsResponseToJson;
  Map<String, dynamic> toJson() => _$UserForumPostsResponseToJson(this);

  @JsonKey(name: 'forumPosts', defaultValue: <ForumPost>[])
  final List<ForumPost>? forumPosts;
  @JsonKey(name: '_links')
  final RequestLinks? links;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$UserForumPostsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserForumPostsResponse &&
            (identical(other.forumPosts, forumPosts) ||
                const DeepCollectionEquality().equals(other.forumPosts, forumPosts)) &&
            (identical(other.links, links) || const DeepCollectionEquality().equals(other.links, links)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(forumPosts) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $UserForumPostsResponseExtension on UserForumPostsResponse {
  UserForumPostsResponse copyWith(
      {List<ForumPost>? forumPosts, RequestLinks? links, RequestMetadataWithLinks? metadata}) {
    return UserForumPostsResponse(
        forumPosts: forumPosts ?? this.forumPosts, links: links ?? this.links, metadata: metadata ?? this.metadata);
  }

  UserForumPostsResponse copyWithWrapped(
      {Wrapped<List<ForumPost>?>? forumPosts,
      Wrapped<RequestLinks?>? links,
      Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return UserForumPostsResponse(
        forumPosts: (forumPosts != null ? forumPosts.value : this.forumPosts),
        links: (links != null ? links.value : this.links),
        metadata: (metadata != null ? metadata.value : this.metadata));
  }
}

@JsonSerializable(explicitToJson: true)
class UserForumThreadsResponse {
  const UserForumThreadsResponse({
    this.forumThreads,
    this.links,
    this.metadata,
  });

  factory UserForumThreadsResponse.fromJson(Map<String, dynamic> json) => _$UserForumThreadsResponseFromJson(json);

  static const toJsonFactory = _$UserForumThreadsResponseToJson;
  Map<String, dynamic> toJson() => _$UserForumThreadsResponseToJson(this);

  @JsonKey(name: 'forumThreads', defaultValue: <ForumThreadUserExtended>[])
  final List<ForumThreadUserExtended>? forumThreads;
  @JsonKey(name: '_links')
  final RequestLinks? links;
  @JsonKey(name: '_metadata')
  final RequestMetadataWithLinks? metadata;
  static const fromJsonFactory = _$UserForumThreadsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserForumThreadsResponse &&
            (identical(other.forumThreads, forumThreads) ||
                const DeepCollectionEquality().equals(other.forumThreads, forumThreads)) &&
            (identical(other.links, links) || const DeepCollectionEquality().equals(other.links, links)) &&
            (identical(other.metadata, metadata) || const DeepCollectionEquality().equals(other.metadata, metadata)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(forumThreads) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $UserForumThreadsResponseExtension on UserForumThreadsResponse {
  UserForumThreadsResponse copyWith(
      {List<ForumThreadUserExtended>? forumThreads, RequestLinks? links, RequestMetadataWithLinks? metadata}) {
    return UserForumThreadsResponse(
        forumThreads: forumThreads ?? this.forumThreads,
        links: links ?? this.links,
        metadata: metadata ?? this.metadata);
  }

  UserForumThreadsResponse copyWithWrapped(
      {Wrapped<List<ForumThreadUserExtended>?>? forumThreads,
      Wrapped<RequestLinks?>? links,
      Wrapped<RequestMetadataWithLinks?>? metadata}) {
    return UserForumThreadsResponse(
        forumThreads: (forumThreads != null ? forumThreads.value : this.forumThreads),
        links: (links != null ? links.value : this.links),
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

String? forumThreadIdPostsGetCatNullableToJson(enums.ForumThreadIdPostsGetCat? forumThreadIdPostsGetCat) {
  return forumThreadIdPostsGetCat?.value;
}

String? forumThreadIdPostsGetCatToJson(enums.ForumThreadIdPostsGetCat forumThreadIdPostsGetCat) {
  return forumThreadIdPostsGetCat.value;
}

enums.ForumThreadIdPostsGetCat forumThreadIdPostsGetCatFromJson(
  Object? forumThreadIdPostsGetCat, [
  enums.ForumThreadIdPostsGetCat? defaultValue,
]) {
  return enums.ForumThreadIdPostsGetCat.values.firstWhereOrNull((e) => e.value == forumThreadIdPostsGetCat) ??
      defaultValue ??
      enums.ForumThreadIdPostsGetCat.swaggerGeneratedUnknown;
}

enums.ForumThreadIdPostsGetCat? forumThreadIdPostsGetCatNullableFromJson(
  Object? forumThreadIdPostsGetCat, [
  enums.ForumThreadIdPostsGetCat? defaultValue,
]) {
  if (forumThreadIdPostsGetCat == null) {
    return null;
  }
  return enums.ForumThreadIdPostsGetCat.values.firstWhereOrNull((e) => e.value == forumThreadIdPostsGetCat) ??
      defaultValue;
}

String forumThreadIdPostsGetCatExplodedListToJson(List<enums.ForumThreadIdPostsGetCat>? forumThreadIdPostsGetCat) {
  return forumThreadIdPostsGetCat?.map((e) => e.value!).join(',') ?? '';
}

List<String> forumThreadIdPostsGetCatListToJson(List<enums.ForumThreadIdPostsGetCat>? forumThreadIdPostsGetCat) {
  if (forumThreadIdPostsGetCat == null) {
    return [];
  }

  return forumThreadIdPostsGetCat.map((e) => e.value!).toList();
}

List<enums.ForumThreadIdPostsGetCat> forumThreadIdPostsGetCatListFromJson(
  List? forumThreadIdPostsGetCat, [
  List<enums.ForumThreadIdPostsGetCat>? defaultValue,
]) {
  if (forumThreadIdPostsGetCat == null) {
    return defaultValue ?? [];
  }

  return forumThreadIdPostsGetCat.map((e) => forumThreadIdPostsGetCatFromJson(e.toString())).toList();
}

List<enums.ForumThreadIdPostsGetCat>? forumThreadIdPostsGetCatNullableListFromJson(
  List? forumThreadIdPostsGetCat, [
  List<enums.ForumThreadIdPostsGetCat>? defaultValue,
]) {
  if (forumThreadIdPostsGetCat == null) {
    return defaultValue;
  }

  return forumThreadIdPostsGetCat.map((e) => forumThreadIdPostsGetCatFromJson(e.toString())).toList();
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

String? userIdForumpostsGetCatNullableToJson(enums.UserIdForumpostsGetCat? userIdForumpostsGetCat) {
  return userIdForumpostsGetCat?.value;
}

String? userIdForumpostsGetCatToJson(enums.UserIdForumpostsGetCat userIdForumpostsGetCat) {
  return userIdForumpostsGetCat.value;
}

enums.UserIdForumpostsGetCat userIdForumpostsGetCatFromJson(
  Object? userIdForumpostsGetCat, [
  enums.UserIdForumpostsGetCat? defaultValue,
]) {
  return enums.UserIdForumpostsGetCat.values.firstWhereOrNull((e) => e.value == userIdForumpostsGetCat) ??
      defaultValue ??
      enums.UserIdForumpostsGetCat.swaggerGeneratedUnknown;
}

enums.UserIdForumpostsGetCat? userIdForumpostsGetCatNullableFromJson(
  Object? userIdForumpostsGetCat, [
  enums.UserIdForumpostsGetCat? defaultValue,
]) {
  if (userIdForumpostsGetCat == null) {
    return null;
  }
  return enums.UserIdForumpostsGetCat.values.firstWhereOrNull((e) => e.value == userIdForumpostsGetCat) ?? defaultValue;
}

String userIdForumpostsGetCatExplodedListToJson(List<enums.UserIdForumpostsGetCat>? userIdForumpostsGetCat) {
  return userIdForumpostsGetCat?.map((e) => e.value!).join(',') ?? '';
}

List<String> userIdForumpostsGetCatListToJson(List<enums.UserIdForumpostsGetCat>? userIdForumpostsGetCat) {
  if (userIdForumpostsGetCat == null) {
    return [];
  }

  return userIdForumpostsGetCat.map((e) => e.value!).toList();
}

List<enums.UserIdForumpostsGetCat> userIdForumpostsGetCatListFromJson(
  List? userIdForumpostsGetCat, [
  List<enums.UserIdForumpostsGetCat>? defaultValue,
]) {
  if (userIdForumpostsGetCat == null) {
    return defaultValue ?? [];
  }

  return userIdForumpostsGetCat.map((e) => userIdForumpostsGetCatFromJson(e.toString())).toList();
}

List<enums.UserIdForumpostsGetCat>? userIdForumpostsGetCatNullableListFromJson(
  List? userIdForumpostsGetCat, [
  List<enums.UserIdForumpostsGetCat>? defaultValue,
]) {
  if (userIdForumpostsGetCat == null) {
    return defaultValue;
  }

  return userIdForumpostsGetCat.map((e) => userIdForumpostsGetCatFromJson(e.toString())).toList();
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

String? userForumpostsGetCatNullableToJson(enums.UserForumpostsGetCat? userForumpostsGetCat) {
  return userForumpostsGetCat?.value;
}

String? userForumpostsGetCatToJson(enums.UserForumpostsGetCat userForumpostsGetCat) {
  return userForumpostsGetCat.value;
}

enums.UserForumpostsGetCat userForumpostsGetCatFromJson(
  Object? userForumpostsGetCat, [
  enums.UserForumpostsGetCat? defaultValue,
]) {
  return enums.UserForumpostsGetCat.values.firstWhereOrNull((e) => e.value == userForumpostsGetCat) ??
      defaultValue ??
      enums.UserForumpostsGetCat.swaggerGeneratedUnknown;
}

enums.UserForumpostsGetCat? userForumpostsGetCatNullableFromJson(
  Object? userForumpostsGetCat, [
  enums.UserForumpostsGetCat? defaultValue,
]) {
  if (userForumpostsGetCat == null) {
    return null;
  }
  return enums.UserForumpostsGetCat.values.firstWhereOrNull((e) => e.value == userForumpostsGetCat) ?? defaultValue;
}

String userForumpostsGetCatExplodedListToJson(List<enums.UserForumpostsGetCat>? userForumpostsGetCat) {
  return userForumpostsGetCat?.map((e) => e.value!).join(',') ?? '';
}

List<String> userForumpostsGetCatListToJson(List<enums.UserForumpostsGetCat>? userForumpostsGetCat) {
  if (userForumpostsGetCat == null) {
    return [];
  }

  return userForumpostsGetCat.map((e) => e.value!).toList();
}

List<enums.UserForumpostsGetCat> userForumpostsGetCatListFromJson(
  List? userForumpostsGetCat, [
  List<enums.UserForumpostsGetCat>? defaultValue,
]) {
  if (userForumpostsGetCat == null) {
    return defaultValue ?? [];
  }

  return userForumpostsGetCat.map((e) => userForumpostsGetCatFromJson(e.toString())).toList();
}

List<enums.UserForumpostsGetCat>? userForumpostsGetCatNullableListFromJson(
  List? userForumpostsGetCat, [
  List<enums.UserForumpostsGetCat>? defaultValue,
]) {
  if (userForumpostsGetCat == null) {
    return defaultValue;
  }

  return userForumpostsGetCat.map((e) => userForumpostsGetCatFromJson(e.toString())).toList();
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
