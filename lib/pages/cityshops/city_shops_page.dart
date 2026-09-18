import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/cityshops/city_shop_item_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/widgets/cityshops/city_shop_item_tile.dart';

enum _RestockSpeed {
  fast("Fast (under 1 h)"),
  medium("Medium (1 to 3 h)"),
  slow("Slow (over 3 h)");

  const _RestockSpeed(this.label);

  final String label;
}

class CityShopsPage extends StatefulWidget {
  const CityShopsPage({super.key});

  @override
  State<CityShopsPage> createState() => _CityShopsPageState();
}

class _CityShopsPageState extends State<CityShopsPage> {
  Future<void>? _loadFuture;
  Timer? _refreshTimer;
  bool _loading = false;

  List<CityShopItemModel> _items = [];
  Map<String, dynamic> _activeAlerts = {};
  bool _loadError = false;

  final _searchController = TextEditingController();
  String _search = "";
  String? _selectedShop;
  CityShopMode? _selectedMode;
  _RestockSpeed? _selectedSpeed;
  bool _onlySubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_loading || !mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
      _load(withAlerts: false);
    });
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool withAlerts = true}) async {
    _loading = true;
    bool error = false;
    var items = <CityShopItemModel>[];
    var active = <String, dynamic>{};
    try {
      final fetched = await FirestoreHelper().getCityShopItems();
      if (fetched == null) {
        error = true;
      } else {
        items = fetched;
      }
      if (withAlerts) {
        final loadedAlerts = await _loadActiveAlerts();
        if (loadedAlerts == null) {
          error = true;
        } else {
          active = loadedAlerts;
        }
      }
    } catch (e) {
      error = true;
    }
    _loading = false;
    if (!mounted || (error && !withAlerts)) return;
    setState(() {
      _items = items;
      if (withAlerts) _activeAlerts = active;
      _loadError = error;
      if (!error && _selectedShop != null && !_shopStillVisible(_selectedShop, items, _activeAlerts)) {
        _selectedShop = null;
      }
    });
  }

  // Player document map; null on failure, so the caller shows a page error instead of stale data
  Future<Map<String, dynamic>?> _loadActiveAlerts() async {
    try {
      return await FirestoreHelper().getCityShopActiveAlerts();
    } catch (e) {
      return null;
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    await _load();
  }

  Future<void> _toggleAlert(CityShopItemModel item) async {
    final tempMap = Map<String, dynamic>.from(_activeAlerts);
    final adding = !tempMap.containsKey(item.key);
    if (adding) {
      tempMap[item.key] = DateTime.now().millisecondsSinceEpoch;
    } else {
      tempMap.remove(item.key);
    }
    final success = await FirestoreHelper().setCityShopActiveAlert(item.key, adding);
    if (!mounted) return;
    if (!success) {
      BotToast.showText(
        text: "Could not update, check your connection",
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.orange[900]!,
        duration: const Duration(seconds: 4),
        contentPadding: const EdgeInsets.all(10),
      );
      return;
    }
    setState(() {
      _activeAlerts = tempMap;
      if (_selectedShop != null && !_shopStillVisible(_selectedShop, _items, tempMap)) {
        _selectedShop = null;
      }
    });
  }

  // Items gone from the shop are hidden everywhere unless the player is still subscribed to them
  List<CityShopItemModel> get _visibleItems {
    return _items.where((item) => !item.gone || _activeAlerts.containsKey(item.key)).toList();
  }

  bool _shopStillVisible(String? shop, List<CityShopItemModel> items, Map<String, dynamic> alerts) {
    return items.any((item) => (!item.gone || alerts.containsKey(item.key)) && item.shop == shop);
  }

  List<CityShopItemModel> get _filteredItems {
    return _visibleItems.where((item) {
      if (_search.isNotEmpty) {
        final name = (item.item ?? "").toLowerCase();
        final shop = (item.shop ?? "").toLowerCase();
        if (!name.contains(_search) && !shop.contains(_search)) return false;
      }
      if (_selectedShop != null && item.shop != _selectedShop) return false;
      if (_selectedMode != null && item.mode != _selectedMode) return false;
      if (!_matchesSpeed(item)) return false;
      if (_onlySubscribed && !_activeAlerts.containsKey(item.key)) return false;
      return true;
    }).toList();
  }

  bool _matchesSpeed(CityShopItemModel item) {
    if (_selectedSpeed == null) return true;
    final baseMin = item.baseMin;
    if (baseMin == null) return false;
    return switch (_selectedSpeed!) {
      _RestockSpeed.fast => baseMin < 60,
      _RestockSpeed.medium => baseMin >= 60 && baseMin <= 180,
      _RestockSpeed.slow => baseMin > 180,
    };
  }

  List<String> get _shopNames {
    final names = _visibleItems.map((e) => e.shop ?? "Unknown shop").toSet().toList();
    names.sort();
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.canvas,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("City shops", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showInfo(themeProvider),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(onRefresh: _refresh, child: _buildList(themeProvider));
        },
      ),
    );
  }

  Widget _buildList(ThemeProvider themeProvider) {
    final filtered = _filteredItems;
    final shops = filtered.map((e) => e.shop ?? "Unknown shop").toSet().toList()..sort();

    final children = <Widget>[_searchAndFilters(themeProvider)];

    if (_loadError) {
      children.add(
        _message(themeProvider, "Could not load city shop data. Check your connection and pull down to retry."),
      );
    } else if (filtered.isEmpty) {
      children.add(
        _message(
          themeProvider,
          _items.isEmpty ? "No city shop data available yet. Pull down to refresh." : "No items match these filters",
        ),
      );
    } else {
      for (final shop in shops) {
        final shopItems = filtered.where((e) => (e.shop ?? "Unknown shop") == shop).toList()
          ..sort((a, b) => (a.item ?? "").compareTo(b.item ?? ""));
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              shop,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeProvider.mainText),
            ),
          ),
        );
        children.addAll(
          shopItems.map(
            (item) => CityShopItemTile(
              item: item,
              subscribed: _activeAlerts.containsKey(item.key),
              onToggleAlert: _toggleAlert,
            ),
          ),
        );
      }
    }

    children.add(const SizedBox(height: 30));

    return ListView(physics: const AlwaysScrollableScrollPhysics(), children: children);
  }

  void _showInfo(ThemeProvider themeProvider) {
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeProvider.secondBackground,
          title: Text("How these alerts work", style: TextStyle(fontSize: 16, color: themeProvider.mainText)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(
                  themeProvider,
                  CityShopMode.headsUp,
                  "Alerts you a few minutes before the restock is due, and shows the window it is expected in.",
                ),
                _infoLine(
                  themeProvider,
                  CityShopMode.onRestock,
                  "Its restock can't be predicted with 95% reliability or more, so it alerts you as soon as the "
                  "restock is seen.",
                ),
                _infoLine(
                  themeProvider,
                  CityShopMode.noData,
                  "Not seen restocking often enough yet. It will move up on its own once there is enough data.",
                ),
                Text(
                  "Tap the bell to follow an item, or the item itself to see what has been measured for it.",
                  style: TextStyle(fontSize: 12, color: themeProvider.mainText),
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close"))],
        );
      },
    );
  }

  Widget _infoLine(ThemeProvider themeProvider, CityShopMode mode, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CityShopModeBadge(label: mode.label, color: mode.color),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(fontSize: 12, color: themeProvider.mainText)),
        ],
      ),
    );
  }

  Widget _searchAndFilters(ThemeProvider themeProvider) {
    final outline = themeProvider.mainText.withAlpha(45);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: themeProvider.secondBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13, color: themeProvider.mainText),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 34),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _searchController.clear()),
                hintText: "Search item or shop",
                hintStyle: TextStyle(fontSize: 13, color: themeProvider.mainText.withAlpha(120)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: outline),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _shopDropdown(themeProvider, outline)),
                const SizedBox(width: 8),
                _chip(
                  themeProvider,
                  label: "Following",
                  selected: _onlySubscribed,
                  accent: Colors.blue,
                  icon: _onlySubscribed ? Icons.notifications_active : Icons.notifications_none,
                  onTap: () => setState(() => _onlySubscribed = !_onlySubscribed),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _chipGroup(themeProvider, "Alert mode", [
              _chip(
                themeProvider,
                label: "All",
                selected: _selectedMode == null,
                onTap: () => setState(() => _selectedMode = null),
              ),
              for (final mode in CityShopMode.values)
                _chip(
                  themeProvider,
                  label: mode.label,
                  selected: _selectedMode == mode,
                  accent: mode.color,
                  onTap: () => setState(() => _selectedMode = mode),
                ),
            ]),
            const SizedBox(height: 12),
            _chipGroup(themeProvider, "Restock speed", [
              _chip(
                themeProvider,
                label: "All",
                selected: _selectedSpeed == null,
                onTap: () => setState(() => _selectedSpeed = null),
              ),
              for (final speed in _RestockSpeed.values)
                _chip(
                  themeProvider,
                  label: speed.label,
                  selected: _selectedSpeed == speed,
                  onTap: () => setState(() => _selectedSpeed = speed),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _chipGroup(ThemeProvider themeProvider, String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: themeProvider.mainText.withAlpha(140),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: chips),
      ],
    );
  }

  Widget _chip(
    ThemeProvider themeProvider, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? accent,
    IconData? icon,
  }) {
    final color = accent ?? themeProvider.mainText;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      backgroundColor: Colors.transparent,
      selectedColor: color.withAlpha(40),
      side: BorderSide(color: selected ? color : themeProvider.mainText.withAlpha(60)),
      avatar: icon == null
          ? null
          : Icon(icon, size: 14, color: selected ? color : themeProvider.mainText.withAlpha(140)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? color : themeProvider.mainText.withAlpha(180),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _shopDropdown(ThemeProvider themeProvider, Color outline) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedShop,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          dropdownColor: themeProvider.secondBackground,
          style: TextStyle(fontSize: 12, color: themeProvider.mainText),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text("All shops", style: TextStyle(fontSize: 12, color: themeProvider.mainText)),
            ),
            for (final shop in _shopNames)
              DropdownMenuItem<String?>(
                value: shop,
                child: Text(
                  shop,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: themeProvider.mainText),
                ),
              ),
          ],
          onChanged: (value) => setState(() => _selectedShop = value),
        ),
      ),
    );
  }

  Widget _message(ThemeProvider themeProvider, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: themeProvider.mainText.withAlpha(180)),
          ),
        ),
      ),
    );
  }
}
