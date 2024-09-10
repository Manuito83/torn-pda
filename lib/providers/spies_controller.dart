// Flutter imports:
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/tornstats/tornstats_spies_model.dart';
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/providers/user_controller.dart';

// Project imports:
import 'package:torn_pda/utils/shared_prefs.dart';

enum SpiesSource {
  yata,
  tornStats,
}

class SpiesController extends GetxController {
  final UserController _u = Get.put(UserController());

  http.Client? _httpClient;
  bool _isCancelled = false;

  @override
  onInit() {
    super.onInit();
    _restoreSpies();
    _httpClient = http.Client();
  }

  @override
  void onClose() {
    _httpClient?.close();
    super.onClose();
  }

  SpiesSource? _spiesSource;
  SpiesSource? get spiesSource => _spiesSource;
  set spiesSource(SpiesSource? value) {
    _spiesSource = value;
    _spiesSource == SpiesSource.yata ? Prefs().setSpiesSource('yata') : Prefs().setSpiesSource('tornstats');
    update();
  }

  DateTime? _yataSpiesTime;
  DateTime? get yataSpiesTime => _yataSpiesTime;
  set yataSpiesTime(DateTime? value) {
    _yataSpiesTime = value;
    saveSpies();
    update();
  }

  DateTime? _tornStatsSpiesTime;
  DateTime? get tornStatsSpiesTime => _tornStatsSpiesTime;
  set tornStatsSpiesTime(DateTime? value) {
    _tornStatsSpiesTime = value;
    saveSpies();
    update();
  }

  List<YataSpyModel> _yataSpies = <YataSpyModel>[];
  List<YataSpyModel> get yataSpies => _yataSpies;
  set yataSpies(List<YataSpyModel> value) {
    _yataSpies = value;
    saveSpies();
    update();
  }

  TornStatsSpiesModel _tornStatsSpies = TornStatsSpiesModel()..spies = <SpyElement>[];
  TornStatsSpiesModel get tornStatsSpies => _tornStatsSpies;
  set tornStatsSpies(TornStatsSpiesModel value) {
    _tornStatsSpies = value;
    saveSpies();
    update();
  }

  bool _allowMixedSpiesSources = true;
  bool get allowMixedSpiesSources => _allowMixedSpiesSources;
  set allowMixedSpiesSources(bool value) {
    _allowMixedSpiesSources = value;
    Prefs().setAllowMixedSpiesSources(value);
    update();
  }

  void saveSpies() {
    if (_spiesSource == SpiesSource.yata) {
      List<String> yataSpiesSave = <String>[];
      for (final YataSpyModel spy in _yataSpies) {
        final String spyJson = yataSpyModelToJson(spy);
        yataSpiesSave.add(spyJson);
      }
      Prefs().setYataSpies(yataSpiesSave);
      Prefs().setYataSpiesTime(yataSpiesTime!.millisecondsSinceEpoch);
    } else {
      Prefs().setTornStatsSpies(tornStatsSpiesModelToJson(_tornStatsSpies));
      Prefs().setTornStatsSpiesTime(tornStatsSpiesTime!.millisecondsSinceEpoch);
    }
  }

  Future _restoreSpies() async {
    String source = await Prefs().getSpiesSource();
    source == "yata" ? spiesSource = SpiesSource.yata : spiesSource = SpiesSource.tornStats;

    // Load YATA
    _yataSpiesTime = DateTime.fromMillisecondsSinceEpoch(await Prefs().getYataSpiesTime());
    List<String> savedYataSpies = await Prefs().getYataSpies();
    for (final String spyJson in savedYataSpies) {
      final YataSpyModel spyModel = yataSpyModelFromJson(spyJson);
      _yataSpies.add(spyModel);
    }

    // Load TS
    _tornStatsSpiesTime = DateTime.fromMillisecondsSinceEpoch(await Prefs().getTornStatsSpiesTime());
    final String savedTornStatsSpies = await Prefs().getTornStatsSpies();
    if (savedTornStatsSpies.isNotEmpty) {
      _tornStatsSpies = tornStatsSpiesModelFromJson(savedTornStatsSpies);
    }
  }

  Future deleteSpies() async {
    _yataSpiesTime = DateTime.fromMillisecondsSinceEpoch(0);
    _yataSpies = <YataSpyModel>[];
    _tornStatsSpiesTime = DateTime.fromMillisecondsSinceEpoch(0);
    _tornStatsSpies = TornStatsSpiesModel()..spies = <SpyElement>[];
    saveSpies();
    update();
  }

