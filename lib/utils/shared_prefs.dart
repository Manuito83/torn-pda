import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SharedPreferencesModel {
  ///
  /// Instantiation of the SharedPreferences library
  ///
  final String _kAppVersion = "pda_appVersion";
  final String _kOwnDetails = "pda_ownDetails";
  final String _kTargetsList = "pda_targetsList";
  final String _kTargetsSort = "pda_targetsSort";
  final String _kAttacksSort = "pda_attacksSort";
  final String _kFriendsList = "pda_friendsList";
  final String _kFriendsSort = "pda_friendsSort";
  final String _kTheme = "pda_theme";
  final String _kDefaultSection = "pda_defaultSection";
  final String _kDefaultBrowser = "pda_defaultBrowser";
  final String _kTravelNotificationTitle = "pda_travelNotificationTitle";
  final String _kTravelNotificationBody = "pda_travelNotificationBody";
  final String _kStockCountryFilter = "pda_stockCountryFilter";
  final String _kStockTypeFilter = "pda_stockTypeFilter";
  final String _kStockSort = "pda_stockSort";
  final String _kStockCapacity = "pda_stockCapacity";

  /// This is use for transitioning from v1.2.0 onwards. After 1.2.0, use
  /// UserDetailsProvider for retrieving the API key and other details!
  @deprecated
  final String _kApiKey = "pda_apiKey";

  /// ----------------------------
  /// Methods for app version
  /// ----------------------------
  Future<String> getAppVersion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAppVersion) ?? "";
  }

  Future<bool> setAppVersion(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAppVersion, value);
  }

  /// ----------------------------
  /// Methods for identification
  /// ----------------------------
  Future<String> getOwnDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kOwnDetails) ?? "";
  }

  Future<bool> setOwnDetails(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kOwnDetails, value);
  }

  /// This is use for transitioning from v1.2.0 onwards. After 1.2.0, use
  /// UserDetailsProvider for retrieving the API key and other details!
  @deprecated
  Future<String> getApiKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kApiKey) ?? "";
  }

  /// This is use for transitioning from v1.2.0 onwards. After 1.2.0, use
  /// UserDetailsProvider for retrieving the API key and other details!
  @deprecated
  Future<bool> setApiKey(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kApiKey, value);
  }

  /// ----------------------------
  /// Methods for targets
  /// ----------------------------
  Future<List<String>> getTargetsList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kTargetsList) ?? List<String>();
  }

  Future<bool> setTargetsList(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kTargetsList, value);
  }

  //**************
  Future<String> getTargetsSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTargetsSort) ?? '';
  }

  Future<bool> setTargetsSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTargetsSort, value);
  }

  /// ----------------------------
  /// Methods for attacks
  /// ----------------------------
  Future<String> getAttackSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAttacksSort) ?? '';
  }

  Future<bool> setAttackSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAttacksSort, value);
  }

  /// ----------------------------
  /// Methods for friends
  /// ----------------------------
  Future<List<String>> getFriendsList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kFriendsList) ?? List<String>();
  }

  Future<bool> setFriendsList(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kFriendsList, value);
  }

  //**************
  Future<String> getFriendsSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFriendsSort) ?? '';
  }

  Future<bool> setFriendsSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kFriendsSort, value);
  }

  /// ----------------------------
  /// Methods for theme
  /// ----------------------------
  Future<String> getAppTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTheme) ?? 'light';
  }

  Future<bool> setAppTheme(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTheme, value);
  }

  /// ----------------------------
  /// Methods for default launch section
  /// ----------------------------
  Future<String> getDefaultSection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultSection) ?? '0';
  }

  Future<bool> setDefaultSection(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDefaultSection, value);
  }

  /// ----------------------------
  /// Methods for default browser
  /// ----------------------------
  Future<String> getDefaultBrowser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultBrowser) ?? 'app';
  }

  Future<bool> setDefaultBrowser(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDefaultBrowser, value);
  }

  /// ----------------------------
  /// Methods for travel options
  /// ----------------------------
  Future<String> getTravelNotificationTitle() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTravelNotificationTitle) ?? 'TORN TRAVEL';
  }

  Future<bool> setTravelNotificationTitle(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTravelNotificationTitle, value);
  }

  Future<String> getTravelNotificationBody() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTravelNotificationBody) ??
        'Arriving at your destination!';
  }

  Future<bool> setTravelNotificationBody(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTravelNotificationBody, value);
  }

  /// ----------------------------
  /// Methods for foreign stocks
  /// ----------------------------
  Future<List<String>> getStockCountryFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kStockCountryFilter) ??
        List<String>.filled(12, '1', growable: false);
  }

  Future<bool> setStockCountryFilter(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kStockCountryFilter, value);
  }

  Future<List<String>> getStockTypeFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kStockTypeFilter) ??
        List<String>.filled(4, '1', growable: false);
  }

  Future<bool> setStockTypeFilter(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kStockTypeFilter, value);
  }

  Future<String> getStockSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kStockSort) ?? 'profit';
  }

  Future<bool> setStockSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kStockSort, value);
  }

  Future<int> getStockCapacity() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStockCapacity) ?? 1;
  }

  Future<bool> setStockCapacity(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kStockCapacity, value);
  }

}
