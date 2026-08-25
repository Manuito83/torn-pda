// Flutter imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/pages/settings/scripts_catalog_page.dart';
import 'package:torn_pda/pages/settings/scripts_docs_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/settings/gold_storage_icon.dart';
import 'package:torn_pda/widgets/settings/script_storage_quota_dialog.dart';
import 'package:torn_pda/widgets/settings/userscripts_add_dialog.dart';
import 'package:torn_pda/widgets/settings/userscripts_bulk_update_dialog.dart';
import 'package:torn_pda/widgets/settings/userscripts_revert_dialog.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';

class UserScriptsPage extends StatefulWidget {
  final bool? fromWebview;

  const UserScriptsPage({super.key, this.fromWebview});

  @override
  UserScriptsPageState createState() => UserScriptsPageState();
}

class UserScriptsPageState extends State<UserScriptsPage> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late UserScriptsProvider _userScriptsProvider;
  late WebViewProvider _webViewProvider;

  bool _firstTimeNotAccepted = false;

  final _scrollController = ScrollController();

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_userScriptsProvider.scriptsFirstTime) {
        await showDialog(
          useRootNavigator: false,
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return _firstTimeDialog();
          },
        );

        if (_firstTimeNotAccepted) {
          _goBack();
        }
      }
    });

    routeWithDrawer = false;
    routeName = "userscripts";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "userscripts") _goBack();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _willPopSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : isStatusBarShown
                ? _themeProvider.statusBar
                : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        right: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.left,
        left: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(height: AppBar().preferredSize.height, child: buildAppBar())
              : null,
          body: Container(
            color: _themeProvider.canvas,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color?>(_themeProvider.secondBackground),
                            shape: WidgetStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: const BorderSide(width: 2, color: Colors.blueGrey),
                              ),
                            ),
                          ),
                          child: Icon(Icons.add, size: 20, color: _themeProvider.mainText),
                          onPressed: () {
                            _showAddDialog(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.disabled)) {
                                return Colors.grey;
                              }
                              return _themeProvider.secondBackground;
                            }),
                            shape: WidgetStateProperty.resolveWith<OutlinedBorder>((Set<WidgetState> states) {
                              return RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  width: 2,
                                  color: states.contains(WidgetState.disabled) ? Colors.grey : Colors.blueGrey,
                                ),
                              );
                            }),
                          ),
                          onPressed: _userScriptsProvider.userScriptList.isEmpty
                              ? null
                              : () => _userScriptsProvider.checkForUpdates().then((i) {
                                  _userScriptsProvider.resetBulkUpdateBannerDismiss();
                                  BotToast.showText(
                                    text: i > 0
                                        ? "$i script${i == 1 ? " is" : "s are"} ready to update"
                                        : "No updates found",
                                    textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                    contentColor: i > 0 ? Colors.green[800]! : Colors.grey[800]!,
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                }),
                          child: Icon(Icons.refresh, size: 20, color: _themeProvider.mainText),
                        ),
                      ),
                      const SizedBox(width: 15),
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.disabled)) {
                                return Colors.grey;
                              }
                              return _userScriptsProvider.isGlobalDisableActive
                                  ? Colors.orange[700]
                                  : _themeProvider.secondBackground;
                            }),
                            shape: WidgetStateProperty.resolveWith<OutlinedBorder>((Set<WidgetState> states) {
                              return RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  width: 2,
                                  color: states.contains(WidgetState.disabled)
                                      ? Colors.grey
                                      : _userScriptsProvider.isGlobalDisableActive
                                      ? Colors.orange[900]!
                                      : Colors.blueGrey,
                                ),
                              );
                            }),
                          ),
                          onPressed: _userScriptsProvider.userScriptList.isEmpty
                              ? null
                              : () {
                                  if (_userScriptsProvider.isGlobalDisableActive) {
                                    _userScriptsProvider.toggleGlobalDisable();
                                  } else {
                                    _showGlobalDisableDialog(context);
                                  }
                                },
                          child: Icon(Icons.remove_circle_outline, size: 20, color: _themeProvider.mainText),
                        ),
                      ),
                      const SizedBox(width: 15),
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.disabled)) {
                                return Colors.grey;
                              }
                              return _themeProvider.secondBackground;
                            }),
                            shape: WidgetStateProperty.resolveWith<OutlinedBorder>((Set<WidgetState> states) {
                              return RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  width: 2,
                                  color: states.contains(WidgetState.disabled) ? Colors.grey : Colors.blueGrey,
                                ),
                              );
                            }),
                          ),
                          onPressed: _userScriptsProvider.userScriptList.isEmpty
                              ? null
                              : () {
                                  _openWipeDialog();
                                },
                          child: Icon(Icons.delete_outline, size: 20, color: _themeProvider.mainText),
                        ),
                      ),
                    ],
                  ),
                  if (_userScriptsProvider.showBulkUpdateBanner) _bulkUpdateBanner(),
                  if (_userScriptsProvider.scriptCatalogEnabled) _catalogBanner(),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Preexisting scripts might require modifications to work with Torn PDA. '
                      'Please ensure that you use scripts responsibly and '
                      'understand the hazards. Tap the exclamation mark for more information.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Consumer<UserScriptsProvider>(builder: (context, settingsProvider, child) => scriptsCards()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catalogBanner() {
    final bool light = _themeProvider.currentTheme == AppTheme.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
      child: Card(
        margin: EdgeInsets.zero,
        color: light ? Colors.blue[50] : Colors.blueGrey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.blueGrey[light ? 200 : 700]!),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (BuildContext context) => const ScriptsCatalogPage()),
            ).then((_) {
              routeWithDrawer = false;
              routeName = "userscripts";
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Icon(MdiIcons.toolbox, size: 20, color: light ? Colors.blue[800] : Colors.blue[200]),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("TornTools scripts", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        "Browse and install TornTools features as individual scripts",
                        style: TextStyle(fontSize: 11, color: Colors.grey[light ? 700 : 400]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bulkUpdateBanner() {
    final int count = _userScriptsProvider.pendingUpdatesCount;
    final bool light = _themeProvider.currentTheme == AppTheme.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
      child: Card(
        margin: EdgeInsets.zero,
        color: light ? Colors.green[50] : Colors.green[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.green[light ? 700 : 400]!),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
          child: Row(
            children: [
              Icon(MdiIcons.earthPlus, size: 18, color: Colors.green[light ? 800 : 300]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$count script update${count == 1 ? "" : "s"} available",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                child: const Text("REVIEW", style: TextStyle(fontSize: 12)),
                onPressed: () {
                  showDialog(context: context, builder: (_) => const UserScriptsBulkUpdateDialog());
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: _userScriptsProvider.dismissBulkUpdateBanner,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storageSupportBadge(UserScriptModel script) {
    return GestureDetector(
      child: const GoldStorageIcon(size: 20),
      onTap: () => showScriptStorageQuotaDialog(context, script.storageId),
    );
  }

  ListView scriptsCards() {
    final scriptList = <Widget>[];
    for (final script in _userScriptsProvider.userScriptList) {
      scriptList.add(
        Card(
          key: UniqueKey(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 60,
                        child: Switch(
                          value: script.enabled,
                          activeTrackColor: Colors.green[100],
                          activeThumbColor: Colors.green,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey[300],
                          onChanged: (value) {
                            _userScriptsProvider.changeUserScriptEnabled(script, value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(script.name, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (script.customApiKeyCandidate)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          child: Icon(
                            Icons.key,
                            color: script.customApiKey.isNotEmpty ? Colors.green : Colors.orangeAccent,
                            size: 20,
                          ),
                          onTap: () async {
                            String message =
                                "This script does not have a dedicated API key.\n\n"
                                "It will use the default Torn PDA API key.\n\n"
                                "If you want to use a dedicated API key, please edit the script and add it there.";

                            if (script.customApiKey.isNotEmpty) {
                              message =
                                  "This script  has a dedicated API key:\n\n"
                                  "${script.customApiKey}\n\n"
                                  "This key will be used instead of the default Torn PDA API key.";
                            }

                            BotToast.showText(
                              text: message,
                              textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                              contentColor: Colors.grey[800]!,
                              contentPadding: const EdgeInsets.all(10),
                              clickClose: true,
                              duration: const Duration(seconds: 10),
                            );
                          },
                        ),
                      ),
                    if (script.updateStatus == UserScriptUpdateStatus.noRemote)
                      GestureDetector(
                        child: const Icon(MdiIcons.tagEdit, color: Colors.grey, size: 20),
                        onTap: () async {
                          BotToast.showText(
                            text:
                                'This is a custom script without an update URL.\n\n'
                                'It will not be updated automatically.',
                            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                            contentColor: Colors.grey[800]!,
                            contentPadding: const EdgeInsets.all(10),
                            duration: const Duration(seconds: 5),
                          );
                        },
                      )
                    else if (script.updateStatus == UserScriptUpdateStatus.localModified)
                      GestureDetector(
                        child: script.isExample
                            ? Image.asset(
                                "images/icons/torn_pda_browser.png",
                                width: 20,
                                height: 20,
                                color: Colors.orange,
                              )
                            : const Icon(MdiIcons.earthOff, color: Colors.orange, size: 20),
                        onTap: () async {
                          BotToast.showText(
                            text:
                                "This is a${script.isExample ? "n example" : ""} script that you have edited, "
                                "so it will not update. Reset changes to enable updates again.",
                            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                            contentColor: Colors.grey[800]!,
                            contentPadding: const EdgeInsets.all(10),
                          );
                        },
                      )
                    else if (script.updateStatus == UserScriptUpdateStatus.upToDate)
                      GestureDetector(
                        child: script.isExample
                            ? Image.asset(
                                "images/icons/torn_pda_browser.png",
                                width: 20,
                                height: 20,
                                color: Colors.green,
                              )
                            : const Icon(MdiIcons.earth, color: Colors.green, size: 20),
                        onTap: () async {
                          BotToast.showText(
                            text: "This ${script.isExample ? "example " : ""}script is up-to-date (v${script.version})",
                            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                            contentColor: Colors.grey[800]!,
                            contentPadding: const EdgeInsets.all(10),
                          );
                        },
                      )
                    else if (script.updateStatus == UserScriptUpdateStatus.updateAvailable)
                      GestureDetector(
                        child: Icon(
                          script.isExample ? MdiIcons.lockPlus : MdiIcons.earthPlus,
                          color: Colors.red,
                          size: 20,
                        ),
                        onTap: () async {
                          BotToast.showText(
                            text: "An update is available (currently on v${script.version})",
                            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                            contentColor: Colors.grey[800]!,
                            contentPadding: const EdgeInsets.all(10),
                          );
                          showDialog(
                            builder: (c) => UserScriptsAddDialog(
                              scriptBeingEdited: script,
                              editingExistingScript: true,
                              defaultPage: 1,
                            ),
                            context: context,
                          );
                        },
                      )
                    else if (script.updateStatus == UserScriptUpdateStatus.error)
                      GestureDetector(
                        child: const Icon(MdiIcons.earthRemove, color: Colors.red, size: 20),
                        onTap: () async {
                          BotToast.showText(
                            text: "An error occurred while checking for updates. Please try again later.",
                            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                            contentColor: Colors.grey[800]!,
                            contentPadding: const EdgeInsets.all(10),
                          );
                        },
                      )
                    else if (script.updateStatus == UserScriptUpdateStatus.updating)
                      GestureDetector(
                        child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
                        onTap: () async => BotToast.showText(
                          text: "Checking for updates...",
                          textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                          contentColor: Colors.grey[800]!,
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      )
                    else
                      GestureDetector(
                        child: const Icon(MdiIcons.helpCircle, color: Colors.blue, size: 20),
                        onTap: () async {
                          BotToast.showText(
                            text: "The update status of this script could not be determined.",
                            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                            contentColor: Colors.grey[800]!,
                            contentPadding: const EdgeInsets.all(10),
                          );
                        },
                      ),
                    if (script.storageSupport == ScriptStorageSupport.pdaNative) ...[
                      const SizedBox(width: 12),
                      _storageSupportBadge(script),
                    ],
                    const SizedBox(width: 12),
                    GestureDetector(
                      child: const Icon(Icons.edit, size: 20),
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          barrierDismissible: false, // user must tap button!
                          builder: (BuildContext context) {
                            return UserScriptsAddDialog(editingExistingScript: true, scriptBeingEdited: script);
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      child: Icon(Icons.delete_outlined, color: Colors.red[300], size: 20),
                      onTap: () async {
                        _openDeleteSingleDialog(script);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(children: scriptList);
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      toolbarHeight: 50,
      title: const Text('User scripts', style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _goBack();
            },
          ),
          if (!_webViewProvider.webViewSplitActive && widget.fromWebview != true)
            const PdaBrowserIcon()
          else
            Container(),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(MdiIcons.cogOutline),
          onSelected: (value) {
            if (value == 'export') {
              _showExportDialog();
            } else if (value == 'export_userjs') {
              _showUserJsExportDialog();
            } else if (value == 'import') {
              _showImportDialog();
            } else if (value == 'toggle_catalog') {
              _userScriptsProvider.setScriptCatalogEnabled = !_userScriptsProvider.scriptCatalogEnabled;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.grey),
                    SizedBox(width: 10),
                    Text('Export to JSON'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export_userjs',
                child: Row(
                  children: [
                    Icon(Icons.javascript, color: Colors.grey),
                    SizedBox(width: 10),
                    Text('Export to .user.js'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.grey),
                    SizedBox(width: 10),
                    Text('Import from file'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'toggle_catalog',
                child: Row(
                  children: [
                    Icon(
                      _userScriptsProvider.scriptCatalogEnabled ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _userScriptsProvider.scriptCatalogEnabled ? 'Hide TornTools section' : 'Show TornTools section',
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
        IconButton(
          icon: const Icon(MdiIcons.backupRestore),
          onPressed: () async {
            _openRestoreDialog();
          },
        ),
        IconButton(
          icon: Icon(MdiIcons.bookOpenPageVariantOutline, color: Colors.orange[300]),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => ScriptsDocsPage(onOpenDisclaimer: _openDisclaimerDialog),
              ),
            );
            routeWithDrawer = false;
            routeName = "userscripts";
          },
        ),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext ctx) {
    return showDialog<void>(
      context: ctx,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return const UserScriptsAddDialog(editingExistingScript: false);
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Export Scripts"),
        content: const Text(
          "You can export your scripts to a JSON file to share them or save them manually.\n\n"
          "Note: bear in mind that you can also export through the Share, "
          "Cloud backup and Local backup features in Settings.",
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showExportSelectionDialog();
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showUserJsExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Export to .user.js"),
        content: const Text(
          "This exports each selected script as a standard .user.js file that you can install in "
          "Tampermonkey/Violentmonkey on a desktop browser (just open the file to trigger the install).\n\n"
          "Note: scripts that rely on Torn PDA's own API key placeholder or PDA-specific features may need "
          "manual adjustments to work on desktop.",
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showExportSelectionDialog(asUserJs: true);
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showExportSelectionDialog({bool asUserJs = false}) {
    final allScripts = _userScriptsProvider.userScriptList;
    final selectedScripts = Set<UserScriptModel>.from(allScripts);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Scripts to Export"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedScripts.clear();
                              selectedScripts.addAll(allScripts);
                            });
                          },
                          child: const Text("Select All"),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedScripts.clear();
                            });
                          },
                          child: const Text("Deselect All"),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allScripts.length,
                        itemBuilder: (context, index) {
                          final script = allScripts[index];
                          return SwitchListTile(
                            title: Text(script.name, style: const TextStyle(fontSize: 14)),
                            value: selectedScripts.contains(script),
                            activeThumbColor: Colors.green,
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey[300],
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedScripts.add(script);
                                } else {
                                  selectedScripts.remove(script);
                                }
                              });
                            },
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: selectedScripts.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _performExport(selectedScripts.toList(), asUserJs: asUserJs);
                        },
                  child: const Text("Share File"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performExport(List<UserScriptModel> scripts, {bool asUserJs = false}) async {
    try {
      final directory = await getTemporaryDirectory();
      final List<XFile> filesToShare = [];

      if (asUserJs) {
        // One .user.js file per script, with the raw source
        final usedNames = <String>{};
        for (final script in scripts) {
          String base = _sanitizeFileName(script.name);
          if (base.isEmpty) base = "script";
          String fileName = "$base.user.js";
          int counter = 1;
          while (usedNames.contains(fileName)) {
            fileName = "$base ($counter).user.js";
            counter++;
          }
          usedNames.add(fileName);

          final file = File('${directory.path}/$fileName');
          await file.writeAsString(script.source);
          filesToShare.add(XFile(file.path));
        }
      } else {
        final jsonString = _userScriptsProvider.exportScriptsToJson(scripts);
        final file = File('${directory.path}/userscripts_export.json');
        await file.writeAsString(jsonString);
        filesToShare.add(XFile(file.path));
      }

      await SharePlus.instance.share(
        ShareParams(
          files: filesToShare,
          sharePositionOrigin: Rect.fromLTWH(
            0,
            0,
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height / 2,
          ),
        ),
      );
    } catch (e) {
      BotToast.showText(text: "Error exporting scripts: $e");
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Import Scripts"),
        content: const Text(
          "You can import scripts from:\n\n"
          "- A JSON file (Torn PDA export format), which may contain several scripts.\n"
          "- A single .user.js file (e.g. exported from Tampermonkey/Violentmonkey on desktop).\n\n"
          "Note: bear in mind that you can also restore from the Share, "
          "Cloud backup and Local backup features in Settings.",
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImportFile();
            },
            child: const Text("Select File"),
          ),
        ],
      ),
    );
  }

  UserScriptModel _userScriptFromRawSource(String source, String fileName) {
    // Fallback name from the file name (strip .user.js / .js) in case the header has no @name
    String fallbackName = fileName
        .replaceAll(RegExp(r'\.user\.js$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.js$', caseSensitive: false), '')
        .trim();
    if (fallbackName.isEmpty) fallbackName = "Imported script";

    Map<String, dynamic>? metaMap;
    try {
      metaMap = UserScriptModel.parseHeader(source);
    } catch (_) {
      metaMap = null;
    }

    final headerName = (metaMap?["name"] as String?)?.trim();
    final matches = (metaMap?["matches"] as List?)?.cast<String>();
    final grants = (metaMap?["grants"] as List?)?.cast<String>();
    final requires = (metaMap?["requires"] as List?)?.cast<String>();
    final downloadUrl = metaMap?["downloadURL"] as String?;

    return UserScriptModel(
      name: (headerName != null && headerName.isNotEmpty) ? headerName : fallbackName,
      version: metaMap?["version"] ?? "0.0.0",
      source: source,
      matches: (matches != null && matches.isNotEmpty) ? matches : const ["*"],
      url: downloadUrl,
      updateStatus: downloadUrl != null ? UserScriptUpdateStatus.upToDate : UserScriptUpdateStatus.noRemote,
      time: metaMap?["injectionTime"] == "document-start" ? UserScriptTime.start : UserScriptTime.end,
      isExample: false,
      grants: grants ?? const [],
      requires: requires ?? const [],
    );
  }

  Future<void> _pickImportFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'js'],
      );

      if (result != null) {
        final picked = result.files.single;
        final file = File(picked.path!);
        final content = await file.readAsString();
        final isUserJs = (picked.name.toLowerCase().endsWith('.js'));
        _parseAndShowImportSelection(content, fileName: picked.name, isUserJs: isUserJs);
      }
    } catch (e) {
      BotToast.showText(text: "Error picking file: $e");
    }
  }

  void _parseAndShowImportSelection(String content, {required String fileName, bool isUserJs = false}) {
    List<UserScriptModel> importedScripts = [];
    try {
      if (isUserJs) {
        importedScripts.add(_userScriptFromRawSource(content, fileName));
      } else {
        final decoded = json.decode(content);
        if (decoded is List) {
          for (final item in decoded) {
            importedScripts.add(UserScriptModel.fromJson(item));
          }
        } else {
          throw const FormatException("JSON is not a list");
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Invalid Format"),
          content: Text("The file could not be parsed as a valid script.\nError: $e"),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))],
        ),
      );
      return;
    }

    if (importedScripts.isEmpty) {
      BotToast.showText(text: "No scripts found in file.");
      return;
    }

    // Selection state
    final selectedScripts = Set<UserScriptModel>.from(importedScripts);
    bool overwriteMode = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Import Options"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text("Mode: "),
                        const Spacer(),
                        Text(
                          overwriteMode ? "Overwrite" : "Append",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: overwriteMode ? Colors.red : Colors.green,
                          ),
                        ),
                        Switch(
                          value: overwriteMode,
                          activeThumbColor: Colors.red,
                          onChanged: (val) {
                            setState(() {
                              overwriteMode = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (overwriteMode)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          "Warning: this will delete ALL your current scripts!",
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedScripts.clear();
                              selectedScripts.addAll(importedScripts);
                            });
                          },
                          child: const Text("Select All"),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedScripts.clear();
                            });
                          },
                          child: const Text("Deselect All"),
                        ),
                      ],
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: importedScripts.length,
                        itemBuilder: (context, index) {
                          final script = importedScripts[index];
                          // Check for conflict (only relevant in Append mode)
                          bool nameConflict = false;
                          if (!overwriteMode) {
                            nameConflict = _userScriptsProvider.userScriptList.any(
                              (s) => s.name.toLowerCase() == script.name.toLowerCase(),
                            );
                          }

                          return SwitchListTile(
                            title: Text(script.name, style: const TextStyle(fontSize: 14)),
                            subtitle: nameConflict
                                ? const Text(
                                    "Name conflict: Will be renamed",
                                    style: TextStyle(color: Colors.orange, fontSize: 12),
                                  )
                                : null,
                            value: selectedScripts.contains(script),
                            activeThumbColor: Colors.green,
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey[300],
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedScripts.add(script);
                                } else {
                                  selectedScripts.remove(script);
                                }
                              });
                            },
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                ElevatedButton(
                  style: overwriteMode
                      ? ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)
                      : null,
                  onPressed: selectedScripts.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _performImport(selectedScripts.toList(), overwriteMode);
                        },
                  child: Text(overwriteMode ? "Overwrite" : "Import"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performImport(List<UserScriptModel> scripts, bool overwrite) async {
    try {
      await _userScriptsProvider.importScriptsFromList(scriptsToImport: scripts, overwrite: overwrite);
      BotToast.showText(text: "Scripts imported successfully!");
    } catch (e) {
      BotToast.showText(text: "Error importing scripts: $e");
    }
  }

  Future<void> _showGlobalDisableDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Temporarily disable all scripts and remember state?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'This feature allows you to temporarily disable all scripts, while remembering '
                  'their current enabled/disabled state.',
                ),
                SizedBox(height: 10),
                Text(
                  'This might be useful, for example, to quickly disable the additional features '
                  'they provide or to test if any of them is causing issues in the browser.',
                ),
                SizedBox(height: 10),
                Text(
                  'If you proceed, all scripts will be disabled but you will be able to restore '
                  'their previous state by tapping this button again.',
                ),
                SizedBox(height: 10),
                Text(
                  'IMPORTANT: if you perform any action on the script list, such as '
                  'manually enabling/disabling, editing, adding or removing any script while '
                  'this mode is active, the "restore" functionality will be disabled.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Proceed'),
              onPressed: () {
                _userScriptsProvider.toggleGlobalDisable();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openWipeDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(top: 45, bottom: 16, left: 16, right: 16),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: _themeProvider.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10.0, offset: Offset(0.0, 10.0))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        const Flexible(
                          child: Text("CAUTION", style: TextStyle(fontSize: 13, color: Colors.red)),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "This will remove all user scripts!",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Text("Are you sure?", style: TextStyle(fontSize: 12, color: _themeProvider.mainText)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Do it!"),
                              onPressed: () {
                                _userScriptsProvider.wipe();
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Oh no!"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: const SizedBox(height: 34, width: 34, child: Icon(Icons.delete_forever_outlined)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDeleteSingleDialog(UserScriptModel script) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(top: 45, bottom: 16, left: 16, right: 16),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: _themeProvider.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10.0, offset: Offset(0.0, 10.0))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "Remove ${script.name}?",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Do it!"),
                              onPressed: () {
                                _userScriptsProvider.removeUserScript(script);
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Oh no!"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: const SizedBox(height: 34, width: 34, child: Icon(Icons.delete_forever_outlined)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRestoreDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return UserScriptsRevertDialog();
      },
    );
  }

  Future<void> _openDisclaimerDialog() async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return _disclaimerDialog();
      },
    );
  }

  AlertDialog _disclaimerDialog() {
    return AlertDialog(
      title: const Text("DISCLAIMER"),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "User scripts are small programs written in JavaScript that enhance the browser's "
              "functionalities. Be careful when using them and ensure that you understand the code "
              "and what the script accomplishes; otherwise, ensure they come from a reliable "
              "source and have been checked by someone you trust.\n\n"
              "As in any other browser, user scripts might be used maliciously to get information "
              "from your Torn account or other websites you visit.",
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 15),
            Text(
              "Remote scripts can be updated by their author at any time. Even though a script may "
              "have been safe previously, malicious updates can be added. Ensure you verify all "
              "changes before you install any update. If you are unsure, please reach out in the "
              "UserScripts section of the Discord server.",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text(
              "Everything else about user scripts, such as how they are injected, how to write them, "
              "native storage, the app handlers and troubleshooting, is explained in the docs section.",
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  PopScope _firstTimeDialog() {
    // Will show for users updating to V2, as well as new users.
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text("CAUTION"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Be careful when using user scripts and ensure that you understand the code "
                "and what it accomplishes; otherwise, ensure they come from a reliable "
                "source and have been checked by someone you trust.\n\n"
                "As in any other browser, user scripts might be used maliciously to get information "
                "from your Torn account or other websites you visit.",
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 10),
              Text(
                "Torn PDA has recently added support for remote scripts. Even though these scripts "
                "may have been safe previously, malicious updates can be added. Ensure you verify all changes "
                "before you install any updates from scripts. If you are unsure, please reach out in the "
                "UserScripts section of the Discord server.",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Please, read the disclaimer by pressing the warning icon in the app bar for "
                "more information.",
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 10),
              Text("Do you understand the risk?", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              child: const Text("Yes, I promise!"),
              onPressed: () {
                _userScriptsProvider.changeScriptsFirstTime = false;
                // Fire and forget: load defaults now that the user accepted
                if (_userScriptsProvider.userScriptList.isEmpty) {
                  _userScriptsProvider.addDefaultScripts();
                }
                Navigator.of(context).pop('exit');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              child: const Text("What?!"),
              onPressed: () {
                _firstTimeNotAccepted = true;
                BotToast.showText(
                  text: 'Returning...!',
                  textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                  contentColor: Colors.orange[800]!,
                  contentPadding: const EdgeInsets.all(10),
                );
                Navigator.of(context).pop('exit');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    routeWithDrawer = false;
    routeName = "settings_browser";
    Navigator.of(context).pop();
  }
}
