// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/war_settings.dart';
import 'package:torn_pda/models/chaining/war_sort.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class WarSettingsDialog extends StatefulWidget {
  @override
  WarSettingsDialogState createState() => WarSettingsDialogState();
}

class WarSettingsDialogState extends State<WarSettingsDialog> with SingleTickerProviderStateMixin {
  bool _applyFiltersInPreview = false;
  late TabController _tabController;
  final WarController _warController = Get.find<WarController>();
  late WarSettings _settings;

  // Dynamic Max Values
  double _maxStats = 1000000000;
  double _maxStr = 1000000000;
  double _maxDef = 1000000000;
  double _maxSpd = 1000000000;
  double _maxDex = 1000000000;

  @override
  void initState() {
    super.initState();
    _settings = _warController.warSettings;
    _tabController = TabController(length: 3, vsync: this, initialIndex: _settings.lastSettingsTabIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _settings.lastSettingsTabIndex = _tabController.index;
        _warController.savePreferences();
      }
    });

    _warController.calculateAttributeRanges();
    _calculateMaxStats();
  }

  void _calculateMaxStats() {
    double maxS = 0;
    double maxStr = 0;
    double maxDef = 0;
    double maxSpd = 0;
    double maxDex = 0;
    double maxHosp = 0;

    for (var faction in _warController.factions) {
      if (faction.members != null) {
        for (var member in faction.members!.values) {
          if (member == null) continue;
          // Total Stats
          double total = _warController.getMemberTotalStats(member);
          if (total > maxS) maxS = total;

          // Individual Stats
          if (member.statsStr != null && member.statsStr! > maxStr) maxStr = member.statsStr!.toDouble();
          if (member.statsDef != null && member.statsDef! > maxDef) maxDef = member.statsDef!.toDouble();
          if (member.statsSpd != null && member.statsSpd! > maxSpd) maxSpd = member.statsSpd!.toDouble();
          if (member.statsDex != null && member.statsDex! > maxDex) maxDex = member.statsDex!.toDouble();

          // Hospital Time (minutes)
          if (member.status?.state == 'Hospital') {
            int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            int remaining = (member.status?.until ?? 0) - now;
            if (remaining < 0) remaining = 0;
            double mins = remaining / 60.0;
            if (mins > maxHosp) maxHosp = mins;
          }
        }
      }
    }

    // Add a buffer to round up to next nice number
    // If max is 0, it means no data found (no spies) so we keep it at 0 to disable the slider later
    if (maxS > 0) {
      _maxStats = maxS * 1.1;
    } else {
      _maxStats = 0;
    }
    if (maxStr > 0) {
      _maxStr = maxStr * 1.1;
    } else {
      _maxStr = 0;
    }
    if (maxDef > 0) {
      _maxDef = maxDef * 1.1;
    } else {
      _maxDef = 0;
    }
    if (maxSpd > 0) {
      _maxSpd = maxSpd * 1.1;
    } else {
      _maxSpd = 0;
    }
    if (maxDex > 0) {
      _maxDex = maxDex * 1.1;
    } else {
      _maxDex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: themeProvider.secondBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            labelColor: themeProvider.mainText,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.pink[700],
            tabs: [
              const Tab(text: "Sorting"),
              const Tab(text: "Smart Score"),
              const Tab(text: "Filters"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSortingTab(themeProvider),
                _buildSmartScoreTab(themeProvider),
                _buildFiltersTab(themeProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortingTab(ThemeProvider theme) {
    var allSorts = WarSortType.values;
    var favorites = allSorts.where((s) => _settings.favoriteSorts.contains(s.toString())).toList();
    var others = allSorts.where((s) => !_settings.favoriteSorts.contains(s.toString())).toList();

    return RadioGroup<WarSortType>(
      groupValue: _warController.currentSort,
      onChanged: (WarSortType? value) {
        if (value != null) {
          setState(() {
            _warController.sortTargets(value);
          });
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (favorites.isNotEmpty) ...[
            const Text("Favorites", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ...favorites.map((type) => _buildSortTile(type, theme)),
            const Divider(),
            const SizedBox(height: 10),
            const Text("All sort criteria", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ] else ...[
            const Text("Main sort criteria", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
          const SizedBox(height: 10),
          ...others.map((type) => _buildSortTile(type, theme)),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSortTile(WarSortType type, ThemeProvider theme) {
    bool isFav = _settings.favoriteSorts.contains(type.toString());
    bool isSelected = _warController.currentSort == type;
    bool showHospitalSettings = isSelected && (type == WarSortType.hospitalDes || type == WarSortType.hospitalAsc);

    String? subtitle;
    if (type == WarSortType.statsAsc) {
      subtitle = "Spied low to high, then estimates low to high, then unknown estimates.";
    } else if (type == WarSortType.statsDes) {
      subtitle = "Spied high to low, then estimates high to low, then unknown estimates.";
    }

    return Column(
      children: [
        RadioListTile<WarSortType>(
          title: Text(WarSort(type: type).description),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
              : null,
          value: type,
          secondary: IconButton(
            icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.orange : Colors.grey),
            onPressed: () {
              setState(() {
                if (isFav) {
                  _settings.favoriteSorts.remove(type.toString());
                } else {
                  _settings.favoriteSorts.add(type.toString());
                }
                _warController.savePreferences();
              });
            },
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
        if (showHospitalSettings)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.secondBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Show 'Okay' targets at top", style: TextStyle(fontSize: 14)),
                    subtitle: Text("Targets not in hospital will appear first.",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    value: _settings.okayTargetsAtTop,
                    onChanged: (val) {
                      setState(() {
                        _settings.okayTargetsAtTop = val;
                        _warController.savePreferences();
                        _warController.update();
                      });
                    },
                    dense: true,
                  ),
                  if (_settings.okayTargetsAtTop)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("Secondary sort:", style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButton<WarSortType>(
                                  value: _settings.secondarySortForOkay,
                                  isExpanded: true,
                                  isDense: true,
                                  underline: Container(height: 1, color: Colors.grey),
                                  items: WarSortType.values.map((WarSortType type) {
                                    return DropdownMenuItem<WarSortType>(
                                      value: type,
                                      child:
                                          Text(WarSort(type: type).description, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (WarSortType? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _settings.secondarySortForOkay = newValue;
                                        _warController.savePreferences();
                                        _warController.update();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Used to sort targets that are NOT in hospital when 'Okay at top' is active. "
                                  "If Smart Score is selected, it uses the configured weights even if not active globally.",
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
          ),
      ],
    );
  }

  Widget _buildSmartScoreTab(ThemeProvider theme) {
    bool isSmartScoreActive = _warController.currentSort == WarSortType.smartScore;
    bool isSecondarySort = _settings.okayTargetsAtTop && _settings.secondarySortForOkay == WarSortType.smartScore;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!isSmartScoreActive)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSecondarySort
                            ? "Smart Score is active as Secondary Sort for 'Okay' targets."
                            : "Smart Score sorting is NOT active",
                      ),
                    ),
                  ],
                ),
                if (!isSecondarySort) ...[
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _warController.sortTargets(WarSortType.smartScore);
                      });
                    },
                    child: const Text("Activate Smart Score sorting"),
                  ),
                ],
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Smart Score weights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () => _showHelpDialog(context),
            ),
          ],
        ),
        Text(
            "Adjust how important each factor is. Negative values prioritize LOW attributes, "
            "positive values prioritize HIGH attributes.",
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 20),
        _buildSlider("Hospital time", _settings.weightHospitalTime, (val) => _settings.weightHospitalTime = val),
        _buildSlider("Life", _settings.weightLife, (val) => _settings.weightLife = val),
        _buildSlider("Fair Fight", _settings.weightFairFight, (val) => _settings.weightFairFight = val),
        _buildSlider("Level", _settings.weightLevel, (val) => _settings.weightLevel = val),

        // Stats Section
        const SizedBox(height: 20),
        Card(
          color: theme.secondBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Row(
                children: [
                  const Text("Stats weights", style: TextStyle(fontWeight: FontWeight.bold)),
                  if (_settings.weightEstimatedStats != 0 ||
                      _settings.weightStats != 0 ||
                      _settings.weightStrength != 0 ||
                      _settings.weightDefense != 0 ||
                      _settings.weightSpeed != 0 ||
                      _settings.weightDexterity != 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          "ACTIVE",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ),
                ],
              ),
              childrenPadding: const EdgeInsets.all(12.0),
              children: [
                _buildSlider(
                  "Estimated stats",
                  _settings.weightEstimatedStats,
                  (val) => _settings.weightEstimatedStats = val,
                  description: "Uses estimated stats",
                ),
                const Divider(),
                _buildSlider(
                  "Total stats (spied)",
                  _settings.weightStats,
                  (val) => _settings.weightStats = val,
                  description: "Uses spied stats if available",
                ),
                _buildSlider("Strength", _settings.weightStrength, (val) => _settings.weightStrength = val),
                _buildSlider("Defense", _settings.weightDefense, (val) => _settings.weightDefense = val),
                _buildSlider("Speed", _settings.weightSpeed, (val) => _settings.weightSpeed = val),
                _buildSlider("Dexterity", _settings.weightDexterity, (val) => _settings.weightDexterity = val),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Divider(),
        _buildPreview(theme),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged, {String? description}) {
    // Determine the key for range lookup based on label
    String rangeKey = '';
    if (label == 'Total stats (spied)') {
      rangeKey = 'Stats';
    } else if (label == 'Estimated stats')
      rangeKey = 'Estimated';
    else if (label == 'Strength')
      rangeKey = 'Str';
    else if (label == 'Defense')
      rangeKey = 'Def';
    else if (label == 'Speed')
      rangeKey = 'Spd';
    else if (label == 'Dexterity')
      rangeKey = 'Dex';
    else if (label.toLowerCase() == 'hospital time') rangeKey = 'Hospital';

    String rangeText = '';
    bool hasData = false;
    double minVal = 0;
    double maxVal = 0;

    String format(double v) {
      if (v >= 1e9) return "${(v / 1e9).toStringAsFixed(1)}B";
      if (v >= 1e6) return "${(v / 1e6).toStringAsFixed(1)}M";
      if (v >= 1e3) return "${(v / 1e3).toStringAsFixed(1)}k";
      return v.toStringAsFixed(0);
    }

    if (rangeKey.isNotEmpty && _warController.attributeRanges.containsKey(rangeKey)) {
      var range = _warController.attributeRanges[rangeKey]!;
      double minLog = range['min']!;
      double maxLog = range['max']!;
      double count = range['count'] ?? 0;

      if (count > 0) hasData = true;

      // Convert back from Log10 to normal numbers for display
      minVal = pow(10, minLog).toDouble() - 1;
      maxVal = pow(10, maxLog).toDouble() - 1;

      // Special formatting for Hospital Time
      if (rangeKey == 'Hospital') {
        if (count == 0) {
          rangeText = "No targets in hospital";
        } else {
          rangeText = "Includes targets currently in hospital";
        }
      } else {
        if (count == 0) {
          rangeText = "No data found";
        } else {
          rangeText = "Range: ${format(minVal)} - ${format(maxVal)} (${count.toInt()} found)";
        }
      }
    }

    String percentage = "${(value * 100).round()}%";
    String titleStatus;
    if (value == 0) {
      titleStatus = "Ignored (0%)";
    } else {
      titleStatus = percentage;
    }

    String prioritySubtitle = "";
    Color color = Colors.grey;

    String getImportance(double v) {
      v = v.abs();
      if (v < 0.25) return "Low";
      if (v < 0.5) return "Moderate";
      if (v < 0.75) return "High";
      return "Extreme";
    }

    if (value != 0) {
      String direction = value > 0 ? "High" : "Low";
      String noun = "values";

      if (rangeKey == 'Hospital') {
        noun = "time";
      } else if (label == 'Life') {
        noun = "life";
      } else if (label == 'Level') {
        noun = "level";
      } else if (label == 'Fair Fight') {
        noun = "FF";
      } else if (['Stats', 'Estimated', 'Str', 'Def', 'Spd', 'Dex'].contains(rangeKey)) {
        noun = "stats";
      }

      prioritySubtitle = "Target: $direction $noun • Importance: ${getImportance(value)}";
      color = value > 0 ? Colors.green : Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$label: $titleStatus", style: const TextStyle(fontWeight: FontWeight.w500)),
            if (value != 0) Icon(value > 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: color),
          ],
        ),
        if (value != 0)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(prioritySubtitle, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ),
        if (rangeText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(rangeText, style: TextStyle(fontSize: 11, color: Colors.blueGrey[400])),
          ),
        if (description != null && !hasData) Text(description, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Slider(
          value: value,
          min: -1.0,
          max: 1.0,
          divisions: 20,
          label: percentage,
          onChanged: (val) {
            setState(() {
              onChanged(val);
              _warController.savePreferences();
              _warController.update();
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeProvider theme) {
    // Gather members for preview
    List<Member> allMembers = [];
    for (var faction in _warController.factions) {
      if (faction.members != null) {
        allMembers.addAll(faction.members!.values.whereType<Member>());
      }
    }

    if (allMembers.isEmpty) {
      return const Text("No members available for preview.");
    }

    // Apply Filters if enabled in Preview
    if (_applyFiltersInPreview && _settings.filtersEnabled) {
      allMembers = allMembers.where((m) {
        // Level Filter
        if (_settings.levelRange != null) {
          double lvl = (m.level ?? 0).toDouble();
          if (lvl < _settings.levelRange!.start || lvl > _settings.levelRange!.end) return false;
        }
        // Life Filter
        if (_settings.lifeRange != null) {
          double life = (m.lifeCurrent ?? 0).toDouble();
          if (life < _settings.lifeRange!.start || life > _settings.lifeRange!.end) return false;
        }
        // Fair Fight Filter
        if (_settings.fairFightRange != null) {
          double ff = m.fairFight ?? 0.0;
          if (ff > 0) {
            if (ff < _settings.fairFightRange!.start || ff > _settings.fairFightRange!.end) return false;
          }
        }
        // Hospital Time Filter
        if (_settings.hospitalTimeRange != null) {
          double mins = 0;
          if (m.status?.state == 'Hospital') {
            int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            int remaining = (m.status?.until ?? 0) - now;
            if (remaining < 0) remaining = 0;
            mins = remaining / 60.0;
          }
          if (mins < _settings.hospitalTimeRange!.start || mins > _settings.hospitalTimeRange!.end) return false;
        }
        // Stats filters
        if (_settings.statsRange != null && _warController.getMemberTotalStats(m) > 0) {
          double s = _warController.getMemberTotalStats(m);
          if (s < _settings.statsRange!.start || s > _settings.statsRange!.end) return false;
        }
        return true;
      }).toList();
    }

    // Calculate details for ALL members once
    // We store original index to handle stable sort simulation
    var memberDetails = allMembers.asMap().entries.map((e) {
      var details = _warController.getSmartScoreDetails(e.value);
      // Add original index for tie-breaking simulation
      details['_originalIndex'] = e.key.toDouble();
      return MapEntry(e.value, details);
    }).toList();

    // Sort by score
    memberDetails.sort((a, b) {
      // Compare scores
      int cmp = b.value['total']!.compareTo(a.value['total']!);
      if (cmp != 0) return cmp;

      // Tie-break with name
      return (a.key.name ?? '').toLowerCase().compareTo((b.key.name ?? '').toLowerCase());
    });

    // Take top 20
    var top20 = memberDetails.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Preview (Top 20)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                const Text("Also apply filters", style: TextStyle(fontSize: 12)),
                Switch(
                  value: _applyFiltersInPreview,
                  onChanged: (val) {
                    setState(() {
                      _applyFiltersInPreview = val;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const Text("Values show score contribution from each factor.",
            style: TextStyle(color: Colors.grey, fontSize: 12)),

        // Warnings
        if (_settings.okayTargetsAtTop &&
            (_warController.currentSort == WarSortType.hospitalAsc ||
                _warController.currentSort == WarSortType.hospitalDes) &&
            _settings.secondarySortForOkay == WarSortType.smartScore)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange[800]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "List might be modified by 'Okay at top' setting (smart score is used as the secondary sort method). "
                    "Targets in hospital will appear at the bottom.",
                    style: TextStyle(fontSize: 11, color: Colors.orange[800], fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        if (_applyFiltersInPreview && _settings.filtersEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 14, color: Colors.orange[800]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "List might be modified by active filters!",
                    style: TextStyle(fontSize: 11, color: Colors.orange[800], fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            "Note: External factors like hidden targets, main page exclusions, or other global settings are not reflected in this preview.",
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),

        const SizedBox(height: 10),
        ...top20.asMap().entries.map((entry) {
          int currentRank = entry.key + 1;
          var m = entry.value.key;
          var details = entry.value.value;
          double totalScore = details['total']!;

          // Remove total from details to sort components
          var components = Map<String, double>.from(details);
          components.remove('total');
          components.remove('_originalIndex');

          // Sort components
          final order = [
            'Level',
            'Life',
            'Fair Fight',
            'Hospital',
            'Stats',
            'Estimated Stats',
            'Str',
            'Def',
            'Spd',
            'Dex'
          ];

          var sortedEntries = components.entries.toList()
            ..sort((a, b) {
              int indexA = order.indexOf(a.key);
              int indexB = order.indexOf(b.key);
              if (indexA == -1) indexA = 999;
              if (indexB == -1) indexB = 999;
              return indexA.compareTo(indexB);
            });

          String scoreText = (totalScore * 100).toStringAsFixed(0);

          // Build info row dynamically based on active weights
          List<String> infoParts = [];

          if (_settings.weightLife != 0) {
            infoParts.add("Life: ${m.lifeCurrent}/${m.lifeMaximum}");
          }

          if (_settings.weightHospitalTime != 0) {
            int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            int remaining = (m.status?.until ?? 0) - now;
            if (remaining < 0) remaining = 0;
            int totalMinutes = remaining ~/ 60;
            int h = totalMinutes ~/ 60;
            int min = totalMinutes % 60;
            String timeStr;
            if (h > 0) {
              if (min == 0) {
                timeStr = "${h}h";
              } else {
                timeStr = "${h}h ${min}m";
              }
            } else {
              timeStr = "${min}m";
            }
            infoParts.add("Hosp: $timeStr");
          }

          if (_settings.weightFairFight != 0) {
            infoParts.add("FF: ${m.fairFight != null && m.fairFight! >= 0 ? m.fairFight!.toStringAsFixed(2) : 'Unk'}");
          }
          if (_settings.weightLevel != 0) {
            infoParts.add("Lvl: ${m.level}");
          }
          if (_settings.weightStats != 0) {
            double stats = _warController.getMemberTotalStats(m);
            if (stats > 0) {
              String statsStr = stats >= 1000000000
                  ? "${(stats / 1000000000).toStringAsFixed(1)}B"
                  : stats >= 1000000
                      ? "${(stats / 1000000).toStringAsFixed(1)}M"
                      : "${(stats / 1000).toStringAsFixed(1)}k";
              infoParts.add("Stats: $statsStr");
            } else {
              infoParts.add("Stats: Unk");
            }
          }
          if (_settings.weightEstimatedStats != 0) {
            String est = m.statsEstimated ?? '';
            if (est.isEmpty) est = 'Unk';
            infoParts.add("Est: $est");
          }

          String formatStat(num? val) {
            if (val == null || val == 0) return 'Unk';
            double v = val.toDouble();
            if (v >= 1000000000) return "${(v / 1000000000).toStringAsFixed(1)}B";
            if (v >= 1000000) return "${(v / 1000000).toStringAsFixed(1)}M";
            if (v >= 1000) return "${(v / 1000).toStringAsFixed(1)}k";
            return v.toStringAsFixed(0);
          }

          if (_settings.weightStrength != 0) infoParts.add("Str: ${formatStat(m.statsStr)}");
          if (_settings.weightDefense != 0) infoParts.add("Def: ${formatStat(m.statsDef)}");
          if (_settings.weightSpeed != 0) infoParts.add("Spd: ${formatStat(m.statsSpd)}");
          if (_settings.weightDexterity != 0) infoParts.add("Dex: ${formatStat(m.statsDex)}");

          String infoText = infoParts.isNotEmpty ? infoParts.join(" | ") : "No smart scores selected (sorted by name)";

          return Card(
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("#$currentRank ${m.name ?? "Unknown"}",
                          style: TextStyle(color: theme.mainText, fontWeight: FontWeight.bold)),
                      Text("Score: $scoreText", style: TextStyle(color: theme.mainText, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    infoText,
                    style: TextStyle(color: theme.mainText.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: sortedEntries.where((e) {
                      bool isSignificant = e.value.abs() > 0.01;
                      bool isActive = false;
                      switch (e.key) {
                        case 'Hospital':
                          isActive = _settings.weightHospitalTime != 0;
                          break;
                        case 'Life':
                          isActive = _settings.weightLife != 0;
                          break;
                        case 'Stats':
                          isActive = _settings.weightStats != 0;
                          break;
                        case 'Estimated Stats':
                          isActive = _settings.weightEstimatedStats != 0;
                          break;
                        case 'Str':
                          isActive = _settings.weightStrength != 0;
                          break;
                        case 'Def':
                          isActive = _settings.weightDefense != 0;
                          break;
                        case 'Spd':
                          isActive = _settings.weightSpeed != 0;
                          break;
                        case 'Dex':
                          isActive = _settings.weightDexterity != 0;
                          break;
                        case 'Fair Fight':
                          isActive = _settings.weightFairFight != 0;
                          break;
                        case 'Level':
                          isActive = _settings.weightLevel != 0;
                          break;
                      }
                      return isSignificant || isActive;
                    }).map((e) {
                      // Show Score Contribution directly
                      String valStr = (e.value * 100).toStringAsFixed(0);

                      // Handle Unknowns
                      if ((e.key == 'Str' && (m.statsStr == null || m.statsStr == -1)) ||
                          (e.key == 'Def' && (m.statsDef == null || m.statsDef == -1)) ||
                          (e.key == 'Spd' && (m.statsSpd == null || m.statsSpd == -1)) ||
                          (e.key == 'Dex' && (m.statsDex == null || m.statsDex == -1)) ||
                          (e.key == 'Stats' &&
                              (m.statsExactTotal == null || m.statsExactTotal == -1) &&
                              (m.statsEstimated == null || m.statsEstimated!.isEmpty))) {
                        valStr = "Unk";
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${e.key}: ", style: TextStyle(color: theme.mainText, fontSize: 10)),
                          Text(valStr,
                              style: TextStyle(color: theme.mainText, fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFiltersTab(ThemeProvider theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text("Enable Filters", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("Only show targets matching these criteria"),
          value: _settings.filtersEnabled,
          onChanged: (val) {
            setState(() {
              _settings.filtersEnabled = val;
              _warController.savePreferences();
              _warController.update();
            });
          },
        ),
        const Divider(),
        if (!_settings.filtersEnabled)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                "Filters are disabled.\nAll targets will be shown.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else ...[
          const Text("Range Filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text("Filter targets based on specific ranges.", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 20),
          _buildRangeSlider("Level", _settings.levelRange, 1, 100, (val) => _settings.levelRange = val),
          _buildRangeSlider("Life", _settings.lifeRange, 0, 10000, (val) => _settings.lifeRange = val),
          _buildRangeSlider("Fair Fight", _settings.fairFightRange, 1.0, 3.0, (val) => _settings.fairFightRange = val),
          _buildHospitalRangeSlider(
              "Hospital Time", _settings.hospitalTimeRange, (val) => _settings.hospitalTimeRange = val),

          // Stats Filters
          const SizedBox(height: 20),
          Card(
            color: theme.secondBackground,
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Row(
                  children: [
                    const Text("Stats Filter", style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_settings.estimatedStatsRange != null ||
                        (_settings.statsRange != null && _maxStats > 0) ||
                        (_settings.strengthRange != null && _maxStr > 0) ||
                        (_settings.defenseRange != null && _maxDef > 0) ||
                        (_settings.speedRange != null && _maxSpd > 0) ||
                        (_settings.dexterityRange != null && _maxDex > 0))
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            "ACTIVE",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ),
                  ],
                ),
                childrenPadding: const EdgeInsets.all(12.0),
                children: [
                  _buildEstimateRangeSlider(
                      "Estimated Stats", _settings.estimatedStatsRange, (val) => _settings.estimatedStatsRange = val),
                  const Divider(),
                  _buildRangeSlider(
                      "Total Stats (Spied)", _settings.statsRange, 0, _maxStats, (val) => _settings.statsRange = val),
                  _buildRangeSlider(
                      "Strength", _settings.strengthRange, 0, _maxStr, (val) => _settings.strengthRange = val),
                  _buildRangeSlider(
                      "Defense", _settings.defenseRange, 0, _maxDef, (val) => _settings.defenseRange = val),
                  _buildRangeSlider("Speed", _settings.speedRange, 0, _maxSpd, (val) => _settings.speedRange = val),
                  _buildRangeSlider(
                      "Dexterity", _settings.dexterityRange, 0, _maxDex, (val) => _settings.dexterityRange = val),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildEstimateRangeSlider(String label, RangeValues? currentRange, Function(RangeValues?) onChanged) {
    // Use the categories from WarController
    final categories = WarController.estimateCategories;
    double min = 0;
    double max = (categories.length - 1).toDouble();

    RangeValues values;
    if (currentRange != null) {
      double safeStart = currentRange.start.clamp(min, max);
      double safeEnd = currentRange.end.clamp(min, max);
      values = RangeValues(safeStart, safeEnd);
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
              value: currentRange != null,
              onChanged: (val) {
                setState(() {
                  onChanged(val ? RangeValues(min, max) : null);
                  _warController.savePreferences();
                  _warController.update();
                });
              },
            ),
          ],
        ),
        if (currentRange != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(categories[values.start.round()], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(categories[values.end.round()], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: categories.length - 1,
            labels: RangeLabels(categories[values.start.round()], categories[values.end.round()]),
            onChanged: (val) {
              setState(() {
                onChanged(val);
                _warController.savePreferences();
                _warController.update();
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildHospitalRangeSlider(String label, RangeValues? currentRange, Function(RangeValues?) onChanged) {
    // Max 100 hours = 6000 minutes
    const double maxMinutes = 6000;

    // Convert minutes -> Slider (0.0 - 1.0)
    // Using power of 4 curve for fine tuning at low values
    double toSlider(double mins) {
      return pow(mins / maxMinutes, 0.25).toDouble().clamp(0.0, 1.0);
    }

    // Convert Slider (0.0 - 1.0) -> Minutes
    double toMinutes(double sliderVal) {
      return maxMinutes * pow(sliderVal, 4);
    }

    // Display
    String formatTime(double mins) {
      int h = (mins / 60).floor();
      int m = (mins % 60).round();
      if (h > 0) {
        if (m == 0) return "${h}h";
        return "${h}h ${m}m";
      }
      return "${m}m";
    }

    // Current values for the slider
    double startSlider = 0.0;
    double endSlider = 1.0;

    if (currentRange != null) {
      startSlider = toSlider(currentRange.start);
      endSlider = toSlider(currentRange.end);
    }

    RangeValues sliderValues = RangeValues(startSlider, endSlider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Switch(
              value: currentRange != null,
              onChanged: (val) {
                setState(() {
                  if (val) {
                    // Default to 0 - 100h
                    onChanged(const RangeValues(0, maxMinutes));
                  } else {
                    onChanged(null);
                  }
                  _warController.savePreferences();
                  _warController.update();
                });
              },
            ),
          ],
        ),
        if (currentRange != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatTime(toMinutes(startSlider)), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(formatTime(toMinutes(endSlider)), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          RangeSlider(
            values: sliderValues,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            labels: RangeLabels(formatTime(toMinutes(startSlider)), formatTime(toMinutes(endSlider))),
            onChanged: (RangeValues newValues) {
              setState(() {
                double startMins = toMinutes(newValues.start);
                double endMins = toMinutes(newValues.end);
                onChanged(RangeValues(startMins, endMins));
                _warController.savePreferences();
                _warController.update();
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRangeSlider(
      String label, RangeValues? currentRange, double min, double max, Function(RangeValues?) onChanged) {
    String formatLabel(double value) {
      if (value >= 1000000000) {
        return "${(value / 1000000000).toStringAsFixed(1)}B";
      }
      if (value >= 1000000) {
        return "${(value / 1000000).toStringAsFixed(1)}M";
      }
      if (value >= 1000) {
        return "${(value / 1000).toStringAsFixed(1)}k";
      }
      return value.round().toString();
    }

    // Check if we have valid data
    bool hasData = max > min;

    if (!hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const Switch(
                value: false,
                onChanged: null, // Disabled
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 0.0, bottom: 10.0),
            child: Text(
              "No spy info available (max: N/A)",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      );
    }

    RangeValues values;
    if (currentRange != null) {
      // Ensure values are within the current min/max limits
      double safeStart = currentRange.start.clamp(min, max);
      double safeEnd = currentRange.end.clamp(min, max);
      values = RangeValues(safeStart, safeEnd);
    } else {
      values = RangeValues(min, max);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$label (max: ${formatLabel(max)})"),
            Switch(
              value: currentRange != null,
              onChanged: (val) {
                setState(() {
                  onChanged(val ? RangeValues(min, max) : null);
                  _warController.savePreferences();
                  _warController.update();
                });
              },
            ),
          ],
        ),
        if (currentRange != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatLabel(values.start), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(formatLabel(values.end), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: 100,
            labels: RangeLabels(formatLabel(values.start), formatLabel(values.end)),
            onChanged: (val) {
              setState(() {
                onChanged(val);
                _warController.savePreferences();
                _warController.update();
              });
            },
          ),
        ],
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How Smart Score works"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection("Importance vs. value",
                  "The sliders control two things simultaneously:\n\n• Direction (left/right): whether you want LOW values (e.g. low hospital time) or HIGH values (e.g. high stats).\n\n• Importance (distance from center): how much this factor influences the final score compared to others.\n"),
              const SizedBox(height: 10),
              _buildHelpSection("Combine factors!",
                  "If you only activate one slider, Smart Score acts just like a normal sort. The real power comes from combining multiple factors.\n\nExample: You can prioritize 'low level' AND 'low hospital time' simultaneously to find weak targets that are about to leave the hospital.\n"),
              const SizedBox(height: 10),
              _buildHelpSection("Relative vs. absolute",
                  "• Stats/Level (relative): 'low' means the importance goes towards the weakest person in the current list, it's stat-dependent. 'High' means the opposite (importance goes towards the member with the highest stat).\n\n• Hospital (Absolute): 'low' always means 0 minutes. 'high' always means 100 hours. Targets NOT in hospital are ignored (neutral score)."),
              const Divider(height: 60),
              const Text("Technical details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              _buildHelpSection("Dynamic relative scoring",
                  "The Smart Score system utilizes a dynamic logarithmic normalization algorithm to evaluate target viability. This method processes the order of magnitude of the parameters, so that it results in a robust comparison between targets regardless of the variance.\n"),
              const SizedBox(height: 10),
              _buildHelpSection("Normalization",
                  "Raw values are transformed using a base-10 logarithmic scale before applying Min-Max Scaling relative to the current target group.\n"),
              const SizedBox(height: 10),
              _buildHelpSection("Dampening",
                  "We compress extreme values, preventing a single entity from rendering the scoring resolution of the remaining population obsolete.\n"),
              const SizedBox(height: 10),
              _buildHelpSection("Stabilization",
                  "We enforce a minimum variance threshold. It prevents minor fluctuations from generating disproportionate scoring differences.\n"),
              const SizedBox(height: 10),
              _buildHelpSection("Final score calculation",
                  "The final index (0–100) is derived from positive weighting (prioritizes max values within the range and negative weighting (prioritizes min values within the range). The cumulative score is the weighted sum of all active attributes.\n"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[800])),
      ],
    );
  }
}
