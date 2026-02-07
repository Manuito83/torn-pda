import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/widgets/player_notes_dialog.dart';
import 'package:torn_pda/widgets/profile_check/profile_check_add_button.dart';
import 'package:torn_pda/widgets/stats/ffscouter_info.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class FFScouterPage extends StatefulWidget {
  const FFScouterPage({super.key});

  @override
  FFScouterPageState createState() => FFScouterPageState();
}

class FFScouterPageState extends State<FFScouterPage> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;
  final UserController _u = Get.find<UserController>();

  List<FFScouterTarget> _targets = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Bulk refresh tracking
  bool _isRefreshingAll = false;
  final Set<int> _refreshingStatus = {};

  // Filter state
  String? _preset;
  int _minLevel = 1;
  int _maxLevel = 100;
  double _minFf = 1.0;
  double _maxFf = 3.0;
  int _limit = 25;
  bool _inactiveOnly = true;
  bool _factionless = false;
  bool _filtersExpanded = true;

  // Text controllers for filter fields (so they update on async load)
  late final TextEditingController _minLevelCtrl = TextEditingController(text: _minLevel.toString());
  late final TextEditingController _maxLevelCtrl = TextEditingController(text: _maxLevel.toString());
  late final TextEditingController _minFfCtrl = TextEditingController(text: _minFf.toStringAsFixed(1));
  late final TextEditingController _maxFfCtrl = TextEditingController(text: _maxFf.toStringAsFixed(1));
  late final TextEditingController _limitCtrl = TextEditingController(text: _limit.toString());

  @override
  void initState() {
    super.initState();
    routeWithDrawer = true;
    routeName = "chaining_target_finder";
    _loadFilters();
    _loadCachedTargets();
  }

  @override
  void dispose() {
    _minLevelCtrl.dispose();
    _maxLevelCtrl.dispose();
    _minFfCtrl.dispose();
    _maxFfCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    final raw = await Prefs().getFFScouterFilters();
    if (raw.isEmpty) return;
    try {
      final Map<String, dynamic> f = json.decode(raw);
      if (mounted) {
        setState(() {
          _preset = f['preset'] as String?;
          _minLevel = (f['minLevel'] as int?) ?? 1;
          _maxLevel = (f['maxLevel'] as int?) ?? 100;
          _minFf = (f['minFf'] as num?)?.toDouble() ?? 1.0;
          _maxFf = (f['maxFf'] as num?)?.toDouble() ?? 3.0;
          _limit = (f['limit'] as int?) ?? 25;
          _inactiveOnly = (f['inactiveOnly'] as bool?) ?? true;
          _factionless = (f['factionless'] as bool?) ?? false;
          // Update text controllers
          _minLevelCtrl.text = _minLevel.toString();
          _maxLevelCtrl.text = _maxLevel.toString();
          _minFfCtrl.text = _minFf.toStringAsFixed(1);
          _maxFfCtrl.text = _maxFf.toStringAsFixed(1);
          _limitCtrl.text = _limit.toString();
        });
      }
    } catch (_) {
      // Ignore corrupt filter cache
    }
  }

  Future<void> _saveFilters() async {
    final f = {
      'preset': _preset,
      'minLevel': _minLevel,
      'maxLevel': _maxLevel,
      'minFf': _minFf,
      'maxFf': _maxFf,
      'limit': _limit,
      'inactiveOnly': _inactiveOnly,
      'factionless': _factionless,
    };
    await Prefs().setFFScouterFilters(json.encode(f));
  }

  Future<void> _loadCachedTargets() async {
    final cached = await Prefs().getFFScouterTargetsCache();
    if (cached.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(cached);
        final restored = decoded.map((e) => FFScouterTarget.fromJson(e)).toList();
        if (mounted && restored.isNotEmpty) {
          setState(() {
            _targets = restored;
            _filtersExpanded = false;
          });
        }
      } catch (_) {
        // Ignore corrupt cache
      }
    }
  }

  Future<void> _saveCachedTargets() async {
    if (_targets.isNotEmpty) {
      final encoded = json.encode(_targets.map((t) => t.toJson()).toList());
      await Prefs().setFFScouterTargetsCache(encoded);
    } else {
      await Prefs().setFFScouterTargetsCache("");
    }
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _settingsProvider = Provider.of<SettingsProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: !_settingsProvider.ffScouterEnabledStatusRemoteConfig
            ? _buildRemoteDisabledScreen()
            : _settingsProvider.ffScouterEnabledStatus != 1
                ? _buildConsentScreen()
                : Column(
                    children: [
                      _buildFiltersSection(),
                      Expanded(child: _buildResultsSection()),
                    ],
                  ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text('FFScouter', style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.splitScreenAndBrowserLeft()) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive) const PdaBrowserIcon(),
        ],
      ),
      actions: [
        if (_targets.isNotEmpty)
          _isRefreshingAll
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.sync, color: Colors.white),
                  tooltip: "Refresh all statuses",
                  onPressed: _refreshAllTargetStatuses,
                ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () {
            showDialog(
              useRootNavigator: false,
              context: context,
              builder: (context) {
                return FFScouterInfoDialog(
                  settingsProvider: _settingsProvider,
                  themeProvider: _themeProvider,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildConsentScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, color: Colors.grey[400], size: 50),
            const SizedBox(height: 16),
            Text(
              "FFScouter is not enabled",
              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Please review the information, terms and data policy before enabling FFScouter",
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await showDialog(
                  useRootNavigator: false,
                  context: context,
                  builder: (context) {
                    return FFScouterInfoDialog(
                      settingsProvider: _settingsProvider,
                      themeProvider: _themeProvider,
                    );
                  },
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text("Review & Enable"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteDisabledScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: Colors.grey[400], size: 50),
            const SizedBox(height: 16),
            Text(
              "FFScouter temporarily deactivated",
              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "This feature is temporarily disabled. Please try again later.",
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Filters",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Icon(
                    _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_filtersExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                children: [
                  // Preset selector
                  _buildPresetSelector(),
                  if (_preset == null) ...[
                    const SizedBox(height: 8),
                    _buildLevelRange(),
                    const SizedBox(height: 8),
                    _buildFairFightRange(),
                    const SizedBox(height: 4),
                    _buildToggleOptions(),
                  ],
                  const SizedBox(height: 4),
                  _buildLimitSelector(),
                  const SizedBox(height: 8),
                  _buildSearchButton(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Mode: ", style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: SegmentedButton<String?>(
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
                  visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _themeProvider.currentTheme == AppTheme.light
                          ? Colors.blueGrey[200]
                          : Colors.blueGrey[700];
                    }
                    return null;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _themeProvider.currentTheme == AppTheme.light ? Colors.black87 : Colors.white;
                    }
                    return null;
                  }),
                ),
                segments: const [
                  ButtonSegment(value: null, label: Text("Custom")),
                  ButtonSegment(value: "respect", label: Text("Respect")),
                  ButtonSegment(value: "level", label: Text("Level")),
                ],
                selected: {_preset},
                onSelectionChanged: (selection) {
                  setState(() => _preset = selection.first);
                  _saveFilters();
                },
              ),
            ),
          ],
        ),
        if (_preset != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _preset == "respect"
                  ? "Server selects targets optimized for best respect gain"
                  : "Server selects targets matched to your level",
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildLevelRange() {
    return Row(
      children: [
        const Text("Level: ", style: TextStyle(fontSize: 13)),
        SizedBox(
          width: 50,
          child: TextFormField(
            controller: _minLevelCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(),
              labelText: "Min",
              labelStyle: TextStyle(fontSize: 11),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) {
              final val = int.tryParse(v);
              if (val != null && val >= 1 && val <= 100) {
                _minLevel = val;
                _saveFilters();
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text("-"),
        ),
        SizedBox(
          width: 50,
          child: TextFormField(
            controller: _maxLevelCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(),
              labelText: "Max",
              labelStyle: TextStyle(fontSize: 11),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) {
              final val = int.tryParse(v);
              if (val != null && val >= 1 && val <= 100) {
                _maxLevel = val;
                _saveFilters();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFairFightRange() {
    return Row(
      children: [
        const Text("Fair Fight: ", style: TextStyle(fontSize: 13)),
        SizedBox(
          width: 55,
          child: TextFormField(
            controller: _minFfCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(),
              labelText: "Min",
              labelStyle: TextStyle(fontSize: 11),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 1.0) {
                _minFf = val;
                _saveFilters();
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text("-"),
        ),
        SizedBox(
          width: 55,
          child: TextFormField(
            controller: _maxFfCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(),
              labelText: "Max",
              labelStyle: TextStyle(fontSize: 11),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 1.0) {
                _maxFf = val;
                _saveFilters();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOptions() {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _inactiveOnly,
                  onChanged: (v) {
                    setState(() => _inactiveOnly = v ?? true);
                    _saveFilters();
                  },
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  activeColor: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 4),
              const Text("Inactive only", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _factionless,
                  onChanged: (v) {
                    setState(() => _factionless = v ?? false);
                    _saveFilters();
                  },
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  activeColor: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 4),
              const Text("Factionless only", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLimitSelector() {
    return Row(
      children: [
        const Text("Results: ", style: TextStyle(fontSize: 13)),
        SizedBox(
          width: 55,
          child: TextFormField(
            controller: _limitCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(),
              labelText: "Max",
              labelStyle: TextStyle(fontSize: 11),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) {
              final val = int.tryParse(v);
              if (val != null && val >= 1 && val <= 50) {
                _limit = val;
                _saveFilters();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text("(1-50)", style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _fetchTargets,
        icon: _isLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.search, size: 18),
        label: Text(_isLoading ? "Searching..." : "Find Targets"),
        style: ElevatedButton.styleFrom(
          visualDensity: const VisualDensity(vertical: -2),
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_targets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, color: Colors.grey[400], size: 50),
              const SizedBox(height: 10),
              Text(
                "Set your filters and tap Find Targets\nto search via FFScouter",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _targets.length,
      itemBuilder: (context, index) => _buildTargetCard(_targets[index]),
    );
  }

  Widget _buildTargetCard(FFScouterTarget target) {
    final lastActionText = _formatLastAction(target.lastAction);
    final bsText = target.bsEstimateHuman ?? (target.bsEstimate != null ? formatBigNumbers(target.bsEstimate!) : "N/A");
    final ffText = target.fairFight?.toStringAsFixed(2) ?? "N/A";
    final pid = target.playerId ?? 0;

    // Green border when just updated
    final borderColor = target.justUpdated ? Colors.green : Colors.transparent;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _openAttack(target, shortTap: true),
        onLongPress: () => _openAttack(target, shortTap: false),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Name + Level + Action buttons
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            target.name ?? "Unknown",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "[${target.playerId}]",
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 4),
                        _buildFactionIcon(target),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _themeProvider.currentTheme == AppTheme.light ? Colors.grey[300] : Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Lv ${target.level ?? '?'}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _themeProvider.mainText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Refresh status
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: _refreshingStatus.contains(pid)
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.refresh, size: 20, color: Colors.blueGrey[400]),
                            tooltip: "Refresh status",
                            onPressed: () => _refreshTargetStatus(target),
                          ),
                  ),
                  const SizedBox(width: 4),
                  // Notes
                  _buildNotesIcon(target),
                  const SizedBox(width: 4),
                  // Add to targets
                  ProfileCheckAddButton(
                    profileId: pid,
                    playerName: target.name,
                    factionId: target.factionId,
                    icon: Icons.add_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Row 2: Stats + last action
              Row(
                children: [
                  _statChip("BS", bsText, Colors.blue[700]!),
                  const SizedBox(width: 8),
                  _statChip("FF", ffText, _ffColor(target.fairFight)),
                  const Spacer(),
                  if (lastActionText != null)
                    Text(
                      lastActionText,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                ],
              ),
              // Row 3: Live status (if has been refreshed)
              if (target.hasStatus) _buildStatusRow(target),
              // Row 4: Player note (if any)
              _buildNoteRow(target),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactionIcon(FFScouterTarget target) {
    final List<Widget> icons = [];

    // Faction icon
    if (target.factionName != null &&
        target.factionName!.isNotEmpty &&
        target.factionId != null &&
        target.factionId != 0) {
      final bool sameFaction = target.factionId == _u.factionId && _u.factionId != 0;
      final Color iconColor = sameFaction ? Colors.red : _themeProvider.mainText;
      final Color borderColor = sameFaction ? Colors.red : Colors.transparent;
      icons.add(
        Tooltip(
          message: target.factionName!,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.5),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(2),
            child: ImageIcon(
              const AssetImage('images/icons/faction.png'),
              size: 12,
              color: iconColor,
            ),
          ),
        ),
      );
    }

    // Company icon
    if (target.companyId != null && target.companyId != 0) {
      final bool sameCompany = target.companyId == _u.companyId && _u.companyId != 0;
      if (sameCompany) {
        if (icons.isNotEmpty) icons.add(const SizedBox(width: 2));
        icons.add(
          Tooltip(
            message: target.companyName ?? "Company",
            child: const Icon(Icons.work, size: 14, color: Colors.red),
          ),
        );
      }
    }

    if (icons.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  Widget _buildNotesIcon(FFScouterTarget target) {
    return GetBuilder<PlayerNotesController>(
      builder: (ctrl) {
        final note = ctrl.getNoteForPlayer(target.playerId.toString());
        Color iconColor = _themeProvider.mainText;
        if (note != null && !PlayerNoteColor.isNone(note.color)) {
          iconColor = PlayerNoteColor.toColor(note.color);
        }
        final hasNote = note != null && (note.note.isNotEmpty || !PlayerNoteColor.isNone(note.color));
        return SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              hasNote ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
              size: 20,
              color: hasNote ? iconColor : Colors.blueGrey[400],
            ),
            tooltip: "Notes",
            onPressed: () {
              showPlayerNotesDialog(
                context: context,
                playerId: target.playerId.toString(),
                playerName: target.name ?? '',
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNoteRow(FFScouterTarget target) {
    return GetBuilder<PlayerNotesController>(
      builder: (ctrl) {
        final note = ctrl.getNoteForPlayer(target.playerId.toString());
        if (note == null || (note.note.isEmpty && PlayerNoteColor.isNone(note.color))) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (!PlayerNoteColor.isNone(note.color))
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.circle, size: 8, color: PlayerNoteColor.toColor(note.color)),
                ),
              Flexible(
                child: Text(
                  note.effectiveDisplayText,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(FFScouterTarget target) {
    final state = target.statusState ?? "";
    final color = target.statusColor ?? "";
    final lastActionStatus = target.lastActionStatus ?? "Offline";

    // Online status icon
    Widget onlineIcon;
    if (lastActionStatus == "Online") {
      onlineIcon = const Icon(Icons.circle, size: 10, color: Colors.green);
    } else if (lastActionStatus == "Idle") {
      onlineIcon = const Icon(Icons.adjust, size: 10, color: Colors.orange);
    } else {
      onlineIcon = const Icon(Icons.remove_circle, size: 10, color: Colors.grey);
    }

    // State text
    String stateText = "OK";
    Color stateColor = Colors.green;
    if (state.contains("Hospital")) {
      stateText = "Hospital";
      stateColor = Colors.red;
      if (target.statusUntil != null && target.statusUntil! > 0) {
        final until = DateTime.fromMillisecondsSinceEpoch(target.statusUntil! * 1000);
        final diff = until.difference(DateTime.now());
        if (diff.isNegative) {
          stateText = "Out of hospital";
          stateColor = Colors.green;
        } else {
          final m = diff.inMinutes;
          final h = diff.inHours;
          stateText = h > 0 ? "Hospital (${h}h ${m % 60}m)" : "Hospital (${m}m)";
        }
      }
    } else if (state.contains("Jail")) {
      stateText = "Jail";
      stateColor = Colors.orange;
      if (target.statusUntil != null && target.statusUntil! > 0) {
        final until = DateTime.fromMillisecondsSinceEpoch(target.statusUntil! * 1000);
        final diff = until.difference(DateTime.now());
        if (!diff.isNegative) {
          final m = diff.inMinutes;
          stateText = "Jail (${m}m)";
        }
      }
    } else if (state.contains("Federal") || state.contains("Fallen")) {
      stateText = state;
      stateColor = Colors.red[800]!;
    } else if (color == "blue") {
      stateText = target.statusDescription ?? "Traveling";
      stateColor = Colors.blue;
    }

    // Updated ago text
    String updatedAgo = "";
    if (target.statusLastUpdated != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(target.statusLastUpdated! * 1000);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        updatedAgo = "just now";
      } else if (diff.inMinutes < 60) {
        updatedAgo = "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        updatedAgo = "${diff.inHours}h ago";
      } else {
        updatedAgo = "${diff.inDays}d ago";
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          onlineIcon,
          const SizedBox(width: 4),
          Text(
            lastActionStatus,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.circle, size: 8, color: stateColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              stateText,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stateColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (updatedAgo.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              updatedAgo,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label: ",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Color _ffColor(double? ff) {
    if (ff == null) return Colors.grey;
    if (ff >= 2.5) return Colors.green[700]!;
    if (ff >= 2.0) return Colors.green;
    if (ff >= 1.5) return Colors.orange;
    return Colors.red;
  }

  String? _formatLastAction(int? timestamp) {
    if (timestamp == null) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return "${diff.inDays ~/ 30}mo ago";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    return "${diff.inMinutes}m ago";
  }

  Future<void> _refreshAllTargetStatuses() async {
    if (_targets.isEmpty || _isRefreshingAll) return;
    setState(() => _isRefreshingAll = true);

    int updated = 0;
    int errors = 0;

    for (final target in _targets) {
      if (target.playerId == null) continue;
      if (!mounted) break;

      try {
        final result = await ApiCallsV1.getTarget(playerId: target.playerId.toString());
        if (result is TargetModel && mounted) {
          target.updateFromTargetModel(result);
          target.justUpdated = true;
          updated++;
          setState(() {});
        } else {
          errors++;
        }
      } catch (_) {
        errors++;
      }
      // Small delay to avoid API flooding
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Save enriched data to cache
    _saveCachedTargets();

    if (mounted) {
      setState(() => _isRefreshingAll = false);

      // Show summary toast
      final msg = errors > 0 ? "Updated $updated targets ($errors failed)" : "Updated $updated targets";
      BotToast.showText(
        text: msg,
        contentColor: Colors.grey[800]!,
        textStyle: const TextStyle(fontSize: 13, color: Colors.white),
        duration: const Duration(seconds: 3),
      );

      // Clear green borders after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            for (final t in _targets) {
              t.justUpdated = false;
            }
          });
        }
      });
    }
  }

  Future<void> _refreshTargetStatus(FFScouterTarget target) async {
    if (target.playerId == null) return;
    final pid = target.playerId!;

    setState(() => _refreshingStatus.add(pid));

    try {
      final result = await ApiCallsV1.getTarget(playerId: pid.toString());
      if (result is TargetModel && mounted) {
        target.updateFromTargetModel(result);
        target.justUpdated = true;
        setState(() => _refreshingStatus.remove(pid));
        _saveCachedTargets();
        // Clear green border after delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => target.justUpdated = false);
          }
        });
      } else {
        if (mounted) setState(() => _refreshingStatus.remove(pid));
        BotToast.showText(
          text: "Could not fetch status for ${target.name}",
          contentColor: Colors.red[800]!,
          textStyle: const TextStyle(fontSize: 13, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _refreshingStatus.remove(pid));
    }
  }

  void _openAttack(FFScouterTarget target, {required bool shortTap}) {
    if (target.playerId == null) return;

    // Build the target list starting from the tapped target
    final startIndex = _targets.indexWhere((t) => t.playerId == target.playerId);
    final subList = startIndex >= 0 ? _targets.sublist(startIndex) : [target];
    final notesCtrl = Get.find<PlayerNotesController>();

    final attackIds = <String>[];
    final attackNames = <String?>[];
    final attackNotes = <String?>[];
    final attackNotesColor = <String?>[];
    for (final t in subList) {
      final id = t.playerId.toString();
      attackIds.add(id);
      attackNames.add(t.name);

      // Combine FFScouter info with player note
      final bsText = t.bsEstimateHuman ?? (t.bsEstimate != null ? formatBigNumbers(t.bsEstimate!) : null);
      final ffText = t.fairFight?.toStringAsFixed(2);
      final parts = <String>[if (bsText != null) 'BS: $bsText', if (ffText != null) 'FF: $ffText'];
      final playerNote = notesCtrl.getNoteForPlayer(id);
      if (playerNote != null && playerNote.note.isNotEmpty) {
        parts.add(playerNote.note);
      }
      attackNotes.add(parts.isNotEmpty ? parts.join(' | ') : null);
      attackNotesColor.add(playerNote?.color ?? '');
    }

    _webViewProvider.openBrowserPreference(
      context: context,
      url: 'https://www.torn.com/loader.php?sid=attack&user2ID=${attackIds[0]}',
      browserTapType: shortTap ? BrowserTapType.chainShort : BrowserTapType.chainLong,
      isChainingBrowser: true,
      chainingPayload: ChainingPayload()
        ..attackIdList = attackIds
        ..attackNameList = attackNames
        ..attackNotesList = attackNotes
        ..attackNotesColorList = attackNotesColor
        ..showNotes = true
        ..showBlankNotes = false
        ..showOnlineFactionWarning = false
        ..skipAutoUpdate = true,
    );
  }

  Future<void> _fetchTargets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await FFScouterComm.getTargets(
      key: _u.alternativeFFScouterKey,
      preset: _preset,
      minLevel: _preset == null ? _minLevel : null,
      maxLevel: _preset == null ? _maxLevel : null,
      inactiveOnly: _preset == null ? (_inactiveOnly ? 1 : 0) : null,
      minFf: _preset == null ? _minFf : null,
      maxFf: _preset == null ? _maxFf : null,
      factionless: _preset == null ? (_factionless ? 1 : 0) : null,
      limit: _limit,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success && result.data?.targets != null) {
        _targets = result.data!.targets!;
        if (_targets.isEmpty) {
          _errorMessage = "No targets found matching your criteria. Try adjusting the filters.";
        }
        _filtersExpanded = false;
        _saveCachedTargets();
        _saveFilters();
      } else {
        _targets = [];
        _errorMessage = result.errorMessage ?? "Failed to fetch targets";
      }
    });
  }
}
