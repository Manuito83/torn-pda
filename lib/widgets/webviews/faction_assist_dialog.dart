import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

/// Data class holding all the info we can potentially send in a faction assist.
class FactionAssistPayload {
  final String attackId;
  final String attackName;
  final String attackLevel;
  final String attackLife;
  final String attackAge;
  final String estimatedStats;
  final String exactStats;
  final String xanax;
  final String refills;
  final String drinks;
  final String ffsStats; // FFScouter battle score string
  final String fairFight; // FFScouter fair fight string

  const FactionAssistPayload({
    required this.attackId,
    this.attackName = "",
    this.attackLevel = "",
    this.attackLife = "",
    this.attackAge = "",
    this.estimatedStats = "",
    this.exactStats = "",
    this.xanax = "unk",
    this.refills = "unk",
    this.drinks = "unk",
    this.ffsStats = "",
    this.fairFight = "",
  });
}

/// Result returned when user confirms the dialog. Contains the same fields
/// but only the ones the user has checked.
class FactionAssistResult {
  final String attackId;
  final String attackName;
  final String attackLevel;
  final String attackLife;
  final String attackAge;
  final String estimatedStats;
  final String exactStats;
  final String xanax;
  final String refills;
  final String drinks;
  final String ffsStats;
  final String fairFight;

  const FactionAssistResult({
    required this.attackId,
    this.attackName = "",
    this.attackLevel = "",
    this.attackLife = "",
    this.attackAge = "",
    this.estimatedStats = "",
    this.exactStats = "",
    this.xanax = "unk",
    this.refills = "unk",
    this.drinks = "unk",
    this.ffsStats = "",
    this.fairFight = "",
  });
}

/// Shows a confirmation dialog with checkboxes for each piece of data
/// that will be sent in a faction assist notification.
///
/// Returns a [FactionAssistResult] if confirmed, or null if cancelled.
Future<FactionAssistResult?> showFactionAssistDialog({
  required BuildContext context,
  required FactionAssistPayload payload,
}) {
  return showDialog<FactionAssistResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _FactionAssistDialog(payload: payload),
  );
}

class _FactionAssistDialog extends StatefulWidget {
  final FactionAssistPayload payload;

  const _FactionAssistDialog({required this.payload});

  @override
  State<_FactionAssistDialog> createState() => _FactionAssistDialogState();
}

class _FactionAssistDialogState extends State<_FactionAssistDialog> {
  late ThemeProvider _themeProvider;

