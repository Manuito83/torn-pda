import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_cache.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/chain_attack.dart';
import 'package:torn_pda/widgets/chaining/ffscouter_target_card.dart';
import 'package:torn_pda/widgets/ffscouter/ffscouter_bounty_board.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/widgets/stats/ffscouter_info.dart';
import 'package:torn_pda/widgets/pip/pip_player_picker.dart';

class FFScouterPage extends StatefulWidget {
  const FFScouterPage({super.key});

  @override
  FFScouterPageState createState() => FFScouterPageState();
}

class FFScouterPageState extends State<FFScouterPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });

  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;
  final UserController _u = Get.find<UserController>();

  List<FFScouterTarget> _targets = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _errorCode;

  // Bulk refresh tracking
  bool _isRefreshingAll = false;

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

  final _pipSelection = PipSelection();

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
    _tabController.dispose();
    _minLevelCtrl.dispose();
    _maxLevelCtrl.dispose();
    _minFfCtrl.dispose();
    _maxFfCtrl.dispose();
    _limitCtrl.dispose();
    _pipSelection.dispose();
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
    final restored = decodeFFScouterTargets(await Prefs().getFFScouterTargetsCache());
    if (mounted && restored.isNotEmpty) {
      setState(() {
        _targets = restored;
        _filtersExpanded = false;
      });
    }
  }

  Future<void> _saveCachedTargets() async {
    await Prefs().setFFScouterTargetsCache(encodeFFScouterTargets(_targets));
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _settingsProvider = Provider.of<SettingsProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      appBar: _settingsProvider.appBarTop ? PipSelectionAppBar(selection: _pipSelection, appBar: buildAppBar) : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: PipSelectionAppBar(selection: _pipSelection, appBar: buildAppBar),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: !_settingsProvider.ffScouterEnabledStatusRemoteConfig
            ? _buildRemoteDisabledScreen()
            : _settingsProvider.ffScouterEnabledStatus != 1
            ? _buildConsentScreen()
            : !_settingsProvider.ffScouterBountiesEnabled
            ? Column(
                children: [
                  _buildFiltersSection(),
                  Expanded(child: _buildResultsSection()),
                ],
              )
            : Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: _themeProvider.mainText,
                    unselectedLabelColor: Colors.grey[500],
                    tabs: const [
                      Tab(height: 36, text: "Target Finder"),
                      Tab(height: 36, text: "Bounty Board"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Column(
                          children: [
                            _buildFiltersSection(),
                            Expanded(child: _buildResultsSection()),
                          ],
                        ),
                        const FFScouterBountyBoardView(),
                      ],
                    ),
                  ),
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
      leadingWidth: _webViewProvider.appCanOpenBrowser ? 88 : 50,
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
          if (_webViewProvider.appCanOpenBrowser) const PdaBrowserIcon(),
        ],
      ),
      actions: [
        PipPlayersButton(
          onPressed: () {
            if (_targets.isNotEmpty) _tabController.animateTo(0);
            _pipSelection.start(empty: _targets.isEmpty);
          },
        ),
        if (_targets.isNotEmpty && _tabController.index == 0)
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FFScouterInfoPage(settingsProvider: _settingsProvider, themeProvider: _themeProvider),
              ),
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FFScouterInfoPage(settingsProvider: _settingsProvider, themeProvider: _themeProvider),
                  ),
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
                  const Text("Filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Icon(_filtersExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
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
                  ButtonSegment(
                    value: null,
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text("Custom")),
                  ),
                  ButtonSegment(
                    value: "respect",
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text("Respect")),
                  ),
                  ButtonSegment(
                    value: "level",
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text("Level")),
                  ),
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
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text("-")),
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
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text("-")),
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
              if (_errorCode == 6) ...[
                const SizedBox(height: 12),
                Text(
                  "Your API key is not registered with FFScouter. "
                  "You can register it directly from Torn PDA.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FFScouterInfoPage(
                          settingsProvider: _settingsProvider,
                          themeProvider: _themeProvider,
                          jumpToKeySetup: true,
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.app_registration, size: 18),
                  label: const Text("Register Key"),
                ),
              ],
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

    return PipSelectionScope(
      selection: _pipSelection,
      child: ListView.builder(
        itemCount: _targets.length,
        itemBuilder: (context, index) {
          final target = _targets[index];
          final card = FFScouterTargetCard(
            key: ObjectKey(target),
            target: target,
            onAttack: (shortTap) => attackFromTargetFinder(context, _targets, target, shortTap: shortTap),
            onChanged: _saveCachedTargets,
          );
          if (target.playerId == null) return card;
          return PipSelectable(id: target.playerId!, name: target.name ?? '', child: card);
        },
      ),
    );
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

  Future<void> _fetchTargets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorCode = null;
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
        _errorCode = result.errorCode;
      }
    });
  }
}
