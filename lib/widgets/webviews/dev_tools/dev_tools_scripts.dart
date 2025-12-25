import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/pages/settings/userscripts_page.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';

class DevToolsScriptsTab extends StatefulWidget {
  final InAppWebViewController? webViewController;

  const DevToolsScriptsTab({super.key, required this.webViewController});

  @override
  State<DevToolsScriptsTab> createState() => _DevToolsScriptsTabState();
}

class _DevToolsScriptsTabState extends State<DevToolsScriptsTab> {
  late UserScriptsProvider _userScriptsProvider;
  late ThemeProvider _themeProvider;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    if (widget.webViewController != null) {
      final url = await widget.webViewController!.getUrl();
      if (mounted) {
        setState(() {
          _currentUrl = url?.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context);
    _themeProvider = Provider.of<ThemeProvider>(context);

    if (_currentUrl == null) {
      return Center(
        child: CircularProgressIndicator(
          color: _themeProvider.mainText,
        ),
      );
    }

    final activeScripts = _userScriptsProvider.getActiveScriptsForUrl(_currentUrl!);

    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          decoration: BoxDecoration(
            color: _themeProvider.canvas.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: _themeProvider.mainText.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: _themeProvider.mainText.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "These scripts are currently injected because they match the criteria for this page.",
                      style: TextStyle(
                        color: _themeProvider.mainText.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Active Scripts",
                    style: TextStyle(
                      color: _themeProvider.mainText,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              "${activeScripts.length} running",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: _themeProvider.mainText),
                        tooltip: "Manage Scripts",
                        onPressed: _openUserScriptsSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scripts List
        Expanded(
          child: activeScripts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.javascript_outlined,
                        size: 80,
                        color: _themeProvider.mainText.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No active scripts for this page",
                        style: TextStyle(
                          color: _themeProvider.mainText.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: activeScripts.length,
                  itemBuilder: (context, index) {
                    final script = activeScripts[index];
                    return _buildScriptCard(script);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScriptCard(UserScriptModel script) {
    final matchPattern = _getMatchPattern(script, _currentUrl!);
    final isStart = script.time == UserScriptTime.start;

    return Card(
      color: _themeProvider.canvas,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _themeProvider.mainText.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Icon + Name + Version
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _themeProvider.canvas,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.javascript, color: Colors.green[400], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        script.name,
                        style: TextStyle(
                          color: _themeProvider.mainText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "v${script.version}",
                        style: TextStyle(
                          color: _themeProvider.mainText.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.code, color: _themeProvider.mainText),
                  tooltip: "View Source",
                  onPressed: () => _showScriptSource(context, script),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                  tooltip: "Disable & Remove",
                  onPressed: () => _showDisableDialog(context, script),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Details
            _buildDetailRow(
              icon: Icons.filter_alt_outlined,
              label: "Match Rule",
              value: matchPattern,
              isCode: true,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: isStart ? Icons.start : Icons.last_page,
              label: "Injection",
              value: isStart ? 'Document Start' : 'Document End',
              valueColor: isStart ? Colors.orangeAccent : Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCode = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _themeProvider.mainText.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            color: _themeProvider.mainText.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        Expanded(
          child: isCode
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _themeProvider.canvas,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _themeProvider.mainText.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: _themeProvider.mainText.withValues(alpha: 0.9),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? _themeProvider.mainText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
        ),
      ],
    );
  }

  String _getMatchPattern(UserScriptModel script, String url) {
    for (var match in script.matches) {
      if (match == "*" || url.contains(match.replaceAll("*", ""))) {
        return match;
      }
    }
    return "Unknown";
  }

  void _showScriptSource(BuildContext context, UserScriptModel script) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeProvider.canvas,
        title: Text(script.name, style: TextStyle(color: _themeProvider.mainText)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              script.source,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _themeProvider.mainText,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showDisableDialog(BuildContext context, UserScriptModel script) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeProvider.canvas,
        title: Text("Disable & Remove", style: TextStyle(color: _themeProvider.mainText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to disable '${script.name}'?",
              style: TextStyle(color: _themeProvider.mainText),
            ),
            const SizedBox(height: 16),
            Text(
              "Please note:",
              style: TextStyle(color: _themeProvider.mainText, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint("This will disable the script globally."),
            _buildBulletPoint(
                "Changes might only fully take effect on the next page load if the script has modified the page memory."),
            _buildBulletPoint("It is recommended to open a new tab or restart the app to ensure a clean state."),
            _buildBulletPoint("On iOS, this might not work if this tab was opened from another tab."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _disableAndRemove(script);
            },
            child: const Text("Disable & Remove", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(color: _themeProvider.mainText)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: _themeProvider.mainText.withValues(alpha: 0.8), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _disableAndRemove(UserScriptModel script) async {
    if (widget.webViewController != null) {
      try {
        await widget.webViewController!.removeUserScriptsByGroupName(groupName: script.name);
      } catch (e) {
        debugPrint("Error removing script: $e");
      }
    }
    _userScriptsProvider.changeUserScriptEnabled(script, false);
  }

  void _openUserScriptsSettings() async {
    if (_userScriptsProvider.isInSafeMode) {
      _userScriptsProvider.showSafeModeWarning();
      return;
    }

    // Snapshot state before navigation
    final beforeScripts = _userScriptsProvider.getActiveScriptsForUrl(_currentUrl!);
    final Map<String, String> beforeState = {
      for (var s in beforeScripts) s.name: s.source,
    };

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => const UserScriptsPage(
          fromWebview: true,
        ),
      ),
    );

    // Snapshot state after navigation
    if (!mounted) return;
    final afterScripts = _userScriptsProvider.getActiveScriptsForUrl(_currentUrl!);
    final Map<String, String> afterState = {
      for (var s in afterScripts) s.name: s.source,
    };

    // Compare
    final added = afterState.keys.where((k) => !beforeState.containsKey(k)).toList();
    final removed = beforeState.keys.where((k) => !afterState.containsKey(k)).toList();
    final modified =
        afterState.keys.where((k) => beforeState.containsKey(k) && beforeState[k] != afterState[k]).toList();

    if (added.isNotEmpty || modified.isNotEmpty || removed.isNotEmpty) {
      _showChangesDialog(added, modified, removed);
    }
  }

  void _showChangesDialog(List<String> added, List<String> modified, List<String> removed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeProvider.canvas,
        title: Text("Scripts Changed", style: TextStyle(color: _themeProvider.mainText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (added.isNotEmpty || modified.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.update, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${added.length + modified.length} script(s) added or updated.",
                      style: TextStyle(color: _themeProvider.mainText, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "These changes will apply on the next page load.",
                style: TextStyle(color: _themeProvider.mainText.withValues(alpha: 0.8), fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
            if (removed.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.orangeAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${removed.length} script(s) disabled/removed.",
                      style: TextStyle(color: _themeProvider.mainText, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Please note:",
                style: TextStyle(color: _themeProvider.mainText, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              _buildBulletPoint(
                  "Changes might only fully take effect on the next page load if the script has modified the page memory."),
              _buildBulletPoint("It is recommended to open a new tab or restart the app to ensure a clean state."),
              _buildBulletPoint("On iOS, this might not work if this tab was opened from another tab."),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