  // Checkboxes — name/level are always sent (not optional)
  bool _sendLife = true;
  bool _sendAge = true;
  bool _sendEstimatedStats = true;
  bool _sendExactStats = true;
  bool _sendFfsStats = true;
  bool _sendFairFight = true;
  bool _sendXanax = true;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _restorePrefs();
  }

  Future<void> _restorePrefs() async {
    final prefs = await Prefs().getFactionAssistPrefs();
    setState(() {
      _sendLife = prefs['life'] ?? true;
      _sendAge = prefs['age'] ?? true;
      _sendEstimatedStats = prefs['estimatedStats'] ?? true;
      _sendExactStats = prefs['exactStats'] ?? true;
      _sendFfsStats = prefs['ffsStats'] ?? true;
      _sendFairFight = prefs['fairFight'] ?? true;
      _sendXanax = prefs['xanax'] ?? true;
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    await Prefs().setFactionAssistPrefs({
      'life': _sendLife,
      'age': _sendAge,
      'estimatedStats': _sendEstimatedStats,
      'exactStats': _sendExactStats,
      'ffsStats': _sendFfsStats,
      'fairFight': _sendFairFight,
      'xanax': _sendXanax,
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: _themeProvider.secondBackground,
      title: Row(
        children: [
          const Icon(MdiIcons.fencing, color: Colors.red, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "FACTION ASSISTANCE",
              style: TextStyle(fontSize: 14, color: _themeProvider.mainText),
            ),
          ),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select what to include in the assist notification:",
                    style: TextStyle(fontSize: 12, color: _themeProvider.mainText, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),

                  // Name + Level (always sent)
                  _buildAlwaysOnRow(
                    icon: Icons.person,
                    label: "Name & Level",
                    value: "${p.attackName.isNotEmpty ? p.attackName : 'ID ${p.attackId}'}"
                        "${p.attackLevel.isNotEmpty ? ' (Lv ${p.attackLevel})' : ''}",
                  ),
                  const Divider(height: 1),

                  // Life
                  if (p.attackLife.isNotEmpty)
                    _buildCheckboxRow(
                      icon: Icons.favorite,
                      iconColor: Colors.red[300]!,
                      label: "Life",
                      value: p.attackLife,
                      checked: _sendLife,
                      onChanged: (v) => setState(() => _sendLife = v!),
                    ),

                  // Age
                  if (p.attackAge.isNotEmpty)
                    _buildCheckboxRow(
                      icon: Icons.cake,
                      iconColor: Colors.amber,
                      label: "Age",
                      value: "${p.attackAge} days",
                      checked: _sendAge,
                      onChanged: (v) => setState(() => _sendAge = v!),
                    ),

                  // Spied stats
                  if (p.exactStats.isNotEmpty)
                    _buildCheckboxRow(
                      icon: MdiIcons.incognito,
                      iconColor: Colors.orange,
                      label: "Spied stats",
                      value: p.exactStats,
                      checked: _sendExactStats,
                      onChanged: (v) => setState(() => _sendExactStats = v!),
                    ),

                  // FFScouter BS
                  if (p.ffsStats.isNotEmpty)
                    _buildCheckboxRow(
                      icon: MdiIcons.swordCross,
                      iconColor: Colors.deepPurple,
                      label: "FFS battle score",
                      value: p.ffsStats,
                      checked: _sendFfsStats,
                      onChanged: (v) => setState(() => _sendFfsStats = v!),
                    ),

                  // Fair Fight
                  if (p.fairFight.isNotEmpty)
                    _buildCheckboxRow(
                      icon: MdiIcons.scaleBalance,
                      iconColor: Colors.teal,
                      label: "Fair Fight",
                      value: p.fairFight,
                      checked: _sendFairFight,
                      onChanged: (v) => setState(() => _sendFairFight = v!),
                    ),

                  // Estimated stats
                  if (p.estimatedStats.isNotEmpty)
                    _buildCheckboxRow(
                      icon: Icons.query_stats,
                      iconColor: Colors.blueGrey,
                      label: "Estimated stats",
                      value: _cleanEstimated(p.estimatedStats),
                      checked: _sendEstimatedStats,
                      onChanged: (v) => setState(() => _sendEstimatedStats = v!),
                    ),

                  // Xanax / Refills / Drinks (grouped)
                  if (p.xanax != "unk" || p.refills != "unk" || p.drinks != "unk")
                    _buildCheckboxRow(
                      icon: MdiIcons.pill,
                      iconColor: Colors.blue,
                      label: "Xanax / Refills / Drinks",
                      value: "X:${p.xanax}  R:${p.refills}  D:${p.drinks}",
                      checked: _sendXanax,
                      onChanged: (v) => setState(() => _sendXanax = v!),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text("CANCEL"),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.send, size: 16),
          label: const Text("SEND"),
          onPressed: () async {
            await _savePrefs();

            final result = FactionAssistResult(
              attackId: p.attackId,
              attackName: p.attackName,
              attackLevel: _sendAge || _sendLife ? p.attackLevel : "",
              attackLife: _sendLife ? p.attackLife : "",
              attackAge: _sendAge ? p.attackAge : "",
              estimatedStats: _sendEstimatedStats ? p.estimatedStats : "",
              exactStats: _sendExactStats ? p.exactStats : "",
              xanax: _sendXanax ? p.xanax : "unk",
              refills: _sendXanax ? p.refills : "unk",
              drinks: _sendXanax ? p.drinks : "unk",
              ffsStats: _sendFfsStats ? p.ffsStats : "",
              fairFight: _sendFairFight ? p.fairFight : "",
            );

            if (context.mounted) Navigator.of(context).pop(result);
          },
        ),
      ],
    );
  }

  /// Row that is always included (not toggleable).
  Widget _buildAlwaysOnRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _themeProvider.mainText),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _themeProvider.mainText)),
                Text(value, style: TextStyle(fontSize: 11, color: _themeProvider.mainText)),
              ],
            ),
          ),
          Icon(Icons.lock, size: 14, color: Colors.grey[500]),
        ],
      ),
    );
  }

  /// Row with a checkbox toggle.
  Widget _buildCheckboxRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool checked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              value: checked,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _themeProvider.mainText),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 10, color: _themeProvider.mainText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Remove the trailing "(tap to get a comparison with you)" and xanax/refills/drinks lines
  /// from the estimated stats string for display (they are shown separately).
  String _cleanEstimated(String raw) {
    String s = raw;
    final tapIdx = s.indexOf("\n(tap to get");
    if (tapIdx != -1) s = s.substring(0, tapIdx);
    final xanIdx = s.indexOf("\n- Xanax:");
    if (xanIdx != -1) s = s.substring(0, xanIdx);
    return s.trim();
  }
}