  String formatUpdateString(int timestamp) {
    DateTime now = DateTime.now();
    DateTime timestampDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    Duration difference = now.difference(timestampDate);

    String format(int amount, String singular, String plural) {
      if (amount == 0) return "";
      return "$amount ${amount == 1 ? singular : plural}";
    }

    String result = "";
    int months = difference.inDays ~/ 30;
    int days = difference.inDays % 30;
    int hours = difference.inHours % 24;
    int minutes = difference.inMinutes % 60;

    if (months > 0) {
      result += format(months, "month", "months");
      if (days > 0) {
        result += ", ${format(days, "day", "days")}";
      }
    } else if (days > 0) {
      result += format(days, "day", "days");
      if (hours > 0) {
        result += ", ${format(hours, "hour", "hours")}";
      }
    } else if (hours > 0) {
      result += format(hours, "hour", "hours");
      if (minutes > 0) {
        result += ", ${format(minutes, "minute", "minutes")}";
      }
    } else if (minutes > 0) {
      result += format(minutes, "minute", "minutes");
    }

    if (result.isEmpty) {
      return "Updated seconds ago";
    }

    return "Updated: $result ago";
  }

  String statsOld(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return "unknown age";

    timestamp = timestamp * 1000;

    DateTime now = DateTime.now();
    DateTime timestampDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    Duration difference = now.difference(timestampDate);

    int days = difference.inDays;
    int months = days ~/ 30;
    int years = days ~/ 365;

    if (years > 0) {
      return "$years year${years > 1 ? 's' : ''} old";
    } else if (months > 0) {
      return "$months month${months > 1 ? 's' : ''} old";
    } else if (days > 1) {
      return "$days days old";
    } else if (days == 1) {
      return "$days day old";
    } else {
      return "Updated today";
    }
  }

  Future<bool> fetchYataSpies() async {
    List<YataSpyModel> spies = <YataSpyModel>[];
    try {
      _isCancelled = false;
      final String yataURL = 'https://yata.yt/api/v1/spies/?key=${_u.alternativeYataKey}';
      final resp = await _httpClient!.get(Uri.parse(yataURL)).timeout(const Duration(seconds: 120));

      if (_isCancelled) return false;

      if (resp.statusCode == 200) {
        final dynamic spiesJson = json.decode(resp.body);
        if (spiesJson != null) {
          Map<String, dynamic> mainMap = spiesJson as Map<String, dynamic>;
          Map<String, dynamic> spyList = mainMap.entries.first.value;
          spyList.forEach((key, value) {
            final YataSpyModel spyModel = yataSpyModelFromJson(json.encode(value));
            spies.add(spyModel);
          });
        }
      } else {
        log("Error fetching Yata spies: ${resp.statusCode}");
        return false;
      }
    } catch (e) {
      if (!_isCancelled) log("Error fetching Yata spies: $e");
      return false;
    }

    if (!_isCancelled) {
      yataSpiesTime = DateTime.now();
      yataSpies = spies;
      return true;
    }

    return false;
  }

  Future<bool> fetchTornStatsSpies() async {
    try {
      _isCancelled = false;
      final String tornStatsURL = 'https://www.tornstats.com/api/v1/${_u.alternativeTornStatsKey}/faction/spies';
      final resp = await _httpClient!.get(Uri.parse(tornStatsURL)).timeout(const Duration(seconds: 120));

      if (_isCancelled) return false;

      if (resp.statusCode == 200) {
        final TornStatsSpiesModel spyJson = tornStatsSpiesModelFromJson(resp.body);
        if (!spyJson.message!.contains("Error")) {
          tornStatsSpiesTime = DateTime.now();
          tornStatsSpies = spyJson;
          return true;
        }
      }
    } catch (e) {
      if (!_isCancelled) log("Error fetching TornStats spies: $e");
    }

    return false;
  }

  void cancelRequests() {
    _isCancelled = true;
    _httpClient?.close();
    _httpClient = http.Client();
  }

  // Allow name lookup for YATA as old spies will be missing the ID
  YataSpyModel? getYataSpy({required String userId, String? name}) {
    if (name == null) {
      return _yataSpies.firstWhereOrNull((spy) => spy.targetId == userId);
    } else {
      YataSpyModel? namedResponse;
      // This looks weird, but it's to ensure that the ID will always take priority. Either an ID match is found,
      // or the last matching name is returned. This is to ensure that if a user changes names with someone,
      // their spies will not be mixed unless the spy data is missing their ID.
      return _yataSpies.firstWhereOrNull((spy) {
            if (spy.targetName == name) {
              namedResponse = spy;
            }
            return spy.targetId == userId;
          }) ??
          namedResponse;
    }
  }

  SpyElement? getTornStatsSpy({required String userId}) {
    return _tornStatsSpies.spies.firstWhereOrNull((spy) => spy.playerId == userId);
  }
}
