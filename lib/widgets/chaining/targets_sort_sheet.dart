import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_sort.dart';
import 'package:torn_pda/models/chaining/targets_filters.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TargetsSortSheet extends StatefulWidget {
  const TargetsSortSheet({
    super.key,
    required this.currentSort,
  });

  final TargetSortType currentSort;

  @override
  State<TargetsSortSheet> createState() => _TargetsSortSheetState();
}

class _TargetsSortSheetState extends State<TargetsSortSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TargetSortType _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.currentSort;
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(_onTabChanged);
    _loadTabFromPrefs();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTabFromPrefs() async {
    final savedIndex = await Prefs().getTargetsSortTabIndex();
    if (!mounted) return;
    final clamped = savedIndex.clamp(0, 1);
    _tabController.animateTo(clamped.toInt());
  }

  void _onTabChanged() {
    Prefs().setTargetsSortTabIndex(_tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final targetsProvider = Provider.of<TargetsProvider>(context);

    final favorites = TargetSortType.values.where((s) => targetsProvider.favoriteSorts.contains(s.toString())).toList();
    final others = TargetSortType.values.where((s) => !favorites.contains(s)).toList();

    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: themeProvider.secondBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 5,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: themeProvider.mainText,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.pink[700],
            tabs: const [
              Tab(text: 'Sorting'),
              Tab(text: 'Filters'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSortingTab(favorites, others, targetsProvider, themeProvider),
                _buildFiltersTab(targetsProvider),
              ],
            ),
          ),
          const SafeArea(top: false, child: SizedBox(height: 4)),
        ],
      ),
    );
  }

  Widget _buildSortingTab(
    List<TargetSortType> favorites,
    List<TargetSortType> others,
    TargetsProvider provider,
    ThemeProvider themeProvider,
  ) {
    return RadioGroup<TargetSortType>(
      groupValue: _selectedSort,
      onChanged: (TargetSortType? value) {
        if (value == null) return;
        setState(() => _selectedSort = value);
        provider.sortTargets(value);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (favorites.isNotEmpty) ...[
            const Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ...favorites.map((type) => _buildSortTile(type, provider, themeProvider)),
            const Divider(),
            const SizedBox(height: 10),
            const Text('All sort criteria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
          ] else ...[
            const Text('Main sort criteria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
          ],
          ...others.map((type) => _buildSortTile(type, provider, themeProvider)),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSortTile(TargetSortType type, TargetsProvider provider, ThemeProvider themeProvider) {
    final isFav = provider.favoriteSorts.contains(type.toString());
    final isSelected = _selectedSort == type;
    final sort = TargetSort(type: type);

    return Column(
      children: [
        RadioListTile<TargetSortType>(
          value: type,
          title: Text(sort.description),
          secondary: IconButton(
            icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.orange : Colors.grey),
            onPressed: () => provider.toggleFavoriteSort(type),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
        if (isSelected && (type == TargetSortType.hospitalAsc || type == TargetSortType.hospitalDes))
          _buildHospitalSettings(provider, themeProvider),
      ],
    );
  }

  Widget _buildHospitalSettings(TargetsProvider provider, ThemeProvider themeProvider) {
    final dropdownItems = TargetSortType.values
        .where((t) => t != TargetSortType.hospitalAsc && t != TargetSortType.hospitalDes)
        .map((t) => DropdownMenuItem<TargetSortType>(
              value: t,
              child: Text(TargetSort(type: t).description, style: const TextStyle(fontSize: 12)),
            ))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.secondBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Show non-hospital at top", style: TextStyle(fontSize: 14)),
              subtitle: const Text("Okay targets appear first when sorting by hospital.",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: provider.hospitalOkayAtTop,
              onChanged: (val) {
                provider.setHospitalOkayAtTop(val);
                setState(() {});
              },
              dense: true,
            ),
            if (provider.hospitalOkayAtTop)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Secondary sort for non-hospital", style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButton<TargetSortType>(
                      value: provider.secondarySortForOkay,
                      isExpanded: true,
                      isDense: true,
                      underline: Container(height: 1, color: Colors.grey),
                      items: dropdownItems,
                      onChanged: (TargetSortType? newValue) {
                        if (newValue != null) {
                          provider.setSecondarySortForOkay(newValue);
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Used to sort targets that are NOT in hospital when 'Okay at top' is active.",
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersTab(TargetsProvider provider) {
    TargetsFilters local = TargetsFilters(
      enabled: provider.filters.enabled,
      levelRange: provider.filters.levelRange,
      lifeRange: provider.filters.lifeRange,
      fairFightRange: provider.filters.fairFightRange,
      hospitalTimeRange: provider.filters.hospitalTimeRange,
    );

    void updateFilters(TargetsFilters next) {
      provider.setFilters(next);
      local = TargetsFilters(
        enabled: next.enabled,
        levelRange: next.levelRange,
        lifeRange: next.lifeRange,
        fairFightRange: next.fairFightRange,
        hospitalTimeRange: next.hospitalTimeRange,
      );
    }

    return StatefulBuilder(
      builder: (context, setStateSB) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Enable Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Only show targets matching these criteria'),
              value: local.enabled,
              onChanged: (val) {
                setStateSB(() {
                  local.enabled = val;
                  updateFilters(local);
                });
              },
            ),
            const Divider(),
            if (!local.enabled)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'Filters are disabled.\nAll targets will be shown.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              const Text('Range Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Filter targets based on specific ranges.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 20),
              _rangeSlider(
                context,
                label: 'Level',
                current: local.levelRange,
                min: 1,
                max: 100,
                divisions: 99,
                formatter: (v) => v.toStringAsFixed(0),
                onChanged: (val) {
                  setStateSB(() {
                    local.levelRange = val;
                    updateFilters(local);
                  });
                },
              ),
              _rangeSlider(
                context,
                label: 'Life',
                current: local.lifeRange,
                min: 0,
                max: 10000,
                divisions: 100,
                formatter: (v) => v.toStringAsFixed(0),
                onChanged: (val) {
                  setStateSB(() {
                    local.lifeRange = val;
                    updateFilters(local);
                  });
                },
              ),
              _rangeSlider(
                context,
                label: 'Fair Fight',
                current: local.fairFightRange,
                min: 1.0,
                max: 3.0,
                divisions: 20,
                formatter: (v) => v.toStringAsFixed(2),
                onChanged: (val) {
                  setStateSB(() {
                    local.fairFightRange = val;
                    updateFilters(local);
                  });
                },
              ),
              _hospitalSlider(
                context,
                label: 'Hospital Time',
                current: local.hospitalTimeRange,
                onChanged: (val) {
                  setStateSB(() {
                    local.hospitalTimeRange = val;
                    updateFilters(local);
                  });
                },
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 50),
          ],
        );
      },
    );
  }

  Widget _rangeSlider(
    BuildContext context, {
    required String label,
    required RangeValues? current,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) formatter,
    required Function(RangeValues?) onChanged,
  }) {
    RangeValues values;
    if (current != null) {
      values = RangeValues(current.start.clamp(min, max), current.end.clamp(min, max));
    } else {
      values = RangeValues(min, max);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Switch(
              value: current != null,
              onChanged: (val) {
                onChanged(val ? RangeValues(min, max) : null);
              },
            ),
          ],
        ),
        if (current != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatter(values.start), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(formatter(values.end), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            labels: RangeLabels(formatter(values.start), formatter(values.end)),
            onChanged: (val) => onChanged(val),
          ),
        ],
      ],
    );
  }

  Widget _hospitalSlider(
    BuildContext context, {
    required String label,
    required RangeValues? current,
    required Function(RangeValues?) onChanged,
  }) {
    const double maxMinutes = 6000; // ~100h

    double toSlider(double mins) => pow(mins / maxMinutes, 0.25).toDouble().clamp(0.0, 1.0);
    double toMinutes(double slider) => maxMinutes * pow(slider, 4);

    String formatTime(double mins) {
      int h = (mins / 60).floor();
      int m = (mins % 60).round();
      if (h > 0) {
        if (m == 0) return '${h}h';
        return '${h}h ${m}m';
      }
      return '${m}m';
    }

    RangeValues values;
    if (current != null) {
      values = RangeValues(toSlider(current.start), toSlider(current.end));
    } else {
      values = const RangeValues(0.0, 1.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Switch(
              value: current != null,
              onChanged: (val) {
                onChanged(val ? const RangeValues(0.0, 1.0) : null);
              },
            ),
          ],
        ),
        if (current != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatTime(toMinutes(values.start)), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(formatTime(toMinutes(values.end)), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          RangeSlider(
            values: values,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            labels: RangeLabels(
              formatTime(toMinutes(values.start)),
              formatTime(toMinutes(values.end)),
            ),
            onChanged: (val) {
              final mins = RangeValues(toMinutes(val.start), toMinutes(val.end));
              onChanged(mins);
            },
          ),
        ],
      ],
    );
  }
}
