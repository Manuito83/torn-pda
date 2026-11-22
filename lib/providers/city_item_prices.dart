import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';

const _timeout = Duration(seconds: 10);

// Names and values of map items
class CityItemPrices extends ChangeNotifier {
  CityItemPrices(this._fetch, {Duration timeout = _timeout, void Function()? onFailed})
    : _limit = timeout,
      _onFailed = onFailed;

  final Future<List<Item>> Function() _fetch;
  final void Function()? _onFailed;
  final Duration _limit;

  List<Item> _all = const [];
  List<String> _onMap = const [];
  int _request = 0;
  bool _disposed = false;

  bool loading = false;
  bool failed = false;

  // In the order of the map
  List<Item> get found => cityFinderItems(_all, _onMap);

  Map<int, CityItemPrice> get byItem => cityItemPrices(_all);

  Future<void> load(List<String> onMap) {
    _onMap = onMap;
    return retry();
  }

  // Refreshing known prices stays silent
  Future<void> retry() async {
    final request = ++_request;
    loading = _all.isEmpty;
    failed = false;
    _notify();
    try {
      final all = await _fetch().timeout(_limit);
      if (request != _request) return;
      _all = all;
    } catch (e) {
      if (request != _request) return;
      debugPrint('city item prices: $e');
      failed = _all.isEmpty;
      if (failed) _onFailed?.call();
    }
    loading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
