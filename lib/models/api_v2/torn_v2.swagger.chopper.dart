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
  Future<Response<FactionSelectionsHofGet$Response>> _factionSelectionsHofGet({
    required String? key,
    int? id,
  }) {
    final Uri $url = Uri.parse('/faction/?selections=hof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionSelectionsHofGet$Response,
        FactionSelectionsHofGet$Response>($request);
  }

  @override
  Future<Response<FactionSelectionsMembersGet$Response>>
      _factionSelectionsMembersGet({
    required String? key,
    int? id,
    String? striptags,
  }) {
    final Uri $url = Uri.parse('/faction/?selections=members');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
      'striptags': striptags,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionSelectionsMembersGet$Response,
        FactionSelectionsMembersGet$Response>($request);
  }

  @override
  Future<Response<FactionSelectionsBasicGet$Response>>
      _factionSelectionsBasicGet({
    required String? key,
    int? id,
  }) {
    final Uri $url = Uri.parse('/faction/?selections=basic');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionSelectionsBasicGet$Response,
        FactionSelectionsBasicGet$Response>($request);
  }

  @override
  Future<Response<FactionSelectionsWarsGet$Response>>
      _factionSelectionsWarsGet({
    required String? key,
    int? id,
  }) {
    final Uri $url = Uri.parse('/faction/?selections=wars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<FactionSelectionsWarsGet$Response,
        FactionSelectionsWarsGet$Response>($request);
  }

  @override
  Future<Response<FactionSelectionsNewsGet$Response>>
      _factionSelectionsNewsGet({
    required String? key,
    String? striptags,
    int? limit,
    String? sort,
    int? to,
    int? from,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/faction/?selections=news');
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
    return client.send<FactionSelectionsNewsGet$Response,
        FactionSelectionsNewsGet$Response>($request);
  }

  @override
  Future<Response<FactionSelectionsAttacksGet$Response>>
      _factionSelectionsAttacksGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/?selections=attacks');
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
    return client.send<FactionSelectionsAttacksGet$Response,
        FactionSelectionsAttacksGet$Response>($request);
  }

  @override
  Future<Response<FactionSelectionsAttacksfullGet$Response>>
      _factionSelectionsAttacksfullGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/faction/?selections=attacksfull');
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
    return client.send<FactionSelectionsAttacksfullGet$Response,
        FactionSelectionsAttacksfullGet$Response>($request);
  }

  @override
  Future<Response<ForumCategories>> _forumSelectionsCategoriesGet(
      {required String? key}) {
    final Uri $url = Uri.parse('/forum/?selections=categories');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumCategories, ForumCategories>($request);
  }

  @override
  Future<Response<ForumSelectionsThreadsGet$Response>>
      _forumSelectionsThreadsGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
    List<int>? id,
  }) {
    final Uri $url = Uri.parse('/forum/?selections=threads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'limit': limit,
      'sort': sort,
      'to': to,
      'from': from,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumSelectionsThreadsGet$Response,
        ForumSelectionsThreadsGet$Response>($request);
  }

  @override
  Future<Response<ForumSelectionsThreadGet$Response>>
      _forumSelectionsThreadGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/forum/?selections=thread');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumSelectionsThreadGet$Response,
        ForumSelectionsThreadGet$Response>($request);
  }

  @override
  Future<Response<ForumSelectionsPostsGet$Response>> _forumSelectionsPostsGet({
    required String? key,
    int? offset,
    String? cat,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/forum/?selections=posts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'offset': offset,
      'cat': cat,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<ForumSelectionsPostsGet$Response,
        ForumSelectionsPostsGet$Response>($request);
  }

  @override
  Future<Response<MarketSelectionsItemmarketGet$Response>>
      _marketSelectionsItemmarketGet({
    required String? key,
    required String? id,
    String? cat,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/market/?selections=itemmarket');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
      'cat': cat,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<MarketSelectionsItemmarketGet$Response,
        MarketSelectionsItemmarketGet$Response>($request);
  }

  @override
  Future<Response<Races>> _racingSelectionsRacesGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? cat,
  }) {
    final Uri $url = Uri.parse('/racing/?selections=races');
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
    return client.send<Races, Races>($request);
  }

  @override
  Future<Response<RaceRecords>> _racingSelectionsRecordsGet({
    required String? key,
    required int? id,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/racing/?selections=records');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
      'cat': cat,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RaceRecords, RaceRecords>($request);
  }

  @override
  Future<Response<RaceDetails>> _racingSelectionsRaceGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/racing/?selections=race');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RaceDetails, RaceDetails>($request);
  }

  @override
  Future<Response<RaceCars>> _racingSelectionsCarsGet({required String? key}) {
    final Uri $url = Uri.parse('/racing/?selections=cars');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RaceCars, RaceCars>($request);
  }

  @override
  Future<Response<RaceTracks>> _racingSelectionsTracksGet(
      {required String? key}) {
    final Uri $url = Uri.parse('/racing/?selections=tracks');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RaceTracks, RaceTracks>($request);
  }

  @override
  Future<Response<RaceCarUpgrades>> _racingSelectionsCarupgradesGet(
      {required String? key}) {
    final Uri $url = Uri.parse('/racing/?selections=carupgrades');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<RaceCarUpgrades, RaceCarUpgrades>($request);
  }

  @override
  Future<Response<TornSubcrimes>> _tornSelectionsSubcrimesGet({
    required String? key,
    required String? id,
  }) {
    final Uri $url = Uri.parse('/torn/?selections=subcrimes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornSubcrimes, TornSubcrimes>($request);
  }

  @override
  Future<Response<TornCrimes>> _tornSelectionsCrimesGet(
      {required String? key}) {
    final Uri $url = Uri.parse('/torn/?selections=crimes');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornCrimes, TornCrimes>($request);
  }

  @override
  Future<Response<TornSelectionsCalendarGet$Response>>
      _tornSelectionsCalendarGet({required String? key}) {
    final Uri $url = Uri.parse('/torn/?selections=calendar');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornSelectionsCalendarGet$Response,
        TornSelectionsCalendarGet$Response>($request);
  }

  @override
  Future<Response<TornSelectionsHofGet$Response>> _tornSelectionsHofGet({
    required String? key,
    int? limit,
    int? offset,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/torn/?selections=hof');
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
    return client.send<TornSelectionsHofGet$Response,
        TornSelectionsHofGet$Response>($request);
  }

  @override
  Future<Response<TornSelectionsFactionhofGet$Response>>
      _tornSelectionsFactionhofGet({
    required String? key,
    int? limit,
    int? offset,
    required String? cat,
  }) {
    final Uri $url = Uri.parse('/torn/?selections=factionhof');
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
    return client.send<TornSelectionsFactionhofGet$Response,
        TornSelectionsFactionhofGet$Response>($request);
  }

  @override
  Future<Response<TornSelectionsLogtypesGet$Response>>
      _tornSelectionsLogtypesGet({
    required String? key,
    int? id,
  }) {
    final Uri $url = Uri.parse('/torn/?selections=logtypes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornSelectionsLogtypesGet$Response,
        TornSelectionsLogtypesGet$Response>($request);
  }

  @override
  Future<Response<TornSelectionsLogcategoriesGet$Response>>
      _tornSelectionsLogcategoriesGet({required String? key}) {
    final Uri $url = Uri.parse('/torn/?selections=logcategories');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<TornSelectionsLogcategoriesGet$Response,
        TornSelectionsLogcategoriesGet$Response>($request);
  }

  @override
  Future<Response<TornSelectionsBountiesGet$Response>>
      _tornSelectionsBountiesGet({
    required String? key,
    int? limit,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/torn/?selections=bounties');
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
    return client.send<TornSelectionsBountiesGet$Response,
        TornSelectionsBountiesGet$Response>($request);
  }

  @override
  Future<Response<UserCrimeDetails>> _userSelectionsCrimesGet({
    required String? key,
    required String? id,
  }) {
    final Uri $url = Uri.parse('/user/?selections=crimes');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserCrimeDetails, UserCrimeDetails>($request);
  }

  @override
  Future<Response<RaceDetails>> _userSelectionsRacesGet({
    required String? key,
    int? limit,
    String? sort,
    int? to,
    int? from,
    String? cat,
  }) {
    final Uri $url = Uri.parse('/user/?selections=races');
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
    return client.send<RaceDetails, RaceDetails>($request);
  }

  @override
  Future<Response<UserRaceCarDetails>> _userSelectionsEnlistedcarsGet(
      {required String? key}) {
    final Uri $url = Uri.parse('/user/?selections=enlistedcars');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserRaceCarDetails, UserRaceCarDetails>($request);
  }

  @override
  Future<Response<UserSelectionsForumpostsGet$Response>>
      _userSelectionsForumpostsGet({
    required String? key,
    String? cat,
    required int? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/?selections=forumposts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'cat': cat,
      'id': id,
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
    return client.send<UserSelectionsForumpostsGet$Response,
        UserSelectionsForumpostsGet$Response>($request);
  }

  @override
  Future<Response<UserSelectionsForumthreadsGet$Response>>
      _userSelectionsForumthreadsGet({
    required String? key,
    required int? id,
    int? limit,
    String? sort,
    int? to,
    int? from,
  }) {
    final Uri $url = Uri.parse('/user/?selections=forumthreads');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
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
    return client.send<UserSelectionsForumthreadsGet$Response,
        UserSelectionsForumthreadsGet$Response>($request);
  }

  @override
  Future<Response<UserSelectionsForumsubscribedthreadsGet$Response>>
      _userSelectionsForumsubscribedthreadsGet({required String? key}) {
    final Uri $url = Uri.parse('/user/?selections=forumsubscribedthreads');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserSelectionsForumsubscribedthreadsGet$Response,
        UserSelectionsForumsubscribedthreadsGet$Response>($request);
  }

  @override
  Future<Response<UserSelectionsForumfeedGet$Response>>
      _userSelectionsForumfeedGet({required String? key}) {
    final Uri $url = Uri.parse('/user/?selections=forumfeed');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserSelectionsForumfeedGet$Response,
        UserSelectionsForumfeedGet$Response>($request);
  }

  @override
  Future<Response<UserSelectionsForumfriendsGet$Response>>
      _userSelectionsForumfriendsGet({required String? key}) {
    final Uri $url = Uri.parse('/user/?selections=forumfriends');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserSelectionsForumfriendsGet$Response,
        UserSelectionsForumfriendsGet$Response>($request);
  }

  @override
  Future<Response<UserSelectionsHofGet$Response>> _userSelectionsHofGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/user/?selections=hof');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserSelectionsHofGet$Response,
        UserSelectionsHofGet$Response>($request);
  }

  @override
  Future<Response<UserSelectionsCalendarGet$Response>>
      _userSelectionsCalendarGet({required String? key}) {
    final Uri $url = Uri.parse('/user/?selections=calendar');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserSelectionsCalendarGet$Response,
        UserSelectionsCalendarGet$Response>($request);
  }

  @override
  Future<Response<UserSelectionsBountiesGet$Response>>
      _userSelectionsBountiesGet({
    required String? key,
    required int? id,
  }) {
    final Uri $url = Uri.parse('/user/?selections=bounties');
    final Map<String, dynamic> $params = <String, dynamic>{
      'key': key,
      'id': id,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserSelectionsBountiesGet$Response,
        UserSelectionsBountiesGet$Response>($request);
  }

  @override
  Future<Response<UserSelectionsJobranksGet$Response>>
      _userSelectionsJobranksGet({required String? key}) {
    final Uri $url = Uri.parse('/user/?selections=jobranks');
    final Map<String, dynamic> $params = <String, dynamic>{'key': key};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<UserSelectionsJobranksGet$Response,
        UserSelectionsJobranksGet$Response>($request);
  }

  @override
  Future<Response<UserSelectionsItemmarketGet$Response>>
      _userSelectionsItemmarketGet({
    required String? key,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/user/?selections=itemmarket');
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
    return client.send<UserSelectionsItemmarketGet$Response,
        UserSelectionsItemmarketGet$Response>($request);
  }
}
